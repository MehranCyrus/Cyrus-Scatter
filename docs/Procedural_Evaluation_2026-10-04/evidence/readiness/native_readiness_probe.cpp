// Read-only numerical investigation of the current core; not a plugin change.
#include "scatter.h"
#include "group_spacing.h"
#include <cmath>
#include <iostream>
#include <map>
#include <stdexcept>

void require(bool condition,const char* message) {
    if(!condition) throw std::runtime_error(message);
}
int main() { try {
    using namespace amin;
    const std::vector<Triangle> surface={
        {{-10,-10,0},{10,-10,0},{10,10,0}},
        {{-10,-10,0},{10,10,0},{-10,10,0}}};
    Settings settings;settings.count=128;settings.seed=71;settings.sourceCount=3;
    settings.preserveDensity=true;settings.uniformScale={.5,1.5};
    const auto plain=scatter(surface,settings);
    auto maskedSettings=settings;
    Area excluded;excluded.include=false;
    excluded.loops={{{-10,-10,0},{0,-10,0},{0,10,0},{-10,10,0}}};
    maskedSettings.areas.push_back(excluded);
    const auto masked=scatter(surface,maskedSettings);
    std::map<std::uint64_t,Instance> original;
    for(const auto& p:plain) original.emplace(p.candidateKey,p);
    unsigned moved=0,attributesChanged=0,sourcesChanged=0;
    for(const auto& p:masked) {
        const auto& old=original.at(p.candidateKey);
        moved+=length(old.position-p.position)>1e-12;
        attributesChanged+=std::abs(old.scale-p.scale)>1e-12 || length(old.xAxis-p.xAxis)>1e-12;
        sourcesChanged+=old.source!=p.source;
    }
    require(!masked.empty()&&masked.size()<plain.size(),"Area fixture did not filter candidates");
    require(moved==0,"Unexpected candidate anchor movement in area fixture");
    require(attributesChanged>0&&sourcesChanged>0,"Expected conditional RNG consumption was not observed");

    auto shortSettings=settings;shortSettings.count=32;
    const auto prefix=scatter(surface,shortSettings);
    for(std::size_t i=0;i<prefix.size();++i)
        require(prefix[i].candidateKey==plain[i].candidateKey && prefix[i].source==plain[i].source &&
            prefix[i].scale==plain[i].scale && length(prefix[i].position-plain[i].position)==0,
            "Unmasked count prefix changed");

    using namespace cyrus::groups;
    const std::vector<Vec3> high={{0,0,0}},low={{.1,0,0},{.2,0,0}};
    Rule obstacle;obstacle.blockers=high;obstacle.gap=1;
    obstacle.ownRadii={0,0};obstacle.blockerRadii={0};
    const auto initially=resolve(low,0,{obstacle},{false,false});
    require(initially.kept.empty(),"Expected both lower candidates to be blocked");
    Instance h{};h.position=high[0];
    FinalSettings cleanup;cleanup.cleanup=true;cleanup.relax=false;cleanup.radius=.3;
    cleanup.minNeighbors=1;cleanup.minIsland=2;
    const auto highCleaned=finalize({},Settings{},{h},{},{0},{},cleanup);
    require(highCleaned.empty(),"Expected isolated blocker cleanup");
    const auto retry=resolve(low,0,{}, {false,false});
    require(retry.kept.size()==2,"Released space was not available to retry");
    std::vector<Instance> lowRows(2);lowRows[0].position=low[0];lowRows[1].position=low[1];
    require(finalize({},Settings{},lowRows,{}, {0,0},{},cleanup).size()==2,"Replacement cluster failed cleanup");

    std::vector<Instance> chain(3);
    for(std::size_t i=0;i<chain.size();++i)chain[i].position={double(i),0,0};
    cleanup.radius=1.01;cleanup.minNeighbors=2;cleanup.minIsland=1;
    const auto centre=finalize({},Settings{},chain,{}, {0,0,0},{},cleanup);
    require(centre.size()==1&&centre[0].position.x==1,"Cleanup fixture is not single-pass neighbor semantics");

    const double invRoot2=1/std::sqrt(2.0);
    const double rowBound=std::sqrt(2.0),actual=length(Vec3{invRoot2,2*invRoot2,0});
    require(actual>rowBound,"Expected shear counterexample");
    std::cout<<"{\"status\":\"passed\",\"scope\":\"existing numeric core and mathematical witnesses; no Max host\","
        <<"\"unmasked_candidates\":"<<plain.size()<<",\"masked_candidates\":"<<masked.size()
        <<",\"same_id_position_changes\":"<<moved<<",\"same_id_attribute_changes\":"<<attributesChanged
        <<",\"same_id_source_changes\":"<<sourcesChanged<<",\"unmasked_prefix_count\":"<<prefix.size()
        <<",\"cleanup_released_candidates\":"<<retry.kept.size()
        <<",\"single_pass_cleanup_survivors\":"<<centre.size()
        <<",\"shear_largest_row_bound\":"<<rowBound<<",\"shear_unit_vector_length\":"<<actual<<"}\n";
    return 0;
} catch(const std::exception& e) {std::cerr<<e.what()<<'\n';return 1;} }
