#include "edit_binding.h"
#include "receiver_plan.h"
#include <charconv>
#include <stdexcept>

namespace cyrus::editbinding {
namespace {
constexpr std::string_view prefix="CyrusSourceBinding1\n",receiverSeparator="\nCyrusReceivers2\n";
void require(bool value,const char* message){if(!value)throw std::invalid_argument(message);}
void text(const std::string& value,std::size_t maximum,bool empty=false){
    require((empty||!value.empty())&&value.size()<=maximum&&value.find('\0')==std::string::npos,"Invalid or oversized source binding text");
}
std::string receiverCanonical(const std::string& value){
    text(value,maxSignatureBytes);
    require(value.starts_with("CyrusBinding2:"),"Source binding needs the supported CyrusBinding2 generation; restore the matching setup");
    const auto at=value.find(receiverSeparator);
    require(at!=std::string::npos&&value.find(receiverSeparator,at+receiverSeparator.size())==std::string::npos,"Invalid source binding receiver section");
    return receivers::mergeBinding(value,value);
}
void append(std::string& result,std::string_view value){
    require(value.size()<=maxDescriptorBytes-result.size(),"Source binding exceeds its saved descriptor allowance");result.append(value);
}
void field(std::string& result,const std::string& value){append(result,std::to_string(value.size()));append(result,"\n");append(result,value);append(result,"\n");}
struct Reader {
    std::string_view remaining;
    std::size_t number(std::size_t maximum){
        const auto end=remaining.find('\n');require(end!=std::string_view::npos&&end>0&&end<=20,"Invalid source binding length");
        const auto number=remaining.substr(0,end);require(number.size()==1||number.front()!='0',"Noncanonical source binding length");
        std::size_t result=0;const auto parsed=std::from_chars(number.data(),number.data()+number.size(),result);
        require(parsed.ec==std::errc{}&&parsed.ptr==number.data()+number.size()&&result<=maximum,"Source binding count exceeds its allowance");
        remaining.remove_prefix(end+1);return result;
    }
    std::string field(std::size_t maximum){
        const auto length=number(maximum);require(length<remaining.size()&&remaining[length]=='\n',"Truncated source binding field");
        std::string result(remaining.substr(0,length));remaining.remove_prefix(length+1);text(result,maximum,true);return result;
    }
};
void validate(const Descriptor& value){
    receiverCanonical(value.legacy);receiverCanonical(value.basis);
    require(value.sources.size()<=maxSources,"Source binding historical inventory exceeds 4096 roles");
    for(const auto& [id,settings]:value.sources){text(id,maxIdentityBytes);text(settings,maxSettingsBytes);}
}
}
bool isSourceAware(std::string_view value) noexcept{return value.starts_with("CyrusSourceBinding");}
Descriptor parse(const std::string& value){
    text(value,maxDescriptorBytes);require(value.starts_with(prefix),"Unknown source binding version; preserve this setup and use its matching plugin");
    Reader reader{std::string_view(value).substr(prefix.size())};Descriptor result;
    result.legacy=reader.field(maxSignatureBytes);result.basis=reader.field(maxSignatureBytes);
    const auto count=reader.number(maxSources);
    require(count<=reader.remaining.size()/8,"Truncated source inventory");
    for(std::size_t i=0;i<count;++i){auto id=reader.field(maxIdentityBytes);auto settings=reader.field(maxSettingsBytes);
        require(result.sources.emplace(std::move(id),std::move(settings)).second,"Duplicate source role in binding");}
    require(reader.remaining.empty(),"Trailing source binding data");validate(result);return result;
}
std::string encode(const Descriptor& value){
    validate(value);std::string result(prefix);field(result,value.legacy);field(result,value.basis);
    append(result,std::to_string(value.sources.size()));append(result,"\n");
    for(const auto& [id,settings]:value.sources){field(result,id);field(result,settings);}return result;
}
std::string make(const std::string& legacy,const std::string& basis,const std::vector<SourceSpec>& sources){
    require(sources.size()<=maxActiveSources,"Source binding active inventory exceeds 1024 roles");
    const auto old=receiverCanonical(legacy),current=receiverCanonical(basis);
    require(old.substr(old.find(receiverSeparator))==current.substr(current.find(receiverSeparator)),"Source binding basis and legacy proof describe different receiver geometry");
    Descriptor result{legacy,basis,{}};std::size_t bytes=legacy.size()+basis.size();
    for(const auto& source:sources){text(source.id,maxIdentityBytes);text(source.settings,maxSettingsBytes);
        require(source.id.size()+source.settings.size()<=maxDescriptorBytes-bytes,"Source binding exceeds its saved descriptor allowance");bytes+=source.id.size()+source.settings.size();
        require(result.sources.emplace(source.id,source.settings).second,"Duplicate source role in binding");}
    return encode(result);
}
Merge merge(const std::string& previous,const std::string& current){
    auto next=parse(current);if(previous.empty())return {std::move(next),false};
    if(!isSourceAware(previous)){
        // This is the old exact common signature guard, including source
        // membership/settings. Receiver additions/removals keep their existing
        // rules; missing receiver revisions remain remembered after hydration.
        receiverCanonical(previous);const auto proof=receivers::mergeBinding(previous,next.legacy);
        next.basis=next.basis.substr(0,next.basis.find(receiverSeparator))+proof.substr(proof.find(receiverSeparator));
        next.legacy=previous;validate(next);return {std::move(next),true};
    }
    auto result=parse(previous);result.basis=receivers::mergeBinding(result.basis,next.basis);
    for(const auto& [id,settings]:next.sources){const auto old=result.sources.find(id);
        require(old==result.sources.end()||old->second==settings,"A retained source's generation settings changed; restore that source's matching setup");
        result.sources.emplace(id,settings);
    }
    // Keep the original proof for unresolved legacy records. Once source-aware,
    // only the basis/receiver/history maps decide compatibility, never legacy
    // source-array membership. Encoding also enforces the aggregate bound.
    (void)encode(result);return {std::move(result),false};
}
const std::string* sourceRevision(const Descriptor& descriptor,const std::string& id) noexcept{
    const auto found=descriptor.sources.find(id);return found==descriptor.sources.end()?nullptr:&found->second;
}
}
