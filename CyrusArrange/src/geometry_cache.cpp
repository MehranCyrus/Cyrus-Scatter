#include "cyrus_arrange/geometry_cache.h"
#include "geometry_cache_accounting.h"
#include <algorithm>
#include <cassert>

namespace cyrus::arrange::cache {
namespace detail {
struct Ledger {
    Footprint live, peak;
    Limits limits;
    void charge(const Footprint& f) noexcept {
        assert(can_add(live,f,limits));
        live.entries+=f.entries;live.bytes+=f.bytes;live.triangles+=f.triangles;live.cells+=f.cells;
        peak.entries=std::max(peak.entries,live.entries);peak.bytes=std::max(peak.bytes,live.bytes);
        peak.triangles=std::max(peak.triangles,live.triangles);peak.cells=std::max(peak.cells,live.cells);
    }
    void release(const Footprint& f) noexcept {
        assert(f.entries<=live.entries && f.bytes<=live.bytes && f.triangles<=live.triangles && f.cells<=live.cells);
        live.entries-=f.entries;live.bytes-=f.bytes;live.triangles-=f.triangles;live.cells-=f.cells;
    }
};
struct CacheEntry {
    GeometryKey key;
    std::optional<GeometryBundle> bundle; // Inline wrapper, no extra essential cold-path allocation.
    std::shared_ptr<Ledger> ledger;
    Footprint charged;
    bool accounted{};
    explicit CacheEntry(const GeometryKey& source):key(source) {} // Copy may throw BEFORE candidate transfer.
    ~CacheEntry() noexcept {
        // Release numeric buffers before reducing budget. These destructors must
        // stay numeric-only and non-reentrant: no Max objects/materials/callbacks.
        bundle.reset();key=GeometryKey{};
        if(accounted)ledger->release(charged);
    }
};

}
using detail::Ledger;
using detail::AllocationCounter;
using detail::CacheEntry;
using detail::CountedAllocator;
using detail::raw_dynamic_bytes;
using detail::key_dynamic_bytes;
GeometryCache::GeometryCache(Limits limits):ledger_(std::make_shared<detail::Ledger>()),metadata_(std::make_shared<detail::AllocationCounter>()) {
    const Limits hard;
    if(limits.entries>hard.entries || limits.bytes>hard.bytes || limits.triangles>hard.triangles || limits.cells>hard.cells)
        throw std::invalid_argument("Cache retention limits may only be lowered.");
    ledger_->limits=limits;
}
GeometryCache::~GeometryCache()=default;
GeometryLease::GeometryLease(std::shared_ptr<const detail::CacheEntry> entry) noexcept:entry_(std::move(entry)) {}
const GeometryBundle& GeometryLease::get() const {
    if(!entry_ || !entry_->bundle)throw std::logic_error("Missing cache lease payload.");
    return *entry_->bundle;
}
void GeometryCache::touch(Slot& slot) noexcept {
        // Saturation only affects eviction preference, never data eligibility.
        if(clock_!=std::numeric_limits<std::uint64_t>::max())++clock_;
        slot.touched=clock_;
    }

int GeometryCache::resident_for(std::uint64_t document) const noexcept {
        for(int i=0;i<4;++i)if(slots_[i].entry && slots_[i].entry->key.ticket.document_instance==document)return i;
        return -1;
    }

int GeometryCache::free_slot() const noexcept {
        for(int i=0;i<4;++i)if(!slots_[i].entry)return i;
        return -1;
    }

int GeometryCache::victim(std::uint64_t replacing_document) const noexcept {
        // Prefer the old same-setup entry; only evict entries whose resident slot
        // owns the sole shared reference, so their ledger charge really releases.
        const auto same=resident_for(replacing_document);
        if(same>=0 && slots_[same].entry.use_count()==1)return same;
        int chosen=-1;
        for(int i=0;i<4;++i)if(slots_[i].entry && slots_[i].entry.use_count()==1)
            if(chosen<0 || slots_[i].touched<slots_[chosen].touched)chosen=i;
        return chosen;
    }

void GeometryCache::subtract(Footprint& a,const Footprint& b) noexcept {
        assert(a.entries>=b.entries && a.bytes>=b.bytes && a.triangles>=b.triangles && a.cells>=b.cells);
        a.entries-=b.entries;a.bytes-=b.bytes;a.triangles-=b.triangles;a.cells-=b.cells;
    }

void GeometryCache::defer_document(std::uint64_t document) noexcept {
        for(auto& slot:slots_)if(slot.entry && slot.entry->key.ticket.document_instance==document)slot.stale=true;
    }

void GeometryCache::defer_all() noexcept { for(auto& slot:slots_)slot.stale=true; }

void GeometryCache::drain_deferred() noexcept {
        for(auto& slot:slots_)if(slot.stale){slot.entry.reset();slot.stale=false;slot.touched=0;}
    }

Lookup GeometryCache::lookup(const GeometryKey& key) noexcept {
        drain_deferred();
        if(!enabled_)return {{},Reason::Disabled};
        if(!eligible_key(key))return {{},Reason::InvalidKey};
        const auto index=resident_for(key.ticket.document_instance);
        if(index<0)return {{},Reason::Empty};
        auto& slot=slots_[index];
        const auto& previous=slot.entry->key;
        if(previous.ticket.scene!=key.ticket.scene)return {{},Reason::SceneChanged};
        if(previous.ticket.geometry!=key.ticket.geometry)return {{},Reason::DependencyChanged};
        if(previous.time!=key.time)return {{},Reason::TimeChanged};
        if(previous.mm_per_system_unit!=key.mm_per_system_unit)return {{},Reason::UnitsChanged};
        if(previous!=key || !slot.entry->bundle || !slot.entry->bundle->validity.contains(key.time))return {{},Reason::KeyChanged};
        touch(slot);return {GeometryLease(slot.entry),Reason::None};
    }

Offer GeometryCache::offer(const GeometryKey& key,std::optional<GeometryBundle>& candidate) noexcept {
        // Failure never moves/destroys candidate. Capture/query/solve errors are
        // outside this optional bookkeeping function and are NOT swallowed.
        if(!enabled_)return {{},Reason::Disabled};
        if(!candidate || !eligible_key(key) || !candidate->validity.contains(key.time))return {{},Reason::InvalidKey};
        if(!candidate->storage.complete || candidate->storage.bytes<candidate->storage.wrapper_bytes)
            return {{},Reason::AccountingUnavailable};
        try {
            const auto metadata_before=metadata_->live;
            auto entry=std::allocate_shared<CacheEntry>(CountedAllocator<CacheEntry>(metadata_),key);
            const auto metadata_bytes=metadata_->live-metadata_before; // Actual rebound request incl shared control/Entry.
            auto bytes=raw_dynamic_bytes(candidate->raw);
            const auto key_bytes=key_dynamic_bytes(entry->key);
            bytes.complete=bytes.complete && key_bytes.complete;
            bytes.add(key_bytes.bytes);bytes.add(metadata_bytes);
            // Entry's inline Bundle already contains query wrapper bytes.
            bytes.add(candidate->storage.bytes-candidate->storage.wrapper_bytes);
            std::size_t cells=0;
            for(const auto& region:candidate->raw.regions) {
                if(region.cells.size()>std::numeric_limits<std::size_t>::max()-cells)return {{},Reason::AccountingUnavailable};
                cells+=region.cells.size();
            }
            if(!bytes.complete)return {{},Reason::AccountingUnavailable};
            const Footprint next{1,bytes.bytes,candidate->storage.triangles,cells};
            if(!can_add({},next,ledger_->limits))return {{},Reason::TooLarge};
            // Preflight all potential reclamation before evicting anything. An
            // optional metadata/budget failure keeps existing useful residents.
            auto possible=ledger_->live;
            for(const auto& slot:slots_)if(slot.entry && slot.entry.use_count()==1)subtract(possible,slot.entry->charged);
            if(!can_add(possible,next,ledger_->limits))return {{},Reason::PinnedBudget};
            drain_deferred();
            while(!can_add(ledger_->live,next,ledger_->limits) ||
                  (free_slot()<0 && resident_for(key.ticket.document_instance)<0)) {
                const auto index=victim(key.ticket.document_instance);
                if(index<0)return {{},Reason::PinnedBudget}; // Defensive; preflight should make this unreachable.
                slots_[index].entry.reset();slots_[index].touched=0;
            }
            auto index=resident_for(key.ticket.document_instance);
            if(index<0)index=free_slot();
            if(index<0)return {{},Reason::PinnedBudget};
            entry->ledger=ledger_;entry->charged=next;
            // All potentially throwing work is complete. Transfer and publish
            // are noexcept; no live scene or authored state is modified.
            ledger_->charge(next);entry->accounted=true;
            entry->bundle.emplace(std::move(*candidate));candidate.reset();
            slots_[index].entry=entry;slots_[index].stale=false;touch(slots_[index]);
            return {GeometryLease(std::move(entry)),Reason::None};
        } catch(...) { return {{},Reason::MetadataAllocation}; }
    }

void GeometryCache::clear_document(std::uint64_t document) noexcept {defer_document(document);drain_deferred();}

void GeometryCache::clear_all() noexcept {defer_all();drain_deferred();}

void GeometryCache::shutdown() noexcept {enabled_=false;clear_all();}

CacheTotals GeometryCache::totals() const noexcept {
        CacheTotals out{ledger_->live,ledger_->peak,0,0,enabled_};
        for(const auto& slot:slots_)if(slot.entry)++out.resident;
        out.retired_borrowed=out.live.entries-out.resident;
        out.entry_metadata_requested_live_bytes=metadata_->live;
        out.entry_metadata_requested_peak_bytes=metadata_->peak;
        out.fixed_service_inline_bytes=sizeof(GeometryCache);
        out.fixed_control_object_bytes=sizeof(Ledger)+sizeof(AllocationCounter);
        return out;
    }
}
