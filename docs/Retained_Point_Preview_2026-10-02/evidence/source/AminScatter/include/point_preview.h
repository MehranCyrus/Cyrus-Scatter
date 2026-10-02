#pragma once
#include <max.h>
#include <cstdint>
#include <memory>
#include <vector>

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
};

// All publication and reference operations run on Max's main thread.
bool publishPoints(INode* helper, INode* controller, std::vector<PointLayer> layers);
bool pointsMatch(INode* helper, const std::vector<PointLayer>& layers);
}
