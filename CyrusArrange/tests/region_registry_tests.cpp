#include "cyrus_arrange/region_registry.h"
#include "cyrus_arrange/placement_queries.h"

#include <algorithm>
#include <cmath>
#include <functional>
#include <iostream>
#include <limits>
#include <map>
#include <stdexcept>
#include <vector>

using namespace cyrus::arrange;
// Literal physical witnesses for retaining saved support identities.
namespace sampling_identity_contract {
void check(bool value,const char* text){if(!value)throw std::runtime_error(text);}
void rejects(const std::function<void()>& action,const char* text){bool failed=false;try{action();}catch(const std::exception&){failed=true;}check(failed,text);}
Mesh box(double width,double depth,double height,Vec3 offset={}){
    Mesh m;m.vertices={{-width/2,-depth/2,0},{width/2,-depth/2,0},{width/2,depth/2,0},{-width/2,depth/2,0},
        {-width/2,-depth/2,height},{width/2,-depth/2,height},{width/2,depth/2,height},{-width/2,depth/2,height}};
    for(auto& p:m.vertices){p.x+=offset.x;p.y+=offset.y;p.z+=offset.z;}
    m.triangles={{{0,2,1}},{{0,3,2}},{{4,5,6}},{{4,6,7}},{{0,1,5}},{{0,5,4}},
        {{1,2,6}},{{1,6,5}},{{2,3,7}},{{2,7,6}},{{3,0,4}},{{3,4,7}}};return m;
}
Mesh soup(const std::vector<FurnitureBody>& bodies){Mesh out;for(const auto& body:bodies){const auto base=static_cast<std::uint32_t>(out.vertices.size());out.vertices.insert(out.vertices.end(),body.mesh.vertices.begin(),body.mesh.vertices.end());for(auto face:body.mesh.triangles){for(auto& v:face.vertices)v+=base;out.triangles.push_back(face);}}return out;}
RegionRegistryUpdate reconcile(std::shared_ptr<const RegionRegistry> old,Result& observed,std::uint64_t first,std::uint64_t source=11){
    const std::vector<std::uint64_t> keys{source};std::vector<RegionObservation> rows;for(const auto& r:observed.regions)rows.push_back({&r,keys});
    auto plan=plan_regions(std::move(old),rows);const bool allocate=plan.required_new_ids()!=0;auto update=finish_regions(std::move(plan),allocate?first:0);
    for(auto& r:observed.regions){auto b=std::find_if(update.bindings.begin(),update.bindings.end(),[&](const auto& row){return row.observed_id==r.id;});check(b!=update.bindings.end(),"Every actual current region has a persistent binding");r.id=b->stable_id;}return update;
}
std::vector<RegionPlacementRule> policies(const RegionRegistry& registry){std::vector<RegionPlacementRule> rows;for(const auto& r:registry.records){const auto& s=r.semantics;rows.push_back({r.stable_id,s.allowed_asset_categories,s.density_multiplier,s.allow_stacking,s.excluded,s.front_direction});}return rows;}
bool same(const Placement& a,const Placement& b){return a.stable_id==b.stable_id&&a.asset_id==b.asset_id&&a.parent_stack_id==b.parent_stack_id&&a.region_id==b.region_id&&a.position.x==b.position.x&&a.position.y==b.position.y&&a.position.z==b.position.z&&a.yaw_degrees==b.yaw_degrees&&a.scale==b.scale&&a.locked==b.locked;}
void every_semantic_field(){
    check(!has_nondefault_region_semantics({}),"Fresh neutral sampled records do not pin automatic sampling");
    const std::vector<std::function<void(RegionSemantics&)>> edits{
        [](auto& s){s.label="named";},[](auto& s){s.compartment_label="bay";},[](auto& s){s.role=SupportRole::Ledge;},
        [](auto& s){s.allowed_asset_categories=asset_bit(AssetCategory::Plant);},[](auto& s){s.density_multiplier=.5;},
        [](auto& s){s.allow_stacking=false;},[](auto& s){s.excluded=true;},[](auto& s){s.front_direction.x=.25;},
        [](auto& s){s.front_direction.y=-2;},[](auto& s){s.front_direction.z=1e-10;}};
    for(const auto& edit:edits){RegionSemantics s;edit(s);check(has_nondefault_region_semantics(s),"Every observable nondefault semantic component pins identity");s=RegionSemantics{};check(!has_nondefault_region_semantics(s),"Explicitly restoring all neutral values releases metadata pin");}
}
void run(){
    every_semantic_field();
    Settings old_grid;old_grid.cell_size_mm=25;old_grid.minimum_clearance_mm=0;old_grid.maximum_slope_degrees=0;
    std::vector<FurnitureBody> full{{11,box(1000,400,20,{0,0,-20})}};auto observed=inspect(soup(full),old_grid);check(observed.regions.size()==1,"Literal outward board has one support");
    auto initial=reconcile({},observed,73);auto authored=std::make_shared<RegionRegistry>(*initial.registry);authored->records[0].semantics.label="Authored current front";authored->records[0].semantics.front_direction={0,-1,0};
    Asset asset;asset.id=1;asset.name="Literal original-size upright book";asset.category=AssetCategory::Book;asset.mesh=box(20,100,100);asset.allowed_yaws_degrees={0};asset.book_row=BookRowProfile{SpineFace::NegativeY};asset=prepare_asset(std::move(asset));std::vector<Asset> assets{asset};
    std::vector<Placement> original;for(std::uint64_t i=0;i<3;++i){Placement p;p.stable_id=101+i;p.asset_id=1;p.region_id=73;p.position={-23+23*static_cast<double>(i),0,0};p.scale=1;p.locked=i==1;original.push_back(p);}
    CompositionGroup group;group.stable_id=999;group.region_id=73;group.member_ids={101,102,103};group.front_direction={0,-1,0};group.gap_mm=3;std::vector<CompositionGroup> groups{group};
    ArrangeSettings settings;settings.amount_mode=AmountMode::Quantity;settings.quantity=3;settings.spacing_mm=20;settings.edge_clearance_mm=10;settings.random_scale=false;settings.fit_to_space=false;
    QuerySettings qs;qs.require_front_access=false;FurniturePlacementQuery query(full,qs);
    auto current=inspect(soup(full),old_grid);auto retained=reconcile(authored,current,74);auto rules=policies(*retained.registry);check(retained.retired_ids.empty()&&retained.registry->records[0].stable_id==73,"Same saved lattice retains authoritative front and region identity");
    ArrangementRequest request{current.regions,assets};request.previous=original;request.previous_groups=groups;request.region_rules=rules;request.composition.book_rows=false;
    const auto kept=arrange(request,settings,query);check(kept.placements.size()==3&&kept.stats.kept==3&&kept.groups.size()==1,"Ordinary geometry retains the complete protected row");
    for(std::size_t i=0;i<original.size();++i)check(same(original[i],kept.placements[i]),"Every original protected pose ID scale and individual lock remains exact");
    check(kept.groups[0].stable_id==999&&kept.groups[0].region_id==73&&kept.groups[0].member_ids==group.member_ids&&kept.groups[0].gap_mm==3&&kept.groups[0].front_direction.x==0&&kept.groups[0].front_direction.y==-1&&kept.groups[0].front_direction.z==0,"Group descriptor is exact");
    auto fine=old_grid;fine.cell_size_mm=automatic_cell_size({{-500,-200,-20},{500,200,0}},20);check(fine.cell_size_mm!=25,"New source-derived grid actually differs from released-style grid");auto resampled=inspect(soup(full),fine);auto renamed=reconcile(authored,resampled,74);check(renamed.retired_ids==std::vector<std::uint32_t>{73},"Automatic resolution change retires old identity under exact contract");
    auto new_rules=policies(*renamed.registry);auto invalid=request;invalid.regions=resampled.regions;invalid.region_rules=new_rules;rejects([&]{arrange(invalid,settings,query);},"Protected row cannot follow a retired ID");
    // Unlocked outputs still need the accepted lattice when a saved region
    // carries exclusion/policy. Counterfactual resampling would silently drop
    // that policy and admit placements on the same physical board.
    auto excluded_registry=std::make_shared<RegionRegistry>(*authored);excluded_registry->records[0].semantics.excluded=true;
    auto policy_observed=inspect(soup(full),old_grid);auto kept_policy=reconcile(excluded_registry,policy_observed,74);auto excluded_rules=policies(*kept_policy.registry);
    ArrangementRequest empty_previous{policy_observed.regions,assets};empty_previous.region_rules=excluded_rules;const auto excluded=arrange(empty_previous,settings,query);check(excluded.placements.empty()&&kept_policy.registry->records[0].semantics.excluded,"Authored exclusion is retained without locks or category eligibility");
    invalid=request;invalid.region_rules=excluded_rules;rejects([&]{arrange(invalid,settings,query);},"A retained excluded policy still rejects a conflicting protected row");
    auto lost_observed=inspect(soup(full),fine);auto lost_policy=reconcile(excluded_registry,lost_observed,74);auto neutral_rules=policies(*lost_policy.registry);empty_previous.regions=lost_observed.regions;empty_previous.region_rules=neutral_rules;
    const auto wrong_board=arrange(empty_previous,settings,query);check(wrong_board.placements.size()==3&&!lost_policy.registry->records[0].semantics.excluded,"Counterfactual changed sampling demonstrably loses exclusion and permits wrong-board output");
    auto turned=rules;turned[0].front_direction={1,0,0};invalid=request;invalid.region_rules=turned;rejects([&]{arrange(invalid,settings,query);},"An intentionally changed regional front remains a hard protected relationship failure");
    auto replacement=inspect(soup(full),old_grid);auto rebound=reconcile(authored,replacement,74,12);auto replacement_rules=policies(*rebound.registry);invalid=request;invalid.regions=replacement.regions;invalid.region_rules=replacement_rules;rejects([&]{arrange(invalid,settings,query);},"Identical geometry with a new persistent source cannot inherit protected identity");
    // A one-millimetre hole at the coarse lattice's four-cell junction misses
    // all five rays (nearest inset rays are 1.25mm from X/Y zero). The physical
    // footprint query must nevertheless reject the middle retained full book.
    std::vector<FurnitureBody> hole{{11,box(499.5,400,20,{-250.25,0,-20})},{12,box(499.5,400,20,{250.25,0,-20})},
        {13,box(1,199.5,20,{0,-100.25,-20})},{14,box(1,199.5,20,{0,100.25,-20})}};
    auto sampled_hole=inspect(soup(hole),old_grid);auto invisible_hole=reconcile(authored,sampled_hole,74);check(invisible_hole.retired_ids.empty()&&invisible_hole.registry->records[0].stable_id==73,"Hole witness is genuinely invisible to the accepted coarse registry");
    FurniturePlacementQuery hole_query(hole,qs);rejects([&]{arrange(request,settings,hole_query);},"Same registry identity never bypasses exact complete-footprint support over an unsampled hole");
    std::vector<FurnitureBody> overhead{{99,box(1000,400,10,{0,0,50})}};FurniturePlacementQuery blocked(full,qs,overhead);rejects([&]{arrange(request,settings,blocked);},"Preserved grid does not exempt actual changed headroom/collision");
    auto released=original;for(auto& p:released)p.locked=false;
    auto neutral_registry=std::make_shared<RegionRegistry>(*authored);neutral_registry->records[0].semantics=RegionSemantics{};
    check(!has_nondefault_region_semantics(neutral_registry->records[0].semantics),"Final release also explicitly clears saved nondefault region intent");
    auto released_observed=inspect(soup(full),fine);auto released_binding=reconcile(neutral_registry,released_observed,74);auto released_rules=policies(*released_binding.registry);
    invalid.regions=released_observed.regions;invalid.assets=assets;invalid.previous=released;invalid.previous_groups=groups;invalid.region_rules=released_rules;invalid.composition.book_rows=false;
    const auto ordinary=arrange(invalid,settings,query);check(ordinary.placements.size()==3&&ordinary.groups.empty()&&ordinary.stats.kept==0,"Released protection and neutral metadata permit fresh grid and ordinary current geometry");for(const auto& p:ordinary.placements)check(p.region_id!=73&&p.scale==1,"Released successor uses current regions and original scale");
}
}
namespace {
void check(bool condition,const char* message){if(!condition)throw std::runtime_error(message);}
void rejects(const std::function<void()>& action){bool failed=false;try{action();}catch(const std::exception&){failed=true;}check(failed,"Expected bounded registry rejection");}
Region region(std::uint32_t id=1,double offset=0){
    Region r;r.id=id;r.bounds={{offset,0,20},{offset+100,100,20}};r.minimum_clearance_mm=std::numeric_limits<double>::infinity();r.open_above=true;
    for(int x=0;x<10;++x)for(int y=0;y<10;++y)r.cells.push_back({{offset+5+x*10.0,5+y*10.0,20},std::numeric_limits<double>::infinity(),true});
    r.sampled_area_mm2=r.usable_area_mm2=10000;return r;
}
void erase_cell(Region& r,std::size_t index){r.cells.erase(r.cells.begin()+static_cast<std::ptrdiff_t>(index));r.sampled_area_mm2=r.usable_area_mm2=static_cast<double>(r.cells.size())*100;}
RegionRegistryUpdate update(std::shared_ptr<const RegionRegistry> previous,std::vector<Region>& regions,std::uint64_t first=1,RegionRegistrySettings settings={}){
    const std::vector<std::uint64_t> sources{7,3};std::vector<RegionObservation> observations;for(const auto& r:regions)observations.push_back({&r,sources});
    auto plan=plan_regions(std::move(previous),observations,settings);const bool needs_ids=plan.required_new_ids()!=0;return finish_regions(std::move(plan),needs_ids?first:0);
}
std::uint32_t binding(const RegionRegistryUpdate& value,std::uint32_t id){for(const auto& b:value.bindings)if(b.observed_id==id)return b.stable_id;throw std::runtime_error("Observed region binding missing");}
void append_plane(Mesh& m,double x,bool other_diagonal){const auto b=static_cast<std::uint32_t>(m.vertices.size());m.vertices.insert(m.vertices.end(),{{x,0,20},{x+100,0,20},{x+100,100,20},{x,100,20}});
    if(other_diagonal){m.triangles.push_back({{b,b+1,b+3}});m.triangles.push_back({{b+1,b+2,b+3}});}else{m.triangles.push_back({{b,b+1,b+2}});m.triangles.push_back({{b,b+2,b+3}});}}
void retriangulation_source_order_and_cow(){
    Mesh first;append_plane(first,0,false);append_plane(first,150,false);Mesh second;append_plane(second,150,true);append_plane(second,0,true);Settings settings;settings.cell_size_mm=10;
    auto a=inspect(first,settings),b=inspect(second,settings);check(a.regions.size()==2&&b.regions.size()==2,"Independent planes remain two support regions");
    auto initial=update({},a.regions,10);const auto encoded=encode_region_registry(*initial.registry);
    std::reverse(b.regions.begin(),b.regions.end());for(auto& r:b.regions)std::reverse(r.cells.begin(),r.cells.end());
    const std::vector<std::uint64_t> keys{3,7};std::vector<RegionObservation> observations;for(const auto& r:b.regions)observations.push_back({&r,keys});
    auto plan=plan_regions(initial.registry,observations);check(plan.required_new_ids()==0,"Retriangulation and source/cell order changes preserve identity");
    auto next=finish_regions(std::move(plan),0);check(encode_region_registry(*next.registry)==encoded,"Equivalent geometry produces byte-identical registry");
    for(std::size_t i=0;i<next.registry->records.size();++i)check(next.registry->records[i].shape==initial.registry->records[i].shape,"Exact matches share immutable shape storage");
}
void semantics_clearance_and_exclusions(){
    std::vector<Region> regions{region()};auto initial=update({},regions,20);auto authored=std::make_shared<RegionRegistry>(*initial.registry);auto& s=authored->records[0].semantics;
    s.label="Shelf \xD8\xA7";s.compartment_label="Left bay";s.role=SupportRole::OpenShelf;s.allowed_asset_categories=asset_bit(AssetCategory::Book);s.density_multiplier=0.5;s.allow_stacking=false;s.excluded=true;s.front_direction={1,0,0};
    regions[0].id=99;regions[0].minimum_clearance_mm=50;regions[0].open_above=false;for(auto& cell:regions[0].cells){cell.clearance_mm=50;cell.usable=false;}regions[0].usable_area_mm2=0;
    auto next=update(authored,regions,21);const auto& record=next.registry->records.front();check(binding(next,99)==20,"Computed obstruction changes do not rename support");
    check(record.minimum_clearance_mm==50&&!record.open_above,"Clearance measurements update independently");
    check(record.semantics.label==s.label&&record.semantics.compartment_label==s.compartment_label&&record.semantics.role==s.role&&record.semantics.excluded&&!record.semantics.allow_stacking&&
        record.semantics.allowed_asset_categories==asset_bit(AssetCategory::Book)&&record.semantics.density_multiplier==0.5&&record.semantics.front_direction.x==1,"Authored semantic policy and exclusion follow stable support");
    check(record.shape==authored->records[0].shape,"Semantic changes never duplicate large shape arrays");
}
void no_reuse_deletion_undo_and_failure(){
    std::uint64_t allocator=1;auto reserve=[&](std::size_t n){const auto first=allocator;allocator+=n;return first;};
    std::vector<Region> observations{region()};auto original=update({},observations,reserve(1));const auto prior=encode_region_registry(*original.registry);
    std::vector<RegionObservation> none;auto removed_plan=plan_regions(original.registry,none);auto removed=finish_regions(std::move(removed_plan),0);
    check(removed.registry->records.empty()&&removed.registry->high_water==1&&removed.retired_ids==std::vector<std::uint32_t>{1},"Deletion retains high-water and reports retired ID");
    auto recreated=update(removed.registry,observations,reserve(1));check(recreated.registry->records[0].stable_id==2,"Deleted geometry returning gets a fresh ID");
    auto restored=original.registry;observations.push_back(region(2,150));auto after_undo=update(restored,observations,reserve(1));
    check(binding(after_undo,1)==1&&binding(after_undo,2)==3,"Undo restores original identity while monotonic host allocator avoids reusing ID2");
    observations={region(5,500)};const std::vector<std::uint64_t> sources{3,7};std::vector<RegionObservation> input{{&observations[0],sources}};
    auto failing=plan_regions(restored,input);reserve(failing.required_new_ids());rejects([&]{finish_regions(std::move(failing),1);});
    auto retried=update(restored,observations,reserve(1));check(retried.registry->records[0].stable_id==5,"Failed publication reservation remains burned outside Undo");
    check(encode_region_registry(*restored)==prior,"Staging or failure never mutates previous registry");
}
void exact_default_and_conservative_overlap(){
    std::vector<Region> original{region()};auto first=update({},original,40);std::vector<Region> edited{region(2)};erase_cell(edited[0],55);
    auto exact=update(first.registry,edited,41);check(binding(exact,2)==41&&exact.retired_ids==std::vector<std::uint32_t>{40},"Exact-only default never proximity-rebinds edited geometry");
    RegionRegistrySettings fuzzy;fuzzy.allow_overlap_matching=true;auto conservative=update(first.registry,edited,41,fuzzy);check(binding(conservative,2)==40,"Explicit mutual-unique 99% geometry overlap can retain identity");
    erase_cell(edited[0],54);erase_cell(edited[0],53);auto too_much=update(first.registry,edited,41,fuzzy);check(binding(too_much,2)==41,"97% overlap is not a conservative match");
    auto raised=region(2);for(auto& cell:raised.cells)cell.center.z+=0.02;std::vector<Region> height_changed{raised};
    check(binding(update(first.registry,height_changed,41,fuzzy),2)==41,"Height change beyond 0.01mm does not retarget support");
}
void ambiguous_split_and_source_scope(){
    std::vector<Region> old{region(),region(2)};erase_cell(old[1],55);auto first=update({},old,50);
    std::vector<Region> current{region(3)};erase_cell(current[0],56);RegionRegistrySettings fuzzy;fuzzy.allow_overlap_matching=true;
    auto ambiguous=update(first.registry,current,52,fuzzy);check(binding(ambiguous,3)==52&&ambiguous.retired_ids.size()==2,"Multiple eligible old surfaces make an overlap match ambiguous");
    std::vector<Region> one{region()};auto parent=update({},one,60);auto left=region(10),right=region(11);
    left.cells.erase(left.cells.begin()+50,left.cells.end());right.cells.erase(right.cells.begin(),right.cells.begin()+50);
    for(auto* r:{&left,&right})r->sampled_area_mm2=r->usable_area_mm2=5000;
    std::vector<Region> split{left,right};auto division=update(parent.registry,split,61,fuzzy);check(division.registry->records.size()==2&&division.retired_ids==std::vector<std::uint32_t>{60}&&
        binding(division,10)!=60&&binding(division,11)!=60,"Split supports never arbitrarily inherit a parent region ID");
    const std::vector<std::uint64_t> new_sources{8};std::vector<RegionObservation> scoped{{&one[0],new_sources}};auto plan=plan_regions(parent.registry,scoped,fuzzy);
    check(plan.required_new_ids()==1,"Same geometry with a new persistent source scope requires fresh identity");
}
void deterministic_new_ids_and_uint32_limit(){
    std::vector<Region> regions{region(8,200),region(9,0)};auto a=update({},regions,100);std::reverse(regions.begin(),regions.end());auto b=update({},regions,100);
    check(binding(a,8)==binding(b,8)&&binding(a,9)==binding(b,9),"Allocation order is geometry/source based, independent of observation order");
    auto near_limit=std::make_shared<RegionRegistry>();near_limit->high_water=std::numeric_limits<std::uint32_t>::max()-1;
    std::vector<Region> one{region()};auto last=update(near_limit,one,std::numeric_limits<std::uint32_t>::max());check(last.registry->high_water==std::numeric_limits<std::uint32_t>::max(),"Last uint32 ID is usable");
    std::vector<Region> changed{region(2,500)};rejects([&]{update(last.registry,changed,std::uint64_t(std::numeric_limits<std::uint32_t>::max())+1);});
}
void serialization_and_corruption(){
    std::vector<Region> regions{region(),region(2,150)};auto first=update({},regions,200);auto edited=std::make_shared<RegionRegistry>(*first.registry);edited->records[0].semantics.label="Persistent shelf";edited->records[0].semantics.excluded=true;
    const auto bytes=encode_region_registry(*edited);auto decoded=decode_region_registry(bytes);check(encode_region_registry(*decoded)==bytes,"Portable LE registry round-trip is exact");
    std::reverse(edited->records.begin(),edited->records.end());check(encode_region_registry(*edited)==bytes,"Serialization canonicalizes record order");
    for(auto n:{std::size_t(0),std::size_t(7),std::size_t(12),std::size_t(19),bytes.size()-1})rejects([&]{decode_region_registry(std::span<const std::uint8_t>(bytes.data(),n));});
    auto invalid=bytes;invalid[0]^=1;rejects([&]{decode_region_registry(invalid);});invalid=bytes;invalid[8]=2;rejects([&]{decode_region_registry(invalid);});
    invalid=bytes;for(std::size_t i=16;i<20;++i)invalid[i]=255;rejects([&]{decode_region_registry(invalid);});
    invalid=bytes;const auto key=invalid.size()-24;for(std::size_t i=0;i<8;++i)invalid[key+i]=i==7?128:0;rejects([&]{decode_region_registry(invalid);});
    invalid=bytes;invalid.push_back(0);rejects([&]{decode_region_registry(invalid);});
}
void bounded_and_invalid(){
    std::vector<Region> regions{region()};const std::vector<std::uint64_t> source{1};std::vector<RegionObservation> observations{{&regions[0],source}};
    RegionRegistrySettings settings;settings.max_work=1;rejects([&]{plan_regions({},observations,settings);});settings={};settings.max_cells=99;rejects([&]{plan_regions({},observations,settings);});
    settings={};settings.max_bytes=32;rejects([&]{plan_regions({},observations,settings);});settings={};settings.overlap_threshold=0.97;rejects([&]{plan_regions({},observations,settings);});
    settings={};settings.maximum_height_change_mm=0.02;rejects([&]{plan_regions({},observations,settings);});settings={};settings.max_work=50000001;rejects([&]{plan_regions({},observations,settings);});
    auto duplicate=observations;duplicate.push_back(observations[0]);rejects([&]{plan_regions({},duplicate);});
    const std::vector<std::uint64_t> bad_source{0};observations[0].source_keys=bad_source;rejects([&]{plan_regions({},observations);});
    regions[0].cells[0].center.x=std::numeric_limits<double>::quiet_NaN();observations[0].source_keys=source;rejects([&]{plan_regions({},observations);});
    regions[0]=region();regions[0].open_above=false;rejects([&]{plan_regions({},observations);});
    regions[0]=region();auto good=update({},regions);auto invalid=std::make_shared<RegionRegistry>(*good.registry);invalid->records[0].semantics.label=std::string("bad\0label",9);
    rejects([&]{validate_region_registry(*invalid);});invalid->records[0].semantics.label="\xC0\xAF";rejects([&]{validate_region_registry(*invalid);});
    invalid->records[0].semantics.label.clear();invalid->records[0].semantics.density_multiplier=5;rejects([&]{encode_region_registry(*invalid);});
}
}
int main(){const std::vector<std::pair<const char*,std::function<void()>>> tests{{"retriangulation_source_order_and_cow",retriangulation_source_order_and_cow},
    {"semantics_clearance_and_exclusions",semantics_clearance_and_exclusions},{"no_reuse_deletion_undo_and_failure",no_reuse_deletion_undo_and_failure},
    {"exact_default_and_conservative_overlap",exact_default_and_conservative_overlap},{"ambiguous_split_and_source_scope",ambiguous_split_and_source_scope},
    {"deterministic_new_ids_and_uint32_limit",deterministic_new_ids_and_uint32_limit},{"serialization_and_corruption",serialization_and_corruption},{"bounded_and_invalid",bounded_and_invalid},
    {"sampling_identity_physical_contract",sampling_identity_contract::run}};
    for(const auto& [name,test]:tests)try{test();std::cout<<"PASS "<<name<<'\n';}catch(const std::exception& e){std::cerr<<"FAIL "<<name<<": "<<e.what()<<'\n';return 1;}
    std::cout<<tests.size()<<" region registry suites passed\n";return 0;}
