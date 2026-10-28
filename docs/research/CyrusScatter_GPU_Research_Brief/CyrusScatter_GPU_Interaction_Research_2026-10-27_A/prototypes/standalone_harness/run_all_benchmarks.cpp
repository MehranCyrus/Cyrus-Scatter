// run_all_benchmarks.cpp
// Standalone synthetic benchmark and D3D11/CUDA/OpenCL interoperability probe
// for the Cyrus Scatter GPU Interaction Research assignment.
//
// Compiled directly with MSVC 14.38.33130 (the exact 3ds Max 2027 C++20 compiler)
// linking against CUDA 12.1 (cudart.lib, cuda.lib, nvrtc.lib), D3D11 (d3d11.lib,
// d3dcompiler.lib, dxgi.lib), and dynamically loading OpenCL.dll.
//
// IMPORTANT: This is a standalone synthetic harness executed on the local
// research workstation (AMD Ryzen 5 5600X + NVIDIA GeForce RTX 3090, Windows 11).
// It does NOT access Cyrus Scatter repository files or 3ds Max 2027 internals.

#define NOMINMAX
#include <windows.h>
#include <d3d11.h>
#include <d3dcompiler.h>
#include <dxgi.h>
#include <cuda.h>
#include <cuda_runtime_api.h>
#include <cuda_d3d11_interop.h>
#include <nvrtc.h>

#include <cstdio>
#include <cstdlib>
#include <cstdint>
#include <cmath>
#include <cstring>
#include <vector>
#include <string>
#include <algorithm>
#include <thread>
#include <atomic>
#include <chrono>

#include "common.h"

#pragma comment(lib, "d3d11.lib")
#pragma comment(lib, "d3dcompiler.lib")
#pragma comment(lib, "dxgi.lib")
#pragma comment(lib, "cudart.lib")
#pragma comment(lib, "cuda.lib")
#pragma comment(lib, "nvrtc.lib")

struct float4_pod { float x, y, z, w; };
inline float4_pod mf4(float x, float y, float z, float w) { return float4_pod{x, y, z, w}; }

// ============================================================================
// 1. CUDA Kernel Source (compiled via NVRTC with fit_core.h embedded)
// ============================================================================
static const char* kCudaKernelHeader = R"CU(
extern "C" {

struct float4_t { float x, y, z, w; };
__device__ __forceinline__ float4_t make_f4(float x, float y, float z, float w) {
    float4_t r; r.x = x; r.y = y; r.z = z; r.w = w; return r;
}
)CU";

static const char* kCudaKernelBody = R"CU(
// Mapping A: 1 thread per plant (loops sequentially over G=451 guides)
__global__ void kFitThreadPerPlant_fp32(
    const float4_t* __restrict__ rest,
    const float4_t* __restrict__ gsphere,
    const float4_t* __restrict__ inst,
    int G, int Nn, int K, int iters, float kBend,
    float4_t capA, float4_t capB,
    float4_t* __restrict__ outPoses,
    int* __restrict__ activeCount)
{
    int k = blockIdx.x * blockDim.x + threadIdx.x;
    if (k >= K) return;
    lcap C = toLocal(inst[k], capA, capB);
    int localActive = 0;
    for (int g = 0; g < G; ++g) {
        if (!guideNear(gsphere[g], C)) continue;
        r3 p[FC_MAXN];
        float res = fitGuide(rest, G, Nn, g, C, iters, kBend, p);
        localActive++;
        size_t base = ((size_t)k * G + g) * Nn;
        for (int i = 0; i < Nn; ++i) {
            outPoses[base + i] = make_f4(p[i].x, p[i].y, p[i].z, (i == 0) ? res : 0.0f);
        }
    }
    if (localActive > 0) atomicAdd(activeCount, localActive);
}

// Mapping B: 1 thread per guide (K * G threads)
__global__ void kFitThreadPerGuide_fp32(
    const float4_t* __restrict__ rest,
    const float4_t* __restrict__ gsphere,
    const float4_t* __restrict__ inst,
    int G, int Nn, int K, int iters, float kBend,
    float4_t capA, float4_t capB,
    float4_t* __restrict__ outPoses,
    int* __restrict__ activeCount,
    int compactOut)
{
    int tid = blockIdx.x * blockDim.x + threadIdx.x;
    int total = K * G;
    if (tid >= total) return;
    int k = tid / G;
    int g = tid - k * G;
    lcap C = toLocal(inst[k], capA, capB);
    if (!guideNear(gsphere[g], C)) return;
    r3 p[FC_MAXN];
    float res = fitGuide(rest, G, Nn, g, C, iters, kBend, p);
    int slot = compactOut ? atomicAdd(activeCount, 1) : tid;
    size_t base = (size_t)slot * Nn;
    for (int i = 0; i < Nn; ++i) {
        outPoses[base + i] = make_f4(p[i].x, p[i].y, p[i].z, (i == 0) ? __int_as_float(tid) : res);
    }
}

// Mapping C: Two-stage (Stage 1: broadphase + atomic queue; Stage 2: compact solve)
__global__ void kBroadphaseQueue_fp32(
    const float4_t* __restrict__ gsphere,
    const float4_t* __restrict__ inst,
    int G, int K, float4_t capA, float4_t capB,
    int* __restrict__ activeQueue,
    int* __restrict__ activeCount)
{
    int tid = blockIdx.x * blockDim.x + threadIdx.x;
    int total = K * G;
    if (tid >= total) return;
    int k = tid / G;
    int g = tid - k * G;
    lcap C = toLocal(inst[k], capA, capB);
    if (guideNear(gsphere[g], C)) {
        int slot = atomicAdd(activeCount, 1);
        activeQueue[slot] = tid;
    }
}

__global__ void kSolveCompactQueue_fp32(
    const float4_t* __restrict__ rest,
    const float4_t* __restrict__ inst,
    int G, int Nn, int iters, float kBend,
    float4_t capA, float4_t capB,
    const int* __restrict__ activeQueue,
    const int* __restrict__ activeCountPtr,
    float4_t* __restrict__ outPoses)
{
    int idx = blockIdx.x * blockDim.x + threadIdx.x;
    int count = *activeCountPtr;
    if (idx >= count) return;
    int tid = activeQueue[idx];
    int k = tid / G;
    int g = tid - k * G;
    lcap C = toLocal(inst[k], capA, capB);
    r3 p[FC_MAXN];
    float res = fitGuide(rest, G, Nn, g, C, iters, kBend, p);
    size_t base = (size_t)idx * Nn;
    for (int i = 0; i < Nn; ++i) {
        outPoses[base + i] = make_f4(p[i].x, p[i].y, p[i].z, (i == 0) ? __int_as_float(tid) : res);
    }
}

// GPU Vertex/Normal Deformation kernel (K_active * V_source threads)
__global__ void kDeformMesh_fp32(
    const float4_t* __restrict__ rest,
    const float4_t* __restrict__ posedDense,
    const int* __restrict__ bindG,
    const int* __restrict__ bindS,
    const float* __restrict__ bindT,
    const float4_t* __restrict__ vOff,
    const float4_t* __restrict__ vNrm,
    int G, int Nn, int V, int K,
    float4_t* __restrict__ outVertices)
{
    int tid = blockIdx.x * blockDim.x + threadIdx.x;
    int total = K * V;
    if (tid >= total) return;
    int k = tid / V;
    int v = tid - k * V;
    int g = bindG[v];
    int s = bindS[v];
    float t = bindT[v];
    float4_t r0 = rest[(s - 1) * G + g];
    float4_t r1 = rest[s * G + g];
    size_t pbase = ((size_t)k * G + g) * Nn;
    float4_t b0f = posedDense[pbase + (s - 1)];
    float4_t b1f = posedDense[pbase + s];
    r3 a0 = node3(r0), a1 = node3(r1);
    bool isRest = (b1f.x == 0.f && b1f.y == 0.f && b1f.z == 0.f);
    r3 b0 = isRest ? a0 : node3(b0f);
    r3 b1 = isRest ? a1 : node3(b1f);
    r3 pos, nrm;
    deformVtx(a0, a1, b0, b1, t, vOff[v], vNrm[v], &pos, &nrm);
    unsigned pn = packN(nrm);
    outVertices[tid] = make_f4(pos.x, pos.y, pos.z, __uint_as_float(pn));
}

} // extern "C"
)CU";

static const char* kCudaFp64Source = R"CU(
extern "C" {
struct float4_t { float x, y, z, w; };
__device__ __forceinline__ float4_t make_f4(float x, float y, float z, float w) {
    float4_t r; r.x = x; r.y = y; r.z = z; r.w = w; return r;
}
#define DEV __device__ __forceinline__
#define GLOBAL
#define REAL double
#define F4 float4_t
#define SQRT sqrt
#define COS cos
#define SIN sin
)CU";

static const char* kCudaFp64Entry = R"CU(
__global__ void kFitThreadPerGuide_fp64(
    const float4_t* __restrict__ rest,
    const float4_t* __restrict__ gsphere,
    const float4_t* __restrict__ inst,
    int G, int Nn, int K, int iters, double kBend,
    float4_t capA, float4_t capB,
    float4_t* __restrict__ outPoses,
    int* __restrict__ activeCount)
{
    int tid = blockIdx.x * blockDim.x + threadIdx.x;
    int total = K * G;
    if (tid >= total) return;
    int k = tid / G;
    int g = tid - k * G;
    lcap C = toLocal(inst[k], capA, capB);
    if (!guideNear(gsphere[g], C)) return;
    r3 p[FC_MAXN];
    double res = fitGuide(rest, G, Nn, g, C, iters, kBend, p);
    size_t base = (size_t)tid * Nn;
    for (int i = 0; i < Nn; ++i) {
        outPoses[base + i] = make_f4((float)p[i].x, (float)p[i].y, (float)p[i].z, (float)res);
    }
}
} // extern "C"
)CU";

// ============================================================================
// 2. OpenCL Dynamic Loader
// ============================================================================
typedef int32_t cl_int;
typedef uint32_t cl_uint;
typedef uint64_t cl_ulong;
typedef struct _cl_platform_id* cl_platform_id;
typedef struct _cl_device_id* cl_device_id;
typedef struct _cl_context* cl_context;
typedef struct _cl_command_queue* cl_command_queue;
typedef struct _cl_mem* cl_mem;
typedef struct _cl_program* cl_program;
typedef struct _cl_kernel* cl_kernel;
typedef struct _cl_event* cl_event;

#define CL_DEVICE_TYPE_GPU 4
#define CL_MEM_READ_ONLY (1 << 2)
#define CL_MEM_WRITE_ONLY (1 << 1)
#define CL_MEM_READ_WRITE (1 << 0)
#define CL_MEM_COPY_HOST_PTR (1 << 5)
#define CL_QUEUE_PROFILING_ENABLE (1 << 1)
#define CL_PROFILING_COMMAND_START 0x1282
#define CL_PROFILING_COMMAND_END 0x1283
#define CL_DEVICE_NAME 0x102B
#define CL_DEVICE_VERSION 0x102F
#define CL_DRIVER_VERSION 0x102D
#define CL_DEVICE_EXTENSIONS 0x1030
#define CL_PROGRAM_BUILD_LOG 0x1183

struct OpenCLApi {
    HMODULE dll = nullptr;
    cl_int (WINAPI *clGetPlatformIDs)(cl_uint, cl_platform_id*, cl_uint*) = nullptr;
    cl_int (WINAPI *clGetDeviceIDs)(cl_platform_id, uint64_t, cl_uint, cl_device_id*, cl_uint*) = nullptr;
    cl_int (WINAPI *clGetDeviceInfo)(cl_device_id, cl_uint, size_t, void*, size_t*) = nullptr;
    cl_context (WINAPI *clCreateContext)(const void*, cl_uint, const cl_device_id*, void*, void*, cl_int*) = nullptr;
    cl_command_queue (WINAPI *clCreateCommandQueue)(cl_context, cl_device_id, uint64_t, cl_int*) = nullptr;
    cl_mem (WINAPI *clCreateBuffer)(cl_context, uint64_t, size_t, void*, cl_int*) = nullptr;
    cl_program (WINAPI *clCreateProgramWithSource)(cl_context, cl_uint, const char**, const size_t*, cl_int*) = nullptr;
    cl_int (WINAPI *clBuildProgram)(cl_program, cl_uint, const cl_device_id*, const char*, void*, void*) = nullptr;
    cl_int (WINAPI *clGetProgramBuildInfo)(cl_program, cl_device_id, cl_uint, size_t, void*, size_t*) = nullptr;
    cl_kernel (WINAPI *clCreateKernel)(cl_program, const char*, cl_int*) = nullptr;
    cl_int (WINAPI *clSetKernelArg)(cl_kernel, cl_uint, size_t, const void*) = nullptr;
    cl_int (WINAPI *clEnqueueWriteBuffer)(cl_command_queue, cl_mem, cl_uint, size_t, size_t, const void*, cl_uint, const cl_event*, cl_event*) = nullptr;
    cl_int (WINAPI *clEnqueueReadBuffer)(cl_command_queue, cl_mem, cl_uint, size_t, size_t, void*, cl_uint, const cl_event*, cl_event*) = nullptr;
    cl_int (WINAPI *clEnqueueNDRangeKernel)(cl_command_queue, cl_kernel, cl_uint, const size_t*, const size_t*, const size_t*, cl_uint, const cl_event*, cl_event*) = nullptr;
    cl_int (WINAPI *clFinish)(cl_command_queue) = nullptr;
    cl_int (WINAPI *clGetEventProfilingInfo)(cl_event, cl_uint, size_t, void*, size_t*) = nullptr;
    cl_int (WINAPI *clReleaseEvent)(cl_event) = nullptr;
    cl_int (WINAPI *clReleaseMemObject)(cl_mem) = nullptr;

    bool load() {
        dll = LoadLibraryA("OpenCL.dll");
        if (!dll) return false;
        #define BIND(fn) fn = (decltype(fn))GetProcAddress(dll, #fn); if (!fn) return false
        BIND(clGetPlatformIDs); BIND(clGetDeviceIDs); BIND(clGetDeviceInfo);
        BIND(clCreateContext); BIND(clCreateCommandQueue); BIND(clCreateBuffer);
        BIND(clCreateProgramWithSource); BIND(clBuildProgram); BIND(clGetProgramBuildInfo);
        BIND(clCreateKernel); BIND(clSetKernelArg); BIND(clEnqueueWriteBuffer);
        BIND(clEnqueueReadBuffer); BIND(clEnqueueNDRangeKernel); BIND(clFinish);
        BIND(clGetEventProfilingInfo); BIND(clReleaseEvent); BIND(clReleaseMemObject);
        #undef BIND
        return true;
    }
};

static const char* kOpenCLKernelWrapper = R"CLC(
#define DEV inline
#define GLOBAL __global
#define REAL float
#define F4 float4
#define SQRT sqrt
#define COS cos
#define SIN sin
)CLC";

static const char* kOpenCLKernelEntry = R"CLC(
__kernel void kFitThreadPerGuide_cl(
    __global const float4* rest,
    __global const float4* gsphere,
    __global const float4* inst,
    int G, int Nn, int K, int iters, float kBend,
    float4 capA, float4 capB,
    __global float4* outPoses,
    volatile __global int* activeCount,
    int compactOut)
{
    int tid = (int)get_global_id(0);
    int total = K * G;
    if (tid >= total) return;
    int k = tid / G;
    int g = tid - k * G;
    lcap C = toLocal(inst[k], capA, capB);
    if (!guideNear(gsphere[g], C)) return;
    r3 p[FC_MAXN];
    float res = fitGuide(rest, G, Nn, g, C, iters, kBend, p);
    int slot = compactOut ? atomic_inc(activeCount) : tid;
    int base = slot * Nn;
    for (int i = 0; i < Nn; ++i) {
        outPoses[base + i] = (float4)(p[i].x, p[i].y, p[i].z, (i == 0) ? as_float(tid) : res);
    }
}
)CLC";

// ============================================================================
// 3. HLSL Compute Shader Source (cs_5_0) for Direct3D 11 comparison
// ============================================================================
static const char* kHlslCs50Source = R"HLSL(
cbuffer Params : register(b0) {
    int G; int Nn; int K; int iters;
    float kBend; int compactOut; int pad0; int pad1;
    float4 capA;
    float4 capB;
};
StructuredBuffer<float4> rest : register(t0);
StructuredBuffer<float4> gsphere : register(t1);
StructuredBuffer<float4> inst : register(t2);
RWStructuredBuffer<float4> outPoses : register(u0);
RWByteAddressBuffer activeCountBuf : register(u1);

float3 closestOnSeg(float3 p, float3 a, float3 b) {
    float3 ab = b - a;
    float den = dot(ab, ab);
    float t = (den > 0.0f) ? (dot(p - a, ab) / den) : 0.0f;
    t = clamp(t, 0.0f, 1.0f);
    return a + ab * t;
}

[numthreads(256, 1, 1)]
void CSMain(uint3 dtid : SV_DispatchThreadID) {
    uint tid = dtid.x;
    uint total = (uint)(K * G);
    if (tid >= total) return;
    int k = (int)(tid / (uint)G);
    int g = (int)(tid - (uint)k * (uint)G);

    float4 ins = inst[k];
    float c = cos(ins.z), s = sin(ins.z), invS = 1.0f / ins.w;
    float dxA = capA.x - ins.x, dzA = capA.z - ins.y;
    float3 ca = float3((c * dxA + s * dzA) * invS, capA.y * invS, (-s * dxA + c * dzA) * invS);
    float dxB = capB.x - ins.x, dzB = capB.z - ins.y;
    float3 cb = float3((c * dxB + s * dzB) * invS, capB.y * invS, (-s * dxB + c * dzB) * invS);
    float rad = (capA.w + capB.w) * invS;

    float4 sph = gsphere[g];
    float3 d0 = sph.xyz - closestOnSeg(sph.xyz, ca, cb);
    float lim = rad + sph.w;
    if (dot(d0, d0) >= lim * lim) return;

    float3 p[8];
    [unroll] for (int i = 0; i < 8; ++i) p[i] = rest[i * G + g].xyz;

    for (int it = 0; it < iters; ++it) {
        for (int i = 1; i < 8; ++i) {
            float4 q0 = rest[(i - 1) * G + g];
            float4 q1 = rest[i * G + g];
            float3 rd = q1.xyz - q0.xyz;
            float3 target = p[i - 1] + rd;
            p[i] = p[i] + (target - p[i]) * kBend;
            float3 cp = closestOnSeg(p[i], ca, cb);
            float3 d = p[i] - cp;
            float dist = sqrt(dot(d, d));
            if (dist < rad) {
                float3 n = (dist > 1e-12f) ? (d / dist) : float3(0.0f, 1.0f, 0.0f);
                p[i] = cp + n * rad;
            }
            float3 e = p[i] - p[i - 1];
            float el = sqrt(dot(e, e));
            p[i] = (el > 1e-12f) ? (p[i - 1] + e * (q1.w / el)) : (p[i - 1] + rd);
        }
    }
    float res = 0.0f;
    for (int i = 1; i < 8; ++i) {
        float3 m = 0.5f * (p[i] + p[i - 1]);
        float3 d1 = p[i] - closestOnSeg(p[i], ca, cb);
        float3 d2 = m - closestOnSeg(m, ca, cb);
        res = max(res, max(rad - sqrt(dot(d1, d1)), rad - sqrt(dot(d2, d2))));
    }
    uint slot = tid;
    if (compactOut != 0) {
        activeCountBuf.InterlockedAdd(0, 1, slot);
    }
    uint base = slot * (uint)Nn;
    [unroll] for (int i = 0; i < 8; ++i) {
        outPoses[base + (uint)i] = float4(p[i], (i == 0) ? asfloat(tid) : res);
    }
}
)HLSL";

// ============================================================================
// 4. CPU Reference & Multi-threaded Benchmark
// ============================================================================
double runCpuSolve(const Workload& w, int numThreads, bool useDouble, std::vector<float4_pod>& outDense, int& totalActiveOut) {
    int K = w.K, G = w.G, Nn = w.Nn, iters = w.iters;
    std::atomic<int> nextK{0};
    std::atomic<int> activeTotal{0};

    auto worker = [&]() {
        int localAct = 0;
        while (true) {
            int k = nextK.fetch_add(1, std::memory_order_relaxed);
            if (k >= K) break;
            if (!useDouble) {
                LocalCap<float> C = toLocal<float>(w.inst[k], w.capA, w.capB);
                V3<float> p[16];
                for (int g = 0; g < G; ++g) {
                    if (!guideNear<float>(w.gsphere[g], C)) continue;
                    float res = fitGuide<float>(w.rest.data(), G, Nn, g, C, iters, w.kBend, p);
                    localAct++;
                    size_t base = ((size_t)k * G + g) * Nn;
                    for (int i = 0; i < Nn; ++i)
                        outDense[base + i] = mf4(p[i].x, p[i].y, p[i].z, res);
                }
            } else {
                LocalCap<double> C = toLocal<double>(w.inst[k], w.capA, w.capB);
                V3<double> p[16];
                for (int g = 0; g < G; ++g) {
                    if (!guideNear<double>(w.gsphere[g], C)) continue;
                    double res = fitGuide<double>(w.rest.data(), G, Nn, g, C, iters, (double)w.kBend, p);
                    localAct++;
                    size_t base = ((size_t)k * G + g) * Nn;
                    for (int i = 0; i < Nn; ++i)
                        outDense[base + i] = mf4((float)p[i].x, (float)p[i].y, (float)p[i].z, (float)res);
                }
            }
        }
        activeTotal.fetch_add(localAct, std::memory_order_relaxed);
    };

    double t0 = nowMs();
    if (numThreads <= 1) {
        worker();
    } else {
        std::vector<std::thread> threads;
        threads.reserve(numThreads);
        for (int t = 0; t < numThreads; ++t) threads.emplace_back(worker);
        for (auto& th : threads) th.join();
    }
    double t1 = nowMs();
    totalActiveOut = activeTotal.load();
    return t1 - t0;
}

static std::string compileToPtx(const char* src, const char* name, double& outMs) {
    nvrtcProgram prog{};
    double t0 = nowMs();
    nvrtcCreateProgram(&prog, src, name, 0, nullptr, nullptr);
    const char* opts[] = { "--gpu-architecture=compute_86", "-default-device" };
    nvrtcResult res = nvrtcCompileProgram(prog, 2, opts);
    double t1 = nowMs();
    outMs = t1 - t0;
    if (res != NVRTC_SUCCESS) {
        size_t logSz = 0; nvrtcGetProgramLogSize(prog, &logSz);
        std::string log(logSz, '\0'); nvrtcGetProgramLog(prog, &log[0]);
        printf("NVRTC compile error (%s):\n%s\n", name, log.c_str());
        nvrtcDestroyProgram(&prog);
        return {};
    }
    size_t ptxSz = 0; nvrtcGetPTXSize(prog, &ptxSz);
    std::string ptx(ptxSz, '\0'); nvrtcGetPTX(prog, &ptx[0]);
    nvrtcDestroyProgram(&prog);
    return ptx;
}

int main() {
    printf("================================================================================\n");
    printf("Cyrus Scatter GPU Interaction Research - Standalone Synthetic Benchmark & Probe\n");
    printf("================================================================================\n");

    cuInit(0);
    cudaFree(0); // ensure primary context is active on device 0

    // 1. Query CUDA Device Properties
    cudaDeviceProp prop{};
    cudaGetDeviceProperties(&prop, 0);
    int driverVer = 0, runtimeVer = 0;
    cudaDriverGetVersion(&driverVer);
    cudaRuntimeGetVersion(&runtimeVer);
    int concManaged = 0, pageMemAccess = 0;
    cudaDeviceGetAttribute(&concManaged, cudaDevAttrConcurrentManagedAccess, 0);
    cudaDeviceGetAttribute(&pageMemAccess, cudaDevAttrPageableMemoryAccess, 0);

    printf("\n[1] CUDA DEVICE & WINDOWS WDDM ATTRIBUTES\n");
    printf("  Host Compiler (_MSC_FULL_VER): %d\n", _MSC_FULL_VER);
    printf("  Device Name                  : %s\n", prop.name);
    printf("  Compute Capability           : %d.%d\n", prop.major, prop.minor);
    printf("  SM Count                     : %d\n", prop.multiProcessorCount);
    printf("  Global Memory                : %.2f MiB\n", prop.totalGlobalMem / (1024.0 * 1024.0));
    printf("  Memory Bus Width             : %d-bit\n", prop.memoryBusWidth);
    printf("  CUDA Driver / Runtime Ver    : %d / %d\n", driverVer, runtimeVer);
    printf("  concurrentManagedAccess      : %d (0 = Windows WDDM no fine-grained page fault concurrency)\n", concManaged);
    printf("  pageableMemoryAccess         : %d\n", pageMemAccess);
    LUID cudaLuid{};
    memcpy(&cudaLuid, prop.luid, sizeof(LUID));
    printf("  Adapter LUID (CUDA)          : %08lx:%08lx (nodeMask=0x%x)\n",
           (unsigned long)cudaLuid.HighPart, (unsigned long)cudaLuid.LowPart, prop.luidDeviceNodeMask);

    // Read fit_core.h and compile CUDA modules via NVRTC
    FILE* fc = fopen("fit_core.h", "rb");
    std::string coreSrc;
    if (fc) {
        fseek(fc, 0, SEEK_END); size_t sz = ftell(fc); fseek(fc, 0, SEEK_SET);
        coreSrc.resize(sz); fread(&coreSrc[0], 1, sz, fc); fclose(fc);
    }
    std::string cuSrc32 = std::string(kCudaKernelHeader)
        + "\n#define DEV __device__ __forceinline__\n#define GLOBAL\n#define REAL float\n#define F4 float4_t\n#define SQRT sqrtf\n#define COS cosf\n#define SIN sinf\n"
        + coreSrc + "\n" + kCudaKernelBody;
    std::string cuSrc64 = std::string(kCudaFp64Source) + "\n" + coreSrc + "\n" + kCudaFp64Entry;

    double nvrtcMs32 = 0, nvrtcMs64 = 0;
    std::string ptx32 = compileToPtx(cuSrc32.c_str(), "fit_fp32.cu", nvrtcMs32);
    std::string ptx64 = compileToPtx(cuSrc64.c_str(), "fit_fp64.cu", nvrtcMs64);

    CUmodule mod32 = nullptr, mod64 = nullptr;
    CUfunction fnPlant32 = nullptr, fnGuide32 = nullptr, fnBroad32 = nullptr, fnCompact32 = nullptr, fnDeform32 = nullptr, fnGuide64 = nullptr;
    double tLoad0 = nowMs();
    cuModuleLoadData(&mod32, ptx32.c_str());
    cuModuleLoadData(&mod64, ptx64.c_str());
    double tLoad1 = nowMs();
    cuModuleGetFunction(&fnPlant32, mod32, "kFitThreadPerPlant_fp32");
    cuModuleGetFunction(&fnGuide32, mod32, "kFitThreadPerGuide_fp32");
    cuModuleGetFunction(&fnBroad32, mod32, "kBroadphaseQueue_fp32");
    cuModuleGetFunction(&fnCompact32, mod32, "kSolveCompactQueue_fp32");
    cuModuleGetFunction(&fnDeform32, mod32, "kDeformMesh_fp32");
    cuModuleGetFunction(&fnGuide64, mod64, "kFitThreadPerGuide_fp64");
    printf("  NVRTC Compile (FP32 / FP64)  : %.2f ms / %.2f ms (PTX JIT cuModuleLoadData: %.2f ms)\n",
           nvrtcMs32, nvrtcMs64, tLoad1 - tLoad0);

    // 2. D3D11 + CUDA Graphics & Buffer Binding Probe
    printf("\n[2] DIRECT3D 11 & CUDA INTEROP / BUFFER BINDING PROBE\n");
    ID3D11Device* d3dDev = nullptr;
    ID3D11DeviceContext* d3dCtx = nullptr;
    D3D_FEATURE_LEVEL flOut{};
    D3D_FEATURE_LEVEL fls[] = { D3D_FEATURE_LEVEL_11_1, D3D_FEATURE_LEVEL_11_0 };
    HRESULT hr = D3D11CreateDevice(nullptr, D3D_DRIVER_TYPE_HARDWARE, nullptr, 0,
                                   fls, 2, D3D11_SDK_VERSION, &d3dDev, &flOut, &d3dCtx);
    if (SUCCEEDED(hr)) {
        IDXGIDevice* dxgiDev = nullptr;
        IDXGIAdapter* adapter = nullptr;
        d3dDev->QueryInterface(__uuidof(IDXGIDevice), (void**)&dxgiDev);
        dxgiDev->GetAdapter(&adapter);
        DXGI_ADAPTER_DESC adesc{};
        adapter->GetDesc(&adesc);
        printf("  D3D11 Adapter Description    : %ls\n", adesc.Description);
        printf("  D3D11 Adapter LUID           : %08lx:%08lx (Matches CUDA LUID: %s)\n",
               (unsigned long)adesc.AdapterLuid.HighPart, (unsigned long)adesc.AdapterLuid.LowPart,
               (adesc.AdapterLuid.HighPart == cudaLuid.HighPart && adesc.AdapterLuid.LowPart == cudaLuid.LowPart) ? "YES" : "NO");

        auto testCreateBuf = [&](UINT bindFlags, UINT miscFlags, D3D11_USAGE usage, UINT cpuAccess, UINT stride, const char* label) {
            D3D11_BUFFER_DESC bd{};
            bd.ByteWidth = 1024 * 64;
            bd.Usage = usage;
            bd.BindFlags = bindFlags;
            bd.CPUAccessFlags = cpuAccess;
            bd.MiscFlags = miscFlags;
            bd.StructureByteStride = stride;
            ID3D11Buffer* buf = nullptr;
            HRESULT h = d3dDev->CreateBuffer(&bd, nullptr, &buf);
            printf("  CreateBuffer %-48s : %s (HRESULT=0x%08lx)\n", label, SUCCEEDED(h) ? "SUCCESS" : "REJECTED", (unsigned long)h);
            if (buf) buf->Release();
        };
        testCreateBuf(D3D11_BIND_VERTEX_BUFFER | D3D11_BIND_UNORDERED_ACCESS, D3D11_RESOURCE_MISC_BUFFER_STRUCTURED,
                      D3D11_USAGE_DEFAULT, 0, 16, "VB + UAV + STRUCTURED (D3D11 spec conflict)");
        testCreateBuf(D3D11_BIND_VERTEX_BUFFER | D3D11_BIND_UNORDERED_ACCESS | D3D11_BIND_SHADER_RESOURCE,
                      D3D11_RESOURCE_MISC_BUFFER_ALLOW_RAW_VIEWS, D3D11_USAGE_DEFAULT, 0, 0,
                      "VB + UAV + SRV + ALLOW_RAW_VIEWS");
        testCreateBuf(D3D11_BIND_VERTEX_BUFFER | D3D11_BIND_UNORDERED_ACCESS, 0,
                      D3D11_USAGE_DEFAULT, 0, 0, "VB + UAV (Typed UAV)");
        testCreateBuf(D3D11_BIND_SHADER_RESOURCE | D3D11_BIND_UNORDERED_ACCESS, D3D11_RESOURCE_MISC_BUFFER_STRUCTURED,
                      D3D11_USAGE_DEFAULT, 0, 16, "SRV + UAV + STRUCTURED (VS pulls via SRV)");

        // Measure CUDA-D3D11 Register / Map / Unmap overhead on a 8 MiB Vertex Buffer
        D3D11_BUFFER_DESC vbd{};
        vbd.ByteWidth = 8 * 1024 * 1024;
        vbd.Usage = D3D11_USAGE_DEFAULT;
        vbd.BindFlags = D3D11_BIND_VERTEX_BUFFER;
        ID3D11Buffer* sharedVB = nullptr;
        if (SUCCEEDED(d3dDev->CreateBuffer(&vbd, nullptr, &sharedVB))) {
            cudaGraphicsResource* cudaRes = nullptr;
            double tReg0 = nowMs();
            cudaError_t cerr = cudaGraphicsD3D11RegisterResource(&cudaRes, sharedVB, cudaGraphicsRegisterFlagsNone);
            double tReg1 = nowMs();
            printf("  cudaGraphicsD3D11RegisterResource (8 MiB DEFAULT VB) : %s (%.3f ms)\n",
                   cudaGetErrorString(cerr), tReg1 - tReg0);
            if (cerr == cudaSuccess) {
                cudaGraphicsResourceSetMapFlags(cudaRes, cudaGraphicsMapFlagsWriteDiscard);
                for (int i = 0; i < 10; ++i) {
                    cudaGraphicsMapResources(1, &cudaRes, 0);
                    void* devPtr = nullptr; size_t sz = 0;
                    cudaGraphicsResourceGetMappedPointer(&devPtr, &sz, cudaRes);
                    cudaGraphicsUnmapResources(1, &cudaRes, 0);
                }
                cudaDeviceSynchronize();
                std::vector<double> mapTimes;
                for (int i = 0; i < 200; ++i) {
                    double m0 = nowMs();
                    cudaGraphicsMapResources(1, &cudaRes, 0);
                    void* devPtr = nullptr; size_t sz = 0;
                    cudaGraphicsResourceGetMappedPointer(&devPtr, &sz, cudaRes);
                    cudaGraphicsUnmapResources(1, &cudaRes, 0);
                    cudaStreamSynchronize(0);
                    mapTimes.push_back((nowMs() - m0) * 1000.0);
                }
                Stats ms = stats(mapTimes);
                printf("  Map+GetPointer+Unmap+Sync latency (200 iters, us)    : p50=%.1f us, p95=%.1f us, p99=%.1f us\n",
                       ms.p50, ms.p95, ms.p99);
                cudaGraphicsUnregisterResource(cudaRes);
            }
            sharedVB->Release();
        }
        adapter->Release();
        dxgiDev->Release();
    }

    // 3. Load OpenCL and inspect platform/device/extensions + build time
    printf("\n[3] OPENCL PLATFORM & EXTENSION PROBE ON SAME GPU\n");
    OpenCLApi cl;
    bool hasCL = cl.load();
    cl_platform_id clPlat = nullptr;
    cl_device_id clDev = nullptr;
    cl_context clCtx = nullptr;
    cl_command_queue clQ = nullptr;
    cl_kernel clKern = nullptr;
    if (hasCL) {
        cl_uint numP = 0;
        cl.clGetPlatformIDs(1, &clPlat, &numP);
        cl_uint numD = 0;
        cl.clGetDeviceIDs(clPlat, CL_DEVICE_TYPE_GPU, 1, &clDev, &numD);
        char dname[256]{}, dver[256]{}, drv[256]{};
        std::vector<char> exts(16384, 0);
        cl.clGetDeviceInfo(clDev, CL_DEVICE_NAME, sizeof(dname), dname, nullptr);
        cl.clGetDeviceInfo(clDev, CL_DEVICE_VERSION, sizeof(dver), dver, nullptr);
        cl.clGetDeviceInfo(clDev, CL_DRIVER_VERSION, sizeof(drv), drv, nullptr);
        cl.clGetDeviceInfo(clDev, CL_DEVICE_EXTENSIONS, exts.size(), exts.data(), nullptr);
        std::string extStr(exts.data());
        printf("  OpenCL Device Name           : %s\n", dname);
        printf("  OpenCL Version / Driver      : %s / %s\n", dver, drv);
        auto hasExt = [&](const char* e) { return extStr.find(e) != std::string::npos ? "YES" : "NO"; };
        printf("  cl_khr_d3d11_sharing         : %s\n", hasExt("cl_khr_d3d11_sharing"));
        printf("  cl_nv_d3d11_sharing          : %s\n", hasExt("cl_nv_d3d11_sharing"));
        printf("  cl_khr_external_memory       : %s\n", hasExt("cl_khr_external_memory"));
        printf("  cl_khr_external_semaphore    : %s\n", hasExt("cl_khr_external_semaphore"));
        printf("  cl_khr_subgroups             : %s\n", hasExt("cl_khr_subgroups"));
        printf("  cl_khr_fp64                  : %s\n", hasExt("cl_khr_fp64"));
        printf("  cl_khr_il_program (SPIR-V)   : %s\n", hasExt("cl_khr_il_program"));

        std::string fullClSrc = std::string(kOpenCLKernelWrapper) + "\n" + coreSrc + "\n" + kOpenCLKernelEntry;
        const char* srcPtr = fullClSrc.c_str();
        size_t srcLen = fullClSrc.size();
        cl_int err = 0;
        clCtx = cl.clCreateContext(nullptr, 1, &clDev, nullptr, nullptr, &err);
        clQ = cl.clCreateCommandQueue(clCtx, clDev, CL_QUEUE_PROFILING_ENABLE, &err);
        double tb0 = nowMs();
        cl_program prog = cl.clCreateProgramWithSource(clCtx, 1, &srcPtr, &srcLen, &err);
        err = cl.clBuildProgram(prog, 1, &clDev, "-cl-std=CL1.2", nullptr, nullptr);
        double tb1 = nowMs();
        printf("  OpenCL clBuildProgram time   : %.3f ms (err=%d)\n", tb1 - tb0, err);
        if (err != 0) {
            std::vector<char> blog(8192, 0);
            cl.clGetProgramBuildInfo(prog, clDev, CL_PROGRAM_BUILD_LOG, blog.size(), blog.data(), nullptr);
            printf("  OpenCL Build Log:\n%s\n", blog.data());
        } else {
            clKern = cl.clCreateKernel(prog, "kFitThreadPerGuide_cl", &err);
        }
    }

    // 4. Compile HLSL cs_5_0 shader for D3D11 compute benchmark
    ID3D11ComputeShader* d3dCs = nullptr;
    ID3DBlob* csBlob = nullptr;
    ID3DBlob* errBlob = nullptr;
    double th0 = nowMs();
    HRESULT hrCs = D3DCompile(kHlslCs50Source, strlen(kHlslCs50Source), "fit_cs.hlsl",
                              nullptr, nullptr, "CSMain", "cs_5_0", D3DCOMPILE_OPTIMIZATION_LEVEL3, 0, &csBlob, &errBlob);
    double th1 = nowMs();
    if (SUCCEEDED(hrCs) && d3dDev) {
        d3dDev->CreateComputeShader(csBlob->GetBufferPointer(), csBlob->GetBufferSize(), nullptr, &d3dCs);
        printf("  HLSL D3DCompile (cs_5_0 O3)  : %.3f ms (blob=%zu bytes)\n", th1 - th0, csBlob->GetBufferSize());
    } else if (errBlob) {
        printf("  HLSL Compile Error: %s\n", (const char*)errBlob->GetBufferPointer());
    }

    // ========================================================================
    // 5. Mapping & Precision Comparison at K = 1,000 candidate plants (451,000 guides)
    // ========================================================================
    printf("\n[4] THREAD MAPPING & PRECISION COMPARISON (K=1000 plants, G=451 guides, Nn=8, iters=8)\n");
    {
        Workload w;
        w.K = 1000; w.G = 451; w.Nn = 8; w.iters = 8;
        w.build();

        void *dRest = nullptr, *dSph = nullptr, *dInst = nullptr, *dOut = nullptr, *dOut64 = nullptr;
        void *dAct = nullptr, *dQueue = nullptr;
        cudaMalloc(&dRest, w.rest.size() * 16);
        cudaMalloc(&dSph, w.gsphere.size() * 16);
        cudaMalloc(&dInst, w.inst.size() * 16);
        cudaMalloc(&dOut, (size_t)w.K * w.G * w.Nn * 16);
        cudaMalloc(&dOut64, (size_t)w.K * w.G * w.Nn * 16);
        cudaMalloc(&dAct, sizeof(int));
        cudaMalloc(&dQueue, (size_t)w.K * w.G * sizeof(int));

        cudaMemcpy(dRest, w.rest.data(), w.rest.size() * 16, cudaMemcpyHostToDevice);
        cudaMemcpy(dSph, w.gsphere.data(), w.gsphere.size() * 16, cudaMemcpyHostToDevice);
        cudaMemcpy(dInst, w.inst.data(), w.inst.size() * 16, cudaMemcpyHostToDevice);

        float4_pod capA = mf4(w.capA.x, w.capA.y, w.capA.z, w.capA.w);
        float4_pod capB = mf4(w.capB.x, w.capB.y, w.capB.z, w.capB.w);

        cudaEvent_t ev0, ev1;
        cudaEventCreate(&ev0); cudaEventCreate(&ev1);

        auto benchKernel = [&](auto launchFn, const char* name) {
            for (int i = 0; i < 5; ++i) launchFn();
            cudaDeviceSynchronize();
            std::vector<double> tms;
            for (int i = 0; i < 40; ++i) {
                cudaMemsetAsync(dAct, 0, sizeof(int));
                cudaEventRecord(ev0);
                launchFn();
                cudaEventRecord(ev1);
                cudaEventSynchronize(ev1);
                float ms = 0; cudaEventElapsedTime(&ms, ev0, ev1);
                tms.push_back(ms);
            }
            int act = 0;
            cudaMemcpy(&act, dAct, sizeof(int), cudaMemcpyDeviceToHost);
            Stats s = stats(tms);
            printf("  %-44s : p50=%7.3f ms, p95=%7.3f ms (activeGuides=%d)\n", name, s.p50, s.p95, act);
        };

        benchKernel([&]() {
            int blk = 128, grd = (w.K + blk - 1) / blk;
            void* args[] = { &dRest, &dSph, &dInst, &w.G, &w.Nn, &w.K, &w.iters, &w.kBend, &capA, &capB, &dOut, &dAct };
            cuLaunchKernel(fnPlant32, grd, 1, 1, blk, 1, 1, 0, 0, args, nullptr);
        }, "CUDA 1-Thread-Per-Plant (FP32)");

        benchKernel([&]() {
            int total = w.K * w.G, blk = 256, grd = (total + blk - 1) / blk, comp = 0;
            void* args[] = { &dRest, &dSph, &dInst, &w.G, &w.Nn, &w.K, &w.iters, &w.kBend, &capA, &capB, &dOut, &dAct, &comp };
            cuLaunchKernel(fnGuide32, grd, 1, 1, blk, 1, 1, 0, 0, args, nullptr);
        }, "CUDA 1-Thread-Per-Guide Dense (FP32)");

        benchKernel([&]() {
            int total = w.K * w.G, blk = 256, grd = (total + blk - 1) / blk, comp = 1;
            void* args[] = { &dRest, &dSph, &dInst, &w.G, &w.Nn, &w.K, &w.iters, &w.kBend, &capA, &capB, &dOut, &dAct, &comp };
            cuLaunchKernel(fnGuide32, grd, 1, 1, blk, 1, 1, 0, 0, args, nullptr);
        }, "CUDA 1-Thread-Per-Guide AtomicCompact (FP32)");

        benchKernel([&]() {
            int total = w.K * w.G, blk = 256, grd = (total + blk - 1) / blk;
            void* args1[] = { &dSph, &dInst, &w.G, &w.K, &capA, &capB, &dQueue, &dAct };
            void* args2[] = { &dRest, &dInst, &w.G, &w.Nn, &w.iters, &w.kBend, &capA, &capB, &dQueue, &dAct, &dOut };
            cuLaunchKernel(fnBroad32, grd, 1, 1, blk, 1, 1, 0, 0, args1, nullptr);
            cuLaunchKernel(fnCompact32, grd, 1, 1, blk, 1, 1, 0, 0, args2, nullptr);
        }, "CUDA 2-Stage Broadphase+CompactQueue (FP32)");

        benchKernel([&]() {
            int total = w.K * w.G, blk = 256, grd = (total + blk - 1) / blk;
            double kb64 = (double)w.kBend;
            void* args[] = { &dRest, &dSph, &dInst, &w.G, &w.Nn, &w.K, &w.iters, &kb64, &capA, &capB, &dOut64, &dAct };
            cuLaunchKernel(fnGuide64, grd, 1, 1, blk, 1, 1, 0, 0, args, nullptr);
        }, "CUDA 1-Thread-Per-Guide Dense (FP64)");

        // Compare numerical accuracy: CPU FP64 vs CPU FP32 vs CUDA FP32
        std::vector<float4_pod> cpu64((size_t)w.K * w.G * w.Nn, mf4(0,0,0,0));
        std::vector<float4_pod> cpu32((size_t)w.K * w.G * w.Nn, mf4(0,0,0,0));
        int act64 = 0, act32 = 0;
        double tCpu64 = runCpuSolve(w, 12, true, cpu64, act64);
        double tCpu32 = runCpuSolve(w, 12, false, cpu32, act32);
        printf("  CPU 12-Thread FP64 Reference                 : %7.3f ms (activeGuides=%d)\n", tCpu64, act64);
        printf("  CPU 12-Thread FP32                           : %7.3f ms (activeGuides=%d)\n", tCpu32, act32);

        cudaMemset(dOut, 0, (size_t)w.K * w.G * w.Nn * 16);
        int total = w.K * w.G, blk = 256, grd = (total + blk - 1) / blk, comp = 0;
        void* args[] = { &dRest, &dSph, &dInst, &w.G, &w.Nn, &w.K, &w.iters, &w.kBend, &capA, &capB, &dOut, &dAct, &comp };
        cuLaunchKernel(fnGuide32, grd, 1, 1, blk, 1, 1, 0, 0, args, nullptr);
        std::vector<float4_pod> gpu32((size_t)w.K * w.G * w.Nn);
        cudaMemcpy(gpu32.data(), dOut, gpu32.size() * 16, cudaMemcpyDeviceToHost);

        double maxErrGpuVsCpu64 = 0.0, sumSqGpuVsCpu64 = 0.0;
        double maxErrGpuVsCpu32 = 0.0, maxRootDrift = 0.0;
        size_t nNodesChecked = 0;
        for (size_t idx = 0; idx < (size_t)w.K * w.G; ++idx) {
            if (cpu64[idx * w.Nn].x == 0.f && cpu64[idx * w.Nn + 1].x == 0.f) continue;
            int g = (int)(idx % w.G);
            F4 rRoot = w.rest[g];
            double rdx = gpu32[idx * w.Nn].x - rRoot.x;
            double rdy = gpu32[idx * w.Nn].y - rRoot.y;
            double rdz = gpu32[idx * w.Nn].z - rRoot.z;
            maxRootDrift = std::max(maxRootDrift, std::sqrt(rdx*rdx + rdy*rdy + rdz*rdz));
            for (int i = 0; i < w.Nn; ++i) {
                float4_pod a = gpu32[idx * w.Nn + i];
                float4_pod b = cpu64[idx * w.Nn + i];
                float4_pod c = cpu32[idx * w.Nn + i];
                double dx64 = a.x - b.x, dy64 = a.y - b.y, dz64 = a.z - b.z;
                double e64 = std::sqrt(dx64*dx64 + dy64*dy64 + dz64*dz64);
                maxErrGpuVsCpu64 = std::max(maxErrGpuVsCpu64, e64);
                sumSqGpuVsCpu64 += e64 * e64;
                double dx32 = a.x - c.x, dy32 = a.y - c.y, dz32 = a.z - c.z;
                double e32 = std::sqrt(dx32*dx32 + dy32*dy32 + dz32*dz32);
                maxErrGpuVsCpu32 = std::max(maxErrGpuVsCpu32, e32);
                nNodesChecked++;
            }
        }
        printf("  Max Node Error (CUDA FP32 vs CPU FP64 Ref)   : %.3e m (RMS=%.3e m over %zu nodes)\n",
               maxErrGpuVsCpu64, std::sqrt(sumSqGpuVsCpu64 / std::max<size_t>(1, nNodesChecked)), nNodesChecked);
        printf("  Max Node Error (CUDA FP32 vs CPU FP32)       : %.3e m\n", maxErrGpuVsCpu32);
        printf("  Max Root Anchor Drift (CUDA FP32)            : %.3e m\n", maxRootDrift);

        cudaEventDestroy(ev0); cudaEventDestroy(ev1);
        cudaFree(dRest); cudaFree(dSph); cudaFree(dInst); cudaFree(dOut); cudaFree(dOut64); cudaFree(dAct); cudaFree(dQueue);
    }

    // ========================================================================
    // 6. Scaling Sweep across K: CPU (1T, 8T, 12T) vs CUDA vs OpenCL vs D3D11 CS
    // ========================================================================
    printf("\n[5] WORKLOAD SCALING SWEEP (G=451 guides/plant, Nn=8 nodes, iters=8, FP32)\n");
    printf("  %6s | %6s | %8s | %8s | %8s | %9s | %10s | %9s | %9s\n",
           "K_cand", "ActGds", "CPU_1T", "CPU_8T", "CPU_12T", "CUDA_Kern", "CUDA+Xfer", "OpenCL_K", "D3D11_CS");
    printf("  -------+--------+----------+----------+----------+-----------+------------+-----------+----------\n");

    int kList[] = { 1, 3, 10, 50, 100, 500, 1000, 5000, 10000 };
    for (int K : kList) {
        Workload w;
        w.K = K; w.G = 451; w.Nn = 8; w.iters = 8;
        w.build();

        std::vector<float4_pod> cpuOut((size_t)K * w.G * w.Nn);
        int actGuides = 0;
        double tCpu1 = 0, tCpu8 = 0, tCpu12 = 0;
        if (K <= 1000) {
            std::vector<double> s1, s8, s12;
            int reps = (K <= 100) ? 15 : 5;
            for (int r = 0; r < reps; ++r) {
                s1.push_back(runCpuSolve(w, 1, false, cpuOut, actGuides));
                s8.push_back(runCpuSolve(w, 8, false, cpuOut, actGuides));
                s12.push_back(runCpuSolve(w, 12, false, cpuOut, actGuides));
            }
            tCpu1 = stats(s1).p50; tCpu8 = stats(s8).p50; tCpu12 = stats(s12).p50;
        } else {
            tCpu1 = runCpuSolve(w, 1, false, cpuOut, actGuides);
            std::vector<double> s8, s12;
            for (int r = 0; r < 3; ++r) {
                s8.push_back(runCpuSolve(w, 8, false, cpuOut, actGuides));
                s12.push_back(runCpuSolve(w, 12, false, cpuOut, actGuides));
            }
            tCpu8 = stats(s8).p50; tCpu12 = stats(s12).p50;
        }

        // CUDA setup
        void *dRest = nullptr, *dSph = nullptr, *dInst = nullptr, *dOut = nullptr, *dAct = nullptr;
        cudaMalloc(&dRest, w.rest.size() * 16);
        cudaMalloc(&dSph, w.gsphere.size() * 16);
        cudaMalloc(&dInst, w.inst.size() * 16);
        cudaMalloc(&dOut, (size_t)K * w.G * w.Nn * 16);
        cudaMalloc(&dAct, sizeof(int));
        cudaMemcpy(dRest, w.rest.data(), w.rest.size() * 16, cudaMemcpyHostToDevice);
        cudaMemcpy(dSph, w.gsphere.data(), w.gsphere.size() * 16, cudaMemcpyHostToDevice);

        void *hInstPinned = nullptr, *hPosePinned = nullptr;
        int *hActPinned = nullptr;
        cudaMallocHost(&hInstPinned, K * 16);
        cudaMallocHost(&hPosePinned, (size_t)std::max(1, actGuides + 1024) * w.Nn * 16);
        cudaMallocHost((void**)&hActPinned, sizeof(int));
        memcpy(hInstPinned, w.inst.data(), K * 16);

        float4_pod capA = mf4(w.capA.x, w.capA.y, w.capA.z, w.capA.w);
        float4_pod capB = mf4(w.capB.x, w.capB.y, w.capB.z, w.capB.w);

        cudaEvent_t ev0, ev1; cudaEventCreate(&ev0); cudaEventCreate(&ev1);
        int total = K * w.G, blk = 256, grd = (total + blk - 1) / blk, comp = 1;
        void* kargs[] = { &dRest, &dSph, &dInst, &w.G, &w.Nn, &K, &w.iters, &w.kBend, &capA, &capB, &dOut, &dAct, &comp };

        for (int i = 0; i < 5; ++i) {
            cudaMemsetAsync(dAct, 0, sizeof(int));
            cuLaunchKernel(fnGuide32, grd, 1, 1, blk, 1, 1, 0, 0, kargs, nullptr);
        }
        cudaDeviceSynchronize();

        std::vector<double> cudaKernMs, cudaFullMs;
        for (int i = 0; i < 30; ++i) {
            double t0 = nowMs();
            cudaMemcpyAsync(dInst, hInstPinned, K * 16, cudaMemcpyHostToDevice, 0);
            cudaMemsetAsync(dAct, 0, sizeof(int), 0);
            cudaEventRecord(ev0, 0);
            cuLaunchKernel(fnGuide32, grd, 1, 1, blk, 1, 1, 0, 0, kargs, nullptr);
            cudaEventRecord(ev1, 0);
            cudaMemcpyAsync(hActPinned, dAct, sizeof(int), cudaMemcpyDeviceToHost, 0);
            cudaStreamSynchronize(0);
            int m = *hActPinned;
            if (m > 0) {
                cudaMemcpyAsync(hPosePinned, dOut, (size_t)m * w.Nn * 16, cudaMemcpyDeviceToHost, 0);
                cudaStreamSynchronize(0);
            }
            double t1 = nowMs();
            float kms = 0; cudaEventElapsedTime(&kms, ev0, ev1);
            cudaKernMs.push_back(kms);
            cudaFullMs.push_back(t1 - t0);
        }

        // OpenCL benchmark on same workload
        double clKernP50 = -1.0;
        if (hasCL && clKern) {
            cl_int err = 0;
            cl_mem bRest = cl.clCreateBuffer(clCtx, CL_MEM_READ_ONLY | CL_MEM_COPY_HOST_PTR, w.rest.size()*16, (void*)w.rest.data(), &err);
            cl_mem bSph  = cl.clCreateBuffer(clCtx, CL_MEM_READ_ONLY | CL_MEM_COPY_HOST_PTR, w.gsphere.size()*16, (void*)w.gsphere.data(), &err);
            cl_mem bInst = cl.clCreateBuffer(clCtx, CL_MEM_READ_ONLY | CL_MEM_COPY_HOST_PTR, w.inst.size()*16, (void*)w.inst.data(), &err);
            cl_mem bOut  = cl.clCreateBuffer(clCtx, CL_MEM_WRITE_ONLY, (size_t)K * w.G * w.Nn * 16, nullptr, &err);
            int zero = 0;
            cl_mem bAct  = cl.clCreateBuffer(clCtx, CL_MEM_READ_WRITE | CL_MEM_COPY_HOST_PTR, sizeof(int), &zero, &err);

            int compactFlag = 1;
            cl.clSetKernelArg(clKern, 0, sizeof(cl_mem), &bRest);
            cl.clSetKernelArg(clKern, 1, sizeof(cl_mem), &bSph);
            cl.clSetKernelArg(clKern, 2, sizeof(cl_mem), &bInst);
            cl.clSetKernelArg(clKern, 3, sizeof(int), &w.G);
            cl.clSetKernelArg(clKern, 4, sizeof(int), &w.Nn);
            cl.clSetKernelArg(clKern, 5, sizeof(int), &K);
            cl.clSetKernelArg(clKern, 6, sizeof(int), &w.iters);
            cl.clSetKernelArg(clKern, 7, sizeof(float), &w.kBend);
            cl.clSetKernelArg(clKern, 8, sizeof(float4_pod), &capA);
            cl.clSetKernelArg(clKern, 9, sizeof(float4_pod), &capB);
            cl.clSetKernelArg(clKern, 10, sizeof(cl_mem), &bOut);
            cl.clSetKernelArg(clKern, 11, sizeof(cl_mem), &bAct);
            cl.clSetKernelArg(clKern, 12, sizeof(int), &compactFlag);

            size_t lws = 256, gws = (size_t)grd * 256;
            for (int i = 0; i < 5; ++i)
                cl.clEnqueueNDRangeKernel(clQ, clKern, 1, nullptr, &gws, &lws, 0, nullptr, nullptr);
            cl.clFinish(clQ);

            std::vector<double> clMs;
            for (int i = 0; i < 30; ++i) {
                cl.clEnqueueWriteBuffer(clQ, bAct, 0, 0, sizeof(int), &zero, 0, nullptr, nullptr);
                cl_event ev = nullptr;
                cl.clEnqueueNDRangeKernel(clQ, clKern, 1, nullptr, &gws, &lws, 0, nullptr, &ev);
                cl.clFinish(clQ);
                cl_ulong tS = 0, tE = 0;
                cl.clGetEventProfilingInfo(ev, CL_PROFILING_COMMAND_START, sizeof(tS), &tS, nullptr);
                cl.clGetEventProfilingInfo(ev, CL_PROFILING_COMMAND_END, sizeof(tE), &tE, nullptr);
                clMs.push_back((double)(tE - tS) * 1e-6);
                cl.clReleaseEvent(ev);
            }
            clKernP50 = stats(clMs).p50;
            cl.clReleaseMemObject(bRest); cl.clReleaseMemObject(bSph); cl.clReleaseMemObject(bInst);
            cl.clReleaseMemObject(bOut); cl.clReleaseMemObject(bAct);
        }

        // D3D11 CS benchmark on same workload
        double d3dKernP50 = -1.0;
        if (d3dDev && d3dCs) {
            auto makeSrvBuf = [&](const void* data, UINT count, UINT stride, ID3D11Buffer** bOut, ID3D11ShaderResourceView** srvOut) {
                D3D11_BUFFER_DESC bd{}; bd.ByteWidth = count * stride; bd.Usage = D3D11_USAGE_DEFAULT;
                bd.BindFlags = D3D11_BIND_SHADER_RESOURCE; bd.MiscFlags = D3D11_RESOURCE_MISC_BUFFER_STRUCTURED;
                bd.StructureByteStride = stride;
                D3D11_SUBRESOURCE_DATA sd{ data, 0, 0 };
                d3dDev->CreateBuffer(&bd, &sd, bOut);
                D3D11_SHADER_RESOURCE_VIEW_DESC vd{}; vd.Format = DXGI_FORMAT_UNKNOWN;
                vd.ViewDimension = D3D11_SRV_DIMENSION_BUFFER; vd.Buffer.NumElements = count;
                d3dDev->CreateShaderResourceView(*bOut, &vd, srvOut);
            };
            ID3D11Buffer *bRest = nullptr, *bSph = nullptr, *bInst = nullptr, *bOut = nullptr, *bCnt = nullptr, *bCB = nullptr;
            ID3D11ShaderResourceView *sRest = nullptr, *sSph = nullptr, *sInst = nullptr;
            ID3D11UnorderedAccessView *uOut = nullptr, *uCnt = nullptr;
            makeSrvBuf(w.rest.data(), (UINT)w.rest.size(), 16, &bRest, &sRest);
            makeSrvBuf(w.gsphere.data(), (UINT)w.gsphere.size(), 16, &bSph, &sSph);
            makeSrvBuf(w.inst.data(), (UINT)w.inst.size(), 16, &bInst, &sInst);

            D3D11_BUFFER_DESC ubd{}; ubd.ByteWidth = (UINT)((size_t)K * w.G * w.Nn * 16);
            ubd.Usage = D3D11_USAGE_DEFAULT; ubd.BindFlags = D3D11_BIND_UNORDERED_ACCESS;
            ubd.MiscFlags = D3D11_RESOURCE_MISC_BUFFER_STRUCTURED; ubd.StructureByteStride = 16;
            d3dDev->CreateBuffer(&ubd, nullptr, &bOut);
            D3D11_UNORDERED_ACCESS_VIEW_DESC uvd{}; uvd.Format = DXGI_FORMAT_UNKNOWN;
            uvd.ViewDimension = D3D11_UAV_DIMENSION_BUFFER; uvd.Buffer.NumElements = (UINT)((size_t)K * w.G * w.Nn);
            d3dDev->CreateUnorderedAccessView(bOut, &uvd, &uOut);

            D3D11_BUFFER_DESC cbd{}; cbd.ByteWidth = 16; cbd.Usage = D3D11_USAGE_DEFAULT;
            cbd.BindFlags = D3D11_BIND_UNORDERED_ACCESS; cbd.MiscFlags = D3D11_RESOURCE_MISC_BUFFER_ALLOW_RAW_VIEWS;
            d3dDev->CreateBuffer(&cbd, nullptr, &bCnt);
            D3D11_UNORDERED_ACCESS_VIEW_DESC cuvd{}; cuvd.Format = DXGI_FORMAT_R32_TYPELESS;
            cuvd.ViewDimension = D3D11_UAV_DIMENSION_BUFFER; cuvd.Buffer.NumElements = 4;
            cuvd.Buffer.Flags = D3D11_BUFFER_UAV_FLAG_RAW;
            d3dDev->CreateUnorderedAccessView(bCnt, &cuvd, &uCnt);

            struct CBData { int G, Nn, K, iters; float kBend; int compactOut, p0, p1; float4_pod capA, capB; } cbData{
                w.G, w.Nn, K, w.iters, w.kBend, 1, 0, 0, capA, capB
            };
            D3D11_BUFFER_DESC cbufd{}; cbufd.ByteWidth = sizeof(CBData); cbufd.Usage = D3D11_USAGE_DEFAULT;
            cbufd.BindFlags = D3D11_BIND_CONSTANT_BUFFER;
            D3D11_SUBRESOURCE_DATA cbsd{ &cbData, 0, 0 };
            d3dDev->CreateBuffer(&cbufd, &cbsd, &bCB);

            ID3D11Query *qDisjoint = nullptr, *qStart = nullptr, *qEnd = nullptr;
            D3D11_QUERY_DESC qd{ D3D11_QUERY_TIMESTAMP_DISJOINT, 0 }; d3dDev->CreateQuery(&qd, &qDisjoint);
            qd.Query = D3D11_QUERY_TIMESTAMP; d3dDev->CreateQuery(&qd, &qStart); d3dDev->CreateQuery(&qd, &qEnd);

            ID3D11ShaderResourceView* srvs[3] = { sRest, sSph, sInst };
            ID3D11UnorderedAccessView* uavs[2] = { uOut, uCnt };
            d3dCtx->CSSetShader(d3dCs, nullptr, 0);
            d3dCtx->CSSetConstantBuffers(0, 1, &bCB);
            d3dCtx->CSSetShaderResources(0, 3, srvs);
            d3dCtx->CSSetUnorderedAccessViews(0, 2, uavs, nullptr);

            for (int i = 0; i < 5; ++i) d3dCtx->Dispatch((UINT)grd, 1, 1);
            d3dCtx->Flush();

            std::vector<double> d3dMs;
            UINT zero4[4] = {0,0,0,0};
            for (int i = 0; i < 30; ++i) {
                d3dCtx->ClearUnorderedAccessViewUint(uCnt, zero4);
                d3dCtx->Begin(qDisjoint);
                d3dCtx->End(qStart);
                d3dCtx->Dispatch((UINT)grd, 1, 1);
                d3dCtx->End(qEnd);
                d3dCtx->End(qDisjoint);
                d3dCtx->Flush();
                while (d3dCtx->GetData(qDisjoint, nullptr, 0, 0) == S_FALSE) {}
                D3D11_QUERY_DATA_TIMESTAMP_DISJOINT dj{};
                UINT64 ts0 = 0, ts1 = 0;
                d3dCtx->GetData(qDisjoint, &dj, sizeof(dj), 0);
                d3dCtx->GetData(qStart, &ts0, sizeof(ts0), 0);
                d3dCtx->GetData(qEnd, &ts1, sizeof(ts1), 0);
                if (!dj.Disjoint) d3dMs.push_back((double)(ts1 - ts0) * 1000.0 / (double)dj.Frequency);
            }
            d3dKernP50 = stats(d3dMs).p50;
            qDisjoint->Release(); qStart->Release(); qEnd->Release();
            uOut->Release(); uCnt->Release(); sRest->Release(); sSph->Release(); sInst->Release();
            bRest->Release(); bSph->Release(); bInst->Release(); bOut->Release(); bCnt->Release(); bCB->Release();
        }

        printf("  %6d | %6d | %7.3fms | %7.3fms | %7.3fms | %8.3fms | %9.3fms | %8.3fms | %8.3fms\n",
               K, actGuides, tCpu1, tCpu8, tCpu12,
               stats(cudaKernMs).p50, stats(cudaFullMs).p50, clKernP50, d3dKernP50);

        cudaEventDestroy(ev0); cudaEventDestroy(ev1);
        cudaFreeHost(hInstPinned); cudaFreeHost(hPosePinned); cudaFreeHost(hActPinned);
        cudaFree(dRest); cudaFree(dSph); cudaFree(dInst); cudaFree(dOut); cudaFree(dAct);
    }

    // ========================================================================
    // 7. Mesh Deformation Benchmark (V = 22,032 vertices/plant, G = 451 guides)
    // ========================================================================
    printf("\n[6] VERTEX & NORMAL DEFORMATION BENCHMARK (V=22,032 vertices/plant, G=451, Nn=8)\n");
    int defKList[] = { 1, 3, 10, 50, 100, 500 };
    for (int K : defKList) {
        Workload w; w.K = K; w.G = 451; w.Nn = 8; w.iters = 8; w.build();
        MeshBind mb; mb.build(w, 22032);

        std::vector<float> cpuVtx((size_t)K * mb.V * 6);
        auto runCpuDef = [&]() {
            double t0 = nowMs();
            std::atomic<int> nextK{0};
            std::vector<std::thread> ths;
            for (int t = 0; t < 12; ++t) {
                ths.emplace_back([&]() {
                    while (true) {
                        int k = nextK.fetch_add(1, std::memory_order_relaxed);
                        if (k >= K) break;
                        for (int v = 0; v < mb.V; ++v) {
                            deformVertex(w.rest.data(), w.G, nullptr, mb.bindG[v], mb.bindS[v], mb.bindT[v],
                                         mb.off[v], mb.nrm[v], &cpuVtx[((size_t)k * mb.V + v) * 6]);
                        }
                    }
                });
            }
            for (auto& th : ths) th.join();
            return nowMs() - t0;
        };
        double cpuDefMs = runCpuDef();

        void *dRest = nullptr, *dPosed = nullptr, *dOff = nullptr, *dNrm = nullptr, *dOutV = nullptr;
        void *dBindG = nullptr, *dBindS = nullptr, *dBindT = nullptr;
        cudaMalloc(&dRest, w.rest.size() * 16);
        cudaMalloc(&dPosed, (size_t)K * w.G * w.Nn * 16);
        cudaMalloc(&dBindG, mb.V * 4);
        cudaMalloc(&dBindS, mb.V * 4);
        cudaMalloc(&dBindT, mb.V * 4);
        cudaMalloc(&dOff, mb.V * 16);
        cudaMalloc(&dNrm, mb.V * 16);
        cudaMalloc(&dOutV, (size_t)K * mb.V * 16);

        cudaMemcpy(dRest, w.rest.data(), w.rest.size()*16, cudaMemcpyHostToDevice);
        cudaMemset(dPosed, 0, (size_t)K * w.G * w.Nn * 16);
        cudaMemcpy(dBindG, mb.bindG.data(), mb.V*4, cudaMemcpyHostToDevice);
        cudaMemcpy(dBindS, mb.bindS.data(), mb.V*4, cudaMemcpyHostToDevice);
        cudaMemcpy(dBindT, mb.bindT.data(), mb.V*4, cudaMemcpyHostToDevice);
        cudaMemcpy(dOff, mb.off.data(), mb.V*16, cudaMemcpyHostToDevice);
        cudaMemcpy(dNrm, mb.nrm.data(), mb.V*16, cudaMemcpyHostToDevice);

        int totalV = K * mb.V, blk = 256, grd = (totalV + blk - 1) / blk;
        void* dargs[] = { &dRest, &dPosed, &dBindG, &dBindS, &dBindT, &dOff, &dNrm, &w.G, &w.Nn, &mb.V, &K, &dOutV };
        cudaEvent_t ev0, ev1; cudaEventCreate(&ev0); cudaEventCreate(&ev1);
        for (int i = 0; i < 5; ++i)
            cuLaunchKernel(fnDeform32, grd, 1, 1, blk, 1, 1, 0, 0, dargs, nullptr);
        cudaDeviceSynchronize();
        std::vector<double> dms;
        for (int i = 0; i < 20; ++i) {
            cudaEventRecord(ev0);
            cuLaunchKernel(fnDeform32, grd, 1, 1, blk, 1, 1, 0, 0, dargs, nullptr);
            cudaEventRecord(ev1);
            cudaEventSynchronize(ev1);
            float ms = 0; cudaEventElapsedTime(&ms, ev0, ev1);
            dms.push_back(ms);
        }
        printf("  K_deform=%4d (%8d verts, %6.2f MiB out) | CPU_12T=%7.3f ms | CUDA_Deform=%7.3f ms\n",
               K, totalV, (totalV * 16.0) / (1024.0 * 1024.0), cpuDefMs, stats(dms).p50);

        cudaEventDestroy(ev0); cudaEventDestroy(ev1);
        cudaFree(dRest); cudaFree(dPosed); cudaFree(dBindG); cudaFree(dBindS);
        cudaFree(dBindT); cudaFree(dOff); cudaFree(dNrm); cudaFree(dOutV);
    }

    if (d3dCs) d3dCs->Release();
    if (d3dCtx) d3dCtx->Release();
    if (d3dDev) d3dDev->Release();
    printf("\nBenchmark completed successfully.\n");
    return 0;
}
