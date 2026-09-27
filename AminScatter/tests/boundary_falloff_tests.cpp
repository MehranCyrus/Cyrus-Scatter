#include "scatter.h"
#include <stdexcept>
#include <iostream>
#include <chrono>
using namespace amin;
void need(bool v){if(!v)throw std::runtime_error("Falloff assertion failed");}
Instance row(Vec3 p){return {p,{2,0,0},{0,3,0},{0,0,4},1,0,0};}
int main(){try{
 std::vector<std::vector<Vec3>> loops={{{0,0,0},{100,0,0},{100,100,0},{0,100,0}}};
 std::vector<Instance> rows={row({0,50,0}),row({5,50,0}),row({10,50,0}),row({20,50,0}),row({50,50,0})};BoundaryFalloff f;
 auto unchanged=boundaryFalloff(rows,{},f,42);need(unchanged.size()==5);
 f.remove=true;f.removeWidth=10;auto cut=boundaryFalloff(rows,loops,f,42);need(cut.size()==3&&cut[0].position.x==10);
 f.scale=true;f.scaleWidth=20;auto scaled=boundaryFalloff(rows,loops,f,42);need(scaled.size()==3&&length(scaled[0].xAxis)==0&&length(scaled[1].xAxis)==1&&length(scaled[2].xAxis)==2);
 f.scaleCurve={1,.75,.5,.25,0};scaled=boundaryFalloff(rows,loops,f,42);need(length(scaled[0].xAxis)==2&&length(scaled[2].xAxis)==0);
 f.remove=false;f.scale=false;f.density=true;f.densityCurve={0,0,0,0,0};need(boundaryFalloff(rows,loops,f,42).empty());f.densityCurve={1,1,1,1,1};need(boundaryFalloff(rows,loops,f,42).size()==5);
 std::vector<Instance> many;for(int i=0;i<100000;++i)many.push_back(row({.001+(i%1000)*.099, .001+(i/1000)*.99,0}));
 f.densityCurve={.2,.2,.2,.2,.2};auto low=boundaryFalloff(many,loops,f,42);auto repeat=boundaryFalloff(many,loops,f,42);need(low.size()==repeat.size());for(std::size_t i=0;i<low.size();++i)need(length(low[i].position-repeat[i].position)==0);
 f.densityCurve={.6,.6,.6,.6,.6};auto high=boundaryFalloff(many,loops,f,42);need(high.size()>low.size());std::size_t k=0;for(auto r:high)if(k<low.size()&&length(r.position-low[k].position)==0)++k;need(k==low.size());
 loops.push_back({{40,40,0},{60,40,0},{60,60,0},{40,60,0}});f.density=false;f.remove=true;f.removeWidth=3;need(boundaryFalloff({row({39,50,0})},loops,f,42).empty());
 loops.push_back({{200,0,0},{300,0,0},{300,100,0},{200,100,0}});need(boundaryFalloff({row({201,50,0}),row({250,50,0})},loops,f,42).size()==1);
 loops={{{0,0,20},{100,0,20},{100,100,20},{0,100,20}}};f=BoundaryFalloff{};f.remove=true;f.removeWidth=10;f.areaSide=1;
 auto inside=boundaryFalloff({row({5,50,0}),row({20,50,0}),row({-5,50,0})},loops,f,42);need(inside.size()==2&&inside[0].position.x==20&&inside[1].position.x==-5);
 f.areaSide=2;auto outside=boundaryFalloff({row({5,50,0}),row({-5,50,0}),row({-20,50,0})},loops,f,42);need(outside.size()==2&&outside[0].position.x==5&&outside[1].position.x==-20);
 f.remove=false;f.scale=true;f.scaleWidth=20;f.scaleCurve.assign(257,0.5);auto areaScale=boundaryFalloff({row({5,50,0}),row({-5,50,0})},loops,f,42);need(length(areaScale[0].xAxis)==2&&length(areaScale[1].xAxis)==1&&areaScale[1].position.z==0);
 f.scale=false;f.density=true;f.densityCurve.assign(257,0);auto areaDensity=boundaryFalloff({row({5,50,0}),row({-5,50,0})},loops,f,42);need(areaDensity.size()==1&&areaDensity[0].position.x==5);
 std::cout<<"PASS boundary, 100k points, Area Include/Exclude directions and XY projection, dense curves, side-limited scale/density\n";
}catch(const std::exception& e){std::cerr<<e.what();return 1;}}
