#include "scatter.h"
#include <iostream>
#include <stdexcept>
#include <cmath>
using namespace amin;
void check(bool b,const char* s){if(!b)throw std::runtime_error(s);}
int main(){try{
 std::vector<Triangle> plane={{{0,0,0},{1000,0,0},{1000,1000,0}},{{0,0,0},{1000,1000,0},{0,1000,0}}};
 Settings s;s.count=100000;s.sourceCount=2;s.uniformScale={1,1};
 auto original=scatter(plane,s);s.sourceWeights={.7,.3};
 for(bool cluster:{false,true}){
  s.clusterEnabled=cluster;s.sourceGroups={1,2};s.clusterSize=10;
  auto p=scatter(plane,s);std::size_t first=0;
  check(p.size()==original.size(),"Weights changed population");
  for(std::size_t i=0;i<p.size();++i){first+=p[i].source==0;check(length(p[i].position-original[i].position)==0,"Weights moved a point");check(length(p[i].xAxis-original[i].xAxis)==0,"Weights changed rotation");}
  const double share=static_cast<double>(first)/p.size();check(std::abs(share-.7)<.03,"Incorrect weighted share");
  std::cout<<(cluster?"cluster":"random")<<" box="<<100*share<<"%\n";
  s.sourceWeights={0,1};for(auto v:scatter(plane,s))check(v.source==1,"Zero-weight source selected");
  s.sourceWeights={0,0};check(scatter(plane,s).empty(),"All-zero weights emitted instances");s.sourceWeights={.7,.3};
 }
 s.sourceCount=3;s.sourceGroups={1,1,2};s.sourceWeights={.2,.5,.3};auto p=scatter(plane,s);std::size_t counts[3]{};
 for(auto v:p)++counts[v.source];for(int i=0;i<3;++i)check(std::abs(static_cast<double>(counts[i])/p.size()-s.sourceWeights[i])<.03,"Group/member weights incorrect");
 s.linePattern=true;LineBand band;band.kind=3;band.width=1000;band.boundary.loops={{{0,500,0},{1000,500,0}}};band.sources={0,2};s.lineBands={band};
 p=scatter(plane,s);std::size_t first=0;for(auto v:p){check(v.source!=1,"Stroke source restriction lost");first+=v.source==0;}check(std::abs(static_cast<double>(first)/p.size()-.4)<.02,"Stroke weights incorrect");
 s.sourceWeights={1,-.1,0};bool failed=false;try{scatter(plane,s);}catch(const std::invalid_argument&){failed=true;}check(failed,"Negative weight accepted");
 std::cout<<"PASS weights, groups, zero, strokes, fixed positions and transforms\n";return 0;
}catch(const std::exception& e){std::cerr<<e.what()<<'\n';return 1;}}
