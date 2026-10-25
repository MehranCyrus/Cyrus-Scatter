#include "lab_core.hpp"
#include <algorithm>
#include <cmath>
#include <limits>
#include <stdexcept>

namespace cvl {
namespace {
using Vec=v::Vec3;
bool finite(Vec p) {return std::isfinite(p.x)&&std::isfinite(p.y)&&std::isfinite(p.z);}
Vec add(Vec a,Vec b){return {a.x+b.x,a.y+b.y,a.z+b.z};}
Vec sub(Vec a,Vec b){return {a.x-b.x,a.y-b.y,a.z-b.z};}
Vec cross(Vec a,Vec b){return {a.y*b.z-a.z*b.y,a.z*b.x-a.x*b.z,a.x*b.y-a.y*b.x};}
double norm(Vec a){return std::hypot(a.x,a.y,a.z);}
void unitAdmission(double unit){if(!std::isfinite(unit)||unit<1e-9||unit>1000)throw std::runtime_error("Unsupported scene system units.");}
std::string issues(const std::vector<v::Issue>& rows) {
    std::string out;for(std::size_t i=0;i<std::min<std::size_t>(rows.size(),3);++i)out+=rows[i].code+": "+rows[i].message+" ";return out;
}
std::shared_ptr<const Patch> prepare(int count) {
    if(count<1||count>maxBlades)throw std::runtime_error("Choose between 1 and 21 demo blades.");
    auto p=std::make_shared<Patch>();p->blades.reserve(count);
    for(int blade=0;blade<count;++blade) {
        PreparedBlade b;auto& g=b.rest;auto& s=b.source;
        g.guide_id=std::uint64_t(blade+1);g.source_revision=1;
        s.source_id=1000+g.guide_id;s.source_revision=1;
        const double depth=.02*(double(blade)-double(count-1)/2.0);
        for(std::uint64_t row=0;row<9;++row) {
            g.node_ids.push_back(g.guide_id*1000+row+1);g.nodes.push_back({-.2,.075*double(row),depth});
            g.material_frames.push_back({-std::sqrt(.5),0,0,std::sqrt(.5)});
            if(row<8){g.span_ids.push_back(g.guide_id*100+row+1);g.span_radius_m.push_back(.015);g.max_bound_offset_m.push_back(.015);}
        }
        for(std::size_t row=0;row<9;++row)for(std::size_t side=0;side<2;++side) {
            const double halfWidth=.015*(1.-.95*std::pow(double(row)/8.,1.5));
            const double x=side?halfWidth:-halfWidth;const auto id=g.guide_id*10000+row*2+side+1;
            s.rest_positions.push_back({-.2+x,.075*double(row),depth});
            s.bindings.push_back({id,id,g.span_ids[std::min<std::size_t>(row,7)],row==8?1.:0.,{x,0,0},{double(side),double(row)/8.}});
        }
        for(std::uint32_t row=0;row<8;++row) {
            auto a=row*2;s.triangles.push_back({a,a+1,a+2});s.triangles.push_back({a+1,a+3,a+2});
            s.face_material_ids.push_back(0);s.face_material_ids.push_back(0);
        }
        p->blades.push_back(std::move(b));
    }
    return p;
}
void quantize(v::EvaluatedMesh& mesh,double unit) {
    for(auto& p:mesh.positions) {
        auto h=coreToHost(p,unit);
        h={double(float(h.x)),double(float(h.y)),double(float(h.z))};
        p=hostToCore(h,unit);if(!finite(p))throw std::runtime_error("Max mesh float conversion overflowed.");
    }
    mesh.normals.assign(mesh.positions.size(),{});
    for(auto t:mesh.triangles) {
        auto n=cross(sub(mesh.positions[t[1]],mesh.positions[t[0]]),sub(mesh.positions[t[2]],mesh.positions[t[0]]));
        for(auto i:t)mesh.normals[i]=add(mesh.normals[i],n);
    }
    for(auto& n:mesh.normals){const double d=norm(n);if(!(d>0)||!std::isfinite(d))throw std::runtime_error("Undefined delivered geometric normal.");n={n.x/d,n.y/d,n.z/d};}
    mesh.bounds_min=mesh.bounds_max=mesh.positions.front();
    for(auto p:mesh.positions) {
        mesh.bounds_min={std::min(mesh.bounds_min.x,p.x),std::min(mesh.bounds_min.y,p.y),std::min(mesh.bounds_min.z,p.z)};
        mesh.bounds_max={std::max(mesh.bounds_max.x,p.x),std::max(mesh.bounds_max.y,p.y),std::max(mesh.bounds_max.z,p.z)};
    }
}
void deliver(State& state) {
    if(!state.prepared||state.poses.size()!=state.prepared->blades.size())throw std::runtime_error("Invalid lab pose count.");
    state.meshes.clear();state.meshes.reserve(state.poses.size());
    const auto target=options(state.clearance,state.clamp);
    for(std::size_t i=0;i<state.poses.size();++i) {
        const auto& source=state.prepared->blades[i];
        auto e=v::evaluate_ribbon(source.source,source.rest,state.poses[i],target.limits,target.tolerances,{});
        if(e.outcome!=v::Outcome::Ok)throw std::runtime_error("Ribbon evaluation failed: "+issues(e.issues));
        quantize(e.mesh,state.metersPerUnit);
        auto check=v::validate_candidate(state.snapshot,source.source,source.rest,state.poses[i],e.mesh,target,{});
        if(check.status!=v::ValidationStatus::Pass)throw std::runtime_error("Delivered visible mesh rejected: "+issues(check.issues));
        state.metrics.root=std::max(state.metrics.root,check.max_root_error_m);
        state.metrics.length=std::max(state.metrics.length,check.max_relative_length_error);
        state.metrics.penetration=std::max(state.metrics.penetration,check.max_visible_penetration_m);
        state.meshes.push_back(std::move(e.mesh));
    }
}
Json vec(Vec p){return Json::array({p.x,p.y,p.z});}
Vec readVec(const Json& j){if(!j.is_array()||j.size()!=3)throw std::runtime_error("Invalid saved vector.");Vec p{j[0].get<double>(),j[1].get<double>(),j[2].get<double>()};if(!finite(p))throw std::runtime_error("Nonfinite saved vector.");return p;}
}
v::Vec3 coreToHost(v::Vec3 p,double unit){return {p.x/unit,-p.z/unit,p.y/unit};}
v::Vec3 hostToCore(v::Vec3 p,double unit){return {p.x*unit,p.z*unit,-p.y*unit};}
v::SolveOptions options(double clearance,bool clamp) {
    if(!std::isfinite(clearance)||clearance<0||clearance>.05)throw std::runtime_error("Clearance must be between 0 and 5 cm.");
    v::SolveOptions o;o.limits={1,64,32,20000,400,10000,20000,8*1024*1024};
    o.tolerances={1e-7,1e-5,.001,.001,1e-6};o.root_mode=clamp?v::RootMode::ClampFrame:v::RootMode::PositionOnly;
    o.clearance_m=clearance;o.rest_shape_weight=.01;o.bend_weight=1;o.root_angle_weight=0;o.max_proposal_step_m=.02;return o;
}
std::shared_ptr<const State> makeRest(int count,double unit,std::uint64_t revision,std::shared_ptr<const Patch> existing) {
    unitAdmission(unit);if(!revision)throw std::runtime_error("Invalid lab generation.");
    auto out=std::make_shared<State>();out->prepared=existing?std::move(existing):prepare(count);
    if(int(out->prepared->blades.size())!=count)throw std::runtime_error("Source count mismatch.");
    out->metersPerUnit=unit;out->revision=revision;out->snapshot.generation=revision;
    for(const auto& blade:out->prepared->blades)out->poses.push_back({blade.rest.guide_id,blade.rest.nodes,blade.rest.material_frames});
    deliver(*out);return out;
}
std::shared_ptr<const State> fit(const State& old,Sphere sphere,double clearance,bool clamp) {
    unitAdmission(old.metersPerUnit);if(!old.prepared||old.revision==std::numeric_limits<std::uint64_t>::max())throw std::runtime_error("Invalid or exhausted lab state.");
    if(!finite(sphere.center)||!std::isfinite(sphere.radius)||sphere.radius<.001||sphere.radius>2||norm(sphere.center)>10)
        throw std::runtime_error("Use a sphere of radius 1 mm to 2 m within 10 m of the grass.");
    auto target=options(clearance,clamp);auto solve=target;solve.clearance_m+=.0001; // Explicit host-float guard.
    auto out=std::make_shared<State>();out->prepared=old.prepared;out->metersPerUnit=old.metersPerUnit;
    out->revision=old.revision+1;out->snapshot.generation=out->revision;out->fitted=true;out->clearance=clearance;out->clamp=clamp;
    v::Obstacle stone;stone.id=1;stone.geometry_revision=1;stone.pose_revision=out->revision;stone.center=sphere.center;stone.sphere_radius=sphere.radius;
    out->snapshot.obstacles.push_back(stone);
    v::BackendOptions backend;backend.limits=target.limits;backend.query_tolerance_m=1e-6;backend.min_supported_feature_m=.001;
    auto world=v::make_jolt_world(out->snapshot,backend,{});
    if(world.outcome!=v::Outcome::Ok||!world.world)throw std::runtime_error("Stone snapshot rejected: "+issues(world.issues));
    for(std::size_t i=0;i<old.prepared->blades.size();++i) {
        if(out->metrics.queries>=target.limits.max_query_calls)throw std::runtime_error("Lab query budget reached; previous result retained.");
        solve.limits.max_query_calls=target.limits.max_query_calls-out->metrics.queries;
        auto result=v::fit_rooted_guide(old.prepared->blades[i].rest,out->revision,*world.world,solve,{});
        if(result.status!=v::SolveStatus::ConvergedCandidate) {
            if(result.status==v::SolveStatus::RootConflict)throw std::runtime_error("Blade "+std::to_string(i+1)+": stone blocks the planted root or locked base. Move the stone away from the roots or unlock base direction. Previous result retained.");
            throw std::runtime_error("Blade "+std::to_string(i+1)+" did not converge: "+issues(result.issues)+"Previous result retained.");
        }
        if(result.generation!=out->revision||result.source_revision!=1)throw std::runtime_error("Stale guide candidate rejected.");
        out->metrics.queries+=result.metrics.query_calls;out->metrics.iterations+=result.metrics.iterations;
        out->poses.push_back(std::move(result.pose));
    }
    deliver(*out);return out;
}
std::string encode(const State& s) {
    Json j={{"schema",1},{"version","0.1.0"},{"core",CVL_CORE_ID},{"unit",s.metersPerUnit},{"revision",s.revision},
        {"count",s.prepared->blades.size()},{"fitted",s.fitted},{"clearance",s.clearance},{"clamp",s.clamp},{"poses",Json::array()}};
    if(s.fitted){const auto& o=s.snapshot.obstacles.at(0);j["stone"]={{"center",vec(o.center)},{"radius",o.sphere_radius}};}
    for(const auto& pose:s.poses){Json p={{"id",pose.guide_id},{"nodes",Json::array()},{"frames",Json::array()}};for(auto x:pose.nodes)p["nodes"].push_back(vec(x));for(auto q:pose.material_frames)p["frames"].push_back(Json::array({q.x,q.y,q.z,q.w}));j["poses"].push_back(std::move(p));}
    auto bytes=j.dump();if(bytes.size()>maxSerializedBytes)throw std::runtime_error("Lab save payload exceeded 2 MiB.");return bytes;
}
std::shared_ptr<const State> decode(std::string_view bytes) {
    if(bytes.size()>maxSerializedBytes)throw std::runtime_error("Lab saved payload exceeded 2 MiB.");
    const auto j=Json::parse(bytes.begin(),bytes.end(),[](int depth,Json::parse_event_t,Json&){if(depth>32)throw std::runtime_error("Lab JSON nesting limit.");return true;});
    if(j.at("schema")!=1||j.at("version")!="0.1.0"||j.at("core")!=CVL_CORE_ID)throw std::runtime_error("Unsupported lab scene/core identity.");
    const int count=j.at("count").get<int>();auto out=std::make_shared<State>();out->prepared=prepare(count);
    out->metersPerUnit=j.at("unit").get<double>();unitAdmission(out->metersPerUnit);
    out->revision=j.at("revision").get<std::uint64_t>();if(!out->revision)throw std::runtime_error("Invalid saved generation.");
    out->snapshot.generation=out->revision;out->fitted=j.at("fitted").get<bool>();out->clearance=j.at("clearance").get<double>();out->clamp=j.at("clamp").get<bool>();options(out->clearance,out->clamp);
    if(out->fitted){v::Obstacle stone;stone.id=1;stone.geometry_revision=1;stone.pose_revision=out->revision;stone.center=readVec(j.at("stone").at("center"));stone.sphere_radius=j.at("stone").at("radius").get<double>();if(!std::isfinite(stone.sphere_radius)||stone.sphere_radius<.001||stone.sphere_radius>2||norm(stone.center)>10)throw std::runtime_error("Invalid saved stone.");out->snapshot.obstacles.push_back(stone);}
    if(!j.at("poses").is_array()||j.at("poses").size()!=std::size_t(count))throw std::runtime_error("Invalid saved pose count.");
    for(std::size_t i=0;i<std::size_t(count);++i) {
        const auto& p=j.at("poses")[i];v::GuidePose pose;pose.guide_id=p.at("id").get<v::Id>();
        if(p.at("nodes").size()!=9||p.at("frames").size()!=9)throw std::runtime_error("Invalid saved guide arrays.");
        for(const auto& x:p.at("nodes"))pose.nodes.push_back(readVec(x));
        for(const auto& q:p.at("frames")){if(!q.is_array()||q.size()!=4)throw std::runtime_error("Invalid saved frame.");pose.material_frames.push_back({q[0].get<double>(),q[1].get<double>(),q[2].get<double>(),q[3].get<double>()});}
        if(!out->fitted){const auto& rest=out->prepared->blades[i].rest;for(std::size_t n=0;n<9;++n){
            if(norm(sub(pose.nodes[n],rest.nodes[n]))>1e-12)throw std::runtime_error("Rest scene contains a deformed pose.");
            const auto a=pose.material_frames[n],b=rest.material_frames[n];
            const double difference=std::min(std::hypot(a.x-b.x,a.y-b.y)+std::hypot(a.z-b.z,a.w-b.w),std::hypot(a.x+b.x,a.y+b.y)+std::hypot(a.z+b.z,a.w+b.w));
            if(!std::isfinite(difference)||difference>1e-12)throw std::runtime_error("Rest scene contains a changed material frame.");
        }}
        out->poses.push_back(std::move(pose));
    }
    deliver(*out);return out;
}
std::size_t estimatedBytes(const State& s) {
    std::size_t total=sizeof(State);
    for(const auto& p:s.poses)total+=sizeof(p)+p.nodes.capacity()*sizeof(v::Vec3)+p.material_frames.capacity()*sizeof(v::Quat);
    for(const auto& m:s.meshes)total+=sizeof(m)+(m.positions.capacity()+m.normals.capacity())*sizeof(v::Vec3)+m.uvs.capacity()*sizeof(v::UV)+m.triangles.capacity()*sizeof(std::array<std::uint32_t,3>)+m.face_material_ids.capacity()*sizeof(std::uint32_t);
    // Shared prepared geometry is conservatively charged once per snapshot for Undo reporting.
    if(s.prepared)for(const auto& b:s.prepared->blades)total+=sizeof(b)+b.rest.nodes.size()*sizeof(v::Vec3)+b.rest.material_frames.size()*sizeof(v::Quat)+b.source.bindings.size()*sizeof(v::BoundVertex)+b.source.rest_positions.size()*sizeof(v::Vec3)+b.source.triangles.size()*sizeof(std::array<std::uint32_t,3>);
    return total;
}
Json summary(const State& s) {
    return {{"version","0.1.0"},{"core",CVL_CORE_ID},{"blades",s.poses.size()},{"vertices",s.poses.size()*18},{"faces",s.poses.size()*16},
        {"revision",s.revision},{"fitted",s.fitted},{"clearance_m",s.clearance},{"clamp",s.clamp},{"meters_per_unit",s.metersPerUnit},
        {"queries",s.metrics.queries},{"iterations",s.metrics.iterations},{"root_error_m",s.metrics.root},{"relative_length_error",s.metrics.length},
        {"visible_penetration_m",s.metrics.penetration},{"estimated_payload_bytes",estimatedBytes(s)}};
}
}
