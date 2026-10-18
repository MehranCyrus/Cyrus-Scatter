#include <max.h>
#include <maxscript/maxscript.h>
#include "placement_value.h"
#include "placement_api.h"
#include "placement_materialization.h"
#include "native_fault_qualification.h"
#include <atomic>
#include <algorithm>
#include <cstring>
#include <limits>
#include <type_traits>

static_assert(sizeof(CyrusPlacementRecord)==sizeof(cyrus::placements::Record),"Placement ABI stride mismatch");
static_assert(offsetof(CyrusPlacementRecord,identity)==offsetof(cyrus::placements::Record,identity),"Placement ABI identity offset mismatch");
static_assert(offsetof(CyrusPlacementRecord,flags)==offsetof(cyrus::placements::Record,flags),"Placement ABI flags offset mismatch");
static_assert(std::is_trivially_copyable<cyrus::placements::Record>::value,"Placement ABI must remain numeric POD");
namespace {std::atomic<std::uint64_t> leases{0},filters{0};}
struct CyrusPlacementLease {
    const cyrus::placements::View view;
    std::atomic<std::uint32_t> refs{1};
    explicit CyrusPlacementLease(const cyrus::placements::View& v):view(v){++leases;}
    ~CyrusPlacementLease(){--leases;}
};
struct CyrusPlacementFilter {
    const cyrus::placements::View input;
    cyrus::placements::Builder builder;
    std::size_t previous=0;
    bool appended=false,finished=false;
    explicit CyrusPlacementFilter(const cyrus::placements::View& view):input(view),builder(view.token().owner,view.stage(),view.sources(),view.size(),view.sourceCohort(),view.receiverCohort()){++filters;}
    ~CyrusPlacementFilter(){--filters;}
};
namespace {
CyrusPlacementLease* acquire(void* value) noexcept {
    if(!value||GetCurrentThreadId()!=GetCOREInterface15()->GetMainThreadID())return nullptr;
    try{return new CyrusPlacementLease(cyrusPlacementView(static_cast<Value*>(value)));}catch(...){return nullptr;}
}
int retain(CyrusPlacementLease* p) noexcept {
    if(!p)return 0;auto refs=p->refs.load(std::memory_order_relaxed);
    while(refs<std::numeric_limits<std::uint32_t>::max())if(p->refs.compare_exchange_weak(refs,refs+1,std::memory_order_relaxed))return 1;
    return 0;
}
void release(CyrusPlacementLease* p) noexcept {if(p&&p->refs.fetch_sub(1,std::memory_order_acq_rel)==1)delete p;}
int info(const CyrusPlacementLease* p,CyrusPlacementInfo* out) noexcept {
    if(!p||!out||out->size!=sizeof(CyrusPlacementInfo))return 0;
    const auto t=p->view.token();*out={sizeof(CyrusPlacementInfo),2,sizeof(CyrusPlacementRecord),p->view.stage()==cyrus::placements::Stage::Candidates?1u:2u,p->view.sources(),0,t.owner,t.generation,t.view,p->view.size()};return 1;
}
int record(const CyrusPlacementLease* p,std::uint64_t i,CyrusPlacementRecord* out) noexcept {
    if(!p||!out||i>=p->view.size())return 0;const auto& r=p->view.at(std::size_t(i));std::memcpy(out,&r,sizeof(r));return 1;
}
const char* authored(const CyrusPlacementLease* p,std::uint64_t i,std::uint32_t* length) noexcept {
    if(length)*length=0;if(!p||!length||i>=p->view.size()||(p->view.at(std::size_t(i)).flags&cyrus::placements::Authored)==0)return nullptr;
    const auto text=p->view.authored(std::size_t(i));*length=static_cast<std::uint32_t>(text.size());return text.data();
}
std::uint64_t liveLeases() noexcept {return leases.load(std::memory_order_relaxed);}
CyrusPlacementFilter* beginFilter(const CyrusPlacementLease* p) noexcept {
    try{if(!p||p->view.stage()!=cyrus::placements::Stage::Candidates)return nullptr;return new CyrusPlacementFilter(p->view);}catch(...){return nullptr;}
}
int appendFilter(CyrusPlacementFilter* p,std::uint64_t i,const float* matrix) noexcept {
    if(!p||p->finished||!matrix||i>=p->input.size()||(p->appended&&i<=p->previous))return 0;
    try{cyrus::owned::fault(4);auto row=p->input.at(std::size_t(i));std::copy_n(matrix,12,row.transform.begin());p->builder.appendGenerated(row);p->previous=std::size_t(i);p->appended=true;return 1;}catch(...){p->finished=true;return 0;}
}
void* finishFilter(CyrusPlacementFilter* p) noexcept {
    if(!p||p->finished||GetCurrentThreadId()!=GetCOREInterface15()->GetMainThreadID())return nullptr;
    p->finished=true;try{return cyrusPlacementValue(p->builder.freeze());}catch(...){return nullptr;}
}
void destroyFilter(CyrusPlacementFilter* p) noexcept {delete p;}
std::uint64_t liveFilters() noexcept{return filters.load(std::memory_order_relaxed);}
std::uint32_t receiverCount(const CyrusPlacementLease* p) noexcept{return p&&p->view.receiverCohort()?std::uint32_t(p->view.receiverCohort()->receivers().size()):0;}
int receiver(const CyrusPlacementLease* p,std::uint32_t i,CyrusPlacementReceiver* out) noexcept {
    if(!out||i>=receiverCount(p))return 0;const auto& r=p->view.receiverCohort()->receivers()[i];*out={r.slot,r.begin,r.faces,0,r.handle};return 1;
}
void notePaintTransport(std::uint64_t rows,std::uint64_t matrices,std::uint64_t arrays) noexcept {
    cyrus::placements::MaterializationScope scope(cyrus::placements::TransportStage::Paint);scope.add({rows,matrices,0,arrays});
}
const CyrusPlacementApi api={sizeof(CyrusPlacementApi),2,sizeof(CyrusPlacementRecord),0,acquire,retain,release,info,record,authored,liveLeases,beginFilter,appendFilter,finishFilter,destroyFilter,liveFilters,receiverCount,receiver,notePaintTransport};
}
extern "C" __declspec(dllexport) const CyrusPlacementApi* CyrusPlacementGetApi(std::uint32_t version) {return version==api.version?&api:nullptr;}
