#include "brush.h"
#include "script_memory_budget.h"
#include "clipper2/clipper.h"
#include <algorithm>
#include <atomic>
#include <cmath>
#include <functional>
#include <map>
#include <numeric>
#include <stdexcept>
#ifdef _WIN32
#ifndef NOMINMAX
#define NOMINMAX
#endif
#include <windows.h>
#endif
#ifdef _MSC_VER
#pragma warning(push, 0)
#endif
#include "../third_party/geodesic/geodesic_algorithm_exact.h"
#ifdef _MSC_VER
#pragma warning(pop)
#endif

namespace cyrus::brush {
namespace {
using namespace Clipper2Lib;
// Binary quantization keeps every dyadic refinement edge exactly collinear.
// Decimal quantization creates narrow artificial slits where unequal refinement
// levels meet, even when both triangles describe the same filled region.
constexpr double resolution=1073741824.;
constexpr std::size_t maxQueries=400000, maxBoundarySources=32768;
std::atomic<std::size_t> reservedBytes{0};
struct Reservation {
    std::size_t bytes=0;
    explicit Reservation(std::size_t amount){
#ifdef _WIN32
        MEMORYSTATUSEX memory{};memory.dwLength=sizeof(memory);if(!GlobalMemoryStatusEx(&memory))throw std::runtime_error("Cannot read surface Paint commit headroom");
        cyrus::script_memory::admitNative(amount,memory.ullAvailPageFile);
#endif
        constexpr std::size_t limit=2ULL*1024*1024*1024;auto used=reservedBytes.load(std::memory_order_relaxed);
        do{if(used>limit||amount>limit-used)throw std::runtime_error("Retained and staged surface Paint exceed the 2 GiB working allowance; release unused Paint Areas");}while(!reservedBytes.compare_exchange_weak(used,used+amount,std::memory_order_relaxed));bytes=amount;
    }
    ~Reservation(){reservedBytes.fetch_sub(bytes,std::memory_order_relaxed);}
    Reservation(const Reservation&)=delete;Reservation& operator=(const Reservation&)=delete;
};
Vec3 cross(Vec3 a,Vec3 b){return {a.y*b.z-a.z*b.y,a.z*b.x-a.x*b.z,a.x*b.y-a.y*b.x};}
Vec3 world(Vec3 p,const Basis& b){return b[0]*p.x+b[1]*p.y+b[2]*p.z;}
Point64 integer(Point p){
    if(!std::isfinite(p[0])||!std::isfinite(p[1])||p[0]<-1e-7||p[1]<-1e-7||p[0]+p[1]>1.0000001)
        throw std::invalid_argument("Invalid surface Paint barycentric coverage");
    return {std::llround(p[0]*resolution),std::llround(p[1]*resolution)};
}
const Path64 triangle{{0,0},{1073741824,0},{0,1073741824}};
Paths64 pack(const FaceRegion& r){
    if(r.full)return {triangle};Paths64 out;
    for(const auto& c:r.contours){Path64 p;for(auto q:c)p.push_back(integer(q));if(p.size()<3)throw std::invalid_argument("Invalid surface Paint contour");out.push_back(std::move(p));}return out;
}
Paths64 boolean(ClipType type,const Paths64& a,const Paths64& b={}){
    Clipper64 clip;clip.AddSubject(a);clip.AddClip(b);Paths64 out;
    if(!clip.Execute(type,FillRule::NonZero,out))throw std::runtime_error("Surface Paint Boolean failed; previous coverage retained");return out;
}
FaceRegion region(std::uint32_t face,const Paths64& paths){
    FaceRegion out;out.face=face;
    if(paths.empty())return out;
    if(boolean(ClipType::Xor,paths,{triangle}).empty()){out.full=true;return out;}
    for(const auto& path:paths){Contour c;for(auto p:path)c.push_back({p.x/resolution,p.y/resolution});if(c.size()>=3)out.contours.push_back(std::move(c));}return out;
}
bool inside(const FaceRegion& r,Point p,QueryStats* stats){
    if(r.full)return true;bool result=false;
    for(const auto& c:r.contours)for(std::size_t i=0,j=c.size()-1;i<c.size();j=i++){
        if(stats)++stats->segments;auto a=c[i],b=c[j];
        const double dx=b[0]-a[0],dy=b[1]-a[1],px=p[0]-a[0],py=p[1]-a[1];
        if(std::abs(dx*py-dy*px)<=1e-9*std::hypot(dx,dy)&&px*dx+py*dy>=-1e-10&&px*dx+py*dy<=dx*dx+dy*dy+1e-10)return true;
        if((a[1]>p[1])!=(b[1]>p[1])&&p[0]<(b[0]-a[0])*(p[1]-a[1])/(b[1]-a[1])+a[0])result=!result;
    }return result;
}
Anchor anchor(std::uint32_t face,Point p){return {face,{1-p[0]-p[1],p[0],p[1]}};}
double segmentDistance(Vec3 p,Vec3 a,Vec3 b){auto d=b-a;const auto l=amin::dot(d,d);return amin::length(p-(a+d*(l>0?std::clamp(amin::dot(p-a,d)/l,0.,1.):0.)));}
double curve(const std::vector<double>& v,double t){auto x=std::clamp(t,0.,1.)*double(v.size()-1);auto i=std::min(v.size()-2,std::size_t(x));return v[i]+(v[i+1]-v[i])*(x-double(i));}
}

std::size_t surfaceReservedBytes(){return reservedBytes.load(std::memory_order_relaxed);}

void validateAttached(const Document& d){
    if(!d.attached){if(!d.faces.empty()||d.topology)throw std::invalid_argument("Mixed Paint coverage domains");return;}
    if(!d.contours.empty()||d.faces.size()>maxSurfaceFaces||!d.topology)throw std::invalid_argument("Invalid surface Paint document");
    std::size_t count=0;std::uint32_t previous=0;bool first=true;
    for(const auto& r:d.faces){
        if(r.face>=maxSurfaceFaces||(!first&&r.face<=previous)||(r.full&&!r.contours.empty())||(!r.full&&r.contours.empty()))throw std::invalid_argument("Invalid surface Paint face record");
        first=false;previous=r.face;
        for(const auto& c:r.contours){if(c.size()<3||c.size()>maxVertices-count)throw std::invalid_argument("Surface Paint boundary capacity exceeded");count+=c.size();for(auto p:c)integer(p);}
    }
}

struct SurfaceAtlas::Impl {
    Reservation reservation;
    Surface surface;Basis basis;std::vector<Vec3> points;geodesic::Mesh mesh;
    std::uint64_t topology=1469598103934665603ULL;double longest=0;
    struct Edge {std::uint32_t a{},b{};std::vector<std::pair<std::uint32_t,int>> faces;};
    std::vector<Edge> edges;std::vector<std::array<std::uint32_t,3>> faceEdges;
    Impl(const Surface& s,Basis b):reservation(8ULL*1024*1024+s.mesh().faces.size()*1536+s.mesh().vertices.size()*128),surface(s),basis(b){
        const auto& input=s.mesh();
        if(input.faces.size()>maxSurfaceFaces||input.vertices.size()>200000)throw std::invalid_argument("Surface Paint supports up to 100,000 triangles and 200,000 vertices");
        const auto determinant=amin::dot(b[0],cross(b[1],b[2]));
        if(!std::isfinite(determinant)||std::abs(determinant)<1e-12)throw std::invalid_argument("Singular surface Paint transform");
        auto hash=[&](std::uint64_t value){for(int i=0;i<8;++i){topology=(topology^(value&255))*1099511628211ULL;value>>=8;}};
        hash(input.vertices.size());
        for(auto p:input.vertices){auto q=world(p,b);if(!std::isfinite(q.x)||!std::isfinite(q.y)||!std::isfinite(q.z))throw std::invalid_argument("Nonfinite surface Paint metric");points.push_back(q);}
        std::map<std::pair<std::uint32_t,std::uint32_t>,std::uint32_t> index;
        faceEdges.resize(input.faces.size());
        std::vector<std::vector<std::uint32_t>> incident(input.vertices.size());
        std::vector<double> vertices;std::vector<unsigned> faces;
        for(auto p:points){vertices.push_back(p.x);vertices.push_back(p.y);vertices.push_back(p.z);}
        for(std::uint32_t fi=0;fi<input.faces.size();++fi){const auto f=input.faces[fi];
            auto a=points[f[0]],u=points[f[1]]-a,v=points[f[2]]-a;
            if(amin::length(cross(u,v))<1e-5*std::max({amin::dot(u,u),amin::dot(v,v),amin::dot(u-v,u-v)}))throw std::invalid_argument("Surface Paint needs nondegenerate triangles; repair collapsed or extremely thin faces");
            for(int k=0;k<3;++k){hash(f[k]);faces.push_back(f[k]);incident[f[k]].push_back(fi);auto x=f[k],y=f[(k+1)%3];if(x>y)std::swap(x,y);
                auto [it,added]=index.emplace(std::make_pair(x,y),static_cast<std::uint32_t>(edges.size()));
                if(added)edges.push_back({x,y,{}});auto& edge=edges[it->second];edge.faces.push_back({fi,k});
                if(edge.faces.size()>2)throw std::invalid_argument("Surface Paint needs manifold edges; split the nonmanifold receiver");faceEdges[fi][k]=it->second;
                longest=std::max(longest,amin::length(points[x]-points[y]));
            }
        }
        std::vector<std::uint32_t> visited(input.faces.size(),UINT_MAX);
        for(std::uint32_t v=0;v<incident.size();++v){if(incident[v].empty())continue;std::vector<std::uint32_t> fan{incident[v].front()};visited[fan[0]]=v;
            for(std::size_t i=0;i<fan.size();++i)for(auto ei:faceEdges[fan[i]]){auto& e=edges[ei];if(e.a!=v&&e.b!=v)continue;for(auto [face,k]:e.faces){(void)k;if(visited[face]!=v){visited[face]=v;fan.push_back(face);}}}
            if(fan.size()!=incident[v].size())throw std::invalid_argument("Surface Paint needs manifold vertex fans; split sheets that touch only at one vertex");
        }
        // Compact unreferenced vertices before passing topology to the solver.
        std::vector<unsigned> remap(points.size(),UINT_MAX);std::vector<double> compact;
        for(auto& i:faces){if(remap[i]==UINT_MAX){remap[i]=static_cast<unsigned>(compact.size()/3);compact.insert(compact.end(),vertices.begin()+i*3,vertices.begin()+i*3+3);}i=remap[i];}
        mesh.initialize_mesh_data(compact,faces);
    }
    Vec3 position(Anchor a)const{return world(surface.position(a),basis);}
    geodesic::SurfacePoint point(Anchor a){auto p=position(a);return {&mesh.faces()[a.face],p.x,p.y,p.z};}
    void check(const Document& d)const{
        validate(d.falloff);validateAttached(d);
        if(!d.attached||d.topology!=topology||d.surface!=surface.fingerprint())throw std::invalid_argument("Surface Paint receiver changed; restore its geometry or create a new Paint Area");
        if(!d.faces.empty()&&d.faces.back().face>=surface.mesh().faces.size())throw std::invalid_argument("Surface Paint face is outside its receiver");
    }
};
SurfaceAtlas::SurfaceAtlas(const Surface& s,Basis b):impl(std::make_shared<Impl>(s,b)){}
std::uint64_t SurfaceAtlas::topology()const{return impl->topology;}
Document SurfaceAtlas::fill(const Document& d,bool value)const{
    impl->check(d);Document next=d;next.faces.clear();if(value)for(std::uint32_t i=0;i<impl->surface.mesh().faces.size();++i)next.faces.push_back({i,true,{}});return next;
}
Document SurfaceAtlas::combine(const Document& d,const Document& input,bool add)const{
    impl->check(d);impl->check(input);Document next=d;next.faces=input.faces;if(!add)return next;
    std::map<std::uint32_t,FaceRegion> regions;for(auto r:d.faces)regions.emplace(r.face,std::move(r));
    for(const auto& r:input.faces){auto old=regions.find(r.face);regions[r.face]=old==regions.end()?r:region(r.face,boolean(ClipType::Union,pack(old->second),pack(r)));}
    next.faces.clear();for(auto& [id,r]:regions){(void)id;next.faces.push_back(std::move(r));}validateAttached(next);return next;
}

Document SurfaceAtlas::paint(const Document& d,Anchor center,double radius,bool erase,const Anchor* previous)const{
    impl->check(d);if(!std::isfinite(radius)||radius<=.0001||radius>1e7)throw std::invalid_argument("Surface brush radius outside supported range");
    Reservation scratch(256ULL*1024*1024);
    auto start=impl->point(center);std::vector<geodesic::SurfacePoint> sources{start};
    geodesic::GeodesicAlgorithmExact solver(&impl->mesh);
    if(previous){
        auto old=impl->point(*previous);solver.propagate(sources,radius*64+impl->longest);double distance;solver.best_source(old,distance);
        if(distance<radius*64){std::vector<geodesic::SurfacePoint> path;solver.trace_back(old,path);
            for(std::size_t i=1;i<path.size();++i){auto& a=path[i-1];auto& b=path[i];const auto steps=std::max(1u,static_cast<unsigned>(std::ceil(a.distance(&b)/(radius*.15))));
                if(sources.size()+steps>1024)throw std::runtime_error("Surface brush path capacity reached; shorten the gesture movement");
                // Consecutive path points share a face; use that face for interpolated sources.
                geodesic::face_pointer face=nullptr;
                auto incident=[](geodesic::SurfacePoint& p){std::vector<geodesic::face_pointer> result;
                    if(p.type()==geodesic::FACE)result.push_back(static_cast<geodesic::face_pointer>(p.base_element()));
                    else {auto& list=p.base_element()->adjacent_faces();for(unsigned k=0;k<list.size();++k)result.push_back(list[k]);}return result;};
                const auto left=incident(a),right=incident(b);for(auto f:left)if(std::find(right.begin(),right.end(),f)!=right.end()){face=f;break;}
                if(!face)throw std::runtime_error("Surface brush path has no common face; previous paint retained");
                for(unsigned k=1;k<=steps;++k){const auto t=double(k)/steps;sources.emplace_back(face,a.x()+(b.x()-a.x())*t,a.y()+(b.y()-a.y())*t,a.z()+(b.z()-a.z())*t);}
            }
        } // Disconnected or a very long jump starts a new dab, never a chord through the object.
    }
    solver.propagate(sources,radius+impl->longest*2);
    std::size_t queries=0,workVertices=0;const double tolerance=radius*.005;
    auto distance=[&](Anchor a){if(++queries>maxQueries)throw std::runtime_error("Surface brush refinement capacity reached; previous paint retained");auto p=impl->point(a);double value;solver.best_source(p,value);return value;};
    std::map<std::uint32_t,FaceRegion> result;for(const auto& r:d.faces)result.emplace(r.face,r);
    struct Sample{Point p;double d;Vec3 world;};
    for(std::uint32_t fi=0;fi<impl->surface.mesh().faces.size();++fi){
        auto found=result.find(fi);if((erase&&found==result.end())||(!erase&&found!=result.end()&&found->second.full))continue;
        auto sample=[&](Point p){auto a=anchor(fi,p);return Sample{p,distance(a),impl->position(a)};};
        Paths64 fragments;std::size_t faceVertices=0;
        std::function<void(const Sample&,const Sample&,const Sample&,unsigned)> refine;
        refine=[&](const Sample& a,const Sample& b,const Sample& c,unsigned depth){
            const double diameter=std::max({amin::length(a.world-b.world),amin::length(b.world-c.world),amin::length(c.world-a.world)});
            const double low=std::min({a.d,b.d,c.d}),high=std::max({a.d,b.d,c.d});
            if(low>radius+diameter)return;
            if(high+diameter<=radius){fragments.push_back({integer(a.p),integer(b.p),integer(c.p)});workVertices+=3;faceVertices+=3;}
            else if(diameter<=tolerance||depth==48){
                if(depth==48&&diameter>tolerance)throw std::runtime_error("Surface brush precision bound reached; previous paint retained");
                std::array<Sample,3> v{a,b,c};Path64 polygon;
                for(int i=0;i<3;++i){auto x=v[i],y=v[(i+1)%3];if(x.d<=radius)polygon.push_back(integer(x.p));if((x.d<=radius)!=(y.d<=radius)){const double t=std::clamp((radius-x.d)/(y.d-x.d),0.,1.);polygon.push_back(integer({x.p[0]+(y.p[0]-x.p[0])*t,x.p[1]+(y.p[1]-x.p[1])*t}));}}
                if(polygon.size()>=3){workVertices+=polygon.size();faceVertices+=polygon.size();fragments.push_back(std::move(polygon));}
            }else{
                // Longest-edge bisection avoids four-way expansion in skinny mesh triangles.
                const double ab=amin::length(a.world-b.world),bc=amin::length(b.world-c.world),ca=amin::length(c.world-a.world);
                if(ab>=bc&&ab>=ca){auto m=sample({(a.p[0]+b.p[0])*.5,(a.p[1]+b.p[1])*.5});refine(a,m,c,depth+1);refine(m,b,c,depth+1);}
                else if(bc>=ca){auto m=sample({(b.p[0]+c.p[0])*.5,(b.p[1]+c.p[1])*.5});refine(b,m,a,depth+1);refine(m,c,a,depth+1);}
                else{auto m=sample({(c.p[0]+a.p[0])*.5,(c.p[1]+a.p[1])*.5});refine(c,m,b,depth+1);refine(m,a,b,depth+1);}
            }
            if(workVertices>1200000||faceVertices>262144)throw std::runtime_error("Surface brush Boolean admission exceeded; previous paint retained");
        };
        refine(sample({0,0}),sample({1,0}),sample({0,1}),0);
        if(fragments.empty())continue;auto footprint=boolean(ClipType::Intersection,boolean(ClipType::Union,fragments),{triangle});
        auto old=found==result.end()?Paths64{}:pack(found->second);
        auto next=region(fi,boolean(erase?ClipType::Difference:ClipType::Union,old,footprint));
        if(!next.full&&next.contours.empty())result.erase(fi);else result[fi]=std::move(next);
    }
    Document next=d;next.faces.clear();for(auto& [id,r]:result){(void)id;next.faces.push_back(std::move(r));}validateAttached(next);return next;
}

std::vector<std::array<Anchor,2>> SurfaceAtlas::boundary(const Document& d)const{
    impl->check(d);std::vector<std::array<Anchor,2>> out;
    struct Interval{double lo,hi;std::uint32_t face;};std::map<std::uint32_t,std::vector<Interval>> intervals;
    for(const auto& r:d.faces){const auto paths=pack(r);const auto face=impl->surface.mesh().faces[r.face];
        for(const auto& path:paths)for(std::size_t i=0;i<path.size();++i){auto x=path[i],y=path[(i+1)%path.size()];Point a{x.x/resolution,x.y/resolution},b{y.x/resolution,y.y/resolution};
            int edge=-1;if(x.y==0&&y.y==0)edge=0;else if(x.x+x.y==1073741824&&y.x+y.y==1073741824)edge=1;else if(x.x==0&&y.x==0)edge=2;
            if(edge<0){out.push_back({anchor(r.face,a),anchor(r.face,b)});continue;}
            auto t=[&](Point p){return edge==0?p[0]:edge==1?p[1]:1-p[1];};double lo=t(a),hi=t(b);
            if(face[edge]>face[(edge+1)%3]){lo=1-lo;hi=1-hi;}if(lo>hi)std::swap(lo,hi);if(hi>lo)intervals[impl->faceEdges[r.face][edge]].push_back({lo,hi,r.face});
        }
    }
    for(const auto& [ei,values]:intervals){const auto& edge=impl->edges[ei];std::vector<double> breaks;
        for(auto v:values){breaks.push_back(v.lo);breaks.push_back(v.hi);}std::sort(breaks.begin(),breaks.end());breaks.erase(std::unique(breaks.begin(),breaks.end()),breaks.end());
        for(std::size_t i=1;i<breaks.size();++i){double mid=(breaks[i-1]+breaks[i])*.5;const Interval* selected=nullptr;unsigned count=0;
            for(const auto& v:values)if(mid>v.lo&&mid<v.hi){selected=&v;++count;}
            if(count%2==0||!selected)continue;const auto f=impl->surface.mesh().faces[selected->face];
            auto locate=[&](double t){Vec3 bary{};for(int k=0;k<3;++k){double weight=f[k]==edge.a?1-t:f[k]==edge.b?t:0;if(k==0)bary.x=weight;else if(k==1)bary.y=weight;else bary.z=weight;}return Anchor{selected->face,bary};};
            out.push_back({locate(breaks[i-1]),locate(breaks[i])});
        }
    }
    if(out.size()>maxVertices)throw std::runtime_error("Surface brush border capacity reached");return out;
}

std::vector<std::vector<Vec3>> SurfaceAtlas::contours(const Document& d)const{
    const auto lines=boundary(d);
    using Key=std::array<std::int64_t,4>;std::map<Key,std::size_t> indices;
    std::vector<Vec3> points;std::vector<std::vector<std::size_t>> links;
    auto key=[&](Anchor a){const auto f=impl->surface.mesh().faces[a.face];double b[3]{a.bary.x,a.bary.y,a.bary.z};
        for(int i=0;i<3;++i)if(b[i]>1-1e-7)return Key{0,f[i],0,0};
        for(int i=0;i<3;++i)if(std::abs(b[i])<1e-7){int j=(i+1)%3,k=(i+2)%3;auto x=f[j],y=f[k];double t=b[k]/(b[j]+b[k]);if(x>y){std::swap(x,y);t=1-t;}return Key{1,x,y,std::llround(t*resolution)};}
        return Key{2,a.face,std::llround(a.bary.y*resolution),std::llround(a.bary.z*resolution)};};
    auto node=[&](Anchor a){auto [it,added]=indices.emplace(key(a),points.size());if(added){points.push_back(impl->surface.position(a));links.emplace_back();}return it->second;};
    for(auto line:lines){auto a=node(line[0]),b=node(line[1]);if(a==b)continue;links[a].push_back(b);links[b].push_back(a);}
    for(std::size_t i=0;i<links.size();++i)if(links[i].size()!=2){std::string detail;for(auto j:links[i])detail+=" -> "+std::to_string(points[j].x)+","+std::to_string(points[j].y);throw std::runtime_error("Surface border connectivity at "+std::to_string(points[i].x)+","+std::to_string(points[i].y)+","+std::to_string(points[i].z)+" degree "+std::to_string(links[i].size())+detail);}
    std::vector<bool> visited(points.size());std::vector<std::vector<Vec3>> out;
    for(std::size_t first=0;first<points.size();++first){if(visited[first])continue;std::vector<Vec3> loop;auto at=first,previous=points.size();
        do{if(visited[at])throw std::runtime_error("Surface spline border connectivity failed");visited[at]=true;loop.push_back(points[at]);const auto next=links[at][0]==previous?links[at][1]:links[at][0];previous=at;at=next;}while(at!=first);
        if(loop.size()>=3)out.push_back(std::move(loop));
    }return out;
}

Document SurfaceAtlas::importCurves(const Document& d,const std::vector<std::vector<Vec3>>& curves,double tolerance,bool add)const{
    impl->check(d);if(!std::isfinite(tolerance)||tolerance<=0||curves.empty())throw std::invalid_argument("Surface spline import needs closed contours and positive tolerance");
    Reservation scratch(256ULL*1024*1024);
    Mesh metricMesh=impl->surface.mesh();metricMesh.vertices=impl->points;Surface metricSurface(std::move(metricMesh));
    std::vector<Paths64> paths(impl->surface.mesh().faces.size());std::size_t steps=0,inputCount=0,propagations=0;
    auto local=[&](std::uint32_t face,geodesic::SurfacePoint& p){const auto f=impl->surface.mesh().faces[face];auto a=impl->points[f[0]],u=impl->points[f[1]]-a,v=impl->points[f[2]]-a,w=Vec3{p.x(),p.y(),p.z()}-a;const auto uu=amin::dot(u,u),uv=amin::dot(u,v),vv=amin::dot(v,v),wu=amin::dot(w,u),wv=amin::dot(w,v),den=uu*vv-uv*uv;return Point{(wu*vv-wv*uv)/den,(wv*uu-wu*uv)/den};};
    auto incident=[](geodesic::SurfacePoint& p){std::vector<geodesic::face_pointer> result;if(p.type()==geodesic::FACE)result.push_back(static_cast<geodesic::face_pointer>(p.base_element()));else{auto& list=p.base_element()->adjacent_faces();for(unsigned k=0;k<list.size();++k)result.push_back(list[k]);}return result;};
    for(const auto& curve:curves){if(curve.size()<3||curve.size()>8192-inputCount)throw std::invalid_argument("Surface spline import exceeds 8,192 points");inputCount+=curve.size();
        std::vector<Anchor> anchors;for(auto p:curve){Hit closest;if(!metricSurface.closest(world(p,impl->basis),closest,tolerance))throw std::invalid_argument("Surface spline must lie on its receiver within Curve tolerance; snap the spline onto the mesh");anchors.push_back(closest.anchor);}
        struct Run{std::uint32_t face;Contour points;};std::vector<Run> runs;
        for(std::size_t i=0;i<anchors.size();++i){auto source=impl->point(anchors[i]),destination=impl->point(anchors[(i+1)%anchors.size()]);const double direct=source.distance(&destination);if(direct<1e-10)continue;
            geodesic::GeodesicAlgorithmExact solver(&impl->mesh);std::vector<geodesic::SurfacePoint> sources{source};solver.propagate(sources,direct*4+impl->longest);double distance;solver.best_source(destination,distance);
            propagations+=solver.propagation_steps();if(propagations>2000000)throw std::runtime_error("Surface spline propagation capacity reached; simplify the contour");
            if(distance>=geodesic::GEODESIC_INF/2)throw std::invalid_argument("Spline crosses disconnected or distant surface regions; split the contour");
            std::vector<geodesic::SurfacePoint> path;solver.trace_back(destination,path);std::reverse(path.begin(),path.end());
            if(path.size()>65536-steps)throw std::runtime_error("Surface spline path capacity exceeded");steps+=path.size();
            for(std::size_t k=1;k<path.size();++k){auto& a=path[k-1];auto& b=path[k];if(a.distance(&b)<1e-10)continue;geodesic::face_pointer face=nullptr;auto left=incident(a),right=incident(b);for(auto f:left)if(std::find(right.begin(),right.end(),f)!=right.end()){face=f;break;}
                if(!face)throw std::runtime_error("Surface spline path has no common triangle");auto x=local(face->id(),a),y=local(face->id(),b);
                if(!runs.empty()&&runs.back().face==face->id())runs.back().points.push_back(y);else runs.push_back({face->id(),{x,y}});
            }
        }
        if(runs.size()>1&&runs.front().face==runs.back().face){auto joined=std::move(runs.back().points);joined.insert(joined.end(),runs.front().points.begin()+1,runs.front().points.end());runs.front().points=std::move(joined);runs.pop_back();}
        for(auto& run:runs){auto& c=run.points;auto first=c.front(),last=c.back();
            if(std::hypot(first[0]-last[0],first[1]-last[1])>1e-7){
                auto perimeter=[](Point p){if(std::abs(p[1])<1e-6)return std::clamp(p[0],0.,1.);if(std::abs(1-p[0]-p[1])<1e-6)return 1+std::clamp(p[1],0.,1.);if(std::abs(p[0])<1e-6)return 3-std::clamp(p[1],0.,1.);throw std::runtime_error("Surface spline path did not close across triangle edges");};
                double start=perimeter(last),end=perimeter(first);if(end<start)end+=3;
                const std::array<Point,3> corners{{{0,0},{1,0},{0,1}}};for(int k=static_cast<int>(std::floor(start))+1;double(k)<end;++k)c.push_back(corners[static_cast<std::size_t>(k%3)]);
            }
            Path64 polygon;for(auto p:c)polygon.push_back(integer(p));if(polygon.size()>=3)paths[run.face].push_back(std::move(polygon));
        }
    }
    std::vector<FaceRegion> base(paths.size());
    for(std::uint32_t i=0;i<paths.size();++i){Clipper64 clip;clip.AddSubject(paths[i]);Paths64 normalized;if(!clip.Execute(ClipType::Union,FillRule::EvenOdd,normalized))throw std::runtime_error("Surface spline Boolean failed");base[i]=region(i,boolean(ClipType::Intersection,normalized,{triangle}));}
    std::vector<int> flips(paths.size(),-1);std::vector<FaceRegion> imported;
    auto edgePoint=[&](std::uint32_t face,const Impl::Edge& e){const auto f=impl->surface.mesh().faces[face];double w[3]{};for(int k=0;k<3;++k)w[k]=f[k]==e.a?.628608:f[k]==e.b?.371392:0;return Point{w[1],w[2]};};
    for(std::uint32_t seed=0;seed<paths.size();++seed){if(flips[seed]>=0)continue;std::vector<std::uint32_t> queue{seed};flips[seed]=0;bool hasBoundary=false;double totalArea=0,paintArea=0;
        for(std::size_t i=0;i<queue.size();++i){auto face=queue[i];hasBoundary=hasBoundary||!paths[face].empty();const auto f=impl->surface.mesh().faces[face];double area=amin::length(cross(impl->points[f[1]]-impl->points[f[0]],impl->points[f[2]]-impl->points[f[0]]))*.5;
            const double fraction=base[face].full?1.:Area(pack(base[face]))/(resolution*resolution*.5);totalArea+=area;paintArea+=area*(flips[face]?1-fraction:fraction);
            for(auto ei:impl->faceEdges[face]){const auto& edge=impl->edges[ei];for(auto [neighbor,k]:edge.faces){(void)k;if(neighbor==face)continue;const int next=flips[face]^int(inside(base[face],edgePoint(face,edge),nullptr))^int(inside(base[neighbor],edgePoint(neighbor,edge),nullptr));
                if(flips[neighbor]<0){flips[neighbor]=next;queue.push_back(neighbor);}else if(flips[neighbor]!=next)throw std::invalid_argument("Surface spline does not separate a consistent closed region; repair crossing or nonseparating loops");}}
        }
        if(!hasBoundary)continue;const bool complement=paintArea>totalArea*.5;
        for(auto face:queue){auto r=base[face];if(bool(flips[face])!=complement)r=region(face,boolean(ClipType::Difference,{triangle},pack(r)));if(r.full||!r.contours.empty())imported.push_back(std::move(r));}
    }
    std::map<std::uint32_t,FaceRegion> result;if(add)for(auto r:d.faces)result.emplace(r.face,std::move(r));
    for(auto& r:imported){auto old=result.find(r.face);if(old!=result.end())r=region(r.face,boolean(ClipType::Union,pack(old->second),pack(r)));result[r.face]=std::move(r);}
    Document next=d;next.faces.clear();for(auto& [id,r]:result){(void)id;next.faces.push_back(std::move(r));}validateAttached(next);return next;
}

class SurfaceAtlas::Prepared {
public:
    Reservation reservation;
    std::shared_ptr<Impl> atlas;Document document;std::vector<int> regions;
    std::vector<std::vector<std::array<Vec3,2>>> localBoundary;
    std::unique_ptr<geodesic::GeodesicAlgorithmExact> distance;
    Prepared(std::shared_ptr<Impl> a,const Document& d):reservation(8ULL*1024*1024+a->surface.mesh().faces.size()*64+vertexCount(d)*32+((d.falloff.inside+d.falloff.outside)>0?64ULL*1024*1024:0)),atlas(std::move(a)),document(d),regions(atlas->surface.mesh().faces.size(),-1),localBoundary(regions.size()){
        for(std::size_t i=0;i<d.faces.size();++i)regions[d.faces[i].face]=static_cast<int>(i);
    }
};
std::shared_ptr<SurfaceAtlas::Prepared> SurfaceAtlas::prepare(const Document& d)const{
    impl->check(d);auto p=std::make_shared<Prepared>(impl,d);const double width=std::max(d.falloff.inside,d.falloff.outside);
    if(width==0||d.faces.empty())return p;
    const auto edges=boundary(d);if(edges.empty())return p;
    std::vector<geodesic::SurfacePoint> sources;const double step=width*.02;
    for(const auto& e:edges){auto a=impl->position(e[0]),b=impl->position(e[1]);p->localBoundary[e[0].face].push_back({a,b});
        const double required=std::ceil(amin::length(b-a)/step);
        if(!std::isfinite(required)||required>double(maxBoundarySources)||sources.size()+static_cast<std::size_t>(required)+1>maxBoundarySources)throw std::runtime_error("Surface feather boundary capacity exceeded; reduce boundary detail or increase feather width");
        const auto count=std::max<std::size_t>(1,static_cast<std::size_t>(required));
        for(std::size_t k=0;k<=count;++k){const double t=double(k)/count;auto q=a+(b-a)*t;sources.emplace_back(&impl->mesh.faces()[e[0].face],q.x,q.y,q.z);}
    }
    p->distance=std::make_unique<geodesic::GeodesicAlgorithmExact>(&impl->mesh);p->distance->propagate(sources,width+impl->longest);return p;
}
Evaluation querySurface(const SurfaceAtlas::Prepared& p,Anchor a,QueryStats* stats){
    const auto position=p.atlas->position(a);if(stats)++stats->fieldQueries;
    const auto index=p.regions[a.face];const bool covered=index>=0&&inside(p.document.faces[static_cast<std::size_t>(index)],{a.bary.y,a.bary.z},stats);
    const auto& f=p.document.falloff;double distance=INFINITY;
    if(p.distance){auto point=p.atlas->point(a);p.distance->best_source(point,distance);
        for(const auto& e:p.localBoundary[a.face]){if(stats)++stats->segments;distance=std::min(distance,segmentDistance(position,e[0],e[1]));}}
    if(!covered)distance=-distance;if(distance< -f.outside)return {};
    const double width=f.inside+f.outside,t=width>0?std::clamp((distance+f.outside)/width,0.,1.):1.;
    return {width>0&&f.density?curve(f.densityCurve,t):1.,f.scale?f.scaleMin+(f.scaleMax-f.scaleMin)*curve(f.scaleCurve,t):1.};
}
}
