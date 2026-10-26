#pragma once
#include "stem_core.hpp"
#include <atomic>
namespace prep {
// SI positions in the host's Z-up axes. No SDK types or host references cross this boundary.
struct Snapshot {
    std::vector<std::array<float,3>> positions;
    std::vector<std::array<unsigned,3>> faces;
    std::vector<unsigned> materials;
    std::string fingerprint;
};
struct Settings { double minimumLength=.005, foliageFraction=.05; };
struct Analysis { stem::Json metadata,report;std::vector<unsigned> labels;std::string fingerprint; };
Analysis analyze(const Snapshot&,Settings,const std::atomic_bool& cancel,std::atomic_int& progress);
std::string fingerprint(const Snapshot&);
std::string geometryHash(const Snapshot&,const std::vector<unsigned>&,unsigned components);
}
