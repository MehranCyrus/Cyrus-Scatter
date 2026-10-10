#include "receiver_plan.h"
#include <algorithm>
#include <cmath>
#include <map>
#include <numeric>
#include <set>
#include <stdexcept>

namespace cyrus::receivers {
namespace {
void require(bool value,const char* message){if(!value)throw std::invalid_argument(message);}
std::vector<unsigned> apportion(const std::vector<double>& weights,unsigned count){
    std::vector<unsigned> result(weights.size());
    const double sum=std::accumulate(weights.begin(),weights.end(),0.0);
    require(std::isfinite(sum),"Receiver area overflow");
    if(sum==0||count==0)return result;
    std::vector<std::pair<double,std::size_t>> remainders;unsigned used=0;
    for(std::size_t i=0;i<weights.size();++i){const double q=weights[i]/sum*count;
        result[i]=static_cast<unsigned>(std::floor(q));used+=result[i];remainders.emplace_back(q-result[i],i);}
    std::stable_sort(remainders.begin(),remainders.end(),[](const auto& a,const auto& b){return a.first>b.first;});
    require(used<=count&&count-used<=result.size(),"Invalid receiver apportionment");
    for(unsigned i=0;i<count-used;++i)++result[remainders[i].second];
    return result;
}
constexpr const char* separator="\nCyrusReceivers2\n";
struct Binding {std::string common;std::map<std::string,std::string> receivers;};
Binding parse(const std::string& text){
    const auto at=text.find(separator);require(at!=std::string::npos,"Receiver binding version changed; reset old instance edits/overrides explicitly");
    Binding result{text.substr(0,at),{}};auto start=at+std::char_traits<char>::length(separator);
    while(start<text.size()) {auto end=text.find('\n',start);if(end==std::string::npos)end=text.size();const auto row=text.substr(start,end-start);const auto split=row.find('=');
        require(split!=std::string::npos&&split>0&&split+1<row.size(),"Invalid receiver binding receipt");
        require(result.receivers.emplace(row.substr(0,split),row.substr(split+1)).second,"Duplicate receiver binding");start=end+1;}
    return result;
}
}
std::uint64_t identity(unsigned slot,unsigned ordinal){
    require(slot<slots&&ordinal<limit,"Receiver candidate identity exceeds limits");return marker+std::uint64_t(slot)*stride+ordinal;
}
bool decode(std::uint64_t id,unsigned& slot,unsigned& ordinal){
    if(id<marker||id>=marker+std::uint64_t(slots)*stride)return false;
    slot=unsigned((id-marker)/stride);ordinal=unsigned((id-marker)%stride);return ordinal<limit;
}
std::uint64_t salt(const std::string& id){
    require(!id.empty()&&id.size()<=256,"Invalid persistent receiver identity");std::uint64_t value=1469598103934665603ULL;
    for(unsigned char c:id){value^=c;value*=1099511628211ULL;}return value;
}
Plan plan(std::vector<Input> input,unsigned total,double density,unsigned factor,unsigned densityCap){
    require(input.size()<=slots&&total<=limit&&densityCap<=limit&&std::isfinite(density)&&factor>=1&&factor<=32,"Invalid receiver plan limits");
    std::sort(input.begin(),input.end(),[](const auto& a,const auto& b){return a.slot<b.slot;});
    std::set<unsigned> used;std::set<std::string> ids;std::vector<double> weights;double wanted=0;
    for(const auto& r:input){require(r.slot<slots&&used.insert(r.slot).second&&!r.id.empty()&&ids.insert(r.id).second,"Duplicate receiver identity");
        require(std::isfinite(r.area)&&r.area>0&&r.required<=limit,"Receiver needs positive finite surface area and bounded Edit requirements");
        const double weight=density<0?r.area:std::floor(r.area*density+0.5);
        require(std::isfinite(weight),"Receiver density overflow");weights.push_back(weight);wanted+=weight;}
    require(std::isfinite(wanted),"Receiver density overflow");Plan out;out.capped=density>=0&&wanted>densityCap;
    auto budgets=apportion(weights,density<0?total:unsigned(std::min<double>(densityCap,wanted)));
    // Below the cap integer receiver quotas are independent of all other receivers.
    if(density>=0&&!out.capped)for(std::size_t i=0;i<input.size();++i)budgets[i]=unsigned(weights[i]);
    const auto budget=std::accumulate(budgets.begin(),budgets.end(),0u);
    std::vector<double> attemptWeights;for(auto b:budgets)attemptWeights.push_back(b);
    const auto attempts=apportion(attemptWeights,std::min(limit,budget*factor));
    std::size_t pool=0;
    for(std::size_t i=0;i<input.size();++i){const unsigned count=std::max(attempts[i],input[i].required);
        out.receivers.push_back({input[i].slot,budgets[i],attempts[i],count});pool+=count;}
    require(pool<=limit,"Receiver candidate admission exceeds 100000 including protected edits");
    // Initial quotas first, then refill capacity, then protected-only suffix.
    // Stable receiver slot order means appending a surface cannot change the
    // relative collision priority of existing candidates within each phase.
    for(unsigned phase=0;phase<3;++phase)for(const auto& r:out.receivers){
        const unsigned begin=phase==0?0:phase==1?r.budget:r.attempts;
        const unsigned end=phase==0?r.budget:phase==1?r.attempts:r.pool;
        for(unsigned i=begin;i<end;++i)out.order.push_back(identity(r.slot,i));}
    out.budget=budget;out.attempts=std::accumulate(attempts.begin(),attempts.end(),0u);return out;
}
std::string mergeBinding(const std::string& previous,const std::string& current){
    if(previous.empty())return current;
    auto a=parse(previous);const auto b=parse(current);require(a.common==b.common,"Generation settings changed; restore the recipe or explicitly reset instance edits/overrides");
    for(const auto& item:b.receivers){const auto old=a.receivers.find(item.first);
        require(old==a.receivers.end()||old->second==item.second,"Bound receiver geometry changed; restore it or explicitly reset instance edits/overrides");a.receivers[item.first]=item.second;}
    std::string result=a.common+separator;for(const auto& item:a.receivers)result+=item.first+"="+item.second+"\n";return result;
}
}
