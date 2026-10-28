#include "interactions_source.h"
#include "interaction_candidate_memo.h"
#include "preparation_authoring.hpp"
#include "math.hpp"
#include "geometry.hpp"
#include <algorithm>
#include <chrono>
#include <numeric>
#include <optional>
#include <unordered_map>
#include <stdexcept>
#include <functional>

namespace cyrus::interactions {
WorkCounters& workCounters(){static WorkCounters counters;return counters;}
Json workCountersJson(){auto& c=workCounters();return {{"source_preparations",c.preparations.load(std::memory_order_relaxed)},
    {"plant_fits",c.plantFits.load(std::memory_order_relaxed)},{"layouts",c.layouts.load(std::memory_order_relaxed)},
    {"evaluations",c.evaluations.load(std::memory_order_relaxed)},{"source_captures",c.sourceCaptures.load(std::memory_order_relaxed)},
    {"collider_cooks",c.colliderCooks.load(std::memory_order_relaxed)}};}
namespace f=v::fitter_detail;
namespace g=v::delivery_detail;
namespace {
struct ScopeMilliseconds {
    double& destination;std::chrono::steady_clock::time_point start=std::chrono::steady_clock::now();
    ~ScopeMilliseconds(){destination+=std::chrono::duration<double,std::milli>(std::chrono::steady_clock::now()-start).count();}
};
// A root may use the original frame or a continuous planted-root chart. The
// selected chart is recorded in the pose and used consistently by mesh checks,
// foliage, child guides, normals and final delivery.
std::optional<v::Quat> skinFrame(const stem::Guide& guide,const std::vector<v::Quat>& frames,unsigned span,double u,bool smoothRoot=false){
    if(span+1>=frames.size())throw std::runtime_error("Skin frame span outside guide");
    const auto& start=smoothRoot&&guide.parent<0&&!guide.anchors.empty()&&span==0?guide.rest.material_frames.front():frames[span];
    return g::shortest_slerp(start,frames[span+1],u);
}
stem::Rigid skinTransform(const stem::Guide& guide,const v::GuidePose& pose,unsigned span,double u,bool smoothRoot=false){
    const auto& rest=guide.rest;
    if(span+1>=rest.nodes.size()||span+1>=pose.nodes.size())throw std::runtime_error("Skin attachment span outside guide");
    auto a=g::shortest_slerp(rest.material_frames[span],rest.material_frames[span+1],u),b=skinFrame(guide,pose.material_frames,span,u,smoothRoot);
    if(!a||!b)throw std::runtime_error("Invalid skin attachment frame");
    const auto q=f::qnormal(f::product(*b,f::conjugate(*a)));
    const auto from=f::lerp(rest.nodes[span],rest.nodes[span+1],u),to=f::lerp(pose.nodes[span],pose.nodes[span+1],u);
    return {q,sub(to,f::rotate(q,from))};
}
bool boundedHinge(const v::RestGuide& rest,const std::vector<Shape>& shapes,MeshWorld& world,double clearance,v::GuidePose& pose,unsigned pivot=0,const std::function<bool(const v::RestGuide&)>& exactClear={}){
    if(pivot+1>=rest.nodes.size())throw std::runtime_error("Invalid rooted hinge pivot");
    if(exactClear&&exactClear(rest)){pose={rest.guide_id,rest.nodes,rest.material_frames};return true;}
    Vec away{};double nearest=1e100;Vec fallback{};
    for(const auto& shape:shapes){auto hit=shape.geometry->point(shape.transform.inversePoint(rest.nodes.front()));double distance=std::abs(hit.gap)*shape.transform.scale();auto normal=unit(shape.transform.vector(hit.normal));away=add(away,mul(normal,1/std::max(.001,distance)));if(distance<nearest){nearest=distance;fallback=normal;}}
    Vec force{};for(unsigned i=0;i+1<rest.nodes.size();++i){auto result=world.query_capsule({rest.guide_id,rest.span_ids[i],rest.nodes[i],rest.nodes[i+1],rest.span_radius_m[i],clearance},{});
        if(result.outcome!=v::Outcome::Ok||!result.complete)throw std::runtime_error("Incomplete hinge direction query");for(const auto& c:result.contacts)if(c.signed_gap_m<0)force=add(force,mul(c.outward_normal,-c.signed_gap_m));}
    if(length(force)>1e-8)away=force;else if(length(away)<1e-8)away=fallback;Vec tangent,axis;if(!f::unit(sub(rest.nodes.back(),rest.nodes.front()),tangent))return false;
    if(!f::unit(cross(tangent,away),axis))axis=f::rotate(rest.material_frames.front(),{1,0,0});
    auto candidate=[&](double angle,Vec rotationAxis){double s=std::sin(angle*.5);v::Quat q{rotationAxis.x*s,rotationAxis.y*s,rotationAxis.z*s,std::cos(angle*.5)};auto out=rest;
        for(unsigned i=pivot+1;i<out.nodes.size();++i)out.nodes[i]=add(rest.nodes[pivot],f::rotate(q,sub(out.nodes[i],rest.nodes[pivot])));
        for(unsigned i=pivot;i<out.material_frames.size();++i)out.material_frames[i]=f::qnormal(f::product(q,out.material_frames[i]));
        if(pivot){Vec t;v::Quat correction;
            // This joint averages a fixed incoming and rotated outgoing span.
            // Its material +Z must follow that average, not the full rotation.
            if(!f::tangent(out.nodes,pivot,t)||!f::swing(f::rotate(out.material_frames[pivot],{0,0,1}),t,correction))throw std::runtime_error("Unsupported basal material-frame chart");
            out.material_frames[pivot]=f::qnormal(f::product(correction,out.material_frames[pivot]));}
        return out;};
    auto clear=[&](const v::RestGuide& guide){if(exactClear)return exactClear(guide);for(unsigned i=0;i+1<guide.nodes.size();++i){auto result=world.capsuleClear({guide.guide_id,guide.span_ids[i],guide.nodes[i],guide.nodes[i+1],guide.span_radius_m[i],clearance},{},1e-8);
        if(!result)throw std::runtime_error("Incomplete bounded hinge validation");if(!*result)return false;}return true;};
    // Short, curved ribbons need the same directional search as longer stems.
    // A single endpoint-derived axis can rotate their basal span into the
    // obstacle on both sides, although a clear fixed-root orientation exists.
    axis=unit(sub(axis,mul(tangent,dot(axis,tangent))));const auto side=cross(tangent,axis);constexpr unsigned directions=8;
    for(unsigned step=1;step<=36;++step)for(unsigned direction=0;direction<directions;++direction){const double azimuth=direction*3.141592653589793/4;const auto selected=add(mul(axis,std::cos(azimuth)),mul(side,std::sin(azimuth)));double high=step*3.141592653589793/36,low=(step-1)*3.141592653589793/36;auto test=candidate(high,selected);
        if(clear(test)){for(unsigned i=0;i<7;++i){double mid=(low+high)*.5;if(clear(candidate(mid,selected)))high=mid;else low=mid;}
            test=candidate(high,selected);if(!clear(test))return false;pose={rest.guide_id,std::move(test.nodes),std::move(test.material_frames)};return true;}}
    if(!pivot){
        const auto basal=unit(sub(rest.nodes[1],rest.nodes[0]));
        for(const auto& shape:shapes){const auto witness=shape.geometry->point(shape.transform.inversePoint(rest.nodes.front()));const auto normal=unit(shape.transform.vector(witness.normal));v::Quat swing;
            if(!f::swing(basal,normal,swing))continue;
            for(unsigned spin=0;spin<8;++spin){const double half=spin*3.141592653589793/8.;const v::Quat turn{normal.x*std::sin(half),normal.y*std::sin(half),normal.z*std::sin(half),std::cos(half)};const auto q=f::qnormal(f::product(turn,swing));auto test=rest;
                for(auto& p:test.nodes)p=add(rest.nodes.front(),f::rotate(q,sub(p,rest.nodes.front())));for(auto& frame:test.material_frames)frame=f::qnormal(f::product(q,frame));
                if(clear(test)){pose={rest.guide_id,std::move(test.nodes),std::move(test.material_frames)};return true;}}
        }
    }
    return false;
}
// Vertices lie in individual span envelopes, but a broad triangle can bridge
// two spans and cut across the inside of a bent guide. Prove actual surfaces
// before publication, using one bounded scratch buffer for this guide.
struct PreparedShape {
    const Shape* shape;double scale;Bounds bounds,rootBounds;InverseTransform inverse;
    PreparedShape(const Shape& s,double rootClearance):shape(&s),scale(s.transform.scale()),bounds(s.transform.bounds(s.geometry->bounds())),
        rootBounds(bounds.expanded(rootClearance*1.00002+1e-9)),inverse(s.transform){}
};
// Root points alone do not describe the whole fixed surface: an anchored edge
// or face can cross a collider while every anchor remains outside it. Check
// those primitives only for active roots near an obstacle, and charge all
// scans and geometry queries to the existing bounded interaction budgets.
bool fixedRootSurfaceInside(const Source& source,unsigned root,const std::vector<PreparedShape>& shapes,double clearance,
                            std::size_t& queries,std::size_t& work){
    const auto& rig=*source.rig;const auto& guide=rig.guides.at(root);
    if(guide.anchors.size()<2)return false;
    Bounds rootBox;rootBox.include(guide.rest.nodes.front());for(auto v:guide.anchors)rootBox.include(rig.positions[v]);
    auto isRootAnchor=[&](unsigned v){return source.anchors.at(v)&&source.guideRoot.at(rig.parts.at(source.labels.at(v)).guide)==root;};
    for(const auto& shape:shapes){if(!rootBox.overlaps(shape.rootBounds))continue;
        for(auto face:source.guideFaces.at(root)){
            if(++work>2000000)throw std::runtime_error("Fixed-root surface check reached its 2M geometry-work budget; reduce simultaneous contact complexity.");
            const auto& t=rig.triangles[face];const bool anchored[3]{isRootAnchor(t[0]),isRootAnchor(t[1]),isRootAnchor(t[2])};
            if(unsigned(anchored[0])+unsigned(anchored[1])+unsigned(anchored[2])<2)continue;
            Bounds faceBox;for(unsigned k=0;k<3;++k)if(anchored[k])faceBox.include(rig.positions[t[k]]);
            if(!faceBox.overlaps(shape.rootBounds))continue;
            const double band=clearance/shape.scale;Vec p[3];for(unsigned k=0;k<3;++k)if(anchored[k])p[k]=shape.inverse.point(rig.positions[t[k]]);
            auto charge=[&]{if(++queries>2000000)throw std::runtime_error("Fixed-root classification reached its 2M query budget; reduce simultaneous collider complexity.");};
            for(unsigned k=0;k<3;++k)if(anchored[k]&&anchored[(k+1)%3]){charge();auto hit=shape.shape->geometry->contactSegment(p[k],p[(k+1)%3],band);if(hit&&hit->gap<band)return true;}
            if(anchored[0]&&anchored[1]&&anchored[2]){charge();if(shape.shape->geometry->triangleNear(p[0],p[1],p[2],band))return true;}
        }
    }
    return false;
}
struct GuideMeshCheck {
    const Source& source;unsigned index;const std::vector<Shape>& shapes;const std::vector<PreparedShape>& preparedShapes;double clearance;std::size_t& work;
    double& meshCheckMs;double& meshTransformMs;double& meshPointMs;double& meshFaceMs;double& edgeQualityMs;
    MeshContactWork& measured;
    bool smoothRoot=false;
    std::vector<Vec> points,localPoints;
    detail::GuideCandidateMemo memo;
    bool operator()(const v::RestGuide& candidate){
    ScopeMilliseconds timer{meshCheckMs};
    if(memo.matches(candidate,smoothRoot)){
        // Preserve the same logical admission/optional-quality decisions. Only
        // measured geometry operations disappear; a cache hit cannot buy a
        // different search path by changing the fitter's remaining allowance.
        if(work>2000000||memo.work>2000000-work)throw std::runtime_error("Detailed contact refinement reached its 2M geometry-query budget; reduce simultaneous contact complexity.");
        work+=memo.work;return memo.clear;
    }
    memo.valid=false;
    const auto workBefore=work;
    const auto& rig=*source.rig;const auto& vertices=source.guideVertices.at(index);const auto& faces=source.guideFaces.at(index);
    if(vertices.size()>50000||faces.size()>100000)throw std::runtime_error("Detailed contact refinement exceeds 50k vertices / 100k triangles for one guide; simplify its attached geometry or revise its guides.");
    points.resize(vertices.size());
    auto charge=[&]{if(++work>2000000)throw std::runtime_error("Detailed contact refinement reached its 2M geometry-query budget; reduce simultaneous contact complexity.");};
        v::GuidePose posed{candidate.guide_id,candidate.nodes,candidate.material_frames};Bounds bounds;
        // Authored tube rings share span/u; follower vertices share one rigid
        // attachment. Consecutive reuse avoids repeating identical SLERPs for
        // every corner without changing source ordering or arithmetic.
        unsigned lastPart=UINT_MAX,lastSpan=UINT_MAX;double lastU=-1;stem::Rigid follower;v::Quat frame;Vec centre;
        {ScopeMilliseconds transformTimer{meshTransformMs};for(unsigned k=0;k<vertices.size();++k){charge();const unsigned vertex=vertices[k];const auto& binding=rig.bindings[vertex];const auto& part=rig.parts[binding.part];Vec p;
            if(source.anchors[vertex])p=rig.positions[vertex];
            else if(!part.stem){if(lastPart!=binding.part){follower=skinTransform(rig.guides[index],posed,part.span,part.u,smoothRoot);lastPart=binding.part;}p=stem::apply(follower,rig.positions[vertex]);}
            else {if(lastSpan!=binding.span||lastU!=binding.u){auto q=skinFrame(rig.guides[index],candidate.material_frames,binding.span,binding.u,smoothRoot);if(!q)throw std::runtime_error("Invalid exact contact material frame");frame=*q;centre=f::lerp(candidate.nodes[binding.span],candidate.nodes[binding.span+1],binding.u);lastSpan=binding.span;lastU=binding.u;}p=add(centre,f::rotate(frame,binding.offset));}
            points[k]=p;bounds.include(p);
        }}
        measured.transformedVertices+=vertices.size();
        for(const auto& cached:preparedShapes){const auto& shape=*cached.shape;const auto obstacleBounds=cached.bounds.expanded(clearance);if(!bounds.overlaps(obstacleBounds))continue;const double band=clearance/cached.scale;
            localPoints.resize(points.size());{ScopeMilliseconds transformTimer{meshTransformMs};for(unsigned k=0;k<points.size();++k)localPoints[k]=cached.inverse.point(points[k]);}
            measured.inverseVertices+=points.size();
            if(meshNear(*shape.geometry,localPoints,source.guideContact.at(index),band,work,measured)){memo.remember(candidate,smoothRoot,false,work-workBefore);return false;}
        }
        memo.remember(candidate,smoothRoot,true,work-workBefore);
        return true;
    }
    std::size_t maximumCheckWork()const{
        const auto vertices=source.guideVertices.at(index).size(),faces=source.guideFaces.at(index).size();
        return vertices*(1+shapes.size())+faces*shapes.size();
    }
    double edgeStrain(){
        ScopeMilliseconds timer{edgeQualityMs};
        const auto& rig=*source.rig;const auto& vertices=source.guideVertices.at(index);const auto& faces=source.guideFaces.at(index);
        double worst=0;
        for(auto fi:faces){++work;const auto tri=rig.triangles[fi];for(unsigned k=0;k<3;++k){const auto a=tri[k],b=tri[(k+1)%3];
            if(!rig.parts[source.labels[a]].stem)continue;
            const auto pa=std::lower_bound(vertices.begin(),vertices.end(),a),pb=std::lower_bound(vertices.begin(),vertices.end(),b);
            if(pa==vertices.end()||*pa!=a||pb==vertices.end()||*pb!=b)continue;
            const double rest=length(sub(rig.positions[a],rig.positions[b]));if(rest<1e-6)continue;
            worst=std::max(worst,std::abs(length(sub(points[pa-vertices.begin()],points[pb-vertices.begin()]))/rest-1));}}
        return worst;
    }
};
bool meshHinge(const v::RestGuide& rest,const std::vector<Shape>& shapes,MeshWorld& world,double clearance,v::GuidePose& pose,unsigned pivot,GuideMeshCheck& check){
    return boundedHinge(rest,shapes,world,clearance,pose,pivot,[&](const v::RestGuide& candidate){return check(candidate);});
}
Vec core(const std::array<float,3>& p){return {p[0],p[2],-p[1]};}
prep::Analysis blades(const prep::Snapshot& s,prep::Settings settings){
    prep::validate(s,settings);
    std::vector<unsigned> parent(s.positions.size());std::iota(parent.begin(),parent.end(),0);
    auto root=[&](unsigned n){while(parent[n]!=n){parent[n]=parent[parent[n]];n=parent[n];}return n;};
    for(auto face:s.faces){for(auto i:face)if(i>=parent.size())throw std::runtime_error("Blade face index outside source");for(int k=1;k<3;++k){auto a=root(face[0]),b=root(face[k]);if(a!=b)parent[std::max(a,b)]=std::min(a,b);}}
    std::unordered_map<unsigned,unsigned> ids;std::vector<std::vector<unsigned>> vertices,faces;prep::Analysis out;out.fingerprint=prep::fingerprint(s);out.labels.resize(parent.size());
    double ground=1e100,top=-1e100,maxRootElevation=0;
    for(unsigned i=0;i<parent.size();++i){for(auto p:s.positions[i])if(!std::isfinite(p)||std::abs(p)>10000)throw std::runtime_error("Invalid blade source coordinates");ground=std::min(ground,double(s.positions[i][2]));top=std::max(top,double(s.positions[i][2]));auto [it,inserted]=ids.emplace(root(i),unsigned(vertices.size()));if(inserted){vertices.emplace_back();faces.emplace_back();}out.labels[i]=it->second;vertices[it->second].push_back(i);}
    if(vertices.size()>settings.limits.guides)throw std::runtime_error("Blade profile exceeds the guide limit; increase Guides in Preparation limits.");
    for(unsigned i=0;i<s.faces.size();++i)faces[out.labels[s.faces[i][0]]].push_back(i);
    Json j={{"schema",2},{"asset","Ordered three-vertex folded blades"},{"vertices",s.positions.size()},{"triangles",s.faces.size()},
        {"guides",Json::array()},{"parts",Json::array()},{"guide_order",Json::array()},{"preview_triangles",s.faces},{"preview_materials",s.materials},{"connectivity_version",2}};
    for(unsigned ci=0;ci<vertices.size();++ci){const auto& vs=vertices[ci];unsigned rings=unsigned(vs.size()/3),tip=unsigned(vs.size()%3);
        if(rings<2||tip>1||faces[ci].size()!=4*(rings-1)+2*tip)throw std::runtime_error("Blade profile requires connected ordered three-vertex sections with an optional terminal tip");
        std::unordered_map<unsigned,unsigned> rank;for(unsigned i=0;i<vs.size();++i)rank.emplace(vs[i],i/3);
        for(auto fi:faces[ci]){unsigned lo=UINT_MAX,hi=0;for(auto v:s.faces[fi]){lo=std::min(lo,rank.at(v));hi=std::max(hi,rank.at(v));}if(hi!=lo+1)throw std::runtime_error("Blade sections are not connected in authored vertex order");}
        std::vector<Vec> nodes;std::vector<unsigned> anchors;
        for(unsigned r=0;r<rings;++r){Vec centre{};for(unsigned k=0;k<3;++k)centre=add(centre,core(s.positions[vs[r*3+k]]));nodes.push_back(mul(centre,1./3));}
        if(tip)nodes.push_back(core(s.positions[vs.back()]));
        if(nodes.front().y>nodes.back().y){std::reverse(nodes.begin(),nodes.end());if(tip)anchors.push_back(vs.back());else for(unsigned k=0;k<3;++k)anchors.push_back(vs[(rings-1)*3+k]);}
        else for(unsigned k=0;k<3;++k)anchors.push_back(vs[k]);
        const double basalBand=std::max(.003,std::min(.025,(top-ground)*.25));
        maxRootElevation=std::max(maxRootElevation,nodes.front().y-ground);
        if(nodes.front().y-ground>basalBand)throw std::runtime_error("Blade root lies outside the admitted basal tuft; review or author guides");
        double arc=0;for(unsigned k=1;k<nodes.size();++k)arc+=length(sub(nodes[k],nodes[k-1]));
        if(arc<settings.minimumLength)throw std::runtime_error("Blade shorter than admitted minimum length");
        if(nodes.size()==2)nodes.insert(nodes.begin()+1,mul(add(nodes.front(),nodes.back()),.5));
        if(nodes.size()>16)throw std::runtime_error("Blade has more than 16 guide stations");
        Json points=Json::array();for(auto p:nodes)points.push_back({p.x,p.y,p.z});
        j["guides"].push_back({{"component",ci},{"nodes",points},{"parent",-1},{"parent_span",0},{"parent_u",0.},
            {"parent_distance_m",0.},{"length_m",arc},{"unresolved",false},{"root_kind","basal"},{"root_ring_vertices",anchors}});
        j["guide_order"].push_back(ci);j["parts"].push_back({{"guide",ci},{"stem",true},{"span",0},{"u",0.},{"material",s.materials[faces[ci].front()]}});
    }
    j["source_geometry_sha256"]=prep::geometryHash(s,out.labels,unsigned(vertices.size()));out.metadata=std::move(j);
    out.report={{"profile","Ordered three-vertex folded blades"},{"guides",vertices.size()},{"ground_roots",vertices.size()},
        {"unresolved_guides",0},{"can_prepare",true},{"review_required",true},{"preview_triangles",s.faces.size()},
        {"basal_band_m",std::max(.003,std::min(.025,(top-ground)*.25))},{"max_root_elevation_m",maxRootElevation},
        {"warning","Review inferred bases. Original blade-root elevations are preserved within a bounded basal tuft."}};
    return out;
}
bool intersects(const v::RestGuide& guide,const std::vector<Shape>& shapes,double gap){
    Bounds b;double radius=0;for(auto p:guide.nodes)b.include(p);for(double r:guide.span_radius_m)radius=std::max(radius,r);b=b.expanded(radius+gap);
    for(const auto& shape:shapes)if(b.overlaps(shape.transform.bounds(shape.geometry->bounds())))return true;return false;
}
const v::GuidePose& guidePose(const Source& source,const Pose& pose,unsigned guide,v::GuidePose& rest){
    if(pose.guides[guide])return *pose.guides[guide];const auto& r=source.rig->guides[guide].rest;rest={r.guide_id,r.nodes,r.material_frames};return rest;
}
}
std::shared_ptr<const Source> prepareSource(const prep::Snapshot& snapshot,prep::Settings settings,const Json* saved,const Json* authored,const std::atomic_bool* requestedCancel){
    workCounters().preparations.fetch_add(1,std::memory_order_relaxed);
    auto start=std::chrono::steady_clock::now();prep::validate(snapshot,settings);auto p=std::make_shared<Source>();p->limits=settings.limits;p->fingerprint=prep::fingerprint(snapshot);prep::Analysis analyzed;
    if(saved){
        if((saved->at("format")!=1&&saved->at("format")!=2)||saved->at("fingerprint")!=p->fingerprint)throw std::runtime_error("Prepared interaction source is stale or incompatible");
        p->authoring=saved->value("authoring",Json::object());
        if(!p->authoring.empty()){std::atomic_bool cancel=false;p->authoring=prep::canonicalAuthoring(snapshot,prep::inspectPieces(snapshot,settings,cancel),p->authoring);}
        analyzed.metadata=saved->at("metadata");analyzed.report=saved->at("report");analyzed.labels=saved->at("labels").get<std::vector<unsigned>>();
        if(analyzed.labels.size()!=snapshot.positions.size()||analyzed.metadata.at("source_geometry_sha256")!=prep::geometryHash(snapshot,analyzed.labels,unsigned(analyzed.metadata.at("parts").size())))throw std::runtime_error("Saved interaction source geometry/binding hash differs");
    }else{
        std::atomic_bool localCancel=false;const auto& cancel=requestedCancel?*requestedCancel:localCancel;std::atomic_int progress=0;
        if(authored){auto pieces=prep::inspectPieces(snapshot,settings,cancel);p->authoring=prep::canonicalAuthoring(snapshot,pieces,*authored);}
        if(authored&&!p->authoring["parts"].empty())analyzed=prep::analyzeTopology(snapshot,settings,cancel,progress,p->authoring);
        else try{analyzed=prep::analyze(snapshot,settings,cancel,progress);}
        catch(const std::exception& e){if(std::string(e.what()).find("No supported ordered tube stems found")==std::string::npos)throw;
            try{analyzed=blades(snapshot,settings);}catch(const std::exception& b){if(std::string(b.what()).find("Blade ")!=0)throw;analyzed=prep::analyzeTopology(snapshot,settings,cancel,progress);}}
        if(!analyzed.report.value("can_prepare",false)&&(!authored||p->authoring["parts"].empty()))analyzed=prep::analyzeTopology(snapshot,settings,cancel,progress);
    }
    if(!analyzed.report.value("can_prepare",false))throw PreparationFailure(std::move(analyzed));
    if(analyzed.metadata.at("guides").size()>settings.limits.guides||analyzed.metadata.at("parts").size()>settings.limits.parts)throw std::runtime_error("Prepared definition exceeds the current Preparation limits; raise the corresponding limit or analyze again.");
    p->metadata=std::move(analyzed.metadata);p->report=std::move(analyzed.report);p->labels=std::move(analyzed.labels);
    if(saved){
        auto& metadata=p->metadata;Json preview=Json::array(),materials=Json::array();const bool componentPreview=metadata.value("preparation_version",0)>=3;
        if(!componentPreview)for(unsigned k=0;k<metadata.at("preview_triangles").size();++k){const auto& tri=metadata["preview_triangles"][k];auto part=p->labels[tri[0].get<unsigned>()];if(metadata["parts"][part].at("stem").get<bool>()){preview.push_back(tri);materials.push_back(metadata["preview_materials"][k]);}}
        for(unsigned fi=0;fi<snapshot.faces.size();++fi){const auto& tri=snapshot.faces[fi];unsigned part=p->labels[tri[0]];bool stem=metadata["parts"][part].at("stem");unsigned hash=(part+2402u)*2654435761u;
            if((componentPreview||!stem)&&double(hash%100000)/100000<std::clamp(settings.foliageFraction,.01,1.)){if(preview.size()>=settings.limits.previewTriangles)throw std::runtime_error("Light preview exceeds Preview triangles in Interactions > Preparation limits; reduce the percentage or increase that limit.");preview.push_back(tri);materials.push_back(snapshot.materials[fi]);}}
        if(preview.empty()&&!snapshot.faces.empty()){preview.push_back(snapshot.faces.front());materials.push_back(snapshot.materials.front());}
        metadata["preview_triangles"]=std::move(preview);metadata["preview_materials"]=std::move(materials);p->report["preview_triangles"]=metadata["preview_triangles"].size();p->report["guide_inference_reused"]=true;
    }
    if(p->metadata.at("preview_triangles").size()>settings.limits.previewTriangles)throw std::runtime_error("Prepared preview exceeds Preview triangles in Preparation limits.");
    std::vector<Vec> positions;positions.reserve(snapshot.positions.size());for(auto q:snapshot.positions)positions.push_back(core(q));
    p->rig=stem::prepare(p->metadata,positions,snapshot.faces,p->labels);
    auto& rig=*p->rig;p->guideRoot.resize(rig.guides.size());p->rootRadius.resize(rig.guides.size());p->rootPivot.assign(rig.guides.size(),1);p->anchors.assign(rig.positions.size(),false);std::vector<double> lengths(rig.guides.size());
    for(unsigned i:rig.order){const auto& guide=rig.guides[i];p->guideRoot[i]=guide.parent<0?i:p->guideRoot[guide.parent];
        double arc=0;for(unsigned k=1;k<guide.rest.nodes.size();++k)arc+=length(sub(guide.rest.nodes[k],guide.rest.nodes[k-1]));
        lengths[i]=arc+(guide.parent<0?length(guide.rest.nodes.front()):lengths[guide.parent]);
        double bound=0;for(auto r:guide.rest.max_bound_offset_m)bound=std::max(bound,r);p->reach=std::max(p->reach,lengths[i]+bound);
        for(auto v:guide.anchors){p->anchors[v]=true;p->rootRadius[i]=std::max(p->rootRadius[i],length(sub(rig.positions[v],guide.rest.nodes.front())));}}
    p->guideBounds.resize(rig.guides.size());p->guideRadius.resize(rig.guides.size());
    for(unsigned i=0;i<rig.guides.size();++i){const auto& rest=rig.guides[i].rest;for(auto q:rest.nodes)p->guideBounds[i].include(q);for(auto r:rest.span_radius_m)p->guideRadius[i]=std::max(p->guideRadius[i],r);p->guideBounds[i]=p->guideBounds[i].expanded(p->guideRadius[i]);}
    p->structuralGuides.assign(rig.guides.size(),false);
    for(const auto& guide:rig.guides)if(guide.parent>=0)p->structuralGuides[p->guideRoot[guide.parent]]=true;
    for(const auto& part:rig.parts)p->partRoot.push_back(p->guideRoot[part.guide]);
    // Some authored root triangles connect an anchored ring directly to a
    // vertex several guide spans away. Rotating just after span 0 tears those
    // long edges. Prefer a later fixed pivot, bounded by the last usable joint.
    for(const auto& tri:rig.triangles)for(unsigned k=0;k<3;++k){const auto a=tri[k],b=tri[(k+1)%3];
        auto observe=[&](unsigned fixed,unsigned adjacent){if(!p->anchors[fixed])return;const auto& fixedPart=rig.parts[p->labels[fixed]];const auto& binding=rig.bindings[adjacent];const auto& other=rig.parts[binding.part];const auto guide=fixedPart.guide;
            if(other.guide!=guide||rig.guides[guide].parent>=0||binding.span==0)return;
            p->rootPivot[guide]=std::max(p->rootPivot[guide],std::min<unsigned>(unsigned(rig.guides[guide].rest.nodes.size()-2),binding.span+2));};
        observe(a,b);observe(b,a);}
    p->guideVertices.resize(rig.guides.size());p->guideFaces.resize(rig.guides.size());
    for(unsigned i=0;i<rig.positions.size();++i){const auto& part=rig.parts[p->labels[i]];if(part.fixed){p->fixedVertices.push_back(i);p->fixedBounds.include(rig.positions[i]);}else p->guideVertices[part.guide].push_back(i);}
    for(unsigned i=0;i<rig.triangles.size();++i){const auto& part=rig.parts[p->labels[rig.triangles[i][0]]];if(part.fixed)p->fixedFaces.push_back(i);else p->guideFaces[part.guide].push_back(i);}
    // Resolve source addresses once; exact candidate checks then use direct
    // local corner indexing and a certified component representative list.
    p->guideContact.reserve(rig.guides.size());std::vector<unsigned> local(rig.positions.size(),UINT_MAX);
    for(unsigned guide=0;guide<rig.guides.size();++guide){const auto& vertices=p->guideVertices[guide];
        for(unsigned k=0;k<vertices.size();++k)local[vertices[k]]=k;
        std::vector<Tri> faces;faces.reserve(p->guideFaces[guide].size());
        for(auto fi:p->guideFaces[guide]){Tri t=rig.triangles[fi];for(auto& v:t){if(local[v]==UINT_MAX)throw std::runtime_error("Cross-guide triangle in contact topology");v=local[v];}faces.push_back(t);}
        p->guideContact.emplace_back(unsigned(vertices.size()),std::move(faces));for(auto v:vertices)local[v]=UINT_MAX;}
    Bounds rootBounds;for(unsigned i=0;i<rig.guides.size();++i)if(rig.guides[i].parent<0){rootBounds.include(rig.guides[i].rest.nodes.front());++p->roots;}
    p->rootCentre=mul(add(rootBounds.lo,rootBounds.hi),.5);
    for(unsigned i=0;i<rig.guides.size();++i)if(rig.guides[i].parent<0)p->rootReach=std::max(p->rootReach,length(sub(rig.guides[i].rest.nodes.front(),p->rootCentre))+std::max(p->rootRadius[i],rig.guides[i].rest.span_radius_m.front()));
    // The light mesh uses authored vertices from a few complete stem rings.
    // Preserve original face/corner addresses for every UV seam. Whole foliage
    // triangles retain their exact original corner addresses. Coarse tube
    // corners select the incident face in the same material and outward sector.
    std::vector<unsigned> offsets(rig.positions.size()+1);for(const auto& tri:rig.triangles)for(auto vertex:tri)++offsets[vertex+1];std::partial_sum(offsets.begin(),offsets.end(),offsets.begin());
    std::vector<unsigned> corners(rig.triangles.size()*3),cursor=offsets;
    for(unsigned fi=0;fi<rig.triangles.size();++fi)for(unsigned k=0;k<3;++k)corners[cursor[rig.triangles[fi][k]]++]=fi*3+k;
    p->previewRemap.assign(rig.positions.size(),UINT_MAX);
    std::vector<bool> previewGuides(rig.guides.size(),true);
    if(p->report.value("profile",std::string{})=="Ordered three-vertex folded blades"){
        previewGuides.assign(rig.guides.size(),false);const auto wanted=std::max<std::size_t>(1,std::size_t(std::ceil(rig.guides.size()*settings.foliageFraction)));
        for(std::size_t i=0;i<wanted;++i)previewGuides[i*rig.guides.size()/wanted]=true;
    }
    for(unsigned pi=0;pi<rig.previewTriangles.size();++pi){const auto& tri=rig.previewTriangles[pi];unsigned original=UINT_MAX;Tri uv{};
        if(!previewGuides[rig.parts[p->labels[tri[0]]].guide])continue;
        for(unsigned j=offsets[tri[0]];j<offsets[tri[0]+1];++j){unsigned fi=corners[j]/3;if(rig.triangles[fi]==tri){original=fi;uv={fi*3,fi*3+1,fi*3+2};break;}}
        if(original==UINT_MAX){const auto normal=unit(cross(sub(rig.positions[tri[1]],rig.positions[tri[0]]),sub(rig.positions[tri[2]],rig.positions[tri[0]])));
            for(unsigned k=0;k<3;++k){double best=-1e100;unsigned address=UINT_MAX;for(unsigned j=offsets[tri[k]];j<offsets[tri[k]+1];++j){unsigned fi=corners[j]/3;if(snapshot.materials[fi]!=rig.previewMaterials[pi])continue;const auto& face=rig.triangles[fi];const auto n=cross(sub(rig.positions[face[1]],rig.positions[face[0]]),sub(rig.positions[face[2]],rig.positions[face[0]]));if(length(n)<1e-16)continue;double match=dot(normal,unit(n));if(match>best){best=match;address=corners[j];}}
                if(address==UINT_MAX)throw std::runtime_error("Light stem corner has no admitted source material/UV sector");uv[k]=address;}original=uv[0]/3;
        }
        if(p->previewFaces.size()>=settings.limits.previewTriangles)throw std::runtime_error("Light preview triangle limit reached; change Preview triangles in Preparation limits.");
        p->previewFaces.push_back(original);p->previewTriangles.push_back(tri);p->previewUVCorners.push_back(uv);for(auto vertex:tri)if(p->previewRemap[vertex]==UINT_MAX){p->previewRemap[vertex]=unsigned(p->previewVertices.size());p->previewVertices.push_back(vertex);}}
    for(auto q:positions)p->bounds.include(q);
    p->sortedVertices.resize(positions.size());std::iota(p->sortedVertices.begin(),p->sortedVertices.end(),0);std::sort(p->sortedVertices.begin(),p->sortedVertices.end(),[&](unsigned a,unsigned b){double x=rig.positions[a].x,y=rig.positions[b].x;return x==y?a<b:x<y;});
    p->bytes=sizeof(Source)+rig.positions.capacity()*sizeof(Vec)+rig.triangles.capacity()*sizeof(Tri)+rig.bindings.capacity()*sizeof(stem::Binding)+rig.parts.capacity()*sizeof(stem::Part)+p->labels.capacity()*sizeof(unsigned)+p->metadata.dump().size()+p->report.dump().size()+p->authoring.dump().size();
    for(const auto& guide:rig.guides)p->bytes+=sizeof(guide)+guide.rest.nodes.capacity()*sizeof(Vec)+guide.rest.material_frames.capacity()*sizeof(v::Quat)+guide.anchors.capacity()*sizeof(unsigned)+guide.rest.node_ids.capacity()*sizeof(v::Id)+guide.rest.span_ids.capacity()*sizeof(v::Id)+guide.rest.span_radius_m.capacity()*sizeof(double)+guide.rest.max_bound_offset_m.capacity()*sizeof(double);
    p->bytes+=(p->fixedVertices.capacity()+p->fixedFaces.capacity())*sizeof(unsigned)+p->guideBounds.capacity()*sizeof(Bounds)+p->guideRadius.capacity()*sizeof(double);
    p->bytes+=(p->sortedVertices.capacity()+p->previewFaces.capacity()+p->previewVertices.capacity()+p->previewRemap.capacity()+p->rootPivot.capacity())*sizeof(unsigned)+(p->anchors.capacity()+p->structuralGuides.capacity()+14)/8;
    p->bytes+=(p->previewTriangles.capacity()+p->previewUVCorners.capacity())*sizeof(Tri);
    p->bytes+=(p->guideVertices.capacity()+p->guideFaces.capacity())*sizeof(std::vector<unsigned>);
    for(const auto& rows:p->guideVertices)p->bytes+=rows.capacity()*sizeof(unsigned);for(const auto& rows:p->guideFaces)p->bytes+=rows.capacity()*sizeof(unsigned);
    p->bytes+=p->guideContact.capacity()*sizeof(ContactTopology);for(const auto& t:p->guideContact)p->bytes+=t.triangles.capacity()*sizeof(Tri)+t.components.capacity()*sizeof(unsigned);
    p->report["delivered_preview_triangles"]=p->previewFaces.size();
    p->report["source_payload_bytes"]=p->bytes;p->report["cache_realization_ms"]=std::chrono::duration<double,std::milli>(std::chrono::steady_clock::now()-start).count();return p;
}
Json saveSource(const Source& source){const bool edited=source.authoring.is_object()&&!source.authoring.empty()&&!source.authoring.value("parts",Json::array()).empty();Json out={{"format",edited?2:1},{"fingerprint",source.fingerprint},{"metadata",source.metadata},{"report",source.report},{"labels",source.labels}};if(edited)out["authoring"]=source.authoring;return out;}
Pose fitSource(const Source& source,const std::vector<Shape>& obstacles,double clearance,double stiffness,bool cover,std::uint64_t generation,Vec worldUpInSource,double hideMargin,bool hideUnder){
    workCounters().plantFits.fetch_add(1,std::memory_order_relaxed);
    if(!std::isfinite(hideMargin)||hideMargin<0||hideMargin>1000)throw std::runtime_error("Hide margin must be 0..1000 metres in source space");
    if(!std::isfinite(clearance)||clearance<0||clearance>10||!std::isfinite(stiffness)||stiffness<0||stiffness>1)throw std::runtime_error("Invalid interaction fit settings");
    const auto& prepared=*source.rig;Pose pose;pose.bytes=sizeof(Pose);std::size_t coverageQueries=0;worldUpInSource=unit(worldUpInSource);
    // Root exclusion is independent of bending clearance. Footprint exclusion
    // is an explicit opt-in along world up, including rotated source instances.
    pose.guides.resize(prepared.guides.size());pose.hiddenRoots.assign(prepared.guides.size(),false);pose.smoothedRoots.assign(prepared.guides.size(),false);
    pose.bytes+=pose.guides.capacity()*sizeof(pose.guides[0])+(pose.hiddenRoots.capacity()+7)/8+(pose.smoothedRoots.capacity()+7)/8;
    std::vector<PreparedShape> coverage;coverage.reserve(obstacles.size());
    const double rootClearance=clearance+1e-5;
    const double hideBand=hideMargin+1e-5;
    for(const auto& shape:obstacles)coverage.emplace_back(shape,std::max(rootClearance,hideBand));
    MeshWorld world(generation,obstacles,200000,64);unsigned roots=0,hidden=0;const auto coverageStart=std::chrono::steady_clock::now();
    for(unsigned i=0;i<prepared.guides.size();++i){const auto& guide=prepared.guides[i];if(guide.parent>=0)continue;++roots;
        const auto root=guide.rest.nodes.front();Bounds rootBox;rootBox.include(root);for(auto vertex:guide.anchors)rootBox.include(prepared.positions[vertex]);
        for(const auto& item:coverage){if(!hideUnder&&!rootBox.overlaps(item.rootBounds))continue;
            auto occupied=[&](Vec point){if(point.x<item.rootBounds.lo.x||point.x>item.rootBounds.hi.x||point.y<item.rootBounds.lo.y||point.y>item.rootBounds.hi.y||point.z<item.rootBounds.lo.z||point.z>item.rootBounds.hi.z)return false;
                if(++coverageQueries>2000000)throw std::runtime_error("Fixed-root classification reached its 2M query budget; reduce simultaneous collider complexity.");return item.shape->geometry->occupied(item.inverse.point(point),item.scale,hideBand);};
            bool inside=occupied(root);for(auto vertex:guide.anchors)if(!inside)inside=occupied(prepared.positions[vertex]);
            if(!inside&&cover&&hideUnder){
                auto projected=[&](Vec p){if(++coverageQueries>2000000)throw std::runtime_error("Root footprint query budget reached");return item.shape->geometry->projectedNear(item.inverse.point(p),unit(item.shape->transform.inverseVector(worldUpInSource)),hideBand/item.scale);};
                inside=projected(root);for(auto vertex:guide.anchors)if(!inside)inside=projected(prepared.positions[vertex]);
            }
            if(!inside)continue;
            if(!cover)continue;
            pose.hiddenRoots[i]=true;++hidden;pose.changed=true;break;}}
    pose.coverageMs=std::chrono::duration<double,std::milli>(std::chrono::steady_clock::now()-coverageStart).count();
    pose.coveredRoots=hidden;pose.coverageQueries=coverageQueries;pose.allHidden=roots>0&&roots==hidden&&source.fixedFaces.empty();if(pose.allHidden){pose.queries=world.calls()+coverageQueries;return pose;}
    // A padded box containing the complete rest mesh can certify separation
    // with triangle/box SAT plus a containment test. Keep every obstacle in the
    // fitter if any box intersects, since bending can enter another obstacle.
    bool needsFit=false;for(const auto& shape:obstacles){Bounds box;for(unsigned k=0;k<8;++k)box.include(shape.transform.inversePoint({k&1?source.bounds.hi.x:source.bounds.lo.x,k&2?source.bounds.hi.y:source.bounds.lo.y,k&4?source.bounds.hi.z:source.bounds.lo.z}));++pose.separationQueries;
        if(shape.geometry->overlapsSolid(box.expanded((clearance+1e-5)/shape.transform.scale()))){needsFit=true;break;}}
    if(!needsFit){pose.queries=world.calls()+coverageQueries+pose.separationQueries;return pose;}
    // Fixed decorations have no deforming guide. Diagnose a real intersection
    // explicitly instead of allowing a neighboring leaf to drag them around.
    for(const auto& shape:obstacles)if(!source.fixedFaces.empty()&&source.fixedBounds.expanded(clearance+1e-5).overlaps(shape.transform.bounds(shape.geometry->bounds()))){
        const double scale=shape.transform.scale();auto charge=[&]{if(++pose.meshRefinementWork>2000000)throw std::runtime_error("Fixed decoration check reached its 2M geometry-query budget.");};
        for(auto v:source.fixedVertices){charge();if(shape.geometry->point(shape.transform.inversePoint(prepared.positions[v])).gap*scale<clearance+1e-5)throw std::runtime_error("Collider intersects fixed source decoration. Move it away from the rigid base or use a plant-only source.");}
        for(auto fi:source.fixedFaces){charge();const auto& t=prepared.triangles[fi];if(shape.geometry->triangleDistance(shape.transform.inversePoint(prepared.positions[t[0]]),shape.transform.inversePoint(prepared.positions[t[1]]),shape.transform.inversePoint(prepared.positions[t[2]]))*scale<clearance+1e-5)throw std::runtime_error("Collider intersects fixed source decoration. Move it away from the rigid base or use a plant-only source.");}
    }
    v::SolveOptions options;options.limits={4096,32,64,12000,240,2000000,4000000,128*1024*1024};options.tolerances={1e-7,1e-8,.002,.003,1e-6};
    options.clearance_m=clearance+1e-5;options.rest_shape_weight=.002+.008*stiffness;options.bend_weight=.2+.8*stiffness;options.root_angle_weight=0;
    for(unsigned index:prepared.order){if(pose.hiddenRoots[source.guideRoot[index]])continue;const auto& guide=prepared.guides[index];auto rest=guide.rest;bool inherited=false;
        if(guide.parent>=0&&pose.guides[guide.parent]){auto delta=skinTransform(prepared.guides[guide.parent],*pose.guides[guide.parent],guide.parentSpan,guide.parentU,pose.smoothedRoots[guide.parent]);
            for(auto& q:rest.nodes)q=stem::apply(delta,q);for(auto& q:rest.material_frames)q=f::qnormal(f::product(delta.q,q));inherited=true;}
        if(intersects(rest,obstacles,options.clearance_m)){
            GuideMeshCheck exact{source,index,obstacles,coverage,options.clearance_m,pose.meshRefinementWork,pose.meshCheckMs,pose.meshTransformMs,pose.meshPointMs,pose.meshFaceMs,pose.edgeQualityMs,pose.exact};
            bool contact=false,basalContact=false;for(unsigned k=0;k+1<rest.nodes.size();++k){auto hit=world.query_capsule({rest.guide_id,rest.span_ids[k],rest.nodes[k],rest.nodes[k+1],rest.span_radius_m[k],options.clearance_m},{});
                if(hit.outcome!=v::Outcome::Ok||!hit.complete)throw std::runtime_error("Incomplete guide contact query");for(const auto& c:hit.contacts)if(c.signed_gap_m< -options.tolerances.penetration_m){contact=true;basalContact|=k==0;}}
            if(!contact)contact=!exact(rest);
            if(contact){
                bool fixedSurfaceInside=false;
                if(guide.parent<0&&!guide.anchors.empty()){
                    ScopeMilliseconds rootTimer{pose.coverageMs};
                    fixedSurfaceInside=fixedRootSurfaceInside(source,index,coverage,rootClearance,coverageQueries,pose.meshRefinementWork);
                }
                if(fixedSurfaceInside){
                    const bool hideSurface=cover&&fixedRootSurfaceInside(source,index,coverage,hideBand,coverageQueries,pose.meshRefinementWork);
                    if(!hideSurface)throw std::runtime_error("Collider or Contact gap intersects a fixed root (guide "+std::to_string(index)+"). Reduce Contact gap, move the collider, or enable hiding and increase Hide margin.");
                    pose.hiddenRoots[index]=true;++hidden;pose.changed=true;continue;
                }
                if(++pose.activeGuides>source.limits.guides)throw std::runtime_error("Active interaction guide limit reached; increase Guides in Preparation limits.");
                // A planted tube's whole basal ring is fixed in the delivered
                // mesh. Preserve its first span/frame when that span is clear;
                // overriding only its ring vertices after rotating the frame
                // creates a skin tear. A collider crossing this span needs the
                // position-only fit instead of an impossible fixed-span solve.
                // Folded blades retain their separately tested flexible base.
                bool clampBase=guide.parent<0&&!basalContact&&source.report.value("profile",std::string{})!="Ordered three-vertex folded blades";
                unsigned pivot=clampBase?source.rootPivot[index]:0;
                options.root_mode=clampBase?v::RootMode::ClampFrame:v::RootMode::PositionOnly;options.max_proposal_step_m=std::max(.002,length(sub(rest.nodes.back(),rest.nodes.front()))/12.);
                v::SolveResult fit;
                bool hingeClear=boundedHinge(rest,obstacles,world,options.clearance_m,fit.pose,pivot);
                if(!hingeClear&&pivot>1){pivot=1;hingeClear=boundedHinge(rest,obstacles,world,options.clearance_m,fit.pose,pivot);}
                // A clear basal span can still block every clamped rotation
                // through its conservative attached-foliage envelope. Relax
                // its direction only after the clamped search proves unable
                // to clear, and freshly validate the position-only candidate.
                if(!hingeClear&&clampBase){clampBase=false;pivot=0;options.root_mode=v::RootMode::PositionOnly;hingeClear=boundedHinge(rest,obstacles,world,options.clearance_m,fit.pose);}
                if(!hingeClear){
                    // Try the actual mesh before the iterative capsule solver:
                    // a wider leaf can make its spherical bound infeasible.
                    hingeClear=meshHinge(rest,obstacles,world,options.clearance_m,fit.pose,false,exact);
                    if(hingeClear)++pose.meshRefinements;
                }
                if(hingeClear){fit.status=v::SolveStatus::ConvergedCandidate;++pose.hinges;}
                else {fit=v::fit_rooted_guide(rest,generation,world,options,{});pose.iterations+=fit.metrics.iterations;}
                if(fit.status!=v::SolveStatus::ConvergedCandidate){
                    if((fit.status==v::SolveStatus::UnresolvedContact||fit.status==v::SolveStatus::WorkLimit||fit.status==v::SolveStatus::RootConflict)&&boundedHinge(rest,obstacles,world,options.clearance_m,fit.pose,pivot))++pose.hinges;
                    else {std::string message="Rooted mesh contact did not converge for guide "+std::to_string(index)+" (status "+std::to_string(int(fit.status))+")";for(const auto& issue:fit.issues)message+=" "+issue.code;
                        message+=" parent="+std::to_string(guide.parent)+" radius="+std::to_string(rest.span_radius_m.front());
                        auto rootReport=world.classify_point(rest.nodes.front(),rest.span_radius_m.front()+options.clearance_m,{});for(const auto& h:rootReport.hits)message+=" root_gap="+std::to_string(h.signed_gap_m);
                        if(guide.parent>=0){const auto& parent=prepared.guides[guide.parent].rest;const auto* posed=pose.guides[guide.parent].get();const auto& nodes=posed?posed->nodes:parent.nodes;auto span=guide.parentSpan;
                            auto result=world.query_capsule({parent.guide_id,parent.span_ids[span],nodes[span],nodes[span+1],parent.span_radius_m[span],options.clearance_m},{});message+=" parent_radius="+std::to_string(parent.span_radius_m[span])+" parent_moved="+std::to_string(bool(posed));for(const auto& c:result.contacts)message+=" parent_gap="+std::to_string(c.signed_gap_m);}
                        throw std::runtime_error(message);}}
                auto delivered=rest;delivered.nodes=fit.pose.nodes;delivered.material_frames=fit.pose.material_frames;
                bool smoothRoot=false,meshClear=exact(delivered);
                constexpr std::size_t workLimit=2000000;
                auto room=[&](std::size_t cost){return pose.meshRefinementWork<=workLimit&&cost<=workLimit-pose.meshRefinementWork;};
                const auto qualityWork=source.guideFaces[index].size();
                // If the original skin chart crosses the obstacle, a continuous
                // root chart may clear the same candidate. Keep it only after
                // checking the actual mesh, not just its guide envelope.
                if(!meshClear&&guide.parent<0&&!guide.anchors.empty()&&room(exact.maximumCheckWork())){
                    exact.smoothRoot=true;meshClear=exact(delivered);smoothRoot=meshClear;if(!meshClear)exact.smoothRoot=false;}
                if(!meshClear){
                    exact.smoothRoot=false;smoothRoot=false;
                    if(!meshHinge(rest,obstacles,world,options.clearance_m,fit.pose,false,exact))throw std::runtime_error("Broad-leaf surface contact did not converge for guide "+std::to_string(index)+"; previous complete result retained.");
                    delivered.nodes=fit.pose.nodes;delivered.material_frames=fit.pose.material_frames;++pose.meshRefinements;
                }
                // A later hinge can protect long anchored edges while tearing a
                // different long edge across its pivot. Compare alternatives
                // only for a bad root chart and only within the existing work
                // budget. Every alternative must independently clear the mesh;
                // if optional work is unavailable the prior clear pose wins.
                if(guide.parent<0&&room(qualityWork)){
                    double best=exact.edgeStrain();auto bestPose=fit.pose;bool bestSmooth=smoothRoot;
                    auto consider=[&](const v::GuidePose& candidate,bool smooth){
                        if(!room(exact.maximumCheckWork()+qualityWork))return;
                        auto proposed=rest;proposed.nodes=candidate.nodes;proposed.material_frames=candidate.material_frames;exact.smoothRoot=smooth;
                        if(exact(proposed)){const double score=exact.edgeStrain();if(score<best){best=score;bestPose=candidate;bestSmooth=smooth;}}
                    };
                    if(best>.25&&!smoothRoot&&!guide.anchors.empty())consider(fit.pose,true);
                    const auto spans=rest.nodes.size()-1;
                    if(best>.25&&pivot>1&&world.calls()+320*spans<200000&&room(exact.maximumCheckWork()+qualityWork)){
                        v::GuidePose alternative;if(boundedHinge(rest,obstacles,world,options.clearance_m,alternative,1)){
                            consider(alternative,false);if(best>.25&&!guide.anchors.empty())consider(alternative,true);}}
                    ++pose.qualityCheckedGuides;pose.maximumCheckedStemEdgeChange=std::max(pose.maximumCheckedStemEdgeChange,best);
                    if(best>.25)++pose.qualityWarningGuides;
                    fit.pose=std::move(bestPose);smoothRoot=bestSmooth;exact.smoothRoot=bestSmooth;
                }
                const auto frames=g::check_frames(fit.pose.nodes,fit.pose.material_frames,rest.span_ids,options.tolerances.frame_radians,false);
                if(frames.state!=g::FrameCheck::State::Ok)throw std::runtime_error("Contact pose material frames do not follow their guide tangents");
                pose.smoothedRoots[index]=smoothRoot;pose.guides[index]=std::make_shared<v::GuidePose>(std::move(fit.pose));pose.changed=true;continue;}}
        if(inherited){pose.guides[index]=std::make_shared<v::GuidePose>(v::GuidePose{rest.guide_id,std::move(rest.nodes),std::move(rest.material_frames)});pose.changed=true;}}
    pose.coveredRoots=hidden;pose.coverageQueries=coverageQueries;pose.allHidden=roots>0&&roots==hidden&&source.fixedFaces.empty();
    for(unsigned i=0;i<prepared.parts.size();++i){const auto& part=prepared.parts[i];if(!part.stem&&!part.fixed&&pose.guides[part.guide])pose.rigid.emplace(i,skinTransform(prepared.guides[part.guide],*pose.guides[part.guide],part.span,part.u,pose.smoothedRoots[part.guide]));}
    pose.meshPointMs=pose.exact.pointMs;pose.meshFaceMs=pose.exact.faceMs;
    pose.queries=world.calls()+coverageQueries+pose.separationQueries;pose.bytes=sizeof(Pose)+pose.guides.capacity()*sizeof(pose.guides[0])+(pose.hiddenRoots.capacity()+7)/8+(pose.smoothedRoots.capacity()+7)/8+pose.rigid.size()*(sizeof(unsigned)+sizeof(stem::Rigid)+4*sizeof(void*))+pose.rigid.bucket_count()*sizeof(void*);
    for(const auto& guide:pose.guides)if(guide)pose.bytes+=sizeof(v::GuidePose)+guide->nodes.capacity()*sizeof(Vec)+guide->material_frames.capacity()*sizeof(v::Quat);
    return pose;
}
#include "interactions_fast_bend.inc"
std::shared_ptr<const MeshGeometry> branchProxy(const Source& source,std::shared_ptr<const void> lease){
    std::vector<Vec> vertices;std::vector<Tri> faces;const auto& rig=*source.rig;
    for(unsigned i:rig.order){const auto& rest=rig.guides[i].rest;const unsigned rings=std::min<unsigned>(5,unsigned(rest.nodes.size()));
        if(vertices.size()+rings*4>250000||faces.size()+rings*8>500000)throw std::runtime_error("Neighbor branch proxy exceeds 250k vertices / 500k triangles; reduce prepared guide complexity");
        const unsigned base=unsigned(vertices.size());
        for(unsigned ring=0;ring<rings;++ring){const unsigned node=unsigned(std::size_t(ring)*(rest.nodes.size()-1)/(rings-1));
            const double radius=std::max(.0001,rest.span_radius_m[std::min<std::size_t>(node,rest.span_radius_m.size()-1)]);
            for(auto offset:{Vec{-radius,-radius,0},Vec{radius,-radius,0},Vec{radius,radius,0},Vec{-radius,radius,0}})vertices.push_back(add(rest.nodes[node],f::rotate(rest.material_frames[node],offset)));
        }
        for(unsigned ring=0;ring+1<rings;++ring)for(unsigned side=0;side<4;++side){const unsigned a=base+ring*4+side,b=base+ring*4+(side+1)%4;faces.push_back({a,b,b+4});faces.push_back({a,b+4,a+4});}
        faces.push_back({base,base+2,base+1});faces.push_back({base,base+3,base+2});const unsigned end=base+(rings-1)*4;faces.push_back({end,end+1,end+2});faces.push_back({end,end+2,end+3});
    }
    auto result=std::make_shared<MeshGeometry>(std::move(vertices),std::move(faces),false);result->allocationLease=std::move(lease);return result;
}
Vec posePoint(const Source& source,const Pose& pose,unsigned vertex){
    const auto& p=*source.rig;if(source.anchors.at(vertex))return p.positions.at(vertex);const auto& binding=p.bindings.at(vertex);const auto& part=p.parts[binding.part];
    if(part.fixed)return p.positions.at(vertex);
    if(!part.stem){auto found=pose.rigid.find(binding.part);return found==pose.rigid.end()?p.positions[vertex]:stem::apply(found->second,p.positions[vertex]);}
    if(!pose.guides[part.guide])return p.positions[vertex];const auto& guide=*pose.guides[part.guide];const bool smooth=part.guide<pose.smoothedRoots.size()&&pose.smoothedRoots[part.guide];auto q=skinFrame(p.guides[part.guide],guide.material_frames,binding.span,binding.u,smooth);
    if(!q)throw std::runtime_error("Invalid interaction material frame");return add(f::lerp(guide.nodes[binding.span],guide.nodes[binding.span+1],binding.u),f::rotate(*q,binding.offset));
}
bool visibleFace(const Source& source,const Pose& pose,unsigned face){if(pose.allHidden)return false;const auto& t=source.rig->triangles.at(face);for(auto v:t){const auto& part=source.rig->parts[source.labels[v]];if(!part.fixed&&(pose.hiddenRoots[source.partRoot[source.labels[v]]]||(!pose.hiddenGuides.empty()&&pose.hiddenGuides.at(part.guide))))return false;}return true;}
Vec poseDirection(const Source& source,const Pose& pose,unsigned vertex,Vec direction){
    const auto& p=*source.rig;if(source.anchors.at(vertex))return direction;const auto& binding=p.bindings.at(vertex);const auto& part=p.parts[binding.part];
    if(part.fixed)return direction;
    if(!part.stem){auto found=pose.rigid.find(binding.part);return found==pose.rigid.end()?direction:f::rotate(found->second.q,direction);}
    if(!pose.guides[part.guide])return direction;const auto& rest=p.guides[part.guide].rest;const auto& posed=*pose.guides[part.guide];
    const bool smooth=part.guide<pose.smoothedRoots.size()&&pose.smoothedRoots[part.guide];const auto a=g::shortest_slerp(rest.material_frames[binding.span],rest.material_frames[binding.span+1],binding.u),b=skinFrame(p.guides[part.guide],posed.material_frames,binding.span,binding.u,smooth);
    if(!a||!b)throw std::runtime_error("Invalid material frame for authored normal");return f::rotate(*b,f::rotate(f::conjugate(*a),direction));
}
unsigned nearestSourceVertex(const Source& source,Vec p){
    const auto& sorted=source.sortedVertices;const auto& points=source.rig->positions;if(sorted.empty())throw std::runtime_error("No source points available for preview binding");
    auto at=std::lower_bound(sorted.begin(),sorted.end(),p.x,[&](unsigned i,double x){return points[i].x<x;});std::size_t right=std::size_t(at-sorted.begin()),left=right;unsigned best=sorted[std::min(right,sorted.size()-1)];double distance=dot(sub(points[best],p),sub(points[best],p));
    while(left>0||right<sorted.size()){
        double a=left>0?std::pow(points[sorted[left-1]].x-p.x,2):1e100,b=right<sorted.size()?std::pow(points[sorted[right]].x-p.x,2):1e100;
        if(a>distance&&b>distance)break;unsigned i;if(a<=b)i=sorted[--left];else i=sorted[right++];double d=dot(sub(points[i],p),sub(points[i],p));if(d<distance){distance=d;best=i;}}
    return best;
}
Json auditSource(const Source& source,const Pose& pose,const std::vector<Shape>& shapes,std::size_t triangleBudget,double deliveryUnit){
    auto started=std::chrono::steady_clock::now();const auto& rig=*source.rig;std::vector<Vec> points(rig.positions.size());std::vector<bool> used(points.size());
    std::size_t triangles=0,penetrating=0,touching=0;double minimum=1e100,roots=0,stemStrain=0,rigidStrain=0;
    for(unsigned fi=0;fi<rig.triangles.size();++fi)if(visibleFace(source,pose,fi)){if(++triangles>triangleBudget)throw std::runtime_error("Full visible mesh audit triangle budget exceeded");for(auto v:rig.triangles[fi])used[v]=true;}
    for(unsigned i=0;i<points.size();++i)if(used[i]){auto p=posePoint(source,pose,i);if(deliveryUnit>0)p={double(float(p.x/deliveryUnit))*deliveryUnit,double(float(p.y/deliveryUnit))*deliveryUnit,double(float(p.z/deliveryUnit))*deliveryUnit};points[i]=p;
        if(source.anchors[i])roots=std::max(roots,length(sub(p,rig.positions[i])));
        for(const auto& shape:shapes){auto w=shape.geometry->point(shape.transform.inversePoint(p));const double gap=w.gap*shape.transform.scale();minimum=std::min(minimum,gap);penetrating+=gap< -1e-6;}}
    for(unsigned fi=0;fi<rig.triangles.size();++fi)if(visibleFace(source,pose,fi)){const auto tri=rig.triangles[fi];
        for(unsigned k=0;k<3;++k){const auto a=tri[k],b=tri[(k+1)%3];const double rest=length(sub(rig.positions[a],rig.positions[b]));if(rest<1e-6)continue;const double strain=std::abs(length(sub(points[a],points[b]))/rest-1);auto& maximum=rig.parts[source.labels[a]].stem?stemStrain:rigidStrain;maximum=std::max(maximum,strain);}
        if(length(cross(sub(points[tri[1]],points[tri[0]]),sub(points[tri[2]],points[tri[0]])))<1e-16)continue;
        for(const auto& shape:shapes){double distance=shape.geometry->triangleDistance(shape.transform.inversePoint(points[tri[0]]),shape.transform.inversePoint(points[tri[1]]),shape.transform.inversePoint(points[tri[2]]))*shape.transform.scale();minimum=std::min(minimum,distance);touching+=distance<1e-7;}}
    return {{"triangles",triangles},{"penetrating_vertex_obstacle_pairs",penetrating},{"touching_triangle_obstacle_pairs",touching},{"minimum_surface_gap_m",minimum==1e100?Json(nullptr):Json(minimum)},
        {"root_anchor_error_m",roots},{"maximum_stem_edge_change",stemStrain},{"maximum_rigid_part_edge_change",rigidStrain},{"delivered_float",deliveryUnit>0},{"audit_ms",std::chrono::duration<double,std::milli>(std::chrono::steady_clock::now()-started).count()}};
}
}
