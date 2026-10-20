#pragma once
#include <windows.h>
#include <string>

namespace cpl::diag {
// Fixed shared packet: the exception path does not allocate or acquire a lock.
struct CrashPacket {
    volatile LONG busy=0;
    DWORD thread=0;
    EXCEPTION_RECORD record{};
    CONTEXT context{};
};
void start(HMODULE module) noexcept;
void detach() noexcept;
void record(const char* event, const std::string& json="{}") noexcept;
void snapshot(const char* name, const std::string& json) noexcept;
std::wstring directory() noexcept;
std::string status() noexcept;
}
