#include "cyrus/licensing/local_state.h"
#include <algorithm>
#include <limits>
#include <windows.h>

namespace cyrus::licensing {
ClockTracker::ClockTracker(std::int64_t highest,std::int64_t now,std::uint64_t ticks) noexcept
    : start_(std::max(highest,now)),highest_(highest),ticks_(ticks),
      trusted_(highest>0&&highest<=253402300799LL&&now>0&&now<=253402300799LL&&now>=highest-2) {}

ClockObservation ClockTracker::observe(std::int64_t now,std::uint64_t ticks) noexcept {
    if(!trusted_||ticks<ticks_||now<=0||now>253402300799LL) { trusted_=false;return {false,highest_}; }
    const auto elapsed=(ticks-ticks_)/1000;
    if(elapsed>static_cast<std::uint64_t>(std::numeric_limits<std::int64_t>::max()-start_)) {
        trusted_=false;return {false,highest_};
    }
    const auto expected=start_+static_cast<std::int64_t>(elapsed);
    if(now<expected-2||now-expected>120) { trusted_=false;return {false,highest_}; }
    highest_=std::max({highest_,expected,now});
    return {true,highest_};
}
std::int64_t systemUtcSeconds() noexcept {
    FILETIME time;GetSystemTimeAsFileTime(&time);
    const auto ticks=(std::uint64_t(time.dwHighDateTime)<<32)|time.dwLowDateTime;
    return static_cast<std::int64_t>(ticks/10000000)-11644473600LL;
}
std::uint64_t systemMonotonicMs() noexcept { return GetTickCount64(); }
}
