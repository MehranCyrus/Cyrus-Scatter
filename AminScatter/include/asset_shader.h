#pragma once
#include "recipes.h"

namespace cyrus::assets {
// Data-only graph-3 renderer validation. The outer package validator retains
// ownership of meshes/files/roles and the existing Standard/Bitmap adapters.
// No SDK objects, renderer constructors, paths or executable values are used.
void validateRendererShaders(const recipes::Json& graph);
}
