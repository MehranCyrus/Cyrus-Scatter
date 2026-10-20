#include "cyrus_arrange/arrangement.h"
#include "cyrus_arrange/contact_base.h"
#include "cyrus_arrange/fit_feedback.h"

#include <algorithm>
#include <cmath>
#include <limits>
#include <map>
#include <queue>
#include <set>
#include <stdexcept>
#include <tuple>

namespace cyrus::arrange {
std::size_t validate_asset_minimums(std::span<const AssetMinimum> minimums,std::span<const Asset> assets) {
    if(minimums.size()>256||assets.size()>256)throw std::invalid_argument("Prop minimums exceed 256 sources.");
    std::set<std::uint64_t> known,seen;for(const auto& a:assets)known.insert(a.id);
    std::size_t total=0;
    for(const auto& m:minimums){
        if(!known.contains(m.asset_id)||!seen.insert(m.asset_id).second||m.quantity==0||m.quantity>10000-total)
            throw std::invalid_argument("Minimum copies require unique registered source IDs and a combined count in 1..10000.");
        total+=m.quantity;
    }
    return total;
}
namespace {
constexpr double pi=3.14159265358979323846;
constexpr std::size_t hard_placements=10000, hard_candidates=200000, hard_depth=8;
constexpr std::uint64_t hard_work=50000000;
struct Budget {
    std::uint64_t used{},limit{};
    void spend(std::uint64_t n=1) {
        if(n>limit-used) throw std::runtime_error("Arrange placement work limit exceeded; reduce density, source geometry or target scope.");
        used+=n;
    }
};
std::uint64_t hash(std::uint64_t x) {
    x+=0x9e3779b97f4a7c15ULL; x=(x^(x>>30))*0xbf58476d1ce4e5b9ULL;
    x=(x^(x>>27))*0x94d049bb133111ebULL; return x^(x>>31);
}
struct Random {
    std::uint64_t state;
    double unit() {state=hash(state); return static_cast<double>(state>>11)*0x1.0p-53;}
    std::size_t index(std::size_t size) {return std::min(size-1,static_cast<std::size_t>(unit()*static_cast<double>(size)));}
};
bool finite(Vec3 p) {return std::isfinite(p.x)&&std::isfinite(p.y)&&std::isfinite(p.z);}
bool coordinate(Vec3 p) {return finite(p)&&std::max({std::abs(p.x),std::abs(p.y),std::abs(p.z)})<=1e9;}
void validate_settings(const ArrangeSettings& s) {
    for(double value:{s.density,s.cluster_strength,s.height_variation,s.empty_space})
        if(!std::isfinite(value)||value<0||value>1) throw std::invalid_argument("Density, clustering, height variation and empty space must be finite values in [0,1].");
    if(!std::isfinite(s.spacing_mm)||s.spacing_mm<0||s.spacing_mm>1000000 ||
       !std::isfinite(s.edge_clearance_mm)||s.edge_clearance_mm<0||s.edge_clearance_mm>1000000)
        throw std::invalid_argument("Placement spacing and edge clearance must be finite and within 0..1000000 mm.");
    if(s.style>=ArrangeStyle::Count||s.category>=FurnitureCategory::Count)
        throw std::invalid_argument("Unknown arrangement style or furniture category.");
    if(s.amount_mode>=AmountMode::Count||s.quantity>hard_placements||(s.amount_mode==AmountMode::Quantity&&s.quantity>s.max_placements)||
       !std::isfinite(s.scale_min)||!std::isfinite(s.scale_max)||s.scale_min<0.01||
       s.scale_max>100||s.scale_min>s.scale_max||(s.fit_to_space&&s.scale_min>1))
        throw std::invalid_argument("Quantity must fit the output limit; scale range must be finite in [0.01,100], and fit minimum at most 1.");
    if(s.max_placements==0||s.max_placements>hard_placements||s.max_candidates==0||s.max_candidates>hard_candidates||
       s.max_stack_depth==0||s.max_stack_depth>hard_depth||s.max_work==0||s.max_work>hard_work)
        throw std::invalid_argument("Placement limits exceed hard bounds: 10000 placements, 200000 candidates, depth 8, work 50000000.");
}
Vec3 transform(Vec3 p,const Asset& a,const Placement& placement) {
    const double angle=std::remainder(placement.yaw_degrees,360.0)*pi/180.0;
    const double c=std::cos(angle),s=std::sin(angle);
    const double x=(p.x-a.anchor.x)*placement.scale,y=(p.y-a.anchor.y)*placement.scale;
    return {placement.position.x+c*x-s*y,placement.position.y+s*x+c*y,
            placement.position.z+(p.z-a.anchor.z)*placement.scale};
}
double footprint_area(const Asset& a) {
    double sum=0;
    for(std::size_t i=0;i<a.contact_footprint.size();++i) {
        const auto& p=a.contact_footprint[i];const auto& q=a.contact_footprint[(i+1)%a.contact_footprint.size()];
        sum+=(p.x-a.anchor.x)*(q.y-a.anchor.y)-(q.x-a.anchor.x)*(p.y-a.anchor.y);
    }
    // Fill estimates occupied room, not just the part that touches the surface.
    // A narrow pot must not request foliage-sized props as if each were tiny.
    const double body=(a.bounds.max.x-a.bounds.min.x)*(a.bounds.max.y-a.bounds.min.y);
    return std::max(std::abs(sum)*0.5,body);
}
const CategoryRule* rule_for(const FurniturePreset& preset,AssetCategory category) {
    const auto found=std::find_if(preset.rules.begin(),preset.rules.end(),[category](const CategoryRule& r){return r.category==category;});
    return found==preset.rules.end()?nullptr:&*found;
}
std::uint64_t identifier(std::uint64_t seed,std::uint32_t region,std::size_t ordinal,std::uint64_t asset,std::uint64_t parent=0) {
    auto id=hash(seed^0x414e52414e474531ULL);
    id=hash(id^region);id=hash(id^static_cast<std::uint64_t>(ordinal));id=hash(id^asset);id=hash(id^parent);
    return id==0?1:id;
}
struct RegionPlan {
    const Region* region{};
    std::vector<const Cell*> cells;
    std::size_t target{};
    double cell_size{};
    std::size_t initial_count{};
};
class ExternalPlacements final:public PlacementQuery {
    const PlacementQuery& query_;std::span<const PlacedObstacle> outside_;
    mutable std::vector<PlacedObstacle> scratch_;
public:
    ExternalPlacements(const PlacementQuery& query,std::span<const PlacedObstacle> outside):query_(query),outside_(outside){}
    SupportCenterHint support_center(Vec3 near,std::uint64_t work)const override{return query_.support_center(near,work);}
    QueryResult validate(const PlacementProbe& probe)const override {
        if(outside_.empty())return query_.validate(probe);
        const auto copies=outside_.size()+probe.accepted.size();
        if(copies>10000||copies>probe.remaining_work)throw std::runtime_error("Regional collision staging exceeds its work or placement budget.");
        scratch_.assign(outside_.begin(),outside_.end());scratch_.insert(scratch_.end(),probe.accepted.begin(),probe.accepted.end());
        auto staged=probe;staged.accepted=scratch_;staged.remaining_work-=copies;auto result=query_.validate(staged);
        if(result.work_units>staged.remaining_work)throw std::runtime_error("Regional collision query exceeded its remaining work.");
        result.work_units+=copies;return result;
    }
};
Budget composition_budget(std::uint64_t limit) {
    if(!limit||limit>hard_work)throw std::invalid_argument("Composition work allowance must be in 1..50000000.");
    return {0,limit};
}
Vec3 row_front(Vec3 v) {
    const double length=std::hypot(v.x,v.y);
    if(!finite(v)||std::abs(v.z)>1e-9||length<1e-9||length>1e6)
        throw std::invalid_argument("Composition front must be a finite nonzero horizontal direction.");
    return {v.x/length,v.y/length,0};
}
double row_dot(Vec3 a,Vec3 b) {return a.x*b.x+a.y*b.y;}
std::pair<double,double> projection(const OrientedBox& box,Vec3 axis) {
    const double angle=std::remainder(box.yaw_degrees,360.0)*pi/180.0,c=std::cos(angle),s=std::sin(angle);
    const double radius=std::abs(axis.x*c+axis.y*s)*box.half_extents.x+
        std::abs(-axis.x*s+axis.y*c)*box.half_extents.y;
    const double centre=row_dot(box.center,axis);return {centre-radius,centre+radius};
}
double face_yaw(SpineFace face) {
    switch(face){case SpineFace::NegativeX:return 180;case SpineFace::PositiveX:return 0;
        case SpineFace::NegativeY:return -90;case SpineFace::PositiveY:return 90;default:throw std::invalid_argument("Unknown spine face.");}
}
}

OrientedBox placement_bounds(const Asset& asset,const Placement& placement) {
    const Vec3 midpoint{(asset.bounds.min.x+asset.bounds.max.x)*0.5,(asset.bounds.min.y+asset.bounds.max.y)*0.5,
        (asset.bounds.min.z+asset.bounds.max.z)*0.5};
    return {transform(midpoint,asset,placement),{(asset.bounds.max.x-asset.bounds.min.x)*placement.scale*0.5,
        (asset.bounds.max.y-asset.bounds.min.y)*placement.scale*0.5,(asset.bounds.max.z-asset.bounds.min.z)*placement.scale*0.5},placement.yaw_degrees};
}
void validate_arrange_settings(const ArrangeSettings& settings){validate_settings(settings);}
std::vector<Vec3> placement_footprint(const Asset& asset,const Placement& placement,bool top_patch) {
    const auto& source=top_patch?asset.stack_footprint:asset.contact_footprint;
    std::vector<Vec3> result;result.reserve(source.size());
    for(const auto point:source) result.push_back(transform(point,asset,placement));
    return result;
}

void validate_composition_options(const CompositionOptions& options,FurnitureCategory category) {
    if(category>=FurnitureCategory::Count||options.minimum_books<2||options.maximum_books>6||options.minimum_books>options.maximum_books||
        !std::isfinite(options.row_gap_mm)||options.row_gap_mm<0||options.row_gap_mm>1000000||
        !std::isfinite(options.row_height_balance)||options.row_height_balance<0||options.row_height_balance>1)
        throw std::invalid_argument("Book rows require 2..6 members, finite gap in 0..1000000 mm and balance in [0,1].");
}

std::uint64_t validate_composition_structure(std::span<const CompositionGroup> groups,std::span<const Placement> poses,std::uint64_t limit) {
    auto budget=composition_budget(limit);
    if(groups.size()>5000||poses.size()>hard_placements)throw std::invalid_argument("Composition input exceeds 5000 groups or 10000 placements.");
    std::map<std::uint64_t,const Placement*> placements;
    for(const auto& p:poses){budget.spend();if(!p.stable_id||!placements.emplace(p.stable_id,&p).second)throw std::invalid_argument("Composition placement IDs must be nonzero and unique.");}
    std::set<std::uint64_t> group_ids,members;std::size_t count=0;
    for(const auto& group:groups){budget.spend();
        if(!group.stable_id||!group_ids.insert(group.stable_id).second||group.kind!=CompositionKind::BookRow||!group.region_id||
            group.member_ids.size()<2||group.member_ids.size()>6||!std::isfinite(group.gap_mm)||group.gap_mm<0||group.gap_mm>1000000)
            throw std::invalid_argument("Invalid composition identity, kind, region, gap or member count.");
        (void)row_front(group.front_direction);
        if(group.member_ids.size()>hard_placements-count)throw std::invalid_argument("Composition member references exceed 10000.");count+=group.member_ids.size();
        for(const auto id:group.member_ids){budget.spend();const auto found=placements.find(id);
            if(!members.insert(id).second||found==placements.end()||found->second->region_id!=group.region_id||found->second->parent_stack_id)
                throw std::invalid_argument("Composition members must exist once, share a region and have no stack parent.");}
    }
    for(const auto& p:poses){budget.spend();if(p.parent_stack_id&&members.contains(p.parent_stack_id))throw std::invalid_argument("A book row member cannot support a stack child.");}
    return budget.used;
}

std::uint64_t validate_book_row_relationship(const CompositionGroup& group,std::span<const Placement> poses,
    std::span<const Asset> assets,Vec3 current_front,std::uint64_t limit) {
    auto budget=composition_budget(limit);
    if(assets.size()>256||poses.size()<2||poses.size()>6||group.member_ids.size()!=poses.size()||
        !group.stable_id||!group.region_id||group.kind!=CompositionKind::BookRow||!std::isfinite(group.gap_mm)||group.gap_mm<0||group.gap_mm>1000000)
        throw std::invalid_argument("Invalid book row relationship input.");
    const auto front=row_front(group.front_direction),current=row_front(current_front);const Vec3 lateral{-front.y,front.x,0};
    const auto angle=[](Vec3 a,Vec3 b){return std::abs(std::atan2(a.x*b.y-a.y*b.x,row_dot(a,b))*180/pi);};
    if(angle(front,current)>0.0001)throw std::invalid_argument("Protected book row front differs from its current regional front.");
    std::set<std::uint64_t> ids;double previous_max=0,front_edge=0;
    for(std::size_t i=0;i<poses.size();++i){budget.spend();const auto& p=poses[i];
        if(p.stable_id!=group.member_ids[i]||!ids.insert(p.stable_id).second||p.region_id!=group.region_id||p.parent_stack_id||
            !coordinate(p.position)||!std::isfinite(p.yaw_degrees)||!std::isfinite(p.scale)||p.scale<=0||p.scale>1000||
            std::abs(p.position.z-poses.front().position.z)>0.01)
            throw std::invalid_argument("Book row members require ordered unique IDs, upright finite poses and a common support plane.");
        const Asset* asset=nullptr;
        for(const auto& a:assets){budget.spend();if(a.id==p.asset_id){if(asset)throw std::invalid_argument("Duplicate row asset identity.");asset=&a;}}
        if(!asset||asset->category!=AssetCategory::Book||!asset->book_row||asset->book_row->spine_face>=SpineFace::Count||
            !coordinate(asset->bounds.min)||!coordinate(asset->bounds.max)||!coordinate(asset->anchor)||
            asset->bounds.max.x<=asset->bounds.min.x||asset->bounds.max.y<=asset->bounds.min.y||asset->bounds.max.z<=asset->bounds.min.z||
            !std::isfinite(asset->min_scale)||!std::isfinite(asset->max_scale)||asset->min_scale<=0||asset->max_scale<asset->min_scale||
            p.scale<asset->min_scale-1e-5*std::max(1.0,asset->min_scale)||p.scale>asset->max_scale+1e-5*std::max(1.0,asset->max_scale)||
            asset->allowed_yaws_degrees.empty()||asset->allowed_yaws_degrees.size()>64||std::abs(asset->anchor.z-asset->bounds.min.z)>0.01)
            throw std::invalid_argument("Protected row lost its prepared upright Book profile, bounds or authored scale range.");
        const double expected=std::atan2(front.y,front.x)*180/pi-face_yaw(asset->book_row->spine_face);
        if(std::abs(std::remainder(std::remainder(p.yaw_degrees,360.0)-expected,360.0))>0.0001)
            throw std::invalid_argument("Book row spine faces no longer align with its authored front.");
        bool allowed=false;for(double yaw:asset->allowed_yaws_degrees){budget.spend();if(!std::isfinite(yaw))throw std::invalid_argument("Invalid row asset yaw.");
            if(std::abs(std::remainder(std::remainder(p.yaw_degrees,360.0)-std::remainder(yaw,360.0),360.0))<=0.0001)allowed=true;}
        if(!allowed)throw std::invalid_argument("Protected row uses a rotation no longer allowed by its asset.");
        const auto box=placement_bounds(*asset,p);const auto side=projection(box,lateral),depth=projection(box,front);
        if(i&&(std::abs(depth.second-front_edge)>0.01||std::abs(side.first-previous_max-group.gap_mm)>0.01))
            throw std::invalid_argument("Book row front alignment or saved internal gap was broken; unlock and regenerate the complete row.");
        previous_max=side.second;if(i==0)front_edge=depth.second;
    }
    return budget.used;
}

ProtectionClosure close_protected_placements(std::span<const Placement> poses,std::span<const CompositionGroup> groups,
    std::span<const std::uint64_t> initial,std::uint64_t limit) {
    auto budget=composition_budget(limit);budget.spend(validate_composition_structure(groups,poses,budget.limit-budget.used));
    if(initial.size()>hard_placements)throw std::invalid_argument("Too many initial protected IDs.");
    std::map<std::uint64_t,const Placement*> previous;for(const auto& p:poses){budget.spend();previous.emplace(p.stable_id,&p);}
    std::set<std::uint64_t> keep;
    for(auto id:initial){budget.spend();if(!previous.contains(id))throw std::invalid_argument("Unknown initial protected placement.");keep.insert(id);}
    bool changed=true;
    while(changed){changed=false;
        for(const auto& p:poses){budget.spend();if(!p.parent_stack_id)continue;
            if(keep.contains(p.stable_id)){if(!previous.contains(p.parent_stack_id))throw std::invalid_argument("Protected stack is missing its parent.");if(keep.insert(p.parent_stack_id).second)changed=true;}
            if(keep.contains(p.parent_stack_id)&&keep.insert(p.stable_id).second)changed=true;}
        for(const auto& group:groups){bool retained=false;for(auto id:group.member_ids){budget.spend();retained=retained||keep.contains(id);}
            if(retained)for(auto id:group.member_ids){budget.spend();if(keep.insert(id).second)changed=true;}}
    }
    for(auto id:keep){std::set<std::uint64_t> path;auto at=id;std::size_t depth=0;
        while(at){budget.spend();if(!previous.contains(at)||!path.insert(at).second||++depth>hard_depth)throw std::invalid_argument("Protected support component is missing, cyclic or deeper than eight.");at=previous.at(at)->parent_stack_id;}}
    ProtectionClosure result;result.placement_ids.assign(keep.begin(),keep.end());
    for(const auto& group:groups){budget.spend();if(keep.contains(group.member_ids.front()))result.group_ids.push_back(group.stable_id);}
    std::sort(result.group_ids.begin(),result.group_ids.end(),[&](auto a,auto b){budget.spend();return a<b;});result.work=budget.used;return result;
}

static void complete_feedback(const ArrangementRequest& request,const ArrangeSettings& settings,const PlacementQuery& geometry,ArrangementResult& result,const FitFailureRecorder& failures) {
    std::map<std::uint64_t,const Asset*> assets;
    std::map<std::uint64_t,CollisionSource> sources;
    for(const auto& a:request.assets){assets.emplace(a.id,&a);sources.try_emplace(a.id,a);}
    std::map<std::uint32_t,const RegionPlacementRule*> policies;
    for(const auto& p:request.region_rules)policies.emplace(p.region_id,&p);
    std::map<std::uint64_t,std::uint64_t> group_ids;
    for(const auto& group:result.groups)for(const auto id:group.member_ids)group_ids.emplace(id,group.stable_id);
    const auto pose=[&](const Placement& p){return CollisionPose{&sources.at(p.asset_id),p.position,p.yaw_degrees,p.scale};};
    std::vector<PlacedObstacle> obstacles;obstacles.reserve(result.placements.size());
    for(const auto& p:result.placements){const auto group=group_ids.find(p.stable_id);obstacles.push_back({p.stable_id,placement_bounds(*assets.at(p.asset_id),p),group==group_ids.end()?0:group->second,pose(p)});}
    result.feedback=failures.finish(result,request.minimums,settings,[&](const Placement&,Placement& trial,std::uint64_t remaining){
        const auto& asset=*assets.at(trial.asset_id);const auto footprint=placement_footprint(asset,trial);const auto box=placement_bounds(asset,trial);
        const auto found=policies.find(trial.region_id);const auto* policy=found==policies.end()?nullptr:found->second;
        if(policy&&policy->excluded)return QueryResult{Rejection::Category,0,{FitIssue::Excluded}};
        const PlacementProbe probe{footprint,box,trial.position.z,trial.region_id,obstacles,0,{},settings.edge_clearance_mm,settings.spacing_mm,remaining,
            policy?std::optional<Vec3>(policy->front_direction):std::nullopt,{},pose(trial)};
        return geometry.validate(probe);
    });
}

static ArrangementResult arrange_with_feedback(const ArrangementRequest& request,const ArrangeSettings& settings,const PlacementQuery& geometry,FitFailureRecorder* shared_failures,unsigned recovery_mode=0,std::optional<FitFailureRecorder>* deferred_failures=nullptr) {
    validate_settings(settings);
    validate_composition_options(request.composition,settings.category);
    if(request.assets.size()>256||request.regions.size()>4096||request.previous.size()>hard_placements||
       request.locked_ids.size()>hard_placements||request.regenerate_region_ids.size()>4096||request.region_rules.size()>4096)
        throw std::invalid_argument("Arrangement input count exceeds the asset, region or placement limits.");
    Budget budget{0,settings.max_work};
    budget.spend(request.minimums.size());
    const auto minimum_total=validate_asset_minimums(request.minimums,request.assets);
    if(request.composition.book_rows&&!request.minimums.empty())throw std::invalid_argument("Per-prop minimums require ordinary geometry placement; disable book-row composition first.");
    if(settings.amount_mode==AmountMode::Quantity&&minimum_total>settings.quantity)throw std::invalid_argument("Minimum copies exceed Copies. Raise Copies or lower a prop minimum.");
    std::map<std::uint64_t,const Asset*> assets;
    std::size_t vertices=0,triangles=0;
    for(const auto& asset:request.assets) {
        if(asset.mesh.vertices.size()>1000000-vertices||asset.mesh.triangles.size()>1000000-triangles)
            throw std::invalid_argument("Arrangement asset geometry exceeds the total 1000000 vertex/triangle bound.");
        vertices+=asset.mesh.vertices.size();triangles+=asset.mesh.triangles.size();
        budget.spend(1+asset.mesh.vertices.size()+asset.mesh.triangles.size()+asset.contact_footprint.size()+asset.stack_footprint.size());
        validate_asset(asset);
        if(!assets.emplace(asset.id,&asset).second) throw std::invalid_argument("Duplicate arrangement asset ID.");
    }
    std::map<std::uint64_t,CollisionSource> colliders;
    for(const auto& a:request.assets){budget.spend();colliders.try_emplace(a.id,a);}
    const auto collider_pose=[&](const Placement& p){return CollisionPose{&colliders.at(p.asset_id),p.position,p.yaw_degrees,p.scale};};
    std::map<std::uint32_t,const Region*> regions;
    std::size_t input_cells=0;
    for(const auto& region:request.regions) {
        if(region.id==0||!regions.emplace(region.id,&region).second) throw std::invalid_argument("Support region IDs must be nonzero and unique.");
        if(region.cells.size()>1000000-input_cells) throw std::invalid_argument("Arrangement support cells exceed 1000000.");
        input_cells+=region.cells.size();budget.spend(1+region.cells.size());
        if(!coordinate(region.bounds.min)||!coordinate(region.bounds.max)||region.bounds.min.x>region.bounds.max.x||
            region.bounds.min.y>region.bounds.max.y||region.bounds.min.z>region.bounds.max.z||
            !std::isfinite(region.sampled_area_mm2)||!std::isfinite(region.usable_area_mm2)||
            region.sampled_area_mm2<0||region.usable_area_mm2<0||region.usable_area_mm2>region.sampled_area_mm2)
            throw std::invalid_argument("Invalid support region bounds or sampled area.");
        for(const auto& cell:region.cells)
            if(!coordinate(cell.center)||std::isnan(cell.clearance_mm)||cell.clearance_mm<0||
               (cell.usable&&cell.clearance_mm<=0)) throw std::invalid_argument("Invalid support cell coordinate, clearance or usability.");
    }
    std::map<std::uint32_t,const RegionPlacementRule*> region_rules;
    for(const auto& rule:request.region_rules) {
        budget.spend();
        const double length=std::hypot(rule.front_direction.x,rule.front_direction.y);
        if(!regions.contains(rule.region_id)||!region_rules.emplace(rule.region_id,&rule).second||
           (rule.allowed_asset_categories&~all_asset_mask)!=0||!std::isfinite(rule.density_multiplier)||
           rule.density_multiplier<0||rule.density_multiplier>4||!finite(rule.front_direction)||
           std::abs(rule.front_direction.z)>1e-9||length<1e-9||length>1e6)
            throw std::invalid_argument("Region rules require unique current region IDs, valid category masks, density in [0,4] and a finite horizontal front direction.");
    }
    const auto policy_for=[&](std::uint32_t id)->const RegionPlacementRule* {
        const auto it=region_rules.find(id);return it==region_rules.end()?nullptr:it->second;
    };
    std::set<std::uint32_t> selected;
    for(const auto id:request.regenerate_region_ids)
        if(!regions.contains(id)||!selected.insert(id).second) throw std::invalid_argument("Selective regeneration region IDs must exist and be unique.");
    const auto is_selected=[&](std::uint32_t id){return selected.empty()||selected.contains(id);};
    std::map<std::uint64_t,const Placement*> previous;
    for(const auto& placement:request.previous) {
        budget.spend();
        if(placement.stable_id==0||!previous.emplace(placement.stable_id,&placement).second||!coordinate(placement.position)||!std::isfinite(placement.yaw_degrees)||
           !std::isfinite(placement.scale)||placement.scale<=0||placement.scale>1000)
            throw std::invalid_argument("Previous placements require unique stable IDs and finite transforms.");
    }
    std::set<std::uint64_t> keep;
    for(const auto& [id,p]:previous) if(p->locked||!is_selected(p->region_id)) keep.insert(id);
    std::set<std::uint64_t> explicit_locks;
    for(const auto id:request.locked_ids) {
        budget.spend();
        if(!previous.contains(id)) throw std::invalid_argument("A locked placement ID does not exist in previous output.");
        if(!explicit_locks.insert(id).second) throw std::invalid_argument("Locked placement IDs must be unique.");
        keep.insert(id);
    }
    std::map<std::uint64_t,GroupSpacing> protected_groups;
    std::vector<CompositionGroup> retained_groups;
    if(!request.previous_groups.empty()) {
        const std::vector<std::uint64_t> initial(keep.begin(),keep.end());
        const auto closure=close_protected_placements(request.previous,request.previous_groups,initial,budget.limit-budget.used);
        budget.spend(closure.work);keep=std::set<std::uint64_t>(closure.placement_ids.begin(),closure.placement_ids.end());
        for(const auto& group:request.previous_groups){budget.spend();
            if(!std::binary_search(closure.group_ids.begin(),closure.group_ids.end(),group.stable_id))continue;
            const auto* policy=policy_for(group.region_id);if(!policy)throw std::invalid_argument("Protected row requires its current regional front policy.");
            std::vector<Placement> members;members.reserve(group.member_ids.size());
            for(auto id:group.member_ids){budget.spend();members.push_back(*previous.at(id));protected_groups.emplace(id,GroupSpacing{group.stable_id,group.gap_mm});}
            budget.spend(validate_book_row_relationship(group,members,request.assets,policy->front_direction,budget.limit-budget.used));
            retained_groups.push_back(group);
        }
        std::sort(retained_groups.begin(),retained_groups.end(),[&](const auto& a,const auto& b){budget.spend();return a.stable_id<b.stable_id;});
    }
    // Preserve the original disabled-path closure and its exact budget accounting.
    bool changed=true;
    while(changed&&request.previous_groups.empty()) {
        changed=false;
        for(const auto& [id,p]:previous) {
            budget.spend();
            if(p->parent_stack_id==0) continue;
            if(keep.contains(id)) {
                if(!previous.contains(p->parent_stack_id)) throw std::invalid_argument("Protected stack is missing its support parent.");
                if(keep.insert(p->parent_stack_id).second) changed=true;
            }
            if(keep.contains(p->parent_stack_id)&&keep.insert(id).second) changed=true;
        }
    }
    std::map<std::uint64_t,std::size_t> depths;
    for(const auto id:keep) {
        const auto* placement=previous.at(id);
        if(!assets.contains(placement->asset_id)||!regions.contains(placement->region_id))
            throw std::invalid_argument("Protected placement references a missing asset or current support region; rebind before regeneration.");
        std::set<std::uint64_t> path;auto cursor=placement;std::size_t depth=0;
        while(cursor->parent_stack_id!=0) {
            budget.spend();
            if(!path.insert(cursor->stable_id).second||!previous.contains(cursor->parent_stack_id)||++depth>=hard_depth)
                throw std::invalid_argument("Protected support graph is cyclic, missing a parent or exceeds depth 8.");
            cursor=previous.at(cursor->parent_stack_id);
            if(cursor->region_id!=placement->region_id) throw std::invalid_argument("Stack parent and child must share a support region.");
        }
        depths.emplace(id,depth);
    }
    if(keep.size()>settings.max_placements) throw std::runtime_error("Protected placements exceed the requested placement limit.");
    // Tags and historical furniture masks are descriptive only. Every source
    // selected by the artist is eligible; physical acceptance decides fit.
    FurniturePreset preset;
    for(std::uint32_t i=0;i<static_cast<std::uint32_t>(AssetCategory::Count);++i)
        preset.rules.push_back({static_cast<AssetCategory>(i),1.0,static_cast<std::uint32_t>(hard_placements),true});
    std::vector<const Asset*> eligible;
    for(const auto& [id,asset]:assets) {
        (void)id;
        eligible.push_back(asset);
    }
    ArrangementResult result;
    std::optional<FitFailureRecorder> local_failures;
    if(!shared_failures)local_failures.emplace(request.assets);
    auto& failures=shared_failures?*shared_failures:*local_failures;
    result.groups=std::move(retained_groups);
    std::vector<PlacedObstacle> obstacles;
    std::map<std::uint64_t,std::size_t> output_indices;
    std::map<std::uint32_t,std::array<std::size_t,static_cast<std::size_t>(AssetCategory::Count)>> category_counts;
    std::map<std::uint32_t,std::vector<std::size_t>> region_outputs;
    std::map<std::uint64_t,std::size_t> asset_counts;
    const auto required_deficit=[&] {
        std::size_t missing=0;for(const auto& m:request.minimums){budget.spend();const auto count=asset_counts[m.asset_id];if(count<m.quantity)missing+=m.quantity-count;}return missing;
    };

    auto publish=[&](const Asset& asset,const Placement& candidate,const OrientedBox& box,std::uint64_t group_id=0) {
        if(result.placements.size()>=settings.max_placements) throw std::runtime_error("Arrange output placement limit exceeded.");
        if(!output_indices.emplace(candidate.stable_id,result.placements.size()).second) throw std::runtime_error("Duplicate generated placement identity.");
        region_outputs[candidate.region_id].push_back(result.placements.size());
        ++category_counts[candidate.region_id][static_cast<std::size_t>(asset.category)];
        ++asset_counts[asset.id];
        result.placements.push_back(candidate);obstacles.push_back({candidate.stable_id,box,group_id,collider_pose(candidate)});
    };
    auto try_placement=[&](const Asset& asset,Placement candidate,bool protected_placement,
        std::optional<GroupSpacing> group_spacing=std::nullopt,bool stage_only=false,
        const std::vector<PlacedObstacle>* staged_obstacles=nullptr,std::size_t staged_category_count=0,std::size_t category_credit=0,
        bool displaced_anchor=false) {
        if(result.stats.candidates>=settings.max_candidates) throw std::runtime_error("Arrange candidate limit exceeded; reduce density or scope.");
        ++result.stats.candidates;budget.spend(1+asset.contact_footprint.size()+asset.stack_footprint.size());
        const auto* policy=policy_for(candidate.region_id);
        if(policy&&policy->excluded) {
            ++result.stats.rejections[static_cast<std::size_t>(Rejection::Category)];
            if(protected_placement)throw std::runtime_error("Protected placement conflicts with an excluded region or its allowed asset categories; include the region in regeneration and unlock its props, or revise its policy.");
            return false;
        }
        if(policy&&!policy->allow_stacking&&candidate.parent_stack_id) {
            ++result.stats.rejections[static_cast<std::size_t>(Rejection::Stack)];
            if(protected_placement)throw std::runtime_error("Protected stack conflicts with its region's stacking policy; unlock its support-connected stack or revise the policy.");
            return false;
        }
        const auto* rule=rule_for(preset,asset.category);
        const auto category_count=category_counts[candidate.region_id][static_cast<std::size_t>(asset.category)];
        if(category_credit>category_count)throw std::logic_error("Invalid staged category credit.");
        if(category_count-category_credit+staged_category_count>=rule->maximum_count){
            ++result.stats.rejections[static_cast<std::size_t>(Rejection::Category)];
            if(protected_placement)throw std::runtime_error("Protected placement conflicts with the current category rules; unlock or revise the rule before regeneration.");
            return false;
        }
        const Placement* parent=nullptr;const Asset* parent_asset=nullptr;
        std::vector<Vec3> parent_patch;
        if((protected_placement||group_spacing||displaced_anchor)&&candidate.parent_stack_id==0) {
            const auto& current=*regions.at(candidate.region_id);
            if(current.cells.empty()||current.sampled_area_mm2<=0) throw std::runtime_error("Protected placement has no current sampled region support; rebind before regeneration.");
            const double half=0.5*std::sqrt(current.sampled_area_mm2/static_cast<double>(current.cells.size()));
            bool member=false;
            for(const auto& cell:current.cells) {
                budget.spend();
                if(std::abs(candidate.position.z-cell.center.z)<=0.01&&std::abs(candidate.position.x-cell.center.x)<=half+0.01&&
                    std::abs(candidate.position.y-cell.center.y)<=half+0.01) {member=true;break;}
            }
            if(!member) {
                if(protected_placement)throw std::runtime_error("Protected placement no longer belongs to its current sampled region; rebind before regeneration.");
                ++result.stats.rejections[static_cast<std::size_t>(Rejection::Boundary)];return false;
            }
        }
        if(candidate.parent_stack_id!=0) {
            if(!output_indices.contains(candidate.parent_stack_id)) throw std::invalid_argument("Stack candidate requires an accepted parent.");
            parent=&result.placements[output_indices.at(candidate.parent_stack_id)];parent_asset=assets.at(parent->asset_id);
            if(!parent_asset->stackable) {
                ++result.stats.rejections[static_cast<std::size_t>(Rejection::Stack)];
                if(protected_placement) throw std::runtime_error("Protected stack no longer has compatible support metadata.");
                return false;
            }
            const double expected_z=parent->position.z+parent_asset->stack_height_mm*parent->scale;
            if(std::abs(candidate.position.z-expected_z)>1e-5) throw std::invalid_argument("Stack anchor does not match its parent's authored top height.");
            parent_patch=placement_footprint(*parent_asset,*parent,true);
        }
        const auto footprint=placement_footprint(asset,candidate);
        const auto box=placement_bounds(asset,candidate);
        const PlacementProbe probe{footprint,box,candidate.position.z,candidate.region_id,staged_obstacles?std::span<const PlacedObstacle>(*staged_obstacles):std::span<const PlacedObstacle>(obstacles),candidate.parent_stack_id,
            parent_patch,candidate.parent_stack_id?0.0:settings.edge_clearance_mm,settings.spacing_mm,budget.limit-budget.used,
            policy?std::optional<Vec3>(policy->front_direction):std::nullopt,group_spacing,collider_pose(candidate)};
        const auto checked=geometry.validate(probe);budget.spend(checked.work_units);
        if(checked.reason>=Rejection::Count) throw std::runtime_error("Placement geometry returned an invalid rejection code.");
        if(checked.reason!=Rejection::None) {
            ++result.stats.rejections[static_cast<std::size_t>(checked.reason)];
            if(protected_placement) throw std::runtime_error("Protected placement no longer passes support, clearance or collision validation; previous output retained by caller.");
            if(!stage_only&&!candidate.parent_stack_id)failures.note(candidate,checked,&regions.at(candidate.region_id)->bounds);
            return false;
        }
        if(!stage_only)publish(asset,candidate,box,group_spacing?group_spacing->group_id:0);
        return true;
    };
    std::vector<std::uint64_t> kept(keep.begin(),keep.end());
    std::sort(kept.begin(),kept.end(),[&](auto a,auto b){budget.spend();return std::tie(depths.at(a),a)<std::tie(depths.at(b),b);});
    for(const auto id:kept) {
        auto placement=*previous.at(id);
        if(explicit_locks.contains(id)) placement.locked=true;
        const auto group=protected_groups.find(id);
        try_placement(*assets.at(placement.asset_id),placement,true,group==protected_groups.end()?std::nullopt:std::optional<GroupSpacing>(group->second));
    }
    result.stats.kept=result.placements.size();
    std::vector<RegionPlan> plans;
    const double style_factor=settings.style==ArrangeStyle::Minimal?0.55:settings.style==ArrangeStyle::Layered?1.35:1.0;
    std::size_t requested=result.stats.kept;
    for(const auto& [id,region]:regions) {
        if(!is_selected(id)) continue;
        const auto* policy=policy_for(id);
        if(policy&&(policy->excluded||policy->density_multiplier==0))continue;
        if(request.composition.book_rows&&!policy)throw std::invalid_argument("Enabled book rows require an explicit regional front policy.");
        RegionPlan plan;plan.region=region;
        for(const auto& cell:region->cells) if(cell.usable) plan.cells.push_back(&cell);
        if(plan.cells.empty()||eligible.empty()||(request.minimums.empty()&&settings.amount_mode==AmountMode::Fill&&(settings.density==0||settings.empty_space==1))) continue;
        double weighted_area=0,total_weight=0;
        for(const auto* asset:eligible) {
            budget.spend(1+asset->contact_footprint.size());
            const auto* rule=rule_for(preset,asset->category);
            const double weight=asset->weight*rule->weight;
            const double scale=settings.random_scale?(settings.scale_min+settings.scale_max)*0.5:1.0;
            const double slot=std::pow(std::sqrt(footprint_area(*asset)*scale*scale)+settings.spacing_mm,2);
            weighted_area+=weight*slot;total_weight+=weight;
        }
        if(total_weight==0)continue;
        if(region->sampled_area_mm2<=0) throw std::invalid_argument("Nonempty usable support requires positive sampled area.");
        plan.cell_size=std::sqrt(region->sampled_area_mm2/static_cast<double>(region->cells.size()));
        std::sort(plan.cells.begin(),plan.cells.end(),[&budget](const Cell* a,const Cell* b){budget.spend();return std::tie(a->center.x,a->center.y,a->center.z)<std::tie(b->center.x,b->center.y,b->center.z);});
        const double desired=settings.amount_mode==AmountMode::Quantity?static_cast<double>(settings.quantity):
            std::ceil(region->usable_area_mm2*settings.density*(policy?policy->density_multiplier:1.0)*(1-settings.empty_space)*style_factor/(weighted_area/total_weight));
        if(!std::isfinite(desired)||desired>static_cast<double>(settings.max_placements))
            throw std::runtime_error("Density requests too many placements for the configured limit.");
        const std::size_t already=region_outputs[id].size();
        plan.initial_count=already;
        plan.target=static_cast<std::size_t>(std::max(0.0,desired-static_cast<double>(already)));
        if(settings.amount_mode==AmountMode::Fill) {
            if(plan.target>settings.max_placements-requested) throw std::runtime_error("Density across support regions exceeds the placement limit.");
            requested+=plan.target;
        }
        plans.push_back(std::move(plan));
    }
    result.stats.requested=settings.amount_mode==AmountMode::Quantity?settings.quantity:requested;
    if(eligible.empty()) result.warnings.emplace_back("No source props are registered. Add the original models to this arrangement.");
    if(settings.amount_mode==AmountMode::Quantity&&result.stats.kept>settings.quantity)
        result.warnings.emplace_back("Protected or unselected output exceeds the requested quantity; those placements were preserved.");
    const auto initial_required_deficit=required_deficit();
    if(settings.amount_mode==AmountMode::Quantity&&initial_required_deficit>settings.quantity-std::min(settings.quantity,result.stats.kept))
        throw std::invalid_argument("Minimum copies and protected output exceed Copies. Increase Copies, lower a minimum or unprotect copies.");
    if(settings.amount_mode==AmountMode::Fill) {
        if(initial_required_deficit>settings.max_placements-result.stats.kept)throw std::invalid_argument("Minimum copies and protected output exceed the placement limit.");
        result.stats.requested=std::max(result.stats.requested,result.stats.kept+initial_required_deficit);
    }
    auto choose=[&](Random& random,std::uint32_t region,const Asset* parent_asset,bool books_only)->const Asset* {
        const auto* policy=policy_for(region);
        if(policy&&(policy->excluded||(parent_asset&&!policy->allow_stacking)))return nullptr;
        std::vector<std::pair<const Asset*,double>> choices;double sum=0;
        for(const auto* asset:eligible) {
            budget.spend();const auto* rule=rule_for(preset,asset->category);
            if(category_counts[region][static_cast<std::size_t>(asset->category)]>=rule->maximum_count) continue;
            if(books_only&&asset->category!=AssetCategory::Book) continue;
            const double weight=asset->weight*rule->weight;choices.emplace_back(asset,weight);sum+=weight;
        }
        if(choices.empty()) return nullptr;
        double pick=random.unit()*sum;
        for(const auto& [asset,weight]:choices) {if(pick<weight) return asset;pick-=weight;}
        return choices.back().first;
    };
    auto orient=[&](const Asset& asset,Placement& placement,Random& random) {
        placement.yaw_degrees=asset.allowed_yaws_degrees[random.index(asset.allowed_yaws_degrees.size())];
        placement.scale=settings.random_scale?settings.scale_min+random.unit()*(settings.scale_max-settings.scale_min):1.0;
    };
    // Fit searches only shrink the sampled/original size. Each probe uses the
    // same full physical query and is staged without changing accepted output.
    // Nonmonotone irregular geometry is searched at bounded descending samples;
    // bisection refines a verified valid/invalid bracket, never an unchecked box.
    auto try_fitted=[&](const Asset& asset,Placement& candidate,bool displaced_anchor,bool allow_fit) {
        if(result.stats.candidates>=settings.max_candidates)
            throw std::runtime_error("Arrange candidate budget exhausted; previous output retained by caller.");
        if(try_placement(asset,candidate,false,std::nullopt,false,nullptr,0,0,displaced_anchor))return true;
        if(!allow_fit||candidate.scale<=settings.scale_min)return false;
        const double original=candidate.scale;double upper=original;
        std::optional<Placement> best;
        for(unsigned step=1;step<=16&&result.stats.candidates<settings.max_candidates;++step) {
            candidate.scale=step==16?settings.scale_min:original*std::pow(settings.scale_min/original,static_cast<double>(step)/16);
            if(try_placement(asset,candidate,false,std::nullopt,true,nullptr,0,0,displaced_anchor)){best=candidate;break;}
            upper=candidate.scale;
        }
        if(!best)return false;
        for(unsigned step=0;step<12&&result.stats.candidates<settings.max_candidates;++step) {
            candidate.scale=(upper+best->scale)*0.5;
            if(try_placement(asset,candidate,false,std::nullopt,true,nullptr,0,0,displaced_anchor))best=candidate;
            else upper=candidate.scale;
        }
        candidate=*best;publish(asset,candidate,placement_bounds(asset,candidate),0);++result.stats.scaled_to_fit;return true;
    };
    std::set<std::uint64_t> composition_ids;
    for(const auto& group:result.groups){budget.spend();composition_ids.insert(group.stable_id);}
    auto row_yaws=[&](const Asset& asset,Vec3 front) {
        std::vector<double> yaws;
        if(!asset.book_row)return yaws;
        const double target=std::atan2(front.y,front.x)*180/pi-face_yaw(asset.book_row->spine_face);
        for(double yaw:asset.allowed_yaws_degrees){budget.spend();if(std::abs(std::remainder(std::remainder(yaw,360.0)-target,360.0))<=0.0001)yaws.push_back(yaw);}
        std::sort(yaws.begin(),yaws.end(),[&](double a,double b){budget.spend();return a<b;});return yaws;
    };
    std::vector<PlacedObstacle> row_scratch;
    // Ordinary geometry placement: reserve required source counts, then sample
    // a finite optional demand and place its largest volumes before small fill.
    // A fair area-normalized search queue prevents low region IDs monopolizing
    // Quantity. No semantic furniture/category eligibility is introduced.
    if(!request.composition.book_rows&&request.minimums.empty()&&settings.amount_mode==AmountMode::Fill&&plans.size()>1) {
        // Fill is a regional density contract: adding another receiving surface
        // must not reroll an unchanged region. Each regional priority solve has
        // the same seed and target as a standalone solve, with other accepted
        // regions supplied as explicit collision obstacles. All repeated work
        // and scratch copies are charged to this command's existing allowance.
        for(const auto& plan:plans) {
            std::vector<Placement> prior;std::set<std::uint64_t> prior_ids;
            for(const auto& p:request.previous){budget.spend();if(p.region_id==plan.region->id){prior.push_back(p);prior_ids.insert(p.stable_id);}}
            std::vector<std::uint64_t> locks;for(auto id:request.locked_ids)if(prior_ids.contains(id))locks.push_back(id);
            std::vector<CompositionGroup> groups;for(const auto& g:request.previous_groups)if(g.region_id==plan.region->id)groups.push_back(g);
            std::vector<PlacedObstacle> outside;for(std::size_t i=0;i<result.placements.size();++i){budget.spend();if(result.placements[i].region_id!=plan.region->id)outside.push_back(obstacles[i]);}
            auto sub=request;sub.regions=std::span<const Region>(plan.region,1);sub.previous=prior;sub.locked_ids=locks;sub.regenerate_region_ids={};sub.previous_groups=groups;
            const auto* policy=policy_for(plan.region->id);sub.region_rules=policy?std::span<const RegionPlacementRule>(policy,1):std::span<const RegionPlacementRule>{};
            auto limits=settings;limits.max_work=budget.limit-budget.used;limits.max_candidates=settings.max_candidates-result.stats.candidates;limits.max_placements=settings.max_placements-outside.size();
            if(!limits.max_work||!limits.max_candidates)throw std::runtime_error("Regional Fill exhausted its command budget; previous output retained by caller.");
            ExternalPlacements bounded_query(geometry,outside);const auto regional=arrange_with_feedback(sub,limits,bounded_query,&failures);budget.spend(regional.stats.work);result.stats.candidates+=regional.stats.candidates;
            for(std::size_t i=0;i<result.stats.rejections.size();++i)result.stats.rejections[i]+=regional.stats.rejections[i];
            result.stats.scaled_to_fit+=regional.stats.scaled_to_fit;
            for(const auto& p:regional.placements)if(!keep.contains(p.stable_id))publish(*assets.at(p.asset_id),p,placement_bounds(*assets.at(p.asset_id),p));
        }
    } else if(!request.composition.book_rows) {
        struct Space {double score{};std::uint64_t tie{};std::size_t index{};};
        struct Later {Budget* budget;bool operator()(const Space& a,const Space& b)const{budget->spend();return std::tie(a.score,a.tie,a.index)>std::tie(b.score,b.tie,b.index);}};
        std::map<std::uint32_t,std::size_t> plan_indices;
        std::vector<double> used_area(plans.size());
        for(std::size_t i=0;i<plans.size();++i)plan_indices.emplace(plans[i].region->id,i);
        for(const auto& p:result.placements)if(!p.parent_stack_id){budget.spend();if(auto it=plan_indices.find(p.region_id);it!=plan_indices.end()){const auto b=placement_bounds(*assets.at(p.asset_id),p);used_area[it->second]+=4*b.half_extents.x*b.half_extents.y;}}
        std::map<std::uint64_t,std::size_t> minima,desired;
        for(const auto& a:eligible)desired[a->id]=asset_counts[a->id];
        for(const auto& m:request.minimums){minima[m.asset_id]=m.quantity;desired[m.asset_id]=std::max(desired[m.asset_id],m.quantity);}
        const auto optional_count=result.stats.requested-std::min(result.stats.requested,result.stats.kept+initial_required_deficit);
        std::vector<double> cumulative;double total_weight=0;
        for(const auto* a:eligible){total_weight+=a->weight;cumulative.push_back(total_weight);}
        auto pick_source=[&](Random& random)->const Asset* {
            if(eligible.empty())return nullptr;
            const double key=random.unit()*total_weight;
            const auto it=std::upper_bound(cumulative.begin(),cumulative.end(),key,[&](double a,double b){budget.spend();return a<b;});
            return eligible[std::min<std::size_t>(eligible.size()-1,static_cast<std::size_t>(it-cumulative.begin()))];
        };
        Random demand_random{hash(settings.seed^0x44454d414e443032ULL)};
        for(std::size_t i=0;i<optional_count;++i){budget.spend();if(const auto* a=pick_source(demand_random))++desired[a->id];}
        std::vector<const Asset*> order=eligible;
        std::sort(order.begin(),order.end(),[&](const Asset* a,const Asset* b){
            budget.spend();auto key=[](const Asset& a){const double x=a.bounds.max.x-a.bounds.min.x,y=a.bounds.max.y-a.bounds.min.y,z=a.bounds.max.z-a.bounds.min.z;return std::tuple{x*y*z,x*y,z};};
            const auto ka=key(*a),kb=key(*b);return ka!=kb?ka>kb:a->id<b->id;
        });
        std::uint64_t ordinal=0,preferred_probe_work=0;std::size_t center_hints=0,center_probes=0,preferred_scans=0,preferred_probes=0;
        const auto preferred_probe_allowance=std::min<std::uint64_t>(1000000,budget.limit/8);
        auto run_batch=[&](const Asset* fixed,std::size_t wanted,bool required) {
            const auto done=[&]{return fixed?asset_counts[fixed->id]>=wanted:result.placements.size()+required_deficit()>=result.stats.requested;};
            if(done()||plans.empty())return;
            const auto count=fixed?wanted-asset_counts[fixed->id]:result.stats.requested-result.placements.size()-required_deficit();
            const auto limit=std::min(settings.max_candidates,std::max<std::size_t>(64,count*64+plans.size()*8));
            for(unsigned pass=0;pass<(settings.fit_to_space?2u:1u)&&!done();++pass) {
                std::priority_queue<Space,std::vector<Space>,Later> spaces{Later{&budget}};
                std::vector<double> effort(plans.size());
                std::vector<std::size_t> visits(plans.size());
                for(std::size_t i=0;i<plans.size();++i){budget.spend();const auto& p=plans[i];spaces.push({used_area[i]/std::max(1.0,p.region->usable_area_mm2),hash(hash(settings.seed)^hash(p.region->id)^hash(fixed?fixed->id:0)),i});}
                for(std::size_t attempt=0;attempt<limit&&!done()&&!spaces.empty();++attempt) {
                    budget.spend();if(result.placements.size()>=result.stats.requested)break;
                    if(result.stats.candidates>=settings.max_candidates)throw std::runtime_error("Arrange candidate budget exhausted; previous output retained by caller.");
                    auto space=spaces.top();spaces.pop();const auto i=space.index;const auto& plan=plans[i];const auto region=plan.region->id;
                    Random random{hash(hash(hash(settings.seed^0x5041434b494e4732ULL)^++ordinal)^region)};
                    const auto* asset=fixed?fixed:pick_source(random);if(!asset)break;
                    const bool deficient=asset_counts[asset->id]<minima[asset->id];
                    if(!required&&!deficient&&result.placements.size()+required_deficit()>=result.stats.requested)break;
                    if(!required&&!deficient&&settings.amount_mode==AmountMode::Fill&&region_outputs[region].size()>=plan.initial_count+plan.target)continue;
                    Placement p;p.asset_id=asset->id;p.region_id=region;p.stable_id=identifier(settings.seed^0x5041434b494e4732ULL,region,ordinal,asset->id);
                    orient(*asset,p,random);const auto* cell=plan.cells[random.index(plan.cells.size())];p.position=cell->center;
                    p.position.x+=(random.unit()-0.5)*plan.cell_size*0.8;p.position.y+=(random.unit()-0.5)*plan.cell_size*0.8;
                    bool displaced=false;
                    if(++visits[i]==1||(recovery_mode&&region_outputs[region].empty()&&visits[i]<=8)) {
                        if(recovery_mode)p.yaw_degrees=asset->allowed_yaws_degrees[(visits[i]-1)%asset->allowed_yaws_degrees.size()];
                        const auto own=placement_bounds(*asset,p);
                        const double a=std::remainder(own.yaw_degrees,360.0)*pi/180,c=std::abs(std::cos(a)),sn=std::abs(std::sin(a));
                        const double spare_x=std::max(0.0,(plan.region->bounds.max.x-plan.region->bounds.min.x)*0.5-c*own.half_extents.x-sn*own.half_extents.y-settings.edge_clearance_mm);
                        const double spare_y=std::max(0.0,(plan.region->bounds.max.y-plan.region->bounds.min.y)*0.5-sn*own.half_extents.x-c*own.half_extents.y-settings.edge_clearance_mm);
                        const double x_bias=recovery_mode?((recovery_mode-1)&1?1.0:-1.0):(random.unit()-0.5)*1.6;
                        const double y_bias=recovery_mode?((recovery_mode-1)&2?1.0:-1.0):(random.unit()-0.5)*1.6;
                        p.position.x+=(plan.region->bounds.min.x+plan.region->bounds.max.x)*0.5+x_bias*spare_x-own.center.x;
                        p.position.y+=(plan.region->bounds.min.y+plan.region->bounds.max.y)*0.5+y_bias*spare_y-own.center.y;displaced=true;
                    }
                    const auto& neighbours=region_outputs[region];
                    if(!neighbours.empty()&&settings.cluster_strength>0&&random.unit()<settings.cluster_strength) {
                        const auto n=neighbours[random.index(neighbours.size())];const auto& anchor=result.placements[n];const auto& b=obstacles[n].box;
                        const auto own=placement_bounds(*asset,p);const double radius=(std::hypot(b.half_extents.x,b.half_extents.y)+std::hypot(own.half_extents.x,own.half_extents.y)+settings.spacing_mm)*(1.05+random.unit()*0.4),angle=random.unit()*2*pi;
                        p.position.x=anchor.position.x+std::cos(angle)*radius;p.position.y=anchor.position.y+std::sin(angle)*radius;displaced=true;
                    }
                    // Late, checked edge-adjacent proposals fill gaps without
                    // changing the broad initial random placement distribution.
                    if(attempt>=count*2&&attempt%4==3&&!neighbours.empty()) {
                        const auto n=neighbours[random.index(neighbours.size())];const auto& parent=result.placements[n];
                        if(!parent.parent_stack_id&&std::abs(parent.position.z-p.position.z)<0.01) {
                            const auto& b=obstacles[n].box;const auto own=placement_bounds(*asset,p);const double byaw=std::remainder(b.yaw_degrees,360.0),a=byaw*pi/180,c=std::cos(a),sn=std::sin(a),d=(std::remainder(own.yaw_degrees,360.0)-byaw)*pi/180;
                            const double x=std::abs(std::cos(d))*own.half_extents.x+std::abs(std::sin(d))*own.half_extents.y,y=std::abs(std::sin(d))*own.half_extents.x+std::abs(std::cos(d))*own.half_extents.y;
                            const auto side=random.index(4),alignment=random.index(3);const double sign=side%2?1.0:-1.0;
                            const double shift=alignment==0?0.0:(alignment==1?-1.0:1.0);
                            const double u=side<2?sign*(b.half_extents.x+x+settings.spacing_mm+0.005):shift*std::abs(b.half_extents.x-x);
                            const double v=side>=2?sign*(b.half_extents.y+y+settings.spacing_mm+0.005):shift*std::abs(b.half_extents.y-y);
                            p.position.x+=b.center.x+c*u-sn*v-own.center.x;p.position.y+=b.center.y+sn*u+c*v-own.center.y;displaced=true;
                        }
                    }
                    const double area=4*placement_bounds(*asset,p).half_extents.x*placement_bounds(*asset,p).half_extents.y;
                    effort[i]+=area*0.05;
                    bool accepted=false;
                    if(!output_indices.contains(p.stable_id))accepted=try_fitted(*asset,p,displaced,pass==1);
                    if(accepted) {
                        const auto b=placement_bounds(*asset,p);used_area[i]+=4*b.half_extents.x*b.half_extents.y;
                        // Keep authored stack supports. Source demand and global
                        // quantity still count every child once.
                        auto parent=p;const Asset* parent_asset=asset;
                        const double chance=settings.cluster_strength*(settings.style==ArrangeStyle::Layered?1.0:settings.style==ArrangeStyle::Minimal?0.25:0.7);
                        for(std::size_t depth=1;depth<settings.max_stack_depth&&parent_asset->stackable&&result.placements.size()<result.stats.requested&&random.unit()<chance;++depth) {
                            const Asset* child=nullptr;
                            for(const auto* a:order)if(asset_counts[a->id]<(required?minima[a->id]:desired[a->id])){child=a;break;}
                            if(!child)break;
                            if(!required&&asset_counts[child->id]>=minima[child->id]&&result.placements.size()+required_deficit()>=result.stats.requested)break;
                            Placement q;q.asset_id=child->id;q.region_id=region;q.parent_stack_id=parent.stable_id;q.stable_id=identifier(settings.seed^0x5041434b494e4732ULL,region,++ordinal,child->id,parent.stable_id);orient(*child,q,random);
                            const auto patch=placement_footprint(*parent_asset,parent,true);Vec3 centre{};for(auto v:patch){centre.x+=v.x;centre.y+=v.y;}centre.x/=patch.size();centre.y/=patch.size();
                            q.position={centre.x,centre.y,parent.position.z+parent_asset->stack_height_mm*parent.scale};
                            const auto foot=placement_footprint(*child,q);Vec3 offset{};for(auto v:foot){offset.x+=v.x-q.position.x;offset.y+=v.y-q.position.y;}q.position.x-=offset.x/foot.size();q.position.y-=offset.y/foot.size();
                            if(output_indices.contains(q.stable_id)||!try_placement(*child,q,false))break;parent=q;parent_asset=child;
                        }
                    }
                    space.score=(used_area[i]+effort[i])/std::max(1.0,plan.region->usable_area_mm2);spaces.push(space);
                }
                if(fixed&&!done())for(std::size_t i=0;i<std::min<std::size_t>(8,plans.size())&&!done()&&center_hints<64&&center_probes<256;++i){
                    const auto& plan=plans[i];const auto region=plan.region->id;
                    if(!required&&asset_counts[fixed->id]>=minima[fixed->id]&&settings.amount_mode==AmountMode::Fill&&region_outputs[region].size()>=plan.initial_count+plan.target)continue;
                    const Vec3 near{(plan.region->bounds.min.x+plan.region->bounds.max.x)*.5,(plan.region->bounds.min.y+plan.region->bounds.max.y)*.5,plan.cells.front()->center.z};
                    ++center_hints;const auto hint=geometry.support_center(near,budget.limit-budget.used);budget.spend(hint.work_units);
                    if(!hint.center)continue;
                    if(!finite(*hint.center))throw std::runtime_error("Support query returned a nonfinite center proposal.");
                    const auto start=hash(settings.seed^region^fixed->id)%fixed->allowed_yaws_degrees.size();
                    for(std::size_t j=0;j<std::min<std::size_t>(8,fixed->allowed_yaws_degrees.size())&&!done()&&center_probes<256&&result.stats.candidates<settings.max_candidates;++j){
                        if(result.placements.size()>=result.stats.requested)break;
                        ++center_probes;budget.spend();Random random{hash(hash(settings.seed^0x43454e5445523032ULL)^++ordinal)};
                        Placement p;p.asset_id=fixed->id;p.region_id=region;p.stable_id=identifier(settings.seed^0x43454e5445523032ULL,region,ordinal,fixed->id);orient(*fixed,p,random);
                        p.yaw_degrees=fixed->allowed_yaws_degrees[(start+j)%fixed->allowed_yaws_degrees.size()];p.position=*hint.center;
                        const auto base=placed_base_center(*fixed,p.position,p.yaw_degrees,p.scale);p.position.x+=hint.center->x-base.x;p.position.y+=hint.center->y-base.y;
                        if(!output_indices.contains(p.stable_id)&&try_fitted(*fixed,p,true,pass==1)){const auto b=placement_bounds(*fixed,p);used_area[i]+=4*b.half_extents.x*b.half_extents.y;}
                    }
                }
                // A continuous floor can run beneath several cubbies. Random
                // proposals and its outline center do not establish that the
                // preferred size has been tried in the tall usable space.
                // Headroom only proposes positions; the complete validator is
                // still authoritative for every pose before publication.
                if(pass==0&&fixed&&!done())for(std::size_t i=0;i<plans.size()&&!done()&&preferred_scans<8192&&preferred_probes<1024&&preferred_probe_work<preferred_probe_allowance;++i) {
                    const auto& plan=plans[i];const auto region=plan.region->id;
                    if(!required&&asset_counts[fixed->id]>=minima[fixed->id]&&settings.amount_mode==AmountMode::Fill&&region_outputs[region].size()>=plan.initial_count+plan.target)continue;
                    const auto allowance=8192-preferred_scans;
                    const auto stride=std::max<std::size_t>(1,(plan.cells.size()+allowance-1)/allowance);
                    const double minimum_height=(fixed->bounds.max.z-fixed->bounds.min.z)*(settings.random_scale?settings.scale_min:1.0);
                    std::vector<const Cell*> cells;cells.reserve(std::min(allowance,plan.cells.size()));
                    for(std::size_t j=0;j<plan.cells.size()&&preferred_scans<8192;j+=stride) {
                        ++preferred_scans;budget.spend();const auto* cell=plan.cells[j];
                        if(cell->clearance_mm+default_contact_tolerance_mm>=minimum_height){budget.spend();cells.push_back(cell);}
                    }
                    if(cells.empty())continue;
                    Vec3 low=cells.front()->center,high=low;
                    for(const auto* cell:cells){budget.spend();low.x=std::min(low.x,cell->center.x);low.y=std::min(low.y,cell->center.y);high.x=std::max(high.x,cell->center.x);high.y=std::max(high.y,cell->center.y);}
                    const Vec3 center{(low.x+high.x)*.5,(low.y+high.y)*.5,cells.front()->center.z};
                    std::sort(cells.begin(),cells.end(),[&](const Cell* a,const Cell* b){budget.spend();const auto key=[&](const Cell* c){const double x=c->center.x-center.x,y=c->center.y-center.y;return std::tuple{x*x+y*y,c->center.x,c->center.y,c->center.z};};return key(a)<key(b);});
                    const auto start=hash(settings.seed^region^fixed->id)%fixed->allowed_yaws_degrees.size();
                    for(std::size_t n=0;n<=cells.size()&&!done()&&preferred_probes<1024&&preferred_probe_work<preferred_probe_allowance;++n)for(std::size_t j=0;j<std::min<std::size_t>(8,fixed->allowed_yaws_degrees.size())&&!done()&&preferred_probes<1024&&result.stats.candidates<settings.max_candidates&&preferred_probe_work<preferred_probe_allowance;++j) {
                        if(result.placements.size()>=result.stats.requested)break;
                        ++preferred_probes;budget.spend();Random random{hash(hash(settings.seed^0x43454c4c50524546ULL)^++ordinal)};
                        Placement p;p.asset_id=fixed->id;p.region_id=region;p.stable_id=identifier(settings.seed^0x43454c4c50524546ULL,region,ordinal,fixed->id);orient(*fixed,p,random);
                        p.yaw_degrees=fixed->allowed_yaws_degrees[(start+j)%fixed->allowed_yaws_degrees.size()];p.position=n?cells[n-1]->center:center;
                        const auto base=placed_base_center(*fixed,p.position,p.yaw_degrees,p.scale);p.position.x+=p.position.x-base.x;p.position.y+=p.position.y-base.y;
                        if(!output_indices.contains(p.stable_id)) {
                            const auto work_before=budget.used;const bool accepted=try_fitted(*fixed,p,true,false);preferred_probe_work+=budget.used-work_before;
                            if(accepted){const auto b=placement_bounds(*fixed,p);used_area[i]+=4*b.half_extents.x*b.half_extents.y;}
                        }
                    }
                }
            }
        };
        for(const auto* a:order)if(minima[a->id]>asset_counts[a->id])run_batch(a,minima[a->id],true);
        for(const auto* a:order)if(desired[a->id]>asset_counts[a->id])run_batch(a,desired[a->id],false);
        run_batch(nullptr,0,false);
        result.stats.minimum_unfilled=required_deficit();
        for(const auto& m:request.minimums)if(asset_counts[m.asset_id]<m.quantity)
            result.warnings.emplace_back("Minimum not met: "+assets.at(m.asset_id)->name+" ("+std::to_string(asset_counts[m.asset_id])+" / "+std::to_string(m.quantity)+" copies). Its missing copies remain unfilled.");
    } else {
    // Search every usable region at the preferred size before shrinking in an
    // earlier compartment. Retained output counts toward both passes exactly once.
    for(unsigned fit_pass=0;fit_pass<(settings.fit_to_space?2u:1u);++fit_pass) {
    for(const auto& plan:plans) {
        const auto region_id=plan.region->id;
        const auto current=region_outputs[region_id].size();
        const auto regional_target=plan.initial_count+plan.target;
        const auto remaining=settings.amount_mode==AmountMode::Quantity?
            (settings.quantity>result.placements.size()?settings.quantity-result.placements.size():0):
            (regional_target>current?regional_target-current:0);
        if(remaining==0)continue;
        const std::size_t target=std::min(plan.target,remaining);
        const std::size_t attempt_limit=std::max<std::size_t>(32,target*24);
        std::size_t emitted=0;
        for(std::size_t attempt=0;emitted<target&&attempt<attempt_limit;++attempt) {
            budget.spend();Random random{hash(hash(hash(settings.seed)^region_id)^static_cast<std::uint64_t>(attempt+1))};
            const auto* asset=choose(random,region_id,nullptr,false);
            if(!asset) {++result.stats.rejections[static_cast<std::size_t>(Rejection::Category)];break;}
            if(request.composition.book_rows&&asset->book_row&&asset->category==AssetCategory::Book&&
                result.groups.size()<settings.max_placements/2) {
                const auto* rule=rule_for(preset,AssetCategory::Book);
                const std::size_t capacity=std::min({static_cast<std::size_t>(request.composition.maximum_books),plan.target-emitted,
                    target-emitted,settings.max_placements-result.placements.size(),static_cast<std::size_t>(rule->maximum_count)-category_counts[region_id][static_cast<std::size_t>(AssetCategory::Book)]});
                if(capacity>=request.composition.minimum_books) {
                    ++result.composition_stats.row_attempts;
                    Random row_random{hash(hash(settings.seed^0x424f4f4b524f5731ULL)^hash(region_id)^hash(attempt))};
                    const auto front=row_front(policy_for(region_id)->front_direction);const Vec3 lateral{-front.y,front.x,0};
                    const auto count=static_cast<std::size_t>(request.composition.minimum_books)+row_random.index(capacity-request.composition.minimum_books+1);
                    CompositionGroup group;group.region_id=region_id;group.front_direction=front;group.gap_mm=request.composition.row_gap_mm;
                    group.stable_id=identifier(settings.seed^0x47524f5550524f57ULL,region_id,attempt,asset->id);
                    std::vector<std::pair<const Asset*,double>> choices;double weight_sum=0;
                    for(const auto* a:eligible){budget.spend();if(a->category==AssetCategory::Book&&a->book_row&&!row_yaws(*a,front).empty()){
                        const double weight=a->weight*rule->weight;choices.emplace_back(a,weight);weight_sum+=weight;}}
                    std::vector<Placement> members;std::vector<const Asset*> member_assets;double width=0;
                    bool valid=!composition_ids.contains(group.stable_id)&&!output_indices.contains(group.stable_id)&&!choices.empty()&&!row_yaws(*asset,front).empty();
                    for(std::size_t i=0;valid&&i<count;++i){budget.spend();const Asset* selected_asset=asset;
                        if(i){double pick=row_random.unit()*weight_sum;selected_asset=choices.back().first;
                            for(const auto& choice:choices){budget.spend();if(pick<choice.second){selected_asset=choice.first;break;}pick-=choice.second;}}
                        const auto yaws=row_yaws(*selected_asset,front);Placement p;p.asset_id=selected_asset->id;p.region_id=region_id;
                        p.stable_id=identifier(settings.seed^0x4d454d424552524fULL,region_id,i,selected_asset->id,group.stable_id);
                        if(output_indices.contains(p.stable_id)||composition_ids.contains(p.stable_id)||p.stable_id==group.stable_id){valid=false;break;}
                        p.yaw_degrees=yaws[row_random.index(yaws.size())];const double mid=(selected_asset->min_scale+selected_asset->max_scale)*0.5;
                        p.scale=mid+(row_random.unit()-0.5)*(selected_asset->max_scale-selected_asset->min_scale)*settings.height_variation;
                        const auto side=projection(placement_bounds(*selected_asset,p),lateral);width+=side.second-side.first;
                        members.push_back(p);member_assets.push_back(selected_asset);group.member_ids.push_back(p.stable_id);
                    }
                    if(valid){const auto* anchor=plan.cells[row_random.index(plan.cells.size())];Vec3 point=anchor->center;
                        point.x+=(row_random.unit()-0.5)*plan.cell_size*0.8;point.y+=(row_random.unit()-0.5)*plan.cell_size*0.8;
                        double cursor=row_dot(point,lateral)-(width+group.gap_mm*static_cast<double>(count-1))*0.5;
                        budget.spend(obstacles.size());row_scratch=obstacles;
                        for(std::size_t i=0;i<count;++i){auto& p=members[i];p.position.z=point.z;
                            const auto box=placement_bounds(*member_assets[i],p);const auto side=projection(box,lateral),depth=projection(box,front);
                            const double side_offset=cursor-side.first,front_offset=row_dot(point,front)-depth.second;
                            p.position.x=lateral.x*side_offset+front.x*front_offset;p.position.y=lateral.y*side_offset+front.y*front_offset;
                            cursor+=side.second-side.first+group.gap_mm;
                            if(!try_placement(*member_assets[i],p,false,GroupSpacing{group.stable_id,group.gap_mm},true,&row_scratch,i)){valid=false;break;}
                            row_scratch.push_back({p.stable_id,placement_bounds(*member_assets[i],p),group.stable_id,collider_pose(p)});
                        }
                    }
                    if(valid){budget.spend(validate_book_row_relationship(group,members,request.assets,front,budget.limit-budget.used));
                        for(std::size_t i=0;i<count;++i)publish(*member_assets[i],members[i],placement_bounds(*member_assets[i],members[i]),group.stable_id);
                        composition_ids.insert(group.stable_id);result.groups.push_back(std::move(group));++result.composition_stats.rows_formed;emitted+=count;continue;
                    }
                    ++result.composition_stats.row_failures;
                }
            }
            Placement placement;placement.asset_id=asset->id;placement.region_id=region_id;
            placement.stable_id=identifier(settings.seed,region_id,attempt,asset->id);
            if(output_indices.contains(placement.stable_id)) continue;
            orient(*asset,placement,random);
            const auto* cell=plan.cells[random.index(plan.cells.size())];placement.position=cell->center;
            placement.position.x+=(random.unit()-0.5)*plan.cell_size*0.8;
            placement.position.y+=(random.unit()-0.5)*plan.cell_size*0.8;
            // This jitter lies within the chosen sampled square (at most 0.4 cell
            // widths on either axis). Clustering abandons that construction and
            // must recheck ownership, even when another support shares its plane.
            bool displaced_anchor=false;
            const auto& existing=region_outputs[region_id];
            if(!existing.empty()&&random.unit()<settings.cluster_strength) {
                displaced_anchor=true;
                const auto anchor_index=existing[random.index(existing.size())];const auto& anchor=result.placements[anchor_index];
                const auto anchor_box=obstacles[anchor_index].box;
                const auto own_box=placement_bounds(*asset,placement);
                const double radius=(std::hypot(anchor_box.half_extents.x,anchor_box.half_extents.y)+
                    std::hypot(own_box.half_extents.x,own_box.half_extents.y)+settings.spacing_mm)*(1.05+random.unit()*0.4);
                const double angle=random.unit()*2*pi;
                placement.position.x=anchor.position.x+std::cos(angle)*radius;
                placement.position.y=anchor.position.y+std::sin(angle)*radius;
            }
            if(!try_fitted(*asset,placement,displaced_anchor,fit_pass==1)) continue;
            ++emitted;
            auto parent=placement;const Asset* parent_asset=asset;
            const double stack_chance=settings.cluster_strength*(settings.style==ArrangeStyle::Layered?1.0:settings.style==ArrangeStyle::Minimal?0.25:0.7);
            for(std::size_t depth=1;emitted<target&&result.stats.candidates<settings.max_candidates&&depth<settings.max_stack_depth&&parent_asset->stackable&&
                random.unit()<stack_chance;++depth) {
                const auto* child=choose(random,region_id,parent_asset,false);if(!child) break;
                Placement stacked;stacked.asset_id=child->id;stacked.region_id=region_id;stacked.parent_stack_id=parent.stable_id;
                stacked.stable_id=identifier(settings.seed,region_id,attempt,child->id,parent.stable_id);
                if(output_indices.contains(stacked.stable_id)) break;
                orient(*child,stacked,random);
                const auto patch=placement_footprint(*parent_asset,parent,true);
                Vec3 centroid{};for(const auto p:patch) {centroid.x+=p.x;centroid.y+=p.y;}
                centroid.x/=static_cast<double>(patch.size());centroid.y/=static_cast<double>(patch.size());
                stacked.position={centroid.x,centroid.y,parent.position.z+parent_asset->stack_height_mm*parent.scale};
                const auto child_patch=placement_footprint(*child,stacked);Vec3 offset{};
                for(const auto p:child_patch) {offset.x+=p.x-stacked.position.x;offset.y+=p.y-stacked.position.y;}
                stacked.position.x-=offset.x/static_cast<double>(child_patch.size());stacked.position.y-=offset.y/static_cast<double>(child_patch.size());
                if(!try_placement(*child,stacked,false)) break;
                ++emitted;parent=stacked;parent_asset=child;
            }
        }
    }
    }
    }
    if(!result.groups.empty())std::sort(result.groups.begin(),result.groups.end(),[&](const auto& a,const auto& b){budget.spend();return a.stable_id<b.stable_id;});
    if(request.composition.row_height_balance>0) {
        for(const auto& group:result.groups) {
            if(protected_groups.contains(group.member_ids.front()))continue;
            budget.spend();const auto& region=*regions.at(group.region_id);const auto front=row_front(group.front_direction);const Vec3 lateral{-front.y,front.x,0};
            if(region.cells.empty()||region.sampled_area_mm2<=0)throw std::invalid_argument("Row balance requires sampled support cells.");
            const double half=0.5*std::sqrt(region.sampled_area_mm2/static_cast<double>(region.cells.size()));
            if(!std::isfinite(half)||half<=0||half>1e9)throw std::invalid_argument("Invalid sampled cell extent for row balance.");
            double minimum=std::numeric_limits<double>::infinity(),maximum=-minimum;
            double xmin=minimum,ymin=minimum,xmax=maximum,ymax=maximum,base_z=minimum;
            for(const auto& cell:region.cells){budget.spend();base_z=std::min(base_z,cell.center.z);}
            std::vector<const Cell*> anchors;
            for(const auto& cell:region.cells){budget.spend();if(std::abs(cell.center.z-base_z)>0.01)throw std::invalid_argument("Row balance requires one horizontal regional support plane.");
                const double centre=row_dot(cell.center,lateral),radius=half*(std::abs(lateral.x)+std::abs(lateral.y));
                minimum=std::min(minimum,centre-radius);maximum=std::max(maximum,centre+radius);
                xmin=std::min(xmin,cell.center.x-half);xmax=std::max(xmax,cell.center.x+half);ymin=std::min(ymin,cell.center.y-half);ymax=std::max(ymax,cell.center.y+half);
                if(cell.usable)anchors.push_back(&cell);
            }
            std::sort(anchors.begin(),anchors.end(),[&](const Cell* a,const Cell* b){budget.spend();return std::tie(a->center.x,a->center.y,a->center.z)<std::tie(b->center.x,b->center.y,b->center.z);});
            const double diagonal=std::hypot(xmax-xmin,ymax-ymin),bin_width=(maximum-minimum)/16;
            if(anchors.empty()||!std::isfinite(diagonal)||diagonal<=0||!std::isfinite(bin_width)||bin_width<=0)
                throw std::invalid_argument("Row balance requires a finite nonempty horizontal extent.");
            const auto add_box=[&](std::array<double,16>& profile,const OrientedBox& box){const auto interval=projection(box,lateral);const double height=std::max(0.0,box.center.z+box.half_extents.z-base_z);
                for(std::size_t bin=0;bin<16;++bin){budget.spend();const double lo=minimum+static_cast<double>(bin)*bin_width;
                    if(interval.second>lo&&interval.first<lo+bin_width)profile[bin]=std::max(profile[bin],height);}};
            const auto imbalance=[&](const std::array<double,16>& profile){double total=0,moment=0;
                for(std::size_t bin=0;bin<16;++bin){budget.spend();total+=profile[bin];moment+=profile[bin]*((2*static_cast<double>(bin)+1)/16-1);}
                return total>0?std::abs(moment)/total:0.0;};
            std::array<double,16> base_profile{};row_scratch.clear();
            for(std::size_t i=0;i<obstacles.size();++i){budget.spend();if(obstacles[i].composition_group_id!=group.stable_id)row_scratch.push_back(obstacles[i]);}
            for(auto index:region_outputs.at(group.region_id)){budget.spend();if(obstacles[index].composition_group_id!=group.stable_id)add_box(base_profile,obstacles[index].box);}
            std::vector<Placement> original;Vec3 centre{};
            auto original_profile=base_profile;
            for(auto id:group.member_ids){budget.spend();const auto& p=result.placements[output_indices.at(id)];original.push_back(p);centre.x+=p.position.x;centre.y+=p.position.y;
                add_box(original_profile,obstacles[output_indices.at(id)].box);}
            centre.x/=static_cast<double>(original.size());centre.y/=static_cast<double>(original.size());
            const auto original_obstacles=row_scratch.size();const double original_balance=imbalance(original_profile),strength=request.composition.row_height_balance;
            double best_score=strength*original_balance;auto best=original;bool moved=false;
            for(std::size_t proposal=0;proposal<8;++proposal){budget.spend();++result.composition_stats.balance_anchor_attempts;
                Random random{hash(hash(settings.seed^0x42414c414e434531ULL)^hash(group.stable_id)^hash(proposal))};
                const auto* cell=anchors[random.index(anchors.size())];const double dx=cell->center.x+(random.unit()-0.5)*half*1.6-centre.x;
                const double dy=cell->center.y+(random.unit()-0.5)*half*1.6-centre.y;auto candidate=original;bool valid=true;auto profile=base_profile;
                row_scratch.resize(original_obstacles);
                for(std::size_t i=0;i<candidate.size();++i){auto& p=candidate[i];p.position.x+=dx;p.position.y+=dy;const auto* a=assets.at(p.asset_id);
                    if(!try_placement(*a,p,false,GroupSpacing{group.stable_id,group.gap_mm},true,&row_scratch,i,original.size())){valid=false;break;}
                    const auto box=placement_bounds(*a,p);row_scratch.push_back({p.stable_id,box,group.stable_id,collider_pose(p)});add_box(profile,box);}
                if(!valid)continue;
                const double balance=imbalance(profile),distance=std::min(1.0,std::hypot(dx,dy)/diagonal);
                const double score=(1-strength)*distance+strength*balance;
                if(balance<=original_balance&&score+1e-14<best_score){best_score=score;best=std::move(candidate);moved=true;}
            }
            if(moved){budget.spend(validate_book_row_relationship(group,best,request.assets,front,budget.limit-budget.used));
                for(const auto& p:best){const auto index=output_indices.at(p.stable_id);result.placements[index]=p;obstacles[index].box=placement_bounds(*assets.at(p.asset_id),p);}
                ++result.composition_stats.rows_moved;
            }
        }
    }
    result.stats.accepted=result.placements.size();
    result.stats.underfilled=result.stats.requested>result.stats.accepted?result.stats.requested-result.stats.accepted:0;
    if(result.stats.underfilled) result.warnings.emplace_back("Some copies remain unplaced. Select a prop in Modify for fit details.");
    if(request.composition.book_rows&&result.composition_stats.row_attempts&&!result.composition_stats.rows_formed)
        result.warnings.emplace_back("No complete upright book row passed the bounded recipe and fit checks; ordinary valid props may still be present.");
    result.stats.work=budget.used;
    if(deferred_failures)*deferred_failures=std::move(local_failures);
    else if(!shared_failures&&result.stats.underfilled){
    // Regional Fill children only record copied failures. Advice runs once,
    // after all production work, with separate source caches and final poses.
    complete_feedback(request,settings,geometry,result,failures);
    }
    return result;
}
ArrangementResult arrange(const ArrangementRequest& request,const ArrangeSettings& settings,const PlacementQuery& geometry){
    if(settings.amount_mode!=AmountMode::Quantity||request.composition.book_rows)return arrange_with_feedback(request,settings,geometry,nullptr);
    std::optional<FitFailureRecorder> failures;
    auto best=arrange_with_feedback(request,settings,geometry,nullptr,0,&failures);
    auto best_settings=settings;
    const auto initial_work=best.stats.work;const auto initial_candidates=best.stats.candidates;
    auto work=initial_work;auto candidates=initial_candidates;auto rejections=best.stats.rejections;
    for(unsigned mode=1;mode<=4&&best.stats.underfilled&&best.stats.accepted>best.stats.kept;++mode){
        // Recovery never retains another full solver workspace. Only the best
        // copied result survives; all trial generation shares this command cap.
        if(settings.max_work-work<=2*initial_work+64||settings.max_candidates-candidates<=2*initial_candidates+16)break;
        ++work;auto trial_settings=settings;
        trial_settings.seed=hash(settings.seed^0x5154595245504143ULL^mode);
        trial_settings.max_work=settings.max_work-work;trial_settings.max_candidates=settings.max_candidates-candidates;
        std::optional<FitFailureRecorder> trial_failures;
        auto trial=arrange_with_feedback(request,trial_settings,geometry,nullptr,mode,&trial_failures);
        work+=trial.stats.work;candidates+=trial.stats.candidates;
        for(std::size_t i=0;i<rejections.size();++i)rejections[i]+=trial.stats.rejections[i];
        if(trial.stats.accepted>=best.stats.accepted&&trial.stats.minimum_unfilled<=best.stats.minimum_unfilled&&
           (trial.stats.accepted>best.stats.accepted||trial.stats.minimum_unfilled<best.stats.minimum_unfilled)){
            best=std::move(trial);failures=std::move(trial_failures);best_settings=trial_settings;
        }
    }
    best.stats.work=work;best.stats.candidates=candidates;best.stats.rejections=rejections;
    if(best.stats.underfilled)complete_feedback(request,best_settings,geometry,best,*failures);
    return best;
}
}
