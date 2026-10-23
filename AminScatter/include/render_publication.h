#pragma once
#include <atomic>
#include <cstdint>
#include <mutex>

namespace cyrus {
// Host writes the selected tickets at publication/container-update boundaries.
// Realize workers only observe these values and populate immutable resources;
// they never promote a publication, inspect a scene node or retire host state.
class RenderPublication {
    std::atomic<std::uint64_t> requested{0},visible{0};
    std::atomic<bool> enabled{false};
public:
    void stage(std::uint64_t ticket) { requested.store(ticket,std::memory_order_release); }
    bool commit(std::uint64_t ticket) {
        if(!isRequested(ticket))return false;
        visible.store(ticket,std::memory_order_release);return true;
    }
    bool isRequested(std::uint64_t ticket) const { return ticket&&requested.load(std::memory_order_acquire)==ticket; }
    bool canDraw(std::uint64_t ticket) const { return enabled.load(std::memory_order_acquire)&&ticket&&visible.load(std::memory_order_acquire)==ticket; }
    void controllerVisible(bool value) { enabled.store(value,std::memory_order_release); }
    bool controllerVisible() const { return enabled.load(std::memory_order_acquire); }
    std::uint64_t requestedTicket() const { return requested.load(std::memory_order_acquire); }
    std::uint64_t visibleTicket() const { return visible.load(std::memory_order_acquire); }
    void stop() { controllerVisible(false);requested.store(0,std::memory_order_release);visible.store(0,std::memory_order_release); }
};

// First visible item realizes every sibling in the admitted candidate. This
// avoids waiting forever for a culled sibling and prevents partially ready
// multi-layer generations from drawing. All data and resource ownership are
// already copied/admitted. The caller keeps the bundle alive throughout.
template<class Bundle,class Context,class RealizeOne>
void realizeRenderPublication(Bundle& bundle,Context& context,RealizeOne realizeOne) {
    std::lock_guard<std::mutex> lock(bundle.realizeMutex);
    const auto& generation=bundle.generation;
    if(!generation->presentation->isRequested(generation->ticket)||generation->complete())return;
    for(const auto& item:bundle.items) {
        if(generation->failed.load(std::memory_order_acquire)||
           !generation->presentation->isRequested(generation->ticket))return;
        realizeOne(item,context);
    }
}
}
