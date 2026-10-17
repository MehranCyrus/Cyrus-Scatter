#include "placement_binding.h"
#include "placement_store.h"
#include <limits>
#include <algorithm>
#include <map>
#include <set>
#include <stdexcept>

namespace cyrus::placements {
namespace {
void require(bool value,const char* message){if(!value)throw std::invalid_argument(message);}
void key(const std::string& value){require(!value.empty()&&value.size()<=maxIdentity&&value.find('\0')==std::string::npos,"Source correspondence requires bounded nonempty stable keys");}
}
SourceCohort::SourceCohort(std::uint64_t owner,const std::string& population,const std::vector<SourceBinding>& sources)
    :owner_(owner),generation_(newOwner()),population_(population),sources_(sources){}
std::shared_ptr<const SourceCohort> SourceCohort::create(std::uint64_t owner,const std::string& population,const std::vector<SourceBinding>& sources){
    require(owner>0&&owner<=std::uint64_t(std::numeric_limits<std::int64_t>::max()),"Source correspondence requires its session owner");key(population);
    require(sources.size()<=maxSources,"Source correspondence exceeds 1024 entries");std::set<std::string> ids;
    for(const auto& source:sources){key(source.id);require(ids.insert(source.id).second,"Duplicate source role identity");
        require(source.handle<=std::uint64_t(std::numeric_limits<std::int64_t>::max())&&!(source.flags&~std::uint32_t(RenderSource|PointSource|EmptySource)),"Invalid source correspondence flags/handle");
        require(source.handle!=0||(source.flags&(PointSource|EmptySource)),"A model role has no scene binding");
    }
    return std::shared_ptr<const SourceCohort>(new SourceCohort(owner,population,sources));
}
bool SourceCohort::equivalent(const SourceCohort& other) const{return owner_==other.owner_&&population_==other.population_&&sources_==other.sources_;}
bool sameSourceCohort(const std::shared_ptr<const SourceCohort>& a,const std::shared_ptr<const SourceCohort>& b){return a==b||(a&&b&&a->equivalent(*b));}
ReceiverCohort::ReceiverCohort(std::uint64_t owner,const std::vector<ReceiverBinding>& receivers):owner_(owner),receivers_(receivers){}
std::shared_ptr<const ReceiverCohort> ReceiverCohort::create(std::uint64_t owner,const std::vector<ReceiverBinding>& receivers){
    require(owner>0&&owner<=std::uint64_t(std::numeric_limits<std::int64_t>::max()),"Receiver provenance requires its session owner");
    require(receivers.size()<=128,"Receiver provenance exceeds 128 receivers");std::set<unsigned> slots;std::set<std::string> ids;
    std::vector<std::pair<unsigned,unsigned>> ranges;
    for(const auto& r:receivers){key(r.id);key(r.revision);
        require(r.slot<128&&slots.insert(r.slot).second&&ids.insert(r.id).second&&r.handle>0&&r.handle<=std::uint64_t(std::numeric_limits<std::int64_t>::max()),"Invalid or duplicate receiver provenance");
        require(r.begin<=10000000&&r.faces<=10000000-r.begin,"Receiver provenance face range exceeds bounds");
        if(r.faces)ranges.emplace_back(r.begin,r.begin+r.faces);
    }
    std::sort(ranges.begin(),ranges.end());for(std::size_t i=1;i<ranges.size();++i)require(ranges[i].first>=ranges[i-1].second,"Receiver provenance face ranges overlap");
    return std::shared_ptr<const ReceiverCohort>(new ReceiverCohort(owner,receivers));
}
std::shared_ptr<const ReceiverCohort> ReceiverCohort::offset(std::uint32_t amount) const{
    auto entries=receivers_;for(auto& r:entries){require(amount<=10000000-r.begin-r.faces,"Receiver provenance offset exceeds bounds");r.begin+=amount;}
    return create(owner_,entries);
}
std::shared_ptr<const ReceiverCohort> ReceiverCohort::merge(std::uint64_t owner,const std::vector<std::shared_ptr<const ReceiverCohort>>& inputs){
    require(inputs.size()<=128,"Receiver provenance join exceeds bounds");std::map<unsigned,ReceiverBinding> entries;bool present=false,missing=false;
    for(const auto& input:inputs){if(!input){missing=true;continue;}present=true;require(input->owner()==owner,"Receiver provenance owner differs");
        for(const auto& r:input->receivers()){const auto added=entries.emplace(r.slot,r);require(added.second||added.first->second==r,"Receiver join mixes geometry revisions or bindings");}}
    require(!present||!missing,"Receiver join mixes bound and unbound inputs");if(!present)return {};
    std::vector<ReceiverBinding> result;for(const auto& entry:entries)result.push_back(entry.second);return create(owner,result);
}
}
