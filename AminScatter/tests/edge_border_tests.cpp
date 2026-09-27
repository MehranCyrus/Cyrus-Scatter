#include "scatter.h"
#include <cmath>
#include <algorithm>
#include <iostream>
#include <stdexcept>
using namespace amin;
void require(bool x){if(!x)throw std::runtime_error("Edge Border assertion failed");}
int main(){try{
 LineBand b;b.kind=6;b.width=2;b.sources={0};b.boundary.loops={{{0,0,0},{10,0,0},{10,10,0},{0,10,0}}};
 auto p=edgeBorderPoints(b,42);require(p.size()==20);
 for(std::size_t i=0;i<p.size();++i)require(std::abs(length(p[(i+1)%p.size()]-p[i])-2)<1e-8);
 auto other=edgeBorderPoints(b,999);for(std::size_t i=0;i<p.size();++i)require(length(p[i]-other[i])==0);
 b.edgeOffset=1;p=edgeBorderPoints(b,42);require(p.size()==20);for(std::size_t i=0;i<p.size();++i)require(length(p[i]-other[i])==0);
 b.edgeAlongJitter=.3;b.edgeAcrossJitter=.2;auto a=edgeBorderPoints(b,42),c=edgeBorderPoints(b,42),d=edgeBorderPoints(b,43);require(a.size()==20&&c.size()==a.size()&&d.size()==a.size());bool moved=false;
 for(std::size_t i=0;i<a.size();++i){require(length(a[i]-c[i])==0);moved|=length(a[i]-d[i])>1e-8;require(a[i].x>=0&&a[i].x<=10&&a[i].y>=0&&a[i].y<=10);}require(moved);
 b.edgeAlongJitter=0;b.edgeAcrossJitter=0;b.edgeOffset=0;b.boundaryMask={true,false,false,false};require(edgeBorderPoints(b,42).size()==5);b.boundaryMask.clear();
 Settings s;s.linePattern=true;s.lineBands={b};s.sourceCount=1;s.uniformScale={1,1};s.count=0;
 std::vector<Triangle> mesh={{{0,0,0},{10,0,0},{10,10,0}},{{0,0,0},{10,10,0},{0,10,0}}};
 auto rows=scatter(mesh,s);require(rows.size()==20);s.count=100000;auto more=scatter(mesh,s);require(more.size()==rows.size());
 s.relaxEnabled=true;s.relaxSpacing=4;auto relaxed=scatter(mesh,s);require(relaxed.size()==rows.size());for(std::size_t i=0;i<rows.size();++i)require(length(rows[i].position-relaxed[i].position)<1e-7);
 s.relaxEnabled=false;s.collisionEnabled=true;s.collisionRadius=1.1;require(scatter(mesh,s).size()<20);
 b.edgeOffset=600;require(edgeBorderPoints(b,42).size()==20);b.edgeOffset=-600;require(edgeBorderPoints(b,42).size()==20);
 b.edgeOffset=0;b.boundary.loops.push_back({{20,0,0},{30,0,0},{30,10,0},{20,10,0}});require(edgeBorderPoints(b,42).size()==40);
 // Corners must survive awkward spacing and jitter, including concave vertices.
 b.boundary.loops={{{0,0,0},{10,0,0},{10,4,0},{4,4,0},{4,10,0},{0,10,0}}};b.width=3.7;b.edgeKeepCorners=true;b.edgeCornerAngle=45;b.edgeCornerCount=1;b.edgeAlongJitter=.5;b.edgeAcrossJitter=.2;
 auto corners=edgeBorderPoints(b,42);for(auto v:b.boundary.loops[0]){int hits=0;for(auto q:corners)if(length(q-v)<1e-8)++hits;require(hits==1);}
 b.edgeCornerCount=3;auto triples=edgeBorderPoints(b,42);for(auto v:b.boundary.loops[0]){int hits=0;for(auto q:triples)if(length(q-v)<1.01)++hits;require(hits>=3);}
 b.edgeCornerAngle=91;auto excluded=edgeBorderPoints(b,42);b.edgeKeepCorners=false;auto disabled=edgeBorderPoints(b,42);require(excluded.size()==disabled.size());for(std::size_t i=0;i<excluded.size();++i)require(length(excluded[i]-disabled[i])==0);
 b.edgeKeepCorners=true;b.edgeCornerAngle=45;b.edgeCornerCount=1;b.boundaryMask={true,false,false,false,false,false};auto masked=edgeBorderPoints(b,42);for(auto q:masked)require(q.y<=.2+1e-8);b.boundaryMask.clear();
 b.boundary.loops={{{0,0,0},{10,0,0},{5,5,0}}};b.edgeCornerAngle=100;auto angled=edgeBorderPoints(b,42);require(std::any_of(angled.begin(),angled.end(),[](Vec3 q){return length(q-Vec3{0,0,0})<1e-8;}));
 b.width=1e-8;bool caught=false;try{edgeBorderPoints(b,42);}catch(const std::invalid_argument&){caught=true;}require(caught);
 std::cout<<"PASS spacing, offset, deterministic jitter, masks, count independence, relax pins, collisions, thin regions, elements, limit\n";
 }catch(const std::exception& e){std::cerr<<e.what()<<'\n';return 1;}}
