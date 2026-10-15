#include "orientation.h"
#include "procedural.h"
#include <cmath>
#include <iostream>
#include <limits>
#include <stdexcept>

namespace o=cyrus::orientation;
using amin::Vec3;
void require(bool ok,const char* why){if(!ok)throw std::runtime_error(why);}
void close(double a,double b,double tolerance=1e-10){require(std::abs(a-b)<tolerance,"Analytical orientation mismatch");}
void close(Vec3 a,Vec3 b,double tolerance=1e-10){close(a.x,b.x,tolerance);close(a.y,b.y,tolerance);close(a.z,b.z,tolerance);}
template<class F>void rejects(F f){bool caught=false;try{f();}catch(const std::invalid_argument&){caught=true;}require(caught,"Invalid orientation was accepted");}
Vec3 cross(Vec3 a,Vec3 b){return {a.y*b.z-a.z*b.y,a.z*b.x-a.x*b.z,a.x*b.y-a.y*b.x};}
void orthogonal(const o::Frame& f){for(int i=0;i<3;++i){close(amin::length(f[i]),1);for(int j=0;j<i;++j)close(amin::dot(f[i],f[j]),0);}close(cross(f[0],f[1]),f[2]);}
int main(){try{
 const double pi=std::acos(-1.);
 for(double angle:{0.,15.,45.,90.,135.,179.,180.}){
  const double a=angle*pi/180;Vec3 normal{std::sin(a),0,std::cos(a)};
  close(o::blendedUp(normal,0),{0,0,1});close(o::blendedUp(normal,1),normal);
  close(o::blendedUp(normal,.5),{std::sin(a/2),0,std::cos(a/2)});
  for(double b:{0.,.25,.5,.75,1.}){o::Settings s;s.normalBlend=b;orthogonal(o::frame(normal,{7,8,9},s));}
 }
 close(o::blendedUp({0,0,-1},.5),{1,0,0});
 close(o::blendedUp({0,0,0},0),{0,0,1});
 rejects([]{o::blendedUp({0,0,0},1);});rejects([]{o::blendedUp({0,0,1},NAN);});
 for(double scale:{1e-200,1.,1e150}){
  auto normals=o::normals({{{0,0,0},{scale,0,0},{0,scale,scale}}});close(normals[0],{0,-std::sqrt(.5),std::sqrt(.5)});
 }
 auto degenerate=o::normals({{{0,0,0},{0,0,0},{1,0,0}}});close(degenerate[0],{0,0,0});
 o::Settings s;s.mode=o::Mode::WorldDirection;
 for(Vec3 direction:std::vector<Vec3>{{0,1,0},{1,0,0},{0,0,1},{0,0,-1},{1,2,3},{0,1e-310,0}}){
  s.direction=direction;const auto f=o::frame({0,0,1},{},s);orthogonal(f);
  if(direction.y==1e-310)close(f[1],{0,1,0});else close(f[1],direction*(1/amin::length(direction)));
 }
 s.direction={};rejects([&]{o::validate(s);});s.direction={NAN,0,0};rejects([&]{o::validate(s);});
 s.mode=o::Mode::Target;s.target={5,6,7};auto coincident=o::frame({0,0,1},s.target,s);close(coincident[1],{0,1,0});
 s.target={5,6,20};close(o::frame({0,0,1},{5,6,7},s)[1],{0,0,1});
 s.target.z=INFINITY;rejects([&]{o::validate(s);});
 // The old aligned sampler is an independent integration oracle for unchanged
 // default behavior. Movement is projected; Relax is deliberately off here.
 const std::vector<amin::Triangle> terrain={{{0,0,0},{50,0,0},{0,50,25}},{{50,0,0},{50,50,-10},{0,50,25}}};
 amin::Settings sampler;sampler.count=1500;sampler.seed=917;sampler.receiverSalt=222;sampler.sourceCount=3;
 sampler.axisScale={{{.2,2},{.4,3},{.6,4}}};sampler.rotationDegrees={{{-30,20},{-17,38},{-180,180}}};
 sampler.movement={{{-3,3},{-2,2},{-1,1}}};sampler.uniformScale={.3,2};
 const auto prior=amin::scatter(terrain,sampler);sampler.alignToNormal=false;const auto canonical=amin::scatter(terrain,sampler);
 const auto normal=o::normals(terrain);s={};const auto aligned=o::apply(canonical,normal,s,{});
 require(aligned.size()==prior.size(),"Orientation changed candidate count");
 for(std::size_t i=0;i<prior.size();++i){const auto& a=prior[i];const auto& b=aligned[i];
  close(a.position,b.position,1e-12);close(a.xAxis,b.xAxis);close(a.yAxis,b.yAxis);close(a.zAxis,b.zAxis);
  require(a.source==b.source&&a.candidateKey==b.candidateKey&&a.triangle==b.triangle&&a.scale==b.scale,"Orientation changed unrelated candidate data");
 }
 s.align=false;auto upright=o::apply(canonical,{},s,{});for(std::size_t i=0;i<upright.size();++i){close(upright[i].xAxis,canonical[i].xAxis);close(upright[i].zAxis,canonical[i].zAxis);}
 amin::Instance row{};row.xAxis={2,0,0};row.yAxis={0,3,0};row.zAxis={0,0,4};row.scale=1;row.triangle=0;row.source=0;row.candidateKey=17;row.bandOwner=4;
 s.mode=o::Mode::WorldDirection;s.direction={0,1,0};
 for(int axis=1;axis<=4;++axis){auto rotated=o::apply({row},{},s,{axis})[0];
  auto forward=axis==1?rotated.yAxis:axis==2?rotated.yAxis*(-1):axis==3?rotated.xAxis:rotated.xAxis*(-1);
  close(forward*(1/amin::length(forward)),{0,1,0});
  close(amin::length(rotated.xAxis),2);close(amin::length(rotated.yAxis),3);close(amin::length(rotated.zAxis),4);
  require(rotated.candidateKey==17&&rotated.bandOwner==4&&rotated.source==0,"Orientation changed identity");
 }
 row.xAxis={};row.yAxis={};row.zAxis={};auto zero=o::apply({row},{},s,{1})[0];close(zero.xAxis,{});close(zero.yAxis,{});close(zero.zAxis,{});
 rejects([&]{o::apply({row},{},s,{});});rejects([&]{o::apply({row},{},s,{5});});
 s.align=true;s.normalBlend=1;rejects([&]{o::apply({row},{},s,{1});});
 // A tall box aimed sideways has larger XY clearance but equal spatial bounds.
 row.xAxis={1,0,0};row.yAxis={0,1,0};row.zAxis={0,0,1};s.align=false;
 const auto before=cyrus::procedural::transformedBounds({-1,-1,0},{1,1,20},{row.xAxis,row.yAxis,row.zAxis});
 s.direction={0,0,1};auto sideways=o::apply({row},{},s,{1})[0];
 const auto after=cyrus::procedural::transformedBounds({-1,-1,0},{1,1,20},{sideways.xAxis,sideways.yAxis,sideways.zAxis});
 require(after.xy>before.xy*10,"Final orientation must affect planar Auto Radius");close(after.spatial,before.spatial);
 std::cout<<"Orientation analytic frames, degenerate cases, 1500 complete sampler comparisons and final bounds passed\n";
 return 0;
}catch(const std::exception& e){std::cerr<<e.what()<<'\n';return 1;}}
