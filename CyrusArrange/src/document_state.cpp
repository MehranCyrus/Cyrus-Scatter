#include "cyrus_arrange/document_state.h"
#include <algorithm>
#include <bit>
#include <cmath>
#include <limits>
#include <map>
#include <set>
#include <stdexcept>
#include <utility>

namespace cyrus::arrange::host {
namespace {
// Match MB_ERR_INVALID_CHARS used by the released host codec. Unlike asset
// names, saved setup labels historically admit ASCII controls other than NUL.
bool valid_utf8(const std::string& value) {
    const auto* bytes=reinterpret_cast<const unsigned char*>(value.data());
    std::size_t at=0;
    while(at<value.size()) {
        const auto lead=bytes[at++];if(lead<0x80)continue;
        std::uint32_t code{},minimum{};unsigned remaining{};
        if((lead&0xe0)==0xc0){code=lead&0x1f;minimum=0x80;remaining=1;}
        else if((lead&0xf0)==0xe0){code=lead&0x0f;minimum=0x800;remaining=2;}
        else if((lead&0xf8)==0xf0){code=lead&0x07;minimum=0x10000;remaining=3;}
        else return false;
        if(remaining>value.size()-at)return false;
        for(unsigned n=0;n<remaining;++n) {
            const auto next=bytes[at++];if((next&0xc0)!=0x80)return false;
            code=(code<<6)|(next&0x3f);
        }
        if(code<minimum||code>0x10ffff||(code>=0xd800&&code<=0xdfff))return false;
    }
    return true;
}
void text(const std::string& value,std::size_t maximum,const char* field) {
    if (value.size()>maximum || value.find('\0')!=std::string::npos ||
        !valid_utf8(value))
        throw std::runtime_error(std::string("Invalid bounded UTF-8 ")+field+".");
}
bool finite(Vec3 v) {return std::isfinite(v.x)&&std::isfinite(v.y)&&std::isfinite(v.z);}
void positive(double v,double maximum,const char* field,bool zero=false) {
    if(!std::isfinite(v)||v<(zero?0.0:std::numeric_limits<double>::min())||v>maximum)
        throw std::runtime_error(std::string("Invalid Arrange ")+field+".");
}
struct Writer {
    std::vector<std::uint8_t> bytes;
    void room(std::size_t amount) {
        if(amount>max_document_bytes-bytes.size())throw std::runtime_error("Arrange scene state exceeds 160 MiB.");
    }
    void u8(std::uint8_t value){room(1);bytes.push_back(value);}
    void u32(std::uint32_t value){for(int i=0;i<4;++i)u8(static_cast<std::uint8_t>(value>>(i*8)));}
    void u64(std::uint64_t value){for(int i=0;i<8;++i)u8(static_cast<std::uint8_t>(value>>(i*8)));}
    void f64(double value){if(!std::isfinite(value))throw std::runtime_error("Nonfinite saved Arrange value.");u64(std::bit_cast<std::uint64_t>(value));}
    void boolean(bool value){u8(value?1:0);}
    void string(const std::string& value){u32(static_cast<std::uint32_t>(value.size()));room(value.size());bytes.insert(bytes.end(),value.begin(),value.end());}
    void point(Vec3 value){f64(value.x);f64(value.y);f64(value.z);}
};
struct Reader {
    const std::vector<std::uint8_t>& bytes;std::size_t cursor{};
    void need(std::size_t amount){if(amount>bytes.size()-cursor)throw std::runtime_error("Truncated Arrange scene state.");}
    std::uint8_t u8(){need(1);return bytes[cursor++];}
    std::uint32_t u32(){std::uint32_t value=0;for(int i=0;i<4;++i)value|=std::uint32_t(u8())<<(i*8);return value;}
    std::uint64_t u64(){std::uint64_t value=0;for(int i=0;i<8;++i)value|=std::uint64_t(u8())<<(i*8);return value;}
    double f64(){const double value=std::bit_cast<double>(u64());if(!std::isfinite(value))throw std::runtime_error("Nonfinite saved Arrange value.");return value;}
    bool boolean(){auto value=u8();if(value>1)throw std::runtime_error("Invalid saved Arrange Boolean.");return value!=0;}
    std::size_t count(std::size_t maximum){auto value=u64();if(value>maximum)throw std::runtime_error("Saved Arrange count exceeds admission.");return static_cast<std::size_t>(value);}
    std::string string(std::size_t maximum){auto size=u32();if(size>maximum)throw std::runtime_error("Saved Arrange string exceeds admission.");need(size);std::string value(reinterpret_cast<const char*>(bytes.data()+cursor),size);cursor+=size;return value;}
    Vec3 point(){const double x=f64(),y=f64(),z=f64();return {x,y,z};}
};
void write_settings(Writer& out,const DocumentState& value) {
    const auto& i=value.inspection;out.f64(i.cell_size_mm);out.f64(i.minimum_clearance_mm);
    out.f64(i.maximum_slope_degrees);out.f64(i.height_tolerance_mm);out.u64(i.max_triangles);
    out.u64(i.max_cells);out.u64(i.max_regions);out.u64(i.max_work);
    const auto& a=value.arrangement;out.u64(a.seed);out.f64(a.density);out.f64(a.spacing_mm);
    out.f64(a.edge_clearance_mm);out.f64(a.cluster_strength);out.f64(a.height_variation);out.f64(a.empty_space);
    out.u32(static_cast<std::uint32_t>(a.style));out.u32(static_cast<std::uint32_t>(a.category));
    out.u64(a.max_placements);out.u64(a.max_candidates);out.u64(a.max_stack_depth);out.u64(a.max_work);
}
void read_settings(Reader& in,DocumentState& value) {
    auto& i=value.inspection;i.cell_size_mm=in.f64();i.minimum_clearance_mm=in.f64();
    i.maximum_slope_degrees=in.f64();i.height_tolerance_mm=in.f64();i.max_triangles=in.count(1000000);
    i.max_cells=in.count(1000000);i.max_regions=in.count(4096);i.max_work=in.u64();
    auto& a=value.arrangement;a.seed=in.u64();a.density=in.f64();a.spacing_mm=in.f64();
    a.edge_clearance_mm=in.f64();a.cluster_strength=in.f64();a.height_variation=in.f64();a.empty_space=in.f64();
    a.style=static_cast<ArrangeStyle>(in.u32());a.category=static_cast<FurnitureCategory>(in.u32());
    a.max_placements=in.count(max_document_placements);a.max_candidates=in.count(200000);
    a.max_stack_depth=in.count(8);a.max_work=in.u64();
}

}

void validate_document_state(const DocumentState& value) {
    text(value.document_id,40,"document identity");text(value.label,512,"setup label");
    if(value.document_id.size()!=38 || value.document_id.front()!='{' || value.document_id.back()!='}' || !value.revision || !value.next_id)
        throw std::runtime_error("Arrange scene identity/revision is invalid.");
    if(value.furniture_count>max_furniture_nodes || value.obstacle_count>max_obstacle_nodes || value.assets.size()>max_document_assets ||
       value.placements.size()>max_document_placements || value.composition_groups.size()>max_document_composition_groups)
        throw std::runtime_error("Arrange scene count exceeds admission.");
    validate_assets(value.assets);
    const auto minimum_total=validate_asset_minimums(value.minimums,value.assets.read());
    if(minimum_total>value.arrangement.max_placements)throw std::runtime_error("Minimum copies exceed the arrangement placement limit.");
    if(value.composition.book_rows&&!value.minimums.empty())throw std::runtime_error("Per-prop minimums require ordinary geometry placement.");
    if(!value.path&&value.arrangement.amount_mode==AmountMode::Quantity&&minimum_total>value.arrangement.quantity)
        throw std::runtime_error("Minimum copies exceed Copies. Raise Copies or lower a prop minimum.");
    if(value.asset_capture.size()!=value.assets.size())throw std::runtime_error("Asset capture policies and catalog counts disagree.");
    if(!value.regions||value.furniture_source_keys.size()!=value.furniture_count)throw std::runtime_error("Furniture source identities and region registry are incomplete.");
    validate_region_registry(*value.regions);
    std::set<std::uint64_t> source_keys;for(auto key:value.furniture_source_keys)if(!key||!source_keys.insert(key).second)throw std::runtime_error("Furniture source identities must be nonzero and unique.");
    for(const auto& rules:value.category_rules){validate_category_rules(rules);if(rules.size()!=static_cast<std::size_t>(AssetCategory::Count))throw std::runtime_error("Saved category rules must define every asset category.");}
    const auto& i=value.inspection;
    positive(i.cell_size_mm,1000000,"sample spacing");if(i.cell_size_mm<0.1)throw std::runtime_error("Arrange sample spacing must be at least 0.1 mm.");
    positive(i.minimum_clearance_mm,1e9,"clearance",true);positive(i.maximum_slope_degrees,45,"slope",true);
    positive(i.height_tolerance_mm,1000,"height tolerance");
    if(!i.max_triangles||i.max_triangles>1000000||!i.max_cells||i.max_cells>1000000||!i.max_regions||i.max_regions>4096||!i.max_work||i.max_work>50000000)
        throw std::runtime_error("Arrange inspection budget exceeds admission.");
    const auto& a=value.arrangement;
    for(double v:{a.density,a.cluster_strength,a.height_variation,a.empty_space})positive(v,1,"style parameter",true);
    positive(a.spacing_mm,1000000,"spacing",true);positive(a.edge_clearance_mm,1000000,"edge clearance",true);
    if(a.amount_mode>=AmountMode::Count||a.quantity>max_document_placements||(a.amount_mode==AmountMode::Quantity&&a.quantity>a.max_placements)||
       !std::isfinite(a.scale_min)||!std::isfinite(a.scale_max)||a.scale_min<0.01||a.scale_max>100||
       a.scale_min>a.scale_max||(a.fit_to_space&&a.scale_min>1))
        throw std::runtime_error("Invalid saved quantity or uniform scale range.");
    if(a.style>=ArrangeStyle::Count||a.category>=FurnitureCategory::Count||!a.max_placements||a.max_placements>max_document_placements||
       !a.max_candidates||a.max_candidates>200000||!a.max_stack_depth||a.max_stack_depth>8||!a.max_work||a.max_work>50000000)
        throw std::runtime_error("Arrange settings or work budget are invalid.");
    validate_composition_options(value.composition,a.category);
    if(!finite(value.frame_origin_mm))throw std::runtime_error("Arrange scene frame is nonfinite.");
    positive(value.captured_mm_per_system_unit,1e12,"captured units");
    std::set<std::uint64_t> assets;for(const auto& asset:value.assets)assets.insert(asset.id);
    std::map<std::uint64_t,std::uint64_t> parents;
    for(const auto& row:value.placements) {
        if(!row.stable_id||!row.region_id||!assets.contains(row.asset_id)||!parents.emplace(row.stable_id,row.parent_stack_id).second||
           !finite(row.position)||std::max({std::abs(row.position.x),std::abs(row.position.y),std::abs(row.position.z)})>1e9||
           !std::isfinite(row.yaw_degrees)||!std::isfinite(row.scale)||row.scale<=0||row.scale>1000000)
            throw std::runtime_error("Arrange placement identity, asset, position or scale is invalid.");
    }
    for(const auto& [id,parent]:parents) {
        std::set<std::uint64_t> path;auto at=id;
        while(at) {
            const auto found=parents.find(at);
            if(found==parents.end()||!path.insert(at).second)throw std::runtime_error("Arrange stack contains a missing parent or cycle.");
            if(path.size()>8)throw std::runtime_error("Arrange stack exceeds depth 8.");at=found->second;
        }
    }
    // Pending edits may invalidate current profiles/support. Only structural
    // membership belongs here; protected/current geometry is checked by solve.
    validate_composition_structure(value.composition_groups,value.placements);
    if(value.path){
        const auto& path=*value.path;validate_path_settings(path.settings);
        if(path.curve_index>=256||!path.lane_count||path.lane_count>2||path.lanes[0].id==path.lanes[1].id||path.lanes[0].quantity!=a.quantity)
            throw std::runtime_error("Invalid saved path curve, lane count/identity or main quantity.");
        std::size_t requested=0;
        for(std::size_t index=0;index<2;++index){const auto& lane=path.lanes[index];validate_path_lane(lane);
            if(assets.contains(lane.id)||source_keys.contains(lane.id))throw std::runtime_error("Path lane identity overlaps a source identity.");
            for(const auto& region:value.regions->records)if(region.stable_id==lane.id)throw std::runtime_error("Path lane identity overlaps a support region.");
            if(index<path.lane_count&&path.settings.amount==PathAmount::Quantity){if(lane.quantity>a.max_placements-requested)throw std::runtime_error("Saved path lane quantities exceed output admission.");requested+=lane.quantity;}
        }
        if(path.settings.amount==PathAmount::Quantity&&minimum_total>requested)throw std::runtime_error("Minimum copies exceed the combined path lane quantity.");
    }
}

std::vector<std::uint8_t> encode_document_state(const DocumentState& value,std::uint64_t high_water) {
    validate_document_state(value);if(!high_water)throw std::runtime_error("Invalid Arrange identity high water.");
    auto assets=encode_assets(value.assets);
    Writer out;out.u32(0x43415244);out.u32(document_schema_version);out.string(value.document_id);out.string(value.label);
    out.u64(value.revision);out.u64(value.next_id);out.u64(high_water);out.boolean(value.live);write_settings(out,value);
    out.point(value.frame_origin_mm);out.u64(value.furniture_count);out.u32(static_cast<std::uint32_t>(value.capture_time));out.f64(value.captured_mm_per_system_unit);
    out.u64(value.obstacle_count);out.boolean(value.require_front_access);
    out.u64(0); // Reserved word; exclusions belong solely to RegionSemantics.
    out.u64(assets.size());out.room(assets.size());out.bytes.insert(out.bytes.end(),assets.begin(),assets.end());
    out.u64(value.asset_capture.size());for(const auto& policy:value.asset_capture){out.boolean(policy.source_required);out.boolean(policy.authored_contact);out.boolean(policy.authored_stack);}
    for(const auto& rules:value.category_rules){out.u64(rules.size());for(const auto& rule:rules){out.u32(static_cast<std::uint32_t>(rule.category));out.f64(rule.weight);out.u32(rule.maximum_count);out.boolean(rule.allow_on_stack);}}
    out.u64(value.furniture_source_keys.size());for(auto key:value.furniture_source_keys)out.u64(key);
    const auto regions=encode_region_registry(*value.regions);out.u64(regions.size());out.room(regions.size());out.bytes.insert(out.bytes.end(),regions.begin(),regions.end());
    out.u64(value.placements.size());
    for(const auto& row:value.placements) {
        out.u64(row.stable_id);out.u64(row.asset_id);out.u64(row.parent_stack_id);out.u32(row.region_id);
        out.point(row.position);out.f64(row.yaw_degrees);out.f64(row.scale);out.boolean(row.locked);
    }
    const auto& options=value.composition;
    out.boolean(options.book_rows);out.u32(options.minimum_books);out.u32(options.maximum_books);
    out.f64(options.row_gap_mm);out.f64(options.row_height_balance);
    out.u64(value.composition_groups.size());
    for(const auto& group:value.composition_groups) {
        out.u64(group.stable_id);out.u32(static_cast<std::uint32_t>(group.kind));out.u32(group.region_id);
        out.u64(group.member_ids.size());for(const auto id:group.member_ids)out.u64(id);
        out.point(group.front_direction);out.f64(group.gap_mm);
    }
    const auto& placement=value.arrangement;
    out.u32(static_cast<std::uint32_t>(placement.amount_mode));out.u64(placement.quantity);
    out.boolean(placement.random_scale);out.boolean(placement.fit_to_space);
    out.f64(placement.scale_min);out.f64(placement.scale_max);
    out.boolean(value.path.has_value());
    if(value.path){const auto& path=*value.path;const auto& s=path.settings;
        out.u32(path.curve_index);out.u32(static_cast<std::uint32_t>(path.lane_count));out.u32(static_cast<std::uint32_t>(s.amount));out.boolean(s.align);
        for(double v:{s.source_forward_degrees,s.start_inset_mm,s.end_inset_mm,s.lateral_jitter_mm,s.longitudinal_jitter_mm})out.f64(v);
        out.u64(s.attempts_per_slot);
        for(const auto& lane:path.lanes){out.u32(lane.id);out.u64(lane.quantity);out.f64(lane.offset_mm);out.f64(lane.width_mm);out.f64(lane.center_spacing_mm);out.boolean(lane.reverse);out.boolean(lane.limit_width);}
    }
    out.u64(value.minimums.size());for(const auto& m:value.minimums){out.u64(m.asset_id);out.u64(m.quantity);}
    return std::move(out.bytes);
}
std::shared_ptr<const DocumentState> decode_document_state(const std::vector<std::uint8_t>& bytes,std::uint64_t& high_water) {
    if(bytes.size()>max_document_bytes)throw std::runtime_error("Saved Arrange state exceeds admission.");
    Reader in{bytes};
    if(in.u32()!=0x43415244)throw std::runtime_error("Unrecognized Arrange document format; original scene is preserved.");
    const auto schema=in.u32();
    if(schema!=3&&schema!=4&&schema!=5&&schema!=6&&schema!=document_schema_version)throw std::runtime_error("Unsupported Arrange document schema; original scene is preserved.");
    auto value=std::make_shared<DocumentState>();value->document_id=in.string(40);value->label=in.string(512);
    value->revision=in.u64();value->next_id=in.u64();const auto high=in.u64();value->live=in.boolean();read_settings(in,*value);
    value->frame_origin_mm=in.point();value->furniture_count=in.count(max_furniture_nodes);
    value->capture_time=std::bit_cast<std::int32_t>(in.u32());value->captured_mm_per_system_unit=in.f64();
    value->obstacle_count=in.count(max_obstacle_nodes);value->require_front_access=in.boolean();
    if(in.u64()!=0)throw std::runtime_error("Unsupported reserved Arrange document data.");
    const auto asset_bytes=in.count(AssetLimits{}.max_library_bytes);in.need(asset_bytes);
    const auto asset_payload=std::span<const std::uint8_t>(bytes.data()+in.cursor,asset_bytes);
    if(schema==3) {
        // Released schema 3 embedded library format 1 exclusively. Do not admit
        // a relabelled future blob under an old document version.
        if(asset_payload.size()<12||asset_payload[8]!=1||asset_payload[9]||asset_payload[10]||asset_payload[11])
            throw std::runtime_error("Schema 3 requires its original asset format 1 payload.");
    }
    value->assets=decode_assets(asset_payload);in.cursor+=asset_bytes;
    const auto policies=in.count(max_document_assets);in.need(policies*3);value->asset_capture.reserve(policies);
    for(std::size_t n=0;n<policies;++n)value->asset_capture.push_back({in.boolean(),in.boolean(),in.boolean()});
    for(auto& rules:value->category_rules){const auto count=in.count(static_cast<std::size_t>(AssetCategory::Count));rules.clear();for(std::size_t n=0;n<count;++n)rules.push_back({static_cast<AssetCategory>(in.u32()),in.f64(),in.u32(),in.boolean()});}
    const auto source_keys=in.count(max_furniture_nodes);in.need(source_keys*8);for(std::size_t n=0;n<source_keys;++n)value->furniture_source_keys.push_back(in.u64());
    const auto region_bytes=in.count(RegionRegistrySettings{}.max_bytes);in.need(region_bytes);value->regions=decode_region_registry(std::span<const std::uint8_t>(bytes.data()+in.cursor,region_bytes));in.cursor+=region_bytes;
    const auto count=in.count(max_document_placements);in.need(count*69);value->placements.reserve(count);
    for(std::size_t n=0;n<count;++n) {
        Placement row;row.stable_id=in.u64();row.asset_id=in.u64();row.parent_stack_id=in.u64();row.region_id=in.u32();
        row.position=in.point();row.yaw_degrees=in.f64();row.scale=in.f64();row.locked=in.boolean();value->placements.push_back(row);
    }
    if(schema>=4) {
        auto& options=value->composition;
        options.book_rows=in.boolean();options.minimum_books=in.u32();options.maximum_books=in.u32();
        options.row_gap_mm=in.f64();options.row_height_balance=in.f64();
        validate_composition_options(options,value->arrangement.category);
        const auto groups=in.count(max_document_composition_groups);
        if(groups>count/2)throw std::runtime_error("Saved composition groups exceed their placement membership admission.");
        in.need(groups*72);value->composition_groups.reserve(groups);std::size_t total_members=0;
        for(std::size_t n=0;n<groups;++n) {
            CompositionGroup group;group.stable_id=in.u64();group.kind=static_cast<CompositionKind>(in.u32());group.region_id=in.u32();
            const auto members=in.count(6);
            if(members<2||members>max_document_placements-total_members)
                throw std::runtime_error("Saved composition membership exceeds admission.");
            total_members+=members;in.need(members*8+32);group.member_ids.reserve(members);
            for(std::size_t member=0;member<members;++member)group.member_ids.push_back(in.u64());
            group.front_direction=in.point();group.gap_mm=in.f64();value->composition_groups.push_back(std::move(group));
        }
    }
    if(schema>=5) {
        auto& placement=value->arrangement;
        placement.amount_mode=static_cast<AmountMode>(in.u32());placement.quantity=in.count(max_document_placements);
        placement.random_scale=in.boolean();placement.fit_to_space=in.boolean();
        placement.scale_min=in.f64();placement.scale_max=in.f64();
    }
    if(schema>=6&&in.boolean()){
        PathLayout path;path.curve_index=in.u32();path.lane_count=in.u32();auto& s=path.settings;
        s.amount=static_cast<PathAmount>(in.u32());s.align=in.boolean();s.source_forward_degrees=in.f64();s.start_inset_mm=in.f64();s.end_inset_mm=in.f64();s.lateral_jitter_mm=in.f64();s.longitudinal_jitter_mm=in.f64();s.attempts_per_slot=in.count(64);
        for(auto& lane:path.lanes){lane.id=in.u32();lane.quantity=in.count(max_document_placements);lane.offset_mm=in.f64();lane.width_mm=in.f64();lane.center_spacing_mm=in.f64();lane.reverse=in.boolean();lane.limit_width=in.boolean();}
        value->path=std::move(path);
    }
    if(schema>=7){const auto minimum_count=in.count(max_document_assets);in.need(minimum_count*16);value->minimums.reserve(minimum_count);for(std::size_t n=0;n<minimum_count;++n){const auto id=in.u64();const auto quantity=in.count(max_document_placements);value->minimums.push_back({id,quantity});}}
    if(in.cursor!=bytes.size()||!high)throw std::runtime_error("Arrange scene has trailing bytes or invalid identity state.");
    validate_document_state(*value);
    auto decoded_high_water=std::max({high,value->next_id,static_cast<std::uint64_t>(value->regions->high_water)+1});
    for(const auto& asset:value->assets.read()) {
        if(asset.id==std::numeric_limits<std::uint64_t>::max())throw std::runtime_error("Saved asset identity is exhausted.");
        decoded_high_water=std::max(decoded_high_water,asset.id+1);
    }
    for(auto key:value->furniture_source_keys) {
        if(key==std::numeric_limits<std::uint64_t>::max())throw std::runtime_error("Saved source identity is exhausted.");
        decoded_high_water=std::max(decoded_high_water,key+1);
    }
    if(value->path)for(const auto& lane:value->path->lanes)decoded_high_water=std::max(decoded_high_water,static_cast<std::uint64_t>(lane.id)+1);
    high_water=decoded_high_water;return value;
}

}
