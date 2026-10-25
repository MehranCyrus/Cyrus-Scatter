#include <nlohmann/json.hpp>
#include <fstream>
#include <filesystem>
#include <numeric>
#include <vector>
#include <map>
#include <max.h>
#include <triobj.h>
#include <units.h>
#include <maxscript/maxscript.h>
#include <maxscript/foundation/numbers.h>
#include <maxscript/foundation/strings.h>
#include <maxscript/maxwrapper/mxsobjects.h>
#include <maxscript/macros/define_instantiation_functions.h>
static_assert(MAX_PRODUCT_YEAR_NUMBER==2027);
namespace {
using Json=nlohmann::json;
struct Dsu {std::vector<unsigned> p;explicit Dsu(unsigned n):p(n){std::iota(p.begin(),p.end(),0u);}unsigned get(unsigned a){while(p[a]!=a){p[a]=p[p[a]];a=p[a];}return a;}void join(unsigned a,unsigned b){a=get(a);b=get(b);if(a!=b)p[b]=a;}};
void inspect(INode* node,const std::filesystem::path& base){
    auto t=GetCOREInterface()->GetTime();auto* object=node->EvalWorldState(t).obj;
    if(!object||!object->CanConvertToType(triObjectClassID))throw std::runtime_error("Choose a mesh.");
    auto* tri=static_cast<TriObject*>(object->ConvertToType(t,triObjectClassID));
    try{auto& mesh=tri->GetMesh();if(mesh.numVerts>2000000||mesh.numFaces>4000000)throw std::runtime_error("Mesh admission limit.");
        Dsu dsu(mesh.numVerts);for(int i=0;i<mesh.numFaces;++i){auto f=mesh.faces[i];dsu.join(f.v[0],f.v[1]);dsu.join(f.v[1],f.v[2]);}
        std::map<unsigned,unsigned> compact;std::vector<unsigned> labels(mesh.numVerts);for(int i=0;i<mesh.numVerts;++i){auto root=dsu.get(i);auto [it,inserted]=compact.try_emplace(root,unsigned(compact.size()));labels[i]=it->second;}
        auto tm=node->GetObjectTM(t);double unit=GetSystemUnitScale(UNITS_METERS);
        std::vector<Point3> positions;positions.reserve(mesh.numVerts);Json rows=Json::array();
        for(unsigned i=0;i<compact.size();++i)rows.push_back({{"id",i},{"vertices",0},{"faces",0},{"min",{FLT_MAX,FLT_MAX,FLT_MAX}},{"max",{-FLT_MAX,-FLT_MAX,-FLT_MAX}},{"materials",Json::object()}});
        for(int i=0;i<mesh.numVerts;++i){auto p=(mesh.verts[i]*tm)*float(unit);positions.push_back(p);auto& r=rows[labels[i]];r["vertices"]=r["vertices"].get<int>()+1;for(int k=0;k<3;++k){r["min"][k]=std::min(r["min"][k].get<float>(),p[k]);r["max"][k]=std::max(r["max"][k].get<float>(),p[k]);}}
        std::vector<std::array<unsigned,3>> faces;std::vector<unsigned> materials;
        for(int i=0;i<mesh.numFaces;++i){auto f=mesh.faces[i];faces.push_back({f.v[0],f.v[1],f.v[2]});materials.push_back(f.getMatID());auto& r=rows[labels[f.v[0]]];r["faces"]=r["faces"].get<int>()+1;auto key=std::to_string(f.getMatID());r["materials"][key]=r["materials"].value(key,0)+1;}
        auto bin=base;bin+=L".bin";std::ofstream out(bin,std::ios::binary);unsigned header[]{0x53544c32u,unsigned(mesh.numVerts),unsigned(mesh.numFaces),unsigned(compact.size())};out.write(reinterpret_cast<char*>(header),sizeof(header));out.write(reinterpret_cast<char*>(positions.data()),positions.size()*sizeof(Point3));out.write(reinterpret_cast<char*>(faces.data()),faces.size()*sizeof(faces[0]));out.write(reinterpret_cast<char*>(materials.data()),materials.size()*4);out.write(reinterpret_cast<char*>(labels.data()),labels.size()*4);if(!out)throw std::runtime_error("Export failed.");out.close();
        Json report={{"vertices",int(mesh.numVerts)},{"triangles",int(mesh.numFaces)},{"unit",unit},{"components",rows}};auto json=base;json+=L".json";std::ofstream meta(json);meta<<report.dump(2);if(!meta)throw std::runtime_error("Metadata failed.");
    }catch(...){if(tri!=object)tri->DeleteThis();throw;}if(tri!=object)tri->DeleteThis();
}
}
extern "C" __declspec(dllexport) const MCHAR* LibDescription(){return _T("Cyrus stem topology inspector - Max 2027");}
extern "C" __declspec(dllexport) ULONG LibVersion(){return VERSION_3DSMAX;}
extern "C" __declspec(dllexport) int LibNumberClasses(){return 0;}
extern "C" __declspec(dllexport) ClassDesc* LibClassDesc(int){return nullptr;}
extern "C" __declspec(dllexport) ULONG CanAutoDefer(){return 0;}
extern "C" __declspec(dllexport) void LibInit(){}
BOOL WINAPI DllMain(HINSTANCE,DWORD,LPVOID){return TRUE;}
def_visible_primitive(cvsInspect,"cvsInspect");
Value* cvsInspect_cf(Value** a,int n){check_arg_count(cvsInspect,2,n);try{inspect(a[0]->to_node(),a[1]->to_string());return &true_value;}catch(const std::exception&){throw RuntimeError(_T("Stem topology inspection failed; check the selected source and output path."));}}
