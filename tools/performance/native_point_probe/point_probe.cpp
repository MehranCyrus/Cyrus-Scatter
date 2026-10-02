// Private display experiment. Not a production scene object or installer component.
// Source points are copied from the existing Cyrus preview diagnostic export.
#include <max.h>
#include <iparamb2.h>
#include <Graphics/CustomRenderItemHandle.h>
#include <Graphics/IRenderItemContainer.h>
#include <Graphics/IVirtualDevice.h>
#include <Graphics/SolidColorMaterialHandle.h>
#include <Graphics/VertexBufferHandle.h>
#include <Graphics/IndexBufferHandle.h>
#include <maxscript/maxscript.h>
#include <maxscript/foundation/arrays.h>
#include <maxscript/foundation/numbers.h>
#include <maxscript/foundation/strings.h>
#include <maxscript/foundation/3dmath.h>
#include <maxscript/maxwrapper/mxsobjects.h>
#include <atomic>
#include <cmath>
#include <cstdint>
#include <memory>
#include <mutex>
#include <string>
#include <vector>
#include <maxscript/macros/define_instantiation_functions.h>
#undef ScripterExport
#define ScripterExport __declspec(dllexport)

using namespace MaxSDK::Graphics;
namespace {
const Class_ID probeID(0x5a316d72, 0x73f091c2);
HINSTANCE instance = nullptr;
std::atomic<std::uint64_t> liveItems{0}, uploads{0}, uploadBytes{0}, draws{0}, failures{0};

struct Group {
    Point3 color;
    std::vector<Point3> points;
    Box3 bounds;
};
struct Snapshot {
    std::vector<Group> groups;
    Box3 bounds;
    std::size_t count = 0;
    std::uint64_t fingerprint = 1469598103934665603ULL;
    Snapshot() { bounds.Init(); }
    void hash(const void* ptr, std::size_t bytes) {
        const auto* p = static_cast<const unsigned char*>(ptr);
        for (std::size_t i = 0; i < bytes; ++i) { fingerprint ^= p[i]; fingerprint *= 1099511628211ULL; }
    }
};

class PointItem : public ICustomRenderItem {
    std::shared_ptr<const Snapshot> data;
    std::size_t groupIndex;
    VertexBufferHandleArray buffers;
    MaterialRequiredStreams format;
    SolidColorMaterialHandle material;
    std::atomic<bool> ready{false}, failed{false};
    std::mutex realizeMutex;
public:
    PointItem(std::shared_ptr<const Snapshot> snapshot, std::size_t index)
        : data(std::move(snapshot)), groupIndex(index) { ++liveItems; }
    ~PointItem() override { --liveItems; }
    void Realize(DrawContext& dc) override {
        if (ready.load(std::memory_order_acquire) || failed.load()) return;
        std::lock_guard<std::mutex> lock(realizeMutex);
        if (ready.load() || failed.load()) return;
        if (!dc.GetVirtualDevice().IsValid()) return;
        const auto& group = data->groups[groupIndex];
        if (!material.Initialize()) { failed = true; ++failures; return; }
        material.SetColor(AColor(group.color.x, group.color.y, group.color.z, 1.f));
        MaterialRequiredStreamElement position;
        position.SetChannelCategory(MeshChannelPosition);
        position.SetType(VertexFieldFloat3);
        format.AddStream(position);
        VertexBufferHandle buffer;
        // Max owns the graphics resources. CPU positions remain alive for recovery.
        if (!buffer.Initialize(sizeof(Point3), group.points.size(), const_cast<Point3*>(group.points.data())) ||
            !buffer.RealizeToHWMemory(true)) {
            failed = true; ++failures; return;
        }
        buffers.append(buffer);
        ++uploads; uploadBytes += group.points.size() * sizeof(Point3);
        ready.store(true, std::memory_order_release);
    }
    void Display(DrawContext& dc) override {
        if (!ready.load(std::memory_order_acquire)) return;
        auto& device = dc.GetVirtualDevice();
        if (!device.IsValid()) return;
        const DepthStencilState originalDepth = device.GetDepthStencilState();
        auto depth = originalDepth;
        depth.SetDepthEnabled(false);
        depth.SetDepthWriteEnabled(false);
        IndexBufferHandle noIndices;
        material.Activate(dc);
        const auto passes = material.GetPassCount(dc);
        for (unsigned int pass = 0; pass < passes; ++pass) {
            material.ActivatePass(dc, pass);
            device.SetDepthStencilState(depth);
            device.SetStreamFormat(format);
            device.SetVertexStreams(buffers);
            device.SetIndexBuffer(noIndices);
            device.Draw(PrimitivePointList, 0, int(data->groups[groupIndex].points.size()));
            ++draws;
        }
        material.PassesFinished(dc);
        material.Terminate();
        device.SetDepthStencilState(originalDepth);
    }
    std::size_t GetPrimitiveCount() const override { return data->groups[groupIndex].points.size(); }
    // Selection through point pixels is deliberately outside this isolated experiment.
    void HitTest(HitTestContext&, DrawContext&) override {}
};

class Probe final : public HelperObject {
    std::vector<RefPtr<PointItem>> items;
    bool itemsDirty = true;
public:
    std::shared_ptr<const Snapshot> snapshot = std::make_shared<Snapshot>();
    bool enabled = false;
    std::uint64_t generation = 0, prepares = 0, nodeUpdates = 0;
    Class_ID ClassID() override { return probeID; }
    void GetClassName(MSTR& name, bool) const override { name = _T("Cyrus Retained Point Probe"); }
    const MCHAR* GetObjectName(bool) const override { return _T("Cyrus Retained Point Probe"); }
    void InitNodeName(MSTR& name) override { name = _T("Cyrus Retained Point Probe"); }
    void DeleteThis() override { delete this; }
    ObjectState Eval(TimeValue) override { return ObjectState(this); }
    Interval ObjectValidity(TimeValue) override { return FOREVER; }
    CreateMouseCallBack* GetCreateMouseCallBack() override { return nullptr; }
    void BeginEditParams(IObjParam*, ULONG, Animatable*) override {}
    void EndEditParams(IObjParam*, ULONG, Animatable*) override {}
    int NumRefs() override { return 0; }
    RefTargetHandle GetReference(int) override { return nullptr; }
    void SetReference(int, RefTargetHandle) override {}
    RefResult NotifyRefChanged(const Interval&, RefTargetHandle, PartID&, RefMessage, BOOL) override { return REF_SUCCEED; }
    RefTargetHandle Clone(RemapDir& remap) override {
        auto* out = new Probe;
        out->snapshot = snapshot; out->enabled = enabled; out->generation = generation;
        BaseClone(this, out, remap); return out;
    }
    Box3 localBounds() const {
        if (snapshot->count) return snapshot->bounds;
        return Box3(Point3(-.001f, -.001f, -.001f), Point3(.001f, .001f, .001f));
    }
    void GetLocalBoundBox(TimeValue, INode*, ViewExp*, Box3& box) override { box = localBounds(); }
    void GetWorldBoundBox(TimeValue t, INode* node, ViewExp*, Box3& box) override { box = localBounds() * node->GetObjectTM(t); }
    void GetDeformBBox(TimeValue, Box3& box, Matrix3* tm, BOOL) override { box = localBounds(); if (tm) box = box * *tm; }
    int Display(TimeValue, INode*, ViewExp*, int) override { return 0; }
    int HitTest(TimeValue, INode*, int, int, int, IPoint2*, ViewExp*) override { return 0; }
    void Snap(TimeValue, INode*, SnapInfo*, IPoint2*, ViewExp*) override {}
    unsigned long GetObjectDisplayRequirement() const override { return 0; }
    bool PrepareDisplay(const UpdateDisplayContext&) override {
        ++prepares;
        if (itemsDirty) {
            items.clear();
            for (std::size_t i = 0; i < snapshot->groups.size(); ++i)
                items.emplace_back(new PointItem(snapshot, i));
            itemsDirty = false;
        }
        return true;
    }
    bool UpdatePerNodeItems(const UpdateDisplayContext&, UpdateNodeContext&, IRenderItemContainer& target) override {
        ++nodeUpdates;
        if (enabled) for (std::size_t i = 0; i < items.size(); ++i) {
            CustomRenderItemHandle handle;
            handle.Initialize();
            handle.SetVisibilityGroup(RenderItemVisible_Gizmo);
            handle.SetObjectBox(snapshot->groups[i].bounds);
            handle.SetCustomImplementation(items[i].GetPointer());
            target.AddRenderItem(handle);
        }
        return true;
    }
    void replace(std::shared_ptr<const Snapshot> value) {
        snapshot = std::move(value); ++generation; itemsDirty = true;
        NotifyDependents(FOREVER, PART_GEOM | PART_DISPLAY, REFMSG_CHANGE);
    }
    void show(bool value) {
        if (enabled == value) return;
        enabled = value;
        NotifyDependents(FOREVER, PART_GEOM | PART_DISPLAY, REFMSG_CHANGE);
    }
};

class ProbeDesc final : public ClassDesc2 {
public:
    int IsPublic() override { return TRUE; }
    void* Create(BOOL) override { return new Probe; }
    const MCHAR* ClassName() override { return _T("Cyrus Retained Point Probe"); }
    const MCHAR* NonLocalizedClassName() override { return _T("Cyrus Retained Point Probe"); }
    SClass_ID SuperClassID() override { return HELPER_CLASS_ID; }
    Class_ID ClassID() override { return probeID; }
    const MCHAR* Category() override { return _T("Cyrus Experiments"); }
    const MCHAR* InternalName() override { return _T("CyrusRetainedPointProbe"); }
    HINSTANCE HInstance() override { return instance; }
};
Probe* probe(Value* value) {
    INode* node = value->to_node();
    auto* object = node ? node->GetObjectRef() : nullptr;
    if (!object || object->ClassID() != probeID) throw RuntimeError(_T("Expected an unmodified CyrusRetainedPointProbe node"));
    return static_cast<Probe*>(object);
}
}

extern "C" __declspec(dllexport) const MCHAR* LibDescription() { return _T("Cyrus isolated retained point experiment"); }
extern "C" __declspec(dllexport) ULONG LibVersion() { return VERSION_3DSMAX; }
extern "C" __declspec(dllexport) void LibInit() {}
// The DLX registers MAXScript primitives. A small DLH entry point registers the helper.
extern "C" __declspec(dllexport) int LibNumberClasses() { return 0; }
extern "C" __declspec(dllexport) ClassDesc* LibClassDesc(int) { return nullptr; }
extern "C" __declspec(dllexport) ClassDesc* CyrusPointProbeDesc() { static ProbeDesc desc; return &desc; }
extern "C" __declspec(dllexport) ULONG CanAutoDefer() { return 0; }
BOOL WINAPI DllMain(HINSTANCE module, DWORD reason, LPVOID) { if (reason == DLL_PROCESS_ATTACH) instance = module; return TRUE; }

def_visible_primitive(cyrusPointProbeSet, "cyrusPointProbeSet");
Value* cyrusPointProbeSet_cf(Value** args, int count) {
    check_arg_count(cyrusPointProbeSet, 2, count);
    auto* owner = probe(args[0]);
    type_check(args[1], Array, _T("point/color rows"));
    const auto* rows = static_cast<Array*>(args[1]);
    if (rows->size > 2000000) throw RuntimeError(_T("Private probe limited to 2 million points"));
    auto snapshot = std::make_shared<Snapshot>();
    for (int i = 0; i < rows->size; ++i) {
        type_check(rows->data[i], Array, _T("point/color row"));
        const auto* row = static_cast<Array*>(rows->data[i]);
        if (row->size != 2) throw RuntimeError(_T("Expected point and color"));
        const auto p = row->data[0]->to_point3();
        const auto color = row->data[1]->to_point3() / 255.f;
        for (int axis = 0; axis < 3; ++axis)
            if (!std::isfinite(p[axis]) || !std::isfinite(color[axis])) throw RuntimeError(_T("Non-finite preview value"));
        if (snapshot->groups.empty() || snapshot->groups.back().color != color) {
            if (snapshot->groups.size() >= 1024) throw RuntimeError(_T("Private probe limited to 1024 contiguous color groups"));
            snapshot->groups.push_back(Group{color, {}, {}}); snapshot->groups.back().bounds.Init();
        }
        snapshot->groups.back().points.push_back(p); snapshot->groups.back().bounds += p;
        snapshot->bounds += p; ++snapshot->count;
        snapshot->hash(&p, sizeof(Point3)); snapshot->hash(&color, sizeof(Point3));
    }
    owner->replace(std::move(snapshot)); return &ok;
}
def_visible_primitive(cyrusPointProbeShow, "cyrusPointProbeShow");
Value* cyrusPointProbeShow_cf(Value** args, int count) {
    check_arg_count(cyrusPointProbeShow, 2, count); probe(args[0])->show(args[1]->to_bool() != FALSE); return &ok;
}
def_visible_primitive(cyrusPointProbeStats, "cyrusPointProbeStats");
Value* cyrusPointProbeStats_cf(Value** args, int count) {
    check_arg_count(cyrusPointProbeStats, 1, count); const auto* owner = probe(args[0]);
    one_typed_value_local(Array* result); vl.result = new Array(12);
    const std::uint64_t values[] = { owner->snapshot->count, owner->snapshot->groups.size(), owner->generation,
        owner->prepares, owner->nodeUpdates, uploads.load(), uploadBytes.load(), draws.load(), failures.load(), liveItems.load() };
    for (auto value : values) vl.result->append(Integer64::intern(value));
    vl.result->append(new String(std::to_wstring(owner->snapshot->fingerprint).c_str()));
    return_value(vl.result);
}
