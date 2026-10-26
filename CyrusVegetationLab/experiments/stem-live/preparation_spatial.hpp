#pragma once
#include <algorithm>
#include <array>
#include <atomic>
#include <cmath>
#include <cstdint>
#include <numeric>
#include <stdexcept>
#include <vector>
namespace prep::spatial {
using V=std::array<double,3>;
inline V add(V a,V b){return {a[0]+b[0],a[1]+b[1],a[2]+b[2]};}
inline V sub(V a,V b){return {a[0]-b[0],a[1]-b[1],a[2]-b[2]};}
inline V mul(V a,double b){return {a[0]*b,a[1]*b,a[2]*b};}
inline double dot(V a,V b){return a[0]*b[0]+a[1]*b[1]+a[2]*b[2];}
inline double length(V a){return std::sqrt(dot(a,a));}
struct Work {
    std::uint64_t used=0,limit;const std::atomic_bool& cancel;
    void charge(std::uint64_t n=1){used+=n;if(used>limit)throw std::runtime_error("Preparation work limit reached; increase Work in Preparation limits.");if(!(used%4096)&&cancel.load())throw std::runtime_error("Analysis cancelled; previous preparation retained.");}
};
struct Segment {V a,b;unsigned guide,span;};
struct Near {unsigned guide=~0u,span=0;double u=0,distance=1e100;};
class Index {
    struct Node {V lo,hi;unsigned begin,end,left=~0u,right=~0u;};
    std::vector<Segment> segments_;std::vector<unsigned> order_;std::vector<Node> nodes_;Work& work_;
    unsigned build(unsigned begin,unsigned end){
        work_.charge(end-begin);Node node{{1e100,1e100,1e100},{-1e100,-1e100,-1e100},begin,end};
        for(unsigned k=begin;k<end;++k)for(int d=0;d<3;++d){auto& s=segments_[order_[k]];node.lo[d]=std::min({node.lo[d],s.a[d],s.b[d]});node.hi[d]=std::max({node.hi[d],s.a[d],s.b[d]});}
        unsigned id=unsigned(nodes_.size());nodes_.push_back(node);if(end-begin>8){unsigned axis=0;for(unsigned d=1;d<3;++d)if(node.hi[d]-node.lo[d]>node.hi[axis]-node.lo[axis])axis=d;unsigned mid=(begin+end)/2;
            std::nth_element(order_.begin()+begin,order_.begin()+mid,order_.begin()+end,[&](unsigned a,unsigned b){double x=segments_[a].a[axis]+segments_[a].b[axis],y=segments_[b].a[axis]+segments_[b].b[axis];return x==y?a<b:x<y;});
            unsigned left=build(begin,mid),right=build(mid,end);nodes_[id].left=left;nodes_[id].right=right;}
        return id;
    }
public:
    Index(std::vector<Segment> segments,Work& work):segments_(std::move(segments)),work_(work){order_.resize(segments_.size());std::iota(order_.begin(),order_.end(),0);nodes_.reserve(order_.size()*2);if(!order_.empty())build(0,unsigned(order_.size()));}
    template<class F> void query(V p,double& radius,F visit)const{
        if(nodes_.empty())return;std::vector<unsigned> stack{0};while(!stack.empty()){auto id=stack.back();stack.pop_back();work_.charge();const auto& node=nodes_[id];double distance=0;for(int d=0;d<3;++d){double q=std::max({node.lo[d]-p[d],0.,p[d]-node.hi[d]});distance+=q*q;}if(distance>radius*radius)continue;
            if(node.left!=~0u){stack.push_back(node.right);stack.push_back(node.left);continue;}
            for(unsigned k=node.begin;k<node.end;++k){work_.charge();const auto& s=segments_[order_[k]];auto delta=sub(s.b,s.a);double denominator=dot(delta,delta);double u=denominator<1e-18?0.:std::clamp(dot(sub(p,s.a),delta)/denominator,0.,1.);double gap=length(sub(p,add(s.a,mul(delta,u))));if(gap<=radius)visit(s,u,gap);}
        }
    }
    Near nearest(V p,unsigned excluded=~0u)const{Near result;double radius=result.distance;query(p,radius,[&](const Segment& s,double u,double gap){if(s.guide!=excluded&&(gap<result.distance||(gap==result.distance&&std::pair{s.guide,s.span}<std::pair{result.guide,result.span}))){result={s.guide,s.span,u,gap};radius=gap;}});return result;}
};
}
