#include "analyzer.h"
#include "samples.h"
#include <cmath>
#include <algorithm>
#include <iostream>
#include <stdexcept>
void check(bool b){if(!b)throw std::runtime_error("Check failed");}
int main(){try{
 cyrus::Mesh attached;for(auto sample:samples()){int offset=int(attached.vertices.size());attached.vertices.insert(attached.vertices.end(),sample.vertices.begin(),sample.vertices.end());for(auto f:sample.faces){for(int& v:f)v+=offset;attached.faces.push_back(f);}}
 cyrus::Settings radiusSettings;radiusSettings.pointRadius=150;
 auto combined=cyrus::analyze(attached,radiusSettings);
 check(combined.elementModes==std::vector<int>({1,2,3}));check(combined.mode==4&&combined.boundaries.size()==3);check(combined.elementPointCounts[1]==4);
 for(size_t i=0;i<combined.points.size();i++)for(size_t j=0;j<i;j++)check(cyrus::len(combined.points[i]-combined.points[j])>=150-1e-7);
 radiusSettings.pointRadius=75;auto dense=cyrus::analyze(attached,radiusSettings);check(dense.points.size()>combined.points.size());
 cyrus::Mesh close;for(int layer=0;layer<2;layer++){int offset=int(close.vertices.size());close.vertices.insert(close.vertices.end(),{{0,0,double(layer)*.1},{10,0,double(layer)*.1},{10,4,double(layer)*.1},{0,4,double(layer)*.1}});close.faces.push_back({offset,offset+1,offset+2});close.faces.push_back({offset,offset+2,offset+3});}radiusSettings.pointRadius=2;auto filtered=cyrus::analyze(close,radiusSettings);check(filtered.elementModes.size()==2);check(filtered.elementPointCounts[1]==0);
 for(size_t i=0;i<filtered.points.size();i++)for(size_t j=0;j<i;j++)check(cyrus::len(filtered.points[i]-filtered.points[j])>=2-1e-9);
 radiusSettings.pointRadius=1e-12;bool budgetRejected=false;try{cyrus::analyze(attached,radiusSettings);}catch(...){budgetRejected=true;}check(budgetRejected);
 std::cout<<"PASS attached mixed elements at different heights; automatic radius counts; star four points; global spacing; tiny-radius guard\n";
 radiusSettings.pointRadius=500;radiusSettings.minimumPoints=3;
 auto minimum=cyrus::analyze(attached,radiusSettings);for(int c:minimum.elementPointCounts)check(c>=3);check(minimum.elementPointCounts[1]==3&&minimum.elementRelaxed[1]==1);
 radiusSettings.minimumPoints=0;auto noMinimum=cyrus::analyze(attached,radiusSettings);check(noMinimum.elementPointCounts[1]==1);
 radiusSettings.minimumPoints=3;radiusSettings.minWidth=1e6;auto noPath=cyrus::analyze(attached,radiusSettings);check(noPath.points.empty());
 std::cout<<"PASS per-element minimum overrides radius; zero disables override; no points outside eligible paths\n";
 cyrus::Settings fit;fit.pointRadius=175;fit.fitRadius=100;fit.relaxIterations=30;fit.minimumPoints=3;
 for(auto sample:samples()){
 auto r=cyrus::analyze(sample,fit);check(!r.points.empty());
 for(auto point:r.points)for(auto& loop:r.boundaries)for(size_t j=0;j<loop.size();j++){auto a=loop[j],d=loop[(j+1)%loop.size()]-a;double t=std::clamp(cyrus::dot(point-a,d)/cyrus::dot(d,d),0.,1.);check(cyrus::len(point-a-d*t)>=100-1e-6);}
 }
 auto slightlyBent=samples()[0];slightlyBent.vertices[0].x+=25;auto straight=cyrus::analyze(slightlyBent,fit);check(straight.mode==1);auto axis=straight.paths[0].back()-straight.paths[0].front();for(auto p:straight.points){auto delta=p-straight.paths[0].front();check(cyrus::len(delta-axis*(cyrus::dot(delta,axis)/cyrus::dot(axis,axis)))<.001);}
 auto tiltedFit=samples()[2];for(auto& p:tiltedFit.vertices){double x=p.x,y=p.y;p={x*.6-y*.8,50,x*.8+y*.6};}auto tiltedResult=cyrus::analyze(tiltedFit,fit);check(!tiltedResult.points.empty());for(auto p:tiltedResult.points){check(std::abs(p.y-50)<1e-6);for(auto& loop:tiltedResult.boundaries)for(size_t j=0;j<loop.size();j++){auto a=loop[j],d=loop[(j+1)%loop.size()]-a;double t=std::clamp(cyrus::dot(p-a,d)/cyrus::dot(d,d),0.,1.);check(cyrus::len(p-a-d*t)>=100-1e-6);}}
 fit.fitRadius=1e6;fit.minimumPoints=10;check(cyrus::analyze(attached,fit).points.empty());
 std::cout<<"PASS hard disk clearance on all shapes after Relax and minimum override; near-rectangular straight axis; impossible footprint returns no points\n";
 int mode=0;for(auto sample:samples()){
 cyrus::Settings settings;auto out=cyrus::analyze(sample,settings);check(out.mode==++mode&&out.points.size()==5);
 for(auto q:out.points){bool inside=false;for(auto f:sample.faces){auto a=sample.vertices[f[0]],b=sample.vertices[f[1]],c=sample.vertices[f[2]];auto sign=[](cyrus::V p,cyrus::V x,cyrus::V y){return (p.x-y.x)*(x.y-y.y)-(x.x-y.x)*(p.y-y.y);};double d1=sign(q,a,b),d2=sign(q,b,c),d3=sign(q,c,a);if(!((d1<0||d2<0||d3<0)&&(d1>0||d2>0||d3>0)))inside=true;}check(inside);}
 for(auto&p:sample.vertices){double x=p.x,y=p.y;p={x*.6-y*.8,100,x*.8+y*.6};}auto tilted=cyrus::analyze(sample,settings);check(tilted.mode==mode&&tilted.points.size()==5);check(std::abs(out.area-tilted.area)<.01);
 }
 std::cout<<"PASS supplied shapes: Auto modes, points inside triangles, tilted/rotated equivalents\n";
 cyrus::Mesh m{{{0,0,0},{10,0,0},{10,4,0},{0,4,0}},{{0,1,2},{0,2,3}}};cyrus::Settings s;
 auto r=cyrus::analyze(m,s);check(r.mode==1&&r.boundaries.size()==1&&r.points.size()==5);check(std::abs(r.area-40)<1e-9);for(auto p:r.points)check(p.x>0&&p.x<10&&p.y>0&&p.y<4);
 for(auto&p:m.vertices){double x=p.x,y=p.y;p={x*.6-y*.8,0,x*.8+y*.6};}auto rotated=cyrus::analyze(m,s);check(std::abs(rotated.area-40)<1e-9);check(std::abs(rotated.pathLength-r.pathLength)<.1);
 s.minWidth=20;check(cyrus::analyze(m,s).points.empty());s.minWidth=0;
 cyrus::Mesh star;star.vertices.push_back({0,0,0});for(int i=0;i<12;i++){double a=i*6.283185307179586/12,rad=i%2?4:10;star.vertices.push_back({std::cos(a)*rad,std::sin(a)*rad,0});}for(int i=0;i<12;i++)star.faces.push_back({0,i+1,(i+1)%12+1});s.count=6;auto sr=cyrus::analyze(star,s);check(sr.mode==2&&sr.points.size()==6);for(auto p:sr.points)check(cyrus::len(p)<4);
 cyrus::Mesh hole{{{0,0,0},{10,0,0},{10,10,0},{0,10,0},{3,3,0},{7,3,0},{7,7,0},{3,7,0}},{{0,1,5},{0,5,4},{1,2,6},{1,6,5},{2,3,7},{2,7,6},{3,0,4},{3,4,7}}};
 s.mode=3;s.count=100;auto hr=cyrus::analyze(hole,s);check(hr.boundaries.size()==2&&hr.points.size()==100);check(std::abs(hr.area-84)<1e-9);for(auto p:hr.points)check(p.x<3||p.x>7||p.y<3||p.y>7);
 s.fitRadius=1;s.pointRadius=1;s.relaxIterations=20;auto fittedHole=cyrus::analyze(hole,s);check(!fittedHole.points.empty());for(auto p:fittedHole.points)for(auto& loop:fittedHole.boundaries)for(size_t j=0;j<loop.size();j++){auto a=loop[j],d=loop[(j+1)%loop.size()]-a;double t=std::clamp(cyrus::dot(p-a,d)/cyrus::dot(d,d),0.,1.);check(cyrus::len(p-a-d*t)>=1-1e-9);}
 m.vertices[0].y=2;bool rejected=false;try{cyrus::analyze(m,s);}catch(...){rejected=true;}check(rejected);
 std::cout<<"PASS rectangle, rotated plane, area, width rejection, star ring, hole boundary/containment, nonplanar rejection\n";
 }catch(std::exception&e){std::cerr<<e.what();return 1;}}

