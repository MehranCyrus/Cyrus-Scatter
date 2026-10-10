#include "../../../src/lab.h"
#include "clipper2/clipper.h"
#include <algorithm>
namespace paintlab {
using namespace Clipper2Lib;
class Vector final:public Kernel {
 Frame frame;double precision;Paths64 paths;Settings settings;Hit last;bool connected=false;Stats counters;
 Path64 disk(V p,double r)const{Path64 out;double error=std::min(precision/4,r/10),angle=std::acos(std::clamp(1-error/r,-1.,1.));int n=std::clamp(int(std::ceil(3.141592653589793/angle)),12,8192);for(int i=0;i<n;++i){double a=6.283185307179586*i/n;out.emplace_back(std::llround((p.x+r*std::cos(a))/precision),std::llround((p.y+r*std::sin(a))/precision));}return out;}
public:
 Vector(const Mesh& m,double p):frame(m),precision(p){}
 std::unique_ptr<Kernel> clone()const override{return std::make_unique<Vector>(*this);}
 void begin(Settings s)override{if(s.softness||s.strength!=1)throw std::runtime_error("A supports hard regions; soft interior opacity is unavailable");settings=s;connected=false;}
 void append(Hit h)override{auto p=frame.project(h.p);if(std::max(std::abs(p.x),std::abs(p.y))/precision>1e13||h.radius/precision>1e10)throw std::runtime_error("Vector coordinate range");Paths64 shape{disk(p,h.radius)};
  if(connected&&h.connected){auto q=frame.project(last.p);auto a=disk(q,last.radius),b=shape[0]; // Convex hull of endpoint disks is a linearly varying-radius sweep.
   std::vector<Point64> all=a;all.insert(all.end(),b.begin(),b.end());std::sort(all.begin(),all.end(),[](auto a,auto b){return a.x<b.x||(a.x==b.x&&a.y<b.y);});auto turn=[](Point64 a,Point64 b,Point64 c){return (long double)(b.x-a.x)*(c.y-a.y)-(long double)(b.y-a.y)*(c.x-a.x);};Path64 hull;for(auto x:all){while(hull.size()>1&&turn(hull[hull.size()-2],hull.back(),x)<=0)hull.pop_back();hull.push_back(x);}auto lower=hull.size();for(auto it=all.rbegin()+1;it!=all.rend();++it){while(hull.size()>lower&&turn(hull[hull.size()-2],hull.back(),*it)<=0)hull.pop_back();hull.push_back(*it);}if(!hull.empty())hull.pop_back();shape={hull};}
  paths=BooleanOp(settings.erase?ClipType::Difference:ClipType::Union,FillRule::NonZero,paths,shape);last=h;connected=true;++counters.edits;
 }
 void end()override{connected=false;}
 double query(Anchor,V p)const override{auto q=frame.project(p);Point64 pt(std::llround(q.x/precision),std::llround(q.y/precision));bool in=false;for(auto& path:paths){auto r=PointInPolygon(pt,path);if(r==PointInPolygonResult::IsOn)return 1;if(r==PointInPolygonResult::IsInside)in=!in;}return in?1:0;}
 std::vector<std::array<V,2>> exactBoundary()const override{std::vector<std::array<V,2>> out;for(auto& p:paths)for(std::size_t i=0;i<p.size();++i){auto a=p[i],b=p[(i+1)%p.size()];out.push_back({frame.lift({a.x*precision,a.y*precision,0}),frame.lift({b.x*precision,b.y*precision,0})});}return out;}
 std::string save()const override{std::ostringstream o;o<<paths.size()<<'\n';for(auto& p:paths){o<<p.size()<<' ';for(auto v:p)o<<v.x<<' '<<v.y<<' ';o<<'\n';}return o.str();}
 void load(const std::string& bytes)override{std::istringstream in(bytes);std::size_t n;if(!(in>>n)||n>1000000)throw std::runtime_error("Invalid contours");Paths64 next;std::size_t total=0;for(std::size_t i=0;i<n;++i){std::size_t k;if(!(in>>k)||k<3||(total+=k)>4000000)throw std::runtime_error("Invalid contour size");Path64 p;for(std::size_t j=0;j<k;++j){std::int64_t x,y;if(!(in>>x>>y)||std::abs((long double)x)>1e13||std::abs((long double)y)>1e13)throw std::runtime_error("Invalid contour coordinate");p.emplace_back(x,y);}next.push_back(std::move(p));}paths=std::move(next);}
 Stats stats()const override{auto s=counters;for(auto& p:paths){s.items+=p.size();s.bytes+=p.capacity()*sizeof(Point64);}return s;}
};
std::unique_ptr<Kernel> makeVector(const Mesh& m,double r){return std::make_unique<Vector>(m,r);}
}
