#pragma once
#include "asset_package.h"
#include <stdexcept>

namespace cyrus::assets {
// PackageTask holds its mutex across access. Leases own immutable native data,
// never SDK nodes, file handles or script values. The file worker stays separate.
class PreparedPackageLeases {
    static constexpr std::uint64_t marker=std::uint64_t{1}<<62;
    std::uint64_t next_=1;
    std::map<std::uint64_t,std::shared_ptr<const PreparedPackage>> values_;
    static void add(std::uint64_t& total,std::uint64_t value,std::uint64_t limit){
        if(value>limit-total)throw std::runtime_error("Retained source packages exceed aggregate resource admission.");
        total+=value;
    }
    static void admit(const PreparedPackage& package,std::uint64_t& payload,std::uint64_t& storage,std::uint64_t& pixels,std::uint64_t& maps,std::uint64_t& materials){
        add(payload,package.payloadBytes,64ull*1024*1024);
        for(const auto& [id,mesh]:package.meshes){
            if(!mesh)throw std::runtime_error("Missing retained source mesh.");
            add(storage,meshStorageBytes(*mesh),128ull*1024*1024);
        }
        const auto& graph=package.metadata.at("graph");
        if(graph.at("nodes").empty()||graph.at("nodes").size()>3||!graph.value("splines",Json::array()).empty())
            throw std::runtime_error("Retained source packages require 1-3 mesh nodes and no splines.");
        add(maps,graph.at("maps").size(),128);add(materials,graph.at("materials").size(),64);
        for(const auto& map:graph.at("maps"))if(map.at("kind")=="bitmap"||map.at("kind")=="corona-bitmap-v1"){
            const auto x=map.at("size").at(0).get<std::uint64_t>(),y=map.at("size").at(1).get<std::uint64_t>();
            if(x==0||y==0||x>32768||y>32768)throw std::runtime_error("Invalid retained image dimensions.");
            add(pixels,x*y,64000000);
        }
    }
public:
    static bool isLease(std::uint64_t token){return (token&marker)!=0;}
    std::uint64_t retain(std::shared_ptr<const PreparedPackage> package){
        if(!package||values_.size()>=3||next_>=marker)throw std::runtime_error("Retained source package lease admission exceeded.");
        std::uint64_t payload=0,storage=0,pixels=0,maps=0,materials=0;
        for(const auto& [id,value]:values_)admit(*value,payload,storage,pixels,maps,materials);
        admit(*package,payload,storage,pixels,maps,materials);
        const auto token=marker|next_;
        values_.emplace(token,std::move(package));++next_;return token;
    }
    std::shared_ptr<const PreparedPackage> get(std::uint64_t token)const{
        const auto found=values_.find(token);
        if(found==values_.end())throw std::runtime_error("Retained source snapshot was released. Review again.");
        return found->second;
    }
    void release(std::uint64_t token){values_.erase(token);}
    std::size_t size()const{return values_.size();}
};
}
