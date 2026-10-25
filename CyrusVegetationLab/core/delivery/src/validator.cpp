#include <cyrus_vegetation/prototype_v1.hpp>

#include "geometry.hpp"

#include <algorithm>
#include <array>
#include <cmath>
#include <cstddef>
#include <cstdint>
#include <exception>
#include <limits>
#include <new>
#include <optional>
#include <sstream>
#include <string>
#include <utility>
#include <vector>

namespace cyrus::vegetation::prototype_v1 {
namespace {
using namespace delivery_detail;

struct ValidationWork {
    ValidationResult result;
    bool failed = false;
};

void fail_candidate(ValidationWork& work, std::string code, std::string message,
                    Id object_id = 0, Id span_id = 0) {
    work.failed = true;
    add_issue(work.result.issues, std::move(code), std::move(message), object_id, span_id);
}

ValidationResult terminal(ValidationStatus status, Generation generation,
                          std::string code, std::string message,
                          Id object_id = 0, Id span_id = 0) {
    ValidationResult out;
    out.status = status;
    out.generation = generation;
    add_issue(out.issues, std::move(code), std::move(message), object_id, span_id);
    return out;
}

Quat reference_normalize(Quat q) {
    const double n = std::sqrt(q.x*q.x + q.y*q.y + q.z*q.z + q.w*q.w);
    return {q.x/n, q.y/n, q.z/n, q.w/n};
}

Vec3 reference_rotate(Quat q, Vec3 v) noexcept {
    const double xx = q.x*q.x, yy = q.y*q.y, zz = q.z*q.z;
    const double xy = q.x*q.y, xz = q.x*q.z, yz = q.y*q.z;
    const double wx = q.w*q.x, wy = q.w*q.y, wz = q.w*q.z;
    return {
        (1.0 - 2.0*(yy + zz))*v.x + 2.0*(xy - wz)*v.y + 2.0*(xz + wy)*v.z,
        2.0*(xy + wz)*v.x + (1.0 - 2.0*(xx + zz))*v.y + 2.0*(yz - wx)*v.z,
        2.0*(xz - wy)*v.x + 2.0*(yz + wx)*v.y + (1.0 - 2.0*(xx + yy))*v.z
    };
}

Vec3 reference_inverse_rotate(Quat q, Vec3 v) noexcept {
    return reference_rotate(Quat{-q.x, -q.y, -q.z, q.w}, v);
}

std::optional<Quat> reference_slerp(Quat a, Quat b, double u) noexcept {
    if (!finite(a) || !finite(b) || !finite(u)) return std::nullopt;
    const double na = std::sqrt(quat_norm_sq(a));
    const double nb = std::sqrt(quat_norm_sq(b));
    if (na <= kTiny || nb <= kTiny || !finite(na) || !finite(nb)) return std::nullopt;
    a = {a.x/na, a.y/na, a.z/na, a.w/na};
    b = {b.x/nb, b.y/nb, b.z/nb, b.w/nb};
    double c = a.x*b.x + a.y*b.y + a.z*b.z + a.w*b.w;
    if (c < 0.0) { b = {-b.x, -b.y, -b.z, -b.w}; c = -c; }
    c = std::clamp(c, 0.0, 1.0);
    const double angle = std::acos(c);
    Quat q;
    if (c == 1.0) {
        q = {a.x + u*(b.x-a.x), a.y + u*(b.y-a.y), a.z + u*(b.z-a.z), a.w + u*(b.w-a.w)};
    } else {
        const double inv_sin = 1.0 / std::sin(angle);
        const double wa = std::sin((1.0-u)*angle) * inv_sin;
        const double wb = std::sin(u*angle) * inv_sin;
        q = {wa*a.x + wb*b.x, wa*a.y + wb*b.y, wa*a.z + wb*b.z, wa*a.w + wb*b.w};
    }
    const double nq = std::sqrt(quat_norm_sq(q));
    if (nq <= kTiny || !finite(nq)) return std::nullopt;
    return Quat{q.x/nq, q.y/nq, q.z/nq, q.w/nq};
}

std::optional<Vec3> reference_sample(const std::vector<Vec3>& nodes,
                                     const std::vector<Quat>& frames,
                                     std::size_t span, double u, Vec3 offset) noexcept {
    if (span + 1 >= nodes.size() || frames.size() != nodes.size()) return std::nullopt;
    const Vec3 center{
        nodes[span].x + u*(nodes[span+1].x - nodes[span].x),
        nodes[span].y + u*(nodes[span+1].y - nodes[span].y),
        nodes[span].z + u*(nodes[span+1].z - nodes[span].z)
    };
    const auto q = reference_slerp(frames[span], frames[span+1], u);
    if (!q) return std::nullopt;
    const Vec3 r = reference_rotate(*q, offset);
    const Vec3 p{center.x+r.x, center.y+r.y, center.z+r.z};
    return finite(p) ? std::optional<Vec3>{p} : std::nullopt;
}

bool valid_options(const SolveOptions& options, ValidationResult& result) {
    if (!all_limits_positive(options.limits)) {
        result.status = ValidationStatus::InvalidInput;
        add_issue(result.issues, "invalid_limits", "Every Limits field must be nonzero.");
        return false;
    }
    if (!all_tolerances_positive(options.tolerances) || options.tolerances.frame_radians >= kPi) {
        result.status = ValidationStatus::InvalidInput;
        add_issue(result.issues, "invalid_tolerances", "Tolerances must be finite, positive and frame_radians must be smaller than pi.");
        return false;
    }
    if (!finite(options.clearance_m) || options.clearance_m < 0.0 ||
        !finite(options.rest_shape_weight) || options.rest_shape_weight < 0.0 ||
        !finite(options.bend_weight) || options.bend_weight < 0.0 ||
        !finite(options.root_angle_weight) || options.root_angle_weight < 0.0 ||
        !finite(options.max_proposal_step_m) || options.max_proposal_step_m <= 0.0) {
        result.status = ValidationStatus::InvalidInput;
        add_issue(result.issues, "invalid_solve_options", "Clearance/weights/proposal step violate the frozen admission profile.");
        return false;
    }
    if (options.root_mode != RootMode::PositionOnly && options.root_mode != RootMode::ClampFrame &&
        options.root_mode != RootMode::SoftFrame) {
        result.status = ValidationStatus::InvalidInput;
        add_issue(result.issues, "invalid_root_mode", "Root mode is not a supported contract enumerator.");
        return false;
    }
    if (options.root_mode == RootMode::SoftFrame && options.root_angle_weight <= 0.0) {
        result.status = ValidationStatus::InvalidInput;
        add_issue(result.issues, "soft_frame_zero_weight", "SoftFrame requires a positive root_angle_weight in this validator.");
        return false;
    }
    return true;
}

bool validate_snapshot(const SceneSnapshot& snapshot, const SolveOptions& options,
                       ValidationResult& result) {
    result.generation = snapshot.generation;
    if (snapshot.generation == 0) {
        result.status = ValidationStatus::InvalidInput;
        add_issue(result.issues, "invalid_generation", "Scene generation must be nonzero.");
        return false;
    }
    if (snapshot.obstacles.size() > options.limits.max_obstacles) {
        result.status = ValidationStatus::ResourceLimit;
        add_issue(result.issues, "obstacle_limit", "Snapshot exceeds max_obstacles.");
        return false;
    }
    for (std::size_t i = 0; i < snapshot.obstacles.size(); ++i) {
        const Obstacle& o = snapshot.obstacles[i];
        if (o.id == 0 || o.geometry_revision == 0 || o.pose_revision == 0 || !finite(o.center) || !approximately_unit(o.orientation)) {
            result.status = ValidationStatus::InvalidInput;
            add_issue(result.issues, "invalid_obstacle_identity_or_pose", "Obstacle identity, revisions, center and orientation must be valid.", o.id);
            return false;
        }
        if (!finite(o.sphere_radius) || !finite(o.box_half_extents)) {
            result.status = ValidationStatus::InvalidInput;
            add_issue(result.issues, "nonfinite_obstacle_dimensions",
                      "All obstacle dimensions, including inactive fields, must be finite.", o.id);
            return false;
        }
        for (std::size_t j = 0; j < i; ++j) if (snapshot.obstacles[j].id == o.id) {
            result.status = ValidationStatus::InvalidInput;
            add_issue(result.issues, "duplicate_obstacle_id", "Obstacle IDs must be unique.", o.id);
            return false;
        }
        if (o.kind == ObstacleKind::Sphere) {
            if (!finite(o.sphere_radius) || o.sphere_radius <= 0.0) {
                result.status = ValidationStatus::InvalidInput;
                add_issue(result.issues, "invalid_sphere", "Sphere radius must be finite and positive.", o.id);
                return false;
            }
        } else if (o.kind == ObstacleKind::Box) {
            if (!finite(o.box_half_extents) || o.box_half_extents.x <= 0.0 ||
                o.box_half_extents.y <= 0.0 || o.box_half_extents.z <= 0.0) {
                result.status = ValidationStatus::InvalidInput;
                add_issue(result.issues, "invalid_box", "Box half extents must be finite and positive.", o.id);
                return false;
            }
        } else {
            result.status = ValidationStatus::Unsupported;
            add_issue(result.issues, "unsupported_obstacle", "Only sphere and rigid oriented-box obstacles are supported.", o.id);
            return false;
        }
    }
    return true;
}

struct SourceAdmission {
    std::vector<std::size_t> binding_spans;
};

bool validate_guides_and_source(const PreparedRibbon& source, const RestGuide& rest,
                                const GuidePose& pose, const SolveOptions& options,
                                SourceAdmission& admitted, ValidationResult& result) {
    const Limits& limits = options.limits;
    const Tolerances& tol = options.tolerances;
    if (rest.guide_id == 0 || rest.source_revision == 0 || source.source_id == 0 || source.source_revision == 0 || pose.guide_id == 0) {
        result.status = ValidationStatus::InvalidInput;
        add_issue(result.issues, "invalid_identity", "Source/guide identities and revisions must be nonzero.");
        return false;
    }
    if (source.source_revision != rest.source_revision) {
        result.status = ValidationStatus::InvalidInput;
        add_issue(result.issues, "source_revision_mismatch", "PreparedRibbon and RestGuide source revisions differ.", source.source_id);
        return false;
    }
    if (pose.guide_id != rest.guide_id) {
        result.status = ValidationStatus::InvalidInput;
        add_issue(result.issues, "guide_identity_mismatch", "GuidePose does not identify RestGuide.", pose.guide_id);
        return false;
    }
    const std::size_t n = rest.nodes.size();
    if (n < 2 || n > limits.max_nodes) {
        result.status = n > limits.max_nodes ? ValidationStatus::ResourceLimit : ValidationStatus::InvalidInput;
        add_issue(result.issues, n > limits.max_nodes ? "node_limit" : "guide_node_count", "Guide node count is outside the admitted profile.", rest.guide_id);
        return false;
    }
    if (rest.node_ids.size() != n || rest.material_frames.size() != n || rest.span_ids.size()+1 != n ||
        rest.span_radius_m.size()+1 != n || rest.max_bound_offset_m.size()+1 != n ||
        pose.nodes.size() != n || pose.material_frames.size() != n) {
        result.status = ValidationStatus::InvalidInput;
        add_issue(result.issues, "guide_array_mismatch", "Rest/Pose arrays do not preserve N / N-1 semantic order.", rest.guide_id);
        return false;
    }
    if (!unique_nonzero(rest.node_ids) || !unique_nonzero(rest.span_ids)) {
        result.status = ValidationStatus::InvalidInput;
        add_issue(result.issues, "duplicate_or_zero_guide_ids", "Node and span IDs must be unique and nonzero.", rest.guide_id);
        return false;
    }
    for (Vec3 p : rest.nodes) if (!finite(p)) {
        result.status = ValidationStatus::InvalidInput; add_issue(result.issues, "nonfinite_rest_node", "Rest guide contains a non-finite node.", rest.guide_id); return false;
    }
    for (Vec3 p : pose.nodes) if (!finite(p)) {
        result.status = ValidationStatus::InvalidInput; add_issue(result.issues, "nonfinite_pose_node", "Pose contains a non-finite node.", pose.guide_id); return false;
    }
    for (std::size_t i = 0; i < rest.span_ids.size(); ++i) {
        if (!finite(rest.span_radius_m[i]) || !finite(rest.max_bound_offset_m[i]) || rest.span_radius_m[i] <= 0.0 || rest.max_bound_offset_m[i] < 0.0) {
            result.status = ValidationStatus::InvalidInput;
            add_issue(result.issues, "invalid_span_envelope", "Span envelope values are invalid.", rest.guide_id, rest.span_ids[i]);
            return false;
        }
        if (rest.span_radius_m[i] + tol.rest_reconstruction_m < rest.max_bound_offset_m[i]) {
            result.status = ValidationStatus::InvalidInput;
            add_issue(result.issues, "radius_below_declared_bound", "span_radius_m is smaller than max_bound_offset_m.", rest.guide_id, rest.span_ids[i]);
            return false;
        }
    }
    std::size_t frame_scratch_bytes = 0;
    if (!checked_mul(n - 1, sizeof(Vec3), frame_scratch_bytes) ||
        frame_scratch_bytes > limits.max_owned_and_scratch_bytes) {
        result.status = ValidationStatus::ResourceLimit;
        add_issue(result.issues, "frame_scratch_budget",
                  "Frame-validation tangent payload exceeds max_owned_and_scratch_bytes.", rest.guide_id);
        return false;
    }
    const FrameCheck rest_check = check_frames(rest.nodes, rest.material_frames, rest.span_ids, tol.frame_radians, rest.requires_full_turn_twist);
    if (rest_check.state != FrameCheck::State::Ok) {
        result.status = rest_check.state == FrameCheck::State::Unsupported ? ValidationStatus::Unsupported :
                        rest_check.state == FrameCheck::State::Ambiguous ? ValidationStatus::Ambiguous : ValidationStatus::InvalidInput;
        add_issue(result.issues, rest_check.code, rest_check.message, rest.guide_id, rest_check.span_id);
        return false;
    }
    const FrameCheck pose_check = check_frames(pose.nodes, pose.material_frames, rest.span_ids, tol.frame_radians, false);
    if (pose_check.state == FrameCheck::State::Ambiguous) {
        result.status = ValidationStatus::Ambiguous;
        add_issue(result.issues, "pose_" + pose_check.code, pose_check.message, pose.guide_id, pose_check.span_id);
        return false;
    }
    if (pose_check.state != FrameCheck::State::Ok) {
        result.status = ValidationStatus::Fail;
        add_issue(result.issues, "pose_" + pose_check.code, pose_check.message, pose.guide_id, pose_check.span_id);
        return false;
    }

    const std::size_t vertices = source.rest_positions.size();
    const std::size_t triangles = source.triangles.size();
    if (vertices == 0 || source.bindings.size() != vertices || triangles == 0 || source.face_material_ids.size() != triangles) {
        result.status = ValidationStatus::InvalidInput;
        add_issue(result.issues, "source_array_mismatch", "PreparedRibbon counts do not satisfy the frozen contract.", source.source_id);
        return false;
    }
    if (vertices > limits.max_render_vertices || triangles > limits.max_render_triangles) {
        result.status = ValidationStatus::ResourceLimit;
        add_issue(result.issues, "render_geometry_limit", "PreparedRibbon exceeds render geometry limits.", source.source_id);
        return false;
    }
    if (!unique_nonzero_render_ids(source.bindings)) {
        result.status = ValidationStatus::InvalidInput;
        add_issue(result.issues, "invalid_render_vertex_ids", "Render IDs must be unique/nonzero; logical seam IDs may repeat but cannot be zero.", source.source_id);
        return false;
    }

    std::size_t scratch = 0;
    if (!add_bytes(vertices, sizeof(Vec3), scratch) || !add_bytes(vertices, sizeof(Vec3), scratch) ||
        !add_bytes(vertices, sizeof(std::size_t), scratch) || !add_bytes(rest.span_ids.size(), sizeof(double), scratch)) {
        result.status = ValidationStatus::ResourceLimit;
        add_issue(result.issues, "memory_size_overflow", "Validation scratch size overflowed size_t.", source.source_id);
        return false;
    }
    if (scratch > limits.max_owned_and_scratch_bytes) {
        result.status = ValidationStatus::ResourceLimit;
        add_issue(result.issues, "memory_budget", "Conservative validation scratch estimate exceeds max_owned_and_scratch_bytes.", source.source_id);
        return false;
    }

    admitted.binding_spans.clear();
    admitted.binding_spans.reserve(vertices);
    std::vector<double> actual_max(rest.span_ids.size(), 0.0);
    for (std::size_t i = 0; i < vertices; ++i) {
        const BoundVertex& b = source.bindings[i];
        if (!finite(source.rest_positions[i]) || !finite(b.material_u) || b.material_u < 0.0 || b.material_u > 1.0 ||
            !finite(b.rest_local_offset) || !finite(b.uv)) {
            result.status = ValidationStatus::InvalidInput;
            add_issue(result.issues, "invalid_binding", "Rest position, binding u/full offset and UV must be finite and admitted.", b.render_vertex_id, b.span_id);
            return false;
        }
        const auto idx = span_index(rest, b.span_id);
        if (!idx) {
            result.status = ValidationStatus::InvalidInput;
            add_issue(result.issues, "unknown_binding_span", "Binding references an unknown semantic span.", b.render_vertex_id, b.span_id);
            return false;
        }
        admitted.binding_spans.push_back(*idx);
        actual_max[*idx] = std::max(actual_max[*idx], length(b.rest_local_offset));
    }
    for (std::size_t i = 0; i < actual_max.size(); ++i) {
        if (actual_max[i] > rest.max_bound_offset_m[i] + tol.rest_reconstruction_m ||
            actual_max[i] > rest.span_radius_m[i] + tol.rest_reconstruction_m) {
            result.status = ValidationStatus::InvalidInput;
            add_issue(result.issues, "insufficient_prepared_envelope", "Declared span radius/bound offset is smaller than an actual full xyz binding offset.", rest.guide_id, rest.span_ids[i]);
            return false;
        }
    }
    for (const auto tri : source.triangles) {
        if (tri[0] >= vertices || tri[1] >= vertices || tri[2] >= vertices || tri[0] == tri[1] || tri[0] == tri[2] || tri[1] == tri[2]) {
            result.status = ValidationStatus::InvalidInput;
            add_issue(result.issues, "invalid_source_triangle", "Source triangle indices are invalid.", source.source_id);
            return false;
        }
        const Vec3 cr = triangle_cross(source.rest_positions[tri[0]], source.rest_positions[tri[1]], source.rest_positions[tri[2]]);
        if (!finite(cr) || length_sq(cr) <= kAxisTiny) {
            result.status = ValidationStatus::InvalidInput;
            add_issue(result.issues, "degenerate_source_triangle", "Zero-area source triangles are not silently removed.", source.source_id);
            return false;
        }
    }
    return true;
}

bool independently_reconstruct(const PreparedRibbon& source, const RestGuide& rest,
                               const GuidePose& pose, const SourceAdmission& admitted,
                               const SolveOptions& options, std::vector<Vec3>& expected,
                               ValidationResult& result, Cancellation cancel) {
    expected.clear();
    expected.reserve(source.bindings.size());
    double max_rest_error = 0.0;
    for (std::size_t i = 0; i < source.bindings.size(); ++i) {
        if ((i & 63U) == 0U && cancelled(cancel)) {
            result.status = ValidationStatus::Cancelled;
            add_issue(result.issues, "cancelled", "Cancellation was requested during independent pose reconstruction.", source.source_id);
            return false;
        }
        const BoundVertex& b = source.bindings[i];
        const std::size_t span = admitted.binding_spans[i];
        const auto rp = reference_sample(rest.nodes, rest.material_frames, span, b.material_u, b.rest_local_offset);
        const auto ep = reference_sample(pose.nodes, pose.material_frames, span, b.material_u, b.rest_local_offset);
        if (!rp || !ep) {
            result.status = ValidationStatus::Ambiguous;
            add_issue(result.issues, "independent_sampler_failure", "Independent normalized shortest-path sampler failed.", b.render_vertex_id, b.span_id);
            return false;
        }
        const double err = distance(*rp, source.rest_positions[i]);
        max_rest_error = std::max(max_rest_error, err);
        expected.push_back(*ep);
    }
    result.rest_reconstruction_error_m = max_rest_error;
    if (!finite(max_rest_error) || max_rest_error > options.tolerances.rest_reconstruction_m) {
        result.status = ValidationStatus::InvalidInput;
        add_issue(result.issues, "rest_reconstruction_error", "Independent sampler cannot reconstruct the supplied rest positions.", source.source_id);
        return false;
    }
    return true;
}

bool independently_compute_normals(const std::vector<Vec3>& positions,
                                   const std::vector<std::array<std::uint32_t, 3>>& triangles,
                                   std::vector<Vec3>& normals) {
    normals.assign(positions.size(), Vec3{});
    for (const auto tri : triangles) {
        const Vec3 cr = triangle_cross(positions[tri[0]], positions[tri[1]], positions[tri[2]]);
        if (!finite(cr) || length_sq(cr) <= kAxisTiny) return false;
        normals[tri[0]] = add(normals[tri[0]], cr);
        normals[tri[1]] = add(normals[tri[1]], cr);
        normals[tri[2]] = add(normals[tri[2]], cr);
    }
    for (Vec3& n : normals) {
        const auto nn = normalized(n);
        if (!nn) return false;
        n = *nn;
    }
    return true;
}

void validate_root_lengths_and_policy(const RestGuide& rest, const GuidePose& pose,
                                      const SolveOptions& options, ValidationWork& work) {
    const double root_error = distance(rest.nodes.front(), pose.nodes.front());
    work.result.max_root_error_m = root_error;
    if (!finite(root_error) || root_error > options.tolerances.root_m)
        fail_candidate(work, "root_position_violation", "Candidate moved the planted root beyond root_m.", rest.guide_id);

    double max_relative = 0.0;
    for (std::size_t i = 0; i + 1 < rest.nodes.size(); ++i) {
        const double lr = distance(rest.nodes[i], rest.nodes[i+1]);
        const double lp = distance(pose.nodes[i], pose.nodes[i+1]);
        if (!finite(lr) || !finite(lp) || lr <= kTiny) {
            fail_candidate(work, "invalid_span_length", "Span length is non-finite or zero.", rest.guide_id, rest.span_ids[i]);
            continue;
        }
        const double relative = std::abs(lp - lr) / lr;
        max_relative = std::max(max_relative, relative);
        if (relative > options.tolerances.relative_length)
            fail_candidate(work, "span_length_violation", "Candidate span length exceeds relative_length tolerance.", rest.guide_id, rest.span_ids[i]);
    }
    work.result.max_relative_length_error = max_relative;

    if (options.root_mode == RootMode::ClampFrame) {
        const double frame_angle = quaternion_geodesic_angle(rest.material_frames.front(), pose.material_frames.front());
        const double tangent_angle = vector_angle(sub(rest.nodes[1], rest.nodes[0]), sub(pose.nodes[1], pose.nodes[0]));
        if (!finite(frame_angle) || frame_angle > options.tolerances.frame_radians)
            fail_candidate(work, "clamp_root_frame_violation", "ClampFrame root material frame changed beyond tolerance.", rest.guide_id, rest.span_ids.front());
        if (!finite(tangent_angle) || tangent_angle > options.tolerances.frame_radians)
            fail_candidate(work, "clamp_initial_span_violation", "ClampFrame initial outgoing span direction changed beyond tolerance.", rest.guide_id, rest.span_ids.front());
    } else if (options.root_mode == RootMode::SoftFrame) {
        const double frame_angle = quaternion_geodesic_angle(rest.material_frames.front(), pose.material_frames.front());
        std::ostringstream message;
        message << "SoftFrame root angle is diagnostic/weighted, not a hard pass threshold; measured radians=" << frame_angle;
        add_issue(work.result.issues, "soft_frame_angle_diagnostic", message.str(), rest.guide_id, rest.span_ids.front());
    }
}

void validate_mesh_correspondence(const PreparedRibbon& source, const EvaluatedMesh& mesh,
                                  const std::vector<Vec3>& expected,
                                  const SolveOptions& options, ValidationWork& work,
                                  Cancellation cancel) {
    if (mesh.source_id != source.source_id || mesh.source_revision != source.source_revision)
        fail_candidate(work, "mesh_source_identity_mismatch", "EvaluatedMesh does not echo source identity/revision.", mesh.source_id);
    if (mesh.positions.size() != source.rest_positions.size() || mesh.normals.size() != mesh.positions.size() || mesh.uvs.size() != mesh.positions.size()) {
        fail_candidate(work, "mesh_vertex_array_mismatch", "Mesh positions/normals/UV counts do not preserve binding order.", mesh.source_id);
        return;
    }
    if (mesh.triangles != source.triangles)
        fail_candidate(work, "mesh_topology_mismatch", "Mesh triangle indices differ from PreparedRibbon.", mesh.source_id);
    if (mesh.face_material_ids != source.face_material_ids)
        fail_candidate(work, "mesh_material_mismatch", "Mesh face material assignments differ from PreparedRibbon.", mesh.source_id);
    if (mesh.triangles.size() != mesh.face_material_ids.size()) {
        fail_candidate(work, "mesh_face_material_count", "Mesh face material count differs from triangle count.", mesh.source_id);
        return;
    }

    const std::size_t n = std::min(mesh.positions.size(), expected.size());
    for (std::size_t i = 0; i < n; ++i) {
        if ((i & 63U) == 0U && cancelled(cancel)) return;
        if (!finite(mesh.positions[i]) || !finite(mesh.normals[i]) || !finite(mesh.uvs[i])) {
            fail_candidate(work, "nonfinite_mesh_geometry", "Mesh contains non-finite position/normal/UV data.", source.bindings[i].render_vertex_id, source.bindings[i].span_id);
            continue;
        }
        if (distance(mesh.positions[i], expected[i]) > options.tolerances.rest_reconstruction_m)
            fail_candidate(work, "mesh_pose_correspondence", "Supplied mesh position does not match independent pose re-evaluation.", source.bindings[i].render_vertex_id, source.bindings[i].span_id);
        if (!same_uv_exact(mesh.uvs[i], source.bindings[i].uv))
            fail_candidate(work, "mesh_uv_mismatch", "Mesh UV changed or seam order was not preserved.", source.bindings[i].render_vertex_id, source.bindings[i].span_id);
    }

    if (!mesh.positions.empty()) {
        const Vec3 exact_min = bounds_min_of(mesh.positions);
        const Vec3 exact_max = bounds_max_of(mesh.positions);
        if (!same_vec_exact(mesh.bounds_min, exact_min) || !same_vec_exact(mesh.bounds_max, exact_max))
            fail_candidate(work, "mesh_bounds_mismatch", "Mesh bounds are not the exact componentwise bounds of supplied positions.", mesh.source_id);
    }

    if (mesh.triangles == source.triangles && mesh.positions.size() == source.rest_positions.size()) {
        std::vector<Vec3> expected_normals;
        if (!independently_compute_normals(mesh.positions, mesh.triangles, expected_normals)) {
            fail_candidate(work, "undefined_mesh_normals", "Candidate topology produces degenerate triangles or undefined geometric normals.", mesh.source_id);
            return;
        }
        for (std::size_t i = 0; i < expected_normals.size(); ++i) {
            const double len = length(mesh.normals[i]);
            if (!finite(len) || std::abs(len - 1.0) > kUnitNormalTolerance) {
                fail_candidate(work, "nonunit_mesh_normal", "Mesh geometric normal is not finite unit length.", source.bindings[i].render_vertex_id);
                continue;
            }
            const double angle = vector_angle(mesh.normals[i], expected_normals[i]);
            if (!finite(angle) || angle > options.tolerances.frame_radians)
                fail_candidate(work, "mesh_normal_mismatch", "Mesh normal does not match independently recomputed area-weighted geometric normal.", source.bindings[i].render_vertex_id);
        }
    }
}

bool root_envelope_conflicts(const Obstacle& obstacle, Vec3 root, double envelope,
                             double& exact_depth, bool& box_proxy) {
    exact_depth = 0.0;
    box_proxy = false;
    if (obstacle.kind == ObstacleKind::Sphere) {
        const double depth = obstacle.sphere_radius + envelope - distance(root, obstacle.center);
        exact_depth = std::max(0.0, depth);
        return depth > 0.0;
    }
    const Quat q = reference_normalize(obstacle.orientation);
    const Vec3 local = reference_inverse_rotate(q, sub(root, obstacle.center));
    const Vec3 e{obstacle.box_half_extents.x + envelope,
                 obstacle.box_half_extents.y + envelope,
                 obstacle.box_half_extents.z + envelope};
    const Vec3 a = abs_vec(local);
    const bool inside = a.x < e.x && a.y < e.y && a.z < e.z;
    if (inside) {
        box_proxy = true;
        exact_depth = std::min({e.x-a.x, e.y-a.y, e.z-a.z});
    }
    return inside;
}

void validate_root_obstacles(const SceneSnapshot& snapshot, const RestGuide& rest,
                             const GuidePose& pose, const SolveOptions& options,
                             ValidationWork& work) {
    const double envelope = rest.span_radius_m.front() + options.clearance_m;
    for (const Obstacle& obstacle : snapshot.obstacles) {
        double depth = 0.0;
        bool box_proxy = false;
        if (root_envelope_conflicts(obstacle, pose.nodes.front(), envelope, depth, box_proxy)) {
            work.result.max_visible_penetration_m = std::max(work.result.max_visible_penetration_m, depth);
            fail_candidate(work, "root_envelope_conflict", box_proxy ?
                "Root envelope lies inside the conservative axis-expanded OBB; reported value is an L-infinity proxy, not exact physical penetration." :
                "Root envelope lies inside the sphere exclusion envelope.", obstacle.id, rest.span_ids.front());
        }
    }
}

void validate_visible_clearance(const SceneSnapshot& snapshot, const EvaluatedMesh& mesh,
                                const SolveOptions& options, ValidationWork& work,
                                Cancellation cancel) {
    std::size_t pair_count = 0;
    if (!checked_mul(snapshot.obstacles.size(), mesh.triangles.size(), pair_count) || pair_count > options.limits.max_query_calls) {
        work.result.status = ValidationStatus::ResourceLimit;
        add_issue(work.result.issues, "visible_pair_budget", "Obstacle/triangle clearance checks exceed max_query_calls.", mesh.source_id);
        return;
    }

    bool box_proxy_reported = false;
    for (std::size_t oi = 0; oi < snapshot.obstacles.size(); ++oi) {
        const Obstacle& obstacle = snapshot.obstacles[oi];
        for (std::size_t ti = 0; ti < mesh.triangles.size(); ++ti) {
            if (((oi * mesh.triangles.size() + ti) & 63U) == 0U && cancelled(cancel)) {
                work.result.status = ValidationStatus::Cancelled;
                add_issue(work.result.issues, "cancelled", "Cancellation was requested during visible triangle validation.", obstacle.id);
                return;
            }
            const auto tri_i = mesh.triangles[ti];
            const std::array<Vec3, 3> tri{mesh.positions[tri_i[0]], mesh.positions[tri_i[1]], mesh.positions[tri_i[2]]};
            if (obstacle.kind == ObstacleKind::Sphere) {
                const double d2 = point_triangle_distance_sq(obstacle.center, tri[0], tri[1], tri[2]);
                if (!finite(d2) || d2 < 0.0) {
                    work.result.status = ValidationStatus::Ambiguous;
                    add_issue(work.result.issues, "sphere_triangle_distance_failure", "Independent triangle/sphere distance was non-finite.", obstacle.id);
                    return;
                }
                const double distance_to_surface = std::sqrt(std::max(0.0, d2));
                const double depth = obstacle.sphere_radius + options.clearance_m - distance_to_surface;
                work.result.max_visible_penetration_m = std::max(work.result.max_visible_penetration_m, std::max(0.0, depth));
                if (depth > options.tolerances.penetration_m)
                    fail_candidate(work, "visible_sphere_penetration", "Whole visible triangle surface penetrates the sphere exclusion envelope; metric is exact triangle minimum-distance deficit.", obstacle.id);
            } else {
                const Quat q = reference_normalize(obstacle.orientation);
                std::array<Vec3, 3> local{
                    reference_inverse_rotate(q, sub(tri[0], obstacle.center)),
                    reference_inverse_rotate(q, sub(tri[1], obstacle.center)),
                    reference_inverse_rotate(q, sub(tri[2], obstacle.center))
                };
                const Vec3 full_extents{obstacle.box_half_extents.x + options.clearance_m,
                                        obstacle.box_half_extents.y + options.clearance_m,
                                        obstacle.box_half_extents.z + options.clearance_m};
                const double accepted_expansion = std::max(0.0, options.clearance_m - options.tolerances.penetration_m);
                const Vec3 accepted_extents{obstacle.box_half_extents.x + accepted_expansion,
                                            obstacle.box_half_extents.y + accepted_expansion,
                                            obstacle.box_half_extents.z + accepted_expansion};
                const TriBoxResult full = triangle_aabb_sat(local, full_extents);
                const TriBoxResult accepted = triangle_aabb_sat(local, accepted_extents);
                if (full.overlaps) {
                    work.result.max_visible_penetration_m = std::max(work.result.max_visible_penetration_m, full.minimum_axis_overlap);
                    if (!box_proxy_reported) {
                        add_issue(work.result.issues, "box_overlap_metric_conservative",
                                  "Box metric is the minimum normalized SAT-axis overlap against an axis-expanded OBB; it is a conservative proxy, not exact Euclidean physical penetration.", obstacle.id);
                        box_proxy_reported = true;
                    }
                }
                if (accepted.overlaps)
                    fail_candidate(work, "visible_box_overlap", "Whole visible triangle intersects the conservative axis-expanded OBB clearance certificate.", obstacle.id);
            }
        }
    }
}

ValidationResult validate_impl(const SceneSnapshot& snapshot, const PreparedRibbon& source,
                               const RestGuide& rest, const GuidePose& pose,
                               const EvaluatedMesh& mesh, const SolveOptions& options,
                               Cancellation cancel) {
    ValidationWork work;
    work.result.generation = snapshot.generation;
    if (cancelled(cancel)) return terminal(ValidationStatus::Cancelled, snapshot.generation, "cancelled", "Cancellation was requested before validation.");
    if (!valid_options(options, work.result)) return work.result;
    if (!validate_snapshot(snapshot, options, work.result)) return work.result;
    if (cancelled(cancel)) return terminal(ValidationStatus::Cancelled, snapshot.generation, "cancelled", "Cancellation was requested during admission.");

    SourceAdmission admitted;
    if (!validate_guides_and_source(source, rest, pose, options, admitted, work.result)) return work.result;

    std::vector<Vec3> expected;
    if (!independently_reconstruct(source, rest, pose, admitted, options, expected, work.result, cancel)) return work.result;

    validate_root_lengths_and_policy(rest, pose, options, work);
    validate_mesh_correspondence(source, mesh, expected, options, work, cancel);
    if (cancelled(cancel)) return terminal(ValidationStatus::Cancelled, snapshot.generation, "cancelled", "Cancellation was requested after mesh correspondence checks.");
    if (work.result.status == ValidationStatus::ResourceLimit || work.result.status == ValidationStatus::Ambiguous) return work.result;

    if (mesh.positions.size() == source.rest_positions.size() && mesh.triangles == source.triangles) {
        validate_root_obstacles(snapshot, rest, pose, options, work);
        validate_visible_clearance(snapshot, mesh, options, work, cancel);
    }
    if (work.result.status == ValidationStatus::Cancelled || work.result.status == ValidationStatus::ResourceLimit || work.result.status == ValidationStatus::Ambiguous)
        return work.result;

    work.result.status = work.failed ? ValidationStatus::Fail : ValidationStatus::Pass;
    if (!work.failed)
        add_issue(work.result.issues, "independent_validation_pass", "Independent source, pose, mesh and whole-triangle primitive checks passed for the narrow v1 profile.", source.source_id);
    return work.result;
}

} // namespace

ValidationResult validate_candidate(const SceneSnapshot& snapshot, const PreparedRibbon& source,
                                    const RestGuide& rest, const GuidePose& pose,
                                    const EvaluatedMesh& mesh, const SolveOptions& options,
                                    Cancellation cancel) {
    try {
        return validate_impl(snapshot, source, rest, pose, mesh, options, cancel);
    } catch (const std::bad_alloc&) {
        ValidationResult out;
        out.status = ValidationStatus::AllocationFailure;
        out.generation = snapshot.generation;
        try { add_issue(out.issues, "allocation_failure", "Allocation failed; no candidate was accepted.", source.source_id); } catch (...) { }
        return out;
    } catch (const std::exception& e) {
        ValidationResult out;
        out.status = ValidationStatus::InternalError;
        out.generation = snapshot.generation;
        try { add_issue(out.issues, "internal_exception", e.what(), source.source_id); } catch (...) { }
        return out;
    } catch (...) {
        ValidationResult out;
        out.status = ValidationStatus::InternalError;
        out.generation = snapshot.generation;
        try { add_issue(out.issues, "internal_exception", "Unknown exception; no candidate was accepted.", source.source_id); } catch (...) { }
        return out;
    }
}

} // namespace cyrus::vegetation::prototype_v1
