#pragma once
#include <cstddef>
#include <limits>
#include <memory>
#include <new>
#include <type_traits>

namespace cyrus::arrange::detail {
// Counts successful allocator requests, not heap usable size or process RAM.
// Accounting failure is sticky and never turns a valid cold query into failure.
struct RetainedAllocationCounter {
    std::size_t live_bytes{}, live_allocations{};
    bool complete{true};
    void allocated(std::size_t bytes) noexcept {
        if(!complete)return;
        if(bytes>std::numeric_limits<std::size_t>::max()-live_bytes ||
            live_allocations==std::numeric_limits<std::size_t>::max()) {complete=false;return;}
        live_bytes+=bytes;++live_allocations;
    }
    void deallocated(std::size_t bytes) noexcept {
        if(!complete)return;
        if(bytes>live_bytes||live_allocations==0){complete=false;return;}
        live_bytes-=bytes;--live_allocations;
    }
};

template<class T> struct RetainedAllocator {
    using value_type=T;
    using is_always_equal=std::false_type;
    using propagate_on_container_copy_assignment=std::false_type;
    using propagate_on_container_move_assignment=std::false_type;
    using propagate_on_container_swap=std::false_type;
    RetainedAllocationCounter* counter{}; // Borrowed from the nonmoving Impl.
    RetainedAllocator() noexcept=default;
    explicit RetainedAllocator(RetainedAllocationCounter* state) noexcept:counter(state){}
    template<class U> RetainedAllocator(const RetainedAllocator<U>& other) noexcept:counter(other.counter){}
    [[nodiscard]] T* allocate(std::size_t n) {
        if(n>std::numeric_limits<std::size_t>::max()/sizeof(T))throw std::bad_array_new_length();
        T* result=std::allocator<T>{}.allocate(n); // Failure leaves accounting unchanged.
        if(counter)counter->allocated(n*sizeof(T));
        return result;
    }
    void deallocate(T* pointer,std::size_t n) noexcept {
        std::allocator<T>{}.deallocate(pointer,n);
        if(counter){
            if(n>std::numeric_limits<std::size_t>::max()/sizeof(T))counter->complete=false;
            else counter->deallocated(n*sizeof(T));
        }
    }
    template<class U> bool operator==(const RetainedAllocator<U>& other) const noexcept{return counter==other.counter;}
};

inline bool checked_add(std::size_t& total,std::size_t value) noexcept {
    if(value>std::numeric_limits<std::size_t>::max()-total)return false;
    total+=value;return true;
}
inline bool checked_product(std::size_t count,std::size_t element_size,std::size_t& bytes) noexcept {
    if(element_size&&count>std::numeric_limits<std::size_t>::max()/element_size){bytes=0;return false;}
    bytes=count*element_size;return true;
}
}
