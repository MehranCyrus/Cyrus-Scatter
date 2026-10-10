#pragma once
#include <cstdint>
#include <string>
#include <vector>

namespace cyrus::receivers {
// A saved append-only receiver slot and local candidate ordinal form an ID.
// Scheduling rank is deliberately separate and can change with quotas.
constexpr std::uint64_t marker=1ULL<<32;
constexpr unsigned stride=131072, limit=100000, slots=128;
std::uint64_t identity(unsigned slot,unsigned ordinal);
bool decode(std::uint64_t id,unsigned& slot,unsigned& ordinal);
std::uint64_t salt(const std::string& persistentID);
struct Input { unsigned slot; std::string id; double area; unsigned required=0; };
struct Allocation { unsigned slot,budget,attempts,pool; };
struct Plan { std::vector<Allocation> receivers; std::vector<std::uint64_t> order; unsigned budget=0,attempts=0; bool capped=false; };
// density < 0 means fixed total. Otherwise density is candidates/world-unit^2.
Plan plan(std::vector<Input> inputs,unsigned total,double density,unsigned attemptFactor,unsigned densityCap=limit);
// Receiver membership is not an Edit generation change. Changed geometry on
// a previously bound receiver remains a guarded change. Missing entries stay
// in the receipt so removing/re-adding cannot erase that guard.
std::string mergeBinding(const std::string& previous,const std::string& current);
}
