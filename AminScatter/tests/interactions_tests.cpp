#include "interactions_source.h"
#include "interactions_engine.h"
#include "sparse_instances.h"
#include <algorithm>
#include <cmath>
#include <fstream>
#include <iostream>
#include <stdexcept>
using namespace cyrus::interactions;
void require(bool p,const char* message){if(!p)throw std::runtime_error(message);}
template<class F>void rejects(F f){bool rejected=false;try{f();}catch(const std::exception&){rejected=true;}require(rejected,"Invalid input was not rejected");}
std::shared_ptr<const MeshGeometry> cube(double half=1){
    std::vector<Vec> p{{-half,-half,-half},{half,-half,-half},{half,half,-half},{-half,half,-half},{-half,-half,half},{half,-half,half},{half,half,half},{-half,half,half}};
    std::vector<Tri> t{{0,2,1},{0,3,2},{4,5,6},{4,6,7},{0,1,5},{0,5,4},{1,2,6},{1,6,5},{2,3,7},{2,7,6},{3,0,4},{3,4,7}};
    return std::make_shared<MeshGeometry>(std::move(p),std::move(t));
}
prep::Snapshot bladeSource(){
    prep::Snapshot s;
    for(float x:{-.03f,.03f}){unsigned start=unsigned(s.positions.size());
        for(unsigned ring=0;ring<3;++ring){float z=ring*.03f;for(auto p:std::vector<std::array<float,3>>{{x,0,z},{x-.001f,.0002f,z},{x+.001f,.0002f,z}})s.positions.push_back(p);}
        s.positions.push_back({x+.005f,0,.075f});
        for(unsigned ring=0;ring<2;++ring){unsigned a=start+3*ring,b=a+3;s.faces.push_back({a,a+1,b});s.faces.push_back({a+1,b+1,b});s.faces.push_back({a+2,a,b});s.faces.push_back({a+2,b,b+2});}
        s.faces.push_back({start+6,start+7,start+9});s.faces.push_back({start+8,start+6,start+9});}
    s.materials.assign(s.faces.size(),0);return s;
}
void geometry(){
    auto mesh=cube();require(mesh->solid(),"Closed cube admission");
    require(std::abs(mesh->point({0,0,0}).gap+1)<1e-9,"Solid interior signed distance");
    require(std::abs(mesh->point({2,0,0}).gap-1)<1e-9,"Exterior distance");
    require(mesh->projectedNear({0,-3,0},{0,1,0},0),"Root below collider projection");
    require(!mesh->projectedNear({1.1,-3,1.1},{0,1,0},.1),"Projection corner distance rejects rectangular expansion false positive");
    require(mesh->projectedNear({1.05,-3,0},{0,1,0},.1),"Root envelope at projection edge");
    require(mesh->overlapsSolid({{-.1,-.1,-.1},{.1,.1,.1}}),"A box contained in the solid cannot be discarded");
    require(mesh->overlapsSolid({{.95,-.1,-.1},{1.05,.1,.1}}),"A triangle crossing the query box is retained");
    require(!mesh->overlapsSolid({{1.01,-.1,-.1},{1.02,.1,.1}}),"A separated rest box is certified exterior");
    cyrus::SparseInstances<int> edits;edits.hidden={8,0,1,4,4};edits.transforms={{2,77}};edits.seal(10);
    require(edits.sourceIndex(0)==2&&edits.sourceIndex(1)==3&&edits.sourceIndex(2)==5&&edits.sourceIndex(5)==9,"Sparse stream rank/select skips consecutive roots and holes");
    rejects([]{cyrus::SparseInstances<int> invalid;invalid.hidden={10};invalid.seal(10);});
    require(mesh->triangleDistance({-3,0,-3},{3,0,-3},{0,0,4})<1e-10,"Triangle interior crossing without an interior query vertex");
    require(std::abs(mesh->triangleDistance({2,-.1,-.1},{2,.1,-.1},{2,0,.1})-1)<1e-9,"Independent triangle separation");
    require(mesh->segment({-2,0,0},{2,0,0}).gap<-.99,"Crossing deepest witness");
    Shape shape{7,mesh,{}};shape.transform.rows={Vec{0,2,0},Vec{-2,0,0},Vec{0,0,2},Vec{3,4,5}};
    MeshWorld world(1,{shape},100,2);auto q=world.classify_point({3,4,5},0,{});require(q.complete&&q.hits[0].location==v::Location::Inside,"Rotated scaled solid point");
    v::CapsuleQuery capsule{3,9,{0,4,5},{6,4,5},.01,.002};auto contacts=world.query_capsule(capsule,{});require(contacts.complete&&contacts.contacts.size()==1,"Whole capsule crossing");
    auto c=contacts.contacts[0];auto axis=add(capsule.a,mul(sub(capsule.b,capsule.a),c.material_u));require(length(sub(axis,c.axis_point))<1e-9,"Material witness reconstruction");
    require(std::abs(dot(c.outward_normal,sub(c.axis_point,c.obstacle_point))-.012-c.signed_gap_m)<1e-8,"Single clearance application");
    auto rounded=shape;rounded.transform.rows[0].x=1.3e-8;rounded.transform.rows[1].x-=2.7e-8;MeshWorld floatWorld(2,{rounded});auto fp=floatWorld.query_capsule(capsule,{});require(fp.complete&&!fp.contacts.empty(),"Float-rounded similarity remains admitted");
    for(const auto& hit:fp.contacts){auto a=add(capsule.a,mul(sub(capsule.b,capsule.a),hit.material_u));require(length(sub(a,hit.axis_point))<1e-12&&std::abs(dot(hit.outward_normal,sub(a,hit.obstacle_point))-.012-hit.signed_gap_m)<1e-12,"Rounded host matrix preserves exact material and signed-gap witnesses");}
    auto invalid=shape;invalid.transform.rows[0]=mul(invalid.transform.rows[0],-1);rejects([&]{MeshWorld w(1,{invalid});});
    invalid=shape;invalid.transform.rows[0]=mul(invalid.transform.rows[0],2);rejects([&]{MeshWorld w(1,{invalid});});
    rejects([]{MeshGeometry open({{0,0,0},{1,0,0},{0,1,0}},{{0,1,2}});});
    std::atomic_bool flag=true;require(world.query_capsule(capsule,{&flag}).outcome==v::Outcome::Cancelled,"Cancellation");
    MeshWorld bounded(1,{shape},1,1);bounded.classify_point({0,0,0},0,{});require(!bounded.query_capsule(capsule,{}).complete,"Explicit query exhaustion");
}
void sources(){
    auto raw=bladeSource();auto source=prepareSource(raw);require(source->rig->guides.size()==2,"Folded blade recognition");
    auto saved=saveSource(*source);auto reloaded=prepareSource(raw,{},&saved);require(reloaded->fingerprint==source->fingerprint,"Prepared metadata round trip");
    auto stale=raw;stale.positions[0][0]+=.001f;rejects([&]{prepareSource(stale,{},&saved);});
    Pose rest;rest.guides.resize(2);rest.hiddenRoots.resize(2);
    for(unsigned i=0;i<raw.positions.size();++i)require(length(sub(posePoint(*source,rest,i),source->rig->positions[i]))<1e-10,"Exact rest reconstruction");
    Shape cover{1,cube(.01),{}};cover.transform.rows[3]={-.03,0,0};
    auto pose=fitSource(*source,{cover},.001,.5,true,2);require(!pose.allHidden&&pose.hiddenRoots[0]&&!pose.hiddenRoots[1],"Partial rooted group cover");
    require(!visibleFace(*source,pose,0)&&visibleFace(*source,pose,10),"Partial clump face mask");
    auto recovered=fitSource(*source,{},.001,.5,true,3);require(!recovered.changed&&!recovered.hiddenRoots[0],"Move-away rest restoration");
    auto invalid=raw;invalid.faces[0][0]=999999;rejects([&]{prepareSource(invalid);});
    Shape overhead{3,cube(.005),{}};overhead.transform.rows[3]={-.03,.02,0};
    auto under=fitSource(*source,{overhead},.001,.5,true,4);require(under.hiddenRoots[0]&&!under.hiddenRoots[1],"A rooted group below an overhang is covered before fitting");
    auto retained=fitSource(*source,{cover},.001,.5,false,4);require(!retained.changed&&!retained.hiddenRoots[0]&&retained.retainedCoveredRoots==1,"Coverage-off retains covered rooted groups at rest without an impossible root fit");
    Shape contact{2,cube(.01),{}};contact.transform.rows[3]={-.018,.055,0};
    auto bent=fitSource(*source,{contact},.001,.5,true,4);require(bent.changed&&bent.activeGuides>0,"Actual mesh contact bends a rooted guide");
    for(unsigned i:source->rig->guides[0].anchors)require(length(sub(posePoint(*source,bent,i),source->rig->positions[i]))<1e-7,"Bending preserves original root cross section");
    const auto audit=auditSource(*source,bent,{contact});std::cout<<"Complete blade audit "<<audit.dump()<<'\n';
    require(audit.at("penetrating_vertex_obstacle_pairs")==0&&audit.at("touching_triangle_obstacle_pairs")==0,"Independent full visible mesh clears the test obstacle");
    require(audit.at("maximum_rigid_part_edge_change").get<double>()<1e-6,"Rigid foliage shape preservation");
}
void engine(){
    auto source=prepareSource(bladeSource());auto plant=std::make_shared<Definition>();plant->rig=source;plant->geometryBounds=source->bounds;
    auto stone=std::make_shared<Definition>();stone->collider=cube(.01);stone->geometryBounds=stone->collider->bounds();
    auto layout=std::make_shared<Layout>();layout->layers={LayerSettings{true,false,true,.001,.5},LayerSettings{false,true,true,.001,.5}};layout->sources={{stone},{plant}};
    Instance obstacle;obstacle.layer=0;obstacle.identity="c:1";obstacle.hostTransform={1,0,0,0,1,0,0,0,1,-1.8f,0,5.5f};layout->instances.push_back(obstacle);
    for(unsigned i=0;i<5000;++i){Instance p;p.layer=1;p.row=i;p.identity="c:"+std::to_string(i+1);p.hostTransform={1,0,0,0,1,0,0,0,1,float(i%100)*40,float(i/100)*40,0};layout->instances.push_back(p);}
    Engine engine(layout);auto first=engine.evaluate({});require(first->statistics.affected==1&&first->poses.size()==1,"Locality over 5000 instances");
    require(engine.evaluate(first)==first,"Unchanged evaluation reuses complete publication");
    auto moved=layout->transform(0);moved.rows[3].x=1.;auto second=engine.evaluate(first,{{0,moved}},{0});require(second->poses.empty()&&second->statistics.restored==1,"Old/new neighborhood restores leaving plants");
    auto invalid=moved;invalid.rows[0]=mul(invalid.rows[0],2);rejects([&]{engine.evaluate(first,{{0,invalid}},{0});});require(first->poses.size()==1,"Failure retains previous immutable publication");
    auto deleted=engine.evaluate(first,{}, {0},{0});require(deleted->poses.empty(),"Deleting a collider restores nearby plants");
    auto restored=engine.evaluate(deleted,{}, {0},{});require(restored->poses.contains(1),"Restoring a deleted collider restores local contact");
    require(engine.evaluate(restored)==restored,"Restored generation no-op reuse");
    auto edited=layout->transform(1);edited.rows[3].x=50;auto third=engine.evaluate(second,{{0,moved},{1,edited}},{1});
    moved.rows[3].x=49.982;auto fourth=engine.evaluate(third,{{0,moved},{1,edited}},{0});require(fourth->poses.contains(1),"Moving collider finds previously edited plant outside the base index");
    std::cout<<"5000-instance kernel "<<statisticsJson(fourth->statistics).dump()<<'\n';
}
void plantedTube(){
    prep::Snapshot raw;
    for(unsigned ring=0;ring<5;++ring)for(unsigned side=0;side<6;++side){const double a=side*6.283185307179586/6;raw.positions.push_back({float(.005*ring+.002*std::cos(a)),float(.002*std::sin(a)),float(.025*ring)});}
    for(unsigned ring=0;ring<4;++ring)for(unsigned side=0;side<6;++side){unsigned a=ring*6+side,b=ring*6+(side+1)%6;raw.faces.push_back({a,b,a+6});raw.faces.push_back({b,b+6,a+6});}
    raw.materials.assign(raw.faces.size(),0);auto source=prepareSource(raw);
    require(source->roots==1&&source->rig->guides.size()==1,"Planted tube recognition");
    for(auto centre:std::vector<Vec>{{.012,.07,0},{.004,.017,0}}){
        Shape obstacle{1,cube(.004),{}};obstacle.coverRoots=false;obstacle.transform.rows[3]=centre;
        auto pose=fitSource(*source,{obstacle},.0001,.5,true,1);
        require(pose.activeGuides==1,"The rooted tube must actually react above and within its basal span");
        const auto& fitted=*pose.guides[0];
        for(unsigned i=0;i<fitted.nodes.size();++i){
            const auto direction=[&](unsigned a,unsigned b){auto d=sub(fitted.nodes[b],fitted.nodes[a]);return mul(d,1/length(d));};
            Vec tangent=i==0?direction(0,1):(i+1==fitted.nodes.size()?direction(i-1,i):unit(add(direction(i-1,i),direction(i,i+1))));
            const auto q=fitted.material_frames[i];Vec materialZ{2*(q.x*q.z+q.w*q.y),2*(q.y*q.z-q.w*q.x),1-2*(q.x*q.x+q.y*q.y)};
            require(length(sub(tangent,materialZ))<1e-8,"Tube material +Z follows the actual average guide tangent");
        }
        const auto audit=auditSource(*source,pose,{obstacle});
        require(audit.at("penetrating_vertex_obstacle_pairs")==0&&audit.at("touching_triangle_obstacle_pairs")==0,"Planted tube clears both collider positions");
        require(audit.at("root_anchor_error_m").get<double>()<1e-12,"Tube basal ring stays planted");
        require(audit.at("maximum_stem_edge_change").get<double>()<.25,"Planted tube avoids excessive basal skin stretch");
    }
}
void actual(const char* input){
    std::ifstream in(input,std::ios::binary);unsigned header[4]{};in.read(reinterpret_cast<char*>(header),sizeof(header));require(header[0]==0x53544c32u,"Asset snapshot header");
    prep::Snapshot s;s.positions.resize(header[1]);s.faces.resize(header[2]);s.materials.resize(header[2]);
    in.read(reinterpret_cast<char*>(s.positions.data()),s.positions.size()*12);in.read(reinterpret_cast<char*>(s.faces.data()),s.faces.size()*12);in.read(reinterpret_cast<char*>(s.materials.data()),s.materials.size()*4);require(bool(in),"Asset snapshot payload");
    auto source=prepareSource(s);std::cout<<input<<" "<<source->report.dump()<<'\n';
    for(unsigned pi=0;pi<source->previewTriangles.size();++pi)for(unsigned k=0;k<3;++k){auto address=source->previewUVCorners[pi][k];require(s.faces.at(address/3)[address%3]==source->previewTriangles[pi][k],"Light preview UV corner retains original authored vertex identity");require(s.materials.at(address/3)==source->rig->previewMaterials[pi],"Light preview preserves source material sector");}
    auto saved=saveSource(*source);auto restored=prepareSource(s,{},&saved);require(restored->rig->guides.size()==source->rig->guides.size(),"Actual source saved definition");
}
#include "interactions_fixture.inc"
int main(int argc,char** argv){try{if(argc>=3&&std::string(argv[1])=="--fixture")return fixtureBenchmark(argv[2],argc>3?unsigned(std::stoul(argv[3])):8);geometry();sources();engine();plantedTube();for(int i=1;i<argc;++i)actual(argv[i]);std::cout<<"PASS mesh witnesses, frames, limits, blade preparation, shared definitions and partial root restoration\n";return 0;}catch(const std::exception& e){std::cerr<<e.what()<<'\n';return 1;}}
