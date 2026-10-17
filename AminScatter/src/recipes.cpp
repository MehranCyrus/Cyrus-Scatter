#include "recipes.h"
#include "recipe_store.h"
#include "brush.h"
#include "presets.h"
#include "mesh_density.h"
#include "surface_filter.h"
#include <algorithm>
#include <cmath>
#include <fstream>
#include <locale>
#include <map>
#include <set>
#include <sstream>
#include <stdexcept>
#include <tuple>
#ifdef _WIN32
#ifndef NOMINMAX
#define NOMINMAX
#endif
#include <windows.h>
#include <bcrypt.h>
#endif

namespace cyrus::recipes {
namespace {
void require(bool ok,const std::string& message){if(!ok)throw std::invalid_argument("Recipe: "+message);}
void keys(const Json& value,std::initializer_list<const char*> expected){
    require(value.is_object()&&value.size()==expected.size(),"incomplete or unknown record fields");
    for(auto key:expected)require(value.contains(key),std::string("missing ")+key);
}
std::string text(const Json& value,std::size_t limit=131072){
    require(value.is_string(),"expected text");const auto result=value.get<std::string>();
    require(result.size()<=limit&&result.find('\0')==std::string::npos,"text exceeds bounds or contains NUL");return result;
}
std::string id(const Json& value){
    const auto result=text(value,160);require(!result.empty(),"empty identity");
    for(unsigned char c:result)require((c>='a'&&c<='z')||(c>='A'&&c<='Z')||(c>='0'&&c<='9')||c=='_'||c=='-'||c=='.'||c==':',"invalid identity");return result;
}
double number(const Json& value){require(value.is_number(),"expected number");const double n=value.get<double>();require(std::isfinite(n)&&std::abs(n)<=1e12,"nonfinite or excessive number");return n;}
void range(const Json& settings,const char* key,int lo,int hi){
    const auto& v=settings.at(key);require(v.is_number_integer()&&v.get<std::int64_t>()>=lo&&v.get<std::int64_t>()<=hi,std::string("unsupported ")+key);
}
void samples(const Json& v,double maximum){
    require(v.is_array()&&v.size()>=2&&v.size()<=257,"curve needs 2..257 samples");
    for(const auto& n:v)require(number(n)>=0&&number(n)<=maximum,"curve sample outside domain");
}
Json packedSamples(const Json& value,double maximum){
    const auto s=text(value,65536);std::istringstream stream(s);stream.imbue(std::locale::classic());std::string part;Json values=Json::array();
    while(std::getline(stream,part,',')){std::istringstream input(part);input.imbue(std::locale::classic());double v=0;require(bool(input>>v),"invalid packed curve");input>>std::ws;require(input.eof(),"trailing packed curve data");values.push_back(v);}
    samples(values,maximum);return values;
}
void scalar(const Json& v,const std::string& kind){
    if(kind=="boolean"||kind=="bool")require(v.is_boolean(),"expected Boolean");
    else if(kind=="integer"||kind=="int"){require(v.is_number_integer()&&number(v)>=-2147483648.0&&number(v)<=2147483647.0,"expected bounded host integer");}
    else if(kind=="string")text(v);
    else if(kind=="node"||kind=="texturemap"){if(!v.is_null())id(v);}
    else if(kind=="color"){
        require(v.is_array()&&v.size()==3,"color needs three components");for(const auto& c:v)require(number(c)>=0&&number(c)<=255,"color outside 0..255");
    }else if(kind=="float"||kind=="worldunits")number(v);
    else throw std::invalid_argument("Recipe: unsupported declared field type "+kind);
}
std::string loadText(const std::filesystem::path& p,std::size_t limit){
    std::ifstream in(nativePath(p),std::ios::binary|std::ios::ate);require(bool(in),"cannot read file");const auto size=in.tellg();
    require(size>=0&&static_cast<std::uint64_t>(size)<=limit,"file exceeds bounds");std::string out(static_cast<std::size_t>(size),'\0');in.seekg(0);
    if(!out.empty())in.read(out.data(),static_cast<std::streamsize>(out.size()));require(bool(in),"file read failed");return out;
}
void saveBytes(const std::filesystem::path& p,const std::string& bytes){
    std::ofstream out(nativePath(p),std::ios::binary|std::ios::trunc);require(bool(out),"cannot create staged file");out.write(bytes.data(),static_cast<std::streamsize>(bytes.size()));out.flush();require(bool(out),"staged file write failed");out.close();require(!out.fail(),"staged file close failed");
}
template<class F>void paints(Json& d,F f){for(auto& layer:d["layers"]){if(!layer["paint"].is_null())f(layer["paint"]);for(auto& area:layer["areas"])if(!area["paint"].is_null())f(area["paint"]);}}
std::filesystem::path checkedAttachment(const std::filesystem::path& manifest,const std::string& relative){
    require(!relative.empty()&&relative.size()<512,"invalid attachment path");
    require(relative.find('\\')==std::string::npos&&relative.find(':')==std::string::npos,"attachment path must be relative");
    const std::filesystem::path p=pathFromUTF8(relative);require(!p.is_absolute(),"absolute attachment path");
    for(const auto& part:p)require(part!=".."&&part!=".","attachment path escapes package");
    const auto parent=nativePath(std::filesystem::weakly_canonical(nativePath(manifest.parent_path(),true)),true);const auto target=nativePath(std::filesystem::weakly_canonical(parent/p),true);
    auto a=parent.begin(),b=target.begin();for(;a!=parent.end();++a,++b)require(b!=target.end()&&*a==*b,"attachment resolves outside package");return nativePath(target);
}
}

std::filesystem::path nativePath(const std::filesystem::path& path,bool force){
#ifdef _WIN32
    auto value=std::filesystem::absolute(path).lexically_normal().wstring();
    if(value.starts_with(L"\\\\?\\UNC\\"))value=L"\\\\"+value.substr(8);
    else if(value.starts_with(L"\\\\?\\"))value=value.substr(4);
    if(!force&&value.size()<248)return std::filesystem::path(value);
    return std::filesystem::path(value.starts_with(L"\\\\")?L"\\\\?\\UNC\\"+value.substr(2):L"\\\\?\\"+value);
#else
    (void)force;return path;
#endif
}
const std::vector<Field>& fields(){static const std::vector<Field> result={
#include "recipe_fields.inc"
};return result;}

void validateSettings(const Json& s){
    require(s.is_object()&&s.size()==fields().size(),"complete settings field count differs from recipe v4");
    for(const auto& f:fields()){
        require(s.contains(f.name),std::string("missing authored field ")+f.name);const auto& v=s.at(f.name);std::string kind=f.type;
        if(kind.size()>3&&kind.substr(kind.size()-3)=="tab"){
            kind.resize(kind.size()-3);require(v.is_array()&&v.size()<=65536,std::string("array exceeds bounds: ")+f.name);for(const auto& item:v)scalar(item,kind);
        }else scalar(v,kind);
    }
    for(const auto& category:{"population","transforms"}){
        cyrus::presets::Document d;d.category=category;d.name="Recipe settings";
        for(const auto& f:cyrus::presets::fields(category))d.values.push_back(f.kind==cyrus::presets::Kind::boolean?(s.at(f.name).get<bool>()?1.:0.):number(s.at(f.name)));
        cyrus::presets::validate(d);
    }
    for(const auto& e:std::vector<std::tuple<const char*,int,int>>{
        {"updateMode",1,2},{"viewportMode",1,3},{"proxyShape",1,3},{"containerMode",1,4},{"diversityMode",1,4},{"meshMaskChannel",0,99},{"meshMaskComponent",1,3},{"areaLineCaps",1,2},{"pointColorMode",1,2},{"identificationMode",1,3},{"radiusDisplayMetric",1,2},{"paintView",0,2},{"bandArrangement",1,2}})range(s,std::get<0>(e),std::get<1>(e),std::get<2>(e));
    require(s["distributionMode"]==1||s["distributionMode"]==3,"unsupported distributionMode");
    require(s["densityUVChannel"].get<int>()>=1&&s["densityUVChannel"].get<int>()<=99,"UV channel outside 1..99");
    require(s["densityResolution"]==64||s["densityResolution"]==128||s["densityResolution"]==256||s["densityResolution"]==512,"unsupported texture resolution");
    for(const auto& e:std::vector<std::pair<const char*,int>>{{"pathJoins",2},{"strokeSides",7},{"strokeModes",2},{"strokeScaleModes",3},{"sourceForwardAxes",4},{"areaModes",2}})
        for(const auto& v:s[e.first])require(v.is_number_integer()&&v.get<int>()>=1&&v.get<int>()<=e.second,std::string("invalid enum in ")+e.first);
    require(s["patternPaths"].size()<=32&&s["patternLines"].size()<=64&&s["surfaceNodes"].size()<=128&&s["procReceiverNodes"].size()<=128&&s["procSourceNodes"].size()<=1024,"owner array limit");
    require(s["pathIDs"].size()==s["patternPaths"].size()&&s["pathJoins"].size()==s["pathIDs"].size(),"incomplete Path records");
    for(auto name:{"patternWidths","strokeSides","strokeModes","strokeMin","strokeMax","edgeRotX","edgeRotY","edgeRotZ","edgeOffsetsWU","edgeAlongWU","edgeAcrossWU","strokeIDs","strokePathIDs","strokeStarts","strokeEnds","strokeStrengths","strokeCurveEnabled","strokeScaleModes","strokeScaleSamples","strokeCurveSamples","strokeScaleGraphs","strokeCurveGraphs","strokeDisplayColors"})require(s[name].size()==s["patternLines"].size(),std::string("incomplete Band field ")+name);
    require(s["strokeSourceRows"].size()==s["strokeSourceIDs"].size()&&s["strokeColorRows"].size()==s["strokeColorKeys"].size(),"incomplete Band memberships");
    require(s["sourceRowIDs"].size()==s["sources"].size(),"incomplete source row identities");
    require(s["procSourceNodes"].size()==s["procSourceIDs"].size()&&s["procReceiverNodes"].size()==s["procReceiverIDs"].size(),"incomplete correspondence history");
    for(const auto* field:{"sourceRowIDs","procSourceIDs","procReceiverIDs"}){
        std::set<std::string> identities;
        for(const auto& entry:s[field]){
            const auto identity=text(entry,256);
            require(!identity.empty()&&identities.insert(identity).second,std::string("empty or duplicate correspondence identity: ")+field);
        }
    }
    const auto& domains=s["procReceiverVariationIDs"];
    require(domains.size()==s["procReceiverIDs"].size(),"incomplete receiver variation history");
    std::set<std::string> uniqueDomains;
    for(const auto& entry:domains){
        const auto domain=text(entry,256);require(!domain.empty(),"empty receiver variation domain");
        for(unsigned char c:domain)require((c>='a'&&c<='z')||(c>='A'&&c<='Z')||(c>='0'&&c<='9')||c=='_'||c=='-'||c=='.'||c==':',"invalid receiver variation domain");
        require(uniqueDomains.insert(domain).second,"duplicate receiver variation domain");
    }
    for(auto name:{"visualSourceLabels","visualSourceColors","visualSourceColorSet"})require(s[name].size()==s["visualSourceKeys"].size(),"incomplete source identification");
    std::set<int> paths,bands;
    for(const auto& v:s["pathIDs"])require(v.get<int>()>0&&paths.insert(v.get<int>()).second,"duplicate Path ID");
    for(const auto& v:s["strokeIDs"])require(v.get<int>()>0&&bands.insert(v.get<int>()).second,"duplicate Band ID");
    for(const auto& v:s["strokePathIDs"])require(paths.count(v.get<int>())!=0,"missing Band Path");
    const auto count=s["patternLines"].size();
    for(auto key:{"strokeSourceRows","strokeColorRows"})for(const auto& v:s[key])require(v.get<int>()>=1&&static_cast<std::size_t>(v.get<int>())<=count,"invalid Band membership row");
    for(const auto& v:s["strokeSourceIDs"])require(std::find(s["sourceRowIDs"].begin(),s["sourceRowIDs"].end(),v)!=s["sourceRowIDs"].end(),"Band references missing source row");
    for(std::size_t i=0;i<count;++i){
        require(number(s["strokeMin"][i])>=0&&number(s["strokeMin"][i])<=number(s["strokeMax"][i]),"invalid Band scale range");
        require(number(s["patternWidths"][i])>=0&&number(s["strokeStarts"][i])>=0&&number(s["strokeEnds"][i])>number(s["strokeStarts"][i]),"invalid Band range");
        require(number(s["strokeStrengths"][i])>=0&&number(s["strokeStrengths"][i])<=1,"invalid Band density");
        const auto densityCurve=packedSamples(s["strokeCurveSamples"][i],1);packedSamples(s["strokeScaleSamples"][i],100);
        if(s["diversityMode"]==3)require(s["strokeSides"][i]==1||s["strokeSides"][i]==2,"Spline Bands support Outside/Inside");
        if(s["procPopulation"]==2&&s["diversityMode"]==3){require(s["bandArrangement"]==1&&s["strokeStrengths"][i]==1,"Accepted target is incompatible with masked/Independent Bands");if(s["strokeCurveEnabled"][i].get<bool>())for(const auto& v:densityCurve)require(number(v)==1,"Accepted target is incompatible with nonneutral Band density");}
    }
    for(auto key:{"sourceWeights","sourceScales","sourceRadiiWU","sourceZOffsetsWU"})require(s[key].size()<=s["sources"].size(),std::string("excess source row data ")+key);
    for(auto key:{"sourceWeights","sourceScales","sourceRadiiWU"})for(const auto& v:s[key])require(number(v)>=0,"negative source weight/size/radius");
    require(number(s["paintDensity"])>=0&&number(s["paintDensity"])<=1,"invalid Paint density");
    cyrus::mesh_density::Settings mesh;mesh.channel=s["meshMaskChannel"].get<int>();mesh.component=s["meshMaskComponent"].get<int>()-1;mesh.minimum=number(s["meshMaskMinimum"]);mesh.maximum=number(s["meshMaskMaximum"]);mesh.curve=s["meshMaskSamples"].empty()?std::vector<double>{0,1}:s["meshMaskSamples"].get<std::vector<double>>();cyrus::mesh_density::validate(mesh);
    cyrus::surface_filter::Settings filter;
    filter.slope={s["slopeEnabled"].get<bool>(),number(s["slopeMinimum"]),number(s["slopeMaximum"]),number(s["slopeLowerFade"]),number(s["slopeUpperFade"])};
    filter.altitude={s["altitudeEnabled"].get<bool>(),number(s["altitudeMinimum"]),number(s["altitudeMaximum"]),number(s["altitudeLowerFade"]),number(s["altitudeUpperFade"])};cyrus::surface_filter::validate(filter);
    require(s["orientationMode"]!=3||!s["orientationTarget"].is_null(),"Look at target requires an explicit target role");
}

Json currentDocument(const Json& document){
    auto result=document;
    if(!result.is_object()||!result.contains("formatVersion")||(result["formatVersion"]!=1&&result["formatVersion"]!=2&&result["formatVersion"]!=3&&result["formatVersion"]!=4))return result;
    require(result["formatVersion"].is_number_integer(),"recipe version must be an integer");
    const int version=result["formatVersion"].get<int>();
    if(version==4){
        require(!result.contains("revision")&&!result.contains("presentation"),"revision/presentation require recipe format 5");
        result["revision"]=1;result["presentation"]=nullptr;result["formatVersion"]=5;return result;
    }
    const auto extend=[&](Json& s){
        require(s.is_object(),"invalid legacy settings");
        if(version<3){
            require(!s.contains("procReceiverVariationIDs"),"variation domains require recipe format 3");
            if(version==1){
                for(const auto* name:{"orientationMode","orientationBlend","orientationX","orientationY","orientationZ","orientationTarget"})require(!s.contains(name),"orientation fields require recipe format 2");
                s["orientationMode"]=1;s["orientationBlend"]=100.;s["orientationX"]=0.;s["orientationY"]=1.;s["orientationZ"]=0.;s["orientationTarget"]=nullptr;
            }
            s["procReceiverVariationIDs"]=s.at("procReceiverIDs");
        }
        for(const auto* name:{"placementMode","gridColumnWU","gridRowWU","gridOriginXWU","gridOriginYWU","gridHeading","gridJitter"})require(!s.contains(name),"grid fields require recipe format 4");
        s["placementMode"]=1;s["gridColumnWU"]=100.;s["gridRowWU"]=100.;s["gridOriginXWU"]=0.;s["gridOriginYWU"]=0.;s["gridHeading"]=0.;s["gridJitter"]=0.;
    };
    extend(result.at("rootSettings"));
    require(result.at("layers").is_array()&&result.at("layers").size()<=10,"invalid layers");
    for(auto& layer:result.at("layers")){
        extend(layer.at("settings"));require(layer.at("areas").is_array()&&layer.at("areas").size()<=128,"invalid Paint Areas");
        for(auto& area:layer.at("areas"))extend(area.at("settings"));
    }
    result["formatVersion"]=4;return currentDocument(result);
}

void validate(const Json& d,bool hydrated){
    if(d.is_object()&&d.contains("formatVersion")&&(d["formatVersion"]==1||d["formatVersion"]==2||d["formatVersion"]==3||d["formatVersion"]==4)){validate(currentDocument(d),hydrated);return;}
    keys(d,{"format","formatVersion","evaluationContract","sceneSchema","hostYear","id","name","unitsPerMetre","exportScope","rootSettings","roles","layers","spacingRelationships","revision","presentation"});
    require(d["format"]=="cyrus.planting-recipe"&&d["formatVersion"].is_number_integer()&&d["formatVersion"]==5&&d["evaluationContract"]=="CyrusUnified1"&&d["sceneSchema"]==58&&d["hostYear"]==2027,"unsupported recipe version/engine/host");
    require(d["revision"].is_number_integer()&&number(d["revision"])>=1&&number(d["revision"])<=2147483647,"invalid recipe revision");validateEntryPresentation(d["presentation"]);
    id(d["id"]);const auto name=text(d["name"],320);require(!name.empty(),"empty name");require(number(d["unitsPerMetre"])>0,"invalid saved unit scale");require(d["exportScope"]=="complete-setup","only complete authored recipes are supported");validateSettings(d["rootSettings"]);
    require(d["roles"].is_array()&&d["roles"].size()<=4096,"too many roles");std::map<std::string,std::string> roles;
    for(const auto& r:d["roles"]){keys(r,{"id","kind","name","purposes","requirements"});const auto key=id(r["id"]),kind=text(r["kind"],16);require(kind=="node"||kind=="texture"||kind=="layer","unknown role kind");require(roles.emplace(key,kind).second,"duplicate role");text(r["name"],1024);require(r["purposes"].is_array()&&r["purposes"].size()<=256,"role purposes limit");for(const auto& purpose:r["purposes"])text(purpose,128);if(!r["requirements"].is_null()){const auto& q=r["requirements"];keys(q,{"width","length","collectEnabled","showLabel","savedSources"});require(kind=="node"&&number(q["width"])>0&&number(q["length"])>0&&q["collectEnabled"].is_boolean()&&q["showLabel"].is_boolean()&&q["savedSources"].is_array()&&q["savedSources"].size()<=1024,"invalid container requirements");}}
    for(const auto& r:d["roles"])if(!r["requirements"].is_null())for(const auto& source:r["requirements"]["savedSources"]){if(source.is_null())continue;const auto found=roles.find(id(source));require(found!=roles.end()&&found->second=="node","missing saved container source role");}
    auto references=[&](const Json& s){for(const auto& f:fields()){
        const std::string kind=f.type;if(kind!="node"&&kind!="nodetab"&&kind!="texturemap")continue;
        const auto check=[&](const Json& v){if(!v.is_null()){const auto found=roles.find(id(v));require(found!=roles.end()&&found->second==(kind=="texturemap"?"texture":"node"),std::string("missing/wrong role: ")+f.name);}};
        if(kind=="nodetab")for(const auto& v:s[f.name])check(v);else check(s[f.name]);
    }};references(d["rootSettings"]);
    require(d["layers"].is_array()&&!d["layers"].empty()&&d["layers"].size()<=10,"recipe needs 1..10 layers");
    std::set<std::string> owners,layerOwners;std::size_t documents=0,bytes=0,vertices=0;
    auto paint=[&](const Json& p){
        if(p.is_null())return;
        keys(p,{"payload","receiverRole","radius","erase","frame"});require(++documents<=maxPaintDocuments,"Paint document limit");
        if(!p["receiverRole"].is_null()){const auto found=roles.find(id(p["receiverRole"]));require(found!=roles.end()&&found->second=="node","missing native Paint receiver role");}
        require(number(p["radius"])>.0001&&number(p["radius"])<=1e7&&p["erase"].is_boolean(),"invalid brush options");
        if(!p["frame"].is_null()){require(p["frame"].is_array()&&p["frame"].size()==12,"Paint frame needs twelve values");for(const auto& v:p["frame"])number(v);}
        if(hydrated){const auto raw=unhex(text(p["payload"],maxPaintBytes*2));bytes+=raw.size();require(bytes<=maxTotalPaintBytes,"aggregate Paint byte limit");const auto doc=cyrus::brush::decode(raw);vertices+=cyrus::brush::vertexCount(doc);require(vertices<=1000000,"aggregate contour vertex limit");}
        else {const auto& payload=p["payload"];keys(payload,{"file","sha256","bytes"});text(payload["file"],512);require(text(payload["sha256"],64).size()==64,"invalid attachment hash");require(payload["bytes"].is_number_unsigned()||payload["bytes"].is_number_integer(),"invalid attachment size");const auto n=payload["bytes"].get<std::int64_t>();require(n>0&&static_cast<std::uint64_t>(n)<=maxPaintBytes,"attachment byte limit");bytes+=static_cast<std::size_t>(n);require(bytes<=maxTotalPaintBytes,"aggregate attachment limit");}
    };
    for(const auto& l:d["layers"]){keys(l,{"id","name","enabled","visible","settings","paint","areas"});require(owners.insert(id(l["id"])).second,"duplicate owner");layerOwners.insert(id(l["id"]));require(!text(l["name"],320).empty()&&l["enabled"].is_boolean()&&l["visible"].is_boolean(),"invalid layer label/state");validateSettings(l["settings"]);references(l["settings"]);paint(l["paint"]);require(l["areas"].is_array()&&l["areas"].size()<=128,"Paint Area count limit");
        for(const auto& a:l["areas"]){keys(a,{"id","settings","receiverRole","paint"});require(owners.insert(id(a["id"])).second,"duplicate area identity");validateSettings(a["settings"]);references(a["settings"]);if(!a["receiverRole"].is_null()){const auto found=roles.find(id(a["receiverRole"]));require(found!=roles.end()&&found->second=="node","missing Paint receiver role");}paint(a["paint"]);}
    }
    require(d["spacingRelationships"].is_array()&&d["spacingRelationships"].size()<=256,"spacing relation limit");std::set<std::string> rules;
    for(const auto& r:d["spacingRelationships"]){keys(r,{"scope","a","b","enabled","multiplier","gap","planar"});require(r["scope"]==1||r["scope"]==2,"invalid spacing scope");auto a=id(r["a"]),b=id(r["b"]);require(a!=b,"self pair");for(const auto& endpoint:{a,b})require(layerOwners.count(endpoint)||(roles.count(endpoint)&&roles.at(endpoint)=="layer"),"missing spacing layer endpoint");if(a>b)std::swap(a,b);require(rules.insert(r["scope"].dump()+":"+a+":"+b).second,"duplicate spacing relation");require(r["enabled"].is_boolean()&&r["planar"].is_boolean()&&number(r["multiplier"])>=0&&number(r["gap"])>=0,"invalid spacing settings");}
}

Json parse(const std::string& input){
    require(!input.empty()&&input.size()<=maxManifestBytes,"manifest exceeds 8 MiB or is empty");std::vector<std::set<std::string>> names;
    auto callback=[&](int depth,Json::parse_event_t event,Json& value){require(depth<=32,"nesting exceeds 32");if(event==Json::parse_event_t::object_start)names.emplace_back();if(event==Json::parse_event_t::key)require(!names.empty()&&names.back().insert(value.get<std::string>()).second,"duplicate JSON key");if(event==Json::parse_event_t::object_end)names.pop_back();return true;};
    return Json::parse(input,callback);
}
std::string serialize(const Json& d){validate(d,false);const auto out=currentDocument(d).dump(2);require(out.size()<=maxManifestBytes,"manifest exceeds 8 MiB");return out;}
std::string hex(const std::vector<unsigned char>& bytes){static const char* digits="0123456789abcdef";std::string s;s.reserve(bytes.size()*2);for(auto v:bytes){s+=digits[v>>4];s+=digits[v&15];}return s;}
std::vector<unsigned char> unhex(const std::string& s){require(s.size()%2==0&&s.size()<=maxPaintBytes*2,"invalid Paint hex length");std::vector<unsigned char> bytes;bytes.reserve(s.size()/2);auto nibble=[](char c){if(c>='0'&&c<='9')return c-'0';if(c>='a'&&c<='f')return c-'a'+10;throw std::invalid_argument("Recipe: invalid Paint hex");};for(std::size_t i=0;i<s.size();i+=2)bytes.push_back(static_cast<unsigned char>((nibble(s[i])<<4)|nibble(s[i+1])));return bytes;}
std::string digest(const std::vector<unsigned char>& bytes){
#ifdef _WIN32
    BCRYPT_ALG_HANDLE algorithm=nullptr;require(BCryptOpenAlgorithmProvider(&algorithm,BCRYPT_SHA256_ALGORITHM,nullptr,0)>=0,"SHA256 provider unavailable");
    unsigned char result[32]{};const auto status=BCryptHash(algorithm,nullptr,0,const_cast<PUCHAR>(bytes.data()),static_cast<ULONG>(bytes.size()),result,sizeof(result));BCryptCloseAlgorithmProvider(algorithm,0);require(status>=0,"SHA256 failed");return hex(std::vector<unsigned char>(result,result+32));
#else
    (void)bytes;throw std::runtime_error("Recipe attachment hashing requires the qualified Windows host");
#endif
}
void writeNew(const std::filesystem::path& path,const Json& hydrated){
    validate(hydrated,true);require(path.is_absolute(),"save path must be absolute");require(!std::filesystem::exists(path),"destination already exists; choose Save a copy");
    std::filesystem::create_directories(path.parent_path());const auto token=id(hydrated["id"]);const auto folderName="paint-"+token+".payload";
    const auto finalFolder=path.parent_path()/pathFromUTF8(folderName),staged=std::filesystem::path(finalFolder.wstring()+L".tmp"),temp=std::filesystem::path(path.wstring()+L"."+pathFromUTF8(token).wstring()+L".tmp");
    require(!std::filesystem::exists(finalFolder)&&!std::filesystem::exists(staged)&&!std::filesystem::exists(temp),"staging path already exists");
    Json output=currentDocument(hydrated);bool stagedCreated=false,folderPublished=false;std::size_t index=0;
    try{
        paints(output,[&](Json& p){const auto bytes=unhex(p["payload"].get<std::string>());if(!stagedCreated){require(std::filesystem::create_directory(staged),"cannot create attachment staging folder");stagedCreated=true;}const auto name="paint-"+std::to_string(++index)+".cspaint";saveBytes(staged/name,std::string(bytes.begin(),bytes.end()));const auto saved=loadText(staged/name,maxPaintBytes);require(std::vector<unsigned char>(saved.begin(),saved.end())==bytes,"attachment readback mismatch");p["payload"]={{"file",folderName+"/"+name},{"sha256",digest(bytes)},{"bytes",bytes.size()}};});
        const auto manifest=serialize(output);saveBytes(temp,manifest);validate(parse(loadText(temp,maxManifestBytes)),false);
        if(stagedCreated){std::filesystem::rename(staged,finalFolder);folderPublished=true;}
        std::filesystem::rename(temp,path);
    }catch(...){std::error_code ec;std::filesystem::remove(temp,ec);if(stagedCreated)std::filesystem::remove_all(folderPublished?finalFolder:staged,ec);throw;}
}
Json read(const std::filesystem::path& path,bool hydrate,std::string* manifestSHA256){
    const auto input=loadText(path,maxManifestBytes);auto d=parse(input);validate(d,false);d=currentDocument(d);
    if(manifestSHA256)*manifestSHA256=digest(std::vector<unsigned char>(input.begin(),input.end()));
    if(!hydrate)return d;
    paints(d,[&](Json& p){const auto record=p["payload"];const auto file=checkedAttachment(path,record["file"].get<std::string>());const auto data=loadText(file,maxPaintBytes);const std::vector<unsigned char> bytes(data.begin(),data.end());require(bytes.size()==record["bytes"].get<std::size_t>()&&digest(bytes)==record["sha256"].get<std::string>(),"Paint attachment integrity mismatch");p["payload"]=hex(bytes);});validate(d,true);return d;
}
std::filesystem::path pathFromUTF8(const std::string& s){
#if defined(__cpp_char8_t)
    return std::filesystem::path(std::u8string(reinterpret_cast<const char8_t*>(s.data()),s.size()));
#else
    return std::filesystem::u8path(s);
#endif
}
std::filesystem::path attachmentPath(const std::filesystem::path& manifest,const std::string& relative){return checkedAttachment(manifest,relative);}
}
