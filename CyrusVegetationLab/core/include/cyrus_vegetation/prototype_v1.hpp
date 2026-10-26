#pragma once
// Frozen source interface for the external GPT Web prototype handoff.
// Declarations/data only: no physics, fitting, decoding or acceptance implementation.
// Internal C++20 source contract, not a stable DLL ABI or a shipped Cyrus schema.
#include <array>
#include <atomic>
#include <cstddef>
#include <cstdint>
#include <memory>
#include <string>
#include <vector>

namespace cyrus::vegetation::prototype_v1 {
using Id = std::uint64_t; // Caller-owned stable IDs; zero is invalid.
using Generation = std::uint64_t;
struct Vec3 { double x = 0, y = 0, z = 0; };
struct Quat { double x = 0, y = 0, z = 0, w = 1; }; // Active local-to-patch rotation, xyzw.
struct UV { double u = 0, v = 0; };
struct Issue { std::string code, message; Id object_id = 0, span_id = 0; };
struct Cancellation {
    const std::atomic_bool* flag = nullptr; // Borrowed for the duration of this synchronous call.
    bool requested() const noexcept { return flag && flag->load(std::memory_order_relaxed); }
};
enum class Outcome { Ok, InvalidInput, Unsupported, Ambiguous, ResourceLimit, Cancelled, AllocationFailure, InternalError };
struct Limits {
    // Caller supplies every value. Zero is invalid, never unlimited.
    std::size_t max_obstacles = 0, max_nodes = 0, max_contacts_per_query = 0;
    std::size_t max_query_calls = 0, max_iterations = 0, max_render_vertices = 0;
    std::size_t max_render_triangles = 0, max_owned_and_scratch_bytes = 0;
};
struct Tolerances {
    // Metres, dimensionless relative error, radians. Explicit fixture criteria, not artist presets.
    double root_m = 0, penetration_m = 0, relative_length = 0;
    double frame_radians = 0, rest_reconstruction_m = 0;
};
enum class ObstacleKind { Sphere, Box };
struct Obstacle {
    Id id = 0;
    std::uint64_t geometry_revision = 0, pose_revision = 0;
    ObstacleKind kind = ObstacleKind::Sphere;
    Vec3 center;
    Quat orientation; // Sphere orientation has no geometric effect; box supports rigid rotation.
    double sphere_radius = 0;
    Vec3 box_half_extents;
};
struct SceneSnapshot {
    Generation generation = 0;
    std::vector<Obstacle> obstacles; // Owned, immutable during each operation.
};
struct BackendOptions {
    Limits limits;
    double query_tolerance_m = 0;
    double min_supported_feature_m = 0; // Declared admission profile; not an engine-wide minimum.
};
struct BackendIdentity {
    std::string name, source_commit, build_flags, precision_profile;
};
enum class Location { Outside, Boundary, Inside, Ambiguous, Unsupported };
struct PointHit {
    Id obstacle_id = 0;
    Location location = Location::Ambiguous;
    double signed_gap_m = 0; // Positive outside the requested exclusion envelope.
};
struct PointResult {
    Outcome outcome = Outcome::InternalError;
    Generation generation = 0;
    bool complete = false;
    std::vector<PointHit> hits; // One per obstacle when successful and complete.
    std::vector<Issue> issues;
};
struct CapsuleQuery {
    Id guide_id = 0, span_id = 0;
    Vec3 a, b;
    double geometric_radius_m = 0, clearance_m = 0; // Added exactly once by the adapter.
};
struct Contact {
    Id obstacle_id = 0, guide_id = 0, span_id = 0;
    double material_u = 0; // Qualified fraction on the directed a -> b interval.
    bool witness_qualified = false;
    Vec3 axis_point, obstacle_point, outward_normal; // All in patch space; normal is unit length.
    double signed_gap_m = 0; // dot(n, axis_point-obstacle_point)-radius-clearance.
};
struct ContactResult {
    Outcome outcome = Outcome::InternalError;
    Generation generation = 0;
    bool complete = false;
    std::vector<Contact> contacts; // All relevant obstacles, not only the nearest one.
    std::vector<Issue> issues;
};
class CollisionWorld {
public:
    virtual ~CollisionWorld() = default;
    virtual Generation generation() const noexcept = 0;
    virtual BackendIdentity backend() const = 0;
    // V1 serializes calls per world. Const is not a promise of concurrent-query support.
    virtual PointResult classify_point(Vec3 point, double exclusion_radius_m, Cancellation cancel) const = 0;
    virtual ContactResult query_capsule(const CapsuleQuery& query, Cancellation cancel) const = 0;
};
struct WorldBuild {
    Outcome outcome = Outcome::InternalError;
    std::shared_ptr<const CollisionWorld> world;
    std::vector<Issue> issues;
};
// Agent A owns this implementation. It deep-copies the snapshot and owns runtime/shape lifetimes.
WorldBuild make_jolt_world(const SceneSnapshot& snapshot, const BackendOptions& options, Cancellation cancel);

enum class RootMode { PositionOnly, ClampFrame, SoftFrame };
struct RestGuide {
    Id guide_id = 0;
    std::uint64_t source_revision = 0;
    std::vector<Id> node_ids, span_ids; // N nodes, N-1 directed spans; ordering never silently changes.
    std::vector<Vec3> nodes;
    std::vector<Quat> material_frames; // N frames; local +Z is the tangent convention.
    std::vector<double> span_radius_m, max_bound_offset_m; // N-1, clearance excluded.
    bool requires_full_turn_twist = false; // Unsupported in the deliberately narrow v1 sampler.
};
struct GuidePose {
    Id guide_id = 0;
    std::vector<Vec3> nodes;
    std::vector<Quat> material_frames; // Same counts/semantic order as RestGuide.
};
struct SolveOptions {
    Limits limits;
    Tolerances tolerances;
    RootMode root_mode = RootMode::PositionOnly;
    double clearance_m = 0;
    double rest_shape_weight = 0, bend_weight = 0, root_angle_weight = 0;
    double max_proposal_step_m = 0;
};
enum class SolveStatus { ConvergedCandidate, UnresolvedContact, RootConflict, InvalidInput, Unsupported, WorkLimit, Cancelled, AllocationFailure, InternalError };
struct SolveMetrics {
    std::size_t iterations = 0, query_calls = 0, unresolved_contacts = 0;
    std::size_t peak_owned_and_scratch_bytes = 0;
    double max_root_error_m = 0, max_relative_length_error = 0;
    double max_penetration_m = 0, root_angle_error_radians = 0;
    double rest_objective = 0;
};
struct SolveResult {
    SolveStatus status = SolveStatus::InternalError;
    Generation generation = 0;
    std::uint64_t source_revision = 0;
    GuidePose pose; // Diagnostic only unless status is ConvergedCandidate.
    SolveMetrics metrics;
    std::vector<Issue> issues;
};
// Agent B owns this implementation. No host mutation, publication, global state or hidden history.
SolveResult fit_rooted_guide(const RestGuide& rest, Generation generation,
    const CollisionWorld& world, const SolveOptions& options, Cancellation cancel);

struct BoundVertex {
    Id render_vertex_id = 0, logical_vertex_id = 0, span_id = 0;
    double material_u = 0;
    Vec3 rest_local_offset; // Complete xyz offset, not only lateral width.
    UV uv;
};
struct PreparedRibbon {
    Id source_id = 0;
    std::uint64_t source_revision = 0;
    std::vector<Vec3> rest_positions; // Render-vertex order; used to certify reconstruction.
    std::vector<BoundVertex> bindings; // One explicit binding per render vertex, one guide only.
    std::vector<std::array<std::uint32_t, 3>> triangles;
    std::vector<std::uint32_t> face_material_ids;
};
struct EvaluatedMesh {
    Id source_id = 0;
    std::uint64_t source_revision = 0;
    std::vector<Vec3> positions, normals; // V1 geometric normals only, no authored-normal guarantee.
    std::vector<UV> uvs;
    std::vector<std::array<std::uint32_t, 3>> triangles;
    std::vector<std::uint32_t> face_material_ids;
    Vec3 bounds_min, bounds_max;
};
struct EvaluationResult {
    Outcome outcome = Outcome::InternalError;
    EvaluatedMesh mesh;
    std::vector<Issue> issues;
};
// Agent C owns these implementations. Sampler: linear center, shortest-path normalized slerp frame.
EvaluationResult evaluate_ribbon(const PreparedRibbon& source, const RestGuide& rest,
    const GuidePose& pose, const Limits& limits, const Tolerances& tolerances, Cancellation cancel);
enum class ValidationStatus { Pass, Fail, InvalidInput, Unsupported, Ambiguous, ResourceLimit, Cancelled, AllocationFailure, InternalError };
struct ValidationResult {
    ValidationStatus status = ValidationStatus::InternalError;
    Generation generation = 0;
    double max_root_error_m = 0, max_relative_length_error = 0;
    double max_visible_penetration_m = 0, rest_reconstruction_error_m = 0;
    std::vector<Issue> issues;
};
// Must use independent primitive/triangle mathematics; it must not call Agent A or Jolt.
ValidationResult validate_candidate(const SceneSnapshot& snapshot, const PreparedRibbon& source,
    const RestGuide& rest, const GuidePose& pose, const EvaluatedMesh& mesh,
    const SolveOptions& options, Cancellation cancel);
} // namespace cyrus::vegetation::prototype_v1
