#pragma once
#include "interactions_geometry.h"
#include <algorithm>
#include <array>
#include <cmath>

namespace cyrus::preparation_view {
using namespace interactions;
// Numeric camera state only. A screen pan must not move the framed orbit pivot.
struct Camera {
    double yaw=.35,pitch=-.20,span=1,extent=1,panRight=0,panUp=0;
    Vec centre{};
    void axes(Vec& right,Vec& up,Vec& forward)const{
        right={std::cos(yaw),std::sin(yaw),0};
        forward={-std::sin(yaw)*std::cos(pitch),std::cos(yaw)*std::cos(pitch),std::sin(pitch)};
        up=cross(right,forward);
    }
    Vec viewCentre()const{Vec right,up,forward;axes(right,up,forward);return add(centre,add(mul(right,panRight),mul(up,panUp)));}
    Vec pixelDelta(double x,double y,int height)const{Vec right,up,forward;axes(right,up,forward);return add(mul(right,x*span/std::max(1,height)),mul(up,-y*span/std::max(1,height)));}
    std::array<double,2> screenPoint(Vec point,int width,int height)const{Vec right,up,forward;axes(right,up,forward);const auto d=sub(point,viewCentre());return {width*.5+dot(d,right)*height/span,height*.5-dot(d,up)*height/span};}
    void panPixels(double x,double y,int height){panRight-=x*span/std::max(1,height);panUp+=y*span/std::max(1,height);}
    void orbitPixels(double x,double y,int height){const auto rate=3.141592653589793/std::max(1,height);yaw=std::remainder(yaw+x*rate,6.283185307179586);pitch=std::clamp(pitch+y*rate,-1.545,1.545);}
    void zoom(double steps,double x,double y,int width,int height){const auto old=span;span=std::clamp(span*std::pow(.85,steps),extent*.02,extent*20);panRight+=(x-width*.5)*(old-span)/std::max(1,height);panUp-=(y-height*.5)*(old-span)/std::max(1,height);}
    void frame(Vec lo,Vec hi,int width,int height){
        centre=mul(add(lo,hi),.5);panRight=panUp=0;extent=std::max({hi.x-lo.x,hi.y-lo.y,hi.z-lo.z,.001});
        Vec right,up,forward;axes(right,up,forward);const auto half=mul(sub(hi,lo),.5);
        const auto horizontal=2*(std::abs(right.x)*half.x+std::abs(right.y)*half.y+std::abs(right.z)*half.z);
        const auto vertical=2*(std::abs(up.x)*half.x+std::abs(up.y)*half.y+std::abs(up.z)*half.z);
        span=std::max({vertical,horizontal*std::max(1,height)/std::max(1,width),.001})*1.15;
    }
};
}
