#pragma once
#include <array>
#include <cstdint>
#include <vector>

namespace cyrus::assets {
constexpr std::size_t maxMeshVertices=100000,maxMeshFaces=100000,maxMeshChannels=8,maxMapVertices=300000;
using Vertex=std::array<double,3>;
using Triangle=std::array<std::uint32_t,3>;
struct Face { Triangle vertices{};std::uint32_t smoothing=0,material=0,edges=7; };
struct Mapping { int channel=1;std::vector<Vertex> vertices;std::vector<Triangle> faces; };
// Positions are source-node-local metres, with object offsets baked explicitly.
// Node transform, identity and material binding live in the asset graph.
struct Mesh { std::vector<Vertex> vertices;std::vector<Face> faces;std::vector<Mapping> maps; };
void validateMesh(const Mesh& mesh);
std::vector<unsigned char> encodeMesh(const Mesh& mesh);
Mesh decodeMesh(const std::vector<unsigned char>& bytes);
}
