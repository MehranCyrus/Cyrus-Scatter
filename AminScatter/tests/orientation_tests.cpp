#include "scatter.h"
#include <algorithm>
#include <cmath>
#include <iostream>
#include <stdexcept>
using namespace amin;
void near(Vec3 a,Vec3 b){if(length(a-b)>1e-7)throw std::runtime_error("orientation mismatch");}
Instance sample(Vec3 p){return {p,{2,0,0},{0,3,0},{0,0,4},1,0,0};}
Vec3 direction(Vec3 p,LineBand b,int axis=1){std::vector<Instance> rows{sample(p)};orientBoundary(rows,{b},{axis});near(rows[0].position,p);if(std::abs(length(rows[0].xAxis)-2)>1e-8||std::abs(length(rows[0].yAxis)-3)>1e-8)throw std::runtime_error("scale changed");return axis<=2?rows[0].yAxis*(axis==1?1.0/3:-1.0/3):rows[0].xAxis*(axis==3?.5:-.5);}
int main(){try{
 LineBand b;b.kind=2;b.width=3;b.faceOutward=true;b.cornerRadius=2;b.boundary.loops={{{0,0,0},{10,0,0},{10,10,0},{0,10,0}}};
 for(int axis=1;axis<=4;++axis)near(direction({5,.5,0},b,axis),{0,-1,0});
 near(direction({5,-0.000001,0},b),{0,-1,0});
 double h=std::sqrt(.5);near(direction({0,0,0},b),{-h,-h,0});near(direction({.1,.1,0},b),{-h,-h,0});
 auto original=direction({.5,.1,0},b);if(original.x>=0||original.y>=0)throw std::runtime_error("blend quadrant");
 std::reverse(b.boundary.loops[0].begin(),b.boundary.loops[0].end());near(direction({.5,.1,0},b),original);
 b.boundary.loops={{{0,0,0},{10,0,0},{10,4,0},{4,4,0},{4,10,0},{0,10,0}}};near(direction({4,4,0},b),{h,h,0});
 // Street mask keeps the adjacent unselected edge available at a corner.
 b.boundaryMask={false,false,true,false,false,false};near(direction({4,4,0},b),{h,h,0});near(direction({7,3.5,0},b),{0,1,0});
 b.boundaryMask.clear();b.boundary.loops={{{0,0,0},{10,0,0},{10,10,0},{0,10,0}},{{3,3,0},{7,3,0},{7,7,0},{3,7,0}}};
 b.cornerRadius=0;near(direction({5,2.8,0},b),{0,1,0});
 std::reverse(b.boundary.loops[1].begin(),b.boundary.loops[1].end());near(direction({5,2.8,0},b),{0,1,0});
 b.boundary.loops={{{0,0,0},{10,0,0},{10,10,0},{0,10,0}}};
 std::vector<Instance> rows{sample({5,.5,12})};orientBoundary(rows,{b},{1},{12});near(rows[0].yAxis,{0,-3,0});near(rows[0].position,{5,.5,12});
 b.faceOutward=false;near(direction({5,.5,0},b),{0,1,0});
 b.faceOutward=true;b.boundary.loops={{{0,0,0},{10,0,0},{10,0,10},{0,0,10}}};near(direction({5,0,.5},b),{0,0,-1});
 // 45-degree corner gives the normalized sum, independent of loop orientation.
 b.cornerRadius=2;b.boundary.loops={{{0,0,0},{10,0,0},{5,5,0}}};near(direction({10,0,0},b),{std::cos(3.141592653589793/8),-std::sin(3.141592653589793/8),0});
 // Local offsets never resample or clip, including movement beyond a thin surface.
 b.kind=6;b.width=.001;b.cornerRadius=0;b.boundary.loops={{{0,0,0},{10,0,0},{10,10,0},{0,10,0}}};
 for(int axis=1;axis<=4;++axis)for(double delta:{-100.0,0.0,100.0}){
  b.edgeOffset=delta;std::vector<Instance> r{sample({5,0,0}),sample({0,0,0})};
  orientBoundary(r,{b},{axis});near(r[0].position,{5,delta,0});near(r[1].position,{delta*h,delta*h,0});
  if(r.size()!=2)throw std::runtime_error("offset removed row");
 }
 b.faceOutward=false;b.edgeOffset=3;std::vector<Instance> local{sample({5,0,0})};orientBoundary(local,{b},{3});near(local[0].position,{2,0,0});near(local[0].xAxis,{2,0,0});
 b.faceOutward=true;b.edgeOffset=0;b.edgeRotation={0,0,90};
 std::vector<Instance> turned{sample({0,5,0}),sample({10,5,0})};orientBoundary(turned,{b},{3});
 near(turned[0].xAxis,{0,-2,0});near(turned[1].xAxis,{0,2,0});near(turned[0].position,{0,5,0});near(turned[0].zAxis,{0,0,4});
 b.edgeRotation={90,0,0};std::vector<Instance> tilted{sample({0,5,0})};orientBoundary(tilted,{b},{3});near(tilted[0].xAxis,{-2,0,0});near(tilted[0].yAxis,{0,0,3});
 b.edgeRotation={};b.edgeOffset=0;b.cornerRadius=4;
 std::vector<Instance> smooth{sample({0,0,0}),sample({0,1,0}),sample({0,2,0}),sample({0,4,0}),sample({0,5,0})};
 orientBoundary(smooth,{b},{3});
 near(smooth[0].xAxis,{-2*h,-2*h,0});near(smooth[3].xAxis,{-2,0,0});near(smooth[4].xAxis,{-2,0,0});
 if(!(smooth[0].xAxis.y<smooth[1].xAxis.y&&smooth[1].xAxis.y<smooth[2].xAxis.y&&smooth[2].xAxis.y<0))throw std::runtime_error("blend falloff not smooth");
 near(smooth[2].position,{0,2,0});
 b.cornerRadius=0;std::vector<Instance> hard{sample({0,1,0})};orientBoundary(hard,{b},{3});near(hard[0].xAxis,{-2,0,0});
 std::cout<<"PASS axes, scales, convex/concave/45deg, masked corners, holes, winding, tilted plane, offsets, disabled\n";
 }catch(const std::exception& e){std::cerr<<e.what()<<'\n';return 1;}}
