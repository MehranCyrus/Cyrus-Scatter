#include "interactions_engine.h"
#include "execution.h"
#include <algorithm>
#include <chrono>
#include <numeric>
#include <set>
#include <stdexcept>

namespace cyrus::interactions {
namespace {
using Clock=std::chrono::steady_clock;
double elapsed(Clock::time_point t){return std::chrono::duration<double,std::milli>(Clock::now()-t).count();}
Vec toCore(Vec p){return {p.x,p.z,-p.y};}
Transform relative(const Transform& obstacle,const Transform& plant){Transform result;for(int k=0;k<3;++k)result.rows[k]=plant.inverseVector(obstacle.rows[k]);result.rows[3]=plant.inversePoint(obstacle.rows[3]);return result;}
bool same(const Transform& a,const Transform& b){for(int k=0;k<4;++k)if(a.rows[k].x!=b.rows[k].x||a.rows[k].y!=b.rows[k].y||a.rows[k].z!=b.rows[k].z)return false;return true;}
}
Transform Layout::transform(std::size_t index)const{
    const auto& a=instances.at(index).hostTransform;Transform result;
    result.rows[0]=toCore({a[0],a[1],a[2]});result.rows[1]=toCore({a[6],a[7],a[8]});result.rows[2]=mul(toCore({a[3],a[4],a[5]}),-1);
    result.rows[3]=mul(toCore({a[9],a[10],a[11]}),metresPerUnit);return result;
}
struct Engine::Impl {
    struct Node {Bounds bounds;unsigned begin=0,count=0,left=0,right=0;};
    std::shared_ptr<const Layout> layout;
    std::vector<std::size_t> plants,obstacles,order;
    std::vector<Bounds> plantBounds;
    std::vector<Node> nodes;
    Statistics base;
    unsigned build(unsigned begin,unsigned end){
        unsigned id=unsigned(nodes.size());nodes.emplace_back();Bounds box;
        for(unsigned i=begin;i<end;++i)box.include(plantBounds[order[i]]);nodes[id].bounds=box;
        if(end-begin<=16){nodes[id].begin=begin;nodes[id].count=end-begin;return id;}
        Vec d=sub(box.hi,box.lo);unsigned axis=d.x>d.y?(d.x>d.z?0:2):(d.y>d.z?1:2),mid=(begin+end)/2;
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
};
Engine::Engine(std::shared_ptr<const Layout> layout){
    auto start=Clock::now();if(!layout||layout->instances.size()>1000000||layout->layers.size()>10||layout->sources.size()!=layout->layers.size()||!std::isfinite(layout->metresPerUnit)||layout->metresPerUnit<=0)throw std::runtime_error("Invalid interaction layout admission");
    auto p=std::make_shared<Impl>();p->layout=std::move(layout);
    std::set<std::pair<unsigned,std::string>> identities;
    for(std::size_t i=0;i<p->layout->instances.size();++i){const auto& instance=p->layout->instances[i];
        if(instance.layer>=p->layout->layers.size()||instance.source>=p->layout->sources[instance.layer].size()||!p->layout->sources[instance.layer][instance.source]||instance.identity.empty()||!identities.emplace(instance.layer,instance.identity).second)throw std::runtime_error("Invalid or duplicate interaction instance binding");
        const auto& cfg=p->layout->layers[instance.layer];if(!cfg.obstacle&&!cfg.react)continue;
        auto tm=p->layout->transform(i);double scale=tm.scale();const auto& def=p->definition(i);
        if(cfg.obstacle){if(!def.collider)throw std::runtime_error("Obstacle source has no admitted solid collider");p->obstacles.push_back(i);}
        if(cfg.react){if(!def.rig)throw std::runtime_error("Reacting source is not prepared");p->plants.push_back(i);double reach=def.rig->reach*scale+cfg.gap;
            const auto centre=tm.rows[3];Bounds b{ sub(centre,{reach,reach,reach}),add(centre,{reach,reach,reach})};p->plantBounds.push_back(b);}}
    if(p->obstacles.size()>4096)throw std::runtime_error("Interaction obstacle budget: 4096 instances");
    p->order.resize(p->plants.size());std::iota(p->order.begin(),p->order.end(),0);p->nodes.reserve(p->plants.size()*2);if(!p->plants.empty())p->build(0,unsigned(p->plants.size()));
    p->base.plants=p->plants.size();p->base.obstacles=p->obstacles.size();p->base.indexMs=elapsed(start);
    p->base.layoutPayloadBytes=sizeof(Layout)+p->layout->instances.capacity()*sizeof(Instance);for(const auto& i:p->layout->instances)p->base.layoutPayloadBytes+=i.identity.capacity();
    p->base.indexPayloadBytes=p->nodes.capacity()*sizeof(Impl::Node)+p->plantBounds.capacity()*sizeof(Bounds)+(p->plants.capacity()+p->obstacles.capacity()+p->order.capacity())*sizeof(std::size_t);
    if(p->base.layoutPayloadBytes+p->base.indexPayloadBytes>512ull*1024*1024)throw std::runtime_error("Interaction layout/index payload exceeds 512 MiB admission");impl_=std::move(p);
}
const Layout& Engine::layout()const{return *impl_->layout;}
std::vector<std::size_t> Engine::nearby(const Bounds& b)const{return impl_->nearby(b);}
std::shared_ptr<const Snapshot> Engine::evaluate(const std::shared_ptr<const Snapshot>& previous,const std::map<std::size_t,Transform>& overrides,const std::vector<std::size_t>& changed,const std::set<std::size_t>& disabled)const{
    if(previous&&previous->layout==impl_->layout&&previous->overrides.size()==overrides.size()&&previous->disabled==disabled){
        bool equal=true;auto a=previous->overrides.begin(),b=overrides.begin();for(;a!=previous->overrides.end();++a,++b)if(a->first!=b->first||!same(a->second,b->second)){equal=false;break;}if(equal)return previous;
    }
    auto start=Clock::now();auto next=std::make_shared<Snapshot>();next->layout=impl_->layout;next->generation=previous?previous->generation+1:1;next->statistics=impl_->base;next->overrides=overrides;next->disabled=disabled;
    if(previous&&previous->layout!=impl_->layout)throw std::runtime_error("Previous interaction publication belongs to another layout");
    if(overrides.size()>4096)throw std::runtime_error("More than 4096 transient edited instances; commit the layout before further live edits");
    for(const auto& [index,tm]:overrides){if(index>=layout().instances.size())throw std::runtime_error("Unknown edited interaction instance");const auto& cfg=layout().layers[layout().instances[index].layer];if(cfg.obstacle||cfg.react)tm.scale();}
    for(auto index:disabled)if(index>=layout().instances.size())throw std::runtime_error("Unknown disabled interaction instance");
    if(previous){next->poses=previous->poses;next->retainedRootCounts=previous->retainedRootCounts;next->statistics.indexMs=0;}
    auto tmFor=[&](std::size_t index,const auto& map){auto found=map.find(index);return found==map.end()?layout().transform(index):found->second;};
    std::set<std::size_t> affected;auto queryStart=Clock::now();
    auto addNear=[&](const Bounds& box){
        for(auto plant:nearby(box))affected.insert(plant);
        auto edited=[&](const auto& map){for(const auto& [plant,tm]:map){const auto& i=layout().instances[plant];const auto& cfg=layout().layers[i.layer];if(!cfg.react)continue;double r=impl_->definition(plant).rig->reach*tm.scale()+cfg.gap;Bounds b{sub(tm.rows[3],{r,r,r}),add(tm.rows[3],{r,r,r})};if(b.overlaps(box))affected.insert(plant);}};
        edited(overrides);if(previous)edited(previous->overrides);
    };
    if(!previous||changed.empty()){
        for(auto stone:impl_->obstacles){auto box=tmFor(stone,overrides).bounds(impl_->definition(stone).collider->bounds());addNear(box);}
        if(previous){for(const auto& [plant,pose]:previous->poses){(void)pose;affected.insert(plant);}for(const auto& [plant,count]:previous->retainedRootCounts){(void)count;affected.insert(plant);}}
    }else for(auto stone:changed){
        const auto& instance=layout().instances.at(stone);const auto& cfg=layout().layers[instance.layer];
        if(cfg.obstacle)for(auto box:{tmFor(stone,previous->overrides).bounds(impl_->definition(stone).collider->bounds()),tmFor(stone,overrides).bounds(impl_->definition(stone).collider->bounds())})addNear(box);
        if(cfg.react)affected.insert(stone);
    }
    next->statistics.queryMs=elapsed(queryStart);next->statistics.affected=affected.size();auto fitStart=Clock::now();
    const std::vector<std::size_t> jobs(affected.begin(),affected.end());
    struct Result{std::shared_ptr<Pose> pose;std::exception_ptr error;};std::vector<Result> results(jobs.size());
    const auto workerCount=jobs.size()<16?1u:unsigned(std::min<std::size_t>(amin::computeParticipants(),jobs.size()));
    const auto execution=amin::detail::forRanges(jobs.size(),16,[&](unsigned slot,std::size_t begin,std::size_t end){const auto stride=begin==0&&end==jobs.size()?1u:workerCount;for(std::size_t job=slot;job<jobs.size();job+=stride){results[job]={};const auto index=jobs[job];try{
        const auto& instance=layout().instances[index];const auto& cfg=layout().layers[instance.layer];const auto& source=*impl_->definition(index).rig;
        if(disabled.contains(index))continue;
        auto plantTM=tmFor(index,overrides);double scale=plantTM.scale();Bounds range;double reach=source.reach*scale+cfg.gap;range={sub(plantTM.rows[3],{reach,reach,reach}),add(plantTM.rows[3],{reach,reach,reach})};
        std::vector<Shape> local;
        for(auto obstacle:impl_->obstacles){if(obstacle==index||disabled.contains(obstacle))continue;auto obstacleTM=tmFor(obstacle,overrides);const auto& def=impl_->definition(obstacle);if(!range.overlaps(obstacleTM.bounds(def.collider->bounds())))continue;
            local.push_back({obstacle+1,def.collider,relative(obstacleTM,plantTM),true});}
        if(local.size()>64)throw std::runtime_error("More than 64 relevant colliders for one plant");
        if(local.empty())continue;
        std::shared_ptr<Pose> pose;try{pose=std::make_shared<Pose>(fitSource(source,local,cfg.gap/scale,cfg.stiffness,cfg.coverRoots,next->generation,unit(plantTM.inverseVector({0,1,0}))));}
        catch(const std::exception& error){throw std::runtime_error("Layer "+std::to_string(instance.layer+1)+", instance "+instance.identity+": "+error.what());}
        results[job].pose=std::move(pose);
    }catch(...){results[job].error=std::current_exception();}}});
    next->statistics.participants=execution.participants;next->statistics.threadFallback=execution.threadLaunchFallback;
    // Join every numeric worker and validate all results before mutating the
    // staged pose map. Ordered merge preserves deterministic failure identity.
    for(const auto& result:results)if(result.error)std::rethrow_exception(result.error);
    for(std::size_t job=0;job<jobs.size();++job){auto& pose=results[job].pose;auto index=jobs[job];if(pose){next->statistics.fittedGuides+=pose->activeGuides;next->statistics.queries+=pose->queries;next->statistics.coverageQueries+=pose->coverageQueries;next->statistics.separationQueries+=pose->separationQueries;next->statistics.iterations+=pose->iterations;next->statistics.hinges+=pose->hinges;next->statistics.meshRefinements+=pose->meshRefinements;next->statistics.meshRefinementWork+=pose->meshRefinementWork;}
        if(pose&&pose->retainedCoveredRoots)next->retainedRootCounts[index]=pose->retainedCoveredRoots;else next->retainedRootCounts.erase(index);
        if(pose&&pose->changed){auto old=previous?previous->poses.find(index):next->poses.end();
            if(previous&&old!=previous->poses.end()&&pose->activeGuides==0&&old->second->activeGuides==0&&pose->allHidden==old->second->allHidden&&pose->hiddenRoots==old->second->hiddenRoots){next->poses[index]=old->second;++next->statistics.reusedPoses;}
            else next->poses[index]=std::move(pose);
        }else if(next->poses.erase(index))++next->statistics.restored;}
    next->statistics.fitMs=elapsed(fitStart);
    for(const auto& [index,pose]:next->poses){(void)index;next->statistics.covered+=pose->allHidden;next->statistics.posed+=!pose->allHidden;
        next->statistics.posePayloadBytes+=pose->bytes;next->statistics.hiddenRoots+=pose->coveredRoots;}
    for(const auto& [index,count]:next->retainedRootCounts){(void)index;next->statistics.retainedCoveredRoots+=count;}
    next->statistics.posePayloadBytes+=next->retainedRootCounts.size()*(2*sizeof(std::size_t)+3*sizeof(void*))+next->retainedRootCounts.bucket_count()*sizeof(void*);
    for(const auto& [index,pose]:next->poses){(void)pose;if(!affected.contains(index))++next->statistics.reusedPoses;}
    if(next->statistics.posePayloadBytes>256ull*1024*1024)throw std::runtime_error("Interaction pose payload exceeds 256 MiB admission");
    next->statistics.totalMs=elapsed(start);return next;
}
Json statisticsJson(const Statistics& s){return {{"plants",s.plants},{"obstacles",s.obstacles},{"affected",s.affected},{"posed",s.posed},{"covered",s.covered},{"hidden_roots",s.hiddenRoots},{"retained_covered_roots",s.retainedCoveredRoots},
    {"fitted_guides",s.fittedGuides},{"queries",s.queries},{"coverage_queries",s.coverageQueries},{"separation_queries",s.separationQueries},{"iterations",s.iterations},{"hinge_fits",s.hinges},{"mesh_refinements",s.meshRefinements},{"mesh_refinement_work",s.meshRefinementWork},{"compute_participants",s.participants},{"thread_launch_fallback",s.threadFallback},{"reused_poses",s.reusedPoses},{"restored",s.restored},
    {"layout_payload_bytes",s.layoutPayloadBytes},{"index_payload_bytes",s.indexPayloadBytes},{"pose_payload_bytes",s.posePayloadBytes},
    {"index_ms",s.indexMs},{"query_ms",s.queryMs},{"fit_ms",s.fitMs},{"total_ms",s.totalMs}};}
Json Engine::audit(const Snapshot& snapshot,std::size_t triangleBudget)const{
    if(snapshot.layout!=impl_->layout||triangleBudget<1||triangleBudget>20000000)throw std::runtime_error("Invalid full-mesh audit admission");
    auto transform=[&](std::size_t i){auto found=snapshot.overrides.find(i);return found==snapshot.overrides.end()?layout().transform(i):found->second;};
    std::set<std::size_t> plants;for(auto obstacle:impl_->obstacles){if(snapshot.disabled.contains(obstacle))continue;const auto box=transform(obstacle).bounds(impl_->definition(obstacle).collider->bounds());for(auto plant:nearby(box))plants.insert(plant);}
    for(const auto& [index,tm]:snapshot.overrides){(void)tm;if(layout().layers[layout().instances[index].layer].react)plants.insert(index);}
    Json output={{"scope","Independent complete visible triangles in double precision; renderer float delivery is a separate check"},{"results",Json::array()}};std::size_t remaining=triangleBudget;
    for(auto index:plants){if(snapshot.disabled.contains(index))continue;auto tm=transform(index);const auto& source=*impl_->definition(index).rig;std::vector<Shape> shapes;
        const double reach=source.reach*tm.scale();Bounds bounds{sub(tm.rows[3],{reach,reach,reach}),add(tm.rows[3],{reach,reach,reach})};
        for(auto obstacle:impl_->obstacles)if(obstacle!=index&&!snapshot.disabled.contains(obstacle)){const auto& def=impl_->definition(obstacle);auto other=transform(obstacle);if(bounds.overlaps(other.bounds(def.collider->bounds())))shapes.push_back({obstacle+1,def.collider,relative(other,tm)});}
        if(shapes.empty())continue;Pose rest;rest.guides.resize(source.rig->guides.size());rest.hiddenRoots.resize(source.rig->guides.size());auto found=snapshot.poses.find(index);const auto& pose=found==snapshot.poses.end()?rest:*found->second;
        auto report=auditSource(source,pose,shapes,remaining);remaining-=report.at("triangles").get<std::size_t>();report["instance"]=index;report["layer"]=layout().instances[index].layer+1;report["identity"]=layout().instances[index].identity;output["results"].push_back(std::move(report));}
    output["triangles"]=triangleBudget-remaining;return output;
}
}
