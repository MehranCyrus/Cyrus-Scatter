#pragma once
#include "interactions_source.h"
#include <map>
#include <unordered_map>
#include <set>
#include <functional>

namespace cyrus::interactions {
struct Definition {
    std::shared_ptr<const Source> rig;
    std::shared_ptr<const MeshGeometry> collider;
    Bounds geometryBounds;
    std::string key;
};
struct LayerSettings {
    bool obstacle=false,react=false,coverRoots=true;
    double gap=.001,stiffness=.5;
    double hideMargin=0;bool hideUnder=false;
    int response=0; // 0 detailed, 1 bend, 2 prune, 3 bend then prune
    double strength=.5,pruneAmount=1,pruneThreshold=0;
    bool neighbors=false;
    double trunkBend=0,fixedBase=0,bendTransition=.25;
    bool operator==(const LayerSettings&)const=default;
};
struct SceneObstacle {std::string identity;std::shared_ptr<const MeshGeometry> geometry;Transform transform;};
struct Instance {
    unsigned layer=0,row=0,source=0;
    std::string identity;
    std::array<float,12> hostTransform{};
};
struct Layout {
    std::shared_ptr<const void> allocationLease; // Host admission outlives every numeric/render snapshot.
    double metresPerUnit=.01;
    std::vector<LayerSettings> layers;
    std::vector<std::vector<std::shared_ptr<const Definition>>> sources;
    std::vector<Instance> instances;
    std::vector<SceneObstacle> sceneObstacles;
    std::function<std::shared_ptr<const void>(std::size_t)> reserveGeometry;
    Transform transform(std::size_t)const;
};
struct Statistics {
    std::size_t plants=0,obstacles=0,affected=0,posed=0,covered=0,hiddenRoots=0,retainedCoveredRoots=0,
        fittedGuides=0,queries=0,coverageQueries=0,separationQueries=0,iterations=0,hinges=0,reusedPoses=0,restored=0,meshRefinements=0,meshRefinementWork=0,qualityCheckedGuides=0,qualityWarningGuides=0,
        layoutPayloadBytes=0,indexPayloadBytes=0,obstacleIndexPayloadBytes=0,transientObstacleIndexPayloadBytes=0,obstacleQueryScratchBoundBytes=0,exactMeshScratchBoundBytes=0,posePayloadBytes=0;
    std::size_t exactMeshChecks=0,exactPointTests=0,exactFaceTests=0,exactTransformedVertices=0,exactInverseVertices=0;
    double indexMs=0,queryMs=0,fitMs=0,totalMs=0,workerCoverageMs=0,workerMeshCheckMs=0,workerMeshTransformMs=0,workerMeshPointMs=0,workerMeshFaceMs=0,workerEdgeQualityMs=0,maximumCheckedStemEdgeChange=0;
    unsigned participants=1;bool threadFallback=false;
    std::size_t prunedGuides=0,blockedGuides=0,limitedGuides=0,colliderBakeBytes=0;
};
struct Snapshot {
    std::uint64_t generation=0;
    std::shared_ptr<const Layout> layout;
    std::map<std::size_t,Transform> overrides;
    std::vector<Transform> sceneTransforms;
    std::vector<Shape> worldObstacles;
    std::set<std::size_t> disabled;
    std::unordered_map<std::size_t,std::shared_ptr<const Pose>> poses;
    // Coverage warnings also apply to unchanged geometry; do not allocate poses for them.
    std::unordered_map<std::size_t,std::size_t> retainedRootCounts;
    std::unordered_map<std::size_t,std::pair<std::size_t,std::size_t>> responseWarnings;
    Statistics statistics;
};
class Engine {
    struct Impl;
    std::shared_ptr<Impl> impl_;
public:
    explicit Engine(std::shared_ptr<const Layout>);
    const Layout& layout()const;
    // Failure cannot mutate the preceding complete publication.
    std::shared_ptr<const Snapshot> evaluate(const std::shared_ptr<const Snapshot>& previous,
        const std::map<std::size_t,Transform>& overrides={},const std::vector<std::size_t>& changed={},const std::set<std::size_t>& disabled={},const std::vector<Transform>& sceneTransforms={})const;
    std::vector<std::size_t> nearby(const Bounds&)const;
    Json audit(const Snapshot&,std::size_t triangleBudget=2000000)const;
};
Json statisticsJson(const Statistics&);
}
