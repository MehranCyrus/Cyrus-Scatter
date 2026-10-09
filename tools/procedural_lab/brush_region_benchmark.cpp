// CPU-only coverage witness. This does not measure Max input, drawing or FPS.
#include "brush.h"
#include <chrono>
#include <cmath>
#include <iomanip>
#include <iostream>
#include <stdexcept>
using namespace cyrus::brush;
using Clock=std::chrono::steady_clock;
double elapsed(Clock::time_point start){return std::chrono::duration<double,std::milli>(Clock::now()-start).count();}
int main(){
    Surface surface({{{-100,-100,0},{100,-100,0},{100,100,0},{-100,100,0}},{{{0,1,2}},{{0,2,3}}}});
    std::vector<Anchor> points;std::vector<double> expected;
    for(int y=0;y<100;++y)for(int x=0;x<100;++x){
        const double px=-99+2*x,py=-99+2*y;Hit hit;
        if(!surface.hit({{px,py,100},{0,0,-1}},hit))throw std::runtime_error("Missing receiver hit");
        points.push_back(hit.anchor);expected.push_back(px*px+py*py<400?1.:0.);
    }
    Hit center;surface.hit({{0,0,100},{0,0,-1}},center);
    Stroke stroke;stroke.radius=20;stroke.strength=1;stroke.softness=0;
    Sample sample;sample.anchor=center.anchor;sample.view={{0,0,100},{0,0,-1},false};stroke.samples={sample};
    std::cout<<"repeat,strokes,build_ms,query_ms,accepted,max_error\n"<<std::setprecision(10);
    for(int repeat=0;repeat<4;++repeat)for(int count:{1,10,100,1000}){
        Document document{surface.fingerprint(),std::vector<Stroke>(count,stroke)};
        auto start=Clock::now();Field field(surface,document);const auto build=elapsed(start);
        start=Clock::now();double error=0;int accepted=0;
        for(std::size_t i=0;i<points.size();++i){const auto value=field.evaluate(points[i]);error=std::max(error,std::abs(value-expected[i]));accepted+=value>0;}
        const auto query=elapsed(start);if(error>1e-9)throw std::runtime_error("Coverage changed");
        std::cout<<repeat<<','<<count<<','<<build<<','<<query<<','<<accepted<<','<<error<<'\n';
    }
}
