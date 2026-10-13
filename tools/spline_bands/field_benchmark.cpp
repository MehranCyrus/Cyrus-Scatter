#include "spline_bands.h"
#include <algorithm>
#include <chrono>
#include <iostream>
#include <vector>

using namespace cyrus::bands;
int main(){
    std::cout<<"scenario,join,candidates,bands,prepare_cold_ms,prepare_median_ms,prepare_p95_ms,query_cold_ms,query_median_ms,query_p95_ms,levels,vertices,retained_bytes,checksum\n";
    for(unsigned scenario:{0u,1u,2u})for(Join join:{Join::Rounded,Join::Sharp})for(unsigned count:{1000u,10000u,100000u})for(unsigned bands:{1u,8u,32u}){
        if(scenario>0 && (count!=100000 || bands==1 || (scenario==2&&bands==32)))continue;
        Path path{1,{{{{0,0,0},{100,0,0},{100,100,0},{0,100,0}}},true},join};std::vector<Band> inputs;
        if(scenario==2)path.area.loops={{{0,0,0},{100,0,0},{100,35,0},{35,35,0},{35,100,0},{0,100,0}}};
        for(unsigned i=0;i<bands;++i){Band band;band.id=i+1;band.path=1;band.end=40;band.curve={0,1};band.strength=scenario?1.:1./bands;if(scenario==2)band.curve={0,0,1,0,0};band.sources={{std::to_string(i+1),i,1,false}};inputs.push_back(band);}
        std::vector<double> preparation,times;double coldPrepare=0,coldQuery=0,checksum=0;Stats stats;
        for(int run=0;run<21;++run){
            const auto begin=std::chrono::steady_clock::now();Field field({path},inputs,Arrangement::Independent);
            const auto prepared=std::chrono::steady_clock::now();checksum=0;stats=field.stats();
            for(unsigned i=0;i<count;++i){const double x=-40+180.*((std::uint64_t(i)*73)%100003)/100003,y=-40+180.*((std::uint64_t(i)*97)%100019)/100019;checksum+=field.inspect({x,y,0}).occupancy;}
            const auto end=std::chrono::steady_clock::now();const double prep=std::chrono::duration<double,std::milli>(prepared-begin).count(),query=std::chrono::duration<double,std::milli>(end-prepared).count();
            if(run==0){coldPrepare=prep;coldQuery=query;}else{preparation.push_back(prep);times.push_back(query);}
        }
        std::sort(preparation.begin(),preparation.end());std::sort(times.begin(),times.end());
        std::cout<<(scenario==0?"normalized":scenario==1?"saturated":"concave-steep")<<','<<(join==Join::Sharp?"Sharp":"Rounded")<<','<<count<<','<<bands<<','<<coldPrepare<<','<<(preparation[9]+preparation[10])*.5<<','<<preparation[18]<<','<<coldQuery<<','<<(times[9]+times[10])*.5<<','<<times[18]<<','<<stats.levels<<','<<stats.vertices<<','<<stats.bytes<<','<<checksum<<std::endl;
    }
}
