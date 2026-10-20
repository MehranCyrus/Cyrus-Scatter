#include "cyrus_arrange/placement_queries.h"

#include <algorithm>
#include <cmath>
#include <functional>
#include <iostream>
#include <map>
#include <stdexcept>
#include <string>
#include <vector>

using namespace cyrus::arrange;
namespace {
void check(bool value,const char* message){if(!value)throw std::runtime_error(message);}
void rejects(const std::function<void()>& action){bool failed=false;try{action();}catch(const std::exception&){failed=true;}check(failed,"Protected invalid pose must abort successor");}
Mesh box(double x0,double y0,double z0,double x1,double y1,double z1) {
    Mesh mesh;mesh.vertices={{x0,y0,z0},{x1,y0,z0},{x1,y1,z0},{x0,y1,z0},{x0,y0,z1},{x1,y0,z1},{x1,y1,z1},{x0,y1,z1}};
    mesh.triangles={{{0,2,1}},{{0,3,2}},{{4,5,6}},{{4,6,7}},{{0,1,5}},{{0,5,4}},
        {{1,2,6}},{{1,6,5}},{{2,3,7}},{{2,7,6}},{{3,0,4}},{{3,4,7}}};return mesh;
}
Mesh merged(const std::vector<FurnitureBody>& bodies) {
    Mesh out;for(const auto& body:bodies){const auto offset=static_cast<std::uint32_t>(out.vertices.size());
        out.vertices.insert(out.vertices.end(),body.mesh.vertices.begin(),body.mesh.vertices.end());
        for(auto triangle:body.mesh.triangles){for(auto& index:triangle.vertices)index+=offset;out.triangles.push_back(triangle);}}
    return out;
}
Asset book(std::uint64_t id=101) {
    Asset a;a.id=id;a.name="Flat book";a.category=AssetCategory::Book;a.mesh=box(-40,-25,0,40,25,10);a.allowed_yaws_degrees={0};
    a.anchor={0,0,0};a.stackable=true;a.stack_height_mm=10;a.stack_footprint={{-40,-25,10},{40,-25,10},{40,25,10},{-40,25,10}};
    a.allowed_on_top=asset_bit(AssetCategory::Book);return prepare_asset(std::move(a));
}
Asset vase() {Asset a;a.id=102;a.name="Vase";a.category=AssetCategory::Vase;a.mesh=box(-25,-25,0,25,25,80);a.anchor={0,0,0};a.allowed_yaws_degrees={0};return prepare_asset(std::move(a));}
ArrangeSettings settings(FurnitureCategory category=FurnitureCategory::TVConsole) {
    ArrangeSettings s;s.category=category;s.density=0.08;s.empty_space=0.5;s.spacing_mm=20;s.edge_clearance_mm=5;s.cluster_strength=0;s.height_variation=0;
    return s;
}
bool same_pose(const Placement& a,const Placement& b) {return a.stable_id==b.stable_id&&a.asset_id==b.asset_id&&a.region_id==b.region_id&&a.parent_stack_id==b.parent_stack_id&&
    a.position.x==b.position.x&&a.position.y==b.position.y&&a.position.z==b.position.z&&a.yaw_degrees==b.yaw_degrees&&a.scale==b.scale;}
const Placement& find(const ArrangementResult& result,std::uint64_t id) {const auto i=std::find_if(result.placements.begin(),result.placements.end(),[id](const Placement& p){return p.stable_id==id;});if(i==result.placements.end())throw std::runtime_error("Preserved stable ID missing");return *i;}
void rectangle_oracle(const ArrangementResult& result,const std::vector<Asset>& assets,double edge,bool shelf_divider) {
    std::map<std::uint64_t,const Asset*> library;for(const auto& a:assets)library.emplace(a.id,&a);
    for(const auto& p:result.placements){const auto& a=*library.at(p.asset_id);check(p.yaw_degrees==0&&p.scale==1,"Independent analytic fixture uses unrotated unscaled boxes");
        // Analytic bounds come directly from known fixture dimensions, not query helpers.
        const double hx=a.id==102?25:40,hy=25,hz=a.id==102?80:10;
        // At z=440 the upper board, side-wall caps and back-wall cap form
        // the literal full rectangle [-20,1020] x [0,420]. Its supported
        // stacks inherit that same boundary. Interior shelves remain [0,1000].
        const bool cap=shelf_divider&&p.position.z>=440-0.003;
        check(p.position.x-hx>=(cap?-20:0)+edge-0.003&&p.position.x+hx<=(cap?1020:1000)-edge+0.003&&p.position.y-hy>=edge-0.003&&p.position.y+hy<=(cap?420:400)-edge+0.003,
            "Complete physical footprint stays inside the board margin");
        if(shelf_divider&&p.position.z<220-0.003)
            check(p.position.x+hx<=480+0.003||p.position.x-hx>=520-0.003,"No prop intersects the known divider slab");
        if(!shelf_divider&&p.position.z<80-0.003)
            check(p.position.x+hx<=450+0.003||p.position.x-hx>=550-0.003||p.position.y+hy<=100+0.003||p.position.y-hy>=300-0.003,
                "No prop intersects the known television foot obstacle");
        for(const auto& other:result.placements){if(p.stable_id>=other.stable_id)continue;
            const double ohx=other.asset_id==102?25:40,ohy=25,ohz=other.asset_id==102?80:10;
            if(p.position.z+hz<=other.position.z+0.003||other.position.z+ohz<=p.position.z+0.003)continue;
            check(std::abs(p.position.x-other.position.x)>=hx+ohx+20-0.003||std::abs(p.position.y-other.position.y)>=hy+ohy+20-0.003,
                "Actual full-volume prop pairs respect spacing independently of the query");
        }
    }
}
std::vector<FurnitureBody> console() {return {{1,box(0,0,0,1000,400,20)},{2,box(0,400,20,1000,420,400)},{3,box(450,100,20,550,300,80)}};}
std::vector<FurnitureBody> shelves() {return {{1,box(0,0,0,1000,400,20)},{2,box(0,0,220,1000,400,240)},{3,box(0,0,420,1000,400,440)},
    {4,box(-20,0,0,0,420,440)},{5,box(1000,0,0,1020,420,440)},{6,box(0,400,0,1000,420,440)},{7,box(480,0,20,520,400,220)}};}
void console_real_fit_and_reroll() {
    const auto bodies=console();FurniturePlacementQuery query(bodies);Settings inspection;inspection.cell_size_mm=50;
    const std::vector<FurnitureBody> target{bodies[0],bodies[1]};
    const auto support=inspect(merged(target),inspection);std::vector<Asset> assets{book(),vase()};auto s=settings();
    const auto first=arrange({support.regions,assets},s,query);check(first.placements.size()>=2,"Real TV-console query must produce several valid props");
    rectangle_oracle(first,assets,5,false);const auto repeated=arrange({support.regions,assets},s,query);check(first.placements.size()==repeated.placements.size(),"Deterministic accepted count under real collision query");
    for(std::size_t i=0;i<first.placements.size();++i)check(same_pose(first.placements[i],repeated.placements[i]),"Real query rerun preserves exact deterministic rows");
    s.seed=27;const auto rerolled=arrange({support.regions,assets},s,query);check(!rerolled.placements.empty(),"Real reroll produces accepted props");
    check(!same_pose(first.placements.front(),rerolled.placements.front()),"Seed reroll changes actual valid rows");rectangle_oracle(rerolled,assets,5,false);
    auto invalid=first.placements;invalid.front().position={500,200,20};invalid.front().locked=true;
    rejects([&]{arrange({support.regions,assets,invalid},s,query);});check(invalid.front().position.x==500&&invalid.front().locked,"Failed protected solve leaves caller rows intact");
}
void shelves_real_stacks_and_selective() {
    const auto bodies=shelves();FurniturePlacementQuery query(bodies);Settings inspection;inspection.cell_size_mm=50;
    const auto support=inspect(merged(bodies),inspection);std::vector<Asset> assets{book()};auto s=settings(FurnitureCategory::OpenShelf);
    s.cluster_strength=1;s.style=ArrangeStyle::Layered;s.density=0.04;
    const auto first=arrange({support.regions,assets},s,query);check(!first.placements.empty(),"Real open shelves generate props");rectangle_oracle(first,assets,5,true);
    std::vector<std::uint32_t> occupied_regions;bool stack=false;
    for(const auto& p:first.placements){if(std::find(occupied_regions.begin(),occupied_regions.end(),p.region_id)==occupied_regions.end())occupied_regions.push_back(p.region_id);
        if(p.parent_stack_id){stack=true;const auto& parent=find(first,p.parent_stack_id);check(std::abs(p.position.z-parent.position.z-10)<1e-7,"Real book stack rests on its authored parent top");}}
    check(occupied_regions.size()>=3,"All three accessible shelf layers receive valid props");check(stack,"Exact support and collision accept real parented book stacks");
    const auto child=std::find_if(first.placements.begin(),first.placements.end(),[](const Placement& p){return p.parent_stack_id!=0;});
    std::vector<std::uint64_t> locks{child->stable_id};std::vector<std::uint32_t> selected{child->region_id};s.seed=55;
    const auto next=arrange({support.regions,assets,first.placements,locks,selected},s,query);
    for(const auto& p:first.placements)if(p.region_id!=selected[0]||p.stable_id==child->stable_id||p.stable_id==child->parent_stack_id)
        check(same_pose(find(next,p.stable_id),p),"Locks/ancestors and unselected shelves preserve exact rows under real query");
    check(find(next,child->stable_id).locked,"Real-query selective solve persists explicit lock");rectangle_oracle(next,assets,5,true);
    std::vector<RegionPlacementRule> rules;for(const auto& r:support.regions){RegionPlacementRule rule;rule.region_id=r.id;rule.allow_stacking=false;rule.excluded=r.bounds.min.z>=440;rules.push_back(rule);}
    const auto flat=arrange({support.regions,assets,first.placements,{},{},{},false,rules},s,query);
    check(!flat.placements.empty()&&std::all_of(flat.placements.begin(),flat.placements.end(),[](const auto& p){return p.parent_stack_id==0;}),"Real shelf regeneration removes unlocked stacks when regional stacking is disabled");
    rectangle_oracle(flat,assets,5,true);
    rejects([&]{arrange({support.regions,assets,first.placements,locks,{},{},false,rules},s,query);});
}
void regional_front_access_and_exclusion() {
    const std::vector<FurnitureBody> bodies{{1,box(0,0,0,1000,400,20)},{2,box(0,390,20,1000,400,300)}};
    QuerySettings query_settings;query_settings.front_direction={0,1,0};FurniturePlacementQuery query(bodies,query_settings);
    Settings inspection;inspection.cell_size_mm=50;const auto support=inspect(merged(bodies),inspection);
    std::vector<RegionPlacementRule> rules;std::uint32_t surface_id=0;
    for(const auto& r:support.regions){RegionPlacementRule rule;rule.region_id=r.id;rule.allowed_asset_categories=asset_bit(AssetCategory::Book);rule.excluded=std::abs(r.bounds.min.z-20)>0.001;rules.push_back(rule);if(!rule.excluded)surface_id=r.id;}
    check(surface_id!=0,"Fixture inspector identifies the known lower support");
    std::vector<Asset> assets{book()};auto s=settings();s.density=0.03;
    const auto open=arrange({support.regions,assets,{},{},{},{},false,rules},s,query);
    check(!open.placements.empty(),"Authored front overrides the query's blocked global direction during real generation");
    for(const auto& p:open.placements)check(p.region_id==surface_id&&p.asset_id==101,"Real generation respects excluded upper support and chosen source geometry");
    for(const auto& p:open.placements){
        check(p.position.x-40>=5-0.003&&p.position.x+40<=995+0.003&&p.position.y-25>=5-0.003&&p.position.y+25<=390+0.003,
            "Known book footprint fits on the lower board and clears the rear wall");
        for(const auto& other:open.placements)if(p.stable_id<other.stable_id)
            check(std::abs(p.position.x-other.position.x)>=100-0.003||std::abs(p.position.y-other.position.y)>=70-0.003,
                "Regional book placements obey analytical full-bounds spacing");
    }
    for(auto& rule:rules)rule.front_direction={0,1,0};
    const auto blocked=arrange({support.regions,assets,{},{},{},{},false,rules},s,query);
    check(blocked.placements.empty()&&blocked.stats.underfilled>0,"Opposite regional front rejects every candidate behind the continuous rear wall");
    std::vector<std::uint64_t> locks{open.placements.front().stable_id};
    rejects([&]{arrange({support.regions,assets,open.placements,locks,{},{},false,rules},s,query);});
    for(auto& rule:rules){rule.front_direction={0,-1,0};rule.excluded=true;}
    check(arrange({support.regions,assets,open.placements,{},{},{},false,rules},s,query).placements.empty(),"Real exclusion drops previous unlocked placements while retaining current region identities");
    rejects([&]{arrange({support.regions,assets,open.placements,locks,{},{},false,rules},s,query);});
}
void query_admission_and_extreme_yaw() {
    const std::vector<FurnitureBody> bodies{{1,box(0,0,0,1000,400,20)}};QuerySettings query_settings;query_settings.require_front_access=false;
    FurniturePlacementQuery query(bodies,query_settings);const auto source=book();Placement placed;placed.position={500,200,20};placed.yaw_degrees=1e308;placed.scale=1;
    const auto footprint=placement_footprint(source,placed);const auto collider=placement_bounds(source,placed);
    PlacementProbe probe{footprint,collider,20,1,{},0,{},5,20000,50000000};
    const auto huge=query.validate(probe);check(huge.reason==Rejection::None,"Extreme finite yaw and legal high spacing remain valid");
    probe.collision.yaw_degrees=std::remainder(placed.yaw_degrees,360.0);const auto normalized=query.validate(probe);
    check(normalized.reason==huge.reason,"Finite huge yaw has the same collision result as its normalized angle");
    std::vector<PlacedObstacle> accepted;accepted.reserve(10001);
    for(std::uint64_t i=0;i<10000;++i)accepted.push_back({i+1,{{100000+static_cast<double>(i)*20,100000,25},{5,5,5},i==0?1e308:0}});
    probe.accepted=std::span<const PlacedObstacle>(accepted.data(),2501);check(query.validate(probe).reason==Rejection::None,"Query accepts more than the obsolete 2000-obstacle limit");
    probe.accepted=accepted;check(query.validate(probe).reason==Rejection::None,"Query and engine agree on the 10000 accepted-placement ceiling");
    accepted.push_back({10001,{{400000,100000,25},{5,5,5},0}});probe.accepted=accepted;rejects([&]{query.validate(probe);});
    query_settings.max_build_work=200000001;rejects([&]{FurniturePlacementQuery excessive(bodies,query_settings);});
}
void clustered_region_membership() {
    const std::vector<FurnitureBody> bodies{{1,box(-15,-15,-5,15,15,0)},{2,box(20,-40,-5,100,40,0)}};
    QuerySettings qs;qs.require_front_access=false;FurniturePlacementQuery query(bodies,qs);
    Asset source;source.id=101;source.name="20 mm regional accessory";source.category=AssetCategory::Accessory;
    source.mesh=box(-10,-10,0,10,10,10);source.allowed_yaws_degrees={0};
    std::vector<Asset> assets{prepare_asset(std::move(source))};
    const auto sampled=[](std::uint32_t id,double x0,double y0,double x1,double y1){
        Region r;r.id=id;r.bounds={{x0,y0,0},{x1,y1,0}};r.sampled_area_mm2=r.usable_area_mm2=(x1-x0)*(y1-y0);
        r.open_above=true;r.minimum_clearance_mm=INFINITY;
        for(double x=x0+2.5;x<x1;x+=5)for(double y=y0+2.5;y<y1;y+=5)r.cells.push_back({{x,y,0},INFINITY,true});return r;
    };
    const std::vector<Region> regions{sampled(1,-15,-15,15,15),sampled(2,20,-40,100,40)};
    Placement base;base.stable_id=9001;base.asset_id=101;base.region_id=1;base.locked=true;
    const std::vector<Placement> previous{base};auto s=settings();s.density=1;s.empty_space=0;s.spacing_mm=0;s.edge_clearance_mm=0;
    s.cluster_strength=1;s.max_placements=32;
    std::vector<RegionPlacementRule> rules(2);rules[0].region_id=1;rules[1].region_id=2;
    const std::vector<std::uint32_t> selected{1}; // Scope A explicitly; tags no longer exclude B.
    for(bool excluded:{true,false}){
        rules[1].excluded=excluded;rules[1].allowed_asset_categories=excluded?all_asset_mask:asset_bit(AssetCategory::Book);
        for(std::uint64_t seed=1;seed<=32;++seed){s.seed=seed;
            const auto result=arrange({regions,assets,previous,{},selected,{},false,rules},s,query);
            check(result.stats.requested==3&&result.stats.kept==1,"Independent area400 versus A900 requests three objects including the locked anchor");
            check(result.placements.size()==1&&result.stats.underfilled==2,"A fits one 20 mm accessory; same-height B cannot absorb its clustered candidates");
            check(result.stats.rejections[static_cast<std::size_t>(Rejection::Boundary)]>0,"Displaced clustered anchors receive explicit boundary rejections");
            for(const auto& p:result.placements)check(p.region_id==1&&std::abs(p.position.x)+10<=15.001&&std::abs(p.position.y)+10<=15.001,
                "Actual complete accessory bounds stay on A, independently of logical region labels and B's support plane");
            auto locked=result.placements;for(auto& p:locked)p.locked=true;
            const auto next=arrange({regions,assets,locked,{},selected,{},false,rules},s,query);
            check(next.placements.size()==locked.size()&&same_pose(next.placements.front(),locked.front()),"Every accepted output can be locked and validated by the next Generate");
            // Query refinement can conservatively fall back at a smaller
            // remaining allowance, so prior_work-1 need not exhaust a solve.
            // This fixture genuinely exhausts 1000 charged units; failure must
            // leave the complete protected caller input intact.
            if(seed==1){s.max_work=1000;rejects([&]{arrange({regions,assets,previous,{},selected,{},false,rules},s,query);});check(previous.size()==1&&previous[0].locked&&previous[0].stable_id==9001,"Work exhaustion retains the complete protected caller input");s.max_work=50000000;}
        }
    }
}
}
int main(){try{console_real_fit_and_reroll();std::cout<<"PASS console_real_fit_and_reroll\n";shelves_real_stacks_and_selective();std::cout<<"PASS shelves_real_stacks_and_selective\n";
    regional_front_access_and_exclusion();std::cout<<"PASS regional_front_access_and_exclusion\n";
    query_admission_and_extreme_yaw();std::cout<<"PASS query_admission_and_extreme_yaw\n";
    clustered_region_membership();std::cout<<"PASS clustered_region_membership\n5 integrated arrangement suites passed\n";return 0;}
    catch(const std::exception& e){std::cerr<<"FAIL integrated arrangement: "<<e.what()<<'\n';return 1;}}
