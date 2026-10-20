#include "cyrus_arrange/document_state.h"
#include <algorithm>
#include <bit>
#include <cmath>
#include <functional>
#include <iostream>
#include <limits>
#include <stdexcept>
#include <utility>

using namespace cyrus::arrange;
using namespace cyrus::arrange::host;
namespace {
void check(bool condition,const char* message) {if(!condition)throw std::runtime_error(message);}
void rejects(const std::function<void()>& action) {
    bool failed=false;try{action();}catch(const std::exception&){failed=true;}
    check(failed,"Expected bounded state operation to reject malformed input");
}
void put32(std::vector<std::uint8_t>& bytes,std::size_t at,std::uint32_t value) {
    check(at+4<=bytes.size(),"Test offset exceeds fixture");
    for(unsigned n=0;n<4;++n)bytes[at+n]=static_cast<std::uint8_t>(value>>(8*n));
}
void put64(std::vector<std::uint8_t>& bytes,std::size_t at,std::uint64_t value) {
    check(at+8<=bytes.size(),"Test offset exceeds fixture");
    for(unsigned n=0;n<8;++n)bytes[at+n]=static_cast<std::uint8_t>(value>>(8*n));
}
void put_real(std::vector<std::uint8_t>& bytes,std::size_t at,double value) {put64(bytes,at,std::bit_cast<std::uint64_t>(value));}
std::uint32_t crc32(const std::vector<std::uint8_t>& bytes) {
    std::uint32_t value=0xffffffffu;
    for(const auto byte:bytes){value^=byte;for(unsigned bit=0;bit<8;++bit)value=(value&1)?(value>>1)^0xedb88320u:value>>1;}
    return value^0xffffffffu;
}
// Independent released-format writer: deliberately does not call the new
// document/asset encoder, so changing both new paths cannot redefine schema 3.
struct LegacyWriter {
    std::vector<std::uint8_t> bytes;
    void u8(std::uint8_t v){bytes.push_back(v);}
    void u32(std::uint32_t v){for(unsigned i=0;i<4;++i)u8(static_cast<std::uint8_t>(v>>(8*i)));}
    void u64(std::uint64_t v){for(unsigned i=0;i<8;++i)u8(static_cast<std::uint8_t>(v>>(8*i)));}
    void real(double v){u64(std::bit_cast<std::uint64_t>(v));}
    void point(Vec3 v){real(v.x);real(v.y);real(v.z);}
    void text(const std::string& v){u32(static_cast<std::uint32_t>(v.size()));bytes.insert(bytes.end(),v.begin(),v.end());}
    void points(const std::vector<Vec3>& v){u32(static_cast<std::uint32_t>(v.size()));for(auto p:v)point(p);}
    void blob(const std::vector<std::uint8_t>& v){u64(v.size());bytes.insert(bytes.end(),v.begin(),v.end());}
};
std::vector<std::uint8_t> legacy_assets(const DocumentState& state) {
    LegacyWriter out;out.bytes={'C','Y','A','S','S','E','T',0};out.u32(1);out.u32(0x01020304);
    out.u32(static_cast<std::uint32_t>(state.assets.size()));
    for(const auto& a:state.assets.read()) {
        out.u64(a.id);out.text(a.name);out.u32(static_cast<std::uint32_t>(a.category));out.u32(a.allowed_furniture);
        out.point(a.anchor);out.point(a.bounds.min);out.point(a.bounds.max);out.points(a.contact_footprint);
        out.u32(static_cast<std::uint32_t>(a.allowed_yaws_degrees.size()));for(auto yaw:a.allowed_yaws_degrees)out.real(yaw);
        out.real(a.weight);out.real(a.min_scale);out.real(a.max_scale);out.u32(a.stackable?1u:0u);
        out.real(a.stack_height_mm);out.points(a.stack_footprint);out.u32(a.allowed_on_top);out.points(a.mesh.vertices);
        out.u32(static_cast<std::uint32_t>(a.mesh.triangles.size()));for(auto t:a.mesh.triangles)for(auto v:t.vertices)out.u32(v);
    }
    const auto checksum=crc32(out.bytes);out.u32(checksum);return std::move(out.bytes);
}
std::vector<std::uint8_t> legacy_document(const DocumentState& state,std::uint64_t high_water) {
    LegacyWriter out;out.u32(0x43415244);out.u32(3);out.text(state.document_id);out.text(state.label);
    out.u64(state.revision);out.u64(state.next_id);out.u64(high_water);out.u8(state.live);
    const auto& i=state.inspection;out.real(i.cell_size_mm);out.real(i.minimum_clearance_mm);out.real(i.maximum_slope_degrees);out.real(i.height_tolerance_mm);
    out.u64(i.max_triangles);out.u64(i.max_cells);out.u64(i.max_regions);out.u64(i.max_work);
    const auto& a=state.arrangement;out.u64(a.seed);out.real(a.density);out.real(a.spacing_mm);out.real(a.edge_clearance_mm);
    out.real(a.cluster_strength);out.real(a.height_variation);out.real(a.empty_space);out.u32(static_cast<std::uint32_t>(a.style));out.u32(static_cast<std::uint32_t>(a.category));
    out.u64(a.max_placements);out.u64(a.max_candidates);out.u64(a.max_stack_depth);out.u64(a.max_work);
    out.point(state.frame_origin_mm);out.u64(state.furniture_count);out.u32(static_cast<std::uint32_t>(state.capture_time));out.real(state.captured_mm_per_system_unit);
    out.u64(state.obstacle_count);out.u8(state.require_front_access);out.u64(0);out.blob(legacy_assets(state));
    out.u64(state.asset_capture.size());for(auto p:state.asset_capture){out.u8(p.source_required);out.u8(p.authored_contact);out.u8(p.authored_stack);}
    for(const auto& rules:state.category_rules){out.u64(rules.size());for(auto r:rules){out.u32(static_cast<std::uint32_t>(r.category));out.real(r.weight);out.u32(r.maximum_count);out.u8(r.allow_on_stack);}}
    out.u64(state.furniture_source_keys.size());for(auto key:state.furniture_source_keys)out.u64(key);
    out.blob(encode_region_registry(*state.regions));out.u64(state.placements.size());
    for(auto p:state.placements){out.u64(p.stable_id);out.u64(p.asset_id);out.u64(p.parent_stack_id);out.u32(p.region_id);out.point(p.position);out.real(p.yaw_degrees);out.real(p.scale);out.u8(p.locked);}
    return std::move(out.bytes);
}
Asset book() {
    Asset a;a.id=11;a.name="Original upright book";a.category=AssetCategory::Book;
    a.mesh.vertices={{-15,-50,0},{15,-50,0},{15,50,0},{-15,50,0},{-15,-50,200},{15,-50,200},{15,50,200},{-15,50,200}};
    a.mesh.triangles={{{0,2,1}},{{0,3,2}},{{4,5,6}},{{4,6,7}},{{0,1,5}},{{0,5,4}},{{1,2,6}},{{1,6,5}},{{2,3,7}},{{2,7,6}},{{3,0,4}},{{3,4,7}}};
    return prepare_asset(std::move(a));
}
DocumentState example() {
    DocumentState state;state.document_id="{01234567-89ab-cdef-0123-456789abcdef}";
    state.label="Saved setup \"warm\" \xd0\x96";state.revision=17;state.next_id=23;state.live=true;
    state.inspection={37,123.5,3.5,0.25,333333,222222,1234,44444444};
    state.arrangement={0xfedcba9876543210ULL,0.37,13,7,0.23,0.11,0.19,ArrangeStyle::Layered,FurnitureCategory::OpenShelf,777,88888,3,33333333};
    state.assets.push_back(book());state.asset_capture.push_back({true,true,false});
    state.furniture_count=1;state.furniture_source_keys={19};state.obstacle_count=2;state.require_front_access=false;
    state.frame_origin_mm={10000,-20000,300};state.capture_time=-123;state.captured_mm_per_system_unit=10;
    state.placements={{1001,11,0,7,{0,0,500},0,1,true},{1002,11,0,7,{33,0,500},0,1,false}};
    return state;
}
DocumentState row_example() {
    auto state=example();state.composition={true,2,6,3,0.75};
    state.assets[0].book_row=BookRowProfile{SpineFace::NegativeY};
    state.composition_groups={{std::numeric_limits<std::uint64_t>::max(),CompositionKind::BookRow,7,{1001,1002},{0,-1,0},3}};
    return state;
}
void same_old_fields(const DocumentState& a,const DocumentState& b) {
    check(legacy_document(a,50)==legacy_document(b,50),"Complete released-format field oracle changed");
    check(a.document_id==b.document_id&&a.label==b.label&&a.revision==b.revision&&a.next_id==b.next_id&&a.live==b.live,"Released document identity/revision/live changed");
    check(a.capture_time==b.capture_time&&a.captured_mm_per_system_unit==b.captured_mm_per_system_unit,"Released time/unit representation changed");
    check(a.furniture_count==b.furniture_count&&a.obstacle_count==b.obstacle_count&&a.require_front_access==b.require_front_access&&a.furniture_source_keys==b.furniture_source_keys,"Released source/obstacle identities changed");
    check(a.frame_origin_mm.x==b.frame_origin_mm.x&&a.frame_origin_mm.y==b.frame_origin_mm.y&&a.frame_origin_mm.z==b.frame_origin_mm.z,"Released frame changed");
    check(a.arrangement.seed==b.arrangement.seed&&a.arrangement.density==b.arrangement.density&&a.arrangement.category==b.arrangement.category,"Released settings changed");
    check(a.assets.size()==b.assets.size()&&legacy_assets(a)==legacy_assets(b),"Released asset metadata/geometry changed");
    check(a.asset_capture.size()==b.asset_capture.size()&&a.asset_capture[0].source_required==b.asset_capture[0].source_required&&a.asset_capture[0].authored_contact==b.asset_capture[0].authored_contact&&a.asset_capture[0].authored_stack==b.asset_capture[0].authored_stack,"Released source provenance changed");
    check(a.placements.size()==b.placements.size(),"Released placement count changed");
    for(std::size_t n=0;n<a.placements.size();++n){const auto& x=a.placements[n];const auto& y=b.placements[n];check(x.stable_id==y.stable_id&&x.asset_id==y.asset_id&&x.parent_stack_id==y.parent_stack_id&&x.region_id==y.region_id&&x.position.x==y.position.x&&x.position.y==y.position.y&&x.position.z==y.position.z&&x.yaw_degrees==y.yaw_degrees&&x.scale==y.scale&&x.locked==y.locked,"Released placement identity/pose/lock changed");}
    check(encode_region_registry(*a.regions)==encode_region_registry(*b.regions),"Released registry changed");
    for(std::size_t c=0;c<a.category_rules.size();++c){check(a.category_rules[c].size()==b.category_rules[c].size(),"Released category count changed");for(std::size_t n=0;n<a.category_rules[c].size();++n){const auto x=a.category_rules[c][n],y=b.category_rules[c][n];check(x.category==y.category&&x.weight==y.weight&&x.maximum_count==y.maximum_count&&x.allow_on_stack==y.allow_on_stack,"Released category rule changed");}}
}
void legacy_migration_defaults() {
    const auto original=example();const auto bytes=legacy_document(original,50);const auto preserved=bytes;
    std::uint64_t high=999;const auto decoded=decode_document_state(bytes,high);same_old_fields(original,*decoded);
    check(high==50&&bytes==preserved,"Legacy read changed its bytes or high-water semantics");
    const auto& options=decoded->composition;
    check(!options.book_rows&&options.minimum_books==2&&options.maximum_books==6&&options.row_gap_mm==3&&options.row_height_balance==0&&decoded->composition_groups.empty(),"Schema 3 composition defaults are not disabled/empty");
    check(!decoded->assets.read()[0].book_row,"Schema 3 asset acquired inferred upright eligibility");
    const auto current=encode_document_state(*decoded,high);check(current[4]==7&&current[5]==0,"Successor encoder must write schema 7");
    auto again=decode_document_state(current,high);same_old_fields(original,*again);
    check(again->composition_groups.empty()&&!again->composition.book_rows,"Reopened migrated state enabled composition");
}
void current_round_trip() {
    const auto state=row_example();const auto bytes=encode_document_state(state,50);std::uint64_t high=0;
    const auto decoded=decode_document_state(bytes,high);same_old_fields(state,*decoded);
    check(high==50,"Hashed group identity must not exhaust monotonic asset/source allocator");
    check(decoded->composition.book_rows&&decoded->composition.row_height_balance==0.75&&decoded->composition_groups.size()==1,"Composition settings/group lost");
    const auto& group=decoded->composition_groups.front();
    check(group.member_ids==std::vector<std::uint64_t>({1001,1002})&&group.stable_id==std::numeric_limits<std::uint64_t>::max()&&group.region_id==7&&group.front_direction.y==-1&&group.gap_mm==3,"Ordered composition record changed");
    check(decoded->assets.read()[0].book_row&&decoded->assets.read()[0].book_row->spine_face==SpineFace::NegativeY,"Embedded library2 profile lost");
    check(encode_document_state(*decoded,high)==bytes,"Current codec roundtrip is not byte-deterministic");
}
void truncation_and_versions() {
    const auto current=encode_document_state(row_example(),50),legacy=legacy_document(example(),50);
    for(const auto* fixture:{&current,&legacy})for(std::size_t n=0;n<fixture->size();++n){std::vector<std::uint8_t> partial(fixture->begin(),fixture->begin()+n);std::uint64_t high=777;rejects([&]{decode_document_state(partial,high);});check(high==777,"Truncated decode changed high-water output");}
    for(auto version:{0u,1u,2u,8u,0xffffffffu}){auto wrong=current;put32(wrong,4,version);std::uint64_t high=777;rejects([&]{decode_document_state(wrong,high);});check(high==777,"Unknown version changed high-water");}
    auto trailing=current;trailing.push_back(0);std::uint64_t high=777;rejects([&]{decode_document_state(trailing,high);});check(high==777,"Trailing bytes changed high-water");
    auto relabelled=current;put32(relabelled,4,3);rejects([&]{decode_document_state(relabelled,high);});
}
void malformed_composition_wire() {
    const auto good=encode_document_state(row_example(),50);const auto offset=good.size()-105-39;
    auto bad=good;bad[offset]=2;
    auto reject_wire=[&](const auto& bytes){std::uint64_t high=777;rejects([&]{decode_document_state(bytes,high);});check(high==777,"Malformed composition changed high-water");};
    reject_wire(bad);
    bad=good;put32(bad,offset+1,1);reject_wire(bad);
    bad=good;put32(bad,offset+5,7);reject_wire(bad);
    bad=good;put64(bad,offset+25,5001);reject_wire(bad);
    bad=good;put32(bad,offset+41,1);reject_wire(bad);
    bad=good;put32(bad,offset+45,8);reject_wire(bad);
    bad=good;put64(bad,offset+49,7);reject_wire(bad);
    bad=good;put64(bad,offset+49,1);reject_wire(bad);
    bad=good;put64(bad,offset+65,1001);reject_wire(bad);
    bad=good;put64(bad,offset+65,9999);reject_wire(bad);
    bad=good;put_real(bad,offset+73,std::numeric_limits<double>::quiet_NaN());reject_wire(bad);
    bad=good;put_real(bad,offset+81,0);reject_wire(bad);
    bad=good;put_real(bad,offset+97,-1);reject_wire(bad);
}
void structural_and_pending_edits() {
    auto state=row_example();state.composition.book_rows=false;state.composition.row_height_balance=0;
    state.assets[0].book_row.reset();state.assets[0].category=AssetCategory::Accessory;
    check(state.regions->records.empty(),"Pending fixture must omit current region");
    // Valid old membership remains serializable while authored edits are pending.
    const auto bytes=encode_document_state(state,50);std::uint64_t high=0;auto restored=decode_document_state(bytes,high);
    check(restored->composition_groups.size()==1,"Unprotected pending metadata must not erase old relationship");
    auto duplicate=state;duplicate.composition_groups.push_back(duplicate.composition_groups[0]);rejects([&]{encode_document_state(duplicate,50);});
    auto stack=state;stack.placements[1].parent_stack_id=1001;rejects([&]{encode_document_state(stack,50);});
    auto child=state;child.placements.push_back({1003,11,1001,7,{0,0,700},0,1,false});rejects([&]{encode_document_state(child,50);});
    auto wrong_region=state;wrong_region.placements[1].region_id=8;rejects([&]{encode_document_state(wrong_region,50);});
}
void high_water_failure_atomicity() {
    for(bool source_failure:{false,true}) {
        auto state=example();
        if(source_failure)state.furniture_source_keys[0]=std::numeric_limits<std::uint64_t>::max();
        else {state.assets[0].id=std::numeric_limits<std::uint64_t>::max();for(auto& p:state.placements)p.asset_id=state.assets.read()[0].id;}
        auto bytes=encode_document_state(state,50);std::uint64_t high=777;
        rejects([&]{decode_document_state(bytes,high);});check(high==777,"Late identity failure partially changed high-water output");
    }
    auto state=example();state.next_id=70;std::uint64_t high=0;decode_document_state(encode_document_state(state,50),high);check(high==70,"Next authored allocator ID must raise decoded high-water");
    state=example();state.furniture_source_keys[0]=80;decode_document_state(encode_document_state(state,50),high);check(high==81,"Source identity must raise decoded high-water");
}
void utf8_preserves_released_semantics() {
    auto state=example();state.label="Setup \xd0\x96 \xf0\x9f\x93\x9a\n\t\x7f \xf4\x8f\xbf\xbf";
    std::uint64_t high=0;const auto decoded=decode_document_state(legacy_document(state,50),high);check(decoded->label==state.label,"Portable validator narrowed valid released UTF8/control labels");
    for(const std::string label:std::vector<std::string>{"\xc0\xaf","\xed\xa0\x80","\xf4\x90\x80\x80","\x80","\xe2\x82","\xf5\x80\x80\x80",std::string("bad\0label",9)}){state.label=label;rejects([&]{validate_document_state(state);});const auto bytes=legacy_document(state,50);high=777;rejects([&]{decode_document_state(bytes,high);});check(high==777,"Invalid UTF8 altered high-water");}
}
void immutable_state_sharing() {
    const auto original=std::make_shared<const DocumentState>(example());auto successor=std::make_shared<DocumentState>(*original);
    const auto* mesh=original->assets.read()[0].mesh.vertices.data();successor->composition.book_rows=true;successor->composition_groups={{99,CompositionKind::BookRow,7,{1001,1002},{0,-1,0},3}};
    check(successor->assets.read()[0].mesh.vertices.data()==mesh&&!original->composition.book_rows&&original->composition_groups.empty(),"Composition edit deep-copied geometry or mutated immutable predecessor");
    successor->assets[0].book_row=BookRowProfile{};
    check(!original->assets.read()[0].book_row&&successor->assets.read()[0].mesh.vertices.data()!=mesh,"Explicit asset edit failed to detach shared catalog");
}
}
int main() {
    const std::pair<const char*,void(*)()> suites[]{
        {"legacy_migration_defaults",legacy_migration_defaults},{"current_round_trip",current_round_trip},
        {"truncation_and_versions",truncation_and_versions},{"malformed_composition_wire",malformed_composition_wire},
        {"structural_and_pending_edits",structural_and_pending_edits},{"high_water_failure_atomicity",high_water_failure_atomicity},
        {"utf8_preserves_released_semantics",utf8_preserves_released_semantics},{"immutable_state_sharing",immutable_state_sharing}
    };
    try{for(const auto& [name,test]:suites){test();std::cout<<"PASS "<<name<<'\n';}}
    catch(const std::exception& error){std::cerr<<"FAIL "<<error.what()<<'\n';return 1;}
    std::cout<<"SUCCESS "<<std::size(suites)<<" document state suites\n";
}
