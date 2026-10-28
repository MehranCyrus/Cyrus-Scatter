// Owned standalone D3D11 buffers only. No Max process or SDK resources are accessed.
#define NOMINMAX
#define CL_TARGET_OPENCL_VERSION 120
#define CL_USE_DEPRECATED_OPENCL_1_2_APIS
#include <d3d11.h>
#include <dxgi.h>
#include <cuda.h>
#include <cudaD3D11.h>
#include <nvrtc.h>
#include <CL/cl.h>
#include <CL/cl_d3d11.h>
#include <cstdio>
#include <stdexcept>
#include <string>
#include <vector>
constexpr unsigned N=1024;
void hr(HRESULT e){if(FAILED(e))throw std::runtime_error("D3D HRESULT "+std::to_string(unsigned(e)));}
void cu(CUresult e){if(e!=CUDA_SUCCESS){const char* s=nullptr;cuGetErrorString(e,&s);throw std::runtime_error(s?s:"CUDA failure");}}
void clok(cl_int e){if(e)throw std::runtime_error("OpenCL error "+std::to_string(e));}
std::string quoted(const std::string& s){std::string out="\"";for(char c:s){if(c=='"'||c=='\\')out+='\\';if(c=='\n')out+="\\n";else if(c=='\r')out+="\\r";else out+=c;}return out+'"';}
std::string devString(cl_device_id d,cl_device_info k){size_t n=0;clok(clGetDeviceInfo(d,k,0,nullptr,&n));std::string s(n,'\0');clok(clGetDeviceInfo(d,k,n,s.data(),nullptr));if(!s.empty()&&s.back()==0)s.pop_back();return s;}
ID3D11Buffer* makeBuffer(ID3D11Device* d){D3D11_BUFFER_DESC desc{};desc.ByteWidth=N*16;desc.Usage=D3D11_USAGE_DEFAULT;desc.BindFlags=D3D11_BIND_VERTEX_BUFFER|D3D11_BIND_SHADER_RESOURCE;ID3D11Buffer* b=nullptr;hr(d->CreateBuffer(&desc,nullptr,&b));return b;}
void verify(ID3D11Device* d,ID3D11DeviceContext* dc,ID3D11Buffer* b){D3D11_BUFFER_DESC desc{};b->GetDesc(&desc);desc.Usage=D3D11_USAGE_STAGING;desc.BindFlags=0;desc.CPUAccessFlags=D3D11_CPU_ACCESS_READ;ID3D11Buffer* stage=nullptr;hr(d->CreateBuffer(&desc,nullptr,&stage));dc->CopyResource(stage,b);D3D11_MAPPED_SUBRESOURCE view{};hr(dc->Map(stage,0,D3D11_MAP_READ,0,&view));auto* f=static_cast<const float*>(view.pData);bool valid=true;for(unsigned i=0;i<N;++i)valid&=f[i*4]==float(i)&&f[i*4+1]==float(i+1)&&f[i*4+2]==2.f&&f[i*4+3]==1.f;dc->Unmap(stage,0);stage->Release();if(!valid)throw std::runtime_error("D3D readback did not match compute writes");}
int main(){try{
 cu(cuInit(0));IDXGIFactory* factory=nullptr;hr(CreateDXGIFactory(__uuidof(IDXGIFactory),reinterpret_cast<void**>(&factory)));IDXGIAdapter* adapter=nullptr;CUdevice cudaDevice=-1;
 for(unsigned i=0;;++i){IDXGIAdapter* a=nullptr;if(factory->EnumAdapters(i,&a)==DXGI_ERROR_NOT_FOUND)break;CUdevice candidate;if(cuD3D11GetDevice(&candidate,a)==CUDA_SUCCESS){adapter=a;cudaDevice=candidate;break;}a->Release();}if(!adapter)throw std::runtime_error("No CUDA/D3D11 matched adapter");
 char name[256]{};cu(cuDeviceGetName(name,sizeof(name),cudaDevice));ID3D11Device* d=nullptr;ID3D11DeviceContext* dc=nullptr;D3D_FEATURE_LEVEL level{};hr(D3D11CreateDevice(adapter,D3D_DRIVER_TYPE_UNKNOWN,nullptr,0,nullptr,0,D3D11_SDK_VERSION,&d,&level,&dc));
 bool cudaPassed=false,clPassed=false;std::string cudaMessage,clMessage,clExtension;
 try{CUcontext context;cu(cuDevicePrimaryCtxRetain(&context,cudaDevice));cu(cuCtxSetCurrent(context));
  const char* code="extern \"C\" __global__ void fill(float4* out,unsigned n){unsigned i=blockIdx.x*blockDim.x+threadIdx.x;if(i<n)out[i]=make_float4(float(i),float(i+1),2.f,1.f);}";
  nvrtcProgram p;if(nvrtcCreateProgram(&p,code,"interop.cu",0,nullptr,nullptr)!=NVRTC_SUCCESS)throw std::runtime_error("NVRTC create failed");const char* opt="--gpu-architecture=compute_86";auto status=nvrtcCompileProgram(p,1,&opt);if(status!=NVRTC_SUCCESS)throw std::runtime_error(nvrtcGetErrorString(status));size_t len=0;nvrtcGetPTXSize(p,&len);std::vector<char> ptx(len);nvrtcGetPTX(p,ptx.data());nvrtcDestroyProgram(&p);CUmodule module;cu(cuModuleLoadData(&module,ptx.data()));CUfunction k;cu(cuModuleGetFunction(&k,module,"fill"));
  auto* buffer=makeBuffer(d);CUgraphicsResource resource;cu(cuGraphicsD3D11RegisterResource(&resource,buffer,CU_GRAPHICS_REGISTER_FLAGS_NONE));cu(cuGraphicsMapResources(1,&resource,nullptr));CUdeviceptr address;size_t bytes=0;cu(cuGraphicsResourceGetMappedPointer(&address,&bytes,resource));if(bytes<N*16)throw std::runtime_error("Mapped buffer too short");unsigned count=N;void* args[]{&address,&count};cu(cuLaunchKernel(k,4,1,1,256,1,1,0,nullptr,args,nullptr));cu(cuGraphicsUnmapResources(1,&resource,nullptr));verify(d,dc,buffer);cu(cuGraphicsUnregisterResource(resource));buffer->Release();cu(cuModuleUnload(module));cu(cuDevicePrimaryCtxRelease(cudaDevice));cudaPassed=true;cudaMessage="CUDA wrote 1024 float4 values; D3D11 staging readback matched exactly";
 }catch(const std::exception& e){cudaMessage=e.what();}
 try{cl_uint count=0;clok(clGetPlatformIDs(0,nullptr,&count));std::vector<cl_platform_id> platforms(count);clok(clGetPlatformIDs(count,platforms.data(),nullptr));cl_platform_id chosen=nullptr;cl_device_id gpu=nullptr;
  clGetDeviceIDsFromD3D11KHR_fn getIDs=nullptr;clCreateFromD3D11BufferKHR_fn fromBuffer=nullptr;clEnqueueAcquireD3D11ObjectsKHR_fn acquire=nullptr;clEnqueueReleaseD3D11ObjectsKHR_fn release=nullptr;
  for(auto platform:platforms){cl_uint n=0;if(clGetDeviceIDs(platform,CL_DEVICE_TYPE_GPU,0,nullptr,&n)!=CL_SUCCESS)continue;std::vector<cl_device_id> ds(n);clok(clGetDeviceIDs(platform,CL_DEVICE_TYPE_GPU,n,ds.data(),nullptr));bool khr=false,nv=false;for(auto x:ds){auto ext=devString(x,CL_DEVICE_EXTENSIONS);khr|=ext.find("cl_khr_d3d11_sharing")!=std::string::npos;nv|=ext.find("cl_nv_d3d11_sharing")!=std::string::npos;}if(!khr&&!nv)continue;std::string suffix=khr?"KHR":"NV";
   getIDs=reinterpret_cast<clGetDeviceIDsFromD3D11KHR_fn>(clGetExtensionFunctionAddressForPlatform(platform,("clGetDeviceIDsFromD3D11"+suffix).c_str()));if(!getIDs)continue;cl_uint nmatch=0;if(getIDs(platform,CL_D3D11_DEVICE_KHR,d,CL_PREFERRED_DEVICES_FOR_D3D11_KHR,1,&gpu,&nmatch)!=CL_SUCCESS||!nmatch)continue;
   fromBuffer=reinterpret_cast<clCreateFromD3D11BufferKHR_fn>(clGetExtensionFunctionAddressForPlatform(platform,("clCreateFromD3D11Buffer"+suffix).c_str()));acquire=reinterpret_cast<clEnqueueAcquireD3D11ObjectsKHR_fn>(clGetExtensionFunctionAddressForPlatform(platform,("clEnqueueAcquireD3D11Objects"+suffix).c_str()));release=reinterpret_cast<clEnqueueReleaseD3D11ObjectsKHR_fn>(clGetExtensionFunctionAddressForPlatform(platform,("clEnqueueReleaseD3D11Objects"+suffix).c_str()));if(fromBuffer&&acquire&&release){chosen=platform;clExtension=khr?"cl_khr_d3d11_sharing":"cl_nv_d3d11_sharing";break;}}
  if(!chosen)throw std::runtime_error("No advertised D3D11-sharing extension resolved for this D3D device");cl_context_properties props[]{CL_CONTEXT_PLATFORM,reinterpret_cast<cl_context_properties>(chosen),CL_CONTEXT_D3D11_DEVICE_KHR,reinterpret_cast<cl_context_properties>(d),0};cl_int e=0;auto ctx=clCreateContext(props,1,&gpu,nullptr,nullptr,&e);clok(e);auto queue=clCreateCommandQueue(ctx,gpu,0,&e);clok(e);
  const char* code="__kernel void fill(__global float4* out){uint i=get_global_id(0);out[i]=(float4)((float)i,(float)(i+1),2.f,1.f);}";auto program=clCreateProgramWithSource(ctx,1,&code,nullptr,&e);clok(e);clok(clBuildProgram(program,1,&gpu,"-cl-std=CL1.2",nullptr,nullptr));auto kernel=clCreateKernel(program,"fill",&e);clok(e);auto* buffer=makeBuffer(d);auto shared=fromBuffer(ctx,CL_MEM_WRITE_ONLY,buffer,&e);clok(e);clok(clSetKernelArg(kernel,0,sizeof(shared),&shared));clok(acquire(queue,1,&shared,0,nullptr,nullptr));size_t global=N,local=256;clok(clEnqueueNDRangeKernel(queue,kernel,1,nullptr,&global,&local,0,nullptr,nullptr));clok(release(queue,1,&shared,0,nullptr,nullptr));clok(clFinish(queue));verify(d,dc,buffer);clok(clReleaseMemObject(shared));buffer->Release();clok(clReleaseKernel(kernel));clok(clReleaseProgram(program));clok(clReleaseCommandQueue(queue));clok(clReleaseContext(ctx));clPassed=true;clMessage="OpenCL wrote 1024 float4 values; D3D11 staging readback matched exactly";
 }catch(const std::exception& e){clMessage=e.what();}
 printf("{\"scope\":\"Standalone owned D3D11 buffers only; not Nitrous or Max\",\"device\":%s,\"feature_level\":%u,\"cuda\":{\"passed\":%s,\"message\":%s},\"opencl\":{\"passed\":%s,\"extension\":%s,\"message\":%s}}\n",quoted(name).c_str(),unsigned(level),cudaPassed?"true":"false",quoted(cudaMessage).c_str(),clPassed?"true":"false",quoted(clExtension).c_str(),quoted(clMessage).c_str());
 dc->ClearState();dc->Release();d->Release();adapter->Release();factory->Release();return cudaPassed&&clPassed?0:2;
}catch(const std::exception& e){fprintf(stderr,"%s\n",e.what());return 1;}}
