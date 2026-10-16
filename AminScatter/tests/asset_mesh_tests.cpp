#include "asset_mesh.h"
#include <iostream>
#include <limits>
#include <stdexcept>
#include <string>
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
    std::cout<<count<<" typed mesh assertions passed\n";return 0;
}catch(const std::exception& e){std::cerr<<e.what()<<'\n';return 1;}}
