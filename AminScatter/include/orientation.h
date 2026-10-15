#pragma once
#include "scatter.h"
#include <array>
#include <vector>

namespace cyrus::orientation {
enum class Mode { Random=0, WorldDirection=1, Target=2 };
struct Settings {
    Mode mode=Mode::Random;
    bool align=true;
    double normalBlend=1;
    amin::Vec3 direction{0,1,0},target{};
};
using Frame=std::array<amin::Vec3,3>;
constexpr std::size_t maxFaces=10000000;
void validate(const Settings&);
// Copied world-space geometry only. Degenerate faces remain zero normals and
// reject only when a row actually needs their normal.
std::vector<amin::Vec3> normals(const std::vector<amin::Triangle>&);
amin::Vec3 blendedUp(amin::Vec3 normal,double blend);
Frame frame(amin::Vec3 normal,amin::Vec3 position,const Settings&);
amin::Instance orient(const amin::Instance&,amin::Vec3 normal,const Settings&,int forwardAxis);
// Input axes carry canonical random rotation/scale, with world +Z up. No RNG,
// host queries, candidate movement, source assignment or in-place publication.
std::vector<amin::Instance> apply(const std::vector<amin::Instance>&,
    const std::vector<amin::Vec3>& normals,const Settings&,const std::vector<int>& forwardAxes);
}
