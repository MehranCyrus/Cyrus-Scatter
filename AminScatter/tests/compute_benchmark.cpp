#include "scatter.h"
#ifdef CYRUS_BENCH_EXECUTION
#include "execution.h"
#endif
#include <algorithm>
#include <chrono>
#include <filesystem>
#include <fstream>
#include <iomanip>
#include <iostream>
#include <string>
using namespace amin;
namespace {
void vectorBytes(std::ofstream& out,Vec3 p) {
    for(double v:{p.x,p.y,p.z}) out.write(reinterpret_cast<const char*>(&v),sizeof(v));
}
void saveRows(const std::filesystem::path& path,const std::vector<Instance>& rows) {
    std::ofstream out(path,std::ios::binary);
    const auto size=static_cast<std::uint64_t>(rows.size());
    out.write(reinterpret_cast<const char*>(&size),sizeof(size));
    for(const auto& row:rows) {
        vectorBytes(out,row.position);vectorBytes(out,row.xAxis);vectorBytes(out,row.yAxis);vectorBytes(out,row.zAxis);
        out.write(reinterpret_cast<const char*>(&row.scale),sizeof(row.scale));
        out.write(reinterpret_cast<const char*>(&row.source),sizeof(row.source));
        out.write(reinterpret_cast<const char*>(&row.triangle),sizeof(row.triangle));
    }
    if(!out) throw std::runtime_error("Could not save differential fixture");
}
}
int main(int argc,char** argv) {
    try {
        if(argc!=4) throw std::invalid_argument("Usage: scatter_benchmark output-directory thread-limit trials");
        const std::filesystem::path output=argv[1];std::filesystem::create_directories(output);
        const auto threads=static_cast<unsigned>(std::stoul(argv[2]));const auto trials=std::stoul(argv[3]);
        if(trials<1 || trials>100) throw std::invalid_argument("Trials must be 1..100");
#ifdef CYRUS_BENCH_EXECUTION
        setComputeThreads(threads);
#else
        (void)threads;
#endif
        const std::vector<Triangle> surface{
            {{-450,-400,0},{500,-400,0},{-450,600,0},{0,0,0},{1,0,0},{0,1,0}},
            {{500,-400,0},{500,600,0},{-450,600,0},{1,0,0},{1,1,0},{0,1,0}}};
        const auto run=[&](const std::string& name,const Settings& settings) {
            const auto expected=scatter(surface,settings); // warmup and ordered golden
            saveRows(output/(name+".bin"),expected);
            std::vector<double> elapsed;
            for(unsigned i=0;i<trials;++i) {
                const auto begin=std::chrono::steady_clock::now();
                const auto rows=scatter(surface,settings);
                const auto end=std::chrono::steady_clock::now();
                elapsed.push_back(std::chrono::duration<double,std::milli>(end-begin).count());
                if(rows.size()!=expected.size()) throw std::runtime_error("Nonrepeatable count");
                // Independently compare every timed output, not just its count.
                saveRows(output/(name+"-last.bin"),rows);
                std::ifstream a(output/(name+".bin"),std::ios::binary),b(output/(name+"-last.bin"),std::ios::binary);
                if(!std::equal(std::istreambuf_iterator<char>(a),{},std::istreambuf_iterator<char>(b),{}))
                    throw std::runtime_error("Nonrepeatable ordered transforms");
            }
            std::sort(elapsed.begin(),elapsed.end());
            const double median=elapsed.size()%2?elapsed[elapsed.size()/2]:(elapsed[elapsed.size()/2-1]+elapsed[elapsed.size()/2])*.5;
            unsigned participants=1;std::uint64_t queries=0;bool fallback=false;
#ifdef CYRUS_BENCH_EXECUTION
            const auto stats=lastComputeStats();participants=stats.participants;queries=stats.clusterQueries;
            fallback=stats.threadLaunchFallback;
#endif
            std::cout<<std::setprecision(12)<<"{\"case\":\""<<name<<"\",\"requested\":"<<settings.count
                <<",\"rows\":"<<expected.size()<<",\"median_ms\":"<<median<<",\"participants\":"<<participants
                <<",\"queries\":"<<queries
                <<",\"thread_fallback\":"<<(fallback?"true":"false")<<",\"samples_ms\":[";
            for(std::size_t i=0;i<elapsed.size();++i) std::cout<<(i?",":"")<<elapsed[i];
            std::cout<<"]}\n"<<std::flush;
        };
        Settings s;s.seed=244;s.sourceCount=2;s.sourceWeights={.05,1};s.sourceGroups={0xff0000,0x646464};
        s.clusterEnabled=true;s.clusterSize=30;s.clusterRoughness=.5;s.clusterSeed=42;
        s.uniformScale={1,1};s.preserveDensity=true;
        for(unsigned count:{200u,4095u,4096u,32000u,64000u,100000u}) {
            s.count=count;run("clover_"+std::to_string(count),s);
        }
        s.count=12000;s.sourceCount=4;s.sourceWeights={.05,1,.7,0};s.sourceGroups={1,2,1,3};
        s.clusterBlur=.7;s.clusterNoise=.23;s.rotationDegrees={{{-20,30},{-10,50},{0,360}}};
        s.axisScale={{{.5,2},{.6,3},{1,4}}};run("blur_noise_weights",s);
        s.sourceWeights.clear();run("uniform_groups",s);
        s.distribution=1;s.clusterRadius=50;run("legacy_cluster",s);
        s.distribution=0;s.movement={{{-3,3},{-2,2},{0,0}}};run("projected_movement",s);
        s.movement={};s.areas={{{{{-300,-250,0},{300,-250,0},{300,350,0},{-300,350,0}}},true}};
        run("area_thinning",s);s.preserveDensity=false;run("area_refill",s);
        s.areas.clear();s.distribution=2;s.densityWidth=s.densityHeight=4;s.density.assign(16,.37);
        run("density_rejection",s);
        s.distribution=0;s.count=8000;s.collisionEnabled=true;s.collisionRadius=2;run("ordered_collision",s);
        s.collisionEnabled=false;s.count=2000;s.relaxEnabled=true;s.relaxSpacing=15;s.relaxIterations=5;
        run("ordered_relax",s);
        s.relaxEnabled=false;s.count=64000;s.linePattern=true;s.lineBands.clear();
        LineBand band;band.kind=2;band.width=50;band.group=1;
        band.boundary.loops={{{-450,-400,0},{500,-400,0},{500,600,0},{-450,600,0}}};
        s.lineBands.push_back(band);run("analyzer_inner_border",s);
        s.lineBands[0].boundary.loops.push_back({{-20,-10,0},{-20,40,0},{40,40,0},{40,-10,0}});
        s.lineBands[0].boundaryMask={true,false,true,true,false,true,true,false};
        s.lineBands[0].straightEnds=true;run("analyzer_masked_hole",s);
        s.linePattern=false;s.lineBands.clear();s.count=8000;s.clusterSize=1e-10;
        try{scatter(surface,s);throw std::runtime_error("Invalid coordinates accepted");}
        catch(const std::invalid_argument& e){std::cout<<"{\"error_case\":\"tiny_cluster\",\"message\":\""<<e.what()<<"\"}\n";}
    } catch(const std::exception& e) {std::cerr<<e.what()<<'\n';return 1;}
}
