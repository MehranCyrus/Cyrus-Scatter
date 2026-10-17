#pragma once
#include "group_spacing.h"
#include <string>

namespace cyrus::procedural {
using DistanceRule=groups::DistanceRule;
using Reason=groups::Reason;
struct Radii {
    double xy=0,spatial=0;
    double forMetric(bool planar) const { return planar?xy:spatial; }
};
// Pivot-local bounds already include object offsets. Apply only the final
// instance basis: no translation and no second Follow Scale multiplication.
Radii transformedBounds(amin::Vec3 minimum,amin::Vec3 maximum,const std::array<amin::Vec3,3>& basis);
struct Sample {
    amin::Vec3 position;
    Radii radii;
    std::uint64_t ordinal=0;
    std::string id;
    bool protectedEdit=false;
    // Native candidates keep their exact key without allocating decimal text.
    // Zero selects the existing authored/text boundary (including test keys).
    std::uint64_t candidateIdentity=0;
};
struct Population {
    std::string id;
    std::vector<Sample> samples;
    DistanceRule self;
    std::uint32_t budget=0,attemptLimit=0;
};
struct Layer {
    std::string id;
    std::vector<Population> sets;
    DistanceRule siblings;
    amin::FinalSettings cleanup;
    bool acceptedTarget=false,repair=false;
    unsigned rounds=1;
};
enum class Scope { Sets, Layers };
struct PairRule { Scope scope=Scope::Layers; std::string a,b; DistanceRule distance; };
struct Plan {
    std::vector<Layer> layers;
    std::vector<PairRule> rules;
    std::size_t maxSamples=1000000;
    std::uint64_t maxNeighborVisits=50000000;
};
struct PopulationResult {
    std::vector<std::size_t> kept,conflicts;
    std::vector<Reason> reasons;
    std::uint64_t neighborVisits=0,attempts=0;
    std::size_t shortfall=0;
};
struct LayerResult { std::vector<PopulationResult> sets; unsigned rounds=0; bool limitReached=false; };
struct Result { std::vector<LayerResult> layers; };
// Pure-data, fixed logical prefix schedule v1. Input cache suffixes are ignored
// until their scheduled round. No scene API, movement, RNG or publication here.
Result evaluate(const Plan&);
// Conservative spectral bound from the row Gram matrix; handles shear without
// a decomposition and is tight for orthogonal rotation/scale rows.
double transformScaleBound(const std::array<amin::Vec3,3>& rows);
}
