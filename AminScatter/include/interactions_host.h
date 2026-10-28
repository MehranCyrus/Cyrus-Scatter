#pragma once
#include "interactions_engine.h"
#include "placement_value.h"
#include "point_preview.h"
#include "interactions_edit.h"
#include <functional>
#include <unordered_map>

class Value;
namespace cyrus {
struct InteractionSourceWatch;
struct InteractionHostSource {
    AnimHandle nodeHandle=0;
    double unit=.01;
    std::shared_ptr<const Mesh> mesh;
    std::shared_ptr<const std::vector<Point3>> cornerNormals;
    std::shared_ptr<const MeshSnapshot> lightGeometry;
    std::shared_ptr<const interactions::Source> rig;
    std::shared_ptr<const prep::Analysis> failedAnalysis;
    std::shared_ptr<const interactions::MeshGeometry> collider;
    std::shared_ptr<InteractionSourceWatch> watch;
    std::shared_ptr<InteractionSourceWatch> proxyWatch;
    AnimHandle proxyNodeHandle=0;
    std::shared_ptr<PreviewMemory> memory;
    std::string fingerprint;
    std::string definitionHash;
    interactions::Bounds bounds;
    prep::Settings settings;
    int proxy=1;
    // A collider-only mesh is not a reusable capture of its visual prototype.
    bool visualMesh=true;
    bool sceneGeometry=false;
    std::array<float,14> offsetSignature{};
    std::size_t analysisCount=0;
};
struct InteractionPreviewCache;
struct InteractionRuntime {
    AnimHandle controller=0;
    std::vector<AnimHandle> renderNodes;
    std::shared_ptr<interactions::Engine> engine;
    std::shared_ptr<PreviewMemory> memory;
    std::shared_ptr<const interactions::Snapshot> current;
    std::shared_ptr<const interactions::Snapshot> pending;
    std::shared_ptr<InteractionPreviewCache> previewCache;
    std::vector<placements::View> rows;
    std::vector<std::string> layerIDs;
    std::vector<int> editKeys;
    std::vector<bool> renderEnabled;
    std::vector<std::vector<std::shared_ptr<const InteractionHostSource>>> sources;
    std::vector<std::shared_ptr<const InteractionHostSource>> sceneSources;
    std::vector<std::vector<std::uint32_t>> byLayerRow;
    std::vector<std::pair<std::weak_ptr<const interactions::Snapshot>,std::optional<placements::View>>> feedbackViews;
    std::map<std::pair<int,std::string>,std::uint32_t> byIdentity;
    std::function<void(const std::shared_ptr<const interactions::Snapshot>&)> publish;
    std::vector<PointLayer> baseLayers;
    std::vector<int> previewLayers;
    std::string error;
    std::uint64_t updates=0,reuses=0,failures=0;
    std::uint64_t previewBuilds=0,previewReuses=0;
    double previewMs=0,previewReuseMs=0;
    bool live=true,busy=false;
};
std::shared_ptr<InteractionRuntime> interactionRuntime(Value*);
std::shared_ptr<InteractionRuntime> interactionRuntime(AnimHandle);
void interactionRegister(const std::shared_ptr<InteractionRuntime>&);
void interactionForget(AnimHandle,const std::shared_ptr<InteractionRuntime>&);
void interactionEdit(AnimHandle,const std::vector<InteractionEditPatch>&)noexcept;
bool interactionLayer(AnimHandle,int)noexcept;
std::vector<PointLayer> interactionPreview(InteractionRuntime&,const interactions::Snapshot&,const std::vector<PointLayer>&,const std::vector<int>&);
void interactionRenderCommit(const std::shared_ptr<InteractionRuntime>&,const std::shared_ptr<const interactions::Snapshot>&,const std::function<void()>& publish={});
}
