// Standalone research surrogate. Not Cyrus's solver, Max display, or a production backend.
#define CL_TARGET_OPENCL_VERSION 120
#define CL_USE_DEPRECATED_OPENCL_1_2_APIS
#include <cuda_runtime_api.h>
#include <cuda.h>
#include <nvrtc.h>
#include <CL/cl.h>
#include <algorithm>
#include <chrono>
#include <cmath>
#include <cstdio>
#include <cstdlib>
#include <stdexcept>
#include <string>
#include <thread>
#include <vector>
using Clock=std::chrono::steady_clock;
constexpr unsigned V=4096,P=512;
struct alignas(16) F4{float x,y,z,w;};
struct alignas(8) B2{unsigned a,b;};
static_assert(sizeof(F4)==16&&sizeof(B2)==8,"Wire layout");
void cu(cudaError_t e){if(e!=cudaSuccess)throw std::runtime_error(cudaGetErrorString(e));}
void clok(cl_int e){if(e!=CL_SUCCESS)throw std::runtime_error("OpenCL error "+std::to_string(e));}
double ms(Clock::time_point t){return std::chrono::duration<double,std::milli>(Clock::now()-t).count();}
F4 skin(F4 p,F4 a,F4 b,F4 ta,F4 tb){
 float s=a.x*b.x+a.y*b.y+a.z*b.z+a.w*b.w<0?-1.f:1.f,u=p.w;
 F4 q{a.x+(s*b.x-a.x)*u,a.y+(s*b.y-a.y)*u,a.z+(s*b.z-a.z)*u,a.w+(s*b.w-a.w)*u};
 float inv=1.f/sqrtf(q.x*q.x+q.y*q.y+q.z*q.z+q.w*q.w);q.x*=inv;q.y*=inv;q.z*=inv;q.w*=inv;
 float x=2*(q.y*p.z-q.z*p.y),y=2*(q.z*p.x-q.x*p.z),z=2*(q.x*p.y-q.y*p.x);
 return {p.x+q.w*x+q.y*z-q.z*y+ta.x+(tb.x-ta.x)*u,p.y+q.w*y+q.z*x-q.x*z+ta.y+(tb.y-ta.y)*u,p.z+q.w*z+q.x*y-q.y*x+ta.z+(tb.z-ta.z)*u,1};
}
const char* cudaSource=R"CU(
struct alignas(16) F4{float x,y,z,w;};struct alignas(8) B2{unsigned a,b;};
constexpr unsigned P=512;
__device__ __forceinline__ F4 skin(F4 p,F4 a,F4 b,F4 ta,F4 tb){
 float s=a.x*b.x+a.y*b.y+a.z*b.z+a.w*b.w<0?-1.f:1.f,u=p.w;
 F4 q{a.x+(s*b.x-a.x)*u,a.y+(s*b.y-a.y)*u,a.z+(s*b.z-a.z)*u,a.w+(s*b.w-a.w)*u};
 float inv=1.f/sqrtf(q.x*q.x+q.y*q.y+q.z*q.z+q.w*q.w);q.x*=inv;q.y*=inv;q.z*=inv;q.w*=inv;
 float x=2*(q.y*p.z-q.z*p.y),y=2*(q.z*p.x-q.x*p.z),z=2*(q.x*p.y-q.y*p.x);
 return {p.x+q.w*x+q.y*z-q.z*y+ta.x+(tb.x-ta.x)*u,p.y+q.w*y+q.z*x-q.x*z+ta.y+(tb.y-ta.y)*u,p.z+q.w*z+q.x*y-q.y*x+ta.z+(tb.z-ta.z)*u,1};
}
extern "C" __global__ void deform(const F4* rest,const B2* bind,const F4* q,const F4* t,F4* out,unsigned n){
 unsigned i=blockIdx.x*blockDim.x+threadIdx.x;if(i>=n)return;unsigned v=i&4095,base=(i>>12)*P;B2 b=bind[v];out[i]=skin(rest[v],q[base+b.a],q[base+b.b],t[base+b.a],t[base+b.b]);
}
)CU";
void driverOK(CUresult e){if(e!=CUDA_SUCCESS){const char* msg=nullptr;cuGetErrorString(e,&msg);throw std::runtime_error(msg?msg:"CUDA driver error");}}
CUfunction cudaFunction;
void launch(F4* r,B2* b,F4* q,F4* t,F4* out,unsigned n){void* args[]{&r,&b,&q,&t,&out,&n};driverOK(cuLaunchKernel(cudaFunction,(n+255)/256,1,1,256,1,1,0,nullptr,args,nullptr));}
const char* clSource=R"CLC(
#pragma OPENCL FP_CONTRACT OFF
__kernel void deform(__global const float4* rest,__global const uint2* bind,__global const float4* qs,__global const float4* ts,__global float4* out,uint n){
 uint i=get_global_id(0);if(i>=n)return;uint v=i&4095,base=(i>>12)*512;uint2 b=bind[v];float4 p=rest[v],a=qs[base+b.x],c=qs[base+b.y];
 float s=dot(a,c)<0?-1.f:1.f,u=p.w;float4 q=a+(s*c-a)*u;q=q/sqrt(dot(q,q));float3 cross1=2.f*cross(q.xyz,p.xyz);
 float3 pos=p.xyz+q.w*cross1+cross(q.xyz,cross1)+ts[base+b.x].xyz+(ts[base+b.y].xyz-ts[base+b.x].xyz)*u;out[i]=(float4)(pos,1.f);
})CLC";
struct Samples{std::vector<double> a;double quant(double f){auto c=a;std::sort(c.begin(),c.end());return c[std::min(c.size()-1,std::size_t(std::ceil(f*c.size()))-1)];}void print(){printf("{\"samples\":%zu,\"p50_ms\":%.8f,\"p95_ms\":%.8f,\"p99_ms\":%.8f,\"min_ms\":%.8f,\"max_ms\":%.8f}",a.size(),quant(.5),quant(.95),quant(.99),*std::min_element(a.begin(),a.end()),*std::max_element(a.begin(),a.end()));}};
__declspec(noinline) void cpu(const std::vector<F4>& rest,const std::vector<B2>& b,const std::vector<F4>& q,const std::vector<F4>& t,std::vector<F4>& out,unsigned workers){
 auto part=[&](unsigned lo,unsigned hi){for(unsigned i=lo;i<hi;++i){unsigned v=i&4095,base=(i>>12)*P;out[i]=skin(rest[v],q[base+b[v].a],q[base+b[v].b],t[base+b[v].a],t[base+b[v].b]);}};
 if(workers==1){part(0,unsigned(out.size()));return;}std::vector<std::thread> threads;
 for(unsigned j=0;j<workers;++j)threads.emplace_back(part,unsigned(out.size()*j/workers),unsigned(out.size()*(j+1)/workers));for(auto& x:threads)x.join();
}
double verify(const std::vector<F4>& rest,const std::vector<B2>& bs,const std::vector<F4>& qs,const std::vector<F4>& ts,const std::vector<F4>& out){
 double maxError=0;for(unsigned i=0;i<out.size();++i){unsigned v=i&4095,base=(i>>12)*P;auto p=rest[v],a=qs[base+bs[v].a],b=qs[base+bs[v].b],ta=ts[base+bs[v].a],tb=ts[base+bs[v].b];double u=p.w,s=double(a.x)*b.x+double(a.y)*b.y+double(a.z)*b.z+double(a.w)*b.w<0?-1:1;
 double x=a.x+(s*b.x-a.x)*u,y=a.y+(s*b.y-a.y)*u,z=a.z+(s*b.z-a.z)*u,w=a.w+(s*b.w-a.w)*u;double inv=1/std::sqrt(x*x+y*y+z*z+w*w);x*=inv;y*=inv;z*=inv;w*=inv;
 double cx=2*(y*p.z-z*p.y),cy=2*(z*p.x-x*p.z),cz=2*(x*p.y-y*p.x);
 double expected[3]{p.x+w*cx+y*cz-z*cy+ta.x+(double(tb.x)-ta.x)*u,p.y+w*cy+z*cx-x*cz+ta.y+(double(tb.y)-ta.y)*u,p.z+w*cz+x*cy-y*cx+ta.z+(double(tb.z)-ta.z)*u};
 float actual[3]{out[i].x,out[i].y,out[i].z};for(int k=0;k<3;++k){if(!std::isfinite(actual[k]))throw std::runtime_error("Nonfinite output");maxError=std::max(maxError,std::abs(actual[k]-expected[k]));}}
 if(maxError>5e-6)throw std::runtime_error("Double reference tolerance exceeded");return maxError;
}
std::string clString(cl_device_id d,cl_device_info k){size_t n=0;clok(clGetDeviceInfo(d,k,0,nullptr,&n));std::string s(n,'\0');clok(clGetDeviceInfo(d,k,n,s.data(),nullptr));if(!s.empty()&&s.back()==0)s.pop_back();return s;}
int main(){try{
 driverOK(cuInit(0));cu(cudaSetDevice(0));cu(cudaFree(nullptr));
 nvrtcProgram cp;auto ne=nvrtcCreateProgram(&cp,cudaSource,"deform.cu",0,nullptr,nullptr);if(ne!=NVRTC_SUCCESS)throw std::runtime_error(nvrtcGetErrorString(ne));
 const char* options[]{"--gpu-architecture=compute_86","--fmad=false","--std=c++17","--prec-div=true","--prec-sqrt=true"};auto cjit=Clock::now();ne=nvrtcCompileProgram(cp,5,options);double cudaJit=ms(cjit);
 if(ne!=NVRTC_SUCCESS){size_t len=0;nvrtcGetProgramLogSize(cp,&len);std::string log(len,'\0');nvrtcGetProgramLog(cp,log.data());throw std::runtime_error(log);}
 size_t ptxSize=0;nvrtcGetPTXSize(cp,&ptxSize);std::vector<char> ptx(ptxSize);nvrtcGetPTX(cp,ptx.data());nvrtcDestroyProgram(&cp);CUmodule module;driverOK(cuModuleLoadData(&module,ptx.data()));driverOK(cuModuleGetFunction(&cudaFunction,module,"deform"));
 cudaDeviceProp prop;cu(cudaGetDeviceProperties(&prop,0));int runtime=0,driver=0;cu(cudaRuntimeGetVersion(&runtime));cu(cudaDriverGetVersion(&driver));
 cl_uint np=0;clok(clGetPlatformIDs(0,nullptr,&np));std::vector<cl_platform_id> platforms(np);clok(clGetPlatformIDs(np,platforms.data(),nullptr));cl_device_id device=nullptr;
 for(auto p:platforms){cl_uint nd=0;if(clGetDeviceIDs(p,CL_DEVICE_TYPE_GPU,0,nullptr,&nd)!=CL_SUCCESS)continue;std::vector<cl_device_id> ds(nd);clok(clGetDeviceIDs(p,CL_DEVICE_TYPE_GPU,nd,ds.data(),nullptr));for(auto d:ds)if(clString(d,CL_DEVICE_NAME)==prop.name)device=d;}
 if(!device)throw std::runtime_error("No OpenCL GPU matching CUDA device name");cl_int e=0;cl_context context=clCreateContext(nullptr,1,&device,nullptr,nullptr,&e);clok(e);cl_command_queue queue=clCreateCommandQueue(context,device,CL_QUEUE_PROFILING_ENABLE,&e);clok(e);
 cl_device_fp_config fp=0;clok(clGetDeviceInfo(device,CL_DEVICE_SINGLE_FP_CONFIG,sizeof(fp),&fp,nullptr));if(!(fp&CL_FP_CORRECTLY_ROUNDED_DIVIDE_SQRT))throw std::runtime_error("Matched strict sqrt/div mode unavailable");
 auto ext=clString(device,CL_DEVICE_EXTENSIONS);auto version=clString(device,CL_DEVICE_VERSION);auto drv=clString(device,CL_DRIVER_VERSION);
 cl_program program=clCreateProgramWithSource(context,1,&clSource,nullptr,&e);clok(e);auto jit=Clock::now();e=clBuildProgram(program,1,&device,"-cl-std=CL1.2 -cl-fp32-correctly-rounded-divide-sqrt",nullptr,nullptr);
 if(e){size_t n=0;clGetProgramBuildInfo(program,device,CL_PROGRAM_BUILD_LOG,0,nullptr,&n);std::string log(n,'\0');clGetProgramBuildInfo(program,device,CL_PROGRAM_BUILD_LOG,n,log.data(),nullptr);throw std::runtime_error(log);}double clJit=ms(jit);cl_kernel kernel=clCreateKernel(program,"deform",&e);clok(e);
 printf("{\"scope\":\"Synthetic guide-pose deformation only; not Max or collision fitting\",\"gpu\":\"%s\",\"cuda_runtime\":%d,\"cuda_driver_api\":%d,\"opencl_version\":\"%s\",\"opencl_driver\":\"%s\",\"opencl_build_ms\":%.6f,\"cuda_nvrtc_build_ms\":%.6f,\"opencl_khr_d3d11_sharing\":%s,\"opencl_fp64\":%s,\"opencl_extensions\":\"%s\",\"math_policy\":\"CUDA precise sqrt/div, fmad=false; OpenCL correctly-rounded div/sqrt, FP_CONTRACT OFF\",\"source_vertices\":%u,\"nodes_per_instance\":%u,\"results\":[",prop.name,runtime,driver,version.c_str(),drv.c_str(),clJit,cudaJit,ext.find("cl_khr_d3d11_sharing")!=std::string::npos?"true":"false",ext.find("cl_khr_fp64")!=std::string::npos?"true":"false",ext.c_str(),V,P);
 std::vector<F4> rest(V);std::vector<B2> bind(V);for(unsigned v=0;v<V;++v){rest[v]={float(v%37)*.001f,float(v%31)*.002f,float(v%23)*.0015f,float((v/512)%17)/16};unsigned a=(v%64)*8+((v/64)%7);bind[v]={a,a+1};}
 bool first=true;for(unsigned k:{1u,16u,256u,1024u}){
  unsigned n=k*V;size_t poseBytes=size_t(k)*P*sizeof(F4),outputBytes=size_t(n)*sizeof(F4);std::vector<F4> q(k*P),t(k*P),out(n);
  for(unsigned i=0;i<q.size();++i){double angle=(i%8==0)?0:double(i%101)*.003,half=angle*.5;float sign=i%9==0?-1.f:1.f;q[i]={0,0,float(std::sin(half))*sign,float(std::cos(half))*sign};t[i]={i%8==0?0.f:float(i%19)*.0007f,i%8==0?0.f:float(i%13)*.0004f,0,0};}
  unsigned reps=20,warm=3,workers=std::min(6u,k);Samples c1,c6;for(unsigned threads:{1u,workers}){Samples& ss=threads==1?c1:c6;if(threads==1&&workers==1&& !c1.a.empty())break;for(unsigned j=0;j<reps+warm;++j){auto start=Clock::now();cpu(rest,bind,q,t,out,threads);double duration=ms(start);if(j>=warm)ss.a.push_back(duration);}}
  if(c6.a.empty())c6=c1;double cpuError=verify(rest,bind,q,t,out);
  F4 *dr=nullptr,*dq=nullptr,*dt=nullptr,*dout=nullptr;B2* db=nullptr;cu(cudaMalloc(reinterpret_cast<void**>(&dr),V*sizeof(F4)));cu(cudaMalloc(reinterpret_cast<void**>(&db),V*sizeof(B2)));cu(cudaMalloc(reinterpret_cast<void**>(&dq),poseBytes));cu(cudaMalloc(reinterpret_cast<void**>(&dt),poseBytes));cu(cudaMalloc(reinterpret_cast<void**>(&dout),outputBytes));
  cu(cudaMemcpy(dr,rest.data(),V*sizeof(F4),cudaMemcpyHostToDevice));cu(cudaMemcpy(db,bind.data(),V*sizeof(B2),cudaMemcpyHostToDevice));cu(cudaMemcpy(dq,q.data(),poseBytes,cudaMemcpyHostToDevice));cu(cudaMemcpy(dt,t.data(),poseBytes,cudaMemcpyHostToDevice));cudaEvent_t a,b;cu(cudaEventCreate(&a));cu(cudaEventCreate(&b));Samples cudaKernel,cudaWall,cudaRound;
  for(unsigned j=0;j<reps+warm;++j){auto start=Clock::now();cu(cudaEventRecord(a));launch(dr,db,dq,dt,dout,n);cu(cudaGetLastError());cu(cudaEventRecord(b));cu(cudaEventSynchronize(b));float elapsed=0;cu(cudaEventElapsedTime(&elapsed,a,b));double wall=ms(start);if(j>=warm){cudaKernel.a.push_back(elapsed);cudaWall.a.push_back(wall);}}
  cu(cudaMemcpy(out.data(),dout,outputBytes,cudaMemcpyDeviceToHost));double cudaError=verify(rest,bind,q,t,out);
  for(unsigned j=0;j<reps+warm;++j){auto start=Clock::now();cu(cudaMemcpy(dq,q.data(),poseBytes,cudaMemcpyHostToDevice));cu(cudaMemcpy(dt,t.data(),poseBytes,cudaMemcpyHostToDevice));launch(dr,db,dq,dt,dout,n);cu(cudaGetLastError());cu(cudaMemcpy(out.data(),dout,outputBytes,cudaMemcpyDeviceToHost));if(j>=warm)cudaRound.a.push_back(ms(start));}
  cudaError=std::max(cudaError,verify(rest,bind,q,t,out));cu(cudaEventDestroy(a));cu(cudaEventDestroy(b));cu(cudaFree(dr));cu(cudaFree(db));cu(cudaFree(dq));cu(cudaFree(dt));cu(cudaFree(dout));
  auto mem=[&](size_t bytes,void* ptr){cl_int code;auto m=clCreateBuffer(context,CL_MEM_READ_WRITE|(ptr?CL_MEM_COPY_HOST_PTR:0),bytes,ptr,&code);clok(code);return m;};cl_mem cr=mem(V*sizeof(F4),rest.data()),cb=mem(V*sizeof(B2),bind.data()),cq=mem(poseBytes,q.data()),ct=mem(poseBytes,t.data()),co=mem(outputBytes,nullptr);cl_mem args[]{cr,cb,cq,ct,co};for(cl_uint i=0;i<5;++i)clok(clSetKernelArg(kernel,i,sizeof(cl_mem),&args[i]));clok(clSetKernelArg(kernel,5,sizeof(n),&n));size_t local=256,global=(n+255)/256*256;Samples clKernel,clWall,clRound;
  for(unsigned j=0;j<reps+warm;++j){cl_event event;auto start=Clock::now();clok(clEnqueueNDRangeKernel(queue,kernel,1,nullptr,&global,&local,0,nullptr,&event));clok(clWaitForEvents(1,&event));double wall=ms(start);cl_ulong st=0,en=0;clok(clGetEventProfilingInfo(event,CL_PROFILING_COMMAND_START,sizeof(st),&st,nullptr));clok(clGetEventProfilingInfo(event,CL_PROFILING_COMMAND_END,sizeof(en),&en,nullptr));if(j>=warm){clKernel.a.push_back(double(en-st)/1e6);clWall.a.push_back(wall);}clok(clReleaseEvent(event));}
  clok(clEnqueueReadBuffer(queue,co,CL_TRUE,0,outputBytes,out.data(),0,nullptr,nullptr));double clError=verify(rest,bind,q,t,out);
  for(unsigned j=0;j<reps+warm;++j){auto start=Clock::now();clok(clEnqueueWriteBuffer(queue,cq,CL_TRUE,0,poseBytes,q.data(),0,nullptr,nullptr));clok(clEnqueueWriteBuffer(queue,ct,CL_TRUE,0,poseBytes,t.data(),0,nullptr,nullptr));clok(clEnqueueNDRangeKernel(queue,kernel,1,nullptr,&global,&local,0,nullptr,nullptr));clok(clEnqueueReadBuffer(queue,co,CL_TRUE,0,outputBytes,out.data(),0,nullptr,nullptr));if(j>=warm)clRound.a.push_back(ms(start));}clError=std::max(clError,verify(rest,bind,q,t,out));for(auto m:args)clok(clReleaseMemObject(m));
  if(!first)printf(",");first=false;printf("{\"instances\":%u,\"vertices\":%u,\"cpu_workers\":%u,\"pose_upload_bytes\":%zu,\"output_bytes\":%zu,\"cpu_1\":",k,n,workers,poseBytes*2,outputBytes);c1.print();printf(",\"cpu_parallel\":");c6.print();printf(",\"cuda_device\":");cudaKernel.print();printf(",\"cuda_completed_wall\":");cudaWall.print();printf(",\"cuda_pageable_roundtrip\":");cudaRound.print();printf(",\"opencl_device\":");clKernel.print();printf(",\"opencl_completed_wall\":");clWall.print();printf(",\"opencl_pageable_roundtrip\":");clRound.print();printf(",\"max_abs_error_vs_double\":{\"cpu\":%.12g,\"cuda\":%.12g,\"opencl\":%.12g}}",cpuError,cudaError,clError);fflush(stdout);
 }
 clok(clReleaseKernel(kernel));clok(clReleaseProgram(program));clok(clReleaseCommandQueue(queue));clok(clReleaseContext(context));driverOK(cuModuleUnload(module));printf("]}\n");return 0;
}catch(const std::exception& e){fprintf(stderr,"%s\n",e.what());return 1;}}
