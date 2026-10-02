#include "point_preview.h"
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
MeshSnapshot::MeshSnapshot(std::vector<PreviewGeometry> value):groups(std::move(value)) {
    bounds.Init();
    auto hash=[this](const Point3& p) {
        for(int axis=0;axis<3;++axis) if(!std::isfinite(p[axis])) throw RuntimeError(_T("Non-finite mesh preview data"));
        const auto* bytes=reinterpret_cast<const unsigned char*>(&p);
        for(std::size_t i=0;i<sizeof(Point3);++i) { fingerprint^=bytes[i];fingerprint*=1099511628211ULL; }
    };
    for(const auto& group:groups) {
        Box3 local,world;local.Init();world.Init();hash(group.color);
        for(const auto& face:group.faces) for(const auto& p:face) { local+=p;hash(p); }
        if(!group.faces.empty() && !group.instances.empty()) {
            for(const auto& tm:group.instances) {
                for(int row=0;row<4;++row) hash(tm.GetRow(row));
                world+=local*tm;
            }
            bounds+=world;faces+=group.faces.size()*group.instances.size();instances+=group.instances.size();
            bufferBytes+=group.faces.size()*9*sizeof(Point3)+group.instances.size()*4*sizeof(Point3);
        }
        groupBounds.push_back(world);
    }
}
PointSnapshot::PointSnapshot(std::vector<PointGroup> value) : groups(std::move(value)) {
    bounds.Init();
    auto hash=[this](const Point3& p) {
        const auto* bytes=reinterpret_cast<const unsigned char*>(&p);
        for(std::size_t i=0;i<sizeof(Point3);++i) { fingerprint^=bytes[i];fingerprint*=1099511628211ULL; }
    };
    for(const auto& group:groups) {
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
constexpr std::size_t ownerByteLimit=64*1024*1024,processByteLimit=128*1024*1024;
constexpr std::size_t meshOwnerByteLimit=512ull*1024*1024,meshProcessByteLimit=1024ull*1024*1024;
std::atomic<std::size_t> reservedBytes{0},liveItems{0};
std::atomic<std::size_t> meshReservedBytes{0};
std::atomic<std::uint64_t> uploads{0},uploadBytes{0},draws{0},failures{0};

struct Generation {
    const std::vector<PointLayer> layers;
    std::atomic<bool> enabled{true},failed{false},submitted{false};
    std::atomic<std::size_t> ready{0};
    std::size_t count=0,groups=0,reservation=0,meshReservation=0;
    bool hasMesh=false;
    Box3 bounds;
    explicit Generation(std::vector<PointLayer> value):layers(std::move(value)) {
        bounds.Init();
        for(const auto& layer:layers) {
            count+=layer.snapshot->count;
            if(layer.snapshot->count) bounds+=layer.snapshot->bounds;
            for(const auto& group:layer.snapshot->groups) if(!group.points.empty()) ++groups;
            if(layer.mesh) {
                hasMesh=true;meshReservation+=layer.mesh->bufferBytes;
                if(layer.mesh->faces) bounds+=layer.mesh->bounds;
                for(const auto& group:layer.mesh->groups) if(!group.faces.empty() && !group.instances.empty()) ++groups;
            }
        }
        const auto bytes=count*sizeof(Point3);
        const auto meshBytes=meshReservation;meshReservation=0;
        if(bytes>ownerByteLimit || meshBytes>meshOwnerByteLimit || groups>1024) { failed=true;++failures;return; }
        auto used=reservedBytes.load();
        do {
            if(bytes>processByteLimit-used) { failed=true;++failures;return; }
        } while(!reservedBytes.compare_exchange_weak(used,used+bytes));
        reservation=bytes;
        used=meshReservedBytes.load();
        do {
            if(meshBytes>meshProcessByteLimit-used) { failed=true;++failures;return; }
        } while(!meshReservedBytes.compare_exchange_weak(used,used+meshBytes));
        meshReservation=meshBytes;
    }
    ~Generation() { reservedBytes-=reservation;meshReservedBytes-=meshReservation; }
};

bool sameLayers(const std::vector<PointLayer>& a,const std::vector<PointLayer>& b) {
    if(a.size()!=b.size()) return false;
    for(std::size_t i=0;i<a.size();++i)
        if(a[i].snapshot!=b[i].snapshot || a[i].mesh!=b[i].mesh || a[i].solid!=b[i].solid || (a[i].solid && a[i].color!=b[i].color)) return false;
    return true;
}

class PointItem : public ICustomRenderItem {
    const std::shared_ptr<Generation> generation;
    const std::size_t layerIndex,groupIndex;
    VertexBufferHandleArray buffers;
    MaterialRequiredStreams format;
    SolidColorMaterialHandle material;
    std::atomic<bool> ready{false};
    std::mutex realizeMutex;
public:
    PointItem(std::shared_ptr<Generation> value,std::size_t layer,std::size_t group)
        :generation(std::move(value)),layerIndex(layer),groupIndex(group) { ++liveItems; }
    ~PointItem() override { --liveItems; }
    void Realize(DrawContext& dc) override {
        if(ready.load(std::memory_order_acquire) || generation->failed.load()) return;
        std::lock_guard<std::mutex> lock(realizeMutex);
        if(ready.load() || generation->failed.load() || !dc.GetVirtualDevice().IsValid()) return;
        try {
            const auto& layer=generation->layers[layerIndex];
            const auto& group=layer.snapshot->groups[groupIndex];
            if(!material.Initialize()) throw std::runtime_error("Point material initialization failed");
            const auto color=layer.solid?layer.color:group.color;
            material.SetColor(AColor(color.x,color.y,color.z,1.f));
            MaterialRequiredStreamElement position;
            position.SetChannelCategory(MeshChannelPosition);position.SetType(VertexFieldFloat3);format.AddStream(position);
            VertexBufferHandle buffer;
            // Keep the SDK system copy as well as the immutable CPU snapshot.
            // Hardware resource management remains with Nitrous; no device pointer is retained.
            if(!buffer.Initialize(sizeof(Point3),group.points.size(),const_cast<Point3*>(group.points.data())) || !buffer.RealizeToHWMemory(true))
                throw std::runtime_error("Point buffer allocation failed");
            buffers.append(buffer);++uploads;uploadBytes+=group.points.size()*sizeof(Point3);
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
            device.Draw(PrimitivePointList,0,int(generation->layers[layerIndex].snapshot->groups[groupIndex].points.size()));++draws;
        }
        material.PassesFinished(dc);material.Terminate();
        device.SetDepthStencilState(originalDepth);dc.SetWorldMatrix(originalWorld);
    }
    std::size_t GetPrimitiveCount() const override { return generation->layers[layerIndex].snapshot->groups[groupIndex].points.size(); }
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
    bool itemsDirty=true;
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
        if(itemsDirty) {
            items.clear();itemBounds.clear();
            if(generation && !generation->failed.load())
                for(std::size_t l=0;l<generation->layers.size();++l) {
                    const auto& layer=generation->layers[l];
                    for(std::size_t g=0;g<layer.snapshot->groups.size();++g)
                        if(!layer.snapshot->groups[g].points.empty()) {
                            items.emplace_back(new PointItem(generation,l,g));itemBounds.push_back(layer.snapshot->groupBounds[g]);
                        }
                    if(layer.mesh) for(std::size_t g=0;g<layer.mesh->groups.size();++g)
                        if(!layer.mesh->groups[g].faces.empty() && !layer.mesh->groups[g].instances.empty()) {
                            items.emplace_back(new MeshItem(generation,l,g));itemBounds.push_back(layer.mesh->groupBounds[g]);
                        }
                }
            itemsDirty=false;
        }
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
    bool publish(INode* node,std::vector<PointLayer> layers) {
        controller.SetRef(node);
        if(generation && sameLayers(generation->layers,layers)) { controller.update();return !generation->failed.load(); }
        if(generation) generation->enabled=false;
        items.clear();generation.reset();
        generation=std::make_shared<Generation>(std::move(layers));
        controller.generation=generation;controller.update();++revision;itemsDirty=true;
        NotifyDependents(FOREVER,PART_GEOM|PART_DISPLAY,REFMSG_CHANGE);
        return !generation->failed.load();
    }
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
    // Off-screen mesh items need not be realized yet. Nitrous realizes visible
    // items before drawing; requiring every item ready would defeat culling.
    return IsRetainedModeEnabled() && gen && gen->enabled.load() && !gen->failed.load() &&
        (gen->hasMesh?gen->submitted.load():gen->ready.load()==gen->groups);
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
