// Coordinator checks: actual A -> B -> C, plus independent admission/slerp controls.
// No Max calls, publication, or claim about production renderer geometry.
#include <cyrus_vegetation/prototype_v1.hpp>
#include "catalog_fixture.hpp"
#include "../abc-starter/delivery/src/diagnostic_obj.hpp"
#include <algorithm>
#include <cmath>
#include <cstdlib>
#include <fstream>
#include <functional>
#include <iomanip>
#include <iostream>
#include <limits>
#include <map>
#include <new>
#include <stdexcept>
#include <string>

namespace v = cyrus::vegetation::prototype_v1;
// Test-only observation of ordinary unaligned C++ allocation requests. This is
// not a process-memory measurement, nor instrumentation of A's native allocator.
thread_local bool observe_new_requests=false;
thread_local std::size_t largest_new_request=0;
void* operator new(std::size_t n) {
    if(observe_new_requests&&n>largest_new_request)largest_new_request=n;
    if(void* p=std::malloc(n?n:1))return p;
    throw std::bad_alloc{};
}
void operator delete(void* p) noexcept {std::free(p);}
void operator delete(void* p,std::size_t) noexcept {std::free(p);}
void require(bool condition,const char* message) {if(!condition)throw std::runtime_error(message);}
v::GuidePose rest_pose(const v::RestGuide& g) {return {g.guide_id,g.nodes,g.material_frames};}
void print_validation(const std::string& label,const v::ValidationResult& r) {
    std::cout<<std::setprecision(17)<<"{\"fixture\":\""<<label<<"\",\"validation_status\":"<<int(r.status)
        <<",\"generation\":"<<r.generation<<",\"root_error_m\":"<<r.max_root_error_m
        <<",\"relative_length_error\":"<<r.max_relative_length_error
        <<",\"visible_penetration_m\":"<<r.max_visible_penetration_m
        <<",\"rest_reconstruction_error_m\":"<<r.rest_reconstruction_error_m<<",\"issues\":[";
    for(std::size_t i=0;i<r.issues.size();++i){if(i)std::cout<<',';std::cout<<'"'<<r.issues[i].code<<'"';}
    std::cout<<"]}\n";
}
v::EvaluatedMesh evaluate(const v::PreparedRibbon& source,const v::RestGuide& rest,const v::GuidePose& pose,const v::SolveOptions& options) {
    auto e=v::evaluate_ribbon(source,rest,pose,options.limits,options.tolerances,{});
    std::cout<<"{\"evaluation_outcome\":"<<int(e.outcome)<<",\"vertices\":"<<e.mesh.positions.size()<<",\"triangles\":"<<e.mesh.triangles.size()<<"}\n";
    if(e.outcome!=v::Outcome::Ok)for(const auto& issue:e.issues)std::cerr<<issue.code<<": "<<issue.message<<'\n';
    require(e.outcome==v::Outcome::Ok,"C evaluator rejected valid prepared data");return std::move(e.mesh);
}
v::SolveResult fit(const v::RestGuide& rest,const v::SceneSnapshot& scene,const v::SolveOptions& options) {
    v::BackendOptions backend;backend.limits=options.limits;backend.query_tolerance_m=1e-6;backend.min_supported_feature_m=.001;
    auto a=v::make_jolt_world(scene,backend,{});require(a.outcome==v::Outcome::Ok&&bool(a.world),"A world failed");
    require(a.world->generation()==scene.generation,"A generation mismatch");
    auto b=v::fit_rooted_guide(rest,scene.generation,*a.world,options,{});
    std::cout<<std::setprecision(17)<<"{\"solve_status\":"<<int(b.status)<<",\"iterations\":"<<b.metrics.iterations
        <<",\"queries\":"<<b.metrics.query_calls<<",\"capsule_penetration_m\":";
    if(std::isfinite(b.metrics.max_penetration_m))std::cout<<b.metrics.max_penetration_m;else std::cout<<"null";
    std::cout<<"}\n";
    return b;
}
void validate_pass(const std::string& label,const v::SceneSnapshot& scene,const v::PreparedRibbon& source,const v::RestGuide& rest,const v::GuidePose& pose,const v::EvaluatedMesh& mesh,const v::SolveOptions& options) {
    auto c=v::validate_candidate(scene,source,rest,pose,mesh,options,{});print_validation(label,c);
    require(c.status==v::ValidationStatus::Pass,"C did not independently validate visible mesh");
    require(c.generation==scene.generation,"C generation mismatch");
}
v::EvaluatedMesh pipeline(const std::string& label,const v::RestGuide& g,const v::PreparedRibbon& source,const v::SceneSnapshot& scene,const v::SolveOptions& o) {
    auto b=fit(g,scene,o);require(b.status==v::SolveStatus::ConvergedCandidate,"B did not return candidate");
    require(b.generation==scene.generation&&b.source_revision==source.source_revision&&g.source_revision==source.source_revision,"coordinator identity gate failed");
    auto mesh=evaluate(source,g,b.pose,o);validate_pass(label,scene,source,g,b.pose,mesh,o);return mesh;
}
void catalog() {
    auto mesh=pipeline("fresh_A_B_C_catalog",catalog_rest(),catalog_source(),catalog_scene(),catalog_options());
    std::string error;require(v::delivery_detail::write_diagnostic_obj(mesh,"catalog-validated.obj",error),"diagnostic OBJ write failed");
    std::ofstream file("catalog-visible-mesh.json");file<<std::setprecision(17);
    file<<"{\"scope\":\"A+B+C headless visible primitive fixture; no Max render/Bake\",\"source_id\":"<<mesh.source_id<<",\"source_revision\":"<<mesh.source_revision<<",\"positions\":[";
    for(std::size_t i=0;i<mesh.positions.size();++i){if(i)file<<',';auto p=mesh.positions[i];file<<'['<<p.x<<','<<p.y<<','<<p.z<<']';}
    file<<"],\"triangles\":[";
    for(std::size_t i=0;i<mesh.triangles.size();++i){if(i)file<<',';auto t=mesh.triangles[i];file<<'['<<t[0]<<','<<t[1]<<','<<t[2]<<']';}
    file<<"]}\n";require(bool(file),"diagnostic mesh JSON write failed");
}
void stored() {
    auto g=catalog_rest();auto source=catalog_source();auto o=catalog_options();
    auto mesh=evaluate(source,g,stored_candidate(),o);validate_pass("stored_AB_candidate_C",catalog_scene(),source,g,stored_candidate(),mesh,o);
}
void clear() {auto scene=catalog_scene();scene.obstacles.clear();pipeline("clear_A_B_C",catalog_rest(),catalog_source(),scene,catalog_options());}
void unfit() {
    auto g=catalog_rest();auto source=catalog_source();auto o=catalog_options();auto p=rest_pose(g);auto mesh=evaluate(source,g,p,o);
    auto c=v::validate_candidate(catalog_scene(),source,g,p,mesh,o,{});print_validation("unfit_ribbon_must_fail",c);
    require(c.status==v::ValidationStatus::Fail,"unfit stone overlap accepted");
}
void corrupt() {
    auto g=catalog_rest();auto source=catalog_source();auto o=catalog_options();auto pose=stored_candidate();auto mesh=evaluate(source,g,pose,o);
    // Perturb an interior vertex inside the existing bounds; metadata alone cannot certify its pose.
    mesh.positions[8].x+=.001;
    auto c=v::validate_candidate(catalog_scene(),source,g,pose,mesh,o,{});print_validation("corrupt_visible_mesh",c);
    require(c.status==v::ValidationStatus::Fail,"corrupt mesh accepted");
}
void root_conflict() {
    auto g=catalog_rest();auto scene=catalog_scene();scene.obstacles[0].center=g.nodes[0];
    auto b=fit(g,scene,catalog_options());require(b.status==v::SolveStatus::RootConflict,"B accepted contained root");
}
v::RestGuide straight(std::size_t n,double x) {
    auto g=catalog_rest();g.nodes.clear();g.node_ids.clear();g.span_ids.clear();g.material_frames.clear();g.span_radius_m.clear();g.max_bound_offset_m.clear();
    for(std::size_t i=0;i<n;++i){g.nodes.push_back({x,.075*double(i),0});g.node_ids.push_back(100+i);g.material_frames.push_back({-.7071067811865476,0,0,.7071067811865476});if(i+1<n){g.span_ids.push_back(200+i);g.span_radius_m.push_back(.015);g.max_bound_offset_m.push_back(.015);}}
    return g;
}
v::PreparedRibbon ribbon(const v::RestGuide& g) {
    v::PreparedRibbon s;s.source_id=10;s.source_revision=g.source_revision;
    for(std::size_t i=0;i<g.nodes.size();++i)for(std::size_t side=0;side<2;++side) {
        const double x=side?.015:-.015;auto p=g.nodes[i];s.rest_positions.push_back({p.x+x,p.y,p.z});
        const auto span=std::min(i,g.span_ids.size()-1);const double u=i+1==g.nodes.size()?1:0;
        s.bindings.push_back({1000+2*i+side,1000+2*i+side,g.span_ids[span],u,{x,0,0},{double(side),double(i)/double(g.nodes.size()-1)}});
    }
    for(std::uint32_t i=0;i+1<g.nodes.size();++i){auto a=2*i;s.triangles.push_back({a,a+1,a+2});s.triangles.push_back({a+1,a+3,a+2});s.face_material_ids.push_back(0);s.face_material_ids.push_back(0);}
    return s;
}
v::Obstacle sphere(v::Id id,v::Vec3 center,double radius) {v::Obstacle o;o.id=id;o.geometry_revision=1;o.pose_revision=1;o.center=center;o.sphere_radius=radius;return o;}
v::Obstacle box(v::Id id,v::Vec3 center,double angle) {auto o=sphere(id,center,0);o.kind=v::ObstacleKind::Box;o.box_half_extents={.28,.07,.09};o.orientation={0,0,std::sin(angle/2),std::cos(angle/2)};return o;}
void two_spheres() {auto g=straight(10,-.25);v::SceneSnapshot scene{1,{sphere(910,{0,.25,-.065},.27),sphere(911,{0,.25,.065},.27)}};pipeline("two_spheres_A_B_C",g,ribbon(g),scene,catalog_options());}
void boxes() {
    auto g=straight(10,-.25);auto source=ribbon(g);auto o=catalog_options();
    v::SceneSnapshot scene{1,{box(920,{0,.22,-.05},.18),box(921,{0,.22,.05},-.18)}};
    auto b=fit(g,scene,o);require(b.status==v::SolveStatus::ConvergedCandidate,"box fitter failed");
    auto mesh=evaluate(source,g,b.pose,o);auto c=v::validate_candidate(scene,source,g,b.pose,mesh,o,{});
    print_validation("two_rotated_boxes_A_B_C",c);
    std::ofstream out("rotated-box-evidence.json");out<<std::setprecision(17);
    out<<"{\"clearance_m\":"<<o.clearance_m<<",\"penetration_tolerance_m\":"<<o.tolerances.penetration_m<<",\"C_status\":"<<int(c.status)<<",\"positions\":[";
    for(std::size_t i=0;i<mesh.positions.size();++i){if(i)out<<',';auto p=mesh.positions[i];out<<'['<<p.x<<','<<p.y<<','<<p.z<<']';}
    out<<"],\"triangles\":[";
    for(std::size_t i=0;i<mesh.triangles.size();++i){if(i)out<<',';auto t=mesh.triangles[i];out<<'['<<t[0]<<','<<t[1]<<','<<t[2]<<']';}
    out<<"],\"obstacles\":[";
    for(std::size_t i=0;i<scene.obstacles.size();++i){if(i)out<<',';auto a=scene.obstacles[i];out<<"{\"id\":"<<a.id<<",\"center\":["<<a.center.x<<','<<a.center.y<<','<<a.center.z<<"],\"orientation\":["<<a.orientation.x<<','<<a.orientation.y<<','<<a.orientation.z<<','<<a.orientation.w<<"],\"half_extents\":["<<a.box_half_extents.x<<','<<a.box_half_extents.y<<','<<a.box_half_extents.z<<"]}";}
    out<<"]}\n";require(bool(out),"box evidence write failed");
    auto physical=o;physical.clearance_m=0;
    validate_pass("rotated_boxes_physical_surface_only",scene,source,g,b.pose,mesh,physical);
    // The frozen C contract permits conservative rejections. This candidate's
    // independent feature distance is recorded separately; do not publish it
    // when C rejects, or equate Euclidean clearance with the axis-expanded box.
    require(c.status==v::ValidationStatus::Fail,"expected conservative box rejection changed");
    require(std::any_of(c.issues.begin(),c.issues.end(),[](const v::Issue& issue){return issue.code=="visible_box_overlap";}),"rejection was not the declared conservative profile");
}
void box_guard_band() {
    auto g=straight(10,-.25);auto source=ribbon(g);auto target=catalog_options();auto solve_options=target;
    solve_options.clearance_m=.010; // Explicit experiment, not a changed artist preset or hidden fallback.
    v::SceneSnapshot scene{1,{box(920,{0,.22,-.05},.18),box(921,{0,.22,.05},-.18)}};
    auto b=fit(g,scene,solve_options);require(b.status==v::SolveStatus::ConvergedCandidate,"guard-band box fitter failed");
    require(b.generation==scene.generation&&b.source_revision==source.source_revision,"guard-band identity mismatch");
    auto mesh=evaluate(source,g,b.pose,target);validate_pass("rotated_box_10mm_solve_5mm_validation",scene,source,g,b.pose,mesh,target);
    std::cout<<"{\"experiment\":\"box_guard_band\",\"solve_clearance_m\":0.010,\"target_clearance_m\":0.005,\"production_policy\":false}\n";
}
void clamp() {auto g=straight(9,-.18);v::SceneSnapshot scene{1,{sphere(980,{0,.35,0},.22)}};auto o=catalog_options();o.root_mode=v::RootMode::ClampFrame;pipeline("clamp_A_B_C",g,ribbon(g),scene,o);}
void invalid_mode() {
    auto g=catalog_rest();auto s=catalog_source();auto o=catalog_options();auto p=rest_pose(g);auto mesh=evaluate(s,g,p,o);auto scene=catalog_scene();scene.obstacles.clear();
    o.root_mode=static_cast<v::RootMode>(99);auto c=v::validate_candidate(scene,s,g,p,mesh,o,{});print_validation("unknown_root_enum",c);
    require(c.status==v::ValidationStatus::InvalidInput||c.status==v::ValidationStatus::Unsupported,"unknown root enum accepted");
}
void nonfinite_inactive() {
    auto g=catalog_rest();auto s=catalog_source();auto o=catalog_options();auto p=rest_pose(g);auto mesh=evaluate(s,g,p,o);
    auto a=catalog_scene();a.obstacles[0].center={5,5,5};a.obstacles[0].box_half_extents.y=std::numeric_limits<double>::quiet_NaN();
    auto c1=v::validate_candidate(a,s,g,p,mesh,o,{});print_validation("sphere_inactive_nan",c1);
    a.obstacles[0].kind=v::ObstacleKind::Box;a.obstacles[0].box_half_extents={.25,.25,.25};a.obstacles[0].sphere_radius=std::numeric_limits<double>::quiet_NaN();
    auto c2=v::validate_candidate(a,s,g,p,mesh,o,{});print_validation("box_inactive_nan",c2);
    require(c1.status==v::ValidationStatus::InvalidInput&&c2.status==v::ValidationStatus::InvalidInput,"nonfinite obstacle metadata accepted");
}
void small_angle() {
    v::RestGuide g;g.guide_id=31;g.source_revision=31;g.node_ids={100,101};g.span_ids={200};g.nodes={{0,0,0},{0,0,1}};
    constexpr double twist=.0016;g.material_frames={{0,0,0,1},{0,0,std::sin(twist/2),std::cos(twist/2)}};g.span_radius_m={1};g.max_bound_offset_m={1};
    v::PreparedRibbon s;s.source_id=31;s.source_revision=31;std::size_t id=1000;
    // Straight Z guide with pure roll: exact shortest slerp is rotation by twist*u.
    for(double u:{.1,.25,.8})for(double offset:{-1.,1.}) {
        s.bindings.push_back({id,id,200,u,{offset,0,0},{offset,u}});++id;
        s.rest_positions.push_back({offset*std::cos(twist*u),offset*std::sin(twist*u),u});
    }
    s.triangles={{0,1,2},{1,3,2},{2,3,4},{3,5,4}};s.face_material_ids={0,0,0,0};
    auto o=catalog_options();o.tolerances.rest_reconstruction_m=1e-13;auto pose=rest_pose(g);
    auto mesh=evaluate(s,g,pose,o);v::SceneSnapshot empty{1,{}};
    validate_pass("small_angle_true_slerp",empty,s,g,pose,mesh,o);
}
void frame_budget() {
    v::RestGuide g;g.guide_id=71;g.source_revision=71;
    for(std::size_t i=0;i<64;++i){g.node_ids.push_back(100+i);g.nodes.push_back({0,0,double(i)});g.material_frames.push_back({0,0,0,1});if(i+1<64){g.span_ids.push_back(200+i);g.span_radius_m.push_back(.15);g.max_bound_offset_m.push_back(.15);}}
    v::PreparedRibbon s;s.source_id=71;s.source_revision=71;
    std::size_t id=1000;
    for(v::Vec3 offset: {v::Vec3{-.1,-.1,0},v::Vec3{.1,-.1,0},v::Vec3{0,.1,0}}) {
        s.bindings.push_back({id,id,200,.5,offset,{offset.x,offset.y}});++id;
        s.rest_positions.push_back({offset.x,offset.y,.5});
    }
    s.triangles={{0,1,2}};s.face_material_ids={0};auto o=catalog_options();auto p=rest_pose(g);
    auto mesh=evaluate(s,g,p,o);o.limits.max_owned_and_scratch_bytes=1000;
    largest_new_request=0;observe_new_requests=true;
    auto e=v::evaluate_ribbon(s,g,p,o.limits,o.tolerances,{});
    observe_new_requests=false;auto evaluator_largest=largest_new_request;
    largest_new_request=0;observe_new_requests=true;
    auto c=v::validate_candidate(v::SceneSnapshot{1,{}},s,g,p,mesh,o,{});
    observe_new_requests=false;auto validator_largest=largest_new_request;
    std::cout<<"{\"fixture\":\"frame_scratch_budget\",\"budget\":1000,\"evaluation_outcome\":"<<int(e.outcome)<<",\"validation_status\":"<<int(c.status)<<",\"evaluator_largest_new_request\":"<<evaluator_largest<<",\"validator_largest_new_request\":"<<validator_largest<<"}\n";
    require(e.outcome==v::Outcome::ResourceLimit&&c.status==v::ValidationStatus::ResourceLimit,"frame scratch not admitted against byte budget");
    require(evaluator_largest<=1000&&validator_largest<=1000,"over-budget frame request occurred before rejection");
}
int main(int argc,char** argv) {
    if(argc!=2)return 2;
    const std::map<std::string,std::function<void()>> cases={{"catalog",catalog},{"stored_candidate",stored},{"clear_rest",clear},{"unfit_rest",unfit},{"corrupt_mesh",corrupt},{"root_conflict",root_conflict},{"two_spheres",two_spheres},{"rotated_boxes_conservative_rejection",boxes},{"rotated_boxes_guard_band",box_guard_band},{"clamp_frame",clamp},{"invalid_root_mode",invalid_mode},{"nonfinite_inactive",nonfinite_inactive},{"small_angle",small_angle},{"frame_budget",frame_budget}};
    auto it=cases.find(argv[1]);if(it==cases.end())return 2;
    try{it->second();std::cout<<"PASS coordinator_"<<argv[1]<<'\n';return 0;}
    catch(const std::exception& e){std::cerr<<"FAIL coordinator_"<<argv[1]<<": "<<e.what()<<'\n';return 1;}
}
