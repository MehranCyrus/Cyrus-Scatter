#include "core.h"
#include <fstream>
#include <iostream>
using namespace cpl;
unsigned checks=0;
void need(bool v,const char* why){++checks;if(!v)throw std::runtime_error(why);}
Mesh decodeMesh(const Json& value){Input in;in.sources={boxSource({.01,.01,.01})};auto j=encodeInput(in);j["colliders"]=Json::array({value});return decodeInput(j).colliders.at(0);}
int main(int argc,char** argv){Json report;try{
 Json fixture;std::ifstream(std::string(CPL_COOK_FIXTURES)+"/millimetre-teapot-020.json")>>fixture;auto original=decodeMesh(fixture);
 report["teapot"]=Json::array();
 for(double scale:{.1,1.,100.,1000.}){auto mesh=original;for(auto& p:mesh.vertices)p=rotate({.1,.2,.3,std::sqrt(.86)},p*scale)+Vec{.3,-.7,1.2};
  auto info=joltColliderInfo(mesh);need(info.at("cooked_triangles").get<unsigned>()>4000,"Teapot lost valid collision faces");info["physical_scale"]=scale;report["teapot"].push_back(info);
  Input in;in.sources={boxSource({.001,.001,.001})};in.colliders={mesh};auto world=joltWorld(in);Birth b;b.id=1;b.position={.3,-.7,2};world->add(b);world->step();need(world->states().size()==1,"Small mesh world could not simulate");
 }
 // A finely tessellated platform has all triangle areas below Jolt's default
 // cutoff. It must support a body at its original height, including translation.
 Mesh grid;constexpr unsigned n=32;for(unsigned y=0;y<=n;++y)for(unsigned x=0;x<=n;++x)grid.vertices.push_back({2.+x*.0005,-3.+y*.0005,.4+.00001*x});
 for(unsigned y=0;y<n;++y)for(unsigned x=0;x<n;++x){unsigned a=y*(n+1)+x;grid.faces.push_back({a,a+1,a+n+2});grid.faces.push_back({a,a+n+2,a+n+1});}
 auto info=joltColliderInfo(grid);need(info.at("cooked_triangles")==grid.faces.size(),"Tiny platform lost triangles");need(info.at("cook_scale").get<double>()>1,"Tiny platform did not normalize");
 Input in;in.settings.thickness=.0001;in.settings.bounce=0;in.sources={boxSource({.001,.001,.001})};in.colliders={grid};auto world=joltWorld(in);Birth b;b.id=1;b.position={2.008,-2.992,.43};world->add(b);for(unsigned i=0;i<1200;++i)world->step();auto body=world->states().at(0);
 need(body.row.position.z>.4008&&body.row.position.z<.4015,"Scaled collider changed physical height or leaked");need(body.sleeping,"Small platform contact did not sleep");report["platform"]={{"cook",info},{"solver_length_scale",joltSimulationScale(in)},{"body_z_m",body.row.position.z},{"sleeping",body.sleeping}};
 auto checkpoint=world->checkpoint();world->step();world->restore(*checkpoint);need(encodeRow(world->states()[0].row)==encodeRow(body.row),"Scaled world checkpoint changed physical pose");
 // External gravity/velocity and length remain metres, with angular units intact.
 auto small=in;small.colliders.clear();auto large=small;large.sources={boxSource({.1,.1,.1})};
 auto smallWorld=joltWorld(small),largeWorld=joltWorld(large);b.position={0,0,2};b.velocity={.1,-.2,0};b.spin={0,0,.3};smallWorld->add(b);largeWorld->add(b);
 for(unsigned i=0;i<30;++i){smallWorld->step();largeWorld->step();}
 auto smallState=smallWorld->states()[0],largeState=largeWorld->states()[0];need(length(smallState.row.position-largeState.row.position)<1.e-6&&length(smallState.velocity-largeState.velocity)<1.e-6,"Solver units changed free-flight physics");
 need(length(smallState.spin-largeState.spin)<1.e-6,"Solver units changed angular velocity");
 auto bad=grid;bad.faces={{0,0,0}};bool rejected=false;try{joltColliderInfo(bad);}catch(const std::exception& e){rejected=std::string(e.what()).find("non-degenerate")!=std::string::npos;}need(rejected,"Truly degenerate geometry was accepted");
 in.colliders={grid,bad};rejected=false;try{auto invalid=joltWorld(in);}catch(const std::exception& e){rejected=std::string(e.what()).find("Static collider 2:")!=std::string::npos;}need(rejected,"Cook error omitted collider identity");
 auto duplicates=grid;duplicates.faces.push_back(grid.faces.front());duplicates.faces.push_back({0,0,0});info=joltColliderInfo(duplicates);need(info.at("cooked_triangles")==grid.faces.size()&&info.at("degenerate_triangles")==1&&info.at("duplicate_triangles")==1,"Cleanup removed valid triangle detail");
 // Optional exact artist capture, kept outside the product fixture/package.
 if(argc>2){Json captured;std::ifstream(argv[2])>>captured;auto capturedInput=decodeInput(captured.at("prepared").at("input"));report["artist_colliders"]=Json::array();for(auto& mesh:capturedInput.colliders)report["artist_colliders"].push_back(joltColliderInfo(mesh));auto exact=joltWorld(capturedInput);Birth birth;birth.id=1;birth.position={0,0,.5};exact->add(birth);for(unsigned i=0;i<120;++i)exact->step();need(exact->states().size()==1,"Exact artist input failed");}
 report["pass"]=true;
 }catch(const std::exception& e){report["pass"]=false;report["error"]=e.what();std::cerr<<e.what()<<'\n';}
 report["checks"]=checks;if(argc>1)std::ofstream(argv[1])<<report.dump(2)<<'\n';std::cout<<report.dump(2)<<'\n';return report["pass"].get<bool>()?0:1;
}
