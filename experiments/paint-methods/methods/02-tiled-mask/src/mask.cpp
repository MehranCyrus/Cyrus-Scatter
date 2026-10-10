#include "../../../src/tiles.h"
namespace paintlab {
class Mask final:public Kernel {
 Frame frame;double h;Tiles pixels,before,stencil;Settings settings;Hit last;bool connected=false;Stats counters;
public:
 Mask(const Mesh& m,double res):frame(m),h(res){}
 std::unique_ptr<Kernel> clone()const override{return std::make_unique<Mask>(*this);}
 void begin(Settings s)override{settings=s;before=pixels;stencil={};connected=false;}
 void append(Hit hit)override{Hit b=hit;b.p=frame.project(hit.p);Hit a=connected&&hit.connected?last:b;Segment segment{a,b,settings};double r=std::max(a.radius,b.radius);int x0,x1,y0,y1;bounds(std::min(a.p.x,b.p.x)-r,std::max(a.p.x,b.p.x)+r,h,x0,x1);bounds(std::min(a.p.y,b.p.y)-r,std::max(a.p.y,b.p.y)+r,h,y0,y1);if(double(x1-x0+1)*(y1-y0+1)>2000000)throw std::runtime_error("Brush exceeds 2 million cells; increase resolution");
  for(int y=y0;y<=y1;++y)for(int x=x0;x<=x1;++x){double a=std::max(double(stencil.get(0,x,y)),influence({(x+.5)*h,(y+.5)*h,0},segment));if(a>stencil.get(0,x,y)){stencil.set(0,x,y,float(a));pixels.set(0,x,y,float(blend(before.get(0,x,y),a,settings.erase)));++counters.touched;}}last=b;connected=true;++counters.edits;}
 void end()override{before={};stencil={};connected=false;}
 double query(Anchor,V p)const override{auto q=frame.project(p);return pixels.get(0,int(std::floor(q.x/h)),int(std::floor(q.y/h)));}
 std::string save()const override{return pixels.save();}void load(const std::string& b)override{pixels.load(b,1);}
 Stats stats()const override{auto s=counters;s.bytes=pixels.bytes()+before.bytes()+stencil.bytes();s.items=pixels.blocks.size();return s;}
};
std::unique_ptr<Kernel> makeMask(const Mesh& m,double r){return std::make_unique<Mask>(m,r);}
}
