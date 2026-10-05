#ifndef CYRUS_LICENSE_LAB_ONLY
#error The synthetic authority bridge must never enter a production target.
#endif

#include <max.h>
#include <maxscript/maxscript.h>
#include <maxscript/foundation/arrays.h>
#include <maxscript/foundation/numbers.h>
#include <maxscript/foundation/strings.h>
#include <maxscript/macros/define_instantiation_functions.h>
#include "cyrus/licensing/policy.h"

using namespace cyrus::licensing;
static_assert(MAX_PRODUCT_YEAR_NUMBER == CYRUS_MAX_YEAR, "SDK mismatch");
extern "C" __declspec(dllexport) const TCHAR* LibDescription() {
    return _T("Cyrus Licensing L0 LAB ONLY - synthetic authority, no verifier");
}
extern "C" __declspec(dllexport) ULONG LibVersion() { return VERSION_3DSMAX; }
extern "C" __declspec(dllexport) void LibInit() {}
BOOL WINAPI DllMain(HINSTANCE, DWORD, LPVOID) { return TRUE; }

def_visible_primitive(cyrusLicenseLabIdentity, "cyrusLicenseLabIdentity");
Value* cyrusLicenseLabIdentity_cf(Value**, int count) {
    check_arg_count(cyrusLicenseLabIdentity, 0, count);
    return new String(_T("L0 synthetic policy probe 1; NEVER SHIP"));
}

// Deliberately script-controlled TEST inputs. This proves policy wiring, not
// authorization. Current product primitives do not call this lab bridge.
def_visible_primitive(cyrusLicenseLabDecide, "cyrusLicenseLabDecide");
Value* cyrusLicenseLabDecide_cf(Value** args, int count) {
    check_arg_count(cyrusLicenseLabDecide, 4, count);
    const int operation = args[0]->to_int();
    const int scenario = args[1]->to_int();
    const auto now = static_cast<std::int64_t>(args[2]->to_int64());
    const int state = args[3]->to_int();
    if (scenario < 0 || scenario > 7 || state < 0 || state > 1)
        throw RuntimeError(_T("Invalid synthetic test scenario/state"));
    AuthorityFacts facts;
    ClockObservation clock{true, now};
    if (scenario != 0) {
        facts = {Authority::Verified, ScatterAuthorRight | AnalyzerAuthorRight,
                 true, true, true, 100, 200};
        if (scenario == 2) facts.authority = Authority::Rejected;
        if (scenario == 3) facts.authoring_end_utc = 400;
        if (scenario == 4) facts.device_matches = false;
        if (scenario == 5) facts.build_eligible = false;
        if (scenario == 6) facts.capacity_reserved = false;
        if (scenario == 7) clock.trusted = false;
    }
    const auto decision = operation >= 1 && operation <= 6
        ? decide(static_cast<Operation>(operation), facts, clock,
                 state == 1 ? StateEvidence::ApprovedExistingState : StateEvidence::Unproven)
        : Decision{false, Reason::UnknownOperation};
    one_typed_value_local(Array* result);
    vl.result = new Array(2);
    vl.result->append(decision.allowed ? &true_value : &false_value);
    vl.result->append(Integer::intern(static_cast<int>(decision.reason)));
    return_value(vl.result);
}
