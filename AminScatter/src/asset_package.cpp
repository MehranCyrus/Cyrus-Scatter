#include "asset_package.h"
#include "asset_mesh.h"
#include "asset_bitmap.h"
#include "recipe_store.h"
#include "recipe_library.h"
#include <algorithm>
#include <array>
#include <cmath>
#include <fstream>
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
void keys(const Json& value,std::initializer_list<const char*> names){require(value.is_object()&&value.size()==names.size(),"Unexpected asset fields.");for(auto name:names)require(value.contains(name),"Incomplete asset record.");}
std::string text(const Json& value,std::size_t cap=160){require(value.is_string(),"Asset text required.");auto s=value.get<std::string>();require(s.size()<=cap&&s.find('\0')==std::string::npos,"Asset text exceeds bounds or contains NUL.");return s;}
std::string identity(const Json& value){const auto s=text(value,80);require(!s.empty()&&std::all_of(s.begin(),s.end(),[](unsigned char c){return(c>='a'&&c<='z')||(c>='A'&&c<='Z')||(c>='0'&&c<='9')||c=='-'||c=='_';}),"Asset IDs require ASCII letters, digits, hyphen or underscore.");return s;}
std::string hash(const Json& value){const auto s=text(value,64);require(s.size()==64&&std::all_of(s.begin(),s.end(),[](char c){return(c>='0'&&c<='9')||(c>='a'&&c<='f');}),"Invalid asset SHA-256.");return s;}
double number(const Json& value,double lo,double hi){require(value.is_number(),"Asset number required.");const auto v=value.get<double>();require(std::isfinite(v)&&v>=lo&&v<=hi,"Asset number outside bounds.");return v;}
void vector(const Json& value,std::size_t size,double lo,double hi){require(value.is_array()&&value.size()==size,"Invalid asset vector.");for(const auto& v:value)number(v,lo,hi);}
std::string suffix(const Json& file){const auto s=text(file.at("suffix"),8);const std::set<std::string> supported={"cmesh","png","jpg","jpeg","tga","bmp","tif","tiff"};require(supported.count(s)!=0,"Unsupported package file suffix.");require((file.at("kind")=="mesh")== (s=="cmesh"),"Asset file type and suffix differ.");return s;}
std::string relative(const Json& file){return "assets/"+hash(file.at("sha256"))+"."+suffix(file);}
std::string load(const std::filesystem::path& path,std::size_t cap){std::ifstream in(recipes::nativePath(path),std::ios::binary|std::ios::ate);require(bool(in),"Cannot read package document.");const auto n=in.tellg();require(n>=0&&static_cast<std::uint64_t>(n)<=cap,"Package document exceeds its limit.");std::string data(static_cast<std::size_t>(n),'\0');in.seekg(0);if(n>0)in.read(data.data(),n);require(bool(in),"Incomplete package document.");return data;}
std::string digest(const std::string& data){return recipes::digest({data.begin(),data.end()});}
void put(const std::filesystem::path& rawPath,const std::string& data){const auto path=recipes::nativePath(rawPath);require(!std::filesystem::exists(path),"Package staging collision.");std::filesystem::create_directories(path.parent_path());std::ofstream out(path,std::ios::binary);require(bool(out),"Cannot write package staging file.");out.write(data.data(),static_cast<std::streamsize>(data.size()));out.flush();require(bool(out),"Package staging write failed.");out.close();require(load(path,data.size())==data,"Package staging readback failed.");}
struct Hash {
    BCRYPT_ALG_HANDLE algorithm=nullptr;BCRYPT_HASH_HANDLE value=nullptr;
    Hash(){require(BCryptOpenAlgorithmProvider(&algorithm,BCRYPT_SHA256_ALGORITHM,nullptr,0)>=0,"Package hash provider unavailable.");if(BCryptCreateHash(algorithm,&value,nullptr,0,nullptr,0,0)<0){BCryptCloseAlgorithmProvider(algorithm,0);algorithm=nullptr;throw std::runtime_error("Package hash unavailable.");}}
    ~Hash(){if(value)BCryptDestroyHash(value);if(algorithm)BCryptCloseAlgorithmProvider(algorithm,0);}
    void add(unsigned char* data,ULONG size){require(BCryptHashData(value,data,size,0)>=0,"Package hashing failed.");}
    std::string finish(){std::vector<unsigned char> bytes(32);require(BCryptFinishHash(value,bytes.data(),32,0)>=0,"Package hashing failed.");return recipes::hex(bytes);}
};
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
void verifyDescriptor(const std::filesystem::path& root,const Json& row,std::size_t cap,const Checkpoint& point){keys(row,{"file","sha256","bytes"});const auto bytes=number(row.at("bytes"),1,static_cast<double>(cap));require(row.at("bytes").is_number_integer(),"Package byte size must be an integer.");require(stream(contained(root,text(row.at("file"),240)),{},static_cast<std::uint64_t>(bytes),point)==hash(row.at("sha256")),"Package payload hash mismatch.");}
Json readDescriptor(const std::filesystem::path& root,const Json& row,std::size_t cap){
    keys(row,{"file","sha256","bytes"});require(row.at("bytes").is_number_integer(),"Package byte size must be an integer.");const auto expected=static_cast<std::size_t>(number(row.at("bytes"),1,static_cast<double>(cap)));
    const auto bytes=load(contained(root,text(row.at("file"),240)),cap);require(bytes.size()==expected&&digest(bytes)==hash(row.at("sha256")),"Package document changed or has a wrong hash.");return recipes::parse(bytes);
}
}

void validateGraph(const Json& graph,const Json& recipe){
    const bool context=graph.value("version",0)==2;
    if(context)keys(graph,{"format","version","nodes","meshes","materials","maps","files","externalRoles","splines"});
    else keys(graph,{"format","version","nodes","meshes","materials","maps","files","externalRoles"});
    require(graph.at("format")=="cyrus.library-assets"&&(graph.at("version")==1||context),"Unsupported asset graph.");
    std::map<std::string,std::string> roleKinds,fileKinds;std::set<std::string> assigned,ids,meshes,materials,maps;
    for(const auto& role:recipe.at("roles"))roleKinds.emplace(role.at("id").get<std::string>(),role.at("kind").get<std::string>());
    for(const auto* name:{"nodes","meshes","materials","maps","files","externalRoles"})require(graph.at(name).is_array()&&graph.at(name).size()<=(std::string(name)=="files"?maxFiles:maxObjects),"Asset graph count exceeds bounds.");
    std::uint64_t total=0;
    for(const auto& file:graph.at("files")){keys(file,{"id","kind","sha256","bytes","suffix"});const auto id=identity(file.at("id"));require(ids.insert(id).second,"Duplicate asset ID.");require(file.at("kind")=="mesh"||file.at("kind")=="bitmap","Unsupported asset file kind.");fileKinds.emplace(id,file.at("kind").get<std::string>());hash(file.at("sha256"));suffix(file);require(file.at("bytes").is_number_integer(),"Asset byte size must be an integer.");total+=static_cast<std::uint64_t>(number(file.at("bytes"),1,static_cast<double>(maxFileBytes)));require(total<=maxPackageBytes,"Asset payloads exceed the package byte budget.");}
    auto reference=[&](const Json& value,const std::set<std::string>& allowed){if(!value.is_null())require(allowed.count(identity(value))!=0,"Missing or incompatible asset reference.");};
    auto roles=[&](const Json& values,const std::string& kind){require(values.is_array()&&values.size()<=maxObjects,"Asset role count exceeds bounds.");for(const auto& value:values){const auto id=text(value);require(roleKinds.count(id)!=0&&roleKinds.at(id)==kind&&assigned.insert(id).second,"Unknown, duplicate or incompatible asset role.");}};
    for(const auto& mesh:graph.at("meshes")){keys(mesh,{"id","file"});const auto id=identity(mesh.at("id"));require(ids.insert(id).second,"Duplicate asset ID.");meshes.insert(id);const auto file=identity(mesh.at("file"));require(fileKinds.count(file)!=0&&fileKinds.at(file)=="mesh","Mesh requires a declared mesh file.");}
    std::uint64_t bitmapPixels=0;
    for(const auto& map:graph.at("maps")){
        keys(map,{"id","kind","name","file","channel","uv","size","color","sampler","output","roles"});const auto id=identity(map.at("id"));require(ids.insert(id).second,"Duplicate asset ID.");maps.insert(id);require(map.at("kind")=="bitmap","Unsupported map adapter.");text(map.at("name"));const auto file=identity(map.at("file"));require(fileKinds.count(file)!=0&&fileKinds.at(file)=="bitmap","Bitmap requires a declared image file.");require(map.at("channel").is_number_integer(),"Map channel must be an integer.");number(map.at("channel"),1,99);vector(map.at("uv"),5,-1e6,1e6);roles(map.at("roles"),"texture");
        vector(map.at("size"),2,1,4096);for(const auto& v:map.at("size"))require(v.is_number_integer(),"Bitmap dimensions must be integers.");
        bitmapPixels+=map.at("size")[0].get<std::uint64_t>()*map.at("size")[1].get<std::uint64_t>();require(bitmapPixels<=maxPackageBitmapPixels,"Package bitmap map instances exceed 16 Mpixels.");
        const auto& color=map.at("color");keys(color,{"mode","configSHA256","renderingSpace","dataSpace","inputSpace"});require(color.at("mode")=="OCIO_Default","Unsupported bitmap colour pipeline.");hash(color.at("configSHA256"));for(const auto* name:{"renderingSpace","dataSpace","inputSpace"})require(!text(color.at(name)).empty(),"Bitmap colour space is missing.");
        const auto& sampler=map.at("sampler");keys(sampler,{"filtering","monoOutput","rgbOutput","alphaSource","preMultAlpha","uMirror","vMirror","uTile","vTile","blur","blurOffset"});
        for(const auto* name:{"filtering","monoOutput","rgbOutput","alphaSource"}){require(sampler.at(name).is_number_integer(),"Bitmap sampler enum must be an integer.");number(sampler.at(name),0,std::string(name)=="filtering"||std::string(name)=="alphaSource"?2:1);}
        for(const auto* name:{"preMultAlpha","uMirror","vMirror","uTile","vTile"})require(sampler.at(name).is_boolean(),"Bitmap sampler Boolean required.");number(sampler.at("blur"),0,1000);number(sampler.at("blurOffset"),-1000,1000);
        const auto& output=map.at("output");keys(output,{"invert","clamp","alphaFromRGB","rgbLevel","rgbOffset","outputAmount"});for(const auto* name:{"invert","clamp","alphaFromRGB"})require(output.at(name).is_boolean(),"Bitmap output Boolean required.");for(const auto* name:{"rgbLevel","rgbOffset","outputAmount"})number(output.at(name),-1e6,1e6);
    }
    for(const auto& material:graph.at("materials")){
        keys(material,{"id","kind","name","diffuse","ambient","specular","specularLevel","glossiness","soften","selfIllumAmount","selfIllumColor","useSelfIllumColor","ambientDiffuseLock","diffuseSpecularLock","textureLock","opacity","twoSided","maps"});const auto id=identity(material.at("id"));require(ids.insert(id).second,"Duplicate asset ID.");materials.insert(id);require(material.at("kind")=="standard-blinn","Unsupported material adapter.");text(material.at("name"));
        for(const auto* name:{"diffuse","ambient","specular","selfIllumColor"})vector(material.at(name),3,0,255);
        for(const auto* name:{"opacity","glossiness","selfIllumAmount"})number(material.at(name),0,100);
        number(material.at("specularLevel"),0,999);number(material.at("soften"),0,1);
        for(const auto* name:{"twoSided","useSelfIllumColor","ambientDiffuseLock","diffuseSpecularLock","textureLock"})require(material.at(name).is_boolean(),"Material Boolean flag required.");
        const auto& slots=material.at("maps");require(slots.is_array()&&slots.size()==3,"Material requires three explicit map slots.");std::set<std::string> seen;
        for(const auto& slot:slots){keys(slot,{"slot","map","amount","enabled"});const auto name=text(slot.at("slot"));require((name=="ambient"||name=="diffuse"||name=="opacity")&&seen.insert(name).second,"Unsupported or duplicate material map slot.");reference(slot.at("map"),maps);number(slot.at("amount"),-1000,1000);require(slot.at("enabled").is_boolean(),"Material map enable flag required.");}
    }
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
    const auto recipeBytes=load(source,recipes::maxManifestBytes);require(digest(recipeBytes)==expected,"Recipe changed since export review.");const auto recipe=recipes::parse(recipeBytes);require(recipe.at("formatVersion")==5||recipe.at("formatVersion")==6,"Resave this recipe before portable export.");recipes::validate(recipe,false);validateGraph(graph,recipe);require(inputs.size()==graph.at("files").size(),"Resolve every package file exactly once.");
    const auto graphBytes=graph.dump();require(graphBytes.size()<=maxGraphBytes,"Asset graph metadata exceeds its budget.");
    const auto stage=parent/recipes::pathFromUTF8(".cyrus-package-stage-"+nonce());bool owned=false,published=false;std::uint64_t copied=recipeBytes.size()+graphBytes.size();std::set<std::string> stored;
    auto notify=[&](const char* name){if(point)point(name,copied);};
    try{
        require(std::filesystem::create_directory(stage),"Cannot create package staging folder.");owned=true;notify("started");
        auto copy=[&](const std::filesystem::path& from,const Json& row,std::uint64_t cap){const auto relativePath=text(row.at("file"),240);const auto to=contained(stage,relativePath);const auto bytes=static_cast<std::uint64_t>(number(row.at("bytes"),1,static_cast<double>(cap)));require(row.at("bytes").is_number_integer(),"Payload byte size must be an integer.");const auto sha=hash(row.at("sha256"));
            if(stored.insert(relativePath).second){copied+=bytes;require(copied<=maxPackageBytes,"Complete package exceeds 256 MiB.");require(stream(from,to,bytes,point)==sha,"Source dependency changed or has a wrong hash.");require(stream(to,{},bytes,point)==sha,"Staged payload readback failed.");}else require(stream(to,{},bytes,point)==sha,"Package payload identity collision.");};
        paints(recipe,[&](const Json& row){copy(recipes::attachmentPath(source,text(row.at("file"),240)),row,recipes::maxPaintBytes);});notify("paint-staged");
        if(!recipe.at("presentation").is_null()&&!recipe.at("presentation").at("thumbnail").is_null()){const auto& row=recipe.at("presentation").at("thumbnail");copy(recipes::attachmentPath(source,text(row.at("file"),240)),row,recipes::maxThumbnailBytes);}
        for(const auto& file:graph.at("files")){const auto id=identity(file.at("id"));require(inputs.count(id)!=0&&inputs.at(id).is_absolute(),"Package file binding needs an absolute input path.");copy(inputs.at(id),{{"file",relative(file)},{"bytes",file.at("bytes")},{"sha256",file.at("sha256")}},maxFileBytes);notify("asset-staged");}
        put(stage/"entry.csrecipe.json",recipeBytes);put(stage/"assets.json",graphBytes);
        Json manifest={{"format","cyrus.library-package"},{"version",1},{"hostYear",recipe.at("hostYear")},{"recipe",descriptor("entry.csrecipe.json",recipeBytes)},{"graph",descriptor("assets.json",graphBytes)},{"redistribution",redistribution}};
        put(stage/"cyrus.package.json",manifest.dump(2));readPackage(stage,point);notify("verified");require(digest(load(source,recipes::maxManifestBytes))==expected,"Recipe changed while exporting.");notify("before-commit");require(!std::filesystem::exists(output),"Package destination appeared while exporting.");std::filesystem::rename(stage,output);published=true;owned=false;
        try{notify("complete");}catch(...){}return output/"cyrus.package.json";
    }catch(...){if(owned&&!published){std::error_code error;std::filesystem::remove_all(stage,error);}throw;}
}

Json readPackage(const std::filesystem::path& rawDirectory,const Checkpoint& point){
    require(rawDirectory.is_absolute(),"Package requires an absolute folder.");
    const auto directory=recipes::nativePath(rawDirectory);
    require(directory.is_absolute()&&std::filesystem::is_directory(directory)&&!std::filesystem::is_symlink(directory),"Package requires an unlinked absolute folder.");
    const auto manifest=recipes::parse(load(directory/"cyrus.package.json",8192));keys(manifest,{"format","version","hostYear","recipe","graph","redistribution"});require(manifest.at("format")=="cyrus.library-package"&&manifest.at("version")==1&&(manifest.at("hostYear")==2024||manifest.at("hostYear")==2026||manifest.at("hostYear")==2027),"Unsupported library package.");require(!text(manifest.at("redistribution"),1024).empty(),"Package redistribution declaration missing.");require(manifest.at("recipe").at("file")=="entry.csrecipe.json"&&manifest.at("graph").at("file")=="assets.json","Unexpected package document paths.");
    const auto recipe=readDescriptor(directory,manifest.at("recipe"),recipes::maxManifestBytes);require(recipe.at("formatVersion")==5||recipe.at("formatVersion")==6,"Unsupported package recipe version.");recipes::validate(recipe,false);
    const auto graph=readDescriptor(directory,manifest.at("graph"),maxGraphBytes);validateGraph(graph,recipe);
    std::uint64_t total=manifest.at("recipe").at("bytes").get<std::uint64_t>()+manifest.at("graph").at("bytes").get<std::uint64_t>();std::set<std::string> files;
    auto verify=[&](const Json& row,std::size_t cap){const auto file=text(row.at("file"),240);if(files.insert(file).second){total+=row.at("bytes").get<std::uint64_t>();require(total<=maxPackageBytes,"Complete package exceeds 256 MiB.");verifyDescriptor(directory,row,cap,point);}};
    paints(recipe,[&](const Json& row){verify(row,recipes::maxPaintBytes);});if(!recipe.at("presentation").is_null()&&!recipe.at("presentation").at("thumbnail").is_null())verify(recipe.at("presentation").at("thumbnail"),recipes::maxThumbnailBytes);
    for(const auto& file:graph.at("files")){
        verify({{"file",relative(file)},{"bytes",file.at("bytes")},{"sha256",file.at("sha256")}},maxFileBytes);
        if(file.at("kind")=="mesh"){
            const auto bytes=load(contained(directory,relative(file)),static_cast<std::size_t>(maxFileBytes));require(digest(bytes)==file.at("sha256").get<std::string>(),"Mesh changed during verification.");decodeMesh({bytes.begin(),bytes.end()});
        }else{
            require(file.at("suffix")=="png","Initial portable bitmap adapter requires PNG.");
            const auto bytes=load(contained(directory,relative(file)),static_cast<std::size_t>(maxFileBytes));require(digest(bytes)==file.at("sha256").get<std::string>(),"Bitmap changed during verification.");const auto info=inspectPNG({bytes.begin(),bytes.end()});
            for(const auto& map:graph.at("maps"))if(map.at("file")==file.at("id"))require(map.at("size")[0]==info.width&&map.at("size")[1]==info.height,"Bitmap dimensions disagree with the declared graph.");
        }
    }
    return {{"manifest",manifest},{"recipe",recipe},{"graph",graph}};
}

PreparedPackage preparePackage(const std::filesystem::path& rawDirectory,const Checkpoint& point,const std::filesystem::path& bitmapDirectory){
    require(rawDirectory.is_absolute(),"Package requires an absolute folder.");
    const auto directory=recipes::nativePath(rawDirectory);
    PreparedPackage result;result.metadata=readPackage(directory,point);
    auto notify=[&](const char* stage){if(point)point(stage,result.payloadBytes);};
    notify("preparing-paint");
    // Count expanded Paint before hydrating. Native payload admission includes
    // these hex strings plus decoded mesh vector capacity, not a claim about
    // total process memory or the later MAXScript/Undo working set.
    paints(result.metadata.at("recipe"),[&](const Json& row){result.payloadBytes+=row.at("bytes").get<std::uint64_t>()*2;});
    require(result.payloadBytes<=maxPackageBytes,"Prepared payload exceeds 256 MiB.");
    std::string recipeHash;result.document=recipes::read(directory/"entry.csrecipe.json",true,&recipeHash);
    require(recipeHash==result.metadata.at("manifest").at("recipe").at("sha256").get<std::string>(),"Recipe changed while preparing import.");
    std::map<std::string,std::shared_ptr<const Mesh>> shared;
    for(const auto& file:result.metadata.at("graph").at("files"))if(file.at("kind")=="mesh"){
        notify("preparing-mesh");const auto sha=file.at("sha256").get<std::string>();auto found=shared.find(sha);
        if(found==shared.end()){
            const auto bytes=load(contained(directory,relative(file)),static_cast<std::size_t>(maxFileBytes));
            require(digest(bytes)==sha,"Mesh changed while preparing import.");
            // Encoded storage is a lower bound. Check it before allocation,
            // then account for the actual decoded vector capacities.
            require(result.payloadBytes+bytes.size()<=maxPackageBytes,"Prepared payload exceeds 256 MiB.");
            auto mesh=std::make_shared<Mesh>(decodeMesh({bytes.begin(),bytes.end()}));
            std::uint64_t size=sizeof(Mesh)+mesh->vertices.capacity()*sizeof(Vertex)+mesh->faces.capacity()*sizeof(Face)+mesh->maps.capacity()*sizeof(Mapping);
            for(const auto& mapping:mesh->maps)size+=mapping.vertices.capacity()*sizeof(Vertex)+mapping.faces.capacity()*sizeof(Triangle);
            require(result.payloadBytes+size<=maxPackageBytes,"Prepared payload exceeds 256 MiB.");result.payloadBytes+=size;
            found=shared.emplace(sha,std::move(mesh)).first;
        }
        result.meshes.emplace(file.at("id").get<std::string>(),found->second);
    }else{
        notify("preparing-bitmap");require(bitmapDirectory.is_absolute(),"Portable bitmaps require the owned imported-asset directory.");
        std::filesystem::create_directories(bitmapDirectory);require(!std::filesystem::is_symlink(bitmapDirectory),"Imported bitmap directory cannot be a link.");const auto root=std::filesystem::canonical(bitmapDirectory);filesystem(root);
        const auto sha=file.at("sha256").get<std::string>(),name=sha+".png";const auto target=contained(root,name),source=contained(directory,relative(file));const auto bytes=file.at("bytes").get<std::uint64_t>();
        if(std::filesystem::exists(target))require(stream(target,{},bytes,point)==sha,"Owned bitmap content differs; it was preserved. Repair or select another library location.");
        else{
            const auto stage=root/recipes::pathFromUTF8(".cyrus-bitmap-stage-"+nonce()+".png");bool owned=false;
            try{
                owned=true;require(stream(source,stage,bytes,point)==sha&&stream(stage,{},bytes,point)==sha,"Bitmap changed while preparing import.");notify("bitmap-staged");
                std::error_code error;std::filesystem::rename(stage,target,error);
                if(error){require(std::filesystem::exists(target)&&stream(target,{},bytes,point)==sha,"Cannot publish imported bitmap.");std::filesystem::remove(stage);}
                owned=false;
            }catch(...){if(owned){std::error_code error;std::filesystem::remove(stage,error);}throw;}
        }
        result.bitmapPaths.emplace(file.at("id").get<std::string>(),target);
    }
    notify("prepared");return result;
}
Json fileInfo(const std::filesystem::path& path,bool png){
    require(path.is_absolute()&&std::filesystem::is_regular_file(path)&&!std::filesystem::is_symlink(path),"Asset input requires an absolute regular file.");const auto bytes=load(path,static_cast<std::size_t>(maxFileBytes));
    if(png){const auto info=inspectPNG({bytes.begin(),bytes.end()});return Json::array({digest(bytes),bytes.size(),info.width,info.height});}
    return Json::array({digest(bytes),bytes.size()});
}
}
