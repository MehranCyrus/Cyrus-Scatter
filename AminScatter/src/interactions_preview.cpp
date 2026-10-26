#include "interactions_host.h"
#include "preview_sampling.h"
#include <chrono>
#include <map>
#include <numeric>
#include <tuple>

namespace cyrus {
namespace ci=interactions;
namespace {
using Face=std::array<Point3,3>;
using BatchKey=std::tuple<unsigned,unsigned,long long,long long,unsigned>;
Point3 host(ci::Vec p,double unit){return {float(p.x/unit),float(-p.z/unit),float(p.y/unit)};}
Matrix3 matrix(const ci::Transform& tm,double unit){Matrix3 m(1);m.SetRow(0,host(tm.rows[0],1));m.SetRow(1,host(ci::mul(tm.rows[2],-1),1));m.SetRow(2,host(tm.rows[1],1));m.SetRow(3,host(tm.rows[3],unit));return m;}
ci::Transform transform(const ci::Snapshot& snapshot,std::size_t index){auto found=snapshot.overrides.find(index);return found==snapshot.overrides.end()?snapshot.layout->transform(index):found->second;}
PreviewGeometry borrow(const std::shared_ptr<const MeshSnapshot>& snapshot,std::size_t group){
    const auto& src=snapshot->groups.at(group);PreviewGeometry out;out.sharedFaces=std::shared_ptr<const std::vector<Face>>(snapshot,&src.faceData());out.sharedBounds=snapshot->localBounds.at(group);out.sharedFingerprint=snapshot->faceFingerprints.at(group);
    out.color=src.color;out.placeholder=src.placeholder;out.reducedBox=src.reducedBox;return out;
}
void borrowInstances(PreviewGeometry& out,const std::shared_ptr<const MeshSnapshot>& snapshot,std::size_t group){
    const auto& src=snapshot->groups.at(group);if(src.edits)throw std::runtime_error("Interaction base already contains transient edits");
    out.sharedInstances=std::shared_ptr<const std::vector<Matrix3>>(snapshot,&src.instanceData());out.sharedBands=std::shared_ptr<const std::vector<std::uint8_t>>(snapshot,&src.bandData());
    out.sharedWorldBounds=snapshot->groupBounds.at(group);out.sharedInstanceFingerprint=snapshot->instanceFingerprints.at(group);
}
std::uint8_t band(const placements::Record& row,const PreviewPalette& palette){
    if(!row.band)return 0;auto it=std::lower_bound(palette.bandIDs.begin(),palette.bandIDs.end(),row.band);if(it==palette.bandIDs.end()||*it!=row.band)throw std::runtime_error("Interaction Band provenance differs from preview");return std::uint8_t(it-palette.bandIDs.begin()+1);
}
}
struct InteractionPreviewCache {
    std::weak_ptr<const ci::Snapshot> snapshot;
    std::vector<PointLayer> inputs,outputs;
    std::vector<int> indices;
    struct Part {std::size_t instance=0;std::shared_ptr<const ci::Pose> pose;ci::Transform transform;};
    struct Batch {std::vector<Part> parts;std::shared_ptr<const MeshSnapshot> mesh;std::shared_ptr<const SourceAppearance> appearance;};
    struct Layer {std::shared_ptr<const MeshSnapshot> base;std::shared_ptr<const PreviewPalette> palette;std::shared_ptr<const MeshAppearance> appearance;std::vector<std::shared_ptr<const SourceAppearance>> lightAppearance;std::shared_ptr<const std::vector<unsigned>> sourceSlots;std::shared_ptr<PreviewMemory> slotMemory;std::map<BatchKey,unsigned> slots;std::vector<Batch> batches;};
    std::vector<Layer> layers;
};
std::vector<PointLayer> interactionPreview(InteractionRuntime& runtime,const ci::Snapshot& snapshot,const std::vector<PointLayer>& base,const std::vector<int>& layerIndices){
    auto started=std::chrono::steady_clock::now();if(base.size()!=layerIndices.size())throw std::runtime_error("Interaction preview owner mapping differs");
    if(runtime.previewCache&&runtime.previewCache->snapshot.lock().get()==&snapshot&&runtime.previewCache->indices==layerIndices&&runtime.previewCache->inputs.size()==base.size()){
        const auto& cache=*runtime.previewCache;bool same=true;for(std::size_t i=0;i<base.size()&&same;++i){const auto& a=base[i];const auto& b=cache.inputs[i];same=a.snapshot==b.snapshot&&a.mesh==b.mesh&&a.palette==b.palette&&a.appearance==b.appearance&&a.geometryMode==b.geometryMode&&a.pointsPerInstance==b.pointsPerInstance;}
        if(same){auto output=base;for(std::size_t i=0;i<output.size();++i){output[i].snapshot=cache.outputs[i].snapshot;output[i].mesh=cache.outputs[i].mesh;output[i].palette=cache.outputs[i].palette;output[i].appearance=cache.outputs[i].appearance;}
            runtime.previewMs=std::chrono::duration<double,std::milli>(std::chrono::steady_clock::now()-started).count();return output;}}
    auto cache=runtime.previewCache?std::make_shared<InteractionPreviewCache>(*runtime.previewCache):std::make_shared<InteractionPreviewCache>();cache->layers.resize(runtime.rows.size());
    std::vector<PointLayer> output=base;
    for(std::size_t slot=0;slot<base.size();++slot){int li=layerIndices[slot];if(li<0)continue;if(li>=int(runtime.rows.size()))throw std::runtime_error("Invalid interaction preview layer");
        const auto& rows=runtime.rows[li];if(runtime.byLayerRow[li].empty())continue;const auto& input=base[slot];if(!input.palette)throw std::runtime_error("Interaction preview palette is missing");
        const bool lightPreview=snapshot.layout->layers[li].react&&input.geometryMode==4;
        bool modified=lightPreview;for(const auto& [i,p]:snapshot.poses){(void)p;if(snapshot.layout->instances[i].layer==unsigned(li)){modified=true;break;}}
        for(const auto& [i,tm]:snapshot.overrides){(void)tm;if(snapshot.layout->instances[i].layer==unsigned(li)){modified=true;break;}}
        if(!modified)for(auto i:snapshot.disabled)if(snapshot.layout->instances[i].layer==unsigned(li)){modified=true;break;}
        if(!modified)continue;
        auto& result=output[slot];std::vector<PointGroup> points(input.snapshot->groups.size());for(std::size_t i=0;i<points.size();++i)points[i].color=input.snapshot->groups[i].color;
        if(input.geometryMode==0){
            const std::size_t per=input.pointsPerInstance;if(!per||input.snapshot->lines)throw std::runtime_error("Interaction point preview lacks sampler provenance");
            std::vector<std::size_t> cursors(points.size());const std::uint64_t total=rows.size()*per,shown=input.snapshot->count;
            for(std::uint64_t sample=0;sample<shown;++sample){const auto flat=amin::previewPointIndex(sample,total,shown);unsigned row=unsigned(flat/per),source=rows.at(row).source-1;
                if(source>=points.size()||cursors[source]>=input.snapshot->groups[source].points.size())throw std::runtime_error("Interaction point sampler correspondence differs");
                const auto& old=input.snapshot->groups[source];auto cursor=cursors[source]++;auto index=runtime.byLayerRow[li][row];if(snapshot.disabled.contains(index))continue;auto pose=snapshot.poses.find(index);
                if(pose!=snapshot.poses.end()&&pose->second->allHidden)continue;
                Point3 p=old.points[cursor];if(index==UINT_MAX){points[source].points.push_back(p);points[source].bandSlots.push_back(old.bandSlots[cursor]);continue;}auto target=transform(snapshot,index);
                if(pose!=snapshot.poses.end()){
                    const auto& rig=*runtime.sources[li][source]->rig;auto original=snapshot.layout->transform(index);auto local=original.inversePoint({double(p.x)*snapshot.layout->metresPerUnit,double(p.z)*snapshot.layout->metresPerUnit,-double(p.y)*snapshot.layout->metresPerUnit});
                    auto vertex=ci::nearestSourceVertex(rig,local);if(pose->second->hiddenRoots[rig.partRoot[rig.labels[vertex]]])continue;p=host(target.point(ci::posePoint(rig,*pose->second,vertex)),snapshot.layout->metresPerUnit);
                }else if(snapshot.overrides.contains(index)){
                    auto original=snapshot.layout->transform(index);auto local=original.inversePoint({double(p.x)*snapshot.layout->metresPerUnit,double(p.z)*snapshot.layout->metresPerUnit,-double(p.y)*snapshot.layout->metresPerUnit});p=host(target.point(local),snapshot.layout->metresPerUnit);
                }
                points[source].points.push_back(p);points[source].bandSlots.push_back(old.bandSlots[cursor]);}
            result.snapshot=std::make_shared<PointSnapshot>(std::move(points));continue;
        }
        if(!input.mesh)throw std::runtime_error("Interaction mesh preview has no geometry");auto& layerCache=cache->layers[li];
        if(layerCache.base!=input.mesh||layerCache.appearance!=input.appearance||!samePalette(layerCache.palette,input.palette)){layerCache={};layerCache.base=input.mesh;layerCache.palette=input.palette;layerCache.appearance=input.appearance;}
        std::vector<PreviewGeometry> groups;groups.reserve(input.mesh->groups.size()+layerCache.batches.size());
        for(std::size_t g=0;g<input.mesh->groups.size();++g){groups.push_back(lightPreview?borrow(runtime.sources[li][g]->lightGeometry,0):borrow(input.mesh,g));groups.back().color=input.mesh->groups[g].color;borrowInstances(groups.back(),input.mesh,g);}
        if(lightPreview&&input.appearance&&layerCache.lightAppearance.empty()){
            for(unsigned source=0;source<runtime.sources[li].size();++source){const auto atlas=input.appearance->sources.at(source);std::shared_ptr<SourceAppearance> material;
                if(atlas){material=std::make_shared<SourceAppearance>();material->atlasOwner=atlas;material->width=atlas->width;material->tiles=atlas->tiles;material->textureColor=atlas->textureColor;const auto& rig=*runtime.sources[li][source]->rig;
                    material->uv.reserve(rig.previewUVCorners.size()*3);for(const auto& corners:rig.previewUVCorners)for(auto corner:corners){if(corner>=atlas->uv.size())throw std::runtime_error("Light source material corner exceeds its atlas");material->uv.push_back(atlas->uv[corner]);}
                    material->cpuBytes=material->uv.capacity()*sizeof(MaterialUV);material->memory=reserveSourceMetadataMemory(material->cpuBytes);material->memory->commit();}
                layerCache.lightAppearance.push_back(std::move(material));}}
        const auto wanted=input.mesh->instances;
        if(!layerCache.sourceSlots||layerCache.sourceSlots->size()!=wanted){
            layerCache.slotMemory=reserveMeshMemory({wanted*sizeof(unsigned),0});auto slots=std::make_shared<std::vector<unsigned>>(wanted);std::vector<unsigned> cursors(groups.size());
            for(std::size_t k=0;k<wanted;++k){unsigned row=unsigned(k*rows.size()/wanted),source=rows.at(row).source-1;if(source>=groups.size())throw std::runtime_error("Interaction mesh source correspondence differs");(*slots)[k]=cursors[source]++;}
            for(std::size_t source=0;source<cursors.size();++source)if(cursors[source]!=groups[source].instanceCount())throw std::runtime_error("Interaction mesh row selection differs from retained source stream");layerCache.sourceSlots=std::move(slots);layerCache.slotMemory->commit();
        }
        std::vector<std::shared_ptr<SparseInstances<Matrix3>>> edits(groups.size());
        auto patch=[&](std::size_t index,bool hide){const auto& instance=snapshot.layout->instances[index];if(instance.layer!=unsigned(li)||!wanted||!rows.size())return;
            auto k=(std::uint64_t(instance.row)*wanted+rows.size()-1)/rows.size();if(k>=wanted||k*rows.size()/wanted!=instance.row)return;
            auto source=instance.source;if(!edits[source])edits[source]=std::make_shared<SparseInstances<Matrix3>>();auto raw=(*layerCache.sourceSlots)[k];
            if(hide)edits[source]->hidden.push_back(raw);else edits[source]->transforms.emplace(raw,matrix(transform(snapshot,index),snapshot.layout->metresPerUnit));};
        for(const auto& [index,pose]:snapshot.poses){(void)pose;patch(index,true);}for(auto index:snapshot.disabled)patch(index,true);
        for(const auto& [index,tm]:snapshot.overrides){(void)tm;if(!snapshot.disabled.contains(index)&&!snapshot.poses.contains(index))patch(index,false);}
        for(std::size_t g=0;g<groups.size();++g)if(edits[g]){edits[g]->seal(groups[g].instanceData().size());groups[g].edits=edits[g];groups[g].editsMemory=reserveMeshMemory({edits[g]->bytes(),0});groups[g].editsMemory->commit();}
        std::map<BatchKey,std::vector<InteractionPreviewCache::Part>> batches;
        for(const auto& [index,pose]:snapshot.poses){const auto& instance=snapshot.layout->instances[index];if(instance.layer!=unsigned(li)||pose->allHidden||snapshot.disabled.contains(index))continue;
            auto tm=transform(snapshot,index);auto owner=band(rows.at(instance.row),*input.palette);BatchKey key{instance.source,owner,std::llround(std::floor(tm.rows[3].x)),std::llround(std::floor(tm.rows[3].z)),0};batches[key].push_back({index,pose,tm});}
        std::map<BatchKey,std::vector<InteractionPreviewCache::Part>> split;
        for(auto& [key,parts]:batches){std::sort(parts.begin(),parts.end(),[](const auto& a,const auto& b){return a.instance<b.instance;});const auto count=runtime.sources[li][std::get<0>(key)]->rig->previewFaces.size();const auto capacity=std::max<std::size_t>(1,2000000/std::max<std::size_t>(1,count));
            for(std::size_t i=0;i<parts.size();i+=capacity){auto chunk=key;std::get<4>(chunk)=unsigned(i/capacity);split[chunk]=std::vector<InteractionPreviewCache::Part>(parts.begin()+i,parts.begin()+std::min(parts.size(),i+capacity));}}
        batches=std::move(split);std::vector<unsigned> available;
        for(auto it=layerCache.slots.begin();it!=layerCache.slots.end();)if(!batches.contains(it->first)){available.push_back(it->second);layerCache.batches[it->second]={};it=layerCache.slots.erase(it);}else++it;
        available.clear();for(unsigned i=0;i<layerCache.batches.size();++i)if(!layerCache.batches[i].mesh)available.push_back(i);
        for(auto& [key,parts]:batches){auto [it,inserted]=layerCache.slots.emplace(key,unsigned(layerCache.batches.size()));if(inserted){
                if(!available.empty()){it->second=available.back();available.pop_back();}else {if(layerCache.batches.size()>=4096)throw std::runtime_error("Interaction preview batch budget: 4096");layerCache.batches.emplace_back();}}
            auto& batch=layerCache.batches[it->second];bool equal=batch.parts.size()==parts.size();
            if(equal)for(std::size_t i=0;i<parts.size()&&equal;++i){equal=parts[i].instance==batch.parts[i].instance&&parts[i].pose==batch.parts[i].pose;for(unsigned r=0;r<4&&equal;++r)equal=ci::length(ci::sub(parts[i].transform.rows[r],batch.parts[i].transform.rows[r]))==0;}
            if(equal&&batch.mesh)continue;
            PreviewGeometry geometry;unsigned source=std::get<0>(key),owner=std::get<1>(key);geometry.color=input.palette->sourceColors.at(source);geometry.instances.emplace_back(1);geometry.bandSlots.push_back(std::uint8_t(owner));
            const auto& rig=*runtime.sources[li][source]->rig;std::size_t budget=0;
            const auto atlas=input.appearance&&source<input.appearance->sources.size()?input.appearance->sources[source]:nullptr;
            std::shared_ptr<SourceAppearance> material;
            if(atlas){material=std::make_shared<SourceAppearance>();material->atlasOwner=atlas;material->width=atlas->width;material->tiles=atlas->tiles;material->textureColor=atlas->textureColor;}
            for(const auto& part:parts){const auto& p=*part.pose;const auto& prepared=*rig.rig;
                std::vector<Point3> vertices(rig.previewVertices.size());for(unsigned i=0;i<rig.previewVertices.size();++i)vertices[i]=host(part.transform.point(ci::posePoint(rig,p,rig.previewVertices[i])),snapshot.layout->metresPerUnit);
                for(unsigned pi=0;pi<rig.previewFaces.size();++pi){auto fi=rig.previewFaces[pi];auto tri=rig.previewTriangles[pi];if(!ci::visibleFace(rig,p,fi))continue;
                    if(++budget>2000000)throw std::runtime_error("One interaction preview batch exceeds 2M triangles");geometry.faces.push_back({vertices[rig.previewRemap[tri[0]]],vertices[rig.previewRemap[tri[1]]],vertices[rig.previewRemap[tri[2]]]});
                    if(material){if(atlas->uv.size()!=prepared.triangles.size()*3)throw std::runtime_error("Posed texture source UV correspondence differs");for(unsigned k=0;k<3;++k)material->uv.push_back(atlas->uv[rig.previewUVCorners[pi][k]]);}}}
            if(material){material->cpuBytes=material->uv.capacity()*sizeof(MaterialUV);material->memory=reserveSourceMetadataMemory(material->cpuBytes);material->memory->commit();}
            std::vector<PreviewGeometry> one;one.push_back(std::move(geometry));batch.mesh=std::make_shared<MeshSnapshot>(std::move(one));batch.parts=parts;batch.appearance=std::move(material);
        }
        auto palette=std::make_shared<PreviewPalette>(*input.palette);auto appearance=input.appearance?std::make_shared<MeshAppearance>(*input.appearance):nullptr;
        if(appearance&&lightPreview)appearance->sources=layerCache.lightAppearance;
        for(std::size_t i=0;i<layerCache.batches.size();++i){PreviewGeometry group;bool active=false;BatchKey key{};
            for(const auto& [candidate,index]:layerCache.slots)if(index==i){key=candidate;active=batches.contains(candidate);break;}
            unsigned source=std::get<0>(key);palette->sourceColors.push_back(input.palette->sourceColors.at(source));
            if(active&&layerCache.batches[i].mesh){group=borrow(layerCache.batches[i].mesh,0);group.instances.emplace_back(1);group.bandSlots.push_back(std::uint8_t(std::get<1>(key)));}
            groups.push_back(std::move(group));if(appearance)appearance->sources.push_back(active?layerCache.batches[i].appearance:nullptr);}
        result.mesh=std::make_shared<MeshSnapshot>(std::move(groups));result.snapshot=std::make_shared<PointSnapshot>(std::move(points));result.palette=std::move(palette);result.appearance=std::move(appearance);
    }
    cache->snapshot=runtime.pending&&runtime.pending.get()==&snapshot?runtime.pending:runtime.current;cache->inputs=base;cache->outputs=output;cache->indices=layerIndices;
    runtime.previewCache=std::move(cache);runtime.previewMs=std::chrono::duration<double,std::milli>(std::chrono::steady_clock::now()-started).count();return output;
}
}
