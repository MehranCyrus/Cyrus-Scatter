// Matched CPU preparation experiment. Not Max brush input latency or FPS.
#include "brush.h"
#include <chrono>
#include <cmath>
#include <iostream>
#include <iomanip>
#include <stdexcept>
using namespace cyrus::brush;
using Clock=std::chrono::steady_clock;
double elapsed(Clock::time_point t){return std::chrono::duration<double,std::milli>(Clock::now()-t).count();}
int main(){
    Mesh mesh;constexpr unsigned side=50;
    for(unsigned y=0;y<=side;++y)for(unsigned x=0;x<=side;++x)mesh.vertices.push_back({double(x),double(y),0});
    for(unsigned y=0;y<side;++y)for(unsigned x=0;x<side;++x){auto a=y*(side+1)+x,b=a+1,c=a+side+1,d=c+1;mesh.faces.push_back({a,b,d});mesh.faces.push_back({a,d,c});}
    Surface surface(mesh);Document document{surface.fingerprint(),{}};
    for(unsigned i=0;i<300;++i){Hit hit;surface.hit({{1.+i%48,1.+(i*7)%48,100},{0,0,-1}},hit);Stroke stroke;stroke.id=i+1;stroke.radius=4;stroke.strength=.4;stroke.erase=i%4==0;Sample sample;sample.anchor=hit.anchor;sample.view={{0,0,100},{0,0,-1},false};stroke.samples={sample};document.strokes.push_back(stroke);}
    Field previous(surface,document);auto next=document;next.strokes.push_back(document.strokes[0]);next.strokes.back().id=301;
    std::cout<<"repeat,fresh_ms,reused_ms,compiled,reused,max_error\n"<<std::setprecision(10);
    for(int repeat=0;repeat<6;++repeat){
        double cold,warm;std::unique_ptr<Field> fresh,reused;
        const auto makeFresh=[&](){auto t=Clock::now();fresh=std::make_unique<Field>(surface,next);cold=elapsed(t);};
        const auto makeReused=[&](){auto t=Clock::now();reused=std::make_unique<Field>(surface,next,&previous);warm=elapsed(t);};
        if(repeat%2){makeReused();makeFresh();}else{makeFresh();makeReused();}
        double error=0;
        for(unsigned y=1;y<50;y+=2)for(unsigned x=1;x<50;x+=2){Hit hit;surface.hit({{double(x),double(y),100},{0,0,-1}},hit);error=std::max(error,std::abs(fresh->evaluate(hit.anchor)-reused->evaluate(hit.anchor)));}
        if(error>1e-12||reused->buildStats().compiledStrokes!=1||reused->buildStats().reusedStrokes!=300)throw std::runtime_error("Incremental field parity failed");
        std::cout<<repeat<<','<<cold<<','<<warm<<','<<reused->buildStats().compiledStrokes<<','<<reused->buildStats().reusedStrokes<<','<<error<<'\n';
    }
}
