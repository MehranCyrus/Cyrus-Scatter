#pragma once
#include <memory>
#include <cstdint>
class INode;
struct CyrusEditFeedback;
// Host thread only. Capture allocates before admission. Stage/Present/Release
// are nonallocating and noexcept; opaque snapshot destruction never calls Max.
std::shared_ptr<const CyrusEditFeedback> cyrusCaptureEditFeedback(INode*);
void cyrusStageEditFeedback(const std::shared_ptr<const CyrusEditFeedback>&,bool retainVisible) noexcept;
void cyrusPresentEditFeedback(const std::shared_ptr<const CyrusEditFeedback>&) noexcept;
// Only when detaching the display owner, not on ordinary generation destruction.
void cyrusReleaseEditFeedback(const std::shared_ptr<const CyrusEditFeedback>&) noexcept;
// Realize workers post only copied window/message/AnimHandle values. The owned
// Edit panel validates both identities and asks the host display to refresh.
void cyrusWakeEditFrameReady(const std::shared_ptr<const CyrusEditFeedback>&,std::uint64_t display) noexcept;
bool cyrusRequestReadyPointDisplay(std::uint64_t display,std::uint64_t controller) noexcept;
