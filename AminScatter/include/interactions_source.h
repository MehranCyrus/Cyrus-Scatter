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
    std::vector<unsigned> labels,guideRoot,partRoot,rootPivot;
    std::vector<bool> anchors,structuralGuides;
    std::vector<unsigned> fixedVertices,fixedFaces;
    Bounds fixedBounds;
    std::vector<unsigned> sortedVertices;
    std::vector<unsigned> previewFaces,previewVertices,previewRemap;
    std::vector<Tri> previewTriangles,previewUVCorners;
    // Shared source correspondence for rare exact-geometry contact refinement.
    std::vector<std::vector<unsigned>> guideVertices,guideFaces;
    std::vector<ContactTopology> guideContact;
    std::vector<double> rootRadius;
    std::vector<Bounds> guideBounds;
    std::vector<double> guideRadius;
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
    std::vector<bool> hiddenRoots,smoothedRoots,hiddenGuides;
    std::unordered_map<unsigned,stem::Rigid> rigid;
    std::size_t activeGuides=0,queries=0,coverageQueries=0,separationQueries=0,iterations=0,hinges=0,coveredRoots=0,retainedCoveredRoots=0,meshRefinements=0,meshRefinementWork=0;
    // Only guides for which the bounded optional edge check actually ran are
    // counted. This is an early warning, not a complete visible-mesh audit.
    std::size_t qualityCheckedGuides=0,qualityWarningGuides=0;
    std::size_t prunedGuides=0,blockedGuides=0,limitedGuides=0;
    double maximumCheckedStemEdgeChange=0;
    // Summed worker time, not elapsed wall time or a viewport FPS measure.
    double coverageMs=0,meshCheckMs=0,meshTransformMs=0,meshPointMs=0,meshFaceMs=0,edgeQualityMs=0;
    MeshContactWork exact;
    bool allHidden=false,changed=false;
    std::size_t bytes=0;
};
// Process-wide monotonic diagnostics. Counts attempts at actual expensive work,
// not read calls. Relaxed atomics avoid a shared per-query instrumentation cost.
struct WorkCounters {
    std::atomic<std::uint64_t> preparations{0},plantFits{0},layouts{0},evaluations{0},sourceCaptures{0},colliderCooks{0};
};
WorkCounters& workCounters();
Json workCountersJson();
Pose fitSource(const Source&,const std::vector<Shape>& localObstacles,double clearance,double stiffness,bool cover,std::uint64_t generation,Vec worldUpInSource={0,1,0},double hideMargin=0,bool hideUnder=false);
// Explicit artistic approximation: bounded guide envelopes, fixed attachments,
// reversible subtree pruning, and observable unresolved/budget-limited guides.
Pose adaptSource(const Source&,const std::vector<Shape>&,double clearance,double strength,int response,double pruneAmount,double threshold,std::uint64_t seed,double trunkBend=0,double fixedBase=0,double bendTransition=.25,bool cover=false,double hideMargin=0,bool hideUnder=false,Vec worldUpInSource={0,1,0});
std::shared_ptr<const MeshGeometry> branchProxy(const Source&,std::shared_ptr<const void> lease={});
Vec posePoint(const Source&,const Pose&,unsigned vertex);
Vec poseDirection(const Source&,const Pose&,unsigned vertex,Vec);
bool visibleFace(const Source&,const Pose&,unsigned face);
bool visibleVertex(const Source&,const Pose&,unsigned vertex);
Bounds poseEnvelope(const Source&); // Fixed geometry and conservative guide reach.
unsigned nearestSourceVertex(const Source&,Vec);
Json auditSource(const Source&,const Pose&,const std::vector<Shape>&,std::size_t triangleBudget=2000000,double deliveryUnit=0);
}
