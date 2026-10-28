#pragma once
#include "interactions_source.h"

namespace cyrus::interactions {
using DeformationWord=std::array<float,4>;
// Typed float4 buffers, not per-instance meshes. Slot indices are exact FP32
// integers and remain below2^24; coordinates remain source-local metres.
struct DeformationSource {
    std::shared_ptr<const Source> source;
    std::vector<DeformationWord> corners; //10 words/triangle:3 bindings + visibility
    std::vector<DeformationWord> rest;
    std::vector<unsigned> guideSlots,faces;
    std::vector<double> offsetRadius;
    std::size_t bytes=0;
};
std::shared_ptr<const DeformationSource> deformationSource(std::shared_ptr<const Source>);
std::vector<DeformationWord> deformationPose(const DeformationSource&,const Pose&);
Bounds deformationBounds(const DeformationSource&,const std::vector<DeformationWord>&);
Vec deformationPoint(const DeformationSource&,const std::vector<DeformationWord>&,unsigned face,unsigned corner);
bool deformationVisible(const DeformationSource&,const std::vector<DeformationWord>&,unsigned face);
// Small open-addressed table keyed by stable source instance slot. Records have
// a header and4 transform rows. Zero key is empty; disabled records remain explicit.
struct DeformationChange {unsigned slot=0,pose=0;bool enabled=true;std::array<float,12> transform;};
struct DeformationChanges {std::vector<DeformationWord> words;unsigned capacity=0,probes=0;};
DeformationChanges deformationChanges(const std::vector<DeformationChange>&);
int deformationFind(const DeformationChanges&,unsigned slot);
}
