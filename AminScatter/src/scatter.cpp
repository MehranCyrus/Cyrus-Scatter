#include "scatter.h"
#include "spline_bands.h"
#include "execution.h"
#include <algorithm>
#include <cmath>
#include <limits>
#include <random>
#include <stdexcept>
#include <memory>
#include <unordered_map>
#include <unordered_set>
#include <functional>
#include <numeric>

namespace amin {
Vec3 operator+(Vec3 a, Vec3 b) { return {a.x+b.x,a.y+b.y,a.z+b.z}; }
Vec3 operator-(Vec3 a, Vec3 b) { return {a.x-b.x,a.y-b.y,a.z-b.z}; }
Vec3 operator*(Vec3 a, double s) { return {a.x*s,a.y*s,a.z*s}; }
double dot(Vec3 a, Vec3 b) { return a.x*b.x+a.y*b.y+a.z*b.z; }
double length(Vec3 a) { return std::sqrt(dot(a,a)); }
namespace {
Vec3 cross(Vec3 a, Vec3 b) { return {a.y*b.z-a.z*b.y,a.z*b.x-a.x*b.z,a.x*b.y-a.y*b.x}; }
Vec3 unit(Vec3 a) { return a*(1.0/length(a)); }
bool finite(Vec3 a) { return std::isfinite(a.x)&&std::isfinite(a.y)&&std::isfinite(a.z); }
struct Random {
    std::mt19937 rng;
    bool counterMode=false;
    std::uint64_t counter=0;
    explicit Random(std::uint32_t seed):rng(seed) {}
    static std::uint64_t mix(std::uint64_t n) {
        n=(n^(n>>30))*0xbf58476d1ce4e5b9ULL;
        n=(n^(n>>27))*0x94d049bb133111ebULL;
        return n^(n>>31);
    }
    void candidate(std::uint32_t seed,std::uint64_t ordinal,std::uint64_t channel,std::uint64_t receiver=0) {
        counterMode=true;counter=mix(ordinal)^mix((std::uint64_t(seed)<<32)^channel)^mix(receiver);
    }
    double next() {
        if(counterMode)return double(mix(counter+=0x9e3779b97f4a7c15ULL)>>11)*(1.0/9007199254740992.0);
        return static_cast<double>(rng()) / 4294967296.0;
    }
    double range(Range r) { return r.min+(r.max-r.min)*next(); }
};
void validate(Range r) {
    if (!std::isfinite(r.min)||!std::isfinite(r.max)||r.min>r.max||!std::isfinite(r.max-r.min))
        throw std::invalid_argument("Invalid randomization range");
}
struct Sampler {
    const std::vector<Triangle>& triangles;
    std::vector<double> cumulative;
    std::vector<std::uint32_t> indices;
    double total{};
    explicit Sampler(const std::vector<Triangle>& mesh):triangles(mesh) {
        if(mesh.size()>std::numeric_limits<std::uint32_t>::max()) throw std::invalid_argument("Too many triangles");
        for(std::size_t i=0;i<mesh.size();++i) {
            const auto& t=mesh[i];
            if(!finite(t.a)||!finite(t.b)||!finite(t.c)) throw std::invalid_argument("Non-finite mesh vertex");
            const double area=length(cross(t.b-t.a,t.c-t.a))*0.5;
            if(!std::isfinite(area)) throw std::invalid_argument("Mesh area overflow");
            if(area>0) { total+=area; cumulative.push_back(total); indices.push_back(static_cast<std::uint32_t>(i)); }
        }
        if(!(total>0)||!std::isfinite(total)) throw std::invalid_argument("Mesh needs non-degenerate triangles");
    }
    std::pair<Vec3,std::uint32_t> sample(Random& r) const {
        const auto it=std::upper_bound(cumulative.begin(),cumulative.end(),r.next()*total);
        const auto slot=std::min(static_cast<std::size_t>(it-cumulative.begin()),indices.size()-1);
        const auto id=indices[slot]; const auto& t=triangles[id];
        const double u=std::sqrt(r.next()), v=r.next();
        return {t.a*(1-u)+t.b*(u*(1-v))+t.c*(u*v),id};
    }
};
Vec3 closest(Vec3 p, const Triangle& t) {
    const Vec3 ab=t.b-t.a, ac=t.c-t.a, ap=p-t.a;
    const double d1=dot(ab,ap), d2=dot(ac,ap);
    if(d1<=0&&d2<=0) return t.a;
    const Vec3 bp=p-t.b; const double d3=dot(ab,bp),d4=dot(ac,bp);
    if(d3>=0&&d4<=d3) return t.b;
    const double vc=d1*d4-d3*d2;
    if(vc<=0&&d1>=0&&d3<=0) return t.a+ab*(d1/(d1-d3));
    const Vec3 cp=p-t.c; const double d5=dot(ab,cp),d6=dot(ac,cp);
    if(d6>=0&&d5<=d6) return t.c;
    const double vb=d5*d2-d1*d6;
    if(vb<=0&&d2>=0&&d6<=0) return t.a+ac*(d2/(d2-d6));
    const double va=d3*d6-d5*d4;
    if(va<=0&&(d4-d3)>=0&&(d5-d6)>=0) return t.b+(t.c-t.b)*((d4-d3)/((d4-d3)+(d5-d6)));
    return t.a+ab*(vb/(va+vb+vc))+ac*(vc/(va+vb+vc));
}
Vec3 rotate(Vec3 p, Vec3 radians) {
    const double cx=std::cos(radians.x),sx=std::sin(radians.x);
    const double cy=std::cos(radians.y),sy=std::sin(radians.y);
    const double cz=std::cos(radians.z),sz=std::sin(radians.z);
    p={p.x,cx*p.y-sx*p.z,sx*p.y+cx*p.z};
    p={cy*p.x+sy*p.z,p.y,-sy*p.x+cy*p.z};
    return {cz*p.x-sz*p.y,sz*p.x+cz*p.y,p.z};
}
std::uint32_t mix(std::uint32_t x) { x^=x>>16;x*=0x7feb352du;x^=x>>15;x*=0x846ca68bu;return x^(x>>16); }
std::uint32_t cellHash(int x,int y,int z,std::uint32_t seed) {
    return mix(static_cast<std::uint32_t>(x)*0x9e3779b9u^static_cast<std::uint32_t>(y)*0x85ebca6bu^static_cast<std::uint32_t>(z)*0xc2b2ae35u^seed);
}
double hashUnit(std::uint32_t x) {return static_cast<double>(mix(x))/4294967296.0;}
struct AreaMask {
    const Area& area;
    double x0{INFINITY}, y0{INFINITY}, x1{-INFINITY}, y1{-INFINITY};
    explicit AreaMask(const Area& a):area(a) {
        if(a.loops.empty()) throw std::invalid_argument("Empty area");
        for(const auto& loop:a.loops) {
            if(loop.size()<3) throw std::invalid_argument("Area needs a closed polygon");
            double twiceArea=0;
            for(std::size_t i=0;i<loop.size();++i) {
                auto p=loop[i],q=loop[(i+1)%loop.size()];
                if(!finite(p)) throw std::invalid_argument("Nonfinite area");
                x0=std::min(x0,p.x);x1=std::max(x1,p.x);y0=std::min(y0,p.y);y1=std::max(y1,p.y);
                twiceArea+=p.x*q.y-q.x*p.y;
            }
            if(std::abs(twiceArea)<1e-12) throw std::invalid_argument("Area has no XY footprint");
        }
    }
    bool contains(Vec3 p) const {
        if(p.x<x0||p.x>x1||p.y<y0||p.y>y1) return false;
        bool inside=false;
        for(const auto& loop:area.loops) for(std::size_t i=0,j=loop.size()-1;i<loop.size();j=i++) {
            const auto a=loop[j],b=loop[i];
            const double dx=b.x-a.x,dy=b.y-a.y;
            if(std::abs(dx*(p.y-a.y)-dy*(p.x-a.x))<=1e-10*std::max(1.0,std::hypot(dx,dy)) &&
                p.x>=std::min(a.x,b.x)&&p.x<=std::max(a.x,b.x)&&p.y>=std::min(a.y,b.y)&&p.y<=std::max(a.y,b.y)) return true;
            if((a.y>p.y)!=(b.y>p.y) && p.x<a.x+(p.y-a.y)*dx/dy) inside=!inside;
        }
        return inside;
    }
};
bool analyzerBand(Vec3 p,const AnalyzerBand& band,double tolerance=0,int kindOverride=-1) {
    const int kind=kindOverride<0?band.kind:kindOverride;
    if(kind==5) return false;
    double nearest=INFINITY; bool inside=false;std::size_t edgeIndex=0;
    for(const auto& path:band.boundary.loops) {
        if(path.empty()) continue;
        if(kind==4) {for(auto q:path) nearest=std::min(nearest,length(p-q));continue;}
        const bool closed=kind<=2;
        Vec3 normal{},x{},y{};
        if(closed) {
            for(std::size_t i=0;i<path.size();++i) normal=normal+cross(path[i]-path[0],path[(i+1)%path.size()]-path[0]);
            if(length(normal)<1e-12) {edgeIndex+=path.size();continue;}
            normal=unit(normal);
            if(std::abs(dot(p-path[0],normal))>1e-4) {edgeIndex+=path.size();continue;}
            x=unit(path[1]-path[0]);y=cross(normal,x);
        }
        for(std::size_t i=0;i+(closed?0:1)<path.size();++i) {
            auto a=path[i],b=path[(i+1)%path.size()],v=b-a;
            const double den=dot(v,v),projection=den>0?dot(p-a,v)/den:0,t=std::clamp(projection,0.0,1.0);
            if((!band.straightEnds || (den>0 && projection>=0 && projection<=1)) && (band.boundaryMask.empty() || (edgeIndex<band.boundaryMask.size() && band.boundaryMask[edgeIndex])))
                nearest=std::min(nearest,length(p-(a+v*t)));
            ++edgeIndex;
            if(closed) {
                const double ax=dot(a-p,x),ay=dot(a-p,y),bx=dot(b-p,x),by=dot(b-p,y);
                if((ay>0)!=(by>0) && 0<ax-ay*(bx-ax)/(by-ay)) inside=!inside;
            }
        }
    }
    return nearest>=std::max(0.0,band.start-tolerance) && nearest<=band.width+tolerance && (kind>2 || inside==(kind==2));
}
#include "prepared_band.inc"
double valueNoise(Vec3 p,std::uint32_t seed) {
    const int x=static_cast<int>(std::floor(p.x)),y=static_cast<int>(std::floor(p.y)),z=static_cast<int>(std::floor(p.z));
    auto smooth=[](double t){return t*t*(3-2*t);};
    const double u=smooth(p.x-x),v=smooth(p.y-y),w=smooth(p.z-z);
    double value=0;
    for(int k=0;k<2;++k) for(int j=0;j<2;++j) for(int i=0;i<2;++i)
        value+=hashUnit(cellHash(x+i,y+j,z+k,seed))*(i?u:1-u)*(j?v:1-v)*(k?w:1-w);
    return value;
}
std::size_t weightedIndex(const std::vector<double>& cumulative,double u) {
    const auto it=std::upper_bound(cumulative.begin(),cumulative.end(),u*cumulative.back());
    return std::min(static_cast<std::size_t>(it-cumulative.begin()),cumulative.size()-1);
}
#include "cluster.inc"
}
#include "spacing.inc"
#include "orientation.inc"
#include "boundary_falloff.inc"
#include "edge_border.inc"
Vec3 Instance::transformPoint(Vec3 p) const { return position+(xAxis*p.x+yAxis*p.y+zAxis*p.z)*scale; }
double stableUnit(std::uint32_t seed,std::uint64_t ordinal,std::uint64_t channel,std::uint64_t receiver){
    const auto counter=Random::mix(ordinal)^Random::mix((std::uint64_t(seed)<<32)^channel)^Random::mix(receiver);
    return double(Random::mix(counter+0x9e3779b97f4a7c15ULL)>>11)*(1.0/9007199254740992.0);
}
namespace {
std::vector<Instance> scatterImpl(const std::vector<Triangle>& surface, const Settings& s,
                                const std::vector<CandidateAnchor>* candidates) {
    detail::recordComputeStats({});
    if(s.splineField&&s.analyzerPattern)
        throw std::invalid_argument("Prepared spline fields cannot mix with Analyzer rows");
    if(s.candidateStart>std::numeric_limits<std::uint64_t>::max()-s.count)
        throw std::invalid_argument("Candidate ordinal overflow");
    if(candidates){
        if(candidates->size()!=s.count||s.candidateStart!=0||candidates->size()>1000000)
            throw std::invalid_argument("Anchored population requires its complete bounded candidate schedule");
        if(s.analyzerPattern&&std::any_of(s.analyzerBands.begin(),s.analyzerBands.end(),[](const AnalyzerBand& b){return b.kind>=5;}))
            throw std::invalid_argument("Grid/path anchors cannot mix with Analyzer single/edge-row position generators");
        std::unordered_set<std::uint64_t> keys;keys.reserve(candidates->size());
        for(const auto& a:*candidates){
            if(!finite(a.position)||!finite(a.bary)||a.face>=surface.size()||!keys.insert(a.key).second||
               std::abs(a.bary.x+a.bary.y+a.bary.z-1)>1e-10||std::min({a.bary.x,a.bary.y,a.bary.z}) < -1e-10)
                throw std::invalid_argument("Invalid or duplicate explicit candidate anchor");
            const auto& t=surface[a.face];
            const auto p=t.a+(t.b-t.a)*a.bary.y+(t.c-t.a)*a.bary.z;
            if(length(p-a.position)>1e-10*std::max({1.,length(t.a),length(t.b),length(t.c)}))
                throw std::invalid_argument("Explicit candidate is not on its receiver face");
        }
    }
    if(s.analyzerPattern&&std::any_of(s.analyzerBands.begin(),s.analyzerBands.end(),[](const AnalyzerBand& b){return b.kind==6;}))return scatterImpl(surface,prepareEdgeRows(s),nullptr);
    if(s.relaxEnabled&&(!std::isfinite(s.relaxSpacing)||s.relaxSpacing<=0||!std::isfinite(s.relaxStrength)||s.relaxStrength<0||s.relaxStrength>1||s.relaxIterations>100))
        throw std::invalid_argument("Invalid relax controls");
    validate(s.uniformScale);
    if(s.uniformScale.min<=0||s.sourceCount==0) throw std::invalid_argument("Positive scale and at least one source required");
    for(auto r:s.rotationDegrees) validate(r);
    for(auto r:s.movement) validate(r);
    for(auto r:s.axisScale) {validate(r);if(r.min<=0) throw std::invalid_argument("Positive axis scale required");}
    if(s.distribution!=0&&s.distribution!=2) throw std::invalid_argument("Unknown distribution");
    const bool clustered=!s.analyzerPattern&&s.clusterEnabled;
    if(clustered) {
        const double size=s.clusterSize;
        if(!std::isfinite(size)||size<=0) throw std::invalid_argument("Invalid cluster size");
        for(auto value:{s.clusterRoughness,s.clusterBlur,s.clusterNoise}) if(!std::isfinite(value)||value<0||value>1) throw std::invalid_argument("Invalid cluster controls");
    }
    if(s.distribution==2) {
        if(!s.densityWidth||!s.densityHeight||s.density.size()!=static_cast<std::size_t>(s.densityWidth)*s.densityHeight) throw std::invalid_argument("Invalid density image");
        for(auto value:s.density) if(!std::isfinite(value)||value<0||value>1) throw std::invalid_argument("Invalid density value");
        for(const auto& t:surface) if(!finite(t.uvA)||!finite(t.uvB)||!finite(t.uvC)) throw std::invalid_argument("Invalid UV");
    }
    std::vector<AreaMask> masks;bool hasInclude=false;
    for(const auto& area:s.areas) {masks.emplace_back(area);hasInclude|=area.include;}
    Sampler sampler(surface); Random placement(s.seed), transforms(s.seed^0x9e3779b9u), sources(s.seed^0x85ebca6bu);
    if(!s.sourceGroups.empty()&&s.sourceGroups.size()!=s.sourceCount) throw std::invalid_argument("One group per source required");
    std::vector<std::uint32_t> groupKeys;
    if(!s.sourceWeights.empty()) {
        if(s.sourceWeights.size()!=s.sourceCount) throw std::invalid_argument("One weight per source required");
        for(auto w:s.sourceWeights) if(!std::isfinite(w)||w<0||w>1) throw std::invalid_argument("Source weight must be 0..1");
    }
    std::vector<std::vector<std::uint32_t>> groupMembers;
    for(std::uint32_t source=0;source<s.sourceCount;++source) {
        const auto key=s.sourceGroups.empty()?source:s.sourceGroups[source];
        auto found=std::find(groupKeys.begin(),groupKeys.end(),key);
        if(found==groupKeys.end()) {groupKeys.push_back(key);groupMembers.push_back({source});}
        else groupMembers[static_cast<std::size_t>(found-groupKeys.begin())].push_back(source);
    }
    std::vector<double> groupCDF;
    if(!s.sourceWeights.empty()) {
        double total=0;
        for(const auto& members:groupMembers) {for(auto i:members) total+=s.sourceWeights[i];groupCDF.push_back(total);}
        if(total==0) return {};
    }
    const auto choose=[&](const std::vector<std::uint32_t>& members,double u,std::uint32_t& source) {
        if(members.empty()) return false;
        if(s.sourceWeights.empty()) {source=members[static_cast<std::size_t>(u*members.size())];return true;}
        double total=0;for(auto i:members) total+=s.sourceWeights[i];
        if(total==0) return false;
        double cursor=u*total;
        for(auto i:members) {cursor-=s.sourceWeights[i];if(cursor<0) {source=i;return true;}}
        for(auto i=members.rbegin();i!=members.rend();++i) if(s.sourceWeights[*i]>0) {source=*i;return true;}
        return false;
    };
    std::vector<std::uint32_t> allSources(s.sourceCount);std::iota(allSources.begin(),allSources.end(),0u);
    std::vector<std::vector<std::uint32_t>> bandMembers;

    if(s.analyzerPattern) {
        for(const auto& band:s.analyzerBands) {
            if(!std::isfinite(band.width)||band.width<=0) throw std::invalid_argument("Invalid line band width");
            if(!std::isfinite(band.scaleMin)||!std::isfinite(band.scaleMax)||band.scaleMin<=0||band.scaleMax<band.scaleMin) throw std::invalid_argument("Invalid stroke scale");
            const auto& members=band.sources;
            for(auto source:members) if(source>=s.sourceCount) throw std::invalid_argument("Invalid stroke source");
            if(band.kind<1||band.kind>5||!std::isfinite(band.start)||band.start<0||band.start>band.width) throw std::invalid_argument("Invalid Analyzer band");
            for(const auto& path:band.boundary.loops) for(auto p:path) if(!finite(p)) throw std::invalid_argument("Invalid Analyzer point");
            bandMembers.push_back(members);
        }
    }
    std::vector<Instance> result; result.reserve(s.count);
    const bool moved=std::any_of(s.movement.begin(),s.movement.end(),[](Range r){return r.min!=0||r.max!=0;});
    Random distribution(s.seed^0xc2b2ae35u), scales(s.seed^0x27d4eb2fu), diversity(s.clusterSeed^0xa341316cu);
    const bool population=!s.analyzerPattern||std::any_of(s.analyzerBands.begin(),s.analyzerBands.end(),[](const AnalyzerBand& b){return b.kind!=5;});
    std::vector<std::pair<Vec3,std::size_t>> anchors;
    for(std::size_t j=0;j<s.analyzerBands.size();++j) if(s.analyzerBands[j].kind==5)
        for(const auto& path:s.analyzerBands[j].boundary.loops) for(auto p:path) anchors.emplace_back(p,j);
    // Anchors occupy the beginning of the canonical candidate stream. They
    // consume its bounded quota; a larger prefix cannot change their IDs.
    const auto end=static_cast<std::uint64_t>(s.count);
    // Lazy and evaluation-owned: an unused band is never additionally prepared.
    std::vector<std::unique_ptr<PreparedAnalyzerBand>> preparedBands(s.analyzerBands.size());
    const auto inBand=[&](Vec3 p,std::size_t j) {
        const auto& band=s.analyzerBands[j];
        if(band.kind!=1 && band.kind!=2) return analyzerBand(p,band);
        if(!preparedBands[j]) preparedBands[j]=std::make_unique<PreparedAnalyzerBand>(band);
        return preparedBands[j]->contains(p);
    };
    // The common clustered population has one immutable query per sampled point.
    // Keep sampling, source RNG and every transform draw in their original order.
    // Density rejection, masks, projected movement and anchors retain the general
    // ordered pipeline below. A tested cell-cache prototype was slower in serial
    // mode; keep the original query math and use workers only for large batches.
    struct ClusterCandidate { Vec3 position; std::uint32_t triangle; ClusterField field; };
    std::vector<ClusterCandidate> clusterCandidates;
    ComputeStats computeStats;
    constexpr std::size_t parallelThreshold=4096;
    const bool batchClusters=clustered && !moved && masks.empty() && s.distribution!=2 &&
        anchors.empty() && s.count>=parallelThreshold && computeParticipants()>1;
    ClusterQueries serialClusters(s,groupMembers.size(),groupCDF);
    if(batchClusters) {
        clusterCandidates.resize(s.count);
        std::uint64_t ordinal=s.candidateStart;
        for(auto& candidate:clusterCandidates) {
            placement.candidate(s.seed,ordinal,1,s.receiverSalt);
            const auto sampled=candidates ? std::make_pair((*candidates)[ordinal].position,(*candidates)[ordinal].face) : sampler.sample(placement);
            ++ordinal;
            candidate.position=sampled.first; candidate.triangle=sampled.second;
        }
        std::array<ComputeStats,64> rangeStats{};
        const auto execution=detail::forRanges(clusterCandidates.size(),parallelThreshold,
            [&](unsigned slot,std::size_t begin,std::size_t end) {
                ClusterQueries queries(s,groupMembers.size(),groupCDF);
                for(auto i=begin;i<end;++i) clusterCandidates[i].field=queries.field(clusterCandidates[i].position);
                rangeStats[slot]={1,queries.queries,false};
            });
        computeStats.participants=execution.participants;
        computeStats.threadLaunchFallback=execution.threadLaunchFallback;
        for(unsigned slot=0;slot<execution.participants;++slot) {
            computeStats.clusterQueries+=rangeStats[slot].clusterQueries;
        }
    }
    for(std::uint64_t i=0;i<end;++i) {
        const auto ordinal=candidates ? (*candidates)[i].key : s.candidateStart+i;
        placement.candidate(s.seed,ordinal,1,s.receiverSalt);transforms.candidate(s.seed,ordinal,2,s.receiverSalt);
        sources.candidate(s.seed,ordinal,3,s.receiverSalt);scales.candidate(s.seed,ordinal,4,s.receiverSalt);
        distribution.candidate(s.seed,ordinal,5,s.receiverSalt);diversity.candidate(s.clusterSeed,ordinal,6,s.receiverSalt);
        const bool single=!candidates&&ordinal<anchors.size();
        const auto anchorIndex=static_cast<std::size_t>(ordinal);
        if(!population&&!single) break;
        auto [p,id]=batchClusters ? std::make_pair(clusterCandidates[static_cast<std::size_t>(i)].position,
                                                 clusterCandidates[static_cast<std::size_t>(i)].triangle) :
            candidates ? std::make_pair((*candidates)[i].position,(*candidates)[i].face) : sampler.sample(placement);
        if(single) {
            const auto target=anchors[anchorIndex].first;
            double best=INFINITY;
            for(auto j:sampler.indices) {const auto q=closest(target,surface[j]);const double d=length(q-target);if(d<best) {best=d;p=q;id=j;}}
            if(best>1e-4) continue; // Anchors must lie on one of the Scatter surfaces.
        }
        const auto densityAccepts=[&]() {
            if(s.distribution!=2||single)return true;
            const auto& t=surface[id];const auto ab=t.b-t.a,ac=t.c-t.a,ap=p-t.a;
            const double aa=dot(ab,ab),bb=dot(ac,ac),cc=dot(ab,ac),den=aa*bb-cc*cc;
            const double u=(bb*dot(ap,ab)-cc*dot(ap,ac))/den,v=(aa*dot(ap,ac)-cc*dot(ap,ab))/den;
            const auto uv=t.uvA*(1-u-v)+t.uvB*u+t.uvC*v;
            const double fx=std::clamp(uv.x,0.0,1.0)*(s.densityWidth-1),fy=(1-std::clamp(uv.y,0.0,1.0))*(s.densityHeight-1);
            const auto x=static_cast<std::uint32_t>(fx),y=static_cast<std::uint32_t>(fy);
            const auto x1=std::min(x+1,s.densityWidth-1),y1=std::min(y+1,s.densityHeight-1);
            const auto at=[&](std::uint32_t xx,std::uint32_t yy){return s.density[static_cast<std::size_t>(yy)*s.densityWidth+xx];};
            const double a=fx-x,b=fy-y;
            const double weight=(at(x,y)*(1-a)+at(x1,y)*a)*(1-b)+(at(x,y1)*(1-a)+at(x1,y1)*a)*b;
            return distribution.next()<weight;
        };
        const Vec3 offset{transforms.range(s.movement[0]),transforms.range(s.movement[1]),transforms.range(s.movement[2])};
        if(moved && s.projectMovement) {
            const Vec3 target=p+offset; double best=std::numeric_limits<double>::infinity();
            for(auto j:sampler.indices) { const auto q=closest(target,surface[j]); const double d=dot(q-target,q-target); if(d<best) {best=d;p=q;id=j;} }
        }
        else if(moved) p=p+offset;
        if(!densityAccepts())continue;
        bool allowed=!hasInclude,excluded=false;
        for(const auto& mask:masks) if(mask.contains(p)) {
            if(mask.area.include) allowed=true;else {excluded=true;break;}
        }
        if(!allowed||excluded) continue;
        std::uint32_t source=0; double strokeScale=1; bool emit=true;std::uint64_t bandOwner=0;
        if(s.splineField) {
            const auto chosen=s.splineField->sample(p,s.seed,ordinal,s.receiverSalt);
            emit=chosen.emitted;source=chosen.source;strokeScale=chosen.scale;bandOwner=chosen.band;
            if(emit&&source>=s.sourceCount)throw std::invalid_argument("Prepared Band source is outside the current source table");
        } else if(s.analyzerPattern) {
            const std::vector<std::uint32_t>* members=nullptr;
            for(std::size_t j=0;j<s.analyzerBands.size();++j) if(single ? j==anchors[anchorIndex].second : inBand(p,j)) {
                members=&bandMembers[j];
                // Separate RNG: stroke sizing never shifts placements or the XYZ random stream.
                Random strokeRandom(s.seed ^ static_cast<std::uint32_t>(ordinal*2654435761u) ^ 0x9e3779b9u);
                strokeScale=strokeRandom.range({s.analyzerBands[j].scaleMin,s.analyzerBands[j].scaleMax});break;
            }
            const double sourceRandom=sources.next();
            if(members) emit=choose(*members,sourceRandom,source);
            else emit=false;
        } else if(clustered) {
            const auto group=batchClusters ? diversityGroup(clusterCandidates[static_cast<std::size_t>(i)].field,s,groupMembers.size(),diversity,groupCDF) :
                serialClusters.group(p,diversity);
            const auto& members=groupMembers[group];
            emit=choose(members,sources.next(),source);
        } else emit=choose(allSources,sources.next(),source);
        const auto& t=surface[id];
        const Vec3 normal=s.alignToNormal?unit(cross(t.b-t.a,t.c-t.a)):Vec3{0,0,1};
        const Vec3 reference=std::abs(normal.z)<0.999?Vec3{0,0,1}:Vec3{0,1,0};
        const Vec3 x=unit(cross(reference,normal)),y=cross(normal,x);
        constexpr double toRadians=3.14159265358979323846/180.0;
        const Vec3 angles{transforms.range(s.rotationDegrees[0])*toRadians,transforms.range(s.rotationDegrees[1])*toRadians,transforms.range(s.rotationDegrees[2])*toRadians};
        const auto basis=[&](Vec3 axis) { const auto v=rotate(axis,angles); return x*v.x+y*v.y+normal*v.z; };
        Instance instance{p,basis({1,0,0})*scales.range(s.axisScale[0]),basis({0,1,0})*scales.range(s.axisScale[1]),basis({0,0,1})*scales.range(s.axisScale[2]),transforms.range(s.uniformScale)*strokeScale,source,id};
        instance.candidateKey=ordinal;
        instance.bandOwner=bandOwner;
        if(emit) result.push_back(instance);
    }
    if(s.relaxEnabled) {
        const auto bandAt=[&](Vec3 p) {
            for(std::size_t j=0;j<s.analyzerBands.size();++j) {
                if(s.analyzerBands[j].kind==5) {
                    for(const auto& path:s.analyzerBands[j].boundary.loops) for(auto anchor:path)
                        if(length(p-anchor)<1e-7) return static_cast<int>(j);
                } else if(inBand(p,j)) return static_cast<int>(j);
            }
            return -1;
        };
        std::vector<int> originalBands;for(const auto& p:result) originalBands.push_back(s.analyzerPattern?bandAt(p.position):-1);
        const auto allowed=[&](std::size_t i,Vec3 p,std::uint32_t tri) {
            bool included=!hasInclude;
            for(const auto& mask:masks) if(mask.contains(p)) {if(!mask.area.include) return false;included=true;}
            if(!included) return false;
            if(s.splineField){const auto chosen=s.splineField->sample(p,s.seed,result[i].candidateKey,s.receiverSalt);
                if(!chosen.emitted||chosen.band!=result[i].bandOwner||chosen.source!=result[i].source)return false;}
            if(s.analyzerPattern&&bandAt(p)!=originalBands[i]) return false;
            if(s.distribution==2) {
                const auto& t=surface[tri];const auto ab=t.b-t.a,ac=t.c-t.a,ap=p-t.a;
                const double aa=dot(ab,ab),bb=dot(ac,ac),cc=dot(ab,ac),den=aa*bb-cc*cc;
                const double u=(bb*dot(ap,ab)-cc*dot(ap,ac))/den,v=(aa*dot(ap,ac)-cc*dot(ap,ab))/den;
                const auto uv=t.uvA*(1-u-v)+t.uvB*u+t.uvC*v;
                const auto x=static_cast<std::uint32_t>(std::clamp(uv.x,0.0,1.0)*(s.densityWidth-1));
                const auto y=static_cast<std::uint32_t>((1-std::clamp(uv.y,0.0,1.0))*(s.densityHeight-1));
                if(s.density[static_cast<std::size_t>(y)*s.densityWidth+x]<=0) return false;
            }
            return true;
        };
        spacePoints(result,surface,s,allowed);
    }
    if(!batchClusters) {
        computeStats.clusterQueries=serialClusters.queries;
    }
    detail::recordComputeStats(computeStats);
    return result;
}
}
std::vector<Instance> scatter(const std::vector<Triangle>& surface,const Settings& s){return scatterImpl(surface,s,nullptr);}
std::vector<Instance> scatter(const std::vector<Triangle>& surface,const Settings& s,const std::vector<CandidateAnchor>& anchors){return scatterImpl(surface,s,&anchors);}
#include "final.inc"
std::vector<Vec3> sampleSource(const std::vector<Triangle>& mesh,std::uint32_t count,std::uint32_t seed) {
    Sampler sampler(mesh); Random random(seed); std::vector<Vec3> result; result.reserve(count);
    for(std::uint32_t i=0;i<count;++i) result.push_back(sampler.sample(random).first);
    return result;
}
std::vector<PreviewPoint> pointCloud(const std::vector<Instance>& instances,
    const std::vector<std::vector<Vec3>>& samples,std::uint32_t budget) {
    std::uint64_t total=0; std::vector<std::uint64_t> ends; ends.reserve(instances.size());
    for(const auto& instance:instances) {
        if(instance.source>=samples.size()||samples[instance.source].empty()) throw std::invalid_argument("Missing source preview geometry");
        total+=samples[instance.source].size(); ends.push_back(total);
    }
    const auto count=std::min<std::uint64_t>(total,budget);
    std::vector<PreviewPoint> result; result.reserve(static_cast<std::size_t>(count));
    for(std::uint64_t i=0;i<count;++i) {
        const std::uint64_t flat=i*(total/count)+(i*(total%count))/count;
        const auto index=static_cast<std::size_t>(std::upper_bound(ends.begin(),ends.end(),flat)-ends.begin());
        const auto& instance=instances[index]; const auto local=static_cast<std::size_t>(flat-(index?ends[index-1]:0));
        result.push_back({instance.transformPoint(samples[instance.source][local]),instance.source,instance.bandOwner});
    }
    return result;
}
}

