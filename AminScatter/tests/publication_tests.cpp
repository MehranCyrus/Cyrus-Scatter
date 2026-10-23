// Exact production publication/presentation bodies and realization coordinator,
// with SDK-free fallible resources. This does not simulate a graphics driver.
#include <atomic>
#include <functional>
#include <iostream>
#include <memory>
#include <stdexcept>
#include <thread>
#include <utility>
#include <vector>
#include "../include/preview_budget.h"
#include "../include/render_publication.h"

namespace {
void require(bool value,const char* why) { if(!value)throw std::runtime_error(why); }
struct INode { bool hidden=false; };
struct Box3 { int identity=0; };
struct PointGroup { std::vector<int> points{1}; };
struct MeshGroup { std::vector<int> faces{1},instances{1},bandSlots{1}; };
struct Snapshot { std::vector<PointGroup> groups{PointGroup{}};std::vector<Box3> groupBounds{{11}}; };
struct Mesh {
    std::vector<MeshGroup> groups{MeshGroup{}};std::vector<Box3> groupBounds{{22}};
    std::shared_ptr<int> geometryIdentity=std::make_shared<int>(1);
};
struct PointLayer {
    std::shared_ptr<Snapshot> snapshot=std::make_shared<Snapshot>();
    std::shared_ptr<Mesh> mesh;
    int color=0;bool solid=false;
};
bool sameLayers(const std::vector<PointLayer>& a,const std::vector<PointLayer>& b) {
    if(a.size()!=b.size())return false;
    for(std::size_t i=0;i<a.size();++i)
        if(a[i].snapshot!=b[i].snapshot||a[i].mesh!=b[i].mesh||a[i].solid!=b[i].solid||
           (a[i].solid&&a[i].color!=b[i].color))return false;
    return true;
}
bool failGeneration=false;
int failItemAt=-1,itemAttempts=0,liveItems=0,reserved=0,reservationLimit=100;
cyrus::PreviewBudget physicalMeshBudget(1000);
cyrus::PreviewBudget physicalInstanceBudget(1000);
struct RenderBundle;
struct Generation {
    std::vector<PointLayer> layers;
    std::atomic<bool> enabled{true},failed{false};
    std::atomic<std::size_t> ready{0};
    std::size_t groups=0;int reservation=0;
    std::shared_ptr<cyrus::RenderPublication> presentation;
    std::weak_ptr<RenderBundle> realization;
    std::uint64_t ticket=0;
    explicit Generation(std::vector<PointLayer> value):layers(std::move(value)) {
        if(failGeneration)throw std::bad_alloc();
        for(const auto& layer:layers) {
            for(const auto& group:layer.snapshot->groups)if(!group.points.empty())++groups;
            if(layer.mesh)for(const auto& group:layer.mesh->groups)if(!group.faces.empty()&&!group.instances.empty())++groups;
        }
        if(reserved+int(groups)>reservationLimit){failed=true;return;}
        reservation=int(groups);reserved+=reservation;
    }
    bool complete() const { return !failed.load()&&ready.load()==groups; }
    bool visible() const { return enabled.load()&&presentation&&presentation->canDraw(ticket)&&complete(); }
    ~Generation(){reserved-=reservation;}
};
struct DrawContext {
    int attempts=0,failAt=-1;
    std::function<void(int)> afterItem;
};
struct ICustomRenderItem { virtual ~ICustomRenderItem()=default;virtual void RealizeResources(DrawContext&)=0; };
template<class T>struct RefPtr {
    std::shared_ptr<T> value;
    explicit RefPtr(T* p):value(p){}
    T* GetPointer() const{return value.get();}
};
struct RenderBundle {
    const std::shared_ptr<Generation> generation;
    std::vector<RefPtr<ICustomRenderItem>> items;
    std::vector<Box3> itemBounds;
    std::mutex realizeMutex;
    explicit RenderBundle(std::shared_ptr<Generation> value):generation(std::move(value)){}
    void realize(DrawContext& context) {
        cyrus::realizeRenderPublication(*this,context,[](const auto& item,DrawContext& dc){item.GetPointer()->RealizeResources(dc);});
    }
};
struct Item:ICustomRenderItem {
    std::shared_ptr<Generation> generation;
    std::size_t layerIndex,groupIndex;
    bool reused,ready=false;
    Item(std::shared_ptr<Generation> gen,std::size_t layer,std::size_t group,bool reuse)
        :generation(std::move(gen)),layerIndex(layer),groupIndex(group),reused(reuse) {
        if(itemAttempts++==failItemAt)throw std::bad_alloc();
        ++liveItems;
    }
    void reusedReady(bool value){if(value){ready=true;++generation->ready;}}
    void RealizeResources(DrawContext& context) override {
        if(ready||generation->failed)return;
        const auto attempt=context.attempts++;
        if(attempt==context.failAt){generation->failed=true;return;}
        ready=true;++generation->ready;
        if(context.afterItem)context.afterItem(attempt);
    }
    ~Item() override{--liveItems;}
};
struct PointItem:Item {
    PointItem(std::shared_ptr<Generation> gen,std::size_t layer,std::size_t group,const PointItem* previous)
        :Item(std::move(gen),layer,group,previous!=nullptr) {
        const auto& next=generation->layers[layerIndex];
        if(previous){const auto& old=previous->generation->layers[previous->layerIndex];reusedReady(old.solid==next.solid&&(!next.solid||old.color==next.color));}
    }
    bool reusable(const PointLayer& next,std::size_t group) const {
        return ready&&!generation->failed&&group==groupIndex&&generation->layers[layerIndex].snapshot==next.snapshot;
    }
};
struct MeshItem:Item {
    std::shared_ptr<cyrus::PreviewMemory> physical,instancePhysical;
    MeshItem(std::shared_ptr<Generation> gen,std::size_t layer,std::size_t group,const MeshItem* previous)
        :Item(std::move(gen),layer,group,previous!=nullptr),physical(previous?previous->physical:
            std::make_shared<cyrus::PreviewMemory>(physicalMeshBudget,cyrus::viewport_memory::Cost{10,10})) {
        const auto& next=generation->layers[layerIndex];
        const bool same=previous&&previous->sameInstances(next,group);
        instancePhysical=same?previous->instancePhysical:
            std::make_shared<cyrus::PreviewMemory>(physicalInstanceBudget,cyrus::viewport_memory::Cost{5,5});
        if(previous){const auto& old=previous->generation->layers[previous->layerIndex];reusedReady(same&&old.solid==next.solid&&(!next.solid||old.color==next.color));}
    }
    bool sameSlot(std::size_t layer,std::size_t group) const {
        return layerIndex==layer&&groupIndex==group;
    }
    bool sameInstances(const PointLayer& next,std::size_t group) const {
        const auto& previous=generation->layers[layerIndex];
        return previous.mesh==next.mesh||cyrus::viewport_memory::sameInstancePayload(
            previous.mesh->groups[groupIndex],next.mesh->groups[group]);
    }
    bool reusable(const PointLayer& next,std::size_t group) const {
        return ready&&!generation->failed&&group==groupIndex&&
            generation->layers[layerIndex].mesh->geometryIdentity==next.mesh->geometryIdentity;
    }
};
struct Controller {
    const std::shared_ptr<cyrus::RenderPublication> presentation=std::make_shared<cyrus::RenderPublication>();
    std::weak_ptr<Generation> generation;
    INode* node=nullptr;
    void SetRef(INode* value){node=value;}
    void update(){presentation->controllerVisible(node&&!node->hidden);}
};
constexpr int FOREVER=0,PART_GEOM=1,PART_DISPLAY=2,REFMSG_CHANGE=0;
struct Display {
    Controller controller;
    const std::shared_ptr<cyrus::RenderPublication> presentation=controller.presentation;
    std::shared_ptr<RenderBundle> candidate,retained;
    bool presentationRefreshRequested=false;
    std::uint64_t revision=0;int notifications=0;
    void NotifyDependents(int,int,int){++notifications;}
    ~Display(){presentation->stop();}
#include "../src/point_presentation.inc"
#include "../src/point_publication.inc"
    void realize(DrawContext context={}){auto keepAlive=candidate;keepAlive->realize(context);}
    void finish(){realize();requestPresentationUpdate();settlePresentation();}
};
PointLayer mixed(){PointLayer layer;layer.mesh=std::make_shared<Mesh>();return layer;}
struct Witness {
    std::shared_ptr<RenderBundle> candidate,visible;
    std::uint64_t revision;int notifications,items,reservations;std::size_t physical;
    INode* node;
    explicit Witness(const Display& display):candidate(display.candidate),visible(display.visibleBundle()),revision(display.revision),
        notifications(display.notifications),items(liveItems),reservations(reserved),physical(physicalMeshBudget.used()),node(display.controller.node){}
    void unchanged(const Display& display) const {
        require(display.candidate==candidate&&display.visibleBundle()==visible&&visible->generation->visible(),"failure lost the complete visible publication");
        require(display.revision==revision&&display.notifications==notifications&&display.controller.node==node,"failed preparation published identity or controller changes");
        require(liveItems==items&&reserved==reservations&&physicalMeshBudget.used()==physical,"failed preparation leaked ownership");
        require(visible->itemBounds.size()==2&&visible->itemBounds[0].identity==11&&visible->itemBounds[1].identity==22,"failed preparation replaced old bounds/items");
    }
};
void preparationFailures() {
    Display display;INode node,other;require(display.publish(&node,{mixed()}),"initial publish");display.finish();
    Witness before(display);failGeneration=true;bool threw=false;
    try{display.publish(&other,{mixed()});}catch(const std::bad_alloc&){threw=true;}
    failGeneration=false;require(threw,"generation fault not exercised");before.unchanged(display);
    for(int at=0;at<2;++at){
        itemAttempts=0;failItemAt=at;threw=false;
        try{display.publish(&other,{mixed()});}catch(const std::bad_alloc&){threw=true;}
        failItemAt=-1;require(threw,"item preparation fault not exercised");before.unchanged(display);
    }
    reservationLimit=3;require(!display.publish(&other,{mixed()}),"real old/new preparation allowance bypassed");
    reservationLimit=100;before.unchanged(display);
}
void admissionAndSharing() {
    physicalMeshBudget.limits(20,10);
    {
        Display display;INode node;auto layer=mixed();layer.solid=true;
        require(display.publish(&node,{layer}),"initial physical publish");display.finish();
        auto sdkPin=display.candidate->items[1].value;
        itemAttempts=0;const auto ticket=display.revision;
        require(display.publish(&node,{layer})&&itemAttempts==0&&display.revision==ticket,"unchanged publication did work");
        layer.color=7;require(display.publish(&node,{layer}),"shared buffers charged twice");
        require(physicalMeshBudget.used()==20&&display.retained&&display.retained->generation->visible(),"style successor lost old visibility or shared physical ownership");
        display.finish();require(!display.retained&&physicalMeshBudget.used()==20,"ready shared successor failed to retire old bundle");
        Witness before(display);bool threw=false;
        try{display.publish(&node,{mixed()});}catch(const std::exception&){threw=true;}
        require(threw,"distinct resource bypassed real physical overlap");before.unchanged(display);
        sdkPin.reset();require(physicalMeshBudget.used()==20,"prior SDK pin freed a still-shared buffer");
    }
    require(physicalMeshBudget.used()==0,"last shared physical lease did not release");
    physicalMeshBudget.limits(1000,1000);
}
void identicalGeometrySelectsExactInstanceResource() {
    {
        Display display;INode node;auto first=mixed(),second=mixed();
        first.snapshot->groups[0].points.clear();second.snapshot->groups[0].points.clear();
        second.mesh=std::make_shared<Mesh>(*first.mesh);second.mesh->groups[0].instances={2};
        first.solid=second.solid=true;
        require(display.publish(&node,{first,second}),"identical geometry initial publish");display.finish();
        const auto oldFirst=display.candidate->items[0].value,oldSecond=display.candidate->items[1].value;
        const auto* a=dynamic_cast<const MeshItem*>(oldFirst.get());
        const auto* b=dynamic_cast<const MeshItem*>(oldSecond.get());
        require(a&&b&&a->instancePhysical!=b->instancePhysical&&physicalInstanceBudget.used()==20,
            "initial distinct instance resources were not independent");
        const auto clone=[](PointLayer layer,int color){layer.mesh=std::make_shared<Mesh>(*layer.mesh);layer.color=color;return layer;};
        first=clone(first,7);second=clone(second,7);
        require(display.publish(&node,{first,second}),"same-shape material successor");
        const auto item=[&](std::size_t i){return dynamic_cast<const MeshItem*>(display.candidate->items[i].GetPointer());};
        require(item(0)->instancePhysical==a->instancePhysical&&item(1)->instancePhysical==b->instancePhysical&&
            physicalInstanceBudget.used()==20,"first geometric match hid the later exact instance lease");
        display.finish();
        first=clone(first,8);second=clone(second,8);
        require(display.publish(&node,{second,first}),"reordered same-shape material successor");
        require(item(0)->instancePhysical==b->instancePhysical&&item(1)->instancePhysical==a->instancePhysical&&
            physicalInstanceBudget.used()==20,"reordered slots failed to find exact immutable instance leases");
        display.finish();
        second=clone(second,9);second.mesh->groups[0].instances={3};
        require(display.publish(&node,{second,first}),"changed transform successor");
        require(item(0)->instancePhysical!=b->instancePhysical&&item(0)->physical==b->physical&&
            item(1)->instancePhysical==a->instancePhysical&&physicalInstanceBudget.used()==30,
            "changed transform reused stale instances or discarded reusable geometry");
        display.finish();
        first=clone(first,9);first.mesh->groups[0].bandSlots={2};
        require(display.publish(&node,{second,first}),"changed Band successor");
        require(item(1)->instancePhysical!=a->instancePhysical&&item(1)->physical==a->physical&&
            physicalInstanceBudget.used()==40,"changed Band ownership reused stale instances");
        display.finish();
    }
    require(physicalMeshBudget.used()==0&&physicalInstanceBudget.used()==0,
        "same-shape successors or SDK pins leaked physical leases");
}
void laterItemFailureAndRetry() {
    for(int at:{1,3}) {
        Display display;INode node;require(display.publish(&node,{mixed(),mixed()}),"initial multi-layer publication");display.finish();
        const auto old=display.visibleBundle();const auto oldTicket=display.presentation->visibleTicket();
        auto successor=std::vector<PointLayer>{mixed(),mixed()};
        require(display.publish(&node,successor),"stage successor");
        const auto next=display.candidate;DrawContext fault;fault.failAt=at;
        fault.afterItem=[&](int){require(old->generation->visible()&&!next->generation->visible(),"partially ready successor drew");};
        next->realize(fault);
        require(next->generation->failed&&display.visibleBundle()==old&&old->generation->visible(),"later SDK resource failure lost old complete display");
        require(display.presentation->visibleTicket()==oldTicket&&!next->generation->visible(),"failed successor changed visible identity");
        auto failedSDKPin=next->items[1].value;
        const auto charged=physicalMeshBudget.used();
        display.requestPresentationUpdate();display.settlePresentation();
        require(next->items.empty()&&physicalMeshBudget.used()<charged,"host did not retire failed item ownership");
        require(display.visibleBundle()==old&&old->generation->visible(),"failed retirement damaged the fallback");
        failedSDKPin.reset();
        require(display.publish(&node,successor),"identical-input retry was cached as permanently failed");
        const auto retry=display.candidate;display.realize();
        require(retry->generation->complete()&&!retry->generation->visible()&&old->generation->visible(),"worker promoted before host container boundary");
        display.requestPresentationUpdate();display.settlePresentation();
        require(display.visibleBundle()==retry&&retry->generation->visible()&&!old->generation->visible()&&!display.retained,"host failed to commit all-ready successor atomically");
    }
}
void rapidReplacementAndCulledSiblings() {
    Display display;INode node;require(display.publish(&node,{mixed()}),"initial ready publication");display.finish();
    const auto old=display.visibleBundle();
    require(display.publish(&node,{mixed(),mixed()}),"first pending successor");
    const auto superseded=display.candidate;
    DrawContext context;context.afterItem=[&](int item){if(item==0)require(display.publish(&node,{mixed()}),"rapid replacement failed");};
    superseded->realize(context);
    require(superseded->generation->ready==1&&!superseded->generation->visible(),"superseded worker continued or promoted");
    require(display.visibleBundle()==old&&old->generation->visible(),"rapid replacement lost last ready bundle");
    const auto newest=display.candidate;display.finish();
    require(display.visibleBundle()==newest&&!old->generation->visible()&&!superseded->generation->visible(),"newest complete publication did not win");
    require(display.publish(&node,{mixed(),mixed()}),"culled sibling successor");
    DrawContext all;display.candidate->realize(all);
    require(all.attempts==4&&display.candidate->generation->complete(),"first activation did not realize every sibling");
    display.settlePresentation();require(display.visibleGeneration()==display.candidate->generation,"complete sibling bundle not committed");
}
void initialFailureNotificationsAndConcurrentRealize() {
    Display display;INode node;const auto layers=std::vector<PointLayer>{mixed(),mixed()};
    require(display.publish(&node,layers),"initial fallible publication");
    DrawContext fault;fault.failAt=0;display.candidate->realize(fault);
    require(display.candidate->generation->failed&&!display.visibleBundle()&&display.presentation->visibleTicket()==0,
        "initial failure invented a visible publication");
    const auto notifications=display.notifications;
    display.requestPresentationUpdate();display.requestPresentationUpdate();
    require(display.notifications==notifications+1,"failed resource retirement requested repeated host updates");
    display.settlePresentation();display.requestPresentationUpdate();
    require(display.candidate->items.empty()&&display.notifications==notifications+1,"retired failure continued requesting host updates");
    require(display.publish(&node,layers),"initial failed input could not retry");
    DrawContext shared;std::vector<std::thread> workers;
    for(int i=0;i<8;++i)workers.emplace_back([&]{display.candidate->realize(shared);});
    for(auto& worker:workers)worker.join();
    require(shared.attempts==4&&display.candidate->generation->ready==4&&!display.visibleBundle(),
        "concurrent activations repeated uploads or promoted from a worker");
    const auto completed=display.notifications;
    display.requestPresentationUpdate();display.requestPresentationUpdate();
    require(display.notifications==completed+1,"completed resources requested repeated host updates");
    display.settlePresentation();display.requestPresentationUpdate();
    require(display.visibleBundle()==display.candidate&&display.notifications==completed+1,
        "ready publication did not settle without further update work");
}
void hideDeleteResetAndEmpty() {
    std::shared_ptr<ICustomRenderItem> sdkPin;
    std::shared_ptr<Generation> oldGeneration;
    {
        Display display;INode node;require(display.publish(&node,{mixed()}),"visible publication");display.finish();
        oldGeneration=display.visibleGeneration();sdkPin=display.candidate->items[1].value;
        node.hidden=true;display.controller.update();require(!oldGeneration->visible(),"hide did not immediately hide retained items");
        node.hidden=false;display.controller.update();require(oldGeneration->visible(),"unhide did not restore complete display");
        require(display.publish(&node,{mixed()}),"pending deletion successor");
        display.controller.SetRef(nullptr);display.controller.update();
        require(!oldGeneration->visible(),"controller deletion left old bundle visible");
        display.controller.SetRef(&node);display.controller.update();require(oldGeneration->visible(),"restored controller lost retained display");
        require(display.publish(&node,{}),"empty publication rejected");
        require(display.visibleGeneration()->groups==0&&!display.retained&&!oldGeneration->visible(),"empty successor retained old drawing");
    }
    require(!oldGeneration->visible()&&!oldGeneration->presentation->controllerVisible(),"SDK-pinned resource outlived display visibility after reset");
    require(physicalMeshBudget.used()==20,"SDK pin did not preserve its physical lease");
    sdkPin.reset();oldGeneration.reset();require(physicalMeshBudget.used()==0,"reset/last SDK pin leaked physical resources");
}
}
int main() {
    try {
        preparationFailures();admissionAndSharing();identicalGeometrySelectsExactInstanceResource();laterItemFailureAndRetry();rapidReplacementAndCulledSiblings();
        initialFailureNotificationsAndConcurrentRealize();hideDeleteResetAndEmpty();
        require(liveItems==0&&reserved==0&&physicalMeshBudget.used()==0&&physicalInstanceBudget.used()==0,"publication fixture leaked resources");
        std::cout<<"PASS production publication/presentation: admission, exact-instance reuse across same-shape layers, sharing, initial/late failure retention, host-only atomic commit, retry, rapid replacement, concurrent activation, culled siblings, hide/delete/reset and SDK pins\n";
    }catch(const std::exception& error){std::cerr<<error.what()<<'\n';return 1;}
}
