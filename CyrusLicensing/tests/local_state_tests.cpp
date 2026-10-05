#include "cyrus/licensing/local_state.h"
#include "../src/cng_signature.h"
#include <windows.h>
#include <ncrypt.h>
#include <fstream>
#include <iostream>
#include <stdexcept>

using namespace cyrus::licensing;
namespace {
int checks=0;
void require(bool value,const char* text) { ++checks;if(!value)throw std::runtime_error(text); }
template<class F> bool rejects(F f) { try { f();return false; }catch(const std::exception&){return true;} }
struct TestKeyCleanup {
    std::wstring name;
    ~TestKeyCleanup() {
        NCRYPT_PROV_HANDLE provider=0;NCRYPT_KEY_HANDLE key=0;
        if(NCryptOpenStorageProvider(&provider,MS_KEY_STORAGE_PROVIDER,0)==ERROR_SUCCESS) {
            if(NCryptOpenKey(provider,&key,name.c_str(),0,NCRYPT_SILENT_FLAG)==ERROR_SUCCESS)NCryptDeleteKey(key,0);
            NCryptFreeObject(provider);
        }
    }
};
}
int wmain(int argc,wchar_t** argv) {
    try {
        if(argc!=3)throw std::runtime_error("Expected group and isolated test path");
        const std::wstring group=argv[1];const std::filesystem::path path=argv[2];
        if(group==L"clock") {
            ClockTracker absent(0,1000,10);require(!absent.observe(1000,10).trusted,"Missing anchor needs recovery");
            ClockTracker rollback(1000,900,10);require(!rollback.observe(900,10).trusted,"Restart clock rollback denied");
            ClockTracker clock(1000,1000,10);
            require(clock.observe(1001,1010).utc_seconds==1001,"Elapsed UTC follows monotonic");
            require(clock.observe(4600,3600010).trusted,"Sleep-inclusive monotonic elapsed");
            require(!clock.observe(4500,3600010).trusted,"Runtime backward clock denied");
            require(!clock.observe(4600,3600010).trusted,"Recovery required remains latched");
            ClockTracker forward(1000,1000,10);require(!forward.observe(10000,1010).trusted,"Runtime forward jump needs recovery");
            ClockTracker ticks(1000,1000,100);require(!ticks.observe(1000,99).trusted,"Monotonic rollback denied");
            ClockTracker restart(1000,1000+366*86400LL,10);
            require(restart.observe(1000+366*86400LL,10).trusted,"Closed-app calendar elapsed does not require periodic refresh");
            ClockTracker tolerance(1000,999,10);require(tolerance.observe(999,10).utc_seconds==1000,"Small skew never decreases time");
            require(systemUtcSeconds()>1700000000,"Real UTC provider");
        } else if(group==L"key") {
            const std::wstring name=L"CyrusLicensing-PRIVATE-TEST-"+std::to_wstring(GetCurrentProcessId())+L"-"+std::to_wstring(GetTickCount64());
            TestKeyCleanup cleanup{name};
            require(rejects([&]{InstallationKey missing(name,false);}),"Missing key does not silently recreate");
            InstallationKey key(name,true), reopened(name,false);
            require(key.deviceId().size()==64&&key.deviceId()==reopened.deviceId(),"Persisted installation identity survives reopen");
            require(key.privateExportDenied(),"Software provider refuses private export");
            const std::string challenge="activation-test-nonce-0123456789";
            auto signature=key.signChallenge(challenge);
            IssuerKey publicKey{"device",key.publicKey()};
            const std::string bytes(reinterpret_cast<char*>(signature.data()),signature.size());
            require(detail::verifyES256(publicKey,"cyrus-device-proof-v1:"+challenge,bytes)==TokenError::None,"Real private-key possession proof");
            require(detail::verifyES256(publicKey,"cyrus-device-proof-v1:different-nonce",bytes)!=TokenError::None,"Proof bound to challenge");
            require(rejects([&]{key.signChallenge("short");}),"Unbounded/short challenge rejected");
        } else if(group==L"store") {
            const auto isolated=path/(L"case-"+std::to_wstring(GetCurrentProcessId())+L"-"+std::to_wstring(GetTickCount64()));
            LocalStateStore store(isolated);
            require(!store.read(),"Missing protected state distinguished");
            store.update([](LocalState& state){state.device=std::string(64,'a');state.highest_utc=1000;state.token="retained-test-authority";});
            require(store.read()->generation==1,"First atomic generation");
            require(rejects([&]{store.update([](LocalState& state){state.highest_utc=900;});}),"Protected high-water cannot decrease");
            require(store.read()->generation==1,"Rejected write retains previous data");
            require(rejects([&]{store.update([](LocalState& state){state.device=std::string(64,'b');});}),"Different installation requires recovery");
            require(rejects([&]{store.update([](LocalState&){throw std::runtime_error("cancel");});}),"Cancelled update propagates");
            require(store.read()->token=="retained-test-authority","Cancelled transaction retains authority");
            std::ifstream file(isolated/L"state.dpapi",std::ios::binary);
            const std::string ciphertext((std::istreambuf_iterator<char>(file)),{});file.close();
            require(ciphertext.find("retained-test-authority")==std::string::npos,"Persisted payload is protected");
            auto broken=ciphertext;broken[broken.size()/2]^=1;
            std::ofstream changed(isolated/L"state.dpapi",std::ios::binary);changed.write(broken.data(),broken.size());changed.close();
            require(rejects([&]{store.read();}),"Tampered protected data requires recovery");
            require(rejects([&]{store.update([](LocalState& state){state.token="replacement";});}),"Corruption never overwritten as absent state");
            std::ofstream restore(isolated/L"state.dpapi",std::ios::binary);restore.write(ciphertext.data(),ciphertext.size());restore.close();
            require(store.read()->generation==1,"Whole protected backup replay remains possible: explicit residual limitation");
        } else if(group==L"increment") {
            LocalStateStore store(path);
            store.update([](LocalState& state){
                if(state.device.empty()){state.device=std::string(64,'a');state.highest_utc=1000;state.token="0";}
                state.token=std::to_string(std::stoi(state.token)+1);
            });
            std::cout<<"PASS increment\n";return 0;
        } else if(group==L"read") {
            const auto state=LocalStateStore(path).read();
            if(!state)throw std::runtime_error("No multi-process state");
            std::cout<<state->generation<<" "<<state->token<<'\n';return 0;
        } else throw std::runtime_error("Unknown group");
        std::cout<<"PASS local: "<<checks<<" assertions\n";return 0;
    } catch(const std::exception& error) { std::cerr<<"FAIL after "<<checks<<": "<<error.what()<<'\n';return 1; }
}
