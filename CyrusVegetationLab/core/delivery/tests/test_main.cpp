#include <cyrus_vegetation/prototype_v1.hpp>

#include "diagnostic_obj.hpp"
#include "geometry.hpp"

#include <algorithm>
#include <array>
#include <atomic>
#include <cmath>
#include <cstddef>
#include <cstdint>
#include <filesystem>
#include <functional>
#include <iostream>
#include <limits>
#include <sstream>
#include <stdexcept>
#include <string>
#include <string_view>
#include <utility>
#include <vector>

using namespace cyrus::vegetation::prototype_v1;
using namespace cyrus::vegetation::prototype_v1::delivery_detail;

namespace {

struct Failure : std::runtime_error { using std::runtime_error::runtime_error; };

#define CHECK_TRUE(expr) do { if (!(expr)) { std::ostringstream os; os << __FILE__ << ':' << __LINE__ << " CHECK_TRUE(" #expr ")"; throw Failure(os.str()); } } while (false)
#define CHECK_EQ(a,b) do { const auto _a=(a); const auto _b=(b); if (!(_a == _b)) { std::ostringstream os; os << __FILE__ << ':' << __LINE__ << " CHECK_EQ(" #a ", " #b ")"; throw Failure(os.str()); } } while (false)
#define CHECK_NEAR(a,b,t) do { const double _a=static_cast<double>(a); const double _b=static_cast<double>(b); const double _t=static_cast<double>(t); if (!(std::abs(_a-_b) <= _t)) { std::ostringstream os; os << __FILE__ << ':' << __LINE__ << " CHECK_NEAR(" << _a << ", " << _b << ", " << _t << ")"; throw Failure(os.str()); } } while (false)

bool has_issue(const std::vector<Issue>& issues, std::string_view code) {
    return std::any_of(issues.begin(), issues.end(), [&](const Issue& i) { return i.code == code; });
}

Limits limits() {
    return Limits{32, 64, 32, 20000, 400, 10000, 20000, 67108864};
}

Tolerances tolerances() {
    return Tolerances{1e-8, 1e-5, 0.001, 0.001, 1e-8};
}

SolveOptions options(RootMode mode = RootMode::PositionOnly) {
    SolveOptions o;
    o.limits = limits();
    o.tolerances = tolerances();
    o.root_mode = mode;
    o.clearance_m = 0.005;
    o.rest_shape_weight = 0.01;
    o.bend_weight = 1.0;
    o.root_angle_weight = mode == RootMode::SoftFrame ? 1.0 : 0.0;
    o.max_proposal_step_m = 0.02;
    return o;
}

Quat axis_angle(Vec3 axis, double angle) {
    const auto n = normalized(axis);
    CHECK_TRUE(n.has_value());
    const double s = std::sin(angle * 0.5);
    return {n->x*s, n->y*s, n->z*s, std::cos(angle*0.5)};
}


RestGuide catalog_rest() {
    RestGuide r;
    r.guide_id = 1; r.source_revision = 1;
    for (Id i = 0; i < 9; ++i) {
        r.node_ids.push_back(100 + i);
        r.nodes.push_back(Vec3{-0.2, 0.075 * static_cast<double>(i), 0.0});
        r.material_frames.push_back(Quat{-0.7071067811865476, 0, 0, 0.7071067811865476});
        if (i < 8) {
            r.span_ids.push_back(200 + i);
            r.span_radius_m.push_back(0.015);
            r.max_bound_offset_m.push_back(0.015);
        }
    }
    return r;
}

GuidePose rest_pose(const RestGuide& r) { return GuidePose{r.guide_id, r.nodes, r.material_frames}; }

GuidePose authored_pose() {
    GuidePose p;
    p.guide_id = 1;
    const Quat q{-0.6532814824381883, -0.2705980500730985, 0.2705980500730985, 0.6532814824381883};
    for (int i = 0; i < 9; ++i) {
        p.nodes.push_back(Vec3{-0.2 - 0.053033008588991064 * i, 0.053033008588991064 * i, 0});
        p.material_frames.push_back(q);
    }
    return p;
}

PreparedRibbon catalog_source() {
    PreparedRibbon s;
    s.source_id = 10; s.source_revision = 1;
    for (std::size_t row = 0; row < 9; ++row) {
        const Id span = row == 8 ? 207 : 200 + row;
        const double u = row == 8 ? 1.0 : 0.0;
        const double y = 0.075 * static_cast<double>(row);
        for (int side = 0; side < 2; ++side) {
            const double xoff = side == 0 ? -0.015 : 0.015;
            s.rest_positions.push_back(Vec3{-0.2 + xoff, y, 0});
            const Id id = 1000 + static_cast<Id>(row*2 + static_cast<std::size_t>(side));
            s.bindings.push_back(BoundVertex{id, id, span, u, Vec3{xoff,0,0}, UV{static_cast<double>(side), static_cast<double>(row)/8.0}});
        }
    }
    for (std::uint32_t row = 0; row < 8; ++row) {
        const std::uint32_t a = row*2;
        s.triangles.push_back({a,a+1,a+2});
        s.triangles.push_back({a+1,a+3,a+2});
        s.face_material_ids.push_back(0);
        s.face_material_ids.push_back(0);
    }
    return s;
}

SceneSnapshot sphere_snapshot() {
    SceneSnapshot s; s.generation = 1;
    Obstacle o; o.id=900; o.geometry_revision=1; o.pose_revision=1; o.kind=ObstacleKind::Sphere;
    o.center={0,0.2,0}; o.orientation={0,0,0,1}; o.sphere_radius=0.25;
    s.obstacles.push_back(o);
    return s;
}

SceneSnapshot empty_snapshot() { SceneSnapshot s; s.generation=1; return s; }

RestGuide z_guide(Vec3 root, Vec3 tip, double radius, Id guide_id=2, std::uint64_t revision=2) {
    RestGuide r;
    r.guide_id=guide_id; r.source_revision=revision;
    r.node_ids={100,101}; r.span_ids={200}; r.nodes={root,tip};
    r.material_frames={{0,0,0,1},{0,0,0,1}};
    r.span_radius_m={radius}; r.max_bound_offset_m={radius};
    return r;
}

PreparedRibbon source_from_bindings(const RestGuide& r, std::vector<BoundVertex> bindings,
                                    std::vector<std::array<std::uint32_t,3>> triangles,
                                    std::vector<std::uint32_t> materials, Id source_id=20) {
    PreparedRibbon s; s.source_id=source_id; s.source_revision=r.source_revision;
    s.bindings=std::move(bindings); s.triangles=std::move(triangles); s.face_material_ids=std::move(materials);
    for (const BoundVertex& b : s.bindings) {
        const auto idx = span_index(r,b.span_id); CHECK_TRUE(idx.has_value());
        const auto q = shortest_slerp(r.material_frames[*idx],r.material_frames[*idx+1],b.material_u); CHECK_TRUE(q.has_value());
        const Vec3 c=add(mul(r.nodes[*idx],1.0-b.material_u),mul(r.nodes[*idx+1],b.material_u));
        s.rest_positions.push_back(add(c,rotate(*q,b.rest_local_offset)));
    }
    return s;
}

EvaluatedMesh eval_ok(const PreparedRibbon& s, const RestGuide& r, const GuidePose& p) {
    const auto e=evaluate_ribbon(s,r,p,limits(),tolerances(),{});
    if (e.outcome != Outcome::Ok) {
        std::ostringstream os; os << "evaluate_ribbon failed with outcome " << static_cast<int>(e.outcome);
        for (const auto& issue:e.issues) os << " [" << issue.code << ']';
        throw Failure(os.str());
    }
    return e.mesh;
}

void expect_pass(const SceneSnapshot& snap,const PreparedRibbon& s,const RestGuide& r,const GuidePose& p,const EvaluatedMesh& m,SolveOptions o=options()) {
    const auto v=validate_candidate(snap,s,r,p,m,o,{});
    if (v.status != ValidationStatus::Pass) {
        std::ostringstream os; os << "expected Pass, got " << static_cast<int>(v.status);
        for (const auto& issue:v.issues) os << " [" << issue.code << ":" << issue.message << ']';
        throw Failure(os.str());
    }
}

void test_clear_rest_evaluator() {
    const auto r=catalog_rest(); const auto s=catalog_source(); const auto p=rest_pose(r);
    const auto e=evaluate_ribbon(s,r,p,limits(),tolerances(),{});
    CHECK_EQ(e.outcome,Outcome::Ok); CHECK_EQ(e.mesh.positions.size(),s.rest_positions.size());
    CHECK_EQ(e.mesh.uvs.size(),s.bindings.size()); CHECK_TRUE(e.mesh.triangles==s.triangles);
    for(std::size_t i=0;i<s.rest_positions.size();++i) CHECK_NEAR(distance(e.mesh.positions[i],s.rest_positions[i]),0,1e-12);
    CHECK_TRUE(finite(e.mesh.bounds_min)&&finite(e.mesh.bounds_max));
    for(Vec3 n:e.mesh.normals) CHECK_NEAR(length(n),1.0,1e-12);
}

void test_authored_feasible_pass() {
    const auto r=catalog_rest(); const auto s=catalog_source(); const auto p=authored_pose();
    const auto m=eval_ok(s,r,p); expect_pass(sphere_snapshot(),s,r,p,m);
}

void test_longitudinal_offset() {
    auto r=z_guide({0,0,0},{0,0,1},0.25);
    std::vector<BoundVertex> b{
        {1,1,200,0.25,{-0.1,0,0.02},{0,0}},
        {2,2,200,0.25,{ 0.1,0,0.02},{1,0}},
        {3,3,200,0.75,{-0.1,0,-0.03},{0,1}},
        {4,4,200,0.75,{ 0.1,0,-0.03},{1,1}}
    };
    auto s=source_from_bindings(r,b,{{0,1,2},{1,3,2}},{0,0});
    GuidePose p=rest_pose(r); p.material_frames={axis_angle({0,0,1},0.5),axis_angle({0,0,1},0.5)};
    auto m=eval_ok(s,r,p);
    CHECK_NEAR(m.positions[0].z,0.27,1e-12); // center z=.25 plus longitudinal +.02
    expect_pass(empty_snapshot(),s,r,p,m);
}

void test_seam_ids_and_uvs() {
    auto r=z_guide({0,0,0},{0,0,1},0.2);
    std::vector<BoundVertex> b{
        {10,1,200,0.2,{-0.1,0,0},{0,0}}, {11,2,200,0.2,{0.1,0,0},{1,0}}, {12,3,200,0.8,{-0.1,0,0},{0,1}},
        {13,1,200,0.2,{-0.1,0,0},{0.25,0}}, {14,2,200,0.2,{0.1,0,0},{0.75,0}}, {15,3,200,0.8,{-0.1,0,0},{0.25,1}}
    };
    auto s=source_from_bindings(r,b,{{0,1,2},{3,4,5}},{0,1});
    auto m=eval_ok(s,r,rest_pose(r));
    CHECK_EQ(m.positions.size(),6U); CHECK_NEAR(distance(m.positions[0],m.positions[3]),0,1e-12);
    CHECK_TRUE(m.uvs[0].u!=m.uvs[3].u); expect_pass(empty_snapshot(),s,r,rest_pose(r),m);
}

void test_quaternion_sign_invariance() {
    auto r=catalog_rest(); auto s=catalog_source(); auto p=rest_pose(r);
    const auto base=eval_ok(s,r,p);
    for(std::size_t i=1;i<r.material_frames.size();i+=2) r.material_frames[i]=quat_negate(r.material_frames[i]);
    for(std::size_t i=0;i<p.material_frames.size();i+=2) p.material_frames[i]=quat_negate(p.material_frames[i]);
    const auto signed_mesh=eval_ok(s,r,p);
    for(std::size_t i=0;i<base.positions.size();++i) CHECK_NEAR(distance(base.positions[i],signed_mesh.positions[i]),0,1e-12);
}

void test_unsupported_full_turn() {
    auto r=catalog_rest(); r.requires_full_turn_twist=true;
    const auto e=evaluate_ribbon(catalog_source(),r,rest_pose(r),limits(),tolerances(),{});
    CHECK_EQ(e.outcome,Outcome::Unsupported); CHECK_TRUE(e.mesh.positions.empty()); CHECK_TRUE(has_issue(e.issues,"unsupported_full_turn"));
}

void test_ambiguous_pi_frame() {
    auto r=z_guide({0,0,0},{0,0,1},0.2);
    r.material_frames[1]=axis_angle({0,0,1},kPi);
    std::vector<BoundVertex> b{{1,1,200,0,{-0.1,0,0},{0,0}},{2,2,200,0,{0.1,0,0},{1,0}},{3,3,200,1,{-0.1,0,0},{0,1}}};
    auto s=source_from_bindings(z_guide({0,0,0},{0,0,1},0.2),b,{{0,1,2}},{0});
    const auto e=evaluate_ribbon(s,r,rest_pose(r),limits(),tolerances(),{});
    CHECK_EQ(e.outcome,Outcome::Ambiguous); CHECK_TRUE(e.mesh.positions.empty());
}

void test_evaluator_cancellation_and_limits() {
    std::atomic_bool flag=true; const Cancellation c{&flag};
    const auto r=catalog_rest(); const auto s=catalog_source();
    auto e=evaluate_ribbon(s,r,rest_pose(r),limits(),tolerances(),c); CHECK_EQ(e.outcome,Outcome::Cancelled); CHECK_TRUE(e.mesh.positions.empty());
    auto l=limits(); l.max_render_vertices=1;
    e=evaluate_ribbon(s,r,rest_pose(r),l,tolerances(),{}); CHECK_EQ(e.outcome,Outcome::ResourceLimit); CHECK_TRUE(e.mesh.positions.empty());
    l=limits(); l.max_owned_and_scratch_bytes=64;
    e=evaluate_ribbon(s,r,rest_pose(r),l,tolerances(),{}); CHECK_EQ(e.outcome,Outcome::ResourceLimit);
}

void test_evaluator_bad_inputs() {
    auto r=catalog_rest(); auto s=catalog_source(); auto p=rest_pose(r);
    s.rest_positions[0].x+=1e-4;
    auto e=evaluate_ribbon(s,r,p,limits(),tolerances(),{}); CHECK_EQ(e.outcome,Outcome::InvalidInput); CHECK_TRUE(e.mesh.positions.empty());
    s=catalog_source(); s.source_revision=2;
    e=evaluate_ribbon(s,r,p,limits(),tolerances(),{}); CHECK_EQ(e.outcome,Outcome::InvalidInput);
    s=catalog_source(); r.span_radius_m[0]=0.001;
    e=evaluate_ribbon(s,r,p,limits(),tolerances(),{}); CHECK_EQ(e.outcome,Outcome::InvalidInput); CHECK_TRUE(has_issue(e.issues,"radius_below_declared_bound"));
    r=catalog_rest(); s=catalog_source(); s.triangles[0]={0,0,2};
    e=evaluate_ribbon(s,r,p,limits(),tolerances(),{}); CHECK_EQ(e.outcome,Outcome::InvalidInput);
    r=catalog_rest(); s=catalog_source(); s.bindings[0].rest_local_offset.x=std::numeric_limits<double>::infinity();
    e=evaluate_ribbon(s,r,p,limits(),tolerances(),{}); CHECK_EQ(e.outcome,Outcome::InvalidInput); CHECK_TRUE(e.mesh.positions.empty());
}

void test_clear_validator() {
    const auto r=catalog_rest(); const auto s=catalog_source(); const auto p=rest_pose(r); const auto m=eval_ok(s,r,p);
    const auto v=validate_candidate(empty_snapshot(),s,r,p,m,options(),{});
    CHECK_EQ(v.status,ValidationStatus::Pass); CHECK_EQ(v.generation,1U); CHECK_NEAR(v.max_root_error_m,0,1e-15); CHECK_NEAR(v.rest_reconstruction_error_m,0,1e-12);
}

void test_root_and_length_failures() {
    auto r=catalog_rest(); auto s=catalog_source(); auto p=rest_pose(r);
    for (Vec3& node : p.nodes) node.x += 1e-3; // preserve tangents while moving the planted root
    auto m=eval_ok(s,r,p);
    auto v=validate_candidate(empty_snapshot(),s,r,p,m,options(),{}); CHECK_EQ(v.status,ValidationStatus::Fail); CHECK_TRUE(has_issue(v.issues,"root_position_violation"));
    p=rest_pose(r);
    for (std::size_t i=1;i<p.nodes.size();++i) p.nodes[i].y = r.nodes[0].y + 1.1 * (r.nodes[i].y-r.nodes[0].y); // valid tangent, wrong lengths
    m=eval_ok(s,r,p);
    v=validate_candidate(empty_snapshot(),s,r,p,m,options(),{}); CHECK_EQ(v.status,ValidationStatus::Fail); CHECK_TRUE(has_issue(v.issues,"span_length_violation"));
}

void test_frame_and_revision_failures() {
    auto r=catalog_rest(); auto s=catalog_source(); auto p=rest_pose(r); auto m=eval_ok(s,r,p);
    p.material_frames[0]={0,0,0,1};
    auto v=validate_candidate(empty_snapshot(),s,r,p,m,options(),{}); CHECK_EQ(v.status,ValidationStatus::Fail); CHECK_TRUE(has_issue(v.issues,"pose_frame_tangent_mismatch"));
    m=eval_ok(s,r,rest_pose(r)); m.source_revision=99;
    v=validate_candidate(empty_snapshot(),s,r,rest_pose(r),m,options(),{}); CHECK_EQ(v.status,ValidationStatus::Fail); CHECK_TRUE(has_issue(v.issues,"mesh_source_identity_mismatch"));
}

void test_mesh_correspondence_failures() {
    const auto r=catalog_rest(); const auto s=catalog_source(); const auto p=rest_pose(r); const auto base=eval_ok(s,r,p);
    auto m=base; std::swap(m.triangles[0][0],m.triangles[0][1]);
    auto v=validate_candidate(empty_snapshot(),s,r,p,m,options(),{}); CHECK_EQ(v.status,ValidationStatus::Fail); CHECK_TRUE(has_issue(v.issues,"mesh_topology_mismatch"));
    m=base; m.uvs[0].u+=0.1;
    v=validate_candidate(empty_snapshot(),s,r,p,m,options(),{}); CHECK_EQ(v.status,ValidationStatus::Fail); CHECK_TRUE(has_issue(v.issues,"mesh_uv_mismatch"));
    m=base; m.bounds_max.x+=0.1;
    v=validate_candidate(empty_snapshot(),s,r,p,m,options(),{}); CHECK_EQ(v.status,ValidationStatus::Fail); CHECK_TRUE(has_issue(v.issues,"mesh_bounds_mismatch"));
    m=base; m.face_material_ids[0]=99;
    v=validate_candidate(empty_snapshot(),s,r,p,m,options(),{}); CHECK_EQ(v.status,ValidationStatus::Fail); CHECK_TRUE(has_issue(v.issues,"mesh_material_mismatch"));
    m=base; for (Vec3& position : m.positions) position.x += 0.001; m.bounds_min.x += 0.001; m.bounds_max.x += 0.001;
    v=validate_candidate(empty_snapshot(),s,r,p,m,options(),{}); CHECK_EQ(v.status,ValidationStatus::Fail); CHECK_TRUE(has_issue(v.issues,"mesh_pose_correspondence"));
    m=base; m.normals[0]=mul(m.normals[0],-1);
    v=validate_candidate(empty_snapshot(),s,r,p,m,options(),{}); CHECK_EQ(v.status,ValidationStatus::Fail); CHECK_TRUE(has_issue(v.issues,"mesh_normal_mismatch"));
}

void test_root_modes() {
    const auto r=catalog_rest(); const auto s=catalog_source();
    const auto restm=eval_ok(s,r,rest_pose(r)); expect_pass(empty_snapshot(),s,r,rest_pose(r),restm,options(RootMode::ClampFrame));
    const auto p=authored_pose(); const auto m=eval_ok(s,r,p);
    auto v=validate_candidate(sphere_snapshot(),s,r,p,m,options(RootMode::ClampFrame),{}); CHECK_EQ(v.status,ValidationStatus::Fail); CHECK_TRUE(has_issue(v.issues,"clamp_root_frame_violation"));
    expect_pass(sphere_snapshot(),s,r,p,m,options(RootMode::SoftFrame));
}

RestGuide wide_guide(double radius) {
    RestGuide r=z_guide({1.1,-0.4,0},{1.1,0.4,0},radius,30,3);
    const Quat q{-0.7071067811865476,0,0,0.7071067811865476};
    r.material_frames={q,q};
    return r;
}

PreparedRibbon wide_ribbon(const RestGuide& r,double half_width) {
    std::vector<BoundVertex> b{{1,1,200,0,{-half_width,0,0},{0,0}},{2,2,200,0,{half_width,0,0},{1,0}},
                               {3,3,200,1,{-half_width,0,0},{0,1}},{4,4,200,1,{half_width,0,0},{1,1}}};
    return source_from_bindings(r,b,{{0,1,2},{1,3,2}},{0,0},31);
}

SceneSnapshot origin_sphere(double radius=1.0) {
    SceneSnapshot s; s.generation=5; Obstacle o; o.id=1;o.geometry_revision=1;o.pose_revision=1;o.kind=ObstacleKind::Sphere;o.center={0,0,0};o.orientation={0,0,0,1};o.sphere_radius=radius;s.obstacles={o};return s;
}


void test_root_contained_obstacle() {
    const auto r=catalog_rest(); const auto s=catalog_source(); const auto p=rest_pose(r); const auto m=eval_ok(s,r,p);
    SceneSnapshot snap; snap.generation=9; Obstacle o; o.id=90;o.geometry_revision=1;o.pose_revision=1;o.kind=ObstacleKind::Sphere;
    o.center=r.nodes.front();o.orientation={0,0,0,1};o.sphere_radius=0.05;snap.obstacles={o};
    auto v=validate_candidate(snap,s,r,p,m,options(),{});CHECK_EQ(v.status,ValidationStatus::Fail);CHECK_TRUE(has_issue(v.issues,"root_envelope_conflict"));
}

void test_invalid_envelope_and_visible_width() {
    auto invalid=wide_guide(0.01); invalid.max_bound_offset_m[0]=0.15;
    auto invalid_source=wide_ribbon(invalid,0.15);
    auto e=evaluate_ribbon(invalid_source,invalid,rest_pose(invalid),limits(),tolerances(),{});
    CHECK_EQ(e.outcome,Outcome::InvalidInput); CHECK_TRUE(has_issue(e.issues,"radius_below_declared_bound"));

    auto valid=wide_guide(0.15); auto source=wide_ribbon(valid,0.15); auto pose=rest_pose(valid); auto mesh=eval_ok(source,valid,pose);
    CHECK_TRUE(distance(Vec3{1.1,0,0},Vec3{0,0,0})-1.0-0.01>0.0); // guide capsule of radius .01 is clear
    auto o=options(); o.clearance_m=0;
    auto v=validate_candidate(origin_sphere(),source,valid,pose,mesh,o,{});
    CHECK_EQ(v.status,ValidationStatus::Fail); CHECK_TRUE(has_issue(v.issues,"visible_sphere_penetration")); CHECK_TRUE(v.max_visible_penetration_m>0.049);
}

PreparedRibbon planar_triangle_source(RestGuide& r,const std::array<Vec3,3>& offsets,double radius,Id source_id=40) {
    r.span_radius_m[0]=radius; r.max_bound_offset_m[0]=radius;
    std::vector<BoundVertex> b;
    for(std::size_t i=0;i<3;++i) b.push_back(BoundVertex{100+i,100+i,200,0.5,offsets[i],UV{static_cast<double>(i),0}});
    return source_from_bindings(r,b,{{0,1,2}},{0},source_id);
}

SceneSnapshot box_snapshot(Vec3 center,Vec3 half,Quat orientation,Id id=2) {
    SceneSnapshot s;s.generation=7;Obstacle o;o.id=id;o.geometry_revision=1;o.pose_revision=1;o.kind=ObstacleKind::Box;o.center=center;o.orientation=orientation;o.box_half_extents=half;s.obstacles={o};return s;
}

void test_large_triangle_sphere_and_box() {
    auto r=z_guide({0,0,-10},{0,0,10},3.0,40,4);
    const std::array<Vec3,3> offsets{Vec3{-2,-2,0},Vec3{2,-2,0},Vec3{0,2,0}};
    auto s=planar_triangle_source(r,offsets,3.0); auto p=rest_pose(r); auto m=eval_ok(s,r,p);
    for(Vec3 v:m.positions) { CHECK_TRUE(length(v)>0.5); CHECK_TRUE(std::abs(v.x)>0.5 || std::abs(v.y)>0.5 || std::abs(v.z)>0.5); }
    auto o=options();o.clearance_m=0;
    auto v=validate_candidate(origin_sphere(0.5),s,r,p,m,o,{});CHECK_EQ(v.status,ValidationStatus::Fail);CHECK_TRUE(has_issue(v.issues,"visible_sphere_penetration"));
    v=validate_candidate(box_snapshot({0,0,0},{0.5,0.5,0.5},{0,0,0,1}),s,r,p,m,o,{});CHECK_EQ(v.status,ValidationStatus::Fail);CHECK_TRUE(has_issue(v.issues,"visible_box_overlap"));
}

void test_containment_and_rotated_box() {
    auto r=z_guide({0,0,-5},{0,0,5},0.3,41,5);
    auto s=planar_triangle_source(r,{Vec3{-0.1,-0.1,0},Vec3{0.1,-0.1,0},Vec3{0,0.1,0}},0.3,41);
    auto p=rest_pose(r);auto m=eval_ok(s,r,p);auto o=options();o.clearance_m=0;
    auto v=validate_candidate(origin_sphere(1),s,r,p,m,o,{});CHECK_EQ(v.status,ValidationStatus::Fail);
    v=validate_candidate(box_snapshot({0,0,0},{1,1,1},axis_angle({0,1,0},0.7)),s,r,p,m,o,{});CHECK_EQ(v.status,ValidationStatus::Fail);CHECK_TRUE(has_issue(v.issues,"visible_box_overlap"));
}

void test_box_clear_control_and_two_obstacles() {
    auto r=z_guide({0,0,-5},{0,0,5},0.3,42,6);
    auto s=planar_triangle_source(r,{Vec3{-0.1,-0.1,0},Vec3{0.1,-0.1,0},Vec3{0,0.1,0}},0.3,42);
    auto p=rest_pose(r);auto m=eval_ok(s,r,p);auto o=options();o.clearance_m=0;
    expect_pass(box_snapshot({5,0,0},{0.5,0.5,0.5},axis_angle({0,1,0},0.8)),s,r,p,m,o);
    auto snap=box_snapshot({5,0,0},{0.5,0.5,0.5},{0,0,0,1},10);
    snap.obstacles.push_back(origin_sphere(0.5).obstacles[0]);snap.obstacles.back().id=11;
    auto v=validate_candidate(snap,s,r,p,m,o,{});CHECK_EQ(v.status,ValidationStatus::Fail);CHECK_TRUE(has_issue(v.issues,"visible_sphere_penetration"));
}

void test_cancellation_and_resource_validator() {
    const auto r=catalog_rest();const auto s=catalog_source();const auto p=rest_pose(r);const auto m=eval_ok(s,r,p);
    std::atomic_bool f=true;auto v=validate_candidate(empty_snapshot(),s,r,p,m,options(),Cancellation{&f});CHECK_EQ(v.status,ValidationStatus::Cancelled);
    auto o=options();o.limits.max_query_calls=1;
    v=validate_candidate(sphere_snapshot(),s,r,p,m,o,{});CHECK_EQ(v.status,ValidationStatus::ResourceLimit);CHECK_TRUE(has_issue(v.issues,"visible_pair_budget"));
}

void test_large_coordinate_control() {
    auto r=z_guide({1e6,0,-5},{1e6,0,5},0.3,43,7);
    auto s=planar_triangle_source(r,{Vec3{-0.1,-0.1,0},Vec3{0.1,-0.1,0},Vec3{0,0.1,0}},0.3,43);
    auto p=rest_pose(r);auto m=eval_ok(s,r,p);auto snap=box_snapshot({1e6+5,0,0},{0.5,0.5,0.5},{0,0,0,1});
    auto o=options();o.clearance_m=0;expect_pass(snap,s,r,p,m,o);
}

void test_triangle_math_direct() {
    const Vec3 c{0,0,0};const Vec3 a{-2,-2,0},b{2,-2,0},d{0,2,0};
    CHECK_NEAR(point_triangle_distance_sq(c,a,b,d),0,1e-15);
    const std::array<Vec3,3> tri{a,b,d};const auto hit=triangle_aabb_sat(tri,{0.5,0.5,0.5});CHECK_TRUE(hit.overlaps);
    const auto clear=triangle_aabb_sat({Vec3{2,2,2},Vec3{3,2,2},Vec3{2,3,2}},{0.5,0.5,0.5});CHECK_TRUE(!clear.overlaps);
}

void test_obj_diagnostic() {
    const auto r=catalog_rest();const auto s=catalog_source();const auto m=eval_ok(s,r,rest_pose(r));
    const auto path=std::filesystem::temp_directory_path()/"cyrus_delivery_diagnostic.obj";std::string error;
    CHECK_TRUE(write_diagnostic_obj(m,path,error));CHECK_TRUE(std::filesystem::file_size(path)>0);std::filesystem::remove(path);
}

struct Test { const char* suite; const char* name; void (*fn)(); };
const std::vector<Test> tests{
    {"evaluator","clear_rest",test_clear_rest_evaluator},
    {"evaluator","authored_feasible",test_authored_feasible_pass},
    {"evaluator","longitudinal_offset",test_longitudinal_offset},
    {"evaluator","seam_ids_uvs",test_seam_ids_and_uvs},
    {"evaluator","quaternion_sign",test_quaternion_sign_invariance},
    {"evaluator","unsupported_full_turn",test_unsupported_full_turn},
    {"evaluator","ambiguous_pi",test_ambiguous_pi_frame},
    {"evaluator","cancel_limits",test_evaluator_cancellation_and_limits},
    {"evaluator","bad_inputs",test_evaluator_bad_inputs},
    {"validator","clear_control",test_clear_validator},
    {"validator","root_length",test_root_and_length_failures},
    {"validator","frame_revision",test_frame_and_revision_failures},
    {"validator","mesh_correspondence",test_mesh_correspondence_failures},
    {"validator","root_modes",test_root_modes},
    {"adversarial","root_contained",test_root_contained_obstacle},
    {"adversarial","invalid_envelope_visible_width",test_invalid_envelope_and_visible_width},
    {"adversarial","large_triangle_sphere_box",test_large_triangle_sphere_and_box},
    {"adversarial","containment_rotated_box",test_containment_and_rotated_box},
    {"adversarial","box_clear_two_obstacles",test_box_clear_control_and_two_obstacles},
    {"adversarial","cancel_resource",test_cancellation_and_resource_validator},
    {"adversarial","large_coordinates",test_large_coordinate_control},
    {"contract","triangle_math",test_triangle_math_direct},
    {"contract","diagnostic_obj",test_obj_diagnostic},
};

} // namespace

int main(int argc,char** argv) {
    const std::string filter=argc>1?argv[1]:"all";
    std::size_t run=0,failed=0;
    for(const Test& t:tests) {
        if(filter!="all"&&filter!=t.suite) continue;
        ++run;
        try { t.fn(); std::cout<<"PASS "<<t.suite<<'.'<<t.name<<'\n'; }
        catch(const std::exception& e) { ++failed; std::cerr<<"FAIL "<<t.suite<<'.'<<t.name<<": "<<e.what()<<'\n'; }
        catch(...) { ++failed; std::cerr<<"FAIL "<<t.suite<<'.'<<t.name<<": unknown exception\n"; }
    }
    std::cout<<"SUMMARY suite="<<filter<<" run="<<run<<" failed="<<failed<<'\n';
    return failed==0?0:1;
}
