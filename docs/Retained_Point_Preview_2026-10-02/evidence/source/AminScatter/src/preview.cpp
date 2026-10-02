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
#include <atomic>
#include <new>
#include "point_preview.h"
#include "preview_sampling.h"
#include <maxscript/macros/define_instantiation_functions.h>
#undef ScripterExport
#define ScripterExport __declspec(dllexport)
#include "preview_batches.inc"

// Immutable transient MAXScript value: ownership follows the controller's local
// cache through GC. No global handles, stale node pointers or per-frame conversion.
visible_class_debug_ok(AminPointCache)
class AminPointCache : public Value {
public:
    using Group = cyrus::PointGroup;
    std::vector<Group> groups;
    std::shared_ptr<const cyrus::PointSnapshot> pointSnapshot;
    const std::vector<Group>& pointGroups() const { return pointSnapshot ? pointSnapshot->groups : groups; }
    struct Geometry { std::vector<std::array<Point3,3>> faces;std::vector<Matrix3> instances;Point3 color;bool placeholder=false; };
    std::vector<Geometry> geometry;
    int faceCount=0;
    int size=0;
    int geometryMode=0;
    // One allocation for triangles and one for source-preserving chunks. Their
    // exact payload sizes are reserved before allocation and released with GC.
    ProxyBatchReservation batchReservation;
    std::unique_ptr<ProxyTriangle[]> batchTriangles;
    std::unique_ptr<ProxyBatch[]> batches;
    std::size_t batchCount=0;
    AminPointCache() { tag=class_tag(AminPointCache); }
    classof_methods(AminPointCache,Value);
    void collect() override { delete this; }
    void sprin1(CharStream* s) override { s->printf(_T("<AminPointCache:%d>"),size); }
    Value* deep_copy(HashTable*) override { return this; }
    void prepareProxyBatches() {
        if (geometryMode < 1 || geometryMode > 3 || faceCount == 0) return;
        std::size_t chunks=0;
        for (const auto& group:geometry) {
            const auto count=group.faces.size()*group.instances.size();
            chunks+=(count+proxyBatchFaceLimit-1)/proxyBatchFaceLimit;
        }
        const auto bytes=std::size_t(faceCount)*sizeof(ProxyTriangle)+chunks*sizeof(ProxyBatch);
        if (!batchReservation.acquire(bytes)) return;
        try {
            auto triangles=std::make_unique<ProxyTriangle[]>(faceCount);
            auto prepared=std::make_unique<ProxyBatch[]>(chunks);
            std::size_t faceIndex=0,chunkIndex=0;
            for (const auto& group:geometry) {
                const auto first=faceIndex;
                for (const auto& tm:group.instances) for (const auto& face:group.faces) {
                    auto& out=triangles[faceIndex++];
                    out.vertices={face[0]*tm,face[1]*tm,face[2]*tm};
                    out.shade=proxyFaceShade(face,tm);
                }
                for (auto offset=first;offset<faceIndex;offset+=proxyBatchFaceLimit)
                    prepared[chunkIndex++]={offset,std::min(proxyBatchFaceLimit,faceIndex-offset),group.color};
            }
            batchTriangles=std::move(triangles);batches=std::move(prepared);batchCount=chunks;
        } catch (const std::bad_alloc&) {
            // An optimization allocation failure must not hide a valid preview.
            batchReservation.release();
        }
    }
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
    const auto shown=std::min<std::uint64_t>(total,static_cast<std::uint64_t>(budget));
    int size=0;
    for(std::uint64_t sample=0;sample<shown;++sample) {
        const auto flat=amin::previewPointIndex(sample,total,shown);
        const auto plant=static_cast<std::size_t>(flat/pointsPerPlant);
        const auto source=indices[plant];
        groups[source].points.push_back(samples[source][flat%pointsPerPlant]*transforms[plant]);
        ++size;
    }
    auto snapshot=std::make_shared<cyrus::PointSnapshot>(std::move(groups));
    auto* result=new AminPointCache();result->pointSnapshot=std::move(snapshot);result->size=size;
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
        if(proxyBatchDrawing && cache->batchCount) {
            // GraphicsWindow stays in identity/world space for the entire cache.
            for(std::size_t i=0;i<cache->batchCount;++i) {
                const auto& batch=cache->batches[i];
                const auto baseColor=solid?color:batch.color;
                gw->startTriangles();
                for(std::size_t j=batch.first;j<batch.first+batch.count;++j) {
                    auto& face=cache->batchTriangles[j];
                    Point3 rgb=baseColor*face.shade,colors[3]={rgb,rgb,rgb};
                    gw->triangle(face.vertices.data(),colors);
                }
                gw->endTriangles();
            }
        } else for(auto& group:cache->geometry)for(auto& tm:group.instances){
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
    for(const auto& group:cache->pointGroups()) {
        if(group.points.empty()) continue;
        gw->setColor(LINE_COLOR,solid?color:group.color);
        gw->startMarkers();
        for(const auto& p:group.points) { auto marker=p;gw->marker(&marker,POINT_MRKR); }
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
    for(const auto& group:cache->pointGroups()) for(const auto& p:group.points) {
        vl.row=new Array(2);vl.result->append(vl.row);
        vl.row->append(new Point3Value(p));
        vl.row->append(new ColorValue(AColor(group.color.x,group.color.y,group.color.z)));
    }
    return_value(vl.result);
}

namespace {
std::vector<cyrus::PointLayer> retainedLayers(Value* cachesValue,Value* stylesValue) {
    type_check(cachesValue,Array,_T("preview caches"));
    type_check(stylesValue,Array,_T("preview styles"));
    auto* caches=static_cast<Array*>(cachesValue);auto* styles=static_cast<Array*>(stylesValue);
    if(caches->size!=styles->size || caches->size>10) throw RuntimeError(_T("Invalid retained preview layers"));
    std::vector<cyrus::PointLayer> layers;layers.reserve(caches->size);
    for(int i=0;i<caches->size;++i) {
        type_check(caches->data[i],AminPointCache,_T("point cache"));
        type_check(styles->data[i],Array,_T("preview style"));
        const auto* cache=static_cast<AminPointCache*>(caches->data[i]);
        auto* style=static_cast<Array*>(styles->data[i]);
        if(cache->geometryMode!=0 || !cache->pointSnapshot || style->size!=2)
            throw RuntimeError(_T("Retained drawing requires a point-cloud cache"));
        layers.push_back({cache->pointSnapshot,style->data[0]->to_bool()!=FALSE,style->data[1]->to_point3()/255.f});
    }
    return layers;
}
}
def_visible_primitive(cyrusRetainedPublish,"cyrusRetainedPublish");
Value* cyrusRetainedPublish_cf(Value** args,int count) {
    check_arg_count(cyrusRetainedPublish,4,count);
    auto layers=retainedLayers(args[2],args[3]);
    return cyrus::publishPoints(args[0]->to_node(),args[1]->to_node(),std::move(layers)) ? &true_value : &false_value;
}
def_visible_primitive(cyrusRetainedMatches,"cyrusRetainedMatches");
Value* cyrusRetainedMatches_cf(Value** args,int count) {
    check_arg_count(cyrusRetainedMatches,3,count);
    return cyrus::pointsMatch(args[0]->to_node(),retainedLayers(args[1],args[2])) ? &true_value : &false_value;
}

// Read-only cache accounting. Array: mode, old batches, prepared batches,
// prepared faces, cache payload bytes, process bytes, cache/process byte caps.
def_visible_primitive(cyrusPreviewDrawStats,"cyrusPreviewDrawStats");
Value* cyrusPreviewDrawStats_cf(Value** args,int count) {
    check_arg_count(cyrusPreviewDrawStats,1,count);
    type_check(args[0],AminPointCache,_T("preview cache"));
    auto* cache=static_cast<AminPointCache*>(args[0]);
    std::size_t oldBatches=0;
    for(const auto& group:cache->geometry) oldBatches+=group.instances.size();
    one_typed_value_local(Array* result);vl.result=new Array(8);
    for(auto n:{std::size_t(cache->geometryMode),oldBatches,cache->batchCount,
        cache->batchCount?std::size_t(cache->faceCount):0,cache->batchReservation.bytes,
        proxyReservedBytes.load(std::memory_order_relaxed),proxyCacheByteLimit,proxyProcessByteLimit})
        vl.result->append(Integer64::intern(static_cast<INT64>(n)));
    return_value(vl.result);
}

// A/B diagnosis only: optional Boolean changes drawing, never cache/output data.
def_visible_primitive(cyrusPreviewBatchDrawing,"cyrusPreviewBatchDrawing");
Value* cyrusPreviewBatchDrawing_cf(Value** args,int count) {
    if(count>1) throw RuntimeError(_T("Expected zero or one batch-drawing Boolean"));
    if(count==1) proxyBatchDrawing=args[0]->to_bool()!=FALSE;
    return proxyBatchDrawing?&true_value:&false_value;
}

// Bounded diagnostic export for transform, shading and source-color parity.
// Each row is #(vertex1, vertex2, vertex3, scalarShade, sourceColor01).
def_visible_primitive(cyrusPreviewTriangles,"cyrusPreviewTriangles");
Value* cyrusPreviewTriangles_cf(Value** args,int count) {
    check_arg_count(cyrusPreviewTriangles,3,count);
    type_check(args[0],AminPointCache,_T("preview cache"));
    auto* cache=static_cast<AminPointCache*>(args[0]);
    const bool prepared=args[1]->to_bool()!=FALSE;
    const int limit=args[2]->to_int();
    if(limit<0 || limit>100000) throw RuntimeError(_T("Diagnostic triangle limit must be 0..100000"));
    two_typed_value_locals(Array* result,Array* row);
    vl.result=new Array(std::min(limit,cache->faceCount));
    auto append=[&](const std::array<Point3,3>& face,float shade,Point3 color) {
        vl.row=new Array(5);vl.result->append(vl.row);
        for(auto p:face) vl.row->append(new Point3Value(p));
        vl.row->append(Float::intern(shade));vl.row->append(new Point3Value(color));
    };
    if(prepared) {
        for(std::size_t i=0;i<cache->batchCount && vl.result->size<limit;++i) {
            const auto& batch=cache->batches[i];
            for(std::size_t j=batch.first;j<batch.first+batch.count && vl.result->size<limit;++j)
                append(cache->batchTriangles[j].vertices,cache->batchTriangles[j].shade,batch.color);
        }
    } else {
        for(const auto& group:cache->geometry) for(const auto& tm:group.instances) for(const auto& face:group.faces) {
            if(vl.result->size>=limit) goto complete;
            // Re-evaluate the previous draw formula independently of preparation.
            auto a=VectorTransform(tm,face[1]-face[0]),b=VectorTransform(tm,face[2]-face[0]);
            const auto shade=.35f+.65f*std::abs(DotProd(Normalize(CrossProd(a,b)),Normalize(Point3(.3f,-.5f,.8f))));
            append({face[0]*tm,face[1]*tm,face[2]*tm},shade,group.color);
        }
    }
complete:
    return_value(vl.result);
}
