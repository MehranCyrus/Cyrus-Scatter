#include "live_session.h"
#include <windows.h>
#include <psapi.h>
#include <algorithm>
#include <chrono>
#include <iostream>
using namespace cpl;
using Clock=std::chrono::steady_clock;
double ms(Clock::time_point start){return std::chrono::duration<double,std::milli>(Clock::now()-start).count();}
std::size_t memory(){PROCESS_MEMORY_COUNTERS_EX m{};m.cb=sizeof(m);GetProcessMemoryInfo(GetCurrentProcess(),reinterpret_cast<PROCESS_MEMORY_COUNTERS*>(&m),sizeof(m));return m.PrivateUsage;}
int main(int argc,char** argv){try{double grip=argc>1?std::stod(argv[1]):0;Json report=Json::array();for(unsigned count:{1000u,5000u}){
 Input in;in.sources={boxSource({.01,.01,.002})};in.colliders={boxMesh({5,5,.1},{0,0,-.1})};in.settings.maxBodies=count;in.settings.radius=.000001;in.settings.spacing=.060001;in.settings.scaleMin=in.settings.scaleMax=1;
 in.settings.stickiness=grip;validate(in);auto start=Clock::now();ContinuousCore core(in,in.colliders[0]);double createMs=ms(start);std::size_t peak=memory();start=Clock::now();core.beginGesture();
 for(unsigned line=0;line<count/100;++line){double y=-3+line*.1;core.sample({-3,y,0},{0,0,1},false);core.sample({-3,y,0},{0,0,1},true);core.sample({-3+99*in.settings.spacing+.0000001,y,0},{0,0,1},true);}
 core.endGesture();double birthMs=ms(start);if(core.view().bodies.size()!=count)throw std::runtime_error("Stress birth count differs");peak=std::max(peak,memory());
 std::vector<double> times;for(unsigned i=0;i<360;++i){start=Clock::now();core.advance();times.push_back(ms(start));if(i%30==0)peak=std::max(peak,memory());}
 std::sort(times.begin(),times.end());auto view=core.view();start=Clock::now();auto archive=core.archive();auto bytes=archive.dump().size();double archiveMs=ms(start);peak=std::max(peak,memory());
 start=Clock::now();core.undoGesture();double undoMs=ms(start);peak=std::max(peak,memory());if(!core.view().bodies.empty())throw std::runtime_error("Stress Undo failed");start=Clock::now();core.redoGesture();double redoMs=ms(start);peak=std::max(peak,memory());if(core.view().bodies.size()!=count)throw std::runtime_error("Stress Redo failed");
 report.push_back({{"bodies",count},{"render_vertices",count*8},{"render_faces",count*12},{"steps",360},{"create_ms",createMs},{"birth_ms",birthMs},{"step_p50_ms",times[180]},{"step_p95_ms",times[342]},{"step_max_ms",times.back()},{"archive_ms",archiveMs},{"archive_bytes",bytes},{"undo_ms",undoMs},{"redo_ms",redoMs},{"sampled_peak_private_bytes",peak},{"moving",view.active},{"lost",view.lost}});
 }std::cout<<Json({{"stickiness",grip},{"runs",report}}).dump(2)<<"\n";return 0;}catch(const std::exception& e){std::cerr<<e.what()<<"\n";return 1;}}
