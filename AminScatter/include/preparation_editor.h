#pragma once
#include "interactions_source.h"
#include <functional>
namespace cyrus {
// Numeric inputs only; the host bridge owns capture, source identity and commit.
void preparationEditorOpen(prep::Snapshot,prep::Settings,interactions::Json saved,std::wstring title,std::shared_ptr<void> sourceLease,std::function<bool()> valid,double stiffness);
void preparationEditorClose();
interactions::Json preparationEditorInfo();
interactions::Json preparationEditorDefinition();
void preparationEditorCommand(const interactions::Json&);
void preparationEditorCommitResult(bool,const std::string&);
}
