#ifndef CYRUS_NATIVE_LICENSE_EXPERIMENT
#error Never compile development authority into an ordinary product build
#endif
#ifdef CYRUS_LICENSE_INSTALLATION_CONTEXT
// MAXScript defines is_string/is_array macros; parse the JSON library before
// introducing those host macros into this translation unit.
#include <nlohmann/json.hpp>
#endif
#include <max.h>
#include <notify.h>
#include <maxscript/maxscript.h>
#include <maxscript/foundation/arrays.h>
#include <maxscript/foundation/numbers.h>
#include <maxscript/foundation/strings.h>
#include <maxscript/macros/define_instantiation_functions.h>
#include "signed_support.h"
#include "license_boundary.h"
#include <chrono>
#include <thread>
#include <condition_variable>
#include <fstream>
#ifdef CYRUS_LICENSE_INSTALLATION_CONTEXT
#include "cyrus/licensing/client.h"
#include "lab_installation_context.h"
#endif

using namespace cyrus::licensing;
namespace {
#ifdef CYRUS_LICENSE_INSTALLATION_CONTEXT
struct NativeRuntime {
    LocalLicenseClient value;
    std::mutex mutex;
    std::condition_variable wake;
    bool stopping=false;
    std::uint64_t cycles=0;
    std::string error;
    std::thread worker;
    static TrustProfile activation(){auto trust=signedLabTrust();trust.token_type+=".activation";return trust;}
    explicit NativeRuntime(bool create):value(signedLabTrust(),activation(),signedLabHost(),CyrusLabKeyName,CyrusLabStatePath,create),
        worker([this]{run();}) {}
    void cycle(bool refresh) noexcept {
        try {
            if(refresh)value.refresh();
            value.checkpoint();
            std::lock_guard lock(mutex);++cycles;error.clear();
        }catch(const std::exception& e){std::lock_guard lock(mutex);error=e.what();}
        catch(...){std::lock_guard lock(mutex);error="Local licensing maintenance failed";}
    }
    void run() noexcept {
        std::unique_lock lock(mutex);
        while(!wake.wait_for(lock,std::chrono::seconds(60),[this]{return stopping;})) {
            lock.unlock();cycle(true);lock.lock();
        }
        lock.unlock();cycle(false);
    }
    void stop() {
        {std::lock_guard lock(mutex);stopping=true;}wake.notify_all();
        if(worker.joinable())worker.join();
    }
    ~NativeRuntime(){stop();}
};
// Main-thread host adapter; workers touch only LocalLicenseClient and numeric
// state, never Max nodes/UI. Destroy explicitly before DLL unload, not in a
// global/static destructor under DllMain's loader lock.
NativeRuntime* runtimeValue=nullptr;
bool shuttingDown=false;
void shutdown(void*,NotifyInfo*) {
    shuttingDown=true;
    if(!runtimeValue)return;
    try {
        const auto start=GetTickCount64();runtimeValue->stop();
        const auto receipt=std::filesystem::path(CyrusLabStatePath)/("shutdown-"+std::to_string(GetCurrentProcessId())+".json");
        std::ofstream output(receipt);output<<nlohmann::json{{"joined",true},{"cycles",runtimeValue->cycles},
            {"error",runtimeValue->error},{"elapsed_ms",GetTickCount64()-start}}.dump();
        delete runtimeValue;runtimeValue=nullptr;
    }catch(...){/* Never throw through host shutdown. OS terminates a crashed host. */}
}
NativeRuntime& runtime(bool create=false) {
    if(shuttingDown)throw std::runtime_error("Cyrus licensing is shutting down");
    if(!runtimeValue) {
        auto value=std::make_unique<NativeRuntime>(create);
        if(!RegisterNotification(shutdown,nullptr,NOTIFY_SYSTEM_SHUTDOWN))throw std::runtime_error("Cannot register native licensing lifetime");
        runtimeValue=value.release();
    }
    return *runtimeValue;
}
LocalLicenseClient& client(bool create=false) {return runtime(create).value;}
#else
LicenseSession& session() {
    static LicenseSession value(signedLabTrust(), signedLabHost());
    return value;
}
// Test clock belongs to this NEVER SHIP target only. The real host provider is
// a separate foundation; no production environment/config toggle selects this.
std::int64_t labUtc = 0;
std::uint64_t ticks() noexcept { return GetTickCount64(); }
#endif
String* text(const char* value) {
    const std::string input(value);
    return new String(std::wstring(input.begin(), input.end()).c_str());
}
}

bool cyrusBoundaryAllows(const void* owner) noexcept {
    auto permit = cyrusBoundaryBegin(owner);
    return cyrusBoundaryCommit(permit, owner);
}
cyrus::licensing::OperationPermit cyrusBoundaryBegin(const void* owner) noexcept {
#ifdef CYRUS_LICENSE_INSTALLATION_CONTEXT
    try { return client().admit(Operation::AuthorScatter,owner); } catch(...) { return {}; }
#else
    return session().admit(Operation::AuthorScatter, owner, {labUtc > 0, labUtc}, ticks(), 30000);
#endif
}
bool cyrusBoundaryCommit(cyrus::licensing::OperationPermit& permit, const void* owner) noexcept {
#ifdef CYRUS_LICENSE_INSTALLATION_CONTEXT
    try { return client().consume(permit,Operation::AuthorScatter,owner); } catch(...) { return false; }
#else
    return session().consume(permit, Operation::AuthorScatter, owner, ticks());
#endif
}

#ifndef CYRUS_LICENSE_INSTALLATION_CONTEXT
def_visible_primitive(cyrusOwnedLabClock, "cyrusOwnedLabClock");
Value* cyrusOwnedLabClock_cf(Value** a, int n) {
    check_arg_count(cyrusOwnedLabClock, 1, n);
    labUtc = a[0]->to_int64();
    return &ok;
}
#endif
def_visible_primitive(cyrusOwnedLabInstall, "cyrusOwnedLabInstall");
Value* cyrusOwnedLabInstall_cf(Value** a, int n) {
    check_arg_count(cyrusOwnedLabInstall, 1, n);
    type_check(a[0], String, _T("compact JWS"));
    const auto* wide = a[0]->to_string();
    const auto size = wcslen(wide);
    if (size > 8192) return text("size");
    std::string token; token.reserve(size);
    for (std::size_t i = 0; i < size; ++i) {
        if (wide[i] > 127) return text("encoding");
        token.push_back(static_cast<char>(wide[i]));
    }
#ifdef CYRUS_LICENSE_INSTALLATION_CONTEXT
    try { client().importRenewal(token);return text("verified"); }
    catch(const std::exception& error) { return text(error.what()); }
#else
    return text(tokenErrorName(session().install(token)));
#endif
}
def_visible_primitive(cyrusOwnedLabStatus, "cyrusOwnedLabStatus");
Value* cyrusOwnedLabStatus_cf(Value**, int n) {
    check_arg_count(cyrusOwnedLabStatus, 0, n);
#ifdef CYRUS_LICENSE_INSTALLATION_CONTEXT
    try { return text(reasonName(client().status().reason)); }
    catch(const std::exception& error) { return text(error.what()); }
#else
    return text(reasonName(session().decide(Operation::AuthorScatter, {labUtc > 0, labUtc}).reason));
#endif
}

#ifdef CYRUS_LICENSE_INSTALLATION_CONTEXT
extern "C" __declspec(dllexport) int LibShutdown() {
    shutdown(nullptr,nullptr);UnRegisterNotification(shutdown,nullptr,NOTIFY_SYSTEM_SHUTDOWN);return TRUE;
}
def_visible_primitive(cyrusOwnedLabWorkerStats,"cyrusOwnedLabWorkerStats");
Value* cyrusOwnedLabWorkerStats_cf(Value**,int n) {
    check_arg_count(cyrusOwnedLabWorkerStats,0,n);
    auto& state=runtime();std::lock_guard lock(state.mutex);
    const auto value=nlohmann::json{{"cycles",state.cycles},{"error",state.error},{"interval_seconds",60}}.dump();
    return text(value.c_str());
}
def_visible_primitive(cyrusOwnedLabActivate,"cyrusOwnedLabActivate");
Value* cyrusOwnedLabActivate_cf(Value** a,int n) {
    check_arg_count(cyrusOwnedLabActivate,1,n);type_check(a[0],String,_T("activation response"));
    const auto* wide=a[0]->to_string();const auto size=wcslen(wide);
    if(size>8192)return text("size");
    std::string response;response.reserve(size);
    for(std::size_t i=0;i<size;++i){if(wide[i]>127)return text("encoding");response+=static_cast<char>(wide[i]);}
    try { client().activate(response);return text("verified"); }
    catch(const std::exception& error) { return text(error.what()); }
}
def_visible_primitive(cyrusOwnedLabRefresh,"cyrusOwnedLabRefresh");
Value* cyrusOwnedLabRefresh_cf(Value**,int n) {
    check_arg_count(cyrusOwnedLabRefresh,0,n);
    try { client().refresh();return text(reasonName(client().status().reason)); }
    catch(const std::exception& error) { return text(error.what()); }
}
def_visible_primitive(cyrusOwnedLabRequest,"cyrusOwnedLabRequest");
Value* cyrusOwnedLabRequest_cf(Value**,int n) {
    check_arg_count(cyrusOwnedLabRequest,0,n);
    try {
        const auto request=client(true).requestActivation();
        auto hex=[](const auto& bytes){std::string result;constexpr char digits[]="0123456789abcdef";for(auto b:bytes){result+=digits[b>>4];result+=digits[b&15];}return result;};
        const auto value=nlohmann::json{{"device",request.device},{"nonce",request.nonce},{"subject",request.subject},{"tenant",request.tenant},
            {"product",request.product},{"public_xy",hex(request.public_key)},{"proof",hex(request.proof)}}.dump();
        return text(value.c_str());
    } catch(const std::exception& error) { throw RuntimeError(MSTR::FromACP(error.what())); }
}
#endif
