#pragma once
#include <cstddef>
#include <limits>
#include <mutex>
#include <stdexcept>
#include "viewport_memory.h"

namespace cyrus {
// CPU allocations awaiting materialization are absent from an OS headroom
// sample. Share this ledger across display and source-metadata admission;
// committed allocations are already represented by the next OS sample.
class SystemMemoryAdmission {
    mutable std::mutex mutex;
    std::size_t pending=0;
public:
    void acquire(std::size_t bytes,std::size_t availableCPU) {
        if(!bytes)return;
        std::lock_guard<std::mutex> lock(mutex);
        const auto next=viewport_memory::add(pending,bytes);
        if(next>availableCPU)throw std::runtime_error("Insufficient system memory headroom for the requested operation; previous result retained.");
        pending=next;
    }
    void release(std::size_t bytes) { std::lock_guard<std::mutex> lock(mutex);pending-=bytes; }
    std::size_t used() const { std::lock_guard<std::mutex> lock(mutex);return pending; }
};
// Numeric/resource payload reservations, including CPU and SDK system copies.
// Driver, Max conversion and allocator overhead are measured separately.
class PreviewBudget {
    mutable std::mutex mutex;
    std::size_t ceiling,deviceCeiling=std::numeric_limits<std::size_t>::max();
    viewport_memory::Cost live;
    std::size_t peak=0,pendingCPU=0;
    SystemMemoryAdmission* systemAdmission;
    const char* ceilingFailure;
public:
    explicit PreviewBudget(std::size_t maximum,SystemMemoryAdmission* admission=nullptr,
        const char* failure="Viewport memory ceiling reached; previous result retained. Raise the ceiling or release unused previews.")
        :ceiling(maximum),systemAdmission(admission),ceilingFailure(failure) {}
    void limits(std::size_t total,std::size_t device) {
        std::lock_guard<std::mutex> lock(mutex);ceiling=total;deviceCeiling=device;
    }
    void acquire(viewport_memory::Cost bytes,std::size_t availableCPU=std::numeric_limits<std::size_t>::max()) {
        std::lock_guard<std::mutex> lock(mutex);
        if(!bytes.cpu&&!bytes.device)return;
        const auto total=viewport_memory::add(live.total(),bytes.total());
        const auto device=viewport_memory::add(live.device,bytes.device);
        const auto pending=viewport_memory::add(pendingCPU,bytes.cpu);
        if(total>ceiling)throw std::runtime_error(ceilingFailure);
        if(device>deviceCeiling)throw std::runtime_error("Viewport device-resource allowance reached; previous result retained.");
        if(systemAdmission)systemAdmission->acquire(bytes.cpu,availableCPU);
        else if(pending>availableCPU)throw std::runtime_error("Insufficient system memory headroom for the viewport successor; previous result retained.");
        live.cpu+=bytes.cpu;live.device=device;pendingCPU=pending;peak=std::max(peak,total);
    }
    void release(viewport_memory::Cost bytes,std::size_t pending) {
        std::lock_guard<std::mutex> lock(mutex);
        if(systemAdmission)systemAdmission->release(pending);
        live.cpu-=bytes.cpu;live.device-=bytes.device;pendingCPU-=pending;
    }
    void committed(std::size_t bytes) {
        std::lock_guard<std::mutex> lock(mutex);
        if(systemAdmission)systemAdmission->release(bytes);
        pendingCPU-=bytes;
    }
    struct State { std::size_t cpu,device,pending,peak;std::size_t total() const{return viewport_memory::add(cpu,device);} };
    State state() const { std::lock_guard<std::mutex> lock(mutex);return {live.cpu,live.device,pendingCPU,peak}; }
    std::size_t used() const { return state().total(); }
    std::size_t highWater() const { return state().peak; }
};
class PreviewMemory {
    PreviewBudget& budget;
    viewport_memory::Cost bytes;
    std::size_t pending;
public:
    PreviewMemory(PreviewBudget& owner,viewport_memory::Cost value,std::size_t availableCPU=std::numeric_limits<std::size_t>::max())
        :budget(owner),bytes(value),pending(value.cpu) { budget.acquire(bytes,availableCPU); }
    PreviewMemory(PreviewBudget& owner,std::size_t value):PreviewMemory(owner,viewport_memory::Cost{value,0}) {}
    ~PreviewMemory() { budget.release(bytes,pending); }
    void grow(viewport_memory::Cost extra,std::size_t availableCPU=std::numeric_limits<std::size_t>::max()) {
        // Validate the lease arithmetic before changing the shared budget.
        const viewport_memory::Cost next{viewport_memory::add(bytes.cpu,extra.cpu),viewport_memory::add(bytes.device,extra.device)};
        const auto nextPending=viewport_memory::add(pending,extra.cpu);
        budget.acquire(extra,availableCPU);bytes=next;pending=nextPending;
    }
    void commit(std::size_t cpuBytes=std::numeric_limits<std::size_t>::max()) {
        const auto amount=std::min(pending,cpuBytes);budget.committed(amount);pending-=amount;
    }
    void trimCPU(std::size_t value) {
        if(value>bytes.cpu)throw std::invalid_argument("Cannot grow a viewport reservation by trimming it");
        const auto removed=bytes.cpu-value,removedPending=std::min(pending,removed);
        budget.release({removed,0},removedPending);bytes.cpu=value;pending-=removedPending;
    }
    viewport_memory::Cost cost() const { return bytes; }
    PreviewMemory(const PreviewMemory&)=delete;
    PreviewMemory& operator=(const PreviewMemory&)=delete;
};
inline constexpr std::size_t pointPreviewOwnerLimit=64ull*1024*1024;
inline constexpr std::size_t pointPreviewProcessLimit=128ull*1024*1024;
// Per-controller preparation capacity, separate from either artist draw cap.
// Per point: doubled CPU vector capacity (26 bytes), retained HW/system/upload
// copies (48), and simultaneous preparation (26). Leave 8 MiB for groups,
// palettes, source samples and inspection bookkeeping. Zero draw caps still
// remove only the artist cap; preparation must fit a complete display successor.
inline constexpr std::size_t pointPreviewPreparationLimit=(pointPreviewOwnerLimit-8ull*1024*1024)/100;
}
