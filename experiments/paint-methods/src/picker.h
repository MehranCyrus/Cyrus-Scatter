#pragma once
#include "lab.h"
#include <algorithm>
#include <numeric>
namespace paintlab {
// Copied numeric snapshot only; this picker never touches Max objects.
class Picker {
 struct Node{V lo{1e300,1e300,1e300},hi{-1e300,-1e300,-1e300};int left=-1,right=-1;unsigned start=0,count=0;};
 const Mesh* mesh;std::vector<unsigned> order;std::vector<Node> nodes;
 static double component(V p,int a){return a==0?p.x:a==1?p.y:p.z;}
 int build(unsigned start,unsigned count){int i=int(nodes.size());nodes.emplace_back();Node node;node.start=start;node.count=count;for(unsigned j=start;j<start+count;++j)for(auto v:mesh->faces[order[j]]){auto p=mesh->vertices[v];node.lo={std::min(node.lo.x,p.x),std::min(node.lo.y,p.y),std::min(node.lo.z,p.z)};node.hi={std::max(node.hi.x,p.x),std::max(node.hi.y,p.y),std::max(node.hi.z,p.z)};}
  if(count>8){V size=node.hi-node.lo;int axis=size.x>size.y?(size.x>size.z?0:2):(size.y>size.z?1:2);auto center=[&](unsigned f){auto face=mesh->faces[f];return component(mesh->vertices[face[0]]+mesh->vertices[face[1]]+mesh->vertices[face[2]],axis);};unsigned half=count/2;std::nth_element(order.begin()+start,order.begin()+start+half,order.begin()+start+count,[&](auto a,auto b){return center(a)<center(b);});node.left=build(start,half);node.right=build(start+half,count-half);node.count=0;}nodes[i]=node;return i;}
 bool box(const Node& n,V o,V d,double best)const{double lo=0,hi=best;for(int a=0;a<3;++a){double origin=component(o,a),dir=component(d,a),l=component(n.lo,a),h=component(n.hi,a);if(std::abs(dir)<1e-20){if(origin<l||origin>h)return false;continue;}double t0=(l-origin)/dir,t1=(h-origin)/dir;if(t0>t1)std::swap(t0,t1);lo=std::max(lo,t0);hi=std::min(hi,t1);if(lo>hi)return false;}return true;}
 void visit(int index,V o,V d,double& best,Anchor& result,bool& found)const{if(index<0)return;auto& n=nodes[index];if(!box(n,o,d,best))return;if(n.count){for(unsigned j=n.start;j<n.start+n.count;++j){auto f=mesh->faces[order[j]];V a=mesh->vertices[f[0]],e1=mesh->vertices[f[1]]-a,e2=mesh->vertices[f[2]]-a,p=cross(d,e2);double det=dot(e1,p);if(std::abs(det)<1e-16)continue;double inv=1/det;V t=o-a;double u=dot(t,p)*inv;if(u<0||u>1)continue;V q=cross(t,e1);double v=dot(d,q)*inv;if(v<0||u+v>1)continue;double distance=dot(e2,q)*inv;if(distance>=0&&distance<best){best=distance;result={order[j],{1-u-v,u,v}};found=true;}}}else{visit(n.left,o,d,best,result,found);visit(n.right,o,d,best,result,found);}}
public:
 explicit Picker(const Mesh& m):mesh(&m){order.resize(m.faces.size());std::iota(order.begin(),order.end(),0);if(!order.empty())build(0,unsigned(order.size()));}
 bool hit(V o,V d,Anchor& a)const{double best=1e300;bool found=false;if(!nodes.empty())visit(0,o,d,best,a,found);return found;}
};
}
