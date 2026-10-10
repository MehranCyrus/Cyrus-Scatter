#pragma once
#include "lab.h"
inline paintlab::Mesh plane(){return{{{-500,-500,0},{500,-500,0},{500,500,0},{-500,500,0}},{{0,1,2},{0,2,3}}};}
inline paintlab::Anchor anchor(double x,double y){double u=(x+500)/1000,v=(y+500)/1000;return y<=x?paintlab::Anchor{0,{1-u,u-v,v}}:paintlab::Anchor{1,{1-v,u,v-u}};}
inline paintlab::Hit hit(double x,double y,double radius,bool connected=false){return{anchor(x,y),{x,y,0},radius,connected};}
inline void stroke(paintlab::Session& s,double x,double y,double r,bool erase=false,double strength=1,double softness=0){s.begin({erase,strength,softness});s.append(hit(x,y,r));s.commit();}
