#include "interactions_source.h"
#include "math.hpp"
#include "geometry.hpp"
#include <algorithm>
#include <chrono>
#include <numeric>
#include <unordered_map>
#include <stdexcept>

namespace cyrus::interactions {
namespace f=v::fitter_detail;
namespace g=v::delivery_detail;
namespace {
bool boundedHinge(const v::RestGuide& rest,const std::vector<Shape>& shapes,MeshWorld& world,double clearance,v::GuidePose& pose,bool clampBase=false){
    Vec away{};double nearest=1e100;Vec fallback{};
    for(const auto& shape:shapes){auto hit=shape.geometry->point(shape.transform.inversePoint(rest.nodes.front()));double distance=std::abs(hit.gap)*shape.transform.scale();auto normal=unit(shape.transform.vector(hit.normal));away=add(away,mul(normal,1/std::max(.001,distance)));if(distance<nearest){nearest=distance;fallback=normal;}}
    Vec force{};for(unsigned i=0;i+1<rest.nodes.size();++i){auto result=world.query_capsule({rest.guide_id,rest.span_ids[i],rest.nodes[i],rest.nodes[i+1],rest.span_radius_m[i],clearance},{});
        if(result.outcome!=v::Outcome::Ok||!result.complete)throw std::runtime_error("Incomplete hinge direction query");for(const auto& c:result.contacts)if(c.signed_gap_m<0)force=add(force,mul(c.outward_normal,-c.signed_gap_m));}
    if(length(force)>1e-8)away=force;else if(length(away)<1e-8)away=fallback;Vec tangent,axis;if(!f::unit(sub(rest.nodes.back(),rest.nodes.front()),tangent))return false;
    if(!f::unit(cross(tangent,away),axis))axis=f::rotate(rest.material_frames.front(),{1,0,0});
    auto candidate=[&](double angle,Vec rotationAxis){double s=std::sin(angle*.5);v::Quat q{rotationAxis.x*s,rotationAxis.y*s,rotationAxis.z*s,std::cos(angle*.5)};auto out=rest;
        const unsigned pivot=clampBase?1:0;
        for(unsigned i=pivot+1;i<out.nodes.size();++i)out.nodes[i]=add(rest.nodes[pivot],f::rotate(q,sub(out.nodes[i],rest.nodes[pivot])));
        for(unsigned i=pivot;i<out.material_frames.size();++i)out.material_frames[i]=f::qnormal(f::product(q,out.material_frames[i]));
        if(clampBase){Vec t;v::Quat correction;
            // This joint averages a fixed incoming and rotated outgoing span.
            // Its material +Z must follow that average, not the full rotation.
            if(!f::tangent(out.nodes,pivot,t)||!f::swing(f::rotate(out.material_frames[pivot],{0,0,1}),t,correction))throw std::runtime_error("Unsupported basal material-frame chart");
            out.material_frames[pivot]=f::qnormal(f::product(correction,out.material_frames[pivot]));}
        return out;};
    auto clear=[&](const v::RestGuide& guide){for(unsigned i=0;i+1<guide.nodes.size();++i){auto hit=world.query_capsule({guide.guide_id,guide.span_ids[i],guide.nodes[i],guide.nodes[i+1],guide.span_radius_m[i],clearance},{});
        if(hit.outcome!=v::Outcome::Ok||!hit.complete)throw std::runtime_error("Incomplete bounded hinge validation");for(const auto& contact:hit.contacts)if(contact.signed_gap_m< -1e-8)return false;}return true;};
    const auto side=cross(tangent,axis);const unsigned directions=rest.nodes.size()<=4?1:8;
    for(unsigned step=1;step<=27;++step)for(unsigned direction=0;direction<directions;++direction){const double azimuth=direction*3.141592653589793/4;const auto selected=add(mul(axis,std::cos(azimuth)),mul(side,std::sin(azimuth)));double high=step*3.141592653589793/36,low=(step-1)*3.141592653589793/36;auto test=candidate(high,selected);
        if(clear(test)){for(unsigned i=0;i<7;++i){double mid=(low+high)*.5;if(clear(candidate(mid,selected)))high=mid;else low=mid;}
            test=candidate(high,selected);if(!clear(test))return false;pose={rest.guide_id,std::move(test.nodes),std::move(test.material_frames)};return true;}}
    return false;
}
Vec core(const std::array<float,3>& p){return {p[0],p[2],-p[1]};}
prep::Analysis blades(const prep::Snapshot& s,prep::Settings settings){
    if(s.positions.size()<3||s.positions.size()>1000000||s.faces.empty()||s.faces.size()>2000000||s.materials.size()!=s.faces.size())throw std::runtime_error("Blade source exceeds admission");
    std::vector<unsigned> parent(s.positions.size());std::iota(parent.begin(),parent.end(),0);
    auto root=[&](unsigned n){while(parent[n]!=n){parent[n]=parent[parent[n]];n=parent[n];}return n;};
    for(auto face:s.faces){for(auto i:face)if(i>=parent.size())throw std::runtime_error("Blade face index outside source");for(int k=1;k<3;++k){auto a=root(face[0]),b=root(face[k]);if(a!=b)parent[std::max(a,b)]=std::min(a,b);}}
    std::unordered_map<unsigned,unsigned> ids;std::vector<std::vector<unsigned>> vertices,faces;prep::Analysis out;out.fingerprint=prep::fingerprint(s);out.labels.resize(parent.size());
    double ground=1e100,top=-1e100,maxRootElevation=0;
    for(unsigned i=0;i<parent.size();++i){for(auto p:s.positions[i])if(!std::isfinite(p)||std::abs(p)>10000)throw std::runtime_error("Invalid blade source coordinates");ground=std::min(ground,double(s.positions[i][2]));top=std::max(top,double(s.positions[i][2]));auto [it,inserted]=ids.emplace(root(i),unsigned(vertices.size()));if(inserted){vertices.emplace_back();faces.emplace_back();}out.labels[i]=it->second;vertices[it->second].push_back(i);}
    if(vertices.size()>2048)throw std::runtime_error("Blade source exceeds 2,048 rooted groups");
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
std::shared_ptr<const Source> prepareSource(const prep::Snapshot& snapshot,prep::Settings settings,const Json* saved){
    auto start=std::chrono::steady_clock::now();auto p=std::make_shared<Source>();p->fingerprint=prep::fingerprint(snapshot);prep::Analysis analyzed;
    if(saved){
        if(saved->at("format")!=1||saved->at("fingerprint")!=p->fingerprint)throw std::runtime_error("Prepared interaction source is stale or incompatible");
        analyzed.metadata=saved->at("metadata");analyzed.report=saved->at("report");analyzed.labels=saved->at("labels").get<std::vector<unsigned>>();
        if(analyzed.labels.size()!=snapshot.positions.size()||analyzed.metadata.at("source_geometry_sha256")!=prep::geometryHash(snapshot,analyzed.labels,unsigned(analyzed.metadata.at("parts").size())))throw std::runtime_error("Saved interaction source geometry/binding hash differs");
    }else{
        std::atomic_bool cancel=false;std::atomic_int progress=0;
        try{analyzed=prep::analyze(snapshot,settings,cancel,progress);}
        catch(const std::exception& e){if(std::string(e.what()).find("No supported ordered tube stems found")==std::string::npos)throw;analyzed=blades(snapshot,settings);}
    }
    if(!analyzed.report.value("can_prepare",false))throw std::runtime_error("Source has unresolved roots or branch connections; review required");
    p->metadata=std::move(analyzed.metadata);p->report=std::move(analyzed.report);p->labels=std::move(analyzed.labels);
    std::vector<Vec> positions;positions.reserve(snapshot.positions.size());for(auto q:snapshot.positions)positions.push_back(core(q));
    p->rig=stem::prepare(p->metadata,positions,snapshot.faces,p->labels);
    auto& rig=*p->rig;p->guideRoot.resize(rig.guides.size());p->rootRadius.resize(rig.guides.size());p->anchors.assign(rig.positions.size(),false);std::vector<double> lengths(rig.guides.size());
    for(unsigned i:rig.order){const auto& guide=rig.guides[i];p->guideRoot[i]=guide.parent<0?i:p->guideRoot[guide.parent];
        double arc=0;for(unsigned k=1;k<guide.rest.nodes.size();++k)arc+=length(sub(guide.rest.nodes[k],guide.rest.nodes[k-1]));
        lengths[i]=arc+(guide.parent<0?length(guide.rest.nodes.front()):lengths[guide.parent]);
        double bound=0;for(auto r:guide.rest.max_bound_offset_m)bound=std::max(bound,r);p->reach=std::max(p->reach,lengths[i]+bound);
        for(auto v:guide.anchors){p->anchors[v]=true;p->rootRadius[i]=std::max(p->rootRadius[i],length(sub(rig.positions[v],guide.rest.nodes.front())));}}
    for(const auto& part:rig.parts)p->partRoot.push_back(p->guideRoot[part.guide]);
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
        if(p->previewFaces.size()>=200000)throw std::runtime_error("Interaction light preview exceeds 200K original faces; reduce foliage or use a simpler source");
        p->previewFaces.push_back(original);p->previewTriangles.push_back(tri);p->previewUVCorners.push_back(uv);for(auto vertex:tri)if(p->previewRemap[vertex]==UINT_MAX){p->previewRemap[vertex]=unsigned(p->previewVertices.size());p->previewVertices.push_back(vertex);}}
    for(auto q:positions)p->bounds.include(q);
    p->sortedVertices.resize(positions.size());std::iota(p->sortedVertices.begin(),p->sortedVertices.end(),0);std::sort(p->sortedVertices.begin(),p->sortedVertices.end(),[&](unsigned a,unsigned b){double x=rig.positions[a].x,y=rig.positions[b].x;return x==y?a<b:x<y;});
    p->bytes=sizeof(Source)+rig.positions.capacity()*sizeof(Vec)+rig.triangles.capacity()*sizeof(Tri)+rig.bindings.capacity()*sizeof(stem::Binding)+rig.parts.capacity()*sizeof(stem::Part)+p->labels.capacity()*sizeof(unsigned)+p->metadata.dump().size()+p->report.dump().size();
    for(const auto& guide:rig.guides)p->bytes+=sizeof(guide)+guide.rest.nodes.capacity()*sizeof(Vec)+guide.rest.material_frames.capacity()*sizeof(v::Quat)+guide.anchors.capacity()*sizeof(unsigned)+guide.rest.node_ids.capacity()*sizeof(v::Id)+guide.rest.span_ids.capacity()*sizeof(v::Id)+guide.rest.span_radius_m.capacity()*sizeof(double)+guide.rest.max_bound_offset_m.capacity()*sizeof(double);
    p->bytes+=(p->sortedVertices.capacity()+p->previewFaces.capacity()+p->previewVertices.capacity()+p->previewRemap.capacity())*sizeof(unsigned)+(p->anchors.capacity()+7)/8;
    p->bytes+=(p->previewTriangles.capacity()+p->previewUVCorners.capacity())*sizeof(Tri);
    p->report["delivered_preview_triangles"]=p->previewFaces.size();
    p->report["source_payload_bytes"]=p->bytes;p->report["cache_realization_ms"]=std::chrono::duration<double,std::milli>(std::chrono::steady_clock::now()-start).count();return p;
}
Json saveSource(const Source& source){return {{"format",1},{"fingerprint",source.fingerprint},{"metadata",source.metadata},{"report",source.report},{"labels",source.labels}};}
Pose fitSource(const Source& source,const std::vector<Shape>& obstacles,double clearance,double stiffness,bool cover,std::uint64_t generation,Vec worldUpInSource){
    if(!std::isfinite(clearance)||clearance<0||clearance>10||!std::isfinite(stiffness)||stiffness<0||stiffness>1)throw std::runtime_error("Invalid interaction fit settings");
    const auto& prepared=*source.rig;Pose pose;pose.bytes=sizeof(Pose);std::size_t coverageQueries=0;worldUpInSource=unit(worldUpInSource);
    // A certified interior ball above the complete basal tuft proves every
    // upward root ray is covered. This works for concave closed geometry too;
    // it never substitutes an AABB or convex-hull approximation for the solid.
    for(const auto& shape:obstacles)if(shape.coverRoots){const auto box=shape.transform.bounds(shape.geometry->bounds());const auto centre=mul(add(box.lo,box.hi),.5);const auto extent=mul(sub(box.hi,box.lo),.5);
        const double projectedCentre=dot(sub(centre,source.rootCentre),worldUpInSource),projectedRadius=std::abs(worldUpInSource.x)*extent.x+std::abs(worldUpInSource.y)*extent.y+std::abs(worldUpInSource.z)*extent.z;
        for(double height:{0.,projectedCentre,projectedCentre-.4*projectedRadius,projectedCentre+.4*projectedRadius}){
            if(height!=0&&height<source.rootReach)continue;++coverageQueries;const auto sample=add(source.rootCentre,mul(worldUpInSource,height));
            if(shape.geometry->point(shape.transform.inversePoint(sample)).gap*shape.transform.scale()<=-source.rootReach-clearance-1e-5){pose.changed=pose.allHidden=cover;pose.coveredRoots=cover?source.roots:0;pose.retainedCoveredRoots=cover?0:source.roots;pose.queries=pose.coverageQueries=coverageQueries;if(!cover){pose.guides.resize(prepared.guides.size());pose.hiddenRoots.resize(prepared.guides.size());}return pose;}}}
    pose.guides.resize(prepared.guides.size());pose.hiddenRoots.assign(prepared.guides.size(),false);
    pose.bytes+=pose.guides.capacity()*sizeof(pose.guides[0])+(pose.hiddenRoots.capacity()+7)/8;
    struct Coverage {const Shape* shape;Vec up;double scale,rayDistance;};std::vector<Coverage> coverage;
    for(const auto& shape:obstacles){const auto& box=shape.geometry->bounds();const double scale=shape.transform.scale();const auto up=shape.transform.inverseVector(worldUpInSource);++coverageQueries;
        if(!shape.geometry->projectedNear(shape.transform.inversePoint(source.rootCentre),up,(source.rootReach+clearance+1e-5)/scale))continue;
        const double distance=length(sub(mul(add(box.lo,box.hi),.5),shape.transform.inversePoint(source.rootCentre)))+.5*length(sub(box.hi,box.lo))+source.rootReach/scale+1e-5;coverage.push_back({&shape,up,scale,distance});}
    MeshWorld world(generation,obstacles,200000,64);unsigned roots=0,hidden=0;std::vector<bool> blocked(prepared.guides.size());
    for(unsigned i=0;i<prepared.guides.size();++i){const auto& guide=prepared.guides[i];if(guide.parent>=0)continue;++roots;
        const double radius=std::max(source.rootRadius[i],guide.rest.span_radius_m.front())+clearance+1e-5;
        const auto root=guide.rest.nodes.front();
        for(const auto& item:coverage)if(item.shape->coverRoots){const auto local=item.shape->transform.inversePoint(root);++coverageQueries;
            // Projection distance is a lower bound on every 3D root-envelope
            // distance. It excludes outside roots without nearest-surface/parity
            // queries, while preserving exact side-envelope handling at edges.
            if(!item.shape->geometry->projectedNear(local,item.up,radius/item.scale))continue;
            ++coverageQueries;bool occupied=item.shape->geometry->rayHit(local,item.up,item.rayDistance);
            if(!occupied){Bounds rootBox;rootBox.include(root);rootBox=rootBox.expanded(radius);if(rootBox.overlaps(item.shape->transform.bounds(item.shape->geometry->bounds()))){++coverageQueries;occupied=item.shape->geometry->point(local).gap*item.scale<=radius;}}
            if(occupied){blocked[i]=true;pose.hiddenRoots[i]=cover;++hidden;pose.changed|=cover;break;}}}
    pose.coveredRoots=cover?hidden:0;pose.retainedCoveredRoots=cover?0:hidden;pose.coverageQueries=coverageQueries;pose.allHidden=cover&&roots>0&&roots==hidden;if(roots>0&&roots==hidden){pose.queries=world.calls()+coverageQueries;return pose;}
    // A padded box containing the complete rest mesh can certify separation
    // with triangle/box SAT plus a containment test. Keep every obstacle in the
    // fitter if any box intersects, since bending can enter another obstacle.
    bool needsFit=false;for(const auto& shape:obstacles){Bounds box;for(unsigned k=0;k<8;++k)box.include(shape.transform.inversePoint({k&1?source.bounds.hi.x:source.bounds.lo.x,k&2?source.bounds.hi.y:source.bounds.lo.y,k&4?source.bounds.hi.z:source.bounds.lo.z}));++pose.separationQueries;
        if(shape.geometry->overlapsSolid(box.expanded((clearance+1e-5)/shape.transform.scale()))){needsFit=true;break;}}
    if(!needsFit){pose.queries=world.calls()+coverageQueries+pose.separationQueries;return pose;}
    v::SolveOptions options;options.limits={4096,32,64,12000,240,2000000,4000000,128*1024*1024};options.tolerances={1e-7,1e-8,.002,.003,1e-6};
    options.clearance_m=clearance+1e-5;options.rest_shape_weight=.002+.008*stiffness;options.bend_weight=.2+.8*stiffness;options.root_angle_weight=0;
    for(unsigned index:prepared.order){if(blocked[source.guideRoot[index]])continue;const auto& guide=prepared.guides[index];auto rest=guide.rest;bool inherited=false;
        if(guide.parent>=0&&pose.guides[guide.parent]){auto delta=stem::transform(prepared.guides[guide.parent].rest,*pose.guides[guide.parent],guide.parentSpan,guide.parentU);
            for(auto& q:rest.nodes)q=stem::apply(delta,q);for(auto& q:rest.material_frames)q=f::qnormal(f::product(delta.q,q));inherited=true;}
        if(intersects(rest,obstacles,options.clearance_m)){
            bool contact=false,basalContact=false;for(unsigned k=0;k+1<rest.nodes.size();++k){auto hit=world.query_capsule({rest.guide_id,rest.span_ids[k],rest.nodes[k],rest.nodes[k+1],rest.span_radius_m[k],options.clearance_m},{});
                if(hit.outcome!=v::Outcome::Ok||!hit.complete)throw std::runtime_error("Incomplete guide contact query");for(const auto& c:hit.contacts)if(c.signed_gap_m< -options.tolerances.penetration_m){contact=true;basalContact|=k==0;}}
            if(contact){if(++pose.activeGuides>512)throw std::runtime_error("Active interaction guide budget exceeded");
                // A planted tube's whole basal ring is fixed in the delivered
                // mesh. Preserve its first span/frame when that span is clear;
                // overriding only its ring vertices after rotating the frame
                // creates a skin tear. A collider crossing this span needs the
                // position-only fit instead of an impossible fixed-span solve.
                // Folded blades retain their separately tested flexible base.
                bool clampBase=guide.parent<0&&!basalContact&&source.report.value("profile",std::string{})!="Ordered three-vertex folded blades";
                options.root_mode=clampBase?v::RootMode::ClampFrame:v::RootMode::PositionOnly;options.max_proposal_step_m=std::max(.002,length(sub(rest.nodes.back(),rest.nodes.front()))/12.);
                v::SolveResult fit;
                bool hingeClear=boundedHinge(rest,obstacles,world,options.clearance_m,fit.pose,clampBase);
                // A clear basal span can still block every clamped rotation
                // through its conservative attached-foliage envelope. Relax
                // its direction only after the clamped search proves unable
                // to clear, and freshly validate the position-only candidate.
                if(!hingeClear&&clampBase){clampBase=false;options.root_mode=v::RootMode::PositionOnly;hingeClear=boundedHinge(rest,obstacles,world,options.clearance_m,fit.pose);}
                if(hingeClear){fit.status=v::SolveStatus::ConvergedCandidate;++pose.hinges;}
                else {fit=v::fit_rooted_guide(rest,generation,world,options,{});pose.iterations+=fit.metrics.iterations;}
                if(fit.status!=v::SolveStatus::ConvergedCandidate){
                    if((fit.status==v::SolveStatus::UnresolvedContact||fit.status==v::SolveStatus::WorkLimit||fit.status==v::SolveStatus::RootConflict)&&boundedHinge(rest,obstacles,world,options.clearance_m,fit.pose,clampBase))++pose.hinges;
                    else {std::string message="Rooted mesh contact did not converge for guide "+std::to_string(index)+" (status "+std::to_string(int(fit.status))+")";for(const auto& issue:fit.issues)message+=" "+issue.code;
                        message+=" parent="+std::to_string(guide.parent)+" radius="+std::to_string(rest.span_radius_m.front());
                        auto rootReport=world.classify_point(rest.nodes.front(),rest.span_radius_m.front()+options.clearance_m,{});for(const auto& h:rootReport.hits)message+=" root_gap="+std::to_string(h.signed_gap_m);
                        if(guide.parent>=0){const auto& parent=prepared.guides[guide.parent].rest;const auto* posed=pose.guides[guide.parent].get();const auto& nodes=posed?posed->nodes:parent.nodes;auto span=guide.parentSpan;
                            auto result=world.query_capsule({parent.guide_id,parent.span_ids[span],nodes[span],nodes[span+1],parent.span_radius_m[span],options.clearance_m},{});message+=" parent_radius="+std::to_string(parent.span_radius_m[span])+" parent_moved="+std::to_string(bool(posed));for(const auto& c:result.contacts)message+=" parent_gap="+std::to_string(c.signed_gap_m);}
                        throw std::runtime_error(message);}}
                const auto frames=g::check_frames(fit.pose.nodes,fit.pose.material_frames,rest.span_ids,options.tolerances.frame_radians,false);
                if(frames.state!=g::FrameCheck::State::Ok)throw std::runtime_error("Contact pose material frames do not follow their guide tangents");
                pose.guides[index]=std::make_shared<v::GuidePose>(std::move(fit.pose));pose.changed=true;continue;}}
        if(inherited){pose.guides[index]=std::make_shared<v::GuidePose>(v::GuidePose{rest.guide_id,std::move(rest.nodes),std::move(rest.material_frames)});pose.changed=true;}}
    for(unsigned i=0;i<prepared.parts.size();++i){const auto& part=prepared.parts[i];if(!part.stem&&pose.guides[part.guide])pose.rigid.emplace(i,stem::transform(prepared.guides[part.guide].rest,*pose.guides[part.guide],part.span,part.u));}
    pose.queries=world.calls()+coverageQueries+pose.separationQueries;pose.bytes=sizeof(Pose)+pose.guides.capacity()*sizeof(pose.guides[0])+(pose.hiddenRoots.capacity()+7)/8+pose.rigid.size()*(sizeof(unsigned)+sizeof(stem::Rigid)+4*sizeof(void*))+pose.rigid.bucket_count()*sizeof(void*);
    for(const auto& guide:pose.guides)if(guide)pose.bytes+=sizeof(v::GuidePose)+guide->nodes.capacity()*sizeof(Vec)+guide->material_frames.capacity()*sizeof(v::Quat);
    return pose;
}
Vec posePoint(const Source& source,const Pose& pose,unsigned vertex){
    const auto& p=*source.rig;if(source.anchors.at(vertex))return p.positions.at(vertex);const auto& binding=p.bindings.at(vertex);const auto& part=p.parts[binding.part];
    if(!part.stem){auto found=pose.rigid.find(binding.part);return found==pose.rigid.end()?p.positions[vertex]:stem::apply(found->second,p.positions[vertex]);}
    if(!pose.guides[part.guide])return p.positions[vertex];const auto& guide=*pose.guides[part.guide];auto q=g::shortest_slerp(guide.material_frames[binding.span],guide.material_frames[binding.span+1],binding.u);
    if(!q)throw std::runtime_error("Invalid interaction material frame");return add(f::lerp(guide.nodes[binding.span],guide.nodes[binding.span+1],binding.u),f::rotate(*q,binding.offset));
}
bool visibleFace(const Source& source,const Pose& pose,unsigned face){if(pose.allHidden)return false;const auto& t=source.rig->triangles.at(face);for(auto v:t)if(pose.hiddenRoots[source.partRoot[source.labels[v]]])return false;return true;}
Vec poseDirection(const Source& source,const Pose& pose,unsigned vertex,Vec direction){
    const auto& p=*source.rig;if(source.anchors.at(vertex))return direction;const auto& binding=p.bindings.at(vertex);const auto& part=p.parts[binding.part];
    if(!part.stem){auto found=pose.rigid.find(binding.part);return found==pose.rigid.end()?direction:f::rotate(found->second.q,direction);}
    if(!pose.guides[part.guide])return direction;const auto& rest=p.guides[part.guide].rest;const auto& posed=*pose.guides[part.guide];
    const auto a=g::shortest_slerp(rest.material_frames[binding.span],rest.material_frames[binding.span+1],binding.u),b=g::shortest_slerp(posed.material_frames[binding.span],posed.material_frames[binding.span+1],binding.u);
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
