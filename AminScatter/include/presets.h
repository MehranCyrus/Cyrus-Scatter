#pragma once
#include <array>
#include <string>
#include <vector>

namespace cyrus::presets {
enum class Kind { number, integer, boolean };
struct Field { const char* name; Kind kind; double minimum, maximum; bool distance=false; };
struct Document {
    std::string category, name;
    std::vector<double> values;
    std::vector<double> samples;
    std::vector<std::array<double,8>> graph;
    bool multiplier=false;
};
inline constexpr std::size_t maxBytes=65536;
const std::vector<Field>& fields(const std::string& category);
bool curve(const std::string& category);
void validate(const Document& document);
Document parse(const std::string& text);
std::string serialize(const Document& document);
// Finalize a bounded native CurveControl evaluation, using the same sampled
// agreement tolerance as the artist editor. No owner or publication is touched.
Document preparedCurve(const Document& source, bool targetMultiplier,
    const std::vector<double>& evaluated,
    const std::vector<std::array<double,8>>& graph);
}
