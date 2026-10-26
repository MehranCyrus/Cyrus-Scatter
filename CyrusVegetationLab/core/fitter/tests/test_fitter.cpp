#include "analytic_world.hpp"
#include <cstdlib>
#include <functional>
#include <iomanip>
#include <iostream>
#include <map>
#include <sstream>
#include <string>

using namespace fitter_test;
namespace v=api;
static void check(bool x,const std::string&m){if(!x)throw std::runtime_error(m);}
#define CHECK(x) check(bool(x),std::string(__func__)+":"+std::to_string(__LINE__)+" " #x)
static v::SolveOptions options(){v::SolveOptions o;o.limits={32,64,32,20000,400,10000,20000,67108864};o.tolerances={1e-8,1e-5,.001,.001,1e-8};o.root_mode=v::RootMode::PositionOnly;o.clearance_m=.005;o.rest_shape_weight=.01;o.bend_weight=1;o.root_angle_weight=0;o.max_proposal_step_m=.02;return o;}
static v::RestGuide straight(std::size_t count=9,Vec3 base={-.2,0,0},Vec3 step={0,.075,0},double radius=.015){
 v::RestGuide g;g.guide_id=1;g.source_revision=1;for(std::size_t i=0;i<count;++i){g.node_ids.push_back(100+i);g.nodes.push_back(add(base,mul(step,double(i))));if(i+1<count){g.span_ids.push_back(200+i);g.span_radius_m.push_back(radius);g.max_bound_offset_m.push_back(radius);}}frames(g);return g;
}
static AnalyticWorld sphere_world(){AnalyticWorld w;w.spheres.push_back({900,{0,.2,0},.25});return w;}
static v::GuidePose rest_pose(const v::RestGuide&g){return {g.guide_id,g.nodes,g.material_frames};}
static std::string fingerprint(const v::RestGuide&g){std::ostringstream s;s<<std::hexfloat<<g.guide_id<<' '<<g.source_revision<<' '<<g.requires_full_turn_twist;for(auto x:g.node_ids)s<<'n'<<x;for(auto x:g.span_ids)s<<'s'<<x;for(auto x:g.nodes)s<<'p'<<x.x<<','<<x.y<<','<<x.z;for(auto x:g.material_frames)s<<'q'<<x.x<<','<<x.y<<','<<x.z<<','<<x.w;for(auto x:g.span_radius_m)s<<'r'<<x;for(auto x:g.max_bound_offset_m)s<<'o'<<x;return s.str();}
static std::string fingerprint(const v::SolveOptions&o){std::ostringstream s;s<<std::hexfloat<<int(o.root_mode)<<' '<<o.clearance_m<<' '<<o.rest_shape_weight<<' '<<o.bend_weight<<' '<<o.root_angle_weight<<' '<<o.max_proposal_step_m<<' '<<o.tolerances.root_m<<' '<<o.tolerances.penetration_m<<' '<<o.tolerances.relative_length<<' '<<o.tolerances.frame_radians<<' '<<o.tolerances.rest_reconstruction_m<<' '<<o.limits.max_obstacles<<' '<<o.limits.max_nodes<<' '<<o.limits.max_contacts_per_query<<' '<<o.limits.max_query_calls<<' '<<o.limits.max_iterations<<' '<<o.limits.max_render_vertices<<' '<<o.limits.max_render_triangles<<' '<<o.limits.max_owned_and_scratch_bytes;return s.str();}
static bool same_vec(Vec3 a,Vec3 b){return a.x==b.x&&a.y==b.y&&a.z==b.z;}
static bool same_quat(Quat a,Quat b){return a.x==b.x&&a.y==b.y&&a.z==b.z&&a.w==b.w;}
static double relative_lengths(const v::RestGuide&g,const v::GuidePose&p){double e=0;for(std::size_t i=0;i<g.span_ids.size();++i)e=std::max(e,std::abs(length(sub(p.nodes[i+1],p.nodes[i]))/length(sub(g.nodes[i+1],g.nodes[i]))-1));return e;}
static double declared_objective(const v::RestGuide&g,const v::GuidePose&p,const v::SolveOptions&o){
 long double value=0;
 for(std::size_t i=0;i<p.nodes.size();++i)for(int axis=0;axis<3;++axis){const long double d=coord(p.nodes[i],axis)-coord(g.nodes[i],axis);value+=.5L*o.rest_shape_weight*d*d;}
 for(std::size_t i=1;i+1<p.nodes.size();++i)for(int axis=0;axis<3;++axis){
  const long double posed=coord(p.nodes[i-1],axis)+coord(p.nodes[i+1],axis)-2*coord(p.nodes[i],axis);
  const long double authored=coord(g.nodes[i-1],axis)+coord(g.nodes[i+1],axis)-2*coord(g.nodes[i],axis);
  const long double d=posed-authored;value+=.5L*o.bend_weight*d*d;
 }return static_cast<double>(value);
}
static double incremental_roll(const std::vector<Vec3>&nodes,const std::vector<Quat>&qs,std::size_t i){
 // Independent vector/Rodrigues transport, not the fitter's quaternion helper.
 const Vec3 before=node_tangent(nodes,i-1),after=node_tangent(nodes,i);
 const Vec3 crossed=cross(before,after);const double sine=length(crossed),cosine=dot(before,after);
 Vec3 transported=rotate(qs[i-1],{1,0,0});
 if(sine>1e-12){const Vec3 axis=mul(crossed,1/sine);transported=add(add(mul(transported,cosine),mul(cross(axis,transported),sine)),mul(axis,dot(axis,transported)*(1-cosine)));}
 else CHECK(cosine>0);
 transported=unit(sub(transported,mul(after,dot(transported,after))));
 Vec3 current=rotate(qs[i],{1,0,0});current=unit(sub(current,mul(after,dot(current,after))));
 return std::atan2(dot(after,cross(transported,current)),dot(transported,current));
}
static void pose_valid(const v::RestGuide&g,const v::GuidePose&p,const v::SolveOptions&o){
 CHECK(p.guide_id==g.guide_id);CHECK(p.nodes.size()==g.nodes.size());CHECK(p.material_frames.size()==g.material_frames.size());CHECK(same_vec(p.nodes[0],g.nodes[0]));CHECK(relative_lengths(g,p)<=o.tolerances.relative_length+2e-12);
 for(std::size_t i=0;i<p.nodes.size();++i){auto n=p.nodes[i];CHECK(std::isfinite(n.x)&&std::isfinite(n.y)&&std::isfinite(n.z));auto q=p.material_frames[i];double qn=std::hypot(std::hypot(q.x,q.y),std::hypot(q.z,q.w));CHECK(std::abs(qn-1)<1e-9);CHECK(angle(rotate(q,{0,0,1}),node_tangent(p.nodes,i))<=o.tolerances.frame_radians+2e-12);if(i)CHECK(qangle(q,p.material_frames[i-1])<std::acos(-1.));}
 if(o.root_mode==v::RootMode::ClampFrame){CHECK(qangle(p.material_frames[0],g.material_frames[0])<=o.tolerances.frame_radians);CHECK(angle(sub(p.nodes[1],p.nodes[0]),sub(g.nodes[1],g.nodes[0]))<=o.tolerances.frame_radians);}
}
static void print_result(const std::string&label,const v::SolveResult&r,double oracle=-1){
 const auto number=[](double value){if(std::isfinite(value))std::cout<<value;else std::cout<<"null";};
 const bool collision_complete=std::isfinite(r.metrics.max_penetration_m)&&r.metrics.unresolved_contacts!=std::numeric_limits<std::size_t>::max();
 std::cout<<std::setprecision(17)<<"{\"fixture\":\""<<label<<"\",\"status\":"<<int(r.status)<<",\"iterations\":"<<r.metrics.iterations<<",\"queries\":"<<r.metrics.query_calls<<",\"root_error\":";number(r.metrics.max_root_error_m);
 std::cout<<",\"relative_length_error\":";number(r.metrics.max_relative_length_error);
 std::cout<<",\"penetration\":";number(r.metrics.max_penetration_m);
 std::cout<<",\"root_angle\":";number(r.metrics.root_angle_error_radians);
 std::cout<<",\"rest_objective\":";number(r.metrics.rest_objective);
 std::cout<<",\"collision_metrics_complete\":"<<(collision_complete?"true":"false");
 std::cout<<",\"unresolved_contacts\":";if(collision_complete)std::cout<<r.metrics.unresolved_contacts;else std::cout<<"null";
 std::cout<<",\"memory_accounting_bytes\":"<<r.metrics.peak_owned_and_scratch_bytes;
 if(oracle>=0){std::cout<<",\"analytic_span_penetration\":";number(oracle);}
 std::cout<<",\"issues\":[";bool first=true;for(auto&i:r.issues){if(!first)std::cout<<',';first=false;std::cout<<'"'<<i.code<<'"';}std::cout<<"]}\n";
}
static v::SolveResult solve_checked(const std::string&label,const v::RestGuide&g,AnalyticWorld&w,const v::SolveOptions&o){
 std::string before=fingerprint(g),before_options=fingerprint(o);auto calls=w.calls();auto r=v::fit_rooted_guide(g,w.generation(),w,o,{});CHECK(fingerprint(g)==before);CHECK(fingerprint(o)==before_options);print_result(label,r,r.pose.nodes.size()==g.nodes.size()?w.worst_penetration(g,r.pose,o.clearance_m):-1);
 CHECK(r.status==v::SolveStatus::ConvergedCandidate);CHECK(r.generation==w.generation());CHECK(r.source_revision==g.source_revision);pose_valid(g,r.pose,o);double pen=w.worst_penetration(g,r.pose,o.clearance_m);CHECK(pen<=o.tolerances.penetration_m+2e-10);CHECK(r.metrics.query_calls==w.calls()-calls);CHECK(r.metrics.query_calls<=o.limits.max_query_calls);CHECK(r.metrics.iterations<=o.limits.max_iterations);CHECK(r.metrics.peak_owned_and_scratch_bytes<=o.limits.max_owned_and_scratch_bytes);CHECK(r.metrics.peak_owned_and_scratch_bytes>0);CHECK(std::abs(r.metrics.max_relative_length_error-relative_lengths(g,r.pose))<1e-10);CHECK(std::abs(r.metrics.max_penetration_m-pen)<2e-8);CHECK(std::abs(r.metrics.root_angle_error_radians-qangle(g.material_frames[0],r.pose.material_frames[0]))<1e-6);CHECK(std::isfinite(r.metrics.rest_objective)&&r.metrics.rest_objective>=0);CHECK(std::abs(r.metrics.rest_objective-declared_objective(g,r.pose,o))<1e-10);CHECK(r.metrics.max_root_error_m==0);CHECK(r.metrics.unresolved_contacts==0);return r;
}
static void clear_rest(){
 auto g=straight();auto o=options();AnalyticWorld w;auto r=solve_checked("F01_empty",g,w,o);for(std::size_t i=0;i<g.nodes.size();++i){CHECK(same_vec(g.nodes[i],r.pose.nodes[i]));CHECK(same_quat(g.material_frames[i],r.pose.material_frames[i]));}CHECK(r.metrics.rest_objective==0);
 auto w2=sphere_world();w2.spheres[0].center={4,5,6};auto r2=solve_checked("clear_nonempty",g,w2,o);for(std::size_t i=0;i<g.nodes.size();++i){CHECK(same_vec(g.nodes[i],r2.pose.nodes[i]));CHECK(same_quat(g.material_frames[i],r2.pose.material_frames[i]));}
 auto curved=g;for(std::size_t i=0;i<curved.nodes.size();++i){curved.nodes[i].x+=.025*std::sin(double(i)*.4);curved.nodes[i].z=.01*std::sin(double(i)*.7);}frames(curved);AnalyticWorld empty;auto r3=solve_checked("clear_curved_rest",curved,empty,o);for(std::size_t i=0;i<g.nodes.size();++i)CHECK(same_vec(curved.nodes[i],r3.pose.nodes[i]));
}
static void one_sphere(){auto g=straight();auto w=sphere_world();auto r=solve_checked("F02_one_sphere",g,w,options());CHECK(r.metrics.root_angle_error_radians>.01);CHECK(r.metrics.rest_objective>0);}
static void positive_control(){
 auto g=straight();auto w=sphere_world();auto p=rest_pose(g);Vec3 dir=unit({-1,1,0});for(std::size_t i=0;i<p.nodes.size();++i)p.nodes[i]=add(g.nodes[0],mul(dir,.075*i));frames(p);pose_valid(g,p,options());CHECK(w.worst_penetration(g,p,.005)==0);double rootgap=std::sqrt(.08)-.25-.02;CHECK(rootgap>.0128);std::cout<<"{\"fixture\":\"catalog_authored_positive_control\",\"root_clearance\":"<<rootgap<<",\"fitter_executed\":false}\n";
}
static void root_inside(){auto g=straight();auto w=sphere_world();w.spheres[0].center=g.nodes[0];auto before=fingerprint(g);auto r=v::fit_rooted_guide(g,1,w,options(),{});print_result("F03_root_inside",r);CHECK(r.status==v::SolveStatus::RootConflict);CHECK(fingerprint(g)==before);CHECK(r.pose.nodes.empty()||same_vec(r.pose.nodes[0],g.nodes[0]));}
static void segment_interior(){auto g=straight(2,{-2,0,0},{4,0,0},.01);auto o=options();o.clearance_m=0;o.max_proposal_step_m=.2;o.limits.max_iterations=1000;o.limits.max_query_calls=20000;AnalyticWorld w;w.spheres={{901,{0,0,0},1}};CHECK(sphere_point_gap(g.nodes.front(),w.spheres[0])>.01&&sphere_point_gap(g.nodes.back(),w.spheres[0])>.01);auto q=w.query_capsule({g.guide_id,g.span_ids[0],g.nodes[0],g.nodes[1],.01,0},{});CHECK(q.complete&&q.contacts.size()==1&&q.contacts[0].material_u>.4&&q.contacts[0].material_u<.6);auto r=solve_checked("F04_single_segment_fit",g,w,o);CHECK(w.longest_query>3.99);CHECK(r.metrics.root_angle_error_radians>.1);}
static void width_envelope(){auto g=straight(2,{1.1,-.4,0},{0,.8,0},.01);g.max_bound_offset_m[0]=.15;AnalyticWorld w;w.spheres={{902,{0,0,0},1}};auto o=options();o.clearance_m=0;auto r=v::fit_rooted_guide(g,1,w,o,{});print_result("F05_invalid_width",r);CHECK(r.status==v::SolveStatus::InvalidInput);CHECK(w.calls()==0);
 g.span_radius_m[0]=.15;o.max_proposal_step_m=.05;auto r2=solve_checked("admitted_full_width",g,w,o);CHECK(r2.metrics.root_angle_error_radians>.01);
}
static void generation(){auto g=straight();auto o=options();AnalyticWorld w;auto r=v::fit_rooted_guide(g,2,w,o,{});CHECK(r.status==v::SolveStatus::InvalidInput);CHECK(w.calls()==0);w.change_generation_after=2;r=v::fit_rooted_guide(g,1,w,o,{});CHECK(r.status!=v::SolveStatus::ConvergedCandidate);print_result("generation_changed_during_query",r);FaultWorld bad(Fault::WrongResultGeneration);bad.spheres={{900,{0,.2,0},.25}};r=v::fit_rooted_guide(g,1,bad,o,{});CHECK(r.status!=v::SolveStatus::ConvergedCandidate);}
static void multi_obstacle(){auto g=straight(10,{-.25,0,0},{0,.075,0});AnalyticWorld w;w.spheres={{910,{0,.25,-.065},.27},{911,{0,.25,.065},.27}};auto p=rest_pose(g);for(std::size_t i=0;i<p.nodes.size();++i)p.nodes[i]=add(g.nodes[0],mul(unit({-1,1,0}),.075*i));frames(p);CHECK(w.worst_penetration(g,p,.005)==0);auto r=solve_checked("F06_two_spheres",g,w,options());CHECK(w.max_contacts_seen>=2);
 AnalyticWorld b;b.boxes={{920,{0,.22,-.05},{.28,.07,.09},axis_angle({0,0,1},.18)},{921,{0,.22,.05},{.28,.07,.09},axis_angle({0,0,1},-.18)}};CHECK(b.worst_penetration(g,p,.005)==0);auto rb=solve_checked("F06_two_rotated_boxes",g,b,options());CHECK(b.max_contacts_seen>=2);
 auto fixed=straight(3,{0,0,0},{0,.4,0},.025);auto o=options();o.root_mode=v::RootMode::ClampFrame;o.clearance_m=0;AnalyticWorld blocked;blocked.boxes={{930,{-.12,.25,0},{.1,.05,.1},{}},{931,{.12,.25,0},{.1,.05,.1},{}}};auto failed=v::fit_rooted_guide(fixed,1,blocked,o,{});print_result("F06_fixed_span_gap_conflict",failed);CHECK(failed.status==v::SolveStatus::RootConflict);CHECK(blocked.max_contacts_seen==2);
}
static void cancellation(){auto g=straight();auto w=sphere_world();auto o=options();std::atomic_bool cancel{true};auto r=v::fit_rooted_guide(g,1,w,o,{&cancel});CHECK(r.status==v::SolveStatus::Cancelled);CHECK(w.calls()==0);cancel=false;w.cancel_flag=&cancel;w.cancel_after=5;r=v::fit_rooted_guide(g,1,w,o,{&cancel});print_result("cancel_during_queries",r);CHECK(r.status==v::SolveStatus::Cancelled);CHECK(w.calls()<=6);}
static void work_limits(){auto g=straight();auto o=options();auto w=sphere_world();o.limits.max_query_calls=1;auto r=v::fit_rooted_guide(g,1,w,o,{});CHECK(r.status==v::SolveStatus::WorkLimit);CHECK(w.calls()<=1);print_result("query_budget",r);
 w=sphere_world();o=options();o.limits.max_iterations=1;o.max_proposal_step_m=1e-5;r=v::fit_rooted_guide(g,1,w,o,{});CHECK(r.status==v::SolveStatus::WorkLimit);CHECK(r.metrics.iterations<=1);print_result("iteration_budget",r);
 w=sphere_world();o=options();o.limits.max_owned_and_scratch_bytes=1;r=v::fit_rooted_guide(g,1,w,o,{});CHECK(r.status==v::SolveStatus::WorkLimit);CHECK(w.calls()==0);print_result("memory_budget",r);
 w=sphere_world();o=options();o.limits.max_nodes=g.nodes.size()-1;r=v::fit_rooted_guide(g,1,w,o,{});CHECK(r.status==v::SolveStatus::WorkLimit);CHECK(w.calls()==0);
 auto two=straight(9,{-.25,0,0},{0,.075,0});AnalyticWorld multi;multi.spheres={{910,{0,.25,-.065},.27},{911,{0,.25,.065},.27}};o=options();o.limits.max_contacts_per_query=1;r=v::fit_rooted_guide(two,1,multi,o,{});CHECK(r.status==v::SolveStatus::WorkLimit);print_result("contact_budget",r);
 o=options();o.limits.max_obstacles=1;r=v::fit_rooted_guide(two,1,multi,o,{});CHECK(r.status==v::SolveStatus::WorkLimit);print_result("obstacle_budget",r);
 FaultWorld oversized(Fault::HugeCapacity);oversized.spheres={{900,{0,.2,0},.25}};o=options();o.limits.max_owned_and_scratch_bytes=512*1024;r=v::fit_rooted_guide(g,1,oversized,o,{});CHECK(r.status==v::SolveStatus::WorkLimit);CHECK(oversized.capsule_calls>0);print_result("returned_capacity_budget",r);
}
static void malformed_contacts(){auto g=straight();auto o=options();for(Fault f:{Fault::Incomplete,Fault::Ambiguous,Fault::Unqualified,Fault::ZeroNormal,Fault::BadFraction,Fault::BadAxis,Fault::BadGap,Fault::BadId,Fault::PointAmbiguous,Fault::PointIncomplete,Fault::ThrowAllocation,Fault::ThrowOther}){FaultWorld w(f);w.spheres={{900,{0,.2,0},.25}};auto r=v::fit_rooted_guide(g,1,w,o,{});CHECK(r.status!=v::SolveStatus::ConvergedCandidate);if(f==Fault::ThrowAllocation)CHECK(r.status==v::SolveStatus::AllocationFailure);if(f==Fault::ThrowOther)CHECK(r.status==v::SolveStatus::InternalError);print_result("fault_"+std::to_string(int(f)),r);}}
static void local_conflict(){auto g=straight(6,{-.4,0,0},{0,.1,0},.01);AnalyticWorld w;w.spheres={{950,{-.4,.05,0},.015}};auto o=options();o.root_mode=v::RootMode::ClampFrame;o.clearance_m=0;CHECK(sphere_point_gap(g.nodes[0],w.spheres[0])>.01);auto r=v::fit_rooted_guide(g,1,w,o,{});print_result("fixed_first_span_zero_denominator",r);CHECK(r.status==v::SolveStatus::RootConflict);CHECK(w.capsule_calls>0);CHECK(r.pose.nodes.empty()||same_vec(r.pose.nodes[0],g.nodes[0]));
 // Synthetic numerical row: the roster and row intentionally do not establish
 // any physical primitive scene or feasible pose. Only the local witness equation
 // is qualified. A positive endpoint coefficient must not become an exact zero
 // mobility conflict merely because its square underflows.
 class TinyUWorld final:public AnalyticWorld {
  public:
  v::PointResult classify_point(Vec3,double,v::Cancellation)const override{
   ++point_calls;v::PointResult x;x.outcome=v::Outcome::Ok;x.generation=version;x.complete=true;x.hits={{970,v::Location::Outside,1}};return x;
  }
  v::ContactResult query_capsule(const v::CapsuleQuery&q,v::Cancellation)const override{
   ++capsule_calls;const double u=1e-200;const Vec3 normal{1,0,0};const Vec3 axis=add(q.a,mul(sub(q.b,q.a),u));
   const Vec3 surface=sub(axis,mul(normal,q.geometric_radius_m+q.clearance_m-.02));
   const double gap=dot(normal,sub(axis,surface))-q.geometric_radius_m-q.clearance_m;
   v::ContactResult x;x.outcome=v::Outcome::Ok;x.generation=version;x.complete=true;x.contacts={{970,q.guide_id,q.span_id,u,true,axis,surface,normal,gap}};return x;
  }
 } tiny;
 auto single=straight(2,{0,0,0},{0,.1,0},.01);o=options();o.limits.max_iterations=2;
 auto tiny_result=v::fit_rooted_guide(single,1,tiny,o,{});print_result("synthetic_tiny_positive_mobility",tiny_result);
 CHECK(tiny_result.status==v::SolveStatus::WorkLimit||tiny_result.status==v::SolveStatus::UnresolvedContact);
 CHECK(tiny.capsule_calls>0);CHECK(tiny_result.pose.nodes.empty()||same_vec(tiny_result.pose.nodes[0],single.nodes[0]));
}
static void frame_tests(){auto g=straight();auto o=options();auto w=sphere_world();auto r=solve_checked("frame_reference",g,w,o);auto signed_g=g;for(std::size_t i=0;i<signed_g.material_frames.size();i+=2){auto&q=signed_g.material_frames[i];q={-q.x,-q.y,-q.z,-q.w};}auto w2=sphere_world();auto s=solve_checked("quaternion_signs",signed_g,w2,o);for(std::size_t i=0;i<g.nodes.size();++i){CHECK(length(sub(r.pose.nodes[i],s.pose.nodes[i]))<1e-10);CHECK(qangle(r.pose.material_frames[i],s.pose.material_frames[i])<1e-6);}
 auto twisted=g;
 for(std::size_t i=0;i<twisted.material_frames.size();++i)twisted.material_frames[i]=product(twisted.material_frames[i],axis_angle({0,0,1},.25+.08*double(i)));
 auto twist_world=sphere_world();auto twist_result=solve_checked("frame_incremental_rest_twist",twisted,twist_world,o);
 for(std::size_t i=0;i<g.nodes.size();++i){CHECK(length(sub(r.pose.nodes[i],twist_result.pose.nodes[i]))<1e-10);if(i){const double rest_roll=incremental_roll(twisted.nodes,twisted.material_frames,i);const double fitted_roll=incremental_roll(twist_result.pose.nodes,twist_result.pose.material_frames,i);CHECK(std::abs(rest_roll-.08)<1e-12);CHECK(std::abs(std::remainder(fitted_roll-rest_roll,2*std::acos(-1.)))<1e-8);}}
 auto bad=g;bad.material_frames[3]={0,0,0,1};AnalyticWorld clear;auto x=v::fit_rooted_guide(bad,1,clear,o,{});CHECK(x.status==v::SolveStatus::InvalidInput||x.status==v::SolveStatus::Unsupported);
 bad=g;bad.material_frames[3].w*=2;x=v::fit_rooted_guide(bad,1,clear,o,{});CHECK(x.status==v::SolveStatus::InvalidInput);
 bad=g;bad.material_frames[3]=product(axis_angle({0,1,0},std::acos(-1.)),bad.material_frames[3]);x=v::fit_rooted_guide(bad,1,clear,o,{});CHECK(x.status==v::SolveStatus::InvalidInput||x.status==v::SolveStatus::Unsupported);
 bad=g;bad.requires_full_turn_twist=true;x=v::fit_rooted_guide(bad,1,clear,o,{});CHECK(x.status==v::SolveStatus::Unsupported);
 auto antip=straight(3,{0,0,0},{0,.1,0});antip.nodes[2]=antip.nodes[0];x=v::fit_rooted_guide(antip,1,clear,o,{});CHECK(x.status==v::SolveStatus::InvalidInput||x.status==v::SolveStatus::Unsupported);
}
static void repeat_immutable(){auto g=straight();auto old=fingerprint(g);auto w=sphere_world();auto o=options();auto a=solve_checked("repeat_first",g,w,o);auto b=solve_checked("repeat_second",g,w,o);CHECK(fingerprint(g)==old);CHECK(a.metrics.query_calls==b.metrics.query_calls);CHECK(a.metrics.iterations==b.metrics.iterations);for(std::size_t i=0;i<g.nodes.size();++i){CHECK(same_vec(a.pose.nodes[i],b.pose.nodes[i]));CHECK(same_quat(a.pose.material_frames[i],b.pose.material_frames[i]));}
 w.spheres[0].center={5,5,5};auto c=solve_checked("stone_removed_rest_start",g,w,o);for(std::size_t i=0;i<g.nodes.size();++i)CHECK(same_vec(c.pose.nodes[i],g.nodes[i]));CHECK(fingerprint(g)==old);
}
static void away_geometry(){auto g=straight();auto o=options();auto w=sphere_world();Quat q=axis_angle({1,2,3},.7);Vec3 shift{.45,-.2,.7};double scale=1.7;for(auto&p:g.nodes)p=add(shift,mul(rotate(q,p),scale));for(auto&f:g.material_frames)f=product(q,f);for(auto&x:g.span_radius_m)x*=scale;for(auto&x:g.max_bound_offset_m)x*=scale;for(auto&x:g.node_ids)x+=900;for(auto&x:g.span_ids)x+=400;g.guide_id=42;g.source_revision=5;w.version=13;w.spheres[0].center=add(shift,mul(rotate(q,w.spheres[0].center),scale));w.spheres[0].radius*=scale;o.clearance_m*=scale;o.max_proposal_step_m*=scale;solve_checked("rotated_translated_scaled",g,w,o);
 auto other=straight(7,{-.14,0,.03},{0,.067,0},.012);AnalyticWorld ow;ow.spheres={{973,{0,.16,.03},.16}};o=options();o.clearance_m=.003;solve_checked("different_discretization_geometry",other,ow,o);
}
static void root_modes(){auto g=straight();auto o=options();AnalyticWorld empty;o.root_mode=v::RootMode::ClampFrame;auto clear=solve_checked("clamp_clear",g,empty,o);CHECK(same_quat(clear.pose.material_frames[0],g.material_frames[0]));
 auto cl=straight(9,{-.18,0,0},{0,.075,0});AnalyticWorld w;w.spheres={{980,{0,.35,0},.22}};auto p=rest_pose(cl);for(std::size_t i=2;i<p.nodes.size();++i)p.nodes[i]=add(cl.nodes[1],mul(unit({-1,1,0}),.075*(i-1)));frames(p);p.material_frames[0]=cl.material_frames[0];CHECK(w.worst_penetration(cl,p,.005)==0);auto r=solve_checked("clamp_clear_initial_span_fit",cl,w,o);CHECK(same_vec(r.pose.nodes[1],cl.nodes[1]));CHECK(same_quat(r.pose.material_frames[0],cl.material_frames[0]));
 o.root_mode=v::RootMode::SoftFrame;o.root_angle_weight=2;auto s=v::fit_rooted_guide(g,1,empty,o,{});CHECK(s.status==v::SolveStatus::Unsupported);print_result("soft_frame_unsupported",s);
}
static void numeric_admission(){auto good=straight();auto o=options();auto invalid=[&](v::RestGuide g,v::SolveOptions x){AnalyticWorld w;auto before=fingerprint(g);auto r=v::fit_rooted_guide(g,1,w,x,{});CHECK(r.status==v::SolveStatus::InvalidInput||r.status==v::SolveStatus::Unsupported);CHECK(w.calls()==0);CHECK(fingerprint(g)==before);};
 auto g=good;g.nodes.pop_back();invalid(g,o);g=good;g.node_ids[2]=g.node_ids[1];invalid(g,o);g=good;g.span_ids[2]=g.span_ids[1];invalid(g,o);g=good;g.node_ids[2]=0;invalid(g,o);g=good;g.guide_id=0;invalid(g,o);g=good;g.source_revision=0;invalid(g,o);g=good;g.nodes[2]=g.nodes[1];invalid(g,o);g=good;g.nodes[2].x=std::numeric_limits<double>::quiet_NaN();invalid(g,o);g=good;g.span_radius_m[0]=-1;invalid(g,o);g=good;g.max_bound_offset_m[0]=-1;invalid(g,o);
 auto x=o;x.max_proposal_step_m=0;invalid(good,x);x=o;x.rest_shape_weight=-1;invalid(good,x);x=o;x.bend_weight=std::numeric_limits<double>::infinity();invalid(good,x);x=o;x.root_angle_weight=-1;invalid(good,x);x=o;x.clearance_m=-1;invalid(good,x);x=o;x.tolerances.root_m=0;invalid(good,x);x=o;x.tolerances.frame_radians=0;invalid(good,x);x=o;x.tolerances.relative_length=0;invalid(good,x);x=o;x.tolerances.penetration_m=0;invalid(good,x);x=o;x.tolerances.rest_reconstruction_m=0;invalid(good,x);
 std::array<std::size_t v::Limits::*,8> fields{&v::Limits::max_obstacles,&v::Limits::max_nodes,&v::Limits::max_contacts_per_query,&v::Limits::max_query_calls,&v::Limits::max_iterations,&v::Limits::max_render_vertices,&v::Limits::max_render_triangles,&v::Limits::max_owned_and_scratch_bytes};for(auto field:fields){x=o;x.limits.*field=0;invalid(good,x);}std::cout<<"{\"fixture\":\"invalid_input_matrix\",\"result\":\"all explicitly rejected before queries\"}\n";
}
static void admission_order(){
 auto o=options();o.limits.max_owned_and_scratch_bytes=4096;
 const auto invalid=[&](const std::string&label,const v::RestGuide&g,bool chart=false){
  AnalyticWorld w;const auto before=fingerprint(g);auto r=v::fit_rooted_guide(g,1,w,o,{});print_result(label,r);
  CHECK(r.status==v::SolveStatus::InvalidInput||(chart&&r.status==v::SolveStatus::Unsupported));
  CHECK(w.calls()==0);CHECK(fingerprint(g)==before);CHECK(r.metrics.peak_owned_and_scratch_bytes<=o.limits.max_owned_and_scratch_bytes);
 };
 auto g=straight();g.nodes[2].x=std::numeric_limits<double>::quiet_NaN();invalid("tight_memory_nonfinite",g);
 g=straight();g.nodes[0].x=-std::numeric_limits<double>::max();g.nodes[1].x=std::numeric_limits<double>::max();invalid("tight_memory_finite_difference_overflow",g);
 g=straight();g.span_radius_m[0]=-1;invalid("tight_memory_negative_radius",g);
 g=straight();g.span_radius_m[0]=std::numeric_limits<double>::infinity();invalid("tight_memory_infinite_radius",g);
 g=straight();g.material_frames[2].w*=3;invalid("tight_memory_nonunit_frame",g);
 g=straight();g.material_frames[2]={0,0,0,1};invalid("tight_memory_wrong_tangent",g);
 g=straight();g.material_frames[2]=product(axis_angle({0,1,0},std::acos(-1.)),g.material_frames[2]);invalid("tight_memory_pi_chart",g,true);
 g=straight();g.requires_full_turn_twist=true;invalid("tight_memory_full_turn",g,true);
}
int main(int argc,char**argv){
 std::map<std::string,std::function<void()>> tests{{"clear_rest",clear_rest},{"one_sphere",one_sphere},{"positive_control",positive_control},{"root_inside",root_inside},{"segment_interior",segment_interior},{"width_envelope",width_envelope},{"generation",generation},{"multi_obstacle",multi_obstacle},{"cancellation",cancellation},{"work_limits",work_limits},{"malformed_contacts",malformed_contacts},{"local_conflict",local_conflict},{"frames",frame_tests},{"repeat_immutable",repeat_immutable},{"away_geometry",away_geometry},{"root_modes",root_modes},{"numeric_admission",numeric_admission},{"admission_order",admission_order}};
 try{if(argc!=2||!tests.count(argv[1])){std::cerr<<"Usage: fitter_tests <case>\n";return 2;}tests.at(argv[1])();std::cout<<"PASS "<<argv[1]<<'\n';return 0;}catch(const std::exception&e){std::cerr<<"FAIL "<<(argc>1?argv[1]:"")<<": "<<e.what()<<'\n';return 1;}
}
