#include "placement_publication.h"
#include "receiver_plan.h"
#include <algorithm>
#include <charconv>
#include <cmath>
#include <limits>
#include <map>
#include <set>
#include <stdexcept>
#include <tuple>

namespace cyrus::placements {
namespace {
void require(bool value,const char* message){if(!value)throw std::invalid_argument(message);}
void key(const std::string& value){require(!value.empty()&&value.size()<=maxIdentity&&value.find('\0')==std::string::npos,"Invalid publication identity/revision");}
void metadata(const std::string& value,std::size_t& bytes){
    constexpr std::size_t maximum=32u*1024*1024;
    require(value.size()<=maximum-bytes,"Publication metadata exceeds 32 MiB");bytes+=value.size();
}
}
Publication::Publication(const PublicationHeader& header,std::vector<PublishedPopulation>&& populations,std::size_t size)
    :header_(header),populations_(std::move(populations)),size_(size){}
std::shared_ptr<const Publication> Publication::create(const PublicationHeader& header,const std::vector<PublishedPopulation>& populations,const std::shared_ptr<const Publication>& previous){
    constexpr auto signedMaximum=std::uint64_t(std::numeric_limits<std::int64_t>::max());
    require(header.owner>0&&header.owner<=signedMaximum&&header.epoch>0&&header.epoch<=signedMaximum,"Invalid publication owner/epoch");key(header.id);
    require(!header.script.empty()&&header.script.size()<=1024&&std::isfinite(header.meters)&&header.meters>0,"Invalid publication units/script identity");
    require(!header.inputKey.empty()&&header.inputKey.size()<=8u*1024*1024,"Invalid publication input signature");
    if(previous)require(header.owner==previous->header().owner&&previous->header().epoch<signedMaximum&&header.epoch==previous->header().epoch+1&&header.id!=previous->header().id,"Publication successor owner/epoch/identity mismatch");
    require(populations.size()<=10&&header.rules.size()<=90,"Publication exceeds layer/population/rule bounds");
    std::size_t size=0,bytes=0,prepared=0;std::uint64_t visits=0;metadata(header.id,bytes);metadata(header.script,bytes);metadata(header.inputKey,bytes);
    std::set<std::string> identities;std::set<std::uint64_t> owners;
    std::map<std::string,unsigned> parents;std::map<unsigned,std::string> parentOrder;std::map<std::string,std::string> parentOf;
    std::set<std::pair<std::string,unsigned>> orders;
    std::vector<std::vector<std::uint32_t>> counts;counts.reserve(populations.size());
    for(const auto& p:populations){key(p.id);key(p.parent);metadata(p.id,bytes);metadata(p.parent,bytes);metadata(p.binding,bytes);metadata(p.preparationKey,bytes);
        require(identities.insert(p.id).second&&p.layerOrder>=1&&p.layerOrder<=10&&p.setOrder>=1&&p.setOrder<=10&&orders.emplace(p.parent,p.setOrder).second,"Duplicate or invalid publication population/order");
        const auto inserted=parents.emplace(p.parent,p.layerOrder);require(inserted.second||inserted.first->second==p.layerOrder,"Inconsistent logical layer order");
        const auto ordered=parentOrder.emplace(p.layerOrder,p.parent);require(ordered.second||ordered.first->second==p.parent,"Logical layers share one order");parentOf.emplace(p.id,p.parent);
        require(p.rows.stage()==Stage::Edited&&p.rows.sourceCohort()&&p.expectedSources&&sameSourceCohort(p.rows.sourceCohort(),p.expectedSources)&&p.expectedSources->population()==p.id,"Publication source correspondence is missing, stale or belongs to another population");
        require(p.rows.preparation()&&p.rows.preparation()->key==p.preparationKey&&p.rows.preparation()->binding==p.binding,"Publication preparation receipt is missing or stale");
        require(owners.insert(p.rows.token().owner).second,"Distinct populations share a placement session owner");
        require(p.radii&&p.radii->size()==p.rows.size(),"Publication radii differ from accepted placements");
        counts.emplace_back(p.expectedSources->sources().size(),0);
        require(p.rows.size()<=maxRecords-size,"Publication exceeds one million placements");size+=p.rows.size();
        require(p.budget<=maxRecords&&p.attempts<=maxRecords&&p.attempts>=p.budget&&p.pool<=maxRecords&&p.rounds>=1&&p.rounds<=16,"Invalid publication allocation/rounds");
        require(p.statistics[1]==p.rows.size()&&p.statistics[0]>=p.rows.size(),"Publication statistics differ from accepted placements");
        for(auto count:p.statistics)require(count<=50000000,"Publication statistics exceed work bounds");
        require(p.statistics[0]<=maxRecords-prepared,"Publication prepared statistics exceed root admission");prepared+=p.statistics[0];
        require(p.statistics[11]<=50000000-visits,"Publication neighbor statistics exceed root work admission");visits+=p.statistics[11];
        require(p.statistics[2]<=p.statistics[1]&&p.statistics[3]<=p.statistics[2]&&p.statistics[9]>=p.budget&&p.statistics[9]<=p.attempts,"Publication protected/conflict/attempt statistics differ");
        require(p.statistics[1]+p.statistics[4]+p.statistics[5]+p.statistics[6]+p.statistics[7]+p.statistics[8]==p.statistics[0],"Publication reason statistics do not partition prepared inputs");
        if(p.statistics[10])require(p.rows.size()<p.budget&&p.statistics[10]==p.budget-p.rows.size(),"Publication shortfall differs from its target");
        for(std::size_t i=0;i<3;++i)require(p.surfaceStatistics[i]>=(i==0?-1:0)&&p.surfaceStatistics[i]<=std::int64_t(maxRecords),"Invalid frozen surface statistics");
        require(p.surfaceStatistics[0]<0?(p.surfaceStatistics[1]==0&&p.surfaceStatistics[2]==0):(p.surfaceStatistics[1]+p.surfaceStatistics[2]<=p.surfaceStatistics[0]),"Frozen surface statistics are inconsistent");
        for(const auto& source:p.expectedSources->sources())metadata(source.id,bytes);
        require(p.receivers.size()<=128,"Publication receiver count exceeds 128");std::map<unsigned,const ReceiverBinding*> receivers;std::set<std::string> receiverIDs;
        std::vector<std::pair<std::uint32_t,std::uint32_t>> ranges;
        for(const auto& r:p.receivers){key(r.id);key(r.revision);metadata(r.id,bytes);metadata(r.revision,bytes);
            require(r.slot<128&&r.handle>0&&r.handle<=signedMaximum&&r.begin<=10000000&&r.faces<=10000000-r.begin&&receivers.emplace(r.slot,&r).second&&receiverIDs.insert(r.id).second,"Invalid or duplicate publication receiver binding");
            if(r.faces)ranges.emplace_back(r.begin,r.begin+r.faces);
        }
        std::sort(ranges.begin(),ranges.end());for(std::size_t i=1;i<ranges.size();++i)require(ranges[i].first>=ranges[i-1].second,"Publication receiver face ranges overlap");
        std::map<unsigned,const ReceiverBinding*> provenance;
        if(p.rows.receiverCohort())for(const auto& r:p.rows.receiverCohort()->receivers()){
            const auto expected=receivers.find(r.slot);
            require(expected!=receivers.end()&&r==*expected->second,"Publication receiver identity, geometry revision or scene binding is stale");provenance.emplace(r.slot,&r);
        }
        std::uint64_t protectedCount=0;
        for(std::size_t i=0;i<p.rows.size();++i){const auto& row=p.rows.at(i);const auto radius=(*p.radii)[i];
            ++counts.back()[row.source-1];
            if(row.flags&Protected)++protectedCount;
            require(std::isfinite(radius[0])&&std::isfinite(radius[1])&&radius[0]>=0&&radius[1]>=0,"Invalid frozen publication radius");
            std::uint64_t candidate=row.identity;bool generated=!(row.flags&Authored);
            if(!generated){const auto id=p.rows.authored(i);
                if(id.substr(0,2)=="c:"){const auto parsed=std::from_chars(id.data()+2,id.data()+id.size(),candidate);
                    require(id.size()>2&&!(id.size()>3&&id[2]=='0')&&parsed.ec==std::errc{}&&parsed.ptr==id.data()+id.size(),"Invalid candidate-like publication identity");generated=true;}
                else require(row.flags&Protected,"Unprotected authored publication identity");
            }
            if(generated){unsigned slot=0;std::uint64_t local=0;require(candidate<=signedMaximum&&cyrus::receivers::decodeCandidate(candidate,slot,local)&&slot==row.receiver,"Publication candidate receiver mismatch");}
            // The existing surface-filter contract permits protected authored
            // changes to retain detached provenance; never reproject/drop them.
            if(!(row.flags&Protected)){const auto found=receivers.find(row.receiver);
                require(found!=receivers.end()&&provenance.count(row.receiver),"Publication candidate receiver provenance is missing");const auto& binding=*found->second;
                require(row.face>binding.begin&&row.face-binding.begin<=binding.faces,"Publication face belongs to another receiver");}
        }
        require(protectedCount==p.statistics[2],"Publication protected statistics differ from accepted rows");
    }
    std::set<std::tuple<unsigned,std::string,std::string>> rules;
    for(const auto& rule:header.rules){key(rule.a);key(rule.b);metadata(rule.a,bytes);metadata(rule.b,bytes);
        require((rule.scope==1||rule.scope==2)&&rule.a!=rule.b&&std::isfinite(rule.multiplier)&&rule.multiplier>=0&&std::isfinite(rule.gap)&&rule.gap>=0,"Invalid frozen publication rule");
        if(rule.scope==1)require(parentOf.count(rule.a)&&parentOf.count(rule.b)&&parentOf.at(rule.a)==parentOf.at(rule.b),"Publication sibling rule endpoints differ");
        else require(parents.count(rule.a)&&parents.count(rule.b),"Publication layer rule endpoint is missing");
        const auto pair=std::minmax(rule.a,rule.b);require(rules.emplace(rule.scope,pair.first,pair.second).second,"Duplicate frozen publication pair rule");
    }
    auto frozen=populations;for(std::size_t i=0;i<frozen.size();++i)frozen[i].sourceCounts=std::move(counts[i]);
    return std::shared_ptr<const Publication>(new Publication(header,std::move(frozen),size));
}
}
