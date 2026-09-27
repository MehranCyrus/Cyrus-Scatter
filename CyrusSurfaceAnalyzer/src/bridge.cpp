#include <max.h>
#include <triobj.h>
#include <maxscript/maxscript.h>
#include <maxscript/foundation/arrays.h>
#include <maxscript/foundation/numbers.h>
#include <maxscript/foundation/3dmath.h>
#include <maxscript/maxwrapper/mxsobjects.h>
#include <memory>
#include <stdexcept>
#include "analyzer.h"
#include <maxscript/macros/define_instantiation_functions.h>
extern "C" __declspec(dllexport) const TCHAR* LibDescription(){return _T("Cyrus Surface Analyzer 0.5");}
extern "C" __declspec(dllexport) ULONG LibVersion(){return VERSION_3DSMAX;}
extern "C" __declspec(dllexport) void LibInit(){}
BOOL WINAPI DllMain(HINSTANCE,DWORD,LPVOID){return TRUE;}
static Point3 point(cyrus::V p){return Point3(float(p.x),float(p.y),float(p.z));}
def_visible_primitive(cyrusAnalyzeSurface,"cyrusAnalyzeSurface");
Value* cyrusAnalyzeSurface_cf(Value** args,int count){
 if(count!=7 && count!=8 && count!=9 && count!=11) throw RuntimeError(_T("Expected 7, 8, 9 or 11 arguments."));
 cyrus::Result result;
 try{
 auto*n=args[0]->to_node();auto time=GetCOREInterface()->GetTime();auto*o=n->EvalWorldState(time).obj;
 if(!o||!o->CanConvertToType(Class_ID(TRIOBJ_CLASS_ID,0)))throw std::runtime_error("Surface must be convertible to mesh.");
 auto*tri=static_cast<TriObject*>(o->ConvertToType(time,Class_ID(TRIOBJ_CLASS_ID,0)));
 auto cleanup=[o](TriObject*p){if(p!=o)p->DeleteThis();};std::unique_ptr<TriObject,decltype(cleanup)> hold(tri,cleanup);
 auto&mesh=tri->GetMesh();auto tm=n->GetObjectTM(time);cyrus::Mesh m;
 for(int i=0;i<mesh.numVerts;i++){auto p=mesh.verts[i]*tm;m.vertices.push_back({p.x,p.y,p.z});}
 for(int i=0;i<mesh.numFaces;i++){auto&f=mesh.faces[i];m.faces.push_back({int(f.v[0]),int(f.v[1]),int(f.v[2])});}
 cyrus::Settings s;s.mode=args[1]->to_int();s.minWidth=args[2]->to_float();s.minLength=args[3]->to_float();s.count=args[4]->to_int();s.resolution=args[5]->to_int();s.ringFraction=args[6]->to_float();if(count>=8){s.pointRadius=args[7]->to_float();if(!(s.pointRadius>0))throw std::runtime_error("Point radius must be positive.");}if(count>=9)s.minimumPoints=args[8]->to_int();if(count==11){s.fitRadius=args[9]->to_float();s.relaxIterations=args[10]->to_int();}result=cyrus::analyze(m,s);
 }catch(const std::exception&e){std::string str=e.what();std::wstring wide(str.begin(),str.end());throw RuntimeError(wide.c_str());}
 two_typed_value_locals(Array* out,Array* row);vl.out=new Array(7);
 for(auto*paths:{&result.boundaries,&result.paths}){vl.row=new Array(int(paths->size()));vl.out->append(vl.row);for(auto&a:*paths){auto*row=new Array(int(a.size()));vl.row->append(row);for(auto p:a)row->append(new Point3Value(point(p)));}}
 vl.row=new Array(int(result.points.size()));vl.out->append(vl.row);for(auto p:result.points)vl.row->append(new Point3Value(point(p)));
 vl.out->append(Double::intern(result.area));vl.out->append(Double::intern(result.regionArea));vl.out->append(Double::intern(result.pathLength));vl.out->append(Integer::intern(result.mode));for(auto* values:{&result.elementModes,&result.elementPointCounts,&result.elementRelaxed}){vl.row=new Array(int(values->size()));vl.out->append(vl.row);for(int v:*values)vl.row->append(Integer::intern(v));}return_value(vl.out);
}



