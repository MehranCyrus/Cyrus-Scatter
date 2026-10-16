#include "presets.h"
#include <nlohmann/json.hpp>
#include <cmath>
#include <set>
#include <stdexcept>

namespace cyrus::presets {
namespace {
using Json=nlohmann::json;
using K=Kind;
void require(bool ok,const char* message){if(!ok)throw std::invalid_argument(message);}
void keys(const Json& object,const std::set<std::string>& expected){
    require(object.is_object()&&object.size()==expected.size(),"Incomplete preset fields");
    for(const auto& item:object.items())require(expected.count(item.key())!=0,"Unknown preset field");
}
double number(const Json& value){require(value.is_number(),"Expected a preset number");const double v=value.get<double>();require(std::isfinite(v),"Preset values must be finite");return v;}
}
bool curve(const std::string& category){return category=="density_curve"||category=="scale_curve";}
const std::vector<Field>& fields(const std::string& category){
    static const std::vector<Field> population={
        {"amount",K::integer,0,1000000},{"populationMode",K::integer,1,2},
        {"plantsPerM2",K::number,0,1e9},{"randomSeed",K::integer,0,2147483647},
        {"procPopulation",K::integer,1,2},{"procAttemptFactor",K::integer,1,32},
        {"procRounds",K::integer,1,16},{"procRepair",K::boolean,0,1},
        {"placementMode",K::integer,1,4},{"gridColumnWU",K::number,.0001,1e9,true},{"gridRowWU",K::number,.0001,1e9,true},
        {"gridOriginXWU",K::number,-1e9,1e9,true},{"gridOriginYWU",K::number,-1e9,1e9,true},{"gridHeading",K::number,-36000,36000},{"gridJitter",K::number,0,100}};
    static const std::vector<Field> transforms={
        {"advancedAxes",K::boolean,0,1},{"alignNormal",K::boolean,0,1},{"projectMove",K::boolean,0,1},
        {"rotXMin",K::number,-36000,36000},{"rotXMax",K::number,-36000,36000},
        {"rotYMin",K::number,-36000,36000},{"rotYMax",K::number,-36000,36000},
        {"rotZMin",K::number,-36000,36000},{"rotZMax",K::number,-36000,36000},
        {"sclXMin",K::number,0,10000},{"sclXMax",K::number,0,10000},
        {"sclYMin",K::number,0,10000},{"sclYMax",K::number,0,10000},
        {"sclZMin",K::number,0,10000},{"sclZMax",K::number,0,10000},
        {"movXMinWU",K::number,-1e9,1e9,true},{"movXMaxWU",K::number,-1e9,1e9,true},
        {"movYMinWU",K::number,-1e9,1e9,true},{"movYMaxWU",K::number,-1e9,1e9,true},
        {"movZMinWU",K::number,-1e9,1e9,true},{"movZMaxWU",K::number,-1e9,1e9,true},
        {"wholeScaleMin",K::number,0,10000},{"wholeScaleMax",K::number,0,10000},
        {"scaleMinimum",K::number,0,10000},{"scaleMaximum",K::number,0,10000},
        {"tiltDegrees",K::number,0,36000},{"yawMinimum",K::number,-36000,36000},
        {"yawMaximum",K::number,-36000,36000},{"movementRange",K::number,0,1e9,true},
        {"orientationMode",K::integer,1,3},{"orientationBlend",K::number,0,100},
        {"orientationX",K::number,-1e6,1e6},{"orientationY",K::number,-1e6,1e6},{"orientationZ",K::number,-1e6,1e6}};
    static const std::vector<Field> spacing={{"enabled",K::boolean,0,1},{"multiplier",K::number,0,10000},{"gap",K::number,0,1e9,true},{"planar",K::boolean,0,1}};
    static const std::vector<Field> empty;
    if(category=="population")return population;
    if(category=="transforms")return transforms;
    if(category=="spacing")return spacing;
    if(curve(category))return empty;
    throw std::invalid_argument("Unsupported preset category");
}
void validate(const Document& d){
    const auto& spec=fields(d.category);
    require(!d.name.empty()&&d.name.size()<=320,"Preset name must contain 1..80 characters");
    std::size_t characters=0;
    for(unsigned char c:d.name){require(c>=32&&c!=127,"Preset name contains control characters");if((c&0xc0)!=0x80)++characters;}
    require(characters<=80,"Preset name exceeds 80 characters");
    require(d.values.size()==spec.size(),"Preset value count differs from its category");
    for(std::size_t i=0;i<spec.size();++i){
        const double v=d.values[i];const auto& f=spec[i];
        require(std::isfinite(v)&&v>=f.minimum&&v<=f.maximum,"Preset value outside supported bounds");
        if(f.kind!=K::number)require(std::floor(v)==v,"Expected a whole-number preset value");
    }
    if(d.category=="transforms"){
        for(std::size_t i=3;i<=23;i+=2)require(d.values[i]<=d.values[i+1],"Transform minimum exceeds maximum");
        require(d.values[26]<=d.values[27],"Yaw minimum exceeds maximum");
        if(d.values[29]==2)require(d.values[31]!=0||d.values[32]!=0||d.values[33]!=0,"World direction must be nonzero");
    }
    if(!curve(d.category)){require(d.samples.empty()&&d.graph.empty()&&!d.multiplier,"Unexpected curve data");return;}
    require(d.category=="scale_curve"||!d.multiplier,"Density curves cannot use multiplier units");
    const double cap=d.multiplier?100.:1.;
    require(d.samples.size()>=2&&d.samples.size()<=257,"Curves require 2..257 samples");
    for(double v:d.samples)require(std::isfinite(v)&&v>=0&&v<=cap,"Curve sample outside its domain");
    require(d.graph.empty()||(d.graph.size()>=2&&d.graph.size()<=257),"Curves require 2..257 graph points");
    double previous=-1;
    for(const auto& p:d.graph){
        for(double v:p)require(std::isfinite(v)&&std::abs(v)<=1e8,"Invalid graph coordinate");
        require(p[0]>=0&&p[0]<=1&&p[0]>previous,"Curve X coordinates must increase in 0..1");previous=p[0];
        require(p[1]>=0&&p[1]<=cap*100,"Graph value outside its domain");
        require((p[6]==0||p[6]==1)&&(p[7]==0||p[7]==1),"Invalid graph flags");
    }
    if(!d.graph.empty())require(d.graph.front()[0]==0&&d.graph.back()[0]==1,"Curve must span 0..1");
}
Document parse(const std::string& text){
    require(!text.empty()&&text.size()<=maxBytes,"Preset exceeds 64 KiB or is empty");
    std::vector<std::set<std::string>> objectKeys;
    auto callback=[&](int depth,Json::parse_event_t event,Json& value){
        require(depth<=8,"Preset nesting exceeds eight levels");
        if(event==Json::parse_event_t::object_start)objectKeys.emplace_back();
        if(event==Json::parse_event_t::key){require(!objectKeys.empty(),"Invalid preset object");require(objectKeys.back().insert(value.get<std::string>()).second,"Duplicate preset key");}
        if(event==Json::parse_event_t::object_end)objectKeys.pop_back();
        return true;
    };
    auto json=Json::parse(text,callback);
    keys(json,{"format","version","category","name","values"});
    require(json["format"]=="cyrus.settings-preset"&&json["version"].is_number_integer()&&(json["version"]==1||json["version"]==2||json["version"]==3),"Unsupported preset format/version");
    require(json["category"].is_string()&&json["name"].is_string(),"Invalid preset metadata");
    Document d;d.category=json["category"].get<std::string>();d.name=json["name"].get<std::string>();
    if(json["version"]==1&&d.category=="transforms"){
        // Only the just-delivered v1 numeric contract is extended. Closed keys
        // below still reject missing/unknown old fields; never alter input files.
        auto& values=json["values"];require(values.is_object(),"Invalid transform values");
        for(const auto& name:{"orientationMode","orientationBlend","orientationX","orientationY","orientationZ"})require(!values.contains(name),"Orientation fields require preset version 2");
        values["orientationMode"]=1;values["orientationBlend"]=100.;values["orientationX"]=0.;values["orientationY"]=1.;values["orientationZ"]=0.;
    }
    if(json["version"]!=3&&d.category=="population"){
        auto& v=json["values"];require(v.is_object(),"Invalid population values");
        for(const auto* name:{"placementMode","gridColumnWU","gridRowWU","gridOriginXWU","gridOriginYWU","gridHeading","gridJitter"})require(!v.contains(name),"Grid fields require preset version 3");
        v["placementMode"]=1;v["gridColumnWU"]=1.;v["gridRowWU"]=1.;v["gridOriginXWU"]=0.;v["gridOriginYWU"]=0.;v["gridHeading"]=0.;v["gridJitter"]=0.;
    }
    const auto& spec=fields(d.category);const auto& values=json["values"];
    if(curve(d.category)){
        keys(values,{"domain","samples","graph"});
        require(values["domain"]=="unit"||values["domain"]=="multiplier","Unknown curve domain");d.multiplier=values["domain"]=="multiplier";
        require(values["samples"].is_array()&&values["graph"].is_array(),"Invalid curve arrays");
        require(values["samples"].size()<=257&&values["graph"].size()<=257,"Curve exceeds admission limits");
        for(const auto& v:values["samples"])d.samples.push_back(number(v));
        for(const auto& row:values["graph"]){
            require(row.is_array()&&row.size()==8,"Graph points require eight values");
            std::array<double,8> point{};for(std::size_t i=0;i<8;++i)point[i]=number(row[i]);d.graph.push_back(point);
        }
    }else{
        std::set<std::string> names;for(const auto& f:spec)names.insert(f.name);keys(values,names);
        for(const auto& f:spec){const auto& v=values[f.name];
            if(f.kind==K::boolean){require(v.is_boolean(),"Expected a Boolean preset field");d.values.push_back(v.get<bool>()?1:0);}
            else {if(f.kind==K::integer)require(v.is_number_integer(),"Expected an integer preset field");d.values.push_back(number(v));}
        }
    }
    validate(d);return d;
}
std::string serialize(const Document& d){
    validate(d);Json values=Json::object();
    if(curve(d.category)){values["domain"]=d.multiplier?"multiplier":"unit";values["samples"]=d.samples;values["graph"]=d.graph;}
    else{const auto& spec=fields(d.category);for(std::size_t i=0;i<spec.size();++i){
        if(spec[i].kind==K::boolean)values[spec[i].name]=d.values[i]!=0;
        else if(spec[i].kind==K::integer)values[spec[i].name]=static_cast<std::int64_t>(d.values[i]);
        else values[spec[i].name]=d.values[i];
    }}
    const auto text=Json{{"format","cyrus.settings-preset"},{"version",3},{"category",d.category},{"name",d.name},{"values",values}}.dump(2)+"\n";
    require(text.size()<=maxBytes,"Preset exceeds 64 KiB");return text;
}
}
