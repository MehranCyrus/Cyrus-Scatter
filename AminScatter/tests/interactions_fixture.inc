// Bounded diagnostic replay of numeric data captured from an owned Max scene.
// It exercises the same Engine; it does not establish Max frame/render timings.
#include <chrono>
#include <algorithm>
#include <cstring>
#include "execution.h"
prep::Snapshot fixtureMesh(const std::string& path){
    std::ifstream in(path,std::ios::binary);unsigned header[4]{};in.read(reinterpret_cast<char*>(header),sizeof(header));
    require(header[0]==0x53544c32u&&header[1]<=1000000&&header[2]<=2000000,"Fixture source admission");prep::Snapshot source;source.positions.resize(header[1]);source.faces.resize(header[2]);source.materials.resize(header[2]);
    in.read(reinterpret_cast<char*>(source.positions.data()),source.positions.size()*12);in.read(reinterpret_cast<char*>(source.faces.data()),source.faces.size()*12);in.read(reinterpret_cast<char*>(source.materials.data()),source.materials.size()*4);require(bool(in),"Fixture source payload");return source;
}
// Stable diagnostic digest of the numerical pose, independent of unordered
// container iteration, to compare serial and multi-worker fixture outputs.
std::uint64_t fixturePoseDigest(const Snapshot& state){
    std::uint64_t hash=1469598103934665603ull;auto integer=[&](std::uint64_t n){for(unsigned i=0;i<8;++i){hash^=(n>>(8*i))&255;hash*=1099511628211ull;}};
    auto real=[&](double value){std::uint64_t bits;std::memcpy(&bits,&value,sizeof(bits));integer(bits);};
    std::vector<std::size_t> indices;for(const auto& [index,pose]:state.poses){(void)pose;indices.push_back(index);}std::sort(indices.begin(),indices.end());
    for(auto index:indices){const auto& p=*state.poses.at(index);integer(index);integer(p.allHidden);integer(p.guides.size());
        for(bool hidden:p.hiddenRoots)integer(hidden);for(bool smooth:p.smoothedRoots)integer(smooth);
        for(const auto& guide:p.guides){integer(bool(guide));if(!guide)continue;integer(guide->guide_id);
            for(auto v:guide->nodes){real(v.x);real(v.y);real(v.z);}for(auto q:guide->material_frames){real(q.x);real(q.y);real(q.z);real(q.w);}}
        std::vector<unsigned> parts;for(const auto& [part,rigid]:p.rigid){(void)rigid;parts.push_back(part);}std::sort(parts.begin(),parts.end());
        for(auto part:parts){const auto& x=p.rigid.at(part);integer(part);real(x.q.x);real(x.q.y);real(x.q.z);real(x.q.w);real(x.shift.x);real(x.shift.y);real(x.shift.z);}}
    std::vector<std::size_t> retained;for(const auto& [index,count]:state.retainedRootCounts){(void)count;retained.push_back(index);}std::sort(retained.begin(),retained.end());
    for(auto index:retained){integer(index);integer(state.retainedRootCounts.at(index));}return hash;
}
int fixtureColliderChecks(const char* path){
    auto raw=fixtureMesh(path);std::vector<Vec> points;for(auto p:raw.positions)points.push_back({p[0],p[2],-p[1]});
    MeshGeometry geometry(std::move(points),std::move(raw.faces));const auto bounds=geometry.bounds();const auto size=sub(bounds.hi,bounds.lo);
    unsigned seed=0x6ac138f1u;auto random=[&]{seed=1664525u*seed+1013904223u;return double(seed)/4294967295.;};
    auto point=[&]{return Vec{bounds.lo.x+size.x*(random()*1.4-.2),bounds.lo.y+size.y*(random()*1.4-.2),bounds.lo.z+size.z*(random()*1.4-.2)};};
    for(unsigned i=0;i<6000;++i){const auto p=point();const double scale=i%2?.1:10.,band=i%3==0?1e-5:i%3==1?.001:.05;
        require(geometry.occupied(p,scale,band)==(geometry.point(p).gap*scale<band),"Captured collider occupancy disagrees with the independent signed distance");
        const auto b=point(),c=point();require(geometry.triangleNear(p,b,c,band)==(geometry.triangleDistance(p,b,c,band)<band),"Captured collider face predicate disagrees with bounded distance");
        require(geometry.segmentNear(p,b,band)==(geometry.segment(p,b).gap<band),"Captured collider segment predicate disagrees with independent witness");}
    std::cout<<Json{{"scope","Captured collider numeric predicate comparison"},{"trials",6000},{"triangles",raw.materials.size()},{"status","pass"}}.dump()<<'\n';return 0;
}
int fixtureRootDiagnostic(const char* path,unsigned guideIndex){
    std::ifstream in(path);auto file=Json::parse(in);Layout layout;layout.metresPerUnit=file.at("metres_per_unit");std::size_t plant=SIZE_MAX,obstacle=SIZE_MAX;
    for(const auto& item:file.at("instances")){Instance v;v.layer=item.at("layer");v.source=item.at("source");v.identity=item.at("identity");v.hostTransform=item.at("transform").get<std::array<float,12>>();
        const auto role=file.at("layers")[v.layer].at("role").get<unsigned>();if(role==2)plant=layout.instances.size();if(role==1)obstacle=layout.instances.size();layout.instances.push_back(std::move(v));}
    require(plant!=SIZE_MAX&&obstacle!=SIZE_MAX,"Root diagnostic requires plant and obstacle");
    const auto& plantEntry=file.at("layers")[layout.instances[plant].layer]["sources"][layout.instances[plant].source];auto raw=fixtureMesh(plantEntry.at("mesh"));
    std::ifstream definition(plantEntry.at("definition").get<std::string>());auto saved=Json::parse(definition);auto settings=saved.at("settings");auto body=saved.at("source");
    auto source=prepareSource(raw,{settings[0],settings[1]},&body);require(guideIndex<source->rig->guides.size(),"Unknown root guide");
    const auto& colliderEntry=file.at("layers")[layout.instances[obstacle].layer]["sources"][layout.instances[obstacle].source];auto collider=fixtureMesh(colliderEntry.at("mesh"));std::vector<Vec> vertices;
    for(auto p:collider.positions)vertices.push_back({p[0],p[2],-p[1]});auto mesh=std::make_shared<MeshGeometry>(std::move(vertices),std::move(collider.faces));
    auto p=layout.transform(plant),o=layout.transform(obstacle);Transform tm;for(int k=0;k<3;++k)tm.rows[k]=p.inverseVector(o.rows[k]);tm.rows[3]=p.inversePoint(o.rows[3]);const double scale=tm.scale();
    const auto& rig=*source->rig;const auto& guide=rig.guides[guideIndex];Json result={{"guide",guideIndex},{"parent",guide.parent},{"anchors",Json::array()},{"fixed_edges",Json::array()},{"fixed_faces",Json::array()},
        {"root_centre_gap_m",mesh->point(tm.inversePoint(guide.rest.nodes.front())).gap*scale},{"root_envelope_radius_m",guide.rest.span_radius_m.front()}};
    for(auto vertex:guide.anchors)result["anchors"].push_back({{"vertex",vertex},{"gap_m",mesh->point(tm.inversePoint(rig.positions[vertex])).gap*scale}});
    const double band=1e-5/scale;
    for(auto fi:source->guideFaces[guideIndex]){const auto tri=rig.triangles[fi];unsigned anchorCount=0;for(auto v:tri)anchorCount+=source->anchors[v];
        for(unsigned k=0;k<3;++k){const auto a=tri[k],b=tri[(k+1)%3];if(!source->anchors[a]||!source->anchors[b])continue;auto hit=mesh->contactSegment(tm.inversePoint(rig.positions[a]),tm.inversePoint(rig.positions[b]),band);
            if(hit&&hit->gap*scale<1e-5)result["fixed_edges"].push_back({{"face",fi},{"a",a},{"b",b},{"gap_m",hit->gap*scale}});}
        if(anchorCount==3&&mesh->triangleNear(tm.inversePoint(rig.positions[tri[0]]),tm.inversePoint(rig.positions[tri[1]]),tm.inversePoint(rig.positions[tri[2]]),band))result["fixed_faces"].push_back(fi);}
    std::cout<<result.dump(2)<<'\n';return 0;
}
// Optional diagnostic for an owned real-model replay. Report the actual worst
// edges and their bindings so a large ratio on a tiny edge can be distinguished
// from a visible displacement. This never runs on the product/viewport path.
Json fixtureStrain(const Layout& layout,const Snapshot& state){
    Json output=Json::array();
    for(const auto& [index,pose]:state.poses){
        const auto& actor=layout.instances.at(index);const auto& source=*layout.sources.at(actor.layer).at(actor.source)->rig;const auto& rig=*source.rig;
        std::vector<Vec> points(rig.positions.size());for(unsigned i=0;i<points.size();++i)points[i]=posePoint(source,*pose,i);
        struct Edge {double strain,rest,after;unsigned face,a,b;};std::vector<Edge> worst;std::size_t over=0;
        for(unsigned face=0;face<rig.triangles.size();++face){if(!visibleFace(source,*pose,face))continue;const auto tri=rig.triangles[face];
            for(unsigned k=0;k<3;++k){auto a=tri[k],b=tri[(k+1)%3];if(!rig.parts[source.labels[a]].stem)continue;
                const double rest=length(sub(rig.positions[a],rig.positions[b]));if(rest<1e-6)continue;
                const double after=length(sub(points[a],points[b])),strain=std::abs(after/rest-1);if(strain>.25)++over;
                if(worst.size()<12||strain>worst.back().strain){worst.push_back({strain,rest,after,face,a,b});
                    std::sort(worst.begin(),worst.end(),[](const Edge& x,const Edge& y){return x.strain>y.strain;});if(worst.size()>12)worst.pop_back();}}
        }
        auto vertex=[&](unsigned i){const auto& binding=rig.bindings[i];const auto& part=rig.parts[binding.part];auto original=rig.positions[i],now=points[i];
            return Json{{"vertex",i},{"anchor",source.anchors[i]},{"part",binding.part},{"guide",part.guide},{"span",binding.span},{"u",binding.u},
                {"rest",{original.x,original.y,original.z}},{"posed",{now.x,now.y,now.z}}};};
        Json record={{"instance",index},{"identity",actor.identity},{"triangle_edges_above_25_percent",over},{"worst",Json::array()}};
        for(const auto& edge:worst)record["worst"].push_back({{"strain",edge.strain},{"rest_m",edge.rest},{"posed_m",edge.after},{"absolute_change_m",std::abs(edge.after-edge.rest)},
            {"face",edge.face},{"a",vertex(edge.a)},{"b",vertex(edge.b)}});
        output.push_back(std::move(record));
    }
    return output;
}
Json fixtureCompactAudit(const Layout& layout,const Snapshot& state,const std::string& exportPath={}){
    std::size_t corners=0,triangles=0;double maximum=0;bool exported=false;
    for(const auto& [index,pose]:state.poses){const auto& actor=layout.instances.at(index);const auto source=layout.sources.at(actor.layer).at(actor.source)->rig;
        const auto data=deformationSource(source);const auto words=deformationPose(*data,*pose);std::vector<DeformationWord> expected;expected.reserve(data->faces.size()*3);
        for(unsigned face=0;face<data->faces.size();++face){auto fi=data->faces[face];bool visible=visibleFace(*source,*pose,fi);require(visible==deformationVisible(*data,words,face),"Real-model compact visibility differs");++triangles;
            for(unsigned k=0;k<3;++k){auto value=deformationPoint(*data,words,face,k),canonical=posePoint(*source,*pose,source->rig->triangles[fi][k]);maximum=std::max(maximum,length(sub(value,canonical)));++corners;
                expected.push_back({float(canonical.x),float(canonical.y),float(canonical.z),visible?1.f:0.f});}}
        if(!exported&&!exportPath.empty()){std::ofstream out(exportPath,std::ios::binary);unsigned header[]{0x43504731u,unsigned(data->corners.size()),unsigned(words.size()),unsigned(expected.size())};out.write(reinterpret_cast<const char*>(header),sizeof(header));
            auto write=[&](const auto& buffer){out.write(reinterpret_cast<const char*>(buffer.data()),buffer.size()*sizeof(DeformationWord));};write(data->corners);write(words);write(expected);require(bool(out),"GPU comparison fixture write failed");exported=true;}
    }
    require(maximum<2e-6,"Real-model compact pose exceeds two micrometre source-space difference");return {{"corners",corners},{"triangles",triangles},{"maximum_source_error_m",maximum},{"exported",exported}};
}
int fixtureBenchmark(const char* path,unsigned steps){
    using Clock=std::chrono::steady_clock;auto started=Clock::now();std::ifstream input(path);auto file=Json::parse(input);require(file.at("instances").size()<=1000000&&file.at("layers").size()<=10&&steps<=100,"Fixture layout admission");
    amin::setComputeThreads(file.value("diagnostic_compute_threads",0u));
    auto layout=std::make_shared<Layout>();layout->metresPerUnit=file.at("metres_per_unit");std::size_t obstacle=SIZE_MAX;
    for(const auto& layer:file.at("layers")){unsigned role=layer.at("role");layout->layers.push_back({bool(role&1),bool(role&2),layer.at("cover"),layer.at("gap"),layer.at("stiffness"),layer.value("hide_margin",0.),layer.value("hide_under",false)});std::vector<std::shared_ptr<const Definition>> sources;
        for(const auto& entry:layer.at("sources")){auto data=fixtureMesh(entry.at("mesh"));auto definition=std::make_shared<Definition>();
            if(entry.at("kind")=="plant"){std::ifstream savedFile(entry.at("definition").get<std::string>());auto saved=Json::parse(savedFile);auto settings=saved.at("settings");auto body=saved.at("source");prep::Settings cfg{settings[0],settings[1]};cfg.connectionReach=saved.value("connection_reach_m",.15);
                if(entry.contains("preparation_limits")){auto p=entry.at("preparation_limits");require(p.size()==7,"Captured preparation limits differ");cfg.limits={p[0],p[1],p[2],p[3],p[4],p[5],p[6]};}
                definition->rig=prepareSource(data,cfg,&body);definition->geometryBounds=definition->rig->bounds;}
            else{std::vector<Vec> points;for(auto p:data.positions)points.push_back({p[0],p[2],-p[1]});definition->collider=std::make_shared<MeshGeometry>(std::move(points),std::move(data.faces));definition->geometryBounds=definition->collider->bounds();}sources.push_back(std::move(definition));}
        layout->sources.push_back(std::move(sources));}
    for(const auto& row:file.at("instances")){Instance value;value.layer=row.at("layer");value.source=row.at("source");value.row=unsigned(layout->instances.size());value.identity=row.at("identity");value.hostTransform=row.at("transform").get<std::array<float,12>>();if(layout->layers.at(value.layer).obstacle&&obstacle==SIZE_MAX)obstacle=layout->instances.size();layout->instances.push_back(std::move(value));}
    require(obstacle!=SIZE_MAX,"Fixture has a movable collider");Engine engine(layout);const double prepare=std::chrono::duration<double,std::milli>(Clock::now()-started).count();auto state=engine.evaluate({});auto initial=statisticsJson(state->statistics);initial["pose_digest_fnv64"]=std::to_string(fixturePoseDigest(*state));Json result={{"scope","Captured numeric kernel replay; not Max presented FPS"},{"diagnostic_compute_threads",amin::computeThreads()},{"prepare_and_index_ms",prepare},{"initial",initial},{"steps",Json::array()}};
    if(file.value("expect_quality_warning",false))require(state->statistics.qualityWarningGuides>0&&state->statistics.maximumCheckedStemEdgeChange>.25,"Captured deformed guide must report a scoped quality warning");
    if(file.value("compact_audit",false))result["compact_audit"]=fixtureCompactAudit(*layout,*state,file.value("compact_export",std::string{}));
    const auto original=layout->transform(obstacle);std::vector<double> times;
    for(unsigned step=0;step<steps;++step){auto tm=original;tm.rows[3].x+=.02*double(step+1);state=engine.evaluate(state,{{obstacle,tm}},{obstacle});auto statistics=statisticsJson(state->statistics);statistics["pose_digest_fnv64"]=std::to_string(fixturePoseDigest(*state));result["steps"].push_back(std::move(statistics));times.push_back(state->statistics.totalMs);}
    if(!times.empty()){std::sort(times.begin(),times.end());result["median_step_ms"]=times[times.size()/2];result["worst_step_ms"]=times.back();}
    if(file.value("audit",false))result["full_mesh_audit"]=engine.audit(*state,20000000);
    if(file.value("strain_diagnostics",false))result["strain_diagnostics"]=fixtureStrain(*layout,*state);
    if(file.contains("delivery_mesh")){
        auto delivered=fixtureMesh(file.at("delivery_mesh"));std::vector<Vec> vertices;for(auto p:delivered.positions)vertices.push_back({p[0],p[2],-p[1]});
        std::size_t inside=0,touching=0;double minimum=1e100;
        for(unsigned i=0;i<layout->instances.size();++i){const auto& actor=layout->instances[i];if(!layout->layers[actor.layer].obstacle)continue;const auto& shape=*layout->sources[actor.layer][actor.source]->collider;auto tm=layout->transform(i);const double scale=tm.scale();
            for(auto p:vertices){double gap=shape.point(tm.inversePoint(p)).gap*scale;minimum=std::min(minimum,gap);inside+=gap< -1e-6;}
            for(auto tri:delivered.faces){double gap=shape.triangleDistance(tm.inversePoint(vertices[tri[0]]),tm.inversePoint(vertices[tri[1]]),tm.inversePoint(vertices[tri[2]]))*scale;minimum=std::min(minimum,gap);touching+=gap<1e-7;}}
        result["delivery_audit"]={{"scope","Actual native Bake mesh exported in world SI float coordinates by the private Max inspector"},{"triangles",delivered.faces.size()},{"penetrating_vertex_obstacle_pairs",inside},{"touching_triangle_obstacle_pairs",touching},{"minimum_surface_gap_m",minimum}};
    }
    std::cout<<result.dump(2)<<'\n';return 0;
}
