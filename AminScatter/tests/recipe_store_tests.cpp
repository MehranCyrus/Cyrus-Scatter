#include "recipe_store.h"
#include "recipe_library.h"
#include "brush.h"
#include <chrono>
#include <fstream>
#include <iostream>
#include <stdexcept>
#include <windows.h>
using namespace cyrus::recipes;
namespace {
unsigned checks=0;
void check(bool ok){++checks;if(!ok)throw std::runtime_error("Entry assertion "+std::to_string(checks));}
template<class F>void rejects(F f){bool failed=false;try{f();}catch(const std::exception&){failed=true;}check(failed);}
std::string load(const std::filesystem::path& path){std::ifstream in(path,std::ios::binary);return {std::istreambuf_iterator<char>(in),std::istreambuf_iterator<char>()};}
void put(const std::filesystem::path& path,const std::string& bytes){std::ofstream out(path,std::ios::binary);out<<bytes;if(!out)throw std::runtime_error("Fixture write");}
}
int main(){std::filesystem::path folder;try{
    const auto settings=parse(load(CYRUS_RECIPE_DEFAULTS));
    cyrus::brush::Document brush;brush.surface=42;brush.contours={{{0,0},{4,0},{4,4},{0,4}},{{1,1},{1,2},{2,2},{2,1}}};
    const auto paintBytes=cyrus::brush::encode(brush);
    Json paint={{"payload",hex(paintBytes)},{"receiverRole",nullptr},{"radius",1.},{"erase",false},{"frame",nullptr}};
    Json layer={{"id","trees"},{"name","Trees"},{"enabled",true},{"visible",true},{"settings",settings},{"paint",paint},{"areas",Json::array()}};
    Json data={{"format","cyrus.planting-recipe"},{"formatVersion",4},{"evaluationContract","CyrusUnified1"},{"sceneSchema",58},{"hostYear",2027},{"id","entry:fixture"},{"name","First entry"},{"unitsPerMetre",100.},{"exportScope","complete-setup"},{"rootSettings",settings},{"roles",Json::array()},{"layers",Json::array({layer})},{"spacingRelationships",Json::array()}};
    auto current=currentDocument(data);check(current["formatVersion"]==7&&current["revision"]==1&&current["presentation"].is_null());validate(current);
    auto bad=data;bad["revision"]=3;rejects([&]{validate(bad);});
    bad=current;bad["revision"]=0;rejects([&]{validate(bad);});bad=current;bad["formatVersion"]=8;rejects([&]{validate(bad);});
    Json info={{"category","Garden"},{"tags",Json::array({"trees","paint"})},{"description","Complete authored entry"}};
    folder=std::filesystem::temp_directory_path()/("cyrus-entry-test-"+std::to_string(std::chrono::steady_clock::now().time_since_epoch().count()));std::filesystem::create_directory(folder);
    const auto path=folder/"entry.csrecipe.json",image=folder/"input.png";
    const auto png=unhex("89504e470d0a1a0a0000000d4948445200000001000000010804000000b51c0c020000000b4944415478da6364f80f00010501012718e3660000000049454e44ae426082");put(image,{png.begin(),png.end()});
    auto sha=writeEntry(path,data,info,image,nullptr,"");auto saved=read(path);check(saved["revision"]==1&&saved["id"]==data["id"]&&saved["layers"][0]["paint"]==paint);
    check(summary(path)[4]=="Garden"&&summary(path)[14]==1&&load(thumbnail(path))==load(image));
    check(summary(path).size()==17&&summary(path)[15].get<std::string>().find("local XY footprint")!=std::string::npos&&summary(path)[16]=="Settings only");
    const auto package=folder/"Presets"/sha;std::filesystem::create_directories(package);
    check(summary(path)[16]=="Incomplete package");
    put(package/"cyrus.package.json",Json({{"format","cyrus.library-package"},{"recipe",{{"sha256",sha}}}}).dump());
    check(summary(path)[16]=="Packaged; checked on Load");
    put(package/"cyrus.package.json","bad");check(summary(path)[16]=="Incomplete package");
    rejects([&]{writeEntry(path,data,info,image,nullptr,"");});rejects([&]{writeEntry(path,data,info,image,nullptr,std::string(64,'0'));});
    const auto original=load(path);data["name"]="Updated";data["layers"][0]["settings"]["amount"]=987;
    for(const auto* stage:{"paint-staged","thumbnail-staged","payload-published","before-commit"}){
        rejects([&]{writeEntry(path,data,info,image,nullptr,sha,false,[&](const char* at){if(std::string(at)==stage)throw std::runtime_error("Injected failure");});});
        check(load(path)==original&&read(path)["layers"][0]["paint"]==paint);
        for(const auto& entry:std::filesystem::directory_iterator(folder))check(!entry.path().filename().string().starts_with(".cyrus-entry-stage-"));
    }
    HANDLE locked=CreateFileW(path.c_str(),GENERIC_READ,FILE_SHARE_READ,nullptr,OPEN_EXISTING,FILE_ATTRIBUTE_NORMAL,nullptr);check(locked!=INVALID_HANDLE_VALUE);
    rejects([&]{writeEntry(path,data,info,image,nullptr,sha);});CloseHandle(locked);check(load(path)==original);
    const auto next=writeEntry(path,data,info,image,nullptr,sha,false,[](const char* at){if(std::string(at)=="after-commit")throw std::runtime_error("Post-commit cleanup failure");});
    check(next!=sha&&read(path)["revision"]==2&&read(path)["layers"][0]["settings"]["amount"]==987);
    const auto backup=folder/pathFromUTF8(".cyrus-previous-"+sha+".json");check(load(backup)==original&&read(backup)["layers"][0]["paint"]==paint);
    rejects([&]{writeEntry(path,data,info,image,nullptr,sha);});sha=next;
    // Rename/tags use descriptors only: corrupt Paint must not be touched by metadata maintenance.
    const auto raw=read(path,false);const auto paintFile=attachmentPath(path,raw["layers"][0]["paint"]["payload"]["file"].get<std::string>());
    put(paintFile,"bad");info["tags"]={"renamed"};const auto renamed=writeEntry(path,{{"name","New name"}},info,thumbnail(path),nullptr,sha,true);
    check(read(path,false)["name"]=="New name"&&read(path,false)["revision"]==3&&summary(path)[5]==info["tags"]);rejects([&]{read(path);});put(paintFile,{paintBytes.begin(),paintBytes.end()});check(read(path)["layers"][0]["paint"]==paint);sha=renamed;
    Json capture={{"method","viewport-published"},{"authoredSHA256",contentFingerprint(data)},{"publicationSHA256",std::string(64,'a')},{"view","perspective"},{"capturedUTC","2026-10-16T00:00:00Z"}};
    sha=writeEntry(path,data,info,image,capture,sha);check(read(path,false)["presentation"]["capture"]==capture);
    data["layers"][0]["settings"]["amount"]=988;rejects([&]{writeEntry(path,data,info,image,capture,sha);});
    auto badPresentation=read(path,false)["presentation"];badPresentation["thumbnail"]["file"]="../escape.png";rejects([&]{validateEntryPresentation(badPresentation);});
    check(load(image)==std::string(png.begin(),png.end()));
    // The revision backup can exceed MAX_PATH even when the public manifest does not.
    const auto deep=folder/std::string(55,'d');std::filesystem::create_directory(deep);
    const auto longPath=deep/(std::string(65,'r')+".csrecipe.json");
    const auto longSha=writeEntry(longPath,data,info,image,nullptr,"");
    check(longPath.wstring().size()+79>260);
    writeEntry(longPath,data,info,image,nullptr,longSha);check(read(longPath)["revision"]==2);
    check(read(deep/pathFromUTF8(".cyrus-previous-"+longSha+".json"))["revision"]==1);
    std::filesystem::remove_all(folder);folder.clear();std::cout<<"PASS: "<<checks<<" revisioned entry checks; immutable Paint, previous revisions, failure retention, stale writers and provenance\n";return 0;
}catch(const std::exception& e){if(!folder.empty()){std::error_code ec;std::filesystem::remove_all(folder,ec);}std::cerr<<e.what()<<'\n';return 1;}}
