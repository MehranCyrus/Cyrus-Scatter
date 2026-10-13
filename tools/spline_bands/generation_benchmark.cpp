#include "spline_bands.h"
#include <algorithm>
#include <chrono>
#include <iostream>
#include <vector>

int main(){
    using namespace cyrus::bands;
    const std::vector<amin::Triangle> surface={{{-100,-100,0},{200,-100,0},{200,200,0}},{{-100,-100,0},{200,200,0},{-100,200,0}}};
    const amin::Area rectangle{{{{0,0,0},{100,0,0},{100,100,0},{0,100,0}}},true};
    std::cout<<"candidates,bands,cold_ms,warm_median_ms,warm_p95_ms,accepted\n";
    for(unsigned count:{1000u,10000u,100000u})for(unsigned bands:{1u,8u,32u}){
        amin::Settings settings;settings.count=count;settings.sourceCount=1;settings.sourceWeights={1};
        std::vector<Band> authored;
        for(unsigned i=0;i<bands;++i){Band b;b.id=i+1;b.path=1;b.start=40.*i/bands;b.end=40.*(i+1)/bands;b.sources={{"source",0,1,false}};authored.push_back(std::move(b));}
        settings.splineField=std::make_shared<Field>(std::vector<Path>{{1,rectangle,Join::Rounded}},authored,Arrangement::Consecutive);
        double cold=0;std::vector<double> times;std::size_t accepted=0;
        for(int run=0;run<21;++run){
            const auto begin=std::chrono::steady_clock::now();const auto result=amin::scatter(surface,settings);
            const auto ms=std::chrono::duration<double,std::milli>(std::chrono::steady_clock::now()-begin).count();accepted=result.size();
            if(run==0)cold=ms;else times.push_back(ms);
        }
        std::sort(times.begin(),times.end());std::cout<<count<<','<<bands<<','<<cold<<','<<(times[9]+times[10])*.5<<','<<times[18]<<','<<accepted<<std::endl;
    }
}
