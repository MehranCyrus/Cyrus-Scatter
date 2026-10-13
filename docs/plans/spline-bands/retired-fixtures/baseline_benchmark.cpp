#include "scatter.h"
#include <algorithm>
#include <chrono>
#include <cmath>
#include <iostream>
#include <vector>

int main(){
    const std::vector<amin::Triangle> surface={{{-100,-100,0},{200,-100,0},{200,200,0}},{{-100,-100,0},{200,200,0},{-100,200,0}}};
    const amin::Area rectangle{{{{0,0,0},{100,0,0},{100,100,0},{0,100,0}}},true};
    std::cout<<"candidates,bands,cold_ms,warm_median_ms,warm_p95_ms,accepted\n";
    for(unsigned count:{1000u,10000u,100000u})for(unsigned bands:{1u,8u,32u}){
        amin::Settings settings;settings.count=count;settings.sourceCount=1;settings.sourceWeights={1};settings.linePattern=true;
        for(unsigned i=0;i<bands;++i){amin::LineBand band;band.boundary=rectangle;band.width=40.*(i+1)/bands;band.sources={0};settings.lineBands.push_back(band);}
        double cold=0;std::vector<double> times;std::size_t accepted=0;
        for(int run=0;run<21;++run){
            const auto begin=std::chrono::steady_clock::now();const auto result=amin::scatter(surface,settings);
            const auto ms=std::chrono::duration<double,std::milli>(std::chrono::steady_clock::now()-begin).count();accepted=result.size();
            if(run==0)cold=ms;else times.push_back(ms);
        }
        std::sort(times.begin(),times.end());std::cout<<count<<','<<bands<<','<<cold<<','<<(times[9]+times[10])*.5<<','<<times[18]<<','<<accepted<<'\n';
    }
}
