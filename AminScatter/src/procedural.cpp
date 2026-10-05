#include "procedural.h"
#include <algorithm>
#include <cmath>
#include <limits>
#include <map>
#include <set>
#include <stdexcept>
#include <tuple>

namespace cyrus::procedural {
namespace {
void require(bool ok,const char* message){if(!ok)throw std::invalid_argument(message);}
void validate(const DistanceRule& r){
    require(std::isfinite(r.multiplier)&&r.multiplier>=0&&std::isfinite(r.gap)&&r.gap>=0,"Invalid procedural rule");
}
}
double transformScaleBound(const std::array<amin::Vec3,3>& rows){
    for(const auto& row:rows)require(std::isfinite(row.x)&&std::isfinite(row.y)&&std::isfinite(row.z),"Non-finite radius transform");
    double bound=0;
    for(std::size_t i=0;i<3;++i){double sum=0;for(std::size_t j=0;j<3;++j)sum+=std::abs(amin::dot(rows[i],rows[j]));bound=std::max(bound,sum);}
    require(std::isfinite(bound),"Transform radius overflow");return std::sqrt(bound);
}
Result evaluate(const Plan& plan){
    require(plan.layers.size()<=10&&plan.maxSamples>0&&plan.maxSamples<=1000000,"Invalid procedural plan limits");
    require(plan.maxNeighborVisits>0&&plan.maxNeighborVisits<=50000000,"Invalid spacing work limit");
    std::uint64_t visits=0;
    std::map<std::string,std::size_t> layerIDs;
    std::map<std::string,std::pair<std::size_t,std::size_t>> setIDs;
    std::size_t count=0,sets=0;
    for(std::size_t l=0;l<plan.layers.size();++l){const auto& layer=plan.layers[l];
        require(!layer.id.empty()&&layerIDs.emplace(layer.id,l).second,"Duplicate or empty layer identity");
        validate(layer.siblings);require(layer.rounds>=1&&layer.rounds<=16,"Repair rounds must be 1..16");
        require(!layer.cleanup.relax,"Procedural cleanup cannot move points");
        for(std::size_t s=0;s<layer.sets.size();++s){const auto& set=layer.sets[s];++sets;
            require(!set.id.empty()&&setIDs.emplace(set.id,std::make_pair(l,s)).second,"Duplicate or empty set identity");
            validate(set.self);require(set.budget<=100000&&set.attemptLimit<=100000,"Population budget/attempt limit exceeds 100000");
            require(set.attemptLimit>=set.budget,"Attempt limit is below initial budget");
            std::set<std::string> ids;std::set<std::uint64_t> ordinaryOrdinals;
            for(const auto& p:set.samples){
                require(!p.id.empty()&&ids.insert(p.id).second,"Duplicate or empty instance identity");
                require(std::isfinite(p.radius)&&p.radius>=0&&std::isfinite(p.position.x)&&std::isfinite(p.position.y)&&std::isfinite(p.position.z),"Non-finite or negative procedural sample");
                if(!p.protectedEdit)require(ordinaryOrdinals.insert(p.ordinal).second,"Duplicate ordinary candidate ordinal");
            }
            count+=set.samples.size();require(count<=plan.maxSamples,"Procedural candidate memory admission limit exceeded");
        }
    }
    require(sets<=10,"Procedural policy supports ten total populations");
    std::map<std::tuple<Scope,std::string,std::string>,DistanceRule> rules;
    for(const auto& rule:plan.rules){validate(rule.distance);
        require(rule.a!=rule.b,"Pair rule needs distinct endpoints");
        if(rule.scope==Scope::Layers)require(layerIDs.count(rule.a)&&layerIDs.count(rule.b),"Unknown layer rule endpoint");
        else {
            require(setIDs.count(rule.a)&&setIDs.count(rule.b),"Unknown set rule endpoint");
            require(setIDs.at(rule.a).first==setIDs.at(rule.b).first,"Set-pair rule must reference siblings");
        }
        const auto pair=std::minmax(rule.a,rule.b);
        require(rules.emplace(std::make_tuple(rule.scope,pair.first,pair.second),rule.distance).second,"Duplicate pair rule");
    }
    const auto pairRule=[&](std::size_t l,std::size_t s,std::size_t otherLayer,std::size_t otherSet){
        const bool sibling=l==otherLayer;
        const auto& a=sibling?plan.layers[l].sets[s].id:plan.layers[l].id;
        const auto& b=sibling?plan.layers[otherLayer].sets[otherSet].id:plan.layers[otherLayer].id;
        const auto endpoints=std::minmax(a,b);
        const auto found=rules.find(std::make_tuple(sibling?Scope::Sets:Scope::Layers,endpoints.first,endpoints.second));
        return found==rules.end()?(sibling?plan.layers[l].siblings:DistanceRule{}):found->second;
    };
    Result output;output.layers.resize(plan.layers.size());
    for(std::size_t l=0;l<plan.layers.size();++l){const auto& layer=plan.layers[l];auto& result=output.layers[l];
        result.sets.resize(layer.sets.size());
        std::vector<std::uint64_t> prefixes;std::vector<std::vector<bool>> suppressed;
        for(const auto& set:layer.sets){prefixes.push_back(set.budget);suppressed.emplace_back(set.samples.size(),false);}
        const unsigned maxRounds=(layer.acceptedTarget||layer.repair)?layer.rounds:1;
        for(unsigned round=0;round<maxRounds;++round){
            ++result.rounds;
            for(auto& r:result.sets){r.kept.clear();r.conflicts.clear();}
            for(std::size_t s=0;s<layer.sets.size();++s){const auto& set=layer.sets[s];auto& r=result.sets[s];
                r.reasons.assign(set.samples.size(),Reason::NotConsumed);r.attempts=prefixes[s];
                std::vector<std::size_t> active;
                for(std::size_t i=0;i<set.samples.size();++i){const auto& p=set.samples[i];
                    if(suppressed[s][i])r.reasons[i]=Reason::Cleanup;
                    else if(p.protectedEdit||p.ordinal<prefixes[s])active.push_back(i);
                }
                std::stable_sort(active.begin(),active.end(),[&](auto a,auto b){return set.samples[a].ordinal<set.samples[b].ordinal;});
                std::vector<amin::Vec3> positions;std::vector<double> radii;std::vector<bool> pins;
                for(auto i:active){const auto& p=set.samples[i];positions.push_back(p.position);radii.push_back(p.radius);pins.push_back(p.protectedEdit);}
                std::vector<groups::ScopedRule> external;
                // Diagnostic priority: layer, sibling, self. It never changes the
                // winner or applies a scope twice to the same pair.
                for(int pass=0;pass<2;++pass)for(std::size_t ol=0;ol<plan.layers.size();++ol){
                    if((ol==l)!=(pass==1))continue;
                    for(std::size_t os=0;os<plan.layers[ol].sets.size();++os){
                        if(ol==l&&os==s)continue;
                        const auto distance=pairRule(l,s,ol,os);if(!distance.enabled)continue;
                        const auto& other=plan.layers[ol].sets[os];
                        groups::ScopedRule rule;rule.multiplier=distance.multiplier;
                        rule.reason=ol==l?Reason::SetSpacing:Reason::LayerSpacing;
                        rule.values.gap=distance.gap;rule.values.planar=distance.planar;rule.values.ownRadii=radii;
                        const auto append=[&](std::size_t i){rule.values.blockers.push_back(other.samples[i].position);rule.values.blockerRadii.push_back(other.samples[i].radius);};
                        if(ol<l||(ol==l&&os<s))for(auto i:output.layers[ol].sets[os].kept)append(i);
                        else for(std::size_t i=0;i<other.samples.size();++i)if(other.samples[i].protectedEdit)append(i);
                        if(!rule.values.blockers.empty())external.push_back(std::move(rule));
                    }
                }
                const auto target=layer.acceptedTarget?std::size_t(set.budget):std::numeric_limits<std::size_t>::max();
                const auto resolved=groups::resolveVariable(positions,radii,set.self,external,pins,target,plan.maxNeighborVisits-visits);
                visits+=resolved.neighborVisits;
                r.neighborVisits+=resolved.neighborVisits;
                for(std::size_t i=0;i<active.size();++i)r.reasons[active[i]]=resolved.reasons[i];
                for(auto i:resolved.kept)r.kept.push_back(active[i]);
                for(auto i:resolved.conflicts)r.conflicts.push_back(active[i]);
            }
            bool removed=false;
            if(layer.cleanup.cleanup){
                std::vector<amin::Instance> unionRows;std::vector<std::pair<std::size_t,std::size_t>> owners;
                for(std::size_t s=0;s<layer.sets.size();++s)for(auto i:result.sets[s].kept){
                    amin::Instance row{};row.position=layer.sets[s].samples[i].position;row.candidateKey=owners.size();
                    unionRows.push_back(row);owners.emplace_back(s,i);
                }
                amin::FinalWorkBudget cleanupWork{plan.maxNeighborVisits-visits};
                const auto cleaned=amin::finalize({},amin::Settings{},unionRows,{},std::vector<double>(unionRows.size(),0),{},layer.cleanup,&cleanupWork);
                visits+=cleanupWork.visits;
                for(std::size_t k=0;k<cleanupWork.rowVisits.size();++k)
                    result.sets[owners[k].first].neighborVisits+=cleanupWork.rowVisits[k];
                std::vector<bool> keep(unionRows.size(),false);for(const auto& row:cleaned)keep[row.candidateKey]=true;
                for(std::size_t k=0;k<owners.size();++k){const auto [s,i]=owners[k];
                    if(!keep[k]&&!layer.sets[s].samples[i].protectedEdit){suppressed[s][i]=true;result.sets[s].reasons[i]=Reason::Cleanup;removed=true;}
                }
                for(std::size_t s=0;s<layer.sets.size();++s){auto& kept=result.sets[s].kept;
                    kept.erase(std::remove_if(kept.begin(),kept.end(),[&](auto i){return suppressed[s][i];}),kept.end());
                }
            }
            bool underfilled=false,extended=false;
            for(std::size_t s=0;s<layer.sets.size();++s){const auto& set=layer.sets[s];auto& r=result.sets[s];
                r.shortfall=layer.acceptedTarget&&r.kept.size()<set.budget?set.budget-r.kept.size():0;
                if(r.shortfall){
                    underfilled=true;
                    const auto next=std::min<std::uint64_t>(set.attemptLimit,std::max(prefixes[s]+32,prefixes[s]*2));
                    if(next>prefixes[s]){prefixes[s]=next;extended=true;}
                }
            }
            const bool more=(layer.acceptedTarget&&underfilled&&(extended||removed))||(layer.repair&&removed);
            if(!more)break;
            if(round+1==maxRounds)result.limitReached=true;
        }
    }
    return output;
}
}
