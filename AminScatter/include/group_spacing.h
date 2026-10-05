#pragma once
#include "scatter.h"
#include <cstddef>
#include <vector>
#include <limits>

namespace cyrus::groups {
struct Rule {
    std::vector<amin::Vec3> blockers;
    std::vector<double> ownRadii, blockerRadii;
    double gap=0;
    bool planar=false;
};
struct Result {
    std::vector<std::size_t> kept, conflicts;
};
// Input is already masked/edited. Protected artist overrides reserve their
// actual positions and survive conflicts; callers must display those conflicts.
// No Max API, mutation, movement, random state or scene access is used here.
Result resolve(const std::vector<amin::Vec3>& positions, double withinDistance,
               const std::vector<Rule>& rules, const std::vector<bool>& protect);
enum class Reason { NotConsumed, Accepted, Protected, LayerSpacing, SetSpacing, SelfSpacing, Cleanup };
struct DistanceRule { bool enabled=false; double multiplier=1, gap=0; bool planar=false; };
struct ScopedRule { Rule values; double multiplier=1; Reason reason=Reason::LayerSpacing; };
struct DetailedResult {
    std::vector<std::size_t> kept, conflicts;
    std::vector<Reason> reasons;
    std::uint64_t neighborVisits=0;
};
DetailedResult resolveVariable(const std::vector<amin::Vec3>& positions,
    const std::vector<double>& radii, const DistanceRule& self,
    const std::vector<ScopedRule>& rules, const std::vector<bool>& protect,
    std::size_t target, std::uint64_t maxNeighborVisits=std::numeric_limits<std::uint64_t>::max());
}
