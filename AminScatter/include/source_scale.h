#pragma once
#include <array>
#include <cmath>
#include <limits>
#include <stdexcept>

namespace cyrus::source_scale {
using Axes=std::array<std::array<double,3>,3>;
// Source placement ignores authored position/orientation, but retains the
// positive scale of its evaluated node frame. Keep object-offset geometry in
// its original pivot-local coordinates; scaling that mesh as well would double it.
inline std::array<double,3> factors(const Axes& rows){
    auto dot=[](const auto& a,const auto& b){return a[0]*b[0]+a[1]*b[1]+a[2]*b[2];};
    std::array<double,3> scale{};
    for(unsigned i=0;i<3;++i){for(double x:rows[i])if(!std::isfinite(x))throw std::invalid_argument("Source node scale is nonfinite.");
        scale[i]=std::sqrt(dot(rows[i],rows[i]));if(!std::isfinite(scale[i])||scale[i]<1e-8)throw std::invalid_argument("Source node scale is singular. Restore a positive source scale.");}
    for(unsigned i=0;i<3;++i)for(unsigned j=i+1;j<3;++j)if(std::abs(dot(rows[i],rows[j]))>scale[i]*scale[j]*1e-5)
        throw std::invalid_argument("Source node scale contains shear. Reset its transform before scattering.");
    const auto& a=rows[0];const auto& b=rows[1];const auto& c=rows[2];
    const double determinant=a[0]*(b[1]*c[2]-b[2]*c[1])-a[1]*(b[0]*c[2]-b[2]*c[0])+a[2]*(b[0]*c[1]-b[1]*c[0]);
    if(!std::isfinite(determinant)||determinant<=0)throw std::invalid_argument("Mirrored source node scale is unsupported. Reset its transform before scattering.");
    return scale;
}
inline std::array<float,3> compose(const std::array<double,3>& scale,double multiplier){
    if(!std::isfinite(multiplier)||multiplier<0)throw std::invalid_argument("Model Scale must be finite and nonnegative.");
    std::array<float,3> result{};for(unsigned i=0;i<3;++i){const double value=scale[i]*multiplier;
        if(!std::isfinite(scale[i])||scale[i]<=0||!std::isfinite(value)||value>std::numeric_limits<float>::max())throw std::invalid_argument("Combined source and model Scale is outside the supported range.");
        result[i]=static_cast<float>(value);}
    return result;
}
}
