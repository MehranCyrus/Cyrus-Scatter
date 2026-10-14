#include "surface_filter.h"
#include <algorithm>
#include <cmath>
#include <iostream>
#include <limits>
#include <stdexcept>
#include <vector>

namespace sf=cyrus::surface_filter;
void require(bool ok,const char* message){if(!ok)throw std::runtime_error(message);}
template<class F> void rejects(F f){bool failed=false;try{f();}catch(const std::invalid_argument&){failed=true;}require(failed,"Expected invalid input rejection");}
void close(double a,double b){require(std::abs(a-b)<1e-10,"Analytic value mismatch");}
int main(){try{
    sf::Settings s;
    s.slope={true,10,70,10,20};sf::validate(s);
    for(const auto pair:std::vector<std::pair<double,double>>{{0,0},{10,0},{12.5,.15625},{15,.5},{20,1},{40,1},{50,1},{60,.5},{65,.15625},{70,0},{80,0}})
        close(sf::intervalWeight(pair.first,s.slope),pair.second);
    s.slope={true,10,70,0,0};sf::validate(s);
    close(sf::intervalWeight(10,s.slope),1);close(sf::intervalWeight(70,s.slope),1);
    close(sf::intervalWeight(std::nextafter(10.0,0.0),s.slope),0);
    close(sf::intervalWeight(std::nextafter(70.0,100.0),s.slope),0);
    s.altitude={true,-5,-5,0,0};sf::validate(s);
    close(sf::intervalWeight(-5,s.altitude),1);close(sf::intervalWeight(-5.001,s.altitude),0);
    s.altitude.lowerFade=1;rejects([&]{sf::validate(s);});s.altitude.enabled=false;
    for(auto bad:std::vector<sf::Interval>{{true,70,10,0,0},{true,-1,20,0,0},{true,0,181,0,0},{true,0,10,6,5},{true,0,10,-1,0},{true,0,10,0,-1},{true,0,10,INFINITY,0},{true,NAN,10,0,0}}){s.slope=bad;rejects([&]{sf::validate(s);});}
    s.slope={true,0,10,5,5};sf::validate(s);close(sf::intervalWeight(5,s.slope),1);
    rejects([&]{sf::intervalWeight(NAN,s.slope);});
    s.slope={false,NAN,-INFINITY,-1,INFINITY};s.altitude.enabled=false;sf::validate(s);
    require(sf::accepts(s,NAN,NAN,42,10,20),"Disabled filters must be neutral");
    for(double angle:{0.,15.,30.,45.,60.,90.,120.,150.,180.}){
        const double r=angle*std::acos(-1.)/180.;
        amin::Triangle t{{0,0,0},{1,0,0},{0,std::cos(r),std::sin(r)}};
        close(sf::slopeDegrees(t),angle);
        std::swap(t.b,t.c);close(sf::slopeDegrees(t),180-angle);
        t.a=t.a*1e150;t.b=t.b*1e150;t.c=t.c*1e150;close(sf::slopeDegrees(t),180-angle);
        t.a=t.a*1e-300;t.b=t.b*1e-300;t.c=t.c*1e-300;close(sf::slopeDegrees(t),180-angle);
    }
    rejects([]{sf::slopeDegrees({{0,0,0},{1,1,1},{2,2,2}});});
    const amin::Vec3 roundedBary{double(.1f),double(.3f),double(.6f)};
    require(sf::anchorAltitude({{0,0,120},{10,0,120},{0,10,120}},roundedBary)==120,
            "Flat altitude endpoints must not depend on float barycentric sum rounding");
    close(sf::anchorAltitude({{0,0,120},{10,0,130},{0,10,140}},{.5,.25,.25}),127.5);
    sf::Settings units;units.altitude={true,-100,200,40,60};sf::validate(units);
    auto meters=units;meters.altitude.minimum/=100;meters.altitude.maximum/=100;meters.altitude.lowerFade/=100;meters.altitude.upperFade/=100;
    for(double z=-150;z<250;z+=.73)close(sf::intervalWeight(z,units.altitude),sf::intervalWeight(z/100,meters.altitude));
    // Independent probability oracle: two half-strength filters have ~1/4 eligibility.
    s.slope={true,0,20,10,0};s.altitude={true,0,20,10,0};sf::validate(s);
    std::size_t kept=0,changedReceiver=0;
    for(std::uint64_t i=0;i<100000;++i){
        const bool a=sf::accepts(s,5,5,42,i,700);
        require(a==sf::accepts(s,5,5,42,i,700),"Eligibility must be repeatable");
        kept+=a;changedReceiver+=a!=sf::accepts(s,5,5,42,i,701);
    }
    require(kept>24400&&kept<25600,"Joint fade probability is not multiplicative");
    require(changedReceiver>30000,"Receiver eligibility channel is not independent");
    // Filtering a real candidate prefix never changes its source or transform.
    const std::vector<amin::Triangle> mesh{{{0,0,0},{100,0,0},{0,100,100}}};
    amin::Settings generation;generation.count=10000;generation.sourceCount=3;generation.receiverSalt=71;
    generation.axisScale={{{.5,2},{.7,1.4},{.8,1.8}}};
    const auto all=amin::scatter(mesh,generation);
    sf::Settings heights;heights.altitude={true,20,60,10,10};sf::validate(heights);
    std::vector<amin::Instance> filtered;
    for(const auto& p:all)if(sf::accepts(heights,45,p.position.z,generation.seed,p.candidateKey,generation.receiverSalt))filtered.push_back(p);
    require(!filtered.empty()&&filtered.size()<all.size(),"Real candidate filtering did not thin");
    generation.count=5000;const auto prefix=amin::scatter(mesh,generation);
    for(const auto& p:filtered)if(p.candidateKey<prefix.size()){
        const auto& q=prefix[p.candidateKey];
        require(p.source==q.source&&p.position.x==q.position.x&&p.position.y==q.position.y&&p.position.z==q.position.z&&p.scale==q.scale&&
            p.xAxis.x==q.xAxis.x&&p.xAxis.y==q.xAxis.y&&p.xAxis.z==q.xAxis.z&&p.yAxis.x==q.yAxis.x&&p.yAxis.y==q.yAxis.y&&p.yAxis.z==q.yAxis.z&&
            p.zAxis.x==q.zAxis.x&&p.zAxis.y==q.zAxis.y&&p.zAxis.z==q.zAxis.z,"Surviving candidate changed");
        require(p.position.z>=20&&p.position.z<=60,"Filtered candidate outside height interval");
    }
    std::cout<<"surface filter analytic, bounds, units, probability and candidate stability passed\n";
    return 0;
}catch(const std::exception& e){std::cerr<<e.what()<<'\n';return 1;}}
