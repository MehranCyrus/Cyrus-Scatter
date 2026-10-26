#include <cyrus_vegetation/prototype_v1.hpp>

#include "geometry.hpp"

#include <algorithm>
#include <cstddef>
#include <limits>
#include <new>
#include <optional>
#include <string>
#include <utility>
#include <vector>

namespace cyrus::vegetation::prototype_v1 {
namespace {
using namespace delivery_detail;

enum class AdmissionState { Ok, Invalid, Unsupported, Ambiguous, Resource, Cancelled };

struct Admission {
    AdmissionState state = AdmissionState::Ok;
    std::vector<std::size_t> binding_spans;
    std::vector<Issue> issues;
    std::size_t estimated_bytes = 0;
};

Outcome outcome_for(AdmissionState state) noexcept {
    switch (state) {
    case AdmissionState::Ok: return Outcome::Ok;
    case AdmissionState::Invalid: return Outcome::InvalidInput;
    case AdmissionState::Unsupported: return Outcome::Unsupported;
    case AdmissionState::Ambiguous: return Outcome::Ambiguous;
    case AdmissionState::Resource: return Outcome::ResourceLimit;
    case AdmissionState::Cancelled: return Outcome::Cancelled;
    }
    return Outcome::InternalError;
}

Admission fail(AdmissionState state, std::string code, std::string message,
               Id object_id = 0, Id span_id = 0) {
    Admission out;
    out.state = state;
    add_issue(out.issues, std::move(code), std::move(message), object_id, span_id);
    return out;
}

bool valid_limits_and_tolerances(const Limits& limits, const Tolerances& tolerances,
                                 Admission& out) {
    if (!all_limits_positive(limits)) {
        out = fail(AdmissionState::Invalid, "invalid_limits", "Every Limits field must be nonzero.");
        return false;
    }
    if (!all_tolerances_positive(tolerances)) {
        out = fail(AdmissionState::Invalid, "invalid_tolerances", "Every tolerance must be finite and positive.");
        return false;
    }
    if (tolerances.frame_radians >= kPi) {
        out = fail(AdmissionState::Invalid, "frame_tolerance_range", "Frame tolerance must be smaller than pi radians.");
        return false;
    }
    return true;
}

bool validate_rest_and_pose(const RestGuide& rest, const GuidePose& pose,
                            const Limits& limits, const Tolerances& tolerances,
                            Admission& out) {
    if (rest.guide_id == 0 || rest.source_revision == 0 || pose.guide_id == 0) {
        out = fail(AdmissionState::Invalid, "invalid_guide_identity", "Guide and source revision identities must be nonzero.", rest.guide_id);
        return false;
    }
    if (pose.guide_id != rest.guide_id) {
        out = fail(AdmissionState::Invalid, "guide_identity_mismatch", "GuidePose does not identify the RestGuide.", pose.guide_id);
        return false;
    }
    const std::size_t n = rest.nodes.size();
    if (n < 2 || n > limits.max_nodes) {
        out = fail(n > limits.max_nodes ? AdmissionState::Resource : AdmissionState::Invalid,
                   n > limits.max_nodes ? "node_limit" : "guide_node_count",
                   n > limits.max_nodes ? "Guide exceeds max_nodes." : "RestGuide needs at least two nodes.", rest.guide_id);
        return false;
    }
    if (rest.node_ids.size() != n || rest.material_frames.size() != n ||
        rest.span_ids.size() + 1 != n || rest.span_radius_m.size() + 1 != n ||
        rest.max_bound_offset_m.size() + 1 != n) {
        out = fail(AdmissionState::Invalid, "rest_array_mismatch", "RestGuide arrays do not follow the N / N-1 contract.", rest.guide_id);
        return false;
    }
    if (pose.nodes.size() != n || pose.material_frames.size() != n) {
        out = fail(AdmissionState::Invalid, "pose_array_mismatch", "GuidePose counts do not match RestGuide semantic order.", pose.guide_id);
        return false;
    }
    if (!unique_nonzero(rest.node_ids) || !unique_nonzero(rest.span_ids)) {
        out = fail(AdmissionState::Invalid, "duplicate_or_zero_guide_ids", "Node and span IDs must be unique and nonzero.", rest.guide_id);
        return false;
    }
    for (Vec3 p : rest.nodes) if (!finite(p)) {
        out = fail(AdmissionState::Invalid, "nonfinite_rest_node", "RestGuide contains a non-finite node.", rest.guide_id);
        return false;
    }
    for (Vec3 p : pose.nodes) if (!finite(p)) {
        out = fail(AdmissionState::Invalid, "nonfinite_pose_node", "GuidePose contains a non-finite node.", pose.guide_id);
        return false;
    }
    for (std::size_t i = 0; i < rest.span_ids.size(); ++i) {
        if (!finite(rest.span_radius_m[i]) || !finite(rest.max_bound_offset_m[i]) ||
            rest.span_radius_m[i] <= 0.0 || rest.max_bound_offset_m[i] < 0.0) {
            out = fail(AdmissionState::Invalid, "invalid_span_envelope", "Span radii must be positive and bound offsets nonnegative.", rest.guide_id, rest.span_ids[i]);
            return false;
        }
        if (rest.span_radius_m[i] + tolerances.rest_reconstruction_m < rest.max_bound_offset_m[i]) {
            out = fail(AdmissionState::Invalid, "radius_below_declared_bound", "span_radius_m is smaller than max_bound_offset_m.", rest.guide_id, rest.span_ids[i]);
            return false;
        }
    }
    // Frame validation owns a directed-tangent vector independently of the
    // later render-vertex payload. Admit this stage before its reserve().
    std::size_t frame_scratch_bytes = 0;
    if (!checked_mul(n - 1, sizeof(Vec3), frame_scratch_bytes) ||
        frame_scratch_bytes > limits.max_owned_and_scratch_bytes) {
        out = fail(AdmissionState::Resource, "frame_scratch_budget",
                   "Frame-validation tangent payload exceeds max_owned_and_scratch_bytes.", rest.guide_id);
        return false;
    }
    const FrameCheck rest_frames = check_frames(rest.nodes, rest.material_frames, rest.span_ids,
                                                tolerances.frame_radians, rest.requires_full_turn_twist);
    if (rest_frames.state != FrameCheck::State::Ok) {
        const AdmissionState state = rest_frames.state == FrameCheck::State::Unsupported ? AdmissionState::Unsupported :
                                     rest_frames.state == FrameCheck::State::Ambiguous ? AdmissionState::Ambiguous : AdmissionState::Invalid;
        out = fail(state, rest_frames.code, rest_frames.message, rest.guide_id, rest_frames.span_id);
        return false;
    }
    const FrameCheck pose_frames = check_frames(pose.nodes, pose.material_frames, rest.span_ids,
                                                tolerances.frame_radians, false);
    if (pose_frames.state != FrameCheck::State::Ok) {
        const AdmissionState state = pose_frames.state == FrameCheck::State::Ambiguous ? AdmissionState::Ambiguous : AdmissionState::Invalid;
        out = fail(state, "pose_" + pose_frames.code, pose_frames.message, pose.guide_id, pose_frames.span_id);
        return false;
    }
    return true;
}

bool validate_source(const PreparedRibbon& source, const RestGuide& rest,
                     const Limits& limits, const Tolerances& tolerances,
                     Admission& out) {
    if (source.source_id == 0 || source.source_revision == 0) {
        out = fail(AdmissionState::Invalid, "invalid_source_identity", "Source identity and revision must be nonzero.", source.source_id);
        return false;
    }
    if (source.source_revision != rest.source_revision) {
        out = fail(AdmissionState::Invalid, "source_revision_mismatch", "PreparedRibbon and RestGuide source revisions differ.", source.source_id);
        return false;
    }
    const std::size_t vertex_count = source.rest_positions.size();
    const std::size_t triangle_count = source.triangles.size();
    if (vertex_count == 0 || source.bindings.size() != vertex_count) {
        out = fail(AdmissionState::Invalid, "binding_count_mismatch", "PreparedRibbon needs one binding for every rest/render vertex.", source.source_id);
        return false;
    }
    if (vertex_count > limits.max_render_vertices || triangle_count > limits.max_render_triangles) {
        out = fail(AdmissionState::Resource,
                   vertex_count > limits.max_render_vertices ? "render_vertex_limit" : "render_triangle_limit",
                   "PreparedRibbon exceeds the declared render geometry limit.", source.source_id);
        return false;
    }
    if (triangle_count == 0 || source.face_material_ids.size() != triangle_count) {
        out = fail(AdmissionState::Invalid, "material_or_triangle_count", "PreparedRibbon needs triangles and one face material assignment per triangle.", source.source_id);
        return false;
    }
    if (!unique_nonzero_render_ids(source.bindings)) {
        out = fail(AdmissionState::Invalid, "invalid_render_vertex_ids", "Render IDs must be unique/nonzero; logical IDs must be nonzero. Logical seam IDs may repeat.", source.source_id);
        return false;
    }

    std::size_t bytes = 0;
    if (!add_bytes(vertex_count, sizeof(Vec3), bytes) ||
        !add_bytes(vertex_count, sizeof(Vec3), bytes) ||
        !add_bytes(vertex_count, sizeof(UV), bytes) ||
        !add_bytes(vertex_count, sizeof(std::size_t), bytes) ||
        !add_bytes(rest.span_ids.size(), sizeof(double), bytes) ||
        !add_bytes(triangle_count, sizeof(std::array<std::uint32_t, 3>), bytes) ||
        !add_bytes(triangle_count, sizeof(std::uint32_t), bytes)) {
        out = fail(AdmissionState::Resource, "memory_size_overflow", "Geometry payload size overflowed size_t.", source.source_id);
        return false;
    }
    out.estimated_bytes = bytes;
    if (bytes > limits.max_owned_and_scratch_bytes) {
        out = fail(AdmissionState::Resource, "memory_budget", "Conservative owned/scratch payload estimate exceeds max_owned_and_scratch_bytes.", source.source_id);
        return false;
    }

    out.binding_spans.clear();
    out.binding_spans.reserve(vertex_count);
    std::vector<double> actual_max(rest.span_ids.size(), 0.0);
    for (std::size_t i = 0; i < vertex_count; ++i) {
        if (!finite(source.rest_positions[i])) {
            out = fail(AdmissionState::Invalid, "nonfinite_rest_position", "PreparedRibbon contains a non-finite rest position.", source.source_id);
            return false;
        }
        const BoundVertex& b = source.bindings[i];
        if (!finite(b.material_u) || b.material_u < 0.0 || b.material_u > 1.0 ||
            !finite(b.rest_local_offset) || !finite(b.uv)) {
            out = fail(AdmissionState::Invalid, "invalid_binding", "Binding u, full xyz offset and UV must be finite; u must be in [0,1].", b.render_vertex_id, b.span_id);
            return false;
        }
        const auto s = span_index(rest, b.span_id);
        if (!s) {
            out = fail(AdmissionState::Invalid, "unknown_binding_span", "Binding references an unknown semantic span ID.", b.render_vertex_id, b.span_id);
            return false;
        }
        out.binding_spans.push_back(*s);
        actual_max[*s] = std::max(actual_max[*s], length(b.rest_local_offset));
    }
    for (std::size_t i = 0; i < actual_max.size(); ++i) {
        if (actual_max[i] > rest.max_bound_offset_m[i] + tolerances.rest_reconstruction_m) {
            out = fail(AdmissionState::Invalid, "declared_bound_too_small", "max_bound_offset_m does not contain every bound full xyz offset.", rest.guide_id, rest.span_ids[i]);
            return false;
        }
        if (actual_max[i] > rest.span_radius_m[i] + tolerances.rest_reconstruction_m) {
            out = fail(AdmissionState::Invalid, "span_radius_too_small", "span_radius_m does not contain every bound full xyz offset.", rest.guide_id, rest.span_ids[i]);
            return false;
        }
    }

    for (std::size_t i = 0; i < triangle_count; ++i) {
        const auto tri = source.triangles[i];
        if (tri[0] >= vertex_count || tri[1] >= vertex_count || tri[2] >= vertex_count ||
            tri[0] == tri[1] || tri[0] == tri[2] || tri[1] == tri[2]) {
            out = fail(AdmissionState::Invalid, "invalid_triangle_index", "Triangle indices must be distinct and in range.", source.source_id);
            return false;
        }
        const Vec3 cross_value = triangle_cross(source.rest_positions[tri[0]], source.rest_positions[tri[1]], source.rest_positions[tri[2]]);
        if (!finite(cross_value) || length_sq(cross_value) <= kAxisTiny) {
            out = fail(AdmissionState::Invalid, "degenerate_rest_triangle", "Zero-area or non-finite rest triangles are not silently erased.", source.source_id);
            return false;
        }
    }
    return true;
}

Admission admit(const PreparedRibbon& source, const RestGuide& rest, const GuidePose& pose,
                const Limits& limits, const Tolerances& tolerances, Cancellation cancel) {
    if (cancelled(cancel)) return fail(AdmissionState::Cancelled, "cancelled", "Cancellation was requested before evaluation.");
    Admission out;
    if (!valid_limits_and_tolerances(limits, tolerances, out)) return out;
    if (!validate_rest_and_pose(rest, pose, limits, tolerances, out)) return out;
    if (cancelled(cancel)) return fail(AdmissionState::Cancelled, "cancelled", "Cancellation was requested during admission.");
    if (!validate_source(source, rest, limits, tolerances, out)) return out;
    return out;
}

std::optional<Vec3> sample(const std::vector<Vec3>& nodes, const std::vector<Quat>& frames,
                           std::size_t span, double u, Vec3 offset) noexcept {
    if (span + 1 >= nodes.size() || frames.size() != nodes.size()) return std::nullopt;
    const Vec3 center = add(mul(nodes[span], 1.0 - u), mul(nodes[span + 1], u));
    const auto frame = shortest_slerp(frames[span], frames[span + 1], u);
    if (!frame) return std::nullopt;
    const Vec3 p = add(center, rotate(*frame, offset));
    if (!finite(p)) return std::nullopt;
    return p;
}

bool compute_geometric_normals(EvaluatedMesh& mesh, std::vector<Issue>& issues, Cancellation cancel) {
    mesh.normals.assign(mesh.positions.size(), Vec3{});
    for (std::size_t i = 0; i < mesh.triangles.size(); ++i) {
        if ((i & 63U) == 0U && cancelled(cancel)) {
            add_issue(issues, "cancelled", "Cancellation was requested while computing geometric normals.", mesh.source_id);
            return false;
        }
        const auto tri = mesh.triangles[i];
        const Vec3 cr = triangle_cross(mesh.positions[tri[0]], mesh.positions[tri[1]], mesh.positions[tri[2]]);
        if (!finite(cr) || length_sq(cr) <= kAxisTiny) {
            add_issue(issues, "degenerate_evaluated_triangle", "Evaluated geometry contains a zero-area or non-finite triangle.", mesh.source_id);
            return false;
        }
        mesh.normals[tri[0]] = add(mesh.normals[tri[0]], cr);
        mesh.normals[tri[1]] = add(mesh.normals[tri[1]], cr);
        mesh.normals[tri[2]] = add(mesh.normals[tri[2]], cr);
    }
    for (std::size_t i = 0; i < mesh.normals.size(); ++i) {
        const auto n = normalized(mesh.normals[i]);
        if (!n) {
            add_issue(issues, "undefined_geometric_normal", "A render vertex has no finite nonzero geometric normal; unreferenced or cancelling faces are unsupported.", mesh.source_id);
            return false;
        }
        mesh.normals[i] = *n;
    }
    return true;
}

EvaluationResult evaluate_impl(const PreparedRibbon& source, const RestGuide& rest,
                               const GuidePose& pose, const Limits& limits,
                               const Tolerances& tolerances, Cancellation cancel) {
    EvaluationResult result;
    Admission admission = admit(source, rest, pose, limits, tolerances, cancel);
    if (admission.state != AdmissionState::Ok) {
        result.outcome = outcome_for(admission.state);
        result.issues = std::move(admission.issues);
        return result;
    }

    EvaluatedMesh staged;
    staged.source_id = source.source_id;
    staged.source_revision = source.source_revision;
    staged.positions.reserve(source.rest_positions.size());
    staged.uvs.reserve(source.bindings.size());
    staged.triangles = source.triangles;
    staged.face_material_ids = source.face_material_ids;

    double max_reconstruction_error = 0.0;
    for (std::size_t i = 0; i < source.bindings.size(); ++i) {
        if ((i & 63U) == 0U && cancelled(cancel)) {
            result.outcome = Outcome::Cancelled;
            add_issue(result.issues, "cancelled", "Cancellation was requested during ribbon evaluation.", source.source_id);
            return result;
        }
        const BoundVertex& binding = source.bindings[i];
        const std::size_t span = admission.binding_spans[i];
        const auto reconstructed = sample(rest.nodes, rest.material_frames, span,
                                          binding.material_u, binding.rest_local_offset);
        if (!reconstructed) {
            result.outcome = Outcome::Ambiguous;
            add_issue(result.issues, "rest_sampler_failure", "Rest sampler could not produce a finite point.", binding.render_vertex_id, binding.span_id);
            return result;
        }
        const double error = distance(*reconstructed, source.rest_positions[i]);
        max_reconstruction_error = std::max(max_reconstruction_error, error);
        if (!finite(error) || error > tolerances.rest_reconstruction_m) {
            result.outcome = Outcome::InvalidInput;
            add_issue(result.issues, "rest_reconstruction_error", "Binding does not reconstruct the supplied rest position within tolerance.", binding.render_vertex_id, binding.span_id);
            return result;
        }
        const auto deformed = sample(pose.nodes, pose.material_frames, span,
                                    binding.material_u, binding.rest_local_offset);
        if (!deformed) {
            result.outcome = Outcome::Ambiguous;
            add_issue(result.issues, "pose_sampler_failure", "Deformed sampler could not produce a finite point.", binding.render_vertex_id, binding.span_id);
            return result;
        }
        staged.positions.push_back(*deformed);
        staged.uvs.push_back(binding.uv);
    }

    if (!compute_geometric_normals(staged, result.issues, cancel)) {
        result.outcome = cancelled(cancel) ? Outcome::Cancelled : Outcome::InvalidInput;
        return result;
    }
    if (cancelled(cancel)) {
        result.outcome = Outcome::Cancelled;
        add_issue(result.issues, "cancelled", "Cancellation was requested before mesh completion.", source.source_id);
        return result;
    }
    staged.bounds_min = bounds_min_of(staged.positions);
    staged.bounds_max = bounds_max_of(staged.positions);
    if (!finite(staged.bounds_min) || !finite(staged.bounds_max)) {
        result.outcome = Outcome::InternalError;
        add_issue(result.issues, "nonfinite_bounds", "Exact evaluated bounds are non-finite.", source.source_id);
        return result;
    }

    if (max_reconstruction_error > 0.0) {
        add_issue(result.issues, "rest_reconstruction_measured",
                  "Rest reconstruction was checked before publishing the privately staged mesh.", source.source_id);
    }
    result.mesh = std::move(staged);
    result.outcome = Outcome::Ok;
    return result;
}

} // namespace

EvaluationResult evaluate_ribbon(const PreparedRibbon& source, const RestGuide& rest,
                                 const GuidePose& pose, const Limits& limits,
                                 const Tolerances& tolerances, Cancellation cancel) {
    try {
        return evaluate_impl(source, rest, pose, limits, tolerances, cancel);
    } catch (const std::bad_alloc&) {
        EvaluationResult out;
        out.outcome = Outcome::AllocationFailure;
        try { add_issue(out.issues, "allocation_failure", "Allocation failed; no partial mesh was returned.", source.source_id); } catch (...) { }
        return out;
    } catch (const std::exception& e) {
        EvaluationResult out;
        out.outcome = Outcome::InternalError;
        try { add_issue(out.issues, "internal_exception", e.what(), source.source_id); } catch (...) { }
        return out;
    } catch (...) {
        EvaluationResult out;
        out.outcome = Outcome::InternalError;
        try { add_issue(out.issues, "internal_exception", "Unknown exception; no partial mesh was returned.", source.source_id); } catch (...) { }
        return out;
    }
}

} // namespace cyrus::vegetation::prototype_v1
