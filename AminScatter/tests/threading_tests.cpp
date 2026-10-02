#include "scatter.h"
#include "execution.h"
#include <cmath>
#include <iostream>
#include <stdexcept>
#include <string>
#include <atomic>
#include <cfenv>
using namespace amin;
namespace {
void check(bool value,const char* message) { if(!value) throw std::runtime_error(message); }
bool same(Vec3 a,Vec3 b) {return a.x==b.x && a.y==b.y && a.z==b.z;}
void equal(const std::vector<Instance>& a,const std::vector<Instance>& b) {
    check(a.size()==b.size(),"Thread limit changed count");
    for(std::size_t i=0;i<a.size();++i) check(same(a[i].position,b[i].position) &&
        same(a[i].xAxis,b[i].xAxis) && same(a[i].yAxis,b[i].yAxis) && same(a[i].zAxis,b[i].zAxis) &&
        a[i].scale==b[i].scale && a[i].source==b[i].source && a[i].triangle==b[i].triangle,
        "Thread limit changed ordered placements");
}
}
int main() {
    try {
        const std::vector<Triangle> surface{
            {{-450,-400,0},{500,-400,0},{-450,600,0},{0,0,0},{1,0,0},{0,1,0}},
            {{500,-400,0},{500,600,0},{-450,600,0},{1,0,0},{1,1,0},{0,1,0}}};
        Settings s;s.count=12000;s.sourceCount=4;s.clusterEnabled=true;s.clusterSize=30;
        s.clusterRoughness=.5;s.clusterBlur=.7;s.clusterNoise=.23;s.sourceWeights={.05,1,.7,0};
        s.sourceGroups={0xff0000,0x808080,0xff0000,0x00ff00};
        s.rotationDegrees={{{-20,30},{-10,50},{0,360}}};s.axisScale={{{.5,2},{.6,3},{1,4}}};
        setComputeThreads(1);const auto serial=scatter(surface,s);
        check(lastComputeStats().participants==1,"Serial policy started workers");
        for(unsigned limit:{2u,4u,0u}) for(int repeat=0;repeat<3;++repeat) {
            setComputeThreads(limit);equal(serial,scatter(surface,s));
            check(lastComputeStats().clusterQueries==s.count,"Wrong cluster query count");
        }
        // The general rejection/movement path remains ordered and serial.
        s.areas={{{{{-300,-250,0},{300,-250,0},{300,350,0},{-300,350,0}}},true}};
        s.movement={{{-3,3},{-2,2},{0,0}}};
        setComputeThreads(1);const auto masked=scatter(surface,s);
        setComputeThreads(4);equal(masked,scatter(surface,s));
        check(lastComputeStats().participants==1,"Unsupported pipeline launched workers");
        s.areas.clear();s.movement={};s.count=100;
        scatter(surface,s);check(lastComputeStats().participants==1,"Small input launched workers");
        // Workers copy the caller's numeric environment, including SSE controls.
        s.count=5000;const int rounding=std::fegetround();
        check(std::fesetround(FE_DOWNWARD)==0,"Could not set test rounding mode");
        setComputeThreads(1);const auto rounded=scatter(surface,s);
        setComputeThreads(4);equal(rounded,scatter(surface,s));
        std::fesetround(rounding);
        // Ordered failure selection and all-worker completion on exceptions.
        std::atomic<int> completed{0};bool rejected=false;
        try {detail::forRanges(100,1,[&](unsigned,std::size_t begin,std::size_t){
            ++completed;throw std::invalid_argument(std::to_string(begin));
        });} catch(const std::invalid_argument& e) {rejected=std::string(e.what())=="0";}
        check(rejected && completed==static_cast<int>(computeParticipants()),"Workers not joined or wrong exception");
        bool invalid=false;try{setComputeThreads(65);}catch(const std::invalid_argument&){invalid=true;}
        check(invalid,"Invalid worker limit accepted");
        setComputeThreads(0);
        std::cout<<"PASS ordered placements, worker limits, fallback pipeline, numeric environment and exception joins\n";
    } catch(const std::exception& e) {std::cerr<<e.what()<<'\n';return 1;}
}
