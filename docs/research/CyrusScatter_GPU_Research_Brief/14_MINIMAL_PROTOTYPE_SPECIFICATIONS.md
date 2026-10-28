# 14. Minimal Prototype Specifications

## 1. Purpose and Execution Status

Every prototype specification below is designed to be **minimal, isolated, and falsifiable** so local engineers can validate one architectural gate at a time before touching production state management.

- **Execution Status:** The code listings below are **reference prototype specifications and kernel sketches (`NOT EXECUTED` inside 3ds Max 2027)**. A standalone synthetic C++/CUDA/OpenCL/D3D11 benchmark harness is also included in the companion `prototypes/standalone_harness/` folder of this research package with exact build instructions.

---

## 2. Prototype P-1: Local 3ds Max 2027 SDK Graphics & Interop Probe (`Gate 1`)

**Goal:** Determine in $< 30\text{ minutes}$ on the local development workstation whether `MaxSDK::Graphics` in 3ds Max 2027 exposes any supported native D3D11 device/resource pointers, and measure the exact `Lock`/`Unlock` throughput of `TextureHandle` and `VertexBufferHandle` for Path F1/F2.

```cpp
// Sketch (NOT EXECUTED in Max): Drop into a test command or PointDisplay::Realize()
// in AminScatter/src/point_display.cpp to log Max 2027 graphics capabilities.

#include <Graphics/IVirtualDevice.h>
#include <Graphics/IDevice.h>
#include <Graphics/VertexBufferHandle.h>
#include <Graphics/TextureHandle.h>
#include <Graphics/HLSLMaterialHandle.h>
#include <chrono>

void ProbeMax2027GraphicsCapabilities(MaxSDK::Graphics::DrawContext& dc) {
    using namespace MaxSDK::Graphics;
    IVirtualDevice& vd = dc.GetVirtualDevice();

    // 1. Measure public TextureHandle (R32G32B32A32_FLOAT, 4096 x 64 = 4.0 MiB) Lock/Unlock bandwidth
    TextureHandle poseTex;
    if (poseTex.Initialize(4096, 64, TargetFormatR32G32B32A32Float)) {
        auto t0 = std::chrono::steady_clock::now();
        // Verify WriteOnlyLockRectangle or Lock semantics in 2027 SDK:
        LockedRect rect{};
        if (poseTex.WriteOnlyLockRectangle(0, rect, nullptr)) {
            // Simulate writing M = 15,000 active guides * 8 nodes * 16 B = 1.83 MiB
            memset(rect.pBits, 0, 15000 * 8 * 16);
            poseTex.UnlockRectangle(0);
        }
        double elapsedMs = std::chrono::duration<double, std::milli>(
            std::chrono::steady_clock::now() - t0).count();
        DebugPrint(_T("[CyrusGPUProbe] 1.83 MiB TextureHandle Lock+Memcpy+Unlock: %.3f ms\n"), elapsedMs);
    }

    // 2. Measure public dynamic VertexBufferHandle Lock/Unlock bandwidth (1.83 MiB)
    VertexBufferHandle dynVB;
    dynVB.SetBufferUsageType(BufferUsageDynamic);
    if (dynVB.Initialize(sizeof(float) * 4, 15000 * 8)) {
        auto t0 = std::chrono::steady_clock::now();
        unsigned char* ptr = dynVB.Lock(0, 15000 * 8, WriteAcess);
        if (ptr) {
            memset(ptr, 0, 15000 * 8 * 16);
            dynVB.Unlock();
        }
        double elapsedMs = std::chrono::duration<double, std::milli>(
            std::chrono::steady_clock::now() - t0).count();
        DebugPrint(_T("[CyrusGPUProbe] 1.83 MiB VertexBufferHandle Lock+Memcpy+Unlock: %.3f ms\n"), elapsedMs);
    }
}
```
- **Pass Criterion:** If either `TextureHandle` or `VertexBufferHandle` `Lock`+`memcpy`+`Unlock` of $1.83\text{ MiB}$ completes in **$\le 0.40\text{ ms}$**, **Path F1/F2 (Compact Pose Upload via Public SDK)** is proven viable for 60–120 Hz interaction without needing undocumented D3D11 pointer extraction!

---

## 3. Prototype P-2: HLSL Shader Model 5.0 Pose-Pull Vertex Deformation (`Gate 2`)

**Goal:** Deform shared source meshes (`V = 22,032` vertices) and apply whole-group visibility masks (`Inside solid` / `Under collider`) directly inside the `MaxSDK::Graphics` HLSL SM 5.0 vertex shader (`mesh_display.inc`).

```hlsl
// Sketch (NOT EXECUTED in Max): HLSL Shader Model 5.0 Vertex Shader for Pose-Pull Deformation
// Bound via MaxSDK::Graphics::HLSLMaterialHandle::SetTextureParameter("g_PosePaletteTex", poseTex)

Texture2D<float4> g_PosePaletteTex : register(t0); // Width = 4096, R32G32B32A32_FLOAT

struct VS_INPUT {
    float3 restPos       : POSITION0;  // Source-local rest position (metres, +Y up)
    float3 restNormal    : NORMAL0;    // Source-local rest unit normal
    float4 restTangent   : TANGENT0;   // xyz = rest tangent, w = handedness sign
    float2 uv            : TEXCOORD0;
    uint4  guideBinding  : BLENDINDICES0; // x=guideIdx (0xFFFF=fixed), y=segIdx, z=rootGroupIdx, w=flags
    float4 guideSegRest  : TEXCOORD1;  // xyz = rest centerline point c_bar(g,s,t), w = paramT in [0,1]
    // Per-instance stream (Stream 1):
    float4 instPosScale  : TEXCOORD2;  // xyz = world translation, w = uniform scale s > 0
    float4 instRotQuat   : TEXCOORD3;  // xyzw = instance unit rotation quaternion
    int4   instPoseMeta  : TEXCOORD4;  // x = poseHeaderTexelOffset (-1 if at rest), y = guideCount G, z = Nn
};

struct VS_OUTPUT {
    float4 posCS         : SV_Position;
    float3 worldNormal   : NORMAL0;
    float2 uv            : TEXCOORD0;
};

float4 LoadPoseTexel(int linearTexelIdx) {
    return g_PosePaletteTex.Load(int3(linearTexelIdx & 4095, linearTexelIdx >> 12, 0));
}

// Unpack smallest-three 10:10:10:2 quaternion from uint32
float4 UnpackQuat10(uint packed) {
    uint largestIdx = packed >> 30;
    float3 abc = (float3((packed >> 0) & 1023u, (packed >> 10) & 1023u, (packed >> 20) & 1023u)
                  * (1.0f / 1023.0f)) * 1.41421356f - 0.70710678f;
    float w = sqrt(max(0.0f, 1.0f - dot(abc, abc)));
    if (largestIdx == 0u) return float4(w, abc.x, abc.y, abc.z);
    if (largestIdx == 1u) return float4(abc.x, w, abc.y, abc.z);
    if (largestIdx == 2u) return float4(abc.x, abc.y, w, abc.z);
    return float4(abc.x, abc.y, abc.z, w);
}

float3 QuatRotate(float4 q, float3 v) {
    float3 t = 2.0f * cross(q.xyz, v);
    return v + q.w * t + cross(q.xyz, t);
}

VS_OUTPUT VSMain_CyrusPosePull(VS_INPUT vin) {
    VS_OUTPUT vout;
    float3 localPos = vin.restPos;
    float3 localNrm = vin.restNormal;

    int poseHeader = vin.instPoseMeta.x;
    if (poseHeader >= 0) {
        // 1. Check Root-Group Visibility Mask (16 root groups per float4 = 128 bits/texel)
        uint rg = vin.guideBinding.z;
        uint4 maskWords = asuint(LoadPoseTexel(poseHeader + (int)(rg >> 7)));
        uint word = (rg >> 5) & 3u;
        uint bitWord = (word == 0u) ? maskWords.x : ((word == 1u) ? maskWords.y : ((word == 2u) ? maskWords.z : maskWords.w));
        if ((bitWord >> (rg & 31u)) & 1u) {
            // Whole-group hidden: discard all triangles of this rooted group by outputting NaN clip pos
            vout.posCS = float4(asfloat(0x7FC00000), 0.0f, 0.0f, 1.0f);
            vout.worldNormal = float3(0.0f, 0.0f, 1.0f);
            vout.uv = vin.uv;
            return vout;
        }

        // 2. Check if this vertex's bound guide g has an active non-rest pose slot
        uint g = vin.guideBinding.x;
        if (g != 0xFFFFu) {
            int slotTableBase = poseHeader + 4; // After 4 texels (512 bits) of root-group masks
            int4 slotQuad = asint(LoadPoseTexel(slotTableBase + (int)(g >> 2)));
            int gMod = (int)(g & 3u);
            int activeSlot = (gMod == 0) ? slotQuad.x : ((gMod == 1) ? slotQuad.y : ((gMod == 2) ? slotQuad.z : slotQuad.w));

            if (activeSlot >= 0) {
                int Nn = vin.instPoseMeta.z;
                int s = (int)vin.guideBinding.y;
                float t = vin.guideSegRest.w;
                float4 node0 = LoadPoseTexel(activeSlot * Nn + (s - 1));
                float4 node1 = LoadPoseTexel(activeSlot * Nn + s);

                float3 cPosed = lerp(node0.xyz, node1.xyz, t);
                float4 q0 = UnpackQuat10(asuint(node0.w));
                float4 q1 = UnpackQuat10(asuint(node1.w));
                if (dot(q0, q1) < 0.0f) q1 = -q1; // Shortest-arc hemisphere consistency
                float4 qSeg = normalize(lerp(q0, q1, t));

                float3 restOffset = vin.restPos - vin.guideSegRest.xyz;
                localPos = cPosed + QuatRotate(qSeg, restOffset);
                localNrm = QuatRotate(qSeg, vin.restNormal);
            }
        }
    }

    // 3. Transform from plant-local (+Y up, metres) to Max world space (+Z up, scene units)
    float3 worldPos = QuatRotate(vin.instRotQuat, localPos * vin.instPosScale.w) + vin.instPosScale.xyz;
    float3 worldNrm = QuatRotate(vin.instRotQuat, localNrm);

    vout.posCS = mul(float4(worldPos, 1.0f), g_WorldViewProj);
    vout.worldNormal = worldNrm;
    vout.uv = vin.uv;
    return vout;
}
```

---

## 4. Prototype P-3: CUDA Quasistatic Rooted-Guide & Local-BVH Solver (`Gate 4`)

**Goal:** Solve root-group exclusion (`Inside solid` / `Under collider`) and iterative Follow-The-Leader / XPBD guide contact fitting on the GPU for $M$ compacted active guides, outputting the exact `node0/node1` format consumed by Prototype P-2.

```cpp
// Sketch (NOT EXECUTED in Max): CUDA Quasistatic Active-Guide Contact Solver
// 1 thread per compacted active guide m in [0 .. M_d - 1] at hierarchy depth d.

__global__ void kSolveCompactedGuidesAtDepth(
    const float4* __restrict__ d_restNodes,        // [Nn * G] node-major rest {x,y,z, segLen}
    const uint4*  __restrict__ d_guideTopo,        // [G] {parentGuide, parentSeg, depth, rootGroup, parentT}
    const int2*   __restrict__ d_activeGuideQueue, // [M_d] {plantIdx k, guideIdx g} sorted deterministically
    const int32_t* __restrict__ d_guideSlotMap,    // [K * G] maps (k, g) -> compact slot index
    const LocalPlantColliders* __restrict__ d_plantCols, // [K] up to 64 local-frame collider refs
    const ColliderBvhData* __restrict__ d_colBvhs, // Shared collider BVH & triangle arrays
    int G, int Nn, int M_d, int iters, float kBend,
    float4* __restrict__ d_compactPoseOut,         // [M_total * Nn] output {pos.xyz, asfloat(packedQuat10)}
    uint32_t* __restrict__ d_infeasibleFlags)      // [K]
{
    int idx = blockIdx.x * blockDim.x + threadIdx.x;
    if (idx >= M_d) return;

    int2 kg = d_activeGuideQueue[idx];
    int k = kg.x;
    int g = kg.y;
    int mySlot = d_guideSlotMap[k * G + g];

    // 1. Load rest nodes into thread registers
    float3 p[12], restP[12];
    float segL[12];
    for (int i = 0; i < Nn; ++i) {
        float4 r = d_restNodes[i * G + g];
        p[i] = restP[i] = make_float3(r.x, r.y, r.z);
        segL[i] = r.w;
    }

    // 2. If child branch (depth d > 0), anchor root p[0] & base rotation q0 to parent's solved segment
    uint4 topo = d_guideTopo[g];
    int parentG = (int)(short)(topo.x & 0xFFFFu);
    float4 qBase = make_float4(0.f, 0.f, 0.f, 1.f);
    if (parentG >= 0) {
        int parentSlot = d_guideSlotMap[k * G + parentG];
        if (parentSlot >= 0) {
            int pSeg = (int)((topo.x >> 16) & 0xFFu);
            float pT = __uint_as_float(topo.z);
            float4 pn0 = d_compactPoseOut[parentSlot * Nn + (pSeg - 1)];
            float4 pn1 = d_compactPoseOut[parentSlot * Nn + pSeg];
            qBase = slerpQuat(unpackQuat10(__float_as_uint(pn0.w)),
                              unpackQuat10(__float_as_uint(pn1.w)), pT);
            float3 cParentRest = lerp3(
                make_float3(d_restNodes[(pSeg - 1) * G + parentG]),
                make_float3(d_restNodes[pSeg * G + parentG]), pT);
            float3 cParentPosed = lerp3(make_float3(pn0), make_float3(pn1), pT);
            p[0] = cParentPosed + quatRotate(qBase, restP[0] - cParentRest);
        }
    }

    // 3. Verify root anchor p[0] is not trapped inside Contact Gap of any collider
    const LocalPlantColliders& cols = d_plantCols[k];
    if (pointInsideAnyContactGap(p[0], cols, d_colBvhs)) {
        atomicOr(&d_infeasibleFlags[k], 1u /* ERR_ROOT_IN_CONTACT_GAP */);
        return;
    }

    // 4. Quasistatic Iterative Follow-The-Leader + Whole-Segment BVH Contact Projection
    for (int it = 0; it < iters; ++it) {
        float4 qRun = qBase;
        for (int i = 1; i < Nn; ++i) {
            float3 restVec = restP[i] - restP[i - 1];
            float3 target = p[i - 1] + quatRotate(qRun, restVec);
            p[i] = p[i] + (target - p[i]) * kBend;

            // Whole-segment capsule query against plant k's relevant colliders (+ Contact Gap)
            projectSegmentOutOfColliders(p[i - 1], p[i], segL[i], cols, d_colBvhs);

            // Follow-The-Leader exact length projection from anchored p[i-1]
            float3 e = p[i] - p[i - 1];
            float el = length3(e);
            p[i] = (el > 1e-12f) ? (p[i - 1] + e * (segL[i] / el)) : target;

            // Transport orientation frame to segment i
            qRun = mulQuat(minimalRotationQuat(normalize3(restVec), (p[i] - p[i - 1]) / segL[i]), qRun);
        }
    }

    // 5. Final squeeze / residual penetration check & NaN guard
    if (!verifyGuideClearAndFinite(p, Nn, cols, d_colBvhs)) {
        atomicOr(&d_infeasibleFlags[k], 2u /* ERR_SQUEEZE_OR_NAN */);
        return;
    }

    // 6. Write posed nodes + packed smallest-three quaternions to compact output slot
    float4 qNode = qBase;
    d_compactPoseOut[mySlot * Nn + 0] = make_float4(p[0].x, p[0].y, p[0].z, __uint_as_float(packQuat10(qNode)));
    for (int i = 1; i < Nn; ++i) {
        float3 dRest = normalize3(restP[i] - restP[i - 1]);
        float3 dPose = normalize3(p[i] - p[i - 1]);
        qNode = mulQuat(minimalRotationQuat(dRest, dPose), qNode);
        d_compactPoseOut[mySlot * Nn + i] = make_float4(p[i].x, p[i].y, p[i].z, __uint_as_float(packQuat10(qNode)));
    }
}
```
