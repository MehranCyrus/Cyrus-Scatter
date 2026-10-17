#pragma once
#include <cstdint>
#include <memory>
#include <string>
#include <vector>

namespace cyrus::placements {
enum SourceFlag : std::uint32_t { RenderSource=1,PointSource=2,EmptySource=4 };
struct SourceBinding {
    std::string id;
    std::uint64_t handle=0;
    std::uint32_t flags=0;
    bool operator==(const SourceBinding& other) const{return id==other.id&&handle==other.handle&&flags==other.flags;}
};
// Small immutable, host-pointer-free correspondence. Source ordinals address
// this exact ordered table, never a later validSources() list of equal length.
class SourceCohort {
    const std::uint64_t owner_,generation_;
    const std::string population_;
    const std::vector<SourceBinding> sources_;
    SourceCohort(std::uint64_t,const std::string&,const std::vector<SourceBinding>&);
public:
    // Copies bounded metadata so no caller's mutable vector/string alias escapes.
    static std::shared_ptr<const SourceCohort> create(std::uint64_t owner,const std::string& population,const std::vector<SourceBinding>&);
    std::uint64_t owner() const noexcept{return owner_;}
    std::uint64_t generation() const noexcept{return generation_;}
    const std::string& population() const noexcept{return population_;}
    const std::vector<SourceBinding>& sources() const noexcept{return sources_;}
    bool equivalent(const SourceCohort&) const;
};
bool sameSourceCohort(const std::shared_ptr<const SourceCohort>&,const std::shared_ptr<const SourceCohort>&);
struct ReceiverBinding {
    std::uint32_t slot=0,begin=0,faces=0;
    std::string id,revision;
    std::uint64_t handle=0;
    bool operator==(const ReceiverBinding& b) const{return slot==b.slot&&begin==b.begin&&faces==b.faces&&id==b.id&&revision==b.revision&&handle==b.handle;}
};
// Provenance is captured from the evaluated mesh actually used by generation.
// It follows immutable transforms/selections; caller metadata cannot replace it.
class ReceiverCohort {
    const std::uint64_t owner_;
    const std::vector<ReceiverBinding> receivers_;
    ReceiverCohort(std::uint64_t,const std::vector<ReceiverBinding>&);
public:
    static std::shared_ptr<const ReceiverCohort> create(std::uint64_t,const std::vector<ReceiverBinding>&);
    static std::shared_ptr<const ReceiverCohort> merge(std::uint64_t,const std::vector<std::shared_ptr<const ReceiverCohort>>&);
    std::shared_ptr<const ReceiverCohort> offset(std::uint32_t) const;
    std::uint64_t owner() const noexcept{return owner_;}
    const std::vector<ReceiverBinding>& receivers() const noexcept{return receivers_;}
};
}
