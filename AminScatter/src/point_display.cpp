#include "point_preview.h"
#include "deformation_preview.h"
#include "viewport_plan.h"
#include "diagnostics.h"
#include "render_publication.h"
#include "edit_feedback.h"
#include "viewport_pick.h"
#include <Graphics/HitTestContext.h>
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
#include <Graphics/IViewportViewSetting.h>
#include <maxscript/maxscript.h>
#include <maxscript/foundation/arrays.h>
#include <maxscript/foundation/numbers.h>
#include <maxscript/foundation/strings.h>
#include <maxscript/maxwrapper/mxsobjects.h>
#include <atomic>
#include <cmath>
#include <cstring>
#include <cfloat>
#include <tuple>
#include <maxscript/foundation/3dmath.h>
#include <mutex>
#include <stdexcept>
#include <string>
#include <unordered_set>
#include <maxscript/macros/define_instantiation_functions.h>
#undef ScripterExport
#define ScripterExport __declspec(dllexport)

extern HINSTANCE CyrusEditInstance;
using namespace MaxSDK::Graphics;
namespace cyrus {
namespace {
std::atomic<std::size_t> requestedViewportMiB{0};
std::mutex viewportAdmissionMutex;
std::string viewportAdmissionMessage;
// Finite fallback policy. Active Nitrous adapter telemetry is unavailable;
// these are application allowances and must not be presented as free VRAM.
constexpr viewport_memory::Calibration viewportCalibration{
    8ull*1024*viewport_memory::MiB,2ull*1024*viewport_memory::MiB,32000000,
    512*viewport_memory::MiB,512*viewport_memory::MiB,8,16};
SystemMemoryAdmission sourceAndDisplayAdmission;
// CPU-only conversion estimates are bounded separately from display policy.
// ConvertToType's opaque plugin allocation remains a measured host limitation.
constexpr std::size_t sourceMetadataMemoryLimit=viewportCalibration.metadataFaces*128;
PreviewBudget sourceMetadataBudget(sourceMetadataMemoryLimit,&sourceAndDisplayAdmission,
    "Source metadata conversion exceeds its finite CPU allowance; previous result retained.");
viewport_memory::SystemMemory systemMemory() {
    MEMORYSTATUSEX memory{};memory.dwLength=sizeof(memory);
    const bool available=GlobalMemoryStatusEx(&memory)!=FALSE;
    return {available,std::size_t(memory.ullTotalPhys),std::size_t(memory.ullAvailPhys),std::size_t(memory.ullAvailPageFile)};
}
}
PreviewBudget pointPreviewBudget(pointPreviewProcessLimit),meshPreviewBudget(viewportCalibration.automaticMaximum,&sourceAndDisplayAdmission);
viewport_memory::Policy viewportMemoryPolicy() {
    return viewport_memory::policy(systemMemory(),requestedViewportMiB.load(),viewportCalibration);
}
std::size_t sourceInspectionFaceLimit() { return viewportCalibration.metadataFaces; }
void recordPreviewFailure(const char* reason) {
    std::lock_guard<std::mutex> lock(viewportAdmissionMutex);viewportAdmissionMessage=reason;
}
std::shared_ptr<PreviewMemory> reserveMeshMemory(viewport_memory::Cost bytes) {
    try {
        const auto policy=viewportMemoryPolicy();meshPreviewBudget.limits(policy.total,policy.device);
        if(bytes.cpu&&!policy.system.available)throw std::runtime_error("Cannot read system memory headroom for the viewport successor; previous result retained.");
        return std::make_shared<PreviewMemory>(meshPreviewBudget,bytes,policy.cpuHeadroom);
    } catch(const std::exception& error) {
        recordPreviewFailure(error.what());const std::string message=error.what();
        throw RuntimeError(std::wstring(message.begin(),message.end()).c_str());
    }
}
std::shared_ptr<PreviewMemory> reserveSourceMetadataMemory(std::size_t bytes) {
    try {
        const auto system=systemMemory();
        if(bytes&&!system.available)throw std::runtime_error("Cannot read system memory headroom for source metadata; previous result retained.");
        return std::make_shared<PreviewMemory>(sourceMetadataBudget,viewport_memory::Cost{bytes,0},
            viewport_memory::systemHeadroom(system,viewportCalibration).available);
    } catch(const std::exception& error) {
        const std::string message=error.what();
        throw RuntimeError(std::wstring(message.begin(),message.end()).c_str());
    }
}
void growMeshMemory(const std::shared_ptr<PreviewMemory>& memory,std::size_t bytes) {
    try {
        const auto policy=viewportMemoryPolicy();meshPreviewBudget.limits(policy.total,policy.device);
        memory->grow({bytes,0},policy.cpuHeadroom);
    } catch(const std::exception& error) {
        recordPreviewFailure(error.what());const std::string message=error.what();
        throw RuntimeError(std::wstring(message.begin(),message.end()).c_str());
    }
}
std::shared_ptr<PreviewMemory> reservePreviewMemory(PreviewBudget& budget,std::size_t bytes) {
    if(&budget==&meshPreviewBudget)return reserveMeshMemory({bytes,0});
    try { return std::make_shared<PreviewMemory>(budget,bytes); }
    catch(const std::exception&) { throw RuntimeError(_T("Preview resource allocation failed or exceeded its process allowance. Reduce display limits or release older caches.")); }
}
MeshSnapshot::MeshSnapshot(std::vector<PreviewGeometry> value,std::shared_ptr<PreviewMemory> storage):groups(std::move(value)) {
    cpuBytes=viewport_memory::add(sizeof(*this),viewport_memory::add(viewport_memory::multiply(groups.capacity(),sizeof(PreviewGeometry)),
        viewport_memory::multiply(groups.size(),2*sizeof(Box3)+2*sizeof(std::uint64_t))));
    for(const auto& group:groups)cpuBytes=viewport_memory::add(cpuBytes,viewport_memory::add(
        viewport_memory::multiply(group.faces.capacity(),sizeof(group.faces[0])),viewport_memory::add(
        viewport_memory::multiply(group.instances.capacity(),sizeof(Matrix3)),group.bandSlots.capacity())));
    for(const auto& group:groups)if(group.pickRows&&!group.sharedInstances)cpuBytes=viewport_memory::add(cpuBytes,group.pickRows->capacity()*sizeof(std::uint32_t));
    // The staging vectors moved into this snapshot; transfer their lease rather
    // than charging the same storage twice. A distinct successor keeps its own.
    memory=std::move(storage);
    if(!memory)memory=reserveMeshMemory({cpuBytes,0});
    else if(memory->cost().cpu<cpuBytes)growMeshMemory(memory,cpuBytes-memory->cost().cpu);
    else memory->trimCPU(cpuBytes);
    groupBounds.reserve(groups.size());localBounds.reserve(groups.size());faceFingerprints.reserve(groups.size());instanceFingerprints.reserve(groups.size());memory->commit();
    bounds.Init();
    auto hash=[this](const Point3& p) {
        for(int axis=0;axis<3;++axis) if(!std::isfinite(p[axis])) throw RuntimeError(_T("Non-finite mesh preview data"));
        const auto* bytes=reinterpret_cast<const unsigned char*>(&p);
        for(std::size_t i=0;i<sizeof(Point3);++i) { fingerprint^=bytes[i];fingerprint*=1099511628211ULL; }
    };
    for(const auto& group:groups) {
        if(group.bandData().size()!=group.instanceData().size())throw RuntimeError(_T("Mesh Band provenance count mismatch"));
        Box3 local,world;local.Init();world.Init();hash(group.color);
        std::uint64_t faceFingerprint=1469598103934665603ULL;
        if(group.sharedFaces){local=group.sharedBounds;faceFingerprint=group.sharedFingerprint;}
        else for(const auto& face:group.faces) for(const auto& p:face) {for(int axis=0;axis<3;++axis)if(!std::isfinite(p[axis]))throw RuntimeError(_T("Non-finite mesh preview data"));local+=p;const auto* bytes=reinterpret_cast<const unsigned char*>(&p);for(std::size_t i=0;i<sizeof(Point3);++i){faceFingerprint^=bytes[i];faceFingerprint*=1099511628211ULL;} }
        fingerprint^=faceFingerprint;fingerprint*=1099511628211ULL;
        faceFingerprints.push_back(faceFingerprint);
        std::uint64_t instanceFingerprint=group.sharedInstances?group.sharedInstanceFingerprint:1469598103934665603ULL;
        auto instanceHash=[&](const void* p,std::size_t n){auto bytes=static_cast<const unsigned char*>(p);for(std::size_t i=0;i<n;++i){instanceFingerprint^=bytes[i];instanceFingerprint*=1099511628211ULL;}};
        auto matrixHash=[&](const Matrix3& tm){for(int row=0;row<4;++row){const auto p=tm.GetRow(row);for(int k=0;k<3;++k)if(!std::isfinite(p[k]))throw RuntimeError(_T("Non-finite mesh instance"));instanceHash(&p,sizeof(p));}};
        if(group.sharedInstances){
            world=group.sharedWorldBounds;
            if(group.edits){for(auto i:group.edits->hidden)instanceHash(&i,sizeof(i));for(const auto& [i,tm]:group.edits->transforms){instanceHash(&i,sizeof(i));matrixHash(tm);world+=local*tm;}}
        }else{
            for(auto slot:group.bandSlots){if(slot>64)throw RuntimeError(_T("Invalid mesh Band palette slot"));instanceHash(&slot,sizeof(slot));}
            for(const auto& tm:group.instances){matrixHash(tm);world+=local*tm;}
        }
        if(group.deformation){world+=group.deformation->worldBounds;fingerprint^=group.deformation->fingerprint;fingerprint*=1099511628211ULL;}
        instanceFingerprints.push_back(instanceFingerprint);fingerprint^=instanceFingerprint;fingerprint*=1099511628211ULL;
        if(!group.faceData().empty() && group.instanceCount()) {
            viewport_memory::validateDrawCounts(group.faceData().size(),group.instanceCount());
            bounds+=world;faces=viewport_memory::add(faces,viewport_memory::multiply(group.faceData().size(),group.instanceCount()));instances=viewport_memory::add(instances,group.instanceCount());
            bufferBytes=viewport_memory::add(bufferBytes,viewport_memory::add(viewport_memory::multiply(group.faceData().size(),9*sizeof(Point3)),
                viewport_memory::multiply(group.instanceCount(),4*sizeof(Point3)+2*sizeof(float))));
            scratchBytes=viewport_memory::add(scratchBytes,viewport_memory::add(viewport_memory::multiply(group.faceData().size(),3*sizeof(Point3)),
                viewport_memory::multiply(group.instanceCount(),4*sizeof(Point3)+2*sizeof(float))));
            if(group.deformation)bufferBytes=viewport_memory::add(bufferBytes,
                viewport_memory::multiply(group.deformation->source->data->corners.size()+group.deformation->nodes.size()+group.deformation->changes.words.size(),sizeof(interactions::DeformationWord)));
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
std::atomic<std::size_t> reservedBytes{0},liveItems{0};
std::atomic<std::uint64_t> uploads{0},uploadBytes{0},draws{0},failures{0};
std::atomic<std::uint64_t> wireMeshDraws{0},solidMeshDraws{0};
// Vertex upload payloads and SDK material parameter payloads are distinct.
// These are submitted bytes, not a measurement of driver/VRAM traffic.
std::atomic<std::uint64_t> geometryUploadBytes{0},transformUploadBytes{0},ownerUploadBytes{0},styleParameterBytes{0},bufferReuses{0};
std::atomic<std::uint64_t> poseUploadBytes{0},bindingUploadBytes{0},poseBufferReuses{0};
std::atomic<bool> interactionHeld{false};
std::atomic<std::uint64_t> navigationDraws{0},idleDraws{0};
// Host camera/mouse activity pairs reduced drawing with its idle repaint timer.
// Graphics-context matrices can change between passes without camera activity.
// Missing an activity callback safely draws full detail instead of latching a
// reduced quota that has no matching request to restore the idle display.
bool navigating(DrawContext&) { return interactionHeld.load(); }
#ifdef CYRUS_PREVIEW_TEST_FAULTS
std::atomic<int> previewFaultStage{0},previewFaultOccurrence{0},previewFaultHits{0};
void previewFault(int stage) {
    if(previewFaultStage.load()==stage&&++previewFaultHits>=previewFaultOccurrence.load())
        throw std::runtime_error("Injected owned preview resource failure");
}
#else
inline void previewFault(int) {}
#endif

struct RenderBundle;
struct Generation {
    const std::vector<PointLayer> layers;
    // Host-thread feedback follows the exact bundle selected for display.
    // Workers never inspect this opaque authored/presentation reference.
    std::shared_ptr<const CyrusEditFeedback> editFeedback;
    std::uint64_t displayOwner=0;
    std::atomic<bool> editWakePosted{false};
    std::atomic<bool> enabled{true},failed{false},submitted{false};
    std::atomic<std::size_t> ready{0};
    std::size_t count=0,groups=0,reservation=0,meshReservation=0;
    std::shared_ptr<PreviewMemory> pointMemory,meshMemory;
    std::unordered_set<const PreviewMemory*> meshResourceOwners;
    void accountMeshResource(const std::shared_ptr<PreviewMemory>& resource) {
        if(resource&&meshResourceOwners.insert(resource.get()).second)
            meshReservation=viewport_memory::add(meshReservation,resource->cost().total());
    }
    bool hasMesh=false;
    bool memoryReduced=false;
    std::shared_ptr<RenderPublication> presentation;
    std::weak_ptr<RenderBundle> realization;
    std::uint64_t ticket=0;
    mutable std::mutex failureMutex;
    std::array<char,512> failureText{};
    bool complete() const { return !failed.load(std::memory_order_acquire)&&ready.load(std::memory_order_acquire)==groups; }
    bool visible() const { return enabled.load(std::memory_order_acquire)&&presentation&&presentation->canDraw(ticket)&&complete(); }
    void fail(const char* reason) {
        {std::lock_guard<std::mutex> lock(failureMutex);const auto size=std::min(std::strlen(reason),failureText.size()-1);
            std::memcpy(failureText.data(),reason,size);failureText[size]=0;}
        failed.store(true,std::memory_order_release);++failures;
        try{recordPreviewFailure(reason);}catch(...){} // diagnostics must not escape SDK realization
    }
    std::string failure() const { std::lock_guard<std::mutex> lock(failureMutex);return failureText.data(); }
    using DrawGroup=ViewportDrawGroup;
    std::vector<std::vector<DrawGroup>> pointPlan,meshPlan;
    Box3 bounds;
    void plan(bool boxes) {
        meshPlan=viewportMeshPlan(viewportMeshDemands(layers),boxes);
        pointPlan.clear();pointPlan.resize(layers.size());
        std::vector<ViewportDemand> input;std::vector<std::pair<std::size_t,std::size_t>> owners;
        ViewportLimits limits;
        for(std::size_t l=0;l<layers.size();++l){
            const auto& layer=layers[l];pointPlan[l].resize(layer.snapshot->groups.size());
            if(layer.snapshot->lines)continue;limits=layer.limits;
            for(std::size_t g=0;g<layer.snapshot->groups.size();++g){
                input.push_back({layer.snapshot->groups[g].points.size(),1});owners.emplace_back(l,g);
            }
        }
        auto idle=viewportQuotas(input,limits.values[0]);auto active=viewportQuotas(input,limits.values[1]);
        for(std::size_t i=0;i<owners.size();++i){const auto [l,g]=owners[i];pointPlan[l][g]={idle[i],active[i],false};}
        for(std::size_t l=0;l<layers.size();++l)if(layers[l].snapshot->lines)
            for(std::size_t g=0;g<pointPlan[l].size();++g){
                const auto n=layers[l].snapshot->groups[g].points.size()/2;
                pointPlan[l][g]={{n,1,false},{n,1,false},false};
            }
    }
    explicit Generation(std::vector<PointLayer> value):layers(std::move(value)) {
        bounds.Init();
        std::size_t vertices=0,pointCPU=0,pointGroups=0,meshGroups=0,paletteBytes=0;
        for(const auto& layer:layers) {
            vertices+=layer.snapshot->count;
            pointCPU+=layer.snapshot->cpuBytes;
            if(layer.palette)paletteBytes+=sizeof(PreviewPalette)+layer.palette->sourceColors.capacity()*sizeof(Point3)+layer.palette->bandIDs.capacity()*sizeof(std::uint64_t);
            if(!layer.snapshot->lines) count+=layer.snapshot->count;
            if(layer.snapshot->count) bounds+=layer.snapshot->bounds;
            for(const auto& group:layer.snapshot->groups) if(!group.points.empty()) {++groups;++pointGroups;}
            if(layer.mesh) {
                hasMesh=true;
                accountMeshResource(layer.mesh->memory);
                if(layer.appearance)for(const auto& source:layer.appearance->sources)if(source)accountMeshResource(source->memory);
                if(layer.mesh->faces) bounds+=layer.mesh->bounds;
                for(const auto& group:layer.mesh->groups) if(!group.faceData().empty() && group.instanceCount()) {++groups;++meshGroups;}
            }
        }
        // Hardware + SDK system copies + simultaneous upload temporaries. Item
        // and palette allowances cover fallback bookkeeping. Emergency drawing
        // submits only bounded centre markers, never CPU source triangles.
        const auto bytes=vertices*(3*(sizeof(Point3)+sizeof(float)))+pointGroups*4096+paletteBytes;
        plan(false);
        // Artist triangle caps may select boxes. Memory pressure rejects the
        // complete successor; it never silently substitutes a different plan.
        if(pointCPU+bytes>ownerByteLimit || groups>1024) { failed=true;++failures;return; }
        try {
            pointMemory=std::make_shared<PreviewMemory>(pointPreviewBudget,bytes);
            // Physical SDK buffers are admitted by MeshItem, where actual reuse
            // is known. Only per-generation bookkeeping belongs to this lease.
            meshMemory=reserveMeshMemory({viewport_memory::multiply(meshGroups,4096),0});meshMemory->commit();
            accountMeshResource(meshMemory);
        } catch(...) { pointMemory.reset();meshMemory.reset();failed=true;++failures;return; }
        reservation=bytes;reservedBytes+=bytes;
    }
    ~Generation() { reservedBytes-=reservation; }
};

class PreparedRenderItem : public ICustomRenderItem {
public:
    virtual void RealizeResources(DrawContext&)=0;
};
struct RenderBundle {
    const std::shared_ptr<Generation> generation;
    std::vector<RefPtr<ICustomRenderItem>> items;
    std::vector<Box3> itemBounds;
    std::mutex realizeMutex;
    explicit RenderBundle(std::shared_ptr<Generation> value):generation(std::move(value)){}
    void realize(DrawContext& dc) {
        realizeRenderPublication(*this,dc,[](const auto& item,DrawContext& context){
            static_cast<PreparedRenderItem*>(item.GetPointer())->RealizeResources(context);
        });
#include "point_ready_wake.inc"
    }
};
void realizeGeneration(const std::shared_ptr<Generation>& generation,DrawContext& dc) {
    if(auto bundle=generation->realization.lock())bundle->realize(dc);
}

bool sameLayers(const std::vector<PointLayer>& a,const std::vector<PointLayer>& b) {
    if(a.size()!=b.size()) return false;
    for(std::size_t i=0;i<a.size();++i)
        if(a[i].snapshot!=b[i].snapshot || a[i].mesh!=b[i].mesh || a[i].appearance!=b[i].appearance || a[i].geometryMode!=b[i].geometryMode || a[i].limits!=b[i].limits || a[i].solid!=b[i].solid || (a[i].solid && a[i].color!=b[i].color) || !samePalette(a[i].palette,b[i].palette)) return false;
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

class PointItem : public PreparedRenderItem {
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
    void Realize(DrawContext& dc) override { realizeGeneration(generation,dc); }
    void RealizeResources(DrawContext& dc) override {
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
        } catch(const std::exception& error) { generation->fail(error.what()); }
          catch(...) { generation->fail("Viewport point realization failed"); }
    }
    void Display(DrawContext& dc) override {
        if(!ready.load(std::memory_order_acquire) || !generation->visible()) return;
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
    const std::shared_ptr<RenderPublication> presentation=std::make_shared<RenderPublication>();
    std::weak_ptr<Generation> generation;
    void update() {
        auto* node=static_cast<INode*>(GetRef());
        presentation->controllerVisible(node&&!node->IsHidden());
    }
    RefResult NotifyRefChanged(const Interval& interval,RefTargetHandle target,PartID& part,RefMessage message,BOOL propagate) override {
        const auto result=SingleWeakRefMaker::NotifyRefChanged(interval,target,part,message,propagate);
        update();return result;
    }
};

// Pending containers submit only this no-draw activation item plus the last
// complete bundle. Its union bounds include the old display, so moving every
// successor group off-screen still realizes the complete successor and retires
// the old display. Per-source Nitrous items/culling remain unchanged once ready.
class RenderActivation final : public ICustomRenderItem {
    const std::shared_ptr<RenderBundle> candidate;
public:
    explicit RenderActivation(std::shared_ptr<RenderBundle> value):candidate(std::move(value)){}
    void Realize(DrawContext& dc) override { candidate->realize(dc); }
    void Display(DrawContext&) override {}
    std::size_t GetPrimitiveCount() const override { return 1; }
    void HitTest(HitTestContext&,DrawContext&) override {}
};

struct PickState;
static std::unordered_map<AnimHandle,AnimHandle> pickDisplays;
class PointDisplay;
int pickDisplay(PointDisplay&,TimeValue,INode*,int,int,int,IPoint2*,ViewExp*);
class PointDisplay final : public HelperObject {
public:
    std::shared_ptr<PickState> pickState;
    // A second disposable helper is pick-only. Nitrous preselection ignores
    // DoOwnSelectHilite for custom items, so it must not own the garden's items.
    // Anim handles are weak, checked on every use; no second geometry owner.
    std::uint64_t pickTarget=0;
    std::uint64_t pickBoundsTicket=0;
    PointDisplay* pickDisplayTarget() const {
        auto* value=pickTarget?Animatable::GetAnimByHandle(pickTarget):nullptr;
        return value&&value!=this&&value->ClassID()==displayID?static_cast<PointDisplay*>(value):nullptr;
    }
    std::uint64_t displayHandle(){return Animatable::GetHandleByAnim(this);}
    ControllerWatch controller;
    const std::shared_ptr<RenderPublication> presentation=controller.presentation;
    std::shared_ptr<RenderBundle> candidate,retained;
    bool presentationRefreshRequested=false;
    std::uint64_t revision=0,prepares=0,nodeUpdates=0;
    ~PointDisplay() override {
        for(auto it=pickDisplays.begin();it!=pickDisplays.end();)if(it->second==displayHandle())it=pickDisplays.erase(it);else ++it;
        presentation->stop();
        if(candidate)cyrusReleaseEditFeedback(candidate->generation->editFeedback);
        if(retained)cyrusReleaseEditFeedback(retained->generation->editFeedback);
    }
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
        if(pickTarget){auto* target=pickDisplayTarget();if(target)return target->worldBounds();Box3 empty;empty.Init();return empty;}
        Box3 bounds;bounds.Init();bool any=false;
        for(const auto& bundle:{candidate,retained})if(bundle&&bundle->generation->groups){bounds+=bundle->generation->bounds;any=true;}
        return any?bounds:Box3(Point3(-.001f,-.001f,-.001f),Point3(.001f,.001f,.001f));
    }
    void GetLocalBoundBox(TimeValue t,INode* node,ViewExp*,Box3& box) override { box=worldBounds()*Inverse(node->GetObjectTM(t)); }
    void GetWorldBoundBox(TimeValue,INode*,ViewExp*,Box3& box) override { box=worldBounds(); }
    void GetDeformBBox(TimeValue,Box3& box,Matrix3* tm,BOOL) override { box=worldBounds();if(tm)box=box**tm; }
    int Display(TimeValue,INode*,ViewExp*,int) override { return 0; }
    // A helper owns every layer's render items. Max's object-wide highlight
    // would redraw the entire garden; the bounded instance overlay owns it.
    int DoOwnSelectHilite() override { return 1; }
    int HitTest(TimeValue t,INode* n,int type,int crossing,int flags,IPoint2* p,ViewExp* v) override { auto* target=pickDisplayTarget();return target?pickDisplay(*target,t,n,type,crossing,flags,p,v):0; }
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
        settlePresentation();
        const auto visible=visibleBundle();
        if(visible) {
            for(std::size_t index=0;index<visible->items.size();++index) {
                CustomRenderItemHandle handle;handle.Initialize();
                handle.SetVisibilityGroup(RenderItemVisible_Gizmo);handle.SetObjectBox(visible->itemBounds[index]);
                handle.SetCustomImplementation(visible->items[index].GetPointer());target.AddRenderItem(handle);
            }
            visible->generation->submitted=true;
        }
        if(candidate&&!candidate->generation->complete()&&!candidate->generation->failed.load()) {
            RefPtr<ICustomRenderItem> activation(new RenderActivation(candidate));
            CustomRenderItemHandle handle;handle.Initialize();handle.SetVisibilityGroup(RenderItemVisible_Gizmo);
            handle.SetObjectBox(worldBounds());handle.SetCustomImplementation(activation.GetPointer());target.AddRenderItem(handle);
        }
        return true;
    }
#include "point_presentation.inc"
#include "point_publication.inc"
};

#include "viewport_pick.inc"
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
    auto* display=owner(helper);
    const bool result=display->publish(controller,std::move(layers));
    if(result){pickDisplays[Animatable::GetHandleByAnim(controller)]=display->displayHandle();if(_tcscmp(helper->GetName(),controller->GetName())!=0)helper->SetName(controller->GetName());}
    return result;
}
bool pointsMatch(INode* helper,const std::vector<PointLayer>& layers) {
    auto* display=owner(helper);display->requestPresentationUpdate();const auto gen=display->visibleGeneration();
    if(gen && !sameLayers(gen->layers,layers)) return false;
    // Matches describes the complete bundle selected at the host container
    // boundary, including while another requested bundle is still pending.
    return IsRetainedModeEnabled() && gen && gen->visible() &&
        gen->submitted.load();
}
}

#include "edit_viewport.inc"

bool cyrusRequestReadyPointDisplay(std::uint64_t displayHandle,std::uint64_t controllerHandle)noexcept{
    try{
        auto* object=Animatable::GetAnimByHandle(displayHandle);
        if(!object||object->ClassID()!=cyrus::displayID||!controllerHandle)return false;
        auto* display=static_cast<cyrus::PointDisplay*>(object);auto* controller=display->controller.GetRef();
        if(!controller||Animatable::GetHandleByAnim(controller)!=controllerHandle)return false;
        display->requestPresentationUpdate();return display->presentationRefreshRequested;
    }catch(...){return false;}
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

def_visible_primitive(cyrusRetainedInvalidate,"cyrusRetainedInvalidate");
Value* cyrusRetainedInvalidate_cf(Value** args,int count) {
    check_arg_count(cyrusRetainedInvalidate,1,count);
    auto* node=args[0]->to_node();(void)cyrus::owner(node);
    // Only its existing screen rectangle changed. Marking geometry dirty would
    // evaluate more of the scene; a plain RedrawViews may do nothing at all.
    node->InvalidateRect(GetCOREInterface()->GetTime(),true);
    return &ok;
}
// Version, idle/nav points, idle/nav proxies, idle/nav mesh triangles,
// idle/nav box instances, memory-reduced, idle/nav draw calls.
def_visible_primitive(cyrusRetainedViewportStats,"cyrusRetainedViewportStats");
Value* cyrusRetainedViewportStats_cf(Value** args,int count) {
    check_arg_count(cyrusRetainedViewportStats,1,count);
    const auto* display=cyrus::owner(args[0]->to_node());const auto gen=display->visibleGeneration();
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
    const auto* display=cyrus::owner(args[0]->to_node());const auto gen=display->visibleGeneration();
    const auto requested=display->candidate?display->candidate->generation:nullptr;
    one_typed_value_local(Array* result);vl.result=new Array(13);
    const std::uint64_t values[]={gen?gen->count:0,gen?gen->groups:0,display->revision,display->prepares,display->nodeUpdates,
        cyrus::uploads.load(),cyrus::uploadBytes.load(),cyrus::draws.load(),cyrus::failures.load(),cyrus::liveItems.load(),cyrus::reservedBytes.load(),
        requested?(requested->failed.load()?2ULL:(gen&&gen==requested?1ULL:0ULL)):0ULL};
    for(auto value:values) vl.result->append(Integer64::intern(value));
    std::wstring hashes;
    if(gen) for(const auto& layer:gen->layers) { hashes+=std::to_wstring(layer.mesh?layer.mesh->fingerprint:layer.snapshot->fingerprint);hashes+=L";"; }
    vl.result->append(new String(hashes.c_str()));return_value(vl.result);
}

// Mesh-specific telemetry; existing point telemetry indices remain stable.
def_visible_primitive(cyrusRetainedMeshStats,"cyrusRetainedMeshStats");
Value* cyrusRetainedMeshStats_cf(Value** args,int count) {
    check_arg_count(cyrusRetainedMeshStats,1,count);
    const auto* display=cyrus::owner(args[0]->to_node());const auto gen=display->visibleGeneration();
    std::size_t faces=0,instances=0,sourceFaces=0;
    if(gen) for(const auto& layer:gen->layers) if(layer.mesh) {
        faces+=layer.mesh->faces;instances+=layer.mesh->instances;
        for(const auto& group:layer.mesh->groups) if(group.instanceCount()) sourceFaces+=group.faceData().size();
    }
    one_typed_value_local(Array* result);vl.result=new Array(9);
    const auto policy=cyrus::viewportMemoryPolicy();
    for(auto value:{faces,instances,sourceFaces,gen?gen->meshReservation:0,cyrus::meshPreviewBudget.used(),policy.total,policy.total})
        vl.result->append(Integer64::intern(value));
    // Append-only process draw counters; existing telemetry indices are stable.
    vl.result->append(Integer64::intern(cyrus::wireMeshDraws.load()));
    vl.result->append(Integer64::intern(cyrus::solidMeshDraws.load()));
    return_value(vl.result);
}

// Version 1: requested ticket, visible ticket, state (0 empty/1 pending/2 ready/
// 3 failed), complete visible bundle, requested ready/items, retry eligible,
// awaiting host commit, controller visible, fallback bundle count, requested
// geometry fingerprint, visible geometry fingerprint, requested failure text.
// Read-only: CPU preparation, realization and actual presentation are distinct.
def_visible_primitive(cyrusRetainedPresentationStats,"cyrusRetainedPresentationStats");
// Host-thread notification only. The SDK container boundary still performs
// the atomic swap; no pending placements are evaluated by this request.
def_visible_primitive(cyrusRetainedRequestReady,"cyrusRetainedRequestReady");
Value* cyrusRetainedRequestReady_cf(Value** args,int count){
    check_arg_count(cyrusRetainedRequestReady,1,count);
    auto* display=cyrus::owner(args[0]->to_node());
    display->requestPresentationUpdate();return bool_result(display->presentationRefreshRequested);
}
Value* cyrusRetainedPresentationStats_cf(Value** args,int count) {
    check_arg_count(cyrusRetainedPresentationStats,1,count);
    const auto* display=cyrus::owner(args[0]->to_node());
    const auto requested=display->candidate?display->candidate->generation:nullptr;
    const auto visible=display->visibleGeneration();
    const bool failed=requested&&requested->failed.load();
    const auto state=!requested?0:failed?3:visible==requested?2:1;
    const bool available=visible&&visible->visible()&&visible->submitted.load();
    const bool awaiting=requested&&requested->complete()&&visible!=requested;
    const auto fingerprint=[](const std::shared_ptr<cyrus::Generation>& generation){
        std::wstring result;
        if(generation)for(const auto& layer:generation->layers){result+=std::to_wstring(layer.mesh?layer.mesh->fingerprint:layer.snapshot->fingerprint);result+=L";";}
        return result;
    };
    one_typed_value_local(Array* result);vl.result=new Array(14);
    vl.result->append(Integer::intern(1));
    vl.result->append(Integer64::intern(display->presentation->requestedTicket()));
    vl.result->append(Integer64::intern(display->presentation->visibleTicket()));
    vl.result->append(Integer::intern(state));vl.result->append(available?&true_value:&false_value);
    vl.result->append(Integer64::intern(requested?requested->ready.load():0));
    vl.result->append(Integer64::intern(requested?requested->groups:0));
    vl.result->append(failed?&true_value:&false_value);vl.result->append(awaiting?&true_value:&false_value);
    vl.result->append(display->presentation->controllerVisible()?&true_value:&false_value);
    vl.result->append(Integer::intern(display->retained?1:0));
    vl.result->append(new String(fingerprint(requested).c_str()));vl.result->append(new String(fingerprint(visible).c_str()));
    const auto reason=requested?requested->failure():std::string{};
    vl.result->append(new String(std::wstring(reason.begin(),reason.end()).c_str()));return_value(vl.result);
}

// Version 1: position/source-geometry, transforms, owners, material parameters,
// reused item buffers; append-only pose/binding upload bytes and pose reuse.
// Parameter bytes are not claimed as physical GPU uploads.
def_visible_primitive(cyrusRetainedStreamStats,"cyrusRetainedStreamStats");
Value* cyrusRetainedStreamStats_cf(Value**,int count) {
    check_arg_count(cyrusRetainedStreamStats,0,count);
    one_typed_value_local(Array* result);vl.result=new Array(9);
    vl.result->append(Integer::intern(1));
    for(auto value:{cyrus::geometryUploadBytes.load(),cyrus::transformUploadBytes.load(),cyrus::ownerUploadBytes.load(),
                    cyrus::styleParameterBytes.load(),cyrus::bufferReuses.load(),cyrus::poseUploadBytes.load(),cyrus::bindingUploadBytes.load(),cyrus::poseBufferReuses.load()})vl.result->append(Integer64::intern(value));
    return_value(vl.result);
}

// Version 1: point live/peak/limit, mesh live/peak/limit. Includes CPU snapshots,
// palette data, staging payloads and conservative GPU/SDK-copy reservations.
def_visible_primitive(cyrusPreviewResourceStats,"cyrusPreviewResourceStats");
Value* cyrusPreviewResourceStats_cf(Value**,int count) {
    check_arg_count(cyrusPreviewResourceStats,0,count);
    one_typed_value_local(Array* result);vl.result=new Array(7);vl.result->append(Integer::intern(1));
    for(auto value:{cyrus::pointPreviewBudget.used(),cyrus::pointPreviewBudget.highWater(),cyrus::pointPreviewProcessLimit,
        cyrus::meshPreviewBudget.used(),cyrus::meshPreviewBudget.highWater(),cyrus::viewportMemoryPolicy().total})
        vl.result->append(Integer64::intern(value));
    return_value(vl.result);
}

// Installation/session preference only. Changing it does not evaluate a scene,
// evict resources, clear Undo, or mutate an existing complete generation.
def_visible_primitive(cyrusSetViewportMemoryLimit,"cyrusSetViewportMemoryLimit");
Value* cyrusSetViewportMemoryLimit_cf(Value** args,int count) {
    check_arg_count(cyrusSetViewportMemoryLimit,1,count);
    const auto value=args[0]->to_int64();
    if(value<0||value>65536||(value>0&&value<256))throw RuntimeError(_T("Viewport memory limit must be 0 (Automatic) or 256..65536 MiB"));
    cyrus::requestedViewportMiB=std::size_t(value);return &ok;
}

// Version 1, all sizes in bytes except the requested MiB setting and face limit:
// version, requestedMiB, effective total, live total, peak total, CPU/system,
// device, pending CPU, OS available commit, OS available physical, physical
// reserve, commit reserve, device allowance, metadata faces, telemetry, last error.
// These are owned allocation estimates. Neither total nor device is actual VRAM.
def_visible_primitive(cyrusViewportMemoryStats,"cyrusViewportMemoryStats");
Value* cyrusViewportMemoryStats_cf(Value**,int count) {
    check_arg_count(cyrusViewportMemoryStats,0,count);
    const auto policy=cyrus::viewportMemoryPolicy();const auto state=cyrus::meshPreviewBudget.state();
    one_typed_value_local(Array* result);vl.result=new Array(16);
    vl.result->append(Integer::intern(1));
    const std::size_t values[]={cyrus::requestedViewportMiB.load(),policy.total,state.total(),state.peak,state.cpu,state.device,
        state.pending,policy.system.availableCommit,policy.system.availablePhysical,policy.physicalReserve,policy.commitReserve,
        policy.device,policy.metadataFaces};
    for(const auto value:values)vl.result->append(Integer64::intern(value));
    vl.result->append(new String(_T("fallback")));
    std::string message;{std::lock_guard<std::mutex> lock(cyrus::viewportAdmissionMutex);message=cyrus::viewportAdmissionMessage;}
    vl.result->append(new String(std::wstring(message.begin(),message.end()).c_str()));return_value(vl.result);
}

// Separate from viewport preference/usage: version, live estimated CPU, peak
// estimated CPU, pending metadata CPU, finite estimate ceiling, shared pending
// metadata/display CPU. All sizes are bytes. Opaque host conversion peaks are
// not measured here and are not made into a hard allocator quota by this lease.
def_visible_primitive(cyrusSourceGeometryMemoryStats,"cyrusSourceGeometryMemoryStats");
Value* cyrusSourceGeometryMemoryStats_cf(Value**,int count) {
    check_arg_count(cyrusSourceGeometryMemoryStats,0,count);
    const auto state=cyrus::sourceMetadataBudget.state();
    one_typed_value_local(Array* result);vl.result=new Array(6);
    vl.result->append(Integer::intern(1));
    for(const auto value:{state.cpu,state.peak,state.pending,cyrus::sourceMetadataMemoryLimit,cyrus::sourceAndDisplayAdmission.used()})
        vl.result->append(Integer64::intern(value));
    return_value(vl.result);
}

#ifdef CYRUS_PREVIEW_TEST_FAULTS
def_visible_primitive(cyrusOwnedPreviewFault,"cyrusOwnedPreviewFault");
Value* cyrusOwnedPreviewFault_cf(Value** args,int count) {
    check_arg_count(cyrusOwnedPreviewFault,2,count);
    const auto stage=args[0]->to_int(),occurrence=args[1]->to_int();
    if(stage<0||stage>6||occurrence<0)throw RuntimeError(_T("Invalid owned preview fault"));
    cyrus::previewFaultStage=stage;cyrus::previewFaultOccurrence=occurrence;cyrus::previewFaultHits=0;
    return &ok;
}
#endif

#include "viewport_pick_bridge.inc"
