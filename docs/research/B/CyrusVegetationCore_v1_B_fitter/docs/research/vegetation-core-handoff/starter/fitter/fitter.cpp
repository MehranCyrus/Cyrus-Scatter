#include "private/math.hpp"
#include <algorithm>
#include <exception>
#include <functional>
#include <limits>
#include <new>
#include <stdexcept>
#include <tuple>
#include <utility>

namespace cyrus::vegetation::prototype_v1 {
namespace fitter_detail {
struct Stop { SolveStatus status; const char* code; const char* text; Id object=0,span=0; };
struct BudgetExceeded {};
std::size_t checked_add(std::size_t a,std::size_t b) {
 if(b>std::numeric_limits<std::size_t>::max()-a)throw BudgetExceeded{};
 return a+b;
}
std::size_t checked_mul(std::size_t a,std::size_t b) {
 if(a&&b>std::numeric_limits<std::size_t>::max()/a)throw BudgetExceeded{};
 return a*b;
}
// Counts requested buffer bytes, fixed object/stack allowance, and observable
// query-return capacities. It is NOT an allocator/OS peak or backend-scratch peak.
struct Budget {
 std::size_t limit,live=0,peak=0;
 void take(std::size_t n) {
  const auto next=checked_add(live,n);if(next>limit)throw BudgetExceeded{};
  live=next;peak=std::max(peak,live);
 }
 void release(std::size_t n) noexcept {live-=n;}
 void observe_external(std::size_t n) {
  const auto next=checked_add(live,n);peak=std::max(peak,next);
  if(next>limit)throw BudgetExceeded{};
  live=next;
 }
};
template<class T> struct Allocator {
 using value_type=T;Budget* budget=nullptr;
 explicit Allocator(Budget* p=nullptr):budget(p){}
 template<class U> Allocator(const Allocator<U>& a):budget(a.budget){}
 T* allocate(std::size_t n) {
  const auto bytes=checked_mul(n,sizeof(T));budget->take(bytes);
  try{return static_cast<T*>(::operator new(bytes));}catch(...){budget->release(bytes);throw;}
 }
 void deallocate(T* p,std::size_t n) noexcept {::operator delete(p);budget->release(n*sizeof(T));}
 template<class U> bool operator==(const Allocator<U>& a)const noexcept{return budget==a.budget;}
 template<class U> bool operator!=(const Allocator<U>& a)const noexcept{return !(*this==a);}
};
template<class T> using Buffer=std::vector<T,Allocator<T>>;
struct ExternalLease {
 Budget& b;std::size_t bytes;
 ExternalLease(Budget& bb,std::size_t n):b(bb),bytes(n){b.observe_external(bytes);}
 void grow(std::size_t n) {
  const auto next=checked_add(bytes,n);b.observe_external(n);bytes=next;
 }
 ~ExternalLease(){b.release(bytes);}
};
template<class T> std::size_t returned_base_bytes(const std::vector<T>& v,const std::vector<Issue>& issues) {
 return checked_add(checked_mul(v.capacity(),sizeof(T)),checked_mul(issues.capacity(),sizeof(Issue)));
}
struct RestNode {Vec3 tangent;Quat aligned;double length=0,twist=0;};
struct Row {Contact contact;std::size_t span=0;};
struct Audit {double penetration=0;std::size_t unresolved=0;};

struct Context {
 Budget budget;
 const RestGuide& rest;Generation generation;const CollisionWorld& world;
 const SolveOptions& opt;Cancellation cancel;
 SolveResult out;
 Buffer<RestNode> info;
 Buffer<Vec3> trial,gradient,query_base;
 Buffer<Quat> trial_frames;
 Buffer<Row> rows;
 Buffer<Id> ids,obstacle_ids;
 bool collision_audited=false;
 static constexpr std::size_t length_sweeps=20,frame_backtracks=12;
 // Reserved accounting space for bounded diagnostics and small fixed local state.
 static constexpr std::size_t fixed_allowance=8192;

 Context(const RestGuide& r,Generation g,const CollisionWorld& w,const SolveOptions& o,Cancellation c):
  budget{o.limits.max_owned_and_scratch_bytes},rest(r),generation(g),world(w),opt(o),cancel(c),
  info(Allocator<RestNode>(&budget)),trial(Allocator<Vec3>(&budget)),gradient(Allocator<Vec3>(&budget)),
  query_base(Allocator<Vec3>(&budget)),trial_frames(Allocator<Quat>(&budget)),rows(Allocator<Row>(&budget)),
  ids(Allocator<Id>(&budget)),obstacle_ids(Allocator<Id>(&budget)) {
  out.generation=g;out.source_revision=r.source_revision;out.pose.guide_id=r.guide_id;
  const double unknown=std::numeric_limits<double>::infinity();
  out.metrics.max_root_error_m=out.metrics.max_relative_length_error=unknown;
  out.metrics.max_penetration_m=out.metrics.root_angle_error_radians=out.metrics.rest_objective=unknown;
  out.metrics.unresolved_contacts=std::numeric_limits<std::size_t>::max();
  budget.peak=sizeof(Context);
 }
 [[noreturn]] void stop(SolveStatus s,const char* code,const char* text,Id object=0,Id span=0)const {throw Stop{s,code,text,object,span};}
 void checkpoint()const {
  if(cancel.requested())stop(SolveStatus::Cancelled,"Cancelled","Cancellation requested; no candidate is accepted.");
  if(generation==0||world.generation()!=generation)stop(SolveStatus::InvalidInput,"GenerationMismatch","Requested, queried and current world generation must match.");
 }
 template<class Iterator,class Compare> void cancellable_sort(Iterator first,Iterator last,Compare compare)const {
  std::size_t comparisons=0;checkpoint();
  std::sort(first,last,[&](const auto& a,const auto& b) {
   if((++comparisons&63)==0)checkpoint();
   return compare(a,b);
  });checkpoint();
 }
 void account_issue_strings(ExternalLease& lease,const std::vector<Issue>& issues)const {
  // The contiguous response capacities have already passed the byte budget,
  // bounding this loop. Stop on the first over-budget string, with cancellation
  // between every issue. A rejected response's peak is only the observed bytes.
  for(const auto& x:issues) {
   checkpoint();lease.grow(checked_add(checked_add(x.code.capacity(),1),checked_add(x.message.capacity(),1)));
  }
 }
 bool fixed(std::size_t i)const {return i==0||(opt.root_mode==RootMode::ClampFrame&&i==1);}
 void anchors() {
  trial[0]=rest.nodes[0];if(opt.root_mode==RootMode::ClampFrame)trial[1]=rest.nodes[1];
 }
 void query_start() {
  checkpoint();if(out.metrics.query_calls==opt.limits.max_query_calls)stop(SolveStatus::WorkLimit,"QueryBudget","Query-call limit reached; retained pose is diagnostic.");
  ++out.metrics.query_calls;
 }
 void response(Outcome outcome,bool complete,Generation g) {
  checkpoint();if(g!=generation)stop(SolveStatus::InvalidInput,"ResponseGeneration","Collision response belongs to a different generation.");
  switch(outcome) {
   case Outcome::Ok:break;
   case Outcome::InvalidInput:stop(SolveStatus::InvalidInput,"BackendInvalidInput","Collision backend rejected the query.");
   case Outcome::Unsupported:stop(SolveStatus::Unsupported,"BackendUnsupported","Collision backend does not support this query profile.");
   case Outcome::Ambiguous:stop(SolveStatus::UnresolvedContact,"BackendAmbiguous","Ambiguous collision query; no clearance certificate.");
   case Outcome::ResourceLimit:stop(SolveStatus::WorkLimit,"BackendResourceLimit","Collision backend query capacity was exceeded.");
   case Outcome::Cancelled:stop(SolveStatus::Cancelled,"BackendCancelled","Collision query was cancelled.");
   case Outcome::AllocationFailure:stop(SolveStatus::AllocationFailure,"BackendAllocation","Collision backend allocation failed.");
   case Outcome::InternalError:stop(SolveStatus::InternalError,"BackendInternal","Collision backend reported an internal error.");
   default:stop(SolveStatus::InternalError,"BackendOutcome","Unrecognized backend outcome.");
  }
  if(!complete)stop(SolveStatus::UnresolvedContact,"IncompleteQuery","Collision query did not return a complete contact set.");
 }
 void bounded_diagnostic(const Stop& s)noexcept {
  out.status=s.status;
  // Diagnostic allocation is best effort; never translate allocation failure to success.
  try {
   if(budget.limit>=fixed_allowance) {
    out.issues.push_back({s.code,s.text,s.object,s.span});
    if(!collision_audited)out.issues.push_back({"CollisionMetricsUnknown","No complete collision audit of the diagnostic pose; penetration is +infinity.",rest.guide_id,0});
   }
  }catch(...){out.issues.clear();}
 }
 RestNode inspect_rest_node(std::size_t i,const RestNode* previous)const {
  RestNode node;
  if(i+1<rest.nodes.size())node.length=norm(sub(rest.nodes[i+1],rest.nodes[i]));
  if(!tangent(rest.nodes,i,node.tangent))stop(SolveStatus::Unsupported,"RestTangent","Undefined or near-antiparallel rest tangent bisector.",rest.guide_id);
  if(angle(zaxis(rest.material_frames[i]),node.tangent)>opt.tolerances.frame_radians)
   stop(SolveStatus::InvalidInput,"RestFrameTangent","Rest frame +Z disagrees with the contract node tangent.",rest.guide_id);
  if(i&&std::abs(qdot(qnormal(rest.material_frames[i-1]),qnormal(rest.material_frames[i])))<=pi_epsilon)
   stop(SolveStatus::Unsupported,"AmbiguousRestRotation","Adjacent rest-frame rotation is ambiguous at pi.",rest.guide_id);
  Quat correction;
  if(!swing(zaxis(rest.material_frames[i]),node.tangent,correction))stop(SolveStatus::Unsupported,"RestFrameChart","Rest frame cannot be represented in the supported transport chart.");
  node.aligned=qnormal(product(correction,qnormal(rest.material_frames[i])));
  if(previous) {
   Quat transport;if(!swing(previous->tangent,node.tangent,transport))stop(SolveStatus::Unsupported,"RestTransport","Near-antipodal rest transport is unsupported.");
   Quat delta=qnormal(product(conjugate(product(transport,previous->aligned)),node.aligned));
   if(delta.w<0)delta=negate(delta);
   node.twist=2*std::atan2(delta.z,delta.w);
  }
  return node;
 }
 void validate_and_allocate() {
  const auto& l=opt.limits;const auto& t=opt.tolerances;const auto n=rest.nodes.size();
  if(!l.max_obstacles||!l.max_nodes||!l.max_contacts_per_query||!l.max_query_calls||!l.max_iterations||
     !l.max_render_vertices||!l.max_render_triangles||!l.max_owned_and_scratch_bytes)
   stop(SolveStatus::InvalidInput,"ZeroLimit","Every Limits field must be nonzero.");
  if(!generation||!rest.guide_id||!rest.source_revision)stop(SolveStatus::InvalidInput,"Identity","Generation, guide ID and source revision must be nonzero.");
  if(n<2||rest.node_ids.size()!=n||rest.material_frames.size()!=n||rest.span_ids.size()!=n-1||
     rest.span_radius_m.size()!=n-1||rest.max_bound_offset_m.size()!=n-1)
   stop(SolveStatus::InvalidInput,"ArrayCounts","Guide node/span/frame/envelope counts do not match.");
  if(n>l.max_nodes)stop(SolveStatus::WorkLimit,"NodeBudget","Guide node count exceeds max_nodes.");
  for(double v:{t.root_m,t.penetration_m,t.relative_length,t.frame_radians,t.rest_reconstruction_m,opt.max_proposal_step_m})
   if(!finite(v)||v<=0)stop(SolveStatus::InvalidInput,"PositiveNumeric","Tolerances and proposal step must be finite and positive.");
  for(double v:{opt.clearance_m,opt.rest_shape_weight,opt.bend_weight,opt.root_angle_weight})
   if(!finite(v)||v<0)stop(SolveStatus::InvalidInput,"NonnegativeNumeric","Clearance and weights must be finite and nonnegative.");
  if(t.frame_radians>=std::numbers::pi)stop(SolveStatus::InvalidInput,"FrameTolerance","Frame tolerance must be less than pi.");
  if(opt.root_mode!=RootMode::PositionOnly&&opt.root_mode!=RootMode::ClampFrame&&opt.root_mode!=RootMode::SoftFrame)
   stop(SolveStatus::InvalidInput,"RootMode","Unrecognized root mode.");
  checkpoint();
  // Admission reads immutable arrays before any solver-sized reservation.
  for(std::size_t i=0;i<n;++i) {
   checkpoint();const Quat q=rest.material_frames[i];
   if(!rest.node_ids[i]||!finite(rest.nodes[i])||!finite(q)||std::abs(qnorm(q)-1)>unit_epsilon)
    stop(SolveStatus::InvalidInput,"RestNumeric","Node IDs must be nonzero, positions finite and frames unit quaternions.",rest.guide_id);
   if(i+1<n) {
    const double length=norm(sub(rest.nodes[i+1],rest.nodes[i]));
    if(!rest.span_ids[i]||!finite(length)||length==0)stop(SolveStatus::InvalidInput,"RestSpan","Span IDs must be nonzero and directed rest spans must have finite nonzero length.",rest.guide_id,rest.span_ids[i]);
    const double radius=rest.span_radius_m[i],offset=rest.max_bound_offset_m[i];
    if(!finite(radius)||!finite(offset)||radius<=0||offset<0||radius<offset||!finite(radius+opt.clearance_m))
     stop(SolveStatus::InvalidInput,"Envelope","Positive finite radius must contain the nonnegative bound-offset norm; clearance is separate.",rest.guide_id,rest.span_ids[i]);
   }
  }
  RestNode previous;
  for(std::size_t i=0;i<n;++i){checkpoint();previous=inspect_rest_node(i,i?&previous:nullptr);}
  if(rest.requires_full_turn_twist)stop(SolveStatus::Unsupported,"FullTurnTwist","The frozen shortest-path sampler cannot encode hidden full turns.");
  if(opt.root_mode==RootMode::SoftFrame)stop(SolveStatus::Unsupported,"SoftFrameUnsupported","SoftFrame is not implemented; PositionOnly is never substituted.");
  // Prove all intended large reservations fit before making any of them.
  const auto max_rows=checked_mul(n-1,l.max_contacts_per_query);
  std::size_t required=checked_add(sizeof(Context),fixed_allowance);
  required=checked_add(required,checked_mul(n,sizeof(RestNode)+4*sizeof(Vec3)+2*sizeof(Quat)+sizeof(Id)));
  required=checked_add(required,checked_mul(max_rows,sizeof(Row)));
  required=checked_add(required,checked_mul(l.max_obstacles,sizeof(Id)));
  required=checked_add(required,std::max(checked_mul(l.max_contacts_per_query,sizeof(Contact)),checked_mul(l.max_obstacles,sizeof(PointHit))));
  if(required>budget.limit)throw BudgetExceeded{};
  budget.take(sizeof(Context)+fixed_allowance);
  ids.reserve(n); // Only the bounded ID scratch is needed before uniqueness admission.
  auto unique_ids=[&](const std::vector<Id>& input) {
   ids.clear();for(const auto id:input){checkpoint();ids.push_back(id);}
   cancellable_sort(ids.begin(),ids.end(),std::less<Id>{});
   for(std::size_t i=0;i<ids.size();++i){checkpoint();if(!ids[i]||(i&&ids[i]==ids[i-1]))stop(SolveStatus::InvalidInput,"SemanticIDs","Node and span IDs must be nonzero and unique within their namespace.");}
  };
  unique_ids(rest.node_ids);unique_ids(rest.span_ids);
  info.resize(n);trial.resize(n);gradient.resize(n);query_base.resize(n);trial_frames.resize(n);
  rows.reserve(max_rows);obstacle_ids.reserve(l.max_obstacles);
  for(std::size_t i=0;i<n;++i){checkpoint();info[i]=inspect_rest_node(i,i?&info[i-1]:nullptr);}
  // Public result vectors cannot use the private allocator: reserve/account them explicitly.
  budget.take(checked_mul(n,sizeof(Vec3)+sizeof(Quat)));
  out.pose.nodes.reserve(n);out.pose.material_frames.reserve(n);
  const auto actual=checked_add(checked_mul(out.pose.nodes.capacity(),sizeof(Vec3)),checked_mul(out.pose.material_frames.capacity(),sizeof(Quat)));
  const auto expected=checked_mul(n,sizeof(Vec3)+sizeof(Quat));if(actual>expected)budget.take(actual-expected);
  out.pose.nodes.assign(rest.nodes.begin(),rest.nodes.end());out.pose.material_frames.assign(rest.material_frames.begin(),rest.material_frames.end());
  out.metrics.max_root_error_m=0;out.metrics.max_relative_length_error=0;out.metrics.root_angle_error_radians=0;out.metrics.rest_objective=0;
 }
 void root_preflight() {
  query_start();auto r=world.classify_point(rest.nodes[0],rest.span_radius_m[0]+opt.clearance_m,cancel);
  ExternalLease lease(budget,returned_base_bytes(r.hits,r.issues));account_issue_strings(lease,r.issues);response(r.outcome,r.complete,r.generation);
  if(r.hits.size()>opt.limits.max_obstacles)stop(SolveStatus::WorkLimit,"ObstacleBudget","Root query returned too many obstacles.");
  for(const auto& h:r.hits) {
   checkpoint();if(!h.obstacle_id||!finite(h.signed_gap_m))stop(SolveStatus::InternalError,"MalformedPoint","Invalid obstacle identity or point gap.");
   obstacle_ids.push_back(h.obstacle_id);
   if(h.location==Location::Unsupported)stop(SolveStatus::Unsupported,"PointUnsupported","Root-envelope classification is unsupported.",h.obstacle_id);
   if(h.location==Location::Ambiguous)stop(SolveStatus::UnresolvedContact,"PointAmbiguous","Root-envelope classification is ambiguous.",h.obstacle_id);
   if(h.location!=Location::Outside&&h.location!=Location::Inside&&h.location!=Location::Boundary)
    stop(SolveStatus::InternalError,"PointLocation","Invalid point-location enum.",h.obstacle_id);
   if(h.location==Location::Inside||h.signed_gap_m < -opt.tolerances.penetration_m)
    stop(SolveStatus::RootConflict,"RootEnvelopeInside","Fixed planted root conflicts with an obstacle exclusion envelope.",h.obstacle_id,rest.span_ids[0]);
   if(h.location==Location::Outside&&h.signed_gap_m<0)stop(SolveStatus::InternalError,"PointSign","Outside classification has a negative signed gap.",h.obstacle_id);
  }
  cancellable_sort(obstacle_ids.begin(),obstacle_ids.end(),std::less<Id>{});
  for(std::size_t i=1;i<obstacle_ids.size();++i){checkpoint();if(obstacle_ids[i]==obstacle_ids[i-1])stop(SolveStatus::InternalError,"DuplicateObstacle","Root classification returned a duplicate obstacle ID.");}
 }
 double witness_tolerance(const CapsuleQuery& q,const Contact& c)const {
  const double magnitude=std::max({norm(q.a),norm(q.b),norm(c.obstacle_point),q.geometric_radius_m+q.clearance_m,1e-300});
  return 128*std::numeric_limits<double>::epsilon()*magnitude+
   0.01*std::min(opt.tolerances.penetration_m,opt.tolerances.rest_reconstruction_m);
 }
 double validate_contact(const CapsuleQuery& q,const Contact& c)const {
  if(!c.witness_qualified||!c.obstacle_id||c.guide_id!=q.guide_id||c.span_id!=q.span_id||
     !std::binary_search(obstacle_ids.begin(),obstacle_ids.end(),c.obstacle_id)||
     !finite(c.material_u)||c.material_u<0||c.material_u>1||!finite(c.axis_point)||!finite(c.obstacle_point)||
     !finite(c.outward_normal)||!finite(c.signed_gap_m)||std::abs(norm(c.outward_normal)-1)>unit_epsilon)
   stop(SolveStatus::UnresolvedContact,"UnqualifiedWitness","Invalid/zero-gradient contact witness; no candidate is accepted.",c.obstacle_id,q.span_id);
  const Vec3 axis=lerp(q.a,q.b,c.material_u);const double gap=dot(c.outward_normal,sub(axis,c.obstacle_point))-q.geometric_radius_m-q.clearance_m;
  const double eps=witness_tolerance(q,c);
  if(!finite(gap)||!finite(eps)||norm(sub(axis,c.axis_point))>eps||std::abs(gap-c.signed_gap_m)>eps)
   stop(SolveStatus::UnresolvedContact,"WitnessConsistency","Axis/material fraction or signed-gap equation is inconsistent.",c.obstacle_id,q.span_id);
  return std::min(gap,c.signed_gap_m); // never turn a more negative qualified gap into a pass
 }
 template<class Points> Audit scan(const Points& points) {
  rows.clear();Audit a;
  for(std::size_t i=0;i+1<points.size();++i) {
   query_start();CapsuleQuery q{rest.guide_id,rest.span_ids[i],points[i],points[i+1],rest.span_radius_m[i],opt.clearance_m};
   auto r=world.query_capsule(q,cancel);ExternalLease lease(budget,returned_base_bytes(r.contacts,r.issues));account_issue_strings(lease,r.issues);response(r.outcome,r.complete,r.generation);
   if(r.contacts.size()>opt.limits.max_contacts_per_query)stop(SolveStatus::WorkLimit,"ContactBudget","A query returned more contacts than admitted.");
   for(const auto& c:r.contacts) {
    checkpoint();const double g=validate_contact(q,c);a.penetration=std::max(a.penetration,std::max(0.0,-g));
    if(g < -opt.tolerances.penetration_m)++a.unresolved;
    if(rows.size()==rows.capacity())throw BudgetExceeded{};
    rows.push_back({c,i});
   }
  }
  cancellable_sort(rows.begin(),rows.end(),[](const Row& a,const Row& b) {
   const auto& x=a.contact;const auto& y=b.contact;
   return std::tie(x.obstacle_id,x.span_id,x.material_u,x.outward_normal.x,x.outward_normal.y,x.outward_normal.z,x.obstacle_point.x,x.obstacle_point.y,x.obstacle_point.z)<
          std::tie(y.obstacle_id,y.span_id,y.material_u,y.outward_normal.x,y.outward_normal.y,y.outward_normal.z,y.obstacle_point.x,y.obstacle_point.y,y.obstacle_point.z);
  });checkpoint();return a;
 }
 template<class Points,class Frames> bool geometry_metrics(const Points& p,const Frames& frames,SolveMetrics& m)const {
  m.max_root_error_m=norm(sub(p[0],rest.nodes[0]));m.max_relative_length_error=0;
  m.root_angle_error_radians=qangle(frames[0],rest.material_frames[0]);
  long double e=0;
  for(std::size_t i=0;i<p.size();++i) {
   checkpoint();if(!finite(p[i])||!finite(frames[i])||std::abs(qnorm(frames[i])-1)>unit_epsilon)return false;
   Vec3 t;if(!tangent(p,i,t)||angle(zaxis(frames[i]),t)>opt.tolerances.frame_radians)return false;
   if(i&&std::abs(qdot(qnormal(frames[i-1]),qnormal(frames[i])))<=pi_epsilon)return false;
   const double d=norm(sub(p[i],rest.nodes[i]));e+=0.5L*opt.rest_shape_weight*static_cast<long double>(d)*d;
   if(i+1<p.size()) {
    const double l=norm(sub(p[i+1],p[i]));if(!finite(l)||l==0)return false;
    const double err=std::abs(l/info[i].length-1);if(!finite(err))return false;
    m.max_relative_length_error=std::max(m.max_relative_length_error,err);
   }
   if(i&&i+1<p.size()) {
    const Vec3 a=sub(add(p[i-1],p[i+1]),mul(p[i],2));const Vec3 b=sub(add(rest.nodes[i-1],rest.nodes[i+1]),mul(rest.nodes[i],2));
    const double d2=norm(sub(a,b));e+=0.5L*opt.bend_weight*static_cast<long double>(d2)*d2;
   }
  }
  m.rest_objective=static_cast<double>(e);
  if(!finite(m.rest_objective)||!finite(m.root_angle_error_radians)||m.max_root_error_m>opt.tolerances.root_m)return false;
  if(opt.root_mode==RootMode::ClampFrame) {
   Vec3 a,b;if(!unit(sub(p[1],p[0]),a)||!unit(sub(rest.nodes[1],rest.nodes[0]),b))return false;
   if(angle(a,b)>opt.tolerances.frame_radians||m.root_angle_error_radians>opt.tolerances.frame_radians)return false;
  }
  return true;
 }
 bool build_frames() {
  Vec3 t;Quat turn;
  if(!tangent(trial,0,t))return false;
  if(opt.root_mode==RootMode::ClampFrame)trial_frames[0]=rest.material_frames[0];
  else {
   if(!swing(zaxis(rest.material_frames[0]),t,turn))return false;
   trial_frames[0]=qnormal(product(turn,qnormal(rest.material_frames[0])));
   if(qdot(trial_frames[0],rest.material_frames[0])<0)trial_frames[0]=negate(trial_frames[0]);
  }
  for(std::size_t i=1;i<trial.size();++i) {
   checkpoint();if(!tangent(trial,i,t)||!swing(zaxis(trial_frames[i-1]),t,turn))return false;
   const double h=info[i].twist/2;const Quat twist{0,0,std::sin(h),std::cos(h)};
   trial_frames[i]=qnormal(product(product(turn,qnormal(trial_frames[i-1])),twist));
   if(qdot(trial_frames[i],trial_frames[i-1])<0)trial_frames[i]=negate(trial_frames[i]);
   if(std::abs(qdot(trial_frames[i],qnormal(trial_frames[i-1])))<=pi_epsilon)return false;
  }
  return true;
 }
 void regularize() {
  const auto& p=out.pose.nodes;std::fill(gradient.begin(),gradient.end(),Vec3{});
  const double scale=std::max(opt.rest_shape_weight,opt.bend_weight);
  double wr=0,wb=0;if(scale>0){const double a=opt.rest_shape_weight/scale,b=opt.bend_weight/scale;wr=.2*a/(a+16*b);wb=.2*b/(a+16*b);}
  for(std::size_t i=1;i+1<p.size();++i) {
   checkpoint();const Vec3 e=sub(sub(add(p[i-1],p[i+1]),mul(p[i],2)),sub(add(rest.nodes[i-1],rest.nodes[i+1]),mul(rest.nodes[i],2)));
   gradient[i-1]=add(gradient[i-1],e);gradient[i]=sub(gradient[i],mul(e,2));gradient[i+1]=add(gradient[i+1],e);
  }
  for(std::size_t i=0;i<p.size();++i) {
   checkpoint();const Vec3 step=capped(add(mul(sub(p[i],rest.nodes[i]),-wr),mul(gradient[i],-wb)),opt.max_proposal_step_m);
   trial[i]=fixed(i)?rest.nodes[i]:add(p[i],step);
  }
 }
 void project_contacts() {
  query_base.assign(trial.begin(),trial.end());
  for(const auto& row:rows) {
   checkpoint();const auto& c=row.contact;const auto i=row.span;const double u=c.material_u;
   const double gap=dot(c.outward_normal,sub(lerp(trial[i],trial[i+1],u),c.obstacle_point))-rest.span_radius_m[i]-opt.clearance_m;
   if(!finite(gap))stop(SolveStatus::UnresolvedContact,"NumericContact","Contact linearization overflowed.",c.obstacle_id,c.span_id);
   if(gap>=0)continue;
   const double a=fixed(i)?0:1-u,b=fixed(i+1)?0:u;
   const double biggest=std::max(a,b);
   if(biggest==0) {
    if(gap < -opt.tolerances.penetration_m)stop(SolveStatus::RootConflict,"LocalImmovableContact","A penetrating local witness has zero movable endpoint gradient; not a global infeasibility proof.",c.obstacle_id,c.span_id);
    continue;
   }
   // D/biggest avoids squaring a tiny but nonzero movable coefficient into
   // zero. Only an actually zero gradient is a local anchoring conflict.
   const double scaled_denominator=(a/biggest)*(1-u)+(b/biggest)*u;
   const double amplitude=std::min((-gap)/scaled_denominator,opt.max_proposal_step_m);
   for(auto [j,factor]:{std::pair{i,a/biggest},std::pair{i+1,b/biggest}}) {
    if(fixed(j))continue;
    const Vec3 proposed=add(trial[j],mul(c.outward_normal,amplitude*factor));
    trial[j]=add(query_base[j],capped(sub(proposed,query_base[j]),opt.max_proposal_step_m));
   }
  }
  anchors();
 }
 void project_lengths() {
  const auto spans=trial.size()-1;
  for(std::size_t sweep=0;sweep<length_sweeps;++sweep) {
   for(std::size_t k=0;k<spans;++k) {
    checkpoint();const auto i=(sweep&1)?spans-1-k:k;
    const double wa=fixed(i)?0:1,wb=fixed(i+1)?0:1;if(wa+wb==0)continue;
    const Vec3 difference=sub(trial[i+1],trial[i]);const double length=norm(difference);Vec3 direction;
    if(!finite(length))stop(SolveStatus::UnresolvedContact,"NumericLength","Nonfinite proposed span length.");
    if(length==0){if(!unit(sub(rest.nodes[i+1],rest.nodes[i]),direction))stop(SolveStatus::InternalError,"RestLength","Invalid stored rest direction.");}
    else if(!unit(difference,direction))stop(SolveStatus::UnresolvedContact,"NumericDirection","Cannot normalize a proposed span.");
    const Vec3 delta=capped(mul(direction,(length-info[i].length)/(wa+wb)),opt.max_proposal_step_m);
    if(wa)trial[i]=add(trial[i],delta);
    if(wb)trial[i+1]=sub(trial[i+1],delta);
   }
   anchors();
  }
 }
 void cap_proposal() {
  double maximum=0;for(std::size_t i=0;i<trial.size();++i){checkpoint();maximum=std::max(maximum,norm(sub(trial[i],out.pose.nodes[i])));}
  if(!finite(maximum))stop(SolveStatus::UnresolvedContact,"NumericProposal","Nonfinite proposed displacement.");
  if(maximum>opt.max_proposal_step_m) {
   const double scale=opt.max_proposal_step_m/maximum;
   for(std::size_t i=0;i<trial.size();++i){checkpoint();trial[i]=lerp(out.pose.nodes[i],trial[i],scale);}
  }
  anchors();
 }
 void install_metrics(const Audit& a,SolveMetrics m) {
  m.iterations=out.metrics.iterations;m.query_calls=out.metrics.query_calls;
  m.max_penetration_m=a.penetration;m.unresolved_contacts=a.unresolved;
  m.peak_owned_and_scratch_bytes=budget.peak;out.metrics=m;collision_audited=true;
 }
 bool acceptable(const SolveMetrics& m)const {return m.max_relative_length_error<=opt.tolerances.relative_length&&m.max_root_error_m<=opt.tolerances.root_m&&m.max_penetration_m<=opt.tolerances.penetration_m;}
 void accept() {checkpoint();out.status=SolveStatus::ConvergedCandidate;}
 void solve() {
  validate_and_allocate();root_preflight();
  SolveMetrics m=out.metrics;
  if(!geometry_metrics(out.pose.nodes,out.pose.material_frames,m))stop(SolveStatus::InvalidInput,"RestGeometry","Rest constraints/frame metrics are not finite and valid.");
  const Audit initial=scan(out.pose.nodes);install_metrics(initial,m);
  if(acceptable(out.metrics)){accept();return;} // retains exact original nodes AND quaternion representatives
  while(out.metrics.iterations<opt.limits.max_iterations) {
   checkpoint();++out.metrics.iterations;
   regularize(); // no timestep: normalized gradient of the declared rest/bend objective
   scan(trial); // local witnesses belong to this regularized iterate, never a permanent attachment
   project_contacts();project_lengths();cap_proposal();
   bool valid=false;
   for(std::size_t attempt=0;attempt<=frame_backtracks;++attempt) {
    checkpoint();m=out.metrics;
    if(build_frames()&&geometry_metrics(trial,trial_frames,m)){valid=true;break;}
    if(attempt==frame_backtracks)break;
    for(std::size_t i=0;i<trial.size();++i){checkpoint();trial[i]=lerp(out.pose.nodes[i],trial[i],.5);}anchors();
   }
   if(!valid)stop(SolveStatus::UnresolvedContact,"FrameChartStall","No valid tangent/frame proposal in the bounded backtracking chart.");
   const Audit final=scan(trial); // final COMPLETE audit, after lengths, proposal cap and frames
   checkpoint();
   out.pose.nodes.assign(trial.begin(),trial.end());out.pose.material_frames.assign(trial_frames.begin(),trial_frames.end());
   install_metrics(final,m);
   if(acceptable(out.metrics)){accept();return;}
  }
  stop(SolveStatus::WorkLimit,"IterationBudget","Iteration limit reached; unresolved search is not global infeasibility.");
 }
 SolveResult run()noexcept {
  try{solve();}
  catch(const Stop& s){bounded_diagnostic(s);}
  catch(const BudgetExceeded&){bounded_diagnostic({SolveStatus::WorkLimit,"MemoryBudget","B-owned/observable payload budget exceeded; opaque backend allocations cannot be preempted by v1."});}
  catch(const std::bad_alloc&){bounded_diagnostic({SolveStatus::AllocationFailure,"AllocationFailure","Allocation failed; staged data is diagnostic only."});}
  catch(const std::exception&){bounded_diagnostic({SolveStatus::InternalError,"Exception","Unexpected exception from arithmetic/container/backend boundary."});}
  catch(...){bounded_diagnostic({SolveStatus::InternalError,"Exception","Unknown exception at synchronous solve boundary."});}
  out.metrics.peak_owned_and_scratch_bytes=budget.peak;
  return std::move(out);
 }
};
} // namespace fitter_detail

SolveResult fit_rooted_guide(const RestGuide& rest,Generation generation,const CollisionWorld& world,
 const SolveOptions& options,Cancellation cancel) {
 try {return fitter_detail::Context(rest,generation,world,options,cancel).run();}
 catch(...) {
  SolveResult r;r.generation=generation;r.source_revision=rest.source_revision;r.pose.guide_id=rest.guide_id;r.status=SolveStatus::AllocationFailure;
  const double unknown=std::numeric_limits<double>::infinity();
  r.metrics.max_root_error_m=r.metrics.max_relative_length_error=r.metrics.max_penetration_m=unknown;
  r.metrics.root_angle_error_radians=r.metrics.rest_objective=unknown;
  r.metrics.unresolved_contacts=std::numeric_limits<std::size_t>::max();
  r.metrics.peak_owned_and_scratch_bytes=sizeof(fitter_detail::Context);
  return r;
 }
}
} // namespace cyrus::vegetation::prototype_v1
