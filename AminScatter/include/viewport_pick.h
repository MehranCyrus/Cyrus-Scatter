#pragma once
#include <max.h>
#include <cstdint>
#include <string>
#include <functional>
#include <vector>
// Host thread only. Queries read the completed retained preview. No evaluation,
// generation or host geometry conversion is permitted through this interface.
struct CyrusViewportHit {
    std::uint64_t owner=0,layer=0;
    std::wstring identity;
    unsigned source=0;
    Point3 position;
    float distance=0;
    Box3 bounds;
    std::size_t displayLayer=0,group=0,instance=0,entry=0;
};
struct CyrusViewportSelectedInstance { std::uint64_t layer;std::wstring identity; };
inline constexpr std::size_t cyrusViewportOutlineInstances=128;
void cyrusViewportDrawSelected(INode*,ViewExp*,std::uint64_t editor,std::uint64_t revision,
    const std::function<std::vector<CyrusViewportSelectedInstance>()>&) noexcept;
void cyrusViewportClearSelected() noexcept;
bool cyrusViewportEditDragging() noexcept;
bool cyrusViewportPick(INode*,ViewExp*,IPoint2,CyrusViewportHit&,bool hover=true) noexcept;
void cyrusViewportClearHover(INode*) noexcept;
void cyrusViewportDrawHover(INode*,ViewExp*) noexcept;
Box3 cyrusViewportPickBounds(INode*) noexcept;
INode* cyrusViewportController(INode*) noexcept;
