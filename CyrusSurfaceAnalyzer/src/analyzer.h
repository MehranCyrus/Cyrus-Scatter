#pragma once
#include <array>
#include <vector>
namespace cyrus {
struct V { double x{},y{},z{}; V operator+(V b)const{return{x+b.x,y+b.y,z+b.z};} V operator-(V b)const{return{x-b.x,y-b.y,z-b.z};} V operator*(double s)const{return{x*s,y*s,z*s};} };
double dot(V a,V b); double len(V a);
struct Mesh {std::vector<V> vertices;std::vector<std::array<int,3>> faces;};
struct Settings {int mode=0,resolution=256,count=5,minimumPoints=0,relaxIterations=0;double minWidth=0,minLength=0,ringFraction=0.65,pointRadius=0,fitRadius=0;};
struct Result {std::vector<std::vector<V>> boundaries,paths;std::vector<V> points;std::vector<int> elementModes,elementPointCounts,elementRelaxed;double area=0,regionArea=0,pathLength=0;int mode=0;};
Result analyze(const Mesh&,const Settings&);
}



