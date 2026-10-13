#include "spline_overlay.h"
#include <algorithm>
#include <array>
#include <cmath>
#include <limits>
#include <numeric>
#include <stdexcept>

namespace cyrus::bands {
namespace {
using amin::Vec3;
void require(bool ok,const char* error){if(!ok)throw std::invalid_argument(error);}
bool finite(Vec3 p){return std::isfinite(p.x)&&std::isfinite(p.y)&&std::isfinite(p.z);}
Vec3 cross(Vec3 a,Vec3 b){return {a.y*b.z-a.z*b.y,a.z*b.x-a.x*b.z,a.x*b.y-a.y*b.x};}
void spend(std::size_t& used,std::size_t n,std::size_t cap){
    require(used<=cap&&n<=cap-used,"Field preview work allowance exceeded; reduce samples or simplify receivers");used+=n;
}
double halton(std::size_t n,std::size_t base){double value=0,scale=1;while(n){scale/=double(base);value+=double(n%base)*scale;n/=base;}return value;}
struct Box {
    double x0=INFINITY,y0=INFINITY,x1=-INFINITY,y1=-INFINITY;
    void add(Vec3 p){x0=std::min(x0,p.x);y0=std::min(y0,p.y);x1=std::max(x1,p.x);y1=std::max(y1,p.y);}
    bool intersects(Vec3 a,Vec3 b) const {
        const double epsilon=64*std::numeric_limits<double>::epsilon()*
            std::max({std::abs(a.x),std::abs(a.y),std::abs(b.x),std::abs(b.y),std::abs(x0),std::abs(y0),std::abs(x1),std::abs(y1)});
        return std::min(a.x,b.x)<=x1+epsilon&&std::max(a.x,b.x)>=x0-epsilon&&
               std::min(a.y,b.y)<=y1+epsilon&&std::max(a.y,b.y)>=y0-epsilon;
    }
};
struct Node {Box box;std::uint32_t begin=0,end=0,left=0,right=0;};
struct SurfaceIndex {
    const std::vector<ReceiverTriangle>& triangles;
    std::vector<std::uint32_t> order;
    std::vector<Node> nodes;
    std::size_t& work;const std::size_t limit;
    std::uint32_t build(std::uint32_t begin,std::uint32_t end){
        const auto id=std::uint32_t(nodes.size());nodes.push_back({});Box box;
        for(auto i=begin;i<end;++i){spend(work,1,limit);const auto& t=triangles[order[i]];for(auto p:{t.a,t.b,t.c})box.add(p);}
        nodes[id].box=box;nodes[id].begin=begin;nodes[id].end=end;
        if(end-begin>8){
            const bool x=(box.x1-box.x0)>(box.y1-box.y0);const auto mid=begin+(end-begin)/2;
            const auto center=[&](std::uint32_t i){const auto& t=triangles[i];return x?t.a.x/3+t.b.x/3+t.c.x/3:t.a.y/3+t.b.y/3+t.c.y/3;};
            std::nth_element(order.begin()+begin,order.begin()+mid,order.begin()+end,[&](auto a,auto b){
                spend(work,1,limit);const auto ca=center(a),cb=center(b);return ca==cb?a<b:ca<cb;});
            const auto left=build(begin,mid),right=build(mid,end);nodes[id].left=left;nodes[id].right=right;
        }
        return id;
    }
    SurfaceIndex(const std::vector<ReceiverTriangle>& input,std::size_t& workCount,std::size_t workLimit):
        triangles(input),work(workCount),limit(workLimit) {
        order.resize(input.size());std::iota(order.begin(),order.end(),0u);nodes.reserve(input.size()*2);
        if(!input.empty())build(0,std::uint32_t(input.size()));
    }
};
// Intersect a vertical curtain over one XY outline segment with a triangle.
// This visits EVERY receiver elevation; no highest-surface ray projection.
template<class Emit> void clipTriangle(const ReceiverTriangle& t,Vec3 a,Vec3 b,Emit&& emit){
    const double length=std::hypot(b.x-a.x,b.y-a.y);if(!(length>0))return;
    require(std::isfinite(length),"Nonfinite field boundary length");
    const double dx=(b.x-a.x)/length,dy=(b.y-a.y)/length;
    const auto along=[&](Vec3 p){return (p.x-a.x)*dx+(p.y-a.y)*dy;};
    const auto side=[&](Vec3 p){return (p.y-a.y)*dx-(p.x-a.x)*dy;};
    const double scale=std::max({length,std::abs(a.x),std::abs(a.y),std::abs(b.x),std::abs(b.y),
        std::abs(t.a.x),std::abs(t.a.y),std::abs(t.b.x),std::abs(t.b.y),std::abs(t.c.x),std::abs(t.c.y)});
    const double epsilon=64*std::numeric_limits<double>::epsilon()*scale;
    const std::array<Vec3,3> vertices{t.a,t.b,t.c};std::array<double,3> distances;
    for(std::size_t i=0;i<3;++i){const double d=side(vertices[i]);distances[i]=std::abs(d)<=epsilon?0:d;}
    if(distances[0]==0&&distances[1]==0&&distances[2]==0){
        // A vertical face can coincide with the curtain. Display the clipped
        // face perimeter, including its slab cuts, rather than drop the face.
        std::array<Vec3,8> polygon{},next{};std::copy(vertices.begin(),vertices.end(),polygon.begin());std::size_t n=3;
        for(int plane=0;plane<2;++plane){std::size_t count=0;
            for(std::size_t i=0;i<n;++i){const auto u=polygon[i],v=polygon[(i+1)%n];
                const double du=plane?length-along(u):along(u),dv=plane?length-along(v):along(v);
                if(du>=0)next[count++]=u;
                if((du>=0)!=(dv>=0))next[count++]=u+(v-u)*(du/(du-dv));
            }
            polygon=next;n=count;
        }
        for(std::size_t i=0;i<n;++i)emit(polygon[i],polygon[(i+1)%n]);return;
    }
    std::array<Vec3,6> hits{};std::size_t n=0;
    for(std::size_t i=0;i<3;++i){const auto j=(i+1)%3;
        if(distances[i]==0)hits[n++]=vertices[i];
        if((distances[i]<0&&distances[j]>0)||(distances[i]>0&&distances[j]<0))
            hits[n++]=vertices[i]+(vertices[j]-vertices[i])*(distances[i]/(distances[i]-distances[j]));
    }
    if(n<2)return;
    Vec3 u=hits[0],v=hits[1];double maximum=amin::dot(v-u,v-u);
    for(std::size_t i=0;i<n;++i)for(std::size_t j=i+1;j<n;++j){const auto delta=hits[j]-hits[i];const double d=amin::dot(delta,delta);
        if(d>maximum){maximum=d;u=hits[i];v=hits[j];}}
    double tu=along(u),tv=along(v);if(tu>tv){std::swap(tu,tv);std::swap(u,v);}
    if(tv<0||tu>length)return;
    const auto delta=v-u;const double span=tv-tu;
    if(span>0){const auto original=u;if(tu<0)u=original+delta*(-tu/span);if(tv>length)v=original+delta*((length-tu)/span);}
    emit(u,v);
}
}

std::size_t overlayPreparationBytes(std::size_t faces,const OverlayOptions& options,const OverlayLimits& limits){
    require(limits.faces<=200000&&limits.samples<=20000&&limits.lines<=100000&&limits.work<=50000000&&limits.bytes<=64u*1024u*1024u,
        "Field preview limits exceed the supported maximum");
    require(faces<=limits.faces,"Field preview exceeds 200,000 receiver faces; simplify receivers");
    require(options.samples<=limits.samples&&(!options.falloff||options.samples>0),"Field preview needs 1..20,000 samples");
    const auto samples=options.falloff?options.samples:0;
    require(samples<=limits.lines/3,"Field sample glyphs exceed the display line allowance");
    // Exact-reserved arrays, the worst-case BVH, all input copies and allocator
    // slack. Output conversion/SDK/GPU copies are admitted separately by the
    // native preview owner while this preparation reservation is still live.
    const auto bytes=faces*(sizeof(ReceiverTriangle)+2*sizeof(Node)+2*sizeof(std::uint32_t)+sizeof(double)+sizeof(Vec3)+1)+
        samples*sizeof(OverlaySample)+limits.lines*sizeof(OverlayLine)+1024u*1024u;
    require(bytes<=limits.bytes,"Field preparation exceeds the 64 MiB allowance; reduce samples or receiver complexity");return bytes;
}

Overlay buildOverlay(const Field& field,const std::vector<ReceiverTriangle>& triangles,const OverlayOptions& options,const OverlayLimits& limits){
    Overlay result;auto& stats=result.stats;stats.preparationBytes=overlayPreparationBytes(triangles.size(),options,limits);
    // Split admission before either component starts, so outline construction
    // plus field queries/clipping can never execute twice the advertised work.
    auto outlineLimits=limits.outlines;
    outlineLimits.work=options.boundaries?std::min(outlineLimits.work,limits.work/2):0;
    const auto geometryWork=limits.work-outlineLimits.work;
    require(!options.band||field.hasBand(options.band),"Selected Band no longer exists");
    stats.faces=triangles.size();result.lines.reserve(limits.lines);
    const auto count=options.falloff?options.samples:0;result.samples.reserve(count);
    std::vector<double> areas;areas.reserve(triangles.size());std::vector<Vec3> normals;normals.reserve(triangles.size());
    std::vector<std::uint32_t> order(triangles.size());std::iota(order.begin(),order.end(),0u);
    std::vector<std::uint8_t> sampled(triangles.size(),0);
    for(const auto& t:triangles){spend(stats.work,1,geometryWork);
        require(t.receiver&&finite(t.a)&&finite(t.b)&&finite(t.c),"Invalid field receiver identity or coordinates");
        const auto normal=cross(t.b-t.a,t.c-t.a);const double size=amin::length(normal);
        require(std::isfinite(size),"Field receiver area overflow");areas.push_back(size*.5);normals.push_back(size>0?normal*(1/size):Vec3{});
        stats.area+=size*.5;if(size==0)++stats.degenerate;
    }
    require(std::isfinite(stats.area),"Field receiver area overflow");
    std::sort(order.begin(),order.end(),[&](auto a,auto b){spend(stats.work,1,geometryWork);const auto& x=triangles[a];const auto& y=triangles[b];
        return x.receiver==y.receiver?x.face<y.face:x.receiver<y.receiver;});
    std::uint64_t previous=0;double receiverArea=0;
    for(std::size_t i=0;i<order.size();++i){const auto& t=triangles[order[i]];
        if(i){const auto& before=triangles[order[i-1]];require(t.receiver!=before.receiver||t.face!=before.face,"Duplicate field receiver face identity");}
        if(t.receiver!=previous){if(receiverArea>0)++stats.receivers;receiverArea=0;previous=t.receiver;}receiverArea+=areas[order[i]];
    }
    if(receiverArea>0)++stats.receivers;
    require(!options.falloff||count>=stats.receivers,"Field sample budget is smaller than the nonempty receiver count");
    const auto line=[&](Vec3 a,Vec3 b,std::uint32_t index,std::uint8_t color){
        // Adjacent clipping planes can leave a floating-point sliver at an
        // exact corner. Reject only coordinate-roundoff-sized segments; using
        // a fixed world-unit epsilon would change the field on unit rescale.
        const double epsilon=64*std::numeric_limits<double>::epsilon()*std::max({
            std::abs(a.x),std::abs(a.y),std::abs(a.z),std::abs(b.x),std::abs(b.y),std::abs(b.z)});
        if(amin::length(b-a)<=epsilon)return;
        require(result.lines.size()<limits.lines,"Field preview exceeds 100,000 clipped lines; simplify receivers or select one Band");
        const auto& t=triangles[index];result.lines.push_back({a,b,normals[index],t.receiver,t.face,color});if(color==33)++stats.boundaryLines;
    };
    if(options.falloff&&stats.area>0){
        double cumulative=0;std::size_t extraBefore=0;const auto extra=count-stats.receivers;
        // One sample per nonempty receiver first. Distribute the remainder by
        // true 3D area so stacked and vertical receivers all participate.
        for(std::size_t begin=0;begin<order.size();){std::size_t end=begin;const auto receiver=triangles[order[begin]].receiver;double area=0;
            while(end<order.size()&&triangles[order[end]].receiver==receiver){area+=areas[order[end]];areas[order[end]]=area;++end;}
            if(area>0){++stats.sampledReceivers;cumulative+=area;
                const auto through=stats.sampledReceivers==stats.receivers?extra:std::min(extra,std::size_t(std::floor(double(extra)*(cumulative/stats.area))));
                const auto n=1+through-extraBefore;extraBefore=through;
                for(std::size_t i=0;i<n;++i){spend(stats.work,1,geometryWork);const double target=area*((double(i)+.5)/double(n));
                    const auto at=std::upper_bound(order.begin()+begin,order.begin()+end,target,[&](double value,std::uint32_t face){return value<areas[face];});
                    require(at!=order.begin()+end,"Field area sampling overflow");const auto index=*at;const auto& t=triangles[index];
                    const double root=std::sqrt(halton(i+1,2)),v=halton(i+1,3);const Vec3 bary{1-root,root*(1-v),root*v};
                    const auto position=t.a*bary.x+t.b*bary.y+t.c*bary.z;const auto value=field.inspect(position,geometryWork-stats.work);spend(stats.work,value.visits,geometryWork);
                    double density=value.occupancy,error=value.error;
                    if(options.band){density=0;error=0;for(const auto& contribution:value.contributions)if(contribution.band==options.band){density=contribution.value;error=contribution.error;break;}}
                    result.samples.push_back({position,bary,t.receiver,t.face,density,error});if(!sampled[index]){sampled[index]=1;++stats.sampledFaces;}
                    const auto color=std::uint8_t(std::clamp(std::lround(density*32),0l,32l));
                    const double span=std::max({amin::length(t.b-t.a),amin::length(t.c-t.b),amin::length(t.a-t.c)});
                    const double factor=std::min(.08,std::sqrt(area/double(n))*.25/span);
                    const std::array<Vec3,3> glyph{position+(t.a-position)*factor,position+(t.b-position)*factor,position+(t.c-position)*factor};
                    for(std::size_t k=0;k<3;++k)line(glyph[k],glyph[(k+1)%3],index,color);
                }
            }
            begin=end;
        }
    }
    if(options.boundaries&&!triangles.empty()){
        SurfaceIndex index(triangles,stats.work,geometryWork);
        stats.outlines=field.visitOutlines(options.band,[&](Vec3 a,Vec3 b){
            std::array<std::uint32_t,32> stack{};std::size_t n=1;stack[0]=0;
            while(n){spend(stats.work,1,geometryWork);const auto& node=index.nodes[stack[--n]];if(!node.box.intersects(a,b))continue;
                if(node.right){require(n+2<=stack.size(),"Field receiver index depth exceeded");stack[n++]=node.right;stack[n++]=node.left;continue;}
                for(auto k=node.begin;k<node.end;++k){spend(stats.work,1,geometryWork);const auto face=index.order[k];
                    if(normals[face].x==0&&normals[face].y==0&&normals[face].z==0)continue;
                    clipTriangle(triangles[face],a,b,[&](Vec3 u,Vec3 v){line(u,v,face,33);});
                }
            }
        },outlineLimits);
        spend(stats.work,stats.outlines.work,limits.work);
    }
    stats.retainedBytes=sizeof(Overlay)+result.samples.capacity()*sizeof(OverlaySample)+result.lines.capacity()*sizeof(OverlayLine);
    require(stats.retainedBytes<=stats.preparationBytes,"Field overlay accounting overflow");return result;
}

Vec3 overlayColor(std::uint8_t bin){
    require(bin<=33,"Invalid field preview color");if(bin==33)return {1,1,1};
    // Saturated blue at zero is distinct from unsampled empty space.
    const double t=double(bin)/32;return {std::clamp(2*t,0.,1.),std::clamp(2-std::abs(4*t-2),0.,1.),std::clamp(2-2*t,0.,1.)};
}
}
