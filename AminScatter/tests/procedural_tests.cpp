#include "procedural.h"
#include "execution.h"
#include <algorithm>
#include <cmath>
#include <iostream>
#include <limits>
#include <random>
#include <stdexcept>
using namespace cyrus::procedural;
void check(bool yes,const char* message){if(!yes)throw std::runtime_error(message);}
template<class F> void rejects(F fn){bool rejected=false;try{fn();}catch(const std::invalid_argument&){rejected=true;}check(rejected,"Expected validation rejection");}
Sample sample(double x,double y,std::uint64_t ordinal,double radius=0,bool pin=false){return {{x,y,0},radius,ordinal,"c:"+std::to_string(ordinal),pin};}
Population population(const char* id,unsigned budget){Population p;p.id=id;p.budget=p.attemptLimit=budget;return p;}
Layer layer(const char* id){Layer l;l.id=id;return l;}
void stableSampler(){
    const std::vector<amin::Triangle> mesh={{{-10,-10,0},{10,-10,0},{10,10,0}},{{-10,-10,0},{10,10,0},{-10,10,0}}};
    amin::Settings s;s.stableCandidates=true;s.count=256;s.sourceCount=3;s.uniformScale={.5,1.5};
    const auto all=amin::scatter(mesh,s);
    s.areas.push_back({{{{-10,-10,0},{0,-10,0},{0,10,0},{-10,10,0}}},false});
    const auto masked=amin::scatter(mesh,s);check(!masked.empty()&&masked.size()<all.size(),"Mask did not filter");
    for(const auto& p:masked){const auto& a=all.at(static_cast<std::size_t>(p.candidateKey));
        check(p.source==a.source&&p.scale==a.scale&&amin::length(p.position-a.position)==0&&amin::length(p.xAxis-a.xAxis)==0,"Filtering shifted candidate attributes");
    }
    s.areas.clear();s.count=71;s.candidateStart=93;const auto part=amin::scatter(mesh,s);
    for(std::size_t i=0;i<part.size();++i){const auto& p=part[i];const auto& a=all[i+93];
        check(p.candidateKey==i+93&&p.source==a.source&&p.scale==a.scale&&amin::length(p.position-a.position)==0,"Candidate range changed prefix");
    }
    s.relaxEnabled=true;rejects([&]{amin::scatter(mesh,s);});
}
void distances(){
    using namespace cyrus::groups;
    const DistanceRule self{true,1,.1,true};
    auto r=resolveVariable({{0,0,0},{.6,0,100},{.59,0,0}},{.2,.3,.3},self,{}, {false,false,false},100);
    check(r.kept==std::vector<std::size_t>({0,1}),"Variable radius / planar equality incorrect");
    auto xyz=self;xyz.planar=false;
    r=resolveVariable({{0,0,0},{0,0,1}},{.2,.3},xyz,{}, {false,false},100);
    check(r.kept.size()==2,"XYZ collapsed height");
    r=resolveVariable({{0,0,0},{0,0,0}},{0,0},{true,0,0,false},{},{false,false},100);
    check(r.kept.size()==2,"Zero reach rejected coincident candidates");
    r=resolveVariable({{0,0,0},{0,0,0}},{0,0},{true,0,1,false},{},{true,true},0);
    check(r.kept.size()==2&&r.conflicts.size()==2,"Protected over-target conflicts were removed");
    rejects([&]{resolveVariable({{0,0,0}},{-1},self,{}, {false},10);});
    rejects([&]{resolveVariable({{0,0,0},{.1,0,0},{.2,0,0}},{0,0,0},{true,0,1,false},{},{false,false,false},10,1);});
}
void refill(){
    Plan p;auto garden=layer("garden");garden.acceptedTarget=true;garden.rounds=4;
    garden.cleanup.cleanup=true;garden.cleanup.radius=.3;garden.cleanup.minNeighbors=1;garden.cleanup.minIsland=2;
    auto flowers=population("flowers",1);flowers.samples={sample(0,0,0)};
    auto grass=population("grass",2);grass.samples={sample(.1,0,0),sample(.2,0,1)};
    garden.sets={flowers,grass};p.layers={garden};p.rules={{Scope::Sets,"flowers","grass",{true,0,1,false}}};
    auto result=evaluate(p);
    check(result.layers[0].sets[0].kept.empty()&&result.layers[0].sets[1].kept.size()==2,"Released cleanup space was not retried");
    check(result.layers[0].sets[0].shortfall==1&&result.layers[0].rounds==2,"Repair was not bounded/explained");
    p.layers[0].sets[1].samples.push_back(sample(.3,0,500));
    check(evaluate(p).layers[0].sets[1].kept==result.layers[0].sets[1].kept,"Warm suffix changed logical replay");
    p.layers[0].rounds=1;result=evaluate(p);
    check(result.layers[0].sets[1].kept.empty()&&result.layers[0].limitReached,"Round-limit result incorrect");
    p.rules.push_back(p.rules[0]);rejects([&]{evaluate(p);});
}
void targetAndOrdering(){
    Plan p;auto l=layer("garden");l.acceptedTarget=true;l.rounds=4;
    auto a=population("flowers",2);a.attemptLimit=64;
    // Only these ordinals survived the author's coverage, including one much
    // later sample which must not get consumed before its canonical prefix.
    a.samples={sample(0,0,4),sample(10,0,20),sample(20,0,60)};
    l.sets={a};p.layers={l};auto r=evaluate(p);
    check(r.layers[0].sets[0].kept==std::vector<std::size_t>({0,1}),"Target did not replenish surviving candidate prefix");
    check(r.layers[0].rounds==2&&r.layers[0].sets[0].attempts==34,"Refill schedule depends on available cache rows");
    p.layers[0].sets[0].attemptLimit=10;r=evaluate(p);
    check(r.layers[0].sets[0].kept.size()==1&&r.layers[0].sets[0].shortfall==1,"Attempt exhaustion hidden");
    auto b=population("grass",1);b.samples={sample(0,0,0)};
    p.layers[0].sets[0]=population("flowers",1);p.layers[0].sets[0].samples={sample(0,0,0)};
    p.layers[0].sets.push_back(b);p.layers[0].siblings={true,0,1,false};r=evaluate(p);
    check(r.layers[0].sets[0].kept.size()==1&&r.layers[0].sets[1].kept.empty(),"Earlier sibling did not win");
    std::swap(p.layers[0].sets[0],p.layers[0].sets[1]);r=evaluate(p);
    check(r.layers[0].sets[0].kept.size()==1&&r.layers[0].sets[1].kept.empty(),"Reordered sibling did not win");
    // A protected clone remains despite zero ordinary quota. Its provenance is
    // shared but its immutable output ID/radius are distinct.
    p.layers[0].sets[1].budget=p.layers[0].sets[1].attemptLimit=0;
    auto pin=sample(0,0,0,1,true);pin.id="clone:independent";
    p.layers[0].sets[1].samples={pin};r=evaluate(p);
    check(r.layers[0].sets[0].kept.empty()&&r.layers[0].sets[1].kept.size()==1,"Protected zero-quota reservation was lost");
    p.rules={{Scope::Sets,"flowers","grass",{false,1,1,false}}};r=evaluate(p);
    check(r.layers[0].sets[0].kept.size()==1,"Explicit disabled pair failed to override default");
    p.layers[0].sets[0].samples.push_back(p.layers[0].sets[0].samples[0]);rejects([&]{evaluate(p);});
}
void scaleBounds(){
    const std::array<amin::Vec3,3> orthogonal={amin::Vec3{-2,0,0},{0,3,0},{0,0,.1}};
    check(transformScaleBound(orthogonal)==3,"Negative/nonuniform scale bound is not tight");
    const std::array<amin::Vec3,3> shear={amin::Vec3{1,2,0},{0,1,0},{0,0,1}};
    const double bound=transformScaleBound(shear);std::mt19937 rng(38);
    for(unsigned i=0;i<2000;++i){amin::Vec3 v{double(int(rng()%200)-100),double(int(rng()%200)-100),double(int(rng()%200)-100)};
        if(amin::length(v)==0)continue;v=v*(1/amin::length(v));
        check(amin::length(shear[0]*v.x+shear[1]*v.y+shear[2]*v.z)<=bound+1e-12,"Sheared footprint underestimated");
    }
    auto bad=shear;bad[0].x=std::numeric_limits<double>::quiet_NaN();rejects([&]{transformScaleBound(bad);});
}
void cleanupWorkLimit(){
    Plan p;auto l=layer("dense");l.cleanup.cleanup=true;l.cleanup.radius=1;
    l.cleanup.minNeighbors=1;l.cleanup.minIsland=2;
    auto a=population("A",2);a.samples={sample(0,0,0),sample(0,0,1)};l.sets={a};p.layers={l};
    p.maxNeighborVisits=3;rejects([&]{evaluate(p);});
    p.maxNeighborVisits=4;const auto r=evaluate(p);
    check(r.layers[0].sets[0].kept.size()==2&&r.layers[0].sets[0].neighborVisits==4,"Cleanup work was not reported");
    // A second layer cannot reset the controller-wide allowance.
    l.id="second";l.sets[0].id="B";p.layers.push_back(l);p.maxNeighborVisits=7;
    rejects([&]{evaluate(p);});p.maxNeighborVisits=8;
    check(evaluate(p).layers[1].sets[0].neighborVisits==4,"Cleanup budget changed accepted rows");
    // Pathological density is bounded even with self collision disabled.
    p.layers.resize(1);auto& dense=p.layers[0].sets[0];dense.samples.clear();dense.budget=dense.attemptLimit=16000;
    for(unsigned i=0;i<16000;++i)dense.samples.push_back(sample(0,0,i));
    p.maxNeighborVisits=100;rejects([&]{evaluate(p);});
}
void stableFalloff(){
    std::vector<amin::Instance> full,filtered;
    for(unsigned i=0;i<1000;++i){amin::Instance row{};row.candidateKey=i;row.position={5,5,0};full.push_back(row);if(i%3)filtered.push_back(row);}
    amin::BoundaryFalloff f;f.density=true;f.densityCurve={.4,.4};f.stableCandidates=true;
    const std::vector<std::vector<amin::Vec3>> paths={{{0,0,0},{10,0,0},{10,10,0},{0,10,0}}};
    const auto a=amin::boundaryFalloff(full,paths,f,42),b=amin::boundaryFalloff(filtered,paths,f,42);
    std::vector<std::uint64_t> expected,actual;
    for(const auto& r:a)if(r.candidateKey%3)expected.push_back(r.candidateKey);
    for(const auto& r:b)actual.push_back(r.candidateKey);
    check(expected==actual&&!actual.empty(),"Upstream rejection changed stable falloff acceptance");
    for(const auto& row:filtered)check(amin::stableUnit(42,row.candidateKey,8)==amin::stableUnit(42,full[row.candidateKey].candidateKey,8),"Whole Scale random key changed");
}
void stableThreadsAndDensity(){
    const std::vector<amin::Triangle> mesh={
        {{0,0,0},{100,0,0},{0,100,0},{0,0,0},{1,0,0},{0,1,0}},
        {{100,0,0},{100,100,0},{0,100,0},{1,0,0},{1,1,0},{0,1,0}}};
    amin::Settings s;s.stableCandidates=true;s.count=5000;s.sourceCount=3;s.clusterEnabled=true;
    s.sourceGroups={1,2,3};s.clusterSize=15;s.clusterNoise=.2;
    amin::setComputeThreads(1);const auto serial=amin::scatter(mesh,s);
    for(unsigned workers:{2u,4u}){amin::setComputeThreads(workers);const auto parallel=amin::scatter(mesh,s);
        check(serial.size()==parallel.size(),"Stable parallel sampler changed count");
        for(std::size_t i=0;i<serial.size();++i)check(serial[i].candidateKey==parallel[i].candidateKey&&serial[i].source==parallel[i].source&&amin::length(serial[i].position-parallel[i].position)==0,"Stable parallel sampler changed placement");
    }
    amin::setComputeThreads(0);
    s.clusterEnabled=false;s.distribution=2;s.densityWidth=s.densityHeight=2;s.density={0,1,0,1};
    s.movement={{{1000,1000},{0,0},{0,0}}};s.projectMovement=true;
    const auto shifted=amin::scatter(mesh,s);
    check(shifted.size()==s.count,"Density was sampled before the resolved support anchor");
    s.candidateStart=std::numeric_limits<std::uint64_t>::max();rejects([&]{amin::scatter(mesh,s);});
}
void exhaustive(){
    std::mt19937 rng(4407);
    for(unsigned trial=0;trial<240;++trial){
        Plan p;
        for(unsigned l=0;l<2;++l){auto group=layer(l?"B":"A");group.siblings={true,.5,.1,trial%2==0};
            for(unsigned s=0;s<2;++s){auto set=population((std::string(l?"B":"A")+std::to_string(s)).c_str(),18);
                set.self={true,1,.05,trial%3==0};
                for(unsigned i=0;i<18;++i){auto row=sample(double(rng()%50)/10,double(rng()%50)/10,i,double(rng()%9)/10,i%13==0);row.position.z=double(rng()%20)/10;set.samples.push_back(row);}
                group.sets.push_back(set);
            }
            p.layers.push_back(group);
        }
        const DistanceRule cross{true,trial%4==0?0.0:1.3,.15,trial%2!=0};p.rules={{Scope::Layers,"A","B",cross}};
        const auto actual=evaluate(p);
        std::vector<std::pair<std::pair<unsigned,unsigned>,unsigned>> kept;
        const auto collides=[&](const Sample& a,const Sample& b,const DistanceRule& d){
            const auto v=a.position-b.position;const double reach=d.multiplier*(a.radius+b.radius)+d.gap;
            return d.enabled&&(v.x*v.x+v.y*v.y+(d.planar?0:v.z*v.z))<reach*reach;
        };
        for(unsigned l=0;l<2;++l)for(unsigned s=0;s<2;++s){const auto& set=p.layers[l].sets[s];std::vector<std::size_t> expected;
            for(unsigned i=0;i<18;++i){const auto& candidate=set.samples[i];bool hit=false;
                if(!candidate.protectedEdit){
                    for(unsigned ol=0;ol<2;++ol)for(unsigned os=0;os<2;++os){const auto& other=p.layers[ol].sets[os];
                        const auto d=ol!=l?cross:os!=s?p.layers[l].siblings:set.self;
                        for(unsigned j=0;j<18;++j){if(ol==l&&os==s&&i==j)continue;
                            const bool accepted=std::find(kept.begin(),kept.end(),std::make_pair(std::make_pair(ol,os),j))!=kept.end();
                            if((other.samples[j].protectedEdit||accepted)&&collides(candidate,other.samples[j],d))hit=true;
                        }
                    }
                }
                if(!hit){expected.push_back(i);kept.push_back({{l,s},i});}
            }
            check(actual.layers[l].sets[s].kept==expected,"Accelerated three-scope solve disagrees with exhaustive oracle");
        }
    }
}
int main(){try{stableSampler();distances();refill();targetAndOrdering();scaleBounds();cleanupWorkLimit();stableFalloff();stableThreadsAndDensity();exhaustive();std::cout<<"Procedural v1: stable/parallel sampler and falloff, anchor density, scopes, radius bounds, protected edits, bounded cleanup/replay and 240 exhaustive comparisons passed\n";return 0;}catch(const std::exception& e){std::cerr<<e.what()<<'\n';return 1;}}
