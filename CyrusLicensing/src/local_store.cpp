#include "cyrus/licensing/local_state.h"
#include <windows.h>
#include <dpapi.h>
#include <bcrypt.h>
#include <nlohmann/json.hpp>
#include <fstream>
#include <vector>
#include <stdexcept>
#include <limits>
#include <set>

namespace cyrus::licensing {
namespace {
struct File {
    HANDLE value=INVALID_HANDLE_VALUE;
    explicit File(HANDLE h):value(h) {}
    ~File(){if(value!=INVALID_HANDLE_VALUE)CloseHandle(value);}
    File(const File&)=delete;
};
struct Blob { DATA_BLOB value{};~Blob(){if(value.pbData){SecureZeroMemory(value.pbData,value.cbData);LocalFree(value.pbData);}} };
class Lock {
    HANDLE value_=INVALID_HANDLE_VALUE;
public:
    explicit Lock(const std::filesystem::path& path) {
        for(int i=0;i<200;++i) {
            value_=CreateFileW(path.c_str(),GENERIC_READ|GENERIC_WRITE,0,nullptr,OPEN_ALWAYS,FILE_ATTRIBUTE_NORMAL,nullptr);
            if(value_!=INVALID_HANDLE_VALUE)return;
            if(GetLastError()!=ERROR_SHARING_VIOLATION)throw std::runtime_error("Cannot lock licensing state");
            Sleep(10);
        }
        throw std::runtime_error("Licensing state busy; retry outside host callback");
    }
    ~Lock(){CloseHandle(value_);}
};
std::optional<LocalState> readUnlocked(const std::filesystem::path& path) {
    std::error_code error;
    const bool exists=std::filesystem::exists(path,error);
    if(error)throw std::runtime_error("Cannot inspect licensing state");
    if(!exists)return {};
    const auto size=std::filesystem::file_size(path);
    if(size==0||size>65536)throw std::runtime_error("Invalid protected state size; recovery required");
    std::vector<unsigned char> bytes(static_cast<std::size_t>(size));
    std::ifstream input(path,std::ios::binary);
    if(!input.read(reinterpret_cast<char*>(bytes.data()),static_cast<std::streamsize>(size)))throw std::runtime_error("Cannot read licensing state");
    DATA_BLOB cipher{static_cast<DWORD>(bytes.size()),bytes.data()};Blob plain;
    if(!CryptUnprotectData(&cipher,nullptr,nullptr,nullptr,nullptr,CRYPTPROTECT_UI_FORBIDDEN,&plain.value)||plain.value.cbData>16384)
        throw std::runtime_error("Protected licensing state unreadable; recovery required");
    std::set<std::string> fields;
    const auto callback=[&](int depth,nlohmann::json::parse_event_t event,nlohmann::json& value) {
        if(depth>1)throw std::runtime_error("Unexpected nested local state");
        if(event==nlohmann::json::parse_event_t::key&&!fields.insert(value.get<std::string>()).second)
            throw std::runtime_error("Duplicate local state field");
        return true;
    };
    const auto json=nlohmann::json::parse(plain.value.pbData,plain.value.pbData+plain.value.cbData,callback);
    const bool version=json.is_object()&&json.contains("v")&&json["v"].is_number_integer();
    const bool legacy=version&&json["v"]==1&&json.size()==5;
    const bool current=version&&json["v"]==2&&json.size()==6;
    if((!legacy&&!current)||!json.contains("generation")||!json.contains("highest_utc")||
       !json.contains("device")||!json.contains("token")||!json["generation"].is_number_unsigned()||
       !json["highest_utc"].is_number_integer()||!json["device"].is_string()||!json["token"].is_string()||(current&&(!json.contains("pending_nonce")||!json["pending_nonce"].is_string())))
        throw std::runtime_error("Protected state schema mismatch; recovery required");
    LocalState state{json["generation"].get<std::uint64_t>(),json["highest_utc"].get<std::int64_t>(),json["device"].get<std::string>(),json["token"].get<std::string>(),legacy?std::string{}:json["pending_nonce"].get<std::string>()};
    if(state.device.size()!=64||state.device.find_first_not_of("0123456789abcdef")!=std::string::npos||state.token.size()>8192||state.highest_utc<0||state.highest_utc>253402300799LL||
        (!state.pending_nonce.empty()&&(state.pending_nonce.size()!=64||state.pending_nonce.find_first_not_of("0123456789abcdef")!=std::string::npos)))
        throw std::runtime_error("Protected state bounds invalid; recovery required");
    return state;
}
void writeUnlocked(const std::filesystem::path& path,const LocalState& state) {
    if(state.device.size()!=64||state.device.find_first_not_of("0123456789abcdef")!=std::string::npos||state.token.size()>8192||
       state.highest_utc<0||state.highest_utc>253402300799LL||
       (!state.pending_nonce.empty()&&(state.pending_nonce.size()!=64||state.pending_nonce.find_first_not_of("0123456789abcdef")!=std::string::npos)))throw std::invalid_argument("Invalid local license state");
    auto bytes=nlohmann::json{{"v",2},{"generation",state.generation},{"highest_utc",state.highest_utc},{"device",state.device},{"token",state.token},{"pending_nonce",state.pending_nonce}}.dump();
    DATA_BLOB plain{static_cast<DWORD>(bytes.size()),reinterpret_cast<PBYTE>(bytes.data())};Blob cipher;
    if(!CryptProtectData(&plain,L"Cyrus licensing state v1",nullptr,nullptr,nullptr,CRYPTPROTECT_UI_FORBIDDEN,&cipher.value))
        throw std::runtime_error("Cannot protect licensing state");
    SecureZeroMemory(bytes.data(),bytes.size());
    std::array<unsigned char,16> nonce{};
    if(BCryptGenRandom(nullptr,nonce.data(),16,BCRYPT_USE_SYSTEM_PREFERRED_RNG)<0)throw std::runtime_error("Cannot allocate atomic state filename");
    std::wstring suffix;constexpr wchar_t hex[]=L"0123456789abcdef";
    for(auto v:nonce){suffix+=hex[v>>4];suffix+=hex[v&15];}
    auto temporary=path;temporary+=L"."+suffix+L".tmp";
    try {
        {
            File file(CreateFileW(temporary.c_str(),GENERIC_WRITE,0,nullptr,CREATE_NEW,FILE_ATTRIBUTE_NORMAL,nullptr));
            if(file.value==INVALID_HANDLE_VALUE)throw std::runtime_error("Cannot create protected state transaction");
            DWORD written=0;
            if(!WriteFile(file.value,cipher.value.pbData,cipher.value.cbData,&written,nullptr)||written!=cipher.value.cbData||!FlushFileBuffers(file.value))
                throw std::runtime_error("Cannot flush protected state transaction");
        }
        if(!MoveFileExW(temporary.c_str(),path.c_str(),MOVEFILE_REPLACE_EXISTING|MOVEFILE_WRITE_THROUGH))throw std::runtime_error("Cannot publish protected state transaction");
    } catch(...) { DeleteFileW(temporary.c_str());throw; }
}
}
LocalStateStore::LocalStateStore(std::filesystem::path directory):directory_(std::move(directory)) {
    if(!directory_.is_absolute())throw std::invalid_argument("Local state path must be application-owned and absolute");
    std::filesystem::create_directories(directory_);
}
std::optional<LocalState> LocalStateStore::read() const {
    Lock lock(directory_/L"state.lock");return readUnlocked(directory_/L"state.dpapi");
}
LocalState LocalStateStore::update(const std::function<void(LocalState&)>& change) const {
    Lock lock(directory_/L"state.lock");
    auto before=readUnlocked(directory_/L"state.dpapi");
    auto next=before.value_or(LocalState{});change(next);
    if(before&&(next.device!=before->device||next.highest_utc<before->highest_utc))throw std::runtime_error("Device change or time rollback requires explicit recovery");
    if(next.generation!= (before?before->generation:0)||next.generation==std::numeric_limits<std::uint64_t>::max())throw std::runtime_error("Invalid state generation");
    ++next.generation;writeUnlocked(directory_/L"state.dpapi",next);return next;
}
}
