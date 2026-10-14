#include "surface_filter.h"
#include <algorithm>
#include <cmath>
#include <stdexcept>

namespace cyrus::surface_filter {
void validate(const Settings& s) {
    for(const auto* r : {&s.slope, &s.altitude}) {
        if(!r->enabled) continue;
        if(!std::isfinite(r->minimum)||!std::isfinite(r->maximum)||
           !std::isfinite(r->lowerFade)||!std::isfinite(r->upperFade)||
           r->minimum>r->maximum||!std::isfinite(r->maximum-r->minimum)||
           r->lowerFade<0||r->upperFade<0||
           r->lowerFade>r->maximum-r->minimum||
           r->upperFade>r->maximum-r->minimum-r->lowerFade)
            throw std::invalid_argument(r==&s.slope ?
                "Slope filter: use ordered finite bounds and non-overlapping inside fades" :
                "Altitude filter: use ordered finite bounds and non-overlapping inside fades");
    }
    if(s.slope.enabled&&(s.slope.minimum<0||s.slope.maximum>180))
        throw std::invalid_argument("Slope filter bounds must be 0..180 degrees from world up");
}
double intervalWeight(double value, const Interval& r) {
    if(!r.enabled) return 1;
    if(!std::isfinite(value)) throw std::invalid_argument("Nonfinite surface filter input");
    if(value<r.minimum||value>r.maximum) return 0;
    const auto smooth=[](double t){t=std::clamp(t,0.0,1.0);return t*t*(3-2*t);};
    const double lo=r.lowerFade==0?1:smooth((value-r.minimum)/r.lowerFade);
    const double hi=r.upperFade==0?1:smooth((r.maximum-value)/r.upperFade);
    return lo*hi;
}
double slopeDegrees(const amin::Triangle& t) {
    auto x=t.b-t.a,y=t.c-t.a;
    const double scale=std::max({std::abs(x.x),std::abs(x.y),std::abs(x.z),
                                 std::abs(y.x),std::abs(y.y),std::abs(y.z)});
    if(!std::isfinite(scale)||scale==0) throw std::invalid_argument("Invalid surface filter triangle");
    x=x*(1/scale);y=y*(1/scale);
    const amin::Vec3 n{x.y*y.z-x.z*y.y,x.z*y.x-x.x*y.z,x.x*y.y-x.y*y.x};
    const double xy=std::hypot(n.x,n.y);
    if(!std::isfinite(xy)||!std::isfinite(n.z)||(xy==0&&n.z==0))
        throw std::invalid_argument("Degenerate surface filter triangle");
    return std::atan2(xy,n.z)*(180.0/3.14159265358979323846);
}
bool accepts(const Settings& s,double slope,double altitude,std::uint32_t seed,
             std::uint64_t ordinal,std::uint64_t receiverSalt) {
    const double weight=intervalWeight(slope,s.slope)*intervalWeight(altitude,s.altitude);
    return weight>=1 || (weight>0 && amin::stableUnit(seed,ordinal,0x5355524641434531ULL,receiverSalt)<weight);
}
double anchorAltitude(const amin::Triangle& t,amin::Vec3 b) {
    // Relative interpolation preserves an exactly flat height even when the
    // saved float barycentric components do not sum to exactly one in double.
    const double z=t.a.z+(t.b.z-t.a.z)*b.y+(t.c.z-t.a.z)*b.z;
    if(!std::isfinite(z))throw std::invalid_argument("Nonfinite surface filter anchor altitude");
    return z;
}
}
