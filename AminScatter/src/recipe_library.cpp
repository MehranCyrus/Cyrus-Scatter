#include "recipe_library.h"
#include <map>
#include "recipe_store.h"
#include <algorithm>
#include <fstream>
#include <set>
#include <stdexcept>
#ifdef _WIN32
#ifndef NOMINMAX
#define NOMINMAX
#endif
#include <windows.h>
#endif

namespace cyrus::recipes {
namespace {
void require(bool ok,const char* message){if(!ok)throw std::invalid_argument(message);}
std::string utf8(const std::filesystem::path& path){const auto s=path.u8string();return {s.begin(),s.end()};}
std::string load(const std::filesystem::path& path,std::size_t limit){
    std::ifstream in(path,std::ios::binary|std::ios::ate);require(bool(in),"Cannot read library file.");
    const auto n=in.tellg();require(n>=0&&static_cast<std::uint64_t>(n)<=limit,"Library file exceeds its byte limit.");
    std::string out(static_cast<std::size_t>(n),'\0');in.seekg(0);if(n>0)in.read(out.data(),n);
    require(bool(in),"Library file read failed.");return out;
}
void write(const std::filesystem::path& path,const std::string& bytes){
    std::ofstream out(path,std::ios::binary|std::ios::trunc);require(bool(out),"Cannot create library file.");
    out.write(bytes.data(),bytes.size());out.flush();require(bool(out),"Library write failed.");out.close();require(!out.fail(),"Library close failed.");
    require(load(path,bytes.size())==bytes,"Library readback mismatch.");
}
std::filesystem::path metadataPath(const std::filesystem::path& recipe){return std::filesystem::path(recipe.wstring()+L".library.json");}
void text(const Json& value,std::size_t maximum){require(value.is_string(),"Library metadata requires text.");const auto& s=value.get_ref<const std::string&>();require(s.size()<=maximum&&s.find('\0')==std::string::npos,"Library text exceeds bounds or contains NUL.");}
void metadata(const Json& value){
    require(value.is_object()&&value.size()==3&&value.contains("category")&&value.contains("tags")&&value.contains("description"),"Invalid library metadata fields.");
    text(value["category"],96);text(value["description"],1024);
    const auto& tags=value["tags"];require(tags.is_array()&&tags.size()<=16,"At most 16 library tags are supported.");
    std::set<std::string> unique;for(const auto& tag:tags){text(tag,64);require(!tag.get_ref<const std::string&>().empty()&&unique.insert(tag.get<std::string>()).second,"Tags must be nonempty and distinct.");}
}
std::string fold(const std::string& input){
#ifdef _WIN32
    if(input.empty())return {};
    const int n=MultiByteToWideChar(CP_UTF8,MB_ERR_INVALID_CHARS,input.data(),static_cast<int>(input.size()),nullptr,0);
    require(n>0,"Invalid Unicode search text.");std::wstring wide(n,L'\0');MultiByteToWideChar(CP_UTF8,MB_ERR_INVALID_CHARS,input.data(),static_cast<int>(input.size()),wide.data(),n);
    const int m=LCMapStringEx(LOCALE_NAME_INVARIANT,LCMAP_LOWERCASE,wide.data(),n,nullptr,0,nullptr,nullptr,0);
    require(m>0,"Cannot normalize library search.");std::wstring lower(m,L'\0');LCMapStringEx(LOCALE_NAME_INVARIANT,LCMAP_LOWERCASE,wide.data(),n,lower.data(),m,nullptr,nullptr,0);
    const int bytes=WideCharToMultiByte(CP_UTF8,0,lower.data(),m,nullptr,0,nullptr,nullptr);std::string out(bytes,'\0');WideCharToMultiByte(CP_UTF8,0,lower.data(),m,out.data(),bytes,nullptr,nullptr);return out;
#else
    auto out=input;for(auto& c:out)if(c>='A'&&c<='Z')c+=32;return out;
#endif
}
Json presentation(const std::filesystem::path& recipe,const std::string& hash){
    const auto path=metadataPath(recipe);if(!std::filesystem::exists(path))return nullptr;
    const auto record=parse(load(path,8192));
    require(record.is_object()&&record.size()==5&&record.value("format","")=="cyrus.recipe-library"&&record.value("version",0)==1&&record.contains("recipeSHA256")&&record.contains("metadata")&&record.contains("thumbnail"),"Unsupported library sidecar.");
    require(record["recipeSHA256"]==hash,"Recipe changed; library metadata is stale. Re-save a copy with its metadata.");
    metadata(record["metadata"]);
    const auto& t=record["thumbnail"];
    if(!t.is_null()){
        require(t.is_object()&&t.size()==3&&t.contains("file")&&t.contains("sha256")&&t.contains("bytes"),"Invalid thumbnail record.");
        text(t["file"],240);text(t["sha256"],64);const auto name=t["file"].get<std::string>();
        require(name.starts_with("thumbnail-")&&name.ends_with(".png")&&name.find_first_of("/\\:")==std::string::npos&&name.find("..") == std::string::npos,"Thumbnail must be a local package filename.");
        require(t["bytes"].is_number_unsigned()||t["bytes"].is_number_integer(),"Invalid thumbnail size.");
        require(t["bytes"].get<std::int64_t>()>0&&t["bytes"].get<std::int64_t>()<=maxThumbnailBytes&&t["sha256"].get<std::string>().size()==64,"Thumbnail bounds exceeded.");
    }
    return record;
}
}

void validateThumbnail(const std::vector<unsigned char>& bytes){
    static constexpr unsigned char signature[]={137,80,78,71,13,10,26,10};
    require(bytes.size()>=33&&bytes.size()<=maxThumbnailBytes&&std::equal(std::begin(signature),std::end(signature),bytes.begin()),"Thumbnail must be a PNG no larger than 2 MiB.");
    auto number=[&](std::size_t offset){std::uint32_t n=0;for(int i=0;i<4;++i)n=(n<<8)|bytes[offset+i];return n;};
    require(number(8)==13&&std::string(bytes.begin()+12,bytes.begin()+16)=="IHDR","Invalid PNG image header.");
    require(number(16)>0&&number(20)>0&&number(16)<=1024&&number(20)<=1024,"Thumbnail dimensions must be 1..1024 pixels.");
}
void writePresentation(const std::filesystem::path& recipe,const Json& info,const std::filesystem::path& image){
    metadata(info);require(recipe.is_absolute(),"Library save needs an absolute recipe path.");
    std::string hash;const auto document=read(recipe,false,&hash);
    const auto path=metadataPath(recipe),temp=std::filesystem::path(path.wstring()+L".tmp");
    require(!std::filesystem::exists(path)&&!std::filesystem::exists(temp),"Library metadata already exists; save a new recipe copy.");
    Json record={{"format","cyrus.recipe-library"},{"version",1},{"recipeSHA256",hash},{"metadata",info},{"thumbnail",nullptr}};
    std::filesystem::path imageTarget,imageTemp;bool imageWritten=false,tempOwned=false;
    try{
        if(!image.empty()){
            const auto data=load(image,maxThumbnailBytes);const std::vector<unsigned char> bytes(data.begin(),data.end());validateThumbnail(bytes);
            // Recipe IDs allow ':'; filenames instead use the content hash.
            const auto name="thumbnail-"+hash+".png";imageTarget=recipe.parent_path()/name;imageTemp=std::filesystem::path(imageTarget.wstring()+L".tmp");
            require(!std::filesystem::exists(imageTarget)&&!std::filesystem::exists(imageTemp),"Thumbnail destination exists.");
            tempOwned=true;write(imageTemp,data);std::filesystem::rename(imageTemp,imageTarget);imageWritten=true;tempOwned=false;
            record["thumbnail"]={{"file",name},{"sha256",digest(bytes)},{"bytes",bytes.size()}};
        }
        write(temp,record.dump(2));std::filesystem::rename(temp,path);
    }catch(...){std::error_code ec;std::filesystem::remove(temp,ec);if(tempOwned)std::filesystem::remove(imageTemp,ec);if(imageWritten)std::filesystem::remove(imageTarget,ec);throw;}
}
Json summary(const std::filesystem::path& recipe){
    std::string hash;const auto d=read(recipe,false,&hash);std::size_t paints=0;Json layers=Json::array(),roles=Json::array();
    for(const auto& l:d["layers"]){layers.push_back(l["name"]);if(!l["paint"].is_null())++paints;for(const auto& a:l["areas"])if(!a["paint"].is_null())++paints;}
    for(const auto& r:d["roles"]){if(roles.size()==8)break;roles.push_back(r["name"]);}
    Json info={{"category",""},{"tags",Json::array()},{"description",""}},image=Json::array();bool hasImage=false;std::string warning;
    try{const auto p=d["presentation"].is_null()?presentation(recipe,hash):d["presentation"];if(!p.is_null()){
        info=p["metadata"];hasImage=!p["thumbnail"].is_null();
        if(hasImage){
            const auto& t=p["thumbnail"];const auto file=attachmentPath(recipe,t["file"].get<std::string>());
            image=Json::array({utf8(file),t["sha256"],t["bytes"]});
        }
    }}
    catch(const std::exception& e){warning=e.what();}
    return Json::array({d["name"],d["layers"].size(),paints,d["id"],info["category"],info["tags"],info["description"],d["roles"].size(),layers,roles,hash,hasImage,warning,image,d["revision"]});
}
std::filesystem::path thumbnail(const std::filesystem::path& recipe){
    std::string hash;const auto d=read(recipe,false,&hash);const auto p=d["presentation"].is_null()?presentation(recipe,hash):d["presentation"];if(p.is_null()||p["thumbnail"].is_null())return {};
    const auto& t=p["thumbnail"];const auto file=attachmentPath(recipe,t["file"].get<std::string>());
    const auto raw=load(file,maxThumbnailBytes);const std::vector<unsigned char> bytes(raw.begin(),raw.end());validateThumbnail(bytes);
    require(bytes.size()==t["bytes"].get<std::size_t>()&&digest(bytes)==t["sha256"].get<std::string>(),"Thumbnail integrity mismatch.");return file;
}

Library::~Library(){stop_=true;if(worker_.joinable()){
#ifdef _WIN32
    CancelSynchronousIo(worker_.native_handle());
#endif
    worker_.join();}}
std::uint64_t Library::start(std::vector<std::filesystem::path> roots){
    require(done_.load(),"The previous library scan is still stopping. Try Refresh after it finishes.");
    require(!roots.empty()&&roots.size()<=4,"Choose one to four library folders.");
    for(const auto& root:roots)require(root.is_absolute(),"Library folders must be absolute paths.");
    if(worker_.joinable())worker_.join();
    {std::lock_guard lock(mutex_);entries_.clear();collections_.clear();collectionsDirty_=true;roots_=roots;scanned_=invalid_=metadataBytes_=0;limited_=false;error_.clear();++generation_;}
    stop_=false;done_=false;try{worker_=std::thread(&Library::scan,this,std::move(roots));}catch(...){done_=true;throw;}return generation_;
}
void Library::cancel(std::uint64_t token){require(token==generation_,"Stale library scan.");stop_=true;
#ifdef _WIN32
    if(worker_.joinable()&&!done_)CancelSynchronousIo(worker_.native_handle());
#endif
}
void Library::scan(std::vector<std::filesystem::path> roots) noexcept {
    try{
        std::size_t visited=0,bytes=0;std::set<std::filesystem::path> seen;
        for(const auto& root:roots){
            if(stop_)break;
            for(const auto& item:std::filesystem::directory_iterator(root)){
                if(stop_)break;
                if(++visited>limits_.directoryEntries){std::lock_guard lock(mutex_);limited_=true;break;}
                if(!item.is_regular_file()||!fold(utf8(item.path().filename())).ends_with(".csrecipe.json"))continue;
                const auto path=std::filesystem::weakly_canonical(item.path());if(!seen.insert(path).second)continue;
                {std::lock_guard lock(mutex_);if(scanned_>=limits_.entries){limited_=true;break;}++scanned_;}
                try{
                    auto info=summary(path);auto search=info[0].get<std::string>()+" "+info[4].get<std::string>()+" "+info[6].get<std::string>();for(const auto& tag:info[5])search+=" "+tag.get<std::string>();for(const auto& name:info[8])search+=" "+name.get<std::string>();
                    Entry entry{utf8(path),fold(search),info[4].get<std::string>(),std::move(info)};
                    const auto size=entry.path.size()+entry.search.size()+entry.category.size()+entry.info.dump().size()+256;entry.bytes=size;
                    std::lock_guard lock(mutex_);if(bytes+size>limits_.metadataBytes){limited_=true;break;}bytes+=size;metadataBytes_=bytes;entries_.push_back(std::move(entry));collectionsDirty_=true;
                }catch(const std::exception&){std::lock_guard lock(mutex_);++invalid_;}
            }
            if(visited>limits_.directoryEntries)break;
        }
        std::lock_guard lock(mutex_);std::sort(entries_.begin(),entries_.end(),[](const Entry& a,const Entry& b){return a.search==b.search?a.path<b.path:a.search<b.search;});collectionsDirty_=true;
    }catch(const std::exception& e){std::lock_guard lock(mutex_);error_=e.what();}catch(...){std::lock_guard lock(mutex_);error_="Library scan failed.";}
    done_=true;
}
void Library::update(std::uint64_t token,const std::filesystem::path& recipe){
    require(done_.load()&&token==generation_,"Finish the current catalog scan before updating one entry.");
    require(recipe.is_absolute(),"Entry refresh requires an absolute path.");
    const auto path=std::filesystem::weakly_canonical(recipe);bool included=false;
    for(const auto& root:roots_)if(std::filesystem::weakly_canonical(root)==path.parent_path())included=true;
    require(included,"Updated recipe belongs to another library.");
    auto info=summary(path);auto search=info[0].get<std::string>()+" "+info[4].get<std::string>()+" "+info[6].get<std::string>();
    for(const auto& tag:info[5])search+=" "+tag.get<std::string>();for(const auto& name:info[8])search+=" "+name.get<std::string>();
    Entry entry{utf8(path),fold(search),info[4].get<std::string>(),std::move(info)};entry.bytes=entry.path.size()+entry.search.size()+entry.category.size()+entry.info.dump().size()+256;
    std::lock_guard lock(mutex_);auto found=std::find_if(entries_.begin(),entries_.end(),[&](const Entry& e){return e.path==entry.path;});
    const auto previous=found==entries_.end()?0:found->bytes;
    require((found!=entries_.end()||entries_.size()<limits_.entries)&&metadataBytes_-previous+entry.bytes<=limits_.metadataBytes,"Catalog limit reached. Choose a smaller library folder.");
    metadataBytes_=metadataBytes_-previous+entry.bytes;
    if(found==entries_.end()){entries_.push_back(std::move(entry));++scanned_;}else *found=std::move(entry);
    std::sort(entries_.begin(),entries_.end(),[](const Entry& a,const Entry& b){return a.search==b.search?a.path<b.path:a.search<b.search;});
    collectionsDirty_=true;
}
Json Library::page(std::uint64_t token,const std::string& search,const std::string& category,std::size_t number) const {
    require(search.size()<=1024&&category.size()<=96&&number>=1&&number<=10000,"Invalid library page request.");const auto query=fold(search);
    std::lock_guard lock(mutex_);require(token==generation_,"Stale library scan.");
    if(collectionsDirty_){
        std::map<std::string,Collection> grouped;
        for(std::size_t i=0;i<entries_.size();++i){
            const auto& entry=entries_[i];if(entry.category.empty())continue;
            auto [it,added]=grouped.try_emplace(entry.category,Collection{entry.category,0,i});
            ++it->second.count;
            if(entries_[it->second.representative].info[13].empty()&&!entry.info[13].empty())it->second.representative=i;
        }
        std::vector<Collection> next;next.reserve(grouped.size());for(auto& item:grouped)next.push_back(std::move(item.second));
        collections_=std::move(next);collectionsDirty_=false;
    }
    Json rows=Json::array(),categories=Json::array();std::size_t matched=0;
    for(const auto& entry:entries_){
        if(!category.empty()&&entry.category!=category)continue;
        if(!query.empty()&&entry.search.find(query)==std::string::npos)continue;
        if(matched>=(number-1)*128&&rows.size()<128)rows.push_back(Json::array({entry.path,entry.info}));++matched;
    }
    Json collectionRows=Json::array();std::size_t index=0;
    for(const auto& item:collections_){
        categories.push_back(item.name);
        if(index++>=(number-1)*128&&collectionRows.size()<128)collectionRows.push_back(Json::array({item.name,item.count,entries_[item.representative].info[13]}));
    }
    return Json::array({done_.load()?(stop_.load()?"cancelled":"complete"):"scanning",scanned_,entries_.size(),invalid_,limited_,error_,matched,std::max<std::size_t>(1,(matched+127)/128),categories,rows,collectionRows,std::max<std::size_t>(1,(collections_.size()+127)/128),collections_.size()});
}
}
