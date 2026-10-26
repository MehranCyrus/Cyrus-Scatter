#pragma once
#include "interactions_source.h"
#include <map>
#include <unordered_map>
#include <set>

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
};
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
    Transform transform(std::size_t)const;
};
struct Statistics {
    std::size_t plants=0,obstacles=0,affected=0,posed=0,covered=0,hiddenRoots=0,
        fittedGuides=0,queries=0,coverageQueries=0,separationQueries=0,iterations=0,hinges=0,reusedPoses=0,restored=0,
        layoutPayloadBytes=0,indexPayloadBytes=0,posePayloadBytes=0;
    double indexMs=0,queryMs=0,fitMs=0,totalMs=0;
    unsigned participants=1;bool threadFallback=false;
};
struct Snapshot {
    std::uint64_t generation=0;
    std::shared_ptr<const Layout> layout;
    std::map<std::size_t,Transform> overrides;
    std::set<std::size_t> disabled;
    std::unordered_map<std::size_t,std::shared_ptr<const Pose>> poses;
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
        const std::map<std::size_t,Transform>& overrides={},const std::vector<std::size_t>& changed={},const std::set<std::size_t>& disabled={})const;
    std::vector<std::size_t> nearby(const Bounds&)const;
    Json audit(const Snapshot&,std::size_t triangleBudget=2000000)const;
};
Json statisticsJson(const Statistics&);
}
