#include "asset_mesh.h"
#include "asset_package.h"
#include <cmath>
#include <cstring>
#include <set>
#include <stdexcept>

namespace cyrus::assets {
namespace {
void require(bool value,const char* message){if(!value)throw std::invalid_argument(message);}
void vertices(const std::vector<Vertex>& rows){for(const auto& row:rows)for(double value:row)require(std::isfinite(value)&&std::abs(value)<=1e9,"Mesh coordinate exceeds finite limits.");}
void indices(const Triangle& face,std::size_t count){for(auto index:face)require(index<count,"Mesh index is out of range.");}
std::size_t bytesRequired(const Mesh& mesh){std::size_t count=20+mesh.vertices.size()*24+mesh.faces.size()*24;for(const auto& map:mesh.maps)count+=12+map.vertices.size()*24+map.faces.size()*12;return count;}
struct Writer {
    std::vector<unsigned char> bytes;
    void u32(std::uint32_t n){for(int i=0;i<4;++i)bytes.push_back(static_cast<unsigned char>((n>>(i*8))&255));}
    void number(double value){std::uint64_t n=0;static_assert(sizeof(n)==sizeof(value));std::memcpy(&n,&value,8);for(int i=0;i<8;++i)bytes.push_back(static_cast<unsigned char>((n>>(i*8))&255));}
    void vertex(const Vertex& value){for(auto v:value)number(v);}
    void triangle(const Triangle& value){for(auto v:value)u32(v);}
};
struct Reader {
    const std::vector<unsigned char>& bytes;std::size_t at=8;
    void available(std::size_t count)const{require(at<=bytes.size()&&count<=bytes.size()-at,"Truncated mesh payload.");}
    std::uint32_t u32(){available(4);std::uint32_t n=0;for(int i=0;i<4;++i)n|=static_cast<std::uint32_t>(bytes[at++])<<(i*8);return n;}
    double number(){available(8);std::uint64_t n=0;for(int i=0;i<8;++i)n|=static_cast<std::uint64_t>(bytes[at++])<<(i*8);double value=0;std::memcpy(&value,&n,8);return value;}
    Vertex vertex(){return {number(),number(),number()};}
    Triangle triangle(){return {u32(),u32(),u32()};}
};
}
void validateMesh(const Mesh& mesh){
    require(!mesh.vertices.empty()&&mesh.vertices.size()<=maxMeshVertices&&!mesh.faces.empty()&&mesh.faces.size()<=maxMeshFaces,"Mesh requires 1..100000 vertices and faces.");
    require(mesh.maps.size()<=maxMeshChannels,"Mesh supports at most eight populated mapping channels.");require(bytesRequired(mesh)<=maxFileBytes,"Mesh payload exceeds 32 MiB.");vertices(mesh.vertices);
    for(const auto& face:mesh.faces){indices(face.vertices,mesh.vertices.size());require(face.material<=65535&&face.edges<=7,"Invalid mesh face attributes.");}
    std::set<int> channels;
    for(const auto& map:mesh.maps){require(map.channel>=-2&&map.channel<=99&&channels.insert(map.channel).second,"Invalid or repeated mapping channel.");require(!map.vertices.empty()&&map.vertices.size()<=maxMapVertices&&map.faces.size()==mesh.faces.size(),"Invalid mapping topology.");vertices(map.vertices);for(const auto& face:map.faces)indices(face,map.vertices.size());}
}
std::vector<unsigned char> encodeMesh(const Mesh& mesh){
    validateMesh(mesh);Writer out;out.bytes.reserve(bytesRequired(mesh));for(char c:std::string("CYRUSM01"))out.bytes.push_back(static_cast<unsigned char>(c));
    out.u32(static_cast<std::uint32_t>(mesh.vertices.size()));out.u32(static_cast<std::uint32_t>(mesh.faces.size()));out.u32(static_cast<std::uint32_t>(mesh.maps.size()));
    for(const auto& vertex:mesh.vertices)out.vertex(vertex);for(const auto& face:mesh.faces){out.triangle(face.vertices);out.u32(face.smoothing);out.u32(face.material);out.u32(face.edges);}
    for(const auto& map:mesh.maps){out.u32(static_cast<std::uint32_t>(map.channel));out.u32(static_cast<std::uint32_t>(map.vertices.size()));out.u32(static_cast<std::uint32_t>(map.faces.size()));for(const auto& v:map.vertices)out.vertex(v);for(const auto& f:map.faces)out.triangle(f);}
    return out.bytes;
}
Mesh decodeMesh(const std::vector<unsigned char>& bytes){
    require(bytes.size()>=20&&bytes.size()<=maxFileBytes&&std::string(bytes.begin(),bytes.begin()+8)=="CYRUSM01","Unsupported or oversized mesh payload.");Reader in{bytes};const auto nv=in.u32(),nf=in.u32(),nc=in.u32();
    require(nv>0&&nv<=maxMeshVertices&&nf>0&&nf<=maxMeshFaces&&nc<=maxMeshChannels,"Mesh counts exceed admission.");in.available(static_cast<std::size_t>(nv)*24+static_cast<std::size_t>(nf)*24);Mesh result;result.vertices.reserve(nv);result.faces.reserve(nf);
    for(std::uint32_t i=0;i<nv;++i)result.vertices.push_back(in.vertex());for(std::uint32_t i=0;i<nf;++i)result.faces.push_back({in.triangle(),in.u32(),in.u32(),in.u32()});
    for(std::uint32_t i=0;i<nc;++i){const auto raw=in.u32();const int channel=raw==0xfffffffeu?-2:raw==0xffffffffu?-1:raw<=99?static_cast<int>(raw):100;const auto mv=in.u32(),mf=in.u32();require(mv>0&&mv<=maxMapVertices&&mf==nf&&channel<=99,"Invalid mesh mapping counts.");in.available(static_cast<std::size_t>(mv)*24+static_cast<std::size_t>(mf)*12);Mapping map;map.channel=channel;map.vertices.reserve(mv);map.faces.reserve(mf);for(std::uint32_t j=0;j<mv;++j)map.vertices.push_back(in.vertex());for(std::uint32_t j=0;j<mf;++j)map.faces.push_back(in.triangle());result.maps.push_back(std::move(map));}
    require(in.at==bytes.size(),"Trailing mesh payload bytes.");validateMesh(result);return result;
}
}
