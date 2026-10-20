#pragma once
#include "cyrus_arrange/geometry.h"
#include <cmath>
#include <limits>

namespace cyrus::arrange::detail {
inline constexpr std::size_t no_receiver_component=std::numeric_limits<std::size_t>::max();
struct ReceiverComponent {
    Bounds bounds{{INFINITY,INFINITY,INFINITY},{-INFINITY,-INFINITY,-INFINITY}};
    std::uint64_t body_id{};
    bool closed{true},obstacle{};
};
struct ReceiverTopology {
    std::vector<std::size_t> face_components;
    std::uint64_t work{};
};
// Appends components for one body without merging independently captured nodes.
// The DSU's own storage becomes the returned label buffer; no second face map.
ReceiverTopology append_receiver_topology(const Mesh&,std::vector<ReceiverComponent>&,
    std::uint64_t body_id,bool obstacle,double max_coordinate,std::uint64_t max_work);
}
