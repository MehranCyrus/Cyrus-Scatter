#include "edit_binding.h"
#include "receiver_plan.h"
#include <array>
#include <charconv>
#include <cmath>
#include <limits>
#include <optional>
#include <stdexcept>

namespace cyrus::editbinding {
namespace {
constexpr std::string_view prefix="CyrusSourceBinding1\n",receiverSeparator="\nCyrusReceivers2\n";
constexpr std::string_view scalePrefix="CyrusSourceScaleSettings1\n";
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
double real(std::string_view text){
    double value=0;const auto result=std::from_chars(text.data(),text.data()+text.size(),value);
    require(!text.empty()&&result.ec==std::errc{}&&result.ptr==text.data()+text.size()&&std::isfinite(value),"Invalid source transform revision number");return value;
}
std::string scaleInvariant(const std::string& raw){
    // Exact known producer only: weight|color|empty|point|scale|z|forward|[Bands:...]
    // Do not infer mutability from arbitrary opaque strings such as a recipe's
    // custom labels. Preserve every byte outside the one scale field.
    std::array<std::string_view,7> values;std::size_t at=0,scaleBegin=0,scaleEnd=0;
    for(unsigned i=0;i<values.size();++i){const auto end=raw.find('|',at);require(end!=std::string::npos&&end>at,"Unknown source settings producer; restore its matching setup");
        values[i]=std::string_view(raw).substr(at,end-at);if(i==4){scaleBegin=at;scaleEnd=end;}at=end+1;}
    require(real(values[0])>=0&&!values[1].empty()&&(values[2]=="true"||values[2]=="false")&&(values[3]=="true"||values[3]=="false"),"Invalid source settings producer");
    require(real(values[4])>=0,"Invalid source scale revision");(void)real(values[5]);const auto forward=real(values[6]);require(forward>=1&&forward<=4&&forward==std::floor(forward),"Invalid source forward-axis revision");
    require(at==raw.size()||std::string_view(raw).substr(at).starts_with("Bands:"),"Unknown source settings suffix");
    return raw.substr(0,scaleBegin)+raw.substr(scaleEnd);
}
struct ScaleSettings {std::string raw;double modelScale;};
std::optional<ScaleSettings> scaleSettings(const std::string& value){
    if(!value.starts_with("CyrusSourceScaleSettings"))return {};
    require(value.starts_with(scalePrefix),"Unknown source scale settings version");Reader reader{std::string_view(value).substr(scalePrefix.size())};
    auto raw=reader.field(maxSettingsBytes);const auto scale=real(reader.field(64));require(reader.remaining.empty()&&scale>=0&&scale<=std::numeric_limits<float>::max(),"Invalid source scale settings");
    (void)scaleInvariant(raw);return ScaleSettings{std::move(raw),scale};
}
bool sameSourceSemantics(const std::string& previous,const std::string& current){
    if(previous==current)return true;const auto next=scaleSettings(current);if(!next)return false;
    const auto old=scaleSettings(previous);
    try{return scaleInvariant(old?old->raw:previous)==scaleInvariant(next->raw);}catch(const std::invalid_argument&){return false;}
}
void validate(const Descriptor& value){
    receiverCanonical(value.legacy);receiverCanonical(value.basis);
    require(value.sources.size()<=maxSources,"Source binding historical inventory exceeds 4096 roles");
    for(const auto& [id,settings]:value.sources){text(id,maxIdentityBytes);text(settings,maxSettingsBytes);(void)scaleSettings(settings);}
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
std::string editableScaleSettings(const std::string& legacySettings,double modelScale){
    text(legacySettings,maxSettingsBytes);(void)scaleInvariant(legacySettings);
    require(std::isfinite(modelScale)&&modelScale>=0&&modelScale<=std::numeric_limits<float>::max(),"Invalid editable model scale");
    char digits[64];const auto converted=std::to_chars(digits,digits+sizeof(digits),modelScale,std::chars_format::general,std::numeric_limits<double>::max_digits10);
    require(converted.ec==std::errc{},"Cannot encode editable model scale");std::string result(scalePrefix);field(result,legacySettings);field(result,std::string(digits,converted.ptr));
    text(result,maxSettingsBytes);return result;
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
        require(old==result.sources.end()||sameSourceSemantics(old->second,settings),"A retained source's generation settings changed; restore that source's matching setup");
        if(old==result.sources.end())result.sources.emplace(id,settings);else old->second=settings;
    }
    // Keep the original proof for unresolved legacy records. Once source-aware,
    // only the basis/receiver/history maps decide compatibility, never legacy
    // source-array membership. Encoding also enforces the aggregate bound.
    (void)encode(result);return {std::move(result),false};
}
const std::string* sourceRevision(const Descriptor& descriptor,const std::string& id) noexcept{
    const auto found=descriptor.sources.find(id);return found==descriptor.sources.end()?nullptr:&found->second;
}
Merge mergePinned(const std::string& previous,const std::string& current){
    if(previous.empty()||!isSourceAware(previous))return merge(previous,current);
    auto old=parse(previous),next=parse(current);
    const auto owner=[](const std::string& basis){
        const auto end=basis.find(receiverSeparator),begin=basis.find("|EditOwner:");
        require(begin!=std::string::npos&&begin<end,"Pinned Edit requires its source-aware layer owner");
        const auto stop=basis.find('|',begin+1);
        require(stop!=std::string::npos&&stop<end&&stop>begin+11,"Invalid pinned Edit owner");
        return basis.substr(begin,stop-begin);
    };
    require(owner(old.basis)==owner(next.basis),"Pinned Edit belongs to another layer");
    const auto previousReceivers=old.basis.substr(old.basis.find(receiverSeparator));
    const auto common=next.basis.substr(0,next.basis.find(receiverSeparator));
    next.basis=receivers::mergeBinding(common+previousReceivers,next.basis);
    next.legacy=old.legacy;
    for(const auto& [id,revision]:old.sources)if(!next.sources.count(id))next.sources.emplace(id,revision);
    (void)encode(next);return {std::move(next),false};
}
}
