#include "cyrus/licensing/local_state.h"
#include <windows.h>
#include <ncrypt.h>
#include <bcrypt.h>
#include <vector>
#include <stdexcept>
#include <algorithm>
#include <cstring>

namespace cyrus::licensing {
namespace {
void checked(SECURITY_STATUS status,const char* action) {
    if(status!=ERROR_SUCCESS)throw std::runtime_error(action);
}
std::array<unsigned char,32> hash(std::string_view bytes) {
    BCRYPT_ALG_HANDLE algorithm=nullptr;
    if(BCryptOpenAlgorithmProvider(&algorithm,BCRYPT_SHA256_ALGORITHM,nullptr,0)<0)
        throw std::runtime_error("SHA256 provider unavailable");
    std::array<unsigned char,32> result{};
    const auto status=BCryptHash(algorithm,nullptr,0,
        reinterpret_cast<PUCHAR>(const_cast<char*>(bytes.data())),static_cast<ULONG>(bytes.size()),result.data(),32);
    BCryptCloseAlgorithmProvider(algorithm,0);
    if(status<0)throw std::runtime_error("SHA256 failed");
    return result;
}
}
struct InstallationKey::Impl {
    NCRYPT_PROV_HANDLE provider=0;
    NCRYPT_KEY_HANDLE key=0;
    ~Impl() { if(key)NCryptFreeObject(key);if(provider)NCryptFreeObject(provider); }
};
InstallationKey::InstallationKey(std::wstring name,bool create):impl_(std::make_unique<Impl>()) {
    if(name.empty()||name.size()>200)throw std::invalid_argument("Invalid application key name");
    checked(NCryptOpenStorageProvider(&impl_->provider,MS_KEY_STORAGE_PROVIDER,0),"Key provider unavailable");
    const auto opened=NCryptOpenKey(impl_->provider,&impl_->key,name.c_str(),0,NCRYPT_SILENT_FLAG);
    if(opened==ERROR_SUCCESS)return;
    if(opened!=NTE_BAD_KEYSET||!create)throw std::runtime_error("Installation key missing or inaccessible; recovery required");
    auto created=NCryptCreatePersistedKey(impl_->provider,&impl_->key,NCRYPT_ECDSA_P256_ALGORITHM,name.c_str(),0,0);
    if(created==NTE_EXISTS) {
        checked(NCryptOpenKey(impl_->provider,&impl_->key,name.c_str(),0,NCRYPT_SILENT_FLAG),"Concurrent key creation failed");
        return;
    }
    checked(created,"Installation key creation failed");
    try {
        DWORD exports=0,usage=NCRYPT_ALLOW_SIGNING_FLAG;
        checked(NCryptSetProperty(impl_->key,NCRYPT_EXPORT_POLICY_PROPERTY,reinterpret_cast<PBYTE>(&exports),sizeof(exports),NCRYPT_PERSIST_FLAG),"Cannot disable private-key export");
        checked(NCryptSetProperty(impl_->key,NCRYPT_KEY_USAGE_PROPERTY,reinterpret_cast<PBYTE>(&usage),sizeof(usage),NCRYPT_PERSIST_FLAG),"Cannot restrict key usage");
        checked(NCryptFinalizeKey(impl_->key,NCRYPT_SILENT_FLAG),"Installation key finalization failed");
    } catch(...) {
        // Only this newly created handle is removed. Never delete an existing
        // user's key while attempting to open or validate it.
        if(NCryptDeleteKey(impl_->key,0)==ERROR_SUCCESS)impl_->key=0;
        throw;
    }
}
InstallationKey::~InstallationKey()=default;
std::array<unsigned char,64> InstallationKey::publicKey() const {
    std::array<unsigned char,sizeof(BCRYPT_ECCKEY_BLOB)+64> bytes{};DWORD used=0;
    checked(NCryptExportKey(impl_->key,0,BCRYPT_ECCPUBLIC_BLOB,nullptr,bytes.data(),static_cast<DWORD>(bytes.size()),&used,0),"Public key export failed");
    BCRYPT_ECCKEY_BLOB header{};std::memcpy(&header,bytes.data(),sizeof(header));
    if(used!=bytes.size()||header.dwMagic!=BCRYPT_ECDSA_PUBLIC_P256_MAGIC||header.cbKey!=32)
        throw std::runtime_error("Unexpected installation key type");
    std::array<unsigned char,64> xy{};std::copy(bytes.begin()+sizeof(header),bytes.end(),xy.begin());return xy;
}
std::string InstallationKey::deviceId() const {
    const auto xy=publicKey();
    std::string material="cyrus-installation-p256-v1:";
    material.append(reinterpret_cast<const char*>(xy.data()),xy.size());
    const auto digest=hash(material);std::string result;result.reserve(64);
    constexpr char hex[]="0123456789abcdef";
    for(auto byte:digest){result.push_back(hex[byte>>4]);result.push_back(hex[byte&15]);}return result;
}
std::array<unsigned char,64> InstallationKey::signChallenge(std::string_view challenge) const {
    if(challenge.size()<16||challenge.size()>4096)throw std::invalid_argument("Bounded challenge required");
    const auto digest=hash("cyrus-device-proof-v1:"+std::string(challenge));
    std::array<unsigned char,64> signature{};DWORD used=0;
    checked(NCryptSignHash(impl_->key,nullptr,const_cast<PBYTE>(digest.data()),32,signature.data(),64,&used,NCRYPT_SILENT_FLAG),"Device proof failed");
    if(used!=64)throw std::runtime_error("Unexpected device signature");return signature;
}
bool InstallationKey::privateExportDenied() const {
    DWORD size=0;
    return NCryptExportKey(impl_->key,0,BCRYPT_ECCPRIVATE_BLOB,nullptr,nullptr,0,&size,0)!=ERROR_SUCCESS;
}
}
