#pragma once
// Private cache-entry requested-allocation and buffer-capacity accounting.
#include "cyrus_arrange/geometry_cache.h"
#include <cassert>
#include <memory>
#include <new>
#include <type_traits>

namespace cyrus::arrange::cache::detail {
struct AllocationCounter {
    std::size_t live{}, peak{};
    void preflight(std::size_t bytes) const {
        if (bytes>std::numeric_limits<std::size_t>::max()-live) throw std::bad_array_new_length();
    }
    void acquired(std::size_t bytes) noexcept { live+=bytes; if(live>peak)peak=live; }
    void released(std::size_t bytes) noexcept { assert(bytes<=live); live-=bytes; }
};
// Owning the counter makes allocate_shared's rebound allocator safe even when a
// numeric lease outlives its cache service. This allocator is for ENTRY metadata;
// the geometry agent's separate query-map draft embeds its own counter in Impl.
template<class T> class CountedAllocator {
public:
    using value_type=T;
    using propagate_on_container_move_assignment=std::true_type;
    std::shared_ptr<AllocationCounter> counter;
    explicit CountedAllocator(std::shared_ptr<AllocationCounter> c) noexcept : counter(std::move(c)) {}
    template<class U> CountedAllocator(const CountedAllocator<U>& c) noexcept : counter(c.counter) {}
    T* allocate(std::size_t n) {
        if(n>std::numeric_limits<std::size_t>::max()/sizeof(T))throw std::bad_array_new_length();
        const auto bytes=n*sizeof(T); counter->preflight(bytes);
        auto* p=std::allocator<T>{}.allocate(n); counter->acquired(bytes); return p;
    }
    void deallocate(T* p,std::size_t n) noexcept {
        std::allocator<T>{}.deallocate(p,n); counter->released(n*sizeof(T));
    }
    template<class U> bool operator==(const CountedAllocator<U>& other) const noexcept { return counter==other.counter; }
};
struct SizeSum {
    std::size_t bytes{};
    bool complete{true};
    void add(std::size_t count,std::size_t element=1) noexcept {
        if(!element)return;
        if(count>std::numeric_limits<std::size_t>::max()/element) { complete=false; return; }
        const auto n=count*element;
        if(n>std::numeric_limits<std::size_t>::max()-bytes)complete=false;
        else bytes+=n;
    }
};
inline SizeSum raw_dynamic_bytes(const Result& raw) noexcept {
    SizeSum out;
    out.add(raw.regions.capacity(),sizeof(Region));
    for(const auto& region:raw.regions)out.add(region.cells.capacity(),sizeof(Cell));
    out.add(raw.warnings.capacity(),sizeof(std::string));
    // SSO is conservatively double-counted; capacity+terminator is a safe buffer
    // account, not a claim to know each standard library string's heap allocation.
    for(const auto& text:raw.warnings) {out.add(text.capacity());out.add(1);}
    return out;
}
inline SizeSum key_dynamic_bytes(const GeometryKey& key) noexcept {
    SizeSum out;out.add(key.roots.capacity(),sizeof(RootStamp));out.add(key.nodes.capacity(),sizeof(NodeStamp));return out;
}
}
