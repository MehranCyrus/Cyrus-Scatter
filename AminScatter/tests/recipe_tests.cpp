#include "recipes.h"
#include "brush.h"
#include <chrono>
#include <fstream>
#include <iostream>
#include <stdexcept>
using namespace cyrus::recipes;
namespace {
unsigned assertions=0;
void check(bool v){++assertions;if(!v)throw std::runtime_error("Recipe assertion "+std::to_string(assertions));}
template<class F>void rejected(F f){bool failed=false;try{f();}catch(const std::exception&){failed=true;}check(failed);}
std::string file(const std::filesystem::path& p){std::ifstream in(p,std::ios::binary);return {std::istreambuf_iterator<char>(in),std::istreambuf_iterator<char>()};}
void put(const std::filesystem::path& p,const std::string& s){std::ofstream out(p,std::ios::binary|std::ios::trunc);out<<s;}
}
int main(){std::filesystem::path temporary;try{
    const auto defaults=parse(file(CYRUS_RECIPE_DEFAULTS));validateSettings(defaults);check(fields().size()==228);
    auto settings=defaults;settings.erase("paintDensity");rejected([&]{validateSettings(settings);});
    settings=defaults;settings["unknown"]=1;rejected([&]{validateSettings(settings);});
    settings=defaults;settings["alignNormal"]=1;rejected([&]{validateSettings(settings);});
    settings=defaults;settings["distributionMode"]=2;rejected([&]{validateSettings(settings);});
    settings=defaults;settings["meshMaskComponent"]=0;rejected([&]{validateSettings(settings);});
    settings=defaults;settings["meshMaskMinimum"]=2.;settings["meshMaskMaximum"]=1.;rejected([&]{validateSettings(settings);});
    settings=defaults;settings["meshMaskSamples"]={0.,1.1};rejected([&]{validateSettings(settings);});
    settings=defaults;settings["sourceWeights"]={-1.};rejected([&]{validateSettings(settings);});
    settings=defaults;settings["pathIDs"]={1,1};settings["pathJoins"]={1,2};settings["patternPaths"]={"p","p"};rejected([&]{validateSettings(settings);});
    settings=defaults;settings["sourceRowIDs"]={"row-a"};rejected([&]{validateSettings(settings);});
    settings=defaults;settings["viewportMode"]=4;rejected([&]{validateSettings(settings);});
    settings=defaults;settings["randomSeed"]=2147483648LL;rejected([&]{validateSettings(settings);});
    cyrus::brush::Document brush;brush.surface=42;brush.contours={{{0.123456789012345,0},{4,0},{4,4},{0,4}},{{1,1},{1,2},{2,2},{2,1}},{{8,0},{10,0},{10,2},{8,2}}};
    brush.falloff.inside=.37;brush.falloff.outside=.11;brush.falloff.scaleMin=.2;brush.falloff.scaleMax=1.4;brush.falloff.scale=false;brush.falloff.densityCurve={0,.25,1};
    const auto bytes=cyrus::brush::encode(brush);check(cyrus::brush::encode(cyrus::brush::decode(bytes))==bytes);check(unhex(hex(bytes))==bytes);
    check(digest({})=="e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855");
    rejected([&]{unhex("0");});rejected([&]{unhex("gg");});
    Json paint={{"payload",hex(bytes)},{"receiverRole",nullptr},{"radius",.5},{"erase",true},{"frame",Json::array({1.,0.,0.,0.,1.,0.,0.,0.,1.,0.,0.,0.})}};
    Json layer={{"id","canopy"},{"name","Canopy"},{"enabled",true},{"visible",false},{"settings",defaults},{"paint",nullptr},{"areas",Json::array()}};
    layer["areas"].push_back({{"id","bed"},{"settings",defaults},{"receiverRole",nullptr},{"paint",paint}});
    Json d={{"format","cyrus.planting-recipe"},{"formatVersion",1},{"evaluationContract","CyrusUnified1"},{"sceneSchema",58},{"hostYear",2027},{"id","fixture"},{"name","Complete hillside"},{"unitsPerMetre",100.},{"exportScope","complete-setup"},{"rootSettings",defaults},{"roles",Json::array()},{"layers",Json::array({layer})},{"spacingRelationships",Json::array()}};
    validate(d);auto broken=d;broken["layers"][0]["areas"][0]["paint"]["payload"]="00";rejected([&]{validate(broken);});
    broken=d;broken["exportScope"]="rules-only";rejected([&]{validate(broken);});
    broken=d;broken["layers"][0]["settings"]["densityMap"]="absent";rejected([&]{validate(broken);});
    broken=d;broken["layers"].push_back(layer);rejected([&]{validate(broken);});
    broken=d;broken["roles"].push_back({{"id","external"},{"kind","layer"},{"name","Neighbor"},{"purposes",Json::array({"spacing"})},{"requirements",nullptr}});
    broken["spacingRelationships"].push_back({{"scope",2},{"a","canopy"},{"b","external"},{"enabled",false},{"multiplier",1.},{"gap",.25},{"planar",true}});validate(broken);check(broken["spacingRelationships"][0]["enabled"]==false);
    broken["spacingRelationships"].push_back(broken["spacingRelationships"][0]);rejected([&]{validate(broken);});
    broken=d;broken["spacingRelationships"].push_back({{"scope",2},{"a","canopy"},{"b","bed"},{"enabled",true},{"multiplier",1.},{"gap",0.},{"planar",true}});rejected([&]{validate(broken);});
    broken=d;broken["layers"][0]["areas"]=Json::array();for(int i=0;i<129;++i)broken["layers"][0]["areas"].push_back({{"id","area-"+std::to_string(i)},{"settings",defaults},{"receiverRole",nullptr},{"paint",nullptr}});rejected([&]{validate(broken);});
    rejected([&]{parse("{\"formatVersion\":1,\"formatVersion\":2}");});rejected([&]{parse(std::string(maxManifestBytes+1,' '));});
    std::string deep="0";for(int i=0;i<35;++i)deep="["+deep+"]";rejected([&]{parse(deep);});
    rejected([&]{parse("{\"bad\":NaN}");});rejected([&]{parse("{\"bad\":\"\xff\"}");});
    temporary=std::filesystem::temp_directory_path()/pathFromUTF8("cyrus-recipe-test-"+std::to_string(std::chrono::steady_clock::now().time_since_epoch().count()));
    std::filesystem::create_directory(temporary);const auto path=temporary/pathFromUTF8("hillside-\xc3\xa9.csrecipe.json");writeNew(path,d);check(read(path)==d);
    const auto old=file(path);rejected([&]{writeNew(path,d);});check(file(path)==old);
    const auto manifest=read(path,false);check(manifest["layers"][0]["areas"][0]["paint"]["payload"].is_object());
    const auto relative=manifest["layers"][0]["areas"][0]["paint"]["payload"]["file"].get<std::string>();check(file(path.parent_path()/pathFromUTF8(relative))==std::string(bytes.begin(),bytes.end()));
    auto malformed=manifest;malformed["formatVersion"]=2;put(path,malformed.dump());rejected([&]{read(path);});put(path,old);
    malformed=manifest;malformed["layers"][0]["areas"][0]["paint"]["payload"]["file"]="../outside.cspaint";put(path,malformed.dump());rejected([&]{read(path);});put(path,old);
    put(path.parent_path()/pathFromUTF8(relative),"corrupt");rejected([&]{read(path);});
    // Metadata browsing never reads/hydrates Paint attachments.
    check(read(path,false)["name"]==d["name"]);
    check(!std::filesystem::exists(temporary/"outside.cspaint"));
    std::filesystem::remove_all(temporary);temporary.clear();std::cout<<"PASS: "<<assertions<<" recipe assertions; typed completeness, exact Paint, hashes, bounded parsing, atomic new saves and traversal rejection\n";return 0;
}catch(const std::exception& e){if(!temporary.empty()){std::error_code ignored;std::filesystem::remove_all(temporary,ignored);}std::cerr<<e.what()<<'\n';return 1;}}
