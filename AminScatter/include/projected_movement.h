#pragma once
#include "scatter.h"
#include "projection_work.h"
#include <memory>
#include <utility>

namespace amin::detail {
// Call-owned immutable geometry index. Mesh and eligible order remain borrowed;
// only the permutation and nodes are allocated. Equal distances always choose
// the first eligible entry, independently of tree order or the sampled hint.
// This policy deliberately does not replace SurfaceTree's Relax hint policy.
class ProjectedMovementIndex {
    struct Impl;
    std::unique_ptr<Impl> impl_;
public:
    ProjectedMovementIndex(const std::vector<Triangle>&,const std::vector<std::uint32_t>& eligible,ProjectionWorkBudget&);
    ~ProjectedMovementIndex();
    std::pair<Vec3,std::uint32_t> project(Vec3) const;
};
}
