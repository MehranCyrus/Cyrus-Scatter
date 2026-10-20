#pragma once
#include <array>
#include <cstdint>
#include <optional>
#include <span>
#include <vector>

namespace cyrus::assets {
constexpr std::size_t maxMeshVertices=100000,maxMeshFaces=100000,maxMeshChannels=8,maxMapVertices=300000;
constexpr std::size_t maxPlantMeshVertices=1000000,maxPlantMeshFaces=1000000,maxPlantMapVertices=1300000,maxPlantNormals=1000000;
constexpr std::size_t maxLegacyMeshBytes=32ull*1024*1024,maxPlantMeshBytes=224ull*1024*1024;
enum class MeshProfile { Legacy, Plant };
constexpr std::uint32_t supportedMeshNormalFlags=43;
using Vertex=std::array<double,3>;
using Triangle=std::array<std::uint32_t,3>;
struct Face { Triangle vertices{};std::uint32_t smoothing=0,material=0,edges=7; };
struct Mapping { int channel=1;std::vector<Vertex> vertices;std::vector<Triangle> faces; };
struct NormalFace { std::array<std::int32_t,3> ids{{-1,-1,-1}};std::array<std::uint8_t,3> specified{}; };
// SDK flags: built=1, computed=2, face-angle weighted=8, modifier support=32.
// Per-vector explicit state and per-corner specified state are independent.
struct MeshNormals { std::uint32_t flags=0;std::vector<Vertex> vectors;std::vector<std::uint8_t> explicitFlags;std::vector<NormalFace> faces; };
// Positions are source-node-local metres, with object offsets baked explicitly.
// Node transform, identity and material binding live in the asset graph.
struct Mesh { std::vector<Vertex> vertices;std::vector<Face> faces;std::vector<Mapping> maps;std::optional<MeshNormals> normals;MeshProfile profile=MeshProfile::Legacy; };
void validateMesh(const Mesh& mesh,MeshProfile profile=MeshProfile::Legacy);
std::size_t meshStorageBytes(const Mesh& mesh);
std::size_t meshEncodedBytes(const Mesh& mesh,MeshProfile profile=MeshProfile::Legacy);
// Row-vector position transform. Applies its inverse transpose to a normal,
// retaining the authored vector length; exact identity leaves values unchanged.
Vertex transformStoredNormal(const Vertex& normal,const std::array<Vertex,3>& linear);
std::vector<unsigned char> encodeMesh(const Mesh& mesh,MeshProfile profile=MeshProfile::Legacy);
Mesh decodeMesh(std::span<const unsigned char> bytes,MeshProfile profile=MeshProfile::Legacy);
Mesh decodeMesh(const std::vector<unsigned char>& bytes,MeshProfile profile=MeshProfile::Legacy);
}
