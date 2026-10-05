#pragma once
#include "group_spacing.h"
#include <string>

namespace cyrus::procedural {
using DistanceRule=groups::DistanceRule;
using Reason=groups::Reason;
struct Sample {
    amin::Vec3 position;
    double radius=0;
    std::uint64_t ordinal=0;
    std::string id;
    bool protectedEdit=false;
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
