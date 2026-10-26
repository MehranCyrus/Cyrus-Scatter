#pragma once

#include <cyrus_vegetation/prototype_v1.hpp>

#include <algorithm>
#include <array>
#include <cmath>
#include <cstddef>
#include <cstdint>
#include <limits>
#include <optional>
#include <string>
#include <vector>

namespace cyrus::vegetation::prototype_v1::delivery_detail {

constexpr double kPi = 3.141592653589793238462643383279502884;
constexpr double kTiny = 1.0e-14;
constexpr double kAxisTiny = 1.0e-24;
constexpr double kUnitQuatTolerance = 1.0e-8;
constexpr double kUnitNormalTolerance = 1.0e-8;

inline bool finite(double v) noexcept { return std::isfinite(v); }
inline bool finite(Vec3 v) noexcept { return finite(v.x) && finite(v.y) && finite(v.z); }
inline bool finite(Quat q) noexcept { return finite(q.x) && finite(q.y) && finite(q.z) && finite(q.w); }
inline bool finite(UV uv) noexcept { return finite(uv.u) && finite(uv.v); }

inline Vec3 add(Vec3 a, Vec3 b) noexcept { return {a.x + b.x, a.y + b.y, a.z + b.z}; }
inline Vec3 sub(Vec3 a, Vec3 b) noexcept { return {a.x - b.x, a.y - b.y, a.z - b.z}; }
inline Vec3 mul(Vec3 v, double s) noexcept { return {v.x * s, v.y * s, v.z * s}; }
inline Vec3 div(Vec3 v, double s) noexcept { return {v.x / s, v.y / s, v.z / s}; }
inline double dot(Vec3 a, Vec3 b) noexcept { return a.x * b.x + a.y * b.y + a.z * b.z; }
inline Vec3 cross(Vec3 a, Vec3 b) noexcept {
    return {a.y * b.z - a.z * b.y, a.z * b.x - a.x * b.z, a.x * b.y - a.y * b.x};
}
inline double length_sq(Vec3 v) noexcept { return dot(v, v); }
inline double length(Vec3 v) noexcept { return std::sqrt(length_sq(v)); }
inline double distance(Vec3 a, Vec3 b) noexcept { return length(sub(a, b)); }
inline Vec3 abs_vec(Vec3 v) noexcept { return {std::abs(v.x), std::abs(v.y), std::abs(v.z)}; }
inline double clamp_unit(double v) noexcept { return std::clamp(v, -1.0, 1.0); }

inline std::optional<Vec3> normalized(Vec3 v) noexcept {
    const double len = length(v);
    if (!finite(len) || len <= kTiny) return std::nullopt;
    return div(v, len);
}

inline double quat_norm_sq(Quat q) noexcept { return q.x * q.x + q.y * q.y + q.z * q.z + q.w * q.w; }
inline double quat_dot(Quat a, Quat b) noexcept { return a.x * b.x + a.y * b.y + a.z * b.z + a.w * b.w; }
inline Quat quat_negate(Quat q) noexcept { return {-q.x, -q.y, -q.z, -q.w}; }
inline Quat quat_conjugate(Quat q) noexcept { return {-q.x, -q.y, -q.z, q.w}; }
inline Quat quat_add(Quat a, Quat b) noexcept { return {a.x + b.x, a.y + b.y, a.z + b.z, a.w + b.w}; }
inline Quat quat_mul_scalar(Quat q, double s) noexcept { return {q.x * s, q.y * s, q.z * s, q.w * s}; }

inline std::optional<Quat> normalized(Quat q) noexcept {
    const double n2 = quat_norm_sq(q);
    if (!finite(n2) || n2 <= kTiny) return std::nullopt;
    const double inv = 1.0 / std::sqrt(n2);
    return Quat{q.x * inv, q.y * inv, q.z * inv, q.w * inv};
}

inline bool approximately_unit(Quat q) noexcept {
    if (!finite(q)) return false;
    const double n = std::sqrt(quat_norm_sq(q));
    return finite(n) && std::abs(n - 1.0) <= kUnitQuatTolerance;
}

inline Vec3 rotate(Quat q, Vec3 v) noexcept {
    const Vec3 u{q.x, q.y, q.z};
    const Vec3 t = mul(cross(u, v), 2.0);
    return add(v, add(mul(t, q.w), cross(u, t)));
}

inline Vec3 inverse_rotate(Quat q, Vec3 v) noexcept { return rotate(quat_conjugate(q), v); }

inline double quaternion_geodesic_angle(Quat a, Quat b) noexcept {
    const auto an = normalized(a);
    const auto bn = normalized(b);
    if (!an || !bn) return std::numeric_limits<double>::infinity();
    const double d = std::abs(quat_dot(*an, *bn));
    return 2.0 * std::acos(std::clamp(d, 0.0, 1.0));
}

inline std::optional<Quat> shortest_slerp(Quat a, Quat b, double u) noexcept {
    auto qa = normalized(a);
    auto qb = normalized(b);
    if (!qa || !qb || !finite(u)) return std::nullopt;
    double d = quat_dot(*qa, *qb);
    if (d < 0.0) {
        *qb = quat_negate(*qb);
        d = -d;
    }
    d = std::clamp(d, 0.0, 1.0);
    // Nlerp over a finite angle can exceed an explicitly tight positional
    // reconstruction tolerance. Use it only at the coincident-frame limit.
    if (d == 1.0) {
        return normalized(quat_add(quat_mul_scalar(*qa, 1.0 - u), quat_mul_scalar(*qb, u)));
    }
    const double theta = std::acos(d);
    const double sin_theta = std::sin(theta);
    if (!finite(theta) || std::abs(sin_theta) <= kTiny) return std::nullopt;
    const double w0 = std::sin((1.0 - u) * theta) / sin_theta;
    const double w1 = std::sin(u * theta) / sin_theta;
    return normalized(quat_add(quat_mul_scalar(*qa, w0), quat_mul_scalar(*qb, w1)));
}

inline double vector_angle(Vec3 a, Vec3 b) noexcept {
    const auto an = normalized(a);
    const auto bn = normalized(b);
    if (!an || !bn) return std::numeric_limits<double>::infinity();
    return std::acos(clamp_unit(dot(*an, *bn)));
}

inline bool checked_mul(std::size_t a, std::size_t b, std::size_t& out) noexcept {
    if (a != 0 && b > std::numeric_limits<std::size_t>::max() / a) return false;
    out = a * b;
    return true;
}

inline bool checked_add(std::size_t a, std::size_t b, std::size_t& out) noexcept {
    if (b > std::numeric_limits<std::size_t>::max() - a) return false;
    out = a + b;
    return true;
}

inline bool add_bytes(std::size_t count, std::size_t element, std::size_t& total) noexcept {
    std::size_t term = 0;
    if (!checked_mul(count, element, term)) return false;
    return checked_add(total, term, total);
}

inline bool all_limits_positive(const Limits& l) noexcept {
    return l.max_obstacles != 0 && l.max_nodes != 0 && l.max_contacts_per_query != 0 &&
           l.max_query_calls != 0 && l.max_iterations != 0 && l.max_render_vertices != 0 &&
           l.max_render_triangles != 0 && l.max_owned_and_scratch_bytes != 0;
}

inline bool all_tolerances_positive(const Tolerances& t) noexcept {
    return finite(t.root_m) && finite(t.penetration_m) && finite(t.relative_length) &&
           finite(t.frame_radians) && finite(t.rest_reconstruction_m) &&
           t.root_m > 0.0 && t.penetration_m > 0.0 && t.relative_length > 0.0 &&
           t.frame_radians > 0.0 && t.rest_reconstruction_m > 0.0;
}

inline void add_issue(std::vector<Issue>& issues, std::string code, std::string message,
                      Id object_id = 0, Id span_id = 0) {
    issues.push_back(Issue{std::move(code), std::move(message), object_id, span_id});
}

inline std::optional<std::size_t> span_index(const RestGuide& rest, Id span_id) noexcept {
    for (std::size_t i = 0; i < rest.span_ids.size(); ++i)
        if (rest.span_ids[i] == span_id) return i;
    return std::nullopt;
}

inline bool unique_nonzero(const std::vector<Id>& ids) {
    for (std::size_t i = 0; i < ids.size(); ++i) {
        if (ids[i] == 0) return false;
        for (std::size_t j = 0; j < i; ++j)
            if (ids[j] == ids[i]) return false;
    }
    return true;
}

inline bool unique_nonzero_render_ids(const std::vector<BoundVertex>& bindings) {
    for (std::size_t i = 0; i < bindings.size(); ++i) {
        if (bindings[i].render_vertex_id == 0 || bindings[i].logical_vertex_id == 0) return false;
        for (std::size_t j = 0; j < i; ++j)
            if (bindings[j].render_vertex_id == bindings[i].render_vertex_id) return false;
    }
    return true;
}

struct FrameCheck {
    enum class State { Ok, Invalid, Ambiguous, Unsupported } state = State::Ok;
    std::string code;
    std::string message;
    Id span_id = 0;
};

inline FrameCheck check_frames(const std::vector<Vec3>& nodes, const std::vector<Quat>& frames,
                               const std::vector<Id>& span_ids, double frame_tolerance,
                               bool requires_full_turn) {
    if (requires_full_turn)
        return {FrameCheck::State::Unsupported, "unsupported_full_turn",
                "The v1 sampler does not support authored full-turn twist.", 0};
    if (nodes.size() < 2 || frames.size() != nodes.size() || span_ids.size() + 1 != nodes.size())
        return {FrameCheck::State::Invalid, "frame_count_mismatch", "Guide node/frame/span counts do not match.", 0};

    std::vector<Vec3> directed;
    directed.reserve(nodes.size() - 1);
    for (std::size_t i = 0; i + 1 < nodes.size(); ++i) {
        const auto t = normalized(sub(nodes[i + 1], nodes[i]));
        if (!t) return {FrameCheck::State::Invalid, "zero_length_span", "Guide contains a zero-length span.", span_ids[i]};
        directed.push_back(*t);
    }

    for (std::size_t i = 0; i < frames.size(); ++i) {
        if (!approximately_unit(frames[i]))
            return {FrameCheck::State::Invalid, "nonunit_frame", "Material frame is non-finite or not unit length.", i < span_ids.size() ? span_ids[i] : span_ids.back()};
        Vec3 tangent;
        if (i == 0) tangent = directed.front();
        else if (i + 1 == nodes.size()) tangent = directed.back();
        else {
            const auto bisector = normalized(add(directed[i - 1], directed[i]));
            if (!bisector)
                return {FrameCheck::State::Ambiguous, "antiparallel_tangent_bisector",
                        "Incoming and outgoing guide tangents have an undefined antiparallel bisector.", span_ids[i - 1]};
            tangent = *bisector;
        }
        const Vec3 frame_z = rotate(frames[i], Vec3{0.0, 0.0, 1.0});
        const double angle = vector_angle(frame_z, tangent);
        if (!finite(angle) || angle > frame_tolerance)
            return {FrameCheck::State::Invalid, "frame_tangent_mismatch", "Material frame local +Z does not match the guide tangent.", i < span_ids.size() ? span_ids[i] : span_ids.back()};
    }

    for (std::size_t i = 0; i + 1 < frames.size(); ++i) {
        const double angle = quaternion_geodesic_angle(frames[i], frames[i + 1]);
        if (!finite(angle))
            return {FrameCheck::State::Invalid, "invalid_adjacent_frames", "Adjacent frame comparison is non-finite.", span_ids[i]};
        if (angle >= kPi - frame_tolerance)
            return {FrameCheck::State::Ambiguous, "ambiguous_pi_frame_rotation",
                    "Adjacent material frames are at or too near an ambiguous pi rotation.", span_ids[i]};
    }
    return {};
}

inline Vec3 triangle_cross(Vec3 a, Vec3 b, Vec3 c) noexcept { return cross(sub(b, a), sub(c, a)); }

inline double point_triangle_distance_sq(Vec3 p, Vec3 a, Vec3 b, Vec3 c) noexcept {
    const Vec3 ab = sub(b, a);
    const Vec3 ac = sub(c, a);
    const Vec3 ap = sub(p, a);
    const double d1 = dot(ab, ap);
    const double d2 = dot(ac, ap);
    if (d1 <= 0.0 && d2 <= 0.0) return length_sq(ap);

    const Vec3 bp = sub(p, b);
    const double d3 = dot(ab, bp);
    const double d4 = dot(ac, bp);
    if (d3 >= 0.0 && d4 <= d3) return length_sq(bp);

    const double vc = d1 * d4 - d3 * d2;
    if (vc <= 0.0 && d1 >= 0.0 && d3 <= 0.0) {
        const double v = d1 / (d1 - d3);
        return length_sq(sub(p, add(a, mul(ab, v))));
    }

    const Vec3 cp = sub(p, c);
    const double d5 = dot(ab, cp);
    const double d6 = dot(ac, cp);
    if (d6 >= 0.0 && d5 <= d6) return length_sq(cp);

    const double vb = d5 * d2 - d1 * d6;
    if (vb <= 0.0 && d2 >= 0.0 && d6 <= 0.0) {
        const double w = d2 / (d2 - d6);
        return length_sq(sub(p, add(a, mul(ac, w))));
    }

    const double va = d3 * d6 - d5 * d4;
    if (va <= 0.0 && (d4 - d3) >= 0.0 && (d5 - d6) >= 0.0) {
        const Vec3 bc = sub(c, b);
        const double w = (d4 - d3) / ((d4 - d3) + (d5 - d6));
        return length_sq(sub(p, add(b, mul(bc, w))));
    }

    const double denom = 1.0 / (va + vb + vc);
    const double v = vb * denom;
    const double w = vc * denom;
    const Vec3 closest = add(a, add(mul(ab, v), mul(ac, w)));
    return length_sq(sub(p, closest));
}

struct TriBoxResult {
    bool overlaps = false;
    double minimum_axis_overlap = 0.0; // SAT-axis overlap in local metres; not exact Euclidean penetration.
};

inline bool axis_separates(Vec3 axis, const std::array<Vec3, 3>& tri, Vec3 extents,
                           double& overlap_out) noexcept {
    const double l2 = length_sq(axis);
    if (l2 <= kAxisTiny) {
        overlap_out = std::numeric_limits<double>::infinity();
        return false;
    }
    const double inv_len = 1.0 / std::sqrt(l2);
    const Vec3 n = mul(axis, inv_len);
    const double p0 = dot(tri[0], n);
    const double p1 = dot(tri[1], n);
    const double p2 = dot(tri[2], n);
    const double mn = std::min({p0, p1, p2});
    const double mx = std::max({p0, p1, p2});
    const double r = extents.x * std::abs(n.x) + extents.y * std::abs(n.y) + extents.z * std::abs(n.z);
    overlap_out = std::min(mx, r) - std::max(mn, -r);
    return overlap_out < 0.0;
}

inline TriBoxResult triangle_aabb_sat(const std::array<Vec3, 3>& tri, Vec3 extents) noexcept {
    const Vec3 e0 = sub(tri[1], tri[0]);
    const Vec3 e1 = sub(tri[2], tri[1]);
    const Vec3 e2 = sub(tri[0], tri[2]);
    const std::array<Vec3, 3> box_axes{Vec3{1, 0, 0}, Vec3{0, 1, 0}, Vec3{0, 0, 1}};
    double min_overlap = std::numeric_limits<double>::infinity();
    auto test_axis = [&](Vec3 axis) {
        double overlap = 0.0;
        if (axis_separates(axis, tri, extents, overlap)) return false;
        if (finite(overlap)) min_overlap = std::min(min_overlap, overlap);
        return true;
    };

    for (Vec3 axis : box_axes) if (!test_axis(axis)) return {false, 0.0};
    if (!test_axis(cross(e0, e1))) return {false, 0.0};
    for (Vec3 edge : std::array<Vec3, 3>{e0, e1, e2})
        for (Vec3 axis : box_axes)
            if (!test_axis(cross(edge, axis))) return {false, 0.0};

    if (!finite(min_overlap)) min_overlap = 0.0;
    return {true, std::max(0.0, min_overlap)};
}

inline bool same_vec_exact(Vec3 a, Vec3 b) noexcept { return a.x == b.x && a.y == b.y && a.z == b.z; }
inline bool same_uv_exact(UV a, UV b) noexcept { return a.u == b.u && a.v == b.v; }

inline Vec3 bounds_min_of(const std::vector<Vec3>& positions) noexcept {
    Vec3 out{std::numeric_limits<double>::infinity(), std::numeric_limits<double>::infinity(), std::numeric_limits<double>::infinity()};
    for (Vec3 p : positions) {
        out.x = std::min(out.x, p.x); out.y = std::min(out.y, p.y); out.z = std::min(out.z, p.z);
    }
    return out;
}
inline Vec3 bounds_max_of(const std::vector<Vec3>& positions) noexcept {
    Vec3 out{-std::numeric_limits<double>::infinity(), -std::numeric_limits<double>::infinity(), -std::numeric_limits<double>::infinity()};
    for (Vec3 p : positions) {
        out.x = std::max(out.x, p.x); out.y = std::max(out.y, p.y); out.z = std::max(out.z, p.z);
    }
    return out;
}

inline bool cancelled(Cancellation c) noexcept { return c.requested(); }

} // namespace cyrus::vegetation::prototype_v1::delivery_detail
