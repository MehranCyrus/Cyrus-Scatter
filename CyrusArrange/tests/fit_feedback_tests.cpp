#include "cyrus_arrange/fit_feedback.h"
#include "cyrus_arrange/placement_queries.h"
#include "cyrus_arrange/path.h"
#include <algorithm>
#include <cmath>
#include <iostream>
#include <stdexcept>
using namespace cyrus::arrange;
namespace {
std::size_t checks{};
void check(bool value,const char* why){++checks;if(!value)throw std::runtime_error(why);}
template<class F>void rejects(F f,const char* why){bool failed=false;try{f();}catch(const std::exception&){failed=true;}check(failed,why);}
Mesh box(double x0,double y0,double z0,double x1,double y1,double z1){Mesh m;m.vertices={{x0,y0,z0},{x1,y0,z0},{x1,y1,z0},{x0,y1,z0},{x0,y0,z1},{x1,y0,z1},{x1,y1,z1},{x0,y1,z1}};m.triangles={{{0,2,1}},{{0,3,2}},{{4,5,6}},{{4,6,7}},{{0,1,5}},{{0,5,4}},{{1,2,6}},{{1,6,5}},{{2,3,7}},{{2,7,6}},{{3,0,4}},{{3,4,7}}};return m;}
Asset prop(double w=100,double d=100,double h=450){Asset a;a.id=17;a.name="Coffee device";a.mesh=box(-w/2,-d/2,0,w/2,d/2,h);a.allowed_yaws_degrees={0};return prepare_asset(std::move(a));}
QueryResult validate(const FurniturePlacementQuery& query,const Asset& asset,const Placement& p,std::span<const PlacedObstacle> accepted={},std::uint64_t work=5000000){const auto f=placement_footprint(asset,p);CollisionSource collider(asset);return query.validate({f,placement_bounds(asset,p),p.position.z,p.region_id,accepted,0,{},5,10,work,{},{},{&collider,p.position,p.yaw_degrees,p.scale}});}
void physical_witnesses(){
    auto a=prop();Placement p{1,a.id,0,1,{300,200,20},0,1};
    const std::vector<FurnitureBody> floor{{41,box(0,0,0,600,400,20)}},roof{{92,box(0,0,300,600,400,320)}};
    QuerySettings settings;settings.require_front_access=false;FurniturePlacementQuery query(floor,settings,roof);
    auto q=validate(query,a,p);check(q.reason==Rejection::Obstacle&&q.witness.issue==FitIssue::Height&&q.witness.body_id==92&&q.witness.placement_id==0&&q.witness.has_bounds,"Actual roof underside names height and its independent body");
    p.scale=.6;q=validate(query,a,p);check(q.reason==Rejection::None&&q.witness.issue==FitIssue::None&&!q.witness.body_id,"Accepted full-size geometry check has no stale obstruction witness");
    p.scale=1;p.position.x=10;q=validate(query,a,p);check(q.reason==Rejection::Boundary&&q.witness.issue==FitIssue::Support&&!q.witness.body_id,"Support failure cannot name a body that was never narrow-phase tested");
    auto short_prop=prop(200,100,100);p.asset_id=short_prop.id;p.position={300,200,20};
    std::vector<FurnitureBody> side=floor;side.push_back({73,box(350,0,20,360,400,250)});FurniturePlacementQuery width(side,settings);q=validate(width,short_prop,p);check(q.witness.issue==FitIssue::Width&&q.witness.body_id==73,"Actual receiver side face distinguishes width obstruction");
    side=floor;side.push_back({74,box(0,225,20,600,235,250)});FurniturePlacementQuery depth(side,settings);q=validate(depth,short_prop,p);check(q.witness.issue==FitIssue::Depth&&q.witness.body_id==74,"Actual receiver back face distinguishes depth obstruction");
    FurniturePlacementQuery clear(floor,settings);std::vector<PlacedObstacle> occupied{{555,{{300,200,70},{30,30,50},0}}};q=validate(clear,short_prop,p,occupied);check(q.reason==Rejection::Obstacle&&q.witness.placement_id==555&&!q.witness.body_id,"Generated-output identity remains separate from body namespace");
    occupied[0].box.center.x=435;q=validate(clear,short_prop,p,occupied);check(q.reason==Rejection::Spacing&&q.witness.placement_id==555,"Gap failure names the actual nearby placement");
    settings.require_front_access=true;std::vector<FurnitureBody> front{{93,box(0,-80,20,600,-60,300)}};FurniturePlacementQuery access(floor,settings,front);q=validate(access,short_prop,p);check(q.reason==Rejection::Obstacle&&q.witness.issue==FitIssue::Access&&q.witness.body_id==93,"Swept approach identifies its actual external obstruction");
}
void cabinet_report(){
    auto a=prop();const auto original=a.mesh.vertices;const std::vector<Asset> assets{a};
    const std::vector<FurnitureBody> floor{{1,box(0,0,0,600,400,20)}},roof{{2,box(0,0,300,600,400,320)}};
    Settings sampling;sampling.cell_size_mm=50;const auto spaces=inspect(floor[0].mesh,sampling);
    QuerySettings qs;qs.require_front_access=false;FurniturePlacementQuery query(floor,qs,roof);
    ArrangeSettings s;s.amount_mode=AmountMode::Quantity;s.quantity=1;s.edge_clearance_mm=5;s.spacing_mm=0;s.max_stack_depth=1;
    const auto result=arrange({spaces.regions,assets},s,query);
    check(result.placements.empty()&&result.stats.underfilled==1&&result.feedback.reports.size()==1,"Original failed cabinet generation carries native source feedback");
    const auto& r=result.feedback.reports[0];check(r.has_failure&&r.issue==FitIssue::Height&&r.witness.body_id==2,"Report carries real height witness and failed pose");
    check(r.has_suggestion&&r.suggested.scale>.62&&r.suggested.scale<.623&&r.below_minimum,"450mm object has a verified near-62% fit below current 80% floor");
    check(20+450*r.suggested.scale<=300.003&&validate(query,a,r.suggested).reason==Rejection::None,"Suggestion satisfies independent height arithmetic and complete physical validation");
    check(result.feedback.probes<=4096&&result.feedback.work<=5000000,"Feedback stays within independent probe/work caps");
    check(fit_report_message(r).find("height")!=std::string::npos&&fit_report_message(r).find("80.0%")!=std::string::npos,"Useful message includes the obstruction and permitted minimum");
    check(result.warnings.size()==1&&result.warnings[0].find("Select a prop")!=std::string::npos,"No technical success explanation leaks into artist status");
    const auto repeat=arrange({spaces.regions,assets},s,query);check(result.stats.work==repeat.stats.work&&result.stats.candidates==repeat.stats.candidates&&result.stats.rejections==repeat.stats.rejections&&repeat.feedback.reports[0].suggested.scale==r.suggested.scale,"Feedback is deterministic and preserves main solve counters");
    check(a.mesh.vertices.size()==original.size()&&a.mesh.vertices.back().z==original.back().z&&a.bounds.max.z==450,"Feedback never resizes source geometry");
    check(r.apply_percent>0&&static_cast<double>(static_cast<float>(r.apply_percent))==r.apply_percent&&r.suggested.scale==r.apply_percent/100,"Suggested minimum is physically verified after actual float-spinner representation");
    s.fit_to_space=true;s.scale_min=r.apply_percent/100;const auto fitted=arrange({spaces.regions,assets},s,query);check(fitted.placements.size()==1&&fitted.feedback.reports.empty(),"Using a permitted checked reduction allows normal generation and removes irrelevant feedback");
}
void bounds_and_recovery(){
    const std::vector<Asset> assets{prop()};FitFailureRecorder recorder(assets);Placement p{1,17,0,1,{0,0,0},0,1};QueryResult no{Rejection::Obstacle,1,{FitIssue::Occupied}};
    for(unsigned i=0;i<1000;++i){p.region_id=i+1;recorder.note(p,no);}
    ArrangementResult result;result.stats.underfilled=1;ArrangeSettings settings;
    std::size_t calls=0;auto feedback=recorder.finish(result,{},settings,[&](const Placement&,Placement&,std::uint64_t){++calls;return no;},{10,3});
    check(calls==3&&feedback.probes==3&&feedback.work==3&&feedback.limited&&feedback.reports.size()==1&&!feedback.reports[0].has_suggestion,"Global probe cap bounds many representative failures without an invented fit");
    feedback=recorder.finish(result,{},settings,[](const Placement&,Placement&,std::uint64_t)->QueryResult{throw std::runtime_error("query budget");},{7,4});check(feedback.work==7&&feedback.probes==1&&feedback.limited&&!feedback.reports[0].has_suggestion,"Optional query exception exhausts feedback conservatively and cannot imply success");
    feedback=recorder.finish(result,{},settings,[](const Placement&,Placement&,std::uint64_t n){return QueryResult{Rejection::None,n+1};},{7,4});check(feedback.limited&&!feedback.reports[0].has_suggestion,"Over-budget validator result cannot certify a proposal");
    result.stats.underfilled=0;calls=0;feedback=recorder.finish(result,{},settings,[&](const Placement&,Placement&,std::uint64_t){++calls;return no;});check(!calls&&feedback.reports.empty(),"Complete results do no follow-up probes");
    rejects([&]{recorder.finish(result,{},settings,[](const Placement&,Placement&,std::uint64_t){return QueryResult{};},{5000001,4096});},"Feedback cannot bypass its hard work limit");
    std::cout<<"FitReport bytes="<<sizeof(FitReport)<<"; max report values="<<256*sizeof(FitReport)<<"\n";
}
void nonmonotone_and_capacity(){
    const std::vector<Asset> assets{prop()};FitFailureRecorder recorder(assets);Placement p{9,17,0,1,{0,0,0},0,1};recorder.note(p,{Rejection::Obstacle,1});ArrangementResult result;result.stats.underfilled=1;ArrangeSettings s;
    const auto response=[](const Placement&,Placement& p,std::uint64_t){return QueryResult{(p.scale>=.55&&p.scale<=.6)||(p.scale>=.19&&p.scale<=.2)?Rejection::None:Rejection::Obstacle,1};};
    auto answer=recorder.finish(result,{},s,response);const auto& r=answer.reports[0];check(r.has_suggestion&&r.suggested.scale>=.599&&r.suggested.scale<=.6,"Nonmonotone valid intervals cannot turn an unchecked interpolated scale into a suggestion");
    auto trial=r.suggested;check(response(p,trial,5000000).reason==Rejection::None,"Final reported nonmonotone size is one of the valid poses");
    answer=recorder.finish(result,{},s,[](const Placement&,Placement&,std::uint64_t){return QueryResult{};});check(answer.reports[0].preferred_fits&&answer.reports[0].has_suggestion&&answer.reports[0].suggested.scale==1&&answer.reports[0].apply_percent==0,"A preferred-size copy that now passes is reported honestly without requiring shrink");
    std::vector<Asset> many(256);for(std::size_t i=0;i<many.size();++i)many[i].id=i+1;FitFailureRecorder bounded(many);
    for(const auto& a:many){p.asset_id=a.id;bounded.note(p,{Rejection::Boundary,1});}
    answer=bounded.finish(result,{},s,[](const Placement&,Placement&,std::uint64_t){return QueryResult{};},{0,0});check(answer.reports.size()==256&&answer.limited&&!answer.probes,"Zero optional work still bounds and reports all 256 selected sources");
    many.push_back(many.back());rejects([&]{FitFailureRecorder excessive(many);},"Source count cannot exceed 256");many.resize(2);many[1].id=many[0].id;rejects([&]{FitFailureRecorder duplicate(many);},"Duplicate feedback source identities are rejected");
}
void path_feedback_centers(){
    Asset a;a.id=17;a.name="Off-center car";a.mesh=box(0,0,0,400,300,100);a.anchor={0,0,0};a.allowed_yaws_degrees={0};a=prepare_asset(std::move(a));const std::vector<Asset> assets{a};
    CubicBezier line;line.control={Vec3{0,0,0},Vec3{1000,0,0},Vec3{2000,0,0},Vec3{3000,0,0}};const std::array<CubicBezier,1> lines{line};const auto curve=PathCurve::build(lines);
    PathLane lane;lane.quantity=1;lane.width_mm=200;const std::array<PathLane,1> lanes{lane};ArrangeSettings s;s.amount_mode=AmountMode::Quantity;s.quantity=1;s.edge_clearance_mm=5;s.spacing_mm=0;PathSettings settings;
    const auto result=arrange_path({curve,lanes,assets},s,settings);check(result.result.placements.empty()&&result.result.feedback.reports.size()==1,"Narrow lane failure produces source feedback");
    const auto& r=result.result.feedback.reports[0];check(r.issue==FitIssue::Lane&&r.has_suggestion&&r.apply_percent>0,"Lane feedback proposes a fully checked smaller car");
    const auto b=placement_bounds(a,r.suggested);check(std::abs(b.center.x-1500)<1e-6&&std::abs(b.center.y)<1e-6&&std::abs(b.center.z-b.half_extents.z)<1e-6,"Shrinking a source with an off-center anchor preserves the actual path base center");
    check(300*r.suggested.scale<=190.003,"Independent car width arithmetic satisfies both complete lane edges");
    const auto mask=PathLaneMask::build(curve,lane);check(mask.validate(b,5).reason==Rejection::None,"Final suggested whole footprint passes the actual lane ribbon");
    s.fit_to_space=true;s.scale_min=r.apply_percent/100;const auto fitted=arrange_path({curve,lanes,assets},s,settings);check(fitted.result.placements.size()==1&&fitted.result.feedback.reports.empty(),"The representable path suggestion works through the normal production solver");
}
void regional_fill_advice_runs_last(){
    const std::vector<FurnitureBody> floors{{1,box(0,0,0,600,400,20)},{2,box(1000,0,0,1600,400,20)}};
    const std::vector<FurnitureBody> roofs{{3,box(0,0,300,600,400,320)},{4,box(1000,0,300,1600,400,320)}};
    QuerySettings qs;qs.require_front_access=false;FurniturePlacementQuery physical(floors,qs,roofs);
    struct Ordered final:PlacementQuery{const FurniturePlacementQuery& physical;mutable bool advice{},resumed_main{};explicit Ordered(const FurniturePlacementQuery& p):physical(p){}QueryResult validate(const PlacementProbe& p)const override{if(p.remaining_work<=5000000)advice=true;else if(advice)resumed_main=true;return physical.validate(p);}} query(physical);
    Settings sampling;sampling.cell_size_mm=50;auto regions=inspect(floors[0].mesh,sampling).regions;check(regions.size()==1,"Regional-order fixture has one exact first support region");
    auto second=regions[0];second.id=2;second.bounds.min.x+=1000;second.bounds.max.x+=1000;for(auto& cell:second.cells)cell.center.x+=1000;regions.push_back(std::move(second));
    const std::vector<Asset> sources{prop()};ArrangeSettings s;s.amount_mode=AmountMode::Fill;s.density=.2;s.spacing_mm=0;s.edge_clearance_mm=5;s.max_stack_depth=1;
    const auto result=arrange({regions,sources},s,query);check(result.stats.underfilled>0&&result.placements.empty(),"Both regional Fill plans reach a real height failure");
    check(query.advice&&!query.resumed_main,"Optional diagnostics run only after every regional production solve");
    check(result.feedback.reports.size()==1&&result.feedback.reports[0].has_failure&&result.feedback.reports[0].has_suggestion,"Regional failure seeds reach one final source report");
}
}
int main(){try{physical_witnesses();cabinet_report();bounds_and_recovery();nonmonotone_and_capacity();path_feedback_centers();regional_fill_advice_runs_last();std::cout<<"PASS "<<checks<<" native fit feedback checks\n";return 0;}catch(const std::exception& e){std::cerr<<"FAIL "<<checks<<": "<<e.what()<<'\n';return 1;}}
