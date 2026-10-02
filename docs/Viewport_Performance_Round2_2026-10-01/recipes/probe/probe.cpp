// Isolated experiment only. Not part of the distributed Cyrus plugin.
#include <max.h>
#include <triobj.h>
#include <HWMesh.h>
#include <maxscript/maxscript.h>
#include <maxscript/foundation/arrays.h>
#include <maxscript/foundation/numbers.h>
#include <maxscript/foundation/3dmath.h>
#include <maxscript/maxwrapper/mxsobjects.h>
#include <array>
#include <vector>
#include <memory>
#include <algorithm>
#include <maxscript/macros/define_instantiation_functions.h>
#undef ScripterExport
#define ScripterExport __declspec(dllexport)

extern "C" __declspec(dllexport) const TCHAR* LibDescription(){return _T("Cyrus isolated viewport experiment");}
extern "C" __declspec(dllexport) ULONG LibVersion(){return VERSION_3DSMAX;}
extern "C" __declspec(dllexport) void LibInit(){}
extern "C" __declspec(dllexport) int LibNumberClasses(){return 0;}
extern "C" __declspec(dllexport) ClassDesc* LibClassDesc(int){return nullptr;}
BOOL WINAPI DllMain(HINSTANCE,DWORD,LPVOID){return TRUE;}

visible_class_debug_ok(CyrusProbeCache)
class CyrusProbeCache:public Value {
public:
 struct FaceData{std::array<Point3,3> p;Point3 rgb;};
 std::vector<FaceData> triangles;
 Mesh mesh;
 std::vector<std::unique_ptr<GFX_MESH::HWTupleMesh>> hardware;
 int hardwareCreated=0;
 CyrusProbeCache(){tag=class_tag(CyrusProbeCache);}
 classof_methods(CyrusProbeCache,Value);
 void collect()override{delete this;}
 void sprin1(CharStream* s)override{s->printf(_T("<CyrusViewportProbe:%d>"),int(triangles.size()));}
 Value* deep_copy(HashTable*)override{return this;}
 void prepare(){
  const int n=int(triangles.size());
  mesh.setNumVerts(n*3);mesh.setNumFaces(n);mesh.setNumVertCol(n);mesh.setNumVCFaces(n);
  for(int i=0;i<n;++i){
   for(int j=0;j<3;++j)mesh.setVert(i*3+j,triangles[i].p[j]);
   mesh.faces[i].setVerts(i*3,i*3+1,i*3+2);mesh.faces[i].setSmGroup(0);mesh.faces[i].setEdgeVisFlags(0,0,0);
   mesh.vertCol[i]=triangles[i].rgb;mesh.vcFace[i].setTVerts(i,i,i);
  }
  mesh.setVCDisplayData(0);mesh.buildNormals();
  constexpr DWORD type=GFX_MESH::kPos|GFX_MESH::kNormal|GFX_MESH::kVC0;
  for(int first=0;first<n;first+=4096){
   const int count=std::min(4096,n-first);
   auto h=std::make_unique<GFX_MESH::HWTupleMesh>(type);
   auto* vb=h->GetHWVertexBuffer();vb->SetHasConnectionData(false);
   if(!vb->CreateBuffer(count*3))throw RuntimeError(_T("Probe vertex allocation failed"));
   const auto id=h->AddHWIndexBuffer(count,GFX_MESH::kTriangleList,true);
   auto* ib=h->GetHWIndexBuffer(id);
   for(int f=0;f<count;++f){
    const auto& t=triangles[first+f];
    const auto normal=Normalize(CrossProd(t.p[1]-t.p[0],t.p[2]-t.p[0]));
    auto byte=[](float v){return DWORD(std::clamp(v,0.f,1.f)*255.f+.5f);};
    const DWORD color=0xff000000u|(byte(t.rgb.x)<<16)|(byte(t.rgb.y)<<8)|byte(t.rgb.z);
    auto index=ib->GetHWIndex16Bit(f);
    for(int j=0;j<3;++j){auto v=vb->GetHWVert(f*3+j);v.SetPos(t.p[j]);v.SetNormal(normal);v.SetVC(0,color);index[j]=WORD(f*3+j);}
   }
   h->SetMatID(0);hardware.push_back(std::move(h));
  }
 }
};
visible_class_instance(CyrusProbeCache,"CyrusProbeCache");

def_visible_primitive(cyrusProbeBuild,"cyrusProbeBuild");
Value* cyrusProbeBuild_cf(Value** args,int count){
 check_arg_count(cyrusProbeBuild,1,count);type_check(args[0],Array,_T("probe triangles"));
 auto* rows=static_cast<Array*>(args[0]);
 if(rows->size>100000)throw RuntimeError(_T("Probe limited to 100000 faces"));
 std::vector<CyrusProbeCache::FaceData> faces;faces.reserve(rows->size);
 for(int i=0;i<rows->size;++i){
  type_check(rows->data[i],Array,_T("probe triangle"));auto* row=static_cast<Array*>(rows->data[i]);
  if(row->size!=5)throw RuntimeError(_T("Expected triangle/shade/color row"));
  faces.push_back({{row->data[0]->to_point3(),row->data[1]->to_point3(),row->data[2]->to_point3()},row->data[4]->to_point3()*row->data[3]->to_float()});
 }
 auto out=std::make_unique<CyrusProbeCache>();out->triangles=std::move(faces);out->prepare();return out.release();
}

def_visible_primitive(cyrusProbeDraw,"cyrusProbeDraw");
Value* cyrusProbeDraw_cf(Value** args,int count){
 check_arg_count(cyrusProbeDraw,2,count);type_check(args[0],CyrusProbeCache,_T("probe"));
 auto* c=static_cast<CyrusProbeCache*>(args[0]);const int mode=args[1]->to_int();
 auto& view=MAXScript_interface->GetActiveViewExp();if(!view.IsAlive())return &ok;
 auto* gw=view.getGW();if(!gw)return &ok;
 const auto limits=gw->getRndLimits();Material previous=*gw->getMaterial(),m;
 m.Ka=m.Kd=Point3(1,1,1);m.Ks=Point3(0,0,0);m.selfIllum=1;m.opacity=1;m.dblSided=1;
 gw->setTransform(Matrix3(1));gw->setMaterial(m);
 gw->setRndLimits((limits|GW_Z_BUFFER|GW_COLOR_VERTS)&~(GW_ILLUM|GW_WIREFRAME|GW_BACKCULL|GW_TEXTURE|GW_SHADE_CVERTS));
 if(mode==1)c->mesh.render(gw,&m,nullptr,COMP_ALL,1);
 else if(mode==2){
  for(auto& h:c->hardware){
   if(!h->GetGFXMesh()){auto* gpu=gw->CreateHWDrawMesh(h.get());if(gpu){h->SetGFXMesh(gpu);++c->hardwareCreated;}}
   gw->DrawHWDrawMesh(h.get());
  }
 }else{
  gw->startTriangles();for(auto& f:c->triangles){Point3 colors[3]={f.rgb,f.rgb,f.rgb};gw->triangle(f.p.data(),colors);}gw->endTriangles();
 }
 gw->setMaterial(previous);gw->setRndLimits(limits);return &ok;
}

def_visible_primitive(cyrusProbeStats,"cyrusProbeStats");
Value* cyrusProbeStats_cf(Value** args,int count){
 check_arg_count(cyrusProbeStats,1,count);type_check(args[0],CyrusProbeCache,_T("probe"));
 auto* c=static_cast<CyrusProbeCache*>(args[0]);one_typed_value_local(Array* result);vl.result=new Array(3);
 vl.result->append(Integer::intern(int(c->triangles.size())));vl.result->append(Integer::intern(int(c->hardware.size())));vl.result->append(Integer::intern(c->hardwareCreated));return_value(vl.result);
}

def_visible_primitive(cyrusProbeMesh,"cyrusProbeMesh");
Value* cyrusProbeMesh_cf(Value** args,int count){
 check_arg_count(cyrusProbeMesh,1,count);type_check(args[0],CyrusProbeCache,_T("probe"));
 auto* c=static_cast<CyrusProbeCache*>(args[0]);return new MeshValue(new Mesh(c->mesh),TRUE);
}
