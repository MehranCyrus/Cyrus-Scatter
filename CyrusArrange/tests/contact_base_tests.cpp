#include "cyrus_arrange/contact_base.h"
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
void append(Mesh& a,const Mesh& b){const auto start=static_cast<std::uint32_t>(a.vertices.size());a.vertices.insert(a.vertices.end(),b.vertices.begin(),b.vertices.end());for(auto t:b.triangles){for(auto& i:t.vertices)i+=start;a.triangles.push_back(t);}}
Mesh cylinder(double radius,double z0,double z1,unsigned sides=128){
    Mesh m;for(double z:{z0,z1})for(unsigned i=0;i<sides;++i){const double a=2*3.14159265358979323846*i/sides;m.vertices.push_back({radius*std::cos(a),radius*std::sin(a),z});}
    m.vertices.push_back({0,0,z0});m.vertices.push_back({0,0,z1});
    for(unsigned i=0;i<sides;++i){const auto j=(i+1)%sides;m.triangles.push_back({{2*sides,j,i}});m.triangles.push_back({{2*sides+1,i+sides,j+sides}});m.triangles.push_back({{i,j,j+sides}});m.triangles.push_back({{i,j+sides,i+sides}});}return m;
}
Asset prepared(Mesh mesh,bool automatic=true){Asset a;a.id=1;a.name="Generic overhang";a.mesh=std::move(mesh);a.allowed_yaws_degrees={0};if(automatic){auto b=infer_contact_base(a.mesh);a.anchor=b.anchor;a.contact_footprint=std::move(b.footprint);}return prepare_asset(std::move(a));}
bool encloses(std::span<const Vec3> polygon,Vec3 p){for(std::size_t i=0;i<polygon.size();++i){const auto a=polygon[i],b=polygon[(i+1)%polygon.size()];if((b.x-a.x)*(p.y-a.y)-(b.y-a.y)*(p.x-a.x)<-1e-6)return false;}return true;}
void all_contact_points(const Mesh& mesh,const ContactBase& base){
    const auto b=mesh_bounds(mesh);const double plane=b.min.z+default_contact_tolerance_mm;
    for(const auto& t:mesh.triangles)for(unsigned i=0;i<3;++i){const auto p=mesh.vertices[t.vertices[i]],q=mesh.vertices[t.vertices[(i+1)%3]];
        if(p.z<=plane)check(encloses(base.footprint,p),"Every actual bottom-band vertex is enclosed");
        if((p.z<plane&&q.z>plane)||(p.z>plane&&q.z<plane)){const double r=(plane-p.z)/(q.z-p.z);check(encloses(base.footprint,{p.x+r*(q.x-p.x),p.y+r*(q.y-p.y),plane}),"Every actual edge/band crossing is enclosed");}
    }
}
void envelopes(){
    auto mesh=box(-20,-20,0,20,20,100);append(mesh,box(-200,-200,100,400,200,120));const auto original=mesh.vertices;
    auto base=infer_contact_base(mesh);check(base.kind==ContactBaseKind::Refined&&base.footprint.size()==4&&base.anchor.x==0&&base.anchor.y==0,"Asymmetric upper geometry does not move the contact anchor");
    check(base.footprint[0].x==-20&&base.footprint[2].x==20&&base.work<=8000000,"Base dimensions derive from actual low geometry within bounded work");all_contact_points(mesh,base);
    auto a=prepared(mesh);check(a.bounds.max.x==400&&a.bounds.min.x==-200&&a.anchor.x==0,"Complete bounds are preserved independently from base anchor");
    check(mesh.vertices.size()==original.size()&&mesh.vertices.back().x==original.back().x,"Contact inference does not mutate the source mesh");
    const auto bytes=encode_assets({a});const auto roundtrip=decode_assets(bytes);check(roundtrip[0].anchor.x==0&&roundtrip[0].contact_footprint[2].x==20&&roundtrip[0].bounds.max.x==400,"Existing library version preserves refined contact metadata");
    auto authored=a;authored.contact_footprint={{-10,-10,0},{10,-10,0},{10,10,0},{-10,10,0}};authored=prepare_asset(std::move(authored));check(authored.contact_footprint[0].x==-10,"Explicit portable footprint is never overwritten");
    const auto scan=mesh.vertices.size()+4*mesh.triangles.size();
    base=infer_contact_base(mesh,{},scan);check(base.kind==ContactBaseKind::FullBounds&&base.limited&&base.work==scan&&base.footprint[0].x==-200,"Exhaustion retains the complete envelope after certifying actual referenced contact");
    mesh.vertices.push_back({0,0,-10});base=infer_contact_base(mesh);check(base.kind==ContactBaseKind::NoReferencedContact,"An unused lower vertex cannot silently define a floating automatic base");
    rejects([&]{infer_contact_base(mesh,{},1);},"Base work admission covers the complete vertex scan");
    rejects([&]{infer_contact_base(mesh,{},mesh.vertices.size());},"A small work budget cannot skip the actual contact preflight");
    auto floating=box(-20,-20,.1,20,20,20);floating.vertices.push_back({0,0,0});
    check(infer_contact_base(floating).kind==ContactBaseKind::NoReferencedContact,"Geometry in the wider base band does not authorize a floating minimum");
    check(infer_contact_base(floating,{},floating.vertices.size()+4*floating.triangles.size()).kind==ContactBaseKind::NoReferencedContact,"Budget fallback cannot bypass the referenced-contact guard");
    mesh.triangles[0].vertices[0]=99999;rejects([&]{infer_contact_base(mesh);},"Invalid face references fail before contact inference");
}
void rounded_and_sloped(){
    auto mesh=cylinder(40,0,100);append(mesh,box(-200,-200,100,200,200,120));const auto base=infer_contact_base(mesh);check(base.kind==ContactBaseKind::Refined&&base.footprint.size()>4&&base.footprint.size()<=64,"Detailed circular base retains a bounded enclosing polygon");all_contact_points(mesh,base);
    double radius=0;for(auto p:base.footprint)radius=std::max(radius,std::hypot(p.x,p.y));check(radius<40.3&&radius>=40,"Envelope encloses the round foot without demanding its bounding-box corners");
    Mesh wedge;wedge.vertices={{-1,0,0},{1,0,0},{100,10,1},{-1,0,2}};wedge.triangles={{{0,2,1}},{{0,1,3}},{{1,2,3}},{{2,0,3}}};const auto edge=infer_contact_base(wedge);all_contact_points(wedge,edge);check(edge.footprint[2].y>0,"Sloping triangle crossings enlarge the contact band beyond minimum vertices");
    AssetLimits fewer;fewer.max_footprint_vertices=4;const auto coarse=infer_contact_base(mesh,fewer);check(coarse.footprint.size()==4&&coarse.footprint[2].x==40,"Lower footprint budget uses a conservative base rectangle");
    auto dense=mesh;dense.triangles.assign(250000,mesh.triangles.front());const auto limited=infer_contact_base(dense);
    check(limited.kind==ContactBaseKind::FullBounds&&limited.limited&&limited.work<=8000000,"Maximum admitted contact-heavy mesh has bounded conservative fallback");
}
void support_and_collision(){
    auto mesh=cylinder(40,0,100);append(mesh,box(-200,-200,100,200,200,120));const auto a=prepared(mesh);const auto legacy=prepared(mesh,false);
    const std::vector<FurnitureBody> floor{{7,cylinder(42,0,20)}};QuerySettings qs;qs.require_front_access=false;FurniturePlacementQuery query(floor,qs);Placement p{1,1,0,1,{0,0,20},0,1};
    const auto validate=[&](const FurniturePlacementQuery& q,const Asset& asset){const auto foot=placement_footprint(asset,p);return q.validate({foot,placement_bounds(asset,p),20,1,{},0,{},1,0,5000000});};
    check(validate(query,legacy).reason==Rejection::Boundary,"Full old envelope rejects a large overhang on narrow round support");
    check(validate(query,a).reason==Rejection::None,"Actual circular contact supports the complete original overhanging prop");
    Settings sampling;sampling.cell_size_mm=automatic_cell_size(mesh_bounds(floor[0].mesh),80,sampling.max_cells);
    const auto inspected=inspect(floor[0].mesh,sampling);const std::vector<Asset> assets{a};
    ArrangeSettings settings;settings.amount_mode=AmountMode::Quantity;settings.quantity=1;settings.edge_clearance_mm=1;settings.spacing_mm=0;
    const auto placed=arrange({inspected.regions,assets},settings,query);
    check(placed.placements.size()==1&&placed.placements[0].scale==1,"Production search finds original-size circular contact on narrow support using automatic sampling");
    const auto hint=query.support_center({5,3,20},200000);check(hint.center&&std::hypot(hint.center->x,hint.center->y)<1e-6&&hint.work_units>0,"Copied support hint uses the actual immutable outline center");
    rejects([&]{query.support_center({5,3,20},1);},"Global work exhaustion during an optional proposal fails the successor rather than publishing a partial scan");
    check(!query.support_center({0,0,25},200000).center,"A different height cannot acquire a support-center proposal");
    const std::vector<FurnitureBody> roof{{8,box(-250,-250,130,250,250,150)}};FurniturePlacementQuery blocked(floor,qs,roof);check(validate(blocked,a).reason==Rejection::Obstacle,"Refined support never bypasses full-body roof collision");
    check(arrange({inspected.regions,assets},settings,blocked).placements.empty(),"Production center fallback still rejects an actual full-body roof collision");
    const std::vector<FurnitureBody> ring{{10,box(-200,-200,0,-60,200,20)},{11,box(60,-200,0,200,200,20)},{12,box(-60,-200,0,60,-60,20)},{13,box(-60,60,0,60,200,20)}};
    FurniturePlacementQuery hole(ring,qs);check(hole.support_center({0,0,20},200000).center.has_value()&&validate(hole,a).reason==Rejection::Boundary,"A center proposed over a hole never bypasses exact support validation");
    check(40<42-1&&120+20>130,"Independent analytic dimensions prove support and actual roof penetration cases");
}
void path_and_fill(){
    auto mesh=box(-20,-20,0,20,20,100);append(mesh,box(-200,-200,100,400,200,120));const auto a=prepared(mesh);const std::vector<Asset> sources{a};
    CubicBezier segment;segment.control={Vec3{0,0,0},Vec3{2000,0,0},Vec3{4000,0,0},Vec3{6000,0,0}};const std::array<CubicBezier,1> segments{segment};const auto curve=PathCurve::build(segments);PathLane lane;lane.quantity=1;lane.width_mm=1000;const std::array<PathLane,1> lanes{lane};ArrangeSettings settings;settings.amount_mode=AmountMode::Quantity;settings.quantity=1;settings.edge_clearance_mm=1;PathSettings path;
    const auto result=arrange_path({curve,lanes,sources},settings,path);check(result.result.placements.size()==1,"Overhanging source fits the wide authored path lane");const auto& p=result.result.placements[0];const auto center=placed_base_center(a,p.position,p.yaw_degrees,p.scale);check(std::abs(center.x-3000)<1e-6&&std::abs(center.y)<1e-6,"The actual base center follows the curve");check(placement_bounds(a,p).center.x>3090,"Upper-body center is allowed to differ from base center");
    struct Reject final:PlacementQuery{QueryResult validate(const PlacementProbe&)const override{return {Rejection::Obstacle,1};}} no;
    const auto support=box(-1000,-1000,-20,1000,1000,0);Settings sample;sample.cell_size_mm=100;const auto regions=inspect(support,sample).regions;settings.amount_mode=AmountMode::Fill;settings.density=.1;settings.spacing_mm=0;
    const auto plain=prepared(mesh,false);const std::vector<Asset> old{plain};const auto narrow=arrange({regions,sources},settings,no),wide=arrange({regions,old},settings,no);check(narrow.stats.requested==wide.stats.requested,"Fill demand uses complete occupied body area despite a small base");
}
}
int main(){try{envelopes();rounded_and_sloped();support_and_collision();path_and_fill();std::cout<<"PASS "<<checks<<" automatic contact-base checks\n";return 0;}catch(const std::exception& e){std::cerr<<"FAIL "<<checks<<": "<<e.what()<<'\n';return 1;}}
