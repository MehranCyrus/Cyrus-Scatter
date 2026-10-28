#pragma once
#include "point_preview.h"
#include "interactions_deformation.h"
namespace cyrus {
struct DeformationPreviewSource {
    std::shared_ptr<PreviewMemory> memory;
    // Keep the original copied rig's reservation alive without retaining any
    // Max node watches in a graphics generation.
    std::shared_ptr<PreviewMemory> sourceMemory;
    std::shared_ptr<const interactions::DeformationSource> data;
};
struct DeformationPreview {
    std::shared_ptr<PreviewMemory> memory;
    std::shared_ptr<const DeformationPreviewSource> source;
    std::vector<interactions::DeformationWord> nodes;
    interactions::DeformationChanges changes;
    double metresPerUnit=.01;
    Box3 worldBounds;
    std::size_t posed=0;
    std::uint64_t fingerprint=1469598103934665603ULL;
};
}
