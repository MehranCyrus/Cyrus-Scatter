#include "source_measurement.h"
#include "source_scale.h"
#include <iostream>
#include <string>
using namespace cyrus::source_measurement;
namespace {
int checks=0;
void check(bool value){++checks;if(!value)throw std::runtime_error("Source measurement assertion "+std::to_string(checks));}
template<class F>void rejected(F f){bool failed=false;try{f();}catch(const std::exception&){failed=true;}check(failed);}
}
int main(){try{
    storage(1000000,2000000,1000000,2000000);
    rejected([]{storage(1000001,1,1000001,2000000);});rejected([]{storage(1,2000001,1000000,2000001);});
    rejected([]{storage(10,20,9,20);});rejected([]{storage(10,20,10,19);});rejected([]{storage(0,1,10,10);});
    index(9,10);rejected([]{index(10,10);});
    Bounds bounds;bounds.add({-3,4,-12});bounds.add({6,-8,2});
    check(bounds.minimum==Point{-3,-8,-12}&&bounds.maximum==Point{6,4,2}&&bounds.count==2);
    check(bounds.radiusXY==10&&bounds.radiusXYZ==13);
    // Pivot-relative radius includes displacement from the origin; AABB half-width
    // is not a valid replacement for off-centre source geometry.
    Bounds offset;offset.add({10,0,0});offset.add({11,0,1});check(offset.radiusXY==11);
    rejected([]{Bounds b;b.add({std::numeric_limits<double>::quiet_NaN(),0,0});});
    rejected([]{Bounds b;b.add({0,std::numeric_limits<double>::infinity(),0});});
    rejected([]{Bounds b;b.add({0,0,1000001});});
    Bounds maximum;maximum.add({-1000000,1000000,1000000});check(std::isfinite(maximum.radiusXYZ));
    using cyrus::source_scale::Axes;using cyrus::source_scale::factors;using cyrus::source_scale::compose;
    const Axes identity{{{{1,0,0}},{{0,1,0}},{{0,0,1}}}};
    check(factors(identity)==std::array<double,3>{1,1,1});
    const Axes rotated{{{{0,.01,0}},{{-.01,0,0}},{{0,0,.01}}}};
    check(factors(rotated)==std::array<double,3>{.01,.01,.01});
    const auto small=compose(factors(rotated),3);for(float x:small)check(std::abs(x-.03f)<1e-8f);
    const Axes nonuniform{{{{0,2,0}},{{-3,0,0}},{{0,0,4}}}};
    check(compose(factors(nonuniform),.5)==std::array<float,3>{1,1.5,2});
    auto invalid=identity;invalid[0][0]=-1;rejected([&]{factors(invalid);});
    invalid=identity;invalid[0][0]=0;rejected([&]{factors(invalid);});
    invalid=identity;invalid[0][1]=.01;rejected([&]{factors(invalid);});
    invalid=identity;invalid[2][2]=std::numeric_limits<double>::quiet_NaN();rejected([&]{factors(invalid);});
    rejected([&]{compose({1,1,1},-1);});rejected([&]{compose({1e30,1e30,1e30},1e30);});
    check(compose({.01,.01,.01},0)==std::array<float,3>{0,0,0});
    std::cout<<"PASS: "<<checks<<" source measurement checks; finite physical bounds, pivot radii, indices and independent admission\n";return 0;
}catch(const std::exception& error){std::cerr<<error.what()<<'\n';return 1;}}
