// Included by point_display.cpp inside cyrus's implementation namespace.
// Uses the same public SDK instancing contract as howto/Graphics/GPUParticle.
// No raw Direct3D device, compute runtime, scene evaluation or MAXScript in Draw.
constexpr const char* meshShader=R"fx(
float4x4 CyrusViewProjection : WORLDVIEWPROJ;
float3 CyrusColor;
struct Input {
    float3 p : POSITION;
    float3 a : TEXCOORD0;
    float3 b : TEXCOORD1;
    float3 r0 : TEXCOORD2;
    float3 r1 : TEXCOORD3;
    float3 r2 : TEXCOORD4;
    float3 r3 : TEXCOORD5;
};
struct Output { float4 p : SV_POSITION; float4 color : COLOR0; };
float3 vectorTransform(float3 v,Input i) { return v.x*i.r0+v.y*i.r1+v.z*i.r2; }
Output meshVS(Input i) {
    Output o;
    o.p=mul(float4(vectorTransform(i.p,i)+i.r3,1),CyrusViewProjection);
    float3 n=cross(vectorTransform(i.a,i),vectorTransform(i.b,i));
    float len=length(n);
    n=len>0?n/len:float3(0,0,0);
    float shade=.35+.65*abs(dot(n,normalize(float3(.3,-.5,.8))));
    o.color=float4(CyrusColor*shade,1);
    return o;
}
float4 meshPS(Output i) : SV_Target { return i.color; }
technique11 CyrusMesh {
    pass P0 {
        SetVertexShader(CompileShader(vs_5_0,meshVS()));
        SetGeometryShader(NULL);
        SetPixelShader(CompileShader(ps_5_0,meshPS()));
    }
}
)fx";

class MeshItem final : public ICustomRenderItem {
    const std::shared_ptr<Generation> generation;
    const std::size_t layerIndex,groupIndex;
    VertexBufferHandleArray buffers;
    MaterialRequiredStreams format;
    HLSLMaterialHandle material;
    std::atomic<bool> ready{false};
    std::mutex realizeMutex;
public:
    MeshItem(std::shared_ptr<Generation> value,std::size_t layer,std::size_t group)
        :generation(std::move(value)),layerIndex(layer),groupIndex(group) { ++liveItems; }
    ~MeshItem() override { --liveItems; }
    void Realize(DrawContext& dc) override {
        if(ready.load(std::memory_order_acquire) || generation->failed.load()) return;
        std::lock_guard<std::mutex> lock(realizeMutex);
        if(ready.load() || generation->failed.load() || !dc.GetVirtualDevice().IsValid()) return;
        try {
            const auto& layer=generation->layers[layerIndex];
            const auto& group=layer.mesh->groups[groupIndex];
            DeviceCaps caps;GetIDisplayManager()->GetDeviceCaps(caps);
            if(caps.FeatureLevel!=Level5_0 || !material.InitializeWithString(CStr(meshShader)))
                throw std::runtime_error("Mesh shader unavailable");
            material.SetFloat3Parameter(_T("CyrusColor"),layer.solid?layer.color:group.color);
            auto addField=[&](MeshChannelCategory category,int usage,int stream,int offset,bool instance) {
                MaterialRequiredStreamElement field;
                field.SetChannelCategory(category);field.SetType(VertexFieldFloat3);
                field.SetUsageIndex(static_cast<unsigned short>(usage));field.SetStreamIndex(static_cast<unsigned char>(stream));
                field.SetOffset(static_cast<unsigned short>(offset));field.SetIsInstanceStream(instance);format.AddStream(field);
            };
            auto upload=[&](std::size_t stride,std::size_t count,void* data) {
                VertexBufferHandle buffer;
                if(!buffer.Initialize(stride,count,data) || !buffer.RealizeToHWMemory(true))
                    throw std::runtime_error("Mesh buffer allocation failed");
                buffers.append(buffer);++uploads;uploadBytes+=stride*count;
            };
            const auto vertices=group.faces.size()*3;
            // Populate one temporary stream at a time. Source triangles and
            // per-instance matrices remain shared; there is no faces*instances CPU loop.
            std::vector<Point3> stream(vertices);
            for(int field=0;field<3;++field) {
                std::size_t vertex=0;
                for(const auto& face:group.faces) for(int corner=0;corner<3;++corner)
                    stream[vertex++]=field==0?face[corner]:(face[field]-face[0]);
                upload(sizeof(Point3),vertices,stream.data());
                addField(field==0?MeshChannelPosition:MeshChannelTexcoord,field==0?0:field-1,field,0,false);
            }
            std::vector<std::array<Point3,4>> instances;instances.reserve(group.instances.size());
            for(const auto& tm:group.instances) instances.push_back({tm.GetRow(0),tm.GetRow(1),tm.GetRow(2),tm.GetRow(3)});
            upload(sizeof(instances[0]),instances.size(),instances.data());
            for(int row=0;row<4;++row) addField(MeshChannelTexcoord,2+row,3,row*sizeof(Point3),true);
            ready.store(true,std::memory_order_release);++generation->ready;
        } catch(...) { generation->failed=true;++failures; }
    }
    void Display(DrawContext& dc) override {
        if(!ready.load(std::memory_order_acquire) || !generation->enabled.load() || generation->failed.load()) return;
        auto& device=dc.GetVirtualDevice();if(!device.IsValid()) return;
        const auto world=dc.GetWorldMatrix();const auto depth=device.GetDepthStencilState();
        const auto raster=device.GetRasterizerState();const auto blend=device.GetBlendState();
        auto meshDepth=depth;meshDepth.SetDepthEnabled(true);meshDepth.SetDepthWriteEnabled(true);
        auto meshRaster=raster;meshRaster.SetCullMode(CullModeNone);meshRaster.SetFillMode(FillSolid);
        auto meshBlend=blend;meshBlend.GetTargetBlendState(0).SetBlendEnabled(false);
        dc.SetWorldMatrix(Matrix3(1));
        const auto& group=generation->layers[layerIndex].mesh->groups[groupIndex];
        IndexBufferHandle noIndices;
        material.Activate(dc);
        for(unsigned int pass=0;pass<material.GetPassCount(dc);++pass) {
            material.ActivatePass(dc,pass);
            device.SetDepthStencilState(meshDepth);device.SetRasterizerState(meshRaster);device.SetBlendState(meshBlend);
            device.SetStreamFormat(format);device.SetVertexStreams(buffers);device.SetIndexBuffer(noIndices);
            device.DrawInstanced(PrimitiveTriangleList,int(group.instances.size()),0,int(group.faces.size()));++draws;
        }
        material.PassesFinished(dc);material.Terminate();
        device.SetDepthStencilState(depth);device.SetRasterizerState(raster);device.SetBlendState(blend);dc.SetWorldMatrix(world);
    }
    std::size_t GetPrimitiveCount() const override {
        const auto& group=generation->layers[layerIndex].mesh->groups[groupIndex];
        return group.faces.size()*group.instances.size();
    }
    void HitTest(HitTestContext&,DrawContext&) override {}
};
