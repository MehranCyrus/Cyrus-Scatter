#include "collision_build_profile.hpp"
#include "jolt_runtime.hpp"

#include <Jolt/Core/Factory.h>
#include <Jolt/Core/Memory.h>
#include <Jolt/Physics/Collision/PhysicsMaterial.h>
#include <Jolt/RegisterTypes.h>

#include <limits>
#include <mutex>
#include <new>
#include <utility>

namespace cyrus::vegetation::prototype_v1::collision_detail {
namespace {

// Shape/vector payload admission belongs to the adapter. Factory registries,
// allocator bookkeeping and other Jolt internals are NOT exactly instrumented
// by the caller's per-world byte budget. These checks turn ordinary null
// allocations into exceptions; they cannot promise recovery from catastrophic
// OOM in every Jolt noexcept path or from foreign mutation of process globals.
// In particular, the pinned HashTable::GrowTable can lose its old allocation
// from member state before a throwing replacement allocation. We clean all
// reachable owned state; no claim is made to reclaim such engine-internal
// failed-growth storage without a separate allocator ledger.
struct NativeAllocators {
    JPH::AllocateFunction allocate = nullptr;
    JPH::ReallocateFunction reallocate = nullptr;
    JPH::FreeFunction free = nullptr;
    JPH::AlignedAllocateFunction aligned_allocate = nullptr;
    JPH::AlignedFreeFunction aligned_free = nullptr;
};

struct RuntimeState {
    std::mutex mutex;
    std::size_t users = 0;
    JPH::Factory* factory = nullptr;
    NativeAllocators native;
    bool registration_attempted = false;
    bool hooks_installed = false;
    bool poisoned = false;
};

RuntimeState& runtime_state() noexcept {
    // Fixed process-lifetime storage avoids a destroyed lifecycle mutex when
    // ordinary owners finish late. No heap allocation is hidden here. Worlds
    // still must release before Jolt's own C++ static objects are destroyed;
    // arbitrary cross-translation-unit static shutdown is not this profile.
    alignas(RuntimeState) static unsigned char storage[sizeof(RuntimeState)];
    static RuntimeState* state = ::new (static_cast<void*>(storage)) RuntimeState;
    return *state;
}

void* checked_allocate(std::size_t size) {
    // A zero-size C++ allocation still returns usable storage or throws.
    void* result = runtime_state().native.allocate(size == 0 ? 1 : size);
    if (!result) throw std::bad_alloc{};
    return result;
}

void* checked_reallocate(void* block, std::size_t old_size, std::size_t new_size) {
    auto& native = runtime_state().native;
    if (new_size == 0) {
        // Do not rely on realloc(ptr, 0)'s implementation-dependent ownership.
        native.free(block);
        return nullptr;
    }
    void* result = native.reallocate(block, old_size, new_size);
    // The pinned default reallocator delegates to realloc: a failed nonzero
    // resize preserves block. Throw before the caller can overwrite its pointer;
    // its normal owner/unwind path can still release that original allocation.
    if (!result) throw std::bad_alloc{};
    return result;
}

void checked_free(void* block) noexcept {
    runtime_state().native.free(block);
}

void* checked_aligned_allocate(std::size_t size, std::size_t alignment) {
    void* result = runtime_state().native.aligned_allocate(size == 0 ? 1 : size, alignment);
    if (!result) throw std::bad_alloc{};
    return result;
}

void checked_aligned_free(void* block) noexcept {
    runtime_state().native.aligned_free(block);
}

bool no_allocator_hooks() noexcept {
    return JPH::Allocate == nullptr && JPH::Reallocate == nullptr &&
        JPH::Free == nullptr && JPH::AlignedAllocate == nullptr &&
        JPH::AlignedFree == nullptr;
}

bool own_allocator_hooks() noexcept {
    return JPH::Allocate == &checked_allocate &&
        JPH::Reallocate == &checked_reallocate &&
        JPH::Free == &checked_free &&
        JPH::AlignedAllocate == &checked_aligned_allocate &&
        JPH::AlignedFree == &checked_aligned_free;
}

void install_checked_default_allocators(RuntimeState& state) noexcept {
    JPH::RegisterDefaultAllocator();
    state.native = {JPH::Allocate, JPH::Reallocate, JPH::Free,
        JPH::AlignedAllocate, JPH::AlignedFree};
    JPH::Allocate = &checked_allocate;
    JPH::Reallocate = &checked_reallocate;
    JPH::Free = &checked_free;
    JPH::AlignedAllocate = &checked_aligned_allocate;
    JPH::AlignedFree = &checked_aligned_free;
    state.hooks_installed = true;
}

// Called with the process mutex held, only after all module shapes have died.
// Also cleans registration that threw partway through first initialization.
bool destroy_runtime_locked(RuntimeState& state) noexcept {
    if (JPH::Factory::sInstance != state.factory ||
        (state.hooks_installed && !own_allocator_hooks())) {
        // Unsupported foreign mutation: do not clear somebody else's factory,
        // invoke their allocator on our blocks, or pretend reentry is safe.
        state.poisoned = true;
        return false;
    }
    try {
        if (state.registration_attempted) JPH::UnregisterTypes();
        delete state.factory;
        state.factory = nullptr;
        JPH::Factory::sInstance = nullptr;
        state.registration_attempted = false;
        // The only admitted initial hook set is all-null. Restore it only after
        // registered maps, default material and Factory storage are released.
        if (state.hooks_installed) {
            JPH::Allocate = nullptr;
            JPH::Reallocate = nullptr;
            JPH::Free = nullptr;
            JPH::AlignedAllocate = nullptr;
            JPH::AlignedFree = nullptr;
            state.hooks_installed = false;
            state.native = {};
        }
        return true;
    } catch (...) {
        // No exception escapes a lease destructor. Retain remaining ownership
        // and reject future acquisitions rather than risk a double teardown.
        state.poisoned = true;
        return false;
    }
}

} // namespace

RuntimeLease::~RuntimeLease() noexcept { release(); }

RuntimeLease::RuntimeLease(RuntimeLease&& other) noexcept
    : active_(std::exchange(other.active_, false)) {}

RuntimeLease& RuntimeLease::operator=(RuntimeLease&& other) noexcept {
    if (this != &other) {
        release();
        active_ = std::exchange(other.active_, false);
    }
    return *this;
}

void RuntimeLease::release() noexcept {
    if (!std::exchange(active_, false)) return;
    auto& state = runtime_state();
    try {
        std::lock_guard lock(state.mutex);
        if (state.users == 0) {
            state.poisoned = true;
            return;
        }
        --state.users;
        if (state.users == 0) (void)destroy_runtime_locked(state);
    } catch (...) {
        // An unexpected mutex failure must not destroy a runtime possibly still
        // in use. Conservatively retain its count/storage; never throw here.
    }
}

RuntimeAcquire acquire_runtime() noexcept {
    auto& state = runtime_state();
    try {
        std::lock_guard lock(state.mutex);
        if (state.poisoned) {
            return {Outcome::InternalError, {}, "RuntimePoisoned",
                "A previous runtime ownership or teardown failure prevents reuse."};
        }
        if (state.users != 0) {
            if (!state.factory || JPH::Factory::sInstance != state.factory ||
                !own_allocator_hooks()) {
                return {Outcome::Unsupported, {}, "ForeignJoltRuntime",
                    "Jolt process globals changed while collision worlds were alive."};
            }
            if (state.users == std::numeric_limits<std::size_t>::max()) {
                return {Outcome::ResourceLimit, {}, "RuntimeLeaseLimit",
                    "The runtime lease count cannot be increased."};
            }
            ++state.users;
            return {Outcome::Ok, RuntimeLease(true), "", ""};
        }
        if (JPH::Factory::sInstance != nullptr || !no_allocator_hooks() ||
            JPH::PhysicsMaterial::sDefault != nullptr) {
            return {Outcome::Unsupported, {}, "ForeignJoltRuntime",
                "Standalone ownership requires a null Jolt Factory, default material and allocator hooks."};
        }
        if (!JPH::VerifyJoltVersionID()) {
            return {Outcome::Unsupported, {}, "JoltVersionMismatch",
                "The adapter and Jolt library version/configuration IDs differ."};
        }
        try {
            install_checked_default_allocators(state);
            state.factory = new JPH::Factory();
            JPH::Factory::sInstance = state.factory;
            state.registration_attempted = true;
            JPH::RegisterTypes();
            state.users = 1;
            return {Outcome::Ok, RuntimeLease(true), "", ""};
        } catch (const std::bad_alloc&) {
            const bool cleaned = destroy_runtime_locked(state);
            // Exact-source HashTable growth is not strongly exception-safe.
            // Prevent repeated attempts from accumulating uncertain allocations
            // that are no longer reachable through an engine object.
            state.poisoned = true;
            return {cleaned ? Outcome::AllocationFailure : Outcome::InternalError, {},
                cleaned ? "RuntimeAllocationFailure" : "RuntimeCleanupFailure",
                cleaned ? "Jolt runtime initialization allocation failed; reachable runtime resources released; process restart required."
                        : "Jolt runtime allocation failed and cleanup could not be completed."};
        } catch (...) {
            const bool cleaned = destroy_runtime_locked(state);
            state.poisoned = true;
            return {Outcome::InternalError, {},
                cleaned ? "RuntimeInitializationFailure" : "RuntimeCleanupFailure",
                cleaned ? "Jolt runtime initialization failed; reachable runtime resources released; process restart required."
                        : "Jolt runtime initialization failed and cleanup could not be completed."};
        }
    } catch (...) {
        return {Outcome::InternalError, {}, "RuntimeSynchronizationFailure",
            "The process-global Jolt lifecycle lock could not be acquired."};
    }
}

} // namespace cyrus::vegetation::prototype_v1::collision_detail
