// Owner A: immutable, public-Jolt primitive query adapter. No simulation world,
// private Jolt access, soft-body rows, host SDK or historical harness is used.
#include "collision_build_profile.hpp" // Also enforces the actual native profile.
#include "jolt_runtime.hpp"
#include "primitive_geometry.hpp"
#include "query_diagnostics.hpp"

#include <Jolt/ConfigurationString.h>
#include <Jolt/Physics/Collision/CollidePointResult.h>
#include <Jolt/Physics/Collision/CollideShape.h>
#include <Jolt/Physics/Collision/CollisionCollector.h>
#include <Jolt/Physics/Collision/CollisionDispatch.h>
#include <Jolt/Physics/Collision/Shape/BoxShape.h>
#include <Jolt/Physics/Collision/Shape/CapsuleShape.h>
#include <Jolt/Physics/Collision/Shape/SphereShape.h>

#include <algorithm>
#include <array>
#include <cmath>
#include <limits>
#include <memory>
#include <mutex>
#include <new>
#include <type_traits>
#include <utility>

namespace cyrus::vegetation::prototype_v1 {
namespace collision_detail {
namespace {

static_assert(std::is_same_v<JPH::Real, double>);
constexpr std::size_t max_profile_obstacles = 4096;
constexpr double min_profile_feature = 1.0e-6;
constexpr double max_profile_feature = 1.0e3;
constexpr double max_profile_coordinate = 1.0e6;
constexpr double min_profile_tolerance = 1.0e-10;
constexpr double max_quaternion_norm_error = 1.0e-10;
constexpr std::size_t max_native_hits_per_pair = 4;

// Budget charges, NOT measured allocator peaks. Known C++/shape payloads are
// counted separately. These explicit reservations cover small adapter metadata
// and a working-stack allowance, not an instrumented bound on all Jolt/runtime
// allocations. The README enumerates exclusions. All population-dependent
// adapter allocations are also limited independently by the hard profile cap.
constexpr std::size_t metadata_reservation_bytes = 4096;
constexpr std::size_t operation_reservation_bytes = 65536;

thread_local QueryDiagnostics trace;

Vec3 add(Vec3 a, Vec3 b) noexcept { return {a.x+b.x,a.y+b.y,a.z+b.z}; }
Vec3 sub(Vec3 a, Vec3 b) noexcept { return {a.x-b.x,a.y-b.y,a.z-b.z}; }
Vec3 mul(Vec3 a, double b) noexcept { return {a.x*b,a.y*b,a.z*b}; }
double dot(Vec3 a, Vec3 b) noexcept { return a.x*b.x+a.y*b.y+a.z*b.z; }
double norm(Vec3 a) noexcept { return std::hypot(a.x,a.y,a.z); }
double magnitude(Vec3 a) noexcept {
    return std::max({std::abs(a.x),std::abs(a.y),std::abs(a.z)});
}
bool finite(Vec3 a) noexcept {
    return std::isfinite(a.x)&&std::isfinite(a.y)&&std::isfinite(a.z);
}
bool finite(Quat a) noexcept {
    return std::isfinite(a.x)&&std::isfinite(a.y)&&std::isfinite(a.z)&&std::isfinite(a.w);
}
double quat_norm(Quat a) noexcept {
    return std::hypot(std::hypot(a.x,a.y),std::hypot(a.z,a.w));
}
JPH::Vec3 to_native(Vec3 v) noexcept {
    return JPH::Vec3(static_cast<float>(v.x),static_cast<float>(v.y),static_cast<float>(v.z));
}
Vec3 from_native(JPH::Vec3Arg v) noexcept { return {v.GetX(),v.GetY(),v.GetZ()}; }
JPH::Quat to_native(Quat q) noexcept {
    return JPH::Quat(static_cast<float>(q.x),static_cast<float>(q.y),
                     static_cast<float>(q.z),static_cast<float>(q.w)).Normalized();
}

struct Failure {
    Outcome outcome = Outcome::Ok;
    const char* code = "";
    const char* message = "";
    Id object_id = 0;
};
Failure invalid(const char* code,const char* message,Id id=0) noexcept {
    return {Outcome::InvalidInput,code,message,id};
}
Failure unsupported(const char* code,const char* message,Id id=0) noexcept {
    return {Outcome::Unsupported,code,message,id};
}
Failure limit(const char* code,const char* message,Id id=0) noexcept {
    return {Outcome::ResourceLimit,code,message,id};
}
Failure ambiguous(const char* code,const char* message,Id id=0) noexcept {
    return {Outcome::Ambiguous,code,message,id};
}
Failure cancelled() noexcept {
    return {Outcome::Cancelled,"cancelled","Operation cancelled; staged output was discarded.",0};
}

void add_issue(std::vector<Issue>& issues,Failure f,Id span=0) noexcept {
    // At most one bounded diagnostic is constructed. In catastrophic OOM the
    // status still survives even if its explanatory strings cannot be allocated.
    try { issues.push_back({f.code,f.message,f.object_id,span}); } catch (...) { }
}
WorldBuild failed_build(Failure f) noexcept {
    WorldBuild r;r.outcome=f.outcome;add_issue(r.issues,f);return r;
}
PointResult failed_point(Generation generation,Failure f) noexcept {
    PointResult r;r.generation=generation;r.outcome=f.outcome;add_issue(r.issues,f);return r;
}
ContactResult failed_contact(Generation generation,Failure f,Id span) noexcept {
    ContactResult r;r.generation=generation;r.outcome=f.outcome;add_issue(r.issues,f,span);return r;
}

bool checked_add(std::size_t& sum,std::size_t value) noexcept {
    if(value>std::numeric_limits<std::size_t>::max()-sum)return false;
    sum+=value;return true;
}
bool checked_array(std::size_t& sum,std::size_t count,std::size_t size) noexcept {
    if(count>std::numeric_limits<std::size_t>::max()/size)return false;
    return checked_add(sum,count*size);
}
bool within_memory(std::size_t owned,std::size_t scratch,std::size_t budget) noexcept {
    return owned<=budget && scratch<=budget-owned;
}

Failure validate_options(const BackendOptions& o) noexcept {
    const auto& l=o.limits;
    if(!l.max_obstacles||!l.max_nodes||!l.max_contacts_per_query||!l.max_query_calls||
       !l.max_iterations||!l.max_render_vertices||!l.max_render_triangles||
       !l.max_owned_and_scratch_bytes)
        return invalid("zero_limit","Every Limits field must be explicitly nonzero.");
    if(!std::isfinite(o.query_tolerance_m)||!(o.query_tolerance_m>0)||
       !std::isfinite(o.min_supported_feature_m)||!(o.min_supported_feature_m>0))
        return invalid("invalid_tolerance","Tolerance and minimum feature must be finite and positive.");
    if(o.min_supported_feature_m<min_profile_feature||o.min_supported_feature_m>max_profile_feature||
       o.query_tolerance_m<min_profile_tolerance||o.query_tolerance_m>o.min_supported_feature_m*0.25)
        return unsupported("numeric_profile","Feature must be 1e-6..1e3 m and tolerance 1e-10..feature/4 m.");
    return {};
}
Failure validate_obstacle(const Obstacle& o,const BackendOptions& options) noexcept {
    if(!o.id||!o.geometry_revision||!o.pose_revision)
        return invalid("zero_obstacle_identity","Obstacle ID and geometry/pose revisions must be nonzero.",o.id);
    if(!finite(o.center)||!finite(o.orientation)||!std::isfinite(o.sphere_radius)||!finite(o.box_half_extents))
        return invalid("nonfinite_obstacle","All obstacle fields, including inactive dimensions, must be finite.",o.id);
    const double qn=quat_norm(o.orientation);
    if(!std::isfinite(qn)||std::abs(qn-1.0)>max_quaternion_norm_error)
        return invalid("nonunit_rotation","Obstacle orientation must be a unit rigid quaternion; scale/shear is not encoded here.",o.id);
    if(magnitude(o.center)>max_profile_coordinate)
        return unsupported("coordinate_profile","Obstacle center exceeds the +/-1e6 m patch profile; rebase first.",o.id);
    if(o.kind!=ObstacleKind::Sphere&&o.kind!=ObstacleKind::Box)
        return unsupported("shape_kind","Only spheres and rigid oriented boxes are admitted.",o.id);
    const Vec3 dimensions=o.kind==ObstacleKind::Sphere?
        Vec3{o.sphere_radius,o.sphere_radius,o.sphere_radius}:o.box_half_extents;
    if(!(dimensions.x>0&&dimensions.y>0&&dimensions.z>0))
        return invalid("nonpositive_dimension","Active radius/half-extents must be strictly positive.",o.id);
    if(std::min({dimensions.x,dimensions.y,dimensions.z})<options.min_supported_feature_m||
       magnitude(dimensions)>max_profile_feature)
        return unsupported("feature_profile","Obstacle dimensions fall outside the declared minimum..1000 m profile.",o.id);
    return {};
}
Failure validate_point(Vec3 p,double exclusion) noexcept {
    if(!finite(p)||!std::isfinite(exclusion)||exclusion<0)
        return invalid("invalid_point","Point and exclusion must be finite; exclusion cannot be negative.");
    if(magnitude(p)>max_profile_coordinate||exclusion>max_profile_feature)
        return unsupported("point_profile","Point exceeds +/-1e6 m or exclusion exceeds 1000 m.");
    return {};
}
Failure validate_capsule(const CapsuleQuery& q,const BackendOptions& o) noexcept {
    if(!q.guide_id||!q.span_id)return invalid("zero_query_identity","Guide and span IDs must be nonzero.",q.guide_id);
    if(!finite(q.a)||!finite(q.b)||!std::isfinite(q.geometric_radius_m)||
       !std::isfinite(q.clearance_m)||!(q.geometric_radius_m>0)||q.clearance_m<0)
        return invalid("invalid_capsule","Finite endpoints, positive radius and nonnegative clearance are required.",q.guide_id);
    const double length=norm(sub(q.b,q.a));
    if(!(length>0)||!std::isfinite(length))
        return invalid("degenerate_segment","A capsule span must have two distinct finite endpoints.",q.guide_id);
    if(magnitude(q.a)>max_profile_coordinate||magnitude(q.b)>max_profile_coordinate||
       length<o.min_supported_feature_m||length>max_profile_feature||
       q.geometric_radius_m<o.min_supported_feature_m||q.geometric_radius_m>max_profile_feature||
       q.clearance_m>max_profile_feature)
        return unsupported("capsule_profile","Endpoints, span length, radius or clearance exceed the admitted numeric profile.",q.guide_id);
    return {};
}

struct Entry {
    Obstacle obstacle; // Entire admitted caller snapshot, including both revisions.
    JPH::RefConst<JPH::Shape> shape;
    JPH::Quat rotation = JPH::Quat::sIdentity();
};
struct RawHit {
    Vec3 query_point,obstacle_point,axis;
    double depth=0;
};
class BoundedShapeCollector final : public JPH::CollideShapeCollector {
public:
    explicit BoundedShapeCollector(Cancellation token):cancel(token){}
    void AddHit(const JPH::CollideShapeResult& hit) override {
        if(cancel.requested()){was_cancelled=true;ForceEarlyOut();return;}
        if(count==hits.size()){overflow=true;ForceEarlyOut();return;}
        auto& r=hits[count++];
        r={from_native(hit.mContactPointOn1),from_native(hit.mContactPointOn2),
           from_native(hit.mPenetrationAxis),hit.mPenetrationDepth};
        if(!finite(r.query_point)||!finite(r.obstacle_point)||!finite(r.axis)||!std::isfinite(r.depth))
            malformed=true;
        // Do not update the early-out fraction: it must not discard a second
        // primitive result. The fixed collector is an explicit safety bound.
    }
    Cancellation cancel;
    std::array<RawHit,max_native_hits_per_pair> hits{};
    std::size_t count=0;
    bool overflow=false,was_cancelled=false,malformed=false;
};
class BoundedPointCollector final : public JPH::CollidePointCollector {
public:
    explicit BoundedPointCollector(Cancellation token):cancel(token){}
    void AddHit(const JPH::CollidePointResult&) override {
        if(cancel.requested()){was_cancelled=true;ForceEarlyOut();return;}
        if(count==1){overflow=true;ForceEarlyOut();return;}
        ++count;
    }
    Cancellation cancel;
    std::size_t count=0;
    bool overflow=false,was_cancelled=false;
};

// A broad numerical discrepancy allowance for the FLOAT public Jolt query,
// used only to reject gross contradictions. It neither replaces query tolerance
// nor certifies a raw witness. Returned contact qualification is done in double.
double native_discrepancy_allowance(const Entry& e,Vec3 local_center,double length,
                                   double radius,double tolerance) noexcept {
    const auto& o=e.obstacle;
    const double extent=o.kind==ObstacleKind::Sphere?o.sphere_radius:magnitude(o.box_half_extents);
    const double scale=std::max({min_profile_feature,extent,magnitude(local_center),length,radius});
    return 256.0*std::numeric_limits<float>::epsilon()*scale + 8.0*tolerance;
}

Failure qualify(const GeometryWitness& w,double tolerance,Id obstacle_id) noexcept {
    if(!w.qualified||!std::isfinite(w.numerical_bound_m)||!(w.numerical_bound_m>0))
        return ambiguous("unqualified_witness","Primitive witness failed finite/surface/normal/u reconstruction checks.",obstacle_id);
    if(w.numerical_bound_m>tolerance)
        return ambiguous("precision_budget","Coordinate-dependent double round-off allowance exceeds query tolerance; rebase or revise profile.",obstacle_id);
    return {};
}
void record_native_hit(const Entry& e,const RawHit& r) noexcept {
    if(trace.first_raw_hit_available)return;
    trace.first_raw_hit_available=true;
    trace.first_raw_obstacle_id=e.obstacle.id;
    trace.first_raw_query_point=add(e.obstacle.center,r.query_point);
    trace.first_raw_obstacle_point=add(e.obstacle.center,r.obstacle_point);
    trace.first_raw_penetration_depth_m=r.depth;
    const double length=norm(r.axis);
    if(length>0&&std::isfinite(length)){
        trace.first_raw_normal_valid=true;
        trace.first_raw_outward_normal=mul(r.axis,-1.0/length);
        trace.first_raw_consistency_error_m=std::abs(
            dot(trace.first_raw_outward_normal,sub(r.query_point,r.obstacle_point))+r.depth);
    }
}

class JoltWorld final : public CollisionWorld {
public:
    JoltWorld(RuntimeLease runtime,std::vector<Entry> entries,Generation generation,
              BackendOptions options,std::size_t owned_bytes)
        :m_runtime(std::move(runtime)),m_entries(std::move(entries)),m_generation(generation),
         m_options(options),m_owned_bytes(owned_bytes){}

    Generation generation() const noexcept override { return m_generation; }
    BackendIdentity backend() const override {
        // Frozen API has no Outcome for identity allocation. std::bad_alloc may
        // propagate here; it cannot be translated into a query success.
        return {"Jolt public primitive queries + qualified double analytic refinement",
                CYRUS_COLLISION_JOLT_COMMIT,
                std::string(CYRUS_COLLISION_BUILD_FLAGS)+"; native="+JPH::GetConfigurationString(),
                CYRUS_COLLISION_PRECISION_PROFILE};
    }

    PointResult classify_point(Vec3 point,double exclusion,Cancellation cancel) const override {
        trace={};trace.operation=NativeOperation::Point;trace.accounted_owned_bytes=m_owned_bytes;
        try {
            if(cancel.requested())return failed_point(m_generation,cancelled());
            if(const auto f=validate_point(point,exclusion);f.outcome!=Outcome::Ok)return failed_point(m_generation,f);
            std::unique_lock lock(m_query_mutex);
            if(cancel.requested())return failed_point(m_generation,cancelled());
            if(m_entries.size()>m_options.limits.max_query_calls)
                return failed_point(m_generation,limit("query_budget","The per-operation native dispatch budget cannot examine every obstacle."));
            if(m_entries.size()>m_options.limits.max_contacts_per_query)
                return failed_point(m_generation,limit("point_result_budget","Complete point classification needs one result per obstacle."));
            std::size_t scratch=operation_reservation_bytes;
            if(!checked_array(scratch,m_entries.size(),sizeof(PointHit))||
               !within_memory(m_owned_bytes,scratch,m_options.limits.max_owned_and_scratch_bytes))
                return failed_point(m_generation,limit("memory_budget","Owned data plus planned point-result/scratch charge exceeds the limit."));
            PointResult result;result.generation=m_generation;result.hits.reserve(m_entries.size());
            scratch=operation_reservation_bytes;
            if(!checked_array(scratch,result.hits.capacity(),sizeof(PointHit))||
               !within_memory(m_owned_bytes,scratch,m_options.limits.max_owned_and_scratch_bytes))
                return failed_point(m_generation,limit("capacity_budget","Actual result-vector capacity exceeds the accounting budget."));
            trace.accounted_scratch_bytes=scratch;
            for(const auto& e:m_entries){
                if(cancel.requested())return failed_point(m_generation,cancelled());
                const Vec3 rebased=sub(point,e.obstacle.center); // subtract in DOUBLE before float conversion
                const JPH::Vec3 local=e.rotation.Conjugated()*to_native(rebased);
                BoundedPointCollector collector(cancel);
                ++trace.native_calls;
                e.shape->CollidePoint(local,JPH::SubShapeIDCreator(),collector);
                trace.native_hits+=collector.count;
                if(cancel.requested()||collector.was_cancelled)return failed_point(m_generation,cancelled());
                if(collector.overflow)return failed_point(m_generation,limit("native_point_overflow","Native primitive point collector exceeded its fixed capacity.",e.obstacle.id));
                const auto w=primitive_point(e.obstacle,point);
                if(const auto f=qualify(w,m_options.query_tolerance_m,e.obstacle.id);f.outcome!=Outcome::Ok)
                    return failed_point(m_generation,f);
                const double native_allowance=native_discrepancy_allowance(e,rebased,0,exclusion,m_options.query_tolerance_m);
                if(collector.count&&w.axis_signed_distance>native_allowance)
                    return failed_point(m_generation,ambiguous("native_point_disagreement","Native solid hit contradicts the admitted primitive beyond the float allowance.",e.obstacle.id));
                if(!collector.count&&w.axis_signed_distance < -native_allowance)++trace.native_misses_refined;
                const double gap=w.axis_signed_distance-exclusion;
                const double tolerance=m_options.query_tolerance_m;
                Location location=Location::Boundary;
                if(gap>tolerance){
                    if(gap-w.numerical_bound_m<=tolerance)
                        return failed_point(m_generation,ambiguous("point_boundary_precision","Outside/boundary comparison is too close for the declared numeric allowance.",e.obstacle.id));
                    location=Location::Outside;
                }else if(gap < -tolerance){
                    if(gap+w.numerical_bound_m>=-tolerance)
                        return failed_point(m_generation,ambiguous("point_boundary_precision","Inside/boundary comparison is too close for the declared numeric allowance.",e.obstacle.id));
                    location=Location::Inside;
                }
                if(gap<=tolerance)++trace.analytic_contacts;
                result.hits.push_back({e.obstacle.id,location,gap});
            }
            if(cancel.requested())return failed_point(m_generation,cancelled());
            result.outcome=Outcome::Ok;result.complete=true;return result;
        }catch(const std::bad_alloc&){
            return failed_point(m_generation,{Outcome::AllocationFailure,"allocation_failure","Point operation allocation failed; no partial result was accepted.",0});
        }catch(...){
            return failed_point(m_generation,{Outcome::InternalError,"query_exception","Point operation failed with an unexpected exception.",0});
        }
    }

    ContactResult query_capsule(const CapsuleQuery& q,Cancellation cancel) const override {
        trace={};trace.operation=NativeOperation::Capsule;trace.accounted_owned_bytes=m_owned_bytes;
        try {
            if(cancel.requested())return failed_contact(m_generation,cancelled(),q.span_id);
            if(const auto f=validate_capsule(q,m_options);f.outcome!=Outcome::Ok)return failed_contact(m_generation,f,q.span_id);
            std::unique_lock lock(m_query_mutex);
            if(cancel.requested())return failed_contact(m_generation,cancelled(),q.span_id);
            if(m_entries.size()>m_options.limits.max_query_calls)
                return failed_contact(m_generation,limit("query_budget","The per-operation native dispatch budget cannot examine every obstacle."),q.span_id);
            const std::size_t capacity=std::min(m_entries.size(),m_options.limits.max_contacts_per_query);
            std::size_t scratch=operation_reservation_bytes;
            if(!checked_array(scratch,capacity,sizeof(Contact))||
               !within_memory(m_owned_bytes,scratch,m_options.limits.max_owned_and_scratch_bytes))
                return failed_contact(m_generation,limit("memory_budget","Owned data plus planned contact-result/scratch charge exceeds the limit."),q.span_id);
            ContactResult result;result.generation=m_generation;result.contacts.reserve(capacity);
            scratch=operation_reservation_bytes;
            if(!checked_array(scratch,result.contacts.capacity(),sizeof(Contact))||
               !within_memory(m_owned_bytes,scratch,m_options.limits.max_owned_and_scratch_bytes))
                return failed_contact(m_generation,limit("capacity_budget","Actual result-vector capacity exceeds the accounting budget."),q.span_id);
            trace.accounted_scratch_bytes=scratch;

            const Vec3 direction=sub(q.b,q.a);const double length=norm(direction);
            const Vec3 midpoint=add(q.a,mul(direction,0.5));
            const double radius=q.geometric_radius_m+q.clearance_m;
            // Native capsule local +Y is explicitly aligned to directed a->b.
            // A guide material quaternion (+Z tangent) is NOT a capsule pose.
            const JPH::Quat capsule_rotation=JPH::Quat::sFromTo(
                JPH::Vec3::sAxisY(),to_native(mul(direction,1.0/length)).Normalized());
            JPH::CapsuleShape capsule(static_cast<float>(0.5*length),static_cast<float>(radius));
            JPH::CollideShapeSettings settings;
            settings.mCollectFacesMode=JPH::ECollectFacesMode::NoFaces;
            settings.mCollisionTolerance=static_cast<float>(m_options.query_tolerance_m);
            settings.mPenetrationTolerance=1.0e-4f; // Relative EPA stopping tolerance, not metres.
            settings.mMaxSeparationDistance=static_cast<float>(m_options.query_tolerance_m);

            for(const auto& e:m_entries){
                if(cancel.requested())return failed_contact(m_generation,cancelled(),q.span_id);
                // All admitted primitives have local COM zero. Per-pair origin
                // is the copied obstacle center; avoid absolute float matrices.
                const Vec3 local_center=sub(midpoint,e.obstacle.center);
                const JPH::Mat44 capsule_pose=JPH::Mat44::sRotationTranslation(capsule_rotation,to_native(local_center));
                const JPH::Mat44 obstacle_pose=JPH::Mat44::sRotation(e.rotation);
                BoundedShapeCollector collector(cancel);
                ++trace.native_calls;
                JPH::CollisionDispatch::sCollideShapeVsShape(
                    &capsule,e.shape.GetPtr(),JPH::Vec3::sOne(),JPH::Vec3::sOne(),
                    capsule_pose,obstacle_pose,JPH::SubShapeIDCreator(),JPH::SubShapeIDCreator(),settings,collector);
                trace.native_hits+=collector.count;
                if(cancel.requested()||collector.was_cancelled)return failed_contact(m_generation,cancelled(),q.span_id);
                if(collector.overflow)return failed_contact(m_generation,limit("native_contact_overflow","Native primitive collector exceeded four fixed raw witnesses; completeness is unknown.",e.obstacle.id),q.span_id);
                if(collector.malformed)return failed_contact(m_generation,ambiguous("malformed_native_witness","Native primitive query returned a nonfinite witness.",e.obstacle.id),q.span_id);
                if(collector.count)record_native_hit(e,collector.hits[0]);

                // Complete whole-segment solid refinement. No raw hit is assigned
                // an invented u; a raw miss is not used to infer Outside.
                const auto w=primitive_segment(e.obstacle,q.a,q.b);
                if(const auto f=qualify(w,m_options.query_tolerance_m,e.obstacle.id);f.outcome!=Outcome::Ok)
                    return failed_contact(m_generation,f,q.span_id);
                const double minimum_gap=w.axis_signed_distance-q.geometric_radius_m-q.clearance_m;
                const double gap=dot(w.normal,sub(w.axis,w.surface))-q.geometric_radius_m-q.clearance_m;
                const double tolerance=m_options.query_tolerance_m;
                const double native_allowance=native_discrepancy_allowance(e,local_center,length,radius,tolerance);
                if(collector.count&&minimum_gap>tolerance+native_allowance)
                    return failed_contact(m_generation,ambiguous("native_contact_disagreement","Native overlap contradicts primitive separation beyond the float allowance.",e.obstacle.id),q.span_id);
                if(!std::isfinite(gap)||std::abs(gap-minimum_gap)>w.numerical_bound_m)
                    return failed_contact(m_generation,ambiguous("gap_reconstruction","Signed gap does not reconstruct from the qualified primitive witness.",e.obstacle.id),q.span_id);
                if(minimum_gap>tolerance&&gap>tolerance){
                    if(std::min(gap,minimum_gap)-w.numerical_bound_m<=tolerance)
                        return failed_contact(m_generation,ambiguous("contact_boundary_precision","Clear/contact comparison is too close for the declared numeric allowance.",e.obstacle.id),q.span_id);
                    continue;
                }
                if(gap>tolerance)
                    return failed_contact(m_generation,ambiguous("contact_boundary_precision","Reconstructed contact gap lies across the requested contact boundary.",e.obstacle.id),q.span_id);
                if(result.contacts.size()==m_options.limits.max_contacts_per_query)
                    return failed_contact(m_generation,limit("contact_limit","All obstacle contacts do not fit; the partial set was discarded.",e.obstacle.id),q.span_id);
                if(!collector.count)++trace.native_misses_refined;
                ++trace.analytic_contacts;
                result.contacts.push_back({e.obstacle.id,q.guide_id,q.span_id,w.u,true,
                                           w.axis,w.surface,w.normal,gap});
            }
            if(cancel.requested())return failed_contact(m_generation,cancelled(),q.span_id);
            result.outcome=Outcome::Ok;result.complete=true;return result;
        }catch(const std::bad_alloc&){
            return failed_contact(m_generation,{Outcome::AllocationFailure,"allocation_failure","Capsule operation allocation failed; no partial result was accepted.",q.guide_id},q.span_id);
        }catch(...){
            return failed_contact(m_generation,{Outcome::InternalError,"query_exception","Capsule operation failed with an unexpected exception.",q.guide_id},q.span_id);
        }
    }

private:
    // Declaration order is a lifetime invariant: entries/shapes die BEFORE
    // the runtime lease's final unregister/default-material/factory teardown.
    RuntimeLease m_runtime;
    const std::vector<Entry> m_entries;
    const Generation m_generation;
    const BackendOptions m_options;
    const std::size_t m_owned_bytes;
    mutable std::mutex m_query_mutex;
};

} // namespace

QueryDiagnostics last_query_diagnostics() noexcept { return trace; }

WorldBuild build_world(const SceneSnapshot& snapshot,const BackendOptions& options,Cancellation cancel) {
    if(cancel.requested())return failed_build(cancelled());
    if(const auto f=validate_options(options);f.outcome!=Outcome::Ok)return failed_build(f);
    if(!snapshot.generation)return failed_build(invalid("zero_generation","Snapshot generation must be nonzero."));
    if(snapshot.obstacles.size()>options.limits.max_obstacles||snapshot.obstacles.size()>max_profile_obstacles)
        return failed_build(limit("obstacle_limit","Obstacle count exceeds the caller limit or the 4096-obstacle profile cap."));
    std::size_t owned=sizeof(JoltWorld)+metadata_reservation_bytes;
    if(!checked_array(owned,snapshot.obstacles.size(),sizeof(Entry))||
       !checked_array(owned,snapshot.obstacles.size(),std::max(sizeof(JPH::SphereShape),sizeof(JPH::BoxShape)))||
       !within_memory(owned,operation_reservation_bytes,options.limits.max_owned_and_scratch_bytes))
        return failed_build(limit("memory_budget","World payload and explicit operation reservation exceed the caller memory budget."));

    // Local order has the same lifetime invariant as the world: a failed build
    // releases staged shape refs before its acquired runtime lease.
    RuntimeLease runtime;
    std::vector<Entry> entries;
    entries.reserve(snapshot.obstacles.size());
    for(const auto& obstacle:snapshot.obstacles){
        if(cancel.requested())return failed_build(cancelled());
        if(const auto f=validate_obstacle(obstacle,options);f.outcome!=Outcome::Ok)return failed_build(f);
        Entry entry;entry.obstacle=obstacle;
        const double qn=quat_norm(entry.obstacle.orientation);
        auto& q=entry.obstacle.orientation;q={q.x/qn,q.y/qn,q.z/qn,q.w/qn};
        entry.rotation=to_native(q);
        entries.push_back(std::move(entry));
    }
    // std::sort uses bounded introsort work/stack for the <=4096-entry profile.
    std::sort(entries.begin(),entries.end(),[](const auto& a,const auto& b){return a.obstacle.id<b.obstacle.id;});
    if(cancel.requested())return failed_build(cancelled());
    for(std::size_t i=1;i<entries.size();++i)
        if(entries[i-1].obstacle.id==entries[i].obstacle.id)
            return failed_build(invalid("duplicate_obstacle_id","Obstacle IDs must be unique within the snapshot.",entries[i].obstacle.id));

    owned=sizeof(JoltWorld)+metadata_reservation_bytes;
    if(!checked_array(owned,entries.capacity(),sizeof(Entry)))
        return failed_build(limit("capacity_overflow","Entry-vector byte accounting overflowed."));
    for(const auto& e:entries)
        if(!checked_add(owned,e.obstacle.kind==ObstacleKind::Sphere?sizeof(JPH::SphereShape):sizeof(JPH::BoxShape)))
            return failed_build(limit("capacity_overflow","Shape byte accounting overflowed."));
    if(!within_memory(owned,operation_reservation_bytes,options.limits.max_owned_and_scratch_bytes))
        return failed_build(limit("capacity_budget","Actual entry capacity plus shape/scratch charges exceed the memory budget."));

    auto acquired=acquire_runtime();
    if(acquired.outcome!=Outcome::Ok)
        return failed_build({acquired.outcome,acquired.code,acquired.message,0});
    runtime=std::move(acquired.lease);
    for(auto& e:entries){
        if(cancel.requested())return failed_build(cancelled());
        if(e.obstacle.kind==ObstacleKind::Sphere)
            e.shape=new JPH::SphereShape(static_cast<float>(e.obstacle.sphere_radius));
        else
            e.shape=new JPH::BoxShape(to_native(e.obstacle.box_half_extents),0.0f); // sharp OBB, no default rounded margin
        if(e.shape->GetCenterOfMass()!=JPH::Vec3::sZero())
            return failed_build({Outcome::InternalError,"unexpected_com","Admitted primitive unexpectedly has a nonzero local center of mass.",e.obstacle.id});
    }
    auto world=std::make_shared<JoltWorld>(std::move(runtime),std::move(entries),snapshot.generation,options,owned);
    if(cancel.requested())return failed_build(cancelled());
    WorldBuild result;result.outcome=Outcome::Ok;result.world=std::move(world);return result;
}

} // namespace collision_detail

WorldBuild make_jolt_world(const SceneSnapshot& snapshot,const BackendOptions& options,Cancellation cancel) {
    try { return collision_detail::build_world(snapshot,options,cancel); }
    catch(const std::bad_alloc&){
        WorldBuild r;r.outcome=Outcome::AllocationFailure;
        try{r.issues.push_back({"allocation_failure","World construction allocation failed; no world was accepted.",0,0});}catch(...){}
        return r;
    }catch(...){
        WorldBuild r;r.outcome=Outcome::InternalError;
        try{r.issues.push_back({"construction_exception","World construction failed with an unexpected exception.",0,0});}catch(...){}
        return r;
    }
}

} // namespace cyrus::vegetation::prototype_v1
