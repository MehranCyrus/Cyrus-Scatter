#pragma once
#include "stem_core.hpp"
#include <atomic>
#include <string_view>
namespace prep {
// SI positions in the host's Z-up axes. No SDK types or host references cross this boundary.
struct Snapshot {
    std::vector<std::array<float,3>> positions;
    std::vector<std::array<unsigned,3>> faces;
    std::vector<unsigned> materials;
    std::string fingerprint;
};
struct Limits {
    unsigned vertices=2000000,triangles=4000000,parts=100000,guides=8192,previewTriangles=500000;
    unsigned memoryMiB=2048,workMillions=256;
    bool operator==(const Limits&)const=default;
};
struct Settings { double minimumLength=.005, foliageFraction=.05; Limits limits; double connectionReach=.15; };
void validate(const Snapshot&,Settings);
void validateLimits(Limits);
struct Analysis { stem::Json metadata,report;std::vector<unsigned> labels;std::string fingerprint; };
Analysis analyze(const Snapshot&,Settings,const std::atomic_bool& cancel,std::atomic_int& progress);
Analysis analyzeTopology(const Snapshot&,Settings,const std::atomic_bool& cancel,std::atomic_int& progress,const stem::Json& authoring=stem::Json::object());
std::string fingerprint(const Snapshot&);
std::string textHash(std::string_view);
std::string geometryHash(const Snapshot&,const std::vector<unsigned>&,unsigned components);
}
