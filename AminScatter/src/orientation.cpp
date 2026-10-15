#include "orientation.h"
#include <algorithm>
#include <cmath>
#include <stdexcept>

namespace cyrus::orientation {
using amin::Vec3;
namespace {
bool finite(Vec3 a){return std::isfinite(a.x)&&std::isfinite(a.y)&&std::isfinite(a.z);}
double magnitude(Vec3 a){return std::max({std::abs(a.x),std::abs(a.y),std::abs(a.z)});}
void require(bool ok,const char* why){if(!ok)throw std::invalid_argument(why);}
Vec3 cross(Vec3 a,Vec3 b){return {a.y*b.z-a.z*b.y,a.z*b.x-a.x*b.z,a.x*b.y-a.y*b.x};}
Vec3 unit(Vec3 a){
    require(finite(a),"Orientation vector is nonfinite");
    const double scale=magnitude(a);
    require(scale>0,"Orientation vector is zero");a={a.x/scale,a.y/scale,a.z/scale};
    return a*(1/std::sqrt(amin::dot(a,a)));
}
Frame randomFrame(Vec3 up){
    const Vec3 reference=std::abs(up.z)<.999?Vec3{0,0,1}:Vec3{0,1,0};
    const auto x=unit(cross(reference,up));return {x,cross(up,x),up};
}
Vec3 correctForward(Vec3 v,int axis){
    switch(axis){case 1:return v;case 2:return {-v.x,-v.y,v.z};case 3:return {-v.y,v.x,v.z};case 4:return {v.y,-v.x,v.z};}
    throw std::invalid_argument("Unsupported source forward axis");
}
}
void validate(const Settings& s){
    require(s.mode==Mode::Random||s.mode==Mode::WorldDirection||s.mode==Mode::Target,"Unknown orientation mode");
    require(std::isfinite(s.normalBlend)&&s.normalBlend>=0&&s.normalBlend<=1,"Normal blend must be 0..1");
    if(s.mode==Mode::WorldDirection)(void)unit(s.direction);
    if(s.mode==Mode::Target)require(finite(s.target),"Target position is nonfinite");
}
std::vector<Vec3> normals(const std::vector<amin::Triangle>& triangles){
    require(triangles.size()<=maxFaces,"Orientation surface exceeds ten million faces");
    std::vector<Vec3> result;result.reserve(triangles.size());
    for(const auto& t:triangles){
        require(finite(t.a)&&finite(t.b)&&finite(t.c),"Orientation surface is nonfinite");
        auto a=t.b-t.a,b=t.c-t.a;
        require(finite(a)&&finite(b),"Orientation surface edge overflows");
        if(magnitude(a)==0||magnitude(b)==0){result.push_back({});continue;}
        auto n=cross(unit(a),unit(b));
        result.push_back(magnitude(n)>0?unit(n):Vec3{});
    }
    return result;
}
Vec3 blendedUp(Vec3 normal,double blend){
    require(std::isfinite(blend)&&blend>=0&&blend<=1,"Normal blend must be 0..1");
    if(blend==0)return {0,0,1};
    const auto n=unit(normal);if(blend==1)return n;
    const double angle=std::acos(std::clamp(n.z,-1.,1.));
    const double tangentLength=std::hypot(n.x,n.y);
    const Vec3 tangent=tangentLength>1e-15?Vec3{n.x/tangentLength,n.y/tangentLength,0}:Vec3{1,0,0};
    return tangent*std::sin(angle*blend)+Vec3{0,0,std::cos(angle*blend)};
}
Frame frame(Vec3 normal,Vec3 position,const Settings& s){
    validate(s);require(finite(position),"Orientation position is nonfinite");
    const Vec3 up=s.align?blendedUp(normal,s.normalBlend):Vec3{0,0,1};
    if(s.mode==Mode::Random)return randomFrame(up);
    const auto direction=s.mode==Mode::WorldDirection?s.direction:s.target-position;
    require(finite(direction),"Target direction overflows");
    if(direction.x==0&&direction.y==0&&direction.z==0)return randomFrame(up);
    const auto y=unit(direction);auto x=cross(y,up);
    if(amin::dot(x,x)<1e-20)x=cross(y,std::abs(y.z)<.999?Vec3{0,0,1}:Vec3{0,1,0});
    x=unit(x);return {x,y,cross(x,y)};
}
amin::Instance orient(const amin::Instance& input,Vec3 normal,const Settings& s,int axis){
    auto row=input;
    require(finite(row.xAxis)&&finite(row.yAxis)&&finite(row.zAxis),"Orientation input basis is nonfinite");
    const auto basis=frame(normal,row.position,s);
    require(axis>=1&&axis<=4,"Unsupported source forward axis");
    if(s.mode==Mode::Random)axis=1;
    const auto transform=[&](Vec3 v){v=correctForward(v,axis);return basis[0]*v.x+basis[1]*v.y+basis[2]*v.z;};
    row.xAxis=transform(row.xAxis);row.yAxis=transform(row.yAxis);row.zAxis=transform(row.zAxis);
    require(finite(row.xAxis)&&finite(row.yAxis)&&finite(row.zAxis),"Oriented basis overflows");
    return row;
}
std::vector<amin::Instance> apply(const std::vector<amin::Instance>& input,const std::vector<Vec3>& ns,const Settings& s,const std::vector<int>& axes){
    validate(s);require(input.size()<=1000000&&ns.size()<=maxFaces,"Orientation work limit exceeded");
    for(int axis:axes)require(axis>=1&&axis<=4,"Unsupported source forward axis");
    auto result=input;
    for(auto& row:result){
        Vec3 normal{0,0,1};
        if(s.align&&s.normalBlend>0){require(row.triangle<ns.size(),"Orientation face is missing");normal=ns[row.triangle];}
        int axis=1;
        if(s.mode!=Mode::Random){require(row.source<axes.size(),"Orientation source axis is missing");axis=axes[row.source];}
        row=orient(row,normal,s,axis);
    }
    return result;
}
}
