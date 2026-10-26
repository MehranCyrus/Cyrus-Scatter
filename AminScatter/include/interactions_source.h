#pragma once
#include "interactions_geometry.h"
#include "analysis.hpp"
#include <unordered_map>
#include <stdexcept>

namespace cyrus::interactions {
using Json=stem::Json;
struct Source {
    std::shared_ptr<const stem::Prepared> rig;
    Json metadata,report,authoring;
    std::vector<unsigned> labels,guideRoot,partRoot;
    std::vector<bool> anchors;
    std::vector<unsigned> fixedVertices,fixedFaces;
    Bounds fixedBounds;
    std::vector<unsigned> sortedVertices;
    std::vector<unsigned> previewFaces,previewVertices,previewRemap;
    std::vector<Tri> previewTriangles,previewUVCorners;
    // Shared source correspondence for rare exact-geometry contact refinement.
    std::vector<std::vector<unsigned>> guideVertices,guideFaces;
    std::vector<double> rootRadius;
    Bounds bounds;
    double reach=0;
    Vec rootCentre{};
    double rootReach=0;
    std::size_t roots=0;
    std::string fingerprint;
    std::size_t bytes=0;
    prep::Limits limits;
};
struct PreparationFailure:std::runtime_error {
    std::shared_ptr<const prep::Analysis> analysis;
    explicit PreparationFailure(prep::Analysis a):std::runtime_error("Source needs guide/attachment review; inspect the retained analysis report."),analysis(std::make_shared<prep::Analysis>(std::move(a))){}
};
std::shared_ptr<const Source> prepareSource(const prep::Snapshot&,prep::Settings={},const Json* saved=nullptr,const Json* authoring=nullptr,const std::atomic_bool* cancel=nullptr);
Json saveSource(const Source&);
struct Pose {
    // Unchanged guides share the source rest definition. No per-instance array
    // of all foliage transforms or full source vertices is allocated.
    std::vector<std::shared_ptr<const v::GuidePose>> guides;
    std::vector<bool> hiddenRoots;
    std::unordered_map<unsigned,stem::Rigid> rigid;
    std::size_t activeGuides=0,queries=0,coverageQueries=0,separationQueries=0,iterations=0,hinges=0,coveredRoots=0,retainedCoveredRoots=0,meshRefinements=0,meshRefinementWork=0;
    bool allHidden=false,changed=false;
    std::size_t bytes=0;
};
Pose fitSource(const Source&,const std::vector<Shape>& localObstacles,double clearance,double stiffness,bool cover,std::uint64_t generation,Vec worldUpInSource={0,1,0});
Vec posePoint(const Source&,const Pose&,unsigned vertex);
Vec poseDirection(const Source&,const Pose&,unsigned vertex,Vec);
bool visibleFace(const Source&,const Pose&,unsigned face);
unsigned nearestSourceVertex(const Source&,Vec);
Json auditSource(const Source&,const Pose&,const std::vector<Shape>&,std::size_t triangleBudget=2000000,double deliveryUnit=0);
}
