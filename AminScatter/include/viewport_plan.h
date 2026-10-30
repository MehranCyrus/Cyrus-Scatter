#pragma once
#include "point_preview.h"

namespace cyrus {
inline std::vector<ViewportMeshLayer> viewportMeshDemands(const std::vector<PointLayer>& layers){
    std::vector<ViewportMeshLayer> demands;demands.reserve(layers.size());
    for(const auto& layer:layers){
        ViewportMeshLayer value;value.lines=layer.snapshot->lines;value.mode=layer.geometryMode;value.limits=layer.limits;
        if(layer.mesh)for(const auto& group:layer.mesh->groups){
            value.groups.push_back({group.faceData().empty()?0:group.instanceCount(),group.faceData().size()});
            value.reduced.push_back(group.reducedBox);
        }
        demands.push_back(std::move(value));
    }
    return demands;
}
}
