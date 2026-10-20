#include "cyrus_arrange/placement_queries.h"
#include <algorithm>
#include <array>
#include <cmath>
#include <functional>
#include <iostream>
#include <limits>
#include <map>
#include <stdexcept>

using namespace cyrus::arrange;
namespace {
void check(bool b,const char* message){if(!b)throw std::runtime_error(message);}
void near(double a,double b,const char* message){check(std::abs(a-b)<1e-7,message);}
void rejects(const std::function<void()>& f){bool failed=false;try{f();}catch(const std::exception&){failed=true;}check(failed,"Expected bounded validation failure");}
Mesh box(double width,double depth,double height,Vec3 offset={}) {
    Mesh m;m.vertices={{-width/2,-depth/2,0},{width/2,-depth/2,0},{width/2,depth/2,0},{-width/2,depth/2,0},
        {-width/2,-depth/2,height},{width/2,-depth/2,height},{width/2,depth/2,height},{-width/2,depth/2,height}};
    for(auto& v:m.vertices){v.x+=offset.x;v.y+=offset.y;v.z+=offset.z;}
    m.triangles={{{0,2,1}},{{0,3,2}},{{4,5,6}},{{4,6,7}},{{0,1,5}},{{0,5,4}},
        {{1,2,6}},{{1,6,5}},{{2,3,7}},{{2,7,6}},{{3,0,4}},{{3,4,7}}};return m;
}
Asset book(std::uint64_t id=1,double height=200) {
    Asset a;a.id=id;a.name="Individual upright book";a.category=AssetCategory::Book;a.mesh=box(20,100,height);
    a.book_row=BookRowProfile{};return prepare_asset(std::move(a));
}
Region region(std::uint32_t id=1,double xoffset=0) {
    Region r;r.id=id;r.bounds={{-500+xoffset,-200,0},{500+xoffset,200,0}};r.sampled_area_mm2=r.usable_area_mm2=400000;
    r.minimum_clearance_mm=std::numeric_limits<double>::infinity();r.open_above=true;
    for(int x=0;x<40;++x)for(int y=0;y<16;++y)r.cells.push_back({{-487.5+25*x+xoffset,-187.5+25*y,0},r.minimum_clearance_mm,true});return r;
}
ArrangeSettings settings(){ArrangeSettings s;s.category=FurnitureCategory::OpenShelf;s.density=.1;s.empty_space=0;s.spacing_mm=20;s.edge_clearance_mm=10;s.cluster_strength=0;s.height_variation=0;return s;}
struct Fixture {
    std::vector<Region> regions{region()};std::vector<Asset> assets{book()};
    std::vector<RegionPlacementRule> rules{{1}};std::vector<CategoryRule> categories{{AssetCategory::Book,1,18,false}};
    ArrangementRequest request()const{ArrangementRequest q{regions,assets};q.region_rules=rules;q.custom_rules=categories;q.use_custom_rules=true;q.composition.book_rows=true;return q;}
};
FurniturePlacementQuery geometry(bool foot=false) {
    std::vector<FurnitureBody> bodies{{1,box(1000,400,20,{0,0,-20})}};
    std::vector<FurnitureBody> obstacles;if(foot)obstacles.push_back({2,box(80,80,300,{150,0,0})});
    QuerySettings q;q.require_front_access=false;return FurniturePlacementQuery(bodies,q,obstacles);
}
bool same(const Placement& a,const Placement& b){return a.stable_id==b.stable_id&&a.asset_id==b.asset_id&&a.region_id==b.region_id&&a.parent_stack_id==b.parent_stack_id&&a.locked==b.locked&&
    a.position.x==b.position.x&&a.position.y==b.position.y&&a.position.z==b.position.z&&a.yaw_degrees==b.yaw_degrees&&a.scale==b.scale;}
void same_result(const ArrangementResult& a,const ArrangementResult& b){check(a.placements.size()==b.placements.size()&&a.groups.size()==b.groups.size(),"Deterministic composition cardinalities");
    for(std::size_t i=0;i<a.placements.size();++i)check(same(a.placements[i],b.placements[i]),"Deterministic member IDs and poses");
    for(std::size_t i=0;i<a.groups.size();++i)check(a.groups[i].stable_id==b.groups[i].stable_id&&a.groups[i].member_ids==b.groups[i].member_ids,"Deterministic ordered group IDs");}
const Placement& find(const ArrangementResult& r,std::uint64_t id){auto p=std::find_if(r.placements.begin(),r.placements.end(),[&](const auto& p){return p.stable_id==id;});if(p==r.placements.end())throw std::runtime_error("Missing retained member");return *p;}

void real_rows_counts_and_prefab() {
    Fixture f;auto q=geometry(true);auto input=f.request();const auto r=arrange(input,settings(),q);
    check(r.stats.requested==10&&r.placements.size()==10,"Independently known area/footprint target is ten individual props");
    check(!r.groups.empty()&&r.composition_stats.rows_formed==r.groups.size(),"Native generated relationships exist");
    validate_composition_structure(r.groups,r.placements);std::size_t grouped=0;
    for(const auto& g:r.groups){grouped+=g.member_ids.size();std::vector<Placement> members;
        for(auto id:g.member_ids){const auto& p=find(r,id);check(p.parent_stack_id==0&&p.scale==1,"Rows have individual full-size furniture-supported members");members.push_back(p);}
        validate_book_row_relationship(g,members,f.assets,{0,-1,0});
    }
    check(grouped<=r.placements.size()&&grouped>=2,"Row population counts members, not one prefab slot");
    for(const auto& p:r.placements){const bool sideways=std::llround(p.yaw_degrees/90)%2!=0;const double rx=sideways?50:10,ry=sideways?10:50;
        check(p.position.x-rx>=-490.001&&p.position.x+rx<=490.001&&p.position.y-ry>=-190.001&&p.position.y+ry<=190.001,"Every full member box inside analytic board edge");
        check(p.position.x+rx<=110.003||p.position.x-rx>=189.997||p.position.y+ry<=-39.997||p.position.y-ry>=39.997,"No full box intersects independent television-foot obstacle");}
    f.assets[0].book_row.reset();f.assets[0].category=AssetCategory::BookStack;f.categories={{AssetCategory::BookStack,1,18,false}};
    const auto prefab=arrange(f.request(),settings(),q);check(!prefab.placements.empty()&&prefab.groups.empty()&&prefab.composition_stats.row_attempts==0,"A prebuilt grouped model remains an ordinary single placement");
}

void spacing_is_scoped_and_collision_mandatory() {
    auto q=geometry();auto a=book();Placement one;one.stable_id=1;one.asset_id=1;one.yaw_degrees=180;Placement two=one;two.stable_id=2;two.position.x=23;
    std::vector<PlacedObstacle> accepted{{1,placement_bounds(a,one),7}};
    auto footprint=placement_footprint(a,two);PlacementProbe p{footprint,placement_bounds(a,two),0,1,accepted,0,{},0,20,100000,{},GroupSpacing{7,3}};
    check(q.validate(p).reason==Rejection::None,"Three millimetre internal gap overrides twenty millimetre external spacing");
    accepted[0].composition_group_id=8;check(q.validate(p).reason==Rejection::Spacing,"Different row retains global spacing");
    accepted[0].composition_group_id=7;p.same_group_spacing.reset();check(q.validate(p).reason==Rejection::Spacing,"No descriptor retains baseline spacing");
    two.position.x=19;footprint=placement_footprint(a,two);p.footprint_world=footprint;p.collision=placement_bounds(a,two);p.same_group_spacing=GroupSpacing{7,0};
    check(q.validate(p).reason==Rejection::Obstacle,"Zero row spacing never exempts static penetration");
    p.same_group_spacing=GroupSpacing{0,3};rejects([&]{q.validate(p);});p.same_group_spacing=GroupSpacing{7,-1};rejects([&]{q.validate(p);});
    p.same_group_spacing=GroupSpacing{7,3};p.support_parent_id=1;rejects([&]{q.validate(p);});
}

struct LastMemberReject final:PlacementQuery {
    mutable std::size_t refused{};
    QueryResult validate(const PlacementProbe& p)const override{if(p.same_group_spacing){std::size_t siblings=0;for(const auto& o:p.accepted)if(o.composition_group_id==p.same_group_spacing->group_id)++siblings;
        if(siblings==2){++refused;return {Rejection::Obstacle,1};}}return {Rejection::None,1};}
};
void atomic_last_member_and_limits() {
    Fixture f;auto request=f.request();request.composition.minimum_books=request.composition.maximum_books=3;f.categories[0].maximum_count=10;request.custom_rules=f.categories;
    LastMemberReject q;auto s=settings();const auto r=arrange(request,s,q);
    check(q.refused>0&&r.groups.empty()&&r.composition_stats.row_failures>0,"Third member failure commits no group");
    check(r.placements.size()==10&&r.stats.underfilled==0,"Failed rows leak neither member slots nor category counts");
    auto previous=r;const auto old=previous.placements;s.max_candidates=1;
    rejects([&]{previous=arrange(request,s,q);});check(previous.placements.size()==old.size()&&same(previous.placements[0],old[0]),"Candidate exhaustion after partial row leaves caller result intact");
    s=settings();s.max_work=1;rejects([&]{previous=arrange(request,s,q);});
    f.categories[0].maximum_count=2;request=f.request();request.composition.minimum_books=request.composition.maximum_books=3;
    auto physical=geometry();const auto capped=arrange(request,settings(),physical);check(!capped.groups.empty()&&capped.placements.size()==10,"Historical category caps cannot prevent complete physically valid rows");
}

void deterministic_order_and_yaw_profiles() {
    Fixture f;f.assets.push_back(book(2,300));f.assets.push_back(book(3,100));auto q=geometry();auto s=settings();const auto a=arrange(f.request(),s,q);
    std::reverse(f.assets.begin(),f.assets.end());std::reverse(f.regions[0].cells.begin(),f.regions[0].cells.end());same_result(a,arrange(f.request(),s,q));
    s.seed=77;const auto changed=arrange(f.request(),s,q);check(!same(a.placements.front(),changed.placements.front()),"Seed changes real row arrangement");
    const std::array<double,4> expected{90,270,0,180};
    for(unsigned face=0;face<4;++face){Fixture off;off.assets[0].mesh=box(20,100,200,{30,70,0});off.assets[0].anchor={25,65,0};off.assets[0].contact_footprint.clear();off.assets[0].book_row->spine_face=static_cast<SpineFace>(face);off.assets[0]=prepare_asset(off.assets[0]);
        const auto r=arrange(off.request(),settings(),q);check(!r.groups.empty(),"Every cardinal spine side generates actual rows with off-center contact anchors");
        for(const auto& g:r.groups)for(auto id:g.member_ids){const auto& p=find(r,id);near(std::fmod(p.yaw_degrees+360,360),expected[face],"Authored spine face selects the known quarter-turn");}
    }
    Fixture bad;bad.assets[0].allowed_yaws_degrees={0};const auto refused=arrange(bad.request(),settings(),q);
    check(refused.groups.empty()&&refused.composition_stats.row_failures>0,"No matching authored yaw creates no row");
    for(const auto& p:refused.placements)check(p.yaw_degrees==0,"Fallback never adds unauthored rotations");
    Fixture stepped;for(std::size_t i=0;i<stepped.regions[0].cells.size();++i)stepped.regions[0].cells[i].center.z=(i%2)*.005;
    struct Accept final:PlacementQuery {QueryResult validate(const PlacementProbe&)const override{return {Rejection::None,1};}} accept;
    auto input=stepped.request();input.composition.row_height_balance=.75;const auto canonical=arrange(input,settings(),accept);
    std::reverse(stepped.regions[0].cells.begin(),stepped.regions[0].cells.end());same_result(canonical,arrange(input,settings(),accept));
}

void protected_closure_and_current_relationship() {
    Fixture f;auto q=geometry();auto input=f.request();input.composition.minimum_books=input.composition.maximum_books=3;const auto first=arrange(input,settings(),q);
    check(!first.groups.empty(),"Retention fixture made a row");const auto group=first.groups.front();std::vector<std::uint64_t> locks{group.member_ids[1]};
    const auto closure=close_protected_placements(first.placements,first.groups,locks);
    check(closure.placement_ids.size()==3&&closure.group_ids==std::vector<std::uint64_t>{group.stable_id},"Locking one member closes whole row");
    input.previous=first.placements;input.previous_groups=first.groups;input.locked_ids=locks;input.composition.book_rows=false;
    auto s=settings();s.seed=999;const auto kept=arrange(input,s,q);
    for(auto id:group.member_ids){auto before=find(first,id),after=find(kept,id);if(id==locks.front())before.locked=true;check(same(before,after),"Protected row preserves every pose while rows disabled");}
    auto moved=first.placements;for(auto& p:moved)if(p.stable_id==locks.front())p.position.x+=5;input.previous=moved;rejects([&]{arrange(input,s,q);});
    input.previous=first.placements;f.assets[0].book_row.reset();input.assets=f.assets;rejects([&]{arrange(input,s,q);});
    f.assets[0].book_row=BookRowProfile{};input.assets=f.assets;f.rules[0].front_direction={0,1,0};input.region_rules=f.rules;rejects([&]{arrange(input,s,q);});
}

void removed_unlocked_and_selective_groups() {
    Fixture f;auto q=geometry();const auto first=arrange(f.request(),settings(),q);check(!first.groups.empty(),"Removed-region fixture made groups");
    f.regions={region(2)};f.rules={{2}};auto request=f.request();request.previous=first.placements;request.previous_groups=first.groups;request.composition.book_rows=false;
    auto s=settings();s.max_placements=2;s.density=0;const auto dropped=arrange(request,s,q);check(dropped.placements.empty()&&dropped.groups.empty(),"Unprotected previous groups drop despite missing region and lower new output cap");
    std::vector<std::uint64_t> locks{first.groups.front().member_ids.front()};request.locked_ids=locks;rejects([&]{arrange(request,s,q);});
    f=Fixture{};f.regions.push_back(region(2));f.rules.push_back({2});auto both=arrange(f.request(),settings(),q);
    std::vector<std::uint32_t> selected{1};request=f.request();request.previous=both.placements;request.previous_groups=both.groups;request.regenerate_region_ids=selected;s=settings();s.seed=91;
    const auto selective=arrange(request,s,q);for(const auto& p:both.placements)if(p.region_id==2)check(same(p,find(selective,p.stable_id)),"Unselected region groups retain all exact member poses");
}

void exact_hole_and_overhead_fit() {
    Fixture f;std::vector<FurnitureBody> supports{{1,box(460,400,20,{-270,0,-20})},{2,box(460,400,20,{270,0,-20})},
        {3,box(80,150,20,{0,125,-20})},{4,box(80,150,20,{0,-125,-20})}};
    QuerySettings qs;qs.require_front_access=false;FurniturePlacementQuery query(supports,qs);const auto r=arrange(f.request(),settings(),query);
    check(!r.groups.empty(),"Actual member rows fit around a known rectangular furniture hole");
    for(const auto& p:r.placements){const bool sideways=std::llround(p.yaw_degrees/90)%2!=0;const double rx=sideways?50:10,ry=sideways?10:50;
        check(p.position.x+rx<=-39.999||p.position.x-rx>=39.999||p.position.y+ry<=-49.999||p.position.y-ry>=49.999,
            "Every individual full footprint avoids the independent 80 by 100 mm hole");}
    std::vector<FurnitureBody> obstacles{{5,box(1000,400,10,{0,0,120})}},solid{{1,box(1000,400,20,{0,0,-20})}};FurniturePlacementQuery ceiling(solid,qs,obstacles);
    const auto blocked=arrange(f.request(),settings(),ceiling);
    check(blocked.groups.empty()&&blocked.placements.empty()&&blocked.stats.underfilled==10&&blocked.composition_stats.row_failures>0,
        "Low independent overhead blocks full-height rows and cannot become a new support");
}

void regional_policy_and_mixed_support_closure() {
    Fixture f;auto q=geometry();auto request=f.request();f.rules[0].allow_stacking=false;request.region_rules=f.rules;
    const auto first=arrange(request,settings(),q);check(!first.groups.empty(),"A non-stacking region still permits furniture-supported book rows");
    f.rules[0].allowed_asset_categories=asset_bit(AssetCategory::Plant);const auto masked=arrange(f.request(),settings(),q);check(!masked.placements.empty()&&!masked.groups.empty(),"Historical regional tags cannot reject the selected book geometry");
    f.rules[0].allowed_asset_categories=all_asset_mask;f.rules[0].excluded=true;check(arrange(f.request(),settings(),q).placements.empty(),"Excluded identities create no rows");
    request=f.request();request.previous=first.placements;request.previous_groups=first.groups;std::vector<std::uint64_t> locked{first.groups[0].member_ids[0]};request.locked_ids=locked;
    rejects([&]{arrange(request,settings(),q);});
    std::vector<Placement> poses{{1,1,0,1},{2,1,0,1},{10,1,0,1},{11,1,10,1},{12,1,999,1}};
    CompositionGroup group;group.stable_id=100;group.region_id=1;group.member_ids={1,2};std::vector<CompositionGroup> groups{group};std::vector<std::uint64_t> initial{2,11};
    const auto closure=close_protected_placements(poses,groups,initial);
    check(closure.placement_ids==std::vector<std::uint64_t>({1,2,10,11})&&closure.group_ids==std::vector<std::uint64_t>{100},"Shared closure preserves complete row and independent real stack");
    initial={12};rejects([&]{close_protected_placements(poses,groups,initial);});
    poses.back().parent_stack_id=1;rejects([&]{validate_composition_structure(groups,poses);});
}

double independent_profile(const std::vector<OrientedBox>& boxes) {
    std::array<double,16> height{};for(std::size_t i=0;i<16;++i){const double lo=-500+62.5*static_cast<double>(i),hi=lo+62.5;
        for(const auto& b:boxes)if(b.center.x+b.half_extents.x>lo&&b.center.x-b.half_extents.x<hi)height[i]=std::max(height[i],b.center.z+b.half_extents.z);}
    double sum=0,moment=0;for(std::size_t i=0;i<16;++i){sum+=height[i];moment+=height[i]*(-.9375+.125*static_cast<double>(i));}return sum?std::abs(moment)/sum:0;
}
struct RecordingQuery final:PlacementQuery {
    FurniturePlacementQuery concrete=geometry();std::size_t expected_members{3};mutable std::vector<std::vector<OrientedBox>> complete;
    QueryResult validate(const PlacementProbe& p)const override{const auto result=concrete.validate(p);if(result.reason==Rejection::None&&p.same_group_spacing){std::vector<OrientedBox> siblings;
        for(const auto& other:p.accepted)if(other.composition_group_id==p.same_group_spacing->group_id)siblings.push_back(other.box);
        if(siblings.size()+1==expected_members){siblings.push_back(p.collision);complete.push_back(std::move(siblings));}}return result;}
};
void real_height_balance_independent_oracle() {
    Fixture f;f.assets={book(1,100),book(2,200),book(3,300)};Asset plant;plant.id=4;plant.name="Tall fixed prop";plant.category=AssetCategory::Plant;plant.mesh=box(80,80,400);plant.weight=1e-12;f.assets.push_back(prepare_asset(plant));
    f.categories={{AssetCategory::Book,1,3,false},{AssetCategory::Plant,1,1,false}};Placement fixed;fixed.stable_id=777;fixed.asset_id=4;fixed.region_id=1;fixed.position={-350,-100,0};fixed.locked=true;
    std::vector<Placement> previous{fixed};auto request=f.request();request.previous=previous;request.composition.minimum_books=request.composition.maximum_books=3;
    auto s=settings();s.amount_mode=AmountMode::Quantity;s.quantity=4;bool witnessed=false;
    for(std::uint64_t seed=1;seed<=24&&!witnessed;++seed){s.seed=seed;RecordingQuery before_query;request.composition.row_height_balance=0;const auto before=arrange(request,s,before_query);
        check(before.groups.size()==1&&before.placements.size()==4,"Known balanced fixture reserves exactly three book members and one fixed tall prop");
        RecordingQuery query;request.composition.row_height_balance=1;const auto after=arrange(request,s,query);
        check(query.complete.size()>=1&&after.composition_stats.balance_anchor_attempts==8,"Balance has original plus at most eight bounded alternatives");
        const auto fixed_box=placement_bounds(f.assets[3],fixed);double best=1;
        for(auto candidate:query.complete){candidate.push_back(fixed_box);best=std::min(best,independent_profile(candidate));}
        std::vector<OrientedBox> actual,old;
        for(const auto& p:after.placements){actual.push_back(placement_bounds(f.assets[static_cast<std::size_t>(p.asset_id-1)],p));check(p.scale==1,"Height balance never rescales actual models");}
        for(const auto& p:before.placements)old.push_back(placement_bounds(f.assets[static_cast<std::size_t>(p.asset_id-1)],p));
        near(independent_profile(actual),best,"Chosen legal row minimizes independently computed sixteen-bin height objective");
        check(independent_profile(actual)<=independent_profile(old)&&same(fixed,find(after,777)),"Measured balance cannot worsen and fixed props never move");
        check(before.composition_stats.balance_anchor_attempts==0,"Zero balance performs no alternative queries");
        if(after.composition_stats.rows_moved){check(independent_profile(actual)<independent_profile(old),"Actual row translation improves height profile");witnessed=true;same_result(after,arrange(request,s,query));
            std::cout<<"BALANCE_WITNESS seed="<<seed<<" before="<<independent_profile(old)<<" after="<<independent_profile(actual)<<'\n';
            for(const auto& p:before.placements)if(p.asset_id!=4){const auto& moved=find(after,p.stable_id);std::cout<<"  asset="<<p.asset_id<<" old="<<p.position.x<<','<<p.position.y<<" new="<<moved.position.x<<','<<moved.position.y<<" yaw="<<p.yaw_degrees<<" scale="<<p.scale<<'\n';}
        }
    }
    check(witnessed,"At least one seeded legal row actually moves to improve the known tall-side fixture");
}

void malformed_public_contracts_and_budgets() {
    Fixture f;auto q=geometry();auto request=f.request();auto options=request.composition;options.minimum_books=1;rejects([&]{validate_composition_options(options,FurnitureCategory::OpenShelf);});
    options=request.composition;options.row_height_balance=std::numeric_limits<double>::quiet_NaN();rejects([&]{validate_composition_options(options,FurnitureCategory::OpenShelf);});
    validate_composition_options(request.composition,FurnitureCategory::DiningTable);request.region_rules={};rejects([&]{arrange(request,settings(),q);});
    const auto result=arrange(f.request(),settings(),q);auto groups=result.groups;check(!groups.empty(),"Malformed fixture made groups");
    groups[0].member_ids[1]=groups[0].member_ids[0];rejects([&]{validate_composition_structure(groups,result.placements);});
    groups=result.groups;groups[0].front_direction={};rejects([&]{validate_composition_structure(groups,result.placements);});
    groups=result.groups;auto poses=result.placements;poses.push_back(Placement{999999,1,groups[0].member_ids[0],1});rejects([&]{validate_composition_structure(groups,poses);});
    rejects([&]{validate_composition_structure(result.groups,result.placements,1);});
    std::vector<std::uint64_t> unknown{123456789};rejects([&]{close_protected_placements(result.placements,result.groups,unknown);});
    auto good=result.groups.front();std::vector<Placement> members;for(auto id:good.member_ids)members.push_back(find(result,id));
    members[0].position.z+=.1;rejects([&]{validate_book_row_relationship(good,members,f.assets,{0,-1,0});});
    struct BadWork final:PlacementQuery {QueryResult validate(const PlacementProbe& p)const override{return {Rejection::None,p.remaining_work+1};}} bad;
    rejects([&]{arrange(f.request(),settings(),bad);});
}

void ordinary_minimums_keep_protected_legacy_row() {
    Fixture f;auto physical=geometry();auto s=settings();s.amount_mode=AmountMode::Quantity;s.quantity=6;
    auto request=f.request();request.composition.minimum_books=request.composition.maximum_books=3;request.composition.row_height_balance=1;
    const auto legacy=arrange(request,s,physical);check(legacy.placements.size()==6&&!legacy.groups.empty(),"Legacy predecessor has real three-book relationships");
    const auto kept=legacy.groups.front();std::vector<std::uint64_t> locks{kept.member_ids[1]};
    auto optional=book(2,100);optional.name="Competing optional source";optional.book_row.reset();optional.weight=1000000;f.assets.push_back(prepare_asset(optional));
    std::vector<AssetMinimum> minimums{{1,5}};request=f.request();request.previous=legacy.placements;request.previous_groups=legacy.groups;request.locked_ids=locks;request.minimums=minimums;
    rejects([&]{arrange(request,s,physical);}); // Raw explicit row mode must not ignore required copies.
    request.composition.book_rows=false;const auto ordinary=arrange(request,s,physical);
    const auto copies=[](const ArrangementResult& r,std::uint64_t source){return std::count_if(r.placements.begin(),r.placements.end(),[&](const auto& p){return p.asset_id==source;});};
    check(ordinary.placements.size()==6&&copies(ordinary,1)>=5&&ordinary.stats.minimum_unfilled==0,"Ordinary placement fulfills source minimum despite a heavily weighted optional source");
    check(ordinary.groups.size()==1&&ordinary.groups[0].stable_id==kept.stable_id&&ordinary.groups[0].member_ids==kept.member_ids&&ordinary.groups[0].gap_mm==kept.gap_mm,"The protected legacy relationship and its small internal gap survive");
    for(auto id:kept.member_ids){auto before=find(legacy,id);if(id==locks[0])before.locked=true;check(same(before,find(ordinary,id)),"Protected closure preserves every member identity pose and scale");}
    check(ordinary.composition_stats.row_attempts==0&&ordinary.composition_stats.rows_formed==0&&ordinary.composition_stats.balance_anchor_attempts==0,"Ordinary generation creates no hidden new row or balance work");
    same_result(ordinary,arrange(request,s,physical));
    request.minimums={};const auto unrequired=arrange(request,s,physical);check(copies(unrequired,1)<5,"Counterfactual without minimum chooses the competing source; required-count check is nonvacuous");
    optional=book(2,300);optional.book_row.reset();f.assets[1]=prepare_asset(optional);minimums={{1,5},{2,1}};
    request=f.request();request.composition.book_rows=false;request.previous=legacy.placements;request.previous_groups=legacy.groups;request.locked_ids=locks;request.minimums=minimums;
    std::vector<FurnitureBody> floor{{1,box(1000,400,20,{0,0,-20})}},roof{{2,box(1000,400,20,{0,0,250})}};QuerySettings qs;qs.require_front_access=false;FurniturePlacementQuery low(floor,qs,roof);
    const auto blocked=arrange(request,s,low);check(copies(blocked,2)==0&&blocked.stats.minimum_unfilled==1,"A required source above actual headroom stays explicitly unfilled");
    for(auto id:kept.member_ids){auto before=find(legacy,id);if(id==locks[0])before.locked=true;check(same(before,find(blocked,id)),"Capacity underfill cannot move a protected row");}
}
}
int main(){try{
    const std::pair<const char*,void(*)()> suites[]={{"real_rows_counts_prefab",real_rows_counts_and_prefab},{"scoped_spacing_static_collision",spacing_is_scoped_and_collision_mandatory},
        {"atomic_last_member_and_limits",atomic_last_member_and_limits},{"deterministic_yaw_profiles",deterministic_order_and_yaw_profiles},
        {"protected_closure_relationship",protected_closure_and_current_relationship},{"removed_selective_groups",removed_unlocked_and_selective_groups},
        {"exact_hole_overhead_fit",exact_hole_and_overhead_fit},{"regional_policy_mixed_closure",regional_policy_and_mixed_support_closure},
        {"independent_height_balance",real_height_balance_independent_oracle},{"malformed_bounded_contracts",malformed_public_contracts_and_budgets},
        {"ordinary_minimums_protected_legacy",ordinary_minimums_keep_protected_legacy_row}};
    for(const auto& [name,test]:suites){test();std::cout<<"PASS "<<name<<'\n';}return 0;
}catch(const std::exception& e){std::cerr<<"FAIL "<<e.what()<<'\n';return 1;}}
