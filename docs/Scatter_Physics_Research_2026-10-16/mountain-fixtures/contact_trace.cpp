#include "core.h"
#include <algorithm>
#include <fstream>
#include <iostream>
#include <map>
#include <set>
using namespace cpl;
int main(int argc,char** argv){try{if(argc!=3)throw std::runtime_error("contact_trace result.json trace.json");Json j;std::ifstream(argv[1])>>j;auto in=decodeInput(j.at("input"));auto world=joltWorld(in);Surface surface(in.colliders.at(0));std::vector<Birth> births;for(auto& b:j["births"])births.push_back(decodeBirth(b));unsigned last=births.empty()?0:births.back().step;std::size_t cursor=0;std::set<std::uint64_t> outside,below;Json report={{"events",Json::array()},{"samples",Json::array()}};double floor=1e100;for(auto v:in.colliders[0].vertices)floor=std::min(floor,v.z);
 report["birth_support"]=Json::array();
 for(unsigned step=0;step<last+4000;++step){while(cursor<births.size()&&births[cursor].step==step){auto b=births[cursor++];double gap=1e100;for(auto& hull:in.sources[b.source].hulls)for(auto v:hull){Vec p=rotate(b.rotation,v*b.scale)+b.position;Hit h;if(surface.hit({p.x,p.y,1000},{0,0,-1},h))gap=std::min(gap,p.z-h.point.z);}report["birth_support"].push_back({{"id",b.id},{"minimum_vertex_gap_m",gap},{"step",step}});world->add(b);}world->step();for(auto& b:world->states()){
  Hit h;bool over=surface.hit({b.row.position.x,b.row.position.y,1000},{0,0,-1},h);if(!over&&outside.insert(b.row.id).second)report["events"].push_back({{"kind","left_receiver"},{"id",b.row.id},{"step",step+1},{"row",encodeRow(b.row)}});
  double hi=-1e100;for(auto& hull:in.sources[b.row.source].hulls)for(auto v:hull)hi=std::max(hi,(rotate(b.row.rotation,v*b.row.scale)+b.row.position).z);
  if(hi<floor-.01&&below.insert(b.row.id).second)report["events"].push_back({{"kind","wholly_below_lowest_surface"},{"id",b.row.id},{"step",step+1},{"ever_left_receiver",outside.contains(b.row.id)},{"over_receiver",over},{"row",encodeRow(b.row)},{"speed",length(b.velocity)}});
  if(step%30==0&&(b.row.id==2||below.contains(b.row.id)))report["samples"].push_back({{"id",b.row.id},{"step",step+1},{"row",encodeRow(b.row)},{"speed",length(b.velocity)},{"over_receiver",over},{"hi_z",hi}});
 }}
 double finalDepth=0,normalDepth=0,sleepDepth=0;unsigned sleeping=0;for(auto& b:world->states()){sleeping+=b.sleeping;for(auto& hull:in.sources[b.row.source].hulls)for(auto v:hull){auto p=rotate(b.row.rotation,v*b.row.scale)+b.row.position;Hit h;if(surface.hit({p.x,p.y,1000},{0,0,-1},h)){finalDepth=std::max(finalDepth,h.point.z-p.z);double d=dot(h.point-p,h.normal);normalDepth=std::max(normalDepth,d);if(b.sleeping)sleepDepth=std::max(sleepDepth,d);}}}
 bool interiorTunnel=false;for(auto& event:report["events"])if(event["kind"]=="wholly_below_lowest_surface"&&!event["ever_left_receiver"].get<bool>())interiorTunnel=true;
 double savedVertical=0,savedNormal=0;for(auto& item:j.at("rows")){auto row=decodeRow(item);for(auto& hull:in.sources[row.source].hulls)for(auto v:hull){auto p=rotate(row.rotation,v*row.scale)+row.position;Hit h;if(surface.hit({p.x,p.y,1000},{0,0,-1},h)){savedVertical=std::max(savedVertical,h.point.z-p.z);savedNormal=std::max(savedNormal,dot(h.point-p,h.normal));}}}report["published_vertical_depth_m"]=savedVertical;report["published_normal_depth_m"]=savedNormal;
 report["bodies"]=births.size();report["ever_left"]=outside;report["wholly_below"]=below;report["final_vertex_depth_m"]=finalDepth;report["final_normal_depth_m"]=normalDepth;report["sleeping_normal_depth_m"]=sleepDepth;report["sleeping"]=sleeping;report["contact_distance_m"]=joltContactDistance(in);report["interior_tunnel"]=interiorTunnel;std::ofstream(argv[2])<<report.dump(2)<<'\n';std::cout<<report["events"].dump(2)<<'\n';return interiorTunnel?2:0;
 }catch(const std::exception& e){std::cerr<<e.what()<<'\n';return 1;}}
