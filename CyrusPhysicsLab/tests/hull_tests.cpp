#include "core.h"
#include <Jolt/Jolt.h>
#include <Jolt/Physics/Collision/Shape/ConvexHullShape.h>
#include <fstream>
#include <iostream>
#include <limits>
#include <algorithm>
using namespace cpl;
namespace {
unsigned checks=0;
void need(bool value,const char* error){++checks;if(!value)throw std::runtime_error(error);}
template<class F>void reject(F f){bool failed=false;try{f();}catch(const std::exception&){failed=true;}need(failed,"Invalid hull was silently accepted");}
Source transformed(Source s,double scale,Vec offset){for(auto& p:s.render.vertices)p=p*scale+offset;for(auto& h:s.hulls)for(auto& p:h)p=p*scale+offset;return s;}
}
int main(int argc,char** argv){Json report;try{
 Json fixture;std::ifstream(std::string(CPL_HULL_FIXTURES)+"/artist-hulls-018.json")>>fixture;
 auto captured=decodeInput(fixture.at("input"));joltValidateSource(boxSource({1,1,1}),.002);
 unsigned legacyFailures=0;
 for(auto& s:captured.sources)for(auto& h:s.hulls){JPH::Array<JPH::Vec3> points;for(auto p:h)points.push_back({float(p.x),float(p.y),float(p.z)});JPH::ConvexHullShapeSettings settings(points);settings.mHullTolerance=1.e-6f;settings.mMaxConvexRadius=.0001f;settings.mMaxErrorConvexRadius=.00002f;auto result=settings.Create();if(result.HasError())++legacyFailures;}
 need(legacyFailures>0,"Captured artist data no longer witnesses the original rejection");report["legacy_rejected_pieces"]=legacyFailures;
 unsigned variants=0;
 for(auto source:captured.sources)for(double scale:{.1,1.,10.})for(Vec offset:{Vec{},Vec{10,-30,4}}){
  Input in;in.settings.thickness=.002*scale;in.sources={transformed(source,scale,offset)};auto wires=joltCollisionGeometry(in);need(wires->segments>0,"Collision display is empty");auto world=joltWorld(in);Birth birth;birth.id=1;birth.position={0,0,20};world->add(birth);for(unsigned i=0;i<4;++i)world->step();need(world->states().size()==1,"Single-model world failed");
  Vec lo{1e100,1e100,1e100},hi=lo*-1;for(auto& h:in.sources[0].hulls)for(auto p:h){lo={std::min(lo.x,p.x),std::min(lo.y,p.y),std::min(lo.z,p.z)};hi={std::max(hi.x,p.x),std::max(hi.y,p.y),std::max(hi.z,p.z)};}
  for(auto line:wires->sources[0])for(auto p:line)need(p.x>=lo.x-.001&&p.x<=hi.x+.001&&p.y>=lo.y-.001&&p.y<=hi.y+.001&&p.z>=lo.z-.001&&p.z<=hi.z+.001,"Recentring moved the collision silhouette");
  ++variants;
 }
 {auto in=captured;auto world=joltWorld(in);for(unsigned i=0;i<in.sources.size();++i){Birth b;b.id=i+1;b.source=i;b.position={double(i)*10,0,5};world->add(b);}for(unsigned i=0;i<100;++i)world->step();need(world->states().size()==2,"Mixed world failed");}
 for(unsigned quality=0;quality<3;++quality){auto s=qualitySource(captured.sources[1].render,.002,quality,quality==1?8:16,1);joltValidateSource(s,.002);need(!s.hulls.empty(),"Quality cook failed");report["teapot_quality_pieces"].push_back(s.hulls.size());}
 for(auto source:captured.sources){for(auto& h:source.hulls){std::reverse(h.begin(),h.end());h.push_back(h[0]);}joltValidateSource(source,.002);++variants;}
 auto thin=boxSource({.2,.1,.001});joltValidateSource(thin,.002);joltValidateSource(transformed(thin,1,{30,-5,3}),.002);
 auto bad=boxSource({1,1,1});for(auto& p:bad.hulls[0])p.z=0;reject([&]{joltValidateSource(bad,.002);});bad.hulls[0][0].x=std::numeric_limits<double>::quiet_NaN();reject([&]{joltValidateSource(bad,.002);});
 {Json data;std::ifstream(std::string(CPL_HULL_FIXTURES)+"/retired-palette-rebuild.json")>>data;auto input=decodeInput(data.at("input"));auto world=joltWorld(input);Surface surface(input.colliders.at(0));std::vector<Birth> births;for(auto& b:data.at("births"))births.push_back(decodeBirth(b));std::size_t cursor=0;
  for(unsigned step=0;step<births.back().step+4000;++step){while(cursor<births.size()&&births[cursor].step==step)world->add(births[cursor++]);world->step();}
  double depth=0;for(auto state:world->states())for(auto& hull:input.sources[state.row.source].hulls)for(auto p:hull){p=rotate(state.row.rotation,p*state.row.scale)+state.row.position;Hit h;if(surface.hit({p.x,p.y,1000},{0,0,-1},h))depth=std::max(depth,dot(h.point-p,h.normal));}
  need(depth<.01,"Repair changed valid compound dynamics and caused deep terrain overlap");report["retired_palette_replay"]={{"bodies",births.size()},{"normal_depth_m",depth}};
 }
 report["pass"]=true;report["checks"]=checks;report["shape_variants"]=variants;std::cout<<"PASS "<<checks<<" artist hull checks, "<<variants<<" variants\n";
 }catch(const std::exception& e){report["pass"]=false;report["error"]=e.what();std::cerr<<e.what()<<'\n';if(argc>1)std::ofstream(argv[1])<<report.dump(2);return 1;}if(argc>1)std::ofstream(argv[1])<<report.dump(2);return 0;}
