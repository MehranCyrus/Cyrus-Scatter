// Qualification of B's test oracle, distinct from qualifying a production backend.
#include "analytic_world.hpp"
#include <iostream>
#include <string>

using namespace fitter_test;
static void require(bool ok,const std::string& why){if(!ok)throw std::runtime_error(why);}
int main(){try{
 Sphere sphere{1,{0,0,0},1};
 auto s=sphere_witness({-2,0,0},{2,0,0},sphere);
 require(std::abs(s.u-.5)<1e-14&&std::abs(s.distance+1)<1e-14,"sphere medial witness");
 require(std::abs(length(s.normal)-1)<1e-14,"sphere normal");
 require(std::abs(dot(s.normal,sub(s.axis,s.surface))-s.distance)<1e-14,"sphere signed witness equation");
 Box box{2,{0,0,0},{1,.5,.75},{}};
 auto cross_box=box_witness({-2,0,0},{2,0,0},box);
 require(std::abs(cross_box.distance+.5)<1e-14,"inside box minimum signed distance");
 auto above=box_witness({-2,1,0},{2,1,0},box);
 require(std::abs(above.distance-.5)<1e-14,"parallel above box distance");
 auto corner=box_witness({2,2,2},{3,3,3},box);
 require(std::abs(corner.distance-std::sqrt(1+2.25+1.5625))<1e-14,"box corner distance");
 auto rotated=box;rotated.center={.3,-.7,1.2};rotated.orientation=axis_angle({1,3,-2},.83);
 auto tx=[&](Vec3 v){return add(rotated.center,rotate(rotated.orientation,v));};
 auto same=box_witness(tx({-2,1,0}),tx({2,1,0}),rotated);
 require(std::abs(same.distance-.5)<2e-14,"rigid OBB invariance");
 std::array<std::pair<Vec3,Vec3>,6> segments{{{{-2,.1,.9},{3,-.7,-.2}},{{.1,.2,.3},{-.2,.1,-.4}},{{-1.2,.7,0},{-.8,-.6,.9}},{{2,2,2},{-2,-2,-2}},{{-3,.500001,.750001},{3,.500001,.750001}},{{0,-2,.2},{.4,2,-.6}}}};
 for(const auto&seg:segments){auto w=box_witness(seg.first,seg.second,box);double sampled=std::numeric_limits<double>::infinity();Vec3 delta=sub(seg.second,seg.first);constexpr int intervals=2048;
  for(int j=0;j<=intervals;++j)sampled=std::min(sampled,local_box_sdf(add(seg.first,mul(delta,double(j)/intervals)),box.half));
  require(w.distance<=sampled+1e-12,"analytic minimum cannot exceed a sample");
  require(sampled-w.distance<=length(delta)/(2*intervals)+1e-12,"1-Lipschitz sampling bound");
  require(std::abs(length(w.normal)-1)<1e-12,"OBB unit normal");
  require(std::abs(dot(w.normal,sub(w.axis,w.surface))-w.distance)<1e-12,"OBB signed witness equation");
  require(std::abs(local_box_sdf(w.surface,box.half))<1e-12,"OBB witness on surface");
 }
 std::cout<<"PASS analytic_oracle: exact primitive controls, rotated OBB invariance, signed witnesses, 6 independent sampling-bound controls\n";
 return 0;
 }catch(const std::exception&e){std::cerr<<"FAIL analytic_oracle: "<<e.what()<<'\n';return 1;}}
