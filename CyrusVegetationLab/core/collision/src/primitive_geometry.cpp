#include "primitive_geometry.hpp"

#include <algorithm>
#include <array>
#include <cmath>
#include <limits>

namespace cyrus::vegetation::prototype_v1::collision_detail {
namespace {

constexpr double eps = std::numeric_limits<double>::epsilon();

Vec3 add(Vec3 a, Vec3 b) noexcept { return {a.x+b.x,a.y+b.y,a.z+b.z}; }
Vec3 sub(Vec3 a, Vec3 b) noexcept { return {a.x-b.x,a.y-b.y,a.z-b.z}; }
Vec3 mul(Vec3 a,double s) noexcept { return {a.x*s,a.y*s,a.z*s}; }
double dot(Vec3 a,Vec3 b) noexcept { return a.x*b.x+a.y*b.y+a.z*b.z; }
Vec3 cross(Vec3 a,Vec3 b) noexcept {
    return {a.y*b.z-a.z*b.y,a.z*b.x-a.x*b.z,a.x*b.y-a.y*b.x};
}
double norm(Vec3 a) noexcept { return std::hypot(a.x,a.y,a.z); }
double component(Vec3 v,int i) noexcept { return i==0?v.x:(i==1?v.y:v.z); }
void set_component(Vec3& v,int i,double x) noexcept {
    if(i==0)v.x=x;else if(i==1)v.y=x;else v.z=x;
}
bool finite(Vec3 v) noexcept {
    return std::isfinite(v.x)&&std::isfinite(v.y)&&std::isfinite(v.z);
}
double magnitude(Vec3 v) noexcept {
    return std::max({std::abs(v.x),std::abs(v.y),std::abs(v.z)});
}
Vec3 lerp(Vec3 a,Vec3 b,double u) noexcept { return add(a,mul(sub(b,a),u)); }

bool unit_quaternion(Quat input,Quat& output) noexcept {
    const double n=std::hypot(std::hypot(input.x,input.y),std::hypot(input.z,input.w));
    if(!std::isfinite(n)||n==0.0||std::abs(n-1.0)>1.0e-8)return false;
    output={input.x/n,input.y/n,input.z/n,input.w/n};
    return true;
}
Vec3 rotate(Quat q,Vec3 v) noexcept {
    const Vec3 xyz{q.x,q.y,q.z};
    const Vec3 t=mul(cross(xyz,v),2.0);
    return add(add(v,mul(t,q.w)),cross(xyz,t));
}
Vec3 unrotate(Quat q,Vec3 v) noexcept {
    return rotate({-q.x,-q.y,-q.z,q.w},v);
}
bool basic_obstacle(const Obstacle& o,Quat& q) noexcept {
    if(!finite(o.center)||!unit_quaternion(o.orientation,q))return false;
    if(o.kind==ObstacleKind::Sphere)
        return std::isfinite(o.sphere_radius)&&o.sphere_radius>0.0;
    if(o.kind==ObstacleKind::Box)
        return finite(o.box_half_extents)&&o.box_half_extents.x>0.0&&
               o.box_half_extents.y>0.0&&o.box_half_extents.z>0.0;
    return false;
}
double roundoff_bound(const Obstacle& o,Vec3 a,Vec3 b) noexcept {
    const double extent=o.kind==ObstacleKind::Sphere?o.sphere_radius:magnitude(o.box_half_extents);
    const double scale=std::max({1.0,magnitude(o.center),magnitude(a),magnitude(b),extent,norm(sub(b,a))});
    return 1024.0*eps*scale;
}

// At an exact sphere center the radial normal is not unique. For a nonzero
// segment choose a deterministic transverse direction (least aligned basis),
// avoiding a normal that would just slide a crossing span along itself.
Vec3 central_normal(Vec3 direction) noexcept {
    const double length=norm(direction);
    if(!(length>0.0)||!std::isfinite(length))return {1,0,0};
    const Vec3 t=mul(direction,1.0/length);
    int axis=0;
    if(std::abs(t.y)<std::abs(t.x))axis=1;
    if(std::abs(t.z)<std::abs(component(t,axis)))axis=2;
    Vec3 basis{};set_component(basis,axis,1.0);
    Vec3 n=cross(t,basis);
    const double size=norm(n);
    if(!(size>0.0)||!std::isfinite(size))return {1,0,0};
    n=mul(n,1.0/size);
    // Remove the directed-span sign from this nonunique-normal choice: a span
    // reversal should not select the opposite exit side merely through a tie.
    for(int i=0;i<3;++i){
        const double c=component(n,i);
        if(c!=0.0){if(c<0.0)n=mul(n,-1.0);break;}
    }
    return n;
}

GeometryWitness sphere_at(const Obstacle& o,Vec3 axis,double u,Vec3 direction) noexcept {
    GeometryWitness w;w.u=u;w.axis=axis;
    const Vec3 delta=sub(axis,o.center);
    const double distance=norm(delta);
    if(!std::isfinite(distance))return w;
    w.normal=distance>0.0?mul(delta,1.0/distance):central_normal(direction);
    w.surface=add(o.center,mul(w.normal,o.sphere_radius));
    w.axis_signed_distance=distance-o.sphere_radius;
    return w;
}

double box_signed_distance(Vec3 p,Vec3 h) noexcept {
    const Vec3 excess{std::abs(p.x)-h.x,std::abs(p.y)-h.y,std::abs(p.z)-h.z};
    const Vec3 outside{std::max(excess.x,0.0),std::max(excess.y,0.0),std::max(excess.z,0.0)};
    return norm(outside)+std::min(std::max({excess.x,excess.y,excess.z}),0.0);
}

GeometryWitness box_at(const Obstacle& o,Quat rotation,Vec3 axis,double u) noexcept {
    GeometryWitness w;w.u=u;w.axis=axis;
    const Vec3 h=o.box_half_extents,p=unrotate(rotation,sub(axis,o.center));
    Vec3 surface{std::clamp(p.x,-h.x,h.x),std::clamp(p.y,-h.y,h.y),std::clamp(p.z,-h.z,h.z)};
    const Vec3 delta=sub(p,surface);
    const double outside_distance=norm(delta);
    Vec3 normal{};
    if(outside_distance>0.0){
        normal=mul(delta,1.0/outside_distance);
        w.axis_signed_distance=outside_distance;
    }else{
        // Inside/boundary: nearest signed face distance, with deterministic
        // ties X before Y before Z, and positive face at coordinate zero.
        int face=0;double signed_distance=std::abs(p.x)-h.x;
        for(int i=1;i<3;++i){
            const double candidate=std::abs(component(p,i))-component(h,i);
            if(candidate>signed_distance){signed_distance=candidate;face=i;}
        }
        const double sign=component(p,face)<0.0?-1.0:1.0;
        set_component(normal,face,sign);
        set_component(surface,face,sign*component(h,face));
        w.axis_signed_distance=signed_distance;
    }
    w.normal=rotate(rotation,normal);
    // Normalize only rounding from a proper rigid transform. Qualification
    // below independently checks surface geometry and signed reconstruction.
    const double n=norm(w.normal);
    if(n>0.0&&std::isfinite(n))w.normal=mul(w.normal,1.0/n);
    w.surface=add(o.center,rotate(rotation,surface));
    return w;
}

// Complete finite candidate set for the segment's minimum box SDF.
// Outside: squared distance to an AABB is piecewise quadratic; breakpoints
// are the six slab planes. Each interval needs its endpoints and stationary
// point. Inside: SDF = max of six signed affine face distances, a convex
// piecewise-linear function. Its minimum lies at an endpoint, at a pairwise
// line intersection, or on a flat piece whose endpoint is already included.
double minimum_box_parameter(Vec3 a,Vec3 b,Vec3 h) noexcept {
    const Vec3 d=sub(b,a);
    double best_u=0.0,best_distance=box_signed_distance(a,h);
    auto consider=[&](double u) noexcept {
        if(!std::isfinite(u)||u<0.0||u>1.0)return;
        const double candidate=box_signed_distance(lerp(a,b,u),h);
        if(candidate<best_distance||(candidate==best_distance&&u<best_u)){
            best_u=u;best_distance=candidate;
        }
    };
    consider(1.0);
    std::array<double,8> cuts{};std::size_t count=2;cuts[0]=0.0;cuts[1]=1.0;
    for(int i=0;i<3;++i){
        const double velocity=component(d,i);
        if(velocity==0.0)continue;
        for(double sign:{-1.0,1.0}){
            const double u=(sign*component(h,i)-component(a,i))/velocity;
            if(u>0.0&&u<1.0&&std::isfinite(u))cuts[count++]=u;
        }
    }
    // Eight elements at most: explicit insertion sort keeps the work/memory
    // bound visible and avoids generic-library small-array overread warnings.
    for(std::size_t i=1;i<count;++i){
        const double value=cuts[i];std::size_t j=i;
        while(j>0&&cuts[j-1]>value){cuts[j]=cuts[j-1];--j;}
        cuts[j]=value;
    }
    for(std::size_t j=0;j<count;++j)consider(cuts[j]);
    for(std::size_t j=0;j+1<count;++j){
        const double lo=cuts[j],hi=cuts[j+1];if(!(hi>lo))continue;
        const double mid=lo+(hi-lo)*0.5;
        double quadratic=0.0,linear=0.0;
        for(int i=0;i<3;++i){
            const double ai=component(a,i),di=component(d,i),half=component(h,i);
            const double at_mid=ai+mid*di;
            double c=0.0;
            if(at_mid>half)c=ai-half;
            else if(at_mid<-half)c=ai+half;
            else continue;
            quadratic+=di*di;linear+=c*di;
        }
        if(quadratic>0.0&&std::isfinite(quadratic)&&std::isfinite(linear))
            consider(std::clamp(-linear/quadratic,lo,hi));
    }
    std::array<double,6> intercept{},slope{};
    for(int i=0;i<3;++i){
        intercept[2*i]=component(a,i)-component(h,i);slope[2*i]=component(d,i);
        intercept[2*i+1]=-component(a,i)-component(h,i);slope[2*i+1]=-component(d,i);
    }
    for(std::size_t i=0;i<6;++i)for(std::size_t j=i+1;j<6;++j){
        const double denominator=slope[i]-slope[j];
        if(denominator!=0.0)consider((intercept[j]-intercept[i])/denominator);
    }
    return best_u;
}

} // namespace

bool qualify_primitive_witness(const Obstacle& o,Vec3 a,Vec3 b,
                              const GeometryWitness& w) noexcept {
    Quat q;
    if(!basic_obstacle(o,q)||!finite(a)||!finite(b)||!std::isfinite(w.u)||
       w.u<0.0||w.u>1.0||!finite(w.axis)||!finite(w.surface)||!finite(w.normal)||
       !std::isfinite(w.axis_signed_distance))return false;
    const double bound=roundoff_bound(o,a,b);
    if(!std::isfinite(bound)||!(bound>0.0)||std::abs(norm(w.normal)-1.0)>4096.0*eps)
        return false;
    if(norm(sub(w.axis,lerp(a,b,w.u)))>bound)return false;
    if(std::abs(dot(w.normal,sub(w.axis,w.surface))-w.axis_signed_distance)>bound)
        return false;
    if(o.kind==ObstacleKind::Sphere){
        const Vec3 s=sub(w.surface,o.center);
        if(std::abs(norm(s)-o.sphere_radius)>bound)return false;
        if(norm(sub(s,mul(w.normal,o.sphere_radius)))>bound)return false;
        const double expected=norm(sub(w.axis,o.center))-o.sphere_radius;
        if(std::abs(expected-w.axis_signed_distance)>bound)return false;
    }else{
        const Vec3 p=unrotate(q,sub(w.axis,o.center));
        const Vec3 s=unrotate(q,sub(w.surface,o.center));
        const Vec3 n=unrotate(q,w.normal),h=o.box_half_extents;
        bool on_face=false;
        for(int i=0;i<3;++i){
            const double si=component(s,i),hi=component(h,i),ni=component(n,i);
            if(std::abs(si)>hi+bound)return false;
            const bool positive_face=std::abs(si-hi)<=bound;
            const bool negative_face=std::abs(si+hi)<=bound;
            on_face=on_face||positive_face||negative_face;
            // n belongs to the box's outward normal cone at the witness.
            if(ni>4096.0*eps&&!positive_face)return false;
            if(ni<-4096.0*eps&&!negative_face)return false;
        }
        if(!on_face||std::abs(box_signed_distance(p,h)-w.axis_signed_distance)>bound)
            return false;
    }
    return true;
}

GeometryWitness primitive_point(const Obstacle& o,Vec3 point) noexcept {
    GeometryWitness w;Quat q;
    if(!basic_obstacle(o,q)||!finite(point))return w;
    w=o.kind==ObstacleKind::Sphere?sphere_at(o,point,0.0,{}):box_at(o,q,point,0.0);
    w.numerical_bound_m=roundoff_bound(o,point,point);
    w.qualified=qualify_primitive_witness(o,point,point,w);
    return w;
}

GeometryWitness primitive_segment(const Obstacle& o,Vec3 a,Vec3 b) noexcept {
    GeometryWitness w;Quat q;
    if(!basic_obstacle(o,q)||!finite(a)||!finite(b))return w;
    const Vec3 d=sub(b,a);const double length=norm(d);
    if(!(length>0.0)||!std::isfinite(length))return w;
    double u=0.0;
    if(o.kind==ObstacleKind::Sphere){
        // Unit-direction projection avoids squaring the full segment length.
        const Vec3 direction=mul(d,1.0/length);
        u=std::clamp(dot(sub(o.center,a),direction)/length,0.0,1.0);
        w=sphere_at(o,lerp(a,b,u),u,d);
    }else{
        const Vec3 local_a=unrotate(q,sub(a,o.center));
        const Vec3 local_b=unrotate(q,sub(b,o.center));
        if(!finite(local_a)||!finite(local_b))return w;
        u=minimum_box_parameter(local_a,local_b,o.box_half_extents);
        w=box_at(o,q,lerp(a,b,u),u);
    }
    w.numerical_bound_m=roundoff_bound(o,a,b);
    w.qualified=qualify_primitive_witness(o,a,b,w);
    return w;
}

} // namespace cyrus::vegetation::prototype_v1::collision_detail
