#include "spline_export.h"
#include <cmath>
#include <iostream>
#include <stdexcept>

using namespace cyrus::spline_export;
static void check(bool value,const char* reason){if(!value)throw std::runtime_error(reason);}
static std::vector<amin::Vec3> circle(std::size_t count,double radius=10){
    std::vector<amin::Vec3> out;out.reserve(count);
    for(std::size_t i=0;i<count;++i){const double a=6.2831853071795864769*double(i)/double(count);out.push_back({radius*std::cos(a),radius*std::sin(a),0});}return out;
}
static Loops selected(const Loops& source,const Result& result){
    Loops out;for(std::size_t r=0;r<source.size();++r){out.emplace_back();for(auto i:result.indices[r])out.back().push_back(source[r][i]);}return out;
}
int main(){try{
    const Loops source{circle(1024)};const auto result=optimize(source,.05);
    check(result.optimized&&result.output<result.input/2,"Dense planar circle did not reduce");
    check(certify(source,selected(source,result),result,.05)<=.05,"Published certificate exceeded tolerance");
    check(optimize(source,.05).indices==result.indices,"Export is not deterministic");
    auto rounded=selected(source,result);rounded[0][0].x+=.1;bool rejected=false;
    try{certify(source,rounded,result,.05);}catch(const std::runtime_error&){rejected=true;}
    check(rejected,"Host rounding beyond tolerance was accepted");
    Loops holes{circle(512,20),circle(512,2)};std::reverse(holes[1].begin(),holes[1].end());
    const auto nested=optimize(holes,.01);check(nested.optimized&&nested.indices.size()==2,"Nested hole reduction failed");
    certify(holes,selected(holes,nested),nested,.01);
    auto curved=source;curved[0][10].z=1;check(!optimize(curved,.05).optimized,"Nonplanar boundary was straightened");
    Loops touching{{{0,0,0},{10,0,0},{10,10,0},{0,10,0}},{{0,0,0},{-2,0,0},{-2,-2,0},{0,-2,0}}};
    check(!optimize(touching,.1).optimized,"Touching contours received an unsafe certificate");
    Limits work;work.work=1;const auto exhausted=optimize(source,.05,work);
    check(!exhausted.optimized&&exhausted.output==exhausted.input,"Exhaustion did not retain Exact geometry");
    const auto large=optimize(Loops{circle(200000)},.05);
    check(large.work<=50000000&&large.output<=200000,"Canonical maximum was unbounded");
    rejected=false;try{optimize(source,0);}catch(const std::invalid_argument&){rejected=true;}check(rejected,"Zero tolerance accepted");
    std::cout<<"PASS deterministic closed contours, holes, final rounding, topology, curved fallback and bounded 200k input\n";
    return 0;
}catch(const std::exception& e){std::cerr<<e.what()<<'\n';return 1;}}
