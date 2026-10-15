#pragma once
#include <nlohmann/json.hpp>
#include <filesystem>
#include <string>
#include <vector>

namespace cyrus::recipes {
using Json = nlohmann::json;
constexpr std::size_t maxManifestBytes=8*1024*1024;
constexpr std::size_t maxPaintBytes=8*1024*1024;
constexpr std::size_t maxTotalPaintBytes=64*1024*1024;
constexpr std::size_t maxPaintDocuments=256;
struct Field { const char* name; const char* type; bool distance; };
const std::vector<Field>& fields();
// Closed, complete static settings. Host references are role IDs, never handles.
void validateSettings(const Json& settings);
void validate(const Json& document, bool hydrated=true);
Json parse(const std::string& text);
std::string serialize(const Json& document);
std::string digest(const std::vector<unsigned char>& bytes);
std::filesystem::path pathFromUTF8(const std::string& text);
std::string hex(const std::vector<unsigned char>& bytes);
std::vector<unsigned char> unhex(const std::string& text);
// New-file saves only. Payloads publish before the manifest; no overwrite on read.
void writeNew(const std::filesystem::path& path, const Json& hydrated);
Json read(const std::filesystem::path& path, bool hydrate=true, std::string* manifestSHA256=nullptr);
}
