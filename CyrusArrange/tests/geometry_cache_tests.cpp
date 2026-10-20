// Pure native cache tests; test-only allocation faults, no host SDK.
#include "cyrus_arrange/geometry_cache.h"
#include <cstdio>
#include <cstdlib>
#include <new>
#include <type_traits>

static bool fail_next_allocation{};
static std::size_t live_allocations{};
void* operator new(std::size_t size) {
    if(fail_next_allocation){fail_next_allocation=false;throw std::bad_alloc();}
    if(auto* p=std::malloc(size?size:1)){++live_allocations;return p;}
    throw std::bad_alloc();
}
void operator delete(void* p) noexcept {if(p){--live_allocations;std::free(p);}}
void operator delete(void* p,std::size_t) noexcept {::operator delete(p);}
void* operator new[](std::size_t size){return ::operator new(size);}
void operator delete[](void* p) noexcept {::operator delete(p);}
void operator delete[](void* p,std::size_t) noexcept {::operator delete(p);}

namespace ca=cyrus::arrange;
namespace cd=ca::cache;
void require(bool value,const char* text){if(!value)throw std::runtime_error(text);}
cd::GeometryKey make_key(std::uint64_t document=1) {
    cd::Epoch scene,geometry;
    cd::GeometryKey out;out.ticket=cd::Ticket::make(document,scene,geometry);out.mm_per_system_unit=1;
    ca::Settings settings;settings.minimum_clearance_mm=0;out.inspection=cd::InspectionKey::from(settings);
    ca::QuerySettings qs;qs.require_front_access=false;out.query=cd::QueryKey::from(qs);
    out.roots.push_back({11,7,cd::ScopeRole::Furniture});
    cd::NodeStamp node;node.handle=11;
    node.object_tm={1,0,0,0,1,0,0,0,1,0,0,0};
    node.evaluated_class_id={1,2};node.evaluated_super_class=3;
    node.object_validity={-100,100};node.transform_validity={-100,100};out.nodes.push_back(node);
    return out;
}
std::optional<cd::GeometryBundle> make_bundle() {
    ca::Mesh mesh;mesh.vertices={{0,0,0},{100,0,0},{100,100,0},{0,100,0}};
    mesh.triangles={{{0,1,2}},{{0,2,3}}};
    ca::Settings settings;settings.minimum_clearance_mm=0;
    auto raw=ca::inspect(mesh,settings);
    const std::vector<ca::FurnitureBody> bodies{{11,std::move(mesh)}};
    ca::QuerySettings qs;qs.require_front_access=false;
    ca::FurniturePlacementQuery query(bodies,qs);
    const auto memory=query.retained_storage();
    require(memory.complete && memory.accounted_bytes>=memory.wrapper_bytes,"query accounting must be complete");
    const cd::QueryStorage storage{memory.accounted_bytes,memory.wrapper_bytes,query.diagnostics().triangles,memory.complete};
    return std::optional<cd::GeometryBundle>(std::in_place,std::move(raw),std::move(query),storage,cd::TickInterval{-100,100});
}
void test_epoch() {
    cd::Epoch scene,geometry;
    require(cd::Ticket::make(1,scene,geometry).valid(),"normal epoch ticket");
    geometry.value=std::numeric_limits<std::uint64_t>::max();geometry.invalidate();
    require(!geometry.reusable && !cd::Ticket::make(1,scene,geometry).valid(),"document saturation refuses reuse");
    geometry=cd::Epoch{};scene.value=std::numeric_limits<std::uint64_t>::max();scene.invalidate();
    require(!cd::Ticket::make(1,scene,geometry).valid(),"scene saturation refuses reuse");
    require(!cd::Ticket{1,2,3}.valid(),"three-number aggregate fails closed");
    auto key=make_key();key.ticket=cd::Ticket::make(1,scene,geometry);
    cd::GeometryCache cache;auto candidate=make_bundle();
    require(!cache.offer(key,candidate).lease && candidate.has_value(),"saturated ticket retains cold candidate");
}
void test_keys() {
    cd::GeometryCache cache;auto key=make_key();auto candidate=make_bundle();auto retained=cache.offer(key,candidate);
    require(bool(retained.lease) && !candidate,"complete candidate transferred");
    require(bool(cache.lookup(key).lease),"exact key hits");
    const auto miss=[&](auto change){auto altered=key;change(altered);require(!cache.lookup(altered).lease,"each changed geometry input misses");};
    miss([](auto& k){++k.ticket.document_instance;});miss([](auto& k){++k.ticket.scene;});miss([](auto& k){++k.ticket.geometry;});
    miss([](auto& k){++k.time;});miss([](auto& k){k.mm_per_system_unit=10;});miss([](auto& k){k.origin_mm[0]=1;});
    miss([](auto& k){++k.roots[0].source_key;});miss([](auto& k){++k.roots[0].handle;});
    miss([](auto& k){++k.nodes[0].handle;});miss([](auto& k){k.nodes[0].object_tm[9]=1;});
    miss([](auto& k){++k.nodes[0].evaluated_class_id[0];});miss([](auto& k){--k.nodes[0].transform_validity.last;});
    miss([](auto& k){k.inspection.cell=50;});miss([](auto& k){++k.inspection.clearance;});miss([](auto& k){++k.inspection.slope;});
    miss([](auto& k){++k.inspection.height_tolerance;});miss([](auto& k){--k.inspection.triangles;});
    miss([](auto& k){--k.inspection.cells;});miss([](auto& k){--k.inspection.regions;});miss([](auto& k){--k.inspection.work;});
    miss([](auto& k){k.query.tolerance=.004;});miss([](auto& k){k.query.require_front_access=true;});
    miss([](auto& k){k.query.default_front[0]=1;});miss([](auto& k){--k.query.triangles;});
    miss([](auto& k){--k.query.support_vertices;});miss([](auto& k){--k.query.build_work;});miss([](auto& k){--k.query.vertices;});
    auto invalid=key;invalid.nodes[0].object_tm[0]=std::numeric_limits<double>::quiet_NaN();
    require(cache.lookup(invalid).reason==cd::Reason::InvalidKey,"nonfinite matrix not reused");
}
void test_raw_and_live_totals() {
    cd::GeometryCache cache;auto key=make_key();auto candidate=make_bundle();
    const auto cells=candidate->raw.sampled_cells;const auto original=candidate->raw.regions[0].id;
    auto offer=cache.offer(key,candidate);require(bool(offer.lease),"retained bundle");
    auto local=offer.lease.get().raw;local.regions[0].id=999;local.regions[0].cells[0].center.x+=100;
    require(offer.lease.get().raw.regions[0].id==original,"raw observation ID not mutated by binding copy");
    require(offer.lease.get().raw.regions[0].cells[0].center.x!=local.regions[0].cells[0].center.x,"cell copy independent");
    auto totals=cache.totals();
    require(totals.live.entries==1 && totals.live.cells==cells && totals.live.triangles==2,"logical aggregate counts");
    require(totals.live.bytes>offer.lease.get().storage.bytes && totals.entry_metadata_requested_live_bytes>0,"entry plus key/raw metadata accounted");
    cache.clear_all();require(cache.totals().retired_borrowed==1,"clear leaves borrower charged");
    offer.lease.reset();totals=cache.totals();
    require(totals.live.entries==0 && totals.live.bytes==0 && totals.entry_metadata_requested_live_bytes==0,"last lease releases payload and control block");
}
void test_optional_failure() {
    cd::GeometryCache cache;auto key=make_key();auto original=make_bundle();auto offer=cache.offer(key,original);
    const auto* address=&offer.lease.get();auto replacement=make_bundle();auto changed=key;++changed.ticket.geometry;
    fail_next_allocation=true;
    const auto failed=cache.offer(changed,replacement);
    require(!fail_next_allocation,"fault reached optional metadata allocation");
    require(!failed.lease && failed.reason==cd::Reason::MetadataAllocation && replacement.has_value(),"metadata failure preserves cold bundle");
    auto same=cache.lookup(key);require(bool(same.lease) && &same.lease.get()==address,"prior cache retained on failure");
    replacement->storage.complete=false;
    require(cache.offer(changed,replacement).reason==cd::Reason::AccountingUnavailable && replacement.has_value(),"incomplete accounting never retains zero size");
}
void test_limits() {
    auto key=make_key();auto sample=make_bundle();const auto cells=sample->raw.sampled_cells;
    cd::GeometryCache reference;auto offer=reference.offer(key,sample);const auto bytes=reference.totals().live.bytes;
    require(bytes>0 && cells>0,"positive observed reference size");
    for(int mode=0;mode<3;++mode){cd::Limits limits;
        if(mode==0)limits.bytes=bytes-1;if(mode==1)limits.triangles=1;if(mode==2)limits.cells=cells-1;
        cd::GeometryCache limited(limits);auto candidate=make_bundle();const auto denied=limited.offer(key,candidate);
        require(!denied.lease && denied.reason==cd::Reason::TooLarge && candidate.has_value(),"lower cap keeps valid cold candidate");}
    bool rejected=false;try{cd::Limits bad;bad.entries=5;cd::GeometryCache invalid(bad);}catch(const std::invalid_argument&){rejected=true;}
    require(rejected,"retention caps cannot exceed implementation limits");
}
void test_pinned_aggregate() {
    cd::GeometryCache cache;std::array<cd::GeometryLease,4> pins;
    for(std::size_t i=0;i<4;++i){auto candidate=make_bundle();pins[i]=cache.offer(make_key(i+1),candidate).lease;require(bool(pins[i]),"four admitted leases");}
    auto fifth=make_bundle();require(cache.offer(make_key(5),fifth).reason==cd::Reason::PinnedBudget && fifth.has_value(),"fifth pinned entry cold fallback");
    const auto bytes=cache.totals().live.bytes;cache.defer_all();
    require(cache.totals().resident==4 && cache.totals().live.bytes==bytes,"callback invalidation does not destroy data");
    cache.drain_deferred();require(cache.totals().resident==0 && cache.totals().live.entries==4 && cache.totals().retired_borrowed==4,"all retired borrowers still charged");
    require(pins[0].get().query.diagnostics().triangles==2,"borrowed query remains alive");
    pins[0].reset();auto admitted=cache.offer(make_key(5),fifth);require(bool(admitted.lease) && !fifth,"release permits fifth cold candidate retention");
    for(auto& pin:pins)pin.reset();cache.clear_all();admitted.lease.reset();
    require(cache.totals().live.entries==0 && cache.totals().entry_metadata_requested_live_bytes==0,"bounded retirement cleanup");
    require(cache.totals().peak.entries==4,"peak never exceeds global four entries");
}
void test_pinned_replacement() {
    cd::GeometryCache cache;auto key=make_key();auto first=make_bundle();auto old=cache.offer(key,first).lease;
    for(std::uint64_t i=2;i<=4;++i){auto candidate=make_bundle();cache.offer(make_key(i),candidate);}
    auto changed=key;++changed.ticket.geometry;auto replacement=make_bundle();auto current=cache.offer(changed,replacement).lease;
    require(bool(current) && !replacement,"new same-setup revision admitted by evicting an unborrowed LRU");
    require(cache.totals().live.entries==4 && cache.totals().retired_borrowed==1,"old same-setup borrower charged once");
    require(!cache.lookup(key).lease && bool(cache.lookup(changed).lease),"only current same-setup key resident");
    old.reset();current.reset();cache.shutdown();require(cache.totals().live.entries==0,"shutdown releases unborrowed numerical data");
    require(!cache.lookup(changed).lease,"shutdown disables future lookup");
}
void test_lease_after_service() {
    static_assert(!std::is_convertible_v<cd::GeometryLease,std::shared_ptr<const cd::detail::CacheEntry>>);
    static_assert(!std::is_constructible_v<std::weak_ptr<const cd::detail::CacheEntry>,cd::GeometryLease>);
    const auto before=live_allocations;
    {
        cd::GeometryLease survivor;
        {cd::GeometryCache cache;auto candidate=make_bundle();survivor=cache.offer(make_key(),candidate).lease;}
        require(survivor.get().query.diagnostics().triangles==2,"numeric lease outlives service without a Document");
        survivor.reset();
    }
    require(live_allocations==before,"all query/cache/key/control allocations released after final lease");
}
int main() {
    const std::pair<const char*,void(*)()> tests[]={{"epoch overflow fail closed",test_epoch},{"fieldwise exact input keys",test_keys},
        {"raw observation immutability and accounting",test_raw_and_live_totals},{"optional allocation failure",test_optional_failure},
        {"retention admission caps",test_limits},{"global pinned/retired aggregate",test_pinned_aggregate},
        {"pinned same-setup replacement",test_pinned_replacement},{"opaque lease outlives service",test_lease_after_service}};
    int failed=0;
    for(const auto& test:tests)try{test.second();std::printf("PASS %s\n",test.first);}catch(const std::exception& error){++failed;std::printf("FAIL %s: %s\n",test.first,error.what());}
    std::printf("SUMMARY %zu suites, %d failed; no host qualification\n",std::size(tests),failed);
    return failed?1:0;
}
