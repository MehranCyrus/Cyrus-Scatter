#include "diagnostics.h"
#include <cstdlib>
#include <iostream>
#include <stdexcept>
#include <thread>
#include <vector>

using amin::diagnostics::Recorder;
void expect(bool condition, const char* message) { if (!condition) throw std::runtime_error(message); }
void contains(const std::string& result, const std::string& field) { expect(result.find(field) != std::string::npos, field.c_str()); }
int main() {
    try {
        std::uint64_t now = 100;
        Recorder recorder([&] { return now; });
        expect(!recorder.record("ignored", "test", "", 0, ""), "off means no events");
        recorder.start("fixture", {2, 2048, 100});
        expect(recorder.record("input", "test", "layer_a", 9, "quoted \"\\\n"), "record input");
        now += 5; recorder.record("publication", "test", "layer_a", 10, "committed");
        auto first = recorder.snapshot(0, 1);
        contains(first, "\"next_sequence\":1"); contains(first, "\"has_more\":true");
        contains(first, "quoted \\\"\\\\\\u000a");
        recorder.record("retained", "test", "layer_a", 10, "reused");
        auto page = recorder.snapshot(1, 500);
        contains(page, "\"oldest_sequence\":2"); contains(page, "\"evicted\":1");
        contains(page, "\"next_sequence\":3"); contains(page, "\"training_eligible\":false");
        expect(page.find("quoted") == std::string::npos, "eviction must actually remove data");
        bool rejected = false;
        try { recorder.start("overwrite"); } catch (const std::logic_error&) { rejected = true; }
        expect(rejected, "cannot silently erase active session");
        now = 200; expect(!recorder.record("late", "test", "", 0, ""), "duration bound");
        contains(recorder.snapshot(), "\"expired\":true");
        recorder.start("bounds", {100, 2048, 100});
        for (int i = 0; i < 100; ++i) recorder.record("event", "test", "", 0, std::string(1000, 'x'));
        contains(recorder.snapshot(), "\"truncated\":100");
        expect(recorder.snapshot().size() < 6000, "byte bound is independent of event count");
        recorder.stop(); expect(!recorder.active(), "stop");
        auto stopped = recorder.snapshot(); recorder.record("off", "test", "", 0, "");
        expect(stopped == recorder.snapshot(), "stopped recorder is inert with fixed clock");
        now += 10000;
        expect(stopped == recorder.snapshot(), "stopped report must not age into expiry");
        recorder.start("idle_expiry", {10, 2048, 20});
        now += 20;
        expect(!recorder.active(), "idle sessions expire without another event");
        contains(recorder.snapshot(), "\"expired\":true");
        recorder.start("after_idle_expiry", {10, 2048, 20});
        expect(recorder.active(), "expired idle session can be replaced explicitly");
        recorder.stop();
        bool badSession=false, badLimit=false;
        try { recorder.start("path/not-an-id"); } catch (const std::invalid_argument&) { badSession=true; }
        try { recorder.start("too_large", {16385, 2048, 20}); } catch (const std::invalid_argument&) { badLimit=true; }
        expect(badSession && badLimit, "invalid IDs and work limits fail closed");
        recorder.start("utf8", {10, 2048, 20});
        recorder.record("event", "test", "", 0, std::string(511, 'x') + "\xc3\xa9");
        auto unicode=recorder.snapshot();
        contains(unicode, "\"truncated\":1");
        expect(unicode.find('\xc3') == std::string::npos, "truncation must not split a UTF-8 codepoint");
        recorder.stop();
        Recorder concurrent; concurrent.start("concurrent");
        std::vector<std::thread> workers;
        std::atomic<unsigned> accepted{0};
        for (int i = 0; i < 4; ++i) workers.emplace_back([&] { for (int n = 0; n < 1000; ++n) if(concurrent.record("event", "worker", "", 0, "copy")) ++accepted; });
        for (auto& thread : workers) thread.join();
        concurrent.stop(); contains(concurrent.snapshot(0, 0), "\"events\":[]");
        contains(concurrent.snapshot(), "\"failures\":0");
        auto counters=concurrent.snapshot(0,0);
        const auto start=counters.find("\"lock_drops\":")+13;
        expect(std::stoull(counters.substr(start))+accepted.load()==4000, "every nonblocking write is recorded or reported as lost");
        std::cout << "diagnostics: bounded paging, overflow, duration, inactive and concurrent paths passed\n";
        return EXIT_SUCCESS;
    } catch (const std::exception& error) { std::cerr << error.what() << '\n'; return EXIT_FAILURE; }
}
