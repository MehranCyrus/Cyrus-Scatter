#pragma once
#include <array>
#include <cstdint>
#include <vector>
#include <memory>

namespace cyrus::bands { class Field; }

namespace amin {
struct Vec3 { double x{}, y{}, z{}; };
Vec3 operator+(Vec3 a, Vec3 b);
Vec3 operator-(Vec3 a, Vec3 b);
Vec3 operator*(Vec3 a, double s);
double dot(Vec3 a, Vec3 b);
double length(Vec3 a);
struct Triangle { Vec3 a, b, c; Vec3 uvA{}, uvB{}, uvC{}; };
// Immutable numeric generator output. Keys are local to a receiver and remain
// independent of enumeration/compaction order (e.g. signed lattice cells).
struct CandidateAnchor { std::uint64_t key{}; Vec3 position{},bary{}; std::uint32_t face{}; };
struct Range { double min{}, max{}; };
struct Area { std::vector<std::vector<Vec3>> loops; bool include{true}; };
struct AnalyzerBand { Area boundary; double width{1}; std::vector<std::uint32_t> sources; double scaleMin{1},scaleMax{1};
    int kind{1}; // Analyzer: 1/2 outer/inner border, 3 center, 4 radius, 5 single
    double start{0};
    std::vector<bool> boundaryMask;
    bool straightEnds=false; // Optional distance-edge mask; closed-loop containment stays intact.
    bool faceOutward=false;
    double cornerRadius=0;
    Vec3 edgeRotation{};
    bool edgeKeepCorners=false; double edgeCornerAngle=45; int edgeCornerCount=1;
    double edgeOffset=0,edgeAlongJitter=0,edgeAcrossJitter=0; // kind 6: ordered boundary row; width=spacing.
};
struct Settings {
    // One counter-based candidate stream. Masks thin its bounded prefix.
    std::uint64_t candidateStart{0};
    std::uint64_t receiverSalt{0}; // Persistent receiver identity; never a list index.
    std::vector<double> sourceWeights; // Empty means equal weights.
    bool relaxEnabled{false};
    double relaxSpacing{0.2}, relaxStrength{0.5};
    std::uint32_t relaxIterations{10};
    std::uint32_t seed{42};
    std::uint32_t count{1000};
    std::uint32_t sourceCount{1};
    Range uniformScale{0.8, 1.2};
    std::array<Range, 3> rotationDegrees{{{0,0}, {0,0}, {0,360}}};
    // World-space movement is projected to the nearest point on the surface.
    // Projection is exhaustive in this reference core; accelerate in the host adapter.
    std::array<Range, 3> movement{{{0,0}, {0,0}, {0,0}}};
    bool alignToNormal{true};
    std::array<Range,3> axisScale{{{1,1},{1,1},{1,1}}};
    bool projectMovement{true};
    int distribution{0}; // 0 random, 2 UV density; clustering is source diversity.
    std::uint32_t densityWidth{}, densityHeight{};
    std::vector<double> density; // rows from v=1 to v=0; clamped UVs
    std::vector<std::uint32_t> sourceGroups; // optional stable keys, one per source
    bool clusterEnabled{false}; // diversity only; never changes placement
    double clusterSize{10}, clusterRoughness{0}, clusterBlur{0}, clusterNoise{0};
    std::uint32_t clusterSeed{42};
    std::vector<Area> areas; // world XY projection; include union minus exclusions
    bool analyzerPattern{false}; // source assignment only; outside closed boundaries
    std::vector<AnalyzerBand> analyzerBands; // first matching row wins
    std::shared_ptr<const cyrus::bands::Field> splineField;
};
struct Instance {
    Vec3 position, xAxis, yAxis, zAxis;
    double scale{};
    std::uint32_t source{}, triangle{};
    // Candidate ordinal is assigned before rejection or compaction. A Brush
    // edit never changes it. Host bridges may attach an immutable base anchor.
    std::uint64_t candidateKey{};
    bool keyed=false;
    std::uint32_t anchorFace{};
    Vec3 anchorBary{1,0,0};
    std::uint64_t bandOwner=0;
    Vec3 transformPoint(Vec3 local) const;
};
struct BoundaryFalloff { bool remove=false,scale=false,density=false; int areaSide=0; double removeWidth=0,scaleWidth=100,densityWidth=100; std::vector<double> scaleCurve{0,.25,.5,.75,1},densityCurve{0,.25,.5,.75,1}; };
double stableUnit(std::uint32_t seed,std::uint64_t ordinal,std::uint64_t channel,std::uint64_t receiver=0);
std::vector<Instance> boundaryFalloff(const std::vector<Instance>&,const std::vector<std::vector<Vec3>>&,const BoundaryFalloff&,std::uint32_t);
// Forward axes: 1=+Y, 2=-Y, 3=+X, 4=-X. Changes basis only.
void orientBoundary(std::vector<Instance>&,const std::vector<AnalyzerBand>&,
                    const std::vector<int>&,const std::vector<double>& offsets={});
std::vector<Vec3> edgeBorderPoints(const AnalyzerBand&,std::uint32_t seed);
Settings prepareEdgeRows(const Settings&);
// All surface vertices must already be in world space. Source vertices are in
// pivot-local space. Empty/degenerate/non-finite input raises invalid_argument.
std::vector<Instance> scatter(const std::vector<Triangle>& surface, const Settings& settings);
// Reuses the complete scatter pipeline with explicit, already projected anchors.
// count must equal anchors.size(), candidateStart must be zero. No random refill.
std::vector<Instance> scatter(const std::vector<Triangle>& surface, const Settings& settings,
                              const std::vector<CandidateAnchor>& anchors);
struct FinalSettings { bool cleanup{false},relax{false},planar{true}; double radius{1},strength{.3},maxMove{.1},gap{0}; unsigned minNeighbors{2},minIsland{5},iterations{5}; };
// Optional caller-owned budget. Procedural replay shares the remaining budget
// with spacing; direct numerical callers may omit this budget.
struct FinalWorkBudget {
    std::uint64_t limit{},visits{};
    std::vector<std::uint64_t> rowVisits;
};
std::vector<Instance> finalize(const std::vector<Triangle>&,const Settings&,std::vector<Instance>,const std::vector<Instance>&,const std::vector<double>&,const std::vector<double>&,const FinalSettings&,FinalWorkBudget* = nullptr);
// Area-weighted points from actual source geometry, not placement markers.
std::vector<Vec3> sampleSource(const std::vector<Triangle>& source, std::uint32_t count,
                             std::uint32_t seed);
struct PreviewPoint { Vec3 position; std::uint32_t source; std::uint64_t bandOwner=0; };
// Strict global point budget. Deterministically subsamples instances and points.
std::vector<PreviewPoint> pointCloud(const std::vector<Instance>& instances,
    const std::vector<std::vector<Vec3>>& sourceSamples, std::uint32_t budget);
}



