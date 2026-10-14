#include <max.h>
#include <triobj.h>
#include <shape.h>
#include <maxscript/maxscript.h>
#include <maxscript/foundation/arrays.h>
#include <maxscript/foundation/numbers.h>
#include <maxscript/foundation/3dmath.h>
#include <maxscript/maxwrapper/mxsobjects.h>
#include "scatter.h"
#include "surface_filter.h"
#include "spline_bands.h"
#include "execution.h"
#include "group_spacing.h"
#include "procedural.h"
#include "receiver_plan.h"
#include "receiver_binding_host.h"
#include "license_boundary.h"
#include "placement_transport.h"
#include <memory>
#include <stdexcept>
#include <map>
#include <set>
#include <unordered_map>
#include <limits>
#include <cstring>
#include <tuple>
#include <cmath>
#include <maxscript/macros/define_instantiation_functions.h>
#undef ScripterExport
#define ScripterExport __declspec(dllexport)
#include "spline_field_bridge.inc"

extern "C" __declspec(dllexport) const TCHAR* LibDescription() {
#ifdef CYRUS_NATIVE_LICENSE_EXPERIMENT
    return _T("Cyrus Scatter CYRUS_LICENSE_EXPERIMENT_NEVER_SHIP");
#else
    return _T("Cyrus Scatter 0.7 native engine");
#endif
}
extern "C" __declspec(dllexport) ULONG LibVersion() { return VERSION_3DSMAX; }
extern "C" __declspec(dllexport) void LibInit() {}
HINSTANCE CyrusEditInstance=nullptr;
extern "C" __declspec(dllexport) ClassDesc* CyrusEditDesc();
extern "C" __declspec(dllexport) int LibNumberClasses(){return 1;}
extern "C" __declspec(dllexport) ClassDesc* LibClassDesc(int i){return i==0?CyrusEditDesc():nullptr;}
BOOL WINAPI DllMain(HINSTANCE instance, DWORD reason, LPVOID) { if(reason==DLL_PROCESS_ATTACH)CyrusEditInstance=instance;return TRUE; }
static_assert(MAX_PRODUCT_YEAR_NUMBER == CYRUS_MAX_YEAR, "SDK year must match the configured host year");
def_visible_primitive(cyrusSplineBandVersion,"cyrusSplineBandVersion");
Value* cyrusSplineBandVersion_cf(Value** args,int count){check_arg_count(cyrusSplineBandVersion,0,count);return Integer::intern(10);}
#include "group_spacing_bridge.inc"

// Diagnostic/session controls. Scene evaluation and MAXScript values stay on
// this calling thread; native workers receive plain owned geometry only.
def_visible_primitive(cyrusScatterCPUThreads, "cyrusScatterCPUThreads");
Value* cyrusScatterCPUThreads_cf(Value** args,int count) {
    if(count!=0 && count!=1) throw RuntimeError(_T("Expected zero or one CPU thread limit"));
    if(count==1) {
        const int limit=args[0]->to_int();
        if(limit<0 || limit>64) throw RuntimeError(_T("CPU thread limit must be 0..64"));
        amin::setComputeThreads(static_cast<unsigned>(limit));
    }
    return Integer::intern(static_cast<int>(amin::computeThreads()));
}
def_visible_primitive(cyrusScatterComputeStats, "cyrusScatterComputeStats");
Value* cyrusScatterComputeStats_cf(Value**,int count) {
    check_arg_count(cyrusScatterComputeStats,0,count);
    const auto stats=amin::lastComputeStats();
    one_typed_value_local(Array* result);vl.result=new Array(3);
    vl.result->append(Integer::intern(static_cast<int>(stats.participants)));
    vl.result->append(Integer64::intern(static_cast<INT64>(stats.clusterQueries)));
    vl.result->append(stats.threadLaunchFallback ? &true_value : &false_value);
    return_value(vl.result);
}

// Stable source filtering after area/falloff processing. Keep the exact existing
// rows (including CS Edit data); avoid a MAXScript function lookup per placement.
def_visible_primitive(cyrusFilterSourceRows, "cyrusFilterSourceRows");
Value* cyrusFilterSourceRows_cf(Value** args,int count) {
    check_arg_count(cyrusFilterSourceRows,2,count);
    type_check(args[0],Array,_T("placement rows"));
    type_check(args[1],Array,_T("source visibility"));
    auto* rows=static_cast<Array*>(args[0]);auto* flags=static_cast<Array*>(args[1]);
    std::vector<bool> keep;keep.reserve(flags->size);
    for(int i=0;i<flags->size;++i) keep.push_back(flags->data[i]->to_bool()!=FALSE);
    one_typed_value_local(Array* result);vl.result=new Array(rows->size);
    for(int i=0;i<rows->size;++i) {
        type_check(rows->data[i],Array,_T("placement row"));
        auto* row=static_cast<Array*>(rows->data[i]);
        // This removal-only operation is shared by candidate eligibility and
        // exact published output. Preserve either current pipeline identity.
        cyrus::rows::current(row);
        const int source=row->data[1]->to_int()-1;
        if(source<0 || static_cast<std::size_t>(source)>=keep.size()) throw RuntimeError(_T("Invalid source index"));
        if(keep[source]) vl.result->append(rows->data[i]);
    }
    return_value(vl.result);
}

def_visible_primitive(cyrusApplySourceTransforms, "cyrusApplySourceTransforms");
Value* cyrusApplySourceTransforms_cf(Value** args,int count) {
    check_arg_count(cyrusApplySourceTransforms,3,count);
    for(int i=0;i<3;++i) type_check(args[i],Array,_T("source transform inputs"));
    auto* rows=static_cast<Array*>(args[0]);auto* offsets=static_cast<Array*>(args[1]);auto* scales=static_cast<Array*>(args[2]);
    if(offsets->size!=scales->size) throw RuntimeError(_T("Source transform count mismatch"));
    std::vector<float> z,factors;z.reserve(scales->size);factors.reserve(scales->size);
    for(int i=0;i<scales->size;++i) {z.push_back(offsets->data[i]->to_float());factors.push_back(scales->data[i]->to_float());}
    // Validate all rows before modifying any. These are transient placement
    // values, never scene transforms; preserve MAXScript's in-place alias rules.
    for(int i=0;i<rows->size;++i) {
        type_check(rows->data[i],Array,_T("placement row"));auto* row=static_cast<Array*>(rows->data[i]);
        cyrus::rows::raw(row);
        type_check(row->data[0],Matrix3Value,_T("placement transform"));
        const int source=row->data[1]->to_int()-1;
        if(source<0 || source>=scales->size) throw RuntimeError(_T("Invalid source index"));
    }
    for(int i=0;i<rows->size;++i) {
        auto* row=static_cast<Array*>(rows->data[i]);const int source=row->data[1]->to_int()-1;
        Matrix3& tm=row->data[0]->to_matrix3();
        for(int axis=0;axis<3;++axis) tm.SetRow(axis,tm.GetRow(axis)*factors[source]);
        // Do not skip identity values: +0 can change a signed zero just as the
        // original script does, and full byte parity is part of the gate.
        tm.SetRow(3,tm.GetRow(3)+Point3(0.0f,0.0f,z[source]));
    }
    return args[0];
}

namespace {
amin::Vec3 vec(Point3 p) { return {p.x,p.y,p.z}; }
Point3 point(amin::Vec3 p) { return {static_cast<float>(p.x),static_cast<float>(p.y),static_cast<float>(p.z)}; }
#include "placement_identity.inc"
std::vector<amin::Triangle> meshOf(INode* node, bool world, bool requireUv=false, std::size_t faceLimit=std::numeric_limits<std::size_t>::max()) {
    if(!node) throw std::invalid_argument("Missing node");
    const auto t=GetCOREInterface()->GetTime();
    auto* object=node->EvalWorldState(t).obj;
    if(!object || !object->CanConvertToType(Class_ID(TRIOBJ_CLASS_ID,0)))
        throw std::invalid_argument("Select a mesh-convertible object");
    auto* tri=static_cast<TriObject*>(object->ConvertToType(t,Class_ID(TRIOBJ_CLASS_ID,0)));
    if(!tri) throw std::invalid_argument("Could not evaluate mesh");
    const auto cleanup=[object](TriObject* p){if(p!=object)p->DeleteThis();};
    std::unique_ptr<TriObject,decltype(cleanup)> holder(tri,cleanup);
    Matrix3 tm=node->GetObjectTM(t);
    if(!world) tm=tm*Inverse(node->GetNodeTM(t));
    Mesh& mesh=tri->GetMesh();
    if(std::size_t(mesh.getNumFaces())>faceLimit)throw std::invalid_argument("Evaluated receiver exceeds the surface filter face limit");
    if(requireUv && (!mesh.mapSupport(1)||!mesh.mapVerts(1)||!mesh.mapFaces(1))) {
        const std::wstring message=std::wstring(L"Texture Density: receiver '")+node->GetName()+L"' requires UV channel 1. Add UV mapping to this surface or choose another Layout mode. The previous result is retained.";
        throw RuntimeError(message.c_str());
    }
    std::vector<amin::Triangle> result;result.reserve(mesh.getNumFaces());
    for(int i=0;i<mesh.getNumFaces();++i) {
        const auto& f=mesh.faces[i];
        result.push_back({vec(mesh.verts[f.v[0]]*tm),vec(mesh.verts[f.v[1]]*tm),vec(mesh.verts[f.v[2]]*tm)});
        if(requireUv) {const auto& uvf=mesh.mapFaces(1)[i];auto* uv=mesh.mapVerts(1);result.back().uvA=vec(uv[uvf.t[0]]);result.back().uvB=vec(uv[uvf.t[1]]);result.back().uvC=vec(uv[uvf.t[2]]);}
    }
    return result;
}
std::vector<amin::Triangle> surfaceMeshes(Value* input,bool requireUv=false) {
    if(!is_array(input)) return meshOf(input->to_node(),true,requireUv);
    auto* nodes=static_cast<Array*>(input);std::vector<amin::Triangle> result;
    std::vector<INode*> seen;
    for(int i=0;i<nodes->size;++i) {
        auto* node=nodes->data[i]->to_node();
        if(std::find(seen.begin(),seen.end(),node)!=seen.end()) continue;
        seen.push_back(node);auto mesh=meshOf(node,true,requireUv);
        result.insert(result.end(),mesh.begin(),mesh.end());
    }
    return result;
}
Value* scatterAdvanced(Value** args,int count) {
    if(count!=29) throw RuntimeError(_T("Cyrus generation requires its current 29-field contract."));
    type_check(args[28],Array,_T("generation options"));
    auto* v1=static_cast<Array*>(args[28]);
    if(v1->size!=11)throw RuntimeError(_T("Expected current keyed generation options"));
    amin::Settings s;
    {
        if(v1->data[7]->to_int()!=1)throw RuntimeError(_T("Unsupported procedural sampler version"));
        const auto start=v1->data[8]->to_int64();
        if(start<0)throw RuntimeError(_T("Negative candidate ordinal"));
        s.candidateStart=static_cast<std::uint64_t>(start);
    }
    unsigned receiverSlot=0;
    {
        const std::wstring id=v1->data[9]->to_string();std::string ascii;
        for(auto c:id){if(c>127)throw RuntimeError(_T("Receiver identity must be ASCII"));ascii.push_back(static_cast<char>(c));}
        const int slot=v1->data[10]->to_int();if(slot<1||slot>128)throw RuntimeError(_T("Invalid receiver slot"));
        receiverSlot=unsigned(slot-1);s.receiverSalt=cyrus::receivers::salt(ascii);
    }
    {
        type_check(args[25],Array,_T("spacing controls"));
        auto* a=static_cast<Array*>(args[25]);
        if(a->size!=4) throw RuntimeError(_T("Relax needs enabled/spacing/iterations/strength."));
        s.relaxEnabled=a->data[0]->to_bool()!=FALSE;s.relaxSpacing=a->data[1]->to_float();
        const int iterations=a->data[2]->to_int();
        if(iterations<0||iterations>100) throw RuntimeError(_T("Relax iterations must be 0..100."));
        s.relaxIterations=iterations;s.relaxStrength=a->data[3]->to_float();
    }
    {
        type_check(args[26],Array,_T("source weights"));
        auto* a=static_cast<Array*>(args[26]);
        for(int i=0;i<a->size;++i) s.sourceWeights.push_back(a->data[i]->to_float());
    }
    if(args[24]->is_kind_of(class_tag(CyrusSplineField))) {
        s.splineField=static_cast<CyrusSplineField*>(args[24])->field;
    }else{
        type_check(args[24],Array,_T("Analyzer pattern"));
        auto* pattern=static_cast<Array*>(args[24]);
        if(pattern->size!=2)throw RuntimeError(_T("Analyzer pattern requires enabled and rows."));
        if(pattern->data[0]!=&true_value&&pattern->data[0]!=&false_value)throw RuntimeError(_T("Analyzer enabled state must be Boolean."));
        s.analyzerPattern=pattern->data[0]==&true_value;
        type_check(pattern->data[1],Array,_T("Analyzer rows"));auto* bands=static_cast<Array*>(pattern->data[1]);
        if(!s.analyzerPattern&&bands->size)throw RuntimeError(_T("Disabled Analyzer pattern must have no rows."));
        for(int i=0;i<bands->size;++i){
            type_check(bands->data[i],Array,_T("Analyzer row"));auto* row=static_cast<Array*>(bands->data[i]);
            if(row->size!=11)throw RuntimeError(_T("Expected the current 11-field Analyzer record."));
            amin::AnalyzerBand band;band.width=row->data[1]->to_float();band.kind=row->data[5]->to_int();band.start=row->data[6]->to_float();
            if(band.kind<1||band.kind>6)throw RuntimeError(_T("Expected a current Analyzer mode (1..6)."));
            type_check(row->data[2],Array,_T("Analyzer sources"));auto* choices=static_cast<Array*>(row->data[2]);
            for(int k=0;k<choices->size;++k){const int choice=choices->data[k]->to_int();if(choice<1)throw RuntimeError(_T("Invalid Analyzer source index."));band.sources.push_back(unsigned(choice-1));}
            band.scaleMin=row->data[3]->to_float();band.scaleMax=row->data[4]->to_float();
            type_check(row->data[7],Array,_T("boundary edge mask"));auto* mask=static_cast<Array*>(row->data[7]);
            for(int m=0;m<mask->size;++m)band.boundaryMask.push_back(mask->data[m]->to_bool()!=FALSE);
            band.straightEnds=row->data[8]->to_bool()!=FALSE;
            type_check(row->data[10],Array,_T("edge settings"));auto* e=static_cast<Array*>(row->data[10]);
            if(e->size!=9)throw RuntimeError(_T("Invalid edge settings."));
            band.edgeKeepCorners=e->data[3]->to_bool()!=FALSE;band.edgeCornerAngle=e->data[4]->to_float();band.edgeCornerCount=e->data[5]->to_int();
            band.edgeOffset=e->data[0]->to_float();band.edgeAlongJitter=e->data[1]->to_float();band.edgeAcrossJitter=e->data[2]->to_float();
            type_check(row->data[0],Array,_T("Analyzer paths"));auto* paths=static_cast<Array*>(row->data[0]);
            for(int k=0;k<paths->size;++k){type_check(paths->data[k],Array,_T("Analyzer path"));auto* path=static_cast<Array*>(paths->data[k]);std::vector<amin::Vec3> points;
                for(int v=0;v<path->size;++v)points.push_back(vec(path->data[v]->to_point3()));band.boundary.loops.push_back(std::move(points));}
            s.analyzerBands.push_back(std::move(band));
        }
    }
    const int n=args[1]->to_int(), ns=args[3]->to_int();
    if(n<0||n>cyrus::receivers::limit||s.candidateStart>cyrus::receivers::limit-static_cast<unsigned>(n)||ns<1)
        throw RuntimeError(_T("Candidate range must stay within 0..1,000,000 and sources must be nonempty."));
    s.count=n;s.seed=args[2]->to_int();s.sourceCount=ns;s.uniformScale={1,1};
    {
        type_check(args[15],Array,_T("source groups"));
        const auto* groups=static_cast<Array*>(args[15]);
        if(groups->size!=ns) throw RuntimeError(_T("One color group per source required."));
        for(int i=0;i<ns;++i) s.sourceGroups.push_back(static_cast<std::uint32_t>(groups->data[i]->to_int()));
    }
    {
        s.clusterEnabled=args[16]->to_bool()!=FALSE;s.clusterSize=args[17]->to_float();s.clusterSeed=args[18]->to_int();
        s.clusterRoughness=args[19]->to_float();s.clusterBlur=args[20]->to_float();s.clusterNoise=args[21]->to_float();
    }
    {
        type_check(args[22],Array,_T("area nodes"));type_check(args[23],Array,_T("area modes"));
        auto* nodes=static_cast<Array*>(args[22]);auto* modes=static_cast<Array*>(args[23]);
        if(nodes->size!=modes->size) throw RuntimeError(_T("One Include/Exclude mode per area required."));
        auto time=GetCOREInterface()->GetTime();
        for(int i=0;i<nodes->size;++i) {
            auto* node=nodes->data[i]->to_node();
            if(!node) throw RuntimeError(_T("Area node was deleted. Remove it from the Area list."));
            auto* object=node->EvalWorldState(time).obj;
            if(!object||object->SuperClassID()!=SHAPE_CLASS_ID) throw RuntimeError(_T("Area must be a closed spline shape."));
            auto* shape=static_cast<ShapeObject*>(object);amin::Area area;
            const int mode=modes->data[i]->to_int();
            if(mode!=1&&mode!=2) throw RuntimeError(_T("Area mode must be Include or Exclude."));
            area.include=mode==1;
            const auto tm=node->GetObjectTM(time);
            for(int curve=0;curve<shape->NumberOfCurves(time);++curve) {
                if(!shape->CurveClosed(time,curve)) throw RuntimeError(_T("Every spline in an Area shape must be closed."));
                const int steps=std::max(3,shape->NumberOfPieces(time,curve)*16);
                if(steps>65536) throw RuntimeError(_T("Area spline is too complex."));
                std::vector<amin::Vec3> loop;loop.reserve(steps);
                for(int k=0;k<steps;++k) loop.push_back(vec(shape->InterpCurve3D(time,curve,static_cast<float>(k)/steps,PARAM_SIMPLE)*tm));
                area.loops.push_back(std::move(loop));
            }
            s.areas.push_back(std::move(area));
        }
    }
    const auto sl=args[4]->to_point3(),sh=args[5]->to_point3(),rl=args[6]->to_point3(),rh=args[7]->to_point3(),ml=args[8]->to_point3(),mh=args[9]->to_point3();
    for(int i=0;i<3;++i) {s.axisScale[i]={sl[i],sh[i]};s.rotationDegrees[i]={rl[i],rh[i]};s.movement[i]={ml[i],mh[i]};}
    s.alignToNormal=args[10]->to_bool()!=FALSE;s.projectMovement=args[11]->to_bool()!=FALSE;
    s.distribution=args[12]->to_int();
    if(s.distribution==2) {
        type_check(args[13],Array,_T("density array"));
        const auto* pixels=static_cast<Array*>(args[13]);const int width=args[14]->to_int();
        if(width<2||width>512||pixels->size!=width*width) throw RuntimeError(_T("Density image must be a square 2..512 grid."));
        s.densityWidth=s.densityHeight=width;s.density.reserve(pixels->size);
        for(int i=0;i<pixels->size;++i) s.density.push_back(pixels->data[i]->to_float());
    }
    // Preserve the existing non-advanced randomization when adding a Brush to
    // a layer. The general path must not quietly substitute XYZ defaults.
    if(v1->data[0]->to_bool()){
        s.axisScale={{{1,1},{1,1},{1,1}}};s.uniformScale={v1->data[1]->to_float(),v1->data[2]->to_float()};
        const auto tilt=v1->data[3]->to_float(),lo=v1->data[4]->to_float(),hi=v1->data[5]->to_float(),move=v1->data[6]->to_float();
        s.rotationDegrees={{{-tilt,tilt},{-tilt,tilt},{lo,hi}}};s.movement={{{-move,move},{-move,move},{-move,move}}};
    }
    std::vector<amin::Instance> instances;
    try {
        const auto mesh=surfaceMeshes(args[0],s.distribution==2);
        if(args[27]!=&undefined) {
            type_check(args[27],Array,_T("final pass"));auto* f=static_cast<Array*>(args[27]);
            if(f->size!=14)throw RuntimeError(_T("Invalid final pass payload"));
            auto rows=[](Value* v){type_check(v,Array,_T("final rows"));auto* a=static_cast<Array*>(v);std::vector<amin::Instance> out;
                for(int i=0;i<a->size;++i){type_check(a->data[i],Array,_T("placement"));out.push_back(placementInstance(static_cast<Array*>(a->data[i])));}return out;};
            auto radii=[](Value* v){type_check(v,Array,_T("radii"));auto* a=static_cast<Array*>(v);std::vector<double> out;for(int i=0;i<a->size;++i){double r=a->data[i]->to_float();if(!std::isfinite(r)||r<0)throw RuntimeError(_T("Invalid radius"));out.push_back(r);}return out;};
            amin::FinalSettings cfg;cfg.cleanup=f->data[4]->to_bool()!=FALSE;cfg.radius=f->data[5]->to_float();
            cfg.minNeighbors=f->data[6]->to_int();cfg.minIsland=f->data[7]->to_int();cfg.relax=f->data[8]->to_bool()!=FALSE;
            cfg.strength=f->data[9]->to_float();cfg.iterations=f->data[10]->to_int();cfg.maxMove=f->data[11]->to_float();cfg.gap=f->data[12]->to_float();cfg.planar=f->data[13]->to_bool()!=FALSE;
            auto input=rows(f->data[0]);
            for(auto& p:input){unsigned slot=0,ordinal=0;if(!cyrus::receivers::decode(p.candidateKey,slot,ordinal)||slot!=receiverSlot)throw RuntimeError(_T("Final movement rows must belong to this receiver."));p.candidateKey=ordinal;}
            instances=amin::finalize(mesh,amin::prepareEdgeRows(s),std::move(input),rows(f->data[1]),radii(f->data[2]),radii(f->data[3]),cfg);
            for(auto& p:instances)p.candidateKey=cyrus::receivers::identity(receiverSlot,unsigned(p.candidateKey));
            for(auto& p:instances)anchorInstance(p,mesh);
        } else {
            instances=amin::scatter(mesh,s);
            for(auto& p:instances)p.candidateKey=cyrus::receivers::identity(receiverSlot,unsigned(p.candidateKey));
            for(auto& p:instances)anchorInstance(p,mesh);
        }
    }
    catch(const std::exception& error) {const std::string message=error.what();throw RuntimeError(MSTR(std::wstring(message.begin(),message.end()).c_str()));}
    two_typed_value_locals(Array* result,Array* row);vl.result=new Array(static_cast<int>(instances.size()));
    for(const auto& v:instances) {
        vl.row=new Array(2);vl.result->append(vl.row);
        vl.row->append(new Matrix3Value(Matrix3(point(v.xAxis*v.scale),point(v.yAxis*v.scale),point(v.zAxis*v.scale),point(v.position))));
        vl.row->append(Integer::intern(v.source+1));
        appendIdentity(vl.row,v);
    }
    return_value(vl.result);
}
}
def_visible_primitive(cyrusScatterAdvanced, "cyrusScatterAdvanced");
Value* cyrusScatterAdvanced_cf(Value** args,int count){return scatterAdvanced(args,count);}
#include "procedural_bridge.inc"
#include "receiver_bridge.inc"
#include "surface_filter_bridge.inc"
def_visible_primitive(cyrusProceduralSurfaceKey,"cyrusProceduralSurfaceKey");
Value* cyrusProceduralSurfaceKey_cf(Value** a,int n){
    if(n!=1&&n!=2)throw RuntimeError(_T("Surface key expects surfaces and optional UV flag"));std::uint64_t hash=1469598103934665603ULL;
    try{
        const bool uv=n==2&&a[1]->to_bool()!=FALSE;const auto triangles=surfaceMeshes(a[0],uv);
        for(const auto& t:triangles){const std::array<amin::Vec3,6> vertices{{t.a,t.b,t.c,t.uvA,t.uvB,t.uvC}};
        for(unsigned k=0;k<(uv?6u:3u);++k)for(double value:{vertices[k].x,vertices[k].y,vertices[k].z}){
            std::uint64_t bits=0;std::memcpy(&bits,&value,sizeof(bits));
            for(int byte=0;byte<8;++byte){hash^=(bits>>(byte*8))&255;hash*=1099511628211ULL;}
        }}
        const auto key=std::to_wstring(triangles.size())+L":"+std::to_wstring(hash);return new String(key.c_str());
    }catch(const std::exception& e){throw RuntimeError(MSTR::FromACP(e.what()));}
}
#include "orientation_bridge.inc"
#include "boundary_falloff_bridge.inc"
#include "whole_scale_bridge.inc"
#include "analyzer_area_bridge.inc"
#include "authored_revision.inc"
def_visible_primitive(aminScatterSourcePoints, "aminScatterSourcePoints");
Value* aminScatterSourcePoints_cf(Value** args,int count) {
    check_arg_count(aminScatterSourcePoints,3,count);
    const int n=args[1]->to_int();if(n<1||n>10000) throw RuntimeError(_T("Source point count must be 1..10000."));
    std::vector<amin::Vec3> points;
    try {points=amin::sampleSource(meshOf(args[0]->to_node(),false),n,args[2]->to_int());}
    catch(const std::exception&) {throw RuntimeError(_T("Cannot sample source geometry. Use a nonempty mesh; Proxy support is not verified."));}
    one_typed_value_local(Array* result);vl.result=new Array(n);
    for(const auto& p:points) vl.result->append(new Point3Value(point(p)));
    return_value(vl.result);
}


def_visible_primitive(aminScatterValidArea, "aminScatterValidArea");
Value* aminScatterValidArea_cf(Value** args,int count) {
    check_arg_count(aminScatterValidArea,1,count);
    auto* node=args[0]->to_node();
    if(!node) return &false_value;
    const auto time=GetCOREInterface()->GetTime();
    auto* object=node->EvalWorldState(time).obj;
    if(!object||object->SuperClassID()!=SHAPE_CLASS_ID) return &false_value;
    auto* shape=static_cast<ShapeObject*>(object);
    if(shape->NumberOfCurves(time)<1) return &false_value;
    for(int i=0;i<shape->NumberOfCurves(time);++i) if(!shape->CurveClosed(time,i)) return &false_value;
    return &true_value;
}

def_visible_primitive(aminScatterSurfaceArea, "aminScatterSurfaceArea");
// The sampler concatenates every receiver's triangles in this same order.
// Coverage uses these offsets to resolve a combined anchor to its receiver.
def_visible_primitive(cyrusReceiverFaceCounts, "cyrusReceiverFaceCounts");
Value* cyrusReceiverFaceCounts_cf(Value** args,int count) {
    check_arg_count(cyrusReceiverFaceCounts,1,count);
    type_check(args[0],Array,_T("receiver nodes"));
    auto* nodes=static_cast<Array*>(args[0]);
    one_typed_value_local(Array* result);vl.result=new Array(nodes->size);
    std::vector<INode*> seen;
    for(int i=0;i<nodes->size;++i){
        auto* node=nodes->data[i]->to_node();
        if(!node||std::find(seen.begin(),seen.end(),node)!=seen.end())throw RuntimeError(_T("Coverage receivers must be valid and unique"));
        seen.push_back(node);
        try{vl.result->append(Integer::intern(int(meshOf(node,true).size())));}
        catch(const std::exception&){throw RuntimeError(_T("Cannot prepare receiver face offsets"));}
    }
    return_value(vl.result);
}
Value* aminScatterSurfaceArea_cf(Value** args,int count) {
    check_arg_count(aminScatterSurfaceArea,1,count);
    double area=0;
    try {
        for(const auto& t:surfaceMeshes(args[0])) {
            auto a=t.b-t.a,b=t.c-t.a;
            area+=amin::length({a.y*b.z-a.z*b.y,a.z*b.x-a.x*b.z,a.x*b.y-a.y*b.x})*0.5;
        }
    } catch(const std::exception&) {throw RuntimeError(_T("Cannot evaluate scatter surface area."));}
    return Double::intern(area);
}




