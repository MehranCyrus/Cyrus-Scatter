#include "cyrus_arrange/arrangement.h"

#include <algorithm>
#include <cmath>
#include <functional>
#include <iostream>
#include <limits>
#include <stdexcept>
#include <string>
#include <vector>

using namespace cyrus::arrange;
namespace {
void check(bool value,const char* message){if(!value)throw std::runtime_error(message);}
void near(double a,double b,const char* message){check(std::abs(a-b)<1e-7,message);}
void rejects(const std::function<void()>& action){bool threw=false;try{action();}catch(const std::exception&){threw=true;}check(threw,"Expected request to fail atomically");}
Asset asset(std::uint64_t id=1,AssetCategory category=AssetCategory::Book,bool stackable=false) {
    Asset a;a.id=id;a.name="Fixture";a.category=category;a.anchor={0,0,0};a.allowed_yaws_degrees={0};
    a.mesh.vertices={{-10,-10,0},{10,-10,0},{10,10,0},{-10,10,0},{-10,-10,10},{10,-10,10},{10,10,10},{-10,10,10}};
    a.mesh.triangles={{{0,2,1}},{{0,3,2}},{{4,5,6}},{{4,6,7}},{{0,1,5}},{{0,5,4}},
        {{1,2,6}},{{1,6,5}},{{2,3,7}},{{2,7,6}},{{3,0,4}},{{3,4,7}}};
    a.stackable=stackable;
    if(stackable){a.stack_height_mm=10;a.allowed_on_top=asset_bit(AssetCategory::Book);a.stack_footprint={{-10,-10,10},{10,-10,10},{10,10,10},{-10,10,10}};}
    return prepare_asset(std::move(a));
}
Region region(std::uint32_t id=1,double offset=0) {
    Region r;r.id=id;r.bounds={{offset,0,0},{offset+100,100,0}};r.sampled_area_mm2=r.usable_area_mm2=10000;
    r.minimum_clearance_mm=std::numeric_limits<double>::infinity();r.open_above=true;
    for(int x=0;x<4;++x)for(int y=0;y<4;++y)r.cells.push_back({{offset+12.5+25*x,12.5+25*y,0},std::numeric_limits<double>::infinity(),true});
    return r;
}
ArrangeSettings settings() {
    ArrangeSettings s;s.category=FurnitureCategory::OpenShelf;s.density=0.2;s.empty_space=0;s.spacing_mm=0;s.edge_clearance_mm=0;s.cluster_strength=0;
    return s;
}
struct AcceptQuery final:PlacementQuery {
    mutable std::size_t calls{};
    QueryResult validate(const PlacementProbe& p)const override{++calls;return {Rejection::None,1+static_cast<std::uint64_t>(p.footprint_world.size())};}
};
struct RejectQuery final:PlacementQuery {
    QueryResult validate(const PlacementProbe&)const override{return {Rejection::Obstacle,1};}
};
struct FixtureQuery final:PlacementQuery {
    std::vector<Region> regions;
    mutable std::size_t calls{};
    QueryResult validate(const PlacementProbe& p)const override {
        ++calls;std::uint64_t work=1;
        if(p.parent_support_world.empty()) {
            const auto it=std::find_if(regions.begin(),regions.end(),[&](const Region& r){return r.id==p.region_id;});
            if(it==regions.end()||std::abs(p.support_z)>1e-7)return {Rejection::Unsupported,work};
            for(const auto point:p.footprint_world){++work;if(point.x<it->bounds.min.x+p.edge_clearance_mm||point.x>it->bounds.max.x-p.edge_clearance_mm||
                point.y<it->bounds.min.y+p.edge_clearance_mm||point.y>it->bounds.max.y-p.edge_clearance_mm)return {Rejection::Boundary,work};}
        } else {
            for(const auto point:p.footprint_world)for(std::size_t i=0;i<p.parent_support_world.size();++i){++work;
                const auto a=p.parent_support_world[i],b=p.parent_support_world[(i+1)%p.parent_support_world.size()];
                if((b.x-a.x)*(point.y-a.y)-(b.y-a.y)*(point.x-a.x)<-1e-6)return {Rejection::Stack,work};}
        }
        for(const auto& other:p.accepted){++work;
            const double z=std::abs(p.collision.center.z-other.box.center.z);
            if(z>=p.collision.half_extents.z+other.box.half_extents.z-1e-7)continue;
            const double x=std::abs(p.collision.center.x-other.box.center.x),y=std::abs(p.collision.center.y-other.box.center.y);
            if(x<p.collision.half_extents.x+other.box.half_extents.x+p.spacing_mm &&
               y<p.collision.half_extents.y+other.box.half_extents.y+p.spacing_mm)
                return {p.spacing_mm>0?Rejection::Spacing:Rejection::Obstacle,work};
        }
        return {Rejection::None,work};
    }
};
bool same(const Placement& a,const Placement& b) {
    return a.stable_id==b.stable_id&&a.asset_id==b.asset_id&&a.parent_stack_id==b.parent_stack_id&&a.region_id==b.region_id&&
        a.position.x==b.position.x&&a.position.y==b.position.y&&a.position.z==b.position.z&&a.yaw_degrees==b.yaw_degrees&&a.scale==b.scale&&a.locked==b.locked;
}
const Placement& find(const ArrangementResult& r,std::uint64_t id){const auto i=std::find_if(r.placements.begin(),r.placements.end(),[id](const Placement& p){return p.stable_id==id;});if(i==r.placements.end())throw std::runtime_error("Protected ID missing");return *i;}
void deterministic_and_ids() {
    std::vector<Asset> assets{asset(2),asset(1)};std::vector<Region> regions{region(2,200),region()};AcceptQuery q;
    const ArrangementRequest input{regions,assets};auto s=settings();const auto a=arrange(input,s,q);
    std::reverse(assets.begin(),assets.end());std::reverse(regions.begin(),regions.end());for(auto& r:regions)std::reverse(r.cells.begin(),r.cells.end());
    const auto b=arrange({regions,assets},s,q);check(a.placements.size()==b.placements.size(),"Sorted input identity counts");
    for(std::size_t i=0;i<a.placements.size();++i)check(same(a.placements[i],b.placements[i]),"Input array order must not change placement output");
    std::vector<Region> second_only{region(2,200)};
    const auto independent=arrange({second_only,assets},s,q);
    for(const auto& p:independent.placements)check(same(find(b,p.stable_id),p),"Region and asset ID hash domains cannot alias or perturb another region");
    s.seed=2;const auto c=arrange({regions,assets},s,q);check(c.placements.front().position.x!=a.placements.front().position.x||c.placements.front().position.y!=a.placements.front().position.y,"Seed changes actual candidate positions");
}
void density_empty_and_styles() {
    std::vector<Asset> assets{asset()};std::vector<Region> regions{region()};AcceptQuery q;auto s=settings();
    const auto low=arrange({regions,assets},s,q);check(low.stats.requested==5&&low.placements.size()==5,"Known area and asset footprint determine five requested slots");
    s.density=0.4;const auto high=arrange({regions,assets},s,q);check(high.stats.requested==10&&high.placements.size()==10,"Density changes real output count");
    s.empty_space=0.5;check(arrange({regions,assets},s,q).placements.size()==5,"Empty space reduces actual prop count");
    s.empty_space=1;check(arrange({regions,assets},s,q).placements.empty(),"All-empty setting generates no props");
    s=settings();s.style=ArrangeStyle::Minimal;const auto minimal=arrange({regions,assets},s,q);s.style=ArrangeStyle::Layered;
    check(arrange({regions,assets},s,q).placements.size()>minimal.placements.size(),"Styles affect requested and accepted density");
}
void transformed_footprint_and_bounds() {
    auto a=asset();a.anchor={0,0,0};Placement p;p.position={100,200,30};p.yaw_degrees=90;p.scale=2;
    const auto shape=placement_footprint(a,p);near(shape[0].x,120,"Footprint yaw/scale X");near(shape[0].y,180,"Footprint yaw/scale Y");near(shape[0].z,30,"Contact anchor preserves support Z");
    const auto bounds=placement_bounds(a,p);near(bounds.center.z,40,"Complete mesh bounds centre includes asset height");near(bounds.half_extents.z,10,"Full collision height scales");
    auto stacked=asset(2,AssetCategory::Book,true);const auto top=placement_footprint(stacked,p,true);near(top[0].z,50,"Authored top patch transforms above contact anchor");
}
void geometry_rejection_and_spacing() {
    std::vector<Asset> assets{asset()};std::vector<Region> regions{region()};FixtureQuery q;q.regions=regions;auto s=settings();
    const auto result=arrange({regions,assets},s,q);check(!result.placements.empty()&&q.calls>=result.placements.size(),"Every placement must pass geometry validation");
    for(const auto& p:result.placements)for(const auto point:placement_footprint(assets[0],p))check(point.x>=0&&point.x<=100&&point.y>=0&&point.y<=100,"Actual complete footprint is contained");
    s.spacing_mm=20;const auto spaced=arrange({regions,assets},s,q);
    for(std::size_t i=0;i<spaced.placements.size();++i)for(std::size_t j=i+1;j<spaced.placements.size();++j){const auto a=spaced.placements[i].position,b=spaced.placements[j].position;
        check(std::abs(a.x-b.x)>=40||std::abs(a.y-b.y)>=40,"Accepted props respect physical footprint spacing");}
    RejectQuery no;const auto rejected=arrange({regions,assets},settings(),no);check(rejected.placements.empty()&&rejected.stats.underfilled==5&&rejected.stats.rejections[static_cast<std::size_t>(Rejection::Obstacle)]>0,"Rejected geometry produces explained bounded underfill");
}
void height_variation_and_clustering() {
    auto a=asset();a.min_scale=0.8;a.max_scale=1.2;std::vector<Asset> assets{a};std::vector<Region> regions{region()};AcceptQuery q;auto s=settings();
    s.height_variation=0;const auto fixed=arrange({regions,assets},s,q);for(const auto& p:fixed.placements)near(p.scale,1,"Zero variation uses authored scale midpoint");
    s.random_scale=true;s.scale_min=.8;s.scale_max=1.2;const auto varied=arrange({regions,assets},s,q);check(std::any_of(varied.placements.begin(),varied.placements.end(),[](const Placement& p){return std::abs(p.scale-1)>1e-5;}),"Random scale changes uniform scale within the explicit range");
    for(const auto& p:varied.placements)check(p.scale>=0.8&&p.scale<=1.2&&p.position.z==0,"Height variation never floats contact anchors");
    s=settings();const auto unclustered=arrange({regions,assets},s,q);s.cluster_strength=1;const auto clustered=arrange({regions,assets},s,q);
    check(unclustered.placements.size()>1&&clustered.placements.size()>1,"Clustering fixture creates multiple props");
    check(unclustered.placements[1].position.x!=clustered.placements[1].position.x||unclustered.placements[1].position.y!=clustered.placements[1].position.y,"Clustering changes actual positions");
}
void books_stack_and_locks() {
    std::vector<Asset> assets{asset(1,AssetCategory::Book,true)};std::vector<Region> regions{region()};FixtureQuery q;q.regions=regions;auto s=settings();s.cluster_strength=1;s.style=ArrangeStyle::Layered;
    const auto result=arrange({regions,assets},s,q);const auto child=std::find_if(result.placements.begin(),result.placements.end(),[](const Placement& p){return p.parent_stack_id!=0;});
    check(child!=result.placements.end(),"Layered clustered books produce an actual parented book stack");
    const auto parent=find(result,child->parent_stack_id);near(child->position.z,parent.position.z+10,"Book child rests on parent's authored top");
    std::vector<std::uint64_t> locked{child->stable_id};const auto kept=arrange({regions,assets,result.placements,locked},s,q);
    check(find(kept,child->stable_id).locked,"Explicit locked ID persists lock state");
    auto expected=*child;expected.locked=true;check(same(find(kept,child->stable_id),expected),"Locked child preserves its exact transform and identity");
    check(same(find(kept,parent.stable_id),parent),"Locking child preserves support ancestors");
    RejectQuery no;rejects([&]{arrange({regions,assets,result.placements,locked},s,no);});
}
void selective_regeneration() {
    std::vector<Asset> assets{asset()};std::vector<Region> regions{region(),region(2,200)};AcceptQuery q;auto s=settings();
    const auto first=arrange({regions,assets},s,q);std::vector<std::uint32_t> selected{1};s.seed=99;
    const auto next=arrange({regions,assets,first.placements,{},selected},s,q);
    for(const auto& p:first.placements)if(p.region_id==2)check(same(find(next,p.stable_id),p),"Unselected region remains exact under seed changes");
    check(next.stats.kept==5,"Selective regeneration reports protected outside-region count");
}
void authored_tray_stack() {
    auto tray=asset(1,AssetCategory::Tray,true);tray.allowed_on_top=asset_bit(AssetCategory::Accessory);
    auto ornament=asset(2,AssetCategory::Accessory);
    std::vector<Asset> assets{tray,ornament};std::vector<Region> regions{region()};FixtureQuery q;q.regions=regions;
    auto s=settings();s.cluster_strength=1;s.style=ArrangeStyle::Layered;
    const auto result=arrange({regions,assets},s,q);
    const auto child=std::find_if(result.placements.begin(),result.placements.end(),[](const Placement& p){return p.parent_stack_id!=0;});
    check(child!=result.placements.end(),"Stable authored top supports a physically valid selected prop regardless of tag");
    const auto& parent=find(result,child->parent_stack_id);check(parent.asset_id==1,"Stack uses the actual source with a stable top");
    near(child->position.z,parent.position.z+10,"Authored stack height is respected");
}
void furniture_categories_and_weights() {
    std::vector<Asset> assets{asset(1,AssetCategory::Kitchenware)};std::vector<Region> regions{region()};AcceptQuery q;auto s=settings();
    assets[0].allowed_furniture=furniture_bit(FurnitureCategory::DiningTable);
    const auto baseline=arrange({regions,assets},s,q);
    check(baseline.placements.size()==5,"Chosen geometry is eligible despite historical source mask");
    for(std::uint32_t c=0;c<static_cast<std::uint32_t>(FurnitureCategory::Count);++c) {
        s.category=static_cast<FurnitureCategory>(c);const auto r=arrange({regions,assets},s,q);
        check(r.placements.size()==baseline.placements.size(),"Historical furniture labels do not change output count");
        for(std::size_t i=0;i<r.placements.size();++i)check(same(r.placements[i],baseline.placements[i]),"Historical furniture labels do not change poses");
    }
    assets={asset(1),asset(2)};assets[0].weight=1e6;assets[1].weight=1e-6;s=settings();const auto weighted=arrange({regions,assets},s,q);
    check(std::all_of(weighted.placements.begin(),weighted.placements.end(),[](const Placement& p){return p.asset_id==1;}),"Artist source weight remains effective");
}
void removed_regions_and_protected_membership() {
    std::vector<Asset> assets{asset()};std::vector<Region> original{region(),region(2,200)};AcceptQuery q;auto s=settings();
    const auto first=arrange({original,assets},s,q);std::vector<Region> remaining{region()};
    const auto regenerated=arrange({remaining,assets,first.placements},s,q);
    check(!regenerated.placements.empty()&&std::all_of(regenerated.placements.begin(),regenerated.placements.end(),[](const Placement& p){return p.region_id==1;}),
        "Full unlocked regeneration discards previous rows from a removed region");
    const auto lost=std::find_if(first.placements.begin(),first.placements.end(),[](const Placement& p){return p.region_id==2;});
    std::vector<std::uint64_t> locks{lost->stable_id};rejects([&]{arrange({remaining,assets,first.placements,locks},s,q);});
    std::vector<std::uint32_t> selected{1};rejects([&]{arrange({remaining,assets,first.placements,{},selected},s,q);});
    std::vector<Placement> one{first.placements.front()};one.front().locked=true;
    std::vector<Region> relabelled{region(1,500)};rejects([&]{arrange({relabelled,assets,one},s,q);});
    auto shifted=region();for(auto& c:shifted.cells)c.center.z=20;shifted.bounds.min.z=shifted.bounds.max.z=20;
    std::vector<Region> wrong_height{shifted};rejects([&]{arrange({wrong_height,assets,one},s,q);});
    auto parentless=one;parentless.front().parent_stack_id=9999;rejects([&]{arrange({remaining,assets,parentless},s,q);});
    check(one.front().position.z==0&&one.front().locked,"Protected membership failure never mutates previous rows");
}
void invalid_and_bounded() {
    std::vector<Asset> assets{asset()};std::vector<Region> regions{region()};AcceptQuery q;auto s=settings();s.density=std::numeric_limits<double>::quiet_NaN();rejects([&]{arrange({regions,assets},s,q);});
    s=settings();s.max_work=1;rejects([&]{arrange({regions,assets},s,q);});
    s=settings();s.max_candidates=1;rejects([&]{arrange({regions,assets},s,q);});
    s=settings();s.max_placements=1;rejects([&]{arrange({regions,assets},s,q);});
    auto duplicate=assets;duplicate.push_back(assets[0]);rejects([&]{arrange({regions,duplicate},settings(),q);});
    std::vector<std::uint64_t> missing{999};rejects([&]{arrange({regions,assets,{},missing},settings(),q);});
    Placement cyclic;cyclic.stable_id=1;cyclic.asset_id=1;cyclic.region_id=1;cyclic.parent_stack_id=1;cyclic.locked=true;std::vector<Placement> previous{cyclic};
    rejects([&]{arrange({regions,assets,previous},settings(),q);});check(previous[0].stable_id==1&&previous[0].parent_stack_id==1,"Failed solve never mutates caller's previous output");
}
void editable_category_rules() {
    std::vector<Asset> assets{asset(1,AssetCategory::Kitchenware)};std::vector<Region> regions{region()};AcceptQuery q;auto s=settings();
    std::vector<CategoryRule> rules{{AssetCategory::Kitchenware,1.0,2,false}};
    const auto result=arrange({regions,assets,{},{},{},rules,true},s,q);
    check(result.placements.size()==5,"Historical per-category caps no longer reduce the physical target");
    check(arrange({regions,assets,{},{},{},{},true},s,q).placements.size()==5,"An empty historical category table cannot disable chosen props");
    auto previous=result.placements;previous.front().locked=true;rules[0].maximum_count=0;
    const auto kept=arrange({regions,assets,previous,{},{},rules,true},s,q);
    check(same(find(kept,previous.front().stable_id),previous.front()),"Retired category restrictions cannot invalidate a protected physically valid object");
}
void regional_masks_density_and_order() {
    auto small=asset();auto large=asset(2,AssetCategory::Vase);
    for(auto& p:large.mesh.vertices){p.x*=2;p.y*=2;}
    for(auto& p:large.contact_footprint){p.x*=2;p.y*=2;}
    large=prepare_asset(std::move(large));
    std::vector<Asset> assets{small,large};std::vector<Region> regions{region(),region(2,200)};AcceptQuery q;auto s=settings();
    std::vector<RegionPlacementRule> rules{{1,asset_bit(AssetCategory::Book)},{2,asset_bit(AssetCategory::Vase)}};
    const auto first=arrange({regions,assets,{},{},{},{},false,rules},s,q);
    check(first.stats.requested==4&&first.placements.size()==4,"Both regions use all chosen footprints: 2 * ceil(2000/1000)");
    std::reverse(rules.begin(),rules.end());const auto reordered=arrange({regions,assets,{},{},{},{},false,rules},s,q);
    for(std::size_t i=0;i<first.placements.size();++i)check(same(first.placements[i],reordered.placements[i]),"Region array order does not change deterministic output");
    rules[1].density_multiplier=2;const auto twice=arrange({regions,assets,{},{},{},{},false,rules},s,q);
    check(twice.stats.requested==6&&twice.placements.size()==6,"Explicit regional density still controls physical targets");
    rules[1].allowed_asset_categories=0;assets[0].allowed_furniture=furniture_bit(FurnitureCategory::TVConsole);
    const auto ignored=arrange({regions,assets,{},{},{},{},true,rules},s,q);
    check(ignored.placements.size()==6,"Historical region/source/category masks cannot exclude selected geometry");
}
void regional_exclusions_and_protected_counts() {
    std::vector<Asset> assets{asset()};std::vector<Region> regions{region(),region(2,200)};AcceptQuery q;auto s=settings();s.density=0.08;
    std::vector<CategoryRule> categories{{AssetCategory::Book,1,2,true}};
    std::vector<RegionPlacementRule> rules{{1},{2}};
    const auto first=arrange({regions,assets,{},{},{},categories,true,rules},s,q);check(first.placements.size()==4,"Two regions each allow two books");
    std::vector<std::uint32_t> selected{1};s.seed=21;
    const auto partial=arrange({regions,assets,first.placements,{},selected,categories,true,rules},s,q);
    check(partial.stats.requested==4&&partial.stats.accepted==4&&partial.stats.kept==2,"Selective protected counts consume their regional cap exactly once");
    categories[0].maximum_count=1;check(arrange({regions,assets,first.placements,{},selected,categories,true,rules},s,q).placements.size()==4,"Retired category caps do not block selective regeneration");categories[0].maximum_count=2;
    rules[0].excluded=true;
    const auto excluded=arrange({regions,assets,first.placements,{},{},categories,true,rules},s,q);
    check(excluded.placements.size()==2&&excluded.stats.requested==2&&excluded.stats.underfilled==0,"Excluded identity remains present while full regeneration drops its unprotected props");
    selected={2};rejects([&]{arrange({regions,assets,first.placements,{},selected,categories,true,rules},s,q);});
    selected={1};const auto selected_exclusion=arrange({regions,assets,first.placements,{},selected,categories,true,rules},s,q);
    check(selected_exclusion.stats.kept==2&&selected_exclusion.placements.size()==2,"Selecting the excluded region removes its unlocked props and preserves other regions");
    std::vector<std::uint64_t> locks{first.placements.front().stable_id};
    rejects([&]{arrange({regions,assets,first.placements,locks,{},categories,true,rules},s,q);});
    rules[0].excluded=false;rules[0].density_multiplier=0;
    const auto zero=arrange({regions,assets,first.placements,locks,{},categories,true,rules},s,q);
    check(zero.stats.kept==1&&zero.stats.requested==3&&zero.placements.size()==3,"Zero regional density retains a locked row without adding more props in that region");
    auto expected=first.placements.front();expected.locked=true;check(same(find(zero,locks.front()),expected),"Zero density preserves the protected pose");
    rules[0].allowed_asset_categories=0;check(arrange({regions,assets,first.placements,locks,{},categories,true,rules},s,q).placements.size()==3,"Historical tag masks do not invalidate protected output");
    check(!first.placements.front().locked&&first.placements.size()==4,"Policy failures leave caller's previous rows untouched");
}
void regional_stacking_policy() {
    std::vector<Asset> assets{asset(1,AssetCategory::Book,true)};std::vector<Region> regions{region()};AcceptQuery q;auto s=settings();s.cluster_strength=1;s.style=ArrangeStyle::Layered;
    std::vector<RegionPlacementRule> rules{{1}};
    const auto stacked=arrange({regions,assets,{},{},{},{},false,rules},s,q);
    const auto child=std::find_if(stacked.placements.begin(),stacked.placements.end(),[](const auto& p){return p.parent_stack_id!=0;});
    check(child!=stacked.placements.end(),"Enabled regional policy produces actual stack edges");
    rules[0].allow_stacking=false;
    const auto flat=arrange({regions,assets,{},{},{},{},false,rules},s,q);
    check(!flat.placements.empty()&&std::all_of(flat.placements.begin(),flat.placements.end(),[](const auto& p){return p.parent_stack_id==0;}),"Disabling stacks still permits stackable assets directly on furniture");
    std::vector<std::uint64_t> locks{child->stable_id};rejects([&]{arrange({regions,assets,stacked.placements,locks,{},{},false,rules},s,q);});
}
void invalid_regional_policies() {
    std::vector<Asset> assets{asset()};std::vector<Region> regions{region()};AcceptQuery q;auto s=settings();std::vector<RegionPlacementRule> rules{{1}};
    const auto invalid=[&]{rejects([&]{arrange({regions,assets,{},{},{},{},false,rules},s,q);});};
    rules[0].region_id=0;invalid();rules[0].region_id=2;invalid();rules[0].region_id=1;
    rules.push_back(rules[0]);invalid();rules.resize(1);
    rules[0].allowed_asset_categories=1u<<31;invalid();rules[0].allowed_asset_categories=all_asset_mask;
    for(double density:{-1.0,4.001,std::numeric_limits<double>::quiet_NaN(),std::numeric_limits<double>::infinity()}){rules[0].density_multiplier=density;invalid();}
    rules[0].density_multiplier=1;
    for(Vec3 direction:std::vector<Vec3>{{0,0,0},{1,0,1},{1e7,0,0},{INFINITY,0,0},{1e308,1e308,0}}){rules[0].front_direction=direction;invalid();}
    rules[0].front_direction={0,-1,0};rules.resize(4097,rules[0]);invalid();rules.resize(1);
    rules[0].density_multiplier=4;s.density=1;s.max_placements=20;invalid();
}
}
int main(){
    const std::vector<std::pair<const char*,std::function<void()>>> tests{{"deterministic_and_ids",deterministic_and_ids},{"density_empty_and_styles",density_empty_and_styles},
        {"transformed_footprint_and_bounds",transformed_footprint_and_bounds},{"geometry_rejection_and_spacing",geometry_rejection_and_spacing},
        {"height_variation_and_clustering",height_variation_and_clustering},{"books_stack_and_locks",books_stack_and_locks},
        {"authored_tray_stack",authored_tray_stack},
        {"selective_regeneration",selective_regeneration},{"furniture_categories_and_weights",furniture_categories_and_weights},
        {"removed_regions_and_protected_membership",removed_regions_and_protected_membership},{"invalid_and_bounded",invalid_and_bounded},{"editable_category_rules",editable_category_rules},
        {"regional_masks_density_and_order",regional_masks_density_and_order},{"regional_exclusions_and_protected_counts",regional_exclusions_and_protected_counts},
        {"regional_stacking_policy",regional_stacking_policy},{"invalid_regional_policies",invalid_regional_policies}};
    for(const auto& [name,test]:tests)try{test();std::cout<<"PASS "<<name<<'\n';}catch(const std::exception& error){std::cerr<<"FAIL "<<name<<": "<<error.what()<<'\n';return 1;}
    std::cout<<tests.size()<<" arrangement suites passed\n";return 0;
}
