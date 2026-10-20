#include "core.h"
#include <windows.h>
#include <psapi.h>
#include <chrono>
#include <fstream>
#include <iostream>
#include <sstream>
using namespace cpl;
double penetration(const Row& a,const Row& b,Vec h){Vec x[3]={rotate(a.rotation,{1,0,0}),rotate(a.rotation,{0,1,0}),rotate(a.rotation,{0,0,1})},y[3]={rotate(b.rotation,{1,0,0}),rotate(b.rotation,{0,1,0}),rotate(b.rotation,{0,0,1})};double minimum=1e100;Vec delta=a.position-b.position;
 auto test=[&](Vec n){double norm=length(n);if(norm<1e-8)return true;n=n*(1/norm);double ra=(std::abs(dot(n,x[0]))*h.x+std::abs(dot(n,x[1]))*h.y+std::abs(dot(n,x[2]))*h.z)*a.scale,rb=(std::abs(dot(n,y[0]))*h.x+std::abs(dot(n,y[1]))*h.y+std::abs(dot(n,y[2]))*h.z)*b.scale;double overlap=ra+rb-std::abs(dot(delta,n));minimum=std::min(minimum,overlap);return overlap>0;};
 for(auto n:x)if(!test(n))return 0;for(auto n:y)if(!test(n))return 0;for(auto u:x)for(auto v:y)if(!test(cross(u,v)))return 0;return minimum;}
std::string fingerprint(const std::vector<Row>& rows){std::uint64_t hash=1469598103934665603ULL;for(auto r:rows)for(unsigned char c:encodeRow(r).dump()){hash^=c;hash*=1099511628211ULL;}std::ostringstream out;out<<std::hex<<hash;return out.str();}
int main(int argc,char** argv){Json reports=Json::array();unsigned maximum=argc>2?unsigned(std::stoul(argv[2])):100;std::string selected=argc>3?argv[3]:"both",scenario=argc>4?argv[4]:"flat";
 for(auto engine:{"jolt","physx"}){if(selected!="both"&&selected!=engine)continue;for(unsigned count:{1u,100u,1000u}){if(count>maximum)continue;for(unsigned repeat=0;repeat<5;++repeat){Json report={{"engine",engine},{"scenario",scenario},{"count",count},{"repeat",repeat},{"dt",1./120},{"worker_threads",0},{"floor_tolerance_m",.0005},{"pair_tolerance_m",.001}};try{
  Input in;Vec half{.05,.025,.002};in.sources.push_back(boxSource(half));in.colliders.push_back(boxMesh({20,20,.1},{0,0,-.1}));if(scenario=="curb")in.colliders.push_back(boxMesh({.1,5,.08},{-.3,0,.08}));
  in.settings.maxSteps=1200;
  std::vector<Birth> births;for(unsigned i=0;i<count;++i){Birth b;b.id=i+1;double pitch=scenario=="pile"?.025:.12;b.position={double(i%32)*pitch,double((i/32)%32)*pitch,.5};if(scenario=="pile")b.position.z+=double(i)*.0045;if(scenario=="curb")b.position.x-=.35;if(scenario=="fast"){b.position.z=3;b.velocity={0,0,-30};}double yaw=double(i%17)*.19;b.rotation={0,0,std::sin(yaw*.5),std::cos(yaw*.5)};births.push_back(b);}
  auto start=std::chrono::steady_clock::now();Session session(in,std::string(engine)=="jolt"?joltWorld:physxWorld);session.emit(births);auto cooked=std::chrono::steady_clock::now();session.release();std::vector<double> slices;bool done=false;while(!done){auto step=std::chrono::steady_clock::now();done=session.tick(1);slices.push_back(std::chrono::duration<double,std::milli>(std::chrono::steady_clock::now()-step).count());}auto ended=std::chrono::steady_clock::now();auto rows=session.rows();double worstFloor=0,worstPair=0;
  for(auto row:rows)for(auto p:in.sources[row.source].render.vertices)worstFloor=std::max(worstFloor,-(rotate(row.rotation,p*row.scale)+row.position).z);
  for(std::size_t i=0;i<rows.size();++i)for(std::size_t j=i+1;j<rows.size();++j)if(length(rows[i].position-rows[j].position)<.13)worstPair=std::max(worstPair,penetration(rows[i],rows[j],half));
  std::sort(slices.begin(),slices.end());PROCESS_MEMORY_COUNTERS memory{};GetProcessMemoryInfo(GetCurrentProcess(),&memory,sizeof(memory));
  report["prepare_ms"]=std::chrono::duration<double,std::milli>(cooked-start).count();report["solve_ms"]=std::chrono::duration<double,std::milli>(ended-cooked).count();report["steps"]=session.stepCount();report["step_p95_ms"]=slices[std::min(slices.size()-1,std::size_t(.95*slices.size()))];report["step_max_ms"]=slices.back();report["process_peak_working_set_bytes"]=memory.PeakWorkingSetSize;report["worst_floor_penetration_m"]=worstFloor;report["worst_pair_penetration_m"]=worstPair;report["transforms_fnv64"]=fingerprint(rows);report["pass"]=worstFloor<.0005&&worstPair<.001;
 }catch(const std::exception& e){report["pass"]=false;report["error"]=e.what();}reports.push_back(report);std::cout<<report.dump()<<std::endl;}}}
 if(argc>1)std::ofstream(argv[1])<<reports.dump(2)<<"\n";return 0;}
