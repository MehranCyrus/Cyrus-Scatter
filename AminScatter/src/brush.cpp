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
Vec3 mapped(Vec3 a,const std::array<Vec3,3>& b){return b[0]*a.x+b[1]*a.y+b[2]*a.z;}
double axis(Vec3 a,int i){return i==0?a.x:i==1?a.y:a.z;}
struct Box {
    Vec3 lo{INFINITY,INFINITY,INFINITY},hi{-INFINITY,-INFINITY,-INFINITY};
    void add(Vec3 v){lo={std::min(lo.x,v.x),std::min(lo.y,v.y),std::min(lo.z,v.z)};hi={std::max(hi.x,v.x),std::max(hi.y,v.y),std::max(hi.z,v.z)};}
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
double segmentDistance2(Vec3 a,Vec3 b){Vec3 d=b-a;const double n=norm2(d);const double t=n>0?std::clamp(-amin::dot(a,d)/n,0.,1.):0;return norm2(a+d*t);}
void checkSample(const Sample& s){
    if(!finite(s.anchor.bary)||std::abs(s.anchor.bary.x+s.anchor.bary.y+s.anchor.bary.z-1)>1e-5||
       std::min({s.anchor.bary.x,s.anchor.bary.y,s.anchor.bary.z})< -1e-6||!finite(s.view.eye)||!finite(s.view.direction))
        throw std::invalid_argument("Invalid Brush sample");
    for(auto b:s.basis)if(!finite(b))throw std::invalid_argument("Invalid capture metric");
    const double scale=amin::length(s.basis[0])*amin::length(s.basis[1])*amin::length(s.basis[2]);
    if(scale==0||std::abs(amin::dot(s.basis[0],cross(s.basis[1],s.basis[2])))<scale*1e-12)
        throw std::invalid_argument("Singular Brush capture transform");
    if(!s.view.perspective&&norm2(s.view.direction)<1e-24)throw std::invalid_argument("Invalid Brush view direction");
    if(s.hasPath&&(!finite(s.ray.origin)||!finite(s.ray.direction)||norm2(s.ray.direction)<1e-24||
        !std::isfinite(s.screen[0])||!std::isfinite(s.screen[1])))throw std::invalid_argument("Invalid Brush path ray");
    if(s.connected&&!s.hasPath)throw std::invalid_argument("Connected sample has no path");
}
}
struct Surface::Impl {
    Mesh data;std::uint64_t fingerprint=1469598103934665603ULL;
    struct Node{Box box;std::uint32_t begin{},end{},left{},right{};};
    std::vector<Node> nodes;std::vector<std::uint32_t> order;std::vector<std::array<int,3>> neighbors;
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
    p->neighbors.resize(p->data.faces.size(),{-1,-1,-1});
    using Edge=std::pair<std::uint32_t,std::uint32_t>;
    std::map<Edge,std::vector<std::pair<std::uint32_t,int>>> edges;
    for(std::uint32_t f=0;f<p->data.faces.size();++f){const auto ids=p->data.faces[f];
        for(auto v:ids)if(v>=p->data.vertices.size())throw std::invalid_argument("Invalid Brush face vertex");
        hash(ids.data(),sizeof(ids));
        for(int e=0;e<3;++e){auto a=ids[e],b=ids[(e+1)%3];if(a>b)std::swap(a,b);edges[{a,b}].push_back({f,e});}
    }
    // Boundary and nonmanifold edges are barriers, never automatic flood paths.
    for(const auto& entry:edges){const auto& v=entry.second;if(v.size()==2){p->neighbors[v[0].first][v[0].second]=static_cast<int>(v[1].first);p->neighbors[v[1].first][v[1].second]=static_cast<int>(v[0].first);}}
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
std::vector<std::uint32_t> Surface::patch(const Sample& s,double radius)const{
    checkSample(s);if(!std::isfinite(radius)||radius<=0)throw std::invalid_argument("Brush radius must be positive");
    const auto center=position(s.anchor);std::vector<std::uint32_t> result{s.anchor.face};std::vector<bool> visited(mesh().faces.size());visited[s.anchor.face]=true;
    for(std::size_t i=0;i<result.size();++i){const auto f=result[i];const auto ids=mesh().faces[f];
        for(int edge=0;edge<3;++edge){const int next=impl->neighbors[f][edge];if(next<0||visited[next])continue;
            const auto a=mapped(mesh().vertices[ids[edge]]-center,s.basis),b=mapped(mesh().vertices[ids[(edge+1)%3]]-center,s.basis);
            if(segmentDistance2(a,b)<=radius*radius){visited[next]=true;result.push_back(static_cast<std::uint32_t>(next));}
        }
    }std::sort(result.begin(),result.end());return result;
}
bool Surface::visible(Anchor a,const View& view,QueryStats* stats)const{
    const auto p=position(a);Vec3 direction=view.perspective?p-view.eye:view.direction;
    const double n=amin::length(direction);if(n<1e-12)return false;direction=direction*(1./n);
    // Start just above the query, toward the captured viewer. Exclude only the
    // endpoint itself, so a parallel sheet in front still occludes the query.
    const double extent=amin::length(impl->nodes[0].box.hi-impl->nodes[0].box.lo);
    const double epsilon=std::max(1e-9,extent*1e-8);
    Hit hitPoint;const double limit=view.perspective?std::max(0.,n-epsilon):std::numeric_limits<double>::infinity();
    return !hit({p-direction*epsilon,direction*(-1)},hitPoint,limit,stats);
}
void validate(const Stroke& s){
    if(!std::isfinite(s.radius)||s.radius<=0||!std::isfinite(s.strength)||s.strength<0||s.strength>1||!std::isfinite(s.softness)||s.softness<0||s.softness>1||s.samples.size()>1000000)throw std::invalid_argument("Invalid Brush stroke settings");
    for(const auto& sample:s.samples)checkSample(sample);
}
Stroke resample(const Surface& surface,const Stroke& input){
    validate(input);Stroke out=input;out.samples.clear();
    for(std::size_t i=0;i<input.samples.size();++i){const auto& current=input.samples[i];
        if(i&&current.connected&&input.samples[i-1].hasPath){const auto& previous=input.samples[i-1];
            // A view/transform change breaks the path in the host. Refuse a
            // malformed persisted connection rather than interpolate frames.
            bool same=current.view.perspective==previous.view.perspective;
            same=same&&norm2(current.view.eye-previous.view.eye)<1e-16&&norm2(current.view.direction-previous.view.direction)<1e-16;
            for(int k=0;k<3;++k)same=same&&norm2(current.basis[k]-previous.basis[k])<1e-16;
            if(!same)throw std::invalid_argument("Brush path spans different capture frames");
            const double pixels=std::hypot(current.screen[0]-previous.screen[0],current.screen[1]-previous.screen[1]);
            const double distance=amin::length(mapped(surface.position(current.anchor)-surface.position(previous.anchor),current.basis));
            const double required=std::ceil(std::max(pixels/2.,distance/(input.radius*.15)));
            if(required>10000)throw std::invalid_argument("Stroke resampling limit: use a larger radius or shorter stroke");
            const auto steps=static_cast<unsigned>(std::max(1.,required));
            for(unsigned j=1;j<steps;++j){const double t=double(j)/steps;Sample dab=current;
                dab.ray={previous.ray.origin*(1-t)+current.ray.origin*t,previous.ray.direction*(1-t)+current.ray.direction*t};
                Hit hit;if(!surface.hit(dab.ray,hit))continue;dab.anchor=hit.anchor;dab.hasPath=false;dab.connected=false;out.samples.push_back(dab);
            }
        }
        out.samples.push_back(current);
        if(out.samples.size()>1000000)throw std::invalid_argument("Derived Brush dab limit");
    }return out;
}
double apply(double before,double q,bool erase){q=std::clamp(q,0.,1.);return erase?before*(1-q):before+(1-before)*q;}
double influence(const Surface& surface,const Sample& sample,const Stroke& stroke,Anchor a,QueryStats* stats){
    const auto d=mapped(surface.position(a)-surface.position(sample.anchor),sample.basis);const double ratio=amin::length(d)/stroke.radius;
    if(ratio>=1||!surface.visible(a,sample.view,stats))return 0;
    double falloff=1;const double core=1-stroke.softness;
    if(ratio>core&&stroke.softness>0){const double x=(ratio-core)/stroke.softness;falloff=1-x*x*(3-2*x);}
    return falloff*stroke.strength;
}
struct Field::Impl {
    Surface surface;Document document;
    struct Link{std::uint32_t stroke,sample;};std::vector<std::vector<Link>> byFace;
    std::vector<std::vector<std::vector<std::uint32_t>>> patches;
    std::vector<std::vector<Vec3>> centers;
    Impl(const Surface& s,const Document& d):surface(s),document(d),byFace(s.mesh().faces.size()){
        if(d.surface!=s.fingerprint())throw std::invalid_argument("Brush surface changed; rebind required");
        if(d.strokes.size()>10000)throw std::invalid_argument("Too many Brush strokes");
        patches.resize(d.strokes.size());centers.resize(d.strokes.size());
        for(std::uint32_t i=0;i<d.strokes.size();++i){document.strokes[i]=resample(s,d.strokes[i]);const auto& stroke=document.strokes[i];patches[i].resize(stroke.samples.size());if(!stroke.enabled)continue;
            for(std::uint32_t j=0;j<stroke.samples.size();++j){centers[i].push_back(s.position(stroke.samples[j].anchor));auto& patch=patches[i][j];patch=s.patch(stroke.samples[j],stroke.radius);for(auto f:patch)byFace[f].push_back({i,j});}
        }
    }
};
Field::Field(const Surface& s,const Document& d):impl(std::make_shared<Impl>(s,d)){}
double Field::evaluate(Anchor a,QueryStats* stats)const{
    const auto position=impl->surface.position(a);if(stats)++stats->fieldQueries;double value=0,q=0;std::uint32_t previous=UINT32_MAX;
    for(auto link:impl->byFace[a.face]){
        if(previous!=link.stroke){if(previous!=UINT32_MAX)value=apply(value,q,impl->document.strokes[previous].erase);q=0;previous=link.stroke;}
        const auto& stroke=impl->document.strokes[link.stroke];if(q>=stroke.strength)continue;
        const auto& dab=stroke.samples[link.sample];
        const double ratio=amin::length(mapped(position-impl->centers[link.stroke][link.sample],dab.basis))/stroke.radius;
        if(ratio>=1)continue;double candidate=stroke.strength;
        if(stroke.softness>0&&ratio>1-stroke.softness){const double x=(ratio-(1-stroke.softness))/stroke.softness;candidate*=1-x*x*(3-2*x);}
        // Only a stronger dab can change this stroke's maximum. Avoid repeating
        // visibility queries for its overlapping interior samples.
        if(candidate>q&&impl->surface.visible(a,dab.view,stats))q=candidate;
    }return previous==UINT32_MAX?0:apply(value,q,impl->document.strokes[previous].erase);
}
double Field::evaluateReference(Anchor a,QueryStats* stats)const{
    impl->surface.position(a);double value=0;
    for(std::size_t i=0;i<impl->document.strokes.size();++i){const auto& stroke=impl->document.strokes[i];if(!stroke.enabled)continue;double q=0;
        for(std::size_t j=0;j<stroke.samples.size();++j){const auto& patch=impl->patches[i][j];if(std::binary_search(patch.begin(),patch.end(),a.face))q=std::max(q,influence(impl->surface,stroke.samples[j],stroke,a,stats));}
        value=apply(value,q,stroke.erase);
    }return value;
}
double threshold(std::uint64_t population,std::uint64_t candidate){std::uint64_t x=candidate^(population+0x9e3779b97f4a7c15ULL);x=(x^(x>>30))*0xbf58476d1ce4e5b9ULL;x=(x^(x>>27))*0x94d049bb133111ebULL;x^=x>>31;return double(x>>11)*(1.0/9007199254740992.0);}
bool accepted(std::uint64_t population,std::uint64_t candidate,double mask,double density){return threshold(population,candidate)<std::clamp(mask*density,0.,1.);}
// Versioned little-endian data on the supported Windows x64 host. Never dump
// struct padding, pointers, bool layout or derived spatial caches into a scene.
std::vector<std::uint8_t> encode(const Document& d){
    if(d.strokes.size()>10000)throw std::invalid_argument("Too many Brush strokes");
    std::vector<std::uint8_t> out;auto write=[&](const auto& v){const auto* p=reinterpret_cast<const std::uint8_t*>(&v);out.insert(out.end(),p,p+sizeof(v));};
    const std::uint32_t version=2,n=static_cast<std::uint32_t>(d.strokes.size());write(version);write(d.surface);write(n);
    std::size_t total=0;
    for(const auto& s:d.strokes){validate(s);total+=s.samples.size();if(total>1000000)throw std::invalid_argument("Brush document sample limit");write(s.id);const std::uint32_t flags=(s.enabled?1u:0u)|(s.erase?2u:0u),count=static_cast<std::uint32_t>(s.samples.size());write(flags);write(s.radius);write(s.strength);write(s.softness);write(count);
        for(const auto& p:s.samples){write(p.anchor.face);write(p.anchor.bary);for(auto b:p.basis)write(b);write(p.view.eye);write(p.view.direction);const std::uint32_t perspective=p.view.perspective?1u:0u;write(perspective);write(p.ray.origin);write(p.ray.direction);for(auto v:p.screen)write(v);const std::uint32_t pathFlags=(p.hasPath?1u:0u)|(p.connected?2u:0u);write(pathFlags);}
    }return out;
}
Document decode(const std::vector<std::uint8_t>& bytes){
    std::size_t pos=0;auto read=[&](auto& v){if(sizeof(v)>bytes.size()-pos)throw std::invalid_argument("Truncated Brush document");std::memcpy(&v,bytes.data()+pos,sizeof(v));pos+=sizeof(v);};
    std::uint32_t version=0,count=0;Document d;read(version);if(version!=2)throw std::invalid_argument("Unsupported Brush document version");read(d.surface);read(count);if(count>10000)throw std::invalid_argument("Brush stroke count limit");
    std::size_t total=0;
    for(std::uint32_t i=0;i<count;++i){Stroke s;std::uint32_t flags=0,n=0;read(s.id);read(flags);if(flags>3)throw std::invalid_argument("Invalid Brush flags");s.enabled=(flags&1)!=0;s.erase=(flags&2)!=0;read(s.radius);read(s.strength);read(s.softness);read(n);total+=n;if(total>1000000||n>(bytes.size()-pos)/220)throw std::invalid_argument("Brush sample count limit");
        for(std::uint32_t j=0;j<n;++j){Sample p;read(p.anchor.face);read(p.anchor.bary);for(auto& b:p.basis)read(b);read(p.view.eye);read(p.view.direction);std::uint32_t perspective=0;read(perspective);if(perspective>1)throw std::invalid_argument("Invalid Brush view");p.view.perspective=perspective!=0;read(p.ray.origin);read(p.ray.direction);for(auto& v:p.screen)read(v);std::uint32_t pathFlags=0;read(pathFlags);if(pathFlags>3)throw std::invalid_argument("Invalid Brush path flags");p.hasPath=(pathFlags&1)!=0;p.connected=(pathFlags&2)!=0;s.samples.push_back(p);}validate(s);d.strokes.push_back(std::move(s));
    }if(pos!=bytes.size())throw std::invalid_argument("Unexpected Brush document tail");return d;
}
}
