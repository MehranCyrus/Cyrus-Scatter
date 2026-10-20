#include "core.h"
#include <algorithm>
#include <fstream>
#include <iostream>
using namespace cpl;
Json run(Input in,std::vector<Birth> births){
 auto w=joltWorld(in);unsigned cursor=0,active=0;double peakSpeed=0,tailMotion=0;std::vector<BodyState> previous;
 unsigned last=0;for(auto& b:births)last=std::max(last,b.step);
 for(unsigned step=0;step<last+3600;++step){while(cursor<births.size()&&births[cursor].step==step)w->add(births[cursor++]);w->step();auto states=w->states();
  if(step>=last+3480){for(unsigned i=0;i<states.size();++i){peakSpeed=std::max(peakSpeed,length(states[i].velocity));if(previous.size()==states.size())tailMotion=std::max(tailMotion,length(states[i].row.position-previous[i].row.position));}}previous=std::move(states);
 }
 double minZ=1e100,maxZ=-1e100,maxSpeed=0,maxSpin=0;unsigned below=0,over=0;Surface surface(in.colliders[0]);
 for(auto& b:previous){active+=!b.sleeping;minZ=std::min(minZ,b.row.position.z);maxZ=std::max(maxZ,b.row.position.z);maxSpeed=std::max(maxSpeed,length(b.velocity));maxSpin=std::max(maxSpin,length(b.spin));Hit hit;if(surface.hit({b.row.position.x,b.row.position.y,10},{0,0,-1},hit)){++over;if(b.row.position.z<0)++below;}}
 Json poses=Json::array();for(auto& b:previous)poses.push_back({{"row",encodeRow(b.row)},{"velocity",{b.velocity.x,b.velocity.y,b.velocity.z}},{"spin",{b.spin.x,b.spin.y,b.spin.z}},{"sleeping",b.sleeping}});
 return {{"bodies",previous.size()},{"active",active},{"over_receiver",over},{"centres_below_surface_over_receiver",below},{"min_z_m",minZ},{"max_z_m",maxZ},{"tail_max_speed_m_s",peakSpeed},{"tail_max_step_motion_m",tailMotion},{"final_max_speed_m_s",maxSpeed},{"final_max_spin_rad_s",maxSpin},{"poses",poses}};
}
int main(int argc,char** argv){try{if(argc!=3)throw std::runtime_error("replay input.json report.json");Json j;std::ifstream(argv[1])>>j;Input in=decodeInput(j["input"]);std::vector<Birth> births;for(auto& b:j["births"])births.push_back(decodeBirth(b));Json report;report["captured_proxy"]=run(in,births);
 for(auto& s:in.sources)s=proxySource(s.render,s.render,in.settings.thickness,true);
 report["automatic_same_births"]=run(in,births);
 // Same recorded positions/times, reset vertical launch offset to the authored height.
 // Old giant plates raised later births above their already mis-sized neighbours.
 for(auto& b:births)b.position.z=in.settings.height;
 report["automatic_authored_height"]=run(in,births);
 report["friction"]=in.settings.friction;report["stickiness"]=in.settings.stickiness;
 std::ofstream(argv[2])<<report.dump(2)<<'\n';std::cout<<report.dump(2)<<'\n';return 0;
 }catch(const std::exception& e){std::cerr<<e.what()<<'\n';return 1;}}
