#include "grid.h"
#include <algorithm>
#include <cmath>
#include <limits>
#include <numeric>
#include <stdexcept>

namespace cyrus::grid {
namespace {
constexpr std::uint64_t mask=(1ULL<<26)-1;
constexpr double pi=3.1415926535897932384626433832795;
void require(bool test,const char* message){if(!test)throw std::invalid_argument(message);}
bool finite(amin::Vec3 p){return std::isfinite(p.x)&&std::isfinite(p.y)&&std::isfinite(p.z);}
bool valid(Mode m){return m==Mode::Rectangular||m==Mode::Staggered||m==Mode::Hexagonal;}
unsigned parity(std::int64_t y){return unsigned((y%2+2)%2);}
struct Box {
    double x0=INFINITY,y0=INFINITY,x1=-INFINITY,y1=-INFINITY;
    void add(amin::Vec3 p){x0=std::min(x0,p.x);y0=std::min(y0,p.y);x1=std::max(x1,p.x);y1=std::max(y1,p.y);}
    void add(const Box& b){add(amin::Vec3{b.x0,b.y0,0});add(amin::Vec3{b.x1,b.y1,0});}
    bool contains(double x,double y)const {
        const double e=64*std::numeric_limits<double>::epsilon()*std::max({1.,std::abs(x0),std::abs(x1),std::abs(y0),std::abs(y1)});
        return x>=x0-e&&x<=x1+e&&y>=y0-e&&y<=y1+e;
    }
};
struct Face {amin::Vec3 a,b,c;Box box;double det{};std::uint32_t original{};};
struct Node {Box box;std::uint32_t begin{},end{},left{},right{};};
struct Projection {
    std::vector<Face> faces;
    std::vector<std::uint32_t> order;
    std::vector<Node> nodes;
    const Limits limits;
    std::uint64_t visits=0;
    explicit Projection(Limits l):limits(l){}
    std::uint32_t build(std::uint32_t begin,std::uint32_t end){
        const auto index=std::uint32_t(nodes.size());nodes.push_back({});
        Box box;for(auto i=begin;i<end;++i)box.add(faces[order[i]].box);
        nodes[index].box=box;nodes[index].begin=begin;nodes[index].end=end;
        if(end-begin>8){
            const bool x=box.x1-box.x0>=box.y1-box.y0;const auto mid=begin+(end-begin)/2;
            std::nth_element(order.begin()+begin,order.begin()+mid,order.begin()+end,[&](auto a,auto b){
                const auto& u=faces[a].box;const auto& v=faces[b].box;
                const double ca=x?u.x0*.5+u.x1*.5:u.y0*.5+u.y1*.5,cb=x?v.x0*.5+v.x1*.5:v.y0*.5+v.y1*.5;
                return ca<cb||(ca==cb&&faces[a].original<faces[b].original);
            });
            const auto left=build(begin,mid),right=build(mid,end);nodes[index].left=left;nodes[index].right=right;
        }
        return index;
    }
    void visit(){require(visits<limits.visits,"Grid projection work limit exceeded; reduce the domain or geometry");++visits;}
    void query(std::uint32_t index,double x,double y,Anchor& hit,bool& found){
        visit();const auto& n=nodes[index];if(!n.box.contains(x,y))return;
        if(n.left){query(n.left,x,y,hit,found);query(n.right,x,y,hit,found);return;}
        for(auto i=n.begin;i<n.end;++i){
            visit();const auto& t=faces[order[i]];if(!t.box.contains(x,y))continue;
            const double ax=t.b.x-t.a.x,ay=t.b.y-t.a.y,bx=t.c.x-t.a.x,by=t.c.y-t.a.y;
            const double px=x-t.a.x,py=y-t.a.y;
            const double b=(px*by-py*bx)/t.det,c=(ax*py-ay*px)/t.det,a=1-b-c;
            constexpr double edge=128*std::numeric_limits<double>::epsilon();
            if(a < -edge||b < -edge||c < -edge)continue;
            // Preserve a constant-height plane exactly, including shared edges.
            const double z=t.a.z+b*(t.b.z-t.a.z)+c*(t.c.z-t.a.z);
            require(std::isfinite(z),"Grid projection height overflow");
            if(!found||z>hit.position.z||(z==hit.position.z&&t.original<hit.face)){
                found=true;hit.position.z=z;hit.bary={a,b,c};hit.face=t.original;
            }
        }
    }
};
struct Range {std::int64_t lo{},hi{};std::uint64_t size()const{return hi<lo?0:std::uint64_t(hi-lo+1);}};
Range cells(double lo,double hi){
    require(std::isfinite(lo)&&std::isfinite(hi),"Grid cell range overflow");
    const auto tolerance=[](double v){return 64*std::numeric_limits<double>::epsilon()*std::max(1.,std::abs(v));};
    const double a=std::ceil(lo-tolerance(lo)),b=std::floor(hi+tolerance(hi));
    if(a>b)return {0,-1};
    require(a>=minCell&&b<=maxCell,"Grid cell coordinates exceed the signed 26-bit domain; move the origin or increase spacing");
    return {std::int64_t(a),std::int64_t(b)};
}
}
std::uint64_t identity(Cell c){
    require(valid(c.mode)&&c.receiver<128&&c.column>=minCell&&c.column<=maxCell&&c.row>=minCell&&c.row<=maxCell,"Invalid grid cell identity");
    return marker|(std::uint64_t(unsigned(c.mode)-1)<<59)|(std::uint64_t(c.receiver)<<52)|
        (std::uint64_t(std::int64_t(c.column)-minCell)<<26)|std::uint64_t(std::int64_t(c.row)-minCell);
}
bool decode(std::uint64_t id,Cell& c)noexcept{
    if((id>>61)!=1)return false;
    const auto mode=unsigned((id>>59)&3)+1;if(mode>3)return false;
    c={Mode(mode),unsigned((id>>52)&127),std::int32_t((id>>26)&mask)+minCell,std::int32_t(id&mask)+minCell};return true;
}
void validate(const Settings& s){
    require(valid(s.mode)&&std::isfinite(s.columnSpacing)&&s.columnSpacing>0&&std::isfinite(s.rowSpacing)&&s.rowSpacing>0&&
        std::isfinite(s.originX)&&std::isfinite(s.originY)&&std::isfinite(s.headingDegrees)&&std::isfinite(s.jitter)&&s.jitter>=0&&s.jitter<=1,"Invalid grid settings");
}
Result generate(const std::vector<amin::Triangle>& surface,const Settings& s,Limits limits){
    validate(s);
    require(limits.cells<=1000000&&limits.triangles<=2000000&&limits.visits<=64000000&&limits.bytes<=512ULL*1024*1024,"Grid limits exceed supported admission");
    require(!surface.empty()&&surface.size()<=limits.triangles,"Grid receiver exceeds triangle admission or is empty");
    const std::uint64_t estimate=surface.size()*(sizeof(Face)+sizeof(std::uint32_t)+2*sizeof(Node))+limits.cells*sizeof(Anchor);
    require(estimate<=limits.bytes,"Grid numeric memory admission exceeded");
    const double angle=std::remainder(s.headingDegrees,360.)*(pi/180.),cs=std::cos(angle),sn=std::sin(angle);
    const double pitch=s.mode==Mode::Hexagonal?s.columnSpacing*(std::sqrt(3.)*.5):s.rowSpacing;
    require(std::isfinite(pitch)&&pitch>0,"Grid row pitch overflow");
    const auto local=[&](amin::Vec3 p){require(finite(p),"Nonfinite grid receiver vertex");const double x=p.x-s.originX,y=p.y-s.originY;amin::Vec3 q{x*cs+y*sn,-x*sn+y*cs,p.z};require(finite(q),"Grid frame overflow");return q;};
    Projection projector(limits);projector.faces.reserve(surface.size());Box bounds;
    for(std::size_t i=0;i<surface.size();++i){
        const auto& t=surface[i];Face f{local(t.a),local(t.b),local(t.c),{},0,std::uint32_t(i)};
        const double u=(f.b.x-f.a.x)*(f.c.y-f.a.y),v=(f.b.y-f.a.y)*(f.c.x-f.a.x);f.det=u-v;
        require(std::isfinite(u)&&std::isfinite(v)&&std::isfinite(f.det),"Grid projected triangle overflow");
        if(std::abs(f.det)<=64*std::numeric_limits<double>::epsilon()*std::max(std::abs(u),std::abs(v)))continue;
        f.box.add(f.a);f.box.add(f.b);f.box.add(f.c);bounds.add(f.box);projector.faces.push_back(f);
    }
    require(!projector.faces.empty(),"Grid needs a receiver with a nondegenerate world-XY footprint");
    const double half=s.jitter*.5;
    const auto ys=cells(bounds.y0/pitch-half,bounds.y1/pitch+half);
    const auto xs=cells(bounds.x0/s.columnSpacing-half,bounds.x1/s.columnSpacing+half);
    const auto shifted=s.mode==Mode::Rectangular?xs:cells(bounds.x0/s.columnSpacing-.5-half,bounds.x1/s.columnSpacing-.5+half);
    Result result;const std::uint64_t rows=ys.size(),odd=rows/2+(rows%2&&parity(ys.lo)==1),even=rows-odd;
    // Cell counts, not triangle hits, admit work before enumeration. Never truncate.
    result.enumeratedCells=even*xs.size()+odd*shifted.size();
    require(result.enumeratedCells<=limits.cells,"Grid candidate admission exceeded; increase spacing or reduce the domain");
    if(!result.enumeratedCells)return result;
    projector.order.resize(projector.faces.size());std::iota(projector.order.begin(),projector.order.end(),0u);
    projector.nodes.reserve(projector.faces.size()*2);projector.build(0,std::uint32_t(projector.faces.size()));
    result.anchors.reserve(std::size_t(result.enumeratedCells));
    for(auto y=ys.lo;y<=ys.hi;++y){
        const bool stagger=s.mode!=Mode::Rectangular&&parity(y);const auto range=stagger?shifted:xs;
        for(auto x=range.lo;x<=range.hi;++x){
            Anchor a;a.key=identity({s.mode,0,std::int32_t(x),std::int32_t(y)});
            const double dx=(amin::stableUnit(s.seed,a.key,0x4752494458ULL,s.receiverSalt)*2-1)*half;
            const double dy=(amin::stableUnit(s.seed,a.key,0x4752494459ULL,s.receiverSalt)*2-1)*half;
            const double px=(double(x)+(stagger?.5:0)+dx)*s.columnSpacing,py=(double(y)+dy)*pitch;
            a.position={s.originX+px*cs-py*sn,s.originY+px*sn+py*cs,-INFINITY};
            require(std::isfinite(a.position.x)&&std::isfinite(a.position.y),"Grid position overflow");
            bool found=false;projector.query(0,px,py,a,found);if(found)result.anchors.push_back(a);
        }
    }
    result.projectionVisits=projector.visits;return result;
}
}
