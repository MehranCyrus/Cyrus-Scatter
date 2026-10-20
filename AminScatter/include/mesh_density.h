#pragma once
#include "scatter.h"

namespace cyrus::mesh_density {
struct Settings {
    bool enabled=false, invert=false;
    int channel=0, component=0, source=1; // 1: authored mesh channel, 2: relative local elevation
    double minimum=0, maximum=1;
    std::vector<double> curve{0,1};
};
void validate(const Settings&);
double weight(double value,const Settings&);
double sample(const std::array<double,3>& corners,amin::Vec3 barycentric);
double relativeElevation(double z,double minimum,double maximum);
bool accepts(double weight,std::uint32_t seed,std::uint64_t ordinal,std::uint64_t salt);
constexpr std::size_t faceLimit=2000000;
constexpr std::size_t previewLimit=2048;
}
