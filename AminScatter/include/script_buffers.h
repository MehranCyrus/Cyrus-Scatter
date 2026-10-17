#pragma once
#include <array>
#include <cstdint>
#include <vector>
#include <memory>
class Value;
// Transient immutable values. No scene pointers; ownership follows MXS GC/Undo.
using CyrusRadiusPair = std::array<float,2>;
using CyrusSharedRadii = std::shared_ptr<const std::vector<CyrusRadiusPair>>;
Value* cyrusNativeSchedule(std::vector<std::uint64_t>);
const std::vector<std::uint64_t>& cyrusScheduleValues(Value*);
Value* cyrusNativeRadii(std::vector<CyrusRadiusPair>);
std::size_t cyrusRadiusCount(Value*);
std::array<double,2> cyrusRadiusAt(Value*,std::size_t);
CyrusSharedRadii cyrusRadiusData(Value*); // Native immutable radius ownership only.
Value* cyrusRadiusValue(CyrusSharedRadii);
