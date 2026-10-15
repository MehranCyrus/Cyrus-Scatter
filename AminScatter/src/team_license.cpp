// The owner signer is a separate tool. This module contains public trust only.
#include <nlohmann/json.hpp>
#include "cyrus/licensing/client.h"
#include "team_public_key.h"
#include "license_boundary.h"
#include <max.h>
#include <notify.h>
#include <hold.h>
#include <shlobj.h>
#include <maxscript/maxscript.h>
#include <maxscript/foundation/arrays.h>
#include <maxscript/foundation/numbers.h>
#include <maxscript/foundation/strings.h>
#include <maxscript/macros/define_instantiation_functions.h>
#include <algorithm>
#include <atomic>
#include <chrono>
#include <condition_variable>
#include <thread>

using namespace cyrus::licensing;
namespace {
TrustProfile trust() {
    IssuerKey key;key.id=CyrusTeamKeyID;
    std::copy(std::begin(CyrusTeamPublicXY),std::end(CyrusTeamPublicXY),key.p256_xy.begin());
    return {"urn:cyrus:team-offline:v1","cyrus-team-offline","cyrus-team-license+jwt",{key}};
}
std::wstring keyName() {
    std::string id=CyrusTeamKeyID;return L"CyrusScatter-Team-"+std::wstring(id.begin(),id.end());
}
std::filesystem::path statePath() {
    PWSTR value=nullptr;
    if(FAILED(SHGetKnownFolderPath(FOLDERID_LocalAppData,0,nullptr,&value)))throw std::runtime_error("Windows Local AppData unavailable");
    std::filesystem::path path(value);CoTaskMemFree(value);
    return path/L"CyrusScatter"/L"Licenses"/CyrusTeamKeyID;
}
struct Runtime {
    LocalLicenseClient client;
    std::mutex mutex;
    std::condition_variable wake;
    bool stopping=false;
    std::atomic<bool> storageHealthy{true};
    std::thread worker;
    Runtime():client(trust(),trust(),{"team-seat","cyrus-team","cyrus-scatter","",79},keyName(),statePath(),true),worker([this]{run();}) {}
    void maintain() noexcept {
        try {client.refresh();if(client.expires())client.checkpoint();storageHealthy=true;}
        catch(...){if(client.expires())storageHealthy=false;}
    }
    void run() noexcept {
        std::unique_lock lock(mutex);
        while(!wake.wait_for(lock,std::chrono::seconds(60),[this]{return stopping;})) {
            lock.unlock();maintain();lock.lock();
        }
        lock.unlock();maintain();
    }
    ~Runtime(){ {std::lock_guard lock(mutex);stopping=true;}wake.notify_all();if(worker.joinable())worker.join(); }
};
// Only the Max thread creates/destroys this runtime. The worker touches no SDK.
Runtime* runtimeValue=nullptr;
bool shuttingDown=false;
void shutdown(void*,NotifyInfo*) {
    shuttingDown=true;delete runtimeValue;runtimeValue=nullptr;
}
Runtime& runtime() {
    if(shuttingDown)throw std::runtime_error("Cyrus licensing is shutting down");
    if(!runtimeValue) {
        auto value=std::make_unique<Runtime>();
        if(!RegisterNotification(shutdown,nullptr,NOTIFY_SYSTEM_SHUTDOWN))throw std::runtime_error("Cannot register licensing shutdown");
        runtimeValue=value.release();
    }
    return *runtimeValue;
}
String* text(const std::string& value){return new String(MSTR::FromUTF8(value.c_str()));}
std::string token(Value* value) {
    type_check(value,String,_T("license text"));const auto* data=value->to_string();
    const auto size=wcslen(data);if(!size||size>8192)throw std::runtime_error("License must contain 1..8192 ASCII characters");
    std::string result;result.reserve(size);
    for(std::size_t i=0;i<size;++i){if(data[i]>127)throw std::runtime_error("License encoding is invalid");result+=char(data[i]);}
    return result;
}
}
OperationPermit cyrusBoundaryBegin(const void* owner) noexcept {
    try {auto& r=runtime();if(!r.storageHealthy)return {};return r.client.admit(Operation::AuthorScatter,owner);}
    catch(...){return {};}
}
bool cyrusBoundaryCommit(OperationPermit& permit,const void* owner) noexcept {
    try {auto& r=runtime();return r.storageHealthy&&r.client.consume(permit,Operation::AuthorScatter,owner);}
    catch(...){return false;}
}
bool cyrusBoundaryAllows(const void* owner) noexcept {
    auto permit=cyrusBoundaryBegin(owner);return cyrusBoundaryCommit(permit,owner);
}
void cyrusRecipeLibraryShutdown();
extern "C" __declspec(dllexport) int LibShutdown() {
    cyrusRecipeLibraryShutdown();
    shutdown(nullptr,nullptr);UnRegisterNotification(shutdown,nullptr,NOTIFY_SYSTEM_SHUTDOWN);return TRUE;
}
def_visible_primitive(cyrusLicenseAllows,"cyrusLicenseAllows");
Value* cyrusLicenseAllows_cf(Value**,int n) {
    check_arg_count(cyrusLicenseAllows,0,n);return cyrusBoundaryAllows(&runtimeValue)?&true_value:&false_value;
}
def_visible_primitive(cyrusLicenseRestoring,"cyrusLicenseRestoring");
Value* cyrusLicenseRestoring_cf(Value**,int n) {
    check_arg_count(cyrusLicenseRestoring,0,n);return theHold.RestoreOrRedoing()?&true_value:&false_value;
}
def_visible_primitive(cyrusLicenseStatus,"cyrusLicenseStatus");
Value* cyrusLicenseStatus_cf(Value**,int n) {
    check_arg_count(cyrusLicenseStatus,0,n);
    one_typed_value_local(Array* result);vl.result=new Array(5);
    bool allowed=false;std::string reason,device;std::int64_t expires=0;
    try {auto& r=runtime();const auto status=r.client.status();allowed=r.storageHealthy&&status.allowed;
        reason=r.storageHealthy?reasonName(status.reason):"Local license state unavailable; check storage and restart Max";
        device=r.client.device();expires=r.client.expires();}
    catch(const std::exception& e){reason=e.what();}
    vl.result->append(allowed?&true_value:&false_value);vl.result->append(text(reason));
    vl.result->append(text(device));vl.result->append(Integer64::intern(expires));vl.result->append(text(CyrusTeamKeyID));
    return_value(vl.result);
}
def_visible_primitive(cyrusLicenseRequest,"cyrusLicenseRequest");
Value* cyrusLicenseRequest_cf(Value**,int n) {
    check_arg_count(cyrusLicenseRequest,0,n);
    try {
        const auto request=runtime().client.requestActivation();
        auto hex=[](const auto& bytes){std::string result;constexpr char digits[]="0123456789abcdef";for(auto b:bytes){result+=digits[b>>4];result+=digits[b&15];}return result;};
        return text(nlohmann::json{{"device",request.device},{"nonce",request.nonce},{"subject",request.subject},
            {"tenant",request.tenant},{"product",request.product},{"public_xy",hex(request.public_key)},{"proof",hex(request.proof)}}.dump());
    }catch(const std::exception& e){throw RuntimeError(MSTR::FromACP(e.what()));}
}
def_visible_primitive(cyrusLicenseImport,"cyrusLicenseImport");
Value* cyrusLicenseImport_cf(Value** a,int n) {
    check_arg_count(cyrusLicenseImport,1,n);
    try {auto& r=runtime();r.client.importOfflineLicense(token(a[0]));r.storageHealthy=true;return &true_value;}
    catch(const std::exception& e){throw RuntimeError(MSTR::FromACP(e.what()));}
}
