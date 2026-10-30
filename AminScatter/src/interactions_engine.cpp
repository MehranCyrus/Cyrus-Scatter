#include "interactions_engine.h"
#include "interaction_candidate_memo.h"
#include "execution.h"
#include <algorithm>
#include <atomic>
#include <chrono>
#include <numeric>
#include <set>
#include <stdexcept>
#include <tuple>

namespace cyrus::interactions {
namespace {
using Clock=std::chrono::steady_clock;
double hideReach(const LayerSettings& c){return c.coverRoots?std::max(c.gap,c.hideMargin):c.gap;}
Bounds reactRange(Vec centre,double reach,const LayerSettings& c){
    Bounds b{sub(centre,{reach,reach,reach}),add(centre,{reach,reach,reach})};
    // Coverage is independent of the selected bending/pruning algorithm.
    if(c.coverRoots&&c.hideUnder)b.hi.y=std::numeric_limits<double>::max()/4;
    return b;
}
double elapsed(Clock::time_point t){return std::chrono::duration<double,std::milli>(Clock::now()-t).count();}
Vec toCore(Vec p){return {p.x,p.z,-p.y};}
Transform relative(const Transform& obstacle,const Transform& plant){Transform result;for(int k=0;k<3;++k)result.rows[k]=plant.inverseVector(obstacle.rows[k]);result.rows[3]=plant.inversePoint(obstacle.rows[3]);return result;}
bool same(const Transform& a,const Transform& b){for(int k=0;k<4;++k)if(a.rows[k].x!=b.rows[k].x||a.rows[k].y!=b.rows[k].y||a.rows[k].z!=b.rows[k].z)return false;return true;}
bool sameLinear(const Transform& a,const Transform& b){for(int k=0;k<3;++k)if(a.rows[k].x!=b.rows[k].x||a.rows[k].y!=b.rows[k].y||a.rows[k].z!=b.rows[k].z)return false;return true;}
Shape colliderShape(std::size_t id,const std::shared_ptr<const MeshGeometry>& geometry,const Transform& transform,const Shape* old,const Transform* oldTransform,std::size_t& bytes,const std::function<std::shared_ptr<const void>(std::size_t)>& reserve){
    try{transform.scale();return {id+1,geometry,transform,true};}catch(const std::runtime_error&){}
    std::shared_ptr<const MeshGeometry> cooked;
    if(old&&oldTransform&&sameLinear(transform,*oldTransform))cooked=old->geometry;
    else {
        if(geometry->bytes()>128ull*1024*1024/3||bytes>128ull*1024*1024-geometry->bytes()*3)throw std::runtime_error("Affine collider copies exceed 128 MiB construction admission");
        auto lease=reserve?reserve(geometry->bytes()*3):nullptr;
        cooked=geometry->bakeLinear(transform,std::move(lease));
    }
    bytes+=cooked->bytes();if(bytes>128ull*1024*1024)throw std::runtime_error("Affine collider geometry exceeds 128 MiB admission");
    Transform translation;translation.rows[3]=transform.rows[3];return {id+1,std::move(cooked),translation,true};
}
}
Transform Layout::transform(std::size_t index)const{
    const auto& a=instances.at(index).hostTransform;Transform result;
    result.rows[0]=toCore({a[0],a[1],a[2]});result.rows[1]=toCore({a[6],a[7],a[8]});result.rows[2]=mul(toCore({a[3],a[4],a[5]}),-1);
    result.rows[3]=mul(toCore({a[9],a[10],a[11]}),metresPerUnit);return result;
}
struct Engine::Impl {
    struct Node {Bounds bounds;unsigned begin=0,count=0,left=0,right=0;};
    // Immutable, exact AABB broad phase. The tree stores only numeric bounds
    // and instance indices; sorted query results preserve original solver order.
    struct BoundsIndex {
        std::vector<std::size_t> ids,order;
        std::vector<Bounds> bounds;
        std::vector<Node> nodes;
        void add(std::size_t id,const Bounds& box){ids.push_back(id);bounds.push_back(box);}
        unsigned build(unsigned begin,unsigned end){
            unsigned id=unsigned(nodes.size());nodes.emplace_back();Bounds box;
            for(unsigned i=begin;i<end;++i)box.include(bounds[order[i]]);nodes[id].bounds=box;
            if(end-begin<=16){nodes[id].begin=begin;nodes[id].count=end-begin;return id;}
            Vec d=sub(box.hi,box.lo);
            // Upward footprint coverage is not a useful spatial split axis.
            const unsigned axis=box.hi.y==std::numeric_limits<double>::max()/4?
                (d.x>d.z?0:2):(d.x>d.y?(d.x>d.z?0:2):(d.y>d.z?1:2));
            unsigned mid=(begin+end)/2;
            auto centre=[&](std::size_t i){const auto& b=bounds[i];return axis==0?b.lo.x+b.hi.x:axis==1?b.lo.y+b.hi.y:b.lo.z+b.hi.z;};
            std::nth_element(order.begin()+begin,order.begin()+mid,order.begin()+end,[&](auto a,auto b){double x=centre(a),y=centre(b);return x==y?ids[a]<ids[b]:x<y;});
            auto left=build(begin,mid),right=build(mid,end);nodes[id].left=left;nodes[id].right=right;return id;
        }
        void finish(){order.resize(ids.size());std::iota(order.begin(),order.end(),0);nodes.reserve(ids.size()*2);if(!ids.empty())build(0,unsigned(ids.size()));}
        std::vector<std::size_t> query(const Bounds& box)const{
            std::vector<std::size_t> result;if(nodes.empty())return result;std::vector<unsigned> stack{0};
            while(!stack.empty()){unsigned id=stack.back();stack.pop_back();const auto& n=nodes[id];if(!box.overlaps(n.bounds))continue;
                if(n.count)for(unsigned k=n.begin;k<n.begin+n.count;++k){auto i=order[k];if(box.overlaps(bounds[i]))result.push_back(ids[i]);}
                else{stack.push_back(n.left);stack.push_back(n.right);}}
            return result;
        }
        std::size_t bytes()const{return (ids.capacity()+order.capacity())*sizeof(std::size_t)+bounds.capacity()*sizeof(Bounds)+nodes.capacity()*sizeof(Node);}
    };
    std::shared_ptr<const Layout> layout;
    std::vector<std::size_t> plants,obstacles,order;
    std::vector<Bounds> plantBounds;
    std::vector<Node> nodes;
    BoundsIndex obstacleIndex;
    std::unordered_map<std::size_t,std::size_t> obstacleSlots;
    std::unordered_map<const Source*,std::shared_ptr<const MeshGeometry>> neighbors;
    Statistics base;
    unsigned build(unsigned begin,unsigned end){
        unsigned id=unsigned(nodes.size());nodes.emplace_back();Bounds box;
        for(unsigned i=begin;i<end;++i)box.include(plantBounds[order[i]]);nodes[id].bounds=box;
        if(end-begin<=16){nodes[id].begin=begin;nodes[id].count=end-begin;return id;}
        Vec d=sub(box.hi,box.lo);
        // A footprint's upward extent is a query convention, not spatial
        // distribution. Splitting that artificial axis would group random
        // placement IDs and lose horizontal locality in a large garden.
        const unsigned axis=box.hi.y==std::numeric_limits<double>::max()/4?
            (d.x>d.z?0:2):(d.x>d.y?(d.x>d.z?0:2):(d.y>d.z?1:2));
        unsigned mid=(begin+end)/2;
        auto centre=[&](std::size_t i){const auto& b=plantBounds[i];return axis==0?b.lo.x+b.hi.x:axis==1?b.lo.y+b.hi.y:b.lo.z+b.hi.z;};
        std::nth_element(order.begin()+begin,order.begin()+mid,order.begin()+end,[&](auto a,auto b){double x=centre(a),y=centre(b);return x==y?a<b:x<y;});
        auto left=build(begin,mid),right=build(mid,end);nodes[id].left=left;nodes[id].right=right;return id;
    }
    std::vector<std::size_t> nearby(const Bounds& bounds)const{
        std::vector<std::size_t> result;if(nodes.empty())return result;std::vector<unsigned> stack{0};
        while(!stack.empty()){unsigned id=stack.back();stack.pop_back();const auto& n=nodes[id];if(!bounds.overlaps(n.bounds))continue;
            if(n.count)for(unsigned k=n.begin;k<n.begin+n.count;++k){auto j=order[k];if(bounds.overlaps(plantBounds[j]))result.push_back(plants[j]);}
            else{stack.push_back(n.left);stack.push_back(n.right);}}
        std::sort(result.begin(),result.end());return result;
    }
    const Definition& definition(std::size_t index)const{const auto& p=layout->instances.at(index);return *layout->sources.at(p.layer).at(p.source);}
    bool neighbor(std::size_t index)const{
        const auto& settings=layout->layers.at(layout->instances.at(index).layer);
        return settings.react&&settings.neighbors&&bool(definition(index).rig);
    }
    std::shared_ptr<const MeshGeometry> obstacleGeometry(std::size_t index)const{return index<layout->instances.size()?definition(index).collider:layout->sceneObstacles.at(index-layout->instances.size()).geometry;}
    Transform obstacleTransform(std::size_t index,const std::map<std::size_t,Transform>& overrides,const std::vector<Transform>& scene)const{
        if(index>=layout->instances.size())return scene.at(index-layout->instances.size());
        auto found=overrides.find(index);return found==overrides.end()?layout->transform(index):found->second;
    }
};
Engine::Engine(std::shared_ptr<const Layout> layout){
    workCounters().layouts.fetch_add(1,std::memory_order_relaxed);
    auto start=Clock::now();if(!layout||layout->instances.size()>1000000||layout->layers.size()>10||layout->sceneObstacles.size()>256||layout->sources.size()!=layout->layers.size()||!std::isfinite(layout->metresPerUnit)||layout->metresPerUnit<=0)throw std::runtime_error("Invalid interaction layout admission");
    auto p=std::make_shared<Impl>();p->layout=std::move(layout);
    std::set<std::pair<unsigned,std::string>> identities;
    for(std::size_t i=0;i<p->layout->instances.size();++i){const auto& instance=p->layout->instances[i];
        if(instance.layer>=p->layout->layers.size()||instance.source>=p->layout->sources[instance.layer].size()||!p->layout->sources[instance.layer][instance.source]||instance.identity.empty()||!identities.emplace(instance.layer,instance.identity).second)throw std::runtime_error("Invalid or duplicate interaction instance binding");
        const auto& cfg=p->layout->layers[instance.layer];if(!cfg.obstacle&&!cfg.react)continue;
        auto tm=p->layout->transform(i);const auto& def=p->definition(i);
        if(cfg.obstacle){if(!def.collider)throw std::runtime_error("Obstacle source has no admitted solid collider");
            if(p->obstacles.size()>=16384)throw std::runtime_error("Interaction obstacle budget: 16384 instances");
            p->obstacles.push_back(i);p->obstacleIndex.add(i,tm.bounds(def.collider->bounds()));}
        if(cfg.react){const double scale=tm.scale();if(!def.rig)throw std::runtime_error("Reacting source is not prepared");p->plants.push_back(i);double reach=def.rig->reach*scale+hideReach(cfg);
            if(p->neighbor(i)&&!p->neighbors.contains(def.rig.get())){const auto estimate=def.rig->rig->guides.size()*20*256ull;if(estimate>128ull*1024*1024-p->base.colliderBakeBytes)throw std::runtime_error("Neighbor branch construction exceeds 128 MiB admission");auto lease=p->layout->reserveGeometry?p->layout->reserveGeometry(estimate):nullptr;auto proxy=branchProxy(*def.rig,std::move(lease));p->base.colliderBakeBytes+=proxy->bytes();if(p->base.colliderBakeBytes>128ull*1024*1024)throw std::runtime_error("Neighbor branch geometry exceeds 128 MiB admission");p->neighbors.emplace(def.rig.get(),std::move(proxy));}
            const auto centre=tm.rows[3];Bounds b=reactRange(centre,reach,cfg);p->plantBounds.push_back(b);}}
    for(std::size_t i=0;i<p->layout->sceneObstacles.size();++i){const auto& scene=p->layout->sceneObstacles[i];if(!scene.geometry||scene.identity.empty())throw std::runtime_error("Invalid scene collider");const auto id=p->layout->instances.size()+i;p->obstacles.push_back(id);p->obstacleIndex.add(id,scene.transform.bounds(scene.geometry->bounds()));}
    for(std::size_t i=0;i<p->obstacles.size();++i)p->obstacleSlots.emplace(p->obstacles[i],i);
    p->order.resize(p->plants.size());std::iota(p->order.begin(),p->order.end(),0);p->nodes.reserve(p->plants.size()*2);if(!p->plants.empty())p->build(0,unsigned(p->plants.size()));p->obstacleIndex.finish();
    p->base.plants=p->plants.size();p->base.obstacles=p->obstacles.size();p->base.indexMs=elapsed(start);
    p->base.layoutPayloadBytes=sizeof(Layout)+p->layout->instances.capacity()*sizeof(Instance);for(const auto& i:p->layout->instances)p->base.layoutPayloadBytes+=i.identity.capacity();
    p->base.layoutPayloadBytes+=p->layout->sceneObstacles.capacity()*sizeof(SceneObstacle);for(const auto& obstacle:p->layout->sceneObstacles)p->base.layoutPayloadBytes+=obstacle.identity.capacity();
    p->base.obstacleIndexPayloadBytes=p->obstacleIndex.bytes();
    p->base.indexPayloadBytes=p->nodes.capacity()*sizeof(Impl::Node)+p->plantBounds.capacity()*sizeof(Bounds)+(p->plants.capacity()+p->obstacles.capacity()+p->order.capacity())*sizeof(std::size_t)+p->base.obstacleIndexPayloadBytes;
    if(p->base.layoutPayloadBytes+p->base.indexPayloadBytes>512ull*1024*1024)throw std::runtime_error("Interaction layout/index payload exceeds 512 MiB admission");impl_=std::move(p);
}
const Layout& Engine::layout()const{return *impl_->layout;}
std::vector<std::size_t> Engine::nearby(const Bounds& b)const{return impl_->nearby(b);}
std::shared_ptr<const Snapshot> Engine::evaluate(const std::shared_ptr<const Snapshot>& previous,const std::map<std::size_t,Transform>& overrides,const std::vector<std::size_t>& changed,const std::set<std::size_t>& disabled,const std::vector<Transform>& sceneTransforms)const{
    std::vector<Transform> scene=sceneTransforms;if(scene.empty()){if(previous)scene=previous->sceneTransforms;else for(const auto& obstacle:layout().sceneObstacles)scene.push_back(obstacle.transform);}
    if(scene.size()!=layout().sceneObstacles.size())throw std::runtime_error("Scene collider transform correspondence changed");
    if(previous&&previous->layout==impl_->layout&&previous->overrides.size()==overrides.size()&&previous->disabled==disabled){
        bool equal=previous->sceneTransforms.size()==scene.size();for(std::size_t i=0;i<scene.size()&&equal;++i)equal=same(previous->sceneTransforms[i],scene[i]);auto a=previous->overrides.begin(),b=overrides.begin();for(;a!=previous->overrides.end();++a,++b)if(a->first!=b->first||!same(a->second,b->second)){equal=false;break;}if(equal)return previous;
    }
    workCounters().evaluations.fetch_add(1,std::memory_order_relaxed);
    auto start=Clock::now();auto next=std::make_shared<Snapshot>();next->layout=impl_->layout;next->generation=previous?previous->generation+1:1;next->statistics=impl_->base;next->overrides=overrides;next->disabled=disabled;next->sceneTransforms=scene;
    if(previous&&previous->layout!=impl_->layout)throw std::runtime_error("Previous interaction publication belongs to another layout");
    if(overrides.size()>4096)throw std::runtime_error("More than 4096 transient edited instances; commit the layout before further live edits");
    for(const auto& [index,tm]:overrides){if(index>=layout().instances.size())throw std::runtime_error("Unknown edited interaction instance");const auto& cfg=layout().layers[layout().instances[index].layer];if(cfg.react)tm.scale();}
    for(auto index:disabled)if(index>=layout().instances.size())throw std::runtime_error("Unknown disabled interaction instance");
    if(previous){next->poses=previous->poses;next->retainedRootCounts=previous->retainedRootCounts;next->responseWarnings=previous->responseWarnings;next->statistics.indexMs=0;}
    auto tmFor=[&](std::size_t index,const auto& map){auto found=map.find(index);return found==map.end()?layout().transform(index):found->second;};
    next->worldObstacles.reserve(impl_->obstacles.size());
    for(auto id:impl_->obstacles){const auto slot=impl_->obstacleSlots.at(id);auto raw=impl_->obstacleTransform(id,overrides,scene);auto oldRaw=previous?impl_->obstacleTransform(id,previous->overrides,previous->sceneTransforms):raw;
        next->worldObstacles.push_back(colliderShape(id,impl_->obstacleGeometry(id),raw,previous?&previous->worldObstacles.at(slot):nullptr,previous?&oldRaw:nullptr,next->statistics.colliderBakeBytes,layout().reserveGeometry));}
    std::set<std::size_t> affected;auto queryStart=Clock::now();
    // Build old/new edited reactor coverage once. A batch edit must not copy
    // or scan both entire override maps for each changed region or plant.
    Impl::BoundsIndex editedReactors;
    auto addEditedReactors=[&](const auto& map){
        for(const auto& [plant,tm]:map){
            const auto& cfg=layout().layers[layout().instances[plant].layer];
            if(!cfg.react)continue;
            const double reach=impl_->definition(plant).rig->reach*tm.scale()+hideReach(cfg);
            editedReactors.add(plant,reactRange(tm.rows[3],reach,cfg));
        }
    };
    addEditedReactors(overrides);if(previous)addEditedReactors(previous->overrides);
    editedReactors.finish();next->statistics.transientReactorIndexPayloadBytes=editedReactors.bytes();
    auto addNear=[&](const Bounds& box){
        for(auto plant:nearby(box))affected.insert(plant);
        for(auto plant:editedReactors.query(box))affected.insert(plant);
    };
    bool sceneChanged=false;if(previous)for(std::size_t i=0;i<scene.size();++i)sceneChanged|=!same(previous->sceneTransforms[i],scene[i]);
    if(!previous||(changed.empty()&&!sceneChanged)){
        for(const auto& obstacle:next->worldObstacles)addNear(obstacle.transform.bounds(obstacle.geometry->bounds()));
        for(auto plant:impl_->plants)if(impl_->neighbor(plant))affected.insert(plant);
        if(previous){for(const auto& [plant,pose]:previous->poses){(void)pose;affected.insert(plant);}for(const auto& [plant,count]:previous->retainedRootCounts){(void)count;affected.insert(plant);}}
    }else for(auto stone:changed){
        const auto& instance=layout().instances.at(stone);const auto& cfg=layout().layers[instance.layer];
        if(cfg.obstacle)for(auto box:{tmFor(stone,previous->overrides).bounds(impl_->definition(stone).collider->bounds()),tmFor(stone,overrides).bounds(impl_->definition(stone).collider->bounds())})addNear(box);
        if(impl_->neighbor(stone))for(const auto* map:{&previous->overrides,&overrides}){
            const auto tm=tmFor(stone,*map);const double reach=impl_->definition(stone).rig->reach*tm.scale();
            addNear(reactRange(tm.rows[3],reach,cfg));
        }
        if(cfg.react)affected.insert(stone);
    }
    if(previous)for(std::size_t i=0;i<scene.size();++i)if(!same(previous->sceneTransforms[i],scene[i])){
        const auto slot=impl_->obstacleSlots.at(layout().instances.size()+i);for(const auto* value:std::array<const Shape*,2>{&previous->worldObstacles[slot],&next->worldObstacles[slot]})addNear(value->transform.bounds(value->geometry->bounds()));}
    // An edited obstacle may be arbitrarily far from its published base bound.
    // Build a bounded per-evaluation index of successor overrides once, rather
    // than scanning every edited obstacle for every affected plant.
    Impl::BoundsIndex editedObstacles;
    for(const auto& [index,tm]:overrides){const auto& instance=layout().instances[index];
        if(layout().layers[instance.layer].obstacle&&!disabled.contains(index))editedObstacles.add(index,tm.bounds(impl_->definition(index).collider->bounds()));}
    for(std::size_t i=0;i<scene.size();++i)if(!same(scene[i],layout().sceneObstacles[i].transform)){const auto id=layout().instances.size()+i;editedObstacles.add(id,scene[i].bounds(layout().sceneObstacles[i].geometry->bounds()));}
    editedObstacles.finish();next->statistics.transientObstacleIndexPayloadBytes=editedObstacles.bytes();
    if(next->statistics.layoutPayloadBytes+next->statistics.indexPayloadBytes+next->statistics.transientObstacleIndexPayloadBytes+next->statistics.transientReactorIndexPayloadBytes>512ull*1024*1024)throw std::runtime_error("Interaction layout/index payload exceeds 512 MiB admission");
    next->statistics.queryMs=elapsed(queryStart);next->statistics.affected=affected.size();auto fitStart=Clock::now();
    const std::vector<std::size_t> jobs(affected.begin(),affected.end());
    struct Result{std::shared_ptr<Pose> pose;std::exception_ptr error;};std::vector<Result> results(jobs.size());
    auto requested=amin::computeParticipants();
    // The existing session override always wins. For a large automatic contact
    // update, use up to eight participants while leaving two logical CPUs free
    // on machines with more than four; small work keeps the established cap.
    if(!amin::computeThreads()&&jobs.size()>=256){const auto available=std::max(1u,std::thread::hardware_concurrency());
        requested=std::max(requested,std::min(8u,available>4?available-2:available));}
    // A handful of large trees can cost more than hundreds of simple blades.
    // Use prepared guide counts to admit parallel work without scanning meshes.
    std::size_t guideWork=0;
    for(auto i:jobs){guideWork+=impl_->definition(i).rig->rig->guides.size();if(guideWork>=512)break;}
    const std::size_t minimumJobs=guideWork>=512?2:16;
    auto workerCount=jobs.size()<minimumJobs?1u:unsigned(std::min<std::size_t>(requested,jobs.size()));
    // Worst-case bounded query vectors, tree traversal stacks and 64 admitted
    // local shapes per worker. This is a conservative charge, not process RSS.
    const auto obstacleScratchPerWorker=3*impl_->obstacles.size()*sizeof(std::size_t)+128*sizeof(unsigned)+
        64*(2*sizeof(Shape)+MeshWorld::cachedShapeBytes()+2*sizeof(Bounds)+sizeof(InverseTransform)+sizeof(double)+sizeof(void*));
    const bool detailed=std::any_of(jobs.begin(),jobs.end(),[&](auto i){return layout().layers[layout().instances[i].layer].response==0;});
    const auto exactScratchPerWorker=detailed?2*50000*sizeof(Vec)+detail::guideCandidateMemoBytes:0;
    const auto fixedPayload=next->statistics.layoutPayloadBytes+next->statistics.indexPayloadBytes+next->statistics.transientObstacleIndexPayloadBytes+next->statistics.transientReactorIndexPayloadBytes+next->statistics.colliderBakeBytes;
    while(workerCount>1&&fixedPayload+std::size_t(workerCount)*(obstacleScratchPerWorker+exactScratchPerWorker)>512ull*1024*1024)--workerCount;
    next->statistics.obstacleQueryScratchBoundBytes=std::size_t(workerCount)*obstacleScratchPerWorker;
    next->statistics.exactMeshScratchBoundBytes=std::size_t(workerCount)*exactScratchPerWorker;
    if(fixedPayload+next->statistics.obstacleQueryScratchBoundBytes+next->statistics.exactMeshScratchBoundBytes>512ull*1024*1024)throw std::runtime_error("Interaction layout/index/query payload exceeds 512 MiB admission");
    // Plants can differ greatly in guide count and contact complexity. Claim
    // bounded jobs dynamically, but retain one result slot per sorted input;
    // the ordered merge below still selects the same first failure and pose.
    // forRanges joins a partially launched team before its full-range serial
    // fallback, which restarts the cursor and overwrites speculative results.
    std::atomic<std::size_t> nextJob{0};
    const auto execution=amin::detail::forRanges(jobs.size(),minimumJobs,[&](unsigned,std::size_t begin,std::size_t end){if(begin==0&&end==jobs.size())nextJob.store(0,std::memory_order_relaxed);for(;;){const auto job=nextJob.fetch_add(1,std::memory_order_relaxed);if(job>=jobs.size())break;results[job]={};const auto index=jobs[job];try{
        const auto& instance=layout().instances[index];const auto& cfg=layout().layers[instance.layer];const auto& source=*impl_->definition(index).rig;
        if(disabled.contains(index))continue;
        auto plantTM=tmFor(index,overrides);double scale=plantTM.scale();Bounds range;double reach=source.reach*scale+hideReach(cfg);range=reactRange(plantTM.rows[3],reach,cfg);
        std::vector<Shape> local;auto candidates=impl_->obstacleIndex.query(range);
        candidates.erase(std::remove_if(candidates.begin(),candidates.end(),[&](auto obstacle){return obstacle<layout().instances.size()?(overrides.contains(obstacle)||disabled.contains(obstacle)):!same(scene[obstacle-layout().instances.size()],layout().sceneObstacles[obstacle-layout().instances.size()].transform);}),candidates.end());
        auto moved=editedObstacles.query(range);candidates.insert(candidates.end(),moved.begin(),moved.end());std::sort(candidates.begin(),candidates.end());
        for(auto obstacle:candidates){if(obstacle==index||disabled.contains(obstacle))continue;const auto& shape=next->worldObstacles.at(impl_->obstacleSlots.at(obstacle));if(!range.overlaps(shape.transform.bounds(shape.geometry->bounds())))continue;
            if(local.size()>=64)throw std::runtime_error("More than 64 relevant colliders for one plant");local.push_back({shape.id,shape.geometry,relative(shape.transform,plantTM),true});}
        if(impl_->neighbor(index)){auto near=nearby(range);
            auto edited=editedReactors.query(range);near.insert(near.end(),edited.begin(),edited.end());
            std::sort(near.begin(),near.end());near.erase(std::unique(near.begin(),near.end()),near.end());
            for(auto other:near){if(other==index||disabled.contains(other)||!impl_->neighbor(other))continue;const auto& peer=layout().instances[other];
                const auto& current=layout().instances[index];if(std::tie(peer.layer,peer.identity)>=std::tie(current.layer,current.identity))continue;
                const auto tm=tmFor(other,overrides);const auto& geometry=impl_->neighbors.at(impl_->definition(other).rig.get());if(!range.overlaps(tm.bounds(geometry->bounds())))continue;
                if(local.size()>=64)throw std::runtime_error("More than 64 nearby obstacle/tree shapes for one plant; increase spacing or separate the adaptation group");local.push_back({other+1,geometry,relative(tm,plantTM),false});
            }
        }
        if(local.empty())continue;
        std::shared_ptr<Pose> pose;try{
            if(cfg.response){std::uint64_t seed=1469598103934665603ull;for(unsigned char c:instance.identity){seed^=c;seed*=1099511628211ull;}
                pose=std::make_shared<Pose>(adaptSource(source,local,cfg.gap/scale,cfg.strength,cfg.response,cfg.pruneAmount,cfg.pruneThreshold/scale,seed,cfg.trunkBend,cfg.fixedBase,cfg.bendTransition,cfg.coverRoots,cfg.hideMargin/scale,cfg.hideUnder,unit(plantTM.inverseVector({0,1,0}))));}
            else pose=std::make_shared<Pose>(fitSource(source,local,cfg.gap/scale,cfg.stiffness,cfg.coverRoots,next->generation,unit(plantTM.inverseVector({0,1,0})),cfg.hideMargin/scale,cfg.hideUnder));}
        catch(const std::exception& error){throw std::runtime_error("Layer "+std::to_string(instance.layer+1)+", instance "+instance.identity+": "+error.what());}
        results[job].pose=std::move(pose);
    }catch(...){results[job].error=std::current_exception();}}},workerCount);
    next->statistics.participants=execution.participants;next->statistics.threadFallback=execution.threadLaunchFallback;
    // Join every numeric worker and validate all results before mutating the
    // staged pose map. Ordered merge preserves deterministic failure identity.
    for(const auto& result:results)if(result.error)std::rethrow_exception(result.error);
    for(std::size_t job=0;job<jobs.size();++job){auto& pose=results[job].pose;auto index=jobs[job];if(pose){next->statistics.fittedGuides+=pose->activeGuides;next->statistics.queries+=pose->queries;next->statistics.coverageQueries+=pose->coverageQueries;next->statistics.separationQueries+=pose->separationQueries;next->statistics.iterations+=pose->iterations;next->statistics.hinges+=pose->hinges;next->statistics.meshRefinements+=pose->meshRefinements;next->statistics.meshRefinementWork+=pose->meshRefinementWork;next->statistics.workerCoverageMs+=pose->coverageMs;next->statistics.workerMeshCheckMs+=pose->meshCheckMs;next->statistics.workerMeshTransformMs+=pose->meshTransformMs;next->statistics.workerMeshPointMs+=pose->meshPointMs;next->statistics.workerMeshFaceMs+=pose->meshFaceMs;next->statistics.workerEdgeQualityMs+=pose->edgeQualityMs;}
        if(pose&&(pose->blockedGuides||pose->limitedGuides))next->responseWarnings[index]={pose->blockedGuides,pose->limitedGuides};else next->responseWarnings.erase(index);
        if(pose){next->statistics.exactMeshChecks+=pose->exact.checks;next->statistics.exactPointTests+=pose->exact.pointTests;
            next->statistics.exactFaceTests+=pose->exact.faceTests;next->statistics.exactTransformedVertices+=pose->exact.transformedVertices;next->statistics.exactInverseVertices+=pose->exact.inverseVertices;}
        if(pose&&pose->retainedCoveredRoots)next->retainedRootCounts[index]=pose->retainedCoveredRoots;else next->retainedRootCounts.erase(index);
        if(pose&&pose->changed){auto old=previous?previous->poses.find(index):next->poses.end();
            if(previous&&old!=previous->poses.end()&&pose->activeGuides==0&&old->second->activeGuides==0&&pose->allHidden==old->second->allHidden&&pose->hiddenRoots==old->second->hiddenRoots&&pose->hiddenGuides==old->second->hiddenGuides){next->poses[index]=old->second;++next->statistics.reusedPoses;}
            else next->poses[index]=std::move(pose);
        }else if(next->poses.erase(index))++next->statistics.restored;}
    next->statistics.fitMs=elapsed(fitStart);
    for(const auto& [index,pose]:next->poses){(void)index;next->statistics.covered+=pose->allHidden;next->statistics.posed+=!pose->allHidden;
        next->statistics.posePayloadBytes+=pose->bytes;next->statistics.hiddenRoots+=pose->coveredRoots;next->statistics.prunedGuides+=pose->prunedGuides;
        next->statistics.qualityCheckedGuides+=pose->qualityCheckedGuides;next->statistics.qualityWarningGuides+=pose->qualityWarningGuides;
        next->statistics.maximumCheckedStemEdgeChange=std::max(next->statistics.maximumCheckedStemEdgeChange,pose->maximumCheckedStemEdgeChange);}
    for(const auto& [index,count]:next->retainedRootCounts){(void)index;next->statistics.retainedCoveredRoots+=count;}
    for(const auto& [index,warning]:next->responseWarnings){(void)index;next->statistics.blockedGuides+=warning.first;next->statistics.limitedGuides+=warning.second;}
    next->statistics.posePayloadBytes+=next->responseWarnings.size()*(3*sizeof(std::size_t)+3*sizeof(void*))+next->responseWarnings.bucket_count()*sizeof(void*);
    next->statistics.posePayloadBytes+=next->retainedRootCounts.size()*(2*sizeof(std::size_t)+3*sizeof(void*))+next->retainedRootCounts.bucket_count()*sizeof(void*);
    for(const auto& [index,pose]:next->poses){(void)pose;if(!affected.contains(index))++next->statistics.reusedPoses;}
    if(next->statistics.posePayloadBytes>256ull*1024*1024)throw std::runtime_error("Interaction pose payload exceeds 256 MiB admission");
    next->statistics.totalMs=elapsed(start);return next;
}
Json statisticsJson(const Statistics& s){return {{"plants",s.plants},{"obstacles",s.obstacles},{"affected",s.affected},{"posed",s.posed},{"covered",s.covered},{"hidden_roots",s.hiddenRoots},{"retained_covered_roots",s.retainedCoveredRoots},
    {"pruned_guides",s.prunedGuides},{"blocked_guides",s.blockedGuides},{"limited_guides",s.limitedGuides},{"collider_bake_bytes",s.colliderBakeBytes},
    {"exact_mesh_checks",s.exactMeshChecks},{"exact_point_tests",s.exactPointTests},{"exact_face_tests",s.exactFaceTests},{"exact_transformed_vertices",s.exactTransformedVertices},{"exact_inverse_vertices",s.exactInverseVertices},
    {"fitted_guides",s.fittedGuides},{"queries",s.queries},{"coverage_queries",s.coverageQueries},{"separation_queries",s.separationQueries},{"iterations",s.iterations},{"hinge_fits",s.hinges},{"mesh_refinements",s.meshRefinements},{"mesh_refinement_work",s.meshRefinementWork},{"compute_participants",s.participants},{"thread_launch_fallback",s.threadFallback},{"reused_poses",s.reusedPoses},{"restored",s.restored},
    {"quality_checked_guides",s.qualityCheckedGuides},{"quality_warning_guides",s.qualityWarningGuides},{"maximum_checked_stem_edge_change",s.maximumCheckedStemEdgeChange},
    {"layout_payload_bytes",s.layoutPayloadBytes},{"index_payload_bytes",s.indexPayloadBytes},{"obstacle_index_payload_bytes",s.obstacleIndexPayloadBytes},{"transient_obstacle_index_payload_bytes",s.transientObstacleIndexPayloadBytes},{"transient_reactor_index_payload_bytes",s.transientReactorIndexPayloadBytes},{"obstacle_query_scratch_bound_bytes",s.obstacleQueryScratchBoundBytes},{"exact_mesh_scratch_bound_bytes",s.exactMeshScratchBoundBytes},{"pose_payload_bytes",s.posePayloadBytes},
    {"index_ms",s.indexMs},{"query_ms",s.queryMs},{"fit_ms",s.fitMs},{"total_ms",s.totalMs},
    {"worker_coverage_ms",s.workerCoverageMs},{"worker_mesh_check_ms",s.workerMeshCheckMs},{"worker_mesh_transform_ms",s.workerMeshTransformMs},{"worker_mesh_point_ms",s.workerMeshPointMs},{"worker_mesh_face_ms",s.workerMeshFaceMs},{"worker_edge_quality_ms",s.workerEdgeQualityMs}};}
Json Engine::audit(const Snapshot& snapshot,std::size_t triangleBudget)const{
    if(snapshot.layout!=impl_->layout||triangleBudget<1||triangleBudget>20000000)throw std::runtime_error("Invalid full-mesh audit admission");
    auto transform=[&](std::size_t i){auto found=snapshot.overrides.find(i);return found==snapshot.overrides.end()?layout().transform(i):found->second;};
    std::set<std::size_t> plants;for(const auto& obstacle:snapshot.worldObstacles){if(snapshot.disabled.contains(obstacle.id-1))continue;const auto box=obstacle.transform.bounds(obstacle.geometry->bounds());for(auto plant:nearby(box))plants.insert(plant);}
    for(auto plant:impl_->plants)if(impl_->neighbor(plant))plants.insert(plant);
    for(const auto& [index,tm]:snapshot.overrides){(void)tm;if(layout().layers[layout().instances[index].layer].react)plants.insert(index);}
    Json output={{"scope","Independent complete visible triangles in double precision; renderer float delivery is a separate check"},{"results",Json::array()}};std::size_t remaining=triangleBudget;
    for(auto index:plants){if(snapshot.disabled.contains(index))continue;auto tm=transform(index);const auto& source=*impl_->definition(index).rig;std::vector<Shape> shapes;
        const double reach=source.reach*tm.scale();Bounds bounds{sub(tm.rows[3],{reach,reach,reach}),add(tm.rows[3],{reach,reach,reach})};
        for(const auto& obstacle:snapshot.worldObstacles)if(obstacle.id!=index+1&&!snapshot.disabled.contains(obstacle.id-1)&&bounds.overlaps(obstacle.transform.bounds(obstacle.geometry->bounds())))shapes.push_back({obstacle.id,obstacle.geometry,relative(obstacle.transform,tm)});
        if(impl_->neighbor(index))for(auto other:impl_->plants){if(other==index||snapshot.disabled.contains(other)||!impl_->neighbor(other))continue;
            const auto& actor=layout().instances[index];const auto& peer=layout().instances[other];if(std::tie(peer.layer,peer.identity)>=std::tie(actor.layer,actor.identity))continue;
            const auto& geometry=impl_->neighbors.at(impl_->definition(other).rig.get());auto otherTM=transform(other);if(bounds.overlaps(otherTM.bounds(geometry->bounds())))shapes.push_back({other+1,geometry,relative(otherTM,tm)});}
        if(shapes.empty())continue;Pose rest;rest.guides.resize(source.rig->guides.size());rest.hiddenRoots.resize(source.rig->guides.size());auto found=snapshot.poses.find(index);const auto& pose=found==snapshot.poses.end()?rest:*found->second;
        auto report=auditSource(source,pose,shapes,remaining);remaining-=report.at("triangles").get<std::size_t>();report["instance"]=index;report["layer"]=layout().instances[index].layer+1;report["identity"]=layout().instances[index].identity;output["results"].push_back(std::move(report));}
    output["triangles"]=triangleBudget-remaining;return output;
}
}
