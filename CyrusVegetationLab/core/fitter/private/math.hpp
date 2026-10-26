#pragma once
#include <cyrus_vegetation/prototype_v1.hpp>
#include <algorithm>
#include <cmath>
#include <limits>
#include <numbers>

namespace cyrus::vegetation::prototype_v1::fitter_detail {
constexpr double unit_epsilon = 1e-10;
constexpr double pole_epsilon = 1e-10;
constexpr double pi_epsilon = 1e-12;
inline bool finite(double x) { return std::isfinite(x); }
inline bool finite(Vec3 v) { return finite(v.x)&&finite(v.y)&&finite(v.z); }
inline bool finite(Quat q) { return finite(q.x)&&finite(q.y)&&finite(q.z)&&finite(q.w); }
inline Vec3 add(Vec3 a, Vec3 b) { return {a.x+b.x,a.y+b.y,a.z+b.z}; }
inline Vec3 sub(Vec3 a, Vec3 b) { return {a.x-b.x,a.y-b.y,a.z-b.z}; }
inline Vec3 mul(Vec3 a,double s) { return {a.x*s,a.y*s,a.z*s}; }
inline double dot(Vec3 a,Vec3 b) { return a.x*b.x+a.y*b.y+a.z*b.z; }
inline Vec3 cross(Vec3 a,Vec3 b) { return {a.y*b.z-a.z*b.y,a.z*b.x-a.x*b.z,a.x*b.y-a.y*b.x}; }
inline double norm(Vec3 v) { return std::hypot(v.x,v.y,v.z); }
inline bool unit(Vec3 v,Vec3& out) { double n=norm(v);if(!finite(n)||n==0)return false;out={v.x/n,v.y/n,v.z/n};return finite(out); }
inline Vec3 lerp(Vec3 a,Vec3 b,double u) { return add(mul(a,1-u),mul(b,u)); }
inline double qnorm(Quat q) { return std::hypot(std::hypot(q.x,q.y),std::hypot(q.z,q.w)); }
inline Quat qnormal(Quat q) { const double n=qnorm(q);return {q.x/n,q.y/n,q.z/n,q.w/n}; }
inline double qdot(Quat a,Quat b) { return a.x*b.x+a.y*b.y+a.z*b.z+a.w*b.w; }
inline Quat negate(Quat q) { return {-q.x,-q.y,-q.z,-q.w}; }
inline Quat conjugate(Quat q) { return {-q.x,-q.y,-q.z,q.w}; }
inline Quat product(Quat a,Quat b) {
 return {a.w*b.x+a.x*b.w+a.y*b.z-a.z*b.y,
         a.w*b.y-a.x*b.z+a.y*b.w+a.z*b.x,
         a.w*b.z+a.x*b.y-a.y*b.x+a.z*b.w,
         a.w*b.w-a.x*b.x-a.y*b.y-a.z*b.z};
}
inline Vec3 rotate(Quat q,Vec3 v) { const Vec3 u{q.x,q.y,q.z};const Vec3 t=mul(cross(u,v),2);return add(v,add(mul(t,q.w),cross(u,t))); }
inline Vec3 zaxis(Quat q) { return rotate(qnormal(q),{0,0,1}); }
inline double angle(Vec3 a,Vec3 b) { return std::atan2(norm(cross(a,b)),dot(a,b)); }
inline double qangle(Quat a,Quat b) {
 const Quat r=product(conjugate(qnormal(a)),qnormal(b));
 return 2*std::atan2(std::hypot(r.x,r.y,r.z),std::abs(r.w));
}
// No arbitrary perpendicular at an antipodal transport: reject that local chart.
inline bool swing(Vec3 a,Vec3 b,Quat& q) {
 const double d=std::clamp(dot(a,b),-1.0,1.0);const Vec3 c=cross(a,b);
 q={c.x,c.y,c.z,1+d};const double n=qnorm(q);
 if(!finite(n)||n<pole_epsilon)return false;
 q=qnormal(q);return finite(q);
}
inline Vec3 capped(Vec3 d,double maximum) {
 const double n=norm(d);if(n>maximum&&finite(n))return mul(d,maximum/n);return d;
}
template<class Points> bool tangent(const Points& p,std::size_t i,Vec3& t) {
 const std::size_t n=p.size();Vec3 a{},b{};
 if(i==0)return unit(sub(p[1],p[0]),t);
 if(i==n-1)return unit(sub(p[n-1],p[n-2]),t);
 if(!unit(sub(p[i],p[i-1]),a)||!unit(sub(p[i+1],p[i]),b))return false;
 Vec3 sum=add(a,b);if(norm(sum)<pole_epsilon)return false;return unit(sum,t);
}
} // namespace
