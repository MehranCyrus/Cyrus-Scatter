// Qualification-only readback of the exact production HLSL deformation maths.
// This standalone probe creates its own D3D11 device; the Max plugin exclusively
// uses public Nitrous handles and contains no raw-device path.
#define NOMINMAX
#include <windows.h>
#include <d3d11.h>
#include <d3dcompiler.h>
#include <d3d11shader.h>
#include <wrl/client.h>
#include <algorithm>
#include <array>
#include <cmath>
#include <fstream>
#include <iostream>
#include <stdexcept>
#include <string>
#include <vector>
#include "../../../AminScatter/src/deformation_shader.inc"
using Microsoft::WRL::ComPtr;
using Word=std::array<float,4>;
void check(HRESULT hr,const char* message){if(FAILED(hr))throw std::runtime_error(message);}
int main(int argc,char** argv){try{
    if(argc!=2)throw std::runtime_error("Expected one compact numeric fixture");
    std::ifstream file(argv[1],std::ios::binary);unsigned header[4]{};file.read(reinterpret_cast<char*>(header),sizeof(header));
    if(header[0]!=0x43504731u||header[1]>(1u<<24)||header[2]>(1u<<24)||header[3]>6000000)throw std::runtime_error("Fixture admission failed");
    std::vector<Word> bindings(header[1]),nodes(header[2]),expected(header[3]);
    for(auto* words:{&bindings,&nodes,&expected})file.read(reinterpret_cast<char*>(words->data()),words->size()*sizeof(Word));
    if(!file||bindings.empty()||nodes.empty()||expected.empty())throw std::runtime_error("Incomplete compact fixture");
    std::string shader(deformationFunctions);shader.resize(shader.find("bool cyrusDeform"));
    shader+=R"hlsl(
RWStructuredBuffer<float4> Result:register(u0);
[numthreads(128,1,1)]void main(uint3 id:SV_DispatchThreadID){
    uint words;CyrusBindings.GetDimensions(words);if(id.x>=(words/10)*3)return;
    uint face=id.x/3,corner=id.x%3;float4 roots=CyrusBindings[face*10+9];
    bool visible=CyrusNodes[(uint)roots.x].w>=0&&CyrusNodes[(uint)roots.y].w>=0&&CyrusNodes[(uint)roots.z].w>=0;
    Result[id.x]=float4(cyrusPoint(face*10+corner*3,0),visible?1:0);
})hlsl";
    ComPtr<ID3DBlob> code,errors;HRESULT compiled=D3DCompile(shader.data(),shader.size(),"production-deformation",nullptr,nullptr,"main","cs_5_0",D3DCOMPILE_ENABLE_STRICTNESS|D3DCOMPILE_OPTIMIZATION_LEVEL3,0,&code,&errors);
    if(FAILED(compiled)){if(errors)std::cerr<<static_cast<char*>(errors->GetBufferPointer());throw std::runtime_error("Production HLSL probe compilation failed");}
    ComPtr<ID3D11Device> device;ComPtr<ID3D11DeviceContext> context;D3D_FEATURE_LEVEL level;
    check(D3D11CreateDevice(nullptr,D3D_DRIVER_TYPE_HARDWARE,nullptr,0,nullptr,0,D3D11_SDK_VERSION,&device,&level,&context),"Hardware D3D11 unavailable");
    ComPtr<ID3D11ComputeShader> kernel;check(device->CreateComputeShader(code->GetBufferPointer(),code->GetBufferSize(),nullptr,&kernel),"GPU probe shader unavailable");
    auto input=[&](const std::vector<Word>& data){D3D11_BUFFER_DESC desc{};desc.ByteWidth=UINT(data.size()*sizeof(Word));desc.Usage=D3D11_USAGE_IMMUTABLE;desc.BindFlags=D3D11_BIND_SHADER_RESOURCE;
        D3D11_SUBRESOURCE_DATA initial{};initial.pSysMem=data.data();ComPtr<ID3D11Buffer> buffer;check(device->CreateBuffer(&desc,&initial,&buffer),"Typed source allocation failed");
        D3D11_SHADER_RESOURCE_VIEW_DESC view{};view.Format=DXGI_FORMAT_R32G32B32A32_FLOAT;view.ViewDimension=D3D11_SRV_DIMENSION_BUFFER;view.Buffer.NumElements=UINT(data.size());ComPtr<ID3D11ShaderResourceView> srv;check(device->CreateShaderResourceView(buffer.Get(),&view,&srv),"Typed source view failed");return srv;};
    auto bindingView=input(bindings),nodeView=input(nodes);
    ComPtr<ID3D11ShaderReflection> reflection;check(D3DReflect(code->GetBufferPointer(),code->GetBufferSize(),__uuidof(ID3D11ShaderReflection),&reflection),"Reflection failed");
    for(auto entry:{std::pair<const char*,ID3D11ShaderResourceView*>{"CyrusBindings",bindingView.Get()},{"CyrusNodes",nodeView.Get()}}){D3D11_SHADER_INPUT_BIND_DESC desc{};check(reflection->GetResourceBindingDescByName(entry.first,&desc),"Missing production buffer");auto* view=entry.second;context->CSSetShaderResources(desc.BindPoint,1,&view);}
    D3D11_BUFFER_DESC desc{};desc.ByteWidth=UINT(expected.size()*sizeof(Word));desc.Usage=D3D11_USAGE_DEFAULT;desc.BindFlags=D3D11_BIND_UNORDERED_ACCESS;desc.MiscFlags=D3D11_RESOURCE_MISC_BUFFER_STRUCTURED;desc.StructureByteStride=sizeof(Word);
    ComPtr<ID3D11Buffer> output;check(device->CreateBuffer(&desc,nullptr,&output),"Probe output allocation failed");D3D11_UNORDERED_ACCESS_VIEW_DESC view{};view.ViewDimension=D3D11_UAV_DIMENSION_BUFFER;view.Buffer.NumElements=UINT(expected.size());ComPtr<ID3D11UnorderedAccessView> uav;check(device->CreateUnorderedAccessView(output.Get(),&view,&uav),"Probe output view failed");
    context->CSSetShader(kernel.Get(),nullptr,0);auto* target=uav.Get();context->CSSetUnorderedAccessViews(0,1,&target,nullptr);context->Dispatch(UINT((expected.size()+127)/128),1,1);target=nullptr;context->CSSetUnorderedAccessViews(0,1,&target,nullptr);
    desc.Usage=D3D11_USAGE_STAGING;desc.BindFlags=0;desc.MiscFlags=0;desc.StructureByteStride=0;desc.CPUAccessFlags=D3D11_CPU_ACCESS_READ;ComPtr<ID3D11Buffer> readback;check(device->CreateBuffer(&desc,nullptr,&readback),"Probe readback allocation failed");context->CopyResource(readback.Get(),output.Get());D3D11_MAPPED_SUBRESOURCE mapped{};check(context->Map(readback.Get(),0,D3D11_MAP_READ,0,&mapped),"GPU readback failed");
    const auto* actual=static_cast<const Word*>(mapped.pData);double maximum=0;std::size_t mismatches=0;
    for(std::size_t i=0;i<expected.size();++i){double squared=0;for(unsigned k=0;k<3;++k){double d=double(actual[i][k])-expected[i][k];squared+=d*d;}double error=std::sqrt(squared);if(!std::isfinite(error))throw std::runtime_error("Nonfinite GPU corner");maximum=std::max(maximum,error);mismatches+=actual[i][3]!=expected[i][3];}
    context->Unmap(readback.Get(),0);std::cout<<"{\"corners\":"<<expected.size()<<",\"maximum_error_m\":"<<maximum<<",\"visibility_mismatches\":"<<mismatches<<",\"hardware_feature_level\":"<<level<<",\"status\":\""<<(maximum<2e-6&&mismatches==0?"pass":"failed")<<"\"}\n";
    return maximum<2e-6&&mismatches==0?0:1;
}catch(const std::exception& e){std::cerr<<e.what()<<'\n';return 1;}}
