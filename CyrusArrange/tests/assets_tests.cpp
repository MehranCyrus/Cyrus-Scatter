#include "cyrus_arrange/assets.h"
#include <algorithm>
#include <cmath>
#include <fstream>
#include <functional>
#include <iostream>
#include <limits>
#include <random>
#include <stdexcept>

using namespace cyrus::arrange;
namespace {
void check(bool value,const char* message) { if(!value)throw std::runtime_error(message); }
void rejects(const std::function<void()>& call) {
    bool failed=false;try { call(); }catch(const std::exception&) { failed=true; }
    check(failed,"Expected asset operation to reject invalid input");
}
Asset example(std::uint64_t id=1) {
    Asset asset;asset.id=id;asset.name="Book \"warm cover\" \xd0\x96";asset.category=AssetCategory::Book;
    asset.mesh.vertices={{-15,-90,0},{15,-90,0},{15,90,0},{-15,90,0},{-15,-90,240},{15,-90,240},{15,90,240},{-15,90,240}};
    asset.mesh.triangles={{{0,2,1}},{{0,3,2}},{{4,5,6}},{{4,6,7}},{{0,1,5}},{{0,5,4}},{{1,2,6}},{{1,6,5}},{{2,3,7}},{{2,7,6}},{{3,0,4}},{{3,4,7}}};
    return prepare_asset(std::move(asset));
}
Asset stack_example(std::uint64_t id=2) {
    auto asset=example(id);asset.name="Flat book stack";asset.category=AssetCategory::BookStack;
    asset.stackable=true;asset.stack_height_mm=240;asset.stack_footprint=asset.contact_footprint;
    for(auto& p:asset.stack_footprint)p.z=240;
    asset.allowed_on_top=asset_bit(AssetCategory::Candle)|asset_bit(AssetCategory::Accessory);
    validate_asset(asset);return asset;
}
void repair_checksum(std::vector<std::uint8_t>& bytes) {
    std::uint32_t value=0xffffffffu;
    for(std::size_t i=0;i<bytes.size()-4;++i) {
        value^=bytes[i];for(unsigned bit=0;bit<8;++bit)value=(value&1)?(value>>1)^0xedb88320u:value>>1;
    }
    value^=0xffffffffu;
    for(unsigned byte=0;byte<4;++byte)bytes[bytes.size()-4+byte]=static_cast<std::uint8_t>(value>>(byte*8));
}
// Fixed independent Python struct/zlib oracles, not produced by encode_assets().
// One tetrahedral Book, id41, anchor(5,5,0), three-point contact, yaws0/90.
// Library2 adds a PositiveY profile tag4 after the complete asset mesh.
std::vector<std::uint8_t> wire_fixture(bool version2) {
    constexpr std::string_view legacy=
        "43594153534554000100000004030201010000002900000000000000090000005769726520426f6f6b000000001f0000"
        "000000000000001440000000000000144000000000000000000000000000000000000000000000000000000000000000"
        "0000000000000034400000000000003e4000000000000049400300000000000000000000000000000000000000000000"
        "000000000000000000000034400000000000000000000000000000000000000000000000000000000000003e40000000"
        "00000000000200000000000000000000000000000000805640000000000000f03f000000000000f03f000000000000f0"
        "3f0000000000000000000000000000000000000000040000000000000000000000000000000000000000000000000000"
        "0000000000000034400000000000000000000000000000000000000000000000000000000000003e4000000000000000"
        "000000000000000000000000000000000000000000000049400400000000000000020000000100000000000000010000"
        "00030000000100000002000000030000000200000000000000030000006bd4cc61";
    constexpr std::string_view current=
        "43594153534554000200000004030201010000002900000000000000090000005769726520426f6f6b000000001f0000"
        "000000000000001440000000000000144000000000000000000000000000000000000000000000000000000000000000"
        "0000000000000034400000000000003e4000000000000049400300000000000000000000000000000000000000000000"
        "000000000000000000000034400000000000000000000000000000000000000000000000000000000000003e40000000"
        "00000000000200000000000000000000000000000000805640000000000000f03f000000000000f03f000000000000f0"
        "3f0000000000000000000000000000000000000000040000000000000000000000000000000000000000000000000000"
        "0000000000000034400000000000000000000000000000000000000000000000000000000000003e4000000000000000"
        "000000000000000000000000000000000000000000000049400400000000000000020000000100000000000000010000"
        "0003000000010000000200000003000000020000000000000003000000040000002c8522eb";
    const auto text=version2?current:legacy;
    const auto nibble=[](char c)->unsigned { return c<='9'?static_cast<unsigned>(c-'0'):static_cast<unsigned>(c-'a'+10); };
    std::vector<std::uint8_t> bytes;bytes.reserve(text.size()/2);
    for(std::size_t i=0;i<text.size();i+=2)bytes.push_back(static_cast<std::uint8_t>((nibble(text[i])<<4)|nibble(text[i+1])));
    return bytes;
}
void write_u32(std::vector<std::uint8_t>& bytes,std::size_t at,std::uint32_t value) {
    check(at+4<=bytes.size(),"Test wire offset is in bounds");
    for(unsigned byte=0;byte<4;++byte)bytes[at+byte]=static_cast<std::uint8_t>(value>>(byte*8));
}
void book_row_metadata() {
    check(!example().book_row,"Book-row eligibility must not be inferred from an upright Book's shape/name");
    auto asset=example();asset.book_row=BookRowProfile{};
    check(asset.book_row->spine_face==SpineFace::PositiveY,"Explicit profile defaults to positive Y spine");
    asset=prepare_asset(asset);
    check(asset.book_row && asset.book_row->spine_face==SpineFace::PositiveY,"Prepare preserves explicit book-row metadata");
    for(unsigned face=0;face<4;++face) {
        asset.book_row=BookRowProfile{static_cast<SpineFace>(face)};validate_asset(asset);
    }
    for(unsigned category=1;category<static_cast<unsigned>(AssetCategory::Count);++category) {
        auto non_book=asset;non_book.category=static_cast<AssetCategory>(category);rejects([&]{validate_asset(non_book);});
    }
    asset.book_row=BookRowProfile{SpineFace::Count};rejects([&]{prepare_asset(asset);});
    asset.book_row=BookRowProfile{static_cast<SpineFace>(0xffffffffu)};rejects([&]{validate_asset(asset);});
    asset=example();asset.book_row=BookRowProfile{};
    for(auto& p:asset.mesh.vertices)p.z*=0.05;
    validate_asset(prepare_asset(asset)); // No metadata-layer upright/flat guessing; fit is the solver's responsibility.
}
void independent_library_versions() {
    const auto legacy=wire_fixture(false),current=wire_fixture(true);
    check(legacy.size()==417 && current.size()==421,"Independent wire fixture lengths are fixed");
    const auto old=decode_assets(legacy),loaded=decode_assets(current);
    check(old.size()==1 && old[0].id==41 && old[0].name=="Wire Book" && !old[0].book_row,"Library1 explicitly decodes with absent row profile");
    check(loaded.size()==1 && loaded[0].book_row && loaded[0].book_row->spine_face==SpineFace::PositiveY,"Independent library2 decodes its positive-Y tag");
    Asset expected;expected.id=41;expected.name="Wire Book";expected.category=AssetCategory::Book;
    expected.anchor={5,5,0};expected.bounds={{0,0,0},{20,30,50}};expected.allowed_yaws_degrees={0,90};
    expected.mesh.vertices={{0,0,0},{20,0,0},{0,30,0},{0,0,50}};
    expected.mesh.triangles={{{0,2,1}},{{0,1,3}},{{1,2,3}},{{2,0,3}}};
    expected.contact_footprint={expected.mesh.vertices[0],expected.mesh.vertices[1],expected.mesh.vertices[2]};expected.book_row=BookRowProfile{};
    check(encode_assets({expected})==current,"Writer2 exactly matches independent fixed field-order/CRC bytes");
    auto absent=current;write_u32(absent,absent.size()-8,0);repair_checksum(absent);
    check(encode_assets(old)==absent,"Library1 upgrades to version2 with explicit absent tag, without guessing");
    for(std::uint32_t tag=0;tag<=4;++tag) {
        auto bytes=current;write_u32(bytes,bytes.size()-8,tag);repair_checksum(bytes);
        const auto profile=decode_assets(bytes)[0].book_row;
        check(tag==0?!profile:(profile && static_cast<std::uint32_t>(profile->spine_face)==tag-1),"Every valid explicit wire tag decodes exactly");
    }
    auto second=example(99);const auto mixed=decode_assets(encode_assets({expected,second}));
    check(mixed.size()==2 && mixed[0].book_row && !mixed[1].book_row && mixed[1].id==99,"Per-asset profile tail cannot bleed into the next asset record");
}
void book_row_wire_rejections() {
    const auto current=wire_fixture(true),legacy=wire_fixture(false);
    for(const auto tag:{5u,255u,0xffffffffu}) {
        auto bytes=current;write_u32(bytes,bytes.size()-8,tag);repair_checksum(bytes);rejects([&]{decode_assets(bytes);});
    }
    auto bytes=current;write_u32(bytes,41,static_cast<unsigned>(AssetCategory::Plant));repair_checksum(bytes);rejects([&]{decode_assets(bytes);});
    for(const auto version:{0u,3u,0xffffffffu}) {
        bytes=current;write_u32(bytes,8,version);repair_checksum(bytes);rejects([&]{decode_assets(bytes);});
    }
    bytes=current;write_u32(bytes,8,1);repair_checksum(bytes);rejects([&]{decode_assets(bytes);}); // V1 cannot consume V2's extra tail.
    bytes=legacy;write_u32(bytes,8,2);repair_checksum(bytes);rejects([&]{decode_assets(bytes);}); // V2 requires the tail.
    for(std::size_t cut=1;cut<=4;++cut) {
        bytes=current;bytes.erase(bytes.end()-4-cut,bytes.end()-4);repair_checksum(bytes);rejects([&]{decode_assets(bytes);});
    }
    bytes=current;bytes[bytes.size()-8]^=1;rejects([&]{decode_assets(bytes);}); // Profile metadata is protected by the library checksum.
    for(const auto* fixture:{&legacy,&current}) {
        AssetLimits limits;limits.max_assets=0;rejects([&]{decode_assets(*fixture,limits);});
        limits=AssetLimits{};limits.max_total_triangles=3;rejects([&]{decode_assets(*fixture,limits);});
        limits=AssetLimits{};limits.max_vertices_per_asset=3;rejects([&]{decode_assets(*fixture,limits);});
    }
    AssetLimits limits;limits.max_library_bytes=legacy.size();
    check(decode_assets(legacy,limits).size()==1,"Version1 admits exactly its configured byte boundary");
    rejects([&]{decode_assets(current,limits);});
    limits.max_library_bytes=current.size();check(decode_assets(current,limits).size()==1,"Version2 admits its own exact byte boundary including profile tag");
}
void model_and_names() {
    const auto asset=example();check(asset.bounds.max.z==240 && asset.contact_footprint.size()==4,"Prepare must derive geometry bounds and conservative contact patch");
    check(asset_category_name(AssetCategory::BookStack)=="Book stack","Asset category label");
    check(furniture_category_name(FurnitureCategory::KitchenCounter)=="Kitchen counter","Furniture category label");
    check(furniture_bit(FurnitureCategory::Count)==0 && asset_bit(AssetCategory::Count)==0,"Sentinel categories cannot become eligibility bits");
    check(infer_asset_category("LIVING_BookStack_Horizontal")==AssetCategory::BookStack,"Compound asset tag inference");
    check(infer_asset_category("my_potted_fern_01")==AssetCategory::Plant,"Plant name inference");
    check(infer_asset_category("unknown model")==std::nullopt,"Unknown names require authored metadata");
    check(infer_asset_category(std::string(5000,'x'))==std::nullopt,"Inference bounds oversized text");
    check(infer_furniture_category("Living_TV_Set_A")==FurnitureCategory::TVConsole,"TV naming inference");
    check(infer_furniture_category("Library_bookshelf")==FurnitureCategory::OpenShelf,"Shelf naming inference");
    check(infer_furniture_category("diningTable")==FurnitureCategory::DiningTable,"Dining table tag inference");
    check(infer_furniture_category("table")==std::nullopt,"Ambiguous table requires manual category");
    check(infer_furniture_category("TV_set_open_shelf")==std::nullopt,"Conflicting furniture categories cannot silently choose the first match");
    check(infer_furniture_category("TV_console_media_console_TV_stand")==FurnitureCategory::TVConsole,"Multiple aliases for one category remain unambiguous");
    check(infer_furniture_category("coffeetable_diningtable")==std::nullopt,"Conflicting table kinds require an explicit category");
}
void category_rules() {
    validate_category_rules({});
    std::vector<CategoryRule> rules{{AssetCategory::Book,1,0,true},{AssetCategory::Plant,2.5,2000,false}};
    validate_category_rules(rules);
    rules.push_back(rules.front());rejects([&]{validate_category_rules(rules);});rules.pop_back();
    rules[0].category=AssetCategory::Count;rejects([&]{validate_category_rules(rules);});rules[0].category=AssetCategory::Book;
    rules[0].weight=0;rejects([&]{validate_category_rules(rules);});
    rules[0].weight=std::numeric_limits<double>::quiet_NaN();rejects([&]{validate_category_rules(rules);});
    rules[0].weight=1000001;rejects([&]{validate_category_rules(rules);});rules[0].weight=1;
    rules[0].maximum_count=2001;rejects([&]{validate_category_rules(rules);});
    rules.assign(12,CategoryRule{});rejects([&]{validate_category_rules(rules);});
}
void metadata_rejections() {
    auto asset=example();asset.id=0;rejects([&]{validate_asset(asset);});
    asset=example();asset.name="";rejects([&]{validate_asset(asset);});
    asset=example();asset.name=std::string("bad\0name",8);rejects([&]{validate_asset(asset);});
    asset=example();asset.name="\xc0\xaf";rejects([&]{validate_asset(asset);});
    asset=example();asset.category=static_cast<AssetCategory>(999);rejects([&]{validate_asset(asset);});
    asset=example();asset.allowed_furniture=0;rejects([&]{validate_asset(asset);});
    asset=example();asset.allowed_furniture=1u<<31;rejects([&]{validate_asset(asset);});
    asset=example();asset.weight=0;rejects([&]{validate_asset(asset);});
    asset=example();asset.weight=std::numeric_limits<double>::quiet_NaN();rejects([&]{validate_asset(asset);});
    asset=example();asset.min_scale=2;asset.max_scale=1;rejects([&]{validate_asset(asset);});
    asset=example();asset.allowed_yaws_degrees={0,360};rejects([&]{validate_asset(asset);});
    asset=example();asset.allowed_yaws_degrees={};rejects([&]{validate_asset(asset);});
    asset=example();asset.allowed_yaws_degrees={std::numeric_limits<double>::infinity()};rejects([&]{validate_asset(asset);});
    asset=example();asset.anchor.z=5;rejects([&]{validate_asset(asset);});
    asset=example();asset.anchor.x=100;rejects([&]{validate_asset(asset);});
}
void geometry_rejections() {
    auto asset=example();asset.mesh.vertices[0].x=std::numeric_limits<double>::infinity();rejects([&]{prepare_asset(asset);});
    asset=example();asset.mesh.triangles[0].vertices[0]=999;rejects([&]{validate_asset(asset);});
    asset=example();asset.mesh.triangles.clear();rejects([&]{validate_asset(asset);});
    asset=example();asset.bounds.max.z=241;rejects([&]{validate_asset(asset);});
    asset=example();std::reverse(asset.contact_footprint.begin(),asset.contact_footprint.end());rejects([&]{validate_asset(asset);});
    asset=example();asset.contact_footprint[1].x=0;asset.contact_footprint[1].y=0;rejects([&]{validate_asset(asset);});
    asset=example();asset.contact_footprint[0].z=1;rejects([&]{validate_asset(asset);});
    asset=example();asset.contact_footprint[0].x=-20;rejects([&]{validate_asset(asset);});
}
void stack_rejections() {
    auto asset=stack_example();validate_asset(asset);
    asset.stack_height_mm=200;rejects([&]{validate_asset(asset);});
    asset=stack_example();asset.allowed_on_top=0;rejects([&]{validate_asset(asset);});
    asset=stack_example();asset.stack_footprint.clear();rejects([&]{validate_asset(asset);});
    asset=stack_example();asset.stackable=false;rejects([&]{validate_asset(asset);});
    asset=example();asset.allowed_on_top=1;rejects([&]{validate_asset(asset);});
}
void roundtrip() {
    std::vector<Asset> assets{example(),stack_example()};
    assets[0].allowed_furniture=furniture_bit(FurnitureCategory::TVConsole)|furniture_bit(FurnitureCategory::OpenShelf);
    assets[0].allowed_yaws_degrees={-25,0,35};assets[0].weight=2.5;assets[0].min_scale=.8;assets[0].max_scale=1.1;
    const auto bytes=encode_assets(assets);const auto loaded=decode_assets(bytes);
    check(loaded.size()==2 && loaded[0].name==assets[0].name && loaded[0].id==1 && loaded[1].id==2,"Identity/Unicode library roundtrip");
    check(loaded[0].mesh.vertices.size()==8 && loaded[0].mesh.triangles.size()==12,"Full geometry is stored in reusable libraries");
    check(loaded[1].stackable && loaded[1].stack_height_mm==240 && loaded[1].allowed_on_top==assets[1].allowed_on_top,"Stack metadata roundtrip");
    check(encode_assets(loaded)==bytes,"Library serialization must be deterministic and lossless");
    check(decode_assets(encode_assets({})).empty(),"Empty library roundtrip");
    std::vector<Asset> categories;
    for(unsigned i=0;i<static_cast<unsigned>(AssetCategory::Count);++i) { auto a=example(i+1);a.category=static_cast<AssetCategory>(i);categories.push_back(std::move(a)); }
    check(decode_assets(encode_assets(categories)).size()==categories.size(),"Every supported category roundtrips");
}
void malformed_payloads() {
    const auto bytes=encode_assets({example()});
    for(std::size_t n=0;n<bytes.size();++n)rejects([&]{decode_assets(std::span(bytes.data(),n));});
    auto damaged=bytes;damaged[damaged.size()/2]^=0x80;rejects([&]{decode_assets(damaged);});
    damaged=bytes;damaged[8]=3;repair_checksum(damaged);rejects([&]{decode_assets(damaged);});
    damaged=bytes;for(unsigned i=16;i<20;++i)damaged[i]=0xff;repair_checksum(damaged);rejects([&]{decode_assets(damaged);});
    damaged=bytes;for(unsigned i=28;i<32;++i)damaged[i]=0xff;repair_checksum(damaged);rejects([&]{decode_assets(damaged);});
    damaged=bytes;damaged.insert(damaged.end()-4,0);repair_checksum(damaged);rejects([&]{decode_assets(damaged);});
}
void limits_and_duplicates() {
    rejects([]{validate_assets({example(),example()});});
    AssetLimits limits;limits.max_assets=1;rejects([&]{encode_assets({example(),example(2)},limits);});
    limits=AssetLimits{};limits.max_total_vertices=7;rejects([&]{encode_assets({example()},limits);});
    limits=AssetLimits{};limits.max_vertices_per_asset=7;rejects([&]{prepare_asset(example(),limits);});
    limits=AssetLimits{};limits.max_library_bytes=100;rejects([&]{encode_assets({example()},limits);});
    limits=AssetLimits{};limits.max_library_bytes=256u*1024u*1024u;rejects([&]{encode_assets({},limits);});
    const auto bytes=encode_assets({example()});limits=AssetLimits{};limits.max_total_triangles=11;rejects([&]{decode_assets(bytes,limits);});
    limits=AssetLimits{};limits.max_name_bytes=3;rejects([&]{decode_assets(bytes,limits);});
}
void file_publication() {
    std::random_device random;
    const auto folder=std::filesystem::current_path()/("asset-tests-"+std::to_string(random()));
    check(std::filesystem::create_directory(folder),"Create private asset test folder");
    const auto path=folder/std::filesystem::path(L"library-\u0416.cyalib");
    save_assets(path,{example()});check(load_assets(path)[0].id==1,"Native library file roundtrip");
    save_assets(path,{example(7)});check(load_assets(path)[0].id==7,"Atomic native library overwrite");
    auto invalid=example();invalid.weight=-1;rejects([&]{save_assets(path,{invalid});});
    check(load_assets(path)[0].id==7,"Failed successor retains previous library file");
    const auto blocked=folder/"directory-target";std::filesystem::create_directory(blocked);
    rejects([&]{save_assets(blocked,{example()});});check(std::filesystem::is_directory(blocked),"Failed publication preserves existing directory");
    std::size_t entries=0;for(const auto& entry:std::filesystem::directory_iterator(folder)) { (void)entry;++entries; }
    check(entries==2,"Failed publication cleans its owned temporary file");
    std::filesystem::remove(path);std::filesystem::remove(blocked);std::filesystem::remove(folder);
}
void native_presets() {
    const auto presets=default_furniture_presets();check(presets.size()==static_cast<unsigned>(FurnitureCategory::Count),"Native preset for every supported furniture category");
    for(unsigned i=0;i<presets.size();++i) {
        const auto& p=presets[i];check(static_cast<unsigned>(p.furniture)==i && !p.name.empty() && !p.rules.empty(),"Ordered named category presets");
        check(p.occupancy_target>0 && p.occupancy_target<1 && p.front_edge_margin_mm>0 && p.lateral_gap_mm>0,"Physical preset controls");
        std::uint32_t seen=0;
        for(const auto& rule:p.rules) { check((seen&asset_bit(rule.category))==0,"Preset categories cannot repeat");seen|=asset_bit(rule.category);check(rule.weight>0 && rule.maximum_count>0,"Preset eligibility and quantity rules"); }
    }
    check(category_allowed(presets[0],AssetCategory::Book),"TV console permits books");
    check(!category_allowed(presets[0],AssetCategory::Kitchenware),"TV console excludes kitchenware by default");
    check(category_allowed(presets[3],AssetCategory::Kitchenware),"Counter permits kitchenware");
    check(!category_allowed(presets[4],AssetCategory::Book),"Dining table default preserves table function");
}
}
int main() {
    const std::pair<const char*,void(*)()> suites[]{
        {"model_and_names",model_and_names},{"metadata_rejections",metadata_rejections},{"geometry_rejections",geometry_rejections},
        {"stack_rejections",stack_rejections},{"roundtrip",roundtrip},{"malformed_payloads",malformed_payloads},
        {"limits_and_duplicates",limits_and_duplicates},{"file_publication",file_publication},{"native_presets",native_presets},{"category_rules",category_rules},
        {"book_row_metadata",book_row_metadata},{"independent_library_versions",independent_library_versions},{"book_row_wire_rejections",book_row_wire_rejections}
    };
    try { for(const auto& [name,test]:suites) { test();std::cout<<"PASS "<<name<<'\n'; } }
    catch(const std::exception& error) { std::cerr<<"FAIL "<<error.what()<<'\n';return 1; }
    std::cout<<"SUCCESS "<<std::size(suites)<<" asset suites\n";
}
