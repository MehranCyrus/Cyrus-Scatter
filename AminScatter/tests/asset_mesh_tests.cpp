#include "asset_mesh.h"
#include <iostream>
#include <limits>
#include <stdexcept>
#include <string>
#include <cstring>
#include <cmath>
using namespace cyrus::assets;
namespace { unsigned count=0;void check(bool ok){++count;if(!ok)throw std::runtime_error("Mesh assertion "+std::to_string(count));}template<class F>void rejects(F f){bool bad=false;try{f();}catch(const std::exception&){bad=true;}check(bad);} }
int main(){try{
    Mesh mesh;mesh.vertices={{0,0,0},{2.5,0,0},{0,1.5,0}};mesh.faces.push_back({{0,1,2},0xffffffffu,65535,5});
    for(int channel:{-2,0,1,42})mesh.maps.push_back({channel,{{0,0,0},{1,0,0},{0,1,0}},{{0,1,2}}});
    auto bytes=encodeMesh(mesh);check(encodeMesh(decodeMesh(bytes))==bytes);
    auto bad=mesh;bad.faces[0].vertices[2]=3;rejects([&]{encodeMesh(bad);});bad=mesh;bad.maps.push_back(bad.maps[0]);rejects([&]{encodeMesh(bad);});bad=mesh;bad.vertices[0][0]=std::numeric_limits<double>::quiet_NaN();rejects([&]{encodeMesh(bad);});
    for(std::size_t size=0;size<bytes.size();++size){auto cut=bytes;cut.resize(size);rejects([&]{decodeMesh(cut);});}
    auto corrupt=bytes;corrupt.push_back(0);rejects([&]{decodeMesh(corrupt);});corrupt=bytes;corrupt[8]=255;corrupt[9]=255;corrupt[10]=255;corrupt[11]=127;rejects([&]{decodeMesh(corrupt);});
    Mesh large;large.vertices.resize(maxMeshVertices,{1,2,3});large.faces.resize(maxMeshFaces,{{0,1,2},1,0,7});check(decodeMesh(encodeMesh(large)).faces.size()==maxMeshFaces);large.faces.push_back(large.faces[0]);rejects([&]{encodeMesh(large);});
    // M02 selection is explicit. A Plant package may retain bounded legacy M01.
    check(decodeMesh(bytes,MeshProfile::Plant).profile==MeshProfile::Legacy);
    auto plant=mesh;plant.profile=MeshProfile::Plant;plant.normals.emplace();
    plant.normals->flags=43;plant.normals->vectors={{0,0,1},{0,1,0}};plant.normals->explicitFlags={1,0};
    plant.normals->faces.push_back({{0,1,-1},{1,0,0}});
    auto modern=encodeMesh(plant,MeshProfile::Plant);check(std::memcmp(modern.data(),"CYRUSM02",8)==0);
    check(modern.size()==bytes.size()+12+28*2+16);check(meshEncodedBytes(plant,MeshProfile::Plant)==modern.size());
    check(encodeMesh(decodeMesh(modern,MeshProfile::Plant),MeshProfile::Plant)==modern);
    // Host SDK float canonicalization must not weaken the codec's binary64 data.
    auto exactDouble=plant;exactDouble.normals->vectors[0][0]=std::nextafter(.5,1.);
    const auto exactPayload=encodeMesh(exactDouble,MeshProfile::Plant);const auto exactDecoded=decodeMesh(exactPayload,MeshProfile::Plant);
    check(std::memcmp(exactDouble.normals->vectors[0].data(),exactDecoded.normals->vectors[0].data(),sizeof(Vertex))==0);
    check(decodeMesh(std::span<const unsigned char>(modern),MeshProfile::Plant).normals->faces[0].ids[2]==-1);
    rejects([&]{encodeMesh(plant);});rejects([&]{decodeMesh(modern);});
    rejects([&]{encodeMesh(mesh,static_cast<MeshProfile>(99));});rejects([&]{decodeMesh(bytes,static_cast<MeshProfile>(99));});
    for(std::size_t size=0;size<modern.size();++size)rejects([&]{decodeMesh(std::span<const unsigned char>(modern.data(),size),MeshProfile::Plant);});
    auto modernBad=modern;modernBad.push_back(0);rejects([&]{decodeMesh(modernBad,MeshProfile::Plant);});
    auto put32=[](std::vector<unsigned char>& b,std::size_t at,std::uint32_t x){for(int i=0;i<4;++i)b[at+static_cast<std::size_t>(i)]=static_cast<unsigned char>((x>>(i*8))&255);};
    for(auto at:{20u,24u,28u}){modernBad=modern;put32(modernBad,at,0xffffffffu);rejects([&]{decodeMesh(modernBad,MeshProfile::Plant);});}
    modernBad=modern;put32(modernBad,24,4);rejects([&]{decodeMesh(modernBad,MeshProfile::Plant);});
    const auto normalAt=modern.size()-72;
    modernBad=modern;put32(modernBad,normalAt+24,2);rejects([&]{decodeMesh(modernBad,MeshProfile::Plant);});
    modernBad=modern;put32(modernBad,modern.size()-4,8);rejects([&]{decodeMesh(modernBad,MeshProfile::Plant);});
    modernBad=modern;put32(modernBad,modern.size()-16,2);rejects([&]{decodeMesh(modernBad,MeshProfile::Plant);});
    modernBad=modern;put32(modernBad,modern.size()-8,0xfffffffeu);rejects([&]{decodeMesh(modernBad,MeshProfile::Plant);});
    modernBad=modern;put32(modernBad,modern.size()-4,7);rejects([&]{decodeMesh(modernBad,MeshProfile::Plant);});
    modernBad=modern;const double nan=std::numeric_limits<double>::quiet_NaN();std::memcpy(modernBad.data()+normalAt,&nan,sizeof(nan));rejects([&]{decodeMesh(modernBad,MeshProfile::Plant);});
    auto failNormal=[&](auto mutate){auto invalid=plant;mutate(*invalid.normals);rejects([&]{encodeMesh(invalid,MeshProfile::Plant);});};
    failNormal([](auto& ns){ns.vectors[0]={0,0,0};});failNormal([](auto& ns){ns.vectors[0][0]=std::numeric_limits<double>::infinity();});
    failNormal([](auto& ns){ns.vectors[0][0]=1000001;});failNormal([](auto& ns){ns.flags=4;});failNormal([](auto& ns){ns.explicitFlags[0]=2;});
    failNormal([](auto& ns){ns.explicitFlags.pop_back();});failNormal([](auto& ns){ns.faces.clear();});failNormal([](auto& ns){ns.faces[0].specified[0]=2;});
    failNormal([](auto& ns){ns.faces[0].ids[0]=-1;});failNormal([](auto& ns){ns.faces[0].ids[1]=-2;});failNormal([](auto& ns){ns.vectors.clear();ns.explicitFlags.clear();});
    for(std::uint32_t flags:{3u,11u,35u,43u}){auto x=plant;x.normals->flags=flags;check(decodeMesh(encodeMesh(x,MeshProfile::Plant),MeshProfile::Plant).normals->flags==flags);}
    for(std::uint32_t flags:{0u,1u,2u,8u,32u,4u,47u}){auto x=plant;x.normals->flags=flags;rejects([&]{encodeMesh(x,MeshProfile::Plant);});modernBad=modern;put32(modernBad,24,flags);rejects([&]{decodeMesh(modernBad,MeshProfile::Plant);});}
    auto plain=mesh;check(!decodeMesh(encodeMesh(plain,MeshProfile::Plant),MeshProfile::Plant).normals);
    // Actual reserve capacity, not logical sizes, is charged for immutable caches.
    auto storage=meshStorageBytes(plant);plant.normals->vectors.reserve(100);check(meshStorageBytes(plant)==storage+(plant.normals->vectors.capacity()-2)*sizeof(Vertex));
    storage=meshStorageBytes(plant);plant.maps[0].vertices.reserve(80);check(meshStorageBytes(plant)==storage+(plant.maps[0].vertices.capacity()-3)*sizeof(Vertex));
    Mesh plantLarge;plantLarge.vertices.resize(maxPlantMeshVertices,{1,2,3});plantLarge.faces.resize(maxPlantMeshFaces,{{0,1,2},1,0,7});
    auto plantLargeBytes=encodeMesh(plantLarge,MeshProfile::Plant);check(plantLargeBytes.size()==48000032);check(decodeMesh(plantLargeBytes,MeshProfile::Plant).faces.size()==maxPlantMeshFaces);rejects([&]{decodeMesh(plantLargeBytes);});
    plantLarge.vertices.push_back({1,2,3});rejects([&]{encodeMesh(plantLarge,MeshProfile::Plant);});plantLarge.vertices.pop_back();plantLarge.faces.push_back(plantLarge.faces[0]);rejects([&]{encodeMesh(plantLarge,MeshProfile::Plant);});
    auto mapBoundary=mesh;mapBoundary.maps[0].vertices.resize(maxPlantMapVertices,{0,0,0});validateMesh(mapBoundary,MeshProfile::Plant);check(true);rejects([&]{validateMesh(mapBoundary);});mapBoundary.maps[0].vertices.push_back({0,0,0});rejects([&]{validateMesh(mapBoundary,MeshProfile::Plant);});
    auto normalBoundary=plant;normalBoundary.normals->vectors.resize(maxPlantNormals,{0,0,1});normalBoundary.normals->explicitFlags.resize(maxPlantNormals,0);validateMesh(normalBoundary,MeshProfile::Plant);check(true);normalBoundary.normals->vectors.push_back({0,0,1});normalBoundary.normals->explicitFlags.push_back(0);rejects([&]{validateMesh(normalBoundary,MeshProfile::Plant);});
    // Eight individually permitted map channels can still exceed aggregate bytes.
    Mesh byteBoundary;byteBoundary.vertices=mesh.vertices;byteBoundary.faces=mesh.faces;
    for(int ch=0;ch<8;++ch){Mapping m;m.channel=ch;m.vertices.resize(maxPlantMapVertices,{0,0,0});m.faces={{0,1,2}};byteBoundary.maps.push_back(std::move(m));}
    rejects([&]{validateMesh(byteBoundary,MeshProfile::Plant);});
    const std::array<Vertex,3> identity{{{1,0,0},{0,1,0},{0,0,1}}};check(transformStoredNormal({0,.9999999,0},identity)==Vertex({0,.9999999,0}));
    const std::array<Vertex,3> nonuniform{{{2,0,0},{0,1,0},{0,0,3}}};auto nt=transformStoredNormal({1,1,0},nonuniform);check(std::abs(nt[0]/nt[1]-.5)<1e-12);check(std::abs(nt[0]*nt[0]+nt[1]*nt[1]-2)<1e-12);
    const std::array<Vertex,3> rotation{{{0,1,0},{-1,0,0},{0,0,1}}};nt=transformStoredNormal({1,0,0},rotation);check(std::abs(nt[0])<1e-12&&std::abs(nt[1]-1)<1e-12);
    const std::array<Vertex,3> shear{{{1,2,0},{0,1,0},{0,0,1}}};nt=transformStoredNormal({0,1,0},shear);check(std::abs(nt[0]+2*nt[1])<1e-12);
    const std::array<Vertex,3> reflection{{{-1,0,0},{0,1,0},{0,0,1}}};check(transformStoredNormal({1,0,0},reflection)==Vertex({-1,0,0}));
    auto singular=identity;singular[1]=singular[0];rejects([&]{transformStoredNormal({0,1,0},singular);});auto nonfinite=identity;nonfinite[0][0]=std::numeric_limits<double>::infinity();rejects([&]{transformStoredNormal({0,1,0},nonfinite);});
    std::cout<<"ABI Mesh="<<sizeof(Mesh)<<" MeshNormals="<<sizeof(MeshNormals)<<" NormalFace="<<sizeof(NormalFace)<<" bytes\n";
    std::cout<<count<<" typed mesh assertions passed\n";return 0;
}catch(const std::exception& e){std::cerr<<e.what()<<'\n';return 1;}}
