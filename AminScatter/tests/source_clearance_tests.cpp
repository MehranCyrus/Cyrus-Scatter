#include "procedural.h"
#include <algorithm>
#include <chrono>
#include <iostream>
#include <random>
#include <stdexcept>
using namespace cyrus::procedural;
void check(bool value,const char* message){if(!value)throw std::runtime_error(message);}
template<class F>void rejects(F f){bool caught=false;try{f();}catch(const std::invalid_argument&){caught=true;}check(caught,"Expected rejection");}
Sample row(double x,unsigned ordinal,unsigned source=0,double radius=1,bool pin=false){
    Sample r;r.position={x,0,0};r.radii={radius,radius};r.ordinal=ordinal;r.id="row"+std::to_string(ordinal);r.source=source;r.protectedEdit=pin;return r;
}
Layer layer(std::string id,std::vector<Sample> rows,unsigned sourceCount=2){
    Layer l;l.id=id;Population p;p.id=id+"-population";p.samples=std::move(rows);p.budget=unsigned(p.samples.size());p.attemptLimit=p.budget;
    for(unsigned i=0;i<sourceCount;++i){SourcePolicy s;s.id=id+"-source"+std::to_string(i);p.sources.push_back(s);}
    l.sets.push_back(p);return l;
}
void scopesAndPriority(){
    Plan p;p.layers={layer("A",{row(0,0),row(0,1,1),row(5,2,1)})};
    auto& s=p.layers[0].sets[0];s.sources[1].others=2;s.sources[1].preferred=true;
    auto r=evaluate(p);check(r.layers[0].sets[0].kept==std::vector<std::size_t>({1,2}),"Preferred source must win an actual conflict");
    s.sources[1].others=1;s.self={true,1,0,false};
    r=evaluate(p);check(r.layers[0].sets[0].kept.size()==3,"Explicit other-model Off overrides layer default for that pair");
    s.sources[0].others=2;
    r=evaluate(p);check(r.layers[0].sets[0].kept==std::vector<std::size_t>({1,2}),"Off is not a veto over the other source's On");
    s.sources[0].others=0;s.sources[1].others=0;
    s.samples[0].protectedEdit=true;
    r=evaluate(p);check(r.layers[0].sets[0].kept==std::vector<std::size_t>({0,2}),"Protected edit precedes preferred source");
    s.samples[1].protectedEdit=true;r=evaluate(p);
    check(r.layers[0].sets[0].kept.size()==3&&r.layers[0].sets[0].conflicts.size()==2,"Both protected conflicts must survive");
}
void countAdmission(){
    Plan p;p.layers={layer("A",{row(0,0),row(10,1),row(20,2,1)})};
    auto& l=p.layers[0];auto& s=l.sets[0];l.acceptedTarget=true;l.rounds=3;s.budget=2;s.attemptLimit=3;s.self={true,1,0,false};s.sources[1].preferred=true;
    check(evaluate(p).layers[0].sets[0].kept==std::vector<std::size_t>({0,1}),"Distant preferred candidate stole a Count slot");
    s.samples[1].position={0,0,0};
    check(evaluate(p).layers[0].sets[0].kept==std::vector<std::size_t>({0,2}),"Conflict shortfall did not admit a refill candidate");
}
void inheritanceAndEquivalence(){
    Plan p;p.layers={layer("A",{row(0,0),row(.1,1),row(10,2)}),layer("B",{row(0,0),row(10,1)})};
    p.layers[0].sets[0].self={true,1,0,true};
    p.layers[0].cleanup.cleanup=true;p.layers[0].cleanup.radius=1;p.layers[0].cleanup.minNeighbors=1;p.layers[0].cleanup.minIsland=0;
    p.rules={{Scope::Layers,"A","B",{true,1,0,true}}};
    const auto baseline=evaluate(p);
    auto& policy=p.layers[0].sets[0].sources[0];policy.copies=2;policy.others=2;policy.distance={true,1,0,true};
    check(clearanceComponents(p)==std::vector<int>({-1,-1}),"Equivalent explicit settings selected a new schedule");
    const auto equivalent=evaluate(p);
    for(unsigned l=0;l<2;++l){const auto& a=baseline.layers[l].sets[0];const auto& b=equivalent.layers[l].sets[0];
        check(a.kept==b.kept&&a.reasons==b.reasons&&a.neighborVisits==b.neighborVisits,"Equivalent Defaults/Custom changed cleanup result or work");
    }
    p.layers[0].cleanup.cleanup=false;policy.copies=1;policy.others=1;
    check(evaluate(p).layers[1].sets[0].kept.empty(),"Local custom edit disabled inherited external spacing");
}
void crossLayerAndCleanup(){
    Plan p;p.layers={layer("A",{row(0,0)}),layer("B",{row(0,0)})};
    auto& preferred=p.layers[1].sets[0].sources[0];preferred.external=2;preferred.targets={"A"};preferred.preferred=true;
    auto r=evaluate(p);check(r.layers[0].sets[0].kept.empty()&&r.layers[1].sets[0].kept.size()==1,"Later preferred model did not win");
    preferred.targets={"missing"};r=evaluate(p);check(r.layers[0].sets[0].kept.size()==1&&r.layers[1].sets[0].kept.size()==1,"Missing layer target name-bound or blocked");
    preferred.targets={"A"};auto& cleanup=p.layers[1].cleanup;cleanup.cleanup=true;cleanup.radius=1;cleanup.minNeighbors=1;cleanup.minIsland=0;
    p.layers[0].repair=true;p.layers[0].rounds=3;
    r=evaluate(p);check(r.layers[0].sets[0].kept.size()==1&&r.layers[1].sets[0].kept.empty(),"Removed preferred blocker left a ghost reservation");
    p.layers[0].sets[0].sources[0].external=3;
    r=evaluate(p);check(r.layers[0].sets[0].kept.size()==1,"Reciprocal targets must terminate");
}
void limits(){
    Plan p;p.layers={layer("A",{row(0,0),row(0,1,1)})};auto& s=p.layers[0].sets[0];
    s.sources[0].others=2;s.sources[0].targets={"A"};rejects([&]{evaluate(p);});
    s.sources[0].targets.clear();s.samples[0].source=7;rejects([&]{evaluate(p);});s.samples[0].source=0;
    s.sources[0].distance.multiplier=-1;rejects([&]{evaluate(p);});s.sources[0].distance.multiplier=1;
    s.sources[1].id=s.sources[0].id;rejects([&]{evaluate(p);});
}
void displacedBlockerAndDormantSource(){
    for(unsigned rounds:{2u,16u})for(bool accepted:{false,true}){
        Plan p;p.layers={layer("A",{row(0,0),row(1.5,1)}),
            layer("P",{row(100,0),row(-1.5,1)}),layer("PIN",{row(100,0,0,1,true)})};
        for(auto& l:p.layers)l.sets[0].self={true,1,0,false};
        p.layers[0].acceptedTarget=accepted; // No retry allowance in this dependent layer.
        auto& pref=p.layers[1];pref.acceptedTarget=true;pref.rounds=rounds;
        pref.sets[0].budget=1;pref.sets[0].attemptLimit=2;
        pref.sets[0].sources[0].preferred=true;pref.sets[0].sources[0].external=3;
        const auto result=evaluate(p);const auto& a=result.layers[0].sets[0];
        check(a.kept==std::vector<std::size_t>{1},"Displaced previous-round blocker left a valid candidate rejected");
        check(a.reasons[1]==Reason::Accepted,"Released candidate retained a stale spacing reason");
        check(result.layers[1].sets[0].kept==std::vector<std::size_t>{1},"Refill preference lost its admitted slot");
        check(result.layers[2].sets[0].kept==std::vector<std::size_t>{0},"Protected blocker was displaced");
        check(evaluate(p).layers[0].sets[0].kept==a.kept,"Stateful replay is not deterministic");
    }
    Plan p;p.layers={layer("A",{row(0,0)}),layer("B",{row(0,0)})};
    p.rules={{Scope::Layers,"A","B",{true,1,0,false}}};
    auto& first=p.layers[0];first.cleanup.cleanup=true;first.cleanup.radius=1;
    first.cleanup.minNeighbors=1;first.cleanup.minIsland=0;
    const auto baseline=evaluate(p);
    first.sets[0].sources[1].preferred=true;
    const auto dormant=evaluate(p);
    for(unsigned l=0;l<2;++l){
        check(baseline.layers[l].sets[0].kept==dormant.layers[l].sets[0].kept,"Unused preference changed another layer");
        check(baseline.layers[l].sets[0].reasons==dormant.layers[l].sets[0].reasons,"Unused preference changed reasons");
    }
    // A cached suffix outside all authorized work is also dormant.
    first.sets[0].samples.push_back(row(50,999,1));
    check(clearanceComponents(p)==std::vector<int>({-1,-1}),"Unauthorized suffix changed scheduling");
    // Protected edits participate regardless of their candidate ordinal.
    first.sets[0].samples.back().protectedEdit=true;
    check(clearanceComponents(p)[0]>=0,"Protected-only source was omitted from compilation");
    first.sets[0].samples.back().protectedEdit=false;
    first.sets[0].samples.back().ordinal=1;first.acceptedTarget=true;first.rounds=2;first.sets[0].attemptLimit=2;
    check(clearanceComponents(p)[0]>=0,"Eligible refill source was omitted from compilation");
    Plan released;released.layers={layer("blocker",{row(0,0)}),layer("dependent",{row(1.5,0),row(10,1)}),
        layer("refill",{row(100,0),row(-1.5,1)}),layer("pin",{row(100,0,0,1,true)})};
    released.layers[0].sets[0].sources[0].external=3;
    released.layers[1].acceptedTarget=true;
    auto& refill=released.layers[2];refill.acceptedTarget=true;refill.rounds=2;refill.sets[0].budget=1;
    refill.sets[0].sources[0].preferred=true;refill.sets[0].sources[0].external=3;
    const auto settled=evaluate(released);
    check(settled.layers[1].sets[0].kept.size()==2&&!settled.layers[1].limitReached,
        "Satisfied dependent layer retained an obsolete retry-limit warning");
}
void dormantValuesAndBoundedWork(){
    for(bool populated:{false,true})for(unsigned sourceCount:{1u,32u,128u,512u}){
        Plan metadata;
        for(unsigned l=0;l<10;++l){
            std::vector<Sample> candidates;
            if(populated)for(unsigned s=0;s<sourceCount;++s)candidates.push_back(row(s*4.,s,s));
            auto owner=layer(std::to_string(l),std::move(candidates),sourceCount);
            owner.sets[0].self={true,1,0,false};metadata.layers.push_back(std::move(owner));
        }
        const auto start=std::chrono::steady_clock::now();
        const auto compiled=compileClearance(metadata);
        check(clearanceComponents(*compiled)==std::vector<int>(10,-1),"Equivalent source cohorts changed schedule");
        std::cout<<"compile 10 layers, sources="<<sourceCount<<", populated="<<populated<<": "
            <<std::chrono::duration<double,std::milli>(std::chrono::steady_clock::now()-start).count()<<" ms\n";
    }
    Plan p;p.layers={layer("A",{row(0,0),row(.5,1,1),row(10,2)})};
    auto& s=p.layers[0].sets[0];s.sources[0].others=2;
    const auto baseline=evaluate(p);
    s.sources[1].distance={true,1e200,1e200,true}; // Inherited, therefore dormant.
    const auto dormant=evaluate(p);
    check(baseline.layers[0].sets[0].kept==dormant.layers[0].sets[0].kept&&
          baseline.layers[0].sets[0].neighborVisits==dormant.layers[0].sets[0].neighborVisits,
          "Dormant source distances changed grid admission or work");
    p.maxNeighborVisits=0;rejects([&]{evaluate(p);});
    p.maxNeighborVisits=50000000;p.maxSamples=2;rejects([&]{evaluate(p);});
    // A substantial sparse component exercises both grids without quadratic
    // placement storage. Timing is recorded, not a machine-specific pass gate.
    std::vector<Sample> rows;rows.reserve(100000);
    for(unsigned i=0;i<100000;++i){auto r=row((i%1000)*4.,i,i%2);r.position.y=(i/1000)*4.;rows.push_back(r);}
    p=Plan{};p.layers={layer("large",std::move(rows))};
    p.layers[0].sets[0].sources[0].others=2;
    const auto start=std::chrono::steady_clock::now();const auto result=evaluate(p);
    check(result.layers[0].sets[0].kept.size()==100000,"Sparse large solve lost noninteracting candidates");
    check(result.layers[0].sets[0].neighborVisits<2000000,"Sparse large solve exceeded linear-scale work allowance");
    std::cout<<"100000 rows: "<<std::chrono::duration<double,std::milli>(std::chrono::steady_clock::now()-start).count()
             <<" ms, "<<result.layers[0].sets[0].neighborVisits<<" neighbor visits\n";
}
void independentOracle(){
    std::mt19937 rng(8668001);
    for(unsigned trial=0;trial<240;++trial){
        Plan p;
        for(unsigned l=0;l<3;++l){
            std::vector<Sample> samples;
            for(unsigned i=0;i<24;++i){auto r=row(double(rng()%100)/10,i,rng()%3,double(rng()%12)/10,i%19==0);r.position.y=double(rng()%60)/10;r.position.z=double(rng()%30)/10;r.radii.spatial+=double(rng()%10)/10;samples.push_back(r);}
            auto a=layer(std::to_string(l),samples,3);
            for(auto& s:a.sets[0].sources){s.copies=unsigned(rng()%3);s.others=unsigned(rng()%3);s.external=unsigned(rng()%4);s.distance={true,double(rng()%4)/2,double(rng()%5)/10,rng()%2==0};s.preferred=rng()%2==0;for(unsigned other=0;other<3;++other)if(other!=l)s.targets.push_back(std::to_string(other));}
            a.sets[0].self={true,.5,.1,trial%2==0};p.layers.push_back(a);
        }
        p.rules={{Scope::Layers,"0","1",{true,.7,.2,false}}};
        const auto actual=evaluate(p);
        struct R{unsigned l,i;};std::vector<R> candidates,kept;
        for(unsigned l=0;l<3;++l)for(unsigned i=0;i<24;++i){candidates.push_back({l,i});if(p.layers[l].sets[0].samples[i].protectedEdit)kept.push_back({l,i});}
        const auto preferred=[&](R r){const auto& pop=p.layers[r.l].sets[0];return pop.sources[pop.samples[r.i].source].preferred;};
        std::stable_sort(candidates.begin(),candidates.end(),[&](R a,R b){return preferred(a)>preferred(b);});
        for(auto a:candidates){
            const auto& pop=p.layers[a.l].sets[0];const auto& x=pop.samples[a.i];if(x.protectedEdit)continue;
            const auto& sx=pop.sources[x.source];bool collision=false;
            for(auto b:kept){const auto& other=p.layers[b.l].sets[0];const auto& y=other.samples[b.i];const auto& sy=other.sources[y.source];
                const bool local=a.l==b.l,same=local&&x.source==y.source;
                const auto xm=local?(same?sx.copies:sx.others):sx.external,ym=local?(same?sy.copies:sy.others):sy.external;
                std::vector<DistanceRule> constraints;
                if(xm==0&&ym==0){if(local)constraints.push_back(pop.self);else if((a.l==0&&b.l==1)||(a.l==1&&b.l==0))constraints.push_back({true,.7,.2,false});}
                else{
                    if(local?xm==2:xm==3||(xm==2&&std::find(sx.targets.begin(),sx.targets.end(),p.layers[b.l].id)!=sx.targets.end()))constraints.push_back(sx.distance);
                    if(!same&&(local?ym==2:ym==3||(ym==2&&std::find(sy.targets.begin(),sy.targets.end(),p.layers[a.l].id)!=sy.targets.end())))constraints.push_back(sy.distance);
                }
                for(const auto& c:constraints){const auto d=x.position-y.position;const double reach=c.multiplier*(c.planar?x.radii.xy+y.radii.xy:x.radii.spatial+y.radii.spatial)+c.gap;
                    if(c.enabled&&std::hypot(d.x,d.y,c.planar?0:d.z)<reach)collision=true;}
            }
            if(!collision)kept.push_back(a);
        }
        for(unsigned l=0;l<3;++l){std::vector<std::size_t> expected;for(auto r:kept)if(r.l==l)expected.push_back(r.i);std::sort(expected.begin(),expected.end());
            check(actual.layers[l].sets[0].kept==expected,"Ranked spatial solve differs from independent exhaustive oracle");
        }
    }
}
void refillOracle(){
    std::mt19937 rng(8681001);
    for(unsigned trial=0;trial<500;++trial){
        std::vector<Sample> ordinary;
        for(unsigned i=0;i<30;++i)ordinary.push_back(row(double(rng()%100)/5-10,i));
        const double replacement=double(rng()%60)/5-6;
        Plan p;p.layers={layer("A",ordinary),layer("P",{row(100,0),row(replacement,1)}),
            layer("PIN",{row(100,0,0,1,true)})};
        p.layers[0].sets[0].self={true,1,0,false};
        p.layers[0].acceptedTarget=trial%2==0;
        auto& pref=p.layers[1];pref.acceptedTarget=true;pref.rounds=trial%2?2:16;
        pref.sets[0].budget=1;pref.sets[0].sources[0].preferred=true;pref.sets[0].sources[0].external=3;
        const auto result=evaluate(p);
        // Exhaustive final-pool oracle: the pin rejects P0, P1 fills its slot;
        // all ordinary candidates are within the unchanged authorized prefix.
        std::vector<std::size_t> expected;
        for(unsigned i=0;i<ordinary.size();++i){
            bool blocked=std::abs(ordinary[i].position.x-replacement)<2;
            for(auto j:expected)blocked|=std::abs(ordinary[i].position.x-ordinary[j].position.x)<2;
            if(!blocked)expected.push_back(i);
        }
        check(result.layers[0].sets[0].kept==expected,"Refill settlement differs from exhaustive final-pool oracle");
        check(result.layers[1].sets[0].kept==std::vector<std::size_t>{1},"Refill oracle lost preferred candidate");
    }
}
int main(){try{scopesAndPriority();countAdmission();inheritanceAndEquivalence();crossLayerAndCleanup();limits();displacedBlockerAndDormantSource();dormantValuesAndBoundedWork();independentOracle();refillOracle();std::cout<<"Source clearance: scopes, independent inheritance, Count admission, effective-rule equivalence, protected priority, displaced blockers, dormant sources, cleanup/refill, limits, 240 single-pass and 500 refill oracle scenes passed\n";return 0;}catch(const std::exception& e){std::cerr<<e.what()<<'\n';return 1;}}
