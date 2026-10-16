#include "recipe_store.h"
#include "recipe_library.h"
#include <algorithm>
#include <fstream>
#include <set>
#include <stdexcept>
#ifdef _WIN32
#ifndef NOMINMAX
#define NOMINMAX
#endif
#include <windows.h>
#include <bcrypt.h>
#endif

namespace cyrus::recipes {
namespace {
void require(bool ok,const char* message){if(!ok)throw std::invalid_argument(message);}
void keys(const Json& value,std::initializer_list<const char*> names){require(value.is_object()&&value.size()==names.size(),"Unexpected entry fields.");for(const auto* name:names)require(value.contains(name),"Incomplete entry record.");}
void text(const Json& value,std::size_t limit){require(value.is_string(),"Entry requires text.");const auto& s=value.get_ref<const std::string&>();require(s.size()<=limit&&s.find('\0')==std::string::npos,"Entry text exceeds bounds or contains NUL.");}
void hash(const Json& value){text(value,64);const auto& s=value.get_ref<const std::string&>();require(s.size()==64&&std::all_of(s.begin(),s.end(),[](char c){return (c>='0'&&c<='9')||(c>='a'&&c<='f');}),"Invalid entry SHA-256.");}
void metadata(const Json& m){
    keys(m,{"category","tags","description"});text(m["category"],96);text(m["description"],1024);
    require(m["tags"].is_array()&&m["tags"].size()<=16,"At most sixteen entry tags.");std::set<std::string> seen;
    for(const auto& tag:m["tags"]){text(tag,64);require(!tag.get_ref<const std::string&>().empty()&&seen.insert(tag.get<std::string>()).second,"Tags must be distinct and nonempty.");}
}
void captureRecord(const Json& capture){
    if(capture.is_null())return;
    keys(capture,{"method","authoredSHA256","publicationSHA256","view","capturedUTC"});
    require(capture["method"]=="viewport-published","Unsupported capture provenance.");hash(capture["authoredSHA256"]);hash(capture["publicationSHA256"]);
    text(capture["view"],1024);text(capture["capturedUTC"],64);require(!capture["capturedUTC"].get_ref<const std::string&>().empty(),"Capture time is required.");
}
std::string load(const std::filesystem::path& path,std::size_t maximum){
    std::ifstream input(path,std::ios::binary|std::ios::ate);require(bool(input),"Cannot read entry file.");const auto n=input.tellg();
    require(n>=0&&static_cast<std::uint64_t>(n)<=maximum,"Entry file exceeds its byte limit.");std::string bytes(static_cast<std::size_t>(n),'\0');input.seekg(0);if(n>0)input.read(bytes.data(),n);require(bool(input),"Cannot finish entry read.");return bytes;
}
std::string sha(const std::string& bytes){return digest(std::vector<unsigned char>(bytes.begin(),bytes.end()));}
void put(const std::filesystem::path& path,const std::string& bytes){
    require(!std::filesystem::exists(path),"Entry staging file already exists.");std::ofstream out(path,std::ios::binary);require(bool(out),"Cannot create entry staging file.");out.write(bytes.data(),bytes.size());out.flush();require(bool(out),"Entry staging write failed.");out.close();require(!out.fail()&&load(path,bytes.size())==bytes,"Entry staging readback failed.");
}
template<class F>void paints(Json& document,F f){for(auto& layer:document["layers"]){if(!layer["paint"].is_null())f(layer["paint"]);for(auto& area:layer["areas"])if(!area["paint"].is_null())f(area["paint"]);}}
std::string nonce(){
#ifdef _WIN32
    std::vector<unsigned char> bytes(16);require(BCryptGenRandom(nullptr,bytes.data(),static_cast<ULONG>(bytes.size()),BCRYPT_USE_SYSTEM_PREFERRED_RNG)>=0,"Cannot create entry transaction identity.");return hex(bytes);
#else
    throw std::runtime_error("Revisioned entries require the qualified Windows filesystem adapter.");
#endif
}
#ifdef _WIN32
std::wstring winPath(const std::filesystem::path& path){
    auto value=std::filesystem::absolute(path).lexically_normal().wstring();
    if(value.starts_with(L"\\\\?\\"))return value;
    if(value.starts_with(L"\\\\"))return L"\\\\?\\UNC\\"+value.substr(2);
    return L"\\\\?\\"+value;
}
struct Lock {
    HANDLE value=INVALID_HANDLE_VALUE;
    explicit Lock(const std::filesystem::path& path){value=CreateFileW(winPath(path).c_str(),GENERIC_READ|GENERIC_WRITE,0,nullptr,OPEN_ALWAYS,FILE_ATTRIBUTE_HIDDEN|FILE_FLAG_DELETE_ON_CLOSE,nullptr);require(value!=INVALID_HANDLE_VALUE,"Another writer holds this recipe, or the directory is read-only.");}
    ~Lock(){if(value!=INVALID_HANDLE_VALUE)CloseHandle(value);}
    Lock(const Lock&)=delete;Lock& operator=(const Lock&)=delete;
};
void localFilesystem(const std::filesystem::path& path){
    wchar_t volume[MAX_PATH]{},format[64]{};require(GetVolumePathNameW(path.c_str(),volume,MAX_PATH)!=FALSE,"Cannot determine entry filesystem.");
    const auto type=GetDriveTypeW(volume);require(type==DRIVE_FIXED||type==DRIVE_REMOVABLE,"Revisioned updates require a local NTFS folder; copy the library locally first.");
    require(GetVolumeInformationW(volume,nullptr,0,nullptr,nullptr,nullptr,format,64)!=FALSE&&std::wstring(format)==L"NTFS","Revisioned updates currently require local NTFS.");
}
#endif
}

void validateEntryPresentation(const Json& presentation){
    if(presentation.is_null())return;
    keys(presentation,{"metadata","thumbnail","capture"});metadata(presentation["metadata"]);captureRecord(presentation["capture"]);
    const auto& t=presentation["thumbnail"];
    if(t.is_null()){require(presentation["capture"].is_null(),"Capture provenance requires an image.");return;}
    keys(t,{"file","sha256","bytes"});text(t["file"],240);hash(t["sha256"]);const auto relative=t["file"].get<std::string>();
    require(!relative.empty()&&relative.find('\\')==std::string::npos&&relative.find(':')==std::string::npos&&relative.front()!='/'&&relative.find("..") ==std::string::npos,"Thumbnail path must stay in the recipe package.");
    require(t["bytes"].is_number_integer()&&t["bytes"].get<std::int64_t>()>=33&&t["bytes"].get<std::int64_t>()<=maxThumbnailBytes,"Thumbnail size exceeds bounds.");
}
std::string contentFingerprint(const Json& hydrated){
    validate(hydrated,true);auto data=currentDocument(hydrated);for(const auto* key:{"id","name","revision","presentation"})data.erase(key);return sha(data.dump());
}
std::string writeEntry(const std::filesystem::path& input,const Json& document,const Json& info,const std::filesystem::path& image,
    const Json& capture,const std::string& expectedHash,bool metadataOnly,const std::function<void(const char*)>& checkpoint){
    metadata(info);captureRecord(capture);require(input.is_absolute(),"Entry save requires an absolute path.");
    require(!input.filename().empty(),"Entry filename is empty.");
    std::filesystem::create_directories(input.parent_path());
    const auto parent=std::filesystem::canonical(input.parent_path()),path=parent/input.filename();
#ifdef _WIN32
    localFilesystem(parent);Lock lock(std::filesystem::path(path.wstring()+L".cyrus-lock"));
#else
    throw std::runtime_error("Revisioned entries require the qualified Windows filesystem adapter.");
#endif
    require(!std::filesystem::is_symlink(path),"Cannot replace a linked recipe file.");
    const bool update=!expectedHash.empty();Json previous;
    if(update){hash(expectedHash);std::string actual;previous=read(path,false,&actual);require(actual==expectedHash,"Recipe changed since review. Refresh and review the new revision.");}
    else require(!std::filesystem::exists(path),"Recipe destination exists. Use Update Existing or Save Copy.");
    require(!metadataOnly||update,"Metadata maintenance requires an existing reviewed recipe.");
    if(metadataOnly)keys(document,{"name"});else validate(document,true);
    Json output=metadataOnly?previous:currentDocument(document);
    if(metadataOnly)output["name"]=document["name"];
    if(update){output["id"]=previous["id"];require(previous["revision"].get<std::int64_t>()<2147483647,"Recipe revision limit reached; save a copy.");output["revision"]=previous["revision"].get<std::int64_t>()+1;}
    else output["revision"]=1;
    if(!capture.is_null()&&!metadataOnly)require(capture["authoredSHA256"]==contentFingerprint(output),"Settings changed after thumbnail capture. Capture again or clear the image.");
    const auto token=nonce(),folderName="recipe-data-"+token;
    const auto staged=parent/pathFromUTF8(".cyrus-entry-stage-"+token),finalFolder=parent/pathFromUTF8(folderName);
    const auto temporary=finalFolder/"manifest.tmp";
    bool stagedOwned=false,folderOwned=false,published=false;
    auto point=[&](const char* name){if(checkpoint)checkpoint(name);};
    try{
        require(std::filesystem::create_directory(staged),"Cannot create owned entry staging folder.");stagedOwned=true;
        std::size_t index=0;
        if(!metadataOnly)paints(output,[&](Json& paint){
            const auto bytes=unhex(paint["payload"].get<std::string>());const auto name="paint-"+std::to_string(++index)+".cspaint";
            put(staged/name,std::string(bytes.begin(),bytes.end()));paint["payload"]={{"file",folderName+"/"+name},{"sha256",digest(bytes)},{"bytes",bytes.size()}};
        });
        point("paint-staged");
        Json presentation={{"metadata",info},{"thumbnail",nullptr},{"capture",capture}};
        if(!image.empty()){
            const auto bytes=load(image,maxThumbnailBytes);validateThumbnail(std::vector<unsigned char>(bytes.begin(),bytes.end()));
            put(staged/"thumbnail.png",bytes);presentation["thumbnail"]={{"file",folderName+"/thumbnail.png"},{"sha256",sha(bytes)},{"bytes",bytes.size()}};
        }
        output["presentation"]=presentation;validate(output,false);point("thumbnail-staged");
        const auto manifest=serialize(output);put(staged/"manifest.tmp",manifest);require(parse(load(staged/"manifest.tmp",maxManifestBytes))==output,"Entry manifest verification failed.");
        std::filesystem::rename(staged,finalFolder);stagedOwned=false;folderOwned=true;point("payload-published");
        if(update)require(sha(load(path,maxManifestBytes))==expectedHash,"Recipe changed while saving. Previous complete entry retained.");
        else require(!std::filesystem::exists(path),"Recipe appeared while saving. Previous entry retained.");
        point("before-commit");
#ifdef _WIN32
        if(update){
            // Keep recovery names bounded independently of the artist's filename.
            // The digest covers the recipe identity as well as its complete content.
            const auto backup=parent/pathFromUTF8(".cyrus-previous-"+expectedHash+".json");
            require(!std::filesystem::exists(backup),"Previous-revision backup already exists. Review recovery files first.");
            if(!ReplaceFileW(winPath(path).c_str(),winPath(temporary).c_str(),winPath(backup).c_str(),0,nullptr,nullptr)){
                const auto error=GetLastError();
                // Windows documents one partial-failure case with the old file at its backup name.
                if(error==ERROR_UNABLE_TO_MOVE_REPLACEMENT_2&&!std::filesystem::exists(path)&&std::filesystem::exists(backup)&&sha(load(backup,maxManifestBytes))==expectedHash){
                    require(MoveFileExW(winPath(backup).c_str(),winPath(path).c_str(),MOVEFILE_WRITE_THROUGH)!=FALSE,"Recipe replacement failed. Previous complete revision is retained in its .cyrus-previous-<hash>.json recovery file.");
                }
                throw std::runtime_error("Atomic recipe replacement failed (Windows "+std::to_string(error)+"); previous revision and payloads retained.");
            }
        }else require(MoveFileExW(winPath(temporary).c_str(),winPath(path).c_str(),MOVEFILE_WRITE_THROUGH)!=FALSE,"Atomic new recipe publication failed.");
#endif
        published=true;
        // Publication is final. Optional cleanup/telemetry cannot turn success into an apparent failed save.
        try{point("after-commit");}catch(...){}
        return sha(manifest);
    }catch(...){
        if(!published){std::error_code ec;if(stagedOwned)std::filesystem::remove_all(staged,ec);if(folderOwned)std::filesystem::remove_all(finalFolder,ec);}
        throw;
    }
}
}
