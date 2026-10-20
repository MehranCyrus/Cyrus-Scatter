#define main unused_fit_main
#include "fit_metrics.cpp"
#undef main
int main(int argc,char** argv){try{Json j;std::ifstream(argv[1])>>j;auto in=decodeInput(j["input"]);auto out=qualitySource(in.sources[0].render,.002,2,16,1);Input data;data.sources={out};j["input"]=encodeInput(data);std::ofstream(argv[2])<<j.dump();Input init;init.sources={boxSource({1,1,1})};joltCollisionGeometry(init);Json info={{"pieces",out.hulls.size()},{"hole_inside",inside(planes(out),{-1.3,0,1.0})}};std::cout<<info.dump();return 0;}catch(const std::exception& e){std::cerr<<e.what();return 1;}}
