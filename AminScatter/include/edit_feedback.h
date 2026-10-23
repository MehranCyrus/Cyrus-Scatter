#pragma once
#include <memory>
class INode;
struct CyrusEditFeedback;
// Host thread only. Capture allocates before admission. Stage/Present/Release
// are nonallocating and noexcept; opaque snapshot destruction never calls Max.
std::shared_ptr<const CyrusEditFeedback> cyrusCaptureEditFeedback(INode*);
void cyrusStageEditFeedback(const std::shared_ptr<const CyrusEditFeedback>&,bool retainVisible) noexcept;
void cyrusPresentEditFeedback(const std::shared_ptr<const CyrusEditFeedback>&) noexcept;
// Only when detaching the display owner, not on ordinary generation destruction.
void cyrusReleaseEditFeedback(const std::shared_ptr<const CyrusEditFeedback>&) noexcept;
