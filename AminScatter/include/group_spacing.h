#pragma once
#include "scatter.h"
#include <cstddef>
#include <vector>

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
}
