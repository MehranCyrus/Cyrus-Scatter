#pragma once
// Owner B's independently authored TEST fixture backend. No engine code is used.
// This is not owner A's Jolt implementation and not owner C's mesh validator.
#include <cyrus_vegetation/prototype_v1.hpp>
#include <algorithm>
#include <array>
#include <cmath>
#include <limits>
#include <stdexcept>
#include <utility>
#include <vector>

namespace fitter_test {
namespace api = cyrus::vegetation::prototype_v1;
using api::Vec3; using api::Quat;
inline Vec3 add(Vec3 a,Vec3 b){return {a.x+b.x,a.y+b.y,a.z+b.z};}
inline Vec3 sub(Vec3 a,Vec3 b){return {a.x-b.x,a.y-b.y,a.z-b.z};}
inline Vec3 mul(Vec3 a,double b){return {a.x*b,a.y*b,a.z*b};}
inline double dot(Vec3 a,Vec3 b){return a.x*b.x+a.y*b.y+a.z*b.z;}
inline Vec3 cross(Vec3 a,Vec3 b){return {a.y*b.z-a.z*b.y,a.z*b.x-a.x*b.z,a.x*b.y-a.y*b.x};}
inline double length(Vec3 a){return std::hypot(a.x,a.y,a.z);}
inline Vec3 unit(Vec3 a){double n=length(a);if(!(n>0))throw std::runtime_error("undefined test unit vector");return mul(a,1/n);}
inline Quat conjugate(Quat q){return {-q.x,-q.y,-q.z,q.w};}
inline Quat product(Quat a,Quat b){return {a.w*b.x+a.x*b.w+a.y*b.z-a.z*b.y,a.w*b.y-a.x*b.z+a.y*b.w+a.z*b.x,a.w*b.z+a.x*b.y-a.y*b.x+a.z*b.w,a.w*b.w-a.x*b.x-a.y*b.y-a.z*b.z};}
inline Vec3 rotate(Quat q,Vec3 v){Vec3 u{q.x,q.y,q.z};return add(v,add(mul(cross(u,v),2*q.w),mul(cross(u,cross(u,v)),2)));}
inline Quat axis_angle(Vec3 axis,double a){axis=unit(axis);double s=std::sin(.5*a);return {s*axis.x,s*axis.y,s*axis.z,std::cos(.5*a)};}
inline double qangle(Quat a,Quat b){double x=std::abs(a.x*b.x+a.y*b.y+a.z*b.z+a.w*b.w);return 2*std::acos(std::clamp(x,0.,1.));}
inline double angle(Vec3 a,Vec3 b){return std::atan2(length(cross(unit(a),unit(b))),dot(unit(a),unit(b)));}
inline Quat frame_z(Vec3 tangent){
 tangent=unit(tangent);Vec3 z{0,0,1};double d=dot(z,tangent);
 if(d < -1+1e-12)return {1,0,0,0};
 Vec3 c=cross(z,tangent);double n=std::sqrt(2*(1+d));return {c.x/n,c.y/n,c.z/n,.5*n};
}
inline Vec3 node_tangent(const std::vector<Vec3>& n,std::size_t i){
 if(i==0)return unit(sub(n[1],n[0]));
 if(i+1==n.size())return unit(sub(n[i],n[i-1]));
 return unit(add(unit(sub(n[i],n[i-1])),unit(sub(n[i+1],n[i]))));
}
inline void frames(api::RestGuide& g){g.material_frames.clear();for(std::size_t i=0;i<g.nodes.size();++i)g.material_frames.push_back(frame_z(node_tangent(g.nodes,i)));}
inline void frames(api::GuidePose& g){g.material_frames.clear();for(std::size_t i=0;i<g.nodes.size();++i)g.material_frames.push_back(frame_z(node_tangent(g.nodes,i)));}

struct Sphere {api::Id id;Vec3 center;double radius;};
struct Box {api::Id id;Vec3 center,half;Quat orientation;};
struct Witness {double distance,u;Vec3 axis,surface,normal;};
inline double sphere_point_gap(Vec3 p,const Sphere&s){return length(sub(p,s.center))-s.radius;}
inline double segment_sphere_distance(Vec3 a,Vec3 b,Vec3 center){
 Vec3 d=sub(b,a);double u=std::clamp(dot(sub(center,a),d)/dot(d,d),0.,1.);
 return length(sub(add(a,mul(d,u)),center));
}
inline Witness sphere_witness(Vec3 a,Vec3 b,const Sphere&s){
 Vec3 d=sub(b,a);double u=std::clamp(dot(sub(s.center,a),d)/dot(d,d),0.,1.);Vec3 p=add(a,mul(d,u));Vec3 v=sub(p,s.center);double n=length(v);
 Vec3 normal;
 if(n>1e-14)normal=mul(v,1/n);
 else { // Deterministic qualified subgradient at the sphere's medial center.
  Vec3 t=unit(d);Vec3 basis=std::abs(t.x)<.8?Vec3{1,0,0}:Vec3{0,1,0};normal=unit(sub(basis,mul(t,dot(basis,t))));
 }
 return {n-s.radius,u,p,add(s.center,mul(normal,s.radius)),normal};
}
inline double coord(Vec3 p,int i){return i==0?p.x:i==1?p.y:p.z;}
inline Vec3 point_from(std::array<double,3> x){return {x[0],x[1],x[2]};}
inline double local_box_sdf(Vec3 p,Vec3 h){
 Vec3 q{std::abs(p.x)-h.x,std::abs(p.y)-h.y,std::abs(p.z)-h.z};
 return length({std::max(q.x,0.),std::max(q.y,0.),std::max(q.z,0.)})+std::min(std::max({q.x,q.y,q.z}),0.);
}
inline Witness box_witness(Vec3 world_a,Vec3 world_b,const Box&box){
 Vec3 a=rotate(conjugate(box.orientation),sub(world_a,box.center));
 Vec3 b=rotate(conjugate(box.orientation),sub(world_b,box.center));Vec3 d=sub(b,a);
 std::vector<double> candidates{0,1};std::vector<double> cuts{0,1};
 for(int i=0;i<3;++i){double di=coord(d,i);if(di==0)continue;for(double sg:{-1.,1.}){double t=(sg*coord(box.half,i)-coord(a,i))/di;if(t>0&&t<1)cuts.push_back(t);}}
 std::sort(cuts.begin(),cuts.end());cuts.erase(std::unique(cuts.begin(),cuts.end()),cuts.end());
 candidates.insert(candidates.end(),cuts.begin(),cuts.end());
 // On every outside interval the squared distance is a quadratic; its stationary
 // point plus interval boundaries give the exact segment/AABB distance candidate.
 for(std::size_t k=1;k<cuts.size();++k){double lo=cuts[k-1],hi=cuts[k],mid=.5*(lo+hi),aa=0,bb=0;
  for(int i=0;i<3;++i){double p=coord(a,i)+mid*coord(d,i),h=coord(box.half,i);if(p>h||p<-h){double c=coord(a,i)-(p>h?h:-h);aa+=coord(d,i)*coord(d,i);bb+=coord(d,i)*c;}}
  if(aa>0)candidates.push_back(std::clamp(-bb/aa,lo,hi));
 }
 // Within the box, signed distance is max of six affine face distances. Its
 // minimum occurs at a boundary or intersection of two of those lines.
 std::array<double,6> slope{},offset{};
 for(int i=0;i<3;++i)for(int j=0;j<2;++j){int k=2*i+j;double sg=j?1.:-1.;slope[k]=sg*coord(d,i);offset[k]=sg*coord(a,i)-coord(box.half,i);}
 for(int i=0;i<6;++i)for(int j=i+1;j<6;++j){double den=slope[i]-slope[j];if(den!=0){double t=(offset[j]-offset[i])/den;if(t>=0&&t<=1)candidates.push_back(t);}}
 double best=std::numeric_limits<double>::infinity(),u=0;
 for(double t:candidates){double sd=local_box_sdf(add(a,mul(d,t)),box.half);if(sd<best){best=sd;u=t;}}
 Vec3 p=add(a,mul(d,u));std::array<double,3> closest{},normal{};
 for(int i=0;i<3;++i)closest[i]=std::clamp(coord(p,i),-coord(box.half,i),coord(box.half,i));
 Vec3 delta=sub(p,point_from(closest));double dl=length(delta);
 if(dl>0){Vec3 n=mul(delta,1/dl);normal={n.x,n.y,n.z};}
 else {int face=0;double value=std::abs(p.x)-box.half.x;for(int i=1;i<3;++i){double v=std::abs(coord(p,i))-coord(box.half,i);if(v>value){face=i;value=v;}}
  double sg=coord(p,face)>=0?1.:-1.;normal[face]=sg;closest[face]=sg*coord(box.half,face);
 }
 return {best,u,add(world_a,mul(sub(world_b,world_a),u)),add(box.center,rotate(box.orientation,point_from(closest))),rotate(box.orientation,point_from(normal))};
}

class AnalyticWorld : public api::CollisionWorld {
public:
 std::vector<Sphere> spheres;
 std::vector<Box> boxes;
 mutable api::Generation version=1;
 mutable std::size_t point_calls=0,capsule_calls=0,max_contacts_seen=0;
 mutable double longest_query=0;
 std::atomic_bool* cancel_flag=nullptr;
 std::size_t cancel_after=std::numeric_limits<std::size_t>::max();
 std::size_t change_generation_after=std::numeric_limits<std::size_t>::max();
 double query_tolerance=1e-6;
 api::Generation generation()const noexcept override{return version;}
 api::BackendIdentity backend()const override{return {"Owner B analytic test world","authored-no-engine-dependency","C++20 double","analytic spheres and rigid OBBs"};}
 std::size_t calls()const{return point_calls+capsule_calls;}
 void checkpoint()const{if(cancel_flag&&calls()>=cancel_after)cancel_flag->store(true);if(calls()==change_generation_after)++version;}
 api::PointResult classify_point(Vec3 p,double radius,api::Cancellation cancel)const override{
  ++point_calls;api::PointResult r;r.generation=version;
  if(cancel.requested()){r.outcome=api::Outcome::Cancelled;checkpoint();return r;}
  for(const auto&s:spheres){double g=sphere_point_gap(p,s)-radius;r.hits.push_back({s.id,g < -query_tolerance?api::Location::Inside:g>query_tolerance?api::Location::Outside:api::Location::Boundary,g});}
  for(const auto&b:boxes){double g=local_box_sdf(rotate(conjugate(b.orientation),sub(p,b.center)),b.half)-radius;r.hits.push_back({b.id,g < -query_tolerance?api::Location::Inside:g>query_tolerance?api::Location::Outside:api::Location::Boundary,g});}
  std::sort(r.hits.begin(),r.hits.end(),[](const auto&a,const auto&b){return a.obstacle_id<b.obstacle_id;});r.outcome=api::Outcome::Ok;r.complete=true;checkpoint();return r;
 }
 api::ContactResult query_capsule(const api::CapsuleQuery&q,api::Cancellation cancel)const override{
  ++capsule_calls;longest_query=std::max(longest_query,length(sub(q.b,q.a)));api::ContactResult r;r.generation=version;
  if(cancel.requested()){r.outcome=api::Outcome::Cancelled;checkpoint();return r;}
  auto insert=[&](api::Id id,const Witness&w){double gap=w.distance-q.geometric_radius_m-q.clearance_m;if(gap<=query_tolerance)r.contacts.push_back({id,q.guide_id,q.span_id,w.u,true,w.axis,w.surface,w.normal,gap});};
  for(const auto&s:spheres)insert(s.id,sphere_witness(q.a,q.b,s));
  for(const auto&b:boxes)insert(b.id,box_witness(q.a,q.b,b));
  std::sort(r.contacts.begin(),r.contacts.end(),[](const auto&a,const auto&b){return a.obstacle_id<b.obstacle_id;});max_contacts_seen=std::max(max_contacts_seen,r.contacts.size());r.outcome=api::Outcome::Ok;r.complete=true;checkpoint();return r;
 }
 double worst_penetration(const api::RestGuide&g,const api::GuidePose&p,double clearance)const{
  double pen=0;for(std::size_t i=0;i<g.span_ids.size();++i){double envelope=g.span_radius_m[i]+clearance;
   for(const auto&s:spheres)pen=std::max(pen,envelope+s.radius-segment_sphere_distance(p.nodes[i],p.nodes[i+1],s.center));
   for(const auto&b:boxes)pen=std::max(pen,envelope-box_witness(p.nodes[i],p.nodes[i+1],b).distance);
  }return pen;
 }
};

enum class Fault { Incomplete,Ambiguous,Unqualified,ZeroNormal,BadFraction,BadAxis,BadGap,BadId,WrongResultGeneration,PointAmbiguous,PointIncomplete,ThrowAllocation,ThrowOther,HugeCapacity };
class FaultWorld final : public AnalyticWorld {
public:
 Fault fault;
 explicit FaultWorld(Fault f):fault(f){}
 api::PointResult classify_point(Vec3 p,double radius,api::Cancellation c)const override{
  auto r=AnalyticWorld::classify_point(p,radius,c);
  if(fault==Fault::PointAmbiguous){r.outcome=api::Outcome::Ambiguous;r.complete=false;}
  if(fault==Fault::PointIncomplete){r.complete=false;}
  return r;
 }
 api::ContactResult query_capsule(const api::CapsuleQuery&q,api::Cancellation c)const override{
  if(fault==Fault::ThrowAllocation){++capsule_calls;throw std::bad_alloc();}
  if(fault==Fault::ThrowOther){++capsule_calls;throw std::runtime_error("test query exception");}
  auto r=AnalyticWorld::query_capsule(q,c);
  if(fault==Fault::HugeCapacity)r.contacts.reserve(8192);
  if(fault==Fault::Incomplete)r.complete=false;
  if(fault==Fault::Ambiguous){r.outcome=api::Outcome::Ambiguous;r.complete=false;}
  if(fault==Fault::WrongResultGeneration)++r.generation;
  if(!r.contacts.empty()){auto&h=r.contacts[0];
   switch(fault){case Fault::Unqualified:h.witness_qualified=false;break;case Fault::ZeroNormal:h.outward_normal={};break;case Fault::BadFraction:h.material_u=1.5;break;case Fault::BadAxis:h.axis_point.x+=1;break;case Fault::BadGap:h.signed_gap_m=std::numeric_limits<double>::quiet_NaN();break;case Fault::BadId:h.guide_id+=99;break;default:break;}
  }return r;
 }
};
} // namespace fitter_test
