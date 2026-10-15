#include "point_preview.h"
#include "diagnostics.h"
#include <iparamb2.h>
#include <SingleWeakRefMaker.h>
#include <Graphics/CustomRenderItemHandle.h>
#include <Graphics/IRenderItemContainer.h>
#include <Graphics/IVirtualDevice.h>
#include <Graphics/IDisplayManager.h>
#include <Graphics/SolidColorMaterialHandle.h>
#include <Graphics/VertexBufferHandle.h>
#include <Graphics/IndexBufferHandle.h>
#include <Graphics/HLSLMaterialHandle.h>
#include <maxscript/maxscript.h>
#include <maxscript/foundation/arrays.h>
#include <maxscript/foundation/numbers.h>
#include <maxscript/foundation/strings.h>
#include <maxscript/maxwrapper/mxsobjects.h>
#include <atomic>
#include <cmath>
#include <mutex>
#include <stdexcept>
#include <string>
#include <maxscript/macros/define_instantiation_functions.h>
#undef ScripterExport
#define ScripterExport __declspec(dllexport)

extern HINSTANCE CyrusEditInstance;
using namespace MaxSDK::Graphics;
namespace cyrus {
PreviewBudget pointPreviewBudget(pointPreviewProcessLimit),meshPreviewBudget(meshPreviewProcessLimit);
std::shared_ptr<PreviewMemory> reservePreviewMemory(PreviewBudget& budget,std::size_t bytes) {
    try { return std::make_shared<PreviewMemory>(budget,bytes); }
    catch(const std::exception&) { throw RuntimeError(_T("Preview resource allocation failed or exceeded its process allowance. Reduce display limits or release older caches.")); }
}
MeshSnapshot::MeshSnapshot(std::vector<PreviewGeometry> value):groups(std::move(value)) {
    cpuBytes=sizeof(*this)+groups.capacity()*sizeof(PreviewGeometry)+groups.size()*2*sizeof(Box3);
    for(const auto& group:groups)cpuBytes+=group.faces.capacity()*sizeof(group.faces[0])+group.instances.capacity()*sizeof(Matrix3)+group.bandSlots.capacity();
    if(cpuBytes>meshPreviewOwnerLimit)throw RuntimeError(_T("Mesh CPU cache exceeds its resource allowance"));
    memory=reservePreviewMemory(meshPreviewBudget,cpuBytes);
    bounds.Init();
    auto hash=[this](const Point3& p) {
        for(int axis=0;axis<3;++axis) if(!std::isfinite(p[axis])) throw RuntimeError(_T("Non-finite mesh preview data"));
        const auto* bytes=reinterpret_cast<const unsigned char*>(&p);
        for(std::size_t i=0;i<sizeof(Point3);++i) { fingerprint^=bytes[i];fingerprint*=1099511628211ULL; }
    };
    for(const auto& group:groups) {
        if(group.bandSlots.size()!=group.instances.size())throw RuntimeError(_T("Mesh Band provenance count mismatch"));
        for(auto slot:group.bandSlots){if(slot>64)throw RuntimeError(_T("Invalid mesh Band palette slot"));fingerprint^=slot;fingerprint*=1099511628211ULL;}
        Box3 local,world;local.Init();world.Init();hash(group.color);
        for(const auto& face:group.faces) for(const auto& p:face) { local+=p;hash(p); }
        if(!group.faces.empty() && !group.instances.empty()) {
            for(const auto& tm:group.instances) {
                for(int row=0;row<4;++row) hash(tm.GetRow(row));
                world+=local*tm;
            }
            bounds+=world;faces+=group.faces.size()*group.instances.size();instances+=group.instances.size();
            bufferBytes+=group.faces.size()*9*sizeof(Point3)+group.instances.size()*(4*sizeof(Point3)+sizeof(float));
            scratchBytes+=group.faces.size()*3*sizeof(Point3)+group.instances.size()*(4*sizeof(Point3)+sizeof(float));
        }
        groupBounds.push_back(world);localBounds.push_back(local);
    }
}
PointSnapshot::PointSnapshot(std::vector<PointGroup> value,bool lineList) : groups(std::move(value)),lines(lineList) {
    cpuBytes=sizeof(*this)+groups.capacity()*sizeof(PointGroup)+groups.size()*sizeof(Box3);
    for(const auto& group:groups)cpuBytes+=group.points.capacity()*sizeof(Point3)+group.bandSlots.capacity();
    if(cpuBytes>pointPreviewOwnerLimit)throw RuntimeError(_T("Point CPU cache exceeds its resource allowance"));
    memory=reservePreviewMemory(pointPreviewBudget,cpuBytes);
    bounds.Init();
    auto hash=[this](const Point3& p) {
        const auto* bytes=reinterpret_cast<const unsigned char*>(&p);
        for(std::size_t i=0;i<sizeof(Point3);++i) { fingerprint^=bytes[i];fingerprint*=1099511628211ULL; }
    };
    for(const auto& group:groups) {
        if(group.bandSlots.size()!=group.points.size())throw RuntimeError(_T("Point Band provenance count mismatch"));
        for(auto slot:group.bandSlots){if(slot>64)throw RuntimeError(_T("Invalid point Band palette slot"));fingerprint^=slot;fingerprint*=1099511628211ULL;}
        if(lines && group.points.size()%2) throw RuntimeError(_T("Incomplete preview line segment"));
        Box3 box;box.Init();
        for(int axis=0;axis<3;++axis) if(!std::isfinite(group.color[axis])) throw RuntimeError(_T("Non-finite preview color"));
        for(const auto& p:group.points) {
            for(int axis=0;axis<3;++axis) if(!std::isfinite(p[axis])) throw RuntimeError(_T("Non-finite preview position"));
            box+=p;bounds+=p;hash(p);hash(group.color);++count;
        }
        groupBounds.push_back(box);
    }
}
namespace {
const Class_ID displayID(0x471d60ab,0x67ca238e);
constexpr std::size_t ownerByteLimit=pointPreviewOwnerLimit,processByteLimit=pointPreviewProcessLimit;
constexpr std::size_t meshOwnerByteLimit=meshPreviewOwnerLimit,meshProcessByteLimit=meshPreviewProcessLimit;
std::atomic<std::size_t> reservedBytes{0},liveItems{0};
std::atomic<std::size_t> meshReservedBytes{0};
std::atomic<std::uint64_t> uploads{0},uploadBytes{0},draws{0},failures{0};
// Vertex upload payloads and SDK material parameter payloads are distinct.
// These are submitted bytes, not a measurement of driver/VRAM traffic.
std::atomic<std::uint64_t> geometryUploadBytes{0},transformUploadBytes{0},ownerUploadBytes{0},styleParameterBytes{0},bufferReuses{0};
std::atomic<bool> interactionHeld{false};
std::atomic<std::uint64_t> navigationDraws{0},idleDraws{0};
// Drawing observes only graphics-context matrices. No scene traversal/evaluation.
bool navigating(DrawContext& dc) {
    struct ViewState { const void* key=nullptr;Matrix44 view,projection;ULONGLONG changed=0; };
    static std::array<ViewState,32> views;
    static std::size_t next=0;
    static std::mutex mutex;
    std::lock_guard<std::mutex> lock(mutex);
    const void* key=dc.GetViewExp();const auto now=GetTickCount64();
    auto it=std::find_if(views.begin(),views.end(),[key](const auto& v){return v.key==key;});
    if(it==views.end()) {
        it=views.begin()+next;next=(next+1)%views.size();
        *it={key,dc.GetViewMatrix(),dc.GetProjectionMatrix(),0};
    } else if(it->view!=dc.GetViewMatrix() || it->projection!=dc.GetProjectionMatrix()) {
        it->view=dc.GetViewMatrix();it->projection=dc.GetProjectionMatrix();it->changed=now;
    }
    return interactionHeld.load() || (it->changed && now-it->changed<350);
}
#ifdef CYRUS_PREVIEW_TEST_FAULTS
std::atomic<int> previewFaultStage{0},previewFaultOccurrence{0},previewFaultHits{0};
void previewFault(int stage) {
    if(previewFaultStage.load()==stage&&++previewFaultHits>=previewFaultOccurrence.load())
        throw std::runtime_error("Injected owned preview resource failure");
}
#else
inline void previewFault(int) {}
#endif

struct Generation {
    const std::vector<PointLayer> layers;
    std::atomic<bool> enabled{true},failed{false},submitted{false};
    std::atomic<std::size_t> ready{0};
    std::size_t count=0,groups=0,reservation=0,meshReservation=0;
    std::shared_ptr<PreviewMemory> pointMemory,meshMemory;
    bool hasMesh=false;
    bool memoryReduced=false;
    struct DrawGroup { ViewportQuota idle,navigation;bool full=false; };
    std::vector<std::vector<DrawGroup>> pointPlan,meshPlan;
    Box3 bounds;
    void plan(bool boxes) {
        pointPlan.clear();meshPlan.clear();
        pointPlan.resize(layers.size());meshPlan.resize(layers.size());
        for(std::size_t l=0;l<layers.size();++l) {
            pointPlan[l].resize(layers[l].snapshot->groups.size());
            if(layers[l].mesh)meshPlan[l].resize(layers[l].mesh->groups.size());
        }
        for(int mode=0;mode<3;++mode) {
            std::vector<ViewportDemand> input;std::vector<std::pair<std::size_t,std::size_t>> owners;
            ViewportLimits limits;
            for(std::size_t l=0;l<layers.size();++l) {
                const auto& layer=layers[l];if(layer.snapshot->lines)continue;
                limits=layer.limits;
                if(mode==0) for(std::size_t g=0;g<layer.snapshot->groups.size();++g) {
                    input.push_back({layer.snapshot->groups[g].points.size(),1});owners.emplace_back(l,g);
                }
                if(layer.mesh && ((mode==2 && layer.geometryMode==4)||(mode==1 && layer.geometryMode!=4)))
                    for(std::size_t g=0;g<layer.mesh->groups.size();++g) {
                        const auto& group=layer.mesh->groups[g];
                        input.push_back({group.faces.empty()?0:group.instances.size(),mode==2?group.faces.size():1});owners.emplace_back(l,g);
                    }
            }
            auto idle=viewportQuotas(input,limits.values[mode*2],mode==2,boxes);
            auto active=viewportQuotas(input,limits.values[mode*2+1],mode==2,boxes);
            for(std::size_t i=0;i<owners.size();++i) {
                const auto [l,g]=owners[i];auto& p=mode==0?pointPlan[l][g]:meshPlan[l][g];
                if(mode==2 && layers[l].mesh->groups[g].reducedBox)idle[i].box=active[i].box=true;
                p={idle[i],active[i],mode!=0 && ((!idle[i].box && idle[i].count)||(!active[i].box && active[i].count))};
            }
        }
        for(std::size_t l=0;l<layers.size();++l)if(layers[l].snapshot->lines)
            for(std::size_t g=0;g<pointPlan[l].size();++g) {
                const auto n=layers[l].snapshot->groups[g].points.size()/2;
                pointPlan[l][g]={{n,1,false},{n,1,false},false};
            }
    }
    explicit Generation(std::vector<PointLayer> value):layers(std::move(value)) {
        bounds.Init();
        std::size_t vertices=0,pointCPU=0,meshCPU=0,pointGroups=0,meshGroups=0,paletteBytes=0;
        for(const auto& layer:layers) {
            vertices+=layer.snapshot->count;
            pointCPU+=layer.snapshot->cpuBytes;
            if(layer.palette)paletteBytes+=sizeof(PreviewPalette)+layer.palette->sourceColors.capacity()*sizeof(Point3)+layer.palette->bandIDs.capacity()*sizeof(std::uint64_t);
            if(!layer.snapshot->lines) count+=layer.snapshot->count;
            if(layer.snapshot->count) bounds+=layer.snapshot->bounds;
            for(const auto& group:layer.snapshot->groups) if(!group.points.empty()) {++groups;++pointGroups;}
            if(layer.mesh) {
                hasMesh=true;meshCPU+=layer.mesh->cpuBytes;
                if(layer.mesh->faces) bounds+=layer.mesh->bounds;
                for(const auto& group:layer.mesh->groups) if(!group.faces.empty() && !group.instances.empty()) {++groups;++meshGroups;}
            }
        }
        // Hardware + SDK system copies + simultaneous upload temporaries. Item
        // and palette allowances cover fallback bookkeeping. Emergency drawing
        // submits only bounded centre markers, never CPU source triangles.
        const auto bytes=vertices*(3*(sizeof(Point3)+sizeof(float)))+pointGroups*4096+paletteBytes;
        meshReservation=0;plan(false);
        auto meshBytesForPlan=[&]() {
            std::size_t buffer=0,scratch=0;
            for(std::size_t l=0;l<layers.size();++l)if(layers[l].mesh)
                for(std::size_t g=0;g<meshPlan[l].size();++g) {
                    const auto& group=layers[l].mesh->groups[g];if(group.instances.empty()||group.faces.empty())continue;
                    const auto faces=meshPlan[l][g].full?group.faces.size():0;
                    // Full and inexpensive box streams share one transform buffer.
                    buffer+=(faces+12)*9*sizeof(Point3)+group.instances.size()*(4*sizeof(Point3)+sizeof(float));
                    scratch+=std::max<std::size_t>(faces,12)*3*sizeof(Point3)+group.instances.size()*(4*sizeof(Point3)+sizeof(float));
                }
            return 2*buffer+scratch+meshGroups*4096;
        };
        auto meshBytes=meshBytesForPlan();
        if(meshCPU+meshBytes>meshOwnerByteLimit || meshBytes>meshProcessByteLimit-std::min(meshProcessByteLimit,meshPreviewBudget.used())) {
            memoryReduced=true;plan(true);meshBytes=meshBytesForPlan();
        }
        if(pointCPU+bytes>ownerByteLimit || meshCPU+meshBytes>meshOwnerByteLimit || groups>1024) { failed=true;++failures;return; }
        try {
            pointMemory=std::make_shared<PreviewMemory>(pointPreviewBudget,bytes);
            meshMemory=std::make_shared<PreviewMemory>(meshPreviewBudget,meshBytes);
        } catch(...) { pointMemory.reset();meshMemory.reset();failed=true;++failures;return; }
        reservation=bytes;meshReservation=meshBytes;reservedBytes+=bytes;meshReservedBytes+=meshBytes;
    }
    ~Generation() { reservedBytes-=reservation;meshReservedBytes-=meshReservation; }
};

bool sameLayers(const std::vector<PointLayer>& a,const std::vector<PointLayer>& b) {
    if(a.size()!=b.size()) return false;
    for(std::size_t i=0;i<a.size();++i)
        if(a[i].snapshot!=b[i].snapshot || a[i].mesh!=b[i].mesh || a[i].geometryMode!=b[i].geometryMode || a[i].limits!=b[i].limits || a[i].solid!=b[i].solid || (a[i].solid && a[i].color!=b[i].color) || !samePalette(a[i].palette,b[i].palette)) return false;
    return true;
}

constexpr const char* pointShader=R"fx(
float4x4 CyrusViewProjection : WORLDVIEWPROJ;
float3 CyrusColor;
bool CyrusUseBands;
float4 CyrusPalette[65];
struct Input { float3 p : POSITION; float owner : TEXCOORD0; };
struct Output { float4 p : SV_POSITION; float4 color : COLOR0; };
Output pointVS(Input i) {
    Output o;o.p=mul(float4(i.p,1),CyrusViewProjection);
    o.color=CyrusUseBands?CyrusPalette[(int)i.owner]:float4(CyrusColor,1);return o;
}
float4 pointPS(Output i) : SV_Target { return i.color; }
technique11 CyrusPoints { pass P0 {
    SetVertexShader(CompileShader(vs_5_0,pointVS()));
    SetGeometryShader(NULL);
    SetPixelShader(CompileShader(ps_5_0,pointPS()));
} }
)fx";

bool sameStyle(const PointLayer& a,const PointLayer& b) {
    return a.solid==b.solid&&(!a.solid||a.color==b.color)&&samePalette(a.palette,b.palette);
}
void setIdentification(HLSLMaterialHandle& material,const PointLayer& layer,std::size_t source,Point3 fallback) {
    const bool bands=!layer.solid&&layer.palette&&layer.palette->mode==3;
    material.SetFloat3Parameter(_T("CyrusColor"),layer.solid?layer.color:previewColor(layer.palette.get(),source,0,fallback));
    material.SetBoolParameter(_T("CyrusUseBands"),bands?TRUE:FALSE);
    styleParameterBytes+=sizeof(Point3)+sizeof(BOOL);
    if(bands) {
        std::array<Point4,65> colors;
        for(std::size_t i=0;i<colors.size();++i){const auto c=layer.palette->bandColors[i];colors[i]=Point4(c.x,c.y,c.z,1.f);}
        material.SetFloat4ArrayParameter(_T("CyrusPalette"),colors.data(),unsigned(colors.size()));
        styleParameterBytes+=sizeof(colors);
    }
}

class PointItem : public ICustomRenderItem {
    const std::shared_ptr<Generation> generation;
    const std::size_t layerIndex,groupIndex;
    VertexBufferHandleArray buffers;
    MaterialRequiredStreams format;
    HLSLMaterialHandle material;
    bool sharedBuffers=false;
    std::atomic<bool> ready{false};
    std::mutex realizeMutex;
public:
    PointItem(std::shared_ptr<Generation> value,std::size_t layer,std::size_t group,const PointItem* previous=nullptr)
        :generation(std::move(value)),layerIndex(layer),groupIndex(group) {
        if(previous) {
            // SDK handles retain their resources. A new item owns the new
            // generation; no old item/controller pointer survives publication.
            buffers=previous->buffers;format=previous->format;sharedBuffers=true;++bufferReuses;
            if(sameStyle(previous->generation->layers[previous->layerIndex],generation->layers[layerIndex])) {
                material=previous->material;ready.store(true,std::memory_order_release);++generation->ready;
            }
        }
        ++liveItems;
    }
    ~PointItem() override { --liveItems; }
    bool reusable(const PointLayer& next,std::size_t group) const {
        const auto& previous=generation->layers[layerIndex];
        return ready.load(std::memory_order_acquire) && !generation->failed.load() && groupIndex==group &&
            previous.snapshot==next.snapshot;
    }
    void Realize(DrawContext& dc) override {
        if(ready.load(std::memory_order_acquire) || generation->failed.load()) return;
        std::lock_guard<std::mutex> lock(realizeMutex);
        if(ready.load() || generation->failed.load() || !dc.GetVirtualDevice().IsValid()) return;
        try {
            const auto& layer=generation->layers[layerIndex];
            const auto& group=layer.snapshot->groups[groupIndex];
            previewFault(1);
            if(!material.InitializeWithString(CStr(pointShader))) throw std::runtime_error("Point material initialization failed");
            setIdentification(material,layer,groupIndex,group.color);
            if(!sharedBuffers) {
            amin::diagnostics::StageTimer measurement(amin::diagnostics::Stage::Upload);
            MaterialRequiredStreamElement position;
            position.SetChannelCategory(MeshChannelPosition);position.SetType(VertexFieldFloat3);format.AddStream(position);
            VertexBufferHandle buffer;
            // Keep the SDK system copy as well as the immutable CPU snapshot.
            // Hardware resource management remains with Nitrous; no device pointer is retained.
            std::vector<Point3> positions;positions.reserve(group.points.size());
            std::vector<float> slots;slots.reserve(group.points.size());
            const auto stride=viewportStride(group.points.size());
            for(std::size_t k=0;k<group.points.size();++k) {
                const auto i=layer.snapshot->lines?k:k*stride%group.points.size();
                positions.push_back(group.points[i]);slots.push_back(float(group.bandSlots[i]));
            }
            if(!buffer.Initialize(sizeof(Point3),positions.size(),positions.data()) || !buffer.RealizeToHWMemory(true))
                throw std::runtime_error("Point buffer allocation failed");
            buffers.append(buffer);++uploads;uploadBytes+=group.points.size()*sizeof(Point3);geometryUploadBytes+=group.points.size()*sizeof(Point3);
            VertexBufferHandle owners;
            previewFault(2);
            if(!owners.Initialize(sizeof(float),slots.size(),slots.data())||!owners.RealizeToHWMemory(true))
                throw std::runtime_error("Point owner buffer allocation failed");
            buffers.append(owners);++uploads;uploadBytes+=slots.size()*sizeof(float);ownerUploadBytes+=slots.size()*sizeof(float);
            MaterialRequiredStreamElement owner;
            owner.SetChannelCategory(MeshChannelTexcoord);owner.SetType(VertexFieldFloat1);owner.SetUsageIndex(0);owner.SetStreamIndex(1);format.AddStream(owner);
            }
            ready.store(true,std::memory_order_release);++generation->ready;
        } catch(...) { generation->failed=true;++failures; }
    }
    void Display(DrawContext& dc) override {
        if(!ready.load(std::memory_order_acquire) || !generation->enabled.load() || generation->failed.load()) return;
        auto& device=dc.GetVirtualDevice();if(!device.IsValid()) return;
        const auto originalWorld=dc.GetWorldMatrix();
        const auto originalDepth=device.GetDepthStencilState();
        auto depth=originalDepth;depth.SetDepthEnabled(false);depth.SetDepthWriteEnabled(false);
        // Cache positions already include each exact scatter placement transform.
        dc.SetWorldMatrix(Matrix3(1));
        IndexBufferHandle noIndices;
        material.Activate(dc);
        for(unsigned int pass=0;pass<material.GetPassCount(dc);++pass) {
            material.ActivatePass(dc,pass);device.SetDepthStencilState(depth);
            device.SetStreamFormat(format);device.SetVertexStreams(buffers);device.SetIndexBuffer(noIndices);
            const auto& snapshot=*generation->layers[layerIndex].snapshot;
            const bool active=navigating(dc);const auto& plan=generation->pointPlan[layerIndex][groupIndex];
            const auto count=active?plan.navigation.count:plan.idle.count;
            if(count){device.Draw(snapshot.lines?PrimitiveLineList:PrimitivePointList,0,int(count));++draws;}
            if(active)++navigationDraws;else ++idleDraws;
        }
        material.PassesFinished(dc);material.Terminate();
        device.SetDepthStencilState(originalDepth);dc.SetWorldMatrix(originalWorld);
    }
    std::size_t GetPrimitiveCount() const override {
        const auto& snapshot=*generation->layers[layerIndex].snapshot;
        return snapshot.groups[groupIndex].points.size()/(snapshot.lines?2:1);
    }
    // Picking remains on the existing controller icon / CS Edit tool.
    void HitTest(HitTestContext&,DrawContext&) override {}
};

#include "mesh_display.inc"

// Weak reference: deleting a controller immediately disables its items even
// before the script's idle cleanup runs. Never keep a raw scene pointer in Display.
class ControllerWatch : public MaxSDK::SingleWeakRefMaker {
public:
    std::weak_ptr<Generation> generation;
    void update() {
        if(auto value=generation.lock()) {
            auto* node=static_cast<INode*>(GetRef());
            value->enabled=node && !node->IsHidden();
        }
    }
    RefResult NotifyRefChanged(const Interval& interval,RefTargetHandle target,PartID& part,RefMessage message,BOOL propagate) override {
        const auto result=SingleWeakRefMaker::NotifyRefChanged(interval,target,part,message,propagate);
        update();return result;
    }
};

class PointDisplay final : public HelperObject {
    std::vector<RefPtr<ICustomRenderItem>> items;
    std::vector<Box3> itemBounds;
public:
    ControllerWatch controller;
    std::shared_ptr<Generation> generation;
    std::uint64_t revision=0,prepares=0,nodeUpdates=0;
    ~PointDisplay() override { if(generation) generation->enabled=false; }
    Class_ID ClassID() override { return displayID; }
    void GetClassName(MSTR& name,bool) const override { name=_T("Cyrus Point Display"); }
    const MCHAR* GetObjectName(bool) const override { return _T("Cyrus Point Display"); }
    void InitNodeName(MSTR& name) override { name=_T("Cyrus Point Display"); }
    void DeleteThis() override { delete this; }
    ObjectState Eval(TimeValue) override { return ObjectState(this); }
    Interval ObjectValidity(TimeValue) override { return FOREVER; }
    CreateMouseCallBack* GetCreateMouseCallBack() override { return nullptr; }
    void BeginEditParams(IObjParam*,ULONG,Animatable*) override {}
    void EndEditParams(IObjParam*,ULONG,Animatable*) override {}
    int NumRefs() override { return 0; }
    RefTargetHandle GetReference(int) override { return nullptr; }
    void SetReference(int,RefTargetHandle) override {}
    RefResult NotifyRefChanged(const Interval&,RefTargetHandle,PartID&,RefMessage,BOOL) override { return REF_SUCCEED; }
    RefTargetHandle Clone(RemapDir& remap) override {
        // Disposable display nodes never inherit another controller's live data.
        auto* out=new PointDisplay;BaseClone(this,out,remap);return out;
    }
    Box3 worldBounds() const {
        return generation && generation->groups ? generation->bounds : Box3(Point3(-.001f,-.001f,-.001f),Point3(.001f,.001f,.001f));
    }
    void GetLocalBoundBox(TimeValue t,INode* node,ViewExp*,Box3& box) override { box=worldBounds()*Inverse(node->GetObjectTM(t)); }
    void GetWorldBoundBox(TimeValue,INode*,ViewExp*,Box3& box) override { box=worldBounds(); }
    void GetDeformBBox(TimeValue,Box3& box,Matrix3* tm,BOOL) override { box=worldBounds();if(tm)box=box**tm; }
    int Display(TimeValue,INode*,ViewExp*,int) override { return 0; }
    int HitTest(TimeValue,INode*,int,int,int,IPoint2*,ViewExp*) override { return 0; }
    void Snap(TimeValue,INode*,SnapInfo*,IPoint2*,ViewExp*) override {}
    unsigned long GetObjectDisplayRequirement() const override { return 0; }
    bool PrepareDisplay(const UpdateDisplayContext&) override {
        ++prepares;
        // CPU item/container allocation is staged by publish(), while the old
        // generation is still owned. Nitrous realizes the staged SDK items.
        return true;
    }
    bool UpdatePerNodeItems(const UpdateDisplayContext&,UpdateNodeContext&,IRenderItemContainer& target) override {
        ++nodeUpdates;
        if(generation && !generation->failed.load()) {
            for(std::size_t index=0;index<items.size();++index) {
                CustomRenderItemHandle handle;handle.Initialize();
                handle.SetVisibilityGroup(RenderItemVisible_Gizmo);handle.SetObjectBox(itemBounds[index]);
                handle.SetCustomImplementation(items[index].GetPointer());target.AddRenderItem(handle);
            }
            generation->submitted=true;
        }
        return true;
    }
#include "point_publication.inc"
};

PointDisplay* owner(INode* node) {
    auto* object=node?node->GetObjectRef():nullptr;
    if(!object || object->ClassID()!=displayID) throw RuntimeError(_T("Expected an unmodified Cyrus point display owner"));
    return static_cast<PointDisplay*>(object);
}
class DisplayDesc final : public ClassDesc2 {
public:
    int IsPublic() override { return FALSE; }
    void* Create(BOOL) override { return new PointDisplay; }
    const MCHAR* ClassName() override { return _T("Cyrus Point Display"); }
    const MCHAR* NonLocalizedClassName() override { return _T("Cyrus Point Display"); }
    SClass_ID SuperClassID() override { return HELPER_CLASS_ID; }
    Class_ID ClassID() override { return displayID; }
    const MCHAR* Category() override { return _T("Cyrus Internal"); }
    const MCHAR* InternalName() override { return _T("CyrusPointDisplay"); }
    HINSTANCE HInstance() override { return CyrusEditInstance; }
};
}
bool publishPoints(INode* helper,INode* controller,std::vector<PointLayer> layers) {
    if(!controller || !IsRetainedModeEnabled()) return false;
    return owner(helper)->publish(controller,std::move(layers));
}
bool pointsMatch(INode* helper,const std::vector<PointLayer>& layers) {
    const auto* display=owner(helper);const auto& gen=display->generation;
    if(gen && !sameLayers(gen->layers,layers)) { gen->enabled=false;return false; }
    // Off-screen items need not be realized yet. Nitrous realizes visible
    // items before drawing; requiring every item ready would defeat culling.
    return IsRetainedModeEnabled() && gen && gen->enabled.load() && !gen->failed.load() &&
        gen->submitted.load();
}
}

extern "C" __declspec(dllexport) ClassDesc* CyrusPointDisplayDesc() { static cyrus::DisplayDesc desc;return &desc; }

def_visible_primitive(cyrusRetainedCreate,"cyrusRetainedCreate");
Value* cyrusRetainedCreate_cf(Value**,int count) {
    check_arg_count(cyrusRetainedCreate,0,count);
    if(!IsRetainedModeEnabled()) return &undefined;
    auto* node=GetCOREInterface()->CreateObjectNode(new cyrus::PointDisplay);
    if(!node) return &undefined;
    node->SetName(_T("Cyrus_Point_Display"));node->SetRenderable(FALSE);
    node->IgnoreExtents(TRUE);
    node->SetNodeTM(GetCOREInterface()->GetTime(),Matrix3(1));
    return MAXNode::intern(node);
}
def_visible_primitive(cyrusRetainedAvailable,"cyrusRetainedAvailable");
Value* cyrusRetainedAvailable_cf(Value**,int count) {
    check_arg_count(cyrusRetainedAvailable,0,count);
    return IsRetainedModeEnabled()?&true_value:&false_value;
}

def_visible_primitive(cyrusViewportPolicyVersion,"cyrusViewportPolicyVersion");
Value* cyrusViewportPolicyVersion_cf(Value**,int count) {
    check_arg_count(cyrusViewportPolicyVersion,0,count);return Integer::intern(2);
}
def_visible_primitive(cyrusViewportPointCapacity,"cyrusViewportPointCapacity");
Value* cyrusViewportPointCapacity_cf(Value**,int count) {
    check_arg_count(cyrusViewportPointCapacity,0,count);
    return Integer::intern(static_cast<int>(cyrus::pointPreviewPreparationLimit));
}
def_visible_primitive(cyrusRetainedInteraction,"cyrusRetainedInteraction");
Value* cyrusRetainedInteraction_cf(Value** args,int count) {
    check_arg_count(cyrusRetainedInteraction,1,count);cyrus::interactionHeld=args[0]->to_bool()!=FALSE;return &ok;
}
// Version, idle/nav points, idle/nav proxies, idle/nav mesh triangles,
// idle/nav box instances, memory-reduced, idle/nav draw calls.
def_visible_primitive(cyrusRetainedViewportStats,"cyrusRetainedViewportStats");
Value* cyrusRetainedViewportStats_cf(Value** args,int count) {
    check_arg_count(cyrusRetainedViewportStats,1,count);
    const auto* display=cyrus::owner(args[0]->to_node());const auto& gen=display->generation;
    std::array<std::uint64_t,12> values{};values[0]=1;
    if(gen) {
        values[9]=gen->memoryReduced;
        for(std::size_t l=0;l<gen->layers.size();++l) {
            if(!gen->layers[l].snapshot->lines)for(const auto& p:gen->pointPlan[l]){values[1]+=p.idle.count;values[2]+=p.navigation.count;}
            for(const auto& p:gen->meshPlan[l]) {
                if(gen->layers[l].geometryMode==4){values[5]+=p.idle.count*p.idle.cost;values[6]+=p.navigation.count*p.navigation.cost;}
                else {values[3]+=p.idle.count;values[4]+=p.navigation.count;}
                if(p.idle.box)values[7]+=p.idle.count;if(p.navigation.box)values[8]+=p.navigation.count;
            }
        }
    }
    values[10]=cyrus::idleDraws.load();values[11]=cyrus::navigationDraws.load();
    one_typed_value_local(Array* result);vl.result=new Array(12);
    for(auto value:values)vl.result->append(Integer64::intern(value));return_value(vl.result);
}
def_visible_primitive(cyrusRetainedStats,"cyrusRetainedStats");
Value* cyrusRetainedStats_cf(Value** args,int count) {
    check_arg_count(cyrusRetainedStats,1,count);
    const auto* display=cyrus::owner(args[0]->to_node());const auto& gen=display->generation;
    one_typed_value_local(Array* result);vl.result=new Array(13);
    const std::uint64_t values[]={gen?gen->count:0,gen?gen->groups:0,display->revision,display->prepares,display->nodeUpdates,
        cyrus::uploads.load(),cyrus::uploadBytes.load(),cyrus::draws.load(),cyrus::failures.load(),cyrus::liveItems.load(),cyrus::reservedBytes.load(),
        gen?(gen->failed.load()?2ULL:(gen->ready.load()==gen->groups?1ULL:0ULL)):0ULL};
    for(auto value:values) vl.result->append(Integer64::intern(value));
    std::wstring hashes;
    if(gen) for(const auto& layer:gen->layers) { hashes+=std::to_wstring(layer.mesh?layer.mesh->fingerprint:layer.snapshot->fingerprint);hashes+=L";"; }
    vl.result->append(new String(hashes.c_str()));return_value(vl.result);
}

// Mesh-specific telemetry; existing point telemetry indices remain stable.
def_visible_primitive(cyrusRetainedMeshStats,"cyrusRetainedMeshStats");
Value* cyrusRetainedMeshStats_cf(Value** args,int count) {
    check_arg_count(cyrusRetainedMeshStats,1,count);
    const auto* display=cyrus::owner(args[0]->to_node());const auto& gen=display->generation;
    std::size_t faces=0,instances=0,sourceFaces=0;
    if(gen) for(const auto& layer:gen->layers) if(layer.mesh) {
        faces+=layer.mesh->faces;instances+=layer.mesh->instances;
        for(const auto& group:layer.mesh->groups) if(!group.instances.empty()) sourceFaces+=group.faces.size();
    }
    one_typed_value_local(Array* result);vl.result=new Array(7);
    for(auto value:{faces,instances,sourceFaces,gen?gen->meshReservation:0,cyrus::meshReservedBytes.load(),cyrus::meshOwnerByteLimit,cyrus::meshProcessByteLimit})
        vl.result->append(Integer64::intern(value));
    return_value(vl.result);
}

// Version 1: position/source-geometry, transforms, owners, material parameters,
// reused item buffers. Parameter bytes are not claimed as physical GPU uploads.
def_visible_primitive(cyrusRetainedStreamStats,"cyrusRetainedStreamStats");
Value* cyrusRetainedStreamStats_cf(Value**,int count) {
    check_arg_count(cyrusRetainedStreamStats,0,count);
    one_typed_value_local(Array* result);vl.result=new Array(6);
    vl.result->append(Integer::intern(1));
    for(auto value:{cyrus::geometryUploadBytes.load(),cyrus::transformUploadBytes.load(),cyrus::ownerUploadBytes.load(),
                    cyrus::styleParameterBytes.load(),cyrus::bufferReuses.load()})vl.result->append(Integer64::intern(value));
    return_value(vl.result);
}

// Version 1: point live/peak/limit, mesh live/peak/limit. Includes CPU snapshots,
// palette data, staging payloads and conservative GPU/SDK-copy reservations.
def_visible_primitive(cyrusPreviewResourceStats,"cyrusPreviewResourceStats");
Value* cyrusPreviewResourceStats_cf(Value**,int count) {
    check_arg_count(cyrusPreviewResourceStats,0,count);
    one_typed_value_local(Array* result);vl.result=new Array(7);vl.result->append(Integer::intern(1));
    for(auto value:{cyrus::pointPreviewBudget.used(),cyrus::pointPreviewBudget.highWater(),cyrus::pointPreviewProcessLimit,
        cyrus::meshPreviewBudget.used(),cyrus::meshPreviewBudget.highWater(),cyrus::meshPreviewProcessLimit})
        vl.result->append(Integer64::intern(value));
    return_value(vl.result);
}

#ifdef CYRUS_PREVIEW_TEST_FAULTS
def_visible_primitive(cyrusOwnedPreviewFault,"cyrusOwnedPreviewFault");
Value* cyrusOwnedPreviewFault_cf(Value** args,int count) {
    check_arg_count(cyrusOwnedPreviewFault,2,count);
    const auto stage=args[0]->to_int(),occurrence=args[1]->to_int();
    if(stage<0||stage>4||occurrence<0)throw RuntimeError(_T("Invalid owned preview fault"));
    cyrus::previewFaultStage=stage;cyrus::previewFaultOccurrence=occurrence;cyrus::previewFaultHits=0;
    return &ok;
}
#endif
