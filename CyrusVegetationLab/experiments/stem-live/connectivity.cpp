#include "connectivity.hpp"
#include "preparation_spatial.hpp"
#include <unordered_map>
#include <algorithm>
#include <cmath>
#include <queue>
#include <tuple>
#include <limits>
namespace prep {
namespace {
Point sub(Point a,Point b){return {a[0]-b[0],a[1]-b[1],a[2]-b[2]};}
double dot(Point a,Point b){return a[0]*b[0]+a[1]*b[1]+a[2]*b[2];}
double length(Point a){return std::sqrt(dot(a,a));}
void check(const std::atomic_bool& cancel){if(cancel.load())throw std::runtime_error("Analysis cancelled; previous preparation retained.");}
struct Candidate {unsigned parent,child,span,end;double u,gap,radius,score;};
bool less(const Candidate& a,const Candidate& b){return std::tie(a.score,a.gap,a.parent,a.span,a.u,a.end)<std::tie(b.score,b.gap,b.parent,b.span,b.u,b.end);}
}
Forest connect(const std::vector<Tube>& tubes,const std::atomic_bool& cancel,Limits limits,double connectionReach,double basalFraction,double groundOverride,double bandOverride){
    check(cancel);if(tubes.empty()||tubes.size()>limits.guides||limits.guides>32768)throw std::runtime_error("Connectivity guide limit exceeded; review Preparation limits.");
    Forest out;out.links.resize(tubes.size());std::vector<std::vector<double>> arcs(tubes.size());double maxRadius=0,zmax=-1e100;
    for(unsigned i=0;i<tubes.size();++i){const auto& t=tubes[i];if(t.nodes.size()<3||t.nodes.size()>16||t.radii.size()!=t.nodes.size())throw std::runtime_error("Connectivity tube admission.");auto& arc=arcs[i];arc.resize(t.nodes.size());for(unsigned s=0;s<t.nodes.size();++s){for(double x:t.nodes[s])if(!std::isfinite(x)||std::abs(x)>10000)throw std::runtime_error("Connectivity coordinates.");if(!std::isfinite(t.radii[s])||t.radii[s]<=0||t.radii[s]>.03)throw std::runtime_error("Connectivity radius.");maxRadius=std::max(maxRadius,t.radii[s]);zmax=std::max(zmax,t.nodes[s][2]);if(s){double d=length(sub(t.nodes[s],t.nodes[s-1]));if(d<1e-7)throw std::runtime_error("Collapsed connectivity span.");arc[s]=arc[s-1]+d;}}}
    const bool hybrid=std::any_of(tubes.begin(),tubes.end(),[](const Tube& t){return t.basalBlade;});
    out.ground=1e100;for(const auto& t:tubes){double r=*std::max_element(t.radii.begin(),t.radii.end());if(t.basalBlade||r>=maxRadius*.5)out.ground=std::min(out.ground,std::min(t.nodes.front()[2],t.nodes.back()[2]));}
    out.basalBand=hybrid?std::clamp((zmax-out.ground)*.03,.003,.03):std::clamp((zmax-out.ground)*basalFraction,.001,basalFraction>.01?.03:.01);
    if(std::isfinite(groundOverride))out.ground=groundOverride;
    if(std::isfinite(bandOverride))out.basalBand=bandOverride;
    std::vector<std::vector<Candidate>> incoming(tubes.size()),outgoing(tubes.size());
    spatial::Work work{0,std::uint64_t(limits.workMillions)*1000000,cancel};std::vector<spatial::Segment> spans;
    for(unsigned gi=0;gi<tubes.size();++gi)if(!tubes[gi].basalBlade&&tubes[gi].canParent)for(unsigned si=0;si+1<tubes[gi].nodes.size();++si)spans.push_back({tubes[gi].nodes[si],tubes[gi].nodes[si+1],gi,si});
    spatial::Index index(std::move(spans),work);
    // Query every geometrically eligible span; retain <=8 ranked contacts/end.
    // The index reduces work without changing the deterministic candidate ranking.
    for(unsigned child=0;child<tubes.size();++child){check(cancel);const auto& c=tubes[child];if(c.basalBlade)continue;for(unsigned end=0;end<2;++end){unsigned e=end?unsigned(c.nodes.size()-1):0,other=end?0:unsigned(c.nodes.size()-1);double radius=c.radii[e];// Flower pedicels may flare at the distal end. Both ends must be
        // considered for a geometric parent; basal orientation remains guarded.
        (void)other;std::vector<Candidate> candidates;candidates.reserve(tubes.size());
        std::unordered_map<unsigned,Candidate> best;double reach=connectionReach;
        index.query(c.nodes[e],reach,[&](const spatial::Segment& s,double u,double gap){unsigned parent=s.guide,span=s.span;if(parent==child)return;const auto& p=tubes[parent];double pr=p.radii[span]*(1-u)+p.radii[span+1]*u;
            const double limit=std::isfinite(groundOverride)?connectionReach:std::min(connectionReach,std::max(.003,6*(pr+radius)));if(gap>limit||pr<radius*.65)return;
            Candidate candidate{parent,child,span,end,u,gap,pr,gap/(pr+radius+.001)};auto found=best.find(parent);if(found==best.end()||less(candidate,found->second))best[parent]=candidate;});
        for(const auto& [id,candidate]:best)candidates.push_back(candidate);
        std::sort(candidates.begin(),candidates.end(),less);if(candidates.size()>8)candidates.resize(8);for(auto candidate:candidates){incoming[child].push_back(candidate);outgoing[candidate.parent].push_back(candidate);++out.candidates;}
    }}
    using Item=std::tuple<double,unsigned>;std::priority_queue<Item,std::vector<Item>,std::greater<Item>> queue;
    std::vector<double> costs(tubes.size(),std::numeric_limits<double>::infinity());std::vector<bool> visited(tubes.size());
    for(unsigned i=0;i<tubes.size();++i){const auto& t=tubes[i];unsigned end=!t.orientedRoot&&t.nodes.back()[2]<t.nodes.front()[2]?1:0,e=end?unsigned(t.nodes.size()-1):0,other=end?0:unsigned(t.nodes.size()-1);
        if(!t.orientedRoot&&(t.nodes[e][2]>out.ground+out.basalBand||t.radii[e]<t.radii[other]*.85))continue;
        // A low branch with a thicker geometric parent remains a branch. Independent
        // basal shoots do not get joined across open space merely to force one root.
        bool thicker=false;for(const auto& c:incoming[i])if(c.radius>t.radii[e]*1.2){thicker=true;break;}if(thicker&&!t.basalBlade&&!std::isfinite(groundOverride))continue;
        out.links[i]={-1,0,0,0,end!=0,true,true};costs[i]=0;queue.emplace(0,i);++out.roots;
    }
    while(!queue.empty()){check(cancel);auto [cost,parent]=queue.top();queue.pop();if(visited[parent]||cost!=costs[parent])continue;visited[parent]=true;out.order.push_back(parent);
        for(const auto& edge:outgoing[parent]){if(visited[edge.child])continue;double along=arcs[parent][edge.span]+edge.u*(arcs[parent][edge.span+1]-arcs[parent][edge.span]);if(out.links[parent].reversed)along=arcs[parent].back()-along;double next=cost+along+edge.gap*8+1e-6;
            if(next<costs[edge.child]){costs[edge.child]=next;out.links[edge.child]={int(parent),edge.span,edge.u,edge.gap,edge.end!=0,false,true};queue.emplace(next,edge.child);}
        }
    }
    for(unsigned i=0;i<tubes.size();++i){if(!visited[i]){out.links[i].resolved=false;++out.unresolved;out.order.push_back(i);}else{auto& link=out.links[i];if(link.parent>=0&&out.links[link.parent].reversed){link.parentSpan=unsigned(tubes[link.parent].nodes.size()-2)-link.parentSpan;link.parentU=1-link.parentU;}}}
    return out;
}
}
