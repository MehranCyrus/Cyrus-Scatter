#include <max.h>
#include <maxscript/maxscript.h>
#include "placement_value.h"
#include "placement_api.h"
#include <atomic>
#include <cstring>
#include <limits>
#include <type_traits>

static_assert(sizeof(CyrusPlacementRecord)==sizeof(cyrus::placements::Record),"Placement ABI stride mismatch");
static_assert(offsetof(CyrusPlacementRecord,identity)==offsetof(cyrus::placements::Record,identity),"Placement ABI identity offset mismatch");
static_assert(offsetof(CyrusPlacementRecord,flags)==offsetof(cyrus::placements::Record,flags),"Placement ABI flags offset mismatch");
static_assert(std::is_trivially_copyable<cyrus::placements::Record>::value,"Placement ABI must remain numeric POD");
namespace {std::atomic<std::uint64_t> leases{0};}
struct CyrusPlacementLease {
    const cyrus::placements::View view;
    std::atomic<std::uint32_t> refs{1};
    explicit CyrusPlacementLease(const cyrus::placements::View& v):view(v){++leases;}
    ~CyrusPlacementLease(){--leases;}
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
    const auto t=p->view.token();*out={sizeof(CyrusPlacementInfo),1,sizeof(CyrusPlacementRecord),p->view.stage()==cyrus::placements::Stage::Candidates?1u:2u,p->view.sources(),0,t.owner,t.generation,t.view,p->view.size()};return 1;
}
int record(const CyrusPlacementLease* p,std::uint64_t i,CyrusPlacementRecord* out) noexcept {
    if(!p||!out||i>=p->view.size())return 0;const auto& r=p->view.at(std::size_t(i));std::memcpy(out,&r,sizeof(r));return 1;
}
const char* authored(const CyrusPlacementLease* p,std::uint64_t i,std::uint32_t* length) noexcept {
    if(length)*length=0;if(!p||!length||i>=p->view.size()||(p->view.at(std::size_t(i)).flags&cyrus::placements::Authored)==0)return nullptr;
    const auto text=p->view.authored(std::size_t(i));*length=static_cast<std::uint32_t>(text.size());return text.data();
}
std::uint64_t liveLeases() noexcept {return leases.load(std::memory_order_relaxed);}
const CyrusPlacementApi api={sizeof(CyrusPlacementApi),1,sizeof(CyrusPlacementRecord),0,acquire,retain,release,info,record,authored,liveLeases};
}
extern "C" __declspec(dllexport) const CyrusPlacementApi* CyrusPlacementGetApi(std::uint32_t version) {return version==api.version?&api:nullptr;}
