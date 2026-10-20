#include "cyrus_arrange/geometry.h"
#include "cyrus_arrange/receiving_mesh.h" // Before MAXScript macros.
#include "arrange_document.h"
#include <max.h>
#include <triobj.h>
#include <units.h>
#include <maxscript/maxscript.h>
#include <maxscript/foundation/arrays.h>
#include <maxscript/foundation/numbers.h>
#include <maxscript/foundation/strings.h>
#include <maxscript/foundation/3dmath.h>
#include <maxscript/maxwrapper/mxsobjects.h>
#include <algorithm>
#include <cmath>
#include <filesystem>
#include <fstream>
#include <iomanip>
#include <limits>
#include <locale>
#include <memory>
#include <set>
#include <sstream>
#include <stdexcept>
#include <string>
#include <vector>
#include <maxscript/macros/define_instantiation_functions.h>

static_assert(MAX_PRODUCT_YEAR_NUMBER == CYRUS_MAX_YEAR && CYRUS_MAX_YEAR == 2027,
              "Cyrus Arrange requires the Max 2027 SDK");

namespace {
namespace ca = cyrus::arrange;
constexpr const wchar_t* version = L"0.3.2";
constexpr std::size_t max_nodes = 4096;
constexpr std::size_t max_overlay_cells = 250000;
HINSTANCE module_instance = nullptr;

struct Source { ULONG handle{}; std::wstring name; };
struct Snapshot {
    ca::Result result;
    ca::Settings settings;
    ca::Vec3 origin_mm;
    double captured_mm_per_unit{};
    TimeValue time{};
    std::vector<Source> sources;
    std::size_t usable_cells{};
    double sampled_area_mm2{}, usable_area_mm2{};
};
// All entry points enforce Max's main thread. No Max pointer is cached.
std::unique_ptr<Snapshot> snapshot;

std::wstring wide(const std::string& input) {
    if (input.empty()) return {};
    const int size = MultiByteToWideChar(CP_UTF8, MB_ERR_INVALID_CHARS,
        input.data(), static_cast<int>(input.size()), nullptr, 0);
    if (size <= 0) return L"Cyrus Arrange native operation failed.";
    std::wstring output(static_cast<std::size_t>(size), L'\0');
    MultiByteToWideChar(CP_UTF8, MB_ERR_INVALID_CHARS, input.data(),
        static_cast<int>(input.size()), output.data(), size);
    return output;
}
std::string utf8(const std::wstring& input) {
    if (input.empty()) return {};
    const int size = WideCharToMultiByte(CP_UTF8, 0, input.data(),
        static_cast<int>(input.size()), nullptr, 0, nullptr, nullptr);
    if (size <= 0) throw std::runtime_error("Cannot encode a scene name as UTF-8.");
    std::string output(static_cast<std::size_t>(size), '\0');
    if (!WideCharToMultiByte(CP_UTF8, 0, input.data(), static_cast<int>(input.size()),
        output.data(), size, nullptr, nullptr))
        throw std::runtime_error("Cannot encode a scene name as UTF-8.");
    return output;
}
void require_main_thread() {
    const HWND window = GetCOREInterface()->GetMAXHWnd();
    if (!window || GetWindowThreadProcessId(window, nullptr) != GetCurrentThreadId())
        throw std::runtime_error("Call Cyrus Arrange from the 3ds Max main thread.");
}
template<class Function> Value* api(Function&& function) {
    try {
        require_main_thread();
        return function();
    } catch (const std::exception& error) {
        throw RuntimeError(wide(error.what()).c_str());
    }
}
const Snapshot& current() {
    if (!snapshot) throw std::runtime_error("Inspect furniture first; no captured snapshot exists.");
    return *snapshot;
}
bool finite(ca::Vec3 p) {
    return std::isfinite(p.x) && std::isfinite(p.y) && std::isfinite(p.z);
}
ca::Vec3 add(ca::Vec3 a, ca::Vec3 b) { return {a.x+b.x, a.y+b.y, a.z+b.z}; }
ca::Vec3 subtract(ca::Vec3 a, ca::Vec3 b) { return {a.x-b.x, a.y-b.y, a.z-b.z}; }
ca::Vec3 multiply(ca::Vec3 a, double scale) { return {a.x*scale, a.y*scale, a.z*scale}; }
ca::Vec3 vector(Point3 p) { return {p.x,p.y,p.z}; }
Point3 point(ca::Vec3 p) {
    const Point3 value(static_cast<float>(p.x), static_cast<float>(p.y), static_cast<float>(p.z));
    if (!finite(vector(value))) throw std::runtime_error("Coordinates exceed Max point precision.");
    return value;
}
double determinant(const Matrix3& matrix) {
    const auto a=vector(matrix.GetRow(0)), b=vector(matrix.GetRow(1)), c=vector(matrix.GetRow(2));
    return a.x*(b.y*c.z-b.z*c.y)-a.y*(b.x*c.z-b.z*c.x)+a.z*(b.x*c.y-b.y*c.x);
}
double units_mm() {
    const double scale = GetSystemUnitScale(UNITS_MILLIMETERS);
    if (!std::isfinite(scale) || scale <= 0)
        throw std::runtime_error("Scene system units cannot be converted to millimetres.");
    return scale;
}
bool generated(INode* node) {
    BOOL value=FALSE;
    return node->GetUserPropBool(_T("CyrusArrangeGenerated"),value) && value;
}
void collect_nodes(INode* root, std::set<ULONG>& visited, std::vector<INode*>& output,
                   std::size_t& skipped) {
    // Iteration bounds recursion depth for deeply nested group assemblies.
    std::vector<INode*> pending{root};
    while (!pending.empty()) {
        auto* node=pending.back(); pending.pop_back();
        if (!node) throw std::runtime_error("Selection contains a missing or deleted node.");
        if (!visited.insert(node->GetHandle()).second) continue;
        if (visited.size() > max_nodes)
            throw std::runtime_error("Selection exceeds the 4,096-node assembly limit.");
        if (generated(node)) { ++skipped; continue; }
        if (node->IsGroupHead()) {
            const int count=node->NumberOfChildren();
            if (count < 0 || static_cast<std::size_t>(count) > max_nodes-pending.size())
                throw std::runtime_error("Group expansion exceeds the 4,096-node assembly limit.");
            for (int i=0;i<count;++i) pending.push_back(node->GetChildNode(i));
        } else output.push_back(node);
    }
}
std::unique_ptr<Snapshot> capture(Array* roots, ca::Settings settings) {
    if (roots->size <= 0 || roots->size > static_cast<int>(max_nodes))
        throw std::runtime_error("Choose 1 to 4,096 mesh nodes or group heads.");
    if (!std::isfinite(settings.cell_size_mm) || settings.cell_size_mm < 0.1 || settings.cell_size_mm > 1000000 ||
        !std::isfinite(settings.minimum_clearance_mm) || settings.minimum_clearance_mm < 0 || settings.minimum_clearance_mm > 1000000000 ||
        !std::isfinite(settings.maximum_slope_degrees) || settings.maximum_slope_degrees < 0 ||
        settings.maximum_slope_degrees > 45)
        throw std::runtime_error("Use finite cell size 0.1..1,000,000 mm, clearance 0..1,000,000,000 mm, and slope 0..45 degrees.");
    auto next=std::make_unique<Snapshot>();
    next->settings=settings; next->time=GetCOREInterface()->GetTime();
    next->captured_mm_per_unit=units_mm();
    std::vector<INode*> nodes;
    std::set<ULONG> visited;
    std::size_t skipped=0;
    for (int i=0;i<roots->size;++i) collect_nodes(roots->data[i]->to_node(),visited,nodes,skipped);
    if (nodes.empty()) throw std::runtime_error("No input mesh remains after excluding generated overlays.");
    std::sort(nodes.begin(),nodes.end(),[](INode* a,INode* b){return a->GetHandle()<b->GetHandle();});
    ca::Mesh owned;std::vector<ca::Mesh> receiving;receiving.reserve(nodes.size());std::size_t captured_vertices=0,captured_triangles=0;
    bool have_origin=false;
    for (auto* node:nodes) {
        ca::Mesh part;
        const std::wstring name=node->GetName();
        const std::string label=utf8(name);
        // GetObjectTM is context-dependent. Explicitly query the final-pipeline
        // object-to-world frame before borrowing evaluated object/mesh pointers;
        // transform evaluation itself may invalidate the pipeline's cached mesh.
        const Matrix3 matrix=node->GetObjTMAfterWSM(next->time);
        Object* object=node->EvalWorldState(next->time).obj;
        if (!object || object->SuperClassID()!=GEOMOBJECT_CLASS_ID ||
            !object->CanConvertToType(Class_ID(TRIOBJ_CLASS_ID,0)))
            throw std::runtime_error("'"+label+"' is not supported evaluated triangle geometry; use an editable mesh copy or analysis proxy.");
        for (int axis=0;axis<4;++axis)
            if (!finite(vector(matrix.GetRow(axis))))
                throw std::runtime_error("'"+label+"' has a nonfinite object transform.");
        const double det=determinant(matrix);
        const auto length=[](Point3 p){return std::hypot(double(p.x),double(p.y),double(p.z));};
        const double magnitude=length(matrix.GetRow(0))*length(matrix.GetRow(1))*length(matrix.GetRow(2));
        if (!std::isfinite(det) || !std::isfinite(magnitude) || magnitude<=0 || std::abs(det)<=magnitude*1e-12)
            throw std::runtime_error("'"+label+"' has a singular or degenerate transform.");
        auto* converted=static_cast<TriObject*>(object->ConvertToType(next->time,Class_ID(TRIOBJ_CLASS_ID,0)));
        if (!converted) throw std::runtime_error("'"+label+"' failed triangle conversion.");
        const auto deleter=[object](TriObject* value){if(value && value!=object)value->DeleteThis();};
        std::unique_ptr<TriObject,decltype(deleter)> lifetime(converted,deleter);
        const auto& mesh=converted->GetMesh();
        if (mesh.numVerts<=0 || mesh.numFaces<=0)
            throw std::runtime_error("'"+label+"' has no triangle geometry.");
        if (static_cast<std::size_t>(mesh.numFaces)>settings.max_triangles-captured_triangles ||
            static_cast<std::size_t>(mesh.numVerts)>settings.max_triangles*3-captured_vertices)
            throw std::runtime_error("Assembly exceeds 1,000,000 triangles or 3,000,000 vertices; simplify the analysis geometry.");
        const std::uint32_t offset=0;
        part.vertices.reserve(part.vertices.size()+static_cast<std::size_t>(mesh.numVerts));
        part.triangles.reserve(part.triangles.size()+static_cast<std::size_t>(mesh.numFaces));
        const auto a=vector(matrix.GetRow(0)),b=vector(matrix.GetRow(1)),c=vector(matrix.GetRow(2)),d=vector(matrix.GetRow(3));
        for (int i=0;i<mesh.numVerts;++i) {
            const auto local=vector(mesh.verts[i]);
            if (!finite(local)) throw std::runtime_error("'"+label+"' contains a nonfinite vertex.");
            const auto world=multiply(add(add(add(multiply(a,local.x),multiply(b,local.y)),multiply(c,local.z)),d),next->captured_mm_per_unit);
            if (!finite(world)) throw std::runtime_error("'"+label+"' exceeds finite world-coordinate limits.");
            if (!have_origin) {next->origin_mm=world;have_origin=true;}
            part.vertices.push_back(subtract(world,next->origin_mm));
        }
        for (int i=0;i<mesh.numFaces;++i) {
            const auto& face=mesh.faces[i];
            for (int k=0;k<3;++k)
                if (face.v[k]>=static_cast<DWORD>(mesh.numVerts))
                    throw std::runtime_error("'"+label+"' contains an invalid triangle vertex index.");
            const int second=det<0?2:1, third=det<0?1:2;
            part.triangles.push_back({{offset+face.v[0],offset+face.v[second],offset+face.v[third]}});
        }
        captured_vertices+=part.vertices.size();captured_triangles+=part.triangles.size();receiving.push_back(std::move(part));
        next->sources.push_back({node->GetHandle(),name});
    }
    std::vector<ca::Mesh*> receiving_scope;receiving_scope.reserve(receiving.size());for(auto& mesh:receiving)receiving_scope.push_back(&mesh);
    ca::ReceivingMeshLimits limits;limits.max_work=settings.max_work;limits.max_triangles=settings.max_triangles;limits.max_vertices=settings.max_triangles*3;limits.max_coordinate_mm=1e9;
    const auto prepared=ca::prepare_receiving_meshes(receiving_scope,limits);
    if(prepared.work>=settings.max_work)throw std::runtime_error("Receiving preparation exhausted the inspection work allowance.");
    if(receiving.size()==1)owned=std::move(receiving.front());
    else{owned.vertices.reserve(captured_vertices);owned.triangles.reserve(captured_triangles);
        for(auto& mesh:receiving){const auto offset=static_cast<std::uint32_t>(owned.vertices.size());owned.vertices.insert(owned.vertices.end(),mesh.vertices.begin(),mesh.vertices.end());for(auto t:mesh.triangles){for(auto& i:t.vertices)i+=offset;owned.triangles.push_back(t);}std::vector<ca::Vec3>().swap(mesh.vertices);std::vector<ca::Triangle>().swap(mesh.triangles);}
    }
    auto sampling=settings;sampling.max_work-=prepared.work;next->result=ca::inspect(owned,sampling);next->result.work+=prepared.work;ca::append_receiving_warnings(next->result,prepared);
    if (skipped) next->result.warnings.push_back("Excluded "+std::to_string(skipped)+" generated overlay node(s).");
    next->result.warnings.push_back("Captured evaluated meshes only; renderer proxies may need a dedicated analysis mesh. Source changes require Inspect again.");
    for (const auto& region:next->result.regions) {
        next->sampled_area_mm2+=region.sampled_area_mm2;
        next->usable_area_mm2+=region.usable_area_mm2;
        for (const auto& cell:region.cells) if (cell.usable) ++next->usable_cells;
    }
    return next;
}
Value* summary(const Snapshot& value) {
    two_typed_value_locals(Array* out,Array* warnings);
    vl.out=new Array(16); vl.warnings=new Array(static_cast<int>(value.result.warnings.size()));
    vl.out->append(new String(version));
    for (auto number:{value.sources.size(),value.result.input_triangles,value.result.regions.size(),
                     value.result.sampled_cells,value.usable_cells})
        vl.out->append(Integer64::intern(static_cast<INT64>(number)));
    vl.out->append(Double::intern(value.sampled_area_mm2));
    vl.out->append(Double::intern(value.usable_area_mm2));
    vl.out->append(new Point3Value(point(add(value.result.bounds.min,value.origin_mm))));
    vl.out->append(new Point3Value(point(add(value.result.bounds.max,value.origin_mm))));
    for (const auto& warning:value.result.warnings) vl.warnings->append(new String(wide(warning).c_str()));
    vl.out->append(vl.warnings);
    vl.out->append(Integer::intern(value.time));
    vl.out->append(new Point3Value(point(value.origin_mm)));
    vl.out->append(Double::intern(value.settings.cell_size_mm));
    vl.out->append(Double::intern(value.settings.minimum_clearance_mm));
    vl.out->append(Double::intern(value.settings.maximum_slope_degrees));
    return_value(vl.out);
}
std::wstring module_path() {
    std::wstring path(32768,L'\0');
    const DWORD count=GetModuleFileNameW(module_instance,path.data(),static_cast<DWORD>(path.size()));
    if (!count || count>=path.size()) throw std::runtime_error("Cannot determine loaded Cyrus Arrange module path.");
    path.resize(count); return path;
}
void json_string(std::ostream& output,const std::string& value) {
    constexpr char hex[]="0123456789abcdef";
    output.put('"');
    for (const unsigned char ch:value) {
        if (ch=='"' || ch=='\\') {output.put('\\');output.put(static_cast<char>(ch));}
        else if (ch<0x20) {output<<"\\u00"<<hex[ch>>4]<<hex[ch&15];}
        else output.put(static_cast<char>(ch));
    }
    output.put('"');
}
void json_point(std::ostream& output,ca::Vec3 point) {
    if (!finite(point)) throw std::runtime_error("Export contains a nonfinite coordinate.");
    output<<'['<<point.x<<','<<point.y<<','<<point.z<<']';
}
void json_distance(std::ostream& output,double value) {
    if (std::isinf(value) && value>0) output<<"null";
    else if (std::isfinite(value)) output<<value;
    else throw std::runtime_error("Export contains an invalid distance.");
}
void export_json(const Snapshot& value,const std::filesystem::path& supplied_path) {
    if (supplied_path.empty()) throw std::runtime_error("Choose an export filename.");
    const auto target=std::filesystem::absolute(supplied_path);
    if (target.filename().empty() || std::filesystem::is_directory(target))
        throw std::runtime_error("Export path must name a file.");
    auto temporary=target;
    temporary+=L".ca-"+std::to_wstring(GetCurrentProcessId())+L"-"+std::to_wstring(GetTickCount64())+L".tmp";
    try {
        std::ofstream output(temporary,std::ios::binary|std::ios::trunc);
        output.exceptions(std::ios::badbit|std::ios::failbit);
        output.imbue(std::locale::classic()); output<<std::setprecision(17);
        output<<"{\"schema\":1,\"product\":\"Cyrus Arrange\",\"version\":\"0.3.2\",\"coordinate_space\":\"world_mm\",\"freshness\":\"captured_snapshot_reinspect_after_source_changes\",\"time_ticks\":"<<value.time<<",\"captured_mm_per_system_unit\":"<<value.captured_mm_per_unit<<",\"origin_mm\":";
        json_point(output,value.origin_mm);
        output<<",\"settings\":{\"cell_size_mm\":"<<value.settings.cell_size_mm<<",\"minimum_clearance_mm\":"<<value.settings.minimum_clearance_mm<<",\"maximum_slope_degrees\":"<<value.settings.maximum_slope_degrees<<",\"height_tolerance_mm\":"<<value.settings.height_tolerance_mm<<"},\"bounds\":{\"min\":";
        json_point(output,add(value.result.bounds.min,value.origin_mm));output<<",\"max\":";
        json_point(output,add(value.result.bounds.max,value.origin_mm));output<<"},\"input_triangles\":"<<value.result.input_triangles<<",\"degenerate_triangles\":"<<value.result.degenerate_triangles<<",\"sampled_cells\":"<<value.result.sampled_cells<<",\"work\":"<<value.result.work<<",\"sources\":[";
        bool separator=false;
        for(const auto& source:value.sources) {
            if(separator)output<<',';separator=true;
            output<<"{\"handle\":"<<source.handle<<",\"name\":";json_string(output,utf8(source.name));output<<'}';
        }
        output<<"],\"warnings\":[";separator=false;
        for(const auto& warning:value.result.warnings) {if(separator)output<<',';separator=true;json_string(output,warning);}
        output<<"],\"regions\":[";separator=false;
        for(const auto& region:value.result.regions) {
            if(separator)output<<',';separator=true;
            output<<"{\"id\":"<<region.id<<",\"bounds\":{\"min\":";json_point(output,add(region.bounds.min,value.origin_mm));
            output<<",\"max\":";json_point(output,add(region.bounds.max,value.origin_mm));
            output<<"},\"sampled_area_mm2\":"<<region.sampled_area_mm2<<",\"usable_area_mm2\":"<<region.usable_area_mm2<<",\"minimum_clearance_mm\":";
            json_distance(output,region.minimum_clearance_mm);output<<",\"open_above\":"<<(region.open_above?"true":"false")<<",\"cells\":[";
            bool cell_separator=false;
            for(const auto& cell:region.cells) {
                if(cell_separator)output<<',';cell_separator=true;
                output<<"{\"center_mm\":";json_point(output,add(cell.center,value.origin_mm));
                output<<",\"clearance_mm\":";json_distance(output,cell.clearance_mm);
                output<<",\"usable\":"<<(cell.usable?"true":"false")<<'}';
            }
            output<<"]}";
        }
        output<<"]}\n";output.flush();output.close();
        if (!MoveFileExW(temporary.c_str(),target.c_str(),MOVEFILE_REPLACE_EXISTING|MOVEFILE_WRITE_THROUGH))
            throw std::runtime_error("Cannot publish export file; Windows error "+std::to_string(GetLastError())+".");
    } catch (...) {
        std::error_code ignored; std::filesystem::remove(temporary,ignored); throw;
    }
}
Value* create_overlay(const Snapshot& value) {
    if (!value.usable_cells) throw std::runtime_error("Snapshot has no usable sampled cells to show.");
    if (value.usable_cells>max_overlay_cells)
        throw std::runtime_error("Overlay exceeds 250,000 usable cells; inspect again with a larger cell size. Captured result retained.");
    const double unit=units_mm();
    const auto deleter=[](TriObject* object){if(object)object->DeleteThis();};
    std::unique_ptr<TriObject,decltype(deleter)> owned(CreateNewTriObject(),deleter);
    if (!owned) throw std::runtime_error("Cannot allocate the overlay mesh.");
    auto& mesh=owned->GetMesh();
    if (!mesh.setNumVerts(static_cast<int>(value.usable_cells*4)) ||
        !mesh.setNumFaces(static_cast<int>(value.usable_cells*2)))
        throw std::runtime_error("Cannot allocate overlay vertices/faces.");
    const double half=value.settings.cell_size_mm*0.47;
    const double lift=std::min(0.5,value.settings.cell_size_mm*0.01);
    std::size_t index=0;
    for(const auto& region:value.result.regions) for(const auto& cell:region.cells) {
        if (!cell.usable) continue;
        for(int corner=0;corner<4;++corner) {
            auto p=cell.center;p.x+=(corner==0||corner==3)?-half:half;
            p.y+=corner<2?-half:half;p.z+=lift;
            // Keep mesh local coordinates near the capture origin. Translation
            // back into the current system-unit frame belongs to the node TM.
            p=multiply(p,1.0/unit);
            const auto rounded=point(p);
            const double tolerance=std::max(0.01,value.settings.cell_size_mm*0.001);
            if (std::hypot(double(rounded.x)-p.x,double(rounded.y)-p.y,double(rounded.z)-p.z)*unit>tolerance)
                throw std::runtime_error("Overlay precision is insufficient at this extent; inspect a smaller assembly.");
            mesh.setVert(static_cast<int>(index*4+corner),rounded);
        }
        const DWORD start=static_cast<DWORD>(index*4);
        auto& first=mesh.faces[index*2];first.setVerts(start,start+1,start+2);
        first.setEdgeVisFlags(1,1,0);first.setSmGroup(0);first.setMatID(0);
        auto& second=mesh.faces[index*2+1];second.setVerts(start,start+2,start+3);
        second.setEdgeVisFlags(0,1,1);second.setSmGroup(0);second.setMatID(0);++index;
    }
    mesh.InvalidateGeomCache();mesh.InvalidateTopologyCache();
    const auto translation=multiply(value.origin_mm,1.0/unit);
    const auto rounded_translation=point(translation);
    if (std::hypot(double(rounded_translation.x)-translation.x,
                   double(rounded_translation.y)-translation.y,
                   double(rounded_translation.z)-translation.z)*unit>
        std::max(0.01,value.settings.cell_size_mm*0.001))
        throw std::runtime_error("World-coordinate precision cannot position this overlay accurately; move the furniture nearer the origin and inspect again.");
    Matrix3 frame(TRUE);frame.SetTrans(rounded_translation);
    auto* ip=GetCOREInterface();
    const bool own_hold=!theHold.Holding();
    if(own_hold)theHold.Begin();
    INode* node=nullptr;
    try {
        node=ip->CreateObjectNode(owned.get());
        if(!node)throw std::runtime_error("Cannot create the overlay scene node.");
        owned.release();node->SetName(_T("CyrusArrange_SupportSnapshot"));
        node->SetNodeTM(ip->GetTime(),frame);
        node->SetUserPropBool(_T("CyrusArrangeGenerated"),TRUE);
        node->SetUserPropString(_T("CyrusArrangeVersion"),version);
        node->SetUserPropString(_T("CyrusArrangeFreshness"),_T("Captured snapshot; inspect again after source changes"));
        node->SetWireColor(RGB(70,205,145));node->SetRenderable(FALSE);
        node->SetCastShadows(FALSE);node->SetRcvShadows(FALSE);
        one_value_local(return_node);vl.return_node=MAXNode::intern(node);
        if(own_hold)theHold.Accept(_T("Cyrus Arrange support overlay"));
        ip->RedrawViews(ip->GetTime());
        return_value(vl.return_node);
    } catch (...) {
        if(own_hold)theHold.Cancel();else if(node)ip->DeleteNode(node,FALSE);
        throw;
    }
}
} // namespace

extern "C" __declspec(dllexport) const TCHAR* LibDescription(){return _T("Cyrus Arrange 0.3.2 native geometry inspector");}
extern "C" __declspec(dllexport) ULONG LibVersion(){return VERSION_3DSMAX;}
void CyrusArrangeInitializeBridge();
void CyrusArrangeShutdownBridge();
extern "C" __declspec(dllexport) void LibInit(){CyrusArrangeInitializeBridge();}
extern "C" __declspec(dllexport) int LibShutdown(){CyrusArrangeShutdownBridge();cyrus::arrange::host::stop_document_service();return TRUE;}
BOOL WINAPI DllMain(HINSTANCE instance,DWORD reason,LPVOID){if(reason==DLL_PROCESS_ATTACH){module_instance=instance;cyrus::arrange::host::set_document_module(instance);}return TRUE;}

def_visible_primitive(caVersion,"caVersion");
Value* caVersion_cf(Value**,int count){check_arg_count(caVersion,0,count);return api([]()->Value*{return new String(version);});}

def_visible_primitive(caSummary,"caSummary");
Value* caSummary_cf(Value**,int count){check_arg_count(caSummary,0,count);return api([]()->Value*{return summary(current());});}

def_visible_primitive(caInspect,"caInspect");
Value* caInspect_cf(Value** args,int count){
    check_arg_count(caInspect,4,count);
    return api([&]()->Value*{
        type_check(args[0],Array,_T("input nodes"));
        ca::Settings settings;settings.cell_size_mm=args[1]->to_double();
        settings.minimum_clearance_mm=args[2]->to_double();settings.maximum_slope_degrees=args[3]->to_double();
        auto next=capture(static_cast<Array*>(args[0]),settings);
        // Allocate the entire bounded script summary before native publication.
        // A failed successor/summary allocation leaves the previous snapshot.
        Value* output=summary(*next);snapshot.swap(next);return output;
    });
}

def_visible_primitive(caRegion,"caRegion");
Value* caRegion_cf(Value** args,int count){
    check_arg_count(caRegion,1,count);
    return api([&]()->Value*{
        const auto& value=current();const auto index=args[0]->to_int64();
        if(index<1 || static_cast<std::uint64_t>(index)>value.result.regions.size())
            throw std::runtime_error("Region index is outside the captured snapshot.");
        const auto& region=value.result.regions[static_cast<std::size_t>(index-1)];
        std::size_t usable=0;for(const auto& cell:region.cells)if(cell.usable)++usable;
        one_typed_value_local(Array* output);vl.output=new Array(9);
        vl.output->append(Integer::intern(static_cast<int>(region.id)));
        vl.output->append(new Point3Value(point(add(region.bounds.min,value.origin_mm))));
        vl.output->append(new Point3Value(point(add(region.bounds.max,value.origin_mm))));
        vl.output->append(Double::intern(region.sampled_area_mm2));
        vl.output->append(Double::intern(region.usable_area_mm2));
        vl.output->append(Double::intern(std::isinf(region.minimum_clearance_mm)?-1:region.minimum_clearance_mm));
        vl.output->append(region.open_above?&true_value:&false_value);
        vl.output->append(Integer64::intern(static_cast<INT64>(region.cells.size())));
        vl.output->append(Integer64::intern(static_cast<INT64>(usable)));return_value(vl.output);
    });
}

def_visible_primitive(caCreateOverlay,"caCreateOverlay");
Value* caCreateOverlay_cf(Value**,int count){check_arg_count(caCreateOverlay,0,count);return api([]()->Value*{return create_overlay(current());});}

def_visible_primitive(caExport,"caExport");
Value* caExport_cf(Value** args,int count){check_arg_count(caExport,1,count);return api([&]()->Value*{
    type_check(args[0],String,_T("export filename"));export_json(current(),std::filesystem::path(args[0]->to_string()));return &true_value;
});}

def_visible_primitive(caClear,"caClear");
Value* caClear_cf(Value**,int count){check_arg_count(caClear,0,count);return api([]()->Value*{snapshot.reset();return &true_value;});}

def_visible_primitive(caDiagnostics,"caDiagnostics");
Value* caDiagnostics_cf(Value**,int count){check_arg_count(caDiagnostics,0,count);return api([]()->Value*{
    three_typed_value_locals(Array* output,Array* sources,Array* row);
    vl.output=new Array(10);vl.sources=new Array(snapshot?static_cast<int>(snapshot->sources.size()):0);
    vl.output->append(new String(module_path().c_str()));vl.output->append(new String(version));
    vl.output->append(snapshot?&true_value:&false_value);
    if(snapshot)for(const auto& source:snapshot->sources){
        vl.row=new Array(2);vl.row->append(Integer64::intern(source.handle));
        vl.row->append(new String(source.name.c_str()));vl.sources->append(vl.row);
    }
    vl.output->append(vl.sources);vl.output->append(Integer::intern(snapshot?snapshot->time:0));
    vl.output->append(Integer64::intern(snapshot?static_cast<INT64>(snapshot->result.work):0));
    vl.output->append(Integer64::intern(snapshot?static_cast<INT64>(snapshot->result.input_triangles):0));
    vl.output->append(Integer64::intern(snapshot?static_cast<INT64>(snapshot->result.sampled_cells):0));
    vl.output->append(Integer64::intern(snapshot?static_cast<INT64>(snapshot->result.regions.size()):0));
    vl.output->append(new Point3Value(snapshot?point(snapshot->origin_mm):Point3(0,0,0)));return_value(vl.output);
});}

def_visible_primitive(caModulePaths,"caModulePaths");
Value* caModulePaths_cf(Value**,int count){check_arg_count(caModulePaths,0,count);return api([]()->Value*{
    const auto storage=GetModuleHandleW(L"CyrusArrangeStorage.dlh");
    if(!storage)throw std::runtime_error("Cyrus Arrange native storage module is not loaded.");
    std::wstring path(32768,L'\0');const DWORD length=GetModuleFileNameW(storage,path.data(),static_cast<DWORD>(path.size()));
    if(!length||length>=path.size())throw std::runtime_error("Cannot determine loaded Cyrus Arrange storage module path.");path.resize(length);
    one_typed_value_local(Array* output);vl.output=new Array(2);vl.output->append(new String(module_path().c_str()));vl.output->append(new String(path.c_str()));return_value(vl.output);
});}
