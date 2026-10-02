#pragma once
#include <max.h>
#include <cstdint>
#include <memory>
#include <vector>
#include <array>

namespace cyrus {
struct PointGroup {
    Point3 color;
    std::vector<Point3> points;
};

// Shared by the MAXScript GC cache and Nitrous items. Publication transfers no
// MAXScript values, scene pointers or mutable geometry to the drawing threads.
struct PointSnapshot {
    std::vector<PointGroup> groups;
    std::vector<Box3> groupBounds;
    Box3 bounds;
    std::size_t count = 0;
    std::uint64_t fingerprint = 1469598103934665603ULL;
    explicit PointSnapshot(std::vector<PointGroup> value);
};
struct PointLayer {
    std::shared_ptr<const PointSnapshot> snapshot;
    bool solid = false;
    Point3 color;
    std::shared_ptr<const struct MeshSnapshot> mesh;
};

struct PreviewGeometry {
    std::vector<std::array<Point3,3>> faces;
    std::vector<Matrix3> instances;
    Point3 color;
    bool placeholder=false;
};
// Source-local triangles and exact accepted placement transforms are shared
// with the fallback cache. No expanded world-space triangle array is retained.
struct MeshSnapshot {
    std::vector<PreviewGeometry> groups;
    std::vector<Box3> groupBounds;
    Box3 bounds;
    std::size_t faces=0,instances=0,bufferBytes=0;
    std::uint64_t fingerprint=1469598103934665603ULL;
    explicit MeshSnapshot(std::vector<PreviewGeometry> value);
};

// All publication and reference operations run on Max's main thread.
bool publishPoints(INode* helper, INode* controller, std::vector<PointLayer> layers);
bool pointsMatch(INode* helper, const std::vector<PointLayer>& layers);
}
