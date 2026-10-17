#include "placement_publication.h"
#include "receiver_plan.h"
#include <iostream>
#include <limits>
#include <optional>
#include <stdexcept>

using namespace cyrus::placements;
namespace {
void check(bool yes,const char* message){if(!yes)throw std::runtime_error(message);}
template<class F>void rejects(F action){bool rejected=false;try{action();}catch(const std::exception&){rejected=true;}check(rejected,"Expected binding/publication rejection");}
Record record(unsigned i){Record r;r.transform={1,0,0,0,1,0,0,0,1,float(i),0,0};r.identity=cyrus::receivers::identity(0,i);return r;}
void cohorts(){
    const auto owner=newOwner();std::vector<SourceBinding> sources={{"tree",42,RenderSource},{"point",0,PointSource}};
    auto source=SourceCohort::create(owner,"population",sources),equal=SourceCohort::create(owner,"population",sources);
    check(source!=equal&&source->generation()!=equal->generation()&&sameSourceCohort(source,equal),"Semantic source equality is independent of metadata allocation identity");
    sources[0].handle=43;check(source->sources()[0].handle==42,"Frozen source metadata has no mutable input aliases");
    auto changed=SourceCohort::create(owner,"population",sources);check(!sameSourceCohort(source,changed),"Equal-cardinality model replacement changes correspondence");
    std::swap(sources[0],sources[1]);check(!sameSourceCohort(source,SourceCohort::create(owner,"population",sources)),"Source reorder changes correspondence");
    sources={{"tree",42,RenderSource},{"tree",43,RenderSource}};rejects([&]{SourceCohort::create(owner,"population",sources);});
    rejects([&]{SourceCohort::create(0,"population",{});});rejects([&]{SourceCohort::create(owner,"",{});});
    rejects([&]{SourceCohort::create(owner,"population",{{"tree",0,RenderSource}});});
    rejects([&]{SourceCohort::create(owner,"population",{{"tree",42,128}});});
    Builder builder(owner,Stage::Candidates,2,4,source);for(unsigned i=0;i<4;++i)builder.appendGenerated(record(i));auto raw=builder.freeze();
    auto edited=raw.edited(),selected=edited.select({3,1}),compact=selected.compact(),empty=selected.select({});
    for(const auto* view:{&raw,&edited,&selected,&compact,&empty})check(view->sourceCohort()==source,"Transforms/selections/compaction/empty views retain exact source ownership");
    rejects([&]{Builder bad(owner,Stage::Candidates,1,0,source);});rejects([&]{Builder bad(newOwner(),Stage::Candidates,2,0,source);});
}
void receiverProvenance(){
    const auto owner=newOwner();std::vector<ReceiverBinding> input{{0,0,3,"terrain-a","revision-a",99}};
    auto a=ReceiverCohort::create(owner,input);input[0].revision="caller changed";
    check(a->receivers()[0].revision=="revision-a","Frozen receiver provenance is detached from mutable metadata");
    auto shifted=a->offset(7);check(a->receivers()[0].begin==0&&shifted->receivers()[0].begin==7,"Receiver face offset retains the original evaluated revision");
    auto b=ReceiverCohort::create(owner,{{1,10,5,"terrain-b","revision-b",100}});
    auto joined=ReceiverCohort::merge(owner,{shifted,b,shifted});check(joined->receivers().size()==2,"Receiver join deduplicates exact provenance without losing per-slot bindings");
    auto changed=ReceiverCohort::create(owner,{{0,7,3,"terrain-a","changed-at-same-frame",99}});
    rejects([&]{ReceiverCohort::merge(owner,{shifted,changed});});rejects([&]{ReceiverCohort::merge(owner,{shifted,{}});});
    rejects([&]{ReceiverCohort::merge(newOwner(),{a});});rejects([&]{a->offset(10000000);});
    rejects([&]{ReceiverCohort::create(owner,{{0,0,3,"a","revision",99},{1,2,2,"b","revision",100}});});
    Builder builder(owner,Stage::Candidates,1,2,{},a);for(unsigned i=0;i<2;++i)builder.appendGenerated(record(i));auto raw=builder.freeze();
    auto edited=raw.edited(),selected=edited.select({1}),compact=selected.compact(),empty=selected.select({});
    for(const auto* view:{&raw,&edited,&selected,&compact,&empty})check(view->receiverCohort()==a,"All immutable view operations preserve receiver provenance, including empty results");
    rejects([&]{Builder bad(newOwner(),Stage::Candidates,1,0,{},a);});
}
void publication(){
    const auto baseline=metrics();std::weak_ptr<const std::vector<CyrusRadiusPair>> radiusPin;
    std::weak_ptr<const SourceCohort> sourcePin;
    {
        const auto owner=newOwner();auto cohort=SourceCohort::create(owner,"population",{{"tree",42,RenderSource}});sourcePin=cohort;
        const std::vector<ReceiverBinding> receivers{{0,0,1,"terrain","revision",99}};
        auto receiverCohort=ReceiverCohort::create(owner,receivers);
        Builder builder(owner,Stage::Candidates,1,3,cohort,receiverCohort);for(unsigned i=0;i<3;++i)builder.appendGenerated(record(i));auto view=builder.freeze().edited().prepared("prepared-key","binding");
        auto radii=std::make_shared<const std::vector<CyrusRadiusPair>>(3,CyrusRadiusPair{.5f,.75f});radiusPin=radii;
        PublishedPopulation pop(view,radii,cohort);pop.id="population";pop.parent="layer";pop.layerOrder=pop.setOrder=1;pop.budget=pop.attempts=pop.pool=3;pop.statistics[0]=pop.statistics[1]=pop.statistics[9]=3;pop.surfaceStatistics={-1,0,0};pop.binding="binding";pop.receivers=receivers;
        pop.preparationKey="prepared-key";
        PublicationHeader header;header.owner=newOwner();header.epoch=1;header.id="publication-one";header.script="script";header.inputKey="input-one";
        std::vector<PublishedPopulation> inputs{pop};const auto before=metrics();auto first=Publication::create(header,inputs);
        check(first->size()==3 && &first->populations()[0].rows.at(0)==&view.at(0)&&first->populations()[0].radii==radii,"Publication shares placement/radius storage");
        check(first->populations()[0].sourceCounts==std::vector<std::uint32_t>{3},"Source counts freeze once for passive UI reads");
        check(metrics().allocations==before.allocations&&metrics().liveBytes==before.liveBytes,"Publication creates no population vector copies");
        inputs[0].binding="binding";header.inputKey="mutated";
        check(first->populations()[0].binding=="binding"&&first->header().inputKey=="input-one","Publication metadata is detached from caller mutation");
        header.epoch=2;header.id="publication-two";auto next=Publication::create(header,inputs,first);
        check(first->header().epoch==1&&next->header().epoch==2,"Successor does not mutate its predecessor");
        rejects([&]{Publication::create(header,inputs,next);});
        auto invalid=inputs;invalid[0].statistics[1]=2;rejects([&]{Publication::create(header,invalid,first);});
        invalid=inputs;invalid[0].expectedSources=SourceCohort::create(owner,"population",{{"tree",43,RenderSource}});rejects([&]{Publication::create(header,invalid,first);});
        invalid=inputs;invalid[0].radii=std::make_shared<const std::vector<CyrusRadiusPair>>(2);rejects([&]{Publication::create(header,invalid,first);});
        invalid=inputs;invalid[0].radii=std::make_shared<const std::vector<CyrusRadiusPair>>(3,CyrusRadiusPair{std::numeric_limits<float>::quiet_NaN(),1});rejects([&]{Publication::create(header,invalid,first);});
        invalid=inputs;invalid[0].receivers.clear();rejects([&]{Publication::create(header,invalid,first);});
        invalid=inputs;invalid[0].receivers.push_back({1,0,1,"other","revision",100});rejects([&]{Publication::create(header,invalid,first);});
        invalid=inputs;invalid[0].receivers[0].revision="changed-at-same-frame";rejects([&]{Publication::create(header,invalid,first);});
        invalid=inputs;invalid[0].receivers[0].handle=100;rejects([&]{Publication::create(header,invalid,first);});
        invalid=inputs;invalid[0].preparationKey="different-preparation";rejects([&]{Publication::create(header,invalid,first);});
        rejects([&]{view.prepared("different-preparation","binding");});
        auto selected=view.select({1}),compact=selected.compact(),empty=selected.select({});
        for(const auto* v:{&selected,&compact,&empty})check(v->preparation()==view.preparation(),"Selection and compaction preserve the exact preparation receipt");
        Builder changedRows(view);auto changedRecord=changedRows.get(0);changedRecord.transform[9]+=1;changedRows.replace(0,changedRecord);
        check(!changedRows.freeze().preparation(),"Builder mutation invalidates a previously sealed preparation receipt");
        invalid=inputs;invalid[0].receivers[0].begin=1;rejects([&]{Publication::create(header,invalid,first);});
        invalid=inputs;invalid[0].id="wrong-population";rejects([&]{Publication::create(header,invalid,first);});
        auto wrongHeader=header;wrongHeader.owner=newOwner();rejects([&]{Publication::create(wrongHeader,inputs,first);});
        wrongHeader=header;wrongHeader.rules={{2,"layer","unknown",true,true,1,0}};rejects([&]{Publication::create(wrongHeader,inputs,first);});
        check(first->size()==3&&first->populations()[0].rows.at(2).identity==record(2).identity,"Failed successors preserve full predecessor");
        // A protected authored copy retains unresolved provenance exactly, as
        // the current surface filter does; ordinary rows must resolve receivers.
        Builder authored(owner,Stage::Edited,1,1,cohort);auto copy=record(0);copy.receiver=127;copy.flags=Protected;authored.appendAuthored(copy,"copy:independent");
        auto protectedPop=pop;protectedPop.rows=authored.freeze().prepared("prepared-key","binding");protectedPop.radii=std::make_shared<const std::vector<CyrusRadiusPair>>(1,CyrusRadiusPair{1,1});protectedPop.budget=protectedPop.attempts=protectedPop.pool=0;protectedPop.statistics[0]=protectedPop.statistics[1]=protectedPop.statistics[2]=1;protectedPop.statistics[9]=0;protectedPop.receivers.clear();
        auto protectedResult=Publication::create(header,{protectedPop},first);check(protectedResult->size()==1,"Protected zero-quota detached provenance is retained");
        cohort.reset();radii.reset();check(!sourcePin.expired()&&!radiusPin.expired(),"Publication retains correspondence/radii while consumers pin it");
    }
    check(sourcePin.expired()&&radiusPin.expired()&&metrics().liveBytes==baseline.liveBytes,"Last publication/input owner releases native storage and metadata");
}
}
int main(){try{cohorts();receiverProvenance();publication();std::cout<<"Native source/receiver binding, immutable coherent data publication, protected provenance, failure retention and shared release passed\n";return 0;}catch(const std::exception& e){std::cerr<<e.what()<<'\n';return 1;}}
