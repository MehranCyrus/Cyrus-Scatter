#include "source_radius.h"
#include <charconv>
#include <cmath>
#include <limits>
#include <map>
#include <set>
#include <stdexcept>
#include <unordered_map>

namespace cyrus::sourceradius {
namespace {
constexpr std::string_view prefix="CyrusSourceRadius1\n";
void require(bool value,const char* message){if(!value)throw std::invalid_argument(message);}
void identity(const std::string& text){require(!text.empty()&&text.size()<=placements::maxIdentity&&text.find('\0')==std::string::npos,"Invalid radius identity");}
bool candidate(std::string_view id,std::uint64_t& value){
    if(id.size()<3||id.substr(0,2)!="c:"||(id.size()>3&&id[2]=='0'))return false;
    const auto parsed=std::from_chars(id.data()+2,id.data()+id.size(),value);
    return parsed.ec==std::errc{}&&parsed.ptr==id.data()+id.size()&&value<=std::uint64_t(INT64_MAX);
}
struct Key {
    std::uint64_t candidate=0;std::string_view authored,source;
    bool operator==(const Key& other)const noexcept{return candidate==other.candidate&&authored==other.authored&&source==other.source;}
};
struct Hash {std::size_t operator()(const Key& key)const noexcept{
    auto result=std::hash<std::uint64_t>{}(key.candidate);
    result^=std::hash<std::string_view>{}(key.authored)+0x9e3779b9+(result<<6)+(result>>2);
    return result^(std::hash<std::string_view>{}(key.source)+0x9e3779b9+(result<<6)+(result>>2));
}};
Key key(std::string_view id,std::string_view source={}){std::uint64_t value=0;return candidate(id,value)?Key{value,{},source}:Key{0,id,source};}
Key key(const placements::View& view,std::size_t row,std::string_view source={}){
    const auto& record=view.at(row);return record.flags&placements::Authored?key(view.authored(row),source):Key{record.identity,{},source};
}
void viewMatches(const placements::View& view,const std::string& current,const editbinding::Descriptor& descriptor){
    require(view.stage()==placements::Stage::Edited&&view.sourceCohort(),"Source-aware radii require edited native rows with their immutable source correspondence");
    // An inactive empty population may have the controller's Inactive receipt.
    // It cannot replay an override. Nonempty inputs must prove their generation.
    if(view.size()==0)return;
    require(view.preparation()&&view.preparation()->binding==current,"Radius lineage requires the exact prepared generation; restore or update the matching setup");
    const auto& sources=view.sourceCohort()->sources();require(sources.size()==descriptor.sources.size(),"Radius source inventory differs from its prepared binding");
    for(const auto& source:sources)require(editbinding::sourceRevision(descriptor,source.id)!=nullptr,"Radius source role is missing from its prepared binding");
}
std::vector<std::string> capture(const placements::View& view,const std::vector<std::string>& ids){
    require(ids.size()<=maxOverrides,"Radius selection exceeds one million identities");
    std::unordered_map<Key,std::size_t,Hash> wanted;wanted.reserve(ids.size());
    for(std::size_t i=0;i<ids.size();++i){identity(ids[i]);require(wanted.emplace(key(ids[i]),i).second,"Duplicate radius command identity");}
    std::vector<std::string> result(ids.size());const auto& sources=view.sourceCohort()->sources();
    for(std::size_t row=0;row<view.size();++row){const auto found=wanted.find(key(view,row));if(found==wanted.end())continue;
        const auto source=view.at(row).source;require(source>0&&source<=sources.size(),"Invalid radius source ordinal");
        auto& entry=result[found->second];require(entry.empty(),"Ambiguous radius identity in native placement input");entry=sources[source-1].id;
    }
    for(const auto& source:result)require(!source.empty(),"A legacy or selected radius identity is absent from its matching generation; restore that setup before changing sources or radii");
    return result;
}
void validate(const Binding& binding){
    require(binding.entries.size()<=maxOverrides,"Saved radius history exceeds one million overrides");
    std::unordered_map<Key,bool,Hash> keys;keys.reserve(binding.entries.size());
    for(const auto& entry:binding.entries){identity(entry.id);identity(entry.source);
        require(editbinding::sourceRevision(binding.generation,entry.source)!=nullptr,"Radius history refers to an unknown source role");
        require(keys.emplace(key(entry.id,entry.source),true).second,"Duplicate candidate/source radius override");}
}
void append(std::string& result,std::string_view value){require(value.size()<=maxBindingBytes-result.size(),"Saved radius binding exceeds 64 MiB");result.append(value);}
void field(std::string& result,const std::string& value){append(result,std::to_string(value.size()));append(result,"\n");append(result,value);append(result,"\n");}
struct Reader {
    std::string_view remaining;
    std::size_t number(std::size_t maximum){const auto end=remaining.find('\n');require(end!=std::string_view::npos&&end>0&&end<=20,"Invalid radius binding length");
        const auto value=remaining.substr(0,end);require(value.size()==1||value.front()!='0',"Noncanonical radius binding length");std::size_t result=0;
        const auto parsed=std::from_chars(value.data(),value.data()+value.size(),result);
        require(parsed.ec==std::errc{}&&parsed.ptr==value.data()+value.size()&&result<=maximum,"Radius binding length exceeds its allowance");remaining.remove_prefix(end+1);return result;}
    std::string field(std::size_t maximum){const auto size=number(maximum);require(size<remaining.size()&&remaining[size]=='\n',"Truncated radius binding field");
        std::string result(remaining.substr(0,size));require(result.find('\0')==std::string::npos,"Radius binding contains NUL");remaining.remove_prefix(size+1);return result;}
};
}
bool isSourceAware(std::string_view value) noexcept{return value.starts_with("CyrusSourceRadius");}
Binding parse(const std::string& value){
    require(value.size()<=maxBindingBytes&&value.starts_with(prefix),"Unknown or oversized source radius binding; preserve this setup and use its matching plugin");
    Reader reader{std::string_view(value).substr(prefix.size())};Binding result;result.generation=editbinding::parse(reader.field(editbinding::maxDescriptorBytes));
    const auto count=reader.number(maxOverrides);require(count<=reader.remaining.size()/8,"Truncated radius history");result.entries.reserve(count);
    for(std::size_t i=0;i<count;++i){auto id=reader.field(placements::maxIdentity);auto source=reader.field(placements::maxIdentity);result.entries.push_back({std::move(id),std::move(source)});}
    require(reader.remaining.empty(),"Trailing radius binding data");validate(result);return result;
}
std::string encode(const Binding& value){
    validate(value);std::string result(prefix);field(result,editbinding::encode(value.generation));append(result,std::to_string(value.entries.size()));append(result,"\n");
    for(const auto& entry:value.entries){field(result,entry.id);field(result,entry.source);}return result;
}
Binding bind(const placements::View& view,const std::string& current,const std::string& previous,const std::vector<std::string>& ids){
    require(ids.size()<=maxOverrides,"Radius history exceeds one million overrides");const auto descriptor=editbinding::parse(current);viewMatches(view,current,descriptor);
    if(isSourceAware(previous)){
        auto result=parse(previous);require(result.entries.size()==ids.size(),"Radius binding and saved override arrays differ");
        for(std::size_t i=0;i<ids.size();++i)require(ids[i]==result.entries[i].id,"Radius binding order differs from saved overrides");
        result.generation=editbinding::merge(editbinding::encode(result.generation),current).descriptor;return result;
    }
    require(ids.empty()||!previous.empty(),"Radius overrides have no generation binding; restore their matching setup or explicitly clear them");
    require(!editbinding::isSourceAware(previous),"Radius overrides have no proven source lineage; restore their original generation before changing sources");
    Binding result;result.generation=editbinding::merge(previous,current).descriptor;
    const auto sources=capture(view,ids);result.entries.reserve(ids.size());
    for(std::size_t i=0;i<ids.size();++i)result.entries.push_back({ids[i],sources[i]});return result;
}
Authored author(const placements::View& view,const std::string& current,const std::string& previous,
    const std::vector<std::string>& ids,const std::vector<int>& modes,const std::vector<double>& values,
    const std::vector<double>& distances,const std::vector<std::string>& selected,int mode,double value,bool reset){
    require(ids.size()==modes.size()&&ids.size()==values.size()&&ids.size()==distances.size(),"Radius metadata length mismatch");
    require((mode==1||mode==2)&&std::isfinite(value)&&value>=0&&value<=std::numeric_limits<float>::max(),"Invalid authored radius value");
    for(std::size_t i=0;i<ids.size();++i)require((modes[i]==1||modes[i]==2)&&std::isfinite(values[i])&&values[i]>=0&&values[i]<=std::numeric_limits<float>::max()&&std::isfinite(distances[i])&&distances[i]>=0&&distances[i]<=std::numeric_limits<float>::max(),"Invalid saved radius override");
    auto bound=bind(view,current,previous,ids);const auto sources=capture(view,selected);
    Authored result{ids,modes,values,distances,{}};std::map<std::pair<std::string,std::string>,std::size_t> lookup;
    for(std::size_t i=0;i<bound.entries.size();++i)lookup.emplace(std::make_pair(bound.entries[i].id,bound.entries[i].source),i);
    std::set<std::size_t> removed;
    for(std::size_t i=0;i<selected.size();++i){const auto pair=std::make_pair(selected[i],sources[i]);const auto found=lookup.find(pair);
        if(reset){if(found!=lookup.end())removed.insert(found->second);continue;}
        std::size_t index=0;
        if(found==lookup.end()){
            require(result.ids.size()<maxOverrides,"Radius history exceeds one million overrides");index=result.ids.size();lookup.emplace(pair,index);
            result.ids.push_back(selected[i]);result.modes.push_back(mode);result.values.push_back(1.0);result.distances.push_back(0.0);bound.entries.push_back({selected[i],sources[i]});
        }else index=found->second;
        result.modes[index]=mode;if(mode==1)result.distances[index]=value;else result.values[index]=value;
    }
    if(!removed.empty()){
        std::size_t out=0;for(std::size_t i=0;i<result.ids.size();++i)if(!removed.count(i)){
            if(out!=i){result.ids[out]=std::move(result.ids[i]);result.modes[out]=result.modes[i];result.values[out]=result.values[i];result.distances[out]=result.distances[i];bound.entries[out]=std::move(bound.entries[i]);}++out;}
        result.ids.resize(out);result.modes.resize(out);result.values.resize(out);result.distances.resize(out);bound.entries.resize(out);
    }
    if(!result.ids.empty())result.binding=encode(bound);return result;
}
struct Replay::Impl {
    Binding binding;placements::Token token;std::unordered_map<Key,std::size_t,Hash> lookup;
    Impl(const placements::View& view,const std::string& current,const std::string& previous,const std::vector<std::string>& ids)
        :binding(bind(view,current,previous,ids)),token(view.token()){
        lookup.reserve(binding.entries.size());for(std::size_t i=0;i<binding.entries.size();++i){const auto& entry=binding.entries[i];lookup.emplace(key(entry.id,entry.source),i);}
    }
};
Replay::Replay(const placements::View& view,const std::string& current,const std::string& previous,const std::vector<std::string>& ids):impl_(std::make_unique<Impl>(view,current,previous,ids)){}
Replay::~Replay()=default;
std::optional<std::size_t> Replay::find(const placements::View& view,std::size_t row)const{
    view.require(impl_->token);const auto source=view.at(row).source;const auto& sources=view.sourceCohort()->sources();
    require(source>0&&source<=sources.size(),"Invalid radius source ordinal");
    const auto found=impl_->lookup.find(key(view,row,sources[source-1].id));if(found==impl_->lookup.end())return {};return found->second;
}
}
