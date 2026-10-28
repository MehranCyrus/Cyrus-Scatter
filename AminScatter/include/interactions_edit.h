#pragma once
#include <max.h>
#include <string>
#include <vector>
#include <optional>
#include <map>
#include <cstdint>
#include "placement_store.h"
namespace cyrus {
struct InteractionEditPatch {int layer=0;std::string identity;Matrix3 transform{1};bool deleted=false;};
std::vector<InteractionEditPatch> interactionAuthoredEdits(INode*,const std::vector<int>& historyLayers,bool collect,const std::map<std::pair<int,std::string>,std::uint32_t>& admitted);
bool interactionLayer(AnimHandle,int)noexcept;
bool interactionObstacleLayer(AnimHandle,int)noexcept;
bool interactionHasOverride(AnimHandle,int,const std::string&)noexcept;
bool interactionTransform(AnimHandle,int,const std::string&,Matrix3&)noexcept;
std::optional<placements::View> interactionFeedbackView(AnimHandle,int);
void interactionFailure(AnimHandle,const char*)noexcept;
void interactionEdit(AnimHandle,const std::vector<InteractionEditPatch>&)noexcept;
}
