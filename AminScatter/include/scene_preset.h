#pragma once
#include "recipes.h"
#include "recipe_store.h"
#include <algorithm>
#include <map>
#include <set>
#include <stdexcept>

// File-only native scene envelope. Max owns graph serialization; this descriptor
// only admits bounded metadata and declares every immutable collected payload.
namespace cyrus::scenepresets {
using Json=cyrus::recipes::Json;
inline bool isScene(const Json& d){return d.is_object()&&d.value("format","")=="cyrus.scene-preset";}
inline void validate(const Json& d){
    const auto need=[](bool ok,const char* why){if(!ok)throw std::invalid_argument(why);};
    const auto text=[&](const Json& v,std::size_t limit){need(v.is_string(),"Scene preset requires text.");const auto& s=v.get_ref<const std::string&>();need(s.size()<=limit&&s.find('\0')==std::string::npos,"Scene preset text exceeds bounds.");};
    need(isScene(d)&&d.value("version",0)==1&&d.size()==13,"Unsupported scene preset format.");
    for(auto key:{"id","revision","name","maxYear","scatterVersion","metersPerUnit","nodeCount","layers","scene","assets","presentation"})need(d.contains(key),"Incomplete scene preset.");
    text(d["id"],80);const auto id=d["id"].get<std::string>();need(!id.empty()&&std::all_of(id.begin(),id.end(),[](unsigned char c){return (c>='a'&&c<='z')||(c>='A'&&c<='Z')||(c>='0'&&c<='9')||c=='_'||c=='-';}),"Invalid scene preset identity.");
    text(d["name"],128);need(!d["name"].get_ref<const std::string&>().empty(),"Name this scene preset.");text(d["scatterVersion"],32);
    need(d["revision"].is_number_integer()&&d["revision"].get<std::int64_t>()>=1&&d["revision"].get<std::int64_t>()<=1000000000,"Invalid scene preset revision.");
    need(d["maxYear"]==2027,"Scene presets currently require Max 2027.");
    need(d["metersPerUnit"].is_number()&&d["metersPerUnit"].get<double>()>1e-12&&d["metersPerUnit"].get<double>()<=1e6,"Invalid scene preset units.");
    need(d["nodeCount"].is_number_integer()&&d["nodeCount"].get<std::int64_t>()>0&&d["nodeCount"].get<std::int64_t>()<=10000,"Scene preset exceeds 10,000 nodes.");
    need(d["layers"].is_array()&&!d["layers"].empty()&&d["layers"].size()<=10,"Scene preset needs 1..10 layers.");for(const auto& name:d["layers"])text(name,128);
    std::uint64_t total=0;std::map<std::string,Json> paths;
    const auto payload=[&](const Json& p){
        need(p.is_object()&&p.size()==3&&p.contains("file")&&p.contains("sha256")&&p.contains("bytes"),"Invalid scene payload record.");text(p["file"],240);text(p["sha256"],64);
        const auto file=p["file"].get<std::string>(),hash=p["sha256"].get<std::string>();need(file=="scene.max"||(file.starts_with("assets/")&&file.size()>7),"Invalid scene payload location.");
        need(file.find("..") == std::string::npos&&file.find_first_of("\\:")==std::string::npos&&file.back()!='/',"Scene payload escapes its package.");
        need(hash.size()==64&&std::all_of(hash.begin(),hash.end(),[](char c){return(c>='0'&&c<='9')||(c>='a'&&c<='f');}),"Invalid scene payload digest.");
        need(p["bytes"].is_number_integer()&&p["bytes"].get<std::int64_t>()>0&&p["bytes"].get<std::int64_t>()<=2LL*1024*1024*1024,"Scene payload exceeds 2 GiB.");
        const auto old=paths.find(file);if(old==paths.end()){paths.emplace(file,p);total+=p["bytes"].get<std::uint64_t>();need(total<=16ULL*1024*1024*1024,"Scene preset exceeds 16 GiB.");}else need(old->second==p,"Conflicting scene payloads.");
    };
    payload(d["scene"]);need(d["scene"]["file"]=="scene.max","Invalid scene filename.");
    need(d["assets"].is_array()&&d["assets"].size()<=1024,"Scene preset exceeds 1,024 assets.");std::set<std::string> ids;
    for(const auto& a:d["assets"]){need(a.is_object()&&a.size()==3&&a.contains("id")&&a.contains("type")&&a.contains("payload"),"Invalid scene asset record.");text(a["id"],128);text(a["type"],64);need(!a["id"].get_ref<const std::string&>().empty()&&ids.insert(a["id"].get<std::string>()).second,"Duplicate scene asset identity.");payload(a["payload"]);need(a["payload"]["file"]!="scene.max","Invalid scene dependency location.");}
    cyrus::recipes::validateEntryPresentation(d["presentation"]);
}
}
