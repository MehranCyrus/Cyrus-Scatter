#include "density_image.h"
#include "asset_bitmap.h"
#include <cmath>
#include <iostream>
#include <limits>
#include <stdexcept>

using namespace cyrus::density;
namespace {
void check(bool ok,const char* text){if(!ok)throw std::runtime_error(text);}
void close(double a,double b,const char* text){check(std::abs(a-b)<1e-10,text);}
template<class F> void rejects(F f){bool threw=false;try{f();}catch(const std::invalid_argument&){threw=true;}check(threw,"expected validation rejection");}
}
int main(){try {
    const std::vector<double> ramp{0,1,0,1};Mapping m;
    ImageSampler legacy(ramp,2,2,m);
    close(legacy.sample(.25,.8,0,0,0),.25,"clamped interpolation");
    close(legacy.sample(-3,.2,0,0,0),0,"clamp lower");
    close(legacy.sample(8,.2,0,0,0),1,"clamp upper");
    m.wrapping=Wrapping::Repeat;ImageSampler periodic(ramp,2,2,m);
    for(double x:{-7.2,-1.01,-.001,0.,.24,.7,.999,3.25}){
        close(periodic.sample(x,.27,0,0,0),periodic.sample(x+4,.27,0,0,0),"negative/positive wrapping");
        close(periodic.sample(x,.27,0,0,0),periodic.sample(x,3.27,0,0,0),"vertical wrapping");
    }
    close(periodic.sample(0,.5,0,0,0),.5,"seam bilinear wrap");
    close(periodic.sample(.25,.5,0,0,0),0,"first texel centre");
    close(periodic.sample(.75,.5,0,0,0),1,"second texel centre");
    m.coordinates=Coordinates::World;m.sizeX=4;m.sizeY=7;
    ImageSampler world(ramp,2,2,m);
    close(world.sample(0,0,3,1,10),1,"world size independently of receiver UVs");
    close(world.sample(.9,.8,3,1,-10),1,"world XY independent of UV and height");
    close(world.sample(0,0,-1,8,0),1,"world repeat negative size");
    m.offsetX=2;m.rotation=90;ImageSampler rotated(ramp,2,2,m);
    close(rotated.sample(0,0,2,3,0),1,"inverse rotation and physical offset");
    m.coordinates=Coordinates::Local;m.rotation=0;m.offsetX=0;m.worldToFrame[9]=-10;
    ImageSampler local(ramp,2,2,m);close(local.sample(0,0,13,1,0),1,"copied local frame");
    m=Mapping{};m.curve={0,.25,1};ImageSampler curve(ramp,2,2,m);
    close(curve.sample(.5,.5,0,0,0),.25,"response follows interpolation");
    const std::vector<double> one{.37};ImageSampler constant(one,1,1,Mapping{});
    close(constant.sample(1,0,0,0,0),.37,"one pixel clamp");
    rejects([&]{auto bad=m;bad.sizeX=0;ImageSampler s(ramp,2,2,bad);});
    rejects([&]{auto bad=m;bad.worldToFrame[2]=INFINITY;ImageSampler s(ramp,2,2,bad);});
    rejects([&]{ImageSampler s(ramp,2,3,m);});
    rejects([&]{ImageSampler s(std::vector<double>{NAN},1,1,m);});
    rejects([&]{legacy.sample(NAN,0,0,0,0);});
    // A receiver map is a valid authored mode, but must never silently become a
    // context-free tile in a worker or portable image path.
    auto receiver=m;receiver.coordinates=Coordinates::Map;validate(receiver);
    rejects([&]{ImageSampler sampled(ramp,2,2,receiver);});
    const auto png=encodeLinearPNG({2,2,{0.,.2,.65,1.}});
    const auto info=cyrus::assets::inspectPNG(png);
    check(info.width==2&&info.height==2&&png[24]==16&&png[25]==2,"Linear scalar snapshot is a valid portable 16-bit RGB PNG");
    rejects([&]{encodeLinearPNG({1,1,{NAN}});});
    rejects([&]{encodeLinearPNG({513,1,std::vector<double>(513)});});
    std::cout<<"PASS: image mapping, wrapping/seams, frames, units, response and validation\n";
}catch(const std::exception& e){std::cerr<<e.what()<<'\n';return 1;}return 0;}
