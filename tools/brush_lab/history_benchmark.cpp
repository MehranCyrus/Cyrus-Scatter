// CPU-only cost baseline. This does not measure viewport latency or GPU work.
#include "brush.h"
#include <chrono>
#include <cmath>
#include <iomanip>
#include <iostream>
#include <stdexcept>
using namespace cyrus::brush;
using Clock=std::chrono::steady_clock;
double elapsed(Clock::time_point start){return std::chrono::duration<double,std::milli>(Clock::now()-start).count();}
Anchor hitAt(const Surface& surface,double x,double y){
    Hit h;if(!surface.hit({{x,y,100},{0,0,-1}},h))throw std::runtime_error("Probe ray missed");return h.anchor;
}
int main(){
    const Surface surface({{{-100,-100,0},{100,-100,0},{100,100,0},{-100,100,0}},{{{0,1,2}},{{0,2,3}}}});
    std::vector<Anchor> candidates;
    for(unsigned y=0;y<100;++y)for(unsigned x=0;x<100;++x)candidates.push_back(hitAt(surface,-99.+2.*x,-99.+2.*y));
    std::cout<<"case,strokes,candidates,build_ms,query_ms,append_full_rebuild_ms,serialized_bytes,reference_queries,max_reference_error\n"<<std::setprecision(9);
    for(bool overlap:{false,true})for(unsigned count:{10u,100u,1000u}){
        Document doc{surface.fingerprint(),{}};
        for(unsigned i=0;i<count;++i){
            Stroke stroke;stroke.id=i+1;stroke.radius=overlap?20:2;stroke.strength=.3;stroke.erase=i%4==3;
            Sample sample;sample.view={{0,0,100},{0,0,-1},false};
            sample.anchor=hitAt(surface,overlap?0.:-96+6.*(i%32),overlap?0.:-96+6.*(i/32));
            stroke.samples={sample};doc.strokes.push_back(stroke);
        }
        auto start=Clock::now();Field field(surface,doc);const auto buildMs=elapsed(start);
        start=Clock::now();std::vector<double> weights;weights.reserve(candidates.size());
        for(auto anchor:candidates)weights.push_back(field.evaluate(anchor));
        const auto queryMs=elapsed(start);
        double maxError=0;unsigned referenceQueries=0;
        // Stratified positions plus center exercise both painted and empty areas.
        for(std::size_t i=0;i<candidates.size();i+=157){maxError=std::max(maxError,std::abs(weights[i]-field.evaluateReference(candidates[i])));++referenceQueries;}
        const auto center=hitAt(surface,0,0);maxError=std::max(maxError,std::abs(field.evaluate(center)-field.evaluateReference(center)));++referenceQueries;
        if(maxError>1e-9)throw std::runtime_error("History replay oracle mismatch");
        auto extra=doc.strokes.back();extra.id=count+1;doc.strokes.push_back(extra);
        start=Clock::now();Field appended(surface,doc);double checksum=0;
        for(auto anchor:candidates)checksum+=appended.evaluate(anchor);
        const auto appendMs=elapsed(start);
        if(!std::isfinite(checksum))throw std::runtime_error("Invalid field sum");
        doc.strokes.pop_back();
        std::cout<<(overlap?"overlapping":"distributed")<<','<<count<<','<<candidates.size()<<','<<buildMs<<','<<queryMs<<','<<appendMs<<','<<encode(doc).size()<<','<<referenceQueries<<','<<maxError<<'\n';
    }
}
