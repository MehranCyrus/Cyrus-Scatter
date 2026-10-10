#include "../../../src/tiles.h"
namespace paintlab {
class Field final:public Kernel {
 struct Patch {V a,u,v,n;double bx,cx,cy;};
 std::shared_ptr<const std::vector<Patch>> patches;std::shared_ptr<const std::vector<unsigned>> components;double h;Tiles pixels,before,stencil;Settings settings;Hit last;bool connected=false;Stats counters;
 V project(const Patch& f,V p)const{return{dot(p-f.a,f.u),dot(p-f.a,f.v),0};}
 bool inside(const Patch& f,V q)const{double v=q.y/f.cy,u=(q.x-v*f.cx)/f.bx;return u>=0&&v>=0&&u+v<=1;}
public:
 Field(const Mesh& m,double res):h(res){auto p=std::make_shared<std::vector<Patch>>();for(auto face:m.faces){V a=m.vertices[face[0]],b=m.vertices[face[1]],c=m.vertices[face[2]],u=unit(b-a),n=unit(cross(b-a,c-a)),v=cross(n,u);p->push_back({a,u,v,n,length(b-a),dot(c-a,u),dot(c-a,v)});}patches=p;
  std::vector<unsigned> parent(m.faces.size());for(unsigned i=0;i<parent.size();++i)parent[i]=i;
  auto root=[&](unsigned x){while(parent[x]!=x){parent[x]=parent[parent[x]];x=parent[x];}return x;};
  std::map<std::pair<unsigned,unsigned>,std::vector<unsigned>> edges;
  for(unsigned i=0;i<m.faces.size();++i)for(int e=0;e<3;++e){auto a=m.faces[i][e],b=m.faces[i][(e+1)%3];if(a>b)std::swap(a,b);edges[{a,b}].push_back(i);}
  for(auto& [edge,faces]:edges)if(faces.size()==2)parent[root(faces[0])]=root(faces[1]);
  for(unsigned i=0;i<parent.size();++i)parent[i]=root(i);components=std::make_shared<std::vector<unsigned>>(std::move(parent));
 }
 std::unique_ptr<Kernel> clone()const override{return std::make_unique<Field>(*this);}
 void begin(Settings s)override{settings=s;before=pixels;stencil={};connected=false;}
 void append(Hit hit)override{Hit a=connected&&hit.connected?last:hit;Segment segment{a,hit,settings};double r=std::max(a.radius,hit.radius);std::size_t visited=0;auto seedNormal=patches->at(hit.anchor.face).n;
  for(unsigned face=0;face<patches->size();++face){const auto& f=(*patches)[face]; // Prototype restriction: same-facing patches, Euclidean swept volume. NOT geodesic.
   if((*components)[face]!=(*components)[hit.anchor.face]||dot(seedNormal,f.n)<=0)continue;double da=dot(a.p-f.a,f.n),db=dot(hit.p-f.a,f.n);if(std::min(da,db)>r||std::max(da,db)<-r)continue;
   auto pa=project(f,a.p),pb=project(f,hit.p);double loX=std::max(std::min(pa.x,pb.x)-r,std::min({0.,f.bx,f.cx})),hiX=std::min(std::max(pa.x,pb.x)+r,std::max({0.,f.bx,f.cx})),loY=std::max(std::min(pa.y,pb.y)-r,0.),hiY=std::min(std::max(pa.y,pb.y)+r,f.cy);if(loX>hiX||loY>hiY)continue;int x0,x1,y0,y1;bounds(loX,hiX,h,x0,x1);bounds(loY,hiY,h,y0,y1);if(visited+double(x1-x0+1)*(y1-y0+1)>2000000)throw std::runtime_error("Surface edit exceeds 2 million samples");
   for(int y=y0;y<=y1;++y)for(int x=x0;x<=x1;++x){++visited;V q{(x+.5)*h,(y+.5)*h,0};if(!inside(f,q)){
     V nearest;double distance=1e300;std::array<V,3> corners={V{0,0,0},V{f.bx,0,0},V{f.cx,f.cy,0}};
     for(int edge=0;edge<3;++edge){V a=corners[edge],b=corners[(edge+1)%3],ab=b-a;double t=std::clamp(dot(q-a,ab)/dot(ab,ab),0.,1.);V candidate=a+ab*t;double d=length(q-candidate);if(d<distance){distance=d;nearest=candidate;}}
     if(distance>h*1.5)continue;q=nearest;
    }double alpha=std::max(double(stencil.get(face,x,y)),influence(f.a+f.u*q.x+f.v*q.y,segment));if(alpha>stencil.get(face,x,y)){stencil.set(face,x,y,float(alpha));pixels.set(face,x,y,float(blend(before.get(face,x,y),alpha,settings.erase)));++counters.touched;}}}
  last=hit;connected=true;++counters.edits;}
 void end()override{before={};stencil={};connected=false;}
 double query(Anchor a,V p)const override{const auto& f=patches->at(a.face);auto q=project(f,p);return pixels.get(a.face,int(std::floor(q.x/h)),int(std::floor(q.y/h)));}
 std::string save()const override{return pixels.save();}void load(const std::string& b)override{pixels.load(b,unsigned(patches->size()));}
 Stats stats()const override{auto s=counters;s.bytes=pixels.bytes()+before.bytes()+stencil.bytes()+patches->size()*sizeof(Patch);s.items=pixels.blocks.size();return s;}
};
std::unique_ptr<Kernel> makeField(const Mesh& m,double r){return std::make_unique<Field>(m,r);}
}
