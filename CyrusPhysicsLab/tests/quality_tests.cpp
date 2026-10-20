#include "core.h"
#include <Jolt/Jolt.h>
#include <Jolt/Physics/Collision/Shape/ConvexHullShape.h>
#include <fstream>
#include <iostream>
#include <chrono>
using namespace cpl;
namespace {
int checks=0;
void need(bool b,const char* msg){++checks;if(!b)throw std::runtime_error(msg);}
template<class F>void reject(F f){bool failed=false;try{f();}catch(const std::exception&){failed=true;}need(failed,"Invalid quality input was admitted");}
Mesh torus(){Mesh m;constexpr unsigned n=48,k=16;for(unsigned i=0;i<n;++i)for(unsigned j=0;j<k;++j){double a=i*6.283185307179586/n,b=j*6.283185307179586/k,r=.7+.2*std::cos(b);m.vertices.push_back({r*std::cos(a),r*std::sin(a),.2*std::sin(b)});}
 for(unsigned i=0;i<n;++i)for(unsigned j=0;j<k;++j){unsigned a=i*k+j,b=((i+1)%n)*k+j,c=((i+1)%n)*k+(j+1)%k,d=i*k+(j+1)%k;m.faces.push_back({a,b,c});m.faces.push_back({a,c,d});}return m;}
bool contains(const Source& s,Vec p){for(auto& points:s.hulls){JPH::Array<JPH::Vec3> values;for(auto v:points)values.push_back({float(v.x),float(v.y),float(v.z)});auto cooked=JPH::ConvexHullShapeSettings(values).Create();if(cooked.HasError())throw std::runtime_error(cooked.GetError().c_str());auto* hull=static_cast<const JPH::ConvexHullShape*>(cooked.Get().GetPtr());auto cm=hull->GetCenterOfMass();JPH::Vec3 test(float(p.x)-cm.GetX(),float(p.y)-cm.GetY(),float(p.z)-cm.GetZ());bool inside=true;
 for(unsigned i=0;i<hull->GetNumFaces();++i){JPH::uint indices[256];auto n=hull->GetFaceVertices(i,256,indices);if(n<3)continue;auto a=hull->GetPoint(indices[0]),b=hull->GetPoint(indices[1]),c=hull->GetPoint(indices[2]);auto normal=(b-a).Cross(c-a);if(normal.Dot(a)<0)normal=-normal;if(normal.Dot(test-a)>normal.Length()*1e-5f){inside=false;break;}}
 if(inside)return true;}return false;}
}
int main(int argc,char** argv){Json report;try{
 // Initializes Jolt through the product path before testing the actual hulls.
 Input init;init.sources={boxSource({.1,.1,.1})};joltCollisionGeometry(init);
 auto offset=boxSource({.1,.1,.1});for(auto& h:offset.hulls)for(auto& p:h)p.x+=2;need(!contains(offset,{0,0,0})&&contains(offset,{2,0,0}),"Point containment witness is incorrect");auto mesh=torus();auto fast=qualitySource(mesh,.002,0,16,1);need(contains(fast,{0,0,0}),"Fast hull should fill the torus opening");
 for(unsigned quality:{1u,2u}){auto begin=std::chrono::steady_clock::now();auto detailed=qualitySource(mesh,.002,quality,16,.5);double ms=std::chrono::duration<double,std::milli>(std::chrono::steady_clock::now()-begin).count();need(detailed.hulls.size()>1&&detailed.hulls.size()<=16,"Compound hull budget/concavity failed");Input debug;debug.sources={detailed};if(argc>1)std::ofstream(std::string(argv[1])+".hulls.json")<<encodeInput(debug).dump(2);need(!contains(detailed,{0,0,0}),"Compound did not preserve empty hole");need(contains(detailed,{.7,0,0}),"Compound removed the solid ring");need(detailed.render.faces==mesh.faces&&detailed.render.vertices.size()==mesh.vertices.size(),"Detailed preparation changed the render mesh");
  auto again=qualitySource(mesh,.002,quality,16,.5);Input a,b;a.sources={detailed};b.sources={again};need(encodeInput(a)==encodeInput(b),"Detailed cook is not repeatable");
  a.colliders={boxMesh({3,3,.05},{0,0,-.05})};auto world=joltWorld(a);Birth birth;birth.id=1;birth.position={0,0,1};world->add(birth);for(unsigned i=0;i<1200;++i)world->step();auto state=world->states().at(0);need(state.row.position.z>0&&state.row.position.z<1,"Compound fell through or escaped floor");
  report[std::to_string(quality)]={{"pieces",detailed.hulls.size()},{"cook_ms",ms},{"hole_clear",true},{"floor_z",state.row.position.z}};
 }
 auto box=boxMesh({.3,.2,.1});Input a,b;a.sources={qualitySource(box,.002,0,16,1)};b.sources={proxySource(box,box,.002,true)};need(encodeInput(a)==encodeInput(b),"Fast changed the previous solver input");for(unsigned quality:{1u,2u}){a.sources={qualitySource(box,.002,quality,16,1)};need(encodeInput(a)==encodeInput(b),"Convex model acquired unnecessary compound pieces");}
 reject([&]{qualitySource(box,.002,3,16,1);});reject([&]{qualitySource(box,.002,2,17,1);});reject([&]{qualitySource(box,.002,2,0,1);});reject([&]{qualitySource(box,.002,2,16,0);});
 auto thin=boxMesh({.3,.2,.0001});reject([&]{qualitySource(thin,.002,2,16,1);});auto invalid=box;invalid.faces[0][0]=10000;reject([&]{qualitySource(invalid,.002,2,16,1);});
 {Json capture;std::ifstream(std::string(CPL_QUALITY_FIXTURES)+"/rolling-sphere-mountain.json")>>capture;auto in=decodeInput(capture.at("input"));auto world=joltWorld(in);std::vector<Birth> births;for(auto& v:capture.at("births"))births.push_back(decodeBirth(v));std::size_t cursor=0;double floor=1e100;for(auto p:in.colliders[0].vertices)floor=std::min(floor,p.z);
  unsigned last=births.back().step;for(unsigned step=0;step<last+4000;++step){while(cursor<births.size()&&births[cursor].step==step)world->add(births[cursor++]);world->step();for(auto b:world->states()){double top=-1e100;for(auto& h:in.sources[b.row.source].hulls)for(auto p:h)top=std::max(top,(rotate(b.row.rotation,p*b.row.scale)+b.row.position).z);need(top>=floor-.01,"Rolling sphere tunnelled inside the actual mountain");}}
  report["rolling_sphere_mountain"]={{"bodies",births.size()},{"steps",last+4000},{"interior_tunnels",0}};
 }
 report["pass"]=true;report["checks"]=checks;std::cout<<"PASS "<<checks<<" quality/hole/determinism/dynamics checks\n";
 }catch(const std::exception& e){report["pass"]=false;report["error"]=e.what();std::cerr<<e.what()<<"\n";if(argc>1)std::ofstream(argv[1])<<report.dump(2);return 1;}
 if(argc>1)std::ofstream(argv[1])<<report.dump(2);return 0;
}
