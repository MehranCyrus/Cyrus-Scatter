#include "recipe_library.h"
#include "scene_preset.h"
#include <chrono>
#include <fstream>
#include <iostream>
#include <stdexcept>
using namespace cyrus::recipes;
namespace {
unsigned checks=0;
void check(bool value){++checks;if(!value)throw std::runtime_error("Library assertion "+std::to_string(checks));}
template<class F>void rejected(F f){bool failed=false;try{f();}catch(const std::exception&){failed=true;}check(failed);}
void put(const std::filesystem::path& p,const std::string& value){std::ofstream out(p,std::ios::binary);out<<value;if(!out)throw std::runtime_error("Fixture write failed");}
std::string load(const std::filesystem::path& p){std::ifstream in(p,std::ios::binary);return {std::istreambuf_iterator<char>(in),std::istreambuf_iterator<char>()};}
Json wait(Library& library,std::uint64_t id){
    const auto deadline=std::chrono::steady_clock::now()+std::chrono::seconds(30);
    while(std::chrono::steady_clock::now()<deadline){auto p=library.page(id,"","",1);if(p[0]!="scanning")return p;std::this_thread::sleep_for(std::chrono::milliseconds(5));}
    throw std::runtime_error("Library worker did not finish");
}
}
int main(){std::filesystem::path folder;try{
    const auto defaults=parse(load(CYRUS_RECIPE_DEFAULTS));
    Json layer={{"id","canopy"},{"name","Canopy"},{"enabled",true},{"visible",true},{"settings",defaults},{"paint",nullptr},{"areas",Json::array()}};
    Json d={{"format","cyrus.planting-recipe"},{"formatVersion",1},{"evaluationContract","CyrusUnified1"},{"sceneSchema",58},{"hostYear",2027},{"id","library-fixture"},{"name","Canopy AA"},{"unitsPerMetre",100.},{"exportScope","complete-setup"},{"rootSettings",defaults},{"roles",Json::array()},{"layers",Json::array({layer})},{"spacingRelationships",Json::array()}};
    folder=std::filesystem::temp_directory_path()/("cyrus-library-"+std::to_string(std::chrono::steady_clock::now().time_since_epoch().count()));std::filesystem::create_directory(folder);
    const auto scenePath=folder/"scene-envelope.json";
    Json scene={{"format","cyrus.scene-preset"},{"version",1},{"id","scene-fixture"},{"revision",1},{"name","Native scene"},{"maxYear",2027},{"scatterVersion","0.87.5.1"},{"metersPerUnit",.01},{"nodeCount",4},{"layers",Json::array({"Grass","Collider"})},{"scene",{{"file","scene.max"},{"sha256",std::string(64,'a')},{"bytes",123}}},{"assets",Json::array()},{"presentation",nullptr}};
    cyrus::scenepresets::validate(scene);put(scenePath,scene.dump());auto sceneInfo=summary(scenePath);check(sceneInfo.size()==17&&sceneInfo[0]=="Native scene"&&sceneInfo[1]==2&&sceneInfo[16]=="Scene preset");
    check(readLibraryMetadata(scenePath)==scene);rejected([&]{read(scenePath,false);});
    auto invalidScene=scene;invalidScene["scene"]["file"]="../scene.max";rejected([&]{cyrus::scenepresets::validate(invalidScene);});
    invalidScene=scene;invalidScene["maxYear"]=2026;rejected([&]{cyrus::scenepresets::validate(invalidScene);});
    invalidScene=scene;invalidScene["assets"]=Json::array({{{"id","file1"},{"type","bitmap"},{"payload",{{"file","assets/a.exr"},{"sha256",std::string(64,'b')},{"bytes",0}}}}});rejected([&]{cyrus::scenepresets::validate(invalidScene);});
    invalidScene=scene;invalidScene["metersPerUnit"]=0;rejected([&]{cyrus::scenepresets::validate(invalidScene);});
    const auto path=folder/"canopy.CSRECIPE.JSON";writeNew(path,d);
    const auto original=load(path);auto info=summary(path);check(info[0]=="Canopy AA"&&info[1]==1&&info[2]==0&&info[4]==""&&!info[11].get<bool>());
    const auto bytes=unhex("89504e470d0a1a0a0000000d4948445200000001000000010804000000b51c0c020000000b4944415478da6364f80f00010501012718e3660000000049454e44ae426082");
    validateThumbnail(bytes);auto bad=bytes;bad[16]=1;rejected([&]{validateThumbnail(bad);});rejected([&]{validateThumbnail({});});
    const auto image=folder/"source.png";put(image,{bytes.begin(),bytes.end()});
    const Json metadata={{"category","Woodland"},{"tags",Json::array({"trees","slope"})},{"description","Two seasonal tree models"}};
    auto invalid=metadata;invalid["tags"]={"tree","tree"};rejected([&]{writePresentation(path,invalid,image);});
    writePresentation(path,metadata,image);check(load(path)==original);info=summary(path);check(info[4]=="Woodland"&&info[5]==metadata["tags"]&&info[11]&&info[12]=="");
    const auto thumb=thumbnail(path);check(!thumb.empty()&&load(thumb)==load(image));rejected([&]{writePresentation(path,metadata,image);});
    check(info.size()==17&&info[13][1]==digest(bytes)&&info[13][2]==bytes.size());
    check(info[15]=="No authored channel or Paint requirements."&&info[16]=="Settings only");
    check(std::filesystem::equivalent(pathFromUTF8(info[13][0].get<std::string>()),thumb));
    put(thumb,"damaged");check(summary(path)[11]);rejected([&]{thumbnail(path);});put(thumb,load(image));
    const auto sidecar=std::filesystem::path(path.wstring()+L".library.json");auto side=parse(load(sidecar));const auto sideOriginal=load(sidecar);side["thumbnail"]["file"]="../outside.png";put(sidecar,side.dump());
    check(summary(path)[12]!="");rejected([&]{thumbnail(path);});put(sidecar,sideOriginal);
    put(folder/"broken.csrecipe.json","{");
    // Large catalogs are built by a file-only worker; each UI page stays bounded.
    for(int i=0;i<300;++i){auto copy=d;copy["name"]="Meadow "+std::to_string(i);copy["id"]="meadow-"+std::to_string(i);put(folder/("meadow-"+std::to_string(i)+".csrecipe.json"),serialize(copy));}
    Library library;auto id=library.start({folder,folder});auto page=wait(library,id);
    check(page[0]=="complete"&&page[1]==302&&page[2]==301&&page[3]==1&&page[5]==""&&page[9].size()==128);
    check(library.page(id,"SLOPE","",1)[6]==1);check(library.page(id,"","Woodland",1)[6]==1);
    check(page.size()==13&&page[10].size()==1&&page[10][0][0]=="Woodland"&&page[10][0][1]==1&&page[10][0][2]==info[13]);
    check(page[11]==1&&page[12]==1);
    check(library.page(id,"meadow","",3)[9].size()==44);check(library.page(id,"unknown","",1)[9].empty());
    const auto stamp=std::filesystem::last_write_time(path);d["name"]="Canopy BB";const auto replacement=serialize(d);check(replacement.size()==original.size());put(path,replacement);std::filesystem::last_write_time(path,stamp);
    library.update(id,path);check(library.page(id,"Canopy BB","",1)[6]==1&&library.page(id,"","",1)[12]==0);
    auto next=library.start({folder});rejected([&]{library.page(id,"","",1);});wait(library,next);
    check(library.page(next,"Canopy AA","",1)[6]==0&&library.page(next,"Canopy BB","",1)[6]==1);
    check(summary(path)[12]!=""); // Hash-bound metadata never silently labels replaced content.
    next=library.start({folder});library.cancel(next);check(wait(library,next)[0]=="cancelled");
    Library bounded({10,100000,32*1024*1024});const auto limited=wait(bounded,bounded.start({folder}));check(limited[4]&&limited[1]==10&&limited[2].get<int>()<=10);
    Library tiny({10000,100000,10});check(wait(tiny,tiny.start({folder}))[4]);
    rejected([&]{library.start({"relative"});});
    const auto absent=library.start({folder/"missing"});check(wait(library,absent)[5]!="");
    // Shared stores are read through one immutable catalog snapshot, without
    // a quadratic fanout of per-generation recipe view directories.
    const auto shared=folder/"shared";std::filesystem::create_directories(shared/"catalog"/"snapshots");
    put(shared/"store.json",Json{{"format","cyrus.asset-store"},{"version",1},{"id","owned-fixture"}}.dump());
    const auto sharedText=serialize(d),sharedHash=digest({sharedText.begin(),sharedText.end()});
    const auto entry=shared/"entries"/sharedHash/"entry.csrecipe.json";std::filesystem::create_directories(entry.parent_path());put(entry,sharedText);
    Json catalog={{"format","cyrus.library-catalog"},{"version",1},{"recipes",{{"library-fixture",{{"sha256",sharedHash},{"package",nullptr}}}}},{"models",Json::object()},{"collections",{{"group",{{"name","Favorite looks"},{"recipes",Json::array({"library-fixture"})},{"models",Json::array()}}}}}};
    auto catalogText=catalog.dump(),catalogHash=digest({catalogText.begin(),catalogText.end()});put(shared/"catalog"/"snapshots"/(catalogHash+".json"),catalogText);put(shared/"catalog"/"current.json",Json{{"sha256",catalogHash}}.dump());
    auto sharedPage=wait(library,library.start({shared},"Favorite looks"));check(sharedPage[2]==1&&sharedPage[3]==0&&sharedPage[5]=="");
    put(entry,sharedText+" ");sharedPage=wait(library,library.start({shared}));check(sharedPage[3]==1&&sharedPage[2]==0);put(entry,sharedText);
    put(shared/"catalog"/"snapshots"/(catalogHash+".json"),catalogText+" ");sharedPage=wait(library,library.start({shared}));check(sharedPage[5]!="");
    std::filesystem::remove_all(folder);folder.clear();std::cout<<"PASS: "<<checks<<" library checks; passive metadata, PNG bounds/hash, search, cancellation, stale generations and refresh replacement\n";return 0;
}catch(const std::exception& e){if(!folder.empty()){std::error_code ignored;std::filesystem::remove_all(folder,ignored);}std::cerr<<e.what()<<'\n';return 1;}}
