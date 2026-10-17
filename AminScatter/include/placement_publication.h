#pragma once
#include "placement_store.h"
#include "script_buffers.h"
#include <array>

namespace cyrus::placements {
struct PublicationRule {
    unsigned scope=0;
    std::string a,b;
    bool enabled=false,planar=false;
    double multiplier=0,gap=0;
};
struct PublicationHeader {
    std::uint64_t owner=0,epoch=0;
    std::int64_t time=0;
    double meters=1;
    std::string id,inputKey,script;
    std::vector<PublicationRule> rules;
};
struct PublishedPopulation {
    View rows;
    CyrusSharedRadii radii;
    std::shared_ptr<const SourceCohort> expectedSources;
    std::string id,parent,binding,preparationKey;
    unsigned layerOrder=0,setOrder=0,budget=0,attempts=0,pool=0,rounds=1;
    bool roundLimit=false;
    std::uint64_t salt=0;
    std::vector<ReceiverBinding> receivers;
    std::vector<std::uint32_t> sourceCounts; // Derived once at freeze, never a UI scan.
    std::array<std::uint64_t,12> statistics{};
    std::array<std::int64_t,3> surfaceStatistics{};
    PublishedPopulation(View value,CyrusSharedRadii radius,std::shared_ptr<const SourceCohort> sources)
        :rows(std::move(value)),radii(std::move(radius)),expectedSources(std::move(sources)){}
};
// One immutable result. Construction validates the whole successor, then owns
// shared placement/radius storage and copied bounded correspondence/metadata.
// It does not install scene state or call Max from a destructor or worker.
class Publication {
    const PublicationHeader header_;
    const std::vector<PublishedPopulation> populations_;
    const std::size_t size_;
    Publication(const PublicationHeader&,std::vector<PublishedPopulation>&&,std::size_t);
public:
    static std::shared_ptr<const Publication> create(const PublicationHeader&,const std::vector<PublishedPopulation>&,const std::shared_ptr<const Publication>& previous={});
    const PublicationHeader& header() const noexcept{return header_;}
    const std::vector<PublishedPopulation>& populations() const noexcept{return populations_;}
    std::size_t size() const noexcept{return size_;}
};
}
