#include "asset_package.h"
#include "shared_package.h"
#include "asset_mesh.h"
#include "asset_bitmap.h"
#include "asset_image.h"
#include "asset_shader.h"
#include "recipe_store.h"
#include "recipe_library.h"
#include <algorithm>
#include <array>
#include <cmath>
#include <chrono>
#include <fstream>
#include <limits>
#include <set>
#include <stdexcept>
#ifndef NOMINMAX
#define NOMINMAX
#endif
#include <windows.h>
#include <bcrypt.h>

namespace cyrus::assets {
namespace {
void require(bool value,const char* message){if(!value)throw std::invalid_argument(message);}
static_assert(maxPlantMeshFileBytes==maxPlantMeshBytes);
bool plantAssets(const Json& graph){return graph.at("version")==4||(graph.at("version")==3&&graph.at("resourceProfile")=="plant-assets-v1");}
bool imageMap(const Json& map){return map.at("kind")=="bitmap"||map.at("kind")=="corona-bitmap-v1";}
std::uint64_t packageBudget(const Json& graph){return plantAssets(graph)?maxPlantPackageBytes:maxPackageBytes;}
std::uint64_t fileBudget(const Json& graph,const Json& file){return plantAssets(graph)&&file.at("kind")=="mesh"?maxPlantMeshFileBytes:maxFileBytes;}
MeshProfile meshProfile(const Json& graph){return plantAssets(graph)?MeshProfile::Plant:MeshProfile::Legacy;}
std::span<const unsigned char> meshBytes(const std::string& value){return {reinterpret_cast<const unsigned char*>(value.data()),value.size()};}
void keys(const Json& value,std::initializer_list<const char*> names){require(value.is_object()&&value.size()==names.size(),"Unexpected asset fields.");for(auto name:names)require(value.contains(name),"Incomplete asset record.");}
std::string text(const Json& value,std::size_t cap=160){require(value.is_string(),"Asset text required.");auto s=value.get<std::string>();require(s.size()<=cap&&s.find('\0')==std::string::npos,"Asset text exceeds bounds or contains NUL.");return s;}
std::string identity(const Json& value){const auto s=text(value,80);require(!s.empty()&&std::all_of(s.begin(),s.end(),[](unsigned char c){return(c>='a'&&c<='z')||(c>='A'&&c<='Z')||(c>='0'&&c<='9')||c=='-'||c=='_';}),"Asset IDs require ASCII letters, digits, hyphen or underscore.");return s;}
std::string hash(const Json& value){const auto s=text(value,64);require(s.size()==64&&std::all_of(s.begin(),s.end(),[](char c){return(c>='0'&&c<='9')||(c>='a'&&c<='f');}),"Invalid asset SHA-256.");return s;}
double number(const Json& value,double lo,double hi){require(value.is_number(),"Asset number required.");const auto v=value.get<double>();require(std::isfinite(v)&&v>=lo&&v<=hi,"Asset number outside bounds.");return v;}
void vector(const Json& value,std::size_t size,double lo,double hi){require(value.is_array()&&value.size()==size,"Invalid asset vector.");for(const auto& v:value)number(v,lo,hi);}
std::string suffix(const Json& file){const auto s=text(file.at("suffix"),8);const std::set<std::string> supported={"cmesh","png","jpg","jpeg","tga","bmp","tif","tiff"};require(supported.count(s)!=0,"Unsupported package file suffix.");require((file.at("kind")=="mesh")== (s=="cmesh"),"Asset file type and suffix differ.");return s;}
std::string relative(const Json& file){return "assets/"+hash(file.at("sha256"))+"."+suffix(file);}
std::string load(const std::filesystem::path& path,std::size_t cap){std::ifstream in(recipes::nativePath(path),std::ios::binary|std::ios::ate);require(bool(in),"Cannot read package document.");const auto n=in.tellg();require(n>=0&&static_cast<std::uint64_t>(n)<=cap,"Package document exceeds its limit.");std::string data(static_cast<std::size_t>(n),'\0');in.seekg(0);if(n>0)in.read(data.data(),n);require(bool(in),"Incomplete package document.");return data;}
std::string digest(const std::string& data);
void put(const std::filesystem::path& rawPath,const std::string& data){const auto path=recipes::nativePath(rawPath);require(!std::filesystem::exists(path),"Package staging collision.");std::filesystem::create_directories(path.parent_path());std::ofstream out(path,std::ios::binary);require(bool(out),"Cannot write package staging file.");out.write(data.data(),static_cast<std::streamsize>(data.size()));out.flush();require(bool(out),"Package staging write failed.");out.close();require(load(path,data.size())==data,"Package staging readback failed.");}
struct Hash {
    BCRYPT_ALG_HANDLE algorithm=nullptr;BCRYPT_HASH_HANDLE value=nullptr;
    Hash(){require(BCryptOpenAlgorithmProvider(&algorithm,BCRYPT_SHA256_ALGORITHM,nullptr,0)>=0,"Package hash provider unavailable.");if(BCryptCreateHash(algorithm,&value,nullptr,0,nullptr,0,0)<0){BCryptCloseAlgorithmProvider(algorithm,0);algorithm=nullptr;throw std::runtime_error("Package hash unavailable.");}}
    ~Hash(){if(value)BCryptDestroyHash(value);if(algorithm)BCryptCloseAlgorithmProvider(algorithm,0);}
    void add(unsigned char* data,ULONG size){require(BCryptHashData(value,data,size,0)>=0,"Package hashing failed.");}
    std::string finish(){std::vector<unsigned char> bytes(32);require(BCryptFinishHash(value,bytes.data(),32,0)>=0,"Package hashing failed.");return recipes::hex(bytes);}
};
std::string digest(const std::string& data){
    // Hash the already bounded storage directly. A second 224-MiB mesh-sized
    // allocation is unnecessary just to adapt string storage to vector storage.
    Hash hash;require(data.size()<=std::numeric_limits<ULONG>::max(),"Package hash input exceeds its byte range.");
    hash.add(reinterpret_cast<unsigned char*>(const_cast<char*>(data.data())),static_cast<ULONG>(data.size()));return hash.finish();
}
void admitPlantPreparation(const Json& graph){
    if(!plantAssets(graph))return;
    std::uint64_t meshes=0,largest=0;
    for(const auto& file:graph.at("files"))if(file.at("kind")=="mesh"){
        const auto bytes=file.at("bytes").get<std::uint64_t>();meshes+=bytes;largest=std::max(largest,bytes);
    }
    // Twice encoded bytes conservatively admit typed-vector alignment, plus
    // bounded per-vector metadata. Include decode/hash overlap and the JPEG
    // helper's independent 256-MiB allocator budget. This is native preparation
    // admission only; host meshes, bitmaps, history and renderer require their
    // separate host-stage admission and measured qualification.
    const auto needed=meshes*2+largest*2+128ull*4096ull+256ull*1024ull*1024ull+2ull*1024ull*1024ull*1024ull;
    MEMORYSTATUSEX memory{};memory.dwLength=sizeof(memory);
    require(GlobalMemoryStatusEx(&memory)!=FALSE,"Cannot inspect plant preparation memory headroom.");
    require(memory.ullAvailPhys>=needed&&memory.ullAvailPageFile>=needed,"Insufficient physical/commit memory for plant mesh preparation and its 2 GiB reserve.");
}
std::string stream(const std::filesystem::path& rawInput,const std::filesystem::path& rawOutput,std::uint64_t expected,const Checkpoint& point){
    const auto input=recipes::nativePath(rawInput),output=rawOutput.empty()?rawOutput:recipes::nativePath(rawOutput);
    require(std::filesystem::is_regular_file(input)&&!std::filesystem::is_symlink(input),"Package dependency must be a regular, unlinked file.");
    require(std::filesystem::file_size(input)==expected,"Package dependency size changed.");
    std::ifstream in(input,std::ios::binary);require(bool(in),"Cannot open package dependency.");std::ofstream out;
    if(!output.empty()){require(!std::filesystem::exists(output),"Package payload already exists.");std::filesystem::create_directories(output.parent_path());out.open(output,std::ios::binary);require(bool(out),"Cannot stage package dependency.");}
    Hash hash;std::array<unsigned char,262144> buffer{};std::uint64_t total=0;
    while(in){in.read(reinterpret_cast<char*>(buffer.data()),buffer.size());const auto n=in.gcount();if(n>0){total+=static_cast<std::uint64_t>(n);require(total<=expected,"Package dependency grew while reading.");hash.add(buffer.data(),static_cast<ULONG>(n));if(!output.empty())out.write(reinterpret_cast<char*>(buffer.data()),n);if(point)point("file-chunk",total);}}
    require(in.eof()&&total==expected,"Package dependency changed or could not be read.");
    if(!output.empty()){out.flush();require(bool(out),"Package payload write failed.");out.close();require(!out.fail(),"Package payload close failed.");}
    return hash.finish();
}
std::filesystem::path contained(const std::filesystem::path& root,const std::string& path){return recipes::attachmentPath(root/"entry.csrecipe.json",path);}
std::string nonce(){std::vector<unsigned char> bytes(16);require(BCryptGenRandom(nullptr,bytes.data(),16,BCRYPT_USE_SYSTEM_PREFERRED_RNG)>=0,"Cannot create package staging identity.");return recipes::hex(bytes);}
void filesystem(const std::filesystem::path& parent){wchar_t volume[MAX_PATH]{},format[64]{};require(GetVolumePathNameW(parent.c_str(),volume,MAX_PATH)!=FALSE,"Cannot determine package filesystem.");const auto type=GetDriveTypeW(volume);require(type==DRIVE_FIXED||type==DRIVE_REMOVABLE,"Package export requires a local NTFS folder.");require(GetVolumeInformationW(volume,nullptr,0,nullptr,nullptr,nullptr,format,64)!=FALSE&&std::wstring(format)==L"NTFS","Package export requires local NTFS.");}
template<class F>void paints(const Json& recipe,F f){for(const auto& layer:recipe.at("layers")){if(!layer.at("paint").is_null())f(layer.at("paint").at("payload"));for(const auto& area:layer.at("areas"))if(!area.at("paint").is_null())f(area.at("paint").at("payload"));}}
Json descriptor(const std::string& path,const std::string& bytes){return {{"file",path},{"sha256",digest(bytes)},{"bytes",bytes.size()}};}
void verifyDescriptor(const std::filesystem::path& root,const Json& row,std::size_t cap,const Checkpoint& point){
    keys(row,{"file","sha256","bytes"});const auto bytes=number(row.at("bytes"),1,static_cast<double>(cap));
    require(row.at("bytes").is_number_integer(),"Package byte size must be an integer.");
    const auto file=text(row.at("file"),240);const auto path=contained(root,file);
    try{require(stream(path,{},static_cast<std::uint64_t>(bytes),point)==hash(row.at("sha256")),"Package payload hash mismatch.");}
    catch(const std::invalid_argument& failure){throw std::invalid_argument("Package payload '"+file+"': "+failure.what()+" Restore this package dependency or re-export the preset.");}
}
Json readDescriptor(const std::filesystem::path& root,const Json& row,std::size_t cap){
    keys(row,{"file","sha256","bytes"});require(row.at("bytes").is_number_integer(),"Package byte size must be an integer.");const auto expected=static_cast<std::size_t>(number(row.at("bytes"),1,static_cast<double>(cap)));
    const auto bytes=load(contained(root,text(row.at("file"),240)),cap);require(bytes.size()==expected&&digest(bytes)==hash(row.at("sha256")),"Package document changed or has a wrong hash.");return recipes::parse(bytes);
}
}

void validateGraph(const Json& graph,const Json& recipe){
    const bool sharedMesh=graph.value("version",0)==4;
    const bool plant=graph.value("version",0)==3,context=graph.value("version",0)==2||plant||sharedMesh;
    if(plant){keys(graph,{"format","version","nodes","meshes","materials","maps","files","externalRoles","splines","rendererProfile","resourceProfile"});require(graph.at("resourceProfile")=="plant-images-v1"||graph.at("resourceProfile")=="plant-assets-v1","Unsupported plant resource profile.");require(recipe.at("hostYear")==2027,"Plant renderer adapters require Max 2027 recipes.");}
    else if(sharedMesh){keys(graph,{"format","version","nodes","meshes","materials","maps","files","externalRoles","splines","resourceProfile"});require(graph.at("resourceProfile")=="shared-static-v1","Unsupported shared geometry profile.");}
    else if(context)keys(graph,{"format","version","nodes","meshes","materials","maps","files","externalRoles","splines"});
    else keys(graph,{"format","version","nodes","meshes","materials","maps","files","externalRoles"});
    require(graph.at("format")=="cyrus.library-assets"&&(graph.at("version")==1||context),"Unsupported asset graph.");
    std::map<std::string,std::string> roleKinds,fileKinds;std::set<std::string> assigned,ids,meshes,materials,maps;
    for(const auto& role:recipe.at("roles"))roleKinds.emplace(role.at("id").get<std::string>(),role.at("kind").get<std::string>());
    for(const auto* name:{"nodes","meshes","materials","maps","files","externalRoles"})require(graph.at(name).is_array()&&graph.at(name).size()<=(std::string(name)=="files"?maxFiles:std::string(name)=="maps"&&plantAssets(graph)?maxPlantMapObjects:maxObjects),"Asset graph count exceeds bounds.");
    std::uint64_t total=0;
    for(const auto& file:graph.at("files")){keys(file,{"id","kind","sha256","bytes","suffix"});const auto id=identity(file.at("id"));require(ids.insert(id).second,"Duplicate asset ID.");require(file.at("kind")=="mesh"||file.at("kind")=="bitmap","Unsupported asset file kind.");fileKinds.emplace(id,file.at("kind").get<std::string>());hash(file.at("sha256"));const auto extension=suffix(file);if(plant&&file.at("kind")=="bitmap")require(extension=="png"||extension=="jpg"||extension=="jpeg","Unsupported plant bitmap suffix.");require(file.at("bytes").is_number_integer(),"Asset byte size must be an integer.");total+=static_cast<std::uint64_t>(number(file.at("bytes"),1,static_cast<double>(fileBudget(graph,file))));require(total<=packageBudget(graph),"Asset payloads exceed the package byte budget.");}
    auto reference=[&](const Json& value,const std::set<std::string>& allowed){if(!value.is_null())require(allowed.count(identity(value))!=0,"Missing or incompatible asset reference.");};
    auto roles=[&](const Json& values,const std::string& kind){require(values.is_array()&&values.size()<=maxObjects,"Asset role count exceeds bounds.");for(const auto& value:values){const auto id=text(value);require(roleKinds.count(id)!=0&&roleKinds.at(id)==kind&&assigned.insert(id).second,"Unknown, duplicate or incompatible asset role.");}};
    for(const auto& mesh:graph.at("meshes")){keys(mesh,{"id","file"});const auto id=identity(mesh.at("id"));require(ids.insert(id).second,"Duplicate asset ID.");meshes.insert(id);const auto file=identity(mesh.at("file"));require(fileKinds.count(file)!=0&&fileKinds.at(file)=="mesh","Mesh requires a declared mesh file.");}
    std::uint64_t bitmapPixels=0;
    for(const auto& map:graph.at("maps")){
        const auto id=identity(map.at("id"));require(ids.insert(id).second,"Duplicate asset ID.");maps.insert(id);
        const bool coronaBitmap=plant&&map.at("kind")=="corona-bitmap-v1";
        if(plant&&!imageMap(map))continue;
        if(coronaBitmap)keys(map,{"id","kind","name","roles","file","size","color","properties","links","coordinates","output"});
        else{keys(map,{"id","kind","name","file","channel","uv","size","color","sampler","output","roles"});require(map.at("kind")=="bitmap","Unsupported map adapter.");require(map.at("channel").is_number_integer(),"Map channel must be an integer.");number(map.at("channel"),1,99);vector(map.at("uv"),5,-1e6,1e6);}
        text(map.at("name"));const auto file=identity(map.at("file"));require(fileKinds.count(file)!=0&&fileKinds.at(file)=="bitmap","Bitmap requires a declared image file.");roles(map.at("roles"),"texture");
        if(coronaBitmap)require(map.at("roles").empty(),"Corona bitmap shader maps cannot bind density texture roles.");
        vector(map.at("size"),2,1,plant?8192:4096);for(const auto& v:map.at("size"))require(v.is_number_integer(),"Bitmap dimensions must be integers.");
        bitmapPixels+=map.at("size")[0].get<std::uint64_t>()*map.at("size")[1].get<std::uint64_t>();require(bitmapPixels<=(plant?maxPlantBitmapPixels:maxPackageBitmapPixels),plant?"Plant bitmap map instances exceed 512 Mpixels.":"Package bitmap map instances exceed 16 Mpixels.");
        const auto& color=map.at("color");
        if((plant||sharedMesh)&&!coronaBitmap){keys(color,{"mode","configSHA256","renderingSpace","dataSpace","inputSpace","inputGamma","effectiveGamma"});const auto& gamma=color.at("inputGamma");if(gamma.is_string())require(gamma=="auto","Unsupported bitmap input gamma symbol.");else number(gamma,0.1,10.);number(color.at("effectiveGamma"),0.1,10.);}
        else keys(color,{"mode","configSHA256","renderingSpace","dataSpace","inputSpace"});
        require(color.at("mode")=="OCIO_Default","Unsupported bitmap colour pipeline.");hash(color.at("configSHA256"));for(const auto* name:{"renderingSpace","dataSpace","inputSpace"})require(!text(color.at(name)).empty(),"Bitmap colour space is missing.");
        if(coronaBitmap){require(color.at("inputSpace")==map.at("properties").at("colorSpaceStr"),"Corona bitmap input space disagrees with its shader interpretation.");continue;}
        const auto& sampler=map.at("sampler");keys(sampler,{"filtering","monoOutput","rgbOutput","alphaSource","preMultAlpha","uMirror","vMirror","uTile","vTile","blur","blurOffset"});
        for(const auto* name:{"filtering","monoOutput","rgbOutput","alphaSource"}){require(sampler.at(name).is_number_integer(),"Bitmap sampler enum must be an integer.");number(sampler.at(name),0,std::string(name)=="filtering"||std::string(name)=="alphaSource"?2:1);}
        for(const auto* name:{"preMultAlpha","uMirror","vMirror","uTile","vTile"})require(sampler.at(name).is_boolean(),"Bitmap sampler Boolean required.");number(sampler.at("blur"),0,1000);number(sampler.at("blurOffset"),-1000,1000);
        const auto& output=map.at("output");keys(output,{"invert","clamp","alphaFromRGB","rgbLevel","rgbOffset","outputAmount"});for(const auto* name:{"invert","clamp","alphaFromRGB"})require(output.at(name).is_boolean(),"Bitmap output Boolean required.");for(const auto* name:{"rgbLevel","rgbOffset","outputAmount"})number(output.at(name),-1e6,1e6);
    }
    for(const auto& material:graph.at("materials")){
        const auto id=identity(material.at("id"));require(ids.insert(id).second,"Duplicate asset ID.");materials.insert(id);
        if(plant&&material.at("kind")!="standard-blinn")continue;
        keys(material,{"id","kind","name","diffuse","ambient","specular","specularLevel","glossiness","soften","selfIllumAmount","selfIllumColor","useSelfIllumColor","ambientDiffuseLock","diffuseSpecularLock","textureLock","opacity","twoSided","maps"});require(material.at("kind")=="standard-blinn","Unsupported material adapter.");text(material.at("name"));
        for(const auto* name:{"diffuse","ambient","specular","selfIllumColor"})vector(material.at(name),3,0,255);
        for(const auto* name:{"opacity","glossiness","selfIllumAmount"})number(material.at(name),0,100);
        number(material.at("specularLevel"),0,999);number(material.at("soften"),0,1);
        for(const auto* name:{"twoSided","useSelfIllumColor","ambientDiffuseLock","diffuseSpecularLock","textureLock"})require(material.at(name).is_boolean(),"Material Boolean flag required.");
        const auto& slots=material.at("maps");require(slots.is_array()&&slots.size()==3,"Material requires three explicit map slots.");std::set<std::string> seen;
        for(const auto& slot:slots){keys(slot,{"slot","map","amount","enabled"});const auto name=text(slot.at("slot"));require((name=="ambient"||name=="diffuse"||name=="opacity")&&seen.insert(name).second,"Unsupported or duplicate material map slot.");reference(slot.at("map"),maps);number(slot.at("amount"),-1000,1000);require(slot.at("enabled").is_boolean(),"Material map enable flag required.");}
    }
    if(plant)validateRendererShaders(graph);
    for(const auto& node:graph.at("nodes")){keys(node,{"id","name","mesh","material","transform","wireColor","roles"});require(ids.insert(identity(node.at("id"))).second,"Duplicate asset ID.");text(node.at("name"));require(!node.at("mesh").is_null(),"Asset node requires a mesh.");reference(node.at("mesh"),meshes);reference(node.at("material"),materials);vector(node.at("transform"),12,-1e9,1e9);vector(node.at("wireColor"),3,0,255);roles(node.at("roles"),"node");}
    if(context){
        const auto& splines=graph.at("splines");require(splines.is_array()&&splines.size()<=maxObjects,"Spline count exceeds bounds.");std::size_t knots=0;
        for(const auto& shape:splines){
            keys(shape,{"id","name","transform","wireColor","roles","curves"});require(ids.insert(identity(shape.at("id"))).second,"Duplicate asset ID.");text(shape.at("name"));vector(shape.at("transform"),12,-1e9,1e9);vector(shape.at("wireColor"),3,0,255);roles(shape.at("roles"),"node");
            const auto& curves=shape.at("curves");require(curves.is_array()&&!curves.empty()&&curves.size()<=128,"Spline curve count exceeds bounds.");
            for(const auto& curve:curves){keys(curve,{"closed","knots"});require(curve.at("closed").is_boolean(),"Spline closure must be Boolean.");const auto& rows=curve.at("knots");require(rows.is_array()&&rows.size()>=2,"Spline needs at least two knots.");knots+=rows.size();require(knots<=4096,"Preset splines exceed 4096 knots.");
                for(const auto& knot:rows){keys(knot,{"type","line","point","in","out"});const auto type=text(knot.at("type")),line=text(knot.at("line"));require(type=="corner"||type=="smooth"||type=="bezier"||type=="bezierCorner","Unsupported spline knot type.");require(line=="line"||line=="curve","Unsupported spline segment type.");for(const auto* key:{"point","in","out"})vector(knot.at(key),3,-1e9,1e9);}
            }
        }
    }
    for(const auto& role:graph.at("externalRoles")){const auto id=text(role);require(roleKinds.count(id)!=0&&assigned.insert(id).second,"Unknown or duplicate external role.");}
    require(assigned.size()==roleKinds.size(),"Asset graph must retain every recipe role as packaged or explicitly external.");
}

std::filesystem::path writePackage(const std::filesystem::path& rawInput,const std::filesystem::path& rawSource,const std::string& expected,
 const Json& graph,const std::map<std::string,std::filesystem::path>& inputs,const std::string& redistribution,const Checkpoint& point){
    require(rawInput.is_absolute()&&rawSource.is_absolute(),"Package export needs absolute paths.");
    const auto input=recipes::nativePath(rawInput),source=recipes::nativePath(rawSource);
    require(input.is_absolute()&&source.is_absolute()&&!input.filename().empty(),"Package export needs absolute paths.");hash(expected);require(!redistribution.empty(),"Confirm permission to redistribute the packaged content.");text(redistribution,1024);
    require(std::filesystem::is_directory(input.parent_path()),"Choose an existing package parent folder.");const auto parent=recipes::nativePath(std::filesystem::canonical(input.parent_path())),output=parent/input.filename();filesystem(parent);require(!std::filesystem::exists(output),"Package destination exists. Choose a new folder.");
    const auto recipeBytes=load(source,recipes::maxManifestBytes);require(digest(recipeBytes)==expected,"Recipe changed since export review.");const auto recipe=recipes::parse(recipeBytes);require(recipe.at("formatVersion")==5||recipe.at("formatVersion")==6||recipe.at("formatVersion")==7||recipe.at("formatVersion")==8,"Resave this recipe before portable export.");recipes::validate(recipe,false);validateGraph(graph,recipe);require(inputs.size()==graph.at("files").size(),"Resolve every package file exactly once.");
    const auto graphBytes=graph.dump();require(graphBytes.size()<=maxGraphBytes,"Asset graph metadata exceeds its budget.");
    const auto stage=parent/recipes::pathFromUTF8(".cyrus-package-stage-"+nonce());bool owned=false,published=false;std::uint64_t copied=recipeBytes.size()+graphBytes.size();std::set<std::string> stored;
    auto notify=[&](const char* name){if(point)point(name,copied);};
    try{
        require(std::filesystem::create_directory(stage),"Cannot create package staging folder.");owned=true;notify("started");
        auto copy=[&](const std::filesystem::path& from,const Json& row,std::uint64_t cap){const auto relativePath=text(row.at("file"),240);const auto to=contained(stage,relativePath);const auto bytes=static_cast<std::uint64_t>(number(row.at("bytes"),1,static_cast<double>(cap)));require(row.at("bytes").is_number_integer(),"Payload byte size must be an integer.");const auto sha=hash(row.at("sha256"));
            if(stored.insert(relativePath).second){copied+=bytes;require(copied<=packageBudget(graph),"Complete package exceeds its resource-profile byte budget.");
                if(shared::ownedStage(from,to)){require(stream(from,{},bytes,point)==sha,"Owned source dependency changed.");std::filesystem::create_directories(to.parent_path());std::filesystem::create_hard_link(from,to);}
                else require(stream(from,to,bytes,point)==sha,"Source dependency changed or has a wrong hash.");
                require(stream(to,{},bytes,point)==sha,"Staged payload readback failed.");}else require(stream(to,{},bytes,point)==sha,"Package payload identity collision.");};
        paints(recipe,[&](const Json& row){copy(recipes::attachmentPath(source,text(row.at("file"),240)),row,recipes::maxPaintBytes);});notify("paint-staged");
        if(!recipe.at("presentation").is_null()&&!recipe.at("presentation").at("thumbnail").is_null()){const auto& row=recipe.at("presentation").at("thumbnail");copy(recipes::attachmentPath(source,text(row.at("file"),240)),row,recipes::maxThumbnailBytes);}
        for(const auto& file:graph.at("files")){const auto id=identity(file.at("id"));require(inputs.count(id)!=0&&inputs.at(id).is_absolute(),"Package file binding needs an absolute input path.");copy(inputs.at(id),{{"file",relative(file)},{"bytes",file.at("bytes")},{"sha256",file.at("sha256")}},fileBudget(graph,file));notify("asset-staged");}
        put(stage/"entry.csrecipe.json",recipeBytes);put(stage/"assets.json",graphBytes);
        Json manifest={{"format","cyrus.library-package"},{"version",1},{"hostYear",recipe.at("hostYear")},{"recipe",descriptor("entry.csrecipe.json",recipeBytes)},{"graph",descriptor("assets.json",graphBytes)},{"redistribution",redistribution}};
        put(stage/"cyrus.package.json",manifest.dump(2));readPackage(stage,point);notify("verified");require(digest(load(source,recipes::maxManifestBytes))==expected,"Recipe changed while exporting.");notify("before-commit");require(!std::filesystem::exists(output),"Package destination appeared while exporting.");std::filesystem::rename(stage,output);published=true;owned=false;
        try{notify("complete");}catch(...){}return output/"cyrus.package.json";
    }catch(...){if(owned&&!published){std::error_code error;std::filesystem::remove_all(stage,error);}throw;}
}

Json readPackage(const std::filesystem::path& rawDirectory,const Checkpoint& point){
    require(rawDirectory.is_absolute(),"Package requires an absolute folder.");
    const auto directory=shared::resolve(rawDirectory);
    require(directory.is_absolute()&&std::filesystem::is_directory(directory)&&!std::filesystem::is_symlink(directory),"Package requires an unlinked absolute folder.");
    const auto manifest=recipes::parse(load(directory/"cyrus.package.json",8192));keys(manifest,{"format","version","hostYear","recipe","graph","redistribution"});require(manifest.at("format")=="cyrus.library-package"&&manifest.at("version")==1&&(manifest.at("hostYear")==2024||manifest.at("hostYear")==2026||manifest.at("hostYear")==2027),"Unsupported library package.");require(!text(manifest.at("redistribution"),1024).empty(),"Package redistribution declaration missing.");require(manifest.at("recipe").at("file")=="entry.csrecipe.json"&&manifest.at("graph").at("file")=="assets.json","Unexpected package document paths.");
    const auto recipe=readDescriptor(directory,manifest.at("recipe"),recipes::maxManifestBytes);require(recipe.at("formatVersion")==5||recipe.at("formatVersion")==6||recipe.at("formatVersion")==7||recipe.at("formatVersion")==8,"Unsupported package recipe version.");recipes::validate(recipe,false);
    const auto graph=readDescriptor(directory,manifest.at("graph"),maxGraphBytes);validateGraph(graph,recipe);admitPlantPreparation(graph);const bool plant=graph.at("version")==3;
    if(plant)require(manifest.at("hostYear")==2027,"Plant package manifest requires Max 2027.");
    std::uint64_t total=manifest.at("recipe").at("bytes").get<std::uint64_t>()+manifest.at("graph").at("bytes").get<std::uint64_t>();std::set<std::string> files;
    auto verify=[&](const Json& row,std::size_t cap){const auto file=text(row.at("file"),240);if(files.insert(file).second){total+=row.at("bytes").get<std::uint64_t>();require(total<=packageBudget(graph),"Complete package exceeds its resource-profile byte budget.");verifyDescriptor(directory,row,cap,point);}};
    paints(recipe,[&](const Json& row){verify(row,recipes::maxPaintBytes);});if(!recipe.at("presentation").is_null()&&!recipe.at("presentation").at("thumbnail").is_null())verify(recipe.at("presentation").at("thumbnail"),recipes::maxThumbnailBytes);
    for(const auto& file:graph.at("files")){
        verify({{"file",relative(file)},{"bytes",file.at("bytes")},{"sha256",file.at("sha256")}},fileBudget(graph,file));
        if(file.at("kind")=="mesh"){
            const auto bytes=load(contained(directory,relative(file)),static_cast<std::size_t>(fileBudget(graph,file)));require(digest(bytes)==file.at("sha256").get<std::string>(),"Mesh changed during verification.");decodeMesh(meshBytes(bytes),meshProfile(graph));
        }else{
            const bool sharedJPEG=graph.at("version")==4&&(file.at("suffix")=="jpg"||file.at("suffix")=="jpeg");
            if(!plant&&!sharedJPEG)require(file.at("suffix")=="png","This portable bitmap adapter requires PNG or a supported shared JPEG.");
            const auto bytes=load(contained(directory,relative(file)),static_cast<std::size_t>(maxFileBytes));require(digest(bytes)==file.at("sha256").get<std::string>(),"Bitmap changed during verification.");
            std::array<std::uint32_t,2> dimensions{};
            if(plant||sharedJPEG){const auto info=inspectPortableImage({bytes.begin(),bytes.end()},suffix(file));dimensions={info.width,info.height};}
            else {const auto info=inspectPNG({bytes.begin(),bytes.end()});dimensions={info.width,info.height};}
            for(const auto& map:graph.at("maps"))if(imageMap(map)&&map.at("file")==file.at("id"))require(map.at("size")[0]==dimensions[0]&&map.at("size")[1]==dimensions[1],"Bitmap dimensions disagree with the declared graph.");
        }
    }
    return {{"manifest",manifest},{"recipe",recipe},{"graph",graph}};
}

Json readModelPackage(const std::filesystem::path& rawDirectory,const Checkpoint& point){
    require(rawDirectory.is_absolute(),"Model package requires an absolute folder.");const auto directory=recipes::nativePath(rawDirectory);shared::noLinks(directory);
    const auto manifest=recipes::parse(load(directory/"cyrus.model.json",262144));
    keys(manifest,{"format","version","definition","graph","definitions","redistribution"});require(manifest.at("format")=="cyrus.model-package"&&manifest.at("version")==1,"Unsupported model package.");text(manifest.at("redistribution"),4096);
    require(manifest.at("definition").at("file")=="model.json"&&manifest.at("graph").at("file")=="assets.json","Unexpected model documents.");
    const auto definition=readDescriptor(directory,manifest.at("definition"),16384);keys(definition,{"format","version","mesh","material","rendererProfile","graph"});
    if(directory.parent_path().filename()=="models")require(directory.filename()==manifest.at("definition").at("sha256").get<std::string>(),"Model directory differs from its revision.");
    require(definition.at("format")=="cyrus.model-definition"&&definition.at("version")==1,"Unsupported model definition.");hash(definition.at("mesh"));if(!definition.at("material").is_null())hash(definition.at("material"));
    const auto graph=readDescriptor(directory,manifest.at("graph"),maxGraphBytes);require(hash(definition.at("graph"))==hash(manifest.at("graph").at("sha256")),"Model graph differs from its revision.");
    require(graph.at("nodes").size()==1&&graph.value("splines",Json::array()).empty()&&graph.at("externalRoles").empty(),"A model package contains exactly one complete source and no context.");
    const Json recipe={{"hostYear",2027},{"roles",Json::array({{{"id","model-role"},{"kind","node"},{"name","Model"},{"purposes",Json::array({"sources"})},{"requirements",nullptr}}})}};
    validateGraph(graph,recipe);admitPlantPreparation(graph);
    const auto& node=graph.at("nodes").at(0);require(node.at("id")=="model-1"&&node.at("roles")==Json::array({"model-role"})&&node.at("transform")==Json::array({1,0,0,0,1,0,0,0,1,0,0,0}),"Model source frame is not normalized.");
    const auto profile=graph.value("rendererProfile",Json(nullptr));require(profile==definition.at("rendererProfile"),"Model compatibility requirements differ.");
    std::map<std::string,Json> records;for(const auto* group:{"meshes","materials","maps"})for(const auto& record:graph.at(group)){
        const auto id=record.at("id").get<std::string>();const char prefix=std::string(group)=="meshes"?'g':std::string(group)=="materials"?'m':'x';require(id.size()>1&&id[0]==prefix&&id[1]=='-',"Model record kind prefix differs.");records.emplace(id,record);
    }
    auto dependencies=records;for(const auto& file:graph.at("files"))dependencies.emplace(file.at("id").get<std::string>(),file);std::set<std::string> reachable;
    std::function<void(const Json&)> visit=[&](const Json& value){
        if(value.is_string()){const auto id=value.get<std::string>();const auto found=dependencies.find(id);if(found!=dependencies.end()&&reachable.insert(id).second)visit(found->second);}
        else if(value.is_structured())for(const auto& child:value)visit(child);
    };visit(node.at("mesh"));visit(node.at("material"));require(reachable.size()==dependencies.size(),"Model package contains unrelated dependencies.");
    auto occurrenceHash=[&](const std::string& id){require(id.size()>67&&id[1]=='-'&&id[66]=='-'&&id[67]>='1'&&id[67]<='9'&&id.find_first_not_of("0123456789",67)==std::string::npos,"Invalid model definition occurrence.");return hash(id.substr(2,64));};
    require(occurrenceHash(node.at("mesh").get<std::string>())==definition.at("mesh").get<std::string>(),"Model mesh pin differs.");
    require(node.at("material").is_null()?definition.at("material").is_null():occurrenceHash(node.at("material").get<std::string>())==definition.at("material").get<std::string>(),"Model material pin differs.");
    require(manifest.at("definitions").is_array()&&manifest.at("definitions").size()<=512,"Model definition count exceeds bounds.");std::map<std::string,Json> definitions;std::uint64_t metadata=0;
    for(const auto& row:manifest.at("definitions")){const auto sha=hash(row.at("sha256"));require(row.at("file")=="definitions/"+sha+".json"&&definitions.count(sha)==0,"Invalid or duplicate model definition.");
        metadata+=row.at("bytes").get<std::uint64_t>();require(metadata<=4ull*1024*1024,"Model definitions exceed 4 MiB.");definitions.emplace(sha,readDescriptor(directory,row,maxGraphBytes));if(point)point("model-definition",metadata);}
    std::set<std::string> used;
    std::function<Json(const Json&)> values=[&](const Json& value)->Json{
        if(value.is_string()&&records.count(value.get<std::string>()))return value.get<std::string>().substr(0,66);
        if(value.is_array()){auto result=Json::array();for(const auto& item:value)result.push_back(values(item));return result;}
        if(value.is_object()){auto result=Json::object();for(auto at=value.begin();at!=value.end();++at)result[at.key()]=values(at.value());return result;}return value;
    };
    for(const auto& [id,record]:records){const auto sha=occurrenceHash(id);require(definitions.count(sha)!=0,"Model definition is missing.");used.insert(sha);const auto& stored=definitions.at(sha);
        keys(stored,{"format","version","profile","data"});const std::string type=id[0]=='g'?"mesh":id[0]=='m'?"material":"map";
        require(stored.at("format")=="cyrus."+type+"-definition"&&stored.at("version")==1,"Model definition kind differs.");
        require(stored.at("profile").is_null()||stored.at("profile")==profile,"Model definition adapter profile differs.");
        auto data=record;data.erase("id");data.erase("name");data.erase("roles");require(values(data)==stored.at("data"),"Model occurrence differs from its shared definition.");
    }
    require(used.size()==definitions.size(),"Model package contains unrelated definitions.");
    std::uint64_t total=0;for(const auto& file:graph.at("files")){
        require(file.at("id")=="f-"+hash(file.at("sha256")),"Model payload identity differs.");total+=file.at("bytes").get<std::uint64_t>();require(total<=packageBudget(graph),"Model payload exceeds its profile bound.");
        verifyDescriptor(directory,{{"file",relative(file)},{"bytes",file.at("bytes")},{"sha256",file.at("sha256")}},fileBudget(graph,file),point);
        const auto bytes=load(contained(directory,relative(file)),static_cast<std::size_t>(fileBudget(graph,file)));
        if(file.at("kind")=="mesh")decodeMesh(meshBytes(bytes),meshProfile(graph));
        else{std::array<std::uint32_t,2> dimensions{};if(graph.at("version")==3||file.at("suffix")!="png"){const auto info=inspectPortableImage({bytes.begin(),bytes.end()},suffix(file));dimensions={info.width,info.height};}
            else{const auto info=inspectPNG({bytes.begin(),bytes.end()});dimensions={info.width,info.height};}
            for(const auto& map:graph.at("maps"))if(imageMap(map)&&map.at("file")==file.at("id"))require(map.at("size")[0]==dimensions[0]&&map.at("size")[1]==dimensions[1],"Model bitmap dimensions differ.");}
    }
    return {{"manifest",manifest},{"graph",graph},{"model",definition}};
}

namespace {
PreparedPackage prepareVerified(const std::filesystem::path& directory,PreparedPackage result,const Checkpoint& point,const std::filesystem::path& bitmapDirectory){
    const auto& graph=result.metadata.at("graph");const auto budget=packageBudget(graph);
    auto notify=[&](const char* stage){if(point)point(stage,result.payloadBytes);};
    notify("preparing-paint");
    // Count expanded Paint before hydrating. Native payload admission includes
    // these hex strings plus decoded mesh vector capacity, not a claim about
    // total process memory or the later MAXScript/Undo working set.
    if(result.metadata.contains("recipe")){
        paints(result.metadata.at("recipe"),[&](const Json& row){result.payloadBytes+=row.at("bytes").get<std::uint64_t>()*2;});
        require(result.payloadBytes<=budget,"Prepared payload exceeds its resource-profile byte budget.");
        std::string recipeHash;result.document=recipes::read(directory/"entry.csrecipe.json",true,&recipeHash);
        require(recipeHash==result.metadata.at("manifest").at("recipe").at("sha256").get<std::string>(),"Recipe changed while preparing import.");
    }else result.document=result.metadata.at("model");
    std::map<std::string,std::shared_ptr<const Mesh>> shared;
    for(const auto& file:result.metadata.at("graph").at("files"))if(file.at("kind")=="mesh"){
        notify("preparing-mesh");const auto sha=file.at("sha256").get<std::string>();auto found=shared.find(sha);
        if(found==shared.end()){
            const auto bytes=load(contained(directory,relative(file)),static_cast<std::size_t>(fileBudget(graph,file)));
            require(digest(bytes)==sha,"Mesh changed while preparing import.");
            // Encoded storage is a lower bound. Check it before allocation,
            // then account for the actual decoded vector capacities.
            require(result.payloadBytes+bytes.size()<=budget,"Prepared payload exceeds its resource-profile byte budget.");
            auto mesh=std::make_shared<Mesh>(decodeMesh(meshBytes(bytes),meshProfile(graph)));
            const auto size=meshStorageBytes(*mesh);
            require(result.payloadBytes+size<=budget,"Prepared payload exceeds its resource-profile byte budget.");result.payloadBytes+=size;
            found=shared.emplace(sha,std::move(mesh)).first;
        }
        result.meshes.emplace(file.at("id").get<std::string>(),found->second);
    }else{
        const auto store=shared::root(directory);
        const auto bitmapRoot=store.empty()?bitmapDirectory:store/"resolved";
        notify("preparing-bitmap");require(bitmapRoot.is_absolute(),"Portable bitmaps require the owned imported-asset directory.");
        std::filesystem::create_directories(bitmapRoot);require(!std::filesystem::is_symlink(bitmapRoot),"Imported bitmap directory cannot be a link.");const auto root=std::filesystem::canonical(bitmapRoot);filesystem(root);
        const auto extension=result.metadata.at("graph").at("version").get<int>()>=3?suffix(file):"png";
        const auto sha=file.at("sha256").get<std::string>(),name=sha+"."+extension;const auto target=contained(root,name),source=contained(directory,relative(file));const auto bytes=file.at("bytes").get<std::uint64_t>();
        if(std::filesystem::exists(target))require(stream(target,{},bytes,point)==sha,"Owned bitmap content differs; it was preserved. Repair or select another library location.");
        else{
            const auto stage=root/recipes::pathFromUTF8(".cyrus-bitmap-stage-"+nonce()+"."+extension);bool owned=false;
            try{
                owned=true;
                if(!store.empty())require(CreateHardLinkW(recipes::nativePath(stage).c_str(),recipes::nativePath(source).c_str(),nullptr)!=FALSE,"Cannot recreate the shared bitmap view.");
                else require(stream(source,stage,bytes,point)==sha,"Bitmap changed while preparing import.");
                require(stream(stage,{},bytes,point)==sha,"Bitmap changed while preparing import.");notify("bitmap-staged");
                std::error_code error;std::filesystem::rename(stage,target,error);
                if(error){require(std::filesystem::exists(target)&&stream(target,{},bytes,point)==sha,"Cannot publish imported bitmap.");std::filesystem::remove(stage);}
                owned=false;
            }catch(...){if(owned){std::error_code error;std::filesystem::remove(stage,error);}throw;}
        }
        result.bitmapPaths.emplace(file.at("id").get<std::string>(),target);
    }
    // Max can reuse a filename's retained gamma annotation in OCIO mode. Each
    // interpretation gets a stable name; aliases share the same byte allocation.
    const auto store=shared::root(directory);struct ContentLock{HANDLE value=INVALID_HANDLE_VALUE;~ContentLock(){if(value!=INVALID_HANDLE_VALUE)CloseHandle(value);}} contentLock;
    if(!store.empty()&&!result.bitmapPaths.empty()){
        const auto deadline=std::chrono::steady_clock::now()+std::chrono::seconds(120);
        while(true){contentLock.value=CreateFileW(recipes::nativePath(store/"content.lock").c_str(),GENERIC_READ|GENERIC_WRITE,0,nullptr,OPEN_ALWAYS,FILE_ATTRIBUTE_NORMAL,nullptr);if(contentLock.value!=INVALID_HANDLE_VALUE)break;
            const auto error=GetLastError();require(error==ERROR_SHARING_VIOLATION||error==ERROR_LOCK_VIOLATION,"Cannot acquire shared bitmap-view publication lock.");require(std::chrono::steady_clock::now()<deadline,"Shared library is busy; retry preparation.");notify("waiting-for-library");Sleep(50);}
    }
    std::set<std::filesystem::path> checkedViews;
    for(const auto& map:graph.at("maps"))if(map.at("kind")=="bitmap"&&graph.at("version").get<int>()>=3){
        const auto id=map.at("file").get<std::string>();const auto raw=result.bitmapPaths.at(id);const auto colour=digest(map.at("color").dump());
        const Json* descriptor=nullptr;for(const auto& file:graph.at("files"))if(file.at("id")==id){descriptor=&file;break;}require(descriptor!=nullptr,"Prepared bitmap descriptor is missing.");
        const auto sha=descriptor->at("sha256").get<std::string>();const auto bytes=descriptor->at("bytes").get<std::uint64_t>();
        const auto alias=raw.parent_path()/recipes::pathFromUTF8(sha+"-"+colour+"."+suffix(*descriptor));
        if(checkedViews.insert(alias).second){
            if(!std::filesystem::exists(alias))require(CreateHardLinkW(recipes::nativePath(alias).c_str(),recipes::nativePath(raw).c_str(),nullptr)!=FALSE,"Cannot create the image interpretation view.");
            require(stream(alias,{},bytes,point)==sha,"An image interpretation view differs; repair from a verified backup.");notify("bitmap-interpretation");
        }
        result.bitmapMapPaths.emplace(map.at("id").get<std::string>(),alias);
    }
    notify("prepared");return result;
}
}
PreparedPackage preparePackage(const std::filesystem::path& rawDirectory,const Checkpoint& point,const std::filesystem::path& bitmapDirectory){
    require(rawDirectory.is_absolute(),"Package requires an absolute folder.");const auto directory=shared::resolve(rawDirectory);PreparedPackage result;result.metadata=readPackage(directory,point);return prepareVerified(directory,std::move(result),point,bitmapDirectory);
}
PreparedPackage prepareModelPackage(const std::filesystem::path& rawDirectory,const Checkpoint& point,const std::filesystem::path& bitmapDirectory){
    require(rawDirectory.is_absolute(),"Model package requires an absolute folder.");const auto directory=recipes::nativePath(rawDirectory);PreparedPackage result;result.metadata=readModelPackage(directory,point);return prepareVerified(directory,std::move(result),point,bitmapDirectory);
}
Json fileInfo(const std::filesystem::path& path,bool png){
    require(path.is_absolute()&&std::filesystem::is_regular_file(path)&&!std::filesystem::is_symlink(path),"Asset input requires an absolute regular file.");const auto bytes=load(path,static_cast<std::size_t>(maxFileBytes));
    if(png){const auto info=inspectPNG({bytes.begin(),bytes.end()});return Json::array({digest(bytes),bytes.size(),info.width,info.height});}
    return Json::array({digest(bytes),bytes.size()});
}
Json imageFileInfo(const std::filesystem::path& path){
    require(path.is_absolute()&&std::filesystem::is_regular_file(path)&&!std::filesystem::is_symlink(path),"Asset input requires an absolute regular file.");
    auto extension=path.extension().u8string();require(extension.size()>1,"Portable image needs an explicit supported suffix.");extension.erase(extension.begin());
    std::string imageSuffix(extension.begin(),extension.end());std::transform(imageSuffix.begin(),imageSuffix.end(),imageSuffix.begin(),[](unsigned char c){return c>='A'&&c<='Z'?static_cast<char>(c-'A'+'a'):static_cast<char>(c);});
    const auto bytes=load(path,static_cast<std::size_t>(maxFileBytes));const auto info=inspectPortableImage({bytes.begin(),bytes.end()},imageSuffix);
    return Json::array({digest(bytes),bytes.size(),info.width,info.height});
}
}
