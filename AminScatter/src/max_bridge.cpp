#include <max.h>
#include <triobj.h>
#include <maxscript/maxscript.h>
#include <maxscript/foundation/arrays.h>
#include <maxscript/foundation/numbers.h>
#include <maxscript/foundation/3dmath.h>
#include <maxscript/maxwrapper/mxsobjects.h>
#include "scatter.h"
#include "execution.h"
#include "group_spacing.h"
#include "procedural.h"
#include "license_boundary.h"
#include <memory>
#include <stdexcept>
#include <map>
#include <unordered_map>
#include <limits>
#include <cstring>
#include <tuple>
#include <cmath>
#include <maxscript/macros/define_instantiation_functions.h>

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
        if(row->size<2) throw RuntimeError(_T("Invalid placement row"));
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
        if(row->size<2) throw RuntimeError(_T("Invalid placement row"));
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

// Final, stable removal only: retain the original MAXScript rows and transforms.
def_visible_primitive(cyrusRemoveOverlaps, "cyrusRemoveOverlaps");
Value* cyrusRemoveOverlaps_cf(Value** args,int count) {
    if(count!=4 && count!=6) throw RuntimeError(_T("Expected 4 or 6 overlap arguments"));
    type_check(args[0],Array,_T("placements"));
    type_check(args[1],Array,_T("blockers"));
    auto* rows=static_cast<Array*>(args[0]);auto* blockers=static_cast<Array*>(args[1]);
    const double radius=args[2]->to_float();const bool planar=args[3]->to_bool()!=FALSE;
    if(!std::isfinite(radius)||radius<0) throw RuntimeError(_T("Invalid overlap radius"));
    std::vector<double> own(rows->size,0), other(blockers->size,0);
    double cellSize=radius;
    if(count==6) {
        auto read=[](Value* v,std::vector<double>& out){
            type_check(v,Array,_T("source radii"));auto* a=static_cast<Array*>(v);
            if(a->size!=out.size()) throw RuntimeError(_T("Radius count mismatch"));
            for(int i=0;i<a->size;++i){out[i]=a->data[i]->to_float();if(!std::isfinite(out[i])||out[i]<0)throw RuntimeError(_T("Invalid source radius"));}
        };
        read(args[4],own);read(args[5],other);
        double a=0,b=0;for(auto r:own)a=std::max(a,r);for(auto r:other)b=std::max(b,r);cellSize+=a+b;
    }
    if(cellSize==0||blockers->size==0) return args[0];
    using Cell=std::tuple<double,double,double>;
    auto cell=[&](Point3 p){return Cell{std::floor(p.x/cellSize),std::floor(p.y/cellSize),planar?0:std::floor(p.z/cellSize)};};
    auto position=[](Value* value){
        type_check(value,Array,_T("placement row"));auto* row=static_cast<Array*>(value);
        if(row->size<2) throw RuntimeError(_T("Invalid placement row"));
        return row->data[0]->to_matrix3().GetTrans();
    };
    std::map<Cell,std::vector<std::pair<Point3,double>>> grid;
    for(int i=0;i<blockers->size;++i){auto p=position(blockers->data[i]);grid[cell(p)].push_back({p,other[i]});}
    one_typed_value_local(Array* result);vl.result=new Array(rows->size);
    for(int i=0;i<rows->size;++i){
        auto p=position(rows->data[i]);auto [x,y,z]=cell(p);bool hit=false;
        for(int dz=planar?0:-1;dz<=(planar?0:1)&&!hit;++dz)
        for(int dy=-1;dy<=1&&!hit;++dy)for(int dx=-1;dx<=1&&!hit;++dx){
            auto found=grid.find(Cell{x+dx,y+dy,z+dz});if(found==grid.end())continue;
            for(auto [q,r]:found->second){double limit=radius+own[i]+r;double a=double(p.x)-q.x,b=double(p.y)-q.y,c=planar?0:double(p.z)-q.z;
                if(a*a+b*b+c*c<limit*limit){hit=true;break;}}
        }
        if(!hit)vl.result->append(rows->data[i]);
    }
    return_value(vl.result);
}

namespace {
amin::Vec3 vec(Point3 p) { return {p.x,p.y,p.z}; }
Point3 point(amin::Vec3 p) { return {static_cast<float>(p.x),static_cast<float>(p.y),static_cast<float>(p.z)}; }
#include "placement_identity.inc"
std::vector<amin::Triangle> meshOf(INode* node, bool world, bool requireUv=false) {
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
    if(requireUv && (!mesh.mapSupport(1)||!mesh.mapVerts(1)||!mesh.mapFaces(1))) throw std::invalid_argument("Surface requires UV channel 1");
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
def_visible_primitive(aminScatterAdvanced, "aminScatterAdvanced");
Value* aminScatterAdvanced_cf(Value** args,int count) {
    if(count!=17&&count!=18&&count!=24&&count!=26&&count!=27&&count!=28&&count!=29&&count!=30&&count!=31&&count!=32) throw RuntimeError(_T("Invalid Cyrus Scatter generation argument count."));
    const bool options=count==32&&args[31]->is_kind_of(class_tag(Array));
    auto* v1=options?static_cast<Array*>(args[31]):nullptr;
    if(v1&&v1->size!=8&&v1->size!=10)throw RuntimeError(_T("Invalid Cyrus generation options"));
    const bool keyed=count==32&&(v1?v1->data[0]:args[31])->to_bool()!=FALSE;
    amin::Settings s;
    if(v1&&v1->size==10) {
        if(v1->data[8]->to_int()!=1)throw RuntimeError(_T("Unsupported procedural sampler version"));
        const auto start=v1->data[9]->to_int64();
        if(start<0)throw RuntimeError(_T("Negative candidate ordinal"));
        s.stableCandidates=true;s.candidateStart=static_cast<std::uint64_t>(start);
    }
    if(count>=29) {
        type_check(args[28],Array,_T("spacing controls"));
        auto* a=static_cast<Array*>(args[28]);
        if(a->size!=6) throw RuntimeError(_T("Spacing needs collision enabled/radius and relax enabled/spacing/iterations/strength."));
        s.collisionEnabled=a->data[0]->to_bool()!=FALSE;s.collisionRadius=a->data[1]->to_float();
        s.relaxEnabled=a->data[2]->to_bool()!=FALSE;s.relaxSpacing=a->data[3]->to_float();
        const int iterations=a->data[4]->to_int();
        if(iterations<0||iterations>100) throw RuntimeError(_T("Relax iterations must be 0..100."));
        s.relaxIterations=iterations;s.relaxStrength=a->data[5]->to_float();
    }
    if(count>=30) {
        type_check(args[29],Array,_T("source weights"));
        auto* a=static_cast<Array*>(args[29]);
        for(int i=0;i<a->size;++i) s.sourceWeights.push_back(a->data[i]->to_float());
    }
    if(count>=27) s.preserveDensity=args[26]->to_bool()!=FALSE;
    if(count>=28) {
        type_check(args[27],Array,_T("line pattern"));
        auto* pattern=static_cast<Array*>(args[27]);
        if(pattern->size!=3) throw RuntimeError(_T("Line pattern needs enabled, rest group and bands."));
        s.linePattern=pattern->data[0]->to_bool()!=FALSE;
        if(s.linePattern) {
            s.restGroup=static_cast<std::uint32_t>(pattern->data[1]->to_int());
            type_check(pattern->data[2],Array,_T("line bands"));
            auto* bands=static_cast<Array*>(pattern->data[2]);
            const auto time=GetCOREInterface()->GetTime();
            for(int i=0;i<bands->size;++i) {
                type_check(bands->data[i],Array,_T("line band"));
                auto* row=static_cast<Array*>(bands->data[i]);
                if(row->size!=3&&row->size!=6&&row->size!=7&&row->size!=9&&row->size!=10&&row->size!=11&&row->size!=12&&row->size!=13) throw RuntimeError(_T("Invalid stroke row."));
                const bool analyzed=row->size>=9;
                auto* node=analyzed?nullptr:row->data[0]->to_node();
                ShapeObject* shape=nullptr;
                if(!analyzed) {
                if(!node) throw RuntimeError(_T("Missing line pattern node."));
                auto* obj=node->EvalWorldState(time).obj;
                if(!obj||obj->SuperClassID()!=SHAPE_CLASS_ID) throw RuntimeError(_T("Line pattern requires closed spline shapes."));
                shape=static_cast<ShapeObject*>(obj);
                }
                amin::LineBand band;band.width=row->data[1]->to_float();band.group=static_cast<std::uint32_t>(row->data[2]->to_int());
                if(row->size>=6) {
                    type_check(row->data[3],Array,_T("stroke sources"));
                    auto* choices=static_cast<Array*>(row->data[3]);
                    if(choices->size==0) throw RuntimeError(_T("Select sources or color groups for every stroke."));
                    for(int k=0;k<choices->size;++k) {
                        const int choice=choices->data[k]->to_int();
                        if(choice<1) throw RuntimeError(_T("Invalid stroke source index."));
                        band.sources.push_back(static_cast<std::uint32_t>(choice-1));
                    }
                    band.scaleMin=row->data[4]->to_float();band.scaleMax=row->data[5]->to_float();
                    if(row->size==7) band.inside=row->data[6]->to_bool()!=FALSE;
                }
                if(analyzed) {
                    if(row->size>=10){
                        type_check(row->data[9],Array,_T("Boundary edge mask"));
                        auto* mask=static_cast<Array*>(row->data[9]);
                        for(int m=0;m<mask->size;++m) band.boundaryMask.push_back(mask->data[m]->to_bool()!=FALSE);
                    }
                    if(row->size>=11) band.straightEnds=row->data[10]->to_bool()!=FALSE;
                    band.kind=row->data[7]->to_int();band.start=row->data[8]->to_float();
                    if(row->size>=13){type_check(row->data[12],Array,_T("Edge settings"));auto* e=static_cast<Array*>(row->data[12]);if(e->size!=3&&e->size!=6&&e->size!=9)throw RuntimeError(_T("Invalid edge settings"));if(e->size>=6){band.edgeKeepCorners=e->data[3]->to_bool()!=FALSE;band.edgeCornerAngle=e->data[4]->to_float();band.edgeCornerCount=e->data[5]->to_int();}band.edgeOffset=e->data[0]->to_float();band.edgeAlongJitter=e->data[1]->to_float();band.edgeAcrossJitter=e->data[2]->to_float();}
                    type_check(row->data[0],Array,_T("Analyzer paths"));
                    auto* paths=static_cast<Array*>(row->data[0]);
                    for(int k=0;k<paths->size;++k) {
                        type_check(paths->data[k],Array,_T("Analyzer path"));
                        auto* path=static_cast<Array*>(paths->data[k]);std::vector<amin::Vec3> points;
                        for(int v=0;v<path->size;++v) points.push_back(vec(path->data[v]->to_point3()));
                        band.boundary.loops.push_back(std::move(points));
                    }
                } else {
                const auto tm=node->GetObjectTM(time);
                for(int curve=0;curve<shape->NumberOfCurves(time);++curve) {
                    if(!shape->CurveClosed(time,curve)) throw RuntimeError(_T("Line pattern: every spline must be closed."));
                    const int pieces=shape->NumberOfPieces(time,curve);
                    if(pieces<1||pieces>1024) throw RuntimeError(_T("Line pattern is empty or too complex."));
                    const int steps=std::max(3,pieces*64);
                    std::vector<amin::Vec3> loop;loop.reserve(steps);
                    for(int k=0;k<steps;++k) loop.push_back(vec(shape->InterpCurve3D(time,curve,static_cast<float>(k)/steps,PARAM_SIMPLE)*tm));
                    band.boundary.loops.push_back(std::move(loop));
                }
                }
                s.lineBands.push_back(std::move(band));
            }
        }
    }
    const int n=args[1]->to_int(), ns=args[3]->to_int();
    if(n<0||n>100000||ns<1) throw RuntimeError(_T("Count must be 0..100000 and sources nonempty."));
    s.count=n;s.seed=args[2]->to_int();s.sourceCount=ns;s.uniformScale={1,1};
    if(count>=18) {
        type_check(args[17],Array,_T("source groups"));
        const auto* groups=static_cast<Array*>(args[17]);
        if(groups->size!=ns) throw RuntimeError(_T("One color group per source required."));
        for(int i=0;i<ns;++i) s.sourceGroups.push_back(static_cast<std::uint32_t>(groups->data[i]->to_int()));
    }
    if(count>=24) {
        s.clusterEnabled=args[18]->to_bool()!=FALSE;s.clusterSize=args[19]->to_float();s.clusterSeed=args[20]->to_int();
        s.clusterRoughness=args[21]->to_float();s.clusterBlur=args[22]->to_float();s.clusterNoise=args[23]->to_float();
    }
    if(count>=26) {
        type_check(args[24],Array,_T("area nodes"));type_check(args[25],Array,_T("area modes"));
        auto* nodes=static_cast<Array*>(args[24]);auto* modes=static_cast<Array*>(args[25]);
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
    s.distribution=args[12]->to_int();s.clusterCount=args[13]->to_int();s.clusterRadius=args[14]->to_float();
    if(s.distribution==2) {
        type_check(args[15],Array,_T("density array"));
        const auto* pixels=static_cast<Array*>(args[15]);const int width=args[16]->to_int();
        if(width<2||width>512||pixels->size!=width*width) throw RuntimeError(_T("Density image must be a square 2..512 grid."));
        s.densityWidth=s.densityHeight=width;s.density.reserve(pixels->size);
        for(int i=0;i<pixels->size;++i) s.density.push_back(pixels->data[i]->to_float());
    }
    // Preserve the existing non-advanced randomization when adding a Brush to
    // a layer. The general path must not quietly substitute XYZ defaults.
    if(v1&&v1->data[1]->to_bool()){
        s.axisScale={{{1,1},{1,1},{1,1}}};s.uniformScale={v1->data[2]->to_float(),v1->data[3]->to_float()};
        const auto tilt=v1->data[4]->to_float(),lo=v1->data[5]->to_float(),hi=v1->data[6]->to_float(),move=v1->data[7]->to_float();
        s.rotationDegrees={{{-tilt,tilt},{-tilt,tilt},{lo,hi}}};s.movement={{{-move,move},{-move,move},{-move,move}}};
    }
    std::vector<amin::Instance> instances;
    try {
        const auto mesh=surfaceMeshes(args[0],s.distribution==2);
        if(count>=31 && args[30]!=&undefined) {
            type_check(args[30],Array,_T("final pass"));auto* f=static_cast<Array*>(args[30]);
            if(f->size!=14)throw RuntimeError(_T("Invalid final pass payload"));
            auto rows=[](Value* v){type_check(v,Array,_T("final rows"));auto* a=static_cast<Array*>(v);std::vector<amin::Instance> out;
                for(int i=0;i<a->size;++i){type_check(a->data[i],Array,_T("placement"));out.push_back(placementInstance(static_cast<Array*>(a->data[i])));}return out;};
            auto radii=[](Value* v){type_check(v,Array,_T("radii"));auto* a=static_cast<Array*>(v);std::vector<double> out;for(int i=0;i<a->size;++i){double r=a->data[i]->to_float();if(!std::isfinite(r)||r<0)throw RuntimeError(_T("Invalid radius"));out.push_back(r);}return out;};
            amin::FinalSettings cfg;cfg.cleanup=f->data[4]->to_bool()!=FALSE;cfg.radius=f->data[5]->to_float();
            cfg.minNeighbors=f->data[6]->to_int();cfg.minIsland=f->data[7]->to_int();cfg.relax=f->data[8]->to_bool()!=FALSE;
            cfg.strength=f->data[9]->to_float();cfg.iterations=f->data[10]->to_int();cfg.maxMove=f->data[11]->to_float();cfg.gap=f->data[12]->to_float();cfg.planar=f->data[13]->to_bool()!=FALSE;
            instances=amin::finalize(mesh,amin::prepareEdgeRows(s),rows(f->data[0]),rows(f->data[1]),radii(f->data[2]),radii(f->data[3]),cfg);
            if(keyed)for(auto& p:instances)anchorInstance(p,mesh);
        } else {
            instances=amin::scatter(mesh,s);
            if(keyed)for(auto& p:instances)anchorInstance(p,mesh);
        }
    }
    catch(const std::exception&) {throw RuntimeError(_T("Invalid scatter settings or surface. Check UV channel 1, min/max ranges, and line pattern width, closed XY shapes and source color groups."));}
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
Value* cyrusScatterAdvanced_cf(Value** args,int count){return aminScatterAdvanced_cf(args,count);}
#include "procedural_bridge.inc"
def_visible_primitive(cyrusProceduralSurfaceKey,"cyrusProceduralSurfaceKey");
Value* cyrusProceduralSurfaceKey_cf(Value** a,int n){
    check_arg_count(cyrusProceduralSurfaceKey,1,n);std::uint64_t hash=1469598103934665603ULL;
    try{
        const auto triangles=surfaceMeshes(a[0],false);
        for(const auto& t:triangles)for(const auto p:{t.a,t.b,t.c})for(double value:{p.x,p.y,p.z}){
            std::uint64_t bits=0;std::memcpy(&bits,&value,sizeof(bits));
            for(int byte=0;byte<8;++byte){hash^=(bits>>(byte*8))&255;hash*=1099511628211ULL;}
        }
        const auto key=std::to_wstring(triangles.size())+L":"+std::to_wstring(hash);return new String(key.c_str());
    }catch(const std::exception& e){throw RuntimeError(MSTR::FromACP(e.what()));}
}
#include "orientation_bridge.inc"
#include "boundary_falloff_bridge.inc"
#include "whole_scale_bridge.inc"
#include "analyzer_area_bridge.inc"
def_visible_primitive(aminScatterTransforms, "aminScatterTransforms");
Value* aminScatterTransforms_cf(Value** args,int count) {
    check_arg_count(aminScatterTransforms,10,count);
    if(!cyrusBoundaryAllows(args))throw RuntimeError(_T("Cyrus new generation requires authoring authority"));
    const int n=args[1]->to_int(), sourceCount=args[3]->to_int();
    if(n<1||n>100000||sourceCount<1) throw RuntimeError(_T("Count must be 1..100000; sources must be nonempty."));
    amin::Settings s;
    s.count=n;s.seed=args[2]->to_int();s.sourceCount=sourceCount;
    s.uniformScale={args[4]->to_float(),args[5]->to_float()};
    const Point3 lo=args[6]->to_point3(),hi=args[7]->to_point3(),move=args[8]->to_point3();
    for(int i=0;i<3;++i) {s.rotationDegrees[i]={lo[i],hi[i]};s.movement[i]={-move[i],move[i]};}
    s.alignToNormal=args[9]->to_bool()!=FALSE;
    std::vector<amin::Instance> instances;
    try {instances=amin::scatter(meshOf(args[0]->to_node(),true),s);}
    catch(const std::exception&) {throw RuntimeError(_T("Scatter failed: check mesh, scale and randomization ranges."));}
    two_typed_value_locals(Array* result, Array* row);
    vl.result=new Array(static_cast<int>(instances.size()));
    for(const auto& v:instances) {
        vl.row=new Array(2);vl.result->append(vl.row);
        Matrix3 tm(point(v.xAxis*v.scale),point(v.yAxis*v.scale),point(v.zAxis*v.scale),point(v.position));
        vl.row->append(new Matrix3Value(tm));vl.row->append(Integer::intern(v.source+1));
    }
    return_value(vl.result);
}

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




