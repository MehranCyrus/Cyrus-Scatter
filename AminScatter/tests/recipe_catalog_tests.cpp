#include "recipe_library.h"
#include "presets.h"
#include <chrono>
#include <fstream>
#include <iostream>
#include <stdexcept>

using namespace cyrus::recipes;
namespace {
unsigned checks=0;
void check(bool value){++checks;if(!value)throw std::runtime_error("Catalog assertion "+std::to_string(checks));}
template<class F>void rejected(F f){bool failed=false;try{f();}catch(const std::exception&){failed=true;}check(failed);}
void put(const std::filesystem::path& path,const std::string& bytes){std::ofstream out(path,std::ios::binary);out<<bytes;if(!out)throw std::runtime_error("Catalog fixture write failed");}
std::string load(const std::filesystem::path& path){std::ifstream in(path,std::ios::binary);return {std::istreambuf_iterator<char>(in),{}};}
template<class Read>Json wait(Read read){
    const auto deadline=std::chrono::steady_clock::now()+std::chrono::seconds(30);
    while(std::chrono::steady_clock::now()<deadline){auto page=read();if(page[0]!="scanning")return page;std::this_thread::sleep_for(std::chrono::milliseconds(2));}
    throw std::runtime_error("Catalog worker did not finish");
}
void drain(Catalogs& catalogs){
    const auto deadline=std::chrono::steady_clock::now()+std::chrono::seconds(30);
    while(catalogs.retained()&&std::chrono::steady_clock::now()<deadline){catalogs.reap();std::this_thread::sleep_for(std::chrono::milliseconds(2));}
    check(catalogs.retained()==0);
}
}
int main(){std::filesystem::path folder;try{
    folder=std::filesystem::temp_directory_path()/("cyrus-catalog-"+std::to_string(std::chrono::steady_clock::now().time_since_epoch().count()));
    std::filesystem::create_directories(folder/"large");std::filesystem::create_directory(folder/"small");
    const auto defaults=parse(load(CYRUS_RECIPE_DEFAULTS));
    Json layer={{"id","grass"},{"name","Grass"},{"enabled",true},{"visible",true},{"settings",defaults},{"paint",nullptr},{"areas",Json::array()}};
    Json document={{"format","cyrus.planting-recipe"},{"formatVersion",1},{"evaluationContract","CyrusUnified1"},{"sceneSchema",58},{"hostYear",2027},{"id","catalog-test"},{"name","Meadow"},{"unitsPerMetre",100.},{"exportScope","complete-setup"},{"rootSettings",defaults},{"roles",Json::array()},{"layers",Json::array({layer})},{"spacingRelationships",Json::array()}};
    for(int i=0;i<301;++i){auto copy=document;copy["id"]="meadow-"+std::to_string(i);copy["name"]="Meadow "+std::to_string(i);put(folder/"large"/(std::to_string(i)+".csrecipe.json"),serialize(copy));}
    put(folder/"small/only.csrecipe.json",serialize(document));put(folder/"small/broken.csrecipe.json","{");
    Library gallery;const auto galleryToken=gallery.start({folder/"large"});
    Catalogs catalogs;const auto large=catalogs.open(folder/"large"),small=catalogs.open(folder/"small");
    rejected([&]{catalogs.open(folder/"small");});
    auto first=wait([&]{return catalogs.page(large,"","",1);});
    auto second=wait([&]{return catalogs.page(small,"","",1);});
    check(first[0]=="complete"&&first[1]==256&&first[2]==256&&first[4]&&first[9].size()==128);
    check(catalogs.page(large,"","",2)[9].size()==128);
    check(second[0]=="complete"&&second[1]==2&&second[2]==1&&second[3]==1&&!second[4]);
    check(catalogs.page(small,"MEADOW","",1)[6]==1);
    const auto before=wait([&]{return gallery.page(galleryToken,"","",1);});
    check(before[2]==301&&!before[4]);
    catalogs.close(large);rejected([&]{catalogs.page(large,"","",1);});rejected([&]{catalogs.close(large);});
    check(catalogs.page(small,"","",1)==second);
    check(gallery.page(galleryToken,"","",1)==before);
    catalogs.close(small);drain(catalogs);
    const auto replacement=catalogs.open(folder/"small");check(replacement>small);
    rejected([&]{catalogs.page(small,"","",1);});
    wait([&]{return catalogs.page(replacement,"","",1);});catalogs.close(replacement);drain(catalogs);
    rejected([&]{catalogs.open("relative");});check(catalogs.retained()==0);
    const auto absent=catalogs.open(folder/"missing");
    const auto error=wait([&]{return catalogs.page(absent,"","",1);});check(error[0]=="complete"&&error[5]!=""&&error[2]==0);
    catalogs.close(absent);drain(catalogs);
    // Cancellation immediately revokes only its owner; a running worker remains
    // budgeted until terminal. No destructor/join occurs in close().
    const auto cancelling=catalogs.open(folder/"large");catalogs.close(cancelling);
    rejected([&]{catalogs.page(cancelling,"","",1);});
    check(gallery.page(galleryToken,"","",1)==before);drain(catalogs);
    // Metadata budget is independent of entry count and the legacy gallery.
    std::filesystem::create_directory(folder/"verbose");
    auto verbose=document;verbose["roles"]=Json::array();
    for(int i=0;i<8;++i)verbose["roles"].push_back({{"id","role-"+std::to_string(i)},{"name",std::string(1024,'x')},{"kind","node"},{"purposes",Json::array()},{"requirements",nullptr}});
    for(int i=0;i<256;++i){verbose["id"]="verbose-"+std::to_string(i);put(folder/"verbose"/(std::to_string(i)+".csrecipe.json"),serialize(verbose));}
    const auto bounded=catalogs.open(folder/"verbose");auto limited=wait([&]{return catalogs.page(bounded,"","",1);});
    check(limited[4]&&limited[2].get<int>()>0&&limited[2].get<int>()<256);
    catalogs.close(bounded);drain(catalogs);
    // Linked roots/files/sidecars/package directories must not extend a grant.
    std::error_code linkError;
    std::filesystem::create_directory_symlink(folder/"small",folder/"linked",linkError);
    if(!linkError){
        rejected([&]{catalogs.open(folder/"linked");});
        rejected([&]{catalogs.open(folder/"linked/../small");});
        check(catalogs.retained()==0);
        std::filesystem::create_symlink(folder/"small/only.csrecipe.json",folder/"large/linked.csrecipe.json");
        rejected([&]{summary(folder/"large/linked.csrecipe.json",true);});
        const auto longLink=folder/"large"/(std::string(210,'x')+".csrecipe.json");
        check(longLink.native().size()>260);
        std::filesystem::create_symlink(nativePath(folder/"small/only.csrecipe.json",true),nativePath(longLink,true));
        rejected([&]{summary(longLink,true);});
        check(std::filesystem::remove(nativePath(longLink,true)));
        std::filesystem::create_symlink(folder/"small/only.csrecipe.json",folder/"small/only.csrecipe.json.library.json");
        rejected([&]{summary(folder/"small/only.csrecipe.json",true);});
        std::filesystem::remove(folder/"small/only.csrecipe.json.library.json");
        std::filesystem::create_directory_symlink(folder/"large",folder/"small/Presets");
        rejected([&]{summary(folder/"small/only.csrecipe.json",true);});
        std::cout<<"PASS: linked root/file/sidecar/package confinement exercised\n";
    }else std::cout<<"UNEXERCISED: symlink confinement fixture unavailable: "<<linkError.message()<<'\n';
    check(gallery.page(galleryToken,"","",1)==before);
    // Settings catalogs reuse the bounded file worker, independently of recipes
    // and gallery, with all five existing typed categories and frozen documents.
    std::filesystem::create_directory(folder/"settings");
    for(const auto& category:{"population","transforms","spacing","density_curve","scale_curve"}){
        cyrus::presets::Document preset;preset.category=category;preset.name=category;
        if(cyrus::presets::curve(category))preset.samples={0.,1.};
        else for(const auto& field:cyrus::presets::fields(category))preset.values.push_back(field.minimum);
        if(preset.category=="transforms"){preset.values[29]=1;preset.values[31]=0;preset.values[32]=1;preset.values[33]=0;}
        put(folder/"settings"/(std::string(category)+".cspreset.json"),cyrus::presets::serialize(preset));
    }
    put(folder/"settings/bad.cspreset.json","{bad");
    Catalogs settings(true);const auto settingHandle=settings.open(folder/"settings");
    auto settingPage=wait([&]{return settings.page(settingHandle,"","",1);});check(settingPage[2]==5&&settingPage[3]==1);
    const auto visible=settings.presetPage(settingHandle,1);check(visible["entries"].size()==5&&visible["pages"]==1);
    const auto key=visible["entries"][0]["entry_key"].get<std::string>();
    const auto stored=settings.preset(settingHandle,key);check(stored["document_json"].is_string()&&stored["preset_sha256"]==visible["entries"][0]["preset_sha256"]);
    for(const auto& entry:visible["entries"])check(!entry.contains("document_text")&&!entry.contains("path"));
    // Frozen inspection does not read changed files; refresh is explicit.
    for(const auto& file:std::filesystem::directory_iterator(folder/"settings"))if(file.is_regular_file())put(file.path(),"changed");
    check(settings.preset(settingHandle,key)==stored);rejected([&]{settings.preset(settingHandle,std::string(64,'f'));});
    settings.close(settingHandle);rejected([&]{settings.preset(settingHandle,key);});drain(settings);
    check(gallery.page(galleryToken,"","",1)==before);
    // Live workers are joined by owner destruction, not left running at shutdown.
    {Catalogs shutdown;shutdown.open(folder/"large");shutdown.open(folder/"small");}
    std::filesystem::remove_all(folder);folder.clear();
    std::cout<<"PASS: "<<checks<<" catalog checks; independent gallery/readers, bounded entries/metadata, closed/stale handles, cancellation and shutdown\n";return 0;
}catch(const std::exception& e){if(!folder.empty()){std::error_code ignored;std::filesystem::remove_all(folder,ignored);}std::cerr<<e.what()<<'\n';return 1;}}
