#include "brush.h"
#include <algorithm>
#include <cmath>
#include <cstring>
#include <map>
#include <numeric>
#include <stdexcept>

namespace cyrus::brush {
namespace {
Vec3 cross(Vec3 a,Vec3 b){return {a.y*b.z-a.z*b.y,a.z*b.x-a.x*b.z,a.x*b.y-a.y*b.x};}
double norm2(Vec3 a){return amin::dot(a,a);}
bool finite(Vec3 a){return std::isfinite(a.x)&&std::isfinite(a.y)&&std::isfinite(a.z);}
double axis(Vec3 a,int i){return i==0?a.x:i==1?a.y:a.z;}
struct Box {
    Vec3 lo{INFINITY,INFINITY,INFINITY},hi{-INFINITY,-INFINITY,-INFINITY};
    void add(Vec3 v){lo={std::min(lo.x,v.x),std::min(lo.y,v.y),std::min(lo.z,v.z)};hi={std::max(hi.x,v.x),std::max(hi.y,v.y),std::max(hi.z,v.z)};}
    bool contains(Vec3 p)const{
        for(int i=0;i<3;++i){const double low=axis(lo,i),high=axis(hi,i),v=axis(p,i);
            const double pad=1e-9+32*std::numeric_limits<double>::epsilon()*std::max({1.,std::abs(v),std::abs(low),std::abs(high)});
            if(v<low-pad||v>high+pad)return false;
        }return true;
    }
    bool intersects(Ray r,double limit)const{
        double near=0,far=limit;
        for(int i=0;i<3;++i){const double o=axis(r.origin,i),d=axis(r.direction,i);
            const double low=axis(lo,i),high=axis(hi,i);
            // Conservative slabs must include the triangle test's barycentric
            // tolerance and floating-point error. At a shared pole, a rounded
            // slab entry can otherwise exceed an equally near triangle hit.
            const double pad=1e-9*(high-low)+32*std::numeric_limits<double>::epsilon()*std::max({1.,std::abs(o),std::abs(low),std::abs(high)});
            const double a=low-pad,b=high+pad;
            if(std::abs(d)<1e-30){if(o<a||o>b)return false;continue;}
            double t0=(a-o)/d,t1=(b-o)/d;if(t0>t1)std::swap(t0,t1);
            near=std::max(near,t0);far=std::min(far,t1);if(near>far)return false;
        }return true;
    }
};
bool triangleHit(const Mesh& mesh,std::uint32_t f,Ray r,Hit& out,double limit){
    const auto ids=mesh.faces[f];const Vec3 a=mesh.vertices[ids[0]],e=mesh.vertices[ids[1]]-a,g=mesh.vertices[ids[2]]-a;
    const Vec3 p=cross(r.direction,g);const double det=amin::dot(e,p);
    if(std::abs(det)<=1e-13*std::sqrt(norm2(e)*norm2(g)*norm2(r.direction)))return false;
    const Vec3 t=r.origin-a;const double u=amin::dot(t,p)/det;
    const Vec3 q=cross(t,e);const double v=amin::dot(r.direction,q)/det;
    const double d=amin::dot(g,q)/det;
    if(u< -1e-9||v< -1e-9||u+v>1+1e-9||d<0||d>limit)return false;
    out={{f,{1-u-v,u,v}},d};return true;
}
}
struct Surface::Impl {
    Mesh data;std::uint64_t fingerprint=1469598103934665603ULL;
    struct Node{Box box;std::uint32_t begin{},end{},left{},right{};};
    std::vector<Node> nodes;std::vector<std::uint32_t> order;
    std::uint32_t build(std::uint32_t begin,std::uint32_t end){
        const auto n=static_cast<std::uint32_t>(nodes.size());nodes.push_back({});Box box,centers;
        for(auto i=begin;i<end;++i){Vec3 c{};for(auto v:data.faces[order[i]]){box.add(data.vertices[v]);c=c+data.vertices[v];}centers.add(c*(1./3));}
        nodes[n].box=box;nodes[n].begin=begin;nodes[n].end=end;
        if(end-begin>8){const auto extent=centers.hi-centers.lo;int ax=extent.x>extent.y?0:1;if(extent.z>axis(extent,ax))ax=2;
            const auto mid=begin+(end-begin)/2;
            auto center=[&](std::uint32_t f){double c=0;for(auto v:data.faces[f])c+=axis(data.vertices[v],ax);return c;};
            std::nth_element(order.begin()+begin,order.begin()+mid,order.begin()+end,[&](auto a,auto b){const auto ca=center(a),cb=center(b);return ca==cb?a<b:ca<cb;});
            const auto l=build(begin,mid),r=build(mid,end);nodes[n].left=l;nodes[n].right=r;
        }return n;
    }
};
Surface::Surface(Mesh mesh){
    if(mesh.faces.empty()||mesh.vertices.empty()||mesh.faces.size()>10000000||mesh.vertices.size()>10000000)throw std::invalid_argument("Invalid Brush mesh size");
    auto p=std::make_shared<Impl>();p->data=std::move(mesh);
    auto hash=[&](const void* src,std::size_t bytes){auto b=static_cast<const unsigned char*>(src);for(std::size_t i=0;i<bytes;++i)p->fingerprint=(p->fingerprint^b[i])*1099511628211ULL;};
    for(auto v:p->data.vertices){if(!finite(v))throw std::invalid_argument("Non-finite Brush vertex");hash(&v,sizeof(v));}
    for(const auto& ids:p->data.faces){
        for(auto v:ids)if(v>=p->data.vertices.size())throw std::invalid_argument("Invalid vector receiver face");
        hash(ids.data(),sizeof(ids));
    }
    p->order.resize(p->data.faces.size());std::iota(p->order.begin(),p->order.end(),0u);p->build(0,static_cast<std::uint32_t>(p->order.size()));impl=std::move(p);
}
const Mesh& Surface::mesh()const{return impl->data;}
std::uint64_t Surface::fingerprint()const{return impl->fingerprint;}
Vec3 Surface::position(Anchor a)const{
    if(a.face>=mesh().faces.size()||!finite(a.bary)||std::abs(a.bary.x+a.bary.y+a.bary.z-1)>1e-5||std::min({a.bary.x,a.bary.y,a.bary.z})< -1e-6)throw std::invalid_argument("Invalid surface anchor");
    const auto f=mesh().faces[a.face];return mesh().vertices[f[0]]*a.bary.x+mesh().vertices[f[1]]*a.bary.y+mesh().vertices[f[2]]*a.bary.z;
}
Vec3 Surface::normal(std::uint32_t face)const{const auto f=mesh().faces.at(face);const auto n=cross(mesh().vertices[f[1]]-mesh().vertices[f[0]],mesh().vertices[f[2]]-mesh().vertices[f[0]]);const auto size=amin::length(n);return size>0?n*(1./size):Vec3{};}
bool Surface::hit(Ray r,Hit& result,double limit,QueryStats* stats)const{
    if(!finite(r.origin)||!finite(r.direction)||norm2(r.direction)<1e-24||std::isnan(limit)||limit<0)throw std::invalid_argument("Invalid Brush ray");
    bool found=false;std::vector<std::uint32_t> stack{0};
    while(!stack.empty()){const auto n=stack.back();stack.pop_back();const auto& node=impl->nodes[n];if(!node.box.intersects(r,limit))continue;
        if(node.right){stack.push_back(node.right);stack.push_back(node.left);continue;}
        for(auto i=node.begin;i<node.end;++i){Hit h;if(stats)++stats->triangles;
            if(triangleHit(mesh(),impl->order[i],r,h,limit)&&(!found||h.distance<result.distance|| (h.distance==result.distance&&h.anchor.face<result.anchor.face))){result=h;limit=h.distance;found=true;}}
    }return found;
}
bool Surface::hitReference(Ray r,Hit& result,double limit)const{bool found=false;for(std::uint32_t f=0;f<mesh().faces.size();++f){Hit h;if(triangleHit(mesh(),f,r,h,limit)&&(!found||h.distance<result.distance)){result=h;limit=h.distance;found=true;}}return found;}
}
