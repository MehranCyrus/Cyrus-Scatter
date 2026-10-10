// Same workload can link to the checkpoint or current native library.
// CPU preparation only; no claim about mouse latency or presented FPS.
#include "brush.h"
#include <chrono>
#include <iostream>
#include <memory>
#include <stdexcept>
using namespace cyrus::brush;
using Clock=std::chrono::steady_clock;
int main(){
    Mesh mesh;constexpr unsigned side=100;
    for(unsigned y=0;y<=side;++y)for(unsigned x=0;x<=side;++x)mesh.vertices.push_back({double(x),double(y),0});
    for(unsigned y=0;y<side;++y)for(unsigned x=0;x<side;++x){auto a=y*(side+1)+x,b=a+1,c=a+side+1,d=c+1;mesh.faces.push_back({a,b,d});mesh.faces.push_back({a,d,c});}
    Surface surface(std::move(mesh));
    std::cout<<"strokes,faces,build_ms,append_ms,max_error\n";
    for(unsigned count:{100u,1000u,3000u}){
        Document doc{surface.fingerprint(),{}};
        for(unsigned i=0;i<count;++i){Hit h;if(!surface.hit({{2.+(i%32)*3.,2.+((i/32)%32)*3.,100},{0,0,-1}},h))throw std::runtime_error("Miss");
            Stroke stroke;stroke.id=i+1;stroke.radius=2;stroke.strength=.3;stroke.softness=.6;stroke.erase=i%4==3;
            Sample sample;sample.anchor=h.anchor;sample.view={{0,0,100},{0,0,-1},false};stroke.samples={sample};doc.strokes.push_back(stroke);}
        for(int repeat=0;repeat<5;++repeat){
            auto start=Clock::now();Field field(surface,doc);
            const auto build=std::chrono::duration<double,std::milli>(Clock::now()-start).count();
            auto extra=doc.strokes.back();extra.id=count+1;doc.strokes.push_back(extra);
            start=Clock::now();Field appended(surface,doc,&field);
            const auto append=std::chrono::duration<double,std::milli>(Clock::now()-start).count();
            double error=0;
            for(unsigned f=0;f<surface.mesh().faces.size();f+=211){Anchor a{f,{.2,.3,.5}};error=std::max(error,std::abs(appended.evaluate(a)-appended.evaluateReference(a)));}
            if(error>1e-9)throw std::runtime_error("Replay mismatch");
            doc.strokes.pop_back();std::cout<<count<<','<<surface.mesh().faces.size()<<','<<build<<','<<append<<','<<error<<'\n';
        }
    }
}
