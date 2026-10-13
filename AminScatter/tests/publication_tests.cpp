// Exercise the production publication body without the Max SDK. Collaborators
// model fallible allocation/admission and resource ownership, not GPU behavior.
#include <atomic>
#include <iostream>
#include <memory>
#include <stdexcept>
#include <utility>
#include <vector>
#include "../include/preview_budget.h"

namespace {
void require(bool value,const char* why) { if(!value) throw std::runtime_error(why); }
struct INode {};
struct Box3 { int identity=0; };
struct PointGroup { std::vector<int> points{1}; };
struct MeshGroup { std::vector<int> faces{1},instances{1}; };
struct Snapshot {
    std::vector<PointGroup> groups{PointGroup{}};
    std::vector<Box3> groupBounds{{11}};
};
struct Mesh {
    std::vector<MeshGroup> groups{MeshGroup{}};
    std::vector<Box3> groupBounds{{22}};
};
struct PointLayer {
    std::shared_ptr<Snapshot> snapshot=std::make_shared<Snapshot>();
    std::shared_ptr<Mesh> mesh;
    int color=0;
    bool solid=false;
};
bool sameLayers(const std::vector<PointLayer>& a,const std::vector<PointLayer>& b) {
    if(a.size()!=b.size()) return false;
    for(std::size_t i=0;i<a.size();++i)
        if(a[i].snapshot!=b[i].snapshot || a[i].mesh!=b[i].mesh || a[i].solid!=b[i].solid ||
           (a[i].solid && a[i].color!=b[i].color)) return false;
    return true;
}
bool failGeneration=false;
int failItemAt=-1,itemAttempts=0,liveItems=0,reserved=0,reservationLimit=100;
struct Generation {
    std::vector<PointLayer> layers;
    std::atomic<bool> enabled{true},failed{false};
    std::size_t groups=0;
    int reservation=0;
    explicit Generation(std::vector<PointLayer> value):layers(std::move(value)) {
        if(failGeneration) throw std::bad_alloc();
        for(const auto& layer:layers) {
            for(const auto& group:layer.snapshot->groups) if(!group.points.empty()) ++groups;
            if(layer.mesh) for(const auto& group:layer.mesh->groups)
                if(!group.faces.empty() && !group.instances.empty()) ++groups;
        }
        if(reserved+int(groups)>reservationLimit) { failed=true;return; }
        reservation=int(groups);reserved+=reservation;
    }
    ~Generation() { reserved-=reservation; }
};
struct ICustomRenderItem { virtual ~ICustomRenderItem()=default; };
template<class T> struct RefPtr {
    std::shared_ptr<T> value;
    explicit RefPtr(T* p):value(p) {}
    T* GetPointer() const { return value.get(); }
};
struct Item : ICustomRenderItem {
    std::shared_ptr<Generation> generation;
    std::size_t layerIndex,groupIndex;
    bool reused;
    Item(std::shared_ptr<Generation> gen,std::size_t layer,std::size_t group,bool reuse)
        :generation(std::move(gen)),layerIndex(layer),groupIndex(group),reused(reuse) {
        if(itemAttempts++==failItemAt) throw std::bad_alloc();
        ++liveItems;
    }
    ~Item() override { --liveItems; }
};
struct PointItem : Item {
    PointItem(std::shared_ptr<Generation> gen,std::size_t layer,std::size_t group,const PointItem* previous)
        :Item(std::move(gen),layer,group,previous!=nullptr) {}
    bool reusable(const PointLayer& next,std::size_t group) const {
        const auto& prior=generation->layers[layerIndex];
        return !generation->failed && group==groupIndex && prior.snapshot==next.snapshot &&
            prior.solid==next.solid && (!next.solid || prior.color==next.color);
    }
};
struct MeshItem : Item {
    MeshItem(std::shared_ptr<Generation> gen,std::size_t layer,std::size_t group,const MeshItem* previous)
        :Item(std::move(gen),layer,group,previous!=nullptr) {}
    bool reusable(const PointLayer& next,std::size_t group) const {
        const auto& prior=generation->layers[layerIndex];
        return !generation->failed && group==groupIndex && prior.mesh==next.mesh &&
            prior.solid==next.solid && (!next.solid || prior.color==next.color);
    }
};
struct Controller {
    std::weak_ptr<Generation> generation;
    INode* node=nullptr;
    void SetRef(INode* value) { node=value; }
    void update() { if(auto value=generation.lock()) value->enabled=node!=nullptr; }
};
constexpr int FOREVER=0,PART_GEOM=1,PART_DISPLAY=2,REFMSG_CHANGE=0;
struct Display {
    Controller controller;
    std::shared_ptr<Generation> generation;
    std::vector<RefPtr<ICustomRenderItem>> items;
    std::vector<Box3> itemBounds;
    int revision=0,notifications=0;
    void NotifyDependents(int,int,int) { ++notifications; }
#include "../src/point_publication.inc"
};
PointLayer mixed() { PointLayer layer;layer.mesh=std::make_shared<Mesh>();return layer; }
void unchanged(const Display& display,const std::shared_ptr<Generation>& previous,
               ICustomRenderItem* item,int revision,INode* node,int items,int reservations) {
    require(display.generation==previous && previous->enabled,"previous generation lost/disabled");
    require(display.items.front().GetPointer()==item,"previous render item replaced on failure");
    require(display.revision==revision && display.notifications==revision,"failed attempt published a revision");
    require(display.controller.node==node && display.controller.generation.lock()==previous,"controller binding changed on failure");
    require(liveItems==items && reserved==reservations,"failed preparation leaked items/reservations");
    require(display.itemBounds.size()==2 && display.itemBounds[0].identity==11 && display.itemBounds[1].identity==22,
            "previous point/mesh bounds changed on failure");
}
void allocationFailure() {
    Display display;INode node,other;require(display.publish(&node,{mixed()}),"initial publish");
    auto prior=display.generation;auto* item=display.items.front().GetPointer();
    failGeneration=true;bool threw=false;
    try { display.publish(&other,{mixed()}); } catch(const std::bad_alloc&) { threw=true; }
    failGeneration=false;require(threw,"allocation failure was not exercised");
    unchanged(display,prior,item,1,&node,2,2);
    require(display.publish(&node,{mixed()}),"retry after allocation failure");
    require(display.revision==2 && !prior->enabled,"successful replacement did not retire prior");
}
void itemFailures() {
    for(int at=0;at<2;++at) {
        Display display;INode node;require(display.publish(&node,{mixed()}),"initial publish");
        auto prior=display.generation;auto* item=display.items.front().GetPointer();
        itemAttempts=0;failItemAt=at;bool threw=false;
        try { display.publish(&node,{mixed()}); } catch(const std::bad_alloc&) { threw=true; }
        failItemAt=-1;require(threw,"point/mesh preparation failure not exercised");
        unchanged(display,prior,item,1,&node,2,2);
        require(display.publish(&node,{mixed()}),"retry after item failure");
    }
}
void admissionAndReuse() {
    Display display;INode node;auto layer=mixed();require(display.publish(&node,{layer}),"initial publish");
    auto prior=display.generation;auto* item=display.items.front().GetPointer();
    reservationLimit=3;require(!display.publish(&node,{mixed()}),"overlap admission should reject");
    unchanged(display,prior,item,1,&node,2,2);reservationLimit=100;
    itemAttempts=0;require(display.publish(&node,{layer}),"unchanged publish");
    require(itemAttempts==0 && display.generation==prior && display.revision==1,"unchanged publication did work");
    // Changed sibling adds work but reuses both unchanged point and mesh resources.
    require(display.publish(&node,{layer,PointLayer{}}),"changed sibling publish");
    require(dynamic_cast<Item*>(display.items[0].GetPointer())->reused &&
            dynamic_cast<Item*>(display.items[1].GetPointer())->reused,"unchanged sibling resources not reused");
    require(!dynamic_cast<Item*>(display.items[2].GetPointer())->reused,"changed resource incorrectly reused");
}
void failedResourceRetryAndEmpty() {
    Display display;INode node;auto layer=mixed();require(display.publish(&node,{layer}),"initial publish");
    auto prior=display.generation;prior->failed=true;
    require(display.publish(&node,{layer}),"same-input failed-resource retry blocked");
    require(display.generation!=prior && !display.generation->failed,"failed generation reused");
    for(const auto& item:display.items) require(!dynamic_cast<Item*>(item.GetPointer())->reused,"failed resources reused");
    require(display.publish(&node,{}),"empty successor rejected");
    require(display.items.empty() && display.itemBounds.empty() && display.generation->groups==0,"empty successor has stale items");
}
}
int main() {
    try {
        cyrus::PreviewBudget budget(100);
        {
            cyrus::PreviewMemory old(budget,60);
            bool denied=false;try { cyrus::PreviewMemory next(budget,41); }catch(const std::exception&){denied=true;}
            require(denied&&budget.used()==60&&budget.highWater()==60,"failed resource admission lost the old reservation or leaked staging");
            { cyrus::PreviewMemory exact(budget,40);require(budget.used()==100,"exact resource boundary not admitted"); }
            require(budget.used()==60&&budget.highWater()==100,"temporary resource reservation did not release");
        }
        require(budget.used()==0,"resource cache lifetime leaked a reservation");
        allocationFailure();itemFailures();admissionAndReuse();failedResourceRetryAndEmpty();
        require(liveItems==0 && reserved==0,"publication fixture leaked resources");
        std::cout<<"PASS production publication: allocation, point/mesh preparation, peak admission, unchanged reuse, retry and empty successor\n";
    } catch(const std::exception& error) { std::cerr<<error.what()<<'\n';return 1; }
}
