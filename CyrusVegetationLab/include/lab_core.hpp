#pragma once
#include <cyrus_vegetation/prototype_v1.hpp>
#include <nlohmann/json.hpp>
#include <memory>
#include <string>
#include <string_view>
#include <vector>

namespace cvl {
namespace v = cyrus::vegetation::prototype_v1;
using Json = nlohmann::json;
struct PreparedBlade { v::RestGuide rest; v::PreparedRibbon source; };
struct Patch { std::vector<PreparedBlade> blades; };
struct Metrics { std::size_t queries=0, iterations=0; double root=0, length=0, penetration=0; };
struct State {
    std::shared_ptr<const Patch> prepared;
    std::vector<v::GuidePose> poses;
    std::vector<v::EvaluatedMesh> meshes;
    v::SceneSnapshot snapshot;
    Metrics metrics;
    std::uint64_t revision=1;
    double metersPerUnit=1, clearance=.005;
    bool fitted=false, clamp=false;
};
struct Sphere { v::Vec3 center; double radius=.25; };
inline constexpr int maxBlades=21;
inline constexpr std::size_t maxSerializedBytes=2*1024*1024;
v::SolveOptions options(double clearance, bool clamp);
std::shared_ptr<const State> makeRest(int count, double metersPerUnit, std::uint64_t revision=1,
                                    std::shared_ptr<const Patch> existing={});
std::shared_ptr<const State> fit(const State&, Sphere, double clearance, bool clamp);
std::string encode(const State&);
std::shared_ptr<const State> decode(std::string_view);
std::size_t estimatedBytes(const State&);
Json summary(const State&);
// Proper rotation: core Y-up -> Max Z-up, with no reflection.
v::Vec3 coreToHost(v::Vec3 meters, double unit);
v::Vec3 hostToCore(v::Vec3 hostUnits, double unit);
}
