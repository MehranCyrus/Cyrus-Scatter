#pragma once
#include <array>
#include <cstddef>
#include <cstdint>
#include <memory>
#include <string>
#include <string_view>
#include <vector>
#include "placement_binding.h"

namespace cyrus::placements {
constexpr std::size_t maxRecords=1000000,maxSources=1024,maxPage=500,maxIdentity=256;
enum class Stage : std::uint8_t { Candidates, Edited };
enum Flag : std::uint32_t { Authored=1, Protected=2 };

// Exact Float32 boundaries of the existing Matrix3/Point3 row transport. No
// host pointers, vtables, strings or redundant double solver scratch per plant.
struct Record {
    std::array<float,12> transform{};
    std::array<float,3> bary{1,0,0};
    std::uint32_t source=1,face=1,receiver=0;
    std::uint64_t identity=0,band=0;
    std::uint32_t flags=0,reserved=0;
};
static_assert(sizeof(Record)==96,"Review placement layout/accounting before changing it");
struct Token {
    std::uint64_t owner=0,generation=0,view=0;
    bool operator==(const Token& b) const noexcept {return owner==b.owner&&generation==b.generation&&view==b.view;}
};
struct Metrics {
    // Requested live vector storage only, including builders and views. Object,
    // shared_ptr control blocks, source/publication metadata and allocator
    // headers are deliberately separate.
    std::uint64_t liveBytes=0,peakBytes=0,totalBytes=0,allocations=0,liveAllocations=0,
        liveStores=0,liveSelections=0,readbackRows=0;
};
Metrics metrics() noexcept;
void noteReadback(std::size_t) noexcept; // Once per explicit bounded host page.
std::uint64_t newOwner(); // Session-local, never serialized or reused.

class Builder;
struct PreparationReceipt {
    const std::string key,binding;
    PreparationReceipt(const std::string& k,const std::string& b):key(k),binding(b){}
};
class View {
    struct Data;
    struct Selection;
    std::shared_ptr<const Data> data_;
    std::shared_ptr<const Selection> selection_;
    Stage stage_{};
    std::uint64_t view_=0;
    std::shared_ptr<const PreparationReceipt> preparation_;
    View(std::shared_ptr<const Data>,std::shared_ptr<const Selection> = {});
    std::size_t physical(std::size_t) const;
    void valid() const;
    friend class Builder;
public:
    // Copying a view pins the same immutable generation, not its row payload.
    View(const View&)=default;View(View&&) noexcept=default;
    View& operator=(const View&)=default;View& operator=(View&&) noexcept=default;
    std::size_t size() const;
    Stage stage() const;
    std::uint32_t sources() const;
    const std::shared_ptr<const SourceCohort>& sourceCohort() const;
    const std::shared_ptr<const ReceiverCohort>& receiverCohort() const;
    const std::shared_ptr<const PreparationReceipt>& preparation() const{return preparation_;}
    Token token() const;
    void require(Token) const; // Wrong owner, generation or selection is stale.
    const Record& at(std::size_t) const;
    std::string_view authored(std::size_t) const;
    std::string textIdentity(std::size_t) const; // Explicit boundary/readback only.
    std::size_t baseBytes() const;
    std::size_t selectionBytes() const;
    std::vector<std::uint32_t> sourceUsage() const;
    std::vector<Record> page(std::size_t offset,std::size_t count,Token) const;
    // Arbitrary unique order, flattened directly to the base; no view chains.
    View select(const std::vector<std::uint32_t>&) const;
    // No-modifier identity normalization changes interpretation, not records.
    // It preserves the immutable base and gives the view a distinct token.
    View edited() const;
    View prepared(const std::string& key,const std::string& binding) const;
    View compact() const;
};

class Builder {
    struct Impl;
    std::unique_ptr<Impl> impl_;
    void active() const;
public:
    Builder(std::uint64_t owner,Stage,std::uint32_t sources,std::size_t reserve=0,std::shared_ptr<const SourceCohort> = {},std::shared_ptr<const ReceiverCohort> = {});
    explicit Builder(const View&); // Private mutable successor; no shared writes.
    ~Builder();
    Builder(Builder&&) noexcept;Builder& operator=(Builder&&) noexcept;
    Builder(const Builder&)=delete;Builder& operator=(const Builder&)=delete;
    std::size_t size() const;
    Record get(std::size_t) const; // By value: no mutable alias can escape freeze.
    void appendGenerated(Record);
    void appendAuthored(Record,std::string_view);
    void replace(std::size_t,Record); // Existing identity table only.
    View freeze(); // Consumes the builder; every later mutation is rejected.
};
}
