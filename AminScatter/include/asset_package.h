#pragma once
#include "recipes.h"
#include "asset_mesh.h"
#include <functional>
#include <map>
#include <memory>

namespace cyrus::assets {
using Json=recipes::Json;
constexpr std::size_t maxGraphBytes=2*1024*1024;
constexpr std::uint64_t maxFileBytes=32*1024*1024;
constexpr std::uint64_t maxPackageBytes=256*1024*1024;
// Explicit graph-3 prototype admission; expanded host/renderer memory needs
// its separate measured admission and qualification before scene mutation.
constexpr std::uint64_t maxPlantBitmapPixels=512ull*1024ull*1024ull;
// Separate candidate profile for measured plant meshes/stored normals and
// authored nested shader graphs. Legacy and plant-images-v1 admission is intact.
constexpr std::uint64_t maxPlantPackageBytes=640ull*1024ull*1024ull;
constexpr std::uint64_t maxPlantMeshFileBytes=224ull*1024ull*1024ull;
constexpr std::size_t maxPlantMapObjects=256;
constexpr std::size_t maxObjects=128, maxFiles=256;
using Checkpoint=std::function<void(const char*,std::uint64_t)>;
// Closed, data-only graph. Geometry is a separate typed payload; no Max scene or scripts.
void validateGraph(const Json& graph,const Json& recipe);
// Export is create-only into a new sibling directory. No user folder is replaced.
// File paths are inputs only and never serialized into the portable manifest.
std::filesystem::path writePackage(const std::filesystem::path& output,
    const std::filesystem::path& recipe,const std::string& recipeSHA256,
    const Json& graph,const std::map<std::string,std::filesystem::path>& files,
    const std::string& redistribution,const Checkpoint& checkpoint={});
// Reads and verifies every declared byte/hash at an explicit import boundary.
// Passive gallery listing uses the contained recipe metadata alone.
Json readPackage(const std::filesystem::path& directory,const Checkpoint& checkpoint={});
// Detached import snapshot. No SDK pointers, file handles or MAXScript values.
// Native payload storage is bounded separately from host/Undo allocations.
struct PreparedPackage {
    Json metadata,document;
    std::map<std::string,std::shared_ptr<const Mesh>> meshes;
    std::map<std::string,std::filesystem::path> bitmapPaths;
    std::uint64_t payloadBytes=0;
};
PreparedPackage preparePackage(const std::filesystem::path& directory,const Checkpoint& checkpoint={},const std::filesystem::path& bitmapDirectory={});
Json fileInfo(const std::filesystem::path& path,bool png);
Json imageFileInfo(const std::filesystem::path& path);
}
