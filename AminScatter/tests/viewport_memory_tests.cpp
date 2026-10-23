#include "../include/preview_budget.h"
#include <array>
#include <cmath>
#include <iostream>
#include <memory>
#include <stdexcept>
#include <vector>

namespace {
using namespace cyrus;
using namespace cyrus::viewport_memory;
void require(bool value,const char* message) {if(!value)throw std::runtime_error(message);}
template<class F> void rejects(F body,const char* message) {
    bool rejected=false;try{body();}catch(const std::exception&){rejected=true;}
    require(rejected,message);
}
void arithmeticAndMeshGuards() {
    const auto maximum=std::numeric_limits<std::size_t>::max();
    require(add(maximum,0)==maximum&&multiply(maximum,1)==maximum,"exact arithmetic boundary");
    rejects([&]{add(maximum,1);},"addition overflow admitted");
    rejects([&]{multiply(maximum,2);},"multiplication overflow admitted");
    validateMesh(0,0,false,false);validateMesh(1,3,true,true);
    validateMesh(0,3,false,true); // orphan vertices remain excluded by the real face scan
    rejects([]{validateMesh(-1,3,true,true);},"negative faces admitted");
    rejects([]{validateMesh(1,-1,true,true);},"negative vertices admitted");
    rejects([]{validateMesh(1,3,false,true);},"missing faces admitted");
    rejects([]{validateMesh(1,3,true,false);},"missing vertices admitted");
    rejects([]{validateMesh(1,0,true,false);},"face with no vertices admitted");
    validateIndex(2,3);rejects([]{validateIndex(3,3);},"out-of-range vertex admitted");
    std::size_t inspected=0;
    inspectFaces(2000001,inspected,32000000);inspectFaces(29999999,inspected,32000000);
    require(inspected==32000000,"aggregate inspected work changed");
    rejects([&]{inspectFaces(1,inspected,32000000);},"inspected work overflow admitted");
    require(inspected==32000000,"failed inspection changed count");
    const auto maxFaces=std::size_t(std::numeric_limits<int>::max())/3;
    validateDrawCounts(maxFaces,1000000);
    rejects([&]{validateDrawCounts(maxFaces+1,1);},"SDK expanded corner range overflow admitted");
}
void resourcePlans() {
    const auto one=meshPlan(2000001,1,true,2000001ull*72+4*MiB);
    const auto many=meshPlan(2000001,1000000,true,2000001ull*72+4*MiB);
    require(one.geometry.total()==many.geometry.total()&&one.appearance.total()==many.appearance.total(),
        "source geometry/appearance incorrectly multiplied by instances");
    require(many.instances.cpu==52000000&&many.instances.device==52000000,"instance SDK/system copies differ");
    require(one.geometry.cpu==one.geometry.device&&one.appearance.cpu==2*one.appearance.device,
        "retained SDK/system/upload allowance lost");
    const auto boxes=meshPlan(2000001,1,false,2000001ull*72+4*MiB);
    require(boxes.geometry.cpu==12*108&&boxes.appearance.total()==0,"box plan charged full geometry/appearance upload");
    require(one.scratch(false,false,false)==0,"shared ready streams request upload scratch");
    require(one.scratch(true,false,false)==2000001ull*36,"geometry upload scratch differs");
    require(many.scratch(false,true,false)==52000000,"instance upload scratch differs");
    rejects([]{meshPlan(100,1,true,std::numeric_limits<std::size_t>::max());},"appearance arithmetic overflow admitted");
}
void exactInstancePayloadReuse() {
    // Matrix3's SDK equality compares all elements exactly. This portable
    // payload uses the same 12 ordered scalar values and the production helper.
    struct Group {std::vector<std::array<float,12>> instances;std::vector<unsigned char> bandSlots;};
    Group before{{{{1,0,0,0,1,0,0,0,1,10,20,30}},{{1,0,0,0,1,0,0,0,1,40,50,60}}},{3,9}};
    auto after=before;
    require(sameInstancePayload(before,after),"identical values in distinct snapshot storage were not reusable");
    for(std::size_t instance=0;instance<before.instances.size();++instance)
        for(std::size_t component=0;component<12;++component) {
            after=before;auto& value=after.instances[instance][component];
            value=std::nextafter(value,std::numeric_limits<float>::infinity());
            require(!sameInstancePayload(before,after),"a changed transform component reused the old instance buffer");
        }
    after=before;std::swap(after.instances[0],after.instances[1]);std::swap(after.bandSlots[0],after.bandSlots[1]);
    require(!sameInstancePayload(before,after),"reordered placement payload reused the old instance buffer");
    after=before;after.bandSlots[1]=10;
    require(!sameInstancePayload(before,after),"changed Band ownership reused the old instance buffer");
    after=before;std::swap(after.bandSlots[0],after.bandSlots[1]);
    require(!sameInstancePayload(before,after),"Band permutation reused the old instance buffer");
    after=before;after.instances.pop_back();after.bandSlots.pop_back();
    require(!sameInstancePayload(before,after),"changed instance count reused the old instance buffer");
    after=before;after.bandSlots.pop_back();
    require(!sameInstancePayload(before,after)&&!sameInstancePayload(after,after),"incomplete ownership payload was reusable");
    PreviewBudget budget(208);budget.limits(208,104);
    auto original=std::make_shared<PreviewMemory>(budget,Cost{104,104});
    after=before;
    auto successor=sameInstancePayload(before,after)?original:std::make_shared<PreviewMemory>(budget,Cost{104,104});
    original.reset();require(budget.used()==208,"retiring an old wrapper released the successor's shared physical stream");
    successor.reset();require(budget.used()==0,"last shared instance payload lease leaked");
}
void finitePolicyAndHeadroom() {
    const Calibration calibration{8ull*1024*MiB,2ull*1024*MiB,32000000,512*MiB,512*MiB,8,16};
    const SystemMemory system{true,64ull*1024*MiB,20ull*1024*MiB,40ull*1024*MiB};
    const auto automatic=policy(system,0,calibration),custom=policy(system,65536,calibration);
    require(automatic.total==8ull*1024*MiB&&automatic.device==2ull*1024*MiB,"automatic finite policy differs");
    require(automatic.cpuHeadroom==16ull*1024*MiB,"physical headroom reserve differs");
    require(custom.total==64ull*1024*MiB&&custom.device==automatic.device&&custom.cpuHeadroom==automatic.cpuHeadroom,
        "custom ceiling bypassed OS/device admission");
    const auto unknown=policy({},0,calibration);
    require(unknown.total==calibration.automaticMaximum&&unknown.device==calibration.deviceFallback&&unknown.cpuHeadroom==0,
        "unknown telemetry became unlimited");
    const auto low=policy({true,system.totalPhysical,512*MiB,512*MiB},65536,calibration);
    require(low.cpuHeadroom==0,"low headroom bypassed by custom setting");
    const auto small=policy({true,8ull*1024*MiB,6ull*1024*MiB,6ull*1024*MiB},0,calibration);
    require(small.total==1024*MiB,"automatic policy ignored physical size");
}
void reservationsAndOwnership() {
    PreviewBudget budget(100);budget.limits(100,40);
    {
        auto staging=std::make_shared<PreviewMemory>(budget,Cost{40,20},80);
        require(budget.used()==60&&budget.state().pending==40,"initial category/pending accounting");
        rejects([&]{PreviewMemory rejected(budget,Cost{1,21},80);},"device boundary admitted");
        require(budget.used()==60&&budget.highWater()==60,"failed device admission changed accounting");
        staging->commit();require(budget.state().pending==0,"materialized CPU still pending");
        // Moving the same vector/lease into a snapshot does not create storage.
        auto snapshot=std::move(staging);auto gpuHandleOwner=snapshot;
        require(!staging&&budget.used()==60,"ownership transfer charged duplicate storage");
        {
            PreviewMemory successor(budget,Cost{20,20},20);
            require(budget.used()==100&&budget.state().pending==20,"exact boundary/new-only OS headroom rejected");
            rejects([&]{PreviewMemory rejected(budget,Cost{1,0},20);},"overlap bypassed total ceiling");
        }
        require(budget.used()==60&&budget.highWater()==100,"successor release damaged old resource");
        snapshot.reset();require(budget.used()==60,"shared physical resource released before last handle owner");
        gpuHandleOwner.reset();require(budget.used()==0,"last shared owner did not release");
    }
    {
        PreviewMemory pending(budget,Cost{40,0},40);
        rejects([&]{PreviewMemory next(budget,Cost{1,0},40);},"unmaterialized reservations omitted from OS admission");
        pending.commit(10);require(budget.state().pending==30,"partial CPU materialization lost outstanding allocations");
        pending.commit();pending.grow({10,0},10);require(budget.state().pending==10&&budget.used()==50,"growth accounting");
        rejects([&]{pending.grow({51,0},100);},"failed growth admitted");
        require(pending.cost().cpu==50&&budget.used()==50,"failed growth changed the lease");
        pending.trimCPU(45);require(budget.state().pending==5&&budget.used()==45,"trim did not transfer/release pending storage");
        pending.commit();pending.commit();require(budget.state().pending==0,"commit is not idempotent");
        budget.limits(20,10);require(budget.used()==45,"lowering policy evicted retained storage");
        PreviewMemory noAllocation(budget,Cost{},0);
        rejects([&]{PreviewMemory next(budget,Cost{1,0},100);},"lowered policy admitted new storage");
    }
    require(budget.used()==0&&budget.state().pending==0,"reservation lifetime leaked after policy reduction");
}
void metadataIsIndependentOfDisplayPreference() {
    const Calibration calibration{8ull*1024*MiB,2ull*1024*MiB,32000000,512*MiB,512*MiB,8,16};
    const SystemMemory system{true,64ull*1024*MiB,20ull*1024*MiB,40ull*1024*MiB};
    const auto headroom=systemHeadroom(system,calibration).available;
    SystemMemoryAdmission admission;
    PreviewBudget display(8ull*1024*MiB,&admission),metadata(32000000ull*128,&admission);
    {
        PreviewMemory retained(display,Cost{512*MiB,512*MiB},headroom);retained.commit();
        display.limits(policy(system,256,calibration).total,2ull*1024*MiB);
        rejects([&]{PreviewMemory successor(display,Cost{1,0},headroom);},"lowered display ceiling admitted a successor");
        {
            PreviewMemory conversion(metadata,Cost{64*MiB,0},headroom);
            require(metadata.used()==64*MiB&&display.used()==1024*MiB,"metadata charged against retained display usage");
            require(admission.used()==64*MiB,"metadata conversion absent from shared pending headroom");
            conversion.commit();
            require(admission.used()==0&&metadata.state().pending==0,"materialized metadata was double counted against OS headroom");
        }
        require(metadata.used()==0&&display.used()==1024*MiB,"metadata release damaged the retained display");
        rejects([&]{PreviewMemory conversion(metadata,Cost{64*MiB,0},64*MiB-1);},"metadata bypassed insufficient CPU headroom");
        rejects([&]{PreviewMemory conversion(metadata,Cost{32000000ull*128+1,0},headroom);},"metadata bypassed its finite CPU allowance");
        require(metadata.used()==0&&admission.used()==0,"failed metadata admission leaked reservations");
        display.limits(8ull*1024*MiB,2ull*1024*MiB);
        {
            PreviewMemory displayPending(display,Cost{40*MiB,0},64*MiB);
            rejects([&]{PreviewMemory conversion(metadata,Cost{25*MiB,0},64*MiB);},"display pending CPU omitted from metadata admission");
            PreviewMemory conversion(metadata,Cost{24*MiB,0},64*MiB);
            require(admission.used()==64*MiB,"cross-budget exact CPU boundary rejected");
            rejects([&]{PreviewMemory next(metadata,Cost{1,0},64*MiB);},"concurrent metadata reservations bypassed headroom");
            conversion.commit(4*MiB);require(admission.used()==60*MiB,"partial metadata commit lost pending bytes");
            conversion.trimCPU(20*MiB);require(admission.used()==56*MiB,"metadata trim failed to release shared pending bytes");
            rejects([&]{conversion.grow({9*MiB,0},64*MiB);},"metadata growth omitted other pending budgets");
            require(conversion.cost().cpu==20*MiB&&admission.used()==56*MiB,"failed metadata growth changed ownership");
        }
        require(admission.used()==0&&metadata.used()==0&&display.used()==1024*MiB,"shared CPU lease cleanup differs");
    }
    require(admission.used()==0&&display.used()==0,"final independent admission cleanup differs");
}
}
int main() {
    try {
        arithmeticAndMeshGuards();resourcePlans();exactInstancePayloadReuse();finitePolicyAndHeadroom();reservationsAndOwnership();metadataIsIndependentOfDisplayPreference();
        std::cout<<"PASS viewport memory: checked resource plans, exact instance/Band reuse, finite CPU/device policy, independent metadata admission, sharing, transfer, overlap and failure retention\n";
    } catch(const std::exception& error) {std::cerr<<error.what()<<'\n';return 1;}
}
