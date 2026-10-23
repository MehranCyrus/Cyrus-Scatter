#pragma once
#include <algorithm>
#include <cmath>
#include <cstdint>
#include <functional>
#include <limits>
#include <numeric>
#include <stdexcept>
#include <vector>

// Immutable numeric broad phase shared by contour certification and Bands.
// Segment storage/order is never changed. Queries charge both traversal and
// narrow-phase visits; their arithmetic/geometry remains the caller's policy.
namespace cyrus::geometry {
struct Point2 { double x=0,y=0; };
struct Segment2 { Point2 a,b; std::uint32_t loop=0,edge=0; };
struct Box2 {
    double x0=INFINITY,y0=INFINITY,x1=-INFINITY,y1=-INFINITY;
    void add(Point2 p){x0=std::min(x0,p.x);y0=std::min(y0,p.y);x1=std::max(x1,p.x);y1=std::max(y1,p.y);}
    void add(const Box2& p){add(Point2{p.x0,p.y0});add(Point2{p.x1,p.y1});}
    bool overlaps(const Box2& p)const{return x0<=p.x1&&p.x0<=x1&&y0<=p.y1&&p.y0<=y1;}
};
class WorkLimit:public std::runtime_error {public:WorkLimit():std::runtime_error("Spline geometry query work allowance exceeded"){};};
inline void charge(std::size_t& work,std::size_t limit){
    if(work>=limit)throw WorkLimit();
    ++work;
}
inline Box2 bounds(const Segment2& s){Box2 b;b.add(s.a);b.add(s.b);return b;}
inline double segmentDistance(Point2 p,Point2 a,Point2 b){
    const double dx=b.x-a.x,dy=b.y-a.y,den=dx*dx+dy*dy;
    const double t=den>0?std::clamp(((p.x-a.x)*dx+(p.y-a.y)*dy)/den,0.,1.):0;
    return std::hypot(p.x-a.x-t*dx,p.y-a.y-t*dy);
}
// Uncertain near-collinearity is a contact, never an unsafe simplicity proof.
inline int orientation(Point2 a,Point2 b,Point2 c){
    const double x=(b.x-a.x)*(c.y-a.y),y=(b.y-a.y)*(c.x-a.x),d=x-y;
    const double uncertainty=(std::abs(x)+std::abs(y))*32*std::numeric_limits<double>::epsilon();
    return d>uncertainty?1:d<-uncertainty?-1:0;
}
inline bool contact(const Segment2& a,const Segment2& b){
    if(!bounds(a).overlaps(bounds(b)))return false;
    const int p=orientation(a.a,a.b,b.a),q=orientation(a.a,a.b,b.b);
    const int r=orientation(b.a,b.b,a.a),s=orientation(b.a,b.b,a.b);
    return (p==0||q==0||p!=q)&&(r==0||s==0||r!=s);
}
class SegmentIndex {
    struct Node {Box2 box;std::uint32_t begin=0,end=0,left=0,right=0;};
    std::vector<Segment2> segments_;
    std::vector<std::uint32_t> order_;
    std::vector<Node> nodes_;
    std::uint32_t build(std::uint32_t begin,std::uint32_t end,std::size_t& work,std::size_t limit){
        charge(work,limit);
        const auto index=std::uint32_t(nodes_.size());nodes_.push_back({});
        Box2 box;for(auto i=begin;i<end;++i){charge(work,limit);box.add(bounds(segments_[order_[i]]));}
        nodes_[index].box=box;nodes_[index].begin=begin;nodes_[index].end=end;
        if(end-begin>8){
            const auto mid=begin+(end-begin)/2;const bool x=box.x1-box.x0>=box.y1-box.y0;
            std::nth_element(order_.begin()+begin,order_.begin()+mid,order_.begin()+end,[&](auto a,auto b){
                charge(work,limit);
                const auto& sa=segments_[a];const auto& sb=segments_[b];
                const double ca=x?(sa.a.x+sa.b.x):(sa.a.y+sa.b.y),cb=x?(sb.a.x+sb.b.x):(sb.a.y+sb.b.y);
                return ca<cb||(ca==cb&&a<b);
            });
            const auto left=build(begin,mid,work,limit),right=build(mid,end,work,limit);
            nodes_[index].left=left;nodes_[index].right=right;
        }
        return index;
    }
    template<class Predicate,class Visitor>
    void visit(std::uint32_t id,const Predicate& accepts,const Visitor& visitor,std::size_t& work,std::size_t limit)const{
        charge(work,limit);const auto& node=nodes_[id];if(!accepts(node.box))return;
        if(node.left){visit(node.left,accepts,visitor,work,limit);visit(node.right,accepts,visitor,work,limit);}
        else for(auto i=node.begin;i<node.end;++i){charge(work,limit);visitor(order_[i],segments_[order_[i]]);}
    }
public:
    explicit SegmentIndex(std::vector<Segment2> segments,std::size_t* measuredWork=nullptr,std::size_t workLimit=std::numeric_limits<std::size_t>::max()):segments_(std::move(segments)){
        if(segments_.size()>200000)throw std::invalid_argument("Spline segment index input limit exceeded");
        order_.resize(segments_.size());std::iota(order_.begin(),order_.end(),0u);
        std::size_t leaves=1;while(leaves<(segments_.size()+7)/8)leaves*=2;
        std::size_t localWork=0;auto& work=measuredWork?*measuredWork:localWork;
        nodes_.reserve(leaves*2);if(!segments_.empty())build(0,std::uint32_t(segments_.size()),work,workLimit);
    }
    const std::vector<Segment2>& segments()const{return segments_;}
    std::size_t bytes()const{return segments_.capacity()*sizeof(Segment2)+order_.capacity()*sizeof(std::uint32_t)+nodes_.capacity()*sizeof(Node);}
    template<class Visitor> void overlap(const Box2& box,const Visitor& visitor,std::size_t& work,std::size_t limit)const{
        if(!nodes_.empty())visit(0,[&](const Box2& b){return b.overlaps(box);},visitor,work,limit);
    }
    template<class Visitor> void ray(Point2 p,const Visitor& visitor,std::size_t& work,std::size_t limit)const{
        if(!nodes_.empty())visit(0,[&](const Box2& b){return b.y0<=p.y&&p.y<=b.y1&&b.x1>=p.x;},visitor,work,limit);
    }
    double nearest(Point2 p,std::size_t& work,std::size_t limit)const{
        double best=INFINITY;
        if(!nodes_.empty())visit(0,[&](const Box2& b){
            const double dx=std::max({b.x0-p.x,0.,p.x-b.x1}),dy=std::max({b.y0-p.y,0.,p.y-b.y1});
            // Round the lower bound down. Retain near-equality candidates.
            const double rounding=64*std::numeric_limits<double>::epsilon()*std::max({1.,std::abs(p.x),std::abs(p.y),std::abs(b.x0),std::abs(b.y0),std::abs(b.x1),std::abs(b.y1)});
            return std::nextafter(std::hypot(dx,dy)-rounding,-INFINITY)<=best;
        },[&](std::uint32_t,const Segment2& s){best=std::min(best,segmentDistance(p,s.a,s.b));},work,limit);
        return best;
    }
};
}
