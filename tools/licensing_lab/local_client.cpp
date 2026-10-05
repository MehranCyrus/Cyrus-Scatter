#ifndef CYRUS_SIGNED_LICENSE_LAB_ONLY
#error This development client must never ship or use customer authority
#endif
#include "signed_support.h"
#include "cyrus/licensing/client.h"
#include <nlohmann/json.hpp>
#include <windows.h>
#include <ncrypt.h>
#include <fstream>
#include <iostream>
#include <stdexcept>
#include <future>
#include <thread>
#include <chrono>
#include <algorithm>
#include <vector>

using namespace cyrus::licensing;
namespace {
std::string hex(const std::array<unsigned char,64>& bytes) {
    std::string out;constexpr char digits[]="0123456789abcdef";
    for(auto v:bytes){out+=digits[v>>4];out+=digits[v&15];}return out;
}
std::string read(const std::filesystem::path& path) {
    if(std::filesystem::file_size(path)>8192)throw std::runtime_error("Response/token too large");
    std::ifstream file(path,std::ios::binary);if(!file)throw std::runtime_error("Cannot read response");
    return {(std::istreambuf_iterator<char>(file)),{}};
}
void status(LocalLicenseClient& client) {
    const auto result=client.status();
    std::cout<<nlohmann::json{{"allowed",result.allowed},{"reason",reasonName(result.reason)},{"device",client.device()}}.dump()<<std::endl;
}
}
int wmain(int argc,wchar_t** argv) {
    try {
        if(argc<4)throw std::runtime_error("Expected command, private state directory and private test key name");
        const std::wstring command=argv[1],name=argv[3];
        if(name.rfind(L"CyrusLicensing-PRIVATE-TEST-",0)!=0)throw std::runtime_error("Test namespace required");
        if(command==L"delete-test-key") {
            NCRYPT_PROV_HANDLE provider=0;NCRYPT_KEY_HANDLE key=0;
            if(NCryptOpenStorageProvider(&provider,MS_KEY_STORAGE_PROVIDER,0)!=ERROR_SUCCESS)throw std::runtime_error("Key provider unavailable");
            auto result=NCryptOpenKey(provider,&key,name.c_str(),0,NCRYPT_SILENT_FLAG);
            if(result==ERROR_SUCCESS)result=NCryptDeleteKey(key,0);
            NCryptFreeObject(provider);
            if(result!=ERROR_SUCCESS&&result!=NTE_BAD_KEYSET)throw std::runtime_error("Test key cleanup failed");
            std::cout<<"{\"deleted_test_key\":true}"<<std::endl;return 0;
        }
        auto activationTrust=signedLabTrust();activationTrust.token_type+=".activation";
        LocalLicenseClient client(signedLabTrust(),activationTrust,signedLabHost(),name,std::filesystem::path(argv[2]),command==L"request");
        if(command==L"request") {
            const auto r=client.requestActivation();
            std::cout<<nlohmann::json{{"device",r.device},{"nonce",r.nonce},{"subject",r.subject},{"tenant",r.tenant},
                {"product",r.product},{"public_xy",hex(r.public_key)},{"proof",hex(r.proof)}}.dump()<<std::endl;
        } else if(command==L"activate"||command==L"renew") {
            if(argc!=5)throw std::runtime_error("Expected response file");
            if(command==L"activate")client.activate(read(argv[4]));else client.importRenewal(read(argv[4]));
            status(client);
        } else if(command==L"state-summary") {
            const auto state=LocalStateStore(std::filesystem::path(argv[2])).read();
            if(!state)throw std::runtime_error("Missing protected state");
            std::cout<<nlohmann::json{{"generation",state->generation},{"highest_utc",state->highest_utc}}.dump()<<std::endl;
        } else if(command==L"io-probe") {
            // Real exclusive state-file contention, not a fake store adapter.
            const auto path=std::filesystem::path(argv[2])/L"state.lock";
            HANDLE lock=CreateFileW(path.c_str(),GENERIC_READ|GENERIC_WRITE,0,nullptr,OPEN_EXISTING,FILE_ATTRIBUTE_NORMAL,nullptr);
            if(lock==INVALID_HANDLE_VALUE)throw std::runtime_error("Cannot acquire private probe lock");
            std::promise<void> started;auto ready=started.get_future();std::string workerError;
            auto worker=std::async(std::launch::async,[&]{started.set_value();try{client.checkpoint();}catch(const std::exception& e){workerError=e.what();}});
            ready.wait();Sleep(50);
            const bool overlapping=worker.wait_for(std::chrono::milliseconds(0))==std::future_status::timeout;
            const auto begin=std::chrono::steady_clock::now();int owner=0;unsigned allowed=0;
            for(int i=0;i<1000;++i){allowed+=client.status().allowed;auto permit=client.admit(Operation::AuthorScatter,&owner);allowed+=client.consume(permit,Operation::AuthorScatter,&owner);}
            const double ms=std::chrono::duration<double,std::milli>(std::chrono::steady_clock::now()-begin).count();
            CloseHandle(lock);worker.get();
            std::cout<<nlohmann::json{{"overlapping_io",overlapping},{"decisions_and_commits",allowed},{"elapsed_ms",ms},{"worker_error",workerError}}.dump()<<std::endl;
            if(!overlapping||allowed!=2000||ms>250||!workerError.empty())return 4;
        } else if(command==L"decision-probe") {
            std::vector<double> samples;int owner=0;unsigned allowed=0;
            for(int trial=0;trial<9;++trial){const auto begin=std::chrono::steady_clock::now();
                for(int i=0;i<100000;++i){auto permit=client.admit(Operation::AuthorScatter,&owner);allowed+=client.consume(permit,Operation::AuthorScatter,&owner);}
                samples.push_back(std::chrono::duration<double,std::nano>(std::chrono::steady_clock::now()-begin).count()/100000);}
            std::sort(samples.begin(),samples.end());
            std::cout<<nlohmann::json{{"median_ns",samples[4]},{"min_ns",samples.front()},{"max_ns",samples.back()},
                {"allowed",allowed},{"scope","Real local clock, mutex and grant; no disk/signature in timed loops. Not FPS."}}.dump()<<std::endl;
            if(allowed!=900000)return 4;
        } else if(command==L"status")status(client);
        else if(command==L"watch") {
            status(client);
            std::string line;
            while(std::getline(std::cin,line)&&line!="quit") {
                if(line=="refresh")client.refresh();
                else if(line=="checkpoint")client.checkpoint();
                else if(line!="status")throw std::runtime_error("Unknown watch command");
                status(client);
            }
        } else throw std::runtime_error("Unknown development command");
        return 0;
    } catch(const std::exception& error) {
        std::cerr<<nlohmann::json{{"error",error.what()}}.dump()<<std::endl;return 1;
    }
}
