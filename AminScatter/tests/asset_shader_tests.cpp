#include "asset_shader.h"
#include <algorithm>
#include <cmath>
#include <cstdint>
#include <fstream>
#include <iostream>
#include <limits>
#include <stdexcept>
#include <string>
using cyrus::recipes::Json;
using cyrus::assets::validateRendererShaders;
namespace {
unsigned checks=0;
void check(bool value){++checks;if(!value)throw std::runtime_error("Shader assertion "+std::to_string(checks));}
template<class F>void rejects(F function){bool failed=false;try{function();}catch(const std::exception&){failed=true;}check(failed);}
const Json& table(){static const auto value=Json::parse(
#include "asset_adapter_schema.inc"
);return value;}
Json fieldValue(const Json& spec){
    const auto type=spec.at("type").get<std::string>();
    if(type.ends_with("-array")&&type!="empty-array"&&type!="null-array"){auto element=spec;element["type"]=type.substr(0,type.size()-6);auto values=Json::array();for(std::size_t i=0;i<spec.at("minCount").get<std::size_t>();++i)values.push_back(fieldValue(element));return values;}
    if(spec.contains("members"))return spec.at("members").at(0);
    if(type=="empty-array")return Json::array();if(type=="null-array"){auto values=Json::array();for(std::size_t i=0;i<spec.at("count").get<std::size_t>();++i)values.push_back(nullptr);return values;}if(type=="absent-filename")return nullptr;
    if(type=="boolean")return false;if(type=="string")return "fixture";
    double number=0;if(spec.contains("lo"))number=std::max(number,spec.at("lo").get<double>());if(spec.contains("hi"))number=std::min(number,spec.at("hi").get<double>());
    if(type=="integer")return static_cast<std::int64_t>(std::ceil(number));
    if(type=="color"||type=="point3"||type=="point3-distance")return Json::array({number,number,number});return number;
}
Json shader(const char* kind,const char* id){
    Json result={{"id",id},{"kind",kind},{"name","Fixture"},{"properties",Json::object()},{"links",Json::object()}};
    bool found=false;
    for(const auto& spec:table().at("adapters"))if(spec.at("kind")==kind){found=true;for(auto field=spec.at("fields").begin();field!=spec.at("fields").end();++field)result["properties"][field.key()]=fieldValue(field.value());for(const auto& link:spec.at("links"))result["links"][link.get<std::string>()]=nullptr;if(spec.contains("arrayLinks"))for(auto link=spec["arrayLinks"].begin();link!=spec["arrayLinks"].end();++link){auto array=Json::array();for(std::size_t i=0;i<link.value().at("minCount").get<std::size_t>();++i)array.push_back(nullptr);result["links"][link.key()]=array;}if(spec.at("category")=="map")result["roles"]=Json::array();if(spec.contains("output")){result["output"]={{"kind",spec.at("output")},{"properties",Json::object()}};for(const auto& sub:table().at("subobjects"))if(sub.at("kind")==spec.at("output"))for(auto f=sub.at("fields").begin();f!=sub.at("fields").end();++f)result["output"]["properties"][f.key()]=fieldValue(f.value());}}
    check(found);
    for(const auto& spec:table().at("adapters"))if(spec.at("kind")==kind&&spec.contains("coordinates")){
        result["coordinates"]={{"kind",spec.at("coordinates")},{"properties",Json::object()}};
        for(const auto& sub:table().at("subobjects"))if(sub.at("kind")==spec.at("coordinates"))for(auto field=sub.at("fields").begin();field!=sub.at("fields").end();++field)result["coordinates"]["properties"][field.key()]=fieldValue(field.value());
        if(std::string(kind)=="corona-bitmap-v1"){result["file"]="image-file";result["size"]={16,16};result["color"]={{"mode","OCIO_Default"},{"configSHA256",std::string(64,'a')},{"renderingSpace","ACEScg"},{"dataSpace","raw"},{"inputSpace",result["properties"].at("colorSpaceStr")}};}
    }
    return result;
}
Json multi(const std::string& id,const Json& material){return {{"id",id},{"kind","multi-sub-v1"},{"name","Multi"},{"showPreviews",true},{"slots",Json::array({{{"materialID",7},{"name","Sparse"},{"enabled",false},{"material",material}}})}};}
Json fixture(){
    auto physical=shader("corona-physical-v1","physical"),normal=shader("corona-normal-v1","normal");
    check(physical["links"].contains("baseBumpTexmap"));check(normal["links"].contains("normalMap"));
    physical["links"]["baseBumpTexmap"]="normal";normal["links"]["normalMap"]="image";
    auto result=Json{{"version",3},{"rendererProfile",table().at("profile")},{"materials",Json::array({physical,physical,multi("multi","physical")})},{"maps",Json::array({normal,{{"id","image"},{"kind","bitmap"}}})}};
    result["materials"][1]["id"]="second";
    for(const auto& spec:table().at("adapters"))if(spec.at("kind")=="corona-legacy-v1")result["materials"][1]=shader("corona-legacy-v1","legacy");
    for(const auto& spec:table().at("adapters"))if(spec.at("category")=="map"&&spec.at("kind")!="corona-normal-v1"){const auto kind=spec.at("kind").get<std::string>();result["maps"].push_back(shader(kind.c_str(),kind.c_str()));}
    return result;
}
}
int main(int argc,char** argv){try{
    auto graph=fixture();validateRendererShaders(graph);check(true);
    auto glossiness=graph;glossiness["materials"][0]["properties"]["roughnessMode"]=1;validateRendererShaders(glossiness);check(true);
    auto displacement=graph;displacement["materials"][0]["properties"]["displacementMaximum"]=.001;validateRendererShaders(displacement);check(true);
    for(double invalid:{-0.001,1000.001,std::numeric_limits<double>::infinity()}){auto rejected=displacement;rejected["materials"][0]["properties"]["displacementMaximum"]=invalid;rejects([&]{validateRendererShaders(rejected);});}
    auto displacementBad=displacement;displacementBad["materials"][0]["properties"].erase("displacementMaximum");rejects([&]{validateRendererShaders(displacementBad);});
    displacementBad=displacement;displacementBad["materials"][0]["links"]["displacementTexmap"]="image";rejects([&]{validateRendererShaders(displacementBad);});
    // The complete selected Legacy/unit audit requires one inactive color and
    // two SI distances. Other SSS/displacement controls remain closed defaults.
    auto legacySettings=graph;
    legacySettings["materials"][1]["properties"]["sssScatterColor"]={152.80349731445312,106.04425048828125,66.55913543701172};
    legacySettings["materials"][1]["properties"]["sssRadius"]=.01;
    legacySettings["materials"][1]["properties"]["displacementMaximum"]=.001;
    validateRendererShaders(legacySettings);check(true);
    for(const auto* name:{"sssScatterColor","sssRadius","displacementMaximum"}){
        auto malformed=legacySettings;malformed["materials"][1]["properties"].erase(name);rejects([&]{validateRendererShaders(malformed);});
        malformed=legacySettings;malformed["materials"][1]["properties"][name]=nullptr;rejects([&]{validateRendererShaders(malformed);});
    }
    for(const auto* name:{"sssRadius","displacementMaximum"})for(double value:{-0.000001,1000.000001,std::numeric_limits<double>::infinity()}){
        auto malformed=legacySettings;malformed["materials"][1]["properties"][name]=value;rejects([&]{validateRendererShaders(malformed);});
    }
    for(double value:{-0.000001,255.000001,std::numeric_limits<double>::infinity()}){
        auto malformed=legacySettings;malformed["materials"][1]["properties"]["sssScatterColor"]={0.,value,0.};rejects([&]{validateRendererShaders(malformed);});
    }
    for(const auto* name:{"levelSss","absorptionDistance","displacementMinimum","displacementWaterLevelOn"}){
        auto malformed=legacySettings;malformed["materials"][1]["properties"][name]=1.;rejects([&]{validateRendererShaders(malformed);});
    }
    for(const auto* name:{"texmapSssAmount","texmapSssRadius","texmapSssScatterColor","texmapDisplace"}){
        auto malformed=legacySettings;malformed["materials"][1]["links"][name]="image";rejects([&]{validateRendererShaders(malformed);});
    }
    // The outer validator owns legacy records. Their IDs still share the
    // namespace and may be referenced by an admitted Multi material.
    auto ior=graph;ior["materials"][0]["links"]["baseIorTexmap"]="corona-mix-v1";
    for(auto& map:ior["maps"])if(map["kind"]=="corona-mix-v1"){map["properties"]["mixOperation"]=6;map["links"]["texmapTop"]="corona-color-v1";map["links"]["texmapBottom"]="ior-one";}
    for(auto& map:ior["maps"])if(map["kind"]=="corona-color-v1"){map["properties"]["method"]=1;map["properties"]["colorHdr"]={1.6020818948745728,1.6020818948745728,1.6020818948745728};map["properties"]["alpha"]=1;map["properties"]["multiplier"]=1;}
    auto one=shader("corona-color-v1","ior-one");one["properties"]["method"]=1;one["properties"]["colorHdr"]={1.,1.,1.};one["properties"]["alpha"]=1;one["properties"]["multiplier"]=1;ior["maps"].push_back(one);validateRendererShaders(ior);check(true);
    auto iorBad=ior;iorBad["materials"][0]["links"]["baseIorTexmap"]="physical";rejects([&]{validateRendererShaders(iorBad);});
    iorBad=ior;iorBad["materials"][0]["links"].erase("baseIorTexmap");rejects([&]{validateRendererShaders(iorBad);});
    auto standard=graph;standard["materials"].push_back({{"id","standard"},{"kind","standard-blinn"},{"maps",Json::array({{{"map","normal"}}})}});standard["materials"][2]["slots"].push_back({{"materialID",31},{"name","Legacy"},{"enabled",true},{"material","standard"}});validateRendererShaders(standard);check(true);
    auto shared=graph;shared["materials"].push_back(multi("shared","physical"));validateRendererShaders(shared);check(true);
    auto sparse=graph;sparse["materials"][2]["slots"].push_back({{"materialID",65535},{"name","Unused"},{"enabled",false},{"material",nullptr}});validateRendererShaders(sparse);check(true);
    auto nullOnly=graph;nullOnly["materials"][2]["slots"][0]["material"]=nullptr;validateRendererShaders(nullOnly);check(true);
    auto empty=graph;empty["materials"][2]["slots"]=Json::array();rejects([&]{validateRendererShaders(empty);});
    auto bad=graph;bad["version"]=2;rejects([&]{validateRendererShaders(bad);});
    for(const auto* key:{"id","hostYear","pluginVersion"}){bad=graph;bad["rendererProfile"].erase(key);rejects([&]{validateRendererShaders(bad);});}
    bad=graph;bad["rendererProfile"]["pluginVersion"]="different";rejects([&]{validateRendererShaders(bad);});bad=graph;bad["rendererProfile"]["hostYear"]=2027.0;rejects([&]{validateRendererShaders(bad);});bad=graph;bad["rendererProfile"]["extra"]=true;rejects([&]{validateRendererShaders(bad);});
    for(const auto* collection:{"materials","maps"}){
        bad=graph;bad[collection][0]["id"]="image";rejects([&]{validateRendererShaders(bad);});
        bad=graph;bad[collection][0]["kind"]="user-constructor";rejects([&]{validateRendererShaders(bad);});
        bad=graph;bad[collection][0]["extra"]=true;rejects([&]{validateRendererShaders(bad);});
        bad=graph;bad[collection][0]["name"]=std::string(161,'x');rejects([&]{validateRendererShaders(bad);});
        bad=graph;bad[collection][0]["id"]="../escape";rejects([&]{validateRendererShaders(bad);});
        bad=graph;bad[collection][0]["id"]=std::string("with\0nul",8);rejects([&]{validateRendererShaders(bad);});
        bad=graph;bad[collection][0]["properties"]["arbitrary"]=1;rejects([&]{validateRendererShaders(bad);});
        bad=graph;bad[collection][0]["links"]["arbitrary"]=nullptr;rejects([&]{validateRendererShaders(bad);});
        bad=graph;bad[collection]=Json::array();for(unsigned i=0;i<129;++i)bad[collection].push_back(graph[collection][0]);rejects([&]{validateRendererShaders(bad);});
    }
    bad=graph;bad["maps"][0]["roles"]={"texture-role"};rejects([&]{validateRendererShaders(bad);});
    bad=graph;bad["maps"][0]["links"]["normalMap"]="physical";rejects([&]{validateRendererShaders(bad);});
    bad=graph;bad["maps"][0]["links"]["normalMap"]="missing";rejects([&]{validateRendererShaders(bad);});
    bad=graph;bad["maps"][0]["links"]["normalMap"]=false;rejects([&]{validateRendererShaders(bad);});
    bad=graph;bad["maps"][0]["links"]["normalMap"]="normal";rejects([&]{validateRendererShaders(bad);});
    bad=graph;auto otherNormal=bad["maps"][0];otherNormal["id"]="other-normal";otherNormal["links"]["normalMap"]="normal";bad["maps"][0]["links"]["normalMap"]="other-normal";bad["maps"].push_back(otherNormal);rejects([&]{validateRendererShaders(bad);});
    bad=graph;bad["maps"][0]["properties"]["multiplier"]=std::numeric_limits<double>::infinity();rejects([&]{validateRendererShaders(bad);});
    bad=graph;bad["maps"][0]["properties"]["multiplier"]=std::numeric_limits<double>::quiet_NaN();rejects([&]{validateRendererShaders(bad);});
    // New map kinds are finite, keep empty external roles, and cannot be put
    // into the material namespace or carry package-selected constructors.
    for(std::size_t i=2;i<graph["maps"].size();++i){
        bad=graph;bad["maps"][i]["roles"]={"external"};rejects([&]{validateRendererShaders(bad);});
        bad=graph;bad["maps"][i]["constructor"]="execute";rejects([&]{validateRendererShaders(bad);});
        bad=graph;bad["materials"].push_back(bad["maps"][i]);bad["maps"].erase(bad["maps"].begin()+static_cast<std::ptrdiff_t>(i));rejects([&]{validateRendererShaders(bad);});
    }
    auto mix=shader("max-mix-v1","mix-output");
    auto outputGraph=graph;outputGraph["maps"].push_back(mix);validateRendererShaders(outputGraph);check(true);
    auto outputBad=outputGraph;outputBad["maps"].back().erase("output");rejects([&]{validateRendererShaders(outputBad);});
    outputBad=outputGraph;outputBad["maps"].back()["output"]["kind"]="script-output";rejects([&]{validateRendererShaders(outputBad);});
    outputBad=outputGraph;outputBad["maps"].back()["output"]["extra"]=true;rejects([&]{validateRendererShaders(outputBad);});
    for(auto f=mix["output"]["properties"].begin();f!=mix["output"]["properties"].end();++f){
        outputBad=outputGraph;outputBad["maps"].back()["output"]["properties"].erase(f.key());rejects([&]{validateRendererShaders(outputBad);});
        outputBad=outputGraph;outputBad["maps"].back()["output"]["properties"][f.key()]=Json::object();rejects([&]{validateRendererShaders(outputBad);});
    }
    outputBad=outputGraph;outputBad["maps"].back()["output"]["properties"]["RGB_Level"]=-1.;rejects([&]{validateRendererShaders(outputBad);});
    outputBad=outputGraph;outputBad["maps"].back()["output"]["properties"]["RGB_Offset"]=std::numeric_limits<double>::infinity();rejects([&]{validateRendererShaders(outputBad);});
    auto composite=shader("max-composite-v1","layers");
    auto arrayGraph=graph;arrayGraph["maps"].push_back(composite);validateRendererShaders(arrayGraph);check(true);
    for(const auto* key:{"mapEnabled","maskEnabled","blendMode","layername","dlgOpened","opacity"}){
        auto arrayBad=arrayGraph;arrayBad["maps"].back()["properties"][key]=Json::array();rejects([&]{validateRendererShaders(arrayBad);});
        arrayBad=arrayGraph;arrayBad["maps"].back()["properties"][key].push_back(arrayBad["maps"].back()["properties"][key][0]);rejects([&]{validateRendererShaders(arrayBad);});
        arrayBad=arrayGraph;arrayBad["maps"].back()["properties"][key][0]=Json::object();rejects([&]{validateRendererShaders(arrayBad);});
    }
    for(const auto* key:{"mapList","Mask"}){
        auto arrayBad=arrayGraph;arrayBad["maps"].back()["links"][key]=nullptr;rejects([&]{validateRendererShaders(arrayBad);});
        arrayBad=arrayGraph;arrayBad["maps"].back()["links"][key][0]="missing";rejects([&]{validateRendererShaders(arrayBad);});
        arrayBad=arrayGraph;arrayBad["maps"].back()["links"][key][0]="physical";rejects([&]{validateRendererShaders(arrayBad);});
        arrayBad=arrayGraph;arrayBad["maps"].back()["links"][key][0]="layers";arrayBad["maps"].back()["properties"]["mapEnabled"][0]=false;rejects([&]{validateRendererShaders(arrayBad);});
    }
    auto arrayBad=arrayGraph;arrayBad["maps"].back()["properties"]["blendMode"][0]=1;rejects([&]{validateRendererShaders(arrayBad);});
    arrayBad=arrayGraph;arrayBad["maps"].back()["properties"]["opacity"][0]=std::numeric_limits<double>::quiet_NaN();rejects([&]{validateRendererShaders(arrayBad);});
    auto largeArrays=arrayGraph;for(auto f=largeArrays["maps"].back()["properties"].begin();f!=largeArrays["maps"].back()["properties"].end();++f)f.value()=Json(128,f.value()[0]);
    for(auto f=largeArrays["maps"].back()["links"].begin();f!=largeArrays["maps"].back()["links"].end();++f)f.value()=Json(128,nullptr);
    validateRendererShaders(largeArrays);check(true);largeArrays["maps"].back()["links"]["Mask"].push_back(nullptr);rejects([&]{validateRendererShaders(largeArrays);});
    auto forest=shader("forest-color-v1","palette");auto forestGraph=graph;forestGraph["maps"].push_back(forest);validateRendererShaders(forestGraph);check(true);
    for(const auto* key:{"maponlist","colorList","problist"}){arrayBad=forestGraph;arrayBad["maps"].back()["properties"][key].erase(arrayBad["maps"].back()["properties"][key].begin());rejects([&]{validateRendererShaders(arrayBad);});}
    arrayBad=forestGraph;arrayBad["maps"].back()["links"]["mapList"][9]="palette";rejects([&]{validateRendererShaders(arrayBad);});
    auto correction=shader("corona-color-correct-v1","correction");auto correctionGraph=graph;correctionGraph["maps"].push_back(correction);
    for(const auto* key:{"lutEnable","curveEnabled","showCopiedMap"}){arrayBad=correctionGraph;arrayBad["maps"].back()["properties"][key]=true;rejects([&]{validateRendererShaders(arrayBad);});}
    arrayBad=correctionGraph;arrayBad["maps"].back()["properties"]["lutFile"]="C:/external.cube";rejects([&]{validateRendererShaders(arrayBad);});
    arrayBad=correctionGraph;arrayBad["maps"].back()["properties"]["additionalInputTexmap"][99]="image";rejects([&]{validateRendererShaders(arrayBad);});
    arrayBad=correctionGraph;arrayBad["maps"].back()["properties"]["additionalInputTexmap"].push_back(nullptr);rejects([&]{validateRendererShaders(arrayBad);});
    arrayBad=correctionGraph;arrayBad["maps"].back()["properties"]["curveMasterNodes"].push_back({0,0});rejects([&]{validateRendererShaders(arrayBad);});
    arrayBad=correctionGraph;arrayBad["maps"].back()["links"]["copiedMap"]="image";rejects([&]{validateRendererShaders(arrayBad);});
    arrayBad=correctionGraph;arrayBad["maps"].back()["properties"]["numIMultipleOutputChannels"]=1;rejects([&]{validateRendererShaders(arrayBad);});
    auto image=shader("corona-bitmap-v1","corona-image");auto imageGraph=graph;imageGraph["maps"].push_back(image);validateRendererShaders(imageGraph);check(true);
    for(const auto* key:{"file","size","color","coordinates","output"}){auto imageBad=imageGraph;imageBad["maps"].back().erase(key);rejects([&]{validateRendererShaders(imageBad);});}
    for(const auto* key:{"gamma","useLegacyGamma","showLegacyGamma","colorSpace","colorSpaceStr"}){auto imageBad=imageGraph;imageBad["maps"].back()["properties"][key]=Json::object();rejects([&]{validateRendererShaders(imageBad);});}
    auto imageBad=imageGraph;imageBad["maps"].back()["properties"]["gamma"]=2.2;rejects([&]{validateRendererShaders(imageBad);});
    imageBad=imageGraph;imageBad["maps"].back()["properties"]["useLegacyGamma"]=true;rejects([&]{validateRendererShaders(imageBad);});
    imageBad=imageGraph;imageBad["maps"].back()["filename"]="C:/unvalidated.png";rejects([&]{validateRendererShaders(imageBad);});
    imageBad=imageGraph;imageBad["maps"].back()["file"]="../escape";rejects([&]{validateRendererShaders(imageBad);});
    for(const auto& size:Json::array({Json::array({0,1}),Json::array({8193,1}),Json::array({1.,1}),Json::array({1}),Json::array({1,1,1})})){imageBad=imageGraph;imageBad["maps"].back()["size"]=size;rejects([&]{validateRendererShaders(imageBad);});}
    imageBad=imageGraph;imageBad["maps"].back()["color"]["inputGamma"]="auto";rejects([&]{validateRendererShaders(imageBad);});
    imageBad=imageGraph;imageBad["maps"].back()["color"]["inputSpace"]="Gamma 2.2 / Rec.709";rejects([&]{validateRendererShaders(imageBad);});
    imageBad=imageGraph;imageBad["maps"].back()["color"]["configSHA256"]="invalid";rejects([&]{validateRendererShaders(imageBad);});
    imageBad=imageGraph;imageBad["maps"].back()["coordinates"]["kind"]="arbitrary-uvw";rejects([&]{validateRendererShaders(imageBad);});
    imageBad=imageGraph;imageBad["maps"].back()["coordinates"]["properties"]["realWorldScale"]=true;rejects([&]{validateRendererShaders(imageBad);});
    imageBad=imageGraph;imageBad["maps"].back()["coordinates"]["properties"]["domeOrigin"][1]=std::numeric_limits<double>::infinity();rejects([&]{validateRendererShaders(imageBad);});
    for(auto field=image["coordinates"]["properties"].begin();field!=image["coordinates"]["properties"].end();++field){imageBad=imageGraph;imageBad["maps"].back()["coordinates"]["properties"].erase(field.key());rejects([&]{validateRendererShaders(imageBad);});imageBad=imageGraph;imageBad["maps"].back()["coordinates"]["properties"][field.key()]=Json::object();rejects([&]{validateRendererShaders(imageBad);});}
    auto gradient=shader("max-gradient-v1","ordinary-gradient");
    auto gradientGraph=graph;gradientGraph["maps"].push_back(gradient);validateRendererShaders(gradientGraph);check(true);
    gradientGraph["maps"].back()["coordinates"]["properties"]["W_Angle"]=-90.;
    gradientGraph["maps"].back()["links"]["map1"]="image";gradientGraph["maps"].back()["properties"]["map1Enabled"]=false;validateRendererShaders(gradientGraph);check(true);
    gradientGraph["maps"].back()["coordinates"]["properties"]["W_Angle"]=90.;validateRendererShaders(gradientGraph);check(true);
    for(const auto* key:{"coordinates","output"}){auto gradientBad=gradientGraph;gradientBad["maps"].back().erase(key);rejects([&]{validateRendererShaders(gradientBad);});}
    auto gradientBad=gradientGraph;gradientBad["maps"].back()["coordinates"]["kind"]="corona-uvw-v1";rejects([&]{validateRendererShaders(gradientBad);});
    gradientBad=gradientGraph;gradientBad["maps"].back()["coordinates"]["properties"]["realWorldScale"]=true;rejects([&]{validateRendererShaders(gradientBad);});
    gradientBad=gradientGraph;gradientBad["maps"].back()["coordinates"]["properties"]["W_Angle"]=-45.;rejects([&]{validateRendererShaders(gradientBad);});
    for(const auto* key:{"U_Offset","V_Offset","U_Tiling","V_Tiling","Noise_On","Noise_Animate"}){gradientBad=gradientGraph;gradientBad["maps"].back()["coordinates"]["properties"][key]=1.5;rejects([&]{validateRendererShaders(gradientBad);});}
    gradientBad=gradientGraph;gradientBad["maps"].back()["coordinates"]["properties"]["realWorldWidth"]=.01;rejects([&]{validateRendererShaders(gradientBad);});
    gradientBad=gradientGraph;gradientBad["maps"].back()["file"]="unvalidated";rejects([&]{validateRendererShaders(gradientBad);});
    gradientBad=gradientGraph;gradientBad["maps"].back()["kind"]="max-gradient-ramp-v1";rejects([&]{validateRendererShaders(gradientBad);});
    for(const auto* key:{"map1","map2","map3"}){
        gradientBad=gradientGraph;gradientBad["maps"].back()["links"][key]="physical";rejects([&]{validateRendererShaders(gradientBad);});
        gradientBad=gradientGraph;gradientBad["maps"].back()["links"][key]="missing";rejects([&]{validateRendererShaders(gradientBad);});
        gradientBad=gradientGraph;gradientBad["maps"].back()["links"][key]="ordinary-gradient";rejects([&]{validateRendererShaders(gradientBad);});
    }
    for(auto field=gradient["coordinates"]["properties"].begin();field!=gradient["coordinates"]["properties"].end();++field){
        gradientBad=gradientGraph;gradientBad["maps"].back()["coordinates"]["properties"].erase(field.key());rejects([&]{validateRendererShaders(gradientBad);});
        gradientBad=gradientGraph;gradientBad["maps"].back()["coordinates"]["properties"][field.key()]=Json::object();rejects([&]{validateRendererShaders(gradientBad);});
        gradientBad=gradientGraph;gradientBad["maps"].back()["coordinates"]["properties"][field.key()]=std::numeric_limits<double>::infinity();rejects([&]{validateRendererShaders(gradientBad);});
    }
    auto capacity=graph;capacity["maps"]=Json::array();capacity["materials"]=Json::array();
    for(unsigned i=0;i<128;++i){auto map=shader("max-vertex-color-v1",("channel-"+std::to_string(i)).c_str());capacity["maps"].push_back(map);}
    capacity["resourceProfile"]="plant-images-v1";validateRendererShaders(capacity);check(true);
    auto extraMap=capacity["maps"][0];extraMap["id"]="channel-128";capacity["maps"].push_back(extraMap);rejects([&]{validateRendererShaders(capacity);});
    capacity["resourceProfile"]="plant-assets-v1";validateRendererShaders(capacity);check(true);
    for(unsigned i=129;i<256;++i){extraMap["id"]="channel-"+std::to_string(i);capacity["maps"].push_back(extraMap);}validateRendererShaders(capacity);check(true);
    extraMap["id"]="channel-256";capacity["maps"].push_back(extraMap);rejects([&]{validateRendererShaders(capacity);});
    capacity["maps"].erase(capacity["maps"].end()-1);capacity["resourceProfile"]="unknown-profile";rejects([&]{validateRendererShaders(capacity);});
    capacity["resourceProfile"]="plant-assets-v1";for(unsigned i=0;i<129;++i)capacity["materials"].push_back(multi("material-"+std::to_string(i),nullptr));rejects([&]{validateRendererShaders(capacity);});
    capacity["materials"]=Json::array({multi("oversized-slots",nullptr)});capacity["materials"][0]["slots"]=Json::array();for(unsigned i=1;i<=129;++i)capacity["materials"][0]["slots"].push_back({{"materialID",i},{"name","slot"},{"enabled",true},{"material",nullptr}});rejects([&]{validateRendererShaders(capacity);});
    bad=graph;bad["materials"][2]["slots"][0]["material"]="image";rejects([&]{validateRendererShaders(bad);});
    bad=graph;bad["materials"][2]["slots"][0]["material"]="multi";rejects([&]{validateRendererShaders(bad);});
    for(const auto& value:Json::array({0,-1,65536,1.5,"1",nullptr})) {bad=graph;bad["materials"][2]["slots"][0]["materialID"]=value;rejects([&]{validateRendererShaders(bad);});}
    bad=graph;bad["materials"][2]["slots"].push_back(bad["materials"][2]["slots"][0]);rejects([&]{validateRendererShaders(bad);});
    bad=graph;bad["materials"][2]["slots"][0]["enabled"]=1;rejects([&]{validateRendererShaders(bad);});
    bad=graph;bad["materials"][2].erase("showPreviews");rejects([&]{validateRendererShaders(bad);});bad=graph;bad["materials"][2]["showPreviews"]=1;rejects([&]{validateRendererShaders(bad);});
    // Check every production-table property, rather than hard-coding only
    // fields present in a convenient fixture. Wrong types never coerce.
    for(const auto* collection:{"materials","maps"})for(std::size_t i=0;i<graph[collection].size();++i){const auto& node=graph[collection][i];if(!node.contains("properties"))continue;
        for(auto field=node["properties"].begin();field!=node["properties"].end();++field){
            bad=graph;bad[collection][i]["properties"].erase(field.key());rejects([&]{validateRendererShaders(bad);});
            bad=graph;bad[collection][i]["properties"][field.key()]=Json::object();rejects([&]{validateRendererShaders(bad);});
        }
    }
    for(const auto& spec:table()["adapters"]){const auto kind=spec.at("kind").get<std::string>();if(kind=="multi-sub-v1")continue;
        const auto* collection=spec.at("category")=="map"?"maps":"materials";std::size_t index=0;
        for(;index<graph[collection].size();++index)if(graph[collection][index].at("kind")==kind)break;
        check(index<graph[collection].size());
        for(auto field=spec["fields"].begin();field!=spec["fields"].end();++field){const auto type=field.value().at("type").get<std::string>();
            if(type=="boolean"){bad=graph;bad[collection][index]["properties"][field.key()]=1;rejects([&]{validateRendererShaders(bad);});}
            if(type=="integer"){bad=graph;bad[collection][index]["properties"][field.key()]=0.5;rejects([&]{validateRendererShaders(bad);});}
            if(field.value().contains("members")){bad=graph;bad[collection][index]["properties"][field.key()]=1234567;rejects([&]{validateRendererShaders(bad);});}
            for(const auto* bound:{"lo","hi"})if(field.value().contains(bound)){const auto outside=field.value().at(bound).get<double>()+(std::string(bound)=="lo"?-1.:1.);bad=graph;bad[collection][index]["properties"][field.key()]=(type=="color"||type=="point3"||type=="point3-distance")?Json::array({outside,outside,outside}):type=="integer"?Json(static_cast<std::int64_t>(outside)):Json(outside);rejects([&]{validateRendererShaders(bad);});}
        }
    }
    // Every depth path matters even when a shared descendant was visited by
    // an earlier root. Eight nodes are accepted; nine reject regardless order.
    auto chain=graph;chain["materials"]=Json::array();chain["maps"]=Json::array();chain["materials"].push_back({{"id","leaf"},{"kind","standard-blinn"},{"maps",Json::array()}});
    std::string previous="leaf";for(unsigned i=0;i<7;++i){const auto id="a"+std::to_string(i);chain["materials"].push_back(multi(id,previous));previous=id;}validateRendererShaders(chain);check(true);
    chain["materials"].push_back(multi("too-deep",previous));rejects([&]{validateRendererShaders(chain);});std::reverse(chain["materials"].begin(),chain["materials"].end());rejects([&]{validateRendererShaders(chain);});
    // Standard is a real graph edge: six Multis + Standard + bitmap is eight.
    auto mixed=chain;mixed["materials"]=Json::array({{{"id","leaf"},{"kind","standard-blinn"},{"maps",Json::array({{{"map","image"}}})}}});mixed["maps"]=Json::array({{{"id","image"},{"kind","bitmap"}}});previous="leaf";
    for(unsigned i=0;i<6;++i){const auto id="mixed"+std::to_string(i);mixed["materials"].push_back(multi(id,previous));previous=id;}validateRendererShaders(mixed);check(true);
    auto sharedNormal=shader("corona-normal-v1","shared-normal");sharedNormal["links"]["normalMap"]="image";mixed["maps"].push_back(sharedNormal);mixed["materials"][0]["maps"][0]["map"]="shared-normal";rejects([&]{validateRendererShaders(mixed);});
    std::reverse(mixed["materials"].begin(),mixed["materials"].end());rejects([&]{validateRendererShaders(mixed);});
    auto cycle=graph;cycle["materials"].push_back(multi("a","b"));cycle["materials"].push_back(multi("b","a"));rejects([&]{validateRendererShaders(cycle);});
    if(argc>1){check(argc==2);std::ifstream input(argv[1],std::ios::binary|std::ios::ate);check(input.good()&&input.tellg()>=0&&input.tellg()<=2*1024*1024);input.seekg(0);Json actual;input>>actual;validateRendererShaders(actual);check(true);std::cout<<"Owned host shader fixture accepted\n";}
    std::cout<<checks<<" renderer shader assertions passed\n";return 0;
}catch(const std::exception& error){std::cerr<<error.what()<<'\n';return 1;}}
