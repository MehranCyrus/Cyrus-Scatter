// Bounded diagnostic replay of numeric data captured from an owned Max scene.
// It exercises the same Engine; it does not establish Max frame/render timings.
#include <chrono>
#include <algorithm>
prep::Snapshot fixtureMesh(const std::string& path){
    std::ifstream in(path,std::ios::binary);unsigned header[4]{};in.read(reinterpret_cast<char*>(header),sizeof(header));
    require(header[0]==0x53544c32u&&header[1]<=1000000&&header[2]<=2000000,"Fixture source admission");prep::Snapshot source;source.positions.resize(header[1]);source.faces.resize(header[2]);source.materials.resize(header[2]);
    in.read(reinterpret_cast<char*>(source.positions.data()),source.positions.size()*12);in.read(reinterpret_cast<char*>(source.faces.data()),source.faces.size()*12);in.read(reinterpret_cast<char*>(source.materials.data()),source.materials.size()*4);require(bool(in),"Fixture source payload");return source;
}
int fixtureBenchmark(const char* path,unsigned steps){
    using Clock=std::chrono::steady_clock;auto started=Clock::now();std::ifstream input(path);auto file=Json::parse(input);require(file.at("instances").size()<=1000000&&file.at("layers").size()<=10&&steps<=100,"Fixture layout admission");
    auto layout=std::make_shared<Layout>();layout->metresPerUnit=file.at("metres_per_unit");std::size_t obstacle=SIZE_MAX;
    for(const auto& layer:file.at("layers")){unsigned role=layer.at("role");layout->layers.push_back({bool(role&1),bool(role&2),layer.at("cover"),layer.at("gap"),layer.at("stiffness")});std::vector<std::shared_ptr<const Definition>> sources;
        for(const auto& entry:layer.at("sources")){auto data=fixtureMesh(entry.at("mesh"));auto definition=std::make_shared<Definition>();
            if(entry.at("kind")=="plant"){std::ifstream savedFile(entry.at("definition").get<std::string>());auto saved=Json::parse(savedFile);auto settings=saved.at("settings");auto body=saved.at("source");definition->rig=prepareSource(data,{settings[0],settings[1]},&body);definition->geometryBounds=definition->rig->bounds;}
            else{std::vector<Vec> points;for(auto p:data.positions)points.push_back({p[0],p[2],-p[1]});definition->collider=std::make_shared<MeshGeometry>(std::move(points),std::move(data.faces));definition->geometryBounds=definition->collider->bounds();}sources.push_back(std::move(definition));}
        layout->sources.push_back(std::move(sources));}
    for(const auto& row:file.at("instances")){Instance value;value.layer=row.at("layer");value.source=row.at("source");value.row=unsigned(layout->instances.size());value.identity=row.at("identity");value.hostTransform=row.at("transform").get<std::array<float,12>>();if(layout->layers.at(value.layer).obstacle&&obstacle==SIZE_MAX)obstacle=layout->instances.size();layout->instances.push_back(std::move(value));}
    require(obstacle!=SIZE_MAX,"Fixture has a movable collider");Engine engine(layout);const double prepare=std::chrono::duration<double,std::milli>(Clock::now()-started).count();auto state=engine.evaluate({});Json result={{"scope","Captured numeric kernel replay; not Max presented FPS"},{"prepare_and_index_ms",prepare},{"initial",statisticsJson(state->statistics)},{"steps",Json::array()}};
    const auto original=layout->transform(obstacle);std::vector<double> times;
    for(unsigned step=0;step<steps;++step){auto tm=original;tm.rows[3].x+=.02*double(step+1);state=engine.evaluate(state,{{obstacle,tm}},{obstacle});result["steps"].push_back(statisticsJson(state->statistics));times.push_back(state->statistics.totalMs);}
    if(!times.empty()){std::sort(times.begin(),times.end());result["median_step_ms"]=times[times.size()/2];result["worst_step_ms"]=times.back();}
    if(file.value("audit",false))result["full_mesh_audit"]=engine.audit(*state,20000000);
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
