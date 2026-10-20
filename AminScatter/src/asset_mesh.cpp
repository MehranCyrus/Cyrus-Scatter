#include "asset_mesh.h"
#include <cmath>
#include <cstring>
#include <limits>
#include <set>
#include <stdexcept>
#include <string_view>

namespace cyrus::assets {
namespace {
void require(bool value,const char* message){if(!value)throw std::invalid_argument(message);}
struct Limits {std::size_t vertices,faces,mapVertices,normals,bytes;};
Limits limits(MeshProfile p){switch(p){case MeshProfile::Legacy:return {maxMeshVertices,maxMeshFaces,maxMapVertices,0,maxLegacyMeshBytes};case MeshProfile::Plant:return {maxPlantMeshVertices,maxPlantMeshFaces,maxPlantMapVertices,maxPlantNormals,maxPlantMeshBytes};}throw std::invalid_argument("Unsupported mesh profile.");}
std::size_t add(std::size_t a,std::size_t b){require(b<=std::numeric_limits<std::size_t>::max()-a,"Mesh byte accounting overflow.");return a+b;}
std::size_t mul(std::size_t a,std::size_t b){require(!b||a<=std::numeric_limits<std::size_t>::max()/b,"Mesh byte accounting overflow.");return a*b;}
void vertices(const std::vector<Vertex>& rows){for(const auto& row:rows)for(double value:row)require(std::isfinite(value)&&std::abs(value)<=1e9,"Mesh coordinate exceeds finite limits.");}
void indices(const Triangle& face,std::size_t count){for(auto index:face)require(index<count,"Mesh index is out of range.");}
std::size_t bytesRequired(const Mesh& mesh,MeshProfile profile){
    std::size_t n=profile==MeshProfile::Plant?32:20;n=add(n,mul(mesh.vertices.size(),24));n=add(n,mul(mesh.faces.size(),24));
    for(const auto& map:mesh.maps){n=add(n,12);n=add(n,mul(map.vertices.size(),24));n=add(n,mul(map.faces.size(),12));}
    if(mesh.normals){n=add(n,mul(mesh.normals->vectors.size(),28));n=add(n,mul(mesh.normals->faces.size(),16));}return n;
}
struct Writer {
    std::vector<unsigned char> bytes;
    void u32(std::uint32_t n){for(int i=0;i<4;++i)bytes.push_back(static_cast<unsigned char>((n>>(i*8))&255));}
    void number(double value){std::uint64_t n=0;static_assert(sizeof(n)==sizeof(value));std::memcpy(&n,&value,8);for(int i=0;i<8;++i)bytes.push_back(static_cast<unsigned char>((n>>(i*8))&255));}
    void vertex(const Vertex& v){for(auto x:v)number(x);}
    void triangle(const Triangle& t){for(auto x:t)u32(x);}
};
struct Reader {
    std::span<const unsigned char> bytes;std::size_t at=8;
    void available(std::size_t n)const{require(at<=bytes.size()&&n<=bytes.size()-at,"Truncated mesh payload.");}
    std::uint32_t u32(){available(4);std::uint32_t n=0;for(int i=0;i<4;++i)n|=static_cast<std::uint32_t>(bytes[at++])<<(i*8);return n;}
    double number(){available(8);std::uint64_t n=0;for(int i=0;i<8;++i)n|=static_cast<std::uint64_t>(bytes[at++])<<(i*8);double value=0;std::memcpy(&value,&n,8);return value;}
    Vertex vertex(){return {number(),number(),number()};}
    Triangle triangle(){return {u32(),u32(),u32()};}
};
// Scan the entire bounded payload before allocating decoded arrays. This checks
// headers, values, flags, topology and exact end position without retaining data.
void scan(Reader in,MeshProfile profile){
    const auto cap=limits(profile);const bool plant=profile==MeshProfile::Plant;
    const auto nv=in.u32(),nf=in.u32(),nc=in.u32();require(nv>0&&nv<=cap.vertices&&nf>0&&nf<=cap.faces&&nc<=maxMeshChannels,"Mesh counts exceed admission.");
    std::uint32_t present=0,nn=0;
    if(plant){present=in.u32();const auto flags=in.u32();nn=in.u32();require(present<=1&&(flags&~supportedMeshNormalFlags)==0&&nn<=cap.normals&&((present&&nn>0&&(flags&3u)==3u)||(!present&&nn==0&&flags==0)),"Invalid or unresolved stored-normal header.");}
    auto vertex=[&](){const auto v=in.vertex();for(auto x:v)require(std::isfinite(x)&&std::abs(x)<=1e9,"Mesh coordinate exceeds finite limits.");return v;};
    in.available(add(mul(nv,24),mul(nf,24)));for(std::uint32_t i=0;i<nv;++i)vertex();
    for(std::uint32_t i=0;i<nf;++i){indices(in.triangle(),nv);in.u32();require(in.u32()<=65535&&in.u32()<=7,"Invalid mesh face attributes.");}
    std::set<int> channels;
    for(std::uint32_t i=0;i<nc;++i){const auto raw=in.u32();const int channel=raw==0xfffffffeu?-2:raw==0xffffffffu?-1:raw<=99?static_cast<int>(raw):100;const auto mv=in.u32(),mf=in.u32();require(channel<=99&&channels.insert(channel).second&&mv>0&&mv<=cap.mapVertices&&mf==nf,"Invalid mapping counts or channel.");in.available(add(mul(mv,24),mul(mf,12)));for(std::uint32_t j=0;j<mv;++j)vertex();for(std::uint32_t j=0;j<mf;++j)indices(in.triangle(),mv);}
    if(present){in.available(add(mul(nn,28),mul(nf,16)));for(std::uint32_t i=0;i<nn;++i){double len2=0;for(auto x:in.vertex()){require(std::isfinite(x)&&std::abs(x)<=1e6,"Stored normal exceeds finite bounds.");len2+=x*x;}require(len2>1e-24,"Stored normal has zero or unusable length.");require(in.u32()<=1,"Invalid explicit-normal flag.");}for(std::uint32_t i=0;i<nf;++i){const auto ids=in.triangle();const auto mask=in.u32();require(mask<=7,"Invalid specified-corner mask.");for(std::size_t c=0;c<3;++c)require(ids[c]<nn||(ids[c]==0xffffffffu&&!(mask&(1u<<c))),"Stored-normal corner index is out of range.");}}
    require(in.at==in.bytes.size(),"Trailing mesh payload bytes.");
}
}
void validateMesh(const Mesh& mesh,MeshProfile profile){
    const auto cap=limits(profile);
    require(!mesh.vertices.empty()&&mesh.vertices.size()<=cap.vertices&&!mesh.faces.empty()&&mesh.faces.size()<=cap.faces,"Mesh geometry exceeds its finite profile.");
    require(mesh.maps.size()<=maxMeshChannels,"Mesh supports at most eight populated mapping channels.");require(profile==MeshProfile::Plant||!mesh.normals,"Legacy meshes cannot contain stored normals.");
    require(bytesRequired(mesh,profile)<=cap.bytes,"Mesh payload exceeds its encoded-byte profile.");vertices(mesh.vertices);
    for(const auto& f:mesh.faces){indices(f.vertices,mesh.vertices.size());require(f.material<=65535&&f.edges<=7,"Invalid mesh face attributes.");}
    std::set<int> channels;
    for(const auto& map:mesh.maps){require(map.channel>=-2&&map.channel<=99&&channels.insert(map.channel).second,"Invalid or repeated mapping channel.");require(!map.vertices.empty()&&map.vertices.size()<=cap.mapVertices&&map.faces.size()==mesh.faces.size(),"Invalid mapping topology.");vertices(map.vertices);for(const auto& f:map.faces)indices(f,map.vertices.size());}
    if(mesh.normals){const auto& ns=*mesh.normals;require((ns.flags&~supportedMeshNormalFlags)==0&&(ns.flags&3u)==3u,"Unsupported or unresolved stored-normal flags.");require(!ns.vectors.empty()&&ns.vectors.size()<=cap.normals&&ns.explicitFlags.size()==ns.vectors.size()&&ns.faces.size()==mesh.faces.size(),"Invalid stored-normal counts.");
        for(const auto& v:ns.vectors){double len2=0;for(auto x:v){require(std::isfinite(x)&&std::abs(x)<=1e6,"Stored normal exceeds finite bounds.");len2+=x*x;}require(len2>1e-24,"Stored normal has zero or unusable length.");}
        for(auto flag:ns.explicitFlags)require(flag<=1,"Invalid explicit-normal flag.");for(const auto& f:ns.faces)for(std::size_t c=0;c<3;++c){require(f.specified[c]<=1,"Invalid specified-corner flag.");const auto id=f.ids[c];require((id==-1&&!f.specified[c])||(id>=0&&static_cast<std::size_t>(id)<ns.vectors.size()),"Stored-normal corner index is out of range.");}
    }
}
std::size_t meshStorageBytes(const Mesh& mesh){
    std::size_t n=sizeof(Mesh);n=add(n,mul(mesh.vertices.capacity(),sizeof(Vertex)));n=add(n,mul(mesh.faces.capacity(),sizeof(Face)));n=add(n,mul(mesh.maps.capacity(),sizeof(Mapping)));
    for(const auto& m:mesh.maps){n=add(n,mul(m.vertices.capacity(),sizeof(Vertex)));n=add(n,mul(m.faces.capacity(),sizeof(Triangle)));}
    if(mesh.normals){const auto& x=*mesh.normals;n=add(n,mul(x.vectors.capacity(),sizeof(Vertex)));n=add(n,mul(x.explicitFlags.capacity(),sizeof(std::uint8_t)));n=add(n,mul(x.faces.capacity(),sizeof(NormalFace)));}return n;
}
std::size_t meshEncodedBytes(const Mesh& mesh,MeshProfile profile){validateMesh(mesh,profile);return bytesRequired(mesh,profile);}
Vertex transformStoredNormal(const Vertex& n,const std::array<Vertex,3>& a){
    double lengths=1.;bool identity=true;for(std::size_t i=0;i<3;++i){double squared=0;for(std::size_t j=0;j<3;++j){require(std::isfinite(a[i][j]),"Normal transform is not finite.");squared+=a[i][j]*a[i][j];identity=identity&&a[i][j]==(i==j?1.:0.);}lengths*=std::sqrt(squared);}
    double original2=0;for(auto x:n){require(std::isfinite(x)&&std::abs(x)<=1e6,"Stored normal exceeds finite bounds.");original2+=x*x;}require(original2>1e-24,"Stored normal has zero or unusable length.");
    const double det=a[0][0]*(a[1][1]*a[2][2]-a[1][2]*a[2][1])-a[0][1]*(a[1][0]*a[2][2]-a[1][2]*a[2][0])+a[0][2]*(a[1][0]*a[2][1]-a[1][1]*a[2][0]);
    require(std::isfinite(det)&&std::isfinite(lengths)&&lengths>0&&std::abs(det)/lengths>=1e-8,"Normal transform is singular or too close to singular.");if(identity)return n;
    // Cofactor matrix is inverse-transpose * determinant. Dividing by the
    // determinant also retains the sign for reflected transforms.
    const std::array<Vertex,3> co{{{a[1][1]*a[2][2]-a[1][2]*a[2][1],a[1][2]*a[2][0]-a[1][0]*a[2][2],a[1][0]*a[2][1]-a[1][1]*a[2][0]},
                                {a[0][2]*a[2][1]-a[0][1]*a[2][2],a[0][0]*a[2][2]-a[0][2]*a[2][0],a[0][1]*a[2][0]-a[0][0]*a[2][1]},
                                {a[0][1]*a[1][2]-a[0][2]*a[1][1],a[0][2]*a[1][0]-a[0][0]*a[1][2],a[0][0]*a[1][1]-a[0][1]*a[1][0]}}};
    Vertex out{};double transformed2=0;for(std::size_t j=0;j<3;++j){for(std::size_t i=0;i<3;++i)out[j]+=n[i]*co[i][j]/det;transformed2+=out[j]*out[j];}
    require(std::isfinite(transformed2)&&transformed2>0,"Transformed normal is unusable.");const auto scale=std::sqrt(original2/transformed2);for(auto& x:out){x*=scale;require(std::isfinite(x)&&std::abs(x)<=1e6,"Transformed normal exceeds finite bounds.");}return out;
}
std::vector<unsigned char> encodeMesh(const Mesh& mesh,MeshProfile profile){
    validateMesh(mesh,profile);Writer out;out.bytes.reserve(bytesRequired(mesh,profile));const auto magic=profile==MeshProfile::Plant?std::string_view("CYRUSM02"):std::string_view("CYRUSM01");for(char c:magic)out.bytes.push_back(static_cast<unsigned char>(c));
    out.u32(static_cast<std::uint32_t>(mesh.vertices.size()));out.u32(static_cast<std::uint32_t>(mesh.faces.size()));out.u32(static_cast<std::uint32_t>(mesh.maps.size()));
    if(profile==MeshProfile::Plant){out.u32(mesh.normals?1:0);out.u32(mesh.normals?mesh.normals->flags:0);out.u32(mesh.normals?static_cast<std::uint32_t>(mesh.normals->vectors.size()):0);}
    for(const auto& v:mesh.vertices)out.vertex(v);for(const auto& f:mesh.faces){out.triangle(f.vertices);out.u32(f.smoothing);out.u32(f.material);out.u32(f.edges);}
    for(const auto& map:mesh.maps){out.u32(static_cast<std::uint32_t>(map.channel));out.u32(static_cast<std::uint32_t>(map.vertices.size()));out.u32(static_cast<std::uint32_t>(map.faces.size()));for(const auto& v:map.vertices)out.vertex(v);for(const auto& f:map.faces)out.triangle(f);}
    if(mesh.normals){const auto& ns=*mesh.normals;for(std::size_t i=0;i<ns.vectors.size();++i){out.vertex(ns.vectors[i]);out.u32(ns.explicitFlags[i]);}for(const auto& f:ns.faces){for(auto id:f.ids)out.u32(static_cast<std::uint32_t>(id));out.u32(f.specified[0]|(f.specified[1]<<1)|(f.specified[2]<<2));}}
    require(out.bytes.size()==bytesRequired(mesh,profile),"Mesh encoded-byte accounting mismatch.");return out.bytes;
}
Mesh decodeMesh(std::span<const unsigned char> bytes,MeshProfile profile){
    const auto requested=limits(profile);require(bytes.size()>=20&&bytes.size()<=requested.bytes,"Unsupported or oversized mesh payload.");
    const bool legacy=std::memcmp(bytes.data(),"CYRUSM01",8)==0;const bool plant=std::memcmp(bytes.data(),"CYRUSM02",8)==0;
    require(legacy||(profile==MeshProfile::Plant&&plant),"Unsupported mesh payload for selected profile.");const auto actual=legacy?MeshProfile::Legacy:MeshProfile::Plant;const auto cap=limits(actual);require(bytes.size()<=cap.bytes,"Mesh exceeds its format byte admission.");
    scan(Reader{bytes},actual);Reader in{bytes};const auto nv=in.u32(),nf=in.u32(),nc=in.u32();std::uint32_t present=0,flags=0,nn=0;if(plant){present=in.u32();flags=in.u32();nn=in.u32();}
    Mesh result;result.profile=actual;result.vertices.reserve(nv);result.faces.reserve(nf);result.maps.reserve(nc);
    for(std::uint32_t i=0;i<nv;++i)result.vertices.push_back(in.vertex());for(std::uint32_t i=0;i<nf;++i)result.faces.push_back({in.triangle(),in.u32(),in.u32(),in.u32()});
    for(std::uint32_t i=0;i<nc;++i){const auto raw=in.u32();const int channel=raw==0xfffffffeu?-2:raw==0xffffffffu?-1:static_cast<int>(raw);const auto mv=in.u32(),mf=in.u32();Mapping map;map.channel=channel;map.vertices.reserve(mv);map.faces.reserve(mf);for(std::uint32_t j=0;j<mv;++j)map.vertices.push_back(in.vertex());for(std::uint32_t j=0;j<mf;++j)map.faces.push_back(in.triangle());result.maps.push_back(std::move(map));}
    if(present){result.normals.emplace();auto& ns=*result.normals;ns.flags=flags;ns.vectors.reserve(nn);ns.explicitFlags.reserve(nn);ns.faces.reserve(nf);for(std::uint32_t i=0;i<nn;++i){ns.vectors.push_back(in.vertex());ns.explicitFlags.push_back(static_cast<std::uint8_t>(in.u32()));}for(std::uint32_t i=0;i<nf;++i){NormalFace f;for(auto& id:f.ids){const auto raw=in.u32();id=raw==0xffffffffu?-1:static_cast<std::int32_t>(raw);}const auto mask=in.u32();for(std::size_t c=0;c<3;++c)f.specified[c]=static_cast<std::uint8_t>((mask>>c)&1);ns.faces.push_back(f);}}
    require(in.at==bytes.size(),"Mesh decode end-position mismatch.");return result;
}
Mesh decodeMesh(const std::vector<unsigned char>& bytes,MeshProfile profile){return decodeMesh(std::span<const unsigned char>(bytes.data(),bytes.size()),profile);}
}
