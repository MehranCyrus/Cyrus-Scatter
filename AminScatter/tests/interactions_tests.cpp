#include "interactions_source.h"
#include "interactions_engine.h"
#include "sparse_instances.h"
#include "connectivity.hpp"
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
    require(mesh->triangleDistance({2,-.1,-.1},{2,.1,-.1},{2,0,.1},.001)==.001,"Separated triangles stop at the requested contact band");
    require(mesh->triangleDistance({-3,0,-3},{3,0,-3},{0,0,4},.001)==0,"Bounded distance retains an interior-only surface crossing");
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
    for(bool hide:{false,true}){
        auto under=fitSource(*source,{overhead},.001,.5,hide,4);require(!under.hiddenRoots[0]&&!under.hiddenRoots[1]&&under.activeGuides>0,"An overhead collider bends the rooted group with hiding on or off");
        auto audit=auditSource(*source,under,{overhead});require(audit.at("penetrating_vertex_obstacle_pairs")==0&&audit.at("touching_triangle_obstacle_pairs")==0,"Overhead contact clears complete visible triangles");
    }
    rejects([&]{fitSource(*source,{cover},.001,.5,false,4);});
    Shape margin{5,cube(.008),{}};margin.transform.rows[3]={-.018,0,0};
    auto noMargin=fitSource(*source,{margin},0,.5,true,4),withMargin=fitSource(*source,{margin},.004,.5,true,4);
    require(!noMargin.hiddenRoots[0]&&withMargin.hiddenRoots[0]&&!withMargin.hiddenRoots[1],"Contact gap expands only the requested actual root exclusion");
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
    auto coverageLayout=std::make_shared<Layout>(*layout);coverageLayout->layers[1].coverRoots=false;
    Engine coverageEngine(coverageLayout);auto clearRoots=coverageEngine.evaluate({});
    auto insideRoot=coverageLayout->transform(0);insideRoot.rows[3]={-.03,0,0};
    rejects([&]{coverageEngine.evaluate(clearRoots,{{0,insideRoot}},{0});});
    require(clearRoots->poses.size()==1&&clearRoots->statistics.hiddenRoots==0,"An impossible fixed-root successor retains the previous complete contact pose");
}
void completeOverheadClump(){
    const auto base=bladeSource();prep::Snapshot raw;
    for(unsigned copy=0;copy<40;++copy){unsigned offset=unsigned(raw.positions.size());for(auto p:base.positions){p[0]+=float(copy%8)*.001f;p[1]+=float(copy/8)*.001f;raw.positions.push_back(p);}for(auto tri:base.faces){for(auto& vertex:tri)vertex+=offset;raw.faces.push_back(tri);}}
    raw.materials.assign(raw.faces.size(),0);auto source=prepareSource(raw);require(source->roots==80,"Complete clump has eighty rooted blades");
    Shape overhead{3,cube(.08),{}};overhead.transform.rows[3]={0,.085,0};
    for(bool hide:{false,true}){
        auto pose=fitSource(*source,{overhead},0,.5,hide,7);
        require(pose.activeGuides==source->roots&&pose.coveredRoots==0,"Every contacting blade under a hovering collider participates in fitting");
        for(unsigned face=0;face<raw.faces.size();++face)require(visibleFace(*source,pose,face),"No contacted blade disappears");
        auto audit=auditSource(*source,pose,{overhead});require(audit.at("penetrating_vertex_obstacle_pairs")==0&&audit.at("touching_triangle_obstacle_pairs")==0&&audit.at("root_anchor_error_m").get<double>()<1e-12,"All eighty bent blades clear the collider with planted roots");
    }
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
void hybridPreparation(){
    prep::Snapshot leaf;constexpr unsigned width=7,rings=100;
    for(unsigned r=0;r<rings;++r)for(unsigned side=0;side<width;++side)leaf.positions.push_back({float((int(side)-3)*.004),float(.03*std::sin(r*.01)),float(r*.005)});
    for(unsigned r=1;r<rings;++r)for(unsigned c=0;c+1<width;++c){unsigned a=(r-1)*width+c,b=r*width+c;leaf.faces.push_back({a,a+1,b});leaf.faces.push_back({a+1,b+1,b});}
    leaf.materials.assign(leaf.faces.size(),0);auto prepared=prepareSource(leaf);
    require(prepared->rig->guides.size()==1&&prepared->report.at("folded_leaf_guides")==1,"Dense folded basal leaf is a bending guide, not giant rigid foliage");
    auto saved=saveSource(*prepared);require(prepareSource(leaf,{},&saved)->rig->guides.size()==1,"Dense leaf definition reload");
    auto airborne=leaf;for(auto& p:airborne.positions)p[2]+=.5f;airborne.positions.push_back({0,0,0});
    // Explicit disconnected geometry cannot manufacture a basal attachment.
    rejects([&]{prepareSource(airborne);});
    std::vector<prep::Tube> tubes{{{{0,0,0},{0,0,.5},{0,0,1}},{.004,.004,.003}},{{{0,0,.5},{.05,0,.55},{.1,0,.6}},{.001,.0015,.002}}};
    std::atomic_bool cancel=false;auto forest=prep::connect(tubes,cancel);
    require(forest.roots==1&&forest.unresolved==0&&forest.links[1].parent==0,"Flared pedicel attaches at its narrower geometric base");
    rejects([&]{prepareSource(leaf,{.0005,.05});});rejects([&]{prepareSource(leaf,{.005,1.01});});
}
void topologyPreparation(){
    require(prep::textHash("abc")=="ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad","Saved definition cache identity uses SHA-256");
    prep::Snapshot ribbon;
    for(unsigned row=0;row<20;++row)for(unsigned side=0;side<2;++side)ribbon.positions.push_back({float(side*.004),float(.02*std::sin(row*.08)),float(row*.01)});
    for(unsigned row=1;row<20;++row){unsigned a=(row-1)*2,b=row*2;ribbon.faces.push_back({a,a+1,b});ribbon.faces.push_back({a+1,b+1,b});}
    ribbon.materials.assign(ribbon.faces.size(),0);
    auto first=prepareSource(ribbon);require(first->roots==1&&first->rig->guides.size()==1,"Ordinary two-rail ribbon preparation");
    auto permuted=ribbon;const unsigned count=unsigned(ribbon.positions.size());for(unsigned i=0;i<count;++i)permuted.positions[count-1-i]=ribbon.positions[i];for(auto& f:permuted.faces)for(auto& v:f)v=count-1-v;
    auto second=prepareSource(permuted);require(second->rig->guides.size()==1,"Arbitrary vertex numbering does not disable a ribbon");
    for(unsigned i=0;i<first->rig->guides[0].rest.nodes.size();++i)require(length(sub(first->rig->guides[0].rest.nodes[i],second->rig->guides[0].rest.nodes[i]))<1e-7,"Topology guide chart is independent of vertex numbering");
    for(unsigned i=0;i<ribbon.positions.size();++i){Pose rest;rest.guides.resize(1);rest.hiddenRoots.resize(1);require(length(sub(posePoint(*first,rest,i),first->rig->positions[i]))<1e-10,"New profile preserves every original rest vertex");}
    require(prepareSource(ribbon,{.005,double(float(.01))})->roots==1,"Float32 one-percent endpoint is valid");
    rejects([&]{prepareSource(ribbon,{.005,.009});});
    prep::Settings bounded;bounded.limits.vertices=3;rejects([&]{prepareSource(ribbon,bounded);});bounded={};bounded.limits.parts=1;
    auto multiple=bladeSource();rejects([&]{prepareSource(multiple,bounded);});
    prep::Snapshot many;for(unsigned i=0;i<2100;++i){unsigned base=unsigned(many.positions.size());for(unsigned row=0;row<3;++row)for(unsigned side=0;side<3;++side)many.positions.push_back({float(i*.01+side*.001),0,float(row*.02)});for(unsigned row=1;row<3;++row)for(unsigned side=0;side<2;++side){unsigned a=base+(row-1)*3+side,b=base+row*3+side;many.faces.push_back({a,a+1,b});many.faces.push_back({a+1,b+1,b});}}
    many.materials.assign(many.faces.size(),0);auto manySource=prepareSource(many);require(manySource->rig->guides.size()==2100,"New default admits more than the historical 2048 rooted guides");bounded={};bounded.limits.guides=2048;rejects([&]{prepareSource(many,bounded);});
    auto definition=saveSource(*manySource);prep::Settings denser;denser.foliageFraction=.25;auto changed=prepareSource(many,denser,&definition);require(changed->rig->guides.size()==2100&&changed->report.at("guide_inference_reused")==true&&changed->previewFaces.size()>manySource->previewFaces.size(),"Display density changes reuse accepted guides without new inference");
    denser.foliageFraction=1;auto complete=prepareSource(many,denser,&definition);require(complete->previewTriangles.size()==many.faces.size()&&complete->report.at("guide_inference_reused")==true,"100 percent retains every admitted ribbon component using saved guides");
}
void conservativeEnvelope(){
    // Isotropic bounds for long attached leaves can exceed the clearance that
    // a fixed short basal span could ever attain. Actual geometry is authoritative.
    auto source=std::make_shared<Source>(*prepareSource(bladeSource()));auto rig=std::make_shared<stem::Prepared>(*source->rig);source->rig=rig;
    for(auto& guide:rig->guides)guide.rest.span_radius_m[1]=.2;
    Shape obstacle{1,cube(.01),{}};obstacle.coverRoots=false;obstacle.transform.rows[3]={0,.045,0};
    auto clear=fitSource(*source,{obstacle},.00001,.5,true,1);
    require(clear.meshRefinements>0&&clear.meshRefinementWork<=2000000,"Conservative-envelope failure receives bounded mesh refinement");
    for(unsigned i=0;i<rig->positions.size();++i)require(length(sub(posePoint(*source,clear,i),rig->positions[i]))<1e-12,"False envelope contact leaves clear visible geometry unchanged");
    obstacle.transform.rows[3]={-.018,.055,0};auto bent=fitSource(*source,{obstacle},.00001,.5,true,2);auto audit=auditSource(*source,bent,{obstacle});
    require(bent.meshRefinements>0&&audit.at("penetrating_vertex_obstacle_pairs")==0&&audit.at("touching_triangle_obstacle_pairs")==0,"Exact refinement clears actual contact despite an infeasible broad envelope");
    require(audit.at("root_anchor_error_m").get<double>()<1e-12,"Exact refinement keeps original root vertices fixed");
}
void elevatedRosette(){
    prep::Snapshot raw;
    // Broad leaves share an elevated crown; half have tips below their roots.
    for(unsigned leaf=0;leaf<8;++leaf){const double angle=leaf*6.283185307179586/8;unsigned offset=unsigned(raw.positions.size());
        for(unsigned row=0;row<18;++row)for(unsigned side=0;side<2;++side){double t=row/17.,radius=.02+.48*t,w=(side?1:-1)*(.004+.016*std::sin(t*3.141592653589793));raw.positions.push_back({float(radius*std::cos(angle)-w*std::sin(angle)),float(radius*std::sin(angle)+w*std::cos(angle)),float(.15+.22*std::sin(t*3.141592653589793)-(leaf%2?.11:0)*t)});}
        for(unsigned row=1;row<18;++row){unsigned a=offset+(row-1)*2,b=a+2;raw.faces.push_back({a,a+1,b});raw.faces.push_back({a+1,b+1,b});}}
    unsigned offset=unsigned(raw.positions.size());for(unsigned k=0;k<8;++k)raw.positions.push_back({float(k&1?.035:-.035),float(k&2?.035:-.035),float(k&4?.09:0)});
    for(auto f:std::vector<Tri>{{0,2,1},{1,2,3},{4,5,6},{5,7,6},{0,1,4},{1,5,4},{2,6,3},{3,6,7},{0,4,2},{2,4,6},{1,3,5},{3,7,5}}){for(auto& v:f)v+=offset;raw.faces.push_back(f);}
    raw.materials.assign(raw.faces.size(),0);auto source=prepareSource(raw,{.005,1.});
    require(source->report.at("crown_root_guides")==8&&source->rig->guides.size()==8,"Every broad leaf gets its own elevated crown guide");
    require(source->fixedVertices.size()==8&&source->fixedFaces.size()==12,"Compact closed decoration is explicitly fixed");
    for(const auto& g:source->rig->guides)require(std::abs(g.rest.nodes.front().y-.15)<.002&&length(Vec{g.rest.nodes.front().x,0,g.rest.nodes.front().z})<.04,"Drooping tips never replace crown roots");
    Shape obstacle{1,cube(.035),{}};obstacle.transform.rows[3]={.27,.31,0};auto pose=fitSource(*source,{obstacle},.00001,.5,false,1);
    require(pose.activeGuides>0&&pose.coveredRoots==0,"Broad elevated leaves actually react");
    for(unsigned i=offset;i<raw.positions.size();++i){require(length(sub(posePoint(*source,pose,i),source->rig->positions[i]))<1e-12,"Decorative base stays fixed while leaves bend");require(length(sub(poseDirection(*source,pose,i,{1,0,0}),Vec{1,0,0}))<1e-12,"Fixed decoration preserves authored normals");}
    auto audit=auditSource(*source,pose,{obstacle});require(audit.at("penetrating_vertex_obstacle_pairs")==0&&audit.at("touching_triangle_obstacle_pairs")==0,"Full broad-leaf mesh clears the collider");
    auto saved=saveSource(*source);auto restored=prepareSource(raw,{.005,1.},&saved);require(restored->fixedFaces==source->fixedFaces,"Fixed decoration survives source definition reload");
    obstacle.transform.rows[3]={0,.04,0};rejects([&]{fitSource(*source,{obstacle},0,.5,false,2);});
}
void broadFaceBridge(){
    auto raw=bladeSource();
    for(unsigned side=0;side<3;++side){raw.positions[6+side][0]+=.06f;raw.positions[6+side][2]=.03f;}
    raw.positions[9]={.045f,0,.03f};auto source=std::make_shared<Source>(*prepareSource(raw));auto rig=std::make_shared<stem::Prepared>(*source->rig);source->rig=rig;
    // An authored triangle bridges two charts of an L-shaped guide. All three
    // vertices and the guide capsules are clear, while the face cuts the box.
    source->guideFaces[0].push_back(unsigned(rig->triangles.size()));rig->triangles.push_back({0,3,6});
    Shape obstacle{1,cube(.001),{}};obstacle.transform.rows[3]={-.01,.02,0};
    Pose rest;rest.guides.resize(2);rest.hiddenRoots.resize(2);const auto before=auditSource(*source,rest,{obstacle});
    require(before.at("penetrating_vertex_obstacle_pairs")==0&&before.at("touching_triangle_obstacle_pairs").get<unsigned>()>0,"Regression has a surface-only intersection");
    MeshWorld world(1,{obstacle});for(unsigned k=0;k+1<rig->guides[0].rest.nodes.size();++k){const auto& g=rig->guides[0].rest;auto result=world.query_capsule({g.guide_id,g.span_ids[k],g.nodes[k],g.nodes[k+1],g.span_radius_m[k],.00001},{});require(result.contacts.empty(),"Regression guide capsules are independently clear");}
    auto pose=fitSource(*source,{obstacle},0,.5,false,2);auto after=auditSource(*source,pose,{obstacle});
    require(pose.activeGuides==1&&pose.meshRefinements>0,"A surface-only hit receives actual mesh refinement");
    require(after.at("penetrating_vertex_obstacle_pairs")==0&&after.at("touching_triangle_obstacle_pairs")==0&&after.at("root_anchor_error_m").get<double>()<1e-12,"Triangle interior clears without moving planted roots");
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
int main(int argc,char** argv){try{if(argc>=3&&std::string(argv[1])=="--fixture")return fixtureBenchmark(argv[2],argc>3?unsigned(std::stoul(argv[3])):8);geometry();sources();engine();completeOverheadClump();plantedTube();hybridPreparation();topologyPreparation();conservativeEnvelope();elevatedRosette();broadFaceBridge();for(int i=1;i<argc;++i)actual(argv[i]);std::cout<<"PASS mesh witnesses, frames, adjustable limits, topology preparation, shared definitions and partial root restoration\n";return 0;}catch(const std::exception& e){std::cerr<<e.what()<<'\n';return 1;}}
