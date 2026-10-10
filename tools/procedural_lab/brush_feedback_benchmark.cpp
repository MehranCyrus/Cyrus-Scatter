// Compile against the current amin_scatter static library, Release /O2.
// CPU field/coverage benchmark; does not measure viewport presentation.
#include "brush.h"
#include <chrono>
#include <iostream>
#include <stdexcept>
using namespace cyrus::brush;
using Clock=std::chrono::steady_clock;
double elapsed(Clock::time_point t){return std::chrono::duration<double,std::milli>(Clock::now()-t).count();}
int main(){
 Mesh mesh;mesh.vertices={{0,0,0},{20,0,0},{20,20,0},{0,20,0}};mesh.faces={{0,1,2},{0,2,3}};Surface surface(mesh);
 Hit hit;surface.hit({{10,10,100},{0,0,-1}},hit);Sample sample;sample.anchor=hit.anchor;sample.view={{0,0,100},{0,0,-1},false};
 std::cout<<"kind,strokes,repeat,prepare_ms,reference_ms,cached_ms,triangles,query_reference_ms,query_decision_ms,reference_dabs,decision_dabs\n";
 for(bool soft:{false,true}){
  Document document{surface.fingerprint(),{}};CoverageCache cache;std::unique_ptr<Field> previous;
  Stroke stroke;stroke.radius=4;stroke.strength=soft?.3:1;stroke.softness=soft?.6:0;stroke.samples={sample};
  for(unsigned i=1;i<=1003;++i){
   stroke.id=i;document.strokes.push_back(stroke);auto t=Clock::now();auto field=std::make_unique<Field>(surface,document,previous.get());double prepare=elapsed(t);
   t=Clock::now();auto cached=cache.build(surface,*field);double warm=elapsed(t);
   if(i>=1000){
    t=Clock::now();auto reference=coverage(surface,*field);double cold=elapsed(t);
    if(reference.triangles.size()!=cached.triangles.size())throw std::runtime_error("Topology differs");
    for(std::size_t j=0;j<reference.triangles.size();++j){
     if(std::abs(reference.triangles[j].weight-cached.triangles[j].weight)>1e-12)throw std::runtime_error("Weight differs");
     for(int k=0;k<3;++k)if(amin::length(reference.triangles[j].vertices[k]-cached.triangles[j].vertices[k])!=0)throw std::runtime_error("Geometry differs");
    }
    QueryStats exact,decision;std::vector<bool> expected;t=Clock::now();for(unsigned j=0;j<2048;++j)expected.push_back(threshold(77,j)<field->evaluate(hit.anchor,&exact));double q=elapsed(t);
    t=Clock::now();for(unsigned j=0;j<2048;++j)if(expected[j]!=field->accepts(hit.anchor,threshold(77,j),1,&decision))throw std::runtime_error("Membership differs");double fast=elapsed(t);
    std::cout<<(soft?"soft":"opaque")<<','<<i<<','<<i-1000<<','<<prepare<<','<<cold<<','<<warm<<','<<cached.triangles.size()<<','<<q<<','<<fast<<','<<exact.dabs<<','<<decision.dabs<<std::endl;
   }
   previous=std::move(field);
  }
 }
}
