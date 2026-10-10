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
std::vector<std::uint32_t> Surface::patch(const Sample& s,double radius,std::size_t maxFaces)const{
    checkSample(s);if(!std::isfinite(radius)||radius<=0)throw std::invalid_argument("Brush radius must be positive");
    if(!maxFaces)throw std::invalid_argument("Brush preparation face-link limit: reduce history or brush radius");
    const auto center=position(s.anchor);std::vector<std::uint32_t> result{s.anchor.face};std::vector<bool> visited(mesh().faces.size());visited[s.anchor.face]=true;
    for(std::size_t i=0;i<result.size();++i){const auto f=result[i];const auto ids=mesh().faces[f];
        for(int edge=0;edge<3;++edge){const int next=impl->neighbors[f][edge];if(next<0||visited[next])continue;
            const auto a=mapped(mesh().vertices[ids[edge]]-center,s.basis),b=mapped(mesh().vertices[ids[(edge+1)%3]]-center,s.basis);
            if(segmentDistance2(a,b)<=radius*radius){
                if(result.size()>=maxFaces)throw std::invalid_argument("Brush preparation face-link limit: reduce history or brush radius");
                visited[next]=true;result.push_back(static_cast<std::uint32_t>(next));
            }
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
Stroke resample(const Surface& surface,const Stroke& input,std::size_t maxDabs){
    validate(input);maxDabs=std::min<std::size_t>(maxDabs,1000000);
    if(input.samples.size()>maxDabs)throw std::invalid_argument("Brush preparation dab limit: reduce stroke history");
    Stroke out;out.id=input.id;out.enabled=input.enabled;out.erase=input.erase;
    out.radius=input.radius;out.strength=input.strength;out.softness=input.softness;
    auto append=[&](const Sample& dab){
        if(out.samples.size()>=maxDabs)throw std::invalid_argument("Brush preparation dab limit: reduce stroke history");
        out.samples.push_back(dab);
    };
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
                Hit hit;if(!surface.hit(dab.ray,hit))continue;dab.anchor=hit.anchor;dab.hasPath=false;dab.connected=false;append(dab);
            }
        }
        append(current);
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
namespace {
bool sameVector(Vec3 a,Vec3 b){return a.x==b.x&&a.y==b.y&&a.z==b.z;}
bool sameSample(const Sample& x,const Sample& y){
    if(x.anchor.face!=y.anchor.face||!sameVector(x.anchor.bary,y.anchor.bary)||!sameVector(x.view.eye,y.view.eye)||!sameVector(x.view.direction,y.view.direction)||x.view.perspective!=y.view.perspective||!sameVector(x.ray.origin,y.ray.origin)||!sameVector(x.ray.direction,y.ray.direction)||x.screen!=y.screen||x.hasPath!=y.hasPath||x.connected!=y.connected)return false;
    for(int j=0;j<3;++j)if(!sameVector(x.basis[j],y.basis[j]))return false;
    return true;
}
bool sameSettings(const Stroke& a,const Stroke& b){return a.id==b.id&&a.enabled==b.enabled&&a.erase==b.erase&&a.radius==b.radius&&a.strength==b.strength&&a.softness==b.softness;}
bool strokePrefix(const Stroke& old,const Stroke& next){
    if(!sameSettings(old,next)||old.samples.size()>next.samples.size())return false;
    for(std::size_t i=0;i<old.samples.size();++i)if(!sameSample(old.samples[i],next.samples[i]))return false;
    return true;
}
bool sameStroke(const Stroke& a,const Stroke& b){return a.samples.size()==b.samples.size()&&strokePrefix(a,b);}

}
struct Field::Impl {
    Surface surface;double base;Box influenceBounds;bool hasInfluence=false;FieldBuildStats stats;
    struct Link{std::uint32_t stroke,sample;};
    // Exact-size contiguous face ranges avoid per-face allocation and growth
    // slack. Entries within each face retain original stroke/dab ordering.
    std::vector<std::size_t> faceOffsets;std::vector<Link> faceLinks;
    struct CompiledStroke {
        Stroke original,stroke;
        std::vector<std::vector<std::uint32_t>> patches;
        std::vector<Vec3> centers;
        Box bounds;bool hasInfluence=false;
        std::size_t links=0;
    };
    // Immutable entries can survive append, Undo and changes to another stroke.
    // They do not retain a chain of previous Field objects.
    std::vector<std::shared_ptr<const CompiledStroke>> compiled;
    enum Reuse { reset, unchanged, append, replaceLast, extendLast };
    // Only a verified immutable derived-dab prefix permits incremental max-q.
    std::shared_ptr<const CompiledStroke> extendedFrom;
    std::size_t extensionStart=0;
    Reuse reuse(const Impl* old)const{
        if(!old||base!=old->base||surface.fingerprint()!=old->surface.fingerprint())return reset;
        const auto n=compiled.size(),m=old->compiled.size();
        std::size_t common=0;while(common<std::min(n,m)&&compiled[common]==old->compiled[common])++common;
        if(n==m&&common==n)return unchanged;
        if(n==m+1&&common==m)return append;
        if(n==m&&n&&common>=n-1)return extendedFrom==old->compiled.back()?extendLast:replaceLast;
        return reset;
    }
    double strokeValue(std::size_t index,Anchor a,std::size_t begin=0,double q=0)const{
        const auto& e=*compiled[index];const auto& stroke=e.stroke;
        if(!stroke.enabled||!e.bounds.contains(surface.position(a)))return 0;
        for(std::size_t j=begin;j<stroke.samples.size()&&q<stroke.strength;++j)
            if(std::binary_search(e.patches[j].begin(),e.patches[j].end(),a.face))
                q=std::max(q,influence(surface,stroke.samples[j],stroke,a));
        return q;
    }
    double rangeValue(Anchor a,std::size_t end)const{
        double value=base;
        for(std::size_t i=0;i<end;++i)value=apply(value,strokeValue(i,a),compiled[i]->stroke.erase);
        return value;
    }
    double rangeStep(std::uint32_t face,const std::array<Vec3,3>& bary,std::size_t begin,std::size_t end,std::size_t firstSample=0)const{
        double step=INFINITY;
        for(auto i=begin;i<end;++i){const auto& entry=*compiled[i];const auto& stroke=entry.stroke;
            if(!stroke.enabled)continue;
            for(std::size_t j=i==begin?firstSample:0;j<stroke.samples.size();++j){
                if(!std::binary_search(entry.patches[j].begin(),entry.patches[j].end(),face))continue;
                const auto& sample=stroke.samples[j];Vec3 lo{INFINITY,INFINITY,INFINITY},hi{-INFINITY,-INFINITY,-INFINITY};
                for(auto b:bary){auto p=mapped(surface.position({face,b})-entry.centers[j],sample.basis);lo={std::min(lo.x,p.x),std::min(lo.y,p.y),std::min(lo.z,p.z)};hi={std::max(hi.x,p.x),std::max(hi.y,p.y),std::max(hi.z,p.z)};}
                const Vec3 nearest{std::clamp(0.,lo.x,hi.x),std::clamp(0.,lo.y,hi.y),std::clamp(0.,lo.z,hi.z)};
                if(amin::dot(nearest,nearest)>stroke.radius*stroke.radius)continue;
                double norm=0;for(auto basis:sample.basis)norm+=amin::dot(basis,basis);
                if(norm>0)step=std::min(step,stroke.radius*.4/std::sqrt(norm));
            }
        }return step;
    }
    struct Value {double before=0,full=0,q=0;bool valid=false;};
    void updateValue(Value& v,Anchor a,Reuse mode)const{
        if(v.valid&&mode==unchanged)return;
        const auto n=compiled.size();
        if(!v.valid||mode==reset)v.before=rangeValue(a,n?n-1:0);
        else if(mode==append)v.before=v.full;
        v.q=n?strokeValue(n-1,a,v.valid&&mode==extendLast?extensionStart:0,v.valid&&mode==extendLast?v.q:0):0;
        v.full=n?apply(v.before,v.q,compiled.back()->stroke.erase):base;
        v.valid=true;
    }
    Impl(const Surface& s,const Document& d,const Impl* previous,FieldLimits limits,const Stroke* pending):surface(s),base(d.base){
        if(d.surface!=s.fingerprint())throw std::invalid_argument("Brush surface changed; rebind required");
        if(!std::isfinite(d.base)||d.base<0||d.base>1)throw std::invalid_argument("Invalid Brush base density");
        if(d.strokes.size()+(pending?1:0)>10000)throw std::invalid_argument("Too many Brush strokes");
        std::vector<const Stroke*> inputs;inputs.reserve(d.strokes.size()+1);
        for(const auto& stroke:d.strokes)inputs.push_back(&stroke);
        if(pending)inputs.push_back(pending);
        if(previous&&previous->surface.fingerprint()!=s.fingerprint())previous=nullptr;
        // A caller may lower the limits for qualification, never bypass them.
        limits.dabs=std::min<std::size_t>(limits.dabs,1000000);
        limits.faceLinks=std::min<std::size_t>(limits.faceLinks,8000000);
        std::size_t storedSamples=0;
        for(const auto* input:inputs){
            const auto& stroke=*input;
            if(stroke.samples.size()>limits.dabs-storedSamples)throw std::invalid_argument("Brush document sample limit");
            storedSamples+=stroke.samples.size();
        }
        compiled.reserve(inputs.size());
        for(std::uint32_t i=0;i<inputs.size();++i){
            if(previous&&i<previous->compiled.size()&&sameStroke(*inputs[i],previous->compiled[i]->original)){
                compiled.push_back(previous->compiled[i]);++stats.reusedStrokes;
            }else{
            auto entry=std::make_shared<CompiledStroke>();entry->stroke=resample(s,*inputs[i],limits.dabs-stats.derivedDabs);entry->original=*inputs[i];
            const auto& stroke=entry->stroke;entry->patches.resize(stroke.samples.size());++stats.compiledStrokes;
            if(stroke.enabled)
            for(std::uint32_t j=0;j<stroke.samples.size();++j){
                const auto& sample=stroke.samples[j];const auto center=s.position(sample.anchor);entry->centers.push_back(center);
                // Conservative local bounds of the world-space spherical footprint.
                // Inverse basis columns handle nonuniform scale, shear and reflection.
                const auto x=cross(sample.basis[1],sample.basis[2]),y=cross(sample.basis[2],sample.basis[0]),z=cross(sample.basis[0],sample.basis[1]);
                const double factor=stroke.radius/std::abs(amin::dot(sample.basis[0],x));
                const Vec3 extent{amin::length(x)*factor,amin::length(y)*factor,amin::length(z)*factor};
                entry->bounds.add(center-extent);entry->bounds.add(center+extent);entry->hasInfluence=true;
                entry->patches[j]=s.patch(sample,stroke.radius,limits.faceLinks-stats.faceLinks-entry->links);
                entry->links+=entry->patches[j].size();
            }
            compiled.push_back(std::move(entry));
            }
            const auto& entry=*compiled.back();
            if(entry.stroke.samples.size()>limits.dabs-stats.derivedDabs)throw std::invalid_argument("Brush preparation dab limit: reduce stroke history");
            if(entry.links>limits.faceLinks-stats.faceLinks)throw std::invalid_argument("Brush preparation face-link limit: reduce history or brush radius");
            stats.derivedDabs+=entry.stroke.samples.size();stats.faceLinks+=entry.links;
            if(entry.hasInfluence){influenceBounds.add(entry.bounds.lo);influenceBounds.add(entry.bounds.hi);hasInfluence=true;}
        }
        if(previous&&!compiled.empty()&&compiled.size()==previous->compiled.size()){
            const auto& old=previous->compiled.back();const auto& last=compiled.back();
            if(old!=last&&strokePrefix(old->stroke,last->stroke)){
                extendedFrom=old;extensionStart=old->stroke.samples.size();
            }
        }
        faceOffsets.resize(s.mesh().faces.size()+1);
        for(const auto& entry:compiled)for(const auto& patch:entry->patches)for(auto f:patch)++faceOffsets[f+1];
        std::partial_sum(faceOffsets.begin(),faceOffsets.end(),faceOffsets.begin());
        faceLinks.resize(static_cast<std::size_t>(stats.faceLinks));
        auto cursor=faceOffsets;
        for(std::uint32_t i=0;i<compiled.size();++i){const auto& patches=compiled[i]->patches;
            for(std::uint32_t j=0;j<patches.size();++j)for(auto f:patches[j])faceLinks[cursor[f]++]={i,j};
        }
        stats.indexBytes=faceOffsets.capacity()*sizeof(std::size_t)+faceLinks.capacity()*sizeof(Link);
    }
};
Field::Field(const Surface& s,const Document& d,const Field* previous,FieldLimits limits,const Stroke* pending):impl(std::make_shared<Impl>(s,d,previous?previous->impl.get():nullptr,limits,pending)){}
FieldBuildStats Field::buildStats()const{return impl->stats;}

double Field::previewStep(std::uint32_t face,const std::array<Vec3,3>& bary)const{
    double step=std::numeric_limits<double>::infinity();
    for(auto i=impl->faceOffsets.at(face);i<impl->faceOffsets.at(std::size_t(face)+1);++i){
        const auto link=impl->faceLinks[i];
        const auto& entry=*impl->compiled[link.stroke];const auto& stroke=entry.stroke;const auto& sample=stroke.samples[link.sample];
        Vec3 lo{INFINITY,INFINITY,INFINITY},hi{-INFINITY,-INFINITY,-INFINITY};
        for(auto b:bary){auto p=mapped(impl->surface.position({face,b})-entry.centers[link.sample],sample.basis);lo={std::min(lo.x,p.x),std::min(lo.y,p.y),std::min(lo.z,p.z)};hi={std::max(hi.x,p.x),std::max(hi.y,p.y),std::max(hi.z,p.z)};}
        const Vec3 nearest{std::clamp(0.,lo.x,hi.x),std::clamp(0.,lo.y,hi.y),std::clamp(0.,lo.z,hi.z)};
        if(amin::dot(nearest,nearest)>stroke.radius*stroke.radius)continue;
        double norm=0;for(auto basis:sample.basis)norm+=amin::dot(basis,basis);
        if(norm>0)step=std::min(step,stroke.radius*.4/std::sqrt(norm));
    }
    return step;
}
Coverage coverage(const Surface& surface,const Field& field,std::size_t budget){
    Coverage result;if(budget==0){result.limited=true;return result;}
    struct Part {std::uint32_t face;std::array<Vec3,3> bary;unsigned depth;};
    std::vector<Part> stack;std::size_t visited=0;
    const auto count=surface.mesh().faces.size();
    const auto stride=std::max<std::size_t>(1,(count+budget-1)/budget);
    result.limited=stride>1;
    for(std::size_t face=0;face<count;face+=stride){
        stack.push_back({static_cast<std::uint32_t>(face),{{{1,0,0},{0,1,0},{0,0,1}}},0});
        while(!stack.empty()){
            if(visited++>=budget*12||result.triangles.size()>=budget){result.limited=true;return result;}
            auto part=stack.back();stack.pop_back();std::array<Vec3,3> vertices;
            for(int i=0;i<3;++i)vertices[i]=surface.position({part.face,part.bary[i]});
            const auto step=field.previewStep(part.face,part.bary);
            const auto longest=std::max({amin::length(vertices[0]-vertices[1]),amin::length(vertices[1]-vertices[2]),amin::length(vertices[2]-vertices[0])});
            if(std::isfinite(step)&&longest>step&&part.depth<16){
                const auto a=(part.bary[0]+part.bary[1])*.5,b=(part.bary[1]+part.bary[2])*.5,c=(part.bary[2]+part.bary[0])*.5;
                stack.push_back({part.face,{{a,b,c}},part.depth+1});
                stack.push_back({part.face,{{c,b,part.bary[2]}},part.depth+1});
                stack.push_back({part.face,{{a,part.bary[1],b}},part.depth+1});
                stack.push_back({part.face,{{part.bary[0],a,c}},part.depth+1});continue;
            }
            if(std::isfinite(step)&&longest>step)result.limited=true;
            const auto weight=field.evaluate({part.face,(part.bary[0]+part.bary[1]+part.bary[2])*(1./3)});
            if(weight>0)result.triangles.push_back({vertices,weight});
        }
    }
    return result;
}

struct CoverageCache::Impl {
    struct Node {double before=INFINITY,step=INFINITY;Field::Impl::Value value;bool valid=false;std::uint64_t stepEpoch=0,valueEpoch=0;};
    std::map<std::pair<std::uint32_t,std::uint64_t>,Node> nodes;
    std::unique_ptr<Field> previous;
    std::uint64_t epoch=0;
};
CoverageCache::CoverageCache():impl(std::make_unique<Impl>()){}
CoverageCache::~CoverageCache()=default;
void CoverageCache::clear(){impl=std::make_unique<Impl>();}
std::size_t CoverageCache::size()const{return impl->nodes.size();}
Coverage CoverageCache::build(const Surface& surface,const Field& field,std::size_t budget){
    if(surface.fingerprint()!=field.impl->surface.fingerprint())throw std::invalid_argument("Preview surface differs from field");
    budget=std::min<std::size_t>(budget,32768);
    const auto& f=*field.impl;auto mode=f.reuse(impl->previous?impl->previous->impl.get():nullptr);
    if(mode==Field::Impl::reset)impl->nodes.clear();
    Coverage result;if(!budget){result.limited=true;clear();return result;}
    struct Part{std::uint32_t face;std::array<Vec3,3> bary;unsigned depth;std::uint64_t path;};
    std::vector<Part> stack;std::size_t visited=0;
    const auto count=surface.mesh().faces.size(),stride=std::max<std::size_t>(1,(count+budget-1)/budget),n=f.compiled.size();
    result.limited=stride>1;
    try {
        for(std::size_t face=0;face<count;face+=stride){
            stack.push_back({std::uint32_t(face),{{{1,0,0},{0,1,0},{0,0,1}}},0,1});
            while(!stack.empty()){
                if(visited++>=budget*12||result.triangles.size()>=budget){result.limited=true;goto done;}
                auto p=stack.back();stack.pop_back();std::array<Vec3,3> vertices;
                for(int i=0;i<3;++i)vertices[i]=surface.position({p.face,p.bary[i]});
                auto key=std::make_pair(p.face,p.path);auto found=impl->nodes.find(key);
                // Nodes no longer visited after radius edits must not grow the
                // cache without bound. Eviction affects performance, not paint.
                if(found==impl->nodes.end()&&impl->nodes.size()>=budget*12){impl->nodes.clear();mode=Field::Impl::reset;}
                auto& node=impl->nodes[key];
                const auto stepMode=node.stepEpoch==impl->epoch?mode:Field::Impl::reset;
                if(!node.valid||stepMode!=Field::Impl::unchanged){
                    if(!node.valid||stepMode==Field::Impl::reset)node.before=f.rangeStep(p.face,p.bary,0,n?n-1:0);
                    else if(stepMode==Field::Impl::append)node.before=node.step;
                    node.step=std::min(stepMode==Field::Impl::extendLast?node.step:node.before,
                        f.rangeStep(p.face,p.bary,n?n-1:0,n,stepMode==Field::Impl::extendLast?f.extensionStart:0));node.valid=true;
                }
                node.stepEpoch=impl->epoch+1;
                const auto longest=std::max({amin::length(vertices[0]-vertices[1]),amin::length(vertices[1]-vertices[2]),amin::length(vertices[2]-vertices[0])});
                if(std::isfinite(node.step)&&longest>node.step&&p.depth<16){
                    const auto a=(p.bary[0]+p.bary[1])*.5,b=(p.bary[1]+p.bary[2])*.5,c=(p.bary[2]+p.bary[0])*.5;
                    stack.push_back({p.face,{{a,b,c}},p.depth+1,p.path*4});
                    stack.push_back({p.face,{{c,b,p.bary[2]}},p.depth+1,p.path*4+1});
                    stack.push_back({p.face,{{a,p.bary[1],b}},p.depth+1,p.path*4+2});
                    stack.push_back({p.face,{{p.bary[0],a,c}},p.depth+1,p.path*4+3});continue;
                }
                if(std::isfinite(node.step)&&longest>node.step)result.limited=true;
                f.updateValue(node.value,{p.face,(p.bary[0]+p.bary[1]+p.bary[2])*(1./3)},node.valueEpoch==impl->epoch?mode:Field::Impl::reset);
                node.valueEpoch=impl->epoch+1;
                if(node.value.full>0)result.triangles.push_back({vertices,node.value.full});
            }
        }
        done: impl->previous=std::make_unique<Field>(field);++impl->epoch;
    }catch(...){clear();throw;}
    return result;
}
struct SampleCache::Impl {
    std::unique_ptr<Field> previous;std::vector<Anchor> anchors;std::vector<Field::Impl::Value> values;
};
SampleCache::SampleCache():impl(std::make_unique<Impl>()){}
SampleCache::~SampleCache()=default;
void SampleCache::clear(){impl=std::make_unique<Impl>();}
std::vector<double> SampleCache::evaluate(const Field& field,const std::vector<Anchor>& anchors){
    if(anchors.size()>100000)throw std::invalid_argument("Feedback sample limit");
    const auto& f=*field.impl;auto mode=f.reuse(impl->previous?impl->previous->impl.get():nullptr);
    bool same=anchors.size()==impl->anchors.size();
    for(std::size_t i=0;same&&i<anchors.size();++i)same=anchors[i].face==impl->anchors[i].face&&sameVector(anchors[i].bary,impl->anchors[i].bary);
    if(!same||mode==Field::Impl::reset){impl->values.assign(anchors.size(),{});impl->anchors=anchors;mode=Field::Impl::reset;}
    std::vector<double> result;result.reserve(anchors.size());
    try{for(std::size_t i=0;i<anchors.size();++i){f.updateValue(impl->values[i],anchors[i],mode);result.push_back(impl->values[i].full);}
        impl->previous=std::make_unique<Field>(field);
    }catch(...){clear();throw;}return result;
}

double Field::evaluate(Anchor a,QueryStats* stats)const{
    const auto position=impl->surface.position(a);if(stats)++stats->fieldQueries;
    if(!impl->hasInfluence||!impl->influenceBounds.contains(position))return impl->base;
    // Each stroke is affine: paint q+(1-q)*old, erase (1-q)*old.
    // Compose backwards. Opaque coverage makes all older history irrelevant;
    // stop exactly at zero transmission, never at an approximate threshold.
    double value=0,transmission=1;
    const auto& links=impl->faceLinks;
    const auto begin=impl->faceOffsets[a.face];std::size_t end=impl->faceOffsets[std::size_t(a.face)+1];
    while(end>begin && transmission>0){
        const auto index=links[end-1].stroke;
        const auto& entry=*impl->compiled[index];const auto& stroke=entry.stroke;
        double q=0;
        do {
            const auto link=links[--end];
            if(q>=stroke.strength)continue;
            if(stats)++stats->dabs;
            const auto& dab=stroke.samples[link.sample];
            const double ratio=amin::length(mapped(position-entry.centers[link.sample],dab.basis))/stroke.radius;
            if(ratio>=1)continue;
            double candidate=stroke.strength;
            if(stroke.softness>0&&ratio>1-stroke.softness){const double x=(ratio-(1-stroke.softness))/stroke.softness;candidate*=1-x*x*(3-2*x);}
            if(candidate>q&&impl->surface.visible(a,dab.view,stats))q=candidate;
        }while(end>begin && links[end-1].stroke==index);
        if(!stroke.erase)value+=transmission*q;
        transmission*=1-q;
    }
    return std::clamp(value+transmission*impl->base,0.,1.);
}

bool Field::accepts(Anchor a,double u,double density,QueryStats* stats)const{
    if(!std::isfinite(u)||u<0||u>=1||!std::isfinite(density)||density<0||density>1)throw std::invalid_argument("Invalid Brush membership query");
    const auto position=impl->surface.position(a);if(stats)++stats->fieldQueries;
    if(!impl->hasInfluence||!impl->influenceBounds.contains(position))return u<std::clamp(impl->base*density,0.,1.);
    // Each stroke is affine: paint q+(1-q)*old, erase (1-q)*old.
    // Compose backwards. Opaque coverage makes all older history irrelevant;
    // stop exactly at zero transmission, never at an approximate threshold.
    double value=0,transmission=1;
    const double guard=64*std::numeric_limits<double>::epsilon()*(impl->compiled.size()+1);
    const auto& links=impl->faceLinks;
    const auto begin=impl->faceOffsets[a.face];std::size_t end=impl->faceOffsets[std::size_t(a.face)+1];
    while(end>begin && transmission>0){
        const auto index=links[end-1].stroke;
        const auto& entry=*impl->compiled[index];const auto& stroke=entry.stroke;
        double q=0;
        do {
            const auto link=links[--end];
            if(q>=stroke.strength)continue;
            if(stats)++stats->dabs;
            const auto& dab=stroke.samples[link.sample];
            const double ratio=amin::length(mapped(position-entry.centers[link.sample],dab.basis))/stroke.radius;
            if(ratio>=1)continue;
            double candidate=stroke.strength;
            if(stroke.softness>0&&ratio>1-stroke.softness){const double x=(ratio-(1-stroke.softness))/stroke.softness;candidate*=1-x*x*(3-2*x);}
            if(candidate>q&&impl->surface.visible(a,dab.view,stats))q=candidate;
        }while(end>begin && links[end-1].stroke==index);
        if(!stroke.erase)value+=transmission*q;
        transmission*=1-q;
        if(value*density>u+guard)return true;
        if((value+transmission)*density<u-guard)return false;
    }
    return u<std::clamp(std::clamp(value+transmission*impl->base,0.,1.)*density,0.,1.);
}

double Field::evaluateReference(Anchor a,QueryStats* stats)const{
    impl->surface.position(a);double value=impl->base;
    for(const auto& entry:impl->compiled){const auto& stroke=entry->stroke;if(!stroke.enabled)continue;double q=0;
        for(std::size_t j=0;j<stroke.samples.size();++j){const auto& patch=entry->patches[j];if(std::binary_search(patch.begin(),patch.end(),a.face))q=std::max(q,influence(impl->surface,stroke.samples[j],stroke,a,stats));}
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
    if(!std::isfinite(d.base)||d.base<0||d.base>1)throw std::invalid_argument("Invalid Brush base density");
    const std::uint32_t version=3,n=static_cast<std::uint32_t>(d.strokes.size());write(version);write(d.surface);write(d.base);write(n);
    std::size_t total=0;
    for(const auto& s:d.strokes){validate(s);total+=s.samples.size();if(total>1000000)throw std::invalid_argument("Brush document sample limit");write(s.id);const std::uint32_t flags=(s.enabled?1u:0u)|(s.erase?2u:0u),count=static_cast<std::uint32_t>(s.samples.size());write(flags);write(s.radius);write(s.strength);write(s.softness);write(count);
        for(const auto& p:s.samples){write(p.anchor.face);write(p.anchor.bary);for(auto b:p.basis)write(b);write(p.view.eye);write(p.view.direction);const std::uint32_t perspective=p.view.perspective?1u:0u;write(perspective);write(p.ray.origin);write(p.ray.direction);for(auto v:p.screen)write(v);const std::uint32_t pathFlags=(p.hasPath?1u:0u)|(p.connected?2u:0u);write(pathFlags);}
    }return out;
}
Document decode(const std::vector<std::uint8_t>& bytes){
    std::size_t pos=0;auto read=[&](auto& v){if(sizeof(v)>bytes.size()-pos)throw std::invalid_argument("Truncated Brush document");std::memcpy(&v,bytes.data()+pos,sizeof(v));pos+=sizeof(v);};
    std::uint32_t version=0,count=0;Document d;read(version);if(version!=2&&version!=3)throw std::invalid_argument("Unsupported Brush document version");read(d.surface);if(version>=3)read(d.base);if(!std::isfinite(d.base)||d.base<0||d.base>1)throw std::invalid_argument("Invalid Brush base density");read(count);if(count>10000)throw std::invalid_argument("Brush stroke count limit");
    std::size_t total=0;
    for(std::uint32_t i=0;i<count;++i){Stroke s;std::uint32_t flags=0,n=0;read(s.id);read(flags);if(flags>3)throw std::invalid_argument("Invalid Brush flags");s.enabled=(flags&1)!=0;s.erase=(flags&2)!=0;read(s.radius);read(s.strength);read(s.softness);read(n);total+=n;if(total>1000000||n>(bytes.size()-pos)/220)throw std::invalid_argument("Brush sample count limit");
        for(std::uint32_t j=0;j<n;++j){Sample p;read(p.anchor.face);read(p.anchor.bary);for(auto& b:p.basis)read(b);read(p.view.eye);read(p.view.direction);std::uint32_t perspective=0;read(perspective);if(perspective>1)throw std::invalid_argument("Invalid Brush view");p.view.perspective=perspective!=0;read(p.ray.origin);read(p.ray.direction);for(auto& v:p.screen)read(v);std::uint32_t pathFlags=0;read(pathFlags);if(pathFlags>3)throw std::invalid_argument("Invalid Brush path flags");p.hasPath=(pathFlags&1)!=0;p.connected=(pathFlags&2)!=0;s.samples.push_back(p);}validate(s);d.strokes.push_back(std::move(s));
    }if(pos!=bytes.size())throw std::invalid_argument("Unexpected Brush document tail");return d;
}
}
