#include "procedural.h"
#include <algorithm>
#include <array>
#include <cmath>
#include <map>
#include <numeric>
#include <set>
#include <stdexcept>
#include <tuple>
#include <unordered_map>

namespace cyrus::procedural {
namespace {
void require(bool b,const char* text){if(!b)throw std::invalid_argument(text);}
struct Policy {
    unsigned copies=0,others=0,external=0,targets=0;
    DistanceRule distance;
    bool preferred=false;
};
struct Rules {
    std::array<DistanceRule,2> values{};unsigned count=0;
    void add(DistanceRule r){
        if(!r.enabled||(r.multiplier==0&&r.gap==0))return;
        for(unsigned i=0;i<count;++i)if(values[i].planar==r.planar){
            if(values[i].multiplier>=r.multiplier&&values[i].gap>=r.gap)return;
            if(values[i].multiplier<=r.multiplier&&values[i].gap<=r.gap){values[i]=r;return;}
        }
        require(count<2,"Clearance constraint overflow");values[count++]=r;
    }
    bool same(const Rules& b)const{
        if(count!=b.count)return false;
        for(unsigned i=0;i<count;++i){
            bool found=false;
            for(unsigned j=0;j<b.count;++j)found|=values[i].planar==b.values[j].planar&&values[i].multiplier==b.values[j].multiplier&&values[i].gap==b.values[j].gap;
            if(!found)return false;
        }
        return true;
    }
};
struct Ref {unsigned layer,set,index;};
struct Context {
    const Plan& plan;
    std::vector<std::vector<std::vector<Policy>>> policies;
    std::map<std::tuple<unsigned,unsigned,unsigned,unsigned>,DistanceRule> defaults;
    Context(const Plan& p):plan(p){
        std::map<std::string,unsigned> layers;for(unsigned l=0;l<p.layers.size();++l)layers.emplace(p.layers[l].id,l);
        policies.resize(p.layers.size());
        for(unsigned l=0;l<p.layers.size();++l){
            policies[l].resize(p.layers[l].sets.size());std::set<std::string> ids;
            for(unsigned s=0;s<p.layers[l].sets.size();++s){const auto& pop=p.layers[l].sets[s];
                require(pop.sources.size()<=512,"Clearance supports at most 512 active source rows per population");
                for(const auto& src:pop.sources){
                    require(!src.id.empty()&&ids.insert(src.id).second,"Duplicate or missing clearance source identity");
                    require(src.copies<=2&&src.others<=2&&src.external<=3,"Unknown clearance scope policy");
                    require(std::isfinite(src.distance.multiplier)&&src.distance.multiplier>=0&&std::isfinite(src.distance.gap)&&src.distance.gap>=0,"Invalid source clearance distance");
                    require(src.targets.size()<=10,"Too many clearance target layers");
                    Policy q{src.copies,src.others,src.external,0,src.distance,src.preferred};std::set<std::string> targets;
                    for(const auto& id:src.targets){
                        require(!id.empty()&&targets.insert(id).second&&id!=p.layers[l].id,"Duplicate, empty or self clearance layer target");
                        const auto it=layers.find(id);if(it!=layers.end())q.targets|=1u<<it->second;
                        // Deleted targets remain authored but inactive; never name-bind.
                    }
                    policies[l][s].push_back(q);
                }
                if(pop.sources.empty())policies[l][s].push_back({});
                for(const auto& row:pop.samples){
                    require(row.source<policies[l][s].size(),"Placement source does not match its clearance policy cohort");
                    require(std::max({std::abs(row.position.x),std::abs(row.position.y),std::abs(row.position.z)})<=1e150,"Clearance coordinates exceed numeric range");
                }
            }
        }
        for(unsigned l=0;l<p.layers.size();++l)for(unsigned s=0;s<p.layers[l].sets.size();++s)
        for(unsigned ol=0;ol<p.layers.size();++ol)for(unsigned os=0;os<p.layers[ol].sets.size();++os){
            DistanceRule rule;
            if(l==ol&&s==os)rule=p.layers[l].sets[s].self;
            else{
                if(l==ol)rule=p.layers[l].siblings;
                const auto& a=l==ol?p.layers[l].sets[s].id:p.layers[l].id;
                const auto& b=l==ol?p.layers[ol].sets[os].id:p.layers[ol].id;
                for(const auto& pair:p.rules)if(pair.scope==(l==ol?Scope::Sets:Scope::Layers)&&((pair.a==a&&pair.b==b)||(pair.a==b&&pair.b==a))){rule=pair.distance;break;}
            }
            defaults.emplace(std::make_tuple(l,s,ol,os),rule);
        }
    }
    Rules rule(unsigned l,unsigned s,unsigned a,unsigned ol,unsigned os,unsigned b)const{
        const auto& x=policies[l][s][a];const auto& y=policies[ol][os][b];
        const bool same=l==ol&&s==os&&a==b,local=l==ol;
        const unsigned xm=local?(same?x.copies:x.others):x.external;
        const unsigned ym=local?(same?y.copies:y.others):y.external;
        Rules out;
        if(xm==0&&ym==0){out.add(defaults.at({l,s,ol,os}));return out;}
        const auto requests=[&](const Policy& q,unsigned mode,unsigned target){return local?mode==2:mode==3||(mode==2&&(q.targets&(1u<<target)));};
        if(requests(x,xm,ol))out.add(x.distance);
        if(!same&&requests(y,ym,l))out.add(y.distance);
        return out;
    }
    const Sample& sample(Ref r)const{return plan.layers[r.layer].sets[r.set].samples[r.index];}
    bool preferred(Ref r)const{return policies[r.layer][r.set][sample(r).source].preferred;}
    Rules rule(Ref a,Ref b)const{return rule(a.layer,a.set,sample(a).source,b.layer,b.set,sample(b).source);}
};
struct Cell {std::int64_t x,y,z;bool operator==(const Cell& b)const{return x==b.x&&y==b.y&&z==b.z;}};
struct Hash {std::size_t operator()(Cell c)const{return std::hash<std::int64_t>{}(c.x)^(std::hash<std::int64_t>{}(c.y)*0x9e3779b9u)^(std::hash<std::int64_t>{}(c.z)*0x85ebca6bu);}};
struct Grid {
    double width;bool planar;std::unordered_map<Cell,std::vector<unsigned>,Hash> cells;
    Cell cell(amin::Vec3 p)const{
        const auto axis=[&](double v){const double q=std::floor(v/width);require(std::isfinite(q)&&std::abs(q)<=9e15,"Clearance is too small for scene coordinates");return std::int64_t(q);};
        return {axis(p.x),axis(p.y),planar?0:axis(p.z)};
    }
    void add(amin::Vec3 p,unsigned i){if(width>0)cells[cell(p)].push_back(i);}
    template<class F>bool hit(amin::Vec3 p,F predicate)const{
        if(width<=0)return false;const auto c=cell(p);
        for(int z=planar?0:-1;z<=(planar?0:1);++z)for(int y=-1;y<=1;++y)for(int x=-1;x<=1;++x){
            const auto it=cells.find({c.x+x,c.y+y,c.z+z});if(it!=cells.end())for(auto j:it->second)if(predicate(j))return true;
        }return false;
    }
};
}
std::vector<int> clearanceComponents(const Plan& plan){
    Context context(plan);const auto n=plan.layers.size();
    std::vector<unsigned> parent(n);std::iota(parent.begin(),parent.end(),0);
    const auto root=[&](unsigned i){while(parent[i]!=i)i=parent[i];return i;};
    std::vector<bool> changed(n,false);
    // Compare effective constraints, never the UI's Defaults/Custom label.
    // Maximum: ten populations x 512 sources; no placement-sized pair table.
    for(unsigned l=0;l<n;++l)for(unsigned ol=l;ol<n;++ol)
    for(unsigned s=0;s<context.policies[l].size();++s)for(unsigned os=0;os<context.policies[ol].size();++os){
        Rules inherited;inherited.add(context.defaults.at({l,s,ol,os}));bool interacts=false,different=false;
        const auto& a=context.policies[l][s];const auto& b=context.policies[ol][os];
        for(unsigned i=0;i<a.size();++i)for(unsigned j=0;j<b.size();++j){
            const auto r=context.rule(l,s,i,ol,os,j);interacts|=r.count>0;
            different|=!r.same(inherited)||(r.count>0&&(a[i].preferred||b[j].preferred));
        }
        if(interacts){parent[root(ol)]=root(l);}
        if(different){changed[l]=true;changed[ol]=true;}
    }
    std::vector<bool> ranked(n,false);for(unsigned l=0;l<n;++l)if(changed[l])ranked[root(l)]=true;
    std::vector<int> result(n,-1);for(unsigned l=0;l<n;++l)if(ranked[root(l)])result[l]=int(root(l));
    return result;
}
void evaluateClearanceComponents(const Plan& plan,const std::vector<int>& components,Result& output,std::uint64_t& visits){
    if(std::none_of(components.begin(),components.end(),[](int c){return c>=0;}))return;
    Context context(plan);std::set<int> groups;for(int c:components)if(c>=0)groups.insert(c);
    for(int group:groups){
        std::vector<Ref> rows;std::vector<std::vector<std::vector<unsigned>>> indices(plan.layers.size());
        std::vector<std::vector<std::uint64_t>> prefixes(plan.layers.size());
        unsigned maxRounds=1;
        double maxRadius[2]{},maxFactor[2]{},maxGap[2]{};
        const auto admitRule=[&](DistanceRule r){if(r.enabled){const unsigned m=r.planar?0:1;maxFactor[m]=std::max(maxFactor[m],r.multiplier);maxGap[m]=std::max(maxGap[m],r.gap);}};
        for(unsigned l=0;l<plan.layers.size();++l)if(components[l]==group){
            const auto& layer=plan.layers[l];maxRounds=std::max(maxRounds,(layer.acceptedTarget||layer.repair)?layer.rounds:1u);
            indices[l].resize(layer.sets.size());output.layers[l].sets.resize(layer.sets.size());
            for(unsigned s=0;s<layer.sets.size();++s){
                const auto& set=layer.sets[s];prefixes[l].push_back(set.budget);
                for(unsigned i=0;i<set.samples.size();++i){
                    indices[l][s].push_back(unsigned(rows.size()));rows.push_back({l,s,i});
                    maxRadius[0]=std::max(maxRadius[0],set.samples[i].radii.xy);maxRadius[1]=std::max(maxRadius[1],set.samples[i].radii.spatial);
                }
                std::stable_sort(indices[l][s].begin(),indices[l][s].end(),[&](auto a,auto b){return context.sample(rows[a]).ordinal<context.sample(rows[b]).ordinal;});
            }
        }
        // Dormant distances must not alter numeric admission or grid cost.
        // Bound the grids using only compiled effective interactions.
        for(unsigned l=0;l<plan.layers.size();++l)if(components[l]==group)
        for(unsigned ol=l;ol<plan.layers.size();++ol)if(components[ol]==group)
        for(unsigned s=0;s<context.policies[l].size();++s)
        for(unsigned os=0;os<context.policies[ol].size();++os)
        for(unsigned a=0;a<context.policies[l][s].size();++a)
        for(unsigned b=0;b<context.policies[ol][os].size();++b){
            const auto rules=context.rule(l,s,a,ol,os,b);
            for(unsigned i=0;i<rules.count;++i)admitRule(rules.values[i]);
        }
        const unsigned none=unsigned(rows.size());
        std::vector<bool> suppressed(rows.size(),false),previousKept(rows.size(),false);
        std::vector<unsigned> blockers(rows.size(),none);
        for(unsigned round=0;round<maxRounds;++round){
            std::vector<bool> kept(rows.size(),false);std::vector<unsigned> nextBlockers(rows.size(),none),active;
            Grid xy{2*maxRadius[0]*maxFactor[0]+maxGap[0],true,{}},spatial{2*maxRadius[1]*maxFactor[1]+maxGap[1],false,{}};
            require(std::isfinite(xy.width)&&std::isfinite(spatial.width)&&std::max(xy.width,spatial.width)<=1e150,"Clearance radius overflow");
            for(unsigned l=0;l<plan.layers.size();++l)if(components[l]==group){
                const auto& layer=plan.layers[l];auto& out=output.layers[l];++out.rounds;
                for(unsigned s=0;s<layer.sets.size();++s){
                    const auto& pop=layer.sets[s];auto& r=out.sets[s];r.kept.clear();r.conflicts.clear();r.reasons.assign(pop.samples.size(),Reason::NotConsumed);r.attempts=prefixes[l][s];
                    std::size_t pins=0;for(auto j:indices[l][s])if(context.sample(rows[j]).protectedEdit)++pins;
                    std::size_t admitted=pins;
                    // Count admission is candidate ordered, BEFORE preference.
                    // A prior rejected row waits while its accepted blocker exists.
                    for(auto j:indices[l][s]){
                        const auto& p=context.sample(rows[j]);
                        if(suppressed[j]){r.reasons[rows[j].index]=Reason::Cleanup;continue;}
                        if(p.protectedEdit){kept[j]=true;active.push_back(j);continue;}
                        if(p.ordinal>=prefixes[l][s])continue;
                        if(blockers[j]!=none&&previousKept[blockers[j]]){nextBlockers[j]=blockers[j];r.reasons[rows[j].index]=rows[j].layer==rows[blockers[j]].layer?Reason::SelfSpacing:Reason::LayerSpacing;continue;}
                        if(layer.acceptedTarget&&admitted>=pop.budget)continue;
                        ++admitted;active.push_back(j);
                    }
                }
            }
            std::stable_sort(active.begin(),active.end(),[&](unsigned a,unsigned b){
                const auto x=rows[a],y=rows[b];const auto& p=context.sample(x);const auto& q=context.sample(y);
                return std::make_tuple(!p.protectedEdit,!context.preferred(x),x.layer,x.set,p.ordinal,a)<std::make_tuple(!q.protectedEdit,!context.preferred(y),y.layer,y.set,q.ordinal,b);
            });
            for(auto j:active)if(context.sample(rows[j]).protectedEdit){xy.add(context.sample(rows[j]).position,j);spatial.add(context.sample(rows[j]).position,j);}
            for(auto j:active){
                const auto ref=rows[j];const auto& a=context.sample(ref);auto& r=output.layers[ref.layer].sets[ref.set];unsigned blocker=none;
                const auto query=[&](const Grid& grid){return grid.hit(a.position,[&](unsigned k){
                    if(j==k)return false;
                    require(visits<plan.maxNeighborVisits,"Procedural spacing work limit exceeded; reduce Count, radius variation or retry rounds");++visits;++r.neighborVisits;
                    const auto& b=context.sample(rows[k]);const auto rules=context.rule(ref,rows[k]);const auto delta=a.position-b.position;
                    for(unsigned t=0;t<rules.count;++t){const auto& rule=rules.values[t];if(rule.planar!=grid.planar)continue;
                        const double d=rule.multiplier*(a.radii.forMetric(rule.planar)+b.radii.forMetric(rule.planar))+rule.gap;
                        if(std::hypot(delta.x,delta.y,rule.planar?0:delta.z)<d){blocker=k;return true;}
                    }return false;
                });};
                const bool collision=query(xy)||query(spatial);
                if(a.protectedEdit){r.reasons[ref.index]=Reason::Protected;if(collision)r.conflicts.push_back(ref.index);}
                else if(collision){nextBlockers[j]=blocker;r.reasons[ref.index]=ref.layer==rows[blocker].layer?Reason::SelfSpacing:Reason::LayerSpacing;}
                else{kept[j]=true;r.reasons[ref.index]=Reason::Accepted;xy.add(a.position,j);spatial.add(a.position,j);}
            }
            bool removed=false,more=false;
            for(unsigned l=0;l<plan.layers.size();++l)if(components[l]==group){
                const auto& layer=plan.layers[l];bool layerRemoved=false;
                if(layer.cleanup.cleanup){
                    std::vector<amin::Instance> plants;std::vector<unsigned> owners;
                    for(unsigned s=0;s<layer.sets.size();++s)for(auto j:indices[l][s])if(kept[j]){
                        amin::Instance p{};p.position=context.sample(rows[j]).position;p.candidateKey=owners.size();plants.push_back(p);owners.push_back(j);
                    }
                    amin::FinalWorkBudget work{plan.maxNeighborVisits-visits};
                    const auto cleaned=amin::finalize({},amin::Settings{},plants,{},std::vector<double>(plants.size(),0),{},layer.cleanup,&work);visits+=work.visits;
                    std::vector<bool> survives(plants.size(),false);for(const auto& p:cleaned)survives[p.candidateKey]=true;
                    for(unsigned k=0;k<owners.size();++k){const auto j=owners[k];const auto ref=rows[j];auto& r=output.layers[l].sets[ref.set];
                        if(k<work.rowVisits.size())r.neighborVisits+=work.rowVisits[k];
                        if(!survives[k]&&!context.sample(ref).protectedEdit){kept[j]=false;suppressed[j]=true;r.reasons[ref.index]=Reason::Cleanup;layerRemoved=true;}
                    }
                }
                const bool retry=round+1<layer.rounds&&(layer.acceptedTarget||layer.repair);
                for(unsigned s=0;s<layer.sets.size();++s){auto& r=output.layers[l].sets[s];const auto& pop=layer.sets[s];
                    for(auto j:indices[l][s])if(kept[j])r.kept.push_back(rows[j].index);
                    std::sort(r.kept.begin(),r.kept.end());
                    r.shortfall=layer.acceptedTarget&&r.kept.size()<pop.budget?pop.budget-r.kept.size():0;
                    if(r.shortfall&&retry){
                        const auto next=std::min<std::uint64_t>(pop.attemptLimit,std::max(prefixes[l][s]+32,prefixes[l][s]*2));
                        more|=next>prefixes[l][s];prefixes[l][s]=next;
                        for(auto j:indices[l][s])if(!kept[j]&&!suppressed[j]&&context.sample(rows[j]).ordinal<prefixes[l][s])more=true;
                    }
                    if(r.shortfall&&!retry)output.layers[l].limitReached=true;
                }
                removed|=layerRemoved;
                if(layerRemoved&&retry)more=true;
            }
            // A disappearing blocker releases its rejected candidates on the
            // next permitted replay. Only complete post-cleanup rounds escape.
            if(removed)for(unsigned j=0;j<rows.size();++j)if(nextBlockers[j]!=none&&!kept[nextBlockers[j]]){
                const auto& layer=plan.layers[rows[j].layer];if(round+1<layer.rounds&&(layer.acceptedTarget||layer.repair))more=true;
            }
            previousKept=std::move(kept);blockers=std::move(nextBlockers);
            if(!more)break;
            if(round+1==maxRounds)for(unsigned l=0;l<plan.layers.size();++l)if(components[l]==group)output.layers[l].limitReached=true;
        }
    }
}
}
