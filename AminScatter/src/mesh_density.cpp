#include "mesh_density.h"
#include <algorithm>
#include <cmath>
#include <stdexcept>

namespace cyrus::mesh_density {
void validate(const Settings& s) {
    if(s.channel<0||s.channel>99||s.component<0||s.component>2)
        throw std::invalid_argument("Mesh density: choose channel 0..99 and component R/X, G/Y or B/Z");
    if(!std::isfinite(s.minimum)||!std::isfinite(s.maximum)||s.minimum>=s.maximum||!std::isfinite(s.maximum-s.minimum))
        throw std::invalid_argument("Mesh density: input minimum must be less than input maximum");
    if(s.curve.size()<2||s.curve.size()>257)
        throw std::invalid_argument("Mesh density: curve requires 2..257 samples");
    for(double v:s.curve)if(!std::isfinite(v)||v<0||v>1)
        throw std::invalid_argument("Mesh density: curve values must be finite and within 0..1");
}
double weight(double value,const Settings& s) {
    if(!std::isfinite(value))throw std::invalid_argument("Mesh density: nonfinite channel value");
    double t=std::clamp((value-s.minimum)/(s.maximum-s.minimum),0.0,1.0);
    if(s.invert)t=1-t;
    const double at=t*double(s.curve.size()-1);
    const auto i=std::min(std::size_t(at),s.curve.size()-2);
    return std::clamp(s.curve[i]+(s.curve[i+1]-s.curve[i])*(at-double(i)),0.0,1.0);
}
double sample(const std::array<double,3>& c,amin::Vec3 b) {
    if(!std::isfinite(b.x)||!std::isfinite(b.y)||!std::isfinite(b.z)||
       b.x<-.0001||b.y<-.0001||b.z<-.0001||std::abs(b.x+b.y+b.z-1)>0.0001)
        throw std::invalid_argument("Mesh density: invalid surface anchor");
    // Relative interpolation keeps an exactly constant channel constant.
    return c[0]+(c[1]-c[0])*b.y+(c[2]-c[0])*b.z;
}
bool accepts(double w,std::uint32_t seed,std::uint64_t ordinal,std::uint64_t salt) {
    return w>=1||(w>0&&amin::stableUnit(seed,ordinal,0x4d4553484d41534bULL,salt)<w);
}
}
