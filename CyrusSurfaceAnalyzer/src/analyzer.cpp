#include "analyzer.h"
#include <algorithm>
#include <cmath>
#include <map>
#include <set>
#include <stdexcept>
#include <limits>
namespace cyrus {
double dot(V a,V b){return a.x*b.x+a.y*b.y+a.z*b.z;} double len(V a){return std::sqrt(dot(a,a));}
static V cross(V a,V b){return{a.y*b.z-a.z*b.y,a.z*b.x-a.x*b.z,a.x*b.y-a.y*b.x};}
static double segment(V p,V a,V b){V d=b-a;double t=dot(d,d)>0?std::clamp(dot(p-a,d)/dot(d,d),0.,1.):0;return len(p-a-d*t);}
Result analyzeElement(const Mesh&m,const Settings&s){
 if(m.faces.empty()||m.vertices.empty())throw std::runtime_error("Select a nonempty surface mesh.");
 if(s.resolution<48||s.resolution>768||s.count<1||s.count>10000||s.minWidth<0||s.minLength<0||s.ringFraction<=0||s.ringFraction>=1)throw std::runtime_error("Invalid analysis settings.");
 Result r;V normal{},origin=m.vertices[0];std::map<std::pair<int,int>,int> edges;
 for(auto f:m.faces){for(int k:f)if(k<0||k>=int(m.vertices.size()))throw std::runtime_error("Invalid mesh indices.");V n=cross(m.vertices[f[1]]-m.vertices[f[0]],m.vertices[f[2]]-m.vertices[f[0]]);normal=normal+n;r.area+=len(n)*.5;for(int j=0;j<3;j++)edges[std::minmax(f[j],f[(j+1)%3])]++;}
 if(len(normal)<1e-12)throw std::runtime_error("Degenerate surface or inconsistent face winding.");normal=normal*(1/len(normal));
 std::map<int,std::vector<int>> adj;for(auto e:edges){if(e.second>2)throw std::runtime_error("Non-manifold surface.");if(e.second==1){adj[e.first.first].push_back(e.first.second);adj[e.first.second].push_back(e.first.first);}}
 if(adj.empty())throw std::runtime_error("Use an open planar surface, not a closed solid.");for(auto a:adj)if(a.second.size()!=2)throw std::runtime_error("Boundary must form closed, welded loops.");
 std::set<int> used;std::vector<std::vector<int>> loops;for(auto a:adj)if(!used.count(a.first)){std::vector<int> loop;int first=a.first,prev=-1,cur=first;do{if(used.count(cur))throw std::runtime_error("Invalid boundary loop.");used.insert(cur);loop.push_back(cur);int next=adj[cur][0]==prev?adj[cur][1]:adj[cur][0];prev=cur;cur=next;}while(cur!=first);loops.push_back(loop);}
 V u{};double longest=0;for(auto a:adj)for(int b:a.second){V d=m.vertices[b]-m.vertices[a.first];if(len(d)>longest){longest=len(d);u=d;}}u=u*(1/longest);V v=cross(normal,u);v=v*(1/len(v));
 std::vector<V> p;double extent=0;for(V x:m.vertices)extent=std::max(extent,len(x-origin));for(V x:m.vertices){if(std::abs(dot(x-origin,normal))>std::max(1e-6,extent*1e-5))throw std::runtime_error("First version requires a planar surface (rotation is supported).");p.push_back({dot(x-origin,u),dot(x-origin,v),0});}
 std::vector<std::vector<V>> poly;for(auto loop:loops){std::vector<V> a,b;for(int i:loop){a.push_back(p[i]);b.push_back(m.vertices[i]);}poly.push_back(a);r.boundaries.push_back(b);}
 auto contains=[&](V x){bool in=false;for(auto&loop:poly)for(size_t i=0,j=loop.size()-1;i<loop.size();j=i++){auto a=loop[i],b=loop[j];if((a.y>x.y)!=(b.y>x.y)&&x.x<(b.x-a.x)*(x.y-a.y)/(b.y-a.y)+a.x)in=!in;}return in;};
 auto clearance=[&](V x){double d=std::numeric_limits<double>::max();for(auto&loop:poly)for(size_t i=0;i<loop.size();i++)d=std::min(d,segment(x,loop[i],loop[(i+1)%loop.size()]));return d;};
 auto world=[&](V x){return origin+u*x.x+v*x.y;};
 double xmin=p[0].x,xmax=xmin,ymin=p[0].y,ymax=ymin;for(V x:p){xmin=std::min(xmin,x.x);xmax=std::max(xmax,x.x);ymin=std::min(ymin,x.y);ymax=std::max(ymax,x.y);}
 double cell=std::max(xmax-xmin,ymax-ymin)/s.resolution;int w=int(std::ceil((xmax-xmin)/cell))+4,h=int(std::ceil((ymax-ymin)/cell))+4;auto pos=[&](int x,int y){return V{xmin+(x-1.5)*cell,ymin+(y-1.5)*cell,0};};
 std::vector<unsigned char> mask(w*h),sk;std::vector<double> dist(w*h);V center{};double bestD=-1;int bestI=0;
 for(int y=1;y<h-1;y++)for(int x=1;x<w-1;x++){int i=y*w+x;V q=pos(x,y);if(contains(q)){mask[i]=1;dist[i]=clearance(q);if(dist[i]>bestD){bestD=dist[i];bestI=i;center=q;}}}
 if(bestD<=0)throw std::runtime_error("Surface is smaller than analysis resolution.");
 // A radial star has balanced alternating radii; an orthogonal corridor has perpendicular edges.
 bool orth=true;for(auto&loop:poly)for(size_t i=0;i<loop.size();i++){V d=loop[(i+1)%loop.size()]-loop[i];if(len(d)>longest*.1 && std::min(std::abs(d.x),std::abs(d.y))>len(d)*.08)orth=false;}
 bool radial=false;if(poly.size()==1&&poly[0].size()>=8){auto &a=poly[0];V c{};for(V q:a)c=c+q;c=c*(1./a.size());double lo=1e100,hi=0;int peaks=0;for(size_t i=0;i<a.size();i++){double d=len(a[i]-c);lo=std::min(lo,d);hi=std::max(hi,d);if(d>len(a[(i+a.size()-1)%a.size()]-c)*1.1&&d>len(a[(i+1)%a.size()]-c)*1.1)peaks++;}double xx=0,yy=0,xy=0;for(V q:a){q=q-c;xx+=q.x*q.x;yy+=q.y*q.y;xy+=q.x*q.y;}double anis=std::sqrt((xx-yy)*(xx-yy)+4*xy*xy)/std::max(xx+yy,1e-20);radial=peaks>=4&&hi>lo*1.3&&anis<.18&&contains(c);if(radial)center=c;}
 r.mode=s.mode?s.mode:(radial?2:orth?1:3);
 std::vector<std::vector<V>> paths;
 if(r.mode==2){double radius=std::min(clearance(center)*s.ringFraction,std::max(0.,clearance(center)-s.fitRadius-cell*.05));if(radius>cell*.01 && radius*2>=s.minWidth&&6.283185307179586*radius>=s.minLength){std::vector<V>a;for(int i=0;i<=128;i++){double t=6.283185307179586*i/128;a.push_back(center+V{std::cos(t)*radius,std::sin(t)*radius,0});}paths.push_back(a);r.regionArea=3.141592653589793*radius*radius;}}
 else if(r.mode==1){
 // Largest interior raster rectangle. Basis follows the longest boundary edge, not world axes.
 std::vector<int> height(w);double best=0;int bx=0,by=0,bw=0,bh=0;
 for(int y=1;y<h-1;y++){for(int x=0;x<w;x++)height[x]=mask[y*w+x]?height[x]+1:0;std::vector<int> st;for(int x=0;x<w;x++){while(!st.empty()&&height[st.back()]>height[x]){int idx=st.back();st.pop_back();int left=st.empty()?0:st.back()+1;int ww=x-left,hh=height[idx];double a=double(ww)*hh;if(a>best&&std::min(ww,hh)*cell>=s.minWidth&&std::max(ww,hh)*cell>=s.minLength){best=a;bx=left;by=y-hh+1;bw=ww;bh=hh;}}st.push_back(x);}}
 if(best>0){V a=pos(bx,by),b=pos(bx+bw-1,by+bh-1);double inset=std::min(bw,bh)*cell*.3;if(bw>=bh){double cy=(a.y+b.y)*.5;paths.push_back({{a.x+inset,cy,0},{b.x-inset,cy,0}});}else{double cx=(a.x+b.x)*.5;paths.push_back({{cx,a.y+inset,0},{cx,b.y-inset,0}});}r.regionArea=best*cell*cell;}
 }else{
 sk=mask;std::vector<int> erase;bool changed=true;int dx[8]={0,1,1,1,0,-1,-1,-1},dy[8]={-1,-1,0,1,1,1,0,-1};
 // Topology-preserving thinning followed by width and branch-length pruning.
 while(changed){changed=false;for(int pass=0;pass<2;pass++){erase.clear();for(int y=1;y<h-1;y++)for(int x=1;x<w-1;x++){int i=y*w+x;if(!sk[i])continue;int a[8],n=0,t=0;for(int k=0;k<8;k++){a[k]=sk[i+dy[k]*w+dx[k]];n+=a[k];}for(int k=0;k<8;k++)if(!a[k]&&a[(k+1)%8])t++;if(n<2||n>6||t!=1)continue;if(pass==0?(a[0]*a[2]*a[4]||a[2]*a[4]*a[6]):(a[0]*a[2]*a[6]||a[0]*a[4]*a[6]))continue;erase.push_back(i);}for(int i:erase)sk[i]=0;if(!erase.empty())changed=true;}}
 double minWidth=s.minWidth>0?s.minWidth:bestD*.5;for(int i=0;i<w*h;i++)if(sk[i]&&dist[i]*2<minWidth)sk[i]=0;
 auto neighbors=[&](int i){std::vector<int> ns;for(int k=0;k<8;k++){int j=i+dy[k]*w+dx[k];if(j<0||j>=w*h||!sk[j])continue;if(dx[k]&&dy[k]&&(sk[i+dx[k]]||sk[i+dy[k]*w]))continue;ns.push_back(j);}return ns;};
 std::set<std::pair<int,int>> seen;auto trace=[&](int start,int next){std::vector<V>a{pos(start%w,start/w)};int prev=start,cur=next;seen.insert(std::minmax(prev,cur));for(int guard=0;guard<w*h;guard++){a.push_back(pos(cur%w,cur/w));auto ns=neighbors(cur);if(ns.size()!=2||cur==start)break;int n=ns[0]==prev?ns[1]:ns[0];if(seen.count(std::minmax(cur,n)))break;seen.insert(std::minmax(cur,n));prev=cur;cur=n;}double length=0;for(size_t j=1;j<a.size();j++)length+=len(a[j]-a[j-1]);if(length>=std::max(s.minLength,cell*4))paths.push_back(a);};
 for(int i=0;i<w*h;i++)if(sk[i]&&neighbors(i).size()!=2)for(int n:neighbors(i))if(!seen.count(std::minmax(i,n)))trace(i,n);
 for(int i=0;i<w*h;i++)if(sk[i])for(int n:neighbors(i))if(!seen.count(std::minmax(i,n)))trace(i,n);
 for(int i=0;i<w*h;i++)if(mask[i]&&dist[i]*2>=minWidth)r.regionArea+=cell*cell;
 }
 // Fit radius constrains the entire footprint, independently of point-to-point spacing.
 auto fits=[&](V q){return contains(q)&&clearance(q)>=s.fitRadius+cell*1e-4;};
 if(s.fitRadius>0){
  std::vector<std::vector<V>> clipped;size_t budget=0;
  for(const auto& path:paths){std::vector<V> run;
   auto flush=[&](){if(run.size()>1)clipped.push_back(run);run.clear();};
   for(size_t j=1;j<path.size();j++){int steps=std::max(1,int(std::ceil(len(path[j]-path[j-1])/(cell*.5))));budget+=steps;if(budget>2000000)throw std::runtime_error("Boundary clipping exceeded work budget.");
    for(int k=(j==1?0:1);k<=steps;k++){V q=path[j-1]+(path[j]-path[j-1])*(double(k)/steps);if(fits(q))run.push_back(q);else flush();}
   }flush();
  }
  paths=std::move(clipped);
  r.regionArea=0;for(int i=0;i<w*h;i++)if(mask[i]&&dist[i]>=s.fitRadius)r.regionArea+=cell*cell;
 }
 // Constrained Laplacian relaxation reduces raster zigzags, without smoothing a ring inward.
 if(s.relaxIterations>0 && r.mode!=2)for(auto& path:paths){
  for(int iteration=0;iteration<s.relaxIterations;iteration++){auto next=path;double movement=0;
   for(size_t j=1;j+1<path.size();j++){V target=(path[j-1]+path[j+1])*.5;V q=path[j]+(target-path[j])*.6;
    if(contains(q)&&clearance(q)>=s.fitRadius+cell*1e-4){next[j]=q;movement=std::max(movement,len(q-path[j]));}
   }path=std::move(next);if(movement<cell*1e-4)break;
  }
 }
 std::vector<double> lengths;for(auto&a:paths){double l=0;std::vector<V>b;for(size_t j=0;j<a.size();j++){if(j)l+=len(a[j]-a[j-1]);b.push_back(world(a[j]));}lengths.push_back(l);r.pathLength+=l;r.paths.push_back(b);}
 if(s.pointRadius==0 && r.pathLength>0)for(int k=0;k<s.count;k++){double target=r.mode==2?r.pathLength*k/s.count:r.pathLength*(k+.5)/s.count;size_t path=0;while(path+1<paths.size()&&target>lengths[path])target-=lengths[path++];auto&a=paths[path];for(size_t j=1;j<a.size();j++){double d=len(a[j]-a[j-1]);if(target<=d||j+1==a.size()){r.points.push_back(world(a[j-1]+(a[j]-a[j-1])*(d>0?std::clamp(target/d,0.,1.):0)));break;}target-=d;}}
 return r;
}
}



