#include <max.h>
#include <maxscript/maxscript.h>
#include <maxscript/foundation/arrays.h>
#include <maxscript/foundation/numbers.h>
#include <maxscript/foundation/3dmath.h>
#include <maxscript/foundation/colors.h>

#include <vector>
#include <cstdint>
#include <triobj.h>
#include <maxscript/maxwrapper/mxsobjects.h>
#include <array>
#include <cmath>
#include <memory>
#include <maxscript/macros/define_instantiation_functions.h>
#undef ScripterExport
#define ScripterExport __declspec(dllexport)

// Immutable transient MAXScript value: ownership follows the controller's local
// cache through GC. No global handles, stale node pointers or per-frame conversion.
visible_class_debug_ok(AminPointCache)
class AminPointCache : public Value {
public:
    struct Group { Point3 color; std::vector<Point3> points; };
    std::vector<Group> groups;
    struct Geometry { std::vector<std::array<Point3,3>> faces;std::vector<Matrix3> instances;Point3 color;bool placeholder=false; };
    std::vector<Geometry> geometry;
    int faceCount=0;
    int size=0;
    AminPointCache() { tag=class_tag(AminPointCache); }
    classof_methods(AminPointCache,Value);
    void collect() override { delete this; }
    void sprin1(CharStream* s) override { s->printf(_T("<AminPointCache:%d>"),size); }
    Value* deep_copy(HashTable*) override { return this; }
};
visible_class_instance(AminPointCache,"AminPointCache");
#include "geometry_preview.inc"

def_visible_primitive(aminScatterBuildPreview,"aminScatterBuildPreview");
Value* aminScatterBuildPreview_cf(Value** args,int count) {
    check_arg_count(aminScatterBuildPreview,4,count);
    for(int i=0;i<3;++i) type_check(args[i],Array,_T("preview inputs"));
    auto* data=static_cast<Array*>(args[0]);
    auto* sources=static_cast<Array*>(args[1]);
    auto* colors=static_cast<Array*>(args[2]);
    const int budget=args[3]->to_int();
    if(budget<1||budget>500000||sources->size!=colors->size)
        throw RuntimeError(_T("Invalid preview budget or source colors."));
    std::vector<std::vector<Point3>> samples;
    std::vector<Point3> rgb;
    int pointsPerPlant=0;
    for(int i=0;i<sources->size;++i) {
        type_check(sources->data[i],Array,_T("source samples"));
        auto* src=static_cast<Array*>(sources->data[i]);
        if(i==0) pointsPerPlant=src->size;
        if(src->size!=pointsPerPlant) throw RuntimeError(_T("Inconsistent source sample count."));
        samples.emplace_back();samples.back().reserve(src->size);
        for(int j=0;j<src->size;++j) samples.back().push_back(src->data[j]->to_point3());
        rgb.push_back(colors->data[i]->to_point3()/255.0f);
    }
    // Validate and unpack before allocating the GC value; exceptions cannot leak it.
    std::vector<Matrix3> transforms;std::vector<int> indices;
    transforms.reserve(data->size);indices.reserve(data->size);
    for(int i=0;i<data->size;++i) {
        type_check(data->data[i],Array,_T("placement"));
        auto* row=static_cast<Array*>(data->data[i]);
        if(row->size!=2) throw RuntimeError(_T("Invalid placement."));
        const int index=row->data[1]->to_int()-1;
        if(index<0||index>=sources->size) throw RuntimeError(_T("Invalid source index."));
        transforms.push_back(row->data[0]->to_matrix3());indices.push_back(index);
    }
    std::vector<AminPointCache::Group> groups;
    for(auto c:rgb) groups.push_back({c,{}});
    const std::uint64_t total=static_cast<std::uint64_t>(data->size)*pointsPerPlant;
    const auto stride=std::max<std::uint64_t>(1,(total+budget-1)/budget);
    int size=0;
    for(std::uint64_t flat=0;flat<total;flat+=stride) {
        const auto plant=static_cast<std::size_t>(flat/pointsPerPlant);
        const auto source=indices[plant];
        groups[source].points.push_back(samples[source][flat%pointsPerPlant]*transforms[plant]);
        ++size;
    }
    auto* result=new AminPointCache();result->groups=std::move(groups);result->size=size;
    return result;
}

def_visible_primitive(aminScatterPreviewCount,"aminScatterPreviewCount");
Value* aminScatterPreviewCount_cf(Value** args,int count) {
    check_arg_count(aminScatterPreviewCount,1,count);
    type_check(args[0],AminPointCache,_T("preview cache"));
    return Integer::intern(static_cast<AminPointCache*>(args[0])->size);
}

def_visible_primitive(aminScatterDrawPreview,"aminScatterDrawPreview");
Value* aminScatterDrawPreview_cf(Value** args,int count) {
    check_arg_count(aminScatterDrawPreview,3,count);
    type_check(args[0],AminPointCache,_T("preview cache"));
    auto* cache=static_cast<AminPointCache*>(args[0]);
    const bool solid=args[1]->to_bool()!=FALSE;
    const Point3 color=args[2]->to_point3()/255.0f;
    auto& view=MAXScript_interface->GetActiveViewExp();
    if(!view.IsAlive()) return &ok;
    auto* gw=view.getGW();if(!gw) return &ok;
    // Match gw.marker's overlay semantics. Save/restore render flags once,
    // change color once per source, and bracket marker submission in batches.
    const auto limits=gw->getRndLimits();
    gw->setRndLimits(limits & ~GW_Z_BUFFER);
    gw->setTransform(Matrix3(1));
    if(!cache->geometry.empty()) {
        Material previous=*gw->getMaterial(),preview;
        preview.Ka=preview.Kd=Point3(1,1,1);preview.Ks=Point3(0,0,0);preview.selfIllum=1;preview.opacity=1;preview.dblSided=1;
        gw->setMaterial(preview);
        gw->setRndLimits((limits|GW_Z_BUFFER|GW_COLOR_VERTS)&~(GW_ILLUM|GW_WIREFRAME|GW_BACKCULL|GW_TEXTURE|GW_SHADE_CVERTS));
        for(auto& group:cache->geometry)for(auto& tm:group.instances){
            gw->setTransform(tm);gw->startTriangles();
            for(auto& face:group.faces){
                auto a=VectorTransform(tm,face[1]-face[0]),b=VectorTransform(tm,face[2]-face[0]);auto normal=Normalize(CrossProd(a,b));
                float shade=.35f+.65f*std::abs(DotProd(normal,Normalize(Point3(.3f,-.5f,.8f))));
                Point3 rgb=(solid?color:group.color)*shade;Point3 colors[3]={rgb,rgb,rgb};gw->triangle(face.data(),colors);
            }
            gw->endTriangles();
        }
        gw->setTransform(Matrix3(1));
        gw->setMaterial(previous);
    }
    for(auto& group:cache->groups) {
        if(group.points.empty()) continue;
        gw->setColor(LINE_COLOR,solid?color:group.color);
        gw->startMarkers();
        for(auto& p:group.points) gw->marker(&p,POINT_MRKR);
        gw->endMarkers();
    }
    gw->setRndLimits(limits);
    return &ok;
}

// Diagnostic export only; normal viewport redraw never allocates MAXScript rows.
def_visible_primitive(aminScatterPreviewPoints,"aminScatterPreviewPoints");
Value* aminScatterPreviewPoints_cf(Value** args,int count) {
    check_arg_count(aminScatterPreviewPoints,1,count);
    type_check(args[0],AminPointCache,_T("preview cache"));
    auto* cache=static_cast<AminPointCache*>(args[0]);
    two_typed_value_locals(Array* result,Array* row);
    vl.result=new Array(cache->size);
    for(const auto& group:cache->groups) for(const auto& p:group.points) {
        vl.row=new Array(2);vl.result->append(vl.row);
        vl.row->append(new Point3Value(p));
        vl.row->append(new ColorValue(AColor(group.color.x,group.color.y,group.color.z)));
    }
    return_value(vl.result);
}
