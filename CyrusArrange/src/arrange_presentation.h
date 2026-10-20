#pragma once
#include <max.h>

namespace cyrus::arrange::host {
// Presentation-only classes. They never own or duplicate Document state.
Class_ID arrange_modifier_class_id();
Class_ID arrange_icon_class_id();
Object* create_arrange_icon();
void add_arrange_modifier(INode*);
HINSTANCE document_module_handle() noexcept;
}

extern "C" __declspec(dllexport) ClassDesc* CyrusArrangeModifierDesc();
extern "C" __declspec(dllexport) ClassDesc* CyrusArrangeIconDesc();
