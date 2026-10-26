#pragma once
#include "recipes.h"
#include <fstream>
#ifndef NOMINMAX
#define NOMINMAX
#endif
#include <windows.h>

namespace cyrus::assets::shared {
inline recipes::Json metadata(const std::filesystem::path& path) {
    std::ifstream in(recipes::nativePath(path),std::ios::binary|std::ios::ate);
    if(!in||in.tellg()<1||in.tellg()>16384)throw std::runtime_error("Shared library marker is missing or oversized");
    std::string bytes(static_cast<std::size_t>(in.tellg()),'\0');in.seekg(0);in.read(bytes.data(),bytes.size());
    if(!in)throw std::runtime_error("Shared library marker changed");return recipes::parse(bytes);
}
inline void noLinks(std::filesystem::path path) {
    for(;!path.empty();){const auto attributes=GetFileAttributesW(recipes::nativePath(path).c_str());
        if(attributes!=INVALID_FILE_ATTRIBUTES&&(attributes&FILE_ATTRIBUTE_REPARSE_POINT))throw std::runtime_error("Shared library paths cannot traverse linked directories");
        const auto next=path.parent_path();if(next==path)break;path=next;
    }
}
inline std::filesystem::path root(std::filesystem::path path) {
    noLinks(path);
    for(int depth=0;depth<16&&!path.empty();++depth){
        if(std::filesystem::is_regular_file(path/"store.json")){
            const auto marker=metadata(path/"store.json");
            if(marker.value("format","")=="cyrus.asset-store"){
                if(marker.value("version",0)!=1)throw std::runtime_error("Unsupported shared asset store");return path;
            }
        }
        const auto next=path.parent_path();if(next==path)break;path=next;
    }return {};
}
inline std::filesystem::path resolve(const std::filesystem::path& raw) {
    const auto path=recipes::nativePath(raw);if(!std::filesystem::exists(path/"cyrus.shared.json"))return path;
    const auto reference=metadata(path/"cyrus.shared.json");const auto store=root(path);
    if(store.empty()||reference.value("format","")!="cyrus.shared-reference"||reference.value("version",0)!=1||reference.at("store")!=metadata(store/"store.json").at("id"))throw std::runtime_error("Shared package ownership differs");
    const auto digest=reference.at("recipe").get<std::string>();
    if(digest.size()!=64||digest.find_first_not_of("0123456789abcdef")!=std::string::npos)throw std::runtime_error("Invalid shared package digest");
    const auto result=store/"packs"/"user"/digest;noLinks(result);
    if(metadata(result/"cyrus.package.json").at("recipe").at("sha256")!=digest)throw std::runtime_error("Shared package recipe differs");return result;
}
inline bool ownedStage(const std::filesystem::path& source,const std::filesystem::path& output) {
    const auto a=root(source.parent_path()),b=root(output.parent_path());if(a.empty()||b.empty()||!std::filesystem::equivalent(a,b))return false;
    const auto from=source.lexically_relative(a),to=output.lexically_relative(b);
    return !from.empty()&&!to.empty()&&*from.begin()=="staging"&&*to.begin()=="staging";
}
}
