#include "mesh_density.h"
#include <cmath>
#include <iostream>
#include <limits>
#include <stdexcept>

using namespace cyrus::mesh_density;
void require(bool pass){if(!pass)throw std::runtime_error("Mesh density test failed");}
template<class F>void rejects(F f){bool rejected=false;try{f();}catch(const std::invalid_argument&){rejected=true;}require(rejected);}
int main(){
    Settings s;s.enabled=true;validate(s);
    require(weight(-1,s)==0&&weight(2,s)==1&&weight(.5,s)==.5);
    require(sample({.3,.3,.3},{.33333334,.33333334,.33333334})==.3);
    require(std::abs(sample({0,1,.5},{.2,.3,.5})-.55)<1e-12);
    s.minimum=-2;s.maximum=2;require(weight(0,s)==.5);
    s.invert=true;require(weight(-2,s)==1&&weight(2,s)==0);
    s.curve={0,1,0};require(weight(0,s)==1&&weight(-2,s)==0);
    require(!accepts(0,42,1,9)&&accepts(1,42,1,9));
    unsigned count=0;for(unsigned i=0;i<100000;++i){
        const bool a=accepts(.25,42,i,9);require(a==accepts(.25,42,i,9));
        require(!a||accepts(.75,42,i,9));count+=a;
    }require(count>24000&&count<26000);
    auto bad=s;bad.minimum=bad.maximum;rejects([&]{validate(bad);});
    bad=s;bad.channel=-1;rejects([&]{validate(bad);});bad.channel=100;rejects([&]{validate(bad);});
    bad=s;bad.component=3;rejects([&]{validate(bad);});
    bad=s;bad.curve={0};rejects([&]{validate(bad);});
    bad=s;bad.curve={0,1.1};rejects([&]{validate(bad);});
    bad=s;bad.curve={0,std::numeric_limits<double>::quiet_NaN()};rejects([&]{validate(bad);});
    rejects([&]{weight(std::numeric_limits<double>::infinity(),s);});
    rejects([&]{sample({0,1,0},{0,2,-1});});
    std::cout<<"Mesh density analytic, stable eligibility and invalid input checks passed\n";
}
