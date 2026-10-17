#include "placement_store.h"
#include <cmath>
#include <cstring>
#include <iostream>
#include <limits>
#include <stdexcept>
#include <type_traits>
#include <atomic>
#include <optional>
#include <thread>
using namespace cyrus::placements;
namespace {
void check(bool v,const char* label){if(!v)throw std::runtime_error(label);}
template<class F> void rejects(F f,const char* label){bool threw=false;try{f();}catch(const std::exception&){threw=true;}check(threw,label);}
Record record(std::uint64_t id=0) {
    Record r;r.transform={1,0,0,0,1,0,0,0,1,float(id),-0.f,3};r.identity=id;r.band=42;r.receiver=127;
    r.bary={.2f,.3f,.5f};return r;
}
bool equal(const Record& a,const Record& b){return std::memcmp(&a,&b,sizeof(Record))==0;}
void basic() {
    static_assert(std::is_same<decltype(std::declval<const View>().at(0)),const Record&>::value,"Read-only native access");
    const auto baseline=metrics();const auto owner=newOwner();
    {
        Builder builder(owner,Stage::Candidates,2,3);builder.appendGenerated(record(5));
        auto r=record(9007199254740993ULL);r.source=2;builder.appendGenerated(r);
        auto escaped=builder.get(0);escaped.transform[9]=100;
        auto view=builder.freeze();check(view.size()==2&&view.at(0).transform[9]==5,"Detached mutable builder read");
        check(std::signbit(view.at(0).transform[10]),"Signed zero kept at host Float32 boundary");
        check(equal(view.at(1),r),"Full-width identity, flags, face, anchor and transform bytes retained");
        rejects([&]{builder.appendGenerated(r);},"Consumed builder mutation");
        rejects([&]{builder.get(0);},"Consumed builder read");
        const auto before=metrics();auto alias=view;check(alias.token()==view.token(),"Shared immutable copy");
        check(metrics().liveBytes==before.liveBytes&&metrics().allocations==before.allocations,"Copying handles allocates no payload");
        auto usage=view.sourceUsage();check(usage==std::vector<std::uint32_t>({1,1}),"Native source-use summary");
        rejects([&]{view.textIdentity(0);},"Raw identity must stay numeric");
        auto wrong=view.token();++wrong.owner;rejects([&]{view.require(wrong);},"Foreign owner rejected");
        wrong=view.token();++wrong.generation;rejects([&]{view.require(wrong);},"Stale generation rejected");
        wrong=view.token();++wrong.view;rejects([&]{view.require(wrong);},"Stale selection rejected");
        auto page=view.page(0,2,view.token());page[0].transform[0]=100;
        check(view.at(0).transform[0]==1,"Readback cannot mutate immutable publication");
        check(view.page(2,0,view.token()).empty(),"Empty page at end");
        rejects([&]{view.page(0,501,view.token());},"Page upper bound");
        rejects([&]{view.page(3,0,view.token());},"Past-end page");
        rejects([&]{view.page(1,std::numeric_limits<std::size_t>::max(),view.token());},"Page overflow");
        rejects([&]{view.at(2);},"Bounds check");
        Builder successor(view);auto changed=successor.get(0);changed.transform[9]=100;successor.replace(0,changed);
        auto next=successor.freeze();check(next.at(0).transform[9]==100&&view.at(0).transform[9]==5,"Successor has private mutable storage");
        check(next.token().generation!=view.token().generation,"Successor has new generation");
        auto moved=std::move(alias);check(moved.size()==2,"Moved view retains storage");
        rejects([&]{alias.at(0);},"Moved-from access is rejected before dereference");
    }
    auto after=metrics();check(after.liveBytes==baseline.liveBytes&&after.liveStores==baseline.liveStores&&after.liveAllocations==baseline.liveAllocations,"All storage releases at last owner");
}
void identitiesAndViews() {
    auto before=metrics();
    {
        Builder builder(newOwner(),Stage::Edited,1,4);
        builder.appendGenerated(record(9223372036854775807ULL));
        auto authored=record(0);authored.flags=Protected;
        builder.appendAuthored(authored,"copy:exact-A");builder.appendAuthored(authored,"copy:exact-A");builder.appendAuthored(authored,"c:00001");
        auto base=builder.freeze();
        check(base.textIdentity(0)=="c:9223372036854775807","Generated external edited identity round trip");
        check(base.textIdentity(1)=="copy:exact-A"&&base.textIdentity(2)=="copy:exact-A","Exact authored identity round trip");
        check(base.at(1).identity==base.at(2).identity&&base.at(3).identity!=base.at(2).identity,"Authored keys interned once");
        check(base.textIdentity(3)=="c:00001","Do not normalize authored strings by guessing candidate format");
        auto selection=base.select({3,1,0});check(selection.size()==3&&selection.at(0).identity==base.at(3).identity,"Selection order and identity preserved");
        check(selection.token().generation==base.token().generation&&selection.token().view!=base.token().view,"Selection pins same generation with a separate token");
        auto nested=selection.select({1});check(nested.textIdentity(0)=="copy:exact-A","Flattened nested selection");
        check(nested.baseBytes()==base.baseBytes()&&nested.selectionBytes()==4,"One base and one flat index, no selection chains");
        auto compact=nested.compact();check(compact.size()==1&&compact.textIdentity(0)==nested.textIdentity(0),"Compaction remaps only internal text slots");
        check(compact.baseBytes()<base.baseBytes()&&compact.selectionBytes()==0,"Small result can release large rejected base");
        check(compact.at(0).flags==nested.at(0).flags&&compact.at(0).band==42,"Compaction keeps protection and Band ownership");
        rejects([&]{base.select({1,1});},"Duplicate selection");rejects([&]{base.select({4});},"Invalid selection");
        auto empty=base.select({});check(empty.size()==0&&empty.baseBytes()==0&&empty.selectionBytes()==0,"Empty selection drops parent payload pin");
    }
    check(metrics().liveBytes==before.liveBytes&&metrics().liveSelections==before.liveSelections,"Flattened views and interned text release");
}
void malformed() {
    auto owner=newOwner();Builder b(owner,Stage::Candidates,1);
    auto bad=[&](Record r){rejects([&]{b.appendGenerated(r);},"Malformed native record rejected");check(b.size()==0,"Invalid append is atomic");};
    auto r=record();r.source=0;bad(r);r=record();r.source=2;bad(r);
    r=record();r.face=0;bad(r);r=record();r.face=0x80000000;bad(r);
    r=record();r.receiver=128;bad(r);r=record();r.reserved=1;bad(r);
    r=record();r.flags=4;bad(r);r=record();r.flags=Protected;bad(r);
    r=record();r.identity=0x8000000000000000ULL;bad(r);r=record();r.band=0x8000000000000000ULL;bad(r);
    r=record();r.transform[4]=std::numeric_limits<float>::infinity();bad(r);
    r=record();r.bary[2]=std::numeric_limits<float>::quiet_NaN();bad(r);
    rejects([&]{b.appendAuthored(record(),"authored");},"No authored IDs on raw candidates");
    rejects([&]{Builder bad(0,Stage::Edited,1);},"Missing owner");
    rejects([&]{Builder bad(owner,static_cast<Stage>(2),1);},"Invalid stage");
    rejects([&]{Builder bad(owner,Stage::Edited,1025);},"Source bound");
    rejects([&]{Builder bad(owner,Stage::Edited,1,maxRecords+1);},"Candidate bound");
    auto empty=Builder(owner,Stage::Candidates,0).freeze();check(empty.size()==0&&empty.sources()==0,"Typed empty zero-source generation");
    Builder edited(owner,Stage::Edited,1);
    for(const auto& text:std::vector<std::string>{"",std::string(257,'x'),std::string("x\0y",3),std::string(1,char(128))})
        rejects([&]{edited.appendAuthored(record(),text);},"Malformed authored identity");
    edited.appendAuthored(record(),std::string(256,'x'));auto result=edited.freeze();check(result.textIdentity(0).size()==256,"Existing 256-byte procedural key boundary");
}
void capacity() {
    auto before=metrics();
    {
        Builder b(newOwner(),Stage::Candidates,1,200000);
        for(std::uint32_t i=0;i<200000;++i)b.appendGenerated(record(i));
        auto view=b.freeze();check(view.baseBytes()==200000*sizeof(Record),"Measured 200k record capacity is 19,200,000 bytes");
        check(metrics().liveBytes-before.liveBytes==view.baseBytes(),"Unique storage attribution matches requested vector capacity");
        check(metrics().readbackRows==before.readbackRows,"Native construction does not materialize pages");
        auto page=view.page(199500,500,view.token());check(page.size()==500&&page.back().identity==199999,"Bounded final page retains full IDs");
    }
    check(metrics().liveBytes==before.liveBytes,"Large generation release");
    check(metrics().peakBytes>=before.liveBytes+19200000,"Peak ownership observes large allocation");
}
void workerPins() {
    const auto before=metrics();
    std::atomic<bool> go{false};std::array<std::uint64_t,4> sums{};std::array<std::thread,4> workers;
    {
        Builder builder(newOwner(),Stage::Candidates,1,10000);
        for(std::uint32_t i=0;i<10000;++i)builder.appendGenerated(record(i));
        std::optional<View> original(builder.freeze());
        for(std::size_t slot=0;slot<workers.size();++slot)workers[slot]=std::thread([view=*original,&go,&sums,slot]{
            while(!go.load(std::memory_order_acquire))std::this_thread::yield();
            for(std::size_t i=0;i<view.size();++i)sums[slot]+=view.at(i).identity;
        });
        original.reset();
        check(metrics().liveStores==before.liveStores+1&&metrics().liveBytes==before.liveBytes+960000,"Worker pins share one generation after producer release");
        go.store(true,std::memory_order_release);
    }
    for(auto& worker:workers)worker.join();
    for(auto sum:sums)check(sum==49995000,"Concurrent numeric reads preserve full identities");
    check(metrics().liveBytes==before.liveBytes&&metrics().liveStores==before.liveStores,"Last worker releases numeric storage without host calls");
}
}
int main(){try{basic();identitiesAndViews();malformed();capacity();workerPins();std::cout<<"Native immutable placement layout, identities, tokens, views, bounded readback and release passed\n";return 0;}catch(const std::exception& e){std::cerr<<e.what()<<'\n';return 1;}}
