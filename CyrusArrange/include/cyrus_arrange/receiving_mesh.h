#pragma once
#include "cyrus_arrange/geometry.h"
#include <span>

namespace cyrus::arrange {
struct ReceivingMeshLimits {
    std::size_t max_bodies{4096},max_vertices{3000000},max_triangles{1000000};
    std::uint64_t max_work{50000000};
    double max_coordinate_mm{10000000};
};
struct ReceivingMeshPreparation {
    std::size_t reversed_components{},reversed_faces{},open_components{},ambiguous_components{};
    std::uint64_t work{};
};
// Supplied meshes must be private native capture copies. Scene/source geometry
// is never an inlet. All admission/analysis finishes before the no-throw swaps.
// Nested/potentially intersecting, open and ambiguous closed shells keep winding.
ReceivingMeshPreparation prepare_receiving_meshes(std::span<Mesh* const>,const ReceivingMeshLimits& = {});
void append_receiving_warnings(Result&,const ReceivingMeshPreparation&);
}
