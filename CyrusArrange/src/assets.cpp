#include "cyrus_arrange/assets.h"
#include <algorithm>
#include <array>
#include <bit>
#include <cmath>
#include <fstream>
#include <limits>
#include <random>
#include <stdexcept>
#include <unordered_set>
#ifdef _WIN32
#ifndef NOMINMAX
#define NOMINMAX
#endif
#define WIN32_LEAN_AND_MEAN
#include <Windows.h>
#endif

namespace cyrus::arrange {
namespace {
constexpr std::array<std::uint8_t,8> magic{'C','Y','A','S','S','E','T',0};
constexpr std::uint32_t format_version = 2;
constexpr double epsilon = 1e-6;
void require(bool valid, const char* message) {
    if (!valid) throw std::runtime_error(message);
}
bool finite(double value) { return std::isfinite(value); }
bool finite(Vec3 value) {
    return finite(value.x) && finite(value.y) && finite(value.z) &&
        std::abs(value.x)<=1e9 && std::abs(value.y)<=1e9 && std::abs(value.z)<=1e9;
}
bool same_distance(double a,double b) { return std::abs(a-b)<=epsilon; }
double cross_xy(Vec3 a,Vec3 b,Vec3 c) {
    return (b.x-a.x)*(c.y-b.y)-(b.y-a.y)*(c.x-b.x);
}
bool valid_utf8(const std::string& text) {
    const auto* p = reinterpret_cast<const unsigned char*>(text.data());
    std::size_t i=0;
    while(i<text.size()) {
        const auto lead=p[i++];
        if(lead<0x80) { if(lead<0x20 || lead==0x7f) return false; continue; }
        std::uint32_t code=0, minimum=0;
        unsigned remaining=0;
        if((lead&0xe0)==0xc0) { code=lead&0x1f;remaining=1;minimum=0x80; }
        else if((lead&0xf0)==0xe0) { code=lead&0x0f;remaining=2;minimum=0x800; }
        else if((lead&0xf8)==0xf0) { code=lead&0x07;remaining=3;minimum=0x10000; }
        else return false;
        if(remaining>text.size()-i) return false;
        for(unsigned n=0;n<remaining;++n) {
            const auto next=p[i++]; if((next&0xc0)!=0x80) return false;
            code=(code<<6)|(next&0x3f);
        }
        if(code<minimum || code>0x10ffff || (code>=0xd800 && code<=0xdfff)) return false;
    }
    return true;
}
void check_limits(const AssetLimits& limits) {
    const AssetLimits ceiling;
    require(limits.max_assets<=ceiling.max_assets &&
        limits.max_vertices_per_asset<=ceiling.max_vertices_per_asset &&
        limits.max_triangles_per_asset<=ceiling.max_triangles_per_asset &&
        limits.max_total_vertices<=ceiling.max_total_vertices &&
        limits.max_total_triangles<=ceiling.max_total_triangles &&
        limits.max_name_bytes<=ceiling.max_name_bytes &&
        limits.max_footprint_vertices<=ceiling.max_footprint_vertices &&
        limits.max_yaws<=ceiling.max_yaws &&
        limits.max_library_bytes<=ceiling.max_library_bytes,
        "Asset limits may be lowered but cannot exceed implementation ceilings");
}
void check_polygon(const std::vector<Vec3>& polygon,double height,const Bounds& bounds,const AssetLimits& limits) {
    require(polygon.size()>=3 && polygon.size()<=limits.max_footprint_vertices,"Asset footprint vertex count is outside the limit");
    double area=0;
    for(std::size_t i=0;i<polygon.size();++i) {
        const auto a=polygon[i],b=polygon[(i+1)%polygon.size()],c=polygon[(i+2)%polygon.size()];
        require(finite(a) && same_distance(a.z,height),"Asset footprint must be finite and on its declared horizontal plane");
        require(a.x>=bounds.min.x-epsilon && a.x<=bounds.max.x+epsilon && a.y>=bounds.min.y-epsilon && a.y<=bounds.max.y+epsilon,
            "Asset footprint extends outside the complete mesh bounds");
        require(cross_xy(a,b,c)>epsilon,"Asset footprint must be strictly convex, counterclockwise and nondegenerate");
        area+=a.x*b.y-a.y*b.x;
    }
    require(area>epsilon,"Asset footprint must have positive area");
    // Every vertex must lie in every directed edge half-plane; catches star polygons.
    for(std::size_t i=0;i<polygon.size();++i)
        for(const auto p:polygon) {
            const auto a=polygon[i],b=polygon[(i+1)%polygon.size()];
            require((b.x-a.x)*(p.y-a.y)-(b.y-a.y)*(p.x-a.x)>=-epsilon,"Asset footprint self-intersects or is non-convex");
        }
}
std::vector<Vec3> rectangle(const Bounds& bounds,double z) {
    return {{bounds.min.x,bounds.min.y,z},{bounds.max.x,bounds.min.y,z},
            {bounds.max.x,bounds.max.y,z},{bounds.min.x,bounds.max.y,z}};
}
std::string normalized_name(std::string_view name) {
    if(name.size()>4096)return {};
    std::string result=" ";result.reserve(name.size()+2);
    for(const unsigned char c:name) {
        if(c>='A' && c<='Z')result.push_back(static_cast<char>(c-'A'+'a'));
        else if((c>='a' && c<='z') || (c>='0' && c<='9'))result.push_back(static_cast<char>(c));
        else if(result.back()!=' ')result.push_back(' ');
    }
    if(result.back()!=' ')result.push_back(' ');
    return result;
}
bool contains_any(const std::string& name,std::initializer_list<const char*> phrases) {
    return std::any_of(phrases.begin(),phrases.end(),[&](const auto phrase) { return name.find(phrase)!=std::string::npos; });
}
std::uint32_t crc32(std::span<const std::uint8_t> bytes) {
    static const auto table=[] {
        std::array<std::uint32_t,256> result{};
        for(std::uint32_t i=0;i<256;++i) {
            auto value=i;
            for(unsigned bit=0;bit<8;++bit) value=(value>>1)^((value&1)?0xedb88320u:0u);
            result[i]=value;
        }
        return result;
    }();
    std::uint32_t value=0xffffffffu;
    for(const auto byte:bytes) value=table[(value^byte)&0xff]^(value>>8);
    return value^0xffffffffu;
}
struct Writer {
    std::vector<std::uint8_t> bytes;
    std::size_t limit;
    void room(std::size_t count) const { require(count<=limit-bytes.size(),"Encoded asset library exceeds its byte budget"); }
    void u32(std::uint32_t value) { room(4);for(unsigned n=0;n<4;++n)bytes.push_back(static_cast<std::uint8_t>(value>>(n*8))); }
    void u64(std::uint64_t value) { room(8);for(unsigned n=0;n<8;++n)bytes.push_back(static_cast<std::uint8_t>(value>>(n*8))); }
    void real(double value) { u64(std::bit_cast<std::uint64_t>(value)); }
    void vec(Vec3 value) { real(value.x);real(value.y);real(value.z); }
    void text(const std::string& value) { u32(static_cast<std::uint32_t>(value.size()));room(value.size());bytes.insert(bytes.end(),value.begin(),value.end()); }
    void points(const std::vector<Vec3>& values) { u32(static_cast<std::uint32_t>(values.size()));for(const auto p:values)vec(p); }
};
struct Reader {
    std::span<const std::uint8_t> bytes;
    std::size_t at{};
    void room(std::size_t count) const { require(count<=bytes.size()-at,"Truncated asset library"); }
    std::uint32_t u32() { room(4);std::uint32_t value=0;for(unsigned n=0;n<4;++n)value|=static_cast<std::uint32_t>(bytes[at++])<<(n*8);return value; }
    std::uint64_t u64() { room(8);std::uint64_t value=0;for(unsigned n=0;n<8;++n)value|=static_cast<std::uint64_t>(bytes[at++])<<(n*8);return value; }
    double real() { return std::bit_cast<double>(u64()); }
    Vec3 vec() { return {real(),real(),real()}; }
    std::string text(std::size_t limit) {
        const auto count=u32();require(count<=limit,"Asset name exceeds its byte budget");room(count);
        std::string result(reinterpret_cast<const char*>(bytes.data()+at),count);at+=count;return result;
    }
    std::vector<Vec3> points(std::size_t limit) {
        const auto count=u32();require(count<=limit,"Asset point array exceeds its count budget");room(static_cast<std::size_t>(count)*24);
        std::vector<Vec3> result;result.reserve(count);for(std::uint32_t i=0;i<count;++i)result.push_back(vec());return result;
    }
};
void write_asset(Writer& out,const Asset& asset) {
    out.u64(asset.id);out.text(asset.name);out.u32(static_cast<std::uint32_t>(asset.category));out.u32(asset.allowed_furniture);
    out.vec(asset.anchor);out.vec(asset.bounds.min);out.vec(asset.bounds.max);out.points(asset.contact_footprint);
    out.u32(static_cast<std::uint32_t>(asset.allowed_yaws_degrees.size()));for(const auto yaw:asset.allowed_yaws_degrees)out.real(yaw);
    out.real(asset.weight);out.real(asset.min_scale);out.real(asset.max_scale);out.u32(asset.stackable?1u:0u);
    out.real(asset.stack_height_mm);out.points(asset.stack_footprint);out.u32(asset.allowed_on_top);
    out.points(asset.mesh.vertices);out.u32(static_cast<std::uint32_t>(asset.mesh.triangles.size()));
    for(const auto face:asset.mesh.triangles)for(const auto index:face.vertices)out.u32(index);
    out.u32(asset.book_row?static_cast<std::uint32_t>(asset.book_row->spine_face)+1u:0u);
}
Asset read_asset(Reader& in,const AssetLimits& limits,std::size_t& total_vertices,std::size_t& total_triangles,std::uint32_t version) {
    Asset asset;
    asset.id=in.u64();asset.name=in.text(limits.max_name_bytes);asset.category=static_cast<AssetCategory>(in.u32());asset.allowed_furniture=in.u32();
    asset.anchor=in.vec();asset.bounds.min=in.vec();asset.bounds.max=in.vec();asset.contact_footprint=in.points(limits.max_footprint_vertices);
    const auto yaws=in.u32();require(yaws<=limits.max_yaws,"Asset yaw array exceeds its count budget");in.room(static_cast<std::size_t>(yaws)*8);
    asset.allowed_yaws_degrees.clear();asset.allowed_yaws_degrees.reserve(yaws);for(std::uint32_t i=0;i<yaws;++i)asset.allowed_yaws_degrees.push_back(in.real());
    asset.weight=in.real();asset.min_scale=in.real();asset.max_scale=in.real();const auto stackable=in.u32();require(stackable<=1,"Invalid asset stacking flag");asset.stackable=stackable!=0;
    asset.stack_height_mm=in.real();asset.stack_footprint=in.points(limits.max_footprint_vertices);asset.allowed_on_top=in.u32();
    // Read and admit counts before allocating any mesh-sized buffer.
    const auto vertices=in.u32();require(vertices<=limits.max_vertices_per_asset && vertices<=limits.max_total_vertices-total_vertices,"Asset vertex count exceeds its budget");
    total_vertices+=vertices;in.room(static_cast<std::size_t>(vertices)*24);asset.mesh.vertices.reserve(vertices);
    for(std::uint32_t i=0;i<vertices;++i)asset.mesh.vertices.push_back(in.vec());
    const auto faces=in.u32();require(faces<=limits.max_triangles_per_asset && faces<=limits.max_total_triangles-total_triangles,"Asset triangle count exceeds its budget");
    total_triangles+=faces;in.room(static_cast<std::size_t>(faces)*12);asset.mesh.triangles.reserve(faces);
    for(std::uint32_t i=0;i<faces;++i)asset.mesh.triangles.push_back({{in.u32(),in.u32(),in.u32()}});
    if(version==2) {
        const auto row_tag=in.u32();
        require(row_tag<=static_cast<std::uint32_t>(SpineFace::Count),"Invalid asset book-row profile tag");
        if(row_tag!=0)asset.book_row=BookRowProfile{static_cast<SpineFace>(row_tag-1u)};
    }
    return asset;
}
}

std::string asset_category_name(AssetCategory category) {
    constexpr const char* names[]{"Book","Book stack","Plant","Candle","Frame","Vase","Accessory","Bowl","Tableware","Kitchenware","Tray"};
    require(static_cast<unsigned>(category)<static_cast<unsigned>(AssetCategory::Count),"Invalid asset category");
    return names[static_cast<unsigned>(category)];
}
std::string furniture_category_name(FurnitureCategory category) {
    constexpr const char* names[]{"TV console","Open shelf","Coffee table","Kitchen counter","Dining table"};
    require(static_cast<unsigned>(category)<static_cast<unsigned>(FurnitureCategory::Count),"Invalid furniture category");
    return names[static_cast<unsigned>(category)];
}
std::optional<AssetCategory> infer_asset_category(std::string_view name) {
    const auto text=normalized_name(name);
    using A=AssetCategory;
    if(contains_any(text,{" book stack "," bookstack "," stacked books "}))return A::BookStack;
    if(contains_any(text,{" book "," books "," cookbook "," magazine "}))return A::Book;
    if(contains_any(text,{" plant "," potted "," succulent "," fern "," foliage "}))return A::Plant;
    if(contains_any(text,{" candle "," candleholder "," candlestick "}))return A::Candle;
    if(contains_any(text,{" frame "," pictureframe "," photo frame "," picture frame "}))return A::Frame;
    if(contains_any(text,{" vase "}))return A::Vase;
    if(contains_any(text,{" bowl "}))return A::Bowl;
    if(contains_any(text,{" tray "}))return A::Tray;
    if(contains_any(text,{" kettle "," toaster "," coffeemaker "," coffee maker "," kitchenware "," utensil "," utensils "}))return A::Kitchenware;
    if(contains_any(text,{" plate "," plates "," cup "," cups "," mug "," glass "," tableware "," saucer "}))return A::Tableware;
    if(contains_any(text,{" accessory "," sculpture "," ornament "," figurine "," decor "}))return A::Accessory;
    return std::nullopt;
}
std::optional<FurnitureCategory> infer_furniture_category(std::string_view name) {
    const auto text=normalized_name(name);
    using F=FurnitureCategory;
    const std::array matches{
        contains_any(text,{" tv console "," tvconsole "," tv stand "," tv table "," tv set "," tvset "," media console "," tv unit "}),
        contains_any(text,{" open shelf "," openshelf "," bookshelf "," bookcase "," shelving "," shelf "," shelves "}),
        contains_any(text,{" coffee table "," coffeetable "," cocktail table "}),
        contains_any(text,{" kitchen counter "," kitchencounter "," counter "," countertop "," worktop "}),
        contains_any(text,{" dining table "," diningtable "})};
    std::optional<F> result;
    for(std::size_t i=0;i<matches.size();++i)if(matches[i]) {
        if(result)return std::nullopt;
        result=static_cast<F>(i);
    }
    return result;
}
void validate_category_rules(std::span<const CategoryRule> rules) {
    require(rules.size()<=static_cast<std::size_t>(AssetCategory::Count),"Too many category rules");
    std::uint32_t seen=0;
    for(const auto& rule:rules) {
        require(static_cast<unsigned>(rule.category)<static_cast<unsigned>(AssetCategory::Count),"Invalid rule asset category");
        const auto bit=asset_bit(rule.category);
        require((seen&bit)==0,"Rule asset categories cannot repeat");seen|=bit;
        require(finite(rule.weight)&&rule.weight>0&&rule.weight<=1e6,"Rule weight must be finite, positive and at most one million");
        require(rule.maximum_count<=2000,"Rule maximum count exceeds 2000 per region");
    }
}
Bounds mesh_bounds(const Mesh& mesh) {
    require(!mesh.vertices.empty(),"Asset mesh has no vertices");
    Bounds bounds{mesh.vertices.front(),mesh.vertices.front()};
    for(const auto p:mesh.vertices) {
        require(finite(p),"Asset geometry contains nonfinite or excessive coordinates");
        bounds.min={std::min(bounds.min.x,p.x),std::min(bounds.min.y,p.y),std::min(bounds.min.z,p.z)};
        bounds.max={std::max(bounds.max.x,p.x),std::max(bounds.max.y,p.y),std::max(bounds.max.z,p.z)};
    }
    return bounds;
}
Asset prepare_asset(Asset asset,const AssetLimits& limits) {
    check_limits(limits);
    require(asset.mesh.vertices.size()<=limits.max_vertices_per_asset && asset.mesh.triangles.size()<=limits.max_triangles_per_asset,"Asset mesh exceeds its per-asset budget");
    asset.bounds=mesh_bounds(asset.mesh);
    if(asset.contact_footprint.empty()) asset.contact_footprint=rectangle(asset.bounds,asset.anchor.z);
    validate_asset(asset,limits);
    return asset;
}
void validate_asset(const Asset& asset,const AssetLimits& limits) {
    check_limits(limits);
    require(asset.id!=0,"Asset ID must be nonzero");
    require(!asset.name.empty() && asset.name.size()<=limits.max_name_bytes && valid_utf8(asset.name),"Asset name must be bounded printable UTF-8");
    require(static_cast<unsigned>(asset.category)<static_cast<unsigned>(AssetCategory::Count),"Invalid asset category");
    require(asset.allowed_furniture!=0 && (asset.allowed_furniture&~all_furniture_mask)==0,"Asset furniture eligibility mask is invalid");
    require(!asset.mesh.vertices.empty() && asset.mesh.vertices.size()<=limits.max_vertices_per_asset &&
        !asset.mesh.triangles.empty() && asset.mesh.triangles.size()<=limits.max_triangles_per_asset,"Asset mesh is empty or exceeds its per-asset budget");
    const auto actual=mesh_bounds(asset.mesh);
    require(finite(asset.bounds.min) && finite(asset.bounds.max) && same_distance(actual.min.x,asset.bounds.min.x) && same_distance(actual.min.y,asset.bounds.min.y) && same_distance(actual.min.z,asset.bounds.min.z) &&
        same_distance(actual.max.x,asset.bounds.max.x) && same_distance(actual.max.y,asset.bounds.max.y) && same_distance(actual.max.z,asset.bounds.max.z),"Asset bounds do not match its full geometry");
    require(actual.max.x-actual.min.x>epsilon && actual.max.y-actual.min.y>epsilon && actual.max.z-actual.min.z>epsilon,"Asset geometry must have positive physical width, depth and height");
    bool nondegenerate=false;
    for(const auto face:asset.mesh.triangles) {
        for(const auto index:face.vertices)require(index<asset.mesh.vertices.size(),"Asset triangle index is outside its vertex array");
        const auto a=asset.mesh.vertices[face.vertices[0]],b=asset.mesh.vertices[face.vertices[1]],c=asset.mesh.vertices[face.vertices[2]];
        const Vec3 u{b.x-a.x,b.y-a.y,b.z-a.z},v{c.x-a.x,c.y-a.y,c.z-a.z};
        const Vec3 cross{u.y*v.z-u.z*v.y,u.z*v.x-u.x*v.z,u.x*v.y-u.y*v.x};
        nondegenerate=nondegenerate || (cross.x*cross.x+cross.y*cross.y+cross.z*cross.z>1e-18);
    }
    require(nondegenerate,"Asset mesh contains no nondegenerate triangles");
    require(finite(asset.anchor) && same_distance(asset.anchor.z,actual.min.z),"Asset contact anchor must lie at the mesh base height");
    check_polygon(asset.contact_footprint,asset.anchor.z,actual,limits);
    for(std::size_t i=0;i<asset.contact_footprint.size();++i) {
        const auto a=asset.contact_footprint[i],b=asset.contact_footprint[(i+1)%asset.contact_footprint.size()];
        require((b.x-a.x)*(asset.anchor.y-a.y)-(b.y-a.y)*(asset.anchor.x-a.x)>=-epsilon,"Asset anchor must lie inside its contact footprint");
    }
    require(finite(asset.weight) && asset.weight>0 && asset.weight<=1e6,"Asset weight must be positive, finite and at most one million");
    require(finite(asset.min_scale) && finite(asset.max_scale) && asset.min_scale>=0.01 && asset.max_scale>=asset.min_scale && asset.max_scale<=100,"Asset uniform scale interval must lie within 0.01..100");
    require(!asset.allowed_yaws_degrees.empty() && asset.allowed_yaws_degrees.size()<=limits.max_yaws,"Asset must have a bounded nonempty yaw list");
    for(std::size_t i=0;i<asset.allowed_yaws_degrees.size();++i) {
        const auto yaw=asset.allowed_yaws_degrees[i];
        require(finite(yaw) && yaw>=-360 && yaw<=360,"Asset yaw must be finite and within -360..360 degrees");
        for(std::size_t j=0;j<i;++j)require(std::abs(std::remainder(yaw-asset.allowed_yaws_degrees[j],360.0))>1e-7,"Asset yaw list contains equivalent duplicate angles");
    }
    if(asset.book_row) {
        require(asset.category==AssetCategory::Book,"Only Book assets may carry a book-row profile");
        require(asset.book_row->spine_face<SpineFace::Count,"Asset book-row spine face is invalid");
    }
    require((asset.allowed_on_top&~all_asset_mask)==0,"Asset top eligibility mask is invalid");
    if(asset.stackable) {
        require(finite(asset.stack_height_mm) && asset.stack_height_mm>epsilon && same_distance(asset.anchor.z+asset.stack_height_mm,actual.max.z),"Asset stacking patch must be at the mesh top height");
        require(asset.allowed_on_top!=0,"Stackable asset must allow at least one category on top");
        check_polygon(asset.stack_footprint,asset.anchor.z+asset.stack_height_mm,actual,limits);
    } else require(asset.allowed_on_top==0 && asset.stack_footprint.empty() && asset.stack_height_mm==0,"Non-stackable asset must not contain active stacking metadata");
}
void validate_assets(const std::vector<Asset>& assets,const AssetLimits& limits) {
    check_limits(limits);require(assets.size()<=limits.max_assets,"Asset library exceeds its asset count budget");
    std::unordered_set<std::uint64_t> ids;
    std::size_t vertices=0,faces=0;
    for(const auto& asset:assets) {
        require(ids.insert(asset.id).second,"Asset library contains duplicate stable IDs");
        require(asset.mesh.vertices.size()<=limits.max_total_vertices-vertices && asset.mesh.triangles.size()<=limits.max_total_triangles-faces,"Asset library exceeds its total geometry budget");
        vertices+=asset.mesh.vertices.size();faces+=asset.mesh.triangles.size();validate_asset(asset,limits);
    }
}
std::vector<std::uint8_t> encode_assets(const std::vector<Asset>& assets,const AssetLimits& limits) {
    validate_assets(assets,limits);
    Writer out{{},limits.max_library_bytes};
    out.room(magic.size());out.bytes.insert(out.bytes.end(),magic.begin(),magic.end());
    out.u32(format_version);out.u32(0x01020304u);out.u32(static_cast<std::uint32_t>(assets.size()));
    for(const auto& asset:assets)write_asset(out,asset);
    const auto checksum=crc32(out.bytes);out.u32(checksum);return std::move(out.bytes);
}
std::vector<Asset> decode_assets(std::span<const std::uint8_t> bytes,const AssetLimits& limits) {
    check_limits(limits);require(bytes.size()<=limits.max_library_bytes,"Asset library exceeds its byte budget");
    require(bytes.size()>=24,"Asset library header is truncated");
    require(std::equal(magic.begin(),magic.end(),bytes.begin()),"Unrecognized asset library format");
    Reader trailer{bytes.last(4)};require(trailer.u32()==crc32(bytes.first(bytes.size()-4)),"Asset library checksum mismatch");
    Reader in{bytes.first(bytes.size()-4),8};
    const auto version=in.u32();require(version==1 || version==format_version,"Unsupported asset library version");require(in.u32()==0x01020304u,"Asset library byte order marker is invalid");
    const auto count=in.u32();require(count<=limits.max_assets,"Asset library exceeds its asset count budget");
    std::vector<Asset> assets;assets.reserve(count);std::size_t vertices=0,faces=0;
    for(std::uint32_t i=0;i<count;++i)assets.push_back(read_asset(in,limits,vertices,faces,version));
    require(in.at==in.bytes.size(),"Asset library contains unexpected trailing payload");
    validate_assets(assets,limits);return assets;
}
void save_assets(const std::filesystem::path& path,const std::vector<Asset>& assets,const AssetLimits& limits) {
    require(!path.empty() && path.has_filename(),"Choose an asset library file path");
    const auto bytes=encode_assets(assets,limits);
    std::filesystem::path temporary;
    std::random_device random;
    for(unsigned attempt=0;attempt<16;++attempt) {
        temporary=path;
        temporary+=std::string(".cyrus-tmp-")+std::to_string(random())+"-"+std::to_string(random());
        if(!std::filesystem::exists(temporary))break;
        temporary.clear();
    }
    require(!temporary.empty(),"Cannot reserve an asset library temporary path");
    try {
        std::ofstream out(temporary,std::ios::binary|std::ios::trunc);
        require(static_cast<bool>(out),"Cannot create asset library temporary file");
        out.write(reinterpret_cast<const char*>(bytes.data()),static_cast<std::streamsize>(bytes.size()));out.flush();
        require(static_cast<bool>(out),"Asset library write failed; previous file is retained");out.close();
        require(!out.fail(),"Asset library close failed; previous file is retained");
#ifdef _WIN32
        require(MoveFileExW(temporary.c_str(),path.c_str(),MOVEFILE_REPLACE_EXISTING|MOVEFILE_WRITE_THROUGH)!=0,"Cannot atomically publish asset library; previous file is retained");
#else
        std::filesystem::rename(temporary,path);
#endif
    } catch(...) {
        std::error_code ignored;std::filesystem::remove(temporary,ignored);throw;
    }
}
std::vector<Asset> load_assets(const std::filesystem::path& path,const AssetLimits& limits) {
    check_limits(limits);
    const auto size=std::filesystem::file_size(path);
    require(size<=limits.max_library_bytes,"Asset library file exceeds its byte budget");
    std::ifstream in(path,std::ios::binary);require(static_cast<bool>(in),"Cannot open asset library file");
    std::vector<std::uint8_t> bytes(static_cast<std::size_t>(size));
    in.read(reinterpret_cast<char*>(bytes.data()),static_cast<std::streamsize>(bytes.size()));
    require(static_cast<bool>(in) && in.peek()==std::char_traits<char>::eof(),"Asset library changed or could not be read completely");
    return decode_assets(bytes,limits);
}

std::vector<FurniturePreset> default_furniture_presets() {
    using A=AssetCategory;using F=FurnitureCategory;
    return {
        {F::TVConsole,"TV console",{{A::Book,3,8,true},{A::BookStack,2,3,true},{A::Plant,1,2,false},{A::Candle,1,3,true},{A::Frame,1.5,2,false},{A::Vase,1,2,false},{A::Accessory,1,4,true},{A::Bowl,0.5,1,true},{A::Tray,0.5,1,false}},0.30,35,20},
        {F::OpenShelf,"Open shelf",{{A::Book,4,18,true},{A::BookStack,2,6,true},{A::Plant,1,4,false},{A::Candle,0.5,3,true},{A::Frame,1,4,false},{A::Vase,1,3,false},{A::Accessory,1,6,true},{A::Bowl,0.5,3,true},{A::Tableware,0.3,4,true},{A::Tray,0.3,2,false}},0.45,15,12},
        {F::CoffeeTable,"Coffee table",{{A::Book,1,3,true},{A::BookStack,2,2,true},{A::Plant,0.5,1,false},{A::Candle,1,2,true},{A::Frame,0.2,1,false},{A::Vase,1,1,false},{A::Accessory,0.75,3,true},{A::Bowl,1,1,true},{A::Tableware,1,3,true},{A::Tray,1,1,false}},0.25,45,25},
        {F::KitchenCounter,"Kitchen counter",{{A::Book,0.5,2,true},{A::BookStack,0.3,1,true},{A::Plant,0.5,2,false},{A::Candle,0.2,1,true},{A::Frame,0.2,1,false},{A::Vase,0.3,1,false},{A::Accessory,0.3,2,true},{A::Bowl,1.5,3,true},{A::Tableware,2,6,true},{A::Kitchenware,3,5,false},{A::Tray,1,2,false}},0.25,40,25},
        {F::DiningTable,"Dining table",{{A::Plant,0.5,1,false},{A::Candle,1,3,true},{A::Vase,1,1,false},{A::Accessory,0.5,2,true},{A::Bowl,1,2,true},{A::Tableware,4,12,true},{A::Kitchenware,0.5,2,false},{A::Tray,1,2,false}},0.30,45,25}
    };
}
bool category_allowed(const FurniturePreset& preset,AssetCategory category) {
    return std::any_of(preset.rules.begin(),preset.rules.end(),[category](const auto& rule) { return rule.category==category && rule.weight>0 && rule.maximum_count>0; });
}
}
