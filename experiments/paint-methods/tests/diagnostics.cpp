#include "fixtures.h"
#include <iostream>
using namespace paintlab;
int main(){
 std::cout<<"method,case,status,observed\n";
 for(int method=1;method<=4;++method){
  // Two nearby sheets connected only by a distant bridge. Along-surface
  // distance is much larger than the radius; Euclidean distance is just 1.
  auto m=plane();for(auto v:plane().vertices){v.z=1;m.vertices.push_back(v);}m.faces.push_back({4,5,6});m.faces.push_back({4,6,7});m.faces.push_back({0,4,5});m.faces.push_back({0,5,1});
  try{Session s(method,m,2);stroke(s,0,0,20);double value=s.view().query({2,{.5,0,.5}},{0,0,1});std::cout<<method<<",connected_fold,"<<(value>.5?"FAIL_surface_distance":"PASS_surface_distance")<<','<<value<<'\n';}catch(const std::exception& e){std::cout<<method<<",connected_fold,N/A_projection,"<<e.what()<<'\n';}
  // Long history cost is measured separately in benchmark.cpp.
 }
}
