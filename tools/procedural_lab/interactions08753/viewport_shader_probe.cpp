// Qualification-only comparison of the complete production cyrusDeform branch.
// Own D3D11 device: no raw device/interop is added to the Max plugin.
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
#include <sstream>
#include <stdexcept>
#include <string>
#include <vector>
#include "../../../AminScatter/src/deformation_shader.inc"
using Microsoft::WRL::ComPtr;
using Word=std::array<float,4>;
constexpr unsigned cases=6,fields=8;
void check(HRESULT hr,const char* message){if(FAILED(hr))throw std::runtime_error(message);}
void replace(std::string& text,const std::string& before,const std::string& after){const auto at=text.find(before);if(at==std::string::npos)throw std::runtime_error("Missing production constant declaration");text.replace(at,before.size(),after);}
std::string referenceSource(const char* path){std::ifstream in(path);std::string text((std::istreambuf_iterator<char>(in)),{});const auto begin=text.find("R\"fx(");const auto end=text.find(")fx\"",begin);if(begin==std::string::npos||end==std::string::npos)throw std::runtime_error("Expected a frozen deformation_shader.inc reference");return text.substr(begin+5,end-begin-5);}
struct Program {ComPtr<ID3D11ComputeShader> shader;ComPtr<ID3D11ShaderReflection> reflection;};
Program program(ID3D11Device* device,std::string functions,unsigned faces,bool full,int coherent=-1){
    replace(functions,"float CyrusChangeCapacity;","static const float CyrusChangeCapacity=32;");
    replace(functions,"float CyrusChangeProbes;","static const float CyrusChangeProbes=32;");
    replace(functions,"float CyrusMetresPerUnit;","static const float CyrusMetresPerUnit=.01;");
    replace(functions,"bool CyrusDeformFull;",std::string("static const bool CyrusDeformFull=")+(full?"true;":"false;"));
    std::string source=R"hlsl(struct Input{float3 p,a,b,r0,r1,r2,r3;float sourceSlot;uint vertex;};
)hlsl"+functions+"\nstatic const uint ProbeFaces="+std::to_string(faces)+";\nstatic const uint ProbeSamples="+std::to_string(std::min(faces,4096u))+";\n"+R"hlsl(
RWStructuredBuffer<float4> Result:register(u0);
[numthreads(128,1,1)]void main(uint3 id:SV_DispatchThreadID){
    if(id.x>=ProbeSamples*3*6)return;uint variant=id.x%6,vertex=id.x/6;
    uint face=((vertex/3)*7919u)%ProbeFaces,corner=vertex%3;
    Input i;i.p=float3(-.031,.043,.057);i.a=float3(.012,-.019,.023);i.b=float3(-.023,.029,.031);
    i.r0=float3(1,0,0);i.r1=float3(0,1,0);i.r2=float3(0,0,1);i.r3=float3(0,0,0);
    i.sourceSlot=variant;i.vertex=face*3+corner;bool visible=cyrusDeform(i);
    Result[id.x*8]=float4(i.p,visible?1:0);Result[id.x*8+1]=float4(i.a,0);Result[id.x*8+2]=float4(i.b,0);
    Result[id.x*8+3]=float4(i.r0,0);Result[id.x*8+4]=float4(i.r1,0);Result[id.x*8+5]=float4(i.r2,0);Result[id.x*8+6]=float4(i.r3,0);
    Result[id.x*8+7]=float4(variant,face,corner,0);
})hlsl";
    if(coherent>=0)replace(source,"uint variant=id.x%6,vertex=id.x/6;","uint variant="+std::to_string(coherent)+",vertex=id.x/6;");
    ComPtr<ID3DBlob> code,errors;const auto hr=D3DCompile(source.data(),source.size(),"full-production-deformation",nullptr,nullptr,"main","cs_5_0",D3DCOMPILE_ENABLE_STRICTNESS|D3DCOMPILE_OPTIMIZATION_LEVEL3,0,&code,&errors);
    if(FAILED(hr)){if(errors)std::cerr<<static_cast<char*>(errors->GetBufferPointer());throw std::runtime_error("Full production HLSL probe compilation failed");}
    Program p;check(device->CreateComputeShader(code->GetBufferPointer(),code->GetBufferSize(),nullptr,&p.shader),"Compute shader creation failed");
    check(D3DReflect(code->GetBufferPointer(),code->GetBufferSize(),__uuidof(ID3D11ShaderReflection),&p.reflection),"Shader reflection failed");return p;
}
int main(int argc,char** argv){try{
    if(argc<3||argc>5)throw std::runtime_error("Expected compact fixture, frozen reference shader, optional candidate shader and --benchmark");
    std::string candidate=deformationFunctions;bool benchmark=false;
    for(int a=3;a<argc;++a)if(std::string(argv[a])=="--benchmark")benchmark=true;else candidate=referenceSource(argv[a]);
    std::ifstream file(argv[1],std::ios::binary);unsigned header[4]{};file.read(reinterpret_cast<char*>(header),sizeof(header));
    if(header[0]!=0x43504731u||header[1]>(1u<<24)||header[2]>(1u<<24)||header[3]>6000000)throw std::runtime_error("Fixture admission failed");
    std::vector<Word> bindings(header[1]),pose(header[2]),expected(header[3]);
    for(auto* words:{&bindings,&pose,&expected})file.read(reinterpret_cast<char*>(words->data()),words->size()*sizeof(Word));
    if(!file||bindings.empty()||pose.empty()||expected.empty()||bindings.size()%10||expected.size()!=bindings.size()/10*3)throw std::runtime_error("Incomplete compact fixture");
    const auto reference=referenceSource(argv[2]);const unsigned faces=unsigned(bindings.size()/10),sampled=std::min(faces,4096u),count=sampled*3*cases;
    std::vector<Word> nodes=pose;
    // The real producer reserves a rest prefix at zero. Keep quaternion words,
    // clear position flags, then append a fitted and an all-hidden pose block.
    nodes[0][3]=0;for(unsigned n=2;n<nodes.size();n+=2)nodes[n][3]=0;
    nodes.insert(nodes.end(),pose.begin(),pose.end());auto hidden=pose;hidden[0][3]=0;for(unsigned n=2;n<hidden.size();n+=2)hidden[n][3]=-1;
    nodes.insert(nodes.end(),hidden.begin(),hidden.end());std::vector<Word> changes(32*5);
    auto change=[&](unsigned key,unsigned offset,bool enabled,float shift){unsigned b=(key*2654435761u)&31;while(changes[b*5][0])b=(b+1)&31;
        changes[b*5]={float(key+1),float(offset),enabled?1.f:-1.f,0};changes[b*5+1]={1,0,0,0};changes[b*5+2]={0,1,0,0};changes[b*5+3]={0,0,1,0};changes[b*5+4]={shift,shift*.5f,-shift,0};};
    change(1,unsigned(pose.size()),true,2);change(2,0,false,3);change(3,0,true,4);change(4,unsigned(pose.size()*2),true,5);change(37,0,true,6); // hash collision for absent slot 5
    ComPtr<ID3D11Device> device;ComPtr<ID3D11DeviceContext> context;D3D_FEATURE_LEVEL level;
    check(D3D11CreateDevice(nullptr,D3D_DRIVER_TYPE_HARDWARE,nullptr,0,nullptr,0,D3D11_SDK_VERSION,&device,&level,&context),"Hardware D3D11 unavailable");
    auto input=[&](const std::vector<Word>& words){D3D11_BUFFER_DESC d{};d.ByteWidth=UINT(words.size()*sizeof(Word));d.Usage=D3D11_USAGE_IMMUTABLE;d.BindFlags=D3D11_BIND_SHADER_RESOURCE;
        D3D11_SUBRESOURCE_DATA initial{};initial.pSysMem=words.data();ComPtr<ID3D11Buffer> b;check(device->CreateBuffer(&d,&initial,&b),"Input buffer allocation failed");D3D11_SHADER_RESOURCE_VIEW_DESC v{};v.Format=DXGI_FORMAT_R32G32B32A32_FLOAT;v.ViewDimension=D3D11_SRV_DIMENSION_BUFFER;v.Buffer.NumElements=UINT(words.size());ComPtr<ID3D11ShaderResourceView> srv;check(device->CreateShaderResourceView(b.Get(),&v,&srv),"Input buffer view failed");return srv;};
    auto bindingView=input(bindings),nodeView=input(nodes),changeView=input(changes);
    D3D11_BUFFER_DESC desc{};desc.ByteWidth=count*fields*sizeof(Word);desc.Usage=D3D11_USAGE_DEFAULT;desc.BindFlags=D3D11_BIND_UNORDERED_ACCESS;desc.MiscFlags=D3D11_RESOURCE_MISC_BUFFER_STRUCTURED;desc.StructureByteStride=sizeof(Word);
    ComPtr<ID3D11Buffer> output;check(device->CreateBuffer(&desc,nullptr,&output),"Output allocation failed");D3D11_UNORDERED_ACCESS_VIEW_DESC v{};v.ViewDimension=D3D11_UAV_DIMENSION_BUFFER;v.Buffer.NumElements=count*fields;ComPtr<ID3D11UnorderedAccessView> uav;check(device->CreateUnorderedAccessView(output.Get(),&v,&uav),"Output view failed");
    desc.Usage=D3D11_USAGE_STAGING;desc.BindFlags=0;desc.MiscFlags=0;desc.StructureByteStride=0;desc.CPUAccessFlags=D3D11_CPU_ACCESS_READ;ComPtr<ID3D11Buffer> staging;check(device->CreateBuffer(&desc,nullptr,&staging),"Readback allocation failed");
    auto bind=[&](const Program& p){context->CSSetShader(p.shader.Get(),nullptr,0);for(auto item:{std::pair<const char*,ID3D11ShaderResourceView*>{"CyrusBindings",bindingView.Get()},{"CyrusNodes",nodeView.Get()},{"CyrusChanges",changeView.Get()}}){D3D11_SHADER_INPUT_BIND_DESC d{};if(SUCCEEDED(p.reflection->GetResourceBindingDescByName(item.first,&d))){auto* ptr=item.second;context->CSSetShaderResources(d.BindPoint,1,&ptr);}}
        auto* ptr=uav.Get();context->CSSetUnorderedAccessViews(0,1,&ptr,nullptr);};
    auto run=[&](const Program& p){bind(p);context->Dispatch((count+127)/128,1,1);ID3D11UnorderedAccessView* none=nullptr;context->CSSetUnorderedAccessViews(0,1,&none,nullptr);context->CopyResource(staging.Get(),output.Get());D3D11_MAPPED_SUBRESOURCE map{};check(context->Map(staging.Get(),0,D3D11_MAP_READ,0,&map),"Readback failed");
        std::vector<Word> result(count*fields);std::copy_n(static_cast<const Word*>(map.pData),result.size(),result.data());context->Unmap(staging.Get(),0);return result;};
    double maximum=0,independent=0;std::size_t visibility=0,transformErrors=0;std::array<std::vector<double>,3> beforeMs,afterMs;
    for(bool full:{true,false}){auto before=program(device.Get(),reference,faces,full),after=program(device.Get(),candidate,faces,full);const auto a=run(before),b=run(after);
        for(unsigned n=0;n<count;++n){const auto at=n*fields;visibility+=a[at][3]!=b[at][3];
            for(unsigned field=3;field<7;++field)for(unsigned k=0;k<3;++k)transformErrors+=a[at+field][k]!=b[at+field][k];
            if(b[at][3]>0)for(unsigned field=0;field<3;++field){double sq=0;for(unsigned k=0;k<3;++k){const double d=double(a[at+field][k])-b[at+field][k];sq+=d*d;}if(!std::isfinite(sq))throw std::runtime_error("Nonfinite full-deformation output");maximum=std::max(maximum,std::sqrt(sq)*.01);}
            const unsigned variant=n%cases,vertex=n/cases,face=((vertex/3)*7919u)%faces,corner=vertex%3;
            bool visible=variant!=2;Word point{-.031f,.043f,.057f,0};
            if(full){point=bindings[face*10+corner*3];if(variant==1){point=expected[face*3+corner];visible=point[3]>0;}
                else if(variant==4){const auto roots=bindings[face*10+9];visible=roots[0]==0&&roots[1]==0&&roots[2]==0;}}
            if(b[at][3]!=(visible?1.f:0.f))throw std::runtime_error("Independent branch visibility mismatch");
            if(visible){double sq=0;for(unsigned k=0;k<3;++k){const double actual=full?(k==0?b[at][0]:k==1?b[at][2]:-b[at][1])*.01:b[at][k],wanted=point[k];const auto d=actual-wanted;sq+=d*d;}independent=std::max(independent,std::sqrt(sq));}
        }
        if(full&&benchmark){
            auto timing=[&](const Program& p){ComPtr<ID3D11Query> disjoint,start,end;D3D11_QUERY_DESC d{D3D11_QUERY_TIMESTAMP_DISJOINT,0};check(device->CreateQuery(&d,&disjoint),"Timestamp unavailable");d.Query=D3D11_QUERY_TIMESTAMP;check(device->CreateQuery(&d,&start),"Timestamp unavailable");check(device->CreateQuery(&d,&end),"Timestamp unavailable");
                bind(p);context->Begin(disjoint.Get());context->End(start.Get());for(unsigned repeat=0;repeat<32;++repeat)context->Dispatch((count+127)/128,1,1);context->End(end.Get());context->End(disjoint.Get());ID3D11UnorderedAccessView* none=nullptr;context->CSSetUnorderedAccessViews(0,1,&none,nullptr);
                D3D11_QUERY_DATA_TIMESTAMP_DISJOINT q{};auto wait=[&](ID3D11Query* query,void* data,unsigned bytes){const auto stop=GetTickCount64()+10000;while(context->GetData(query,data,bytes,0)==S_FALSE){if(GetTickCount64()>stop)throw std::runtime_error("Timestamp timeout");Sleep(1);}};wait(disjoint.Get(),&q,sizeof(q));if(q.Disjoint)throw std::runtime_error("Disjoint GPU timestamp");UINT64 x=0,y=0;wait(start.Get(),&x,sizeof(x));wait(end.Get(),&y,sizeof(y));return double(y-x)/q.Frequency*1000/32;};
            // Instance draws keep neighboring lanes on the same source slot.
            // Mixed per-lane variants above deliberately stress correctness,
            // but would create artificial divergence in a timing comparison.
            for(unsigned kind=0;kind<3;++kind){const auto slot=kind==2?4:int(kind);auto old=program(device.Get(),reference,faces,true,slot),next=program(device.Get(),candidate,faces,true,slot);
                for(unsigned repeat=0;repeat<4;++repeat){if(repeat%2){afterMs[kind].push_back(timing(next));beforeMs[kind].push_back(timing(old));}else{beforeMs[kind].push_back(timing(old));afterMs[kind].push_back(timing(next));}}}
        }
    }
    const bool pass=maximum<2e-6&&independent<2e-6&&visibility==0&&transformErrors==0;
    std::cout<<"{\"scope\":\"Complete production cyrusDeform on an independent hardware D3D11 device; CS timings are not Max FPS\",\"sampled_faces\":"<<sampled<<",\"branches_per_face\":6,\"full_and_box\":true,\"maximum_reference_error_m\":"<<maximum<<",\"maximum_independent_error_m\":"<<independent<<",\"visibility_mismatches\":"<<visibility<<",\"transform_mismatches\":"<<transformErrors;
    if(!beforeMs[0].empty()){const char* names[]{"rest","posed","hidden"};for(unsigned kind=0;kind<3;++kind){std::sort(beforeMs[kind].begin(),beforeMs[kind].end());std::sort(afterMs[kind].begin(),afterMs[kind].end());std::cout<<",\""<<names[kind]<<"_reference_gpu_ms\":"<<beforeMs[kind][2]<<",\""<<names[kind]<<"_optimized_gpu_ms\":"<<afterMs[kind][2];}}
    std::cout<<",\"status\":\""<<(pass?"pass":"failed")<<"\"}\n";return pass?0:1;
}catch(const std::exception& error){std::cerr<<error.what()<<'\n';return 1;}}
