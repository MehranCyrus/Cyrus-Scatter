#pragma once
#include <max.h>
#include <cstdint>
#include <memory>
#include <vector>
#include <array>
#include "preview_budget.h"
#include "viewport_policy.h"

namespace cyrus {
extern PreviewBudget pointPreviewBudget,meshPreviewBudget;
std::shared_ptr<PreviewMemory> reservePreviewMemory(PreviewBudget& budget,std::size_t bytes);
std::shared_ptr<PreviewMemory> reserveMeshMemory(viewport_memory::Cost bytes);
std::shared_ptr<PreviewMemory> reserveSourceMetadataMemory(std::size_t bytes);
std::size_t sourceInspectionFaceLimit();
void growMeshMemory(const std::shared_ptr<PreviewMemory>& memory,std::size_t bytes);
viewport_memory::Policy viewportMemoryPolicy();
void recordPreviewFailure(const char* reason);
struct PointGroup {
    Point3 color;
    std::vector<Point3> points;
    std::vector<std::uint8_t> bandSlots;
};

// Slots address this immutable publication dictionary, never authored row order.
// Slot zero is explicitly Unbanded; ordinary Band rows must have a real owner.
struct PreviewPalette {
    std::shared_ptr<PreviewMemory> memory;
    int mode=1;
    bool requireBand=false;
    std::vector<Point3> sourceColors;
    std::vector<std::uint64_t> bandIDs;
    std::array<Point3,65> bandColors{};
    PreviewPalette() { bandColors.fill(Point3(0,0,0)); }
};
inline bool samePalette(const std::shared_ptr<const PreviewPalette>& a,const std::shared_ptr<const PreviewPalette>& b) {
    return a==b || (a&&b&&a->mode==b->mode&&a->requireBand==b->requireBand&&
        a->sourceColors==b->sourceColors&&a->bandIDs==b->bandIDs&&a->bandColors==b->bandColors);
}
inline Point3 previewColor(const PreviewPalette* palette,std::size_t source,std::uint8_t slot,Point3 fallback) {
    return !palette?fallback:palette->mode==3?palette->bandColors[slot]:palette->sourceColors[source];
}

// Shared by the MAXScript GC cache and Nitrous items. Publication transfers no
// MAXScript values, scene pointers or mutable geometry to the drawing threads.
struct PointSnapshot {
    std::shared_ptr<PreviewMemory> memory;
    std::vector<PointGroup> groups;
    std::vector<Box3> groupBounds;
    Box3 bounds;
    std::size_t count = 0;
    std::size_t cpuBytes = 0;
    bool lines = false;
    std::uint64_t fingerprint = 1469598103934665603ULL;
    explicit PointSnapshot(std::vector<PointGroup> value, bool lineList = false);
};
struct PointLayer {
    std::shared_ptr<const PointSnapshot> snapshot;
    bool solid = false;
    Point3 color;
    std::shared_ptr<const struct MeshSnapshot> mesh;
    std::shared_ptr<const PreviewPalette> palette;
    int geometryMode=0;
    ViewportLimits limits;
    std::shared_ptr<const struct MeshAppearance> appearance;
};

// Host-prepared material data. No scene pointers survive into the draw thread.
// RGB and alpha use independent source UV channels in one bounded atlas.
struct MaterialUV { Point3 color,opacity; };
struct SourceAppearance {
    std::shared_ptr<PreviewMemory> memory;
    std::vector<MaterialUV> uv;
    std::vector<std::uint32_t> pixels;
    int width=0,tiles=0;
    std::size_t cpuBytes=0;
    std::wstring status;
    bool textureColor=false;
};
struct MeshAppearance {
    std::vector<std::shared_ptr<const SourceAppearance>> sources;
    std::wstring key,status;
    std::size_t cpuBytes=0,gpuBytes=0;
};

struct PreviewGeometry {
    std::vector<std::array<Point3,3>> faces;
    std::vector<Matrix3> instances;
    Point3 color;
    bool placeholder=false;
    bool reducedBox=false;
    std::vector<std::uint8_t> bandSlots;
};
// Source-local triangles and exact accepted placement transforms are shared
// with the fallback cache. No expanded world-space triangle array is retained.
struct MeshSnapshot {
    std::shared_ptr<PreviewMemory> memory;
    std::vector<PreviewGeometry> groups;
    std::vector<Box3> groupBounds;
    std::vector<Box3> localBounds;
    Box3 bounds;
    std::size_t faces=0,instances=0,bufferBytes=0,cpuBytes=0,scratchBytes=0;
    std::uint64_t fingerprint=1469598103934665603ULL;
    explicit MeshSnapshot(std::vector<PreviewGeometry> value,std::shared_ptr<PreviewMemory> storage={});
};

// All publication and reference operations run on Max's main thread.
bool publishPoints(INode* helper, INode* controller, std::vector<PointLayer> layers);
bool pointsMatch(INode* helper, const std::vector<PointLayer>& layers);
}
