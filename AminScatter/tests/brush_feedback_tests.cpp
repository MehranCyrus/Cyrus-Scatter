#include "brush.h"
#include <iostream>
#include <stdexcept>
using namespace cyrus::brush;
int main(){try{
 Surface s({{{-100,-100,0},{100,-100,0},{100,100,0},{-100,100,0}},{{0,1,2},{0,2,3}}});
 Document d;d.surface=s.fingerprint();Point a{-70,0},b{70,0};d=paint(d,a,5,false);d=paint(d,b,5,false,{},&a);
 Field field(s,d);for(int x=-70;x<=70;++x)if(field.queryPoint({double(x),0}).density!=1)throw std::runtime_error("sweep gap");
 auto saved=encode(d);auto lines=boundary(s,d);if(lines.empty())throw std::runtime_error("missing border");
 bool rejected=false;try{boundary(s,d,1);}catch(const std::exception&){rejected=true;}if(!rejected||encode(d)!=saved)throw std::runtime_error("feedback failed atomicity");
 d=paint(d,{0,0},10,true);Field erased(s,d);if(erased.queryPoint({0,0}).density!=0||erased.queryPoint({50,0}).density!=1)throw std::runtime_error("erase locality");
 Hit hit,oracle;if(!s.hit({{0,0,10},{0,0,-1}},hit)||!s.hitReference({{0,0,10},{0,0,-1}},oracle)||hit.distance!=oracle.distance)throw std::runtime_error("picking");
 std::cout<<"PASS vector sweep, local erase, feedback bounds, BVH picking\n";return 0;
 }catch(const std::exception& e){std::cerr<<e.what()<<"\n";return 1;}}
