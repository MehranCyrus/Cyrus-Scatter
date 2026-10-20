#include <max.h>
#include "native_fault_qualification.h"
#include <maxscript/maxscript.h>
#include <maxscript/foundation/arrays.h>
#include <maxscript/foundation/numbers.h>
#include <maxscript/foundation/3dmath.h>
#include <maxscript/foundation/colors.h>

#include <vector>
#include <algorithm>
#include <cstdint>
#include <triobj.h>
#include <SingleWeakRefMaker.h>
#include <maxscript/maxwrapper/mxsobjects.h>
#include <array>
#include <cmath>
#include <memory>
#include <atomic>
#include <new>
#include <string>
#include <stdmat.h>
#include <iparamb2.h>
#include <bitmap.h>
#include <ColorManagement/IColorPipelineMgr.h>
#include <notify.h>
#include "point_preview.h"
#include "diagnostics.h"
#include "preview_sampling.h"
#include "placement_transport.h"
#include "placement_value.h"
#include "script_buffers.h"
#include "spline_overlay.h"
#include "spline_field_value.h"
#include <maxscript/macros/define_instantiation_functions.h>
#undef ScripterExport
#define ScripterExport __declspec(dllexport)
#include "preview_palette.inc"
#include "preview_rows.inc"
#include "source_geometry.inc"
namespace { std::atomic<std::uint64_t> fallbackCalls{0},fallbackPointVertices{0},fallbackFaces{0}; }
struct FieldPreviewDetails {
    std::shared_ptr<cyrus::PreviewMemory> memory;
    cyrus::bands::OverlayStats stats;
    std::vector<cyrus::bands::OverlaySample> samples;
    std::size_t sampleCount=0,lineCount=0,reservedBytes=0;
};

// Immutable transient MAXScript value: ownership follows the controller's local
// cache through GC. No global handles, stale node pointers or per-frame conversion.
visible_class_debug_ok(AminPointCache)
class AminPointCache : public Value {
public:
    using Group = cyrus::PointGroup;
    std::shared_ptr<const cyrus::PointSnapshot> pointSnapshot;
    const std::vector<Group>& pointGroups() const { return pointSnapshot->groups; }
    using Geometry=cyrus::PreviewGeometry;
    std::shared_ptr<const cyrus::MeshSnapshot> meshSnapshot;
    std::shared_ptr<const cyrus::PreviewPalette> palette;
    std::shared_ptr<const cyrus::MeshAppearance> appearance;
    std::shared_ptr<const FieldPreviewDetails> fieldDetails;
    const std::vector<Geometry>& geometryGroups() const { static const std::vector<Geometry> empty;return meshSnapshot?meshSnapshot->groups:empty; }
    std::size_t faceCount=0;
    int size=0;
    int geometryMode=0;
    bool radiusDetails=false;
    AminPointCache() { cyrus::owned::fault(8);tag=class_tag(AminPointCache); }
    classof_methods(AminPointCache,Value);
    void collect() override { delete this; }
    void sprin1(CharStream* s) override { s->printf(_T("<AminPointCache:%d>"),size); }
    Value* deep_copy(HashTable*) override { return this; }
    Value* get_property(Value** a,int n) override {
        if(n==1&&a[0]==Name::intern(_T("count")))return Integer::intern(size);
        return Value::get_property(a,n);
    }

};
visible_class_instance(AminPointCache,"AminPointCache");
#include "preview_compare.inc"
#include "geometry_preview.inc"
#include "material_preview.inc"
#include "spline_overlay_bridge.inc"
#include "radius_preview.inc"

def_visible_primitive(aminScatterBuildPreview,"aminScatterBuildPreview");
Value* aminScatterBuildPreview_cf(Value** args,int count) {
    amin::diagnostics::StageTimer measurement(amin::diagnostics::Stage::Preview);
    check_arg_count(aminScatterBuildPreview,4,count);
    for(int i=1;i<3;++i) type_check(args[i],Array,_T("preview inputs"));
    PreviewRows data(args[0]);
    auto* sources=static_cast<Array*>(args[1]);
    const auto palette=previewPalette(args[2],sources->size);
    const int budget=args[3]->to_int();
    if(budget<0)
        throw RuntimeError(_T("Invalid preview budget or source colors."));
    std::size_t inputSamples=0;
    for(int i=0;i<sources->size;++i) {
        type_check(sources->data[i],Array,_T("source samples"));
        const auto samples=static_cast<Array*>(sources->data[i])->size;
        if(samples>10000||inputSamples+samples>1000000)throw RuntimeError(_T("Preview source samples exceed the bounded inspection allowance"));
        inputSamples+=samples;
    }
    const auto perSource=sources->size?static_cast<Array*>(sources->data[0])->size:0;
    const auto requested=data.size()*perSource;
    const auto outputLimit=budget?std::min<std::size_t>(budget,requested):requested;
    const auto stagingBytes=inputSamples*sizeof(Point3)+outputLimit*2*(sizeof(Point3)+sizeof(std::uint8_t))+sources->size*256+4096;
    if(stagingBytes>cyrus::pointPreviewOwnerLimit)throw RuntimeError(_T("Point preparation exceeds the 64 MiB allowance"));
    auto staging=cyrus::reservePreviewMemory(cyrus::pointPreviewBudget,stagingBytes);
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
        rgb.push_back(palette->sourceColors[i]);
    }
    // Validate every input, including unshown rows, without copying the entire
    // placement stream. Conversion stays on the host thread; only the bounded
    // displayed samples enter the immutable snapshot used by draw workers.
    data.validate(sources->size,*palette);
    std::vector<AminPointCache::Group> groups;
    for(auto c:rgb) groups.push_back({c,{}});
    const std::uint64_t total=static_cast<std::uint64_t>(data.size())*pointsPerPlant;
    const auto shown=budget?std::min<std::uint64_t>(total,static_cast<std::uint64_t>(budget)):total;
    int size=0;
    for(std::uint64_t sample=0;sample<shown;++sample) {
        const auto flat=amin::previewPointIndex(sample,total,shown);
        const auto plant=static_cast<std::size_t>(flat/pointsPerPlant);
        const auto source=data.source(plant)-1;
        groups[source].points.push_back(samples[source][flat%pointsPerPlant]*data.matrix(plant));
        groups[source].bandSlots.push_back(data.band(plant,*palette));
        ++size;
    }
    auto snapshot=std::make_shared<cyrus::PointSnapshot>(std::move(groups));
    auto* result=new AminPointCache();result->pointSnapshot=std::move(snapshot);result->palette=palette;result->size=size;
    return result;
}

// Compare the ordered display inputs without allocating snapshots or touching
// published state. Candidate/anchor/protection changes still publish normally;
// only transform, source and Band owner contribute to the retained geometry.
def_visible_primitive(cyrusPreviewPlacementsEqual,"cyrusPreviewPlacementsEqual");
Value* cyrusPreviewPlacementsEqual_cf(Value** args,int count) {
    check_arg_count(cyrusPreviewPlacementsEqual,2,count);
    PreviewRows a(args[0]),b(args[1]);
    if(a.size()!=b.size())return &false_value;
    for(std::size_t i=0;i<a.size();++i) {
        if(a.source(i)!=b.source(i)||a.owner(i)!=b.owner(i))return &false_value;
        const auto x=a.matrix(i),y=b.matrix(i);
        for(int row=0;row<4;++row)for(int axis=0;axis<3;++axis)
            if(x.GetRow(row)[axis]!=y.GetRow(row)[axis])return &false_value;
    }
    return &true_value;
}

def_visible_primitive(cyrusPreviewRadiiEqual,"cyrusPreviewRadiiEqual");
Value* cyrusPreviewRadiiEqual_cf(Value** args,int count) {
    check_arg_count(cyrusPreviewRadiiEqual,2,count);
    const auto size=cyrusRadiusCount(args[0]),other=cyrusRadiusCount(args[1]);
    if(size>1000000||other>1000000)throw RuntimeError(_T("Radius comparison exceeds 1,000,000 placements"));
    if(size!=other)return &false_value;
    for(std::size_t i=0;i<size;++i) {
        const auto left=cyrusRadiusAt(args[0],i),right=cyrusRadiusAt(args[1],i);
        for(int metric=0;metric<2;++metric)
            if(left[metric]!=right[metric])return &false_value;
    }
    return &true_value;
}

def_visible_primitive(cyrusRecolorPreview,"cyrusRecolorPreview");
Value* cyrusRecolorPreview_cf(Value** args,int count) {
    check_arg_count(cyrusRecolorPreview,2,count);
    type_check(args[0],AminPointCache,_T("preview cache"));
    auto* cache=static_cast<AminPointCache*>(args[0]);
    if(!cache->palette)throw RuntimeError(_T("This overlay has no identification palette"));
    auto palette=previewPalette(args[1],cache->palette->sourceColors.size());
    if(palette->bandIDs!=cache->palette->bandIDs||palette->requireBand!=cache->palette->requireBand)
        throw RuntimeError(_T("Recolor must preserve the published Band dictionary"));
    if(cyrus::samePalette(cache->palette,palette))return args[0];
    auto result=std::make_unique<AminPointCache>();
    result->pointSnapshot=cache->pointSnapshot;result->meshSnapshot=cache->meshSnapshot;result->palette=std::move(palette);
    result->appearance=cache->appearance;
    result->size=cache->size;result->faceCount=cache->faceCount;result->geometryMode=cache->geometryMode;
    return result.release();
}

def_visible_primitive(aminScatterPreviewCount,"aminScatterPreviewCount");
Value* aminScatterPreviewCount_cf(Value** args,int count) {
    check_arg_count(aminScatterPreviewCount,1,count);
    type_check(args[0],AminPointCache,_T("preview cache"));
    return Integer::intern(static_cast<AminPointCache*>(args[0])->size);
}

// Radius rings share the immutable retained-buffer path with points. Conversion
// occurs when the display snapshot changes, never on the viewport draw thread.
def_visible_primitive(cyrusBuildInspectionPreview,"cyrusBuildInspectionPreview");
Value* cyrusBuildInspectionPreview_cf(Value** args,int count) {
    amin::diagnostics::StageTimer measurement(amin::diagnostics::Stage::Preview);
    check_arg_count(cyrusBuildInspectionPreview,2,count);
    if(args[0]->is_kind_of(class_tag(AminPointCache)))return combineRadiusPreview(args[0],args[1]);
    type_check(args[0],Array,_T("radius rings"));
    auto* rings=static_cast<Array*>(args[0]);
    AminPointCache* field=nullptr;
    if(args[1]!=&undefined){type_check(args[1],AminPointCache,_T("field preview"));field=static_cast<AminPointCache*>(args[1]);
        if(!field->fieldDetails||!field->pointSnapshot->lines)throw RuntimeError(_T("Inspection expects a field overlay cache"));}
    if(rings->size==0&&field)return args[1];
    constexpr std::size_t vertexLimit=cyrus::pointPreviewOwnerLimit/(2*(sizeof(Point3)+sizeof(std::uint8_t)));
    std::size_t vertices=field?field->pointSnapshot->count:0;
    if(vertices>vertexLimit)throw RuntimeError(_T("Field and radius display exceed the vertex allowance"));
    if(rings->size>10000)throw RuntimeError(_T("Radius display exceeds 10,000 rings"));
    for(int i=0;i<rings->size;++i) {
        type_check(rings->data[i],Array,_T("radius ring"));auto* ring=static_cast<Array*>(rings->data[i]);
        if(ring->size!=2)throw RuntimeError(_T("Invalid radius ring"));
        type_check(ring->data[0],Array,_T("radius vertices"));auto* points=static_cast<Array*>(ring->data[0]);
        if(points->size<3||std::size_t(points->size)>(vertexLimit-vertices)/2)throw RuntimeError(_T("Radius display exceeds its bounded vertex allowance"));
        vertices+=std::size_t(points->size)*2;
    }
    auto staging=cyrus::reservePreviewMemory(cyrus::pointPreviewBudget,vertices*2*(sizeof(Point3)+sizeof(std::uint8_t))+rings->size*256+4096);
    vertices=field?field->pointSnapshot->count:0;
    std::vector<AminPointCache::Group> groups=field?field->pointGroups():std::vector<AminPointCache::Group>{};
    for(int i=0;i<rings->size;++i) {
        type_check(rings->data[i],Array,_T("radius ring"));
        auto* ring=static_cast<Array*>(rings->data[i]);
        if(ring->size!=2) throw RuntimeError(_T("Invalid radius ring"));
        type_check(ring->data[0],Array,_T("radius vertices"));
        auto* points=static_cast<Array*>(ring->data[0]);
        if(points->size<3 || std::size_t(points->size)>(vertexLimit-vertices)/2)
            throw RuntimeError(_T("Radius display exceeds the 64 MiB cache limit. Reduce Radii / layer."));
        vertices+=std::size_t(points->size)*2;
        const Point3 color=ring->data[1]->to_point3()/255.f;
        auto group=std::find_if(groups.begin(),groups.end(),[&](const auto& g){return g.color==color;});
        if(group==groups.end()) { groups.push_back({color,{}});group=groups.end()-1; }
        for(int j=0;j<points->size;++j) {
            group->points.push_back(points->data[j]->to_point3());
            group->points.push_back(points->data[(j+1)%points->size]->to_point3());
            group->bandSlots.push_back(0);group->bandSlots.push_back(0);
        }
    }
    auto snapshot=std::make_shared<cyrus::PointSnapshot>(std::move(groups),true);
    auto* result=new AminPointCache();result->pointSnapshot=std::move(snapshot);result->size=rings->size;
    if(field)result->fieldDetails=field->fieldDetails;
    return result;
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
    // Emergency representation only. GPU failure/admission must never turn
    // camera movement into a faces-times-instances CPU submission loop.
    std::size_t remaining=2048,submitted=0;
    for(std::size_t source=0;source<cache->geometryGroups().size() && remaining;++source) {
        const auto& group=cache->geometryGroups()[source];
        const auto shown=std::min(remaining,group.instances.size());
        const auto stride=cyrus::viewportStride(group.instances.size());
        gw->startMarkers();
        for(std::size_t k=0;k<shown;++k) {
            const auto i=k*stride%group.instances.size();
            gw->setColor(LINE_COLOR,solid?color:cyrus::previewColor(cache->palette.get(),source,group.bandSlots[i],group.color));
            auto marker=group.instances[i].GetTrans();gw->marker(&marker,PLUS_SIGN_MRKR);
        }
        gw->endMarkers();remaining-=shown;submitted+=shown;
    }
    for(std::size_t source=0;source<cache->pointGroups().size();++source) {
        const auto& group=cache->pointGroups()[source];
        if(group.points.empty()) continue;
        if(cache->pointSnapshot->lines) {
            for(std::size_t i=0;i<group.points.size();i+=2) {
                gw->setColor(LINE_COLOR,solid?color:cyrus::previewColor(cache->palette.get(),source,group.bandSlots[i],group.color));
                Point3 line[2]={group.points[i],group.points[i+1]};gw->polyline(2,line,nullptr,nullptr,FALSE,nullptr);
            }
        } else {
            gw->startMarkers();
            const auto shown=std::min(remaining,group.points.size());
            const auto stride=cyrus::viewportStride(group.points.size());
            for(std::size_t k=0;k<shown;++k) {
                const auto i=k*stride%group.points.size();
                gw->setColor(LINE_COLOR,solid?color:cyrus::previewColor(cache->palette.get(),source,group.bandSlots[i],group.color));
                auto marker=group.points[i];gw->marker(&marker,POINT_MRKR);
            }
            gw->endMarkers();remaining-=shown;submitted+=shown;
        }
    }
    gw->setRndLimits(limits);
    ++fallbackCalls;fallbackPointVertices+=submitted;
    return &ok;
}

def_visible_primitive(cyrusPreviewFallbackStats,"cyrusPreviewFallbackStats");
Value* cyrusPreviewFallbackStats_cf(Value**,int count) {
    check_arg_count(cyrusPreviewFallbackStats,0,count);
    one_typed_value_local(Array* result);vl.result=new Array(4);vl.result->append(Integer::intern(1));
    for(auto value:{fallbackCalls.load(),fallbackPointVertices.load(),fallbackFaces.load()})vl.result->append(Integer64::intern(value));
    return_value(vl.result);
}

// Diagnostic export only; normal viewport redraw never allocates MAXScript rows.
def_visible_primitive(aminScatterPreviewPoints,"aminScatterPreviewPoints");
Value* aminScatterPreviewPoints_cf(Value** args,int count) {
    check_arg_count(aminScatterPreviewPoints,1,count);
    type_check(args[0],AminPointCache,_T("preview cache"));
    auto* cache=static_cast<AminPointCache*>(args[0]);
    two_typed_value_locals(Array* result,Array* row);
    vl.result=new Array(cache->size);
    for(std::size_t source=0;source<cache->pointGroups().size();++source) {
      const auto& group=cache->pointGroups()[source];
      for(std::size_t i=0;i<group.points.size();++i) {
        const auto p=group.points[i],color=cyrus::previewColor(cache->palette.get(),source,group.bandSlots[i],group.color);
        vl.row=new Array(2);vl.result->append(vl.row);
        vl.row->append(new Point3Value(p));
        vl.row->append(new ColorValue(AColor(color.x,color.y,color.z)));
      }
    }
    return_value(vl.result);
}

namespace {
std::vector<cyrus::PointLayer> retainedLayers(Value* cachesValue,Value* stylesValue) {
    type_check(cachesValue,Array,_T("preview caches"));
    type_check(stylesValue,Array,_T("preview styles"));
    auto* caches=static_cast<Array*>(cachesValue);auto* styles=static_cast<Array*>(stylesValue);
    // At most ten populations, each with one preview and one radius overlay.
    if(caches->size!=styles->size || caches->size>20) throw RuntimeError(_T("Invalid retained preview layers"));
    std::vector<cyrus::PointLayer> layers;layers.reserve(caches->size);
    for(int i=0;i<caches->size;++i) {
        type_check(caches->data[i],AminPointCache,_T("point cache"));
        type_check(styles->data[i],Array,_T("preview style"));
        const auto* cache=static_cast<AminPointCache*>(caches->data[i]);
        auto* style=static_cast<Array*>(styles->data[i]);
        if(cache->geometryMode<0 || cache->geometryMode>4 || !cache->pointSnapshot ||
           (cache->geometryMode!=0 && !cache->meshSnapshot) || (style->size!=2 && style->size!=8))
            throw RuntimeError(_T("Retained drawing requires a point-cloud or geometry cache"));
        layers.push_back({cache->pointSnapshot,style->data[0]->to_bool()!=FALSE,style->data[1]->to_point3()/255.f,cache->meshSnapshot,cache->palette});
        layers.back().appearance=cache->appearance;
        layers.back().geometryMode=cache->geometryMode;
        if(style->size==8)for(int setting=0;setting<6;++setting) {
            const auto limit=style->data[setting+2]->to_int64();
            if(limit<0 || limit>2147483647)throw RuntimeError(_T("Viewport limits must be nonnegative integers"));
            layers.back().limits.values[setting]=static_cast<std::uint64_t>(limit);
        }
    }
    return layers;
}
}
def_visible_primitive(cyrusRetainedPublish,"cyrusRetainedPublish");
Value* cyrusRetainedPublish_cf(Value** args,int count) {
    amin::diagnostics::StageTimer measurement(amin::diagnostics::Stage::Publication);
    check_arg_count(cyrusRetainedPublish,4,count);
    auto layers=retainedLayers(args[2],args[3]);
    return cyrus::publishPoints(args[0]->to_node(),args[1]->to_node(),std::move(layers)) ? &true_value : &false_value;
}
def_visible_primitive(cyrusRetainedMatches,"cyrusRetainedMatches");
Value* cyrusRetainedMatches_cf(Value** args,int count) {
    check_arg_count(cyrusRetainedMatches,3,count);
    return cyrus::pointsMatch(args[0]->to_node(),retainedLayers(args[1],args[2])) ? &true_value : &false_value;
}

// Bounded diagnostic export for transform, shading and source-color parity.
// Each row is #(vertex1, vertex2, vertex3, scalarShade, sourceColor01).
def_visible_primitive(cyrusPreviewTriangles,"cyrusPreviewTriangles");
Value* cyrusPreviewTriangles_cf(Value** args,int count) {
    check_arg_count(cyrusPreviewTriangles,2,count);
    type_check(args[0],AminPointCache,_T("preview cache"));
    auto* cache=static_cast<AminPointCache*>(args[0]);
    const int limit=args[1]->to_int();
    if(limit<0 || limit>100000) throw RuntimeError(_T("Diagnostic triangle limit must be 0..100000"));
    two_typed_value_locals(Array* result,Array* row);
    vl.result=new Array(int(std::min<std::size_t>(limit,cache->faceCount)));
    auto append=[&](const std::array<Point3,3>& face,float shade,Point3 color) {
        vl.row=new Array(5);vl.result->append(vl.row);
        for(auto p:face) vl.row->append(new Point3Value(p));
        vl.row->append(Float::intern(shade));vl.row->append(new Point3Value(color));
    };
    for(std::size_t source=0;source<cache->geometryGroups().size();++source) {
        const auto& group=cache->geometryGroups()[source];
        for(std::size_t i=0;i<group.instances.size();++i)for(const auto& face:group.faces) {
            if(vl.result->size>=limit) goto complete;
            const auto& tm=group.instances[i];
            auto a=VectorTransform(tm,face[1]-face[0]),b=VectorTransform(tm,face[2]-face[0]);
            const auto shade=.35f+.65f*std::abs(DotProd(Normalize(CrossProd(a,b)),Normalize(Point3(.3f,-.5f,.8f))));
            append({face[0]*tm,face[1]*tm,face[2]*tm},shade,cyrus::previewColor(cache->palette.get(),source,group.bandSlots[i],group.color));
        }
    }
complete:
    return_value(vl.result);
}
