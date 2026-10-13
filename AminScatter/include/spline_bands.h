#pragma once
#include "scatter.h"
#include <memory>
#include <cstddef>
#include <string>
#include <functional>

namespace cyrus::bands {
enum class Join { Rounded, Sharp };
enum class Arrangement { Consecutive, Independent };
struct Path { std::uint64_t id=0; amin::Area area; Join join=Join::Rounded; };
struct Source { std::string id; std::uint32_t index=0; double weight=1; bool empty=false; };
struct Band {
    std::uint64_t id=0,path=0;
    bool inside=false;
    double start=0,end=1,strength=1;
    std::vector<double> curve{1,1};
    std::vector<Source> sources;
    amin::Range scale{1,1};
    // Effective multiplier trace: Off is flat one; UI resolves Follow Density.
    std::vector<double> scaleCurve{1,1};
};
// The caller supplies physical precision in SYSTEM units, never display units.
// Limits include all paths/sides in this prepared field, not one cache per Band.
struct Limits {
    double quantum=1e-5, aggregateError=.005, progressError=1./256, scaleError=.005;
    std::size_t paths=32,bands=64,memberships=65536,inputVertices=8192,levels=32768,vertices=2000000;
    std::size_t queryVisits=262144,bytes=128*1024*1024;
    std::size_t constructionWork=250000000,constructionBytes=256*1024*1024;
};
struct Stats { std::size_t inputVertices=0,levels=0,vertices=0,bytes=0,constructionWork=0,scratchAllowance=0; };
// Admission reservations include all live fields, including retained and
// staged successors. This is an owned-data allowance, not process working set.
std::size_t reservedFieldBytes();
struct Cubic { amin::Vec3 a,b,c,d; };
// Closed cubic chain -> XY polyline. The convex-hull/chord error is certified
// per accepted leaf; no fixed sample count is treated as an accuracy bound.
std::vector<amin::Vec3> tessellate(const std::vector<Cubic>&,double tolerance,std::size_t maxVertices);
struct Contribution { std::uint64_t band=0; double value=0,progress=0,error=0; bool boundaryUncertain=false; };
struct Inspection { std::vector<Contribution> contributions; double occupancy=0,error=0; std::size_t visits=0; };
struct Decision {
    bool emitted=false;
    std::uint64_t band=0;
    std::string sourceId;
    std::uint32_t source=0;
    double scale=1,occupancy=0;
};
struct OutlineLimits {
    std::size_t segments=32768,work=50000000,bytes=128u*1024u*1024u;
};
struct OutlineStats {
    std::size_t levels=0,segments=0,work=0,scratchAllowance=0;
    double error=0;
};
// Immutable numeric data only. No host calls, Clipper work or cache writes in
// inspect/select. Shared by generation, movement validation and field preview.
class Field {
    struct Data;
    std::shared_ptr<const Data> data_;
public:
    Field(std::vector<Path>,std::vector<Band>,Arrangement,const Limits& = {});
    Inspection inspect(amin::Vec3,std::size_t visitLimit=std::size_t(-1)) const;
    Decision select(amin::Vec3,double occupancy,double owner,double source,double scale) const;
    Decision sample(amin::Vec3,std::uint32_t seed,std::uint64_t ordinal,std::uint64_t receiver) const;
    // Zero selects all Bands. Contours are streamed, never retained per Band.
    // Sharp reuses exact prepared endpoint levels. Rounded approximates the
    // distance to the original segments, including holes and self-overlaps.
    // The callback receives world XY segments (z=0), before receiver clipping.
    OutlineStats visitOutlines(std::uint64_t selected,const std::function<void(amin::Vec3,amin::Vec3)>&,
                              const OutlineLimits& = {}) const;
    bool hasBand(std::uint64_t) const;
    const Stats& stats() const;
};
double curveValue(const std::vector<double>&,double progress);
}
