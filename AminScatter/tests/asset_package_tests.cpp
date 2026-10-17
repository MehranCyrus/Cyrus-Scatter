#include "asset_package.h"
#include "asset_mesh.h"
#include "asset_bitmap.h"
#include "recipe_store.h"
#include "brush.h"
#include <chrono>
#include <fstream>
#include <iostream>
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
}
int main(){std::filesystem::path folder;try{
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
