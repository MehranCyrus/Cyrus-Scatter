#include <max.h>
#include <maxscript/maxscript.h>
#include <maxscript/foundation/numbers.h>
#include <maxscript/foundation/strings.h>
#include <maxscript/macros/define_instantiation_functions.h>
#include "diagnostics.h"
#include <stdexcept>

namespace {
std::string utf8(const wchar_t* value) {
    const int length = WideCharToMultiByte(CP_UTF8, 0, value, -1, nullptr, 0, nullptr, nullptr);
    if (length <= 0) throw std::runtime_error("UTF-8 conversion failed");
    std::string result(static_cast<std::size_t>(length), '\0');
    WideCharToMultiByte(CP_UTF8, 0, value, -1, result.data(), length, nullptr, nullptr);
    result.pop_back(); return result;
}
Value* textResult(const std::string& value) {
    const int length = MultiByteToWideChar(CP_UTF8, 0, value.c_str(), -1, nullptr, 0);
    if (length <= 0) throw RuntimeError(_T("Diagnostic UTF-8 conversion failed"));
    std::wstring result(static_cast<std::size_t>(length), L'\0');
    MultiByteToWideChar(CP_UTF8, 0, value.c_str(), -1, result.data(), length);
    return new String(result.c_str());
}
}
def_visible_primitive(cyrusDiagnosticActive, "cyrusDiagnosticActive");
Value* cyrusDiagnosticActive_cf(Value**, int count) {
    check_arg_count(cyrusDiagnosticActive, 0, count);
    return amin::diagnostics::recorder().active() ? &true_value : &false_value;
}
def_visible_primitive(cyrusDiagnosticStart, "cyrusDiagnosticStart");
Value* cyrusDiagnosticStart_cf(Value** args, int count) {
    check_arg_count(cyrusDiagnosticStart, 4, count);
    const int events = args[1]->to_int(), bytes = args[2]->to_int(), duration = args[3]->to_int();
    if (events <= 0 || bytes <= 0 || duration <= 0) throw RuntimeError(_T("Diagnostic limits must be positive"));
    try {
        amin::diagnostics::recorder().start(utf8(args[0]->to_string()),
            {static_cast<std::size_t>(events), static_cast<std::size_t>(bytes), static_cast<std::uint64_t>(duration)});
        return &true_value;
    } catch (const std::exception&) { throw RuntimeError(_T("Cannot start diagnostics: stop an active session and check bounded limits.")); }
}
def_visible_primitive(cyrusDiagnosticStop, "cyrusDiagnosticStop");
Value* cyrusDiagnosticStop_cf(Value**, int count) {
    check_arg_count(cyrusDiagnosticStop, 0, count);
    amin::diagnostics::recorder().stop(); return &true_value;
}
def_visible_primitive(cyrusDiagnosticEvent, "cyrusDiagnosticEvent");
Value* cyrusDiagnosticEvent_cf(Value** args, int count) {
    check_arg_count(cyrusDiagnosticEvent, 5, count);
    auto& recorder = amin::diagnostics::recorder();
    if (!recorder.active()) return &false_value;
    try {
        const auto epoch = args[3]->to_int64();
        if (epoch < 0) return &false_value;
        return recorder.record(utf8(args[0]->to_string()), utf8(args[1]->to_string()), utf8(args[2]->to_string()),
            static_cast<std::uint64_t>(epoch), utf8(args[4]->to_string())) ? &true_value : &false_value;
    } catch (...) { return &false_value; } // Diagnostics never abort scene work.
}
def_visible_primitive(cyrusDiagnosticSnapshot, "cyrusDiagnosticSnapshot");
Value* cyrusDiagnosticSnapshot_cf(Value** args, int count) {
    check_arg_count(cyrusDiagnosticSnapshot, 2, count);
    const auto after = args[0]->to_int64(); const int limit = args[1]->to_int();
    if (after < 0 || limit < 0 || limit > 500) throw RuntimeError(_T("Invalid diagnostic page bounds"));
    return textResult(amin::diagnostics::recorder().snapshot(static_cast<std::uint64_t>(after), static_cast<std::size_t>(limit)));
}
