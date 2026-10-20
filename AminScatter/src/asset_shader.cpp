#include "asset_shader.h"
#include <algorithm>
#include <cmath>
#include <cstdint>
#include <functional>
#include <map>
#include <set>
#include <stdexcept>
#include <string>

namespace cyrus::assets {
namespace {
using Json=recipes::Json;
constexpr std::size_t maxNodes=128,maxDepth=8;
void require(bool ok,const std::string& message){if(!ok)throw std::invalid_argument("Asset shader: "+message);}
void keys(const Json& value,std::initializer_list<const char*> names,const std::string& where){
    require(value.is_object()&&value.size()==names.size(),where+" has unexpected fields");
    for(const auto* name:names)require(value.contains(name),where+" is missing "+name);
}
std::string text(const Json& value,std::size_t cap,const std::string& where){
    require(value.is_string(),where+" requires text");const auto result=value.get<std::string>();
    require(result.size()<=cap&&result.find('\0')==std::string::npos,where+" exceeds text bounds");return result;
}
std::string identity(const Json& value,const std::string& where){
    const auto result=text(value,80,where);require(!result.empty()&&std::all_of(result.begin(),result.end(),[](unsigned char c){return(c>='a'&&c<='z')||(c>='A'&&c<='Z')||(c>='0'&&c<='9')||c=='-'||c=='_';}),where+" has invalid identity");return result;
}
const Json& schema(){
    static const Json value=Json::parse(
#include "asset_adapter_schema.inc"
    );return value;
}
bool materialKind(const std::string& kind){return kind=="corona-physical-v1"||kind=="corona-legacy-v1"||kind=="multi-sub-v1";}
bool mapKind(const std::string& kind){return kind=="corona-normal-v1"||kind=="max-color-correction-v1"||kind=="max-vertex-color-v1"||kind=="corona-front-back-v1"||kind=="max-mix-v1"||kind=="corona-color-v1"||kind=="corona-mix-v1"||kind=="corona-color-correct-v1"||kind=="max-composite-v1"||kind=="forest-color-v1"||kind=="forest-edge-v1"||kind=="corona-bitmap-v1"||kind=="max-gradient-v1";}
const Json& adapter(const std::string& kind){
    const auto& values=schema().at("adapters");
    require(values.is_array(),"compiled adapter table is invalid");
    for(const auto& value:values)if(value.at("kind")==kind)return value;
    throw std::invalid_argument("Asset shader: compiled adapter is missing "+kind);
}
void adapterIdentity(const Json& spec,const std::string& kind,bool material){
    const Json expected=kind=="corona-physical-v1"?Json::array({1762831241u,2266306336u}):kind=="corona-normal-v1"?Json::array({678481578u,3424142204u}):kind=="corona-legacy-v1"?Json::array({1891525894u,1149841885u}):kind=="multi-sub-v1"?Json::array({512u,0u}):kind=="max-color-correction-v1"?Json::array({720u,0u}):kind=="max-vertex-color-v1"?Json::array({9652305u,0u}):kind=="corona-front-back-v1"?Json::array({2882347111u,2267239517u}):kind=="max-mix-v1"?Json::array({560u,0u}):kind=="corona-color-v1"?Json::array({1749183946u,925065940u}):kind=="corona-mix-v1"?Json::array({1749493871u,1073719988u}):kind=="corona-color-correct-v1"?Json::array({2168614345u,931412224u}):kind=="max-composite-v1"?Json::array({640u,0u}):kind=="forest-color-v1"?Json::array({1613723927u,104154128u}):kind=="forest-edge-v1"?Json::array({1568227357u,1783892597u}):kind=="corona-bitmap-v1"?Json::array({2881116036u,1699234372u}):kind=="max-gradient-v1"?Json::array({624u,0u}):Json();
    require(!expected.is_null(),"compiled adapter kind is unknown");
    require(spec.at("classID")==expected&&spec.at("category")== (material?"material":"map"),"compiled adapter identity differs for "+kind);
}
void property(const Json& value,const Json& spec,const std::string& where){
    const auto type=spec.at("type").get<std::string>();
    if(type.ends_with("-array")&&type!="empty-array"&&type!="null-array"){
        require(value.is_array()&&value.size()>=spec.at("minCount").get<std::size_t>()&&value.size()<=spec.at("maxCount").get<std::size_t>(),where+" has an unsupported array count");
        auto element=spec;element["type"]=type.substr(0,type.size()-6);for(const auto& item:value)property(item,element,where+" element");return;
    }
    if(type=="boolean")require(value.is_boolean(),where+" requires a Boolean");
    else if(type=="number"||type=="distance"||type=="integer"){
        require(type=="integer"?value.is_number_integer():value.is_number(),where+" requires "+type);
        const auto number=value.get<double>();require(std::isfinite(number),where+" must be finite");
        if(spec.contains("lo"))require(number>=spec.at("lo").get<double>(),where+" is below its bound");
        if(spec.contains("hi"))require(number<=spec.at("hi").get<double>(),where+" is above its bound");
    }else if(type=="color"||type=="point3"||type=="point3-distance"){
        require(value.is_array()&&value.size()==3,where+" requires three color components");
        for(const auto& component:value){require(component.is_number(),where+" color component is not numeric");const auto number=component.get<double>();require(std::isfinite(number),where+" color must be finite");if(spec.contains("lo"))require(number>=spec.at("lo").get<double>(),where+" color is below its bound");if(spec.contains("hi"))require(number<=spec.at("hi").get<double>(),where+" color is above its bound");}
    }else if(type=="empty-array")require(value.is_array()&&value.empty(),where+" requires an empty array");
    else if(type=="null-array"){require(value.is_array()&&value.size()==spec.at("count").get<std::size_t>(),where+" has an unsupported null array count");for(const auto& item:value)require(item.is_null(),where+" requires absent inputs");}
    else if(type=="absent-filename")require(value.is_null(),where+" requires an absent filename");
    else if(type=="string")text(value,160,where);
    else require(false,"compiled property type is unknown: "+type);
    if(spec.contains("members")){
        const auto& members=spec.at("members");require(members.is_array()&&!members.empty(),"compiled enum is invalid");
        require(std::find(members.begin(),members.end(),value)!=members.end(),where+" has an unsupported enum value");
    }
}
void validateProperties(const Json& values,const Json& fields,const std::string& where){
    require(fields.is_object()&&values.is_object()&&fields.size()==values.size(),where+" have unexpected fields");
    for(auto item=fields.begin();item!=fields.end();++item){require(values.contains(item.key()),where+" is missing "+item.key());property(values.at(item.key()),item.value(),where+"."+item.key());}
}
void subobject(const Json& value,const Json& spec,const char* member,const char* knownKind,const std::string& where){
    require(spec.at(member)==knownKind,where+" has an unknown compiled subobject adapter");
    keys(value,{"kind","properties"},where+" "+member);require(value.at("kind")==knownKind,where+" has an unknown subobject kind");
    const auto& values=schema().at("subobjects");require(values.is_array()&&values.size()==3,"compiled subobject table is invalid");
    const auto found=std::find_if(values.begin(),values.end(),[&](const Json& item){return item.at("kind")==knownKind;});
    require(found!=values.end(),"compiled subobject is missing");validateProperties(value.at("properties"),found->at("fields"),where+" "+member+" properties");
}
void imageEnvelope(const Json& value,const std::string& id){
    identity(value.at("file"),id+" image file");const auto& size=value.at("size");require(size.is_array()&&size.size()==2,id+" image size requires two dimensions");
    for(const auto& number:size)require(number.is_number_integer()&&number.get<double>()>=1&&number.get<double>()<=8192,id+" image size is outside its bound");
    const auto& color=value.at("color");keys(color,{"mode","configSHA256","renderingSpace","dataSpace","inputSpace"},id+" image color");
    require(color.at("mode")=="OCIO_Default",id+" image color mode is unsupported");const auto hash=text(color.at("configSHA256"),64,id+" config hash");
    require(hash.size()==64&&std::all_of(hash.begin(),hash.end(),[](char c){return(c>='0'&&c<='9')||(c>='a'&&c<='f');}),id+" config hash is invalid");
    for(const auto* key:{"renderingSpace","dataSpace","inputSpace"})require(!text(color.at(key),160,id+" image color space").empty(),id+" image color space is empty");
    require(color.at("inputSpace")==value.at("properties").at("colorSpaceStr"),id+" image input space differs from its plugin interpretation");
}
struct Node {bool material=false;const Json* value=nullptr;std::string kind;std::vector<std::string> edges;};
}
void validateRendererShaders(const Json& graph){
    require(graph.is_object()&&graph.contains("version")&&graph.at("version").is_number_integer()&&graph.at("version")==3,"renderer adapters require graph version 3");
    require(graph.contains("rendererProfile"),"renderer profile is missing");const auto& profile=graph.at("rendererProfile");
    keys(profile,{"id","hostYear","pluginVersion"},"renderer profile");
    require(profile.at("id")=="corona-max2027-15.0.671720-v1"&&profile.at("hostYear").is_number_integer()&&profile.at("hostYear")==2027&&profile.at("pluginVersion")=="15.0.671720","renderer profile is unsupported");
    require(profile==schema().at("profile"),"renderer profile differs from the compiled adapter table");
    std::map<std::string,Node> nodes;
    for(const auto* collection:{"materials","maps"}){
        require(graph.contains(collection),std::string(collection)+" is missing");const auto& values=graph.at(collection);const bool material=std::string(collection)=="materials";
        const auto cap=!material&&graph.contains("resourceProfile")&&graph.at("resourceProfile")=="plant-assets-v1"?256u:maxNodes;
        require(values.is_array()&&values.size()<=cap,std::string(collection)+" exceeds its count bound");
        for(const auto& value:values){
            require(value.is_object()&&value.contains("id")&&value.contains("kind"),"node identity or kind is missing");
            const auto id=identity(value.at("id"),"node ID"),kind=text(value.at("kind"),40,id+" kind");
            require(material?(kind=="standard-blinn"||materialKind(kind)):(kind=="bitmap"||mapKind(kind)),id+" has an unsupported adapter kind or namespace");
            require(nodes.emplace(id,Node{material,&value,kind,{}}).second,"duplicate node identity "+id);
        }
    }
    auto reference=[&](Node& node,const Json& value,bool material,const std::string& where){
        if(value.is_null())return;const auto id=identity(value,where);const auto found=nodes.find(id);
        require(found!=nodes.end()&&found->second.material==material,where+" references a missing or incompatible node");node.edges.push_back(id);
    };
    for(auto& [id,node]:nodes){
        const auto& value=*node.value;
        if(node.kind=="bitmap")continue;
        if(node.kind=="standard-blinn"){
            // The outer validator owns the Standard record's complete shape,
            // but its map links still count toward combined shader depth.
            require(value.contains("maps")&&value.at("maps").is_array(),id+" Standard map slots are missing");
            require(value.at("maps").size()<=maxNodes,id+" Standard map slots exceed their bound");
            for(const auto& slot:value.at("maps")){require(slot.is_object()&&slot.contains("map"),id+" Standard map slot is missing its reference");reference(node,slot.at("map"),false,id+" Standard map");}
            continue;
        }
        const auto& spec=adapter(node.kind);adapterIdentity(spec,node.kind,node.material);
        if(node.kind=="multi-sub-v1"){
            keys(value,{"id","kind","name","slots","showPreviews"},id);text(value.at("name"),160,id+" name");require(value.at("showPreviews").is_boolean(),id+" showPreviews requires a Boolean");const auto& slots=value.at("slots");
            require(slots.is_array()&&!slots.empty()&&slots.size()<=maxNodes,id+" requires one to 128 slots");std::set<std::uint64_t> ids;
            for(const auto& slot:slots){keys(slot,{"materialID","name","enabled","material"},id+" slot");const auto& number=slot.at("materialID");
                require(number.is_number_integer()&&number.get<double>()>=1&&number.get<double>()<=65535,id+" slot materialID is outside its bound");
                require(ids.insert(number.get<std::uint64_t>()).second,id+" has duplicate slot material IDs");text(slot.at("name"),160,id+" slot name");require(slot.at("enabled").is_boolean(),id+" slot enabled requires a Boolean");reference(node,slot.at("material"),true,id+" slot material");
            }continue;
        }
        require(materialKind(node.kind)||mapKind(node.kind),id+" has an unsupported renderer adapter");
        if(node.material)keys(value,{"id","kind","name","properties","links"},id);
        else {
            if(node.kind=="corona-bitmap-v1"){
                keys(value,{"id","kind","name","properties","links","roles","output","coordinates","file","size","color"},id);
                require(spec.contains("output")&&spec.contains("coordinates"),id+" compiled image adapter is incomplete");
                imageEnvelope(value,id);subobject(value.at("coordinates"),spec,"coordinates","corona-uvw-v1",id);
            }else if(node.kind=="max-gradient-v1"){
                keys(value,{"id","kind","name","properties","links","roles","output","coordinates"},id);
                require(spec.contains("output")&&spec.contains("coordinates"),id+" compiled Gradient adapter is incomplete");
                subobject(value.at("coordinates"),spec,"coordinates","ordinary-gradient-uv-v1",id);
            }else if(spec.contains("output")){require(node.kind=="max-mix-v1",id+" has an unsupported compiled output owner");keys(value,{"id","kind","name","properties","links","roles","output"},id);}
            else keys(value,{"id","kind","name","properties","links","roles"},id);
            if(spec.contains("output"))subobject(value.at("output"),spec,"output","standard-output-v1",id);
            require(value.at("roles").is_array()&&value.at("roles").empty(),id+" renderer map cannot bind an external texture role");
        }
        text(value.at("name"),160,id+" name");
        const auto& fields=spec.at("fields"),properties=value.at("properties");
        validateProperties(properties,fields,id+" properties");
        const auto& names=spec.at("links"),links=value.at("links");require(names.is_array()&&links.is_object()&&names.size()+(spec.contains("arrayLinks")?spec.at("arrayLinks").size():0)==links.size(),id+" links have unexpected fields");
        for(const auto& name:names){const auto key=text(name,80,"compiled link");require(links.contains(key),id+" is missing link "+key);reference(node,links.at(key),false,id+"."+key);}
        if(spec.contains("arrayLinks"))for(auto field=spec.at("arrayLinks").begin();field!=spec.at("arrayLinks").end();++field){
            require(links.contains(field.key()),id+" is missing array link "+field.key());const auto& array=links.at(field.key());
            require(array.is_array()&&array.size()>=field.value().at("minCount").get<std::size_t>()&&array.size()<=field.value().at("maxCount").get<std::size_t>(),id+" has an unsupported array link count");
            for(const auto& child:array)reference(node,child,false,id+"."+field.key());
        }
        if(spec.contains("alignedArrays")){std::size_t count=0;for(const auto& field:spec.at("alignedArrays")){const auto key=field.get<std::string>();const auto size=properties.contains(key)?properties.at(key).size():links.at(key).size();if(count==0)count=size;require(size==count,id+" has inconsistent layer arrays");}}
        if(node.kind=="corona-color-correct-v1")require(links.at("copiedMap").is_null(),id+" copied output controls are unsupported");
    }
    // A shared DAG is valid. Memoize subtree height only after visiting all
    // descendants; a simple global visited flag would miss a deeper alias path.
    std::map<std::string,unsigned> heights;std::set<std::string> visiting;
    std::function<unsigned(const std::string&)> visit=[&](const std::string& id)->unsigned{
        const auto cached=heights.find(id);if(cached!=heights.end())return cached->second;
        require(visiting.insert(id).second,"dependency cycle at "+id);unsigned height=1;
        for(const auto& child:nodes.at(id).edges)height=std::max(height,1+visit(child));
        require(height<=maxDepth,"dependency depth exceeds eight at "+id);visiting.erase(id);heights.emplace(id,height);return height;
    };
    for(const auto& [id,node]:nodes){(void)node;visit(id);}
}
}
