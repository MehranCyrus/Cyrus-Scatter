#pragma once

// Private standalone-process ownership; this is not a host/DLL integration API.
// No Jolt type crosses this header or the frozen public interface.
#include <cyrus_vegetation/prototype_v1.hpp>

namespace cyrus::vegetation::prototype_v1::collision_detail {

struct RuntimeAcquire;

class RuntimeLease final {
public:
    RuntimeLease() noexcept = default;
    ~RuntimeLease() noexcept;
    RuntimeLease(const RuntimeLease&) = delete;
    RuntimeLease& operator=(const RuntimeLease&) = delete;
    RuntimeLease(RuntimeLease&& other) noexcept;
    RuntimeLease& operator=(RuntimeLease&& other) noexcept;
    bool valid() const noexcept { return active_; }

private:
    explicit RuntimeLease(bool active) noexcept : active_(active) {}
    void release() noexcept;
    bool active_ = false;
    friend RuntimeAcquire acquire_runtime() noexcept;
};

struct RuntimeAcquire {
    Outcome outcome = Outcome::InternalError;
    RuntimeLease lease;
    const char* code = "RuntimeInternalError";
    const char* message = "Runtime acquisition did not complete.";
};

// The World declares its lease BEFORE every Jolt shape-owning member, so those
// members are destroyed first. Every acquisition and final release shares one
// mutex and a manual count; no weak_ptr expiration/reinitialization window.
RuntimeAcquire acquire_runtime() noexcept;

} // namespace cyrus::vegetation::prototype_v1::collision_detail
