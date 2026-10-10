#include "brush.h"
#include "clipper2/clipper.h"
#include <algorithm>
#include <cmath>
#include <cstring>
#include <numeric>
#include <stdexcept>
namespace cyrus::brush {
namespace {
using namespace Clipper2Lib;
constexpr double quantum=0.0001, maxCoordinate=1.e9;
bool finite(Point p){return std::isfinite(p[0])&&std::isfinite(p[1]);}
void check(Point p){if(!finite(p)||std::max(std::abs(p[0]),std::abs(p[1]))>maxCoordinate)throw std::invalid_argument("Vector coordinate outside supported range");}
Point64 integer(Point p){check(p);return {std::llround(p[0]/quantum),std::llround(p[1]/quantum)};}
Paths64 pack(const Contours& contours){
    Paths64 out;std::size_t count=0;
    for(const auto& contour:contours){
        if(contour.size()<3||contour.size()>maxVertices-count)throw std::invalid_argument("Vector boundary capacity exceeded");
        count+=contour.size();Path64 path;path.reserve(contour.size());for(auto p:contour)path.push_back(integer(p));out.push_back(std::move(path));
    }return out;
}
Contours unpack(const Paths64& paths){
    Contours out;std::size_t count=0;
    for(const auto& path:paths){
        if(path.size()<3)continue;
        if(path.size()>maxVertices-count)throw std::invalid_argument("Vector boundary capacity exceeded; previous paint retained");
        count+=path.size();Contour c;c.reserve(path.size());for(auto p:path)c.push_back({p.x*quantum,p.y*quantum});out.push_back(std::move(c));
    }return out;
}
Paths64 combine(ClipType type,const Paths64& subject,const Paths64& clip={}){
    Clipper64 engine;engine.AddSubject(subject);engine.AddClip(clip);Paths64 result;
    if(!engine.Execute(type,FillRule::NonZero,result))throw std::runtime_error("Vector Boolean failed; previous paint retained");
    return result;
}
Paths64 triangles(const Surface& s){
    if(s.mesh().faces.size()>1000000)throw std::invalid_argument("Vector projection supports at most one million faces");
    Paths64 out;out.reserve(s.mesh().faces.size());double sign=0;
    for(const auto& f:s.mesh().faces){
        Path64 path;for(auto v:f){auto p=s.mesh().vertices[v];path.push_back(integer({p.x,p.y}));}
        const double area=Area(path);
        if(area==0)throw std::invalid_argument("Vector brush needs a surface without vertical or degenerate faces in local XY");
        if(sign==0)sign=area;
        if(area*sign<=0)throw std::invalid_argument("Vector brush needs terrain or a single-valued local XY surface; closed/folded receivers are unsupported");
        if(area<0)std::reverse(path.begin(),path.end());out.push_back(std::move(path));
    }return out;
}
double curve(const std::vector<double>& v,double x){
    const double t=std::clamp(x,0.,1.)*double(v.size()-1);const auto i=std::min(v.size()-2,std::size_t(t));
    return v[i]+(v[i+1]-v[i])*(t-double(i));
}
Point sub(Point a,Point b){return {a[0]-b[0],a[1]-b[1]};}
double dot(Point a,Point b){return a[0]*b[0]+a[1]*b[1];}
struct Box{
    Point lo{INFINITY,INFINITY},hi{-INFINITY,-INFINITY};
    void add(Point p){for(int i=0;i<2;++i){lo[i]=std::min(lo[i],p[i]);hi[i]=std::max(hi[i],p[i]);}}
    double distance2(Point p)const{double d=0;for(int i=0;i<2;++i){double v=std::max({lo[i]-p[i],0.,p[i]-hi[i]});d+=v*v;}return d;}
};
template<class T>void put(std::vector<std::uint8_t>& bytes,T v){const auto* p=reinterpret_cast<const std::uint8_t*>(&v);bytes.insert(bytes.end(),p,p+sizeof(v));}
struct Reader{
    const std::vector<std::uint8_t>& data;std::size_t pos=0;
    template<class T>T get(){if(sizeof(T)>data.size()-pos)throw std::invalid_argument("Truncated vector document");T v;std::memcpy(&v,data.data()+pos,sizeof(v));pos+=sizeof(v);return v;}
};
}
std::size_t vertexCount(const Document& d){std::size_t n=0;for(const auto& c:d.contours)n+=c.size();return n;}
Metric Metric::fromBasis(Vec3 x,Vec3 y){
    Metric m;m.xx=amin::length(x);if(!std::isfinite(m.xx)||m.xx<1.e-9)throw std::invalid_argument("Singular vector projection metric");
    m.xy=amin::dot(x,y)/m.xx;m.yy=std::sqrt(std::max(0.,amin::dot(y,y)-m.xy*m.xy));
    if(!std::isfinite(m.xy)||!std::isfinite(m.yy)||m.yy<1.e-9)throw std::invalid_argument("Singular vector projection metric");return m;
}
Point Metric::map(Point p)const{return {p[0]*xx+p[1]*xy,p[1]*yy};}
Point Metric::unmap(Point p)const{return {(p[0]-p[1]*xy/yy)/xx,p[1]/yy};}
void validate(const Falloff& f){
    for(double v:{f.inside,f.outside,f.scaleMin,f.scaleMax})if(!std::isfinite(v)||v<0||v>1.e9)throw std::invalid_argument("Invalid vector feather/scale setting");
    if(f.scaleMin>f.scaleMax)throw std::invalid_argument("Scale minimum exceeds maximum");
    for(const auto* values:{&f.densityCurve,&f.scaleCurve}){
        if(values->size()<2||values->size()>257)throw std::invalid_argument("Curve needs 2..257 samples");
        for(double v:*values)if(!std::isfinite(v)||v<0||v>1)throw std::invalid_argument("Vector curves must remain between 0 and 100 percent");
    }
}
void validateProjection(const Surface& s){
    const auto paths=triangles(s);const auto united=combine(ClipType::Union,paths);
    double sum=0;for(const auto& p:paths)sum+=Area(p);double unionArea=0;for(const auto& p:united)unionArea+=Area(p);
    // Quantized shared edges coincide exactly. Detect disconnected stacked sheets
    // as well as folds; normal checks alone are not enough.
    if(sum-unionArea>std::max(1.,sum*1.e-10))throw std::invalid_argument("Vector receiver overlaps itself in local XY; choose a separate terrain/plane receiver");
}
Contours domain(const Surface& s){validateProjection(s);return unpack(combine(ClipType::Union,triangles(s)));}
Document constrain(const Document& d,const Contours& receiverDomain){
    Document next=d;next.contours=unpack(combine(ClipType::Intersection,pack(d.contours),pack(receiverDomain)));return next;
}
Document paint(const Document& d,Point center,double radius,bool erase,Metric metric,const Point* previous){
    check(center);if(!std::isfinite(radius)||radius<=quantum||radius>1.e7)throw std::invalid_argument("Vector brush radius outside supported range");
    if(!std::isfinite(metric.xx)||!std::isfinite(metric.xy)||!std::isfinite(metric.yy)||metric.xx<=0||metric.yy<=0)throw std::invalid_argument("Invalid vector metric");
    auto disk=[&](Point p){Path64 out;const auto world=metric.map(p);constexpr int count=96;
        for(int i=0;i<count;++i){const double a=6.283185307179586*double(i)/count;out.push_back(integer(metric.unmap({world[0]+radius*std::cos(a),world[1]+radius*std::sin(a)})));}return out;};
    Path64 shape=disk(center);
    if(previous){
        check(*previous);auto points=disk(*previous);points.insert(points.end(),shape.begin(),shape.end());
        std::sort(points.begin(),points.end(),[](auto a,auto b){return a.x<b.x||(a.x==b.x&&a.y<b.y);});
        points.erase(std::unique(points.begin(),points.end()),points.end());
        auto turn=[](Point64 a,Point64 b,Point64 c){return (long double)(b.x-a.x)*(c.y-a.y)-(long double)(b.y-a.y)*(c.x-a.x);};
        Path64 hull;for(auto p:points){while(hull.size()>1&&turn(hull[hull.size()-2],hull.back(),p)<=0)hull.pop_back();hull.push_back(p);}
        auto lower=hull.size();for(auto it=points.rbegin()+1;it!=points.rend();++it){while(hull.size()>lower&&turn(hull[hull.size()-2],hull.back(),*it)<=0)hull.pop_back();hull.push_back(*it);}
        hull.pop_back();shape=std::move(hull);
    }
    Document next=d;next.contours=unpack(combine(erase?ClipType::Difference:ClipType::Union,pack(d.contours),{shape}));return next;
}
struct Field::Impl{
    Surface surface;Falloff falloff;Metric metric;
    struct Segment{Point a,b;};struct Node{Box box;std::size_t begin=0,end=0,left=0,right=0;};
    std::vector<Segment> segments;std::vector<Node> nodes;
    Impl(const Surface& s,const Document& d,Metric m):surface(s),falloff(d.falloff),metric(m){
        validate(falloff);if(d.surface!=s.fingerprint())throw std::invalid_argument("Vector receiver shape changed; restore it or create a new Paint Area");
        pack(d.contours);
        for(const auto& c:d.contours)for(std::size_t i=0;i<c.size();++i)segments.push_back({m.map(c[i]),m.map(c[(i+1)%c.size()])});
        if(!segments.empty())build(0,segments.size());
    }
    std::size_t build(std::size_t a,std::size_t b){
        const auto id=nodes.size();nodes.push_back({});Box bounds;
        for(auto i=a;i<b;++i){bounds.add(segments[i].a);bounds.add(segments[i].b);}
        nodes[id].box=bounds;nodes[id].begin=a;nodes[id].end=b;
        if(b-a>8){int axis=(bounds.hi[0]-bounds.lo[0])>(bounds.hi[1]-bounds.lo[1])?0:1;auto mid=a+(b-a)/2;
            std::nth_element(segments.begin()+a,segments.begin()+mid,segments.begin()+b,[&](const auto& l,const auto& r){return l.a[axis]+l.b[axis]<r.a[axis]+r.b[axis];});
            auto left=build(a,mid),right=build(mid,b);nodes[id].left=left;nodes[id].right=right;
        }return id;
    }
    bool inside(Point p,QueryStats* stats)const{
        bool in=false;std::vector<std::size_t> stack{0};
        while(!stack.empty()){auto i=stack.back();stack.pop_back();const auto& n=nodes[i];
            if(p[1]<n.box.lo[1]||p[1]>n.box.hi[1]||p[0]>n.box.hi[0])continue;
            if(n.right){stack.push_back(n.left);stack.push_back(n.right);continue;}
            for(auto j=n.begin;j<n.end;++j){if(stats)++stats->segments;const auto& s=segments[j];
                if((s.a[1]>p[1])!=(s.b[1]>p[1])&&p[0]<(s.b[0]-s.a[0])*(p[1]-s.a[1])/(s.b[1]-s.a[1])+s.a[0])in=!in;
            }
        }return in;
    }
    double distance(Point p,QueryStats* stats)const{
        double best=INFINITY;std::vector<std::size_t> stack{0};
        while(!stack.empty()){auto i=stack.back();stack.pop_back();const auto& n=nodes[i];if(n.box.distance2(p)>best)continue;
            if(n.right){auto l=n.left,r=n.right;if(nodes[l].box.distance2(p)<nodes[r].box.distance2(p))std::swap(l,r);stack.push_back(l);stack.push_back(r);continue;}
            for(auto j=n.begin;j<n.end;++j){if(stats)++stats->segments;auto s=segments[j];auto v=sub(s.b,s.a),w=sub(p,s.a);const double len=dot(v,v),t=len>0?std::clamp(dot(w,v)/len,0.,1.):0;
                const Point d{w[0]-v[0]*t,w[1]-v[1]*t};best=std::min(best,dot(d,d));}
        }return std::sqrt(best);
    }
};
Field::Field(const Surface& s,const Document& d,Metric m):impl(std::make_shared<Impl>(s,d,m)){}
double Field::signedDistance(Point p,QueryStats* stats)const{
    check(p);if(impl->segments.empty())return -INFINITY;p=impl->metric.map(p);double d=impl->distance(p,stats);return impl->inside(p,stats)?d:-d;
}
Evaluation Field::queryPoint(Point p,QueryStats* stats)const{
    if(stats)++stats->fieldQueries;check(p);if(impl->segments.empty())return {};
    const auto& f=impl->falloff;const double width=f.inside+f.outside;
    const double d=signedDistance(p,stats);
    if(d< -f.outside)return {};
    const double t=width>0?std::clamp((d+f.outside)/width,0.,1.):1.;
    return {width>0&&f.density?curve(f.densityCurve,t):1.,f.scale?f.scaleMin+(f.scaleMax-f.scaleMin)*curve(f.scaleCurve,t):1.};
}
Evaluation Field::query(Anchor a,QueryStats* stats)const{auto p=impl->surface.position(a);return queryPoint({p.x,p.y},stats);}
bool Field::accepts(Anchor a,double u,double density,QueryStats* stats)const{return u<std::clamp(evaluate(a,stats)*density,0.,1.);}
std::vector<std::array<Vec3,2>> boundary(const Surface& s,const Document& d,std::size_t budget){
    std::vector<std::array<Vec3,2>> out;double lo=INFINITY,hi=-INFINITY,extent=0;
    for(auto v:s.mesh().vertices){lo=std::min(lo,v.z);hi=std::max(hi,v.z);extent=std::max({extent,std::abs(v.x),std::abs(v.y)});}
    const double step=std::max(1.e-3,extent/256.);const double top=hi+std::max(1.,hi-lo),offset=std::max(1.e-4,extent*1.e-6);
    auto lift=[&](Point p,Vec3& v){Hit hit;if(!s.hit({{p[0],p[1],top},{0,0,-1}},hit))return false;v=s.position(hit.anchor);v.z+=offset;return true;};
    for(const auto& c:d.contours)for(std::size_t i=0;i<c.size();++i){auto a=c[i],b=c[(i+1)%c.size()];const auto v=sub(b,a);const auto count=std::max<std::size_t>(1,std::size_t(std::ceil(std::sqrt(dot(v,v))/step)));
        if(count>budget-out.size())throw std::runtime_error("Vector feedback capacity reached; previous complete feedback retained");
        Vec3 last;bool prior=lift(a,last);
        for(std::size_t k=1;k<=count;++k){double t=double(k)/double(count);Vec3 next;bool valid=lift({a[0]+v[0]*t,a[1]+v[1]*t},next);if(prior&&valid)out.push_back({last,next});last=next;prior=valid;}
    }return out;
}
double threshold(std::uint64_t population,std::uint64_t candidate){
    std::uint64_t v=population^(candidate+0x9e3779b97f4a7c15ULL);v=(v^(v>>30))*0xbf58476d1ce4e5b9ULL;v=(v^(v>>27))*0x94d049bb133111ebULL;v^=v>>31;return double(v>>11)*(1./9007199254740992.);
}
bool accepted(std::uint64_t p,std::uint64_t c,double mask,double density){return threshold(p,c)<std::clamp(mask*density,0.,1.);}
std::vector<std::uint8_t> encode(const Document& d){
    validate(d.falloff);pack(d.contours);std::vector<std::uint8_t> out;put(out,std::uint64_t(0x31524f5443455653ULL));put(out,d.surface);
    const auto& f=d.falloff;for(double v:{f.inside,f.outside,f.scaleMin,f.scaleMax})put(out,v);
    put(out,std::uint32_t(f.density));put(out,std::uint32_t(f.scale));
    for(const auto* c:{&f.densityCurve,&f.scaleCurve}){put(out,std::uint32_t(c->size()));for(double v:*c)put(out,v);}
    put(out,std::uint32_t(d.contours.size()));for(const auto& c:d.contours){put(out,std::uint32_t(c.size()));for(auto p:c){put(out,p[0]);put(out,p[1]);}}return out;
}
Document decode(const std::vector<std::uint8_t>& bytes){
    Reader r{bytes};if(r.get<std::uint64_t>()!=0x31524f5443455653ULL)throw std::invalid_argument("Unsupported retired Brush format; 0.78 requires a new vector setup");
    Document d;d.surface=r.get<std::uint64_t>();auto& f=d.falloff;f.inside=r.get<double>();f.outside=r.get<double>();f.scaleMin=r.get<double>();f.scaleMax=r.get<double>();
    const auto density=r.get<std::uint32_t>(),scale=r.get<std::uint32_t>();if(density>1||scale>1)throw std::invalid_argument("Invalid vector flags");f.density=density!=0;f.scale=scale!=0;
    for(auto* c:{&f.densityCurve,&f.scaleCurve}){auto count=r.get<std::uint32_t>();if(count<2||count>257)throw std::invalid_argument("Invalid vector curve");c->clear();for(std::uint32_t i=0;i<count;++i)c->push_back(r.get<double>());}
    const auto count=r.get<std::uint32_t>();if(count>maxVertices/3)throw std::invalid_argument("Vector contour capacity");std::size_t total=0;
    for(std::uint32_t i=0;i<count;++i){auto size=r.get<std::uint32_t>();if(size<3||size>maxVertices-total)throw std::invalid_argument("Vector vertex capacity");total+=size;Contour c;for(std::uint32_t k=0;k<size;++k)c.push_back({r.get<double>(),r.get<double>()});d.contours.push_back(std::move(c));}
    if(r.pos!=bytes.size())throw std::invalid_argument("Trailing vector payload");validate(f);pack(d.contours);return d;
}
}
