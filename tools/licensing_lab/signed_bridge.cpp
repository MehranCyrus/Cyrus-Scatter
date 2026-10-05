#ifndef CYRUS_SIGNED_LICENSE_LAB_ONLY
#error The ephemeral issuer and synthetic identity must never enter a product target
#endif
#include <max.h>
#include <maxscript/maxscript.h>
#include <maxscript/foundation/arrays.h>
#include <maxscript/foundation/numbers.h>
#include <maxscript/foundation/strings.h>
#include <maxscript/macros/define_instantiation_functions.h>
#include "signed_support.h"

using namespace cyrus::licensing;
static_assert(MAX_PRODUCT_YEAR_NUMBER == CYRUS_MAX_YEAR, "SDK mismatch");
extern "C" __declspec(dllexport) const TCHAR* LibDescription() {
    return _T("Cyrus SIGNED LICENSE LAB ONLY - synthetic device/time, ephemeral issuer");
}
extern "C" __declspec(dllexport) ULONG LibVersion() { return VERSION_3DSMAX; }
extern "C" __declspec(dllexport) void LibInit() {}
BOOL WINAPI DllMain(HINSTANCE, DWORD, LPVOID) { return TRUE; }

static std::unique_ptr<LicenseSession>& sessionOwner() {
    static auto value = std::make_unique<LicenseSession>(signedLabTrust(), signedLabHost());
    return value;
}
static LicenseSession& session() { return *sessionOwner(); }
static String* text(const char* value) {
    const std::string narrow(value);
    const std::wstring wide(narrow.begin(), narrow.end());
    return new String(wide.c_str());
}
def_visible_primitive(cyrusSignedLabIdentity, "cyrusSignedLabIdentity");
Value* cyrusSignedLabIdentity_cf(Value**, int count) {
    check_arg_count(cyrusSignedLabIdentity, 0, count);
    return text("Signed license lab 1; NEVER SHIP");
}
def_visible_primitive(cyrusSignedLabReset, "cyrusSignedLabReset");
Value* cyrusSignedLabReset_cf(Value**, int count) {
    check_arg_count(cyrusSignedLabReset, 0, count);
    sessionOwner() = std::make_unique<LicenseSession>(signedLabTrust(), signedLabHost());
    return &ok;
}
def_visible_primitive(cyrusSignedLabInstall, "cyrusSignedLabInstall");
Value* cyrusSignedLabInstall_cf(Value** args, int count) {
    check_arg_count(cyrusSignedLabInstall, 1, count);
    type_check(args[0], String, _T("compact JWS token"));
    const auto* wide = args[0]->to_string();
    const auto length = wcslen(wide);
    if (length > 8192) return text("size");
    std::string token;
    token.reserve(length);
    for (std::size_t i = 0; i < length; ++i) {
        if (wide[i] > 127) return text("encoding");
        token.push_back(static_cast<char>(wide[i]));
    }
    return text(tokenErrorName(session().install(token)));
}
def_visible_primitive(cyrusSignedLabDecide, "cyrusSignedLabDecide");
Value* cyrusSignedLabDecide_cf(Value** args, int count) {
    check_arg_count(cyrusSignedLabDecide, 3, count);
    const auto op = static_cast<Operation>(static_cast<std::uint32_t>(args[0]->to_int()));
    const auto now = static_cast<std::int64_t>(args[1]->to_int64());
    const auto state = args[2]->to_int();
    if (state < 0 || state > 1) throw RuntimeError(_T("Invalid synthetic scene evidence"));
    const auto result = session().decide(op, {true, now},
        state == 1 ? StateEvidence::ApprovedExistingState : StateEvidence::Unproven);
    one_typed_value_local(Array* answer);
    vl.answer = new Array(2);
    vl.answer->append(result.allowed ? &true_value : &false_value);
    vl.answer->append(text(reasonName(result.reason)));
    return_value(vl.answer);
}
