#include "core.h"
#include <fstream>
#include <iostream>
using namespace cpl;
int main(int argc,char** argv){Json report;try{
 Input in;in.sources={boxSource({.0015,.0015,.0015})};in.settings.friction=0;in.settings.bounce=0;in.settings.thickness=.0001;
 auto surface=boxMesh({.1,.1,.002});Quat rotation{0,std::sin(.1),0,std::cos(.1)};for(auto& p:surface.vertices)p=rotate(rotation,p);in.colliders={surface};
 double travel[2];report["cases"]=Json::array();
 for(unsigned grip=0;grip<2;++grip){in.settings.stickiness=grip;auto world=joltWorld(in);Birth b;b.id=1;b.position={0,0,.01};world->add(b);for(unsigned i=0;i<600;++i)world->step();auto state=world->states()[0];travel[grip]=length(state.row.position-Vec{0,0,.004});report["cases"].push_back({{"stickiness",grip},{"solver_scale",joltSimulationScale(in)},{"position",{state.row.position.x,state.row.position.y,state.row.position.z}},{"travel_m",travel[grip]},{"sleeping",state.sleeping}});}
 if(!(travel[0]>.05&&travel[1]<.003))throw std::runtime_error("Small-object grip did not retain slope support");report["pass"]=true;
 }catch(const std::exception& e){report["pass"]=false;report["error"]=e.what();}
 if(argc>1)std::ofstream(argv[1])<<report.dump(2)<<'\n';std::cout<<report.dump(2)<<'\n';return report["pass"].get<bool>()?0:1;
}
