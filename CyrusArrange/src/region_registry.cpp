#include "cyrus_arrange/region_registry.h"

#include <algorithm>
#include <bit>
#include <cmath>
#include <limits>
#include <map>
#include <set>
#include <stdexcept>
#include <tuple>

namespace cyrus::arrange {
namespace {
constexpr std::size_t hard_regions=4096,hard_cells=1000000,hard_sources=32768,hard_bytes=64u*1024u*1024u;
constexpr std::uint64_t hard_work=50000000;
constexpr double units=1000.0;
struct Budget {
    std::uint64_t used{},limit{};
    void charge(std::uint64_t n=1){if(n>limit-used)throw std::runtime_error("Region registry work budget exceeded; previous registry retained.");used+=n;}
};
void require(bool condition,const char* message){if(!condition)throw std::invalid_argument(message);}
void settings_valid(const RegionRegistrySettings& s){
    require(s.max_regions&&s.max_regions<=hard_regions&&s.max_cells&&s.max_cells<=hard_cells&&s.max_source_keys&&s.max_source_keys<=hard_sources&&
        s.max_bytes>=20&&s.max_bytes<=hard_bytes&&s.max_work&&s.max_work<=hard_work,"Region registry limits exceed hard ceilings.");
    require(std::isfinite(s.overlap_threshold)&&s.overlap_threshold>=0.98&&s.overlap_threshold<=1&&std::isfinite(s.maximum_height_change_mm)&&
        s.maximum_height_change_mm>=0&&s.maximum_height_change_mm<=0.01,"Conservative region matching requires overlap >=98% and height change <=0.01 mm.");
}
bool utf8(const std::string& value){
    for(std::size_t i=0;i<value.size();){const auto c=static_cast<unsigned char>(value[i++]);if(c<0x80){if(c<32||c==127)return false;continue;}
        unsigned count=0;std::uint32_t point=0,minimum=0;
        if(c>=0xc2&&c<=0xdf){count=1;point=c&31;minimum=0x80;}else if(c>=0xe0&&c<=0xef){count=2;point=c&15;minimum=0x800;}
        else if(c>=0xf0&&c<=0xf4){count=3;point=c&7;minimum=0x10000;}else return false;
        if(count>value.size()-i)return false;while(count--){const auto d=static_cast<unsigned char>(value[i++]);if((d&0xc0)!=0x80)return false;point=(point<<6)|(d&63);}
        if(point<minimum||point>0x10ffff||(point>=0xd800&&point<=0xdfff))return false;
    }return true;
}
bool finite(Vec3 p){return std::isfinite(p.x)&&std::isfinite(p.y)&&std::isfinite(p.z);}
void semantics_valid(const RegionSemantics& s){
    require(s.label.size()<=512&&s.compartment_label.size()<=512&&utf8(s.label)&&utf8(s.compartment_label),"Region labels must be printable UTF-8 of at most 512 bytes.");
    require(s.role<SupportRole::Count&&(s.allowed_asset_categories&~all_asset_mask)==0,"Invalid support role or allowed asset-category mask.");
    require(std::isfinite(s.density_multiplier)&&s.density_multiplier>=0&&s.density_multiplier<=4,"Region density multiplier must lie in [0,4].");
    const double length=std::hypot(s.front_direction.x,s.front_direction.y);
    require(finite(s.front_direction)&&std::abs(s.front_direction.z)<=1e-9&&length>=1e-9&&length<=1e6,"Region front direction must be a finite nonzero horizontal vector.");
}
std::int64_t quantize(double value){require(std::isfinite(value)&&std::abs(value)<=1e9,"Region coordinates must be finite and within +/-1000000000 mm.");return static_cast<std::int64_t>(std::llround(value*units));}
void hash_value(std::uint64_t& h,std::uint64_t value){for(unsigned i=0;i<8;++i){h^=(value>>(8*i))&255;h*=1099511628211ULL;}}
std::uint64_t fingerprint(const RegionShape& shape,Budget& budget){
    std::uint64_t h=14695981039346656037ULL;hash_value(h,static_cast<std::uint64_t>(shape.cell_size_um));hash_value(h,shape.source_keys.size());
    for(auto key:shape.source_keys){budget.charge();hash_value(h,key);}hash_value(h,shape.cells.size());
    for(auto cell:shape.cells){budget.charge();hash_value(h,static_cast<std::uint64_t>(cell.x));hash_value(h,static_cast<std::uint64_t>(cell.y));hash_value(h,static_cast<std::uint64_t>(cell.z));}
    return h;
}
Bounds shape_bounds(const RegionShape& shape){
    const double half=static_cast<double>(shape.cell_size_um)/(2*units);
    Bounds out{{INFINITY,INFINITY,INFINITY},{-INFINITY,-INFINITY,-INFINITY}};
    for(auto cell:shape.cells){const double x=static_cast<double>(cell.x)/units,y=static_cast<double>(cell.y)/units,z=static_cast<double>(cell.z)/units;
        out.min={std::min(out.min.x,x-half),std::min(out.min.y,y-half),std::min(out.min.z,z)};
        out.max={std::max(out.max.x,x+half),std::max(out.max.y,y+half),std::max(out.max.z,z)};}
    return out;
}
bool same_shape(const RegionShape& a,const RegionShape& b,Budget& budget){
    if(a.cell_size_um!=b.cell_size_um||a.source_keys.size()!=b.source_keys.size()||a.cells.size()!=b.cells.size())return false;
    for(std::size_t i=0;i<a.source_keys.size();++i){budget.charge();if(a.source_keys[i]!=b.source_keys[i])return false;}
    for(std::size_t i=0;i<a.cells.size();++i){budget.charge();if(a.cells[i]!=b.cells[i])return false;}return true;
}
void validate(const RegionRegistry& registry,const RegionRegistrySettings& settings,Budget& budget){
    require(registry.records.size()<=settings.max_regions,"Region registry record count exceeds its limit.");
    std::set<std::uint32_t> ids;std::size_t cells=0,sources=0,bytes=20;
    std::map<std::uint64_t,std::vector<const RegionShape*>> signatures;
    for(const auto& record:registry.records){budget.charge();
        require(record.stable_id&&record.stable_id<=registry.high_water&&ids.insert(record.stable_id).second,"Registry IDs must be unique, nonzero and below its high-water mark.");
        require(static_cast<bool>(record.shape),"Region record has no immutable shape.");const auto& shape=*record.shape;
        require(shape.cell_size_um>=100&&shape.cell_size_um<=1000000000LL&&!shape.cells.empty()&&!shape.source_keys.empty(),"Invalid region cell size or empty shape/source scope.");
        require(shape.cells.size()<=settings.max_cells-cells&&shape.source_keys.size()<=settings.max_source_keys-sources,"Registry cell or source-reference limit exceeded.");
        cells+=shape.cells.size();sources+=shape.source_keys.size();
        semantics_valid(record.semantics);
        const auto cost=256+shape.cells.size()*24+shape.source_keys.size()*8+record.semantics.label.size()+record.semantics.compartment_label.size();
        require(cost<=settings.max_bytes-bytes,"Region registry memory/serialization admission exceeded.");bytes+=cost;
        for(std::size_t i=0;i<shape.source_keys.size();++i){budget.charge();require(shape.source_keys[i]&&(i==0||shape.source_keys[i-1]<shape.source_keys[i]),"Source keys must be nonzero, sorted and unique.");}
        for(std::size_t i=0;i<shape.cells.size();++i){budget.charge();const auto cell=shape.cells[i];
            require(cell.x>=-1000000000000LL&&cell.x<=1000000000000LL&&cell.y>=-1000000000000LL&&cell.y<=1000000000000LL&&cell.z>=-1000000000000LL&&cell.z<=1000000000000LL&&
                (i==0||shape.cells[i-1]<cell),"Canonical region cells must be bounded, sorted and unique.");}
        const auto bounds=shape_bounds(shape);
        require(finite(shape.bounds.min)&&finite(shape.bounds.max)&&std::abs(shape.bounds.min.x-bounds.min.x)<=1e-6&&std::abs(shape.bounds.min.y-bounds.min.y)<=1e-6&&
            std::abs(shape.bounds.min.z-bounds.min.z)<=1e-6&&std::abs(shape.bounds.max.x-bounds.max.x)<=1e-6&&std::abs(shape.bounds.max.y-bounds.max.y)<=1e-6&&std::abs(shape.bounds.max.z-bounds.max.z)<=1e-6,
            "Registry sampled bounds do not match its canonical cells.");
        require(!std::isnan(record.minimum_clearance_mm)&&record.minimum_clearance_mm>=0&&record.open_above==std::isinf(record.minimum_clearance_mm),"Registry clearance/open-above measurement is inconsistent.");
        const auto signature=fingerprint(shape,budget);
        for(const auto* prior:signatures[signature])require(!same_shape(shape,*prior,budget),"Registry has duplicate geometry in the same source scope.");
        signatures[signature].push_back(&shape);
    }
}
std::shared_ptr<const RegionShape> observe(const RegionObservation& observation,const RegionRegistrySettings& settings,Budget& budget){
    require(observation.region&&observation.region->id&&!observation.region->cells.empty(),"A region observation needs a nonempty identified support region.");
    require(!observation.source_keys.empty()&&observation.source_keys.size()<=settings.max_source_keys,"A region observation requires bounded persistent source keys.");
    const auto& region=*observation.region;
    require(std::isfinite(region.sampled_area_mm2)&&region.sampled_area_mm2>0,"Region observation requires positive finite sampled area.");
    const double size=std::sqrt(region.sampled_area_mm2/static_cast<double>(region.cells.size()));
    require(std::isfinite(size)&&size>=0.1&&size<=1000000,"Observed region cell size is outside the supported range.");
    auto shape=std::make_shared<RegionShape>();shape->cell_size_um=quantize(size);
    shape->source_keys.assign(observation.source_keys.begin(),observation.source_keys.end());
    std::sort(shape->source_keys.begin(),shape->source_keys.end(),[&](auto a,auto b){budget.charge();return a<b;});
    shape->source_keys.erase(std::unique(shape->source_keys.begin(),shape->source_keys.end()),shape->source_keys.end());
    require(shape->source_keys.front()!=0,"Persistent region source keys cannot be zero.");
    shape->cells.reserve(region.cells.size());
    for(const auto& cell:region.cells){budget.charge();shape->cells.push_back({quantize(cell.center.x),quantize(cell.center.y),quantize(cell.center.z)});}
    std::sort(shape->cells.begin(),shape->cells.end(),[&](const auto& a,const auto& b){budget.charge();return a<b;});
    require(std::adjacent_find(shape->cells.begin(),shape->cells.end())==shape->cells.end(),"Observed region has duplicate canonical support cells.");
    shape->bounds=shape_bounds(*shape);return shape;
}
bool overlap_match(const RegionShape& a,const RegionShape& b,const RegionRegistrySettings& settings,Budget& budget){
    budget.charge();if(a.cell_size_um!=b.cell_size_um||a.source_keys!=b.source_keys)return false;
    if(std::abs(a.bounds.min.z-b.bounds.min.z)>settings.maximum_height_change_mm||std::abs(a.bounds.max.z-b.bounds.max.z)>settings.maximum_height_change_mm)return false;
    const double ix=std::max(0.0,std::min(a.bounds.max.x,b.bounds.max.x)-std::max(a.bounds.min.x,b.bounds.min.x));
    const double iy=std::max(0.0,std::min(a.bounds.max.y,b.bounds.max.y)-std::max(a.bounds.min.y,b.bounds.min.y));
    const double area_a=(a.bounds.max.x-a.bounds.min.x)*(a.bounds.max.y-a.bounds.min.y),area_b=(b.bounds.max.x-b.bounds.min.x)*(b.bounds.max.y-b.bounds.min.y),intersection=ix*iy;
    if(intersection/(area_a+area_b-intersection)<settings.overlap_threshold)return false;
    const auto height=static_cast<std::int64_t>(std::floor(settings.maximum_height_change_mm*units+1e-8));
    std::size_t i=0,j=0,matches=0;
    while(i<a.cells.size()&&j<b.cells.size()){budget.charge();const auto x=a.cells[i],y=b.cells[j];
        if(x.x==y.x&&x.y==y.y&&std::abs(x.z-y.z)<=height){++matches;++i;++j;}
        else if(std::tie(x.x,x.y,x.z)<std::tie(y.x,y.y,y.z))++i;else ++j;
    }
    return static_cast<double>(matches)/static_cast<double>(a.cells.size()+b.cells.size()-matches)>=settings.overlap_threshold;
}
struct Writer {
    std::vector<std::uint8_t> bytes;std::size_t limit;Budget& budget;
    void u8(std::uint8_t value){budget.charge();if(bytes.size()>=limit)throw std::runtime_error("Registry encoding exceeds byte budget.");bytes.push_back(value);}
    void u32(std::uint32_t v){for(unsigned i=0;i<4;++i)u8(static_cast<std::uint8_t>(v>>(8*i)));}
    void u64(std::uint64_t v){for(unsigned i=0;i<8;++i)u8(static_cast<std::uint8_t>(v>>(8*i)));}
    void f64(double v){u64(std::bit_cast<std::uint64_t>(v));}
    void string(const std::string& value){u32(static_cast<std::uint32_t>(value.size()));for(auto c:value)u8(static_cast<std::uint8_t>(c));}
};
struct Reader {
    std::span<const std::uint8_t> bytes;std::size_t at{};Budget& budget;
    void remaining(std::size_t n){require(n<=bytes.size()-at,"Truncated region registry payload.");}
    std::uint8_t u8(){remaining(1);budget.charge();return bytes[at++];}
    std::uint32_t u32(){std::uint32_t v=0;for(unsigned i=0;i<4;++i)v|=static_cast<std::uint32_t>(u8())<<(8*i);return v;}
    std::uint64_t u64(){std::uint64_t v=0;for(unsigned i=0;i<8;++i)v|=static_cast<std::uint64_t>(u8())<<(8*i);return v;}
    double f64(){return std::bit_cast<double>(u64());}
    bool boolean(){const auto v=u8();require(v<=1,"Invalid registry boolean.");return v!=0;}
    std::string string(){const auto n=u32();require(n<=512,"Registry label exceeds its limit.");remaining(n);std::string out;out.reserve(n);for(std::uint32_t i=0;i<n;++i)out.push_back(static_cast<char>(u8()));return out;}
};
}
bool has_nondefault_region_semantics(const RegionSemantics& value) noexcept {
    const RegionSemantics neutral;
    return value.label!=neutral.label||value.compartment_label!=neutral.compartment_label||
        value.role!=neutral.role||value.allowed_asset_categories!=neutral.allowed_asset_categories||
        value.density_multiplier!=neutral.density_multiplier||value.allow_stacking!=neutral.allow_stacking||
        value.excluded!=neutral.excluded||value.front_direction.x!=neutral.front_direction.x||
        value.front_direction.y!=neutral.front_direction.y||value.front_direction.z!=neutral.front_direction.z;
}
struct RegionRegistryPlan::Impl {
    struct Candidate{std::uint32_t observed_id{};RegionRecord record;};
    RegionRegistrySettings settings;Budget budget;std::uint32_t previous_high_water{};
    std::vector<Candidate> candidates;std::vector<std::uint32_t> retired;std::size_t required{};
};
RegionRegistryPlan::RegionRegistryPlan(std::unique_ptr<Impl> impl):impl_(std::move(impl)){}
RegionRegistryPlan::~RegionRegistryPlan()=default;
RegionRegistryPlan::RegionRegistryPlan(RegionRegistryPlan&&)noexcept=default;
RegionRegistryPlan& RegionRegistryPlan::operator=(RegionRegistryPlan&&)noexcept=default;
std::size_t RegionRegistryPlan::required_new_ids()const noexcept{return impl_?impl_->required:0;}
std::uint64_t RegionRegistryPlan::work()const noexcept{return impl_?impl_->budget.used:0;}
RegionRegistryPlan plan_regions(std::shared_ptr<const RegionRegistry> previous,std::span<const RegionObservation> observations,const RegionRegistrySettings& settings){
    settings_valid(settings);require(observations.size()<=settings.max_regions,"Too many support-region observations.");
    auto plan=std::make_unique<RegionRegistryPlan::Impl>();plan->settings=settings;plan->budget.limit=settings.max_work;
    if(!previous)previous=std::make_shared<const RegionRegistry>();validate(*previous,settings,plan->budget);plan->previous_high_water=previous->high_water;
    std::size_t cells=0,sources=0,bytes=20;std::set<std::uint32_t> observed_ids;
    for(const auto& observation:observations){plan->budget.charge();require(observation.region&&observed_ids.insert(observation.region->id).second,"Duplicate or missing observed region.");
        const auto count=observation.region->cells.size();require(count<=settings.max_cells-cells&&observation.source_keys.size()<=settings.max_source_keys-sources,"Observed cells or source references exceed admission.");
        cells+=count;sources+=observation.source_keys.size();const auto cost=256+count*24+observation.source_keys.size()*8;
        require(cost<=settings.max_bytes-bytes,"Observed region storage exceeds admission.");bytes+=cost;
        auto shape=observe(observation,settings,plan->budget);RegionRecord record;record.shape=std::move(shape);record.minimum_clearance_mm=observation.region->minimum_clearance_mm;record.open_above=observation.region->open_above;
        require(!std::isnan(record.minimum_clearance_mm)&&record.minimum_clearance_mm>=0&&record.open_above==std::isinf(record.minimum_clearance_mm),"Observed clearance/open-above measurement is inconsistent.");
        plan->candidates.push_back({observation.region->id,std::move(record)});
    }
    std::sort(plan->candidates.begin(),plan->candidates.end(),[&](const auto& a,const auto& b){
        const auto& x=*a.record.shape;const auto& y=*b.record.shape;plan->budget.charge();
        if(x.source_keys!=y.source_keys)return std::lexicographical_compare(x.source_keys.begin(),x.source_keys.end(),y.source_keys.begin(),y.source_keys.end());
        if(x.cell_size_um!=y.cell_size_um)return x.cell_size_um<y.cell_size_um;
        return std::lexicographical_compare(x.cells.begin(),x.cells.end(),y.cells.begin(),y.cells.end(),[&](const auto& p,const auto& q){plan->budget.charge();return p<q;});
    });
    for(std::size_t i=1;i<plan->candidates.size();++i)require(!same_shape(*plan->candidates[i-1].record.shape,*plan->candidates[i].record.shape,plan->budget),"Duplicate observed geometry in the same source scope.");
    std::map<std::uint64_t,std::vector<std::size_t>> exact;
    for(std::size_t i=0;i<previous->records.size();++i)exact[fingerprint(*previous->records[i].shape,plan->budget)].push_back(i);
    std::vector<unsigned char> used(previous->records.size(),0);
    auto match=[&](std::size_t observation,std::size_t old,bool reuse_shape){
        auto& record=plan->candidates[observation].record;const auto& prior=previous->records[old];record.stable_id=prior.stable_id;record.semantics=prior.semantics;
        if(reuse_shape)record.shape=prior.shape;used[old]=1;
    };
    for(std::size_t i=0;i<plan->candidates.size();++i){const auto signature=fingerprint(*plan->candidates[i].record.shape,plan->budget);const auto candidates=exact.find(signature);if(candidates==exact.end())continue;
        for(auto old:candidates->second)if(!used[old]&&same_shape(*plan->candidates[i].record.shape,*previous->records[old].shape,plan->budget)){match(i,old,true);break;}}
    if(settings.allow_overlap_matching){
        std::vector<std::size_t> old_count(previous->records.size()),new_count(plan->candidates.size()),choice(plan->candidates.size());
        for(std::size_t i=0;i<plan->candidates.size();++i)if(!plan->candidates[i].record.stable_id)
            for(std::size_t old=0;old<previous->records.size();++old)if(!used[old]&&overlap_match(*plan->candidates[i].record.shape,*previous->records[old].shape,settings,plan->budget)){
                ++new_count[i];++old_count[old];choice[i]=old;}
        for(std::size_t i=0;i<plan->candidates.size();++i)if(new_count[i]==1&&old_count[choice[i]]==1)match(i,choice[i],false);
    }
    for(const auto& candidate:plan->candidates)if(!candidate.record.stable_id)++plan->required;
    for(std::size_t i=0;i<previous->records.size();++i)if(!used[i])plan->retired.push_back(previous->records[i].stable_id);
    std::sort(plan->retired.begin(),plan->retired.end());return RegionRegistryPlan(std::move(plan));
}
RegionRegistryUpdate finish_regions(RegionRegistryPlan&& source,std::uint64_t first_reserved_id){
    require(static_cast<bool>(source.impl_),"Region registry plan has already been consumed.");auto plan=std::move(source.impl_);
    if(plan->required){require(first_reserved_id>plan->previous_high_water&&first_reserved_id<=std::numeric_limits<std::uint32_t>::max()&&
        plan->required-1<=std::numeric_limits<std::uint32_t>::max()-first_reserved_id,"Reserved region IDs would reuse retired identities or exceed uint32 range.");}
    auto registry=std::make_shared<RegionRegistry>();registry->high_water=plan->previous_high_water;
    RegionRegistryUpdate update;update.retired_ids=std::move(plan->retired);registry->records.reserve(plan->candidates.size());update.bindings.reserve(plan->candidates.size());
    for(auto& candidate:plan->candidates){plan->budget.charge();if(!candidate.record.stable_id)candidate.record.stable_id=static_cast<std::uint32_t>(first_reserved_id++);
        registry->high_water=std::max(registry->high_water,candidate.record.stable_id);update.bindings.push_back({candidate.observed_id,candidate.record.stable_id});registry->records.push_back(std::move(candidate.record));}
    std::sort(registry->records.begin(),registry->records.end(),[](const auto& a,const auto& b){return a.stable_id<b.stable_id;});
    std::sort(update.bindings.begin(),update.bindings.end(),[](const auto& a,const auto& b){return a.observed_id<b.observed_id;});
    validate(*registry,plan->settings,plan->budget);update.work=plan->budget.used;update.registry=std::move(registry);return update;
}
void validate_region_registry(const RegionRegistry& registry,const RegionRegistrySettings& settings){settings_valid(settings);Budget budget{0,settings.max_work};validate(registry,settings,budget);}
std::vector<std::uint8_t> encode_region_registry(const RegionRegistry& registry,const RegionRegistrySettings& settings){
    settings_valid(settings);Budget budget{0,settings.max_work};validate(registry,settings,budget);Writer out{{},settings.max_bytes,budget};
    for(auto c:std::string("CAREG001"))out.u8(static_cast<std::uint8_t>(c));out.u32(1);out.u32(registry.high_water);out.u32(static_cast<std::uint32_t>(registry.records.size()));
    std::vector<const RegionRecord*> order;for(const auto& record:registry.records)order.push_back(&record);std::sort(order.begin(),order.end(),[](auto* a,auto* b){return a->stable_id<b->stable_id;});
    for(const auto* pointer:order){const auto& r=*pointer;const auto& s=r.semantics;const auto& shape=*r.shape;out.u32(r.stable_id);out.u32(static_cast<std::uint32_t>(s.role));out.u32(s.allowed_asset_categories);out.f64(s.density_multiplier);
        out.u8(s.allow_stacking);out.u8(s.excluded);out.f64(s.front_direction.x);out.f64(s.front_direction.y);out.f64(s.front_direction.z);out.string(s.label);out.string(s.compartment_label);
        out.f64(r.minimum_clearance_mm);out.u8(r.open_above);out.u64(static_cast<std::uint64_t>(shape.cell_size_um));out.u32(static_cast<std::uint32_t>(shape.source_keys.size()));for(auto key:shape.source_keys)out.u64(key);
        out.u32(static_cast<std::uint32_t>(shape.cells.size()));for(auto cell:shape.cells){out.u64(std::bit_cast<std::uint64_t>(cell.x));out.u64(std::bit_cast<std::uint64_t>(cell.y));out.u64(std::bit_cast<std::uint64_t>(cell.z));}}
    return std::move(out.bytes);
}
std::shared_ptr<const RegionRegistry> decode_region_registry(std::span<const std::uint8_t> bytes,const RegionRegistrySettings& settings){
    settings_valid(settings);require(bytes.size()<=settings.max_bytes,"Region registry payload exceeds byte limit.");Budget budget{0,settings.max_work};Reader in{bytes,0,budget};
    for(auto c:std::string("CAREG001"))require(in.u8()==static_cast<std::uint8_t>(c),"Region registry magic is invalid.");require(in.u32()==1,"Unsupported region registry schema.");
    auto registry=std::make_shared<RegionRegistry>();registry->high_water=in.u32();const auto count=in.u32();require(count<=settings.max_regions,"Registry payload record count exceeds limit.");registry->records.reserve(count);
    std::size_t sources=0,cells=0;
    for(std::uint32_t i=0;i<count;++i){RegionRecord r;r.stable_id=in.u32();auto& s=r.semantics;s.role=static_cast<SupportRole>(in.u32());s.allowed_asset_categories=in.u32();s.density_multiplier=in.f64();
        s.allow_stacking=in.boolean();s.excluded=in.boolean();s.front_direction={in.f64(),in.f64(),in.f64()};s.label=in.string();s.compartment_label=in.string();r.minimum_clearance_mm=in.f64();r.open_above=in.boolean();
        auto shape=std::make_shared<RegionShape>();shape->cell_size_um=std::bit_cast<std::int64_t>(in.u64());const auto source_count=in.u32();require(source_count<=settings.max_source_keys-sources,"Decoded source-key count exceeds limit.");sources+=source_count;
        in.remaining(static_cast<std::size_t>(source_count)*8);shape->source_keys.reserve(source_count);for(std::uint32_t j=0;j<source_count;++j)shape->source_keys.push_back(in.u64());
        const auto cell_count=in.u32();require(cell_count<=settings.max_cells-cells,"Decoded region-cell count exceeds limit.");cells+=cell_count;in.remaining(static_cast<std::size_t>(cell_count)*24);shape->cells.reserve(cell_count);
        for(std::uint32_t j=0;j<cell_count;++j)shape->cells.push_back({std::bit_cast<std::int64_t>(in.u64()),std::bit_cast<std::int64_t>(in.u64()),std::bit_cast<std::int64_t>(in.u64())});
        if(!shape->cells.empty())shape->bounds=shape_bounds(*shape);r.shape=std::move(shape);registry->records.push_back(std::move(r));}
    require(in.at==bytes.size(),"Region registry payload has trailing bytes.");validate(*registry,settings,budget);return registry;
}
}
