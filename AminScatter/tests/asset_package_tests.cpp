#include "asset_package.h"
#include "prepared_package_leases.h"
#include "asset_mesh.h"
#include "asset_bitmap.h"
#include "recipe_store.h"
#include "brush.h"
#include <chrono>
#include <fstream>
#include <iostream>
#include <limits>
#include <stdexcept>
using namespace cyrus;
using recipes::Json;
namespace {
unsigned checks=0;
void check(bool ok){++checks;if(!ok)throw std::runtime_error("Package assertion "+std::to_string(checks));}
template<class F>void rejects(F f){bool failed=false;try{f();}catch(const std::exception&){failed=true;}check(failed);}
std::string load(const std::filesystem::path& path){std::ifstream in(path,std::ios::binary);return {std::istreambuf_iterator<char>(in),std::istreambuf_iterator<char>()};}
void put(const std::filesystem::path& path,const std::string& bytes){std::filesystem::create_directories(path.parent_path());std::ofstream out(path,std::ios::binary);out<<bytes;if(!out)throw std::runtime_error("Fixture write");}
std::string sha(const std::string& bytes){return recipes::digest({bytes.begin(),bytes.end()});}
const Json& shaderTable(){static const auto table=Json::parse(
#include "asset_adapter_schema.inc"
);return table;}
Json subobject(const char* kind){
    for(const auto& spec:shaderTable().at("subobjects"))if(spec.at("kind")==kind){
        Json values=Json::object();
        for(auto field=spec.at("fields").begin();field!=spec.at("fields").end();++field){
            const auto& rule=field.value();const auto type=rule.at("type").get<std::string>();Json value;
            if(rule.contains("members"))value=rule.at("members")[0];
            else if(type=="boolean")value=false;
            else if(type=="color"||type=="point3"||type=="point3-distance"){const auto lo=rule.value("lo",0.);value={lo,lo,lo};}
            else if(type=="integer")value=static_cast<std::int64_t>(rule.value("lo",0.));
            else value=rule.value("lo",0.);
            values[field.key()]=value;
        }
        return {{"kind",kind},{"properties",values}};
    }
    throw std::runtime_error("Unknown fixture subobject");
}
Json shader(const char* kind,const char* id){
    Json result={{"id",id},{"kind",kind},{"name","Renderer fixture"},{"properties",Json::object()},{"links",Json::object()}};bool found=false;
    for(const auto& adapter:shaderTable().at("adapters"))if(adapter.at("kind")==kind){found=true;
        for(auto field=adapter.at("fields").begin();field!=adapter.at("fields").end();++field){const auto& spec=field.value();const auto type=spec.at("type").get<std::string>();Json value;
            if(spec.contains("members"))value=spec.at("members")[0];else if(type=="boolean")value=false;else if(type=="color"){const auto number=spec.value("lo",0.);value={number,number,number};}else if(type=="integer")value=static_cast<std::int64_t>(spec.value("lo",0.));else value=spec.value("lo",0.);
            result["properties"][field.key()]=value;
        }
        for(const auto& link:adapter.at("links"))result["links"][link.get<std::string>()]=nullptr;
        if(adapter.at("category")=="map")result["roles"]=Json::array();
    }check(found);return result;
}
}
int main(){std::filesystem::path folder;try{
    {
        assets::PreparedPackageLeases leases;
        auto make=[](std::uint64_t bytes=1){auto p=std::make_shared<assets::PreparedPackage>();p->payloadBytes=bytes;
            p->metadata={{"graph",{{"nodes",Json::array({Json::object()})},{"maps",Json::array()},{"materials",Json::array()},{"splines",Json::array()}}}};return p;};
        auto worker=make();std::weak_ptr<const assets::PreparedPackage> lifetime=worker;
        const auto first=leases.retain(worker);worker.reset();check(!lifetime.expired());
        const auto second=leases.retain(make()),third=leases.retain(make());
        check(first!=second&&second!=third&&assets::PreparedPackageLeases::isLease(first)&&leases.size()==3);
        rejects([&]{leases.retain(make());});check(leases.size()==3&&leases.get(first)->payloadBytes==1);
        leases.release(second);leases.release(second);check(leases.size()==2&&leases.get(first));rejects([&]{leases.get(second);});
        auto inFlight=leases.get(first);leases.release(first);check(!lifetime.expired());inFlight.reset();check(lifetime.expired());
        leases.release(third);check(leases.size()==0);
        const auto large=leases.retain(make(50ull*1024*1024));rejects([&]{leases.retain(make(20ull*1024*1024));});
        check(leases.size()==1&&leases.get(large)->payloadBytes==50ull*1024*1024);leases.release(large);
        auto image=make();image->metadata["graph"]["maps"]=Json::array({{{"kind","bitmap"},{"size",{8000,8000}}}});
        const auto imageLease=leases.retain(image);rejects([&]{leases.retain(image);});check(leases.size()==1);leases.release(imageLease);
        auto invalid=make();invalid->metadata["graph"]["nodes"]=Json::array();rejects([&]{leases.retain(invalid);});check(leases.size()==0);
    }
    const auto settings=recipes::parse(load(CYRUS_RECIPE_DEFAULTS));
    brush::Document brush;brush.surface=42;brush.contours={{{0,0},{4,0},{4,4},{0,4}},{{1,1},{1,2},{2,2},{2,1}}};
    Json paint={{"payload",recipes::hex(brush::encode(brush))},{"receiverRole",nullptr},{"radius",1.},{"erase",false},{"frame",nullptr}};
    Json layer={{"id","trees"},{"name","Trees"},{"enabled",true},{"visible",true},{"settings",settings},{"paint",paint},{"areas",Json::array()}};
    Json roles=Json::array({{{"id","model"},{"kind","node"},{"name","Model"},{"purposes",{"sources"}},{"requirements",nullptr}},{{"id","terrain"},{"kind","node"},{"name","Terrain"},{"purposes",{"surface"}},{"requirements",nullptr}}});
    Json data={{"format","cyrus.planting-recipe"},{"formatVersion",5},{"revision",1},{"presentation",nullptr},{"evaluationContract","CyrusUnified1"},{"sceneSchema",58},{"hostYear",2027},{"id","package-fixture"},{"name","Portable fixture"},{"unitsPerMetre",100.},{"exportScope","complete-setup"},{"rootSettings",settings},{"roles",roles},{"layers",Json::array({layer})},{"spacingRelationships",Json::array()}};
    folder=std::filesystem::temp_directory_path()/("cyrus-package-test-"+std::to_string(std::chrono::steady_clock::now().time_since_epoch().count()));std::filesystem::create_directory(folder);
    const auto path=folder/"source.csrecipe.json",mesh=folder/"one"/"same.cmesh",other=folder/"two"/"same.cmesh";
    const auto recipeSHA=recipes::writeEntry(path,data,{{"category","Package"},{"tags",Json::array()},{"description","Fixture"}},{},nullptr,"");
    assets::Mesh triangle;triangle.vertices={{0,0,0},{1,0,0},{0,1,0}};triangle.faces={{{0,1,2},1,0,7}};
    const auto first=assets::encodeMesh(triangle);triangle.vertices[1][0]=2;const auto second=assets::encodeMesh(triangle);
    put(mesh,{first.begin(),first.end()});put(other,{second.begin(),second.end()});
    Json graph={{"format","cyrus.library-assets"},{"version",1},{"nodes",Json::array({{{"id","node-1"},{"name","Tree"},{"mesh","mesh-1"},{"material",nullptr},{"transform",{1,0,0,0,1,0,0,0,1,0,0,0}},{"wireColor",{0,255,0}},{"roles",{"model"}}}})},
        {"meshes",Json::array({{{"id","mesh-1"},{"file","file-1"}},{{"id","mesh-2"},{"file","file-2"}}})},{"materials",Json::array()},{"maps",Json::array()},
        {"files",Json::array({{{"id","file-1"},{"kind","mesh"},{"sha256",sha(load(mesh))},{"bytes",load(mesh).size()},{"suffix","cmesh"}},{{"id","file-2"},{"kind","mesh"},{"sha256",sha(load(other))},{"bytes",load(other).size()},{"suffix","cmesh"}}})},{"externalRoles",{"terrain"}}};
    const std::map<std::string,std::filesystem::path> files={{"file-1",mesh},{"file-2",other}};
    assets::validateGraph(graph,data);
    auto context=graph,contextRecipe=data;context["version"]=2;contextRecipe["roles"].push_back({{"id","path"},{"kind","node"},{"name","Border"},{"purposes",{"patternPaths"}},{"requirements",nullptr}});
    const Json knot={{"type","bezierCorner"},{"line","curve"},{"point",{0,0,0}},{"in",{-1,0,0}},{"out",{1,0,0}}};
    context["splines"]=Json::array({{{"id","spline-1"},{"name","Border"},{"transform",{1,0,0,0,1,0,0,0,1,0,0,0}},{"wireColor",{0,255,0}},{"roles",{"path"}},{"curves",Json::array({{{"closed",false},{"knots",Json::array({knot,knot})}}})}}});
    assets::validateGraph(context,contextRecipe);
    auto malformed=context;malformed["splines"][0]["roles"]={"terrain"};rejects([&]{assets::validateGraph(malformed,contextRecipe);});
    malformed=context;malformed["splines"][0]["curves"][0]["knots"][0]["type"]="script";rejects([&]{assets::validateGraph(malformed,contextRecipe);});
    malformed=context;malformed["splines"][0]["curves"][0]["knots"]=Json::array();rejects([&]{assets::validateGraph(malformed,contextRecipe);});
    malformed=context;malformed["splines"][0]["curves"][0]["knots"]=Json::array();for(int i=0;i<4097;++i)malformed["splines"][0]["curves"][0]["knots"].push_back(knot);rejects([&]{assets::validateGraph(malformed,contextRecipe);});
    auto bad=graph;bad["externalRoles"]=Json::array();rejects([&]{assets::validateGraph(bad,data);});
    bad=graph;bad["nodes"][0]["mesh"]="node-1";rejects([&]{assets::validateGraph(bad,data);});
    bad=graph;bad["files"][0]["suffix"]="../ms";rejects([&]{assets::validateGraph(bad,data);});
    bad=graph;bad["files"][0]["bytes"]=assets::maxFileBytes+1;rejects([&]{assets::validateGraph(bad,data);});
    bad=graph;bad["files"][1]["id"]="file-1";rejects([&]{assets::validateGraph(bad,data);});
    const auto out=folder/recipes::pathFromUTF8("Portable \xC3\xA9 sample");
    rejects([&]{assets::writePackage(out,path,recipeSHA,graph,files,"");});
    for(const auto* failure:{"started","file-chunk","paint-staged","asset-staged","verified","before-commit"}){
        rejects([&]{assets::writePackage(out,path,recipeSHA,graph,files,"Owned test assets",[&](const char* at,std::uint64_t){if(std::string(at)==failure)throw std::runtime_error("Injected cancellation");});});
        check(!std::filesystem::exists(out));check(recipes::read(path)["layers"][0]["paint"]==paint);
        for(const auto& entry:std::filesystem::directory_iterator(folder))check(!entry.path().filename().string().starts_with(".cyrus-package-stage-"));
    }
    const auto result=assets::writePackage(out,path,recipeSHA,graph,files,"Owned test assets",[](const char* at,std::uint64_t){if(std::string(at)=="complete")throw std::runtime_error("After commit");});
    check(result==out/"cyrus.package.json");check(load(out/"entry.csrecipe.json")==load(path));
    const auto loaded=assets::readPackage(out);check(loaded["graph"]==graph);check(recipes::read(out/"entry.csrecipe.json")["layers"][0]["paint"]==paint);
    // A recipient can identify and repair the exact missing dependency. Existing
    // complete package/output bytes are not rewritten by the rejected read.
    const auto missingRelative="assets/"+sha(load(mesh))+".cmesh";
    const auto missingPayload=out/missingRelative,movedPayload=folder/"missing-mesh-held.cmesh";
    std::filesystem::rename(missingPayload,movedPayload);bool namedMissing=false;
    try{assets::readPackage(out);}catch(const std::invalid_argument& failure){const std::string message=failure.what();namedMissing=message.find(missingRelative)!=std::string::npos&&message.find("re-export")!=std::string::npos;}
    check(namedMissing&&load(movedPayload)==load(mesh));std::filesystem::rename(movedPayload,missingPayload);
    check(assets::readPackage(out)==loaded);
    const auto prepared=assets::preparePackage(out);check(prepared.metadata==loaded);check(prepared.document["layers"][0]["paint"]==paint);check(prepared.meshes.size()==2&&prepared.payloadBytes>0);check(prepared.meshes.at("file-1")->vertices[1][0]==1&&prepared.meshes.at("file-2")->vertices[1][0]==2);
    for(const auto* stage:{"file-chunk","preparing-paint","preparing-mesh","prepared"})rejects([&]{assets::preparePackage(out,[&](const char* name,std::uint64_t){if(std::string(name)==stage)throw std::runtime_error("Import cancelled");});});
    const auto held=folder/"temporarily-moved";std::filesystem::rename(out,held);check(prepared.meshes.at("file-1")->faces.size()==1&&prepared.document["layers"][0]["paint"]==paint);std::filesystem::rename(held,out);
    // Actual Max 2027 RGB/A16 PNG, generated in an owned disposable profile.
    const auto png=recipes::unhex("89504e470d0a1a0a0000000d49484452000000100000001010060000004f6323220000000774494d4507ea0a10082c329e57b6ec0000002a494441544889636460d8fea4e4f4ffff0c03049806cae251078c3a60d401a30e1875c0a803461d0003007d2d04f871c156fa0000000049454e44ae426082");
    const auto pngInfo=assets::inspectPNG(png);check(pngInfo.width==16&&pngInfo.height==16);
    for(std::size_t i=0;i<png.size();++i)rejects([&]{assets::inspectPNG({png.begin(),png.begin()+i});});
    auto changedPNG=png;changedPNG[53]^=1;rejects([&]{assets::inspectPNG(changedPNG);});changedPNG=png;changedPNG.push_back(0);rejects([&]{assets::inspectPNG(changedPNG);});
    const auto image=folder/"source.png";put(image,{png.begin(),png.end()});check(assets::fileInfo(image,true)[2]==16);
    auto textured=graph;const auto bitmapSHA=recipes::digest(png);
    textured["files"].push_back({{"id","image-file"},{"kind","bitmap"},{"sha256",bitmapSHA},{"bytes",png.size()},{"suffix","png"}});
    textured["maps"].push_back({{"id","image"},{"kind","bitmap"},{"name","Shared image"},{"file","image-file"},{"channel",1},{"uv",{0,0,1,1,0}},{"size",{16,16}},
        {"color",{{"mode","OCIO_Default"},{"configSHA256",std::string(64,'0')},{"renderingSpace","ACEScg"},{"dataSpace","raw"},{"inputSpace","sRGB"}}},
        {"sampler",{{"filtering",0},{"monoOutput",0},{"rgbOutput",0},{"alphaSource",0},{"preMultAlpha",true},{"uMirror",false},{"vMirror",false},{"uTile",true},{"vTile",true},{"blur",1.},{"blurOffset",0.}}},
        {"output",{{"invert",false},{"clamp",false},{"alphaFromRGB",false},{"rgbLevel",1.},{"rgbOffset",0.},{"outputAmount",1.}}},{"roles",Json::array()}});
    assets::validateGraph(textured,data);auto texturedFiles=files;texturedFiles.emplace("image-file",image);
    const auto bitmapPackage=folder/"bitmap-package",cache=folder/"owned-images";
    assets::writePackage(bitmapPackage,path,recipeSHA,textured,texturedFiles,"Owned image fixture");
    rejects([&]{assets::preparePackage(bitmapPackage);});
    const auto bitmapSnapshot=assets::preparePackage(bitmapPackage,{},cache);check(bitmapSnapshot.bitmapPaths.size()==1);const auto ownedImage=bitmapSnapshot.bitmapPaths.at("image-file");check(load(ownedImage)==std::string(png.begin(),png.end()));
    const auto again=assets::preparePackage(bitmapPackage,{},cache);check(again.bitmapPaths.at("image-file")==ownedImage);
    const auto cancelledCache=folder/"cancelled-images";rejects([&]{assets::preparePackage(bitmapPackage,[](const char* stage,std::uint64_t){if(std::string(stage)=="bitmap-staged")throw std::runtime_error("Cancel bitmap publish");},cancelledCache);});check(std::filesystem::is_empty(cancelledCache));
    put(ownedImage,"user edited cached image");rejects([&]{assets::preparePackage(bitmapPackage,{},cache);});check(load(ownedImage)=="user edited cached image");
    bad=textured;bad["maps"][0]["size"]={4096,4096};auto duplicateMap=bad["maps"][0];duplicateMap["id"]="another-map";bad["maps"].push_back(duplicateMap);rejects([&]{assets::validateGraph(bad,data);});
    bad=textured;bad["maps"][0]["color"]["mode"]="OCIO_Custom";rejects([&]{assets::validateGraph(bad,data);});
    bad=textured;bad["maps"][0]["output"]["code"]="arbitrary";rejects([&]{assets::validateGraph(bad,data);});
    // Graph 3 adds a closed, version-pinned renderer/image profile. Its mixed
    // graph retains the old Standard/Bitmap shape, global IDs and role rules.
    auto plant=textured;plant["version"]=3;plant["splines"]=Json::array();plant["rendererProfile"]=shaderTable().at("profile");plant["resourceProfile"]="plant-images-v1";
    plant["maps"][0]["color"]["inputGamma"]="auto";plant["maps"][0]["color"]["effectiveGamma"]=2.2;
    auto physical=shader("corona-physical-v1","physical"),normal=shader("corona-normal-v1","normal"),legacy=shader("corona-legacy-v1","legacy");
    physical["links"]["baseTexmap"]="image";physical["links"]["baseBumpTexmap"]="normal";normal["links"]["normalMap"]="image";legacy["links"]["texmapDiffuse"]="image";
    Json standard={{"id","standard"},{"kind","standard-blinn"},{"name","Standard"},{"diffuse",{255,255,255}},{"ambient",{255,255,255}},{"specular",{255,255,255}},{"specularLevel",0},{"glossiness",0},{"soften",0},{"selfIllumAmount",0},{"selfIllumColor",{0,0,0}},{"useSelfIllumColor",false},{"ambientDiffuseLock",false},{"diffuseSpecularLock",false},{"textureLock",false},{"opacity",100},{"twoSided",true},{"maps",Json::array()}};
    for(const auto* slot:{"ambient","diffuse","opacity"})standard["maps"].push_back({{"slot",slot},{"map","image"},{"amount",100},{"enabled",true}});
    Json multi={{"id","multi"},{"kind","multi-sub-v1"},{"name","Mixed"},{"showPreviews",true},{"slots",Json::array({{{"materialID",1},{"name","Physical"},{"enabled",true},{"material","physical"}},{{"materialID",7},{"name","Legacy"},{"enabled",true},{"material","legacy"}},{{"materialID",12},{"name","Standard"},{"enabled",false},{"material","standard"}},{{"materialID",31},{"name","Unused"},{"enabled",false},{"material",nullptr}}})}};
    plant["materials"]={multi,physical,legacy,standard};plant["maps"].push_back(normal);plant["nodes"][0]["material"]="multi";
    assets::validateGraph(plant,data);
    for(const auto* key:{"splines","rendererProfile","resourceProfile"}){bad=plant;bad.erase(key);rejects([&]{assets::validateGraph(bad,data);});}
    bad=plant;bad["resourceProfile"]="unbounded";rejects([&]{assets::validateGraph(bad,data);});
    bad=plant;bad["rendererProfile"]["pluginVersion"]="unqualified";rejects([&]{assets::validateGraph(bad,data);});
    bad=plant;bad["maps"][1]["id"]="file-1";rejects([&]{assets::validateGraph(bad,data);});
    bad=plant;bad["materials"][0]["id"]="mesh-1";rejects([&]{assets::validateGraph(bad,data);});
    bad=plant;bad["nodes"][0]["material"]="normal";rejects([&]{assets::validateGraph(bad,data);});
    bad=plant;bad["maps"][1]["roles"]={"terrain"};rejects([&]{assets::validateGraph(bad,data);});
    bad=plant;bad["materials"][1]["properties"]["unsupported"]=0;rejects([&]{assets::validateGraph(bad,data);});
    bad=plant;bad["files"][2]["suffix"]="tiff";rejects([&]{assets::validateGraph(bad,data);});
    for(const auto* key:{"inputGamma","effectiveGamma"}){
        bad=plant;bad["maps"][0]["color"].erase(key);rejects([&]{assets::validateGraph(bad,data);});
        for(const auto& value:Json::array({nullptr,false,"linear",0,11})){bad=plant;bad["maps"][0]["color"][key]=value;rejects([&]{assets::validateGraph(bad,data);});}
        bad=plant;bad["maps"][0]["color"][key]=std::numeric_limits<double>::infinity();rejects([&]{assets::validateGraph(bad,data);});
        bad=plant;bad["maps"][0]["color"][key]=std::numeric_limits<double>::quiet_NaN();rejects([&]{assets::validateGraph(bad,data);});
    }
    bad=plant;bad["maps"][0]["color"]["inputGamma"]=1.;bad["maps"][0]["color"]["effectiveGamma"]=1.;assets::validateGraph(bad,data);check(true);
    bad=textured;bad["maps"][0]["color"]["inputGamma"]="auto";rejects([&]{assets::validateGraph(bad,data);});
    auto wrongHost=data;wrongHost["hostYear"]=2024;rejects([&]{assets::validateGraph(plant,wrongHost);});
    for(int version:{1,2}){
        bad=plant;bad["version"]=version;bad.erase("rendererProfile");bad.erase("resourceProfile");if(version==1)bad.erase("splines");rejects([&]{assets::validateGraph(bad,data);});
        bad=graph;bad["version"]=version;if(version==2)bad["splines"]=Json::array();bad["rendererProfile"]=shaderTable().at("profile");rejects([&]{assets::validateGraph(bad,data);});
    }
    // Per-image and aggregate INSTANCE admission are independent from file
    // hash sharing. Eight 64-Mpixel instances fit; the ninth does not.
    auto pixels=plant;pixels["maps"][0]["size"]={8192,8192};for(unsigned i=1;i<8;++i){auto map=pixels["maps"][0];map["id"]="large-image-"+std::to_string(i);pixels["maps"].push_back(map);}assets::validateGraph(pixels,data);check(assets::maxPlantBitmapPixels==512ull*1024ull*1024ull);
    auto ninth=pixels["maps"][0];ninth["id"]="ninth";pixels["maps"].push_back(ninth);rejects([&]{assets::validateGraph(pixels,data);});
    bad=plant;bad["maps"][0]["size"]={8193,1};rejects([&]{assets::validateGraph(bad,data);});
    // Real-model PNG/JPEG uses its own decoder profile. Original encoded
    // bytes and validated suffix survive export, cache staging and relocation.
    const std::vector<unsigned char> rgb8PNG={137,80,78,71,13,10,26,10,0,0,0,13,73,72,68,82,0,0,0,2,0,0,0,3,8,2,0,0,0,54,136,73,214,0,0,0,11,73,68,65,84,120,156,99,96,192,2,0,0,21,0,1,170,101,151,196,0,0,0,0,73,69,78,68,174,66,96,130};
    const auto image8=folder/"source8.PNG";const auto sha8=recipes::digest(rgb8PNG);put(image8,{rgb8PNG.begin(),rgb8PNG.end()});check(assets::imageFileInfo(image8)==Json::array({sha8,rgb8PNG.size(),2,3}));
    plant["files"][2]["sha256"]=sha8;plant["files"][2]["bytes"]=rgb8PNG.size();plant["maps"][0]["size"]={2,3};auto plantFiles=files;plantFiles.emplace("image-file",image8);
    // CoronaBitmap has a distinct typed shader envelope but participates in the
    // same file namespace, strict decoder, instance-pixel bound and owned cache.
    auto corona=shader("corona-bitmap-v1","corona-image");corona["file"]="image-file";corona["size"]={2,3};
    corona["color"]=plant["maps"][0]["color"];corona["color"].erase("inputGamma");corona["color"].erase("effectiveGamma");corona["color"]["inputSpace"]="Raw";
    corona["coordinates"]=subobject("corona-uvw-v1");corona["output"]=subobject("standard-output-v1");
    auto coronaGraph=plant;coronaGraph["maps"].push_back(corona);coronaGraph["materials"][1]["links"]["baseTexmap"]="corona-image";
    assets::validateGraph(coronaGraph,data);
    for(const auto* invalid:{"file-1","missing-image"}){bad=coronaGraph;bad["maps"].back()["file"]=invalid;rejects([&]{assets::validateGraph(bad,data);});}
    for(const auto* key:{"file","size","color","coordinates","output"}){bad=coronaGraph;bad["maps"].back().erase(key);rejects([&]{assets::validateGraph(bad,data);});}
    bad=coronaGraph;bad["maps"].back()["color"]["inputGamma"]="auto";rejects([&]{assets::validateGraph(bad,data);});
    bad=coronaGraph;bad["maps"].back()["color"]["inputSpace"]="Gamma 2.2 / Rec.709";rejects([&]{assets::validateGraph(bad,data);});
    bad=coronaGraph;bad["maps"].back()["filename"]="outside.png";rejects([&]{assets::validateGraph(bad,data);});
    bad=coronaGraph;bad["maps"].back()["size"]={8193,1};rejects([&]{assets::validateGraph(bad,data);});
    auto combinedPixels=plant;combinedPixels["maps"][0]["size"]={8192,8192};
    for(unsigned i=0;i<7;++i){auto map=corona;map["id"]="corona-pixels-"+std::to_string(i);map["size"]={8192,8192};combinedPixels["maps"].push_back(map);}
    assets::validateGraph(combinedPixels,data);check(true);auto extraCorona=corona;extraCorona["id"]="corona-over-budget";extraCorona["size"]={8192,8192};combinedPixels["maps"].push_back(extraCorona);rejects([&]{assets::validateGraph(combinedPixels,data);});
    const auto coronaPackage=folder/"corona-bitmap-package",coronaCache=folder/"corona-bitmap-cache";
    assets::writePackage(coronaPackage,path,recipeSHA,coronaGraph,plantFiles,"Owned mixed Standard/Corona image fixture");
    const auto preparedCorona=assets::preparePackage(coronaPackage,{},coronaCache);check(preparedCorona.metadata["graph"]==coronaGraph&&preparedCorona.bitmapPaths.size()==1&&load(preparedCorona.bitmapPaths.at("image-file"))==std::string(rgb8PNG.begin(),rgb8PNG.end()));
    const auto movedCorona=folder/recipes::pathFromUTF8("Corona bitmap moved \xC3\xA9");std::filesystem::rename(coronaPackage,movedCorona);
    check(assets::preparePackage(movedCorona,{},coronaCache).bitmapPaths.at("image-file")==preparedCorona.bitmapPaths.at("image-file"));
    bad=coronaGraph;bad["maps"].back()["size"]={3,2};const auto wrongCoronaDimensions=folder/"wrong-corona-dimensions";
    rejects([&]{assets::writePackage(wrongCoronaDimensions,path,recipeSHA,bad,plantFiles,"Owned rejected Corona dimensions");});check(!std::filesystem::exists(wrongCoronaDimensions));
    const auto coronaCancelled=folder/"corona-cancel-cache";rejects([&]{assets::preparePackage(movedCorona,[](const char* stage,std::uint64_t){if(std::string(stage)=="bitmap-staged")throw std::runtime_error("Cancel Corona image");},coronaCancelled);});check(std::filesystem::is_empty(coronaCancelled));
    // The finite large-plant profile is additive. Per-image and material/node
    // admission remain unchanged; only map nodes and typed mesh/package budgets
    // opt in. Metadata boundary tests do not allocate these declared payloads.
    auto expanded=plant;expanded["resourceProfile"]="plant-assets-v1";
    auto declared=expanded;declared["files"][0]["bytes"]=assets::maxPlantMeshFileBytes;assets::validateGraph(declared,data);check(true);
    declared["resourceProfile"]="plant-images-v1";rejects([&]{assets::validateGraph(declared,data);});
    declared=expanded;declared["files"][0]["bytes"]=assets::maxPlantMeshFileBytes+1;rejects([&]{assets::validateGraph(declared,data);});
    declared=expanded;declared["files"][2]["bytes"]=assets::maxFileBytes+1;rejects([&]{assets::validateGraph(declared,data);});
    declared=expanded;declared["files"][0]["bytes"]=224ull*1024*1024;declared["files"][1]["bytes"]=224ull*1024*1024;
    auto extra=declared["files"][0];extra["id"]="third-mesh-file";extra["bytes"]=192ull*1024*1024-1;declared["files"].push_back(extra);
    // The existing PNG consumes more than the remaining one byte.
    rejects([&]{assets::validateGraph(declared,data);});declared["files"][3]["bytes"]=192ull*1024*1024-rgb8PNG.size();assets::validateGraph(declared,data);check(true);
    for(unsigned i=2;i<256;++i){auto map=expanded["maps"][0];map["id"]="expanded-image-"+std::to_string(i);map["roles"]=Json::array();expanded["maps"].push_back(map);}
    assets::validateGraph(expanded,data);check(expanded["maps"].size()==256);
    declared=expanded;declared["resourceProfile"]="plant-images-v1";rejects([&]{assets::validateGraph(declared,data);});
    auto tooMany=expanded["maps"][0];tooMany["id"]="map-257";expanded["maps"].push_back(tooMany);rejects([&]{assets::validateGraph(expanded,data);});
    expanded["maps"].erase(expanded["maps"].end()-1);expanded["resourceProfile"]="plant-assets-v2";rejects([&]{assets::validateGraph(expanded,data);});
    // One explicit-normal M02 and one unchanged M01 share a package. Only the
    // opted-in profile may decode M02; prepared accounting includes normals.
    auto normalMesh=triangle;assets::MeshNormals stored;stored.flags=3;stored.vectors={{0,0,1},{0,0,1},{0,0,1}};stored.explicitFlags={1,1,1};stored.faces.push_back({{0,1,2},{1,1,1}});normalMesh.normals=stored;
    const auto normalBytes=assets::encodeMesh(normalMesh,assets::MeshProfile::Plant);const auto normalFile=folder/"plant-normal.cmesh";
    put(normalFile,{normalBytes.begin(),normalBytes.end()});const auto normalSHA=recipes::digest(normalBytes);
    auto normalGraph=plant;normalGraph["resourceProfile"]="plant-assets-v1";normalGraph["files"][0]["sha256"]=normalSHA;normalGraph["files"][0]["bytes"]=normalBytes.size();auto normalFiles=plantFiles;normalFiles["file-1"]=normalFile;
    const auto normalPackage=folder/"normal-plant";assets::writePackage(normalPackage,path,recipeSHA,normalGraph,normalFiles,"Owned M02 fixture");
    const auto normalPrepared=assets::preparePackage(normalPackage,{},folder/"normal-cache");
    check(normalPrepared.meshes.at("file-1")->profile==assets::MeshProfile::Plant&&normalPrepared.meshes.at("file-1")->normals.has_value());
    check(normalPrepared.meshes.at("file-2")->profile==assets::MeshProfile::Legacy);
    check(normalPrepared.payloadBytes>=assets::meshStorageBytes(*normalPrepared.meshes.at("file-1"))+assets::meshStorageBytes(*normalPrepared.meshes.at("file-2")));
    auto forbidden=normalGraph;forbidden["resourceProfile"]="plant-images-v1";const auto wrongProfile=folder/"normal-wrong-profile";
    rejects([&]{assets::writePackage(wrongProfile,path,recipeSHA,forbidden,normalFiles,"Owned rejected M02 fixture");});check(!std::filesystem::exists(wrongProfile));
    const auto cancelledNormal=folder/"cancelled-normal";rejects([&]{assets::writePackage(cancelledNormal,path,recipeSHA,normalGraph,normalFiles,"Owned cancelled M02 fixture",[](const char* stage,std::uint64_t){if(std::string(stage)=="asset-staged")throw std::runtime_error("Cancel M02");});});check(!std::filesystem::exists(cancelledNormal));
    const auto plantPackage=folder/"plant-package",plantCache=folder/"plant-cache";assets::writePackage(plantPackage,path,recipeSHA,plant,plantFiles,"Owned renderer fixture");check(assets::readPackage(plantPackage)["graph"]==plant);
    const auto preparedPlant=assets::preparePackage(plantPackage,{},plantCache);const auto preparedImage=preparedPlant.bitmapPaths.at("image-file");check(preparedImage.extension()==".png"&&load(preparedImage)==std::string(rgb8PNG.begin(),rgb8PNG.end()));
    const auto relocated=folder/"moved-plant";std::filesystem::rename(plantPackage,relocated);check(assets::readPackage(relocated)["graph"]==plant);check(assets::preparePackage(relocated,{},plantCache).bitmapPaths.at("image-file")==preparedImage);
    const auto plantManifestPath=relocated/"cyrus.package.json";const auto plantManifestBytes=load(plantManifestPath);auto alteredManifest=recipes::parse(plantManifestBytes);alteredManifest["hostYear"]=2024;put(plantManifestPath,alteredManifest.dump());rejects([&]{assets::readPackage(relocated);});put(plantManifestPath,plantManifestBytes);
    const auto cancelledPlant=folder/"cancelled-plant-cache";rejects([&]{assets::preparePackage(relocated,[](const char* stage,std::uint64_t){if(std::string(stage)=="bitmap-staged")throw std::runtime_error("Cancel plant cache");},cancelledPlant);});check(std::filesystem::is_empty(cancelledPlant));
    bad=plant;bad["maps"][0]["size"]={3,2};const auto wrongDimensions=folder/"wrong-dimensions";rejects([&]{assets::writePackage(wrongDimensions,path,recipeSHA,bad,plantFiles,"Owned malformed fixture");});check(!std::filesystem::exists(wrongDimensions));
    bad=plant;bad["files"][2]["suffix"]="jpg";const auto wrongSuffix=folder/"wrong-suffix";rejects([&]{assets::writePackage(wrongSuffix,path,recipeSHA,bad,plantFiles,"Owned malformed fixture");});check(!std::filesystem::exists(wrongSuffix));
    const auto jpeg=recipes::unhex("ffd8ffe000104a46494600010100000100010000ffdb004300080606070605080707070909080a0c140d0c0b0b0c1912130f141d1a1f1e1d1a1c1c20242e2720222c231c1c2837292c30313434341f27393d38323c2e333432ffc0000b080003000201011100ffc4001f0000010501010101010100000000000000000102030405060708090a0bffc400b5100002010303020403050504040000017d01020300041105122131410613516107227114328191a1082342b1c11552d1f02433627282090a161718191a25262728292a3435363738393a434445464748494a535455565758595a636465666768696a737475767778797a838485868788898a92939495969798999aa2a3a4a5a6a7a8a9aab2b3b4b5b6b7b8b9bac2c3c4c5c6c7c8c9cad2d3d4d5d6d7d8d9dae1e2e3e4e5e6e7e8e9eaf1f2f3f4f5f6f7f8f9faffda0008010100003f00f9febfffd9");const auto jpegImage=folder/"source-gray.JpEg";put(jpegImage,{jpeg.begin(),jpeg.end()});const auto jpegSHA=recipes::digest(jpeg);check(assets::imageFileInfo(jpegImage)==Json::array({jpegSHA,jpeg.size(),2,3}));
    auto jpegPlant=plant;jpegPlant["files"][2]["sha256"]=jpegSHA;jpegPlant["files"][2]["bytes"]=jpeg.size();jpegPlant["files"][2]["suffix"]="jpeg";auto jpegFiles=files;jpegFiles.emplace("image-file",jpegImage);const auto jpegPackage=folder/"jpeg-plant";assets::writePackage(jpegPackage,path,recipeSHA,jpegPlant,jpegFiles,"Owned JPEG fixture");
    const auto jpegPrepared=assets::preparePackage(jpegPackage,{},plantCache);const auto cachedJPEG=jpegPrepared.bitmapPaths.at("image-file");check(cachedJPEG.extension()==".jpeg"&&load(cachedJPEG)==std::string(jpeg.begin(),jpeg.end()));check(assets::preparePackage(jpegPackage,{},plantCache).bitmapPaths.at("image-file")==cachedJPEG);
    const auto misleading=folder/"not-jpeg.png";put(misleading,{jpeg.begin(),jpeg.end()});rejects([&]{assets::imageFileInfo(misleading);});
    rejects([&]{assets::imageFileInfo(image);}); // Existing 16-bit PNG remains legacy-only.
    rejects([&]{assets::imageFileInfo("relative.png");});
    check(std::filesystem::directory_iterator(out/"assets")!=std::filesystem::directory_iterator());
#ifdef _WIN32
    // Max's process need not opt in to long paths: all native file operations
    // retain containment/hash checks beyond the ordinary MAX_PATH boundary.
    const auto deep=folder/std::string(120,'a')/std::string(120,'b')/std::string(80,'c');
    std::filesystem::create_directories(recipes::nativePath(deep));
    const auto longPackage=deep/"ready";
    assets::writePackage(longPackage,path,recipeSHA,graph,files,"Owned long-path fixture");
    check(assets::readPackage(longPackage)["graph"]==graph);
    check(assets::preparePackage(longPackage).meshes.size()==2);
    auto longManifest=recipes::parse(load(recipes::nativePath(longPackage/"cyrus.package.json")));
    longManifest["graph"]["file"]="../assets.json";
    put(recipes::nativePath(longPackage/"cyrus.package.json"),longManifest.dump());rejects([&]{assets::readPackage(longPackage);});
    rejects([&]{assets::readPackage("relative-folder");});
    std::filesystem::remove_all(recipes::nativePath(deep,true));
#endif
    rejects([&]{assets::writePackage(out,path,recipeSHA,graph,files,"Owned test assets");});
    const auto newOut=folder/"new-output";put(mesh,"same size changed data");rejects([&]{assets::writePackage(newOut,path,recipeSHA,graph,files,"Owned test assets");});check(!std::filesystem::exists(newOut));
    const auto payload=out/"assets"/(graph["files"][0]["sha256"].get<std::string>()+".cmesh");put(payload,"tampered payload");rejects([&]{assets::readPackage(out);});
    auto manifest=recipes::parse(load(result));manifest["graph"]["file"]="../assets.json";put(result,manifest.dump());rejects([&]{assets::readPackage(out);});
    check(load(other)==std::string(second.begin(),second.end()));
    std::filesystem::remove_all(recipes::nativePath(folder,true));std::cout<<checks<<" package assertions passed\n";return 0;
}catch(const std::exception& e){std::cerr<<e.what()<<"\nFixture: "<<folder<<'\n';return 1;}}
