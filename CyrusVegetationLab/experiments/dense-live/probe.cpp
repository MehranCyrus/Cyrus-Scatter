// Private owned-host experiment. No Scatter registration, product installer or persistence.
#include <cyrus_vegetation/prototype_v1.hpp>
#include "geometry.hpp"
#include <nlohmann/json.hpp>
#include <algorithm>
#include <chrono>
#include <memory>
#include <string>
#include <vector>
#include <max.h>
#include <iparamb2.h>
#include <triobj.h>
#include <units.h>
#include <istdplug.h>
#include <notify.h>
#include <maxscript/maxscript.h>
#include <maxscript/foundation/numbers.h>
#include <maxscript/foundation/strings.h>
#include <maxscript/maxwrapper/mxsobjects.h>
#include <maxscript/macros/define_instantiation_functions.h>
static_assert(MAX_PRODUCT_YEAR_NUMBER==2027);
namespace {
namespace v=cyrus::vegetation::prototype_v1;
namespace g=cyrus::vegetation::prototype_v1::delivery_detail;
using Json=nlohmann::json;using Clock=std::chrono::steady_clock;using Time=Clock::time_point;
double ms(Time start){return std::chrono::duration<double,std::milli>(Clock::now()-start).count();}
v::Vec3 vec(Point3 p){return {p.x,p.y,p.z};}
Point3 point(v::Vec3 p){return {float(p.x),float(p.y),float(p.z)};}
v::Vec3 fromHost(Point3 p,double unit){return {p.x*unit,p.z*unit,-p.y*unit};}
Point3 toHost(v::Vec3 p,double unit){return {float(p.x/unit),float(-p.z/unit),float(p.y/unit)};}
std::wstring wide(const std::string& s){int n=MultiByteToWideChar(CP_UTF8,0,s.data(),int(s.size()),nullptr,0);std::wstring out(n,L'\0');MultiByteToWideChar(CP_UTF8,0,s.data(),int(s.size()),out.data(),n);return out;}
Value* text(const Json& j){return new String(wide(j.dump()).c_str());}
template<class F>Value* api(F f){try{return f();}catch(const std::exception& e){throw RuntimeError(wide(e.what()).c_str());}}
std::string issues(const std::vector<v::Issue>& rows){std::string s;for(std::size_t i=0;i<std::min<std::size_t>(rows.size(),3);++i)s+=rows[i].code+": "+rows[i].message+" ";return s;}
struct Model {
    std::unique_ptr<Mesh> mesh;
    v::PreparedRibbon source;v::RestGuide guide;v::GuidePose pose;
    std::vector<v::Vec3> accepted,work;
    double unit=1,height=1,clearance=.001;Point3 origin{};
    std::uint64_t generation=1,attempts=0,successes=0,meshCopies=0,timerCalls=0,unchanged=0;
    std::size_t degenerate=0,unused=0,anchored=0;
    SingleRefMaker target,stone;
    bool watching=false,busy=false;Json lastInput,metrics,cold,history=Json::array();
    double preparationMs=0,lastMeshCopyMs=0;Time inputMark{};
};
std::vector<std::shared_ptr<Model>> models;UINT_PTR timerId=0;bool timerBusy=false;HINSTANCE module=nullptr;
Model& model(Value* value){int i=value->to_int();if(i<1||std::size_t(i)>models.size()||!models[i-1])throw std::runtime_error("Expired private dense-model handle.");return *models[i-1];}
v::SolveOptions options(){v::SolveOptions o;o.limits={1,32,32,40000,800,2000000,4000000,512*1024*1024};o.tolerances={1e-7,1e-5,.001,.001,1e-6};o.clearance_m=.001;o.root_mode=v::RootMode::ClampFrame;o.rest_shape_weight=.01;o.bend_weight=1;o.max_proposal_step_m=.025;return o;}
std::shared_ptr<Model> prepare(INode* node){
    auto started=Clock::now();if(!node)throw std::runtime_error("Missing source node.");
    auto m=std::make_shared<Model>();m->unit=GetSystemUnitScale(UNITS_METERS);
    if(!std::isfinite(m->unit)||m->unit<1e-9||m->unit>1000)throw std::runtime_error("Unsupported scene units.");
    const auto t=GetCOREInterface()->GetTime();auto* object=node->EvalWorldState(t).obj;
    if(!object||!object->CanConvertToType(triObjectClassID))throw std::runtime_error("Source is not triangulatable.");
    auto* tri=static_cast<TriObject*>(object->ConvertToType(t,triObjectClassID));
    try{const auto& input=tri->GetMesh();if(input.numVerts<3||input.numVerts>2000000||input.numFaces<1||input.numFaces>4000000)throw std::runtime_error("Private mesh bound: 2M vertices / 4M triangles.");
        m->mesh=std::make_unique<Mesh>(input);m->mesh->ClearSpecifiedNormals();const auto tm=node->GetObjectTM(t);
        Point3 low(FLT_MAX,FLT_MAX,FLT_MAX),high(-FLT_MAX,-FLT_MAX,-FLT_MAX);
        for(int i=0;i<input.numVerts;++i){auto p=input.verts[i]*tm;if(!g::finite(vec(p)))throw std::runtime_error("Nonfinite source.");for(int k=0;k<3;++k){low[k]=std::min(low[k],p[k]);high[k]=std::max(high[k],p[k]);}m->mesh->verts[i]=p;}
        m->origin={(low.x+high.x)*.5f,(low.y+high.y)*.5f,low.z};m->height=(high.z-low.z)*m->unit;
        if(m->height<.01||m->height>5)throw std::runtime_error("Choose a plant 1 cm to 5 m high.");
        auto& r=m->guide;r.guide_id=1;r.source_revision=1;
        for(int i=0;i<9;++i){r.node_ids.push_back(i+1);r.nodes.push_back({0,m->height*i/8.,0});r.material_frames.push_back({-std::sqrt(.5),0,0,std::sqrt(.5)});if(i<8){r.span_ids.push_back(i+1);r.span_radius_m.push_back(.00001);r.max_bound_offset_m.push_back(0);}}
        auto& s=m->source;s.source_id=1;s.source_revision=1;
        for(int i=0;i<input.numVerts;++i){auto p=fromHost(m->mesh->verts[i]-m->origin,m->unit);s.rest_positions.push_back(p);m->accepted.push_back(p);m->mesh->verts[i]=toHost(p,m->unit);
            const double coordinate=std::clamp(p.y/m->height*8.,0.,8.);const int span=std::min(7,int(coordinate));const double u=coordinate-span;
            const v::Vec3 offset{p.x,-p.z,0};const auto radius=g::length(offset);
            r.span_radius_m[span]=std::max(r.span_radius_m[span],radius+.00001);r.max_bound_offset_m[span]=std::max(r.max_bound_offset_m[span],radius);
            s.bindings.push_back({std::uint64_t(i+1),std::uint64_t(i+1),std::uint64_t(span+1),u,offset,{0,0}});
            if(p.y<=1e-8)++m->anchored;
        }
        std::vector<bool> used(input.numVerts,false);
        for(int i=0;i<input.numFaces;++i){auto f=input.faces[i];std::array<std::uint32_t,3> face{f.v[0],f.v[1],f.v[2]};for(auto vi:face){if(vi>=std::size_t(input.numVerts))throw std::runtime_error("Invalid face index.");used[vi]=true;}
            s.triangles.push_back(face);s.face_material_ids.push_back(f.getMatID());if(g::length_sq(g::triangle_cross(s.rest_positions[face[0]],s.rest_positions[face[1]],s.rest_positions[face[2]]))<=1e-24)++m->degenerate;
        }
        m->unused=std::count(used.begin(),used.end(),false);m->pose={1,r.nodes,r.material_frames};m->work.resize(m->accepted.size());
        m->mesh->InvalidateGeomCache();m->mesh->buildBoundingBox();
    }catch(...){if(tri!=object)tri->DeleteThis();throw;}if(tri!=object)tri->DeleteThis();
    m->preparationMs=ms(started);return m;
}
// Degenerate triangles remain in original topology; qualify their contact as segments/points.
double segmentDistance(v::Vec3 p,v::Vec3 a,v::Vec3 b){auto ab=g::sub(b,a);double d=g::length_sq(ab);double u=d>1e-30?std::clamp(g::dot(g::sub(p,a),ab)/d,0.,1.):0;return g::length_sq(g::sub(p,g::add(a,g::mul(ab,u))));}
double triangleDistance(v::Vec3 p,v::Vec3 a,v::Vec3 b,v::Vec3 c){if(g::length_sq(g::triangle_cross(a,b,c))<=1e-24)return std::min({segmentDistance(p,a,b),segmentDistance(p,a,c),segmentDistance(p,b,c)});return g::point_triangle_distance_sq(p,a,b,c);}
struct Sphere {v::Vec3 center;double radius;Json identity;};
Sphere capture(Model& m,INode* node){if(!node)throw std::runtime_error("Missing sphere.");
    double unit=GetSystemUnitScale(UNITS_METERS);if(std::abs(unit-m.unit)>1e-9*m.unit)throw std::runtime_error("System units changed.");
    auto time=GetCOREInterface()->GetTime();auto* object=node->EvalWorldState(time).obj;
    if(!object||object->ClassID()!=Class_ID(SPHERE_CLASS_ID,0))throw std::runtime_error("Use an unmodified complete standard Sphere.");
    auto* pb=object->GetParamBlock(0);if(!pb)throw std::runtime_error("Missing sphere parameters.");Interval valid=FOREVER;float radius=0,hemi=0;int slice=0,recenter=0;
    pb->GetValue(SPHERE_RADIUS,time,radius,valid);pb->GetValue(SPHERE_HEMI,time,hemi,valid);pb->GetValue(SPHERE_SLICEON,time,slice,valid);pb->GetValue(SPHERE_RECENTER,time,recenter,valid);
    if(hemi!=0||slice||recenter)throw std::runtime_error("Incomplete sphere rejected.");
    auto tm=node->GetObjectTM(time);double scale=Length(tm.GetRow(0));if(!std::isfinite(scale)||scale<1e-8||tm.Parity())throw std::runtime_error("Invalid sphere scale.");
    for(int i=0;i<3;++i){if(!g::finite(vec(tm.GetRow(i)))||std::abs(Length(tm.GetRow(i))-scale)>1e-5*scale)throw std::runtime_error("Nonuniform sphere scale.");for(int j=i+1;j<3;++j)if(std::abs(DotProd(tm.GetRow(i),tm.GetRow(j)))>1e-5*scale*scale)throw std::runtime_error("Sheared sphere.");}
    auto c=fromHost(tm.GetTrans()-m.origin,m.unit);double r=radius*scale*m.unit;
    if(!g::finite(c)||!std::isfinite(r)||r<.001||r>2||g::length(c)>20)throw std::runtime_error("Sphere admission failed.");
    return {c,r,Json::array({c.x,c.y,c.z,r,m.clearance})};
}
void record(Model& m,Json row){m.metrics=std::move(row);m.metrics["generation"]=m.generation;if(m.history.size()==128)m.history.erase(m.history.begin());m.history.push_back(m.metrics);}
bool update(Model& m,INode* stone,INode* target,bool redraw){
    if(m.busy)return false;m.busy=true;struct Guard{bool& b;~Guard(){b=false;}}guard{m.busy};
    auto started=Clock::now();Json row={{"accepted",false},{"error",""},{"mouse_left_down_at_capture",(GetAsyncKeyState(VK_LBUTTON)&0x8000)!=0},
        {"monotonic_capture_ms",std::chrono::duration<double,std::milli>(started.time_since_epoch()).count()}};
    try{auto sphere=capture(m,stone);if(sphere.identity==m.lastInput){++m.unchanged;return false;}m.lastInput=sphere.identity;++m.attempts;
        row["sphere"]={sphere.center.x,sphere.center.y,sphere.center.z,sphere.radius};
        auto phase=Clock::now();auto o=options();o.clearance_m=m.clearance+.0001;o.max_proposal_step_m=m.height/40.;
        v::SceneSnapshot snapshot;snapshot.generation=m.generation+1;v::Obstacle obs;obs.id=1;obs.geometry_revision=1;obs.pose_revision=snapshot.generation;obs.center=sphere.center;obs.sphere_radius=sphere.radius;snapshot.obstacles.push_back(obs);
        v::BackendOptions backend;backend.limits=o.limits;backend.query_tolerance_m=1e-6;backend.min_supported_feature_m=.001;
        auto world=v::make_jolt_world(snapshot,backend,{});if(world.outcome!=v::Outcome::Ok)throw std::runtime_error("World: "+issues(world.issues));
        auto fit=v::fit_rooted_guide(m.guide,snapshot.generation,*world.world,o,{});row["guide_ms"]=ms(phase);row["queries"]=fit.metrics.query_calls;row["iterations"]=fit.metrics.iterations;row["solver_status"]=int(fit.status);
        if(fit.status!=v::SolveStatus::ConvergedCandidate)throw std::runtime_error("Guide did not converge: "+issues(fit.issues));
        phase=Clock::now();double rootError=0,maxMove=0;
        for(std::size_t i=0;i<m.source.bindings.size();++i){const auto& b=m.source.bindings[i];const auto span=std::size_t(b.span_id-1);auto q=g::shortest_slerp(fit.pose.material_frames[span],fit.pose.material_frames[span+1],b.material_u);if(!q)throw std::runtime_error("Invalid interpolated frame.");
            auto center=g::add(g::mul(fit.pose.nodes[span],1-b.material_u),g::mul(fit.pose.nodes[span+1],b.material_u));
            auto p=g::add(center,g::rotate(*q,b.rest_local_offset));p=fromHost(toHost(p,m.unit),m.unit);
            if(!g::finite(p))throw std::runtime_error("Nonfinite deformed vertex.");m.work[i]=p;maxMove=std::max(maxMove,g::distance(p,m.source.rest_positions[i]));if(m.source.rest_positions[i].y<=1e-8)rootError=std::max(rootError,g::distance(p,m.source.rest_positions[i]));
        }row["deform_ms"]=ms(phase);row["root_mesh_error_m"]=rootError;row["max_vertex_displacement_m"]=maxMove;
        phase=Clock::now();double minDistance=std::numeric_limits<double>::infinity();double maxEdgeStretch=0;std::size_t testedEdges=0,stretchedEdges=0;
        for(auto f:m.source.triangles){const auto a=m.work[f[0]],b=m.work[f[1]],c=m.work[f[2]];double ds=triangleDistance(sphere.center,a,b,c);if(!std::isfinite(ds)||ds<0)throw std::runtime_error("Unqualified triangle distance.");minDistance=std::min(minDistance,ds);
            for(int j=0;j<3;++j){auto k=f[j],l=f[(j+1)%3];double rest=g::distance(m.source.rest_positions[k],m.source.rest_positions[l]);if(rest>1e-5){double strain=std::abs(g::distance(m.work[k],m.work[l])/rest-1);maxEdgeStretch=std::max(maxEdgeStretch,strain);++testedEdges;if(strain>.1)++stretchedEdges;}}
        }
        double gap=std::sqrt(minDistance)-sphere.radius;row["triangle_check_ms"]=ms(phase);row["min_surface_gap_m"]=gap;row["visible_penetration_m"]=std::max(0.,-gap);row["max_edge_relative_change"]=maxEdgeStretch;row["fraction_face_edges_over_10pct"]=testedEdges?double(stretchedEdges)/testedEdges:0;
        if(rootError>1e-7||gap<m.clearance-1e-5)throw std::runtime_error("Dense-mesh contact/root check rejected the candidate.");
        // Exact visible mesh publication is staged as a replacement object; authored source stays intact.
        if(!target||target==stone)throw std::runtime_error("Missing output owner.");
        phase=Clock::now();auto* successor=CreateNewTriObject();if(!successor)throw std::runtime_error("Cannot stage Max output.");
        try{successor->GetMesh()=*m.mesh;for(int i=0;i<successor->GetMesh().numVerts;++i)successor->GetMesh().verts[i]=toHost(m.work[i],m.unit);successor->GetMesh().InvalidateGeomCache();successor->GetMesh().buildBoundingBox();}
        catch(...){successor->DeleteThis();throw;}
        row["max_mesh_stage_ms"]=ms(phase);phase=Clock::now();target->SetObjectRef(successor);target->InvalidateWS();successor->NotifyDependents(FOREVER,PART_ALL,REFMSG_CHANGE);row["publish_ms"]=ms(phase);
        m.accepted.swap(m.work);m.pose=std::move(fit.pose);m.generation=snapshot.generation;++m.successes;row["accepted"]=true;row["mouse_left_down_at_publish"]=(GetAsyncKeyState(VK_LBUTTON)&0x8000)!=0;
        phase=Clock::now();if(redraw)GetCOREInterface()->RedrawViews(GetCOREInterface()->GetTime());row["redraw_ms"]=ms(phase);row["total_ms"]=ms(started);if(m.inputMark!=Time{}){row["request_to_redraw_ms"]=ms(m.inputMark);m.inputMark={};}record(m,row);return true;
    }catch(const std::exception& e){row["error"]=e.what();row["total_ms"]=ms(started);if(m.inputMark!=Time{}){row["request_to_redraw_ms"]=ms(m.inputMark);m.inputMark={};}record(m,row);return false;}
}
void CALLBACK tick(HWND,UINT,UINT_PTR,DWORD){if(timerBusy)return;timerBusy=true;auto owned=models;
    for(auto& m:owned)if(m&&m->watching){++m->timerCalls;auto* target=static_cast<INode*>(m->target.GetRef());auto* stone=static_cast<INode*>(m->stone.GetRef());if(!target||!stone){m->watching=false;continue;}update(*m,stone,target,true);}timerBusy=false;
}
void stopTimer(){if(timerId){KillTimer(GetCOREInterface()->GetMAXHWnd(),timerId);timerId=0;}}
void cleanup(void*,NotifyInfo*){stopTimer();models.clear();}
Json summary(Model& m){Json radii=m.guide.span_radius_m;return {{"private_experiment","dense-live-20261024"},{"vertices",m.source.bindings.size()},{"triangles",m.source.triangles.size()},{"height_m",m.height},{"unit",m.unit},{"origin_host",{m.origin.x,m.origin.y,m.origin.z}},{"guide_radii_m",radii},{"degenerate_faces",m.degenerate},{"unused_vertices",m.unused},{"base_anchors",m.anchored},{"preparation_ms",m.preparationMs},{"preparations",1},{"generation",m.generation},{"attempts",m.attempts},{"successes",m.successes},{"timer_calls",m.timerCalls},{"unchanged_skips",m.unchanged},{"watching",m.watching},{"last_mesh_copy_ms",m.lastMeshCopyMs},{"cold_control",m.cold},{"last",m.metrics},{"history",m.history}};}
}
extern "C" __declspec(dllexport) const MCHAR* LibDescription(){return _T("Private dense vegetation experiment 20261024 - Max 2027");}
extern "C" __declspec(dllexport) ULONG LibVersion(){return VERSION_3DSMAX;}
extern "C" __declspec(dllexport) int LibNumberClasses(){return 0;}
extern "C" __declspec(dllexport) ClassDesc* LibClassDesc(int){return nullptr;}
extern "C" __declspec(dllexport) ULONG CanAutoDefer(){return 0;}
extern "C" __declspec(dllexport) void LibInit(){for(int code:{NOTIFY_SYSTEM_PRE_RESET,NOTIFY_FILE_PRE_OPEN,NOTIFY_SYSTEM_SHUTDOWN})RegisterNotification(cleanup,nullptr,code);}
BOOL WINAPI DllMain(HINSTANCE i,DWORD reason,LPVOID){if(reason==DLL_PROCESS_ATTACH)module=i;return TRUE;}
def_visible_primitive(dvpPrepare,"dvpPrepare");
Value* dvpPrepare_cf(Value** a,int n){check_arg_count(dvpPrepare,1,n);return api([&]()->Value*{if(models.size()>=8)throw std::runtime_error("Private registry limit eight sources.");models.push_back(prepare(a[0]->to_node()));return Integer::intern(int(models.size()));});}
def_visible_primitive(dvpMesh,"dvpMesh");
Value* dvpMesh_cf(Value** a,int n){check_arg_count(dvpMesh,1,n);return api([&]()->Value*{auto& m=model(a[0]);auto start=Clock::now();auto out=std::make_unique<Mesh>(*m.mesh);for(int i=0;i<out->numVerts;++i)out->verts[i]=toHost(m.accepted[i],m.unit);out->InvalidateGeomCache();out->buildBoundingBox();m.lastMeshCopyMs=ms(start);++m.meshCopies;return new MeshValue(out.release(),TRUE);});}
def_visible_primitive(dvpStats,"dvpStats");
Value* dvpStats_cf(Value** a,int n){check_arg_count(dvpStats,1,n);return api([&]()->Value*{return text(summary(model(a[0])));});}
def_visible_primitive(dvpUpdate,"dvpUpdate");
Value* dvpUpdate_cf(Value** a,int n){check_arg_count(dvpUpdate,4,n);return api([&]()->Value*{auto& m=model(a[0]);m.clearance=a[3]->to_float()*m.unit;if(!std::isfinite(m.clearance)||m.clearance<0||m.clearance>.05)throw std::runtime_error("Clearance admission.");return update(m,a[1]->to_node(),a[2]->to_node(),true)?&true_value:&false_value;});}
def_visible_primitive(dvpWatch,"dvpWatch");
Value* dvpWatch_cf(Value** a,int n){check_arg_count(dvpWatch,4,n);return api([&]()->Value*{auto& m=model(a[0]);m.clearance=a[3]->to_float()*m.unit;if(!std::isfinite(m.clearance)||m.clearance<0||m.clearance>.05)throw std::runtime_error("Clearance admission.");m.stone.SetRef(a[1]->to_node());m.target.SetRef(a[2]->to_node());m.watching=true;if(!timerId)timerId=SetTimer(GetCOREInterface()->GetMAXHWnd(),0,16,tick);if(!timerId)throw std::runtime_error("Native UI timer failed.");return &true_value;});}
def_visible_primitive(dvpStop,"dvpStop");
Value* dvpStop_cf(Value** a,int n){check_arg_count(dvpStop,1,n);return api([&]()->Value*{auto& m=model(a[0]);m.watching=false;m.target.SetRef(nullptr);m.stone.SetRef(nullptr);return &true_value;});}
def_visible_primitive(dvpMark,"dvpMark");
Value* dvpMark_cf(Value** a,int n){check_arg_count(dvpMark,1,n);return api([&]()->Value*{model(a[0]).inputMark=Clock::now();return &true_value;});}
def_visible_primitive(dvpColdControl,"dvpColdControl");
Value* dvpColdControl_cf(Value** a,int n){check_arg_count(dvpColdControl,1,n);return api([&]()->Value*{auto& m=model(a[0]);auto start=Clock::now();auto o=options();auto e=v::evaluate_ribbon(m.source,m.guide,{1,m.guide.nodes,m.guide.material_frames},o.limits,o.tolerances,{});m.cold={{"evaluate_ms",ms(start)},{"outcome",int(e.outcome)},{"issues",issues(e.issues)}};
    if(e.outcome==v::Outcome::Ok){start=Clock::now();v::SceneSnapshot controlScene;controlScene.generation=1;auto validation=v::validate_candidate(controlScene,m.source,m.guide,{1,m.guide.nodes,m.guide.material_frames},e.mesh,o,{});m.cold["validate_ms"]=ms(start);m.cold["validation_status"]=int(validation.status);m.cold["validation_issues"]=issues(validation.issues);}return text(m.cold);});}
def_visible_primitive(dvpAudit,"dvpAudit");
Value* dvpAudit_cf(Value** a,int n){check_arg_count(dvpAudit,2,n);return api([&]()->Value*{auto& m=model(a[0]);auto sphere=capture(m,a[1]->to_node());auto started=Clock::now();auto o=options();o.clearance_m=m.clearance;
    // Visible-triangle audit has its own admitted work, separate from the 40k guide-query budget.
    o.limits.max_query_calls=m.source.triangles.size()+10000;
    auto e=v::evaluate_ribbon(m.source,m.guide,m.pose,o.limits,o.tolerances,{});Json audit={{"evaluate_ms",ms(started)},{"outcome",int(e.outcome)},{"issues",issues(e.issues)},{"visible_pair_budget",o.limits.max_query_calls}};
    if(e.outcome==v::Outcome::Ok){double difference=0;for(std::size_t i=0;i<e.mesh.positions.size();++i)difference=std::max(difference,g::distance(e.mesh.positions[i],m.accepted[i]));audit["fast_sampler_difference_m"]=difference;
        v::SceneSnapshot scene;scene.generation=m.generation;v::Obstacle stone;stone.id=1;stone.geometry_revision=1;stone.pose_revision=m.generation;stone.center=sphere.center;stone.sphere_radius=sphere.radius;scene.obstacles.push_back(stone);started=Clock::now();auto validation=v::validate_candidate(scene,m.source,m.guide,m.pose,e.mesh,o,{});audit["validate_ms"]=ms(started);audit["validation_status"]=int(validation.status);audit["validation_issues"]=issues(validation.issues);audit["independent_penetration_m"]=validation.max_visible_penetration_m;}return text(audit);});}
