#pragma once
#include "scatter.h"
#include <algorithm>
#include <cmath>
#include <stdexcept>

// Shared exact XY include/exclude predicate for generation and field visualization.
namespace amin {
struct AreaMask {
    const Area& area;
    double x0{INFINITY}, y0{INFINITY}, x1{-INFINITY}, y1{-INFINITY};
    explicit AreaMask(const Area& a):area(a) {
        if(a.loops.empty()) throw std::invalid_argument("Empty area");
        for(const auto& loop:a.loops) {
            if(loop.size()<3) throw std::invalid_argument("Area needs a closed polygon");
            double twiceArea=0;
            for(std::size_t i=0;i<loop.size();++i) {
                auto p=loop[i],q=loop[(i+1)%loop.size()];
                if(!std::isfinite(p.x)||!std::isfinite(p.y)||!std::isfinite(p.z)) throw std::invalid_argument("Nonfinite area");
                x0=std::min(x0,p.x);x1=std::max(x1,p.x);y0=std::min(y0,p.y);y1=std::max(y1,p.y);
                twiceArea+=p.x*q.y-q.x*p.y;
            }
            if(std::abs(twiceArea)<1e-12) throw std::invalid_argument("Area has no XY footprint");
        }
    }
    bool contains(Vec3 p) const {
        if(p.x<x0||p.x>x1||p.y<y0||p.y>y1) return false;
        bool inside=false;
        for(const auto& loop:area.loops) for(std::size_t i=0,j=loop.size()-1;i<loop.size();j=i++) {
            const auto a=loop[j],b=loop[i];
            const double dx=b.x-a.x,dy=b.y-a.y;
            if(std::abs(dx*(p.y-a.y)-dy*(p.x-a.x))<=1e-10*std::max(1.0,std::hypot(dx,dy)) &&
                p.x>=std::min(a.x,b.x)&&p.x<=std::max(a.x,b.x)&&p.y>=std::min(a.y,b.y)&&p.y<=std::max(a.y,b.y)) return true;
            if((a.y>p.y)!=(b.y>p.y) && p.x<a.x+(p.y-a.y)*dx/dy) inside=!inside;
        }
        return inside;
    }
};
}
