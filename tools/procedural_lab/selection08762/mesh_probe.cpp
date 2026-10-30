// Private independent brute-force CPU mesh reference, never packaged.
#include <max.h>
#include <triobj.h>
#include <cfloat>
#include <cmath>
#include <maxscript/maxscript.h>
#include <maxscript/foundation/3dmath.h>
#include <maxscript/maxwrapper/mxsobjects.h>
#include <maxscript/macros/define_instantiation_functions.h>
#undef ScripterExport
#define ScripterExport __declspec(dllexport)
extern "C" __declspec(dllexport) void LibInit(){}
extern "C" __declspec(dllexport) const MCHAR* LibDescription(){return L"Cyrus two-sided selection reference only";}
extern "C" __declspec(dllexport) int LibNumberClasses(){return 0;}
extern "C" __declspec(dllexport) ClassDesc* LibClassDesc(int){return nullptr;}
extern "C" __declspec(dllexport) ULONG LibVersion(){return VERSION_3DSMAX;}
extern "C" __declspec(dllexport) ULONG CanAutoDefer(){return 0;}
def_visible_primitive(selectionProbeMesh,"selectionProbeMesh");
Value* selectionProbeMesh_cf(Value** a,int count){
 check_arg_count(selectionProbeMesh,3,count);auto* ip=GetCOREInterface();auto* node=a[0]->to_node();auto state=node->EvalWorldState(ip->GetTime());
 auto* tri=static_cast<TriObject*>(state.obj->ConvertToType(ip->GetTime(),triObjectClassID));if(!tri)return &undefined;
 auto& view=ip->GetActiveViewExp();Ray ray;view.MapScreenToWorldRay(float(a[1]->to_int()),float(a[2]->to_int()),ray);ray.dir=Normalize(ray.dir);
 const auto tm=node->GetObjectTM(ip->GetTime());const auto inverse=Inverse(tm);const auto origin=ray.p*inverse,dir=VectorTransform(inverse,ray.dir);
 float best=FLT_MAX;const auto& mesh=tri->GetMesh();
 for(int f=0;f<mesh.getNumFaces();++f){const auto& face=mesh.faces[f];auto v0=mesh.verts[face.v[0]],edge1=mesh.verts[face.v[1]]-v0,edge2=mesh.verts[face.v[2]]-v0;
  const auto h=CrossProd(dir,edge2);const double det=DotProd(edge1,h);if(std::abs(det)<1e-18)continue;
  const auto s=origin-v0;const double u=DotProd(s,h)/det;if(u<0||u>1)continue;const auto q=CrossProd(s,edge1);const double v=DotProd(dir,q)/det;if(v<0||u+v>1)continue;
  const float distance=float(DotProd(edge2,q)/det);if(distance>=0&&distance<best)best=distance;
 }
 if(tri!=state.obj)tri->DeleteThis();return best==FLT_MAX?&undefined:static_cast<Value*>(new Point3Value(ray.p+ray.dir*best));
}
