#include "interactions_source.h"
#include "interaction_candidate_memo.h"
#include "interactions_deformation.h"
#include "interactions_engine.h"
#include "execution.h"
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
void candidateMemo(){
    detail::GuideCandidateMemo memo;v::RestGuide candidate;candidate.guide_id=7;
    candidate.nodes={{0,0,0},{0,1,0},{0,2,0}};candidate.material_frames.resize(3);
    require(!memo.matches(candidate,false),"An empty candidate memo cannot certify clearance");
    memo.remember(candidate,false,true,37);require(memo.matches(candidate,false)&&memo.clear&&memo.work==37,"An identical candidate reuses its exact result, skin buffer and logical admission cost");
    require(!memo.matches(candidate,true),"A different planted-root skin chart must be checked again");
    auto changed=candidate;changed.nodes[1].x=std::nextafter(0.,1.);require(!memo.matches(changed,false),"One changed coordinate invalidates the exact candidate memo");
    changed=candidate;changed.nodes[0].x=-0.;require(!memo.matches(changed,false),"Signed-zero candidate changes preserve exact arithmetic identity");
    changed=candidate;changed.material_frames[1].w=std::nextafter(1.,0.);require(!memo.matches(changed,false),"A material frame change invalidates the candidate memo");
    changed=candidate;changed.guide_id=8;require(!memo.matches(changed,false),"A candidate cannot reuse another guide's check");
    memo.remember(candidate,true,false);require(memo.matches(candidate,true)&&!memo.clear&&!memo.matches(candidate,false),"A checked contact result and skin chart are also memoized exactly");
    changed=candidate;changed.nodes.resize(17);changed.material_frames.resize(17);memo.remember(changed,false,true);
    require(!memo.matches(changed,false)&&!memo.matches(candidate,true),"An oversized candidate disables the bounded memo without accepting a stale result");
}
void boundedTriangleCache(){
    // Query the face just beyond the acceleration metadata cap. Every source
    // triangle remains admitted and tested; cache capacity never changes shape.
    std::vector<Vec> vertices;std::vector<Tri> faces;vertices.reserve(3*65537);faces.reserve(65537);
    for(unsigned i=0;i<65537;++i){const double x=double(i%257)*.01,z=double(i/257)*.01;const auto first=unsigned(vertices.size());
        vertices.push_back({x,0,z});vertices.push_back({x+.003,0,z});vertices.push_back({x,0,z+.003});faces.push_back({first,first+1,first+2});}
    const auto last=faces.back();const auto a=vertices[last[0]],b=vertices[last[1]],c=vertices[last[2]];
    MeshGeometry large(std::move(vertices),std::move(faces),false);
    for(double band:{1e-5,.0001,.01})for(double distance:{0.,.00009999,.0001,.00010001,.02}){
        const auto shift=Vec{0,distance,0};const auto x=add(a,shift),y=add(b,shift),z=add(c,shift);
        require(large.triangleNear(x,y,z,band)==(large.triangleDistance(x,y,z,band)<band),"Faces beyond the metadata cache retain independent exact triangle predicates");}
}
void connectedMeshContact(){
    const auto obstacle=cube();unsigned seed=189032u;
    auto random=[&]{seed=seed*1664525u+1013904223u;return double(seed)/4294967295.*4-2;};
    auto compare=[&](const std::vector<Vec>& points,const std::vector<Tri>& faces,double band){
        ContactTopology topology(unsigned(points.size()),faces);std::size_t work=0;MeshContactWork measured;
        const bool observed=meshNear(*obstacle,points,topology,band,work,measured);
        bool expected=false;
        for(auto p:points){const Vec d{std::max(std::abs(p.x)-1,0.),std::max(std::abs(p.y)-1,0.),std::max(std::abs(p.z)-1,0.)};
            // Analytic box distance is independent of the collision BVH/parity.
            if(length(d)<band)expected=true;}
        for(auto t:faces)if(obstacle->triangleDistance(points[t[0]],points[t[1]],points[t[2]],band)<band)expected=true;
        require(observed==expected,"Connected component proof must match analytic box containment and exhaustive face distance");
    };
    // One exterior component cannot certify a different enclosed component.
    compare({{2,0,0},{2,1,0},{2,0,1},{0,0,0},{.1,0,0},{0,.1,0}},{{0,1,2},{3,4,5}},1e-5);
    compare({{2,0,0},{2,1,0},{2,0,1},{0,0,0}},{{0,1,2}},1e-5); // unused interior vertex
    compare({{-3,0,-3},{3,0,-3},{0,0,4}},{{0,1,2}},1e-5); // face-only crossing
    for(unsigned trial=0;trial<6000;++trial){std::vector<Vec> points;for(unsigned v=0;v<10;++v)points.push_back({random(),random(),random()});
        compare(points,trial%2?std::vector<Tri>{{0,1,2},{2,3,4},{5,6,7}}:std::vector<Tri>{{0,1,2},{3,4,5},{6,7,8}},trial%3==0?1e-5:trial%3==1?.01:.2);}
    // Dense disconnected sheets well outside the solid: one point per sheet,
    // with every triangle retained in the surface proof and no nearest queries.
    std::vector<Vec> p;std::vector<Tri> t;for(unsigned i=0;i<100;++i){p.push_back({2,double(i)/100,0});p.push_back({2,double(i)/100,.1});}
    for(unsigned i=0;i<99;++i){t.push_back({i*2,i*2+1,i*2+2});t.push_back({i*2+1,i*2+3,i*2+2});}
    ContactTopology topology(unsigned(p.size()),t);require(topology.components.size()==1,"Connected strip needs exactly one containment representative");
    MeshContactWork count;std::size_t work=0;require(!meshNear(*obstacle,p,topology,.01,work,count)&&count.pointTests==0,"Separated strip needs no point classification");
    rejects([]{ContactTopology bad(2,{{0,1,2}});});work=2000000;rejects([&]{meshNear(*obstacle,p,topology,.01,work,count);});
}
void geometry(){
    auto mesh=cube();require(mesh->solid(),"Closed cube admission");
    require(std::abs(mesh->point({0,0,0}).gap+1)<1e-9,"Solid interior signed distance");
    require(std::abs(mesh->point({2,0,0}).gap-1)<1e-9,"Exterior distance");
    // The fast root predicate must preserve the original strict signed-gap
    // result inside, outside, and near faces, edges and corners at several
    // instance scales. A deterministic grid also exercises parity paths.
    for(double scale:{.01,1.,13.})for(double gap:{1e-5,.03,1.}){
        for(int x=-13;x<=13;++x)for(int y=-13;y<=13;++y)for(int z=-13;z<=13;++z){
            Vec p{x*.1,y*.1,z*.1};require(mesh->occupied(p,scale,gap)==(mesh->point(p).gap*scale<gap),"Fast root occupancy must match signed-distance classification");}
        for(double delta:{-1e-8,0.,1e-8}){const double radius=gap/scale;
            for(Vec p:{Vec{1+radius+delta,0,0},Vec{1+delta,1+delta,0},Vec{1+delta,1+delta,1+delta}})
                require(mesh->occupied(p,scale,gap)==(mesh->point(p).gap*scale<gap),"Fast root occupancy must match contact-band boundaries");}}
    // Nested closed shells exercise the parity buffer's bounded fast path and
    // its overflow path; even and odd depths have different interior status.
    for(unsigned shellCount:{31u,32u,40u,41u}){std::vector<Vec> vertices;std::vector<Tri> triangles;
        for(unsigned i=0;i<shellCount;++i){const double h=.2+.02*i;const unsigned base=unsigned(vertices.size());
            for(Vec q:{Vec{-h,-h,-h},Vec{h,-h,-h},Vec{h,h,-h},Vec{-h,h,-h},Vec{-h,-h,h},Vec{h,-h,h},Vec{h,h,h},Vec{-h,h,h}})vertices.push_back(q);
            for(Tri t:{Tri{0,2,1},Tri{0,3,2},Tri{4,5,6},Tri{4,6,7},Tri{0,1,5},Tri{0,5,4},Tri{1,2,6},Tri{1,6,5},Tri{2,3,7},Tri{2,7,6},Tri{3,0,4},Tri{3,4,7}})triangles.push_back({base+t[0],base+t[1],base+t[2]});}
        MeshGeometry shells(std::move(vertices),std::move(triangles));require(shells.occupied({0,0,0},1.,1e-5)==bool(shellCount%2),"Nested-shell parity must survive the hit-buffer overflow path");}
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
    for(double band:{1e-5,.025,.3})for(int x=-12;x<=12;++x)for(int y=-8;y<=8;++y){
        const double u=x*.13,v=y*.17;Vec a{u,v,.75},b{u+.04,v+.21,1.2},c{u+.19,v-.07,1.3};
        require(mesh->triangleNear(a,b,c,band)==(mesh->triangleDistance(a,b,c,band)<band),"Early triangle contact must match the independent bounded distance");}
    require(mesh->triangleNear({-3,0,-3},{3,0,-3},{0,0,4},.001),"Early triangle contact catches a surface-only crossing");
    require(!mesh->triangleNear({2,-.1,-.1},{2,.1,-.1},{2,0,.1},.001),"Early triangle contact rejects separated faces");
    unsigned randomState=1234567;auto sample=[&]{randomState=1664525u*randomState+1013904223u;return (double(randomState)/4294967295.)*4-2;};
    for(unsigned trial=0;trial<4000;++trial){Vec a{sample(),sample(),sample()},b{sample(),sample(),sample()},c{sample(),sample(),sample()};
        const double band=trial%3==0?1e-5:trial%3==1?.01:.2;require(mesh->triangleNear(a,b,c,band)==(mesh->triangleDistance(a,b,c,band)<band),"Early triangle separation must match bounded distance across varied faces");}
    for(unsigned trial=0;trial<2000;++trial){Vec a{sample(),sample(),sample()},b{sample(),sample(),sample()};const double radius=.03+.1*(trial%4);
        const auto exact=mesh->segment(a,b);const auto bounded=mesh->contactSegment(a,b,radius);require(bool(bounded)==(exact.gap<=radius),"Bounded capsule contact must match the unbounded witness");
        if(bounded)require(std::abs(bounded->gap-exact.gap)<1e-8,"Bounded capsule witness preserves its signed gap");
        require(mesh->segmentNear(a,b,radius)==(exact.gap<radius),"Early segment band must agree with the independent signed witness");}
    require(mesh->segment({-2,0,0},{2,0,0}).gap<-.99,"Crossing deepest witness");
    Shape shape{7,mesh,{}};shape.transform.rows={Vec{0,2,0},Vec{-2,0,0},Vec{0,0,2},Vec{3,4,5}};
    for(auto tm:{shape.transform,Transform{}}){InverseTransform inverse(tm);for(Vec p:{Vec{3,4,5},Vec{1,-2,9},Vec{.125,.002,-7}})
        require(length(sub(inverse.point(p),tm.inversePoint(p)))<1e-14,"Cached inverse matches the original cofactor transform");}
    MeshWorld world(1,{shape},100,2);auto q=world.classify_point({3,4,5},0,{});require(q.complete&&q.hits[0].location==v::Location::Inside,"Rotated scaled solid point");
    v::CapsuleQuery capsule{3,9,{0,4,5},{6,4,5},.01,.002};auto contacts=world.query_capsule(capsule,{});require(contacts.complete&&contacts.contacts.size()==1,"Whole capsule crossing");
    auto c=contacts.contacts[0];auto axis=add(capsule.a,mul(sub(capsule.b,capsule.a),c.material_u));require(length(sub(axis,c.axis_point))<1e-9,"Material witness reconstruction");
    require(std::abs(dot(c.outward_normal,sub(c.axis_point,c.obstacle_point))-.012-c.signed_gap_m)<1e-8,"Single clearance application");
    auto rounded=shape;rounded.transform.rows[0].x=1.3e-8;rounded.transform.rows[1].x-=2.7e-8;MeshWorld floatWorld(2,{rounded});auto fp=floatWorld.query_capsule(capsule,{});require(fp.complete&&!fp.contacts.empty(),"Float-rounded similarity remains admitted");
    for(const auto& hit:fp.contacts){auto a=add(capsule.a,mul(sub(capsule.b,capsule.a),hit.material_u));require(length(sub(a,hit.axis_point))<1e-12&&std::abs(dot(hit.outward_normal,sub(a,hit.obstacle_point))-.012-hit.signed_gap_m)<1e-12,"Rounded host matrix preserves exact material and signed-gap witnesses");}
    Shape skewed{8,mesh,{}};skewed.transform.rows={Vec{1,0,0},Vec{.000009,1.000009,0},Vec{0,0,.999991},Vec{3,4,5}};
    Shape small{9,mesh,{}};small.transform.rows={Vec{.0001,0,0},Vec{0,.0001,0},Vec{0,0,.0001},Vec{3,4,5}};
    Shape large{10,mesh,{}};large.transform.rows={Vec{1000,0,0},Vec{0,1000,0},Vec{0,0,1000},Vec{3,4,5}};
    Shape far{11,mesh,{}};far.transform.rows[3]={1e8,-1e8,1e8};auto smallFar=small;smallFar.id=12;smallFar.transform.rows[3]=far.transform.rows[3];
    for(auto transformed:{shape,rounded,skewed,small,large,far,smallFar}){MeshWorld reference(3,{transformed},50000,64),fast(3,{transformed},50000,64);
        auto compare=[&](const v::CapsuleQuery& q){auto observed=reference.query_capsule(q,{});auto clear=fast.capsuleClear(q,{},1e-8);require(observed.complete&&bool(clear),"Hinge predicate returns a complete query");
            bool expected=true;for(const auto& hit:observed.contacts)if(hit.signed_gap_m< -1e-8)expected=false;require(*clear==expected,"Early hinge predicate matches the original transformed witness");};
        const double scale=transformed.transform.scale();
        for(unsigned trial=0;trial<6000;++trial){Vec a=transformed.transform.point({sample(),sample(),sample()}),b=transformed.transform.point({sample(),sample(),sample()});compare({3,9,a,b,scale*(.001+.1*(trial%5)),scale*.002});}
        for(double delta:{-1e-7,-1e-9,0.,1e-9,1e-7}){const double radius=.02*scale,clearance=.002*scale,offset=(radius+clearance-1e-8+delta*scale)/scale;
            compare({3,9,transformed.transform.point({1+offset,-.5,0}),transformed.transform.point({1+offset,.5,0}),radius,clearance});}}
    MeshWorld manyReference(4,{shape,skewed,small},10000,64),manyFast(4,{shape,skewed,small},10000,64);
    for(unsigned trial=0;trial<6000;++trial){v::CapsuleQuery q{3,9,add({3,4,5},{sample(),sample(),sample()}),add({3,4,5},{sample(),sample(),sample()}),.001+.1*(trial%5),.002};
        const auto observed=manyReference.query_capsule(q,{});const auto clear=manyFast.capsuleClear(q,{},1e-8);require(observed.complete&&bool(clear),"Multi-collider hinge query completes");
        bool expected=true;for(const auto& hit:observed.contacts)if(hit.signed_gap_m< -1e-8)expected=false;require(*clear==expected,"Multi-collider fast predicate matches all original witnesses");}
    MeshWorld limitedCollector(5,{shape,skewed,small},10,1);v::CapsuleQuery overlap{3,9,{3,4,5},{3.00001,4,5},.1,.002};
    require(!limitedCollector.capsuleClear(overlap,{},1e-8),"A constrained collector retains explicit incomplete results");
    auto invalid=shape;invalid.transform.rows[0]=mul(invalid.transform.rows[0],-1);rejects([&]{MeshWorld w(1,{invalid});});
    invalid=shape;invalid.transform.rows[0]=mul(invalid.transform.rows[0],2);rejects([&]{MeshWorld w(1,{invalid});});
    rejects([]{MeshGeometry open({{0,0,0},{1,0,0},{0,1,0}},{{0,1,2}});});
    std::atomic_bool flag=true;require(world.query_capsule(capsule,{&flag}).outcome==v::Outcome::Cancelled,"Cancellation");
    MeshWorld bounded(1,{shape},1,1);bounded.classify_point({0,0,0},0,{});require(!bounded.query_capsule(capsule,{}).complete,"Explicit query exhaustion");
    MeshWorld fastBounded(1,{shape},1,1);require(bool(fastBounded.capsuleClear(capsule,{},1e-8)),"A bounded hinge query returns a complete result before exhaustion");
    require(!fastBounded.capsuleClear(capsule,{},1e-8),"The fast predicate preserves query exhaustion");
    MeshWorld fastCancelled(1,{shape},1,1);require(!fastCancelled.capsuleClear(capsule,{&flag},1e-8),"The fast predicate preserves cancellation");
}
void sources(){
    auto raw=bladeSource();auto source=prepareSource(raw);require(source->rig->guides.size()==2,"Folded blade recognition");
    const auto compact=deformationSource(source);
    auto compareCompact=[&](const Pose& pose){
        const auto words=deformationPose(*compact,pose);const auto bounds=deformationBounds(*compact,words);
        for(unsigned face=0;face<compact->faces.size();++face){auto original=compact->faces[face];
            require(deformationVisible(*compact,words,face)==visibleFace(*source,pose,original),"Compact triangle visibility matches canonical delivery");
            for(unsigned k=0;k<3;++k){auto p=deformationPoint(*compact,words,face,k),expected=posePoint(*source,pose,source->rig->triangles[original][k]);
                require(length(sub(p,expected))<2e-7,"Compact pose matches double CPU mesh delivery");
                require(p.x>=bounds.lo.x&&p.x<=bounds.hi.x&&p.y>=bounds.lo.y&&p.y<=bounds.hi.y&&p.z>=bounds.lo.z&&p.z<=bounds.hi.z,"Compact conservative bounds enclose delivered corners");}}
    };
    std::vector<DeformationChange> changed;
    for(unsigned slot:{0u,1u,31u,63u,95u,127u,65535u}){DeformationChange c;c.slot=slot;c.pose=slot;c.enabled=slot%2==0;c.transform={1,0,0,0,1,0,0,0,1,float(slot),0,0};changed.push_back(c);}
    const auto table=deformationChanges(changed);
    for(const auto& c:changed){auto index=deformationFind(table,c.slot);require(index>=0&&table.words[index][1]==float(c.pose)&&table.words[index][2]==(c.enabled?1.f:-1.f),"Sparse changed-instance lookup preserves identity and disable state");}
    for(unsigned slot=2;slot<65535;++slot)if(slot!=31&&slot!=63&&slot!=95&&slot!=127)require(deformationFind(table,slot)<0,"Sparse hash misses terminate across wrapped clusters");
    changed.push_back(changed.front());rejects([&]{deformationChanges(changed);});
    auto saved=saveSource(*source);auto reloaded=prepareSource(raw,{},&saved);require(reloaded->fingerprint==source->fingerprint,"Prepared metadata round trip");
    auto stale=raw;stale.positions[0][0]+=.001f;rejects([&]{prepareSource(stale,{},&saved);});
    Pose rest;rest.guides.resize(2);rest.hiddenRoots.resize(2);
    compareCompact(rest);
    for(unsigned i=0;i<raw.positions.size();++i)require(length(sub(posePoint(*source,rest,i),source->rig->positions[i]))<1e-10,"Exact rest reconstruction");
    Shape cover{1,cube(.01),{}};cover.transform.rows[3]={-.03,0,0};
    auto pose=fitSource(*source,{cover},.001,.5,true,2);require(!pose.allHidden&&pose.hiddenRoots[0]&&!pose.hiddenRoots[1],"Partial rooted group cover");
    compareCompact(pose);
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
    auto noMargin=fitSource(*source,{margin},0,.5,true,4),withMargin=fitSource(*source,{margin},0,.5,true,4,{0,1,0},.004);
    require(!noMargin.hiddenRoots[0]&&withMargin.hiddenRoots[0]&&!withMargin.hiddenRoots[1],"Hide margin expands root exclusion independently of Contact gap");
    // A fixed edge can cross a tiny obstacle even when the root centre and
    // all its anchored vertices are outside; only the intersected root hides.
    const auto& anchors=source->rig->guides[0].anchors;require(anchors.size()==3,"Expected basal blade anchors");
    Shape fixedEdge{6,cube(.0001),{}};fixedEdge.transform.rows[3]=mul(add(source->rig->positions[anchors[0]],source->rig->positions[anchors[1]]),.5);
    const auto edgeInverse=InverseTransform(fixedEdge.transform);constexpr double rootBand=1e-5;
    require(!fixedEdge.geometry->occupied(edgeInverse.point(source->rig->guides[0].rest.nodes.front()),1,rootBand),"Fixed-edge fixture keeps root centre outside");
    for(auto v:anchors)require(!fixedEdge.geometry->occupied(edgeInverse.point(source->rig->positions[v]),1,rootBand),"Fixed-edge fixture keeps each anchor outside");
    auto crossing=fixedEdge.geometry->contactSegment(edgeInverse.point(source->rig->positions[anchors[0]]),edgeInverse.point(source->rig->positions[anchors[1]]),rootBand);
    require(crossing&&crossing->gap<rootBand,"Fixed-edge fixture really crosses collider");
    auto edgeHidden=fitSource(*source,{fixedEdge},0,.5,true,4);
    require(edgeHidden.hiddenRoots[0]&&!edgeHidden.hiddenRoots[1]&&edgeHidden.coveredRoots==1,"Hide precisely the root whose fixed edge crosses");
    rejects([&]{fitSource(*source,{fixedEdge},0,.5,false,4);});
    auto edgeAudit=auditSource(*source,edgeHidden,{fixedEdge});
    require(edgeAudit.at("penetrating_vertex_obstacle_pairs")==0&&edgeAudit.at("touching_triangle_obstacle_pairs")==0,"Fixed-edge masking leaves a clear visible mesh");
    // Also exercise the interior of a fully anchored face when its boundary,
    // vertices and root centre all remain outside the obstacle.
    auto faceSource=std::make_shared<Source>(*source);auto faceRig=std::make_shared<stem::Prepared>(*source->rig);faceSource->rig=faceRig;
    faceRig->triangles.push_back({anchors[0],anchors[1],anchors[2]});faceSource->guideFaces[0].push_back(unsigned(faceRig->triangles.size()-1));
    Shape fixedFace{7,cube(.000005),{}};const auto a=faceRig->positions[anchors[0]],b=faceRig->positions[anchors[1]],c=faceRig->positions[anchors[2]];
    fixedFace.transform.rows[3]=add(add(mul(a,.55),mul(b,.20)),mul(c,.25));const auto faceInverse=InverseTransform(fixedFace.transform);
    require(!fixedFace.geometry->occupied(faceInverse.point(faceRig->guides[0].rest.nodes.front()),1,rootBand),"Fixed-face fixture keeps root centre outside");
    for(auto v:anchors)require(!fixedFace.geometry->occupied(faceInverse.point(faceRig->positions[v]),1,rootBand),"Fixed-face fixture keeps each anchor outside");
    for(auto edge:{std::pair<Vec,Vec>{a,b},{b,c},{c,a}}){auto hit=fixedFace.geometry->contactSegment(faceInverse.point(edge.first),faceInverse.point(edge.second),rootBand);require(!hit||hit->gap>=rootBand,"Fixed-face fixture keeps every edge outside");}
    require(fixedFace.geometry->triangleNear(faceInverse.point(a),faceInverse.point(b),faceInverse.point(c),rootBand),"Fixed-face fixture intersects only face interior");
    auto faceHidden=fitSource(*faceSource,{fixedFace},0,.5,true,4);
    require(faceHidden.hiddenRoots[0]&&!faceHidden.hiddenRoots[1]&&faceHidden.coveredRoots==1,"Hide precisely the root whose fixed face crosses");
    rejects([&]{fitSource(*faceSource,{fixedFace},0,.5,false,4);});
    Shape contact{2,cube(.01),{}};contact.transform.rows[3]={-.018,.055,0};
    auto bent=fitSource(*source,{contact},.001,.5,true,4);require(bent.changed&&bent.activeGuides>0,"Actual mesh contact bends a rooted guide");
    compareCompact(bent);
    for(unsigned i:source->rig->guides[0].anchors)require(length(sub(posePoint(*source,bent,i),source->rig->positions[i]))<1e-7,"Bending preserves original root cross section");
    const auto audit=auditSource(*source,bent,{contact});std::cout<<"Complete blade audit "<<audit.dump()<<'\n';
    require(audit.at("penetrating_vertex_obstacle_pairs")==0&&audit.at("touching_triangle_obstacle_pairs")==0,"Independent full visible mesh clears the test obstacle");
    require(audit.at("maximum_rigid_part_edge_change").get<double>()<1e-6,"Rigid foliage shape preservation");
}
void independentHiding(){
    auto source=prepareSource(bladeSource());Shape overhead{1,cube(.005),{}};overhead.transform.rows[3]={-.03,.20,0};
    auto inside=fitSource(*source,{overhead},0,.5,true,1,{0,1,0},0,false);
    auto under=fitSource(*source,{overhead},0,.5,true,1,{0,1,0},0,true);
    require(!inside.changed&&under.hiddenRoots[0]&&!under.hiddenRoots[1],"Under collider hides the projected root, Inside solid leaves it visible");
    auto expanded=fitSource(*source,{overhead},0,.5,true,1,{0,1,0},.06,true);
    require(expanded.allHidden,"Hide margin expands the footprint past the second rooted blade");
    auto noHide=fitSource(*source,{overhead},0,.5,false,1,{0,1,0},.06,true);
    require(!noHide.changed,"Disabled hiding ignores its area and margin");
    auto otherGap=fitSource(*source,{overhead},.001,.5,true,1,{0,1,0},0,true);
    require(otherGap.hiddenRoots==under.hiddenRoots,"Changing bend gap does not change selected hidden roots");
    overhead.transform.rows[3].y=-.2;
    require(!fitSource(*source,{overhead},0,.5,true,1,{0,1,0},0,true).changed,"A collider below the roots does not project upwards");
    require(!cube()->projectedNear({0,2,0},{0,1,0},0),"Positive-halfspace projection excludes geometry below origin");
    require(cube()->projectedNear({1.1,-2,0},{0,1,0},.101)&&!cube()->projectedNear({1.1,-2,0},{0,1,0},.099),"Projected margin boundary uses actual triangles");
    auto plant=std::make_shared<Definition>();plant->rig=source;plant->geometryBounds=source->bounds;
    auto stone=std::make_shared<Definition>();stone->collider=cube(.005);stone->geometryBounds=stone->collider->bounds();
    auto layout=std::make_shared<Layout>();layout->layers={LayerSettings{true,false,true,0,.5},LayerSettings{false,true,true,0,.5,.06,true}};layout->sources={{stone},{plant}};
    Instance c;c.identity="stone";c.layer=0;c.hostTransform={1,0,0,0,1,0,0,0,1,-3,0,2000};layout->instances.push_back(c);
    Instance p;p.identity="plant";p.layer=1;p.hostTransform={1,0,0,0,1,0,0,0,1,0,0,0};layout->instances.push_back(p);
    Engine engine(layout);auto a=engine.evaluate({});require(a->poses.contains(1)&&a->poses.at(1)->allHidden,"Footprint broad phase finds a collider above plant reach");
    auto moved=layout->transform(0);moved.rows[3].x=10;auto b=engine.evaluate(a,{{0,moved}},{0});require(b->poses.empty(),"Moving the footprint away restores hidden roots");
    moved.rows[3].x=-.03;auto d=engine.evaluate(b,{{0,moved}},{0});require(d->poses.contains(1),"Moved collider index restores footprint coverage");
    auto garden=std::make_shared<Layout>(*layout);
    for(unsigned i=1;i<5000;++i){auto next=p;next.row=i;next.identity="plant"+std::to_string(i);next.hostTransform[9]=float(i%100)*40;next.hostTransform[10]=float(i/100)*40;garden->instances.push_back(next);}
    Engine gardenEngine(garden);auto local=gardenEngine.evaluate({});
    require(local->statistics.affected==1&&local->poses.size()==1,"Downward footprint keeps one exact neighborhood in a 5000-plant garden");
    auto rotated=overhead;rotated.transform.rows={Vec{0,1,0},Vec{-1,0,0},Vec{0,0,1},Vec{.20,0,0}};
    require(fitSource(*source,{rotated},0,.5,true,1,{1,0,0},.06,true).allHidden,"Projection follows supplied world up through local collider rotation");
    rejects([&]{fitSource(*source,{},0,.5,true,1,{0,1,0},-1);});
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
    auto invalid=moved;invalid.rows[0]={0,0,0};rejects([&]{engine.evaluate(first,{{0,invalid}},{0});});require(first->poses.size()==1,"Failure retains previous immutable publication");
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
void parallelInteractions(){
    auto source=prepareSource(bladeSource());auto plant=std::make_shared<Definition>();plant->rig=source;plant->geometryBounds=source->bounds;
    auto stone=std::make_shared<Definition>();stone->collider=cube(.01);stone->geometryBounds=stone->collider->bounds();
    auto layout=std::make_shared<Layout>();layout->layers={LayerSettings{true,false,false,0,.5},LayerSettings{false,true,false,0,.5}};layout->sources={{stone},{plant}};
    Instance obstacle;obstacle.layer=0;obstacle.identity="o:parallel";obstacle.hostTransform={1,0,0,0,1,0,0,0,1,-1.8f,0,5.5f};layout->instances.push_back(obstacle);
    for(unsigned i=0;i<300;++i){Instance p;p.layer=1;p.row=i;p.identity="p:"+std::to_string(i);p.hostTransform={1,0,0,0,1,0,0,0,1,0,0,0};layout->instances.push_back(p);}
    Engine engine(layout);amin::setComputeThreads(1);const auto serial=engine.evaluate({});amin::setComputeThreads(2);const auto explicitTwo=engine.evaluate({});
    amin::setComputeThreads(0);const auto automatic=engine.evaluate({});const auto available=std::max(1u,std::thread::hardware_concurrency());
    require(serial->statistics.participants==1&&explicitTwo->statistics.participants==std::min(2u,available),"Explicit interaction worker override is respected");
    require(automatic->statistics.participants==std::max(std::min(available,4u),std::min(8u,available>4?available-2:available)),"Large automatic interaction work uses the bounded worker policy");
    require(serial->poses.size()==300&&explicitTwo->poses.size()==300&&automatic->poses.size()==300,"Every overlapping plant participates at each worker setting");
    for(std::size_t i=1;i<=300;++i){const auto& a=*serial->poses.at(i);const auto& b=*automatic->poses.at(i);
        require(a.hiddenRoots==b.hiddenRoots&&a.smoothedRoots==b.smoothedRoots,"Parallel root and chart choices are deterministic");
        for(unsigned v=0;v<source->rig->positions.size();++v)require(length(sub(posePoint(*source,a,v),posePoint(*source,b,v)))<1e-12,"Parallel interaction pose matches serial output");}
}
void movedObstacleIndex(){
    auto source=prepareSource(bladeSource());auto plant=std::make_shared<Definition>();plant->rig=source;plant->geometryBounds=source->bounds;
    auto stone=std::make_shared<Definition>();stone->collider=cube(.01);stone->geometryBounds=stone->collider->bounds();
    auto layout=std::make_shared<Layout>();layout->layers={LayerSettings{true,false,false,0,.5},LayerSettings{false,true,false,0,.5}};layout->sources={{stone},{plant}};
    Instance near;near.layer=0;near.identity="o:near";near.hostTransform={1,0,0,0,1,0,0,0,1,-1.8f,0,5.5f};layout->instances.push_back(near);
    Instance remote=near;remote.identity="o:remote";remote.hostTransform[9]=10000;layout->instances.push_back(remote);
    for(unsigned i=0;i<128;++i){auto extra=remote;extra.identity="o:extra:"+std::to_string(i);extra.hostTransform[10]=float(i)*200;layout->instances.push_back(extra);}
    Instance flower;flower.layer=1;flower.identity="p:one";flower.hostTransform={1,0,0,0,1,0,0,0,1,0,0,0};const auto plantIndex=layout->instances.size();layout->instances.push_back(flower);
    Engine engine(layout);auto first=engine.evaluate({});require(first->poses.contains(plantIndex),"Published collider contacts the real rooted source");
    auto nearTM=layout->transform(0),farTM=layout->transform(1);std::map<std::size_t,Transform> swap{{0,farTM},{1,nearTM}};
    auto moved=engine.evaluate(first,swap,{0,1});require(moved->poses.contains(plantIndex)&&moved->statistics.fittedGuides>0,"Edited collider enters from outside its original indexed bounds");
    auto audit=engine.audit(*moved,1000);require(!audit.at("results").empty()&&audit["results"][0]["penetrating_vertex_obstacle_pairs"]==0&&audit["results"][0]["touching_triangle_obstacle_pairs"]==0,"Indexed candidates clear the independent brute-force full-mesh audit");
    auto disabled=engine.evaluate(moved,swap,{1},{1});require(!disabled->poses.contains(plantIndex),"Moved-away base bound and deleted override do not create stale contacts");
    auto restored=engine.evaluate(disabled,swap,{1},{});require(restored->poses.contains(plantIndex),"Re-enabling an edited collider restores its current contact");
    require(first->poses.contains(plantIndex),"Successor edits cannot mutate the prior complete publication");
    std::map<std::size_t,Transform> crowded;std::vector<std::size_t> changed;
    for(std::size_t i=1;i<=65;++i){crowded.emplace(i,nearTM);changed.push_back(i);}
    bool bounded=false;try{engine.evaluate(first,crowded,changed);}catch(const std::exception& error){bounded=std::string(error.what()).find("More than 64 relevant colliders")!=std::string::npos;}
    require(bounded&&first->poses.contains(plantIndex),"Too many relevant edited colliders reject atomically without changing the previous publication");
}
void largeObstacleAdmission(){
    auto stone=std::make_shared<Definition>();stone->collider=cube(.01);stone->geometryBounds=stone->collider->bounds();
    auto layout=std::make_shared<Layout>();layout->layers={LayerSettings{true,false,false,0,.5}};layout->sources={{stone}};
    for(unsigned i=0;i<16384;++i){Instance item;item.layer=0;item.identity="o:"+std::to_string(i);item.hostTransform={1,0,0,0,1,0,0,0,1,float(i)*20,0,0};layout->instances.push_back(std::move(item));}
    Engine engine(layout);auto state=engine.evaluate({});require(state->statistics.obstacles==16384&&state->statistics.obstacleIndexPayloadBytes>0,"Large obstacle layouts are indexed and admitted");
    auto excess=std::make_shared<Layout>(*layout);auto item=excess->instances.back();item.identity="o:excess";excess->instances.push_back(item);
    rejects([&]{Engine denied(excess);});require(state->statistics.obstacles==16384,"Rejected excess layout leaves the prior publication intact");
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
        require(audit.at("maximum_stem_edge_change").get<double>()<.25,"The fully contacted tuft preserves bounded stem-edge shape");
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
void longRootEdges(){
    // A coarse basal face can bridge multiple stations of a rooted ribbon.
    // The collider touches the upper leaf; its fixed root and long edges must
    // survive without tearing or sacrificing full-surface clearance.
    prep::Snapshot raw;const float heights[]={0,.14f,.24f,.34f,.44f,.54f,.64f,.74f,.84f};
    for(float z:heights){raw.positions.push_back({-.015f,0,z});raw.positions.push_back({.015f,0,z});}
    for(unsigned i=1;i<std::size(heights);++i){unsigned a=(i-1)*2,b=i*2;raw.faces.push_back({a,a+1,b});raw.faces.push_back({a+1,b+1,b});}
    raw.materials.assign(raw.faces.size(),0);auto source=prepareSource(raw);
    require(source->roots==1&&source->rig->guides.size()==1,"Coarse planted ribbon prepares as one rooted guide");
    require(source->rootPivot[0]>1,"Long root-adjacent faces select a later safe hinge pivot");
    Shape obstacle{1,cube(.015),{}};obstacle.transform.rows[3]={.012,.65,0};
    auto pose=fitSource(*source,{obstacle},0,.5,false,1);require(pose.activeGuides>0,"The coarse rooted ribbon actually contacts the obstacle");
    const auto audit=auditSource(*source,pose,{obstacle});
    require(audit.at("root_anchor_error_m").get<double>()<1e-12&&audit.at("penetrating_vertex_obstacle_pairs")==0&&audit.at("touching_triangle_obstacle_pairs")==0,"Coarse ribbon retains its root and clears the complete collider surface");
    require(audit.at("maximum_stem_edge_change").get<double>()<.25,"Coarse rooted ribbon avoids excessive edge distortion");
    require(pose.qualityCheckedGuides>0&&pose.qualityWarningGuides==0&&pose.maximumCheckedStemEdgeChange<.25,"A checked clear guide reports its scoped deformation quality");
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
    // This fixture deliberately edits an otherwise immutable prepared rig.
    // Rebuild its derived topology just as a real source revision does.
    auto faces=source->guideContact[0].triangles;Tri local{0,3,6};
    for(auto& v:local)v=unsigned(std::lower_bound(source->guideVertices[0].begin(),source->guideVertices[0].end(),v)-source->guideVertices[0].begin());
    faces.push_back(local);source->guideContact[0]=ContactTopology(unsigned(source->guideVertices[0].size()),std::move(faces));
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
#include "interactions_adaptation.inc"
int main(int argc,char** argv){try{if(argc>=3&&std::string(argv[1])=="--fixture")return fixtureBenchmark(argv[2],argc>3?unsigned(std::stoul(argv[3])):8);if(argc==3&&std::string(argv[1])=="--collider-check")return fixtureColliderChecks(argv[2]);if(argc==4&&std::string(argv[1])=="--root-diagnostic")return fixtureRootDiagnostic(argv[2],unsigned(std::stoul(argv[3])));sceneAdaptation();candidateMemo();boundedTriangleCache();geometry();connectedMeshContact();sources();independentHiding();engine();parallelInteractions();movedObstacleIndex();largeObstacleAdmission();completeOverheadClump();plantedTube();longRootEdges();hybridPreparation();topologyPreparation();conservativeEnvelope();elevatedRosette();broadFaceBridge();for(int i=1;i<argc;++i)actual(argv[i]);std::cout<<"PASS mesh witnesses, bounded exact caches, connected-component oracle, frames, adjustable limits, topology preparation, shared definitions and partial root restoration\n";return 0;}catch(const std::exception& e){std::cerr<<e.what()<<'\n';return 1;}}
