#pragma once
#include "placement_store.h"
class Value;
// Internal to AminScatter's owning module. Brush must use the versioned POD
// ownership boundary, never link a second placement store or exchange shared_ptr.
Value* cyrusPlacementValue(cyrus::placements::View);
bool cyrusIsPlacementValue(Value*);
const cyrus::placements::View& cyrusPlacementView(Value*);
bool cyrusIsPlacementContextValue(Value*);
const std::shared_ptr<const cyrus::placements::SourceCohort>& cyrusPlacementContext(Value*);
Value* cyrusPlacementContextValue(std::shared_ptr<const cyrus::placements::SourceCohort>);
