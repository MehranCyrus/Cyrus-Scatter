#pragma once
#include "scatter.h"
#include <cstddef>
#include <cstdint>
#include <vector>

namespace cyrus::grid {
enum class Mode : unsigned { Rectangular=1, Staggered=2, Hexagonal=3 };
constexpr std::int32_t minCell=-(1<<25),maxCell=(1<<25)-1;
// Positive signed-64-bit family, disjoint from existing receiver ordinals.
constexpr std::uint64_t marker=1ULL<<61;
struct Cell { Mode mode{}; unsigned receiver{}; std::int32_t column{},row{}; };
std::uint64_t identity(Cell);
bool decode(std::uint64_t,Cell&) noexcept;
struct Settings {
    Mode mode=Mode::Rectangular;
    double columnSpacing=1,rowSpacing=1,originX=0,originY=0,headingDegrees=0;
    double jitter=0; // 0..1; independently +/- half a pitch per axis.
    std::uint32_t seed=42;
    std::uint64_t receiverSalt=0;
};
struct Limits {
    std::size_t cells=1000000,triangles=2000000,bytes=512ULL*1024*1024;
    std::uint64_t visits=64000000;
};
void validate(const Settings&);
using Anchor=amin::CandidateAnchor; // Local cell key: receiver slot is zero.
struct Result {
    std::vector<Anchor> anchors;
    std::uint64_t enumeratedCells{},projectionVisits{};
};
// Owned plain-data numeric operation. Highest world-Z projection per receiver;
// equal-height shared edges choose the lowest evaluated face index.
// Throws before returning on invalid input or admission/work exhaustion.
Result generate(const std::vector<amin::Triangle>&,const Settings&,Limits={});
}
