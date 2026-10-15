// Included by point_display.cpp inside cyrus's implementation namespace.
// Uses the same public SDK instancing contract as howto/Graphics/GPUParticle.
// No raw Direct3D device, compute runtime, scene evaluation or MAXScript in Draw.
constexpr const char* meshShader=R"fx(
float4x4 CyrusViewProjection : WORLDVIEWPROJ;
float3 CyrusColor;
bool CyrusUseBands;
float4 CyrusPalette[65];
struct Input {
    float3 p : POSITION;
    float3 a : TEXCOORD0;
    float3 b : TEXCOORD1;
    float3 r0 : TEXCOORD2;
    float3 r1 : TEXCOORD3;
    float3 r2 : TEXCOORD4;
    float3 r3 : TEXCOORD5;
    float owner : TEXCOORD6;
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
    float3 color=CyrusUseBands?CyrusPalette[(int)i.owner].rgb:CyrusColor;
    o.color=float4(color*shade,1);
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
    VertexBufferHandleArray boxBuffers;
    MaterialRequiredStreams format;
    HLSLMaterialHandle material;
    bool sharedBuffers=false;
    bool fullGeometry=false;
    std::atomic<bool> ready{false};
    std::mutex realizeMutex;
public:
    MeshItem(std::shared_ptr<Generation> value,std::size_t layer,std::size_t group,const MeshItem* previous=nullptr)
        :generation(std::move(value)),layerIndex(layer),groupIndex(group) {
        fullGeometry=generation->meshPlan[layer][group].full;
        if(previous && previous->fullGeometry==fullGeometry) {
            buffers=previous->buffers;boxBuffers=previous->boxBuffers;format=previous->format;sharedBuffers=true;++bufferReuses;
            if(sameStyle(previous->generation->layers[previous->layerIndex],generation->layers[layerIndex])) {
                material=previous->material;ready.store(true,std::memory_order_release);++generation->ready;
            }
        }
        ++liveItems;
    }
    ~MeshItem() override { --liveItems; }
    bool reusable(const PointLayer& next,std::size_t group) const {
        const auto& previous=generation->layers[layerIndex];
        return ready.load(std::memory_order_acquire) && !generation->failed.load() && groupIndex==group &&
            previous.mesh==next.mesh;
    }
    void Realize(DrawContext& dc) override {
        if(ready.load(std::memory_order_acquire) || generation->failed.load()) return;
        std::lock_guard<std::mutex> lock(realizeMutex);
        if(ready.load() || generation->failed.load() || !dc.GetVirtualDevice().IsValid()) return;
        try {
            const auto& layer=generation->layers[layerIndex];
            const auto& group=layer.mesh->groups[groupIndex];
            DeviceCaps caps;GetIDisplayManager()->GetDeviceCaps(caps);
            previewFault(3);
            if(caps.FeatureLevel!=Level5_0 || !material.InitializeWithString(CStr(meshShader)))
                throw std::runtime_error("Mesh shader unavailable");
            setIdentification(material,layer,groupIndex,group.color);
            if(!sharedBuffers) {
            amin::diagnostics::StageTimer measurement(amin::diagnostics::Stage::Upload);
            auto addField=[&](MeshChannelCategory category,int usage,int stream,int offset,bool instance) {
                MaterialRequiredStreamElement field;
                field.SetChannelCategory(category);field.SetType(VertexFieldFloat3);
                field.SetUsageIndex(static_cast<unsigned short>(usage));field.SetStreamIndex(static_cast<unsigned char>(stream));
                field.SetOffset(static_cast<unsigned short>(offset));field.SetIsInstanceStream(instance);format.AddStream(field);
            };
            auto upload=[&](VertexBufferHandleArray& target,std::size_t stride,std::size_t count,void* data) {
                VertexBufferHandle buffer;
                if(!buffer.Initialize(stride,count,data) || !buffer.RealizeToHWMemory(true))
                    throw std::runtime_error("Mesh buffer allocation failed");
                target.append(buffer);++uploads;uploadBytes+=stride*count;
            };
            // Populate one temporary stream at a time. Source triangles and
            // per-instance matrices remain shared; there is no faces*instances CPU loop.
            auto geometry=[&](const auto& faces,VertexBufferHandleArray& target) {
                const auto vertices=faces.size()*3;std::vector<Point3> stream(vertices);
                for(int field=0;field<3;++field) {
                    std::size_t vertex=0;
                    for(const auto& face:faces)for(int corner=0;corner<3;++corner)
                        stream[vertex++]=field==0?face[corner]:(face[field]-face[0]);
                    upload(target,sizeof(Point3),vertices,stream.data());geometryUploadBytes+=sizeof(Point3)*vertices;
                }
            };
            if(fullGeometry)geometry(group.faces,buffers);
            const auto& box=layer.mesh->localBounds[groupIndex];const auto lo=box.Min(),hi=box.Max();
            Point3 corners[8];for(int i=0;i<8;++i)corners[i]=Point3(i&1?hi.x:lo.x,i&2?hi.y:lo.y,i&4?hi.z:lo.z);
            const int quads[6][4]={{0,2,3,1},{4,5,7,6},{0,1,5,4},{2,6,7,3},{0,4,6,2},{1,3,7,5}};
            std::array<std::array<Point3,3>,12> boxFaces;std::size_t face=0;
            for(const auto& q:quads){boxFaces[face++]={corners[q[0]],corners[q[1]],corners[q[2]]};boxFaces[face++]={corners[q[0]],corners[q[2]],corners[q[3]]};}
            geometry(boxFaces,boxBuffers);
            for(int field=0;field<3;++field) {
                addField(field==0?MeshChannelPosition:MeshChannelTexcoord,field==0?0:field-1,field,0,false);
            }
            // Nitrous permits instance data in the final vertex buffer only.
            // Ownership is a separate logical field in that immutable payload.
            struct InstanceData { std::array<Point3,4> rows;float owner; };
            static_assert(sizeof(InstanceData)==4*sizeof(Point3)+sizeof(float));
            std::vector<InstanceData> instances;instances.reserve(group.instances.size());
            const auto stride=viewportStride(group.instances.size());
            for(std::size_t k=0;k<group.instances.size();++k) {
                const auto i=k*stride%group.instances.size();
                const auto& tm=group.instances[i];
                instances.push_back({{tm.GetRow(0),tm.GetRow(1),tm.GetRow(2),tm.GetRow(3)},float(group.bandSlots[i])});
            }
            previewFault(4);
            upload(boxBuffers,sizeof(instances[0]),instances.size(),instances.data());
            if(fullGeometry)buffers.append(boxBuffers[3]);
            transformUploadBytes+=4*sizeof(Point3)*instances.size();ownerUploadBytes+=sizeof(float)*instances.size();
            for(int row=0;row<4;++row) addField(MeshChannelTexcoord,2+row,3,row*sizeof(Point3),true);
            MaterialRequiredStreamElement owner;
            owner.SetChannelCategory(MeshChannelTexcoord);owner.SetType(VertexFieldFloat1);owner.SetUsageIndex(6);
            owner.SetStreamIndex(3);owner.SetOffset(4*sizeof(Point3));owner.SetIsInstanceStream(true);format.AddStream(owner);
            }
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
        const bool active=navigating(dc);const auto& plan=generation->meshPlan[layerIndex][groupIndex];
        const auto& quota=active?plan.navigation:plan.idle;
        const bool box=quota.box||!fullGeometry;
        if(active)++navigationDraws;else ++idleDraws;
        IndexBufferHandle noIndices;
        material.Activate(dc);
        for(unsigned int pass=0;pass<material.GetPassCount(dc);++pass) {
            material.ActivatePass(dc,pass);
            device.SetDepthStencilState(meshDepth);device.SetRasterizerState(meshRaster);device.SetBlendState(meshBlend);
            device.SetStreamFormat(format);device.SetVertexStreams(box?boxBuffers:buffers);device.SetIndexBuffer(noIndices);
            if(quota.count){device.DrawInstanced(PrimitiveTriangleList,int(quota.count),0,box?12:int(group.faces.size()));++draws;}
        }
        material.PassesFinished(dc);material.Terminate();
        device.SetDepthStencilState(depth);device.SetRasterizerState(raster);device.SetBlendState(blend);dc.SetWorldMatrix(world);
    }
    std::size_t GetPrimitiveCount() const override {
        const auto& p=generation->meshPlan[layerIndex][groupIndex];
        const auto faces=generation->layers[layerIndex].mesh->groups[groupIndex].faces.size();
        return std::max(p.idle.count*(p.idle.box?12:faces),p.navigation.count*(p.navigation.box?12:faces));
    }
    void HitTest(HitTestContext&,DrawContext&) override {}
};
