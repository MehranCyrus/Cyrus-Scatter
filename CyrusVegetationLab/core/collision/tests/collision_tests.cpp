// New owner-A black-box tests. Historical report harnesses are neither linked nor rerun.
// Analytic controls use the frozen public source interface and independent double math.
// One separate case inspects private raw-Jolt observation counters/witnesses.
#include <cyrus_vegetation/prototype_v1.hpp>
#include "query_diagnostics.hpp"

#include <algorithm>
#include <array>
#include <cmath>
#include <cstddef>
#include <cstdint>
#include <exception>
#include <functional>
#include <iomanip>
#include <iostream>
#include <limits>
#include <map>
#include <numbers>
#include <sstream>
#include <stdexcept>
#include <string>
#include <string_view>
#include <utility>
#include <vector>

namespace v = cyrus::vegetation::prototype_v1;
namespace cd = v::collision_detail;
namespace {
constexpr char kPin[] = "1b2e77e3c6c09709e5edc79dc208459b8ff32051";
constexpr double kExact = 2.0e-10; // Double analytic controls, not Jolt GJK tolerance.
std::size_t check_count = 0;
double largest_expected_error = 0;

void require(bool value, const std::string& label) {
    ++check_count;
    if (!value) throw std::runtime_error(label);
}
void near(double actual, double expected, double tolerance, const std::string& label) {
    require(std::isfinite(actual) && std::isfinite(expected), label + ": nonfinite numeric result");
    const double error = std::abs(actual - expected);
    largest_expected_error = std::max(largest_expected_error, error);
    std::ostringstream out;
    out << std::setprecision(17) << label << ": actual=" << actual
        << " expected=" << expected << " error=" << error << " allowed=" << tolerance;
    require(error <= tolerance, out.str());
}
v::Vec3 add(v::Vec3 a, v::Vec3 b) { return {a.x+b.x,a.y+b.y,a.z+b.z}; }
v::Vec3 sub(v::Vec3 a, v::Vec3 b) { return {a.x-b.x,a.y-b.y,a.z-b.z}; }
v::Vec3 mul(v::Vec3 a, double b) { return {a.x*b,a.y*b,a.z*b}; }
double dot(v::Vec3 a, v::Vec3 b) { return a.x*b.x+a.y*b.y+a.z*b.z; }
v::Vec3 cross(v::Vec3 a, v::Vec3 b) { return {a.y*b.z-a.z*b.y,a.z*b.x-a.x*b.z,a.x*b.y-a.y*b.x}; }
double length(v::Vec3 a) { return std::hypot(a.x,a.y,a.z); }
v::Vec3 normalized(v::Vec3 a) { return mul(a,1.0/length(a)); }
void near_vec(v::Vec3 a,v::Vec3 b,double t,const std::string& label) {
    near(a.x,b.x,t,label+" x");near(a.y,b.y,t,label+" y");near(a.z,b.z,t,label+" z");
}
bool finite(v::Vec3 p) { return std::isfinite(p.x)&&std::isfinite(p.y)&&std::isfinite(p.z); }
v::Quat rotation(v::Vec3 axis,double radians) {
    const auto n=normalized(axis);const double s=std::sin(0.5*radians);
    return {s*n.x,s*n.y,s*n.z,std::cos(0.5*radians)};
}
v::Vec3 rotate(v::Quat q,v::Vec3 p) {
    // Independent quaternion-vector formula, no adapter or Jolt math helpers.
    const v::Vec3 qv{q.x,q.y,q.z};
    const auto t=mul(cross(qv,p),2.0);
    return add(p,add(mul(t,q.w),cross(qv,t)));
}
v::Vec3 inverse_rotate(v::Quat q,v::Vec3 p) { return rotate({-q.x,-q.y,-q.z,q.w},p); }
v::Vec3 to_patch(const v::Obstacle& b,v::Vec3 p) { return add(b.center,rotate(b.orientation,p)); }
double box_point_sdf(v::Vec3 p, v::Vec3 h) {
    // Independent textbook point/AABB distance in the box's local coordinates.
    const v::Vec3 d{std::abs(p.x)-h.x,std::abs(p.y)-h.y,std::abs(p.z)-h.z};
    const v::Vec3 outside{std::max(d.x,0.0),std::max(d.y,0.0),std::max(d.z,0.0)};
    return length(outside)+std::min(std::max({d.x,d.y,d.z}),0.0);
}

struct FixedRandom {
    std::uint64_t state = 0x3a22e18bf7019c4dULL;
    double unit() {
        // Fixed arithmetic and conversion: independent of standard-library RNG distributions.
        state=state*6364136223846793005ULL+1442695040888963407ULL;
        return static_cast<double>(state>>11)*(1.0/9007199254740992.0);
    }
    double range(double lo,double hi) { return lo+(hi-lo)*unit(); }
    v::Vec3 vector(double lo,double hi) { return {range(lo,hi),range(lo,hi),range(lo,hi)}; }
};

v::BackendOptions options() {
    v::BackendOptions o;
    o.limits={32,64,32,20000,400,10000,20000,67108864};
    o.query_tolerance_m=1.0e-6;o.min_supported_feature_m=0.001;
    return o;
}
v::Obstacle sphere(v::Id id=900,v::Vec3 center={},double radius=1.0) {
    v::Obstacle o;o.id=id;o.geometry_revision=11;o.pose_revision=17;
    o.kind=v::ObstacleKind::Sphere;o.center=center;o.sphere_radius=radius;return o;
}
v::Obstacle box(v::Id id=720) {
    v::Obstacle b;b.id=id;b.geometry_revision=2;b.pose_revision=9;b.kind=v::ObstacleKind::Box;
    b.center={3.25,-1.75,2.125};b.orientation=rotation({1,2,3},0.63);b.box_half_extents={1.25,0.55,0.8};return b;
}
v::SceneSnapshot scene(std::vector<v::Obstacle> obstacles,v::Generation generation=42) {
    return {generation,std::move(obstacles)};
}
std::string issues_text(const std::vector<v::Issue>& issues) {
    std::string s;for(const auto& i:issues)s+=" ["+i.code+": "+i.message+"]";return s;
}
std::shared_ptr<const v::CollisionWorld> build(const v::SceneSnapshot& s,const v::BackendOptions& o=options()) {
    auto r=v::make_jolt_world(s,o,{});
    require(r.outcome==v::Outcome::Ok,"world build must succeed"+issues_text(r.issues));
    require(static_cast<bool>(r.world),"successful build owns a world");
    require(r.world->generation()==s.generation,"world echoes immutable generation");
    return r.world;
}
void failed_build(const v::SceneSnapshot& s,const v::BackendOptions& o,v::Outcome expected,const std::string& label) {
    auto r=v::make_jolt_world(s,o,{});
    require(r.outcome==expected,label+": wrong failure outcome"+issues_text(r.issues));
    require(!r.world,label+": failed build must not return world");
}
void complete_point(const v::PointResult& r,v::Generation generation,std::size_t count) {
    require(r.outcome==v::Outcome::Ok,"point outcome"+issues_text(r.issues));
    require(r.complete,"point complete");require(r.generation==generation,"point generation");
    require(r.hits.size()==count,"point one result per obstacle");
    for(std::size_t i=0;i<r.hits.size();++i) {
        require(r.hits[i].obstacle_id!=0,"point stable nonzero ID");
        require(std::isfinite(r.hits[i].signed_gap_m),"point finite signed gap");
        if(i)require(r.hits[i-1].obstacle_id<r.hits[i].obstacle_id,"point deterministic strict ID order");
    }
}
void complete_contact(const v::ContactResult& r,v::Generation generation) {
    require(r.outcome==v::Outcome::Ok,"capsule outcome"+issues_text(r.issues));
    require(r.complete,"capsule complete");require(r.generation==generation,"capsule generation");
    for(std::size_t i=1;i<r.contacts.size();++i)
        require(r.contacts[i-1].obstacle_id<=r.contacts[i].obstacle_id,"contact deterministic obstacle order");
}
void failed_point(const v::PointResult& r,v::Generation generation,v::Outcome expected,const std::string& label) {
    require(r.outcome==expected,label+": failure outcome"+issues_text(r.issues));
    require(!r.complete,label+": incomplete");require(r.hits.empty(),label+": staged point data discarded");
    require(r.generation==generation,label+": generation echoed");
}
bool clear(const v::ContactResult& r) { return r.outcome==v::Outcome::Ok&&r.complete&&r.contacts.empty(); }
void failed_contact(const v::ContactResult& r,v::Generation generation,v::Outcome expected,const std::string& label) {
    require(r.outcome==expected,label+": failure outcome"+issues_text(r.issues));
    require(!r.complete,label+": incomplete");require(r.contacts.empty(),label+": staged contacts discarded");
    require(r.generation==generation,label+": generation echoed");
    require(!clear(r),label+": incomplete empty query must not be mistaken for clear");
}
v::CapsuleQuery query(v::Vec3 a,v::Vec3 b,double r=.1,double c=.02) {
    return {73,9011,a,b,r,c};
}
const v::Contact& first_for(const v::ContactResult& r,v::Id id) {
    const auto it=std::find_if(r.contacts.begin(),r.contacts.end(),[&](const auto& c){return c.obstacle_id==id;});
    require(it!=r.contacts.end(),"expected obstacle contact "+std::to_string(id));return *it;
}
void qualify(const v::Contact& c,const v::CapsuleQuery& q,const v::Obstacle& o,double query_tolerance=1e-6,double numeric=kExact) {
    require(c.witness_qualified,"witness qualified flag");
    require(c.obstacle_id==o.id&&c.guide_id==q.guide_id&&c.span_id==q.span_id,"caller IDs preserved");
    require(finite(c.axis_point)&&finite(c.obstacle_point)&&finite(c.outward_normal),"finite witness vectors");
    require(std::isfinite(c.material_u)&&c.material_u>=0&&c.material_u<=1,"u belongs to directed span");
    near_vec(c.axis_point,add(q.a,mul(sub(q.b,q.a),c.material_u)),numeric,"axis/u reconstruction");
    near(length(c.outward_normal),1.0,numeric,"unit outward normal");
    near(c.signed_gap_m,dot(c.outward_normal,sub(c.axis_point,c.obstacle_point))-q.geometric_radius_m-q.clearance_m,numeric,"gap reconstructed with radius/clearance once");
    require(c.signed_gap_m<=query_tolerance+numeric,"returned contact lies in requested contact band");
    if(o.kind==v::ObstacleKind::Sphere) {
        near(length(sub(c.obstacle_point,o.center)),o.sphere_radius,numeric,"sphere surface witness");
        near_vec(c.outward_normal,mul(sub(c.obstacle_point,o.center),1/o.sphere_radius),numeric,"sphere outward sign");
    } else {
        const auto p=inverse_rotate(o.orientation,sub(c.obstacle_point,o.center));
        const auto n=inverse_rotate(o.orientation,c.outward_normal);
        const auto h=o.box_half_extents;
        require(std::abs(p.x)<=h.x+numeric&&std::abs(p.y)<=h.y+numeric&&std::abs(p.z)<=h.z+numeric,"OBB witness within all slabs");
        require(std::min({std::abs(std::abs(p.x)-h.x),std::abs(std::abs(p.y)-h.y),std::abs(std::abs(p.z)-h.z)})<=numeric,"OBB witness belongs to surface");
        // A supporting outward normal must not point towards any of the eight vertices.
        for(int ix:{-1,1})for(int iy:{-1,1})for(int iz:{-1,1})
            require(dot(n,sub({ix*h.x,iy*h.y,iz*h.z},p))<=numeric,"OBB supporting outward normal");
    }
}
void same_contacts(const v::ContactResult& a,const v::ContactResult& b,double tolerance=kExact) {
    require(a.outcome==b.outcome&&a.complete==b.complete&&a.generation==b.generation,"repeat status/generation");
    require(a.contacts.size()==b.contacts.size(),"repeat contact count");
    for(std::size_t i=0;i<a.contacts.size();++i) {
        const auto& x=a.contacts[i];const auto& y=b.contacts[i];
        require(x.obstacle_id==y.obstacle_id&&x.guide_id==y.guide_id&&x.span_id==y.span_id,"repeat stable IDs");
        require(x.witness_qualified==y.witness_qualified,"repeat witness flag");
        near(x.material_u,y.material_u,tolerance,"repeat u");near(x.signed_gap_m,y.signed_gap_m,tolerance,"repeat gap");
        near_vec(x.axis_point,y.axis_point,tolerance,"repeat axis");near_vec(x.obstacle_point,y.obstacle_point,tolerance,"repeat surface");near_vec(x.outward_normal,y.outward_normal,tolerance,"repeat normal");
    }
}

void identity_empty() {
    auto w=build(scene({},109));const auto id=w->backend();
    require(id.source_commit==kPin,"backend exact dependency pin");
    require(id.name.find("Jolt")!=std::string::npos||id.name.find("jolt")!=std::string::npos,"backend identifies real Jolt path");
    require(!id.build_flags.empty()&&!id.precision_profile.empty(),"backend reports build/precision identity");
    require(id.precision_profile.find("double")!=std::string::npos||id.precision_profile.find("Double")!=std::string::npos,"double world precision identity");
    complete_point(w->classify_point({1,2,3},0,{}),109,0);
    auto r=w->query_capsule(query({0,0,0},{0,1,0}),{});complete_contact(r,109);require(clear(r),"valid empty scene is complete clear");
    std::cout<<"BACKEND "<<id.name<<" | "<<id.precision_profile<<" | "<<id.build_flags<<'\n';
}
void point_sphere() {
    auto s=scene({sphere()});auto o=options();auto w=build(s,o);
    const auto check=[&](v::Vec3 p,double e,v::Location loc,double gap){auto r=w->classify_point(p,e,{});complete_point(r,s.generation,1);require(r.hits[0].location==loc,"sphere point location");near(r.hits[0].signed_gap_m,gap,kExact,"sphere exact exclusion gap");};
    check({0,0,0},0,v::Location::Inside,-1);
    check({.2,0,0},.1,v::Location::Inside,-.9);
    check({1.3,0,0},.1,v::Location::Outside,.2);
    check({1.1,0,0},.1,v::Location::Boundary,0);
    check({1.1+.25e-6,0,0},.1,v::Location::Boundary,.25e-6);
    check({1.1-.25e-6,0,0},.1,v::Location::Boundary,-.25e-6);
    check({1.1+4e-6,0,0},.1,v::Location::Outside,4e-6);
    check({1.1-4e-6,0,0},.1,v::Location::Inside,-4e-6);
}
void point_box() {
    const auto b=box();auto s=scene({b});auto w=build(s);
    const auto check=[&](v::Vec3 p,double e,v::Location loc,double gap){auto r=w->classify_point(to_patch(b,p),e,{});complete_point(r,s.generation,1);require(r.hits[0].location==loc,"rotated box point location");near(r.hits[0].signed_gap_m,gap,kExact,"rotated box exact exclusion gap");};
    check({0,0,0},0,v::Location::Inside,-.55);
    check({.2,0,.1},.2,v::Location::Inside,-.75);
    check({1.55,.1,.2},.1,v::Location::Outside,.2);
    check({1.55,.95,.2},.2,v::Location::Outside,.3); // .3/.4 right triangle outside a box edge.
    check({.1,.70,.2},.15,v::Location::Boundary,0);
    check({.1,.70+.25e-6,.2},.15,v::Location::Boundary,.25e-6);
    check({.1,.70-4e-6,.2},.15,v::Location::Inside,-4e-6);
}
void capsule_sphere() {
    const auto o=sphere();auto s=scene({o});auto w=build(s);
    auto q=query({-2,1.05,0},{2,1.05,0});auto r=w->query_capsule(q,{});complete_contact(r,s.generation);
    auto c=first_for(r,o.id);qualify(c,q,o);near(c.material_u,.5,kExact,"sphere tangent witness u");near(c.signed_gap_m,-.07,kExact,"sphere analytic capsule gap");near_vec(c.outward_normal,{0,1,0},kExact,"sphere above normal");
    q=query({-2,1.3,0},{2,1.3,0});r=w->query_capsule(q,{});complete_contact(r,s.generation);require(clear(r),"separated sphere capsule clear control");
    q=query({1.05,0,0},{2,0,0},.1,0);r=w->query_capsule(q,{});complete_contact(r,s.generation);c=first_for(r,o.id);qualify(c,q,o);near(c.material_u,0,kExact,"endpoint u0");near(c.signed_gap_m,-.05,kExact,"endpoint analytic gap");
    std::swap(q.a,q.b);r=w->query_capsule(q,{});complete_contact(r,s.generation);c=first_for(r,o.id);qualify(c,q,o);near(c.material_u,1,kExact,"reversed endpoint u1");
    q=query({-2,0,0},{2,0,0},.01,0);
    for(auto p:{q.a,q.b}){auto pr=w->classify_point(p,0,{});complete_point(pr,s.generation,1);require(pr.hits[0].location==v::Location::Outside,"crossing endpoints outside");}
    r=w->query_capsule(q,{});complete_contact(r,s.generation);c=first_for(r,o.id);qualify(c,q,o);require(c.signed_gap_m<-.5,"crossing segment detected");same_contacts(r,w->query_capsule(q,{}));
    q=query({.1,0,0},{.3,0,0},.01,0);r=w->query_capsule(q,{});complete_contact(r,s.generation);c=first_for(r,o.id);qualify(c,q,o);require(c.signed_gap_m<0,"entire capsule axis inside solid");
}
void capsule_box() {
    const auto b=box();auto s=scene({b});auto w=build(s);
    auto q=query(to_patch(b,{1.30,-.3,.1}),to_patch(b,{1.30,.3,.1}));auto r=w->query_capsule(q,{});complete_contact(r,s.generation);auto c=first_for(r,b.id);qualify(c,q,b);
    near(c.signed_gap_m,-.07,kExact,"rotated box face gap");near_vec(c.outward_normal,rotate(b.orientation,{1,0,0}),kExact,"box face outward normal");
    q=query(to_patch(b,{1.31,.63,.1}),to_patch(b,{1.71,1.03,.1}),.1,.025);r=w->query_capsule(q,{});complete_contact(r,s.generation);c=first_for(r,b.id);qualify(c,q,b);near(c.material_u,0,kExact,"box corner endpoint u");near(c.signed_gap_m,-.025,kExact,"box corner Euclidean gap");near_vec(c.outward_normal,rotate(b.orientation,{.6,.8,0}),kExact,"box corner outward normal");
    q=query(to_patch(b,{1.45,-.3,.1}),to_patch(b,{1.45,.3,.1}));r=w->query_capsule(q,{});complete_contact(r,s.generation);require(clear(r),"box separated face clear control");
    q=query(to_patch(b,{-2,0,0}),to_patch(b,{2,0,0}),.01,0);
    for(auto p:{q.a,q.b}){auto pr=w->classify_point(p,0,{});complete_point(pr,s.generation,1);require(pr.hits[0].location==v::Location::Outside,"rotated crossing endpoints outside");}
    r=w->query_capsule(q,{});complete_contact(r,s.generation);c=first_for(r,b.id);qualify(c,q,b);require(c.signed_gap_m<0,"OBB complete segment crossing");
    q=query(to_patch(b,{.1,.1,0}),to_patch(b,{.2,.2,.1}),.01,0);r=w->query_capsule(q,{});complete_contact(r,s.generation);c=first_for(r,b.id);qualify(c,q,b);require(c.signed_gap_m<0,"capsule wholly inside OBB is contact");

    // The adapter declares one deepest centerline-SDF witness per obstacle.
    // A finite point sample is an upper bound on the continuous minimum; it
    // cannot prove absence, so no clear claim is based only on positive samples.
    FixedRandom random;
    constexpr std::size_t trials=200;
    constexpr std::size_t samples=501;
    std::size_t sampled_contacts=0;
    std::size_t returned_contacts=0;
    double max_gap_above_sample=0;
    double max_witness_sdf_error=0;
    for(std::size_t trial=0;trial<trials;++trial) {
        auto rb=box(100000+static_cast<v::Id>(trial));
        rb.center=random.vector(-3,3);
        rb.box_half_extents=random.vector(.08,1.25);
        auto rotation_axis=random.vector(-1,1);
        if(length(rotation_axis)<.1)rotation_axis.x=1;
        rb.orientation=rotation(rotation_axis,random.range(-std::numbers::pi,std::numbers::pi));
        const auto h=rb.box_half_extents;
        const double radius=random.range(.005,.12);
        const double clearance=random.range(0,.04);
        auto a=random.vector(-2,2);
        auto b_local=random.vector(-2,2);
        a={a.x*h.x,a.y*h.y,a.z*h.z};
        b_local={b_local.x*h.x,b_local.y*h.y,b_local.z*h.z};
        if(trial%4==1) {
            auto direction=random.vector(-1,1);
            if(length(direction)<.1)direction.z=1;
            direction=normalized(direction);
            const double span_half=3*std::max({h.x,h.y,h.z});
            const v::Vec3 midpoint{.07*h.x,-.05*h.y,.03*h.z};
            a=sub(midpoint,mul(direction,span_half));
            b_local=add(midpoint,mul(direction,span_half));
        } else if(trial%4==2) {
            a={h.x+.5*radius,-.8*h.y,.1*h.z};
            b_local={h.x+.5*radius,.8*h.y,-.1*h.z};
        } else if(trial%4==3) {
            a={h.x+.25+radius+clearance,-.8*h.y,.1*h.z};
            b_local={h.x+.25+radius+clearance,.8*h.y,-.1*h.z};
        }
        if(length(sub(b_local,a))<.001)b_local.z+=.1;
        const auto random_scene=scene({rb},20000+static_cast<v::Generation>(trial));
        auto random_world=build(random_scene);
        const auto random_query=query(to_patch(rb,a),to_patch(rb,b_local),radius,clearance);
        const auto random_result=random_world->query_capsule(random_query,{});
        complete_contact(random_result,random_scene.generation);
        double sampled_min=std::numeric_limits<double>::infinity();
        for(std::size_t sample=0;sample<samples;++sample) {
            const double u=static_cast<double>(sample)/static_cast<double>(samples-1);
            const auto p=add(a,mul(sub(b_local,a),u));
            sampled_min=std::min(sampled_min,box_point_sdf(p,h)-radius-clearance);
        }
        if(sampled_min<=options().query_tolerance_m-2e-10) {
            ++sampled_contacts;
            require(!random_result.contacts.empty(),"sampled OBB contact cannot be complete clear");
        }
        for(const auto& contact:random_result.contacts) {
            ++returned_contacts;
            qualify(contact,random_query,rb);
            const auto local_axis=inverse_rotate(rb.orientation,sub(contact.axis_point,rb.center));
            const double witness_gap=box_point_sdf(local_axis,h)-radius-clearance;
            max_witness_sdf_error=std::max(max_witness_sdf_error,std::abs(contact.signed_gap_m-witness_gap));
            near(contact.signed_gap_m,witness_gap,kExact,"sampled OBB witness point-SDF consistency");
            max_gap_above_sample=std::max(max_gap_above_sample,contact.signed_gap_m-sampled_min);
            require(contact.signed_gap_m<=sampled_min+2e-10,"declared deepest OBB witness no worse than sampled minimum");
        }
    }
    std::cout<<std::setprecision(17)
        <<"{\"control\":\"independent_analytic_sampled_obb\",\"trials\":"<<trials
        <<",\"samples_per_span\":"<<samples<<",\"sampled_contacts\":"<<sampled_contacts
        <<",\"returned_contacts\":"<<returned_contacts
        <<",\"max_gap_above_sampled_minimum\":"<<max_gap_above_sample
        <<",\"max_witness_sdf_error\":"<<max_witness_sdf_error<<"}\n";
}
void capsule_axes() {
    const auto o=sphere();auto s=scene({o});auto w=build(s);
    const std::array<v::Vec3,7> directions={v::Vec3{1,0,0},{0,1,0},{0,0,1},{-1,0,0},{0,-1,0},{0,0,-1},{1,2,3}};
    for(const auto raw:directions){const auto d=normalized(raw);const auto n=normalized(cross(d,std::abs(d.x)<.8?v::Vec3{1,0,0}:v::Vec3{0,1,0}));const auto center=mul(n,1.05);const auto q=query(sub(center,mul(d,.75)),add(center,mul(d,2.25)),.1,0);auto r=w->query_capsule(q,{});complete_contact(r,s.generation);const auto c=first_for(r,o.id);qualify(c,q,o);near(c.material_u,.25,kExact,"axis orientation unique u");near(c.signed_gap_m,-.05,kExact,"axis orientation exact gap");near_vec(c.outward_normal,n,kExact,"axis orientation expected normal");}
}
void two_obstacles() {
    auto b=box(21);b.center={1,0,0};b.box_half_extents={.4,.5,.3};b.orientation=rotation({0,0,1},.45);
    const auto a=sphere(900,{-1,0,0},.5);const auto distant=sphere(333,{0,7,0},.5);
    auto s=scene({a,distant,b},801);auto w=build(s);const auto q=query({-2,0,0},{2,0,0},.02,0);auto r=w->query_capsule(q,{});complete_contact(r,s.generation);
    qualify(first_for(r,a.id),q,a);qualify(first_for(r,b.id),q,b);
    require(std::none_of(r.contacts.begin(),r.contacts.end(),[&](const auto& c){return c.obstacle_id==distant.id;}),"irrelevant obstacle excluded from contacts");
    const auto pr=w->classify_point({0,0,0},.01,{});complete_point(pr,s.generation,3);require(pr.hits[0].obstacle_id==21&&pr.hits[1].obstacle_id==333&&pr.hits[2].obstacle_id==900,"stable IDs survive sorting");
    std::reverse(s.obstacles.begin(),s.obstacles.end());auto reordered=build(s);same_contacts(r,reordered->query_capsule(q,{}));
}
void invalid_inputs() {
    const auto valid=scene({sphere()});const auto opt=options();
    auto s=valid;s.generation=0;failed_build(s,opt,v::Outcome::InvalidInput,"zero generation");
    s=valid;s.obstacles[0].id=0;failed_build(s,opt,v::Outcome::InvalidInput,"zero obstacle ID");
    s=valid;s.obstacles[0].geometry_revision=0;failed_build(s,opt,v::Outcome::InvalidInput,"zero geometry revision");
    s=valid;s.obstacles[0].pose_revision=0;failed_build(s,opt,v::Outcome::InvalidInput,"zero pose revision");
    s=valid;s.obstacles.push_back(s.obstacles[0]);failed_build(s,opt,v::Outcome::InvalidInput,"duplicate obstacle ID");
    s=valid;s.obstacles[0].sphere_radius=0;failed_build(s,opt,v::Outcome::InvalidInput,"zero sphere dimension");
    s=valid;s.obstacles[0].center.y=std::numeric_limits<double>::quiet_NaN();failed_build(s,opt,v::Outcome::InvalidInput,"nonfinite center");
    s=valid;s.obstacles[0].box_half_extents.y=std::numeric_limits<double>::quiet_NaN();failed_build(s,opt,v::Outcome::InvalidInput,"nonfinite inactive sphere box dimension");
    s=scene({box()});s.obstacles[0].sphere_radius=std::numeric_limits<double>::infinity();failed_build(s,opt,v::Outcome::InvalidInput,"nonfinite inactive box sphere radius");
    s=valid;s.obstacles[0].orientation.w=2;failed_build(s,opt,v::Outcome::InvalidInput,"nonunit orientation cannot encode scale");
    s=scene({box()});s.obstacles[0].box_half_extents.z=-1;failed_build(s,opt,v::Outcome::InvalidInput,"negative box dimension");
    s=valid;s.obstacles[0].kind=static_cast<v::ObstacleKind>(99);failed_build(s,opt,v::Outcome::Unsupported,"unsupported shape enum");
    auto badopt=opt;badopt.query_tolerance_m=std::numeric_limits<double>::infinity();failed_build(valid,badopt,v::Outcome::InvalidInput,"nonfinite query tolerance");
    badopt=opt;badopt.min_supported_feature_m=0;failed_build(valid,badopt,v::Outcome::InvalidInput,"zero feature profile");
    auto w=build(valid);auto q=query({0,0,0},{0,1,0});
    auto badq=q;badq.a.z=std::numeric_limits<double>::infinity();failed_contact(w->query_capsule(badq,{}),valid.generation,v::Outcome::InvalidInput,"nonfinite query");
    badq=q;badq.guide_id=0;failed_contact(w->query_capsule(badq,{}),valid.generation,v::Outcome::InvalidInput,"zero guide ID");
    badq=q;badq.span_id=0;failed_contact(w->query_capsule(badq,{}),valid.generation,v::Outcome::InvalidInput,"zero span ID");
    badq=q;badq.b=badq.a;failed_contact(w->query_capsule(badq,{}),valid.generation,v::Outcome::InvalidInput,"degenerate segment");
    badq=q;badq.geometric_radius_m=-1;failed_contact(w->query_capsule(badq,{}),valid.generation,v::Outcome::InvalidInput,"negative radius");
    badq=q;badq.clearance_m=-1;failed_contact(w->query_capsule(badq,{}),valid.generation,v::Outcome::InvalidInput,"negative clearance");
    failed_point(w->classify_point({std::numeric_limits<double>::quiet_NaN(),0,0},0,{}),valid.generation,v::Outcome::InvalidInput,"nonfinite point");
    failed_point(w->classify_point({0,0,0},-1,{}),valid.generation,v::Outcome::InvalidInput,"negative exclusion");
}
void limits() {
    const auto s=scene({sphere()});const auto defaults=options();
    using Member=std::size_t v::Limits::*;
    const std::array<Member,8> members={&v::Limits::max_obstacles,&v::Limits::max_nodes,&v::Limits::max_contacts_per_query,&v::Limits::max_query_calls,&v::Limits::max_iterations,&v::Limits::max_render_vertices,&v::Limits::max_render_triangles,&v::Limits::max_owned_and_scratch_bytes};
    for(const auto m:members){auto o=defaults;o.limits.*m=0;failed_build(s,o,v::Outcome::InvalidInput,"every zero limit invalid");}
    auto o=defaults;o.limits.max_owned_and_scratch_bytes=1;failed_build(s,o,v::Outcome::ResourceLimit,"tiny owned memory budget");
    const auto two=scene({sphere(2,{-.25,0,0}),sphere(1,{.25,0,0})});
    o=defaults;o.limits.max_obstacles=1;failed_build(two,o,v::Outcome::ResourceLimit,"obstacle count admission");
    o=defaults;o.limits.max_contacts_per_query=1;auto w=build(two,o);
    const auto q=query({-2,0,0},{2,0,0},.01,0);
    failed_contact(w->query_capsule(q,{}),two.generation,v::Outcome::ResourceLimit,"contact overflow discards partial result");
    failed_point(w->classify_point({4,0,0},0,{}),two.generation,v::Outcome::ResourceLimit,"point classification result budget");
    o=defaults;o.limits.max_query_calls=1;w=build(two,o);
    failed_contact(w->query_capsule(query({-2,5,0},{2,5,0}),{}),two.generation,v::Outcome::ResourceLimit,"incomplete clear-looking query is not clear");
    failed_point(w->classify_point({4,0,0},0,{}),two.generation,v::Outcome::ResourceLimit,"point native-query work budget");
    // Per-operation semantics: no hidden lifetime consumption on an immutable world.
    w=build(s,o);for(int i=0;i<3;++i){complete_point(w->classify_point({2,0,0},0,{}),s.generation,1);auto r=w->query_capsule(query({-2,5,0},{2,5,0}),{});complete_contact(r,s.generation);require(clear(r),"budget resets for each public operation");}
}
void cancellation() {
    const auto s=scene({sphere()});const auto o=options();std::atomic_bool cancelled{true};const v::Cancellation token{&cancelled};
    auto r=v::make_jolt_world(s,o,token);require(r.outcome==v::Outcome::Cancelled&&!r.world,"cancelled construction no world");
    auto w=build(s);failed_point(w->classify_point({0,0,0},0,token),s.generation,v::Outcome::Cancelled,"cancelled point");
    failed_contact(w->query_capsule(query({-2,0,0},{2,0,0}),token),s.generation,v::Outcome::Cancelled,"cancelled capsule");
    cancelled.store(false);complete_point(w->classify_point({0,0,0},0,token),s.generation,1);
    auto empty=build(scene({},17));cancelled.store(true);failed_contact(empty->query_capsule(query({0,0,0},{0,1,0}),token),17,v::Outcome::Cancelled,"cancelled empty scene cannot succeed");
}
void snapshot() {
    auto s=scene({sphere(912,{1,0,0},.5),box(88)},129);const auto original=s;auto w=build(s);
    const auto q=query({-.5,0,0},{2,0,0},.05,0);const auto before=w->query_capsule(q,{});complete_contact(before,129);require(!before.contacts.empty(),"snapshot fixture contact exists");
    s.generation=130;for(auto& ob:s.obstacles){ob.id+=10000;ob.center={500,500,500};ob.sphere_radius=4;ob.box_half_extents={7,8,9};ob.orientation=rotation({0,1,0},1.2);++ob.geometry_revision;++ob.pose_revision;}
    s.obstacles.clear();s.obstacles.shrink_to_fit();
    require(w->generation()==129,"caller snapshot edit cannot mutate world generation");
    same_contacts(before,w->query_capsule(q,{}));
    auto pr=w->classify_point({1,0,0},0,{});complete_point(pr,129,original.obstacles.size());
    require(pr.hits[0].obstacle_id==88&&pr.hits[1].obstacle_id==912,"caller IDs survive caller storage destruction");
    auto second=build(scene({},130));require(second->generation()==130,"successor owns its own generation");same_contacts(before,w->query_capsule(q,{}));
}
void lifetime() {
    const auto q=query({-2,0,0},{2,0,0},.01,0);
    const auto use=[&](const auto& w,v::Generation g,std::size_t expected){auto r=w->query_capsule(q,{});complete_contact(r,g);require(r.contacts.size()==expected,"surviving world after other teardown");};
    {
        auto a=build(scene({sphere()},1));auto b=build(scene({sphere(8,{0,.25,0},.5)},2));
        a.reset();use(b,2,1);auto c=build(scene({},3));use(c,3,0);b.reset();use(c,3,0);
    }
    {
        auto a=build(scene({sphere()},4));auto b=build(scene({sphere(8,{0,.25,0},.5)},5));
        b.reset();use(a,4,1);auto c=build(scene({},6));c.reset();use(a,4,1);
    }
    {
        auto a=build(scene({},7));auto b=build(scene({},8));a.reset();use(b,8,0);
    }
    {
        auto a=build(scene({},9));auto b=build(scene({},10));b.reset();use(a,9,0);
    }
    for(int i=0;i<3;++i){auto w=build(scene({sphere()},20+static_cast<v::Generation>(i)));use(w,20+static_cast<v::Generation>(i),1);}
}
void scale_profile() {
    auto o=options();auto s=scene({sphere()});
    auto tiny=s;tiny.obstacles[0].sphere_radius=.0005;failed_build(tiny,o,v::Outcome::Unsupported,"feature below declared profile");
    auto small_box=scene({box()});small_box.obstacles[0].box_half_extents.z=.0005;failed_build(small_box,o,v::Outcome::Unsupported,"box feature below profile");
    auto huge=s;huge.obstacles[0].center.x=1e20;failed_build(huge,o,v::Outcome::Unsupported,"coordinate outside local patch profile");
    huge=s;huge.obstacles[0].sphere_radius=1001;failed_build(huge,o,v::Outcome::Unsupported,"dimension above profile");
    auto invalid_profile=o;invalid_profile.query_tolerance_m=.001;failed_build(s,invalid_profile,v::Outcome::Unsupported,"tolerance exceeds feature ratio");
    auto w=build(s,o);auto q=query({0,0,0},{0,1,0},.0005,0);failed_contact(w->query_capsule(q,{}),s.generation,v::Outcome::Unsupported,"capsule radius below admitted feature");
    q=query({0,0,0},{0,.0005,0},.01,0);failed_contact(w->query_capsule(q,{}),s.generation,v::Outcome::Unsupported,"span below admitted feature");
    q=query({0,0,0},{1001,0,0},.01,0);failed_contact(w->query_capsule(q,{}),s.generation,v::Outcome::Unsupported,"span above profile");
    failed_point(w->classify_point({1e20,0,0},0,{}),s.generation,v::Outcome::Unsupported,"point outside profile");
    // New tiny profile is a distinct run; no historical small-scale result is reused.
    o.min_supported_feature_m=1e-6;o.query_tolerance_m=1e-10;
    const auto tiny_obstacle=sphere(61,{},1e-5);auto tw=build(scene({tiny_obstacle},61),o);
    q=query({-2e-5,1.05e-5,0},{2e-5,1.05e-5,0},1e-6,0);auto r=tw->query_capsule(q,{});complete_contact(r,61);const auto c=first_for(r,61);qualify(c,q,tiny_obstacle,o.query_tolerance_m,2e-12);near(c.signed_gap_m,-5e-7,2e-12,"tiny admitted analytic gap");
    // Large but admitted local coordinates retain offsets in the declared double profile.
    const auto big=sphere(7,{100000,-100000,100000},1);auto bw=build(scene({big},7));q=query(add(big.center,{-2,1.05,0}),add(big.center,{2,1.05,0}),.1,0);r=bw->query_capsule(q,{});complete_contact(r,7);const auto bc=first_for(r,7);qualify(bc,q,big,1e-6,2e-9);near(bc.signed_gap_m,-.05,2e-9,"admitted translated gap");
    // Coordinates can satisfy admission while a stricter requested precision
    // cannot qualify a result. Even an analytically separated fixture must
    // then report incomplete ambiguity rather than silently claiming clear.
    auto strict=options();strict.query_tolerance_m=1e-10;
    const auto translated=sphere(481,{100000,0,0},1);
    auto strict_world=build(scene({translated},481),strict);
    failed_point(strict_world->classify_point(add(translated.center,{3,0,0}),0,{}),481,v::Outcome::Ambiguous,"point precision bound exceeds requested tolerance");
    q=query(add(translated.center,{-2,3,0}),add(translated.center,{2,3,0}),.1,0);
    failed_contact(strict_world->query_capsule(q,{}),481,v::Outcome::Ambiguous,"clear-looking capsule cannot bypass precision ambiguity");
}
void repeatability() {
    auto a=sphere(78,{0,0,0},1);auto b=box(17);b.center={.1,.2,.3};auto s=scene({a,b},67);auto w=build(s);const auto q=query({-2,.1,.05},{2,.1,.05},.03,.01);const auto r=w->query_capsule(q,{});complete_contact(r,67);
    for(int i=0;i<6;++i)same_contacts(r,w->query_capsule(q,{}));
    auto sign=s;for(auto& obstacle:sign.obstacles){auto& t=obstacle.orientation;t={-t.x,-t.y,-t.z,-t.w};}
    auto other=build(sign);same_contacts(r,other->query_capsule(q,{}));
    std::reverse(sign.obstacles.begin(),sign.obstacles.end());auto reordered=build(sign);same_contacts(r,reordered->query_capsule(q,{}));
}

void native_observations() {
    // These metre-scale controls observe the actual public Jolt query result.
    // They deliberately use a float-engine allowance, not kExact.
    constexpr double raw_tolerance_m=3e-4;
    const auto o=options();
    const auto accounting=[&](const cd::QueryDiagnostics& trace) {
        require(trace.accounted_owned_bytes>0,"native diagnostics owned-memory accounting present");
        require(trace.accounted_scratch_bytes>0,"native diagnostics scratch accounting present");
        require(trace.accounted_owned_bytes<=o.limits.max_owned_and_scratch_bytes,"owned accounting within admitted budget");
        require(trace.accounted_scratch_bytes<=o.limits.max_owned_and_scratch_bytes-trace.accounted_owned_bytes,"owned plus scratch accounting within admitted budget");
    };
    const auto observe=[&](const char* label,const v::Obstacle& obstacle,const v::CapsuleQuery& q,v::Vec3 expected_normal) {
        const auto s=scene({obstacle},981);
        auto w=build(s,o);
        const auto inside=w->classify_point(obstacle.center,0,{});
        complete_point(inside,s.generation,1);
        require(inside.hits[0].location==v::Location::Inside,"native point interior control");
        const auto point_trace=cd::last_query_diagnostics();
        require(point_trace.operation==cd::NativeOperation::Point,"observed native point operation");
        require(point_trace.native_calls==1&&point_trace.native_hits>=1,"point classification actually dispatched and hit Jolt");
        accounting(point_trace);

        const auto result=w->query_capsule(q,{});
        complete_contact(result,s.generation);
        require(!result.contacts.empty(),"shallow native control contact");
        const auto trace=cd::last_query_diagnostics();
        require(trace.operation==cd::NativeOperation::Capsule,"observed native capsule operation");
        require(trace.native_calls==1&&trace.native_hits>=1,"capsule actually dispatched and hit Jolt");
        require(trace.analytic_contacts==result.contacts.size(),"separate analytic-contact observation count");
        require(trace.native_misses_refined==0,"ordinary native control requires no miss refinement");
        require(trace.first_raw_hit_available&&trace.first_raw_normal_valid,"actual native pair and valid normal available");
        require(trace.first_raw_obstacle_id==obstacle.id,"raw observation retains stable caller ID");
        require(finite(trace.first_raw_query_point)&&finite(trace.first_raw_obstacle_point)&&finite(trace.first_raw_outward_normal),"raw native vectors finite");
        accounting(trace);
        near(length(trace.first_raw_outward_normal),1,raw_tolerance_m,"raw Jolt normal unit length");
        near_vec(trace.first_raw_outward_normal,expected_normal,raw_tolerance_m,"raw Jolt outward normal control");
        near(trace.first_raw_penetration_depth_m,.07,raw_tolerance_m,"raw Jolt shallow penetration control");
        require(std::isfinite(trace.first_raw_consistency_error_m)&&trace.first_raw_consistency_error_m>=0&&trace.first_raw_consistency_error_m<=raw_tolerance_m,"raw Jolt reported witness/depth consistency");
        const double independently_reconstructed=dot(trace.first_raw_outward_normal,sub(trace.first_raw_query_point,trace.first_raw_obstacle_point));
        near(independently_reconstructed,-trace.first_raw_penetration_depth_m,raw_tolerance_m,"raw native pair/depth sign reconstruction");
        // Projection here tests membership of a raw capsule surface witness.
        // It does not assign material_u to the public contact or qualify a raw u.
        const auto delta=sub(q.b,q.a);
        const double projection=std::clamp(dot(sub(trace.first_raw_query_point,q.a),delta)/dot(delta,delta),0.0,1.0);
        const auto nearest_axis=add(q.a,mul(delta,projection));
        near(length(sub(trace.first_raw_query_point,nearest_axis)),q.geometric_radius_m+q.clearance_m,raw_tolerance_m,"raw native query witness on once-expanded capsule");
        if(obstacle.kind==v::ObstacleKind::Sphere) {
            near(length(sub(trace.first_raw_obstacle_point,obstacle.center)),obstacle.sphere_radius,raw_tolerance_m,"raw native sphere surface witness");
        } else {
            const auto local_point=inverse_rotate(obstacle.orientation,sub(trace.first_raw_obstacle_point,obstacle.center));
            near(box_point_sdf(local_point,obstacle.box_half_extents),0,raw_tolerance_m,"raw native rotated-box surface witness");
        }
        std::cout<<std::setprecision(17)
            <<"{\"control\":\"raw_public_jolt_observation\",\"fixture\":\""<<label
            <<"\",\"native_calls\":"<<trace.native_calls<<",\"native_hits\":"<<trace.native_hits
            <<",\"raw_penetration_depth_m\":"<<trace.first_raw_penetration_depth_m
            <<",\"raw_consistency_error_m\":"<<trace.first_raw_consistency_error_m
            <<",\"allowed_float_error_m\":"<<raw_tolerance_m
            <<",\"accounted_owned_bytes\":"<<trace.accounted_owned_bytes
            <<",\"accounted_scratch_bytes\":"<<trace.accounted_scratch_bytes<<"}\n";
    };
    const auto sph=sphere(1201);
    observe("sphere_span_X",sph,query({-2,1.05,0},{2,1.05,0}),{0,1,0});
    observe("sphere_span_Z",sph,query({0,1.05,-2},{0,1.05,2}),{0,1,0});
    const auto ob=box(1202);
    const auto normal=rotate(ob.orientation,{1,0,0});
    observe("rotated_box_local_span_Y",ob,query(to_patch(ob,{1.30,-.3,.1}),to_patch(ob,{1.30,.3,.1})),normal);
    observe("rotated_box_local_span_Z",ob,query(to_patch(ob,{1.30,.1,-.3}),to_patch(ob,{1.30,.1,.3})),normal);
}

using Test=std::pair<std::string_view,void(*)()>;
const std::array<Test,15> tests={{{"identity_empty",identity_empty},{"point_sphere",point_sphere},{"point_box",point_box},{"capsule_sphere",capsule_sphere},{"capsule_box",capsule_box},{"capsule_axes",capsule_axes},{"two_obstacles",two_obstacles},{"invalid_inputs",invalid_inputs},{"limits",limits},{"cancellation",cancellation},{"snapshot",snapshot},{"lifetime",lifetime},{"scale_profile",scale_profile},{"repeatability",repeatability},{"native_observations",native_observations}}};
std::string escape(std::string_view text) {
    std::string out;for(char c:text){if(c=='\\'||c=='"')out+='\\';if(c=='\n')out+="\\n";else if(c=='\r')out+="\\r";else out+=c;}return out;
}
}
int main(int argc,char** argv) {
    if(argc!=2){std::cerr<<"Usage: cyrus_collision_tests <case|all>\nCases:";for(const auto& t:tests)std::cerr<<' '<<t.first;std::cerr<<'\n';return 2;}
    const std::string_view requested=argv[1];bool found=false,failed=false;
    for(const auto& [name,fn]:tests){if(requested!="all"&&requested!=name)continue;found=true;check_count=0;largest_expected_error=0;
        try{fn();std::cout<<std::setprecision(17)<<"{\"case\":\""<<name<<"\",\"status\":\"passed\",\"checks\":"<<check_count<<",\"largest_expected_numeric_error\":"<<largest_expected_error<<",\"evidence\":\""<<(name=="native_observations"?"new raw public-Jolt observations; explicit float-engine tolerance":"new public-adapter test; independent analytic controls")<<"\"}\n";}
        catch(const std::exception& e){failed=true;std::cerr<<"{\"case\":\""<<name<<"\",\"status\":\"failed\",\"checks_before_failure\":"<<check_count<<",\"error\":\""<<escape(e.what())<<"\"}\n";}
        catch(...){failed=true;std::cerr<<"{\"case\":\""<<name<<"\",\"status\":\"failed\",\"error\":\"nonstandard exception\"}\n";}
    }
    if(!found){std::cerr<<"Unknown case\n";return 2;}return failed?1:0;
}
