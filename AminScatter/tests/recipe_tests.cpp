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
    const auto defaults=parse(file(CYRUS_RECIPE_DEFAULTS));validateSettings(defaults);check(fields().size()==262);
    auto imageSettings=defaults;imageSettings["densityCoordinateMode"]=3;validateSettings(imageSettings);
    imageSettings["densityCoordinateMode"]=4;rejected([&]{validateSettings(imageSettings);});
    imageSettings=defaults;imageSettings["densityTileXWU"]=0.;rejected([&]{validateSettings(imageSettings);});
    imageSettings=defaults;imageSettings["densityResponseSamples"]={0.,2.};rejected([&]{validateSettings(imageSettings);});
    imageSettings=defaults;imageSettings["densityFrameBasis"]={1.,0.,0.,0.,1.,0.,0.,0.,1.};rejected([&]{validateSettings(imageSettings);});
    imageSettings["densityFrameOriginWU"]={1.25,-3.5,7.};validateSettings(imageSettings);
    imageSettings["densityFrameBasis"][0]=0.;rejected([&]{validateSettings(imageSettings);});
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
    Json d={{"format","cyrus.planting-recipe"},{"formatVersion",7},{"revision",1},{"presentation",nullptr},{"evaluationContract","CyrusUnified1"},{"sceneSchema",58},{"hostYear",2027},{"id","fixture"},{"name","Complete hillside"},{"unitsPerMetre",100.},{"exportScope","complete-setup"},{"rootSettings",defaults},{"roles",Json::array()},{"layers",Json::array({layer})},{"spacingRelationships",Json::array()}};
    validate(d);
    auto v6=d;v6["formatVersion"]=6;
    v6["rootSettings"].erase("meshMaskSource");v6["layers"][0]["settings"].erase("meshMaskSource");v6["layers"][0]["areas"][0]["settings"].erase("meshMaskSource");
    validate(v6);check(currentDocument(v6)==d);
    auto channelRecipe=v6;channelRecipe["layers"][0]["settings"]["meshMaskEnabled"]=true;channelRecipe["layers"][0]["settings"]["meshMaskChannel"]=2;
    check(currentDocument(channelRecipe)["layers"][0]["settings"]["meshMaskSource"]==1);
    auto smuggled=v6;smuggled["rootSettings"]["meshMaskSource"]=2;rejected([&]{validate(smuggled);});
    auto elevationRecipe=d;elevationRecipe["layers"][0]["settings"]["meshMaskSource"]=2;validate(elevationRecipe);check(parse(elevationRecipe.dump())==elevationRecipe);
    elevationRecipe["layers"][0]["settings"]["meshMaskSource"]=3;rejected([&]{validate(elevationRecipe);});
    for(int year:{2024,2026,2027}){auto portable=currentDocument(d);portable["hostYear"]=year;validate(portable);check(portable["hostYear"]==year);}
    for(int year:{2023,2025,2028}){auto unsupported=currentDocument(d);unsupported["hostYear"]=year;rejected([&]{validate(unsupported);});}
    auto stripGrid=[](Json& settings){for(const auto* name:{"placementMode","gridColumnWU","gridRowWU","gridOriginXWU","gridOriginYWU","gridHeading","gridJitter"})settings.erase(name);};
    auto v5=d;v5["formatVersion"]=5;
    auto stripImage=[](Json& settings){settings.erase("meshMaskSource");for(const auto* key:{"densityCoordinateMode","densityWrapMode","densityTileXWU","densityTileYWU","densityTileLock","densityRepeatX","densityRepeatY","densityHeading","densityOffsetXWU","densityOffsetYWU","densityUOffset","densityVOffset","densityPatternID","densityPatternRevision","densityResponseSamples","densityResponseGraph","densityMapProvenance","densityFrameBasis","densityFrameOriginWU"})settings.erase(key);};
    stripImage(v5["rootSettings"]);stripImage(v5["layers"][0]["settings"]);stripImage(v5["layers"][0]["areas"][0]["settings"]);
    validate(v5);check(currentDocument(v5)==d);auto v4=v5;v4["formatVersion"]=4;v4.erase("revision");v4.erase("presentation");
    auto v3=v4;v3["formatVersion"]=3;stripGrid(v3["rootSettings"]);stripGrid(v3["layers"][0]["settings"]);stripGrid(v3["layers"][0]["areas"][0]["settings"]);
    validate(v3);check(currentDocument(v3)==currentDocument(d));check(v3["formatVersion"]==3);
    auto badGrid=v3;badGrid["rootSettings"]["placementMode"]=1;rejected([&]{validate(badGrid);});
    auto grid=d;grid["layers"][0]["settings"]["placementMode"]=4;grid["layers"][0]["settings"]["gridColumnWU"]=37.125;grid["layers"][0]["settings"]["gridHeading"]=-31.;validate(grid);check(parse(grid.dump())==grid);
    for(const auto* name:{"gridColumnWU","gridRowWU"}){auto invalid=defaults;invalid[name]=0.;rejected([&]{validateSettings(invalid);});}
    auto invalid=defaults;invalid["placementMode"]=5;rejected([&]{validateSettings(invalid);});invalid=defaults;invalid["gridJitter"]=101.;rejected([&]{validateSettings(invalid);});
    auto v2=v3;v2["formatVersion"]=2;
    v2["rootSettings"].erase("procReceiverVariationIDs");v2["layers"][0]["settings"].erase("procReceiverVariationIDs");v2["layers"][0]["areas"][0]["settings"].erase("procReceiverVariationIDs");
    validate(v2);check(currentDocument(v2)==currentDocument(d));check(v2["formatVersion"]==2);
    auto receiverV2=v2;auto& receiverSettings=receiverV2["layers"][0]["settings"];
    receiverSettings["procReceiverNodes"]={nullptr,nullptr};receiverSettings["procReceiverIDs"]={"original-a","original-b"};
    validate(receiverV2);const auto receiverV3=currentDocument(receiverV2);
    check(receiverV3["layers"][0]["settings"]["procReceiverVariationIDs"]==receiverSettings["procReceiverIDs"]);
    auto variation=receiverV3["layers"][0]["settings"];variation["procReceiverVariationIDs"]={};rejected([&]{validateSettings(variation);});
    variation=receiverV3["layers"][0]["settings"];variation["procReceiverVariationIDs"]={"same","same"};rejected([&]{validateSettings(variation);});
    variation["procReceiverVariationIDs"]={"valid",""};rejected([&]{validateSettings(variation);});
    variation["procReceiverVariationIDs"]={"valid",std::string(257,'x')};rejected([&]{validateSettings(variation);});
    variation["procReceiverVariationIDs"]={"valid","not a domain"};rejected([&]{validateSettings(variation);});
    variation["procReceiverVariationIDs"]={"saved-a","saved-b"};validateSettings(variation);
    variation["procReceiverIDs"]={"same-owner","same-owner"};rejected([&]{validateSettings(variation);});
    variation=defaults;variation["procSourceNodes"]={nullptr,nullptr};variation["procSourceIDs"]={"same-source","same-source"};rejected([&]{validateSettings(variation);});
    variation=defaults;variation["sources"]={nullptr,nullptr};variation["sourceRowIDs"]={"same-row","same-row"};rejected([&]{validateSettings(variation);});
    variation=defaults;variation["procReceiverNodes"]={nullptr};variation["procReceiverIDs"]={""};variation["procReceiverVariationIDs"]={"valid"};rejected([&]{validateSettings(variation);});
    auto legacy=v3;legacy["formatVersion"]=1;
    auto strip=[](Json& settings){for(const auto& name:{"orientationMode","orientationBlend","orientationX","orientationY","orientationZ","orientationTarget","procReceiverVariationIDs"})settings.erase(name);};
    strip(legacy["rootSettings"]);strip(legacy["layers"][0]["settings"]);strip(legacy["layers"][0]["areas"][0]["settings"]);
    validate(legacy);check(currentDocument(legacy)==currentDocument(d));check(legacy["formatVersion"]==1);
    auto badLegacy=legacy;badLegacy["rootSettings"]["orientationMode"]=1;rejected([&]{validate(badLegacy);});
    badLegacy=legacy;badLegacy["rootSettings"].erase("amount");rejected([&]{validate(badLegacy);});
    auto direction=d;direction["layers"][0]["settings"]["orientationMode"]=2;direction["layers"][0]["settings"]["orientationY"]=0.;rejected([&]{validate(direction);});
    direction=d;direction["layers"][0]["settings"]["orientationMode"]=3;rejected([&]{validate(direction);});
    direction["layers"][0]["settings"]["orientationTarget"]="aim";
    direction["roles"].push_back({{"id","aim"},{"kind","node"},{"name","Aim pivot"},{"purposes",Json::array({"orientationTarget"})},{"requirements",nullptr}});validate(direction);
    auto broken=d;broken["layers"][0]["areas"][0]["paint"]["payload"]="00";rejected([&]{validate(broken);});
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
    std::filesystem::create_directory(temporary);const auto path=temporary/pathFromUTF8("hillside-\xc3\xa9.csrecipe.json");writeNew(path,d);check(read(path)==currentDocument(d));
    const auto gridPath=temporary/"grid"/"recipe.json";writeNew(gridPath,grid);check(read(gridPath)==currentDocument(grid));
    const auto old=file(path);rejected([&]{writeNew(path,d);});check(file(path)==old);
    const auto manifest=read(path,false);check(manifest["layers"][0]["areas"][0]["paint"]["payload"].is_object());
    const auto relative=manifest["layers"][0]["areas"][0]["paint"]["payload"]["file"].get<std::string>();check(file(path.parent_path()/pathFromUTF8(relative))==std::string(bytes.begin(),bytes.end()));
    auto malformed=manifest;malformed["formatVersion"]=8;put(path,malformed.dump());rejected([&]{read(path);});put(path,old);
    malformed=manifest;malformed["layers"][0]["areas"][0]["paint"]["payload"]["file"]="../outside.cspaint";put(path,malformed.dump());rejected([&]{read(path);});put(path,old);
    put(path.parent_path()/pathFromUTF8(relative),"corrupt");rejected([&]{read(path);});
    // Metadata browsing never reads/hydrates Paint attachments.
    check(read(path,false)["name"]==d["name"]);
    check(!std::filesystem::exists(temporary/"outside.cspaint"));
    std::filesystem::remove_all(temporary);temporary.clear();std::cout<<"PASS: "<<assertions<<" recipe assertions; typed completeness, exact Paint, hashes, bounded parsing, atomic new saves and traversal rejection\n";return 0;
}catch(const std::exception& e){if(!temporary.empty()){std::error_code ignored;std::filesystem::remove_all(temporary,ignored);}std::cerr<<"after "<<assertions<<" assertions: "<<e.what()<<'\n';return 1;}}
