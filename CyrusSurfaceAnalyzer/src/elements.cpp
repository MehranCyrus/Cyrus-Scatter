#include "analyzer.h"
#include <algorithm>
#include <cmath>
#include <map>
#include <numeric>
#include <stdexcept>
#include <string>
#include <tuple>
#include <cstdint>
#include <optional>

namespace cyrus {
Result analyzeElement(const Mesh&,const Settings&);

// Mesh elements are connected through shared topology edges. Holes stay in their element.
static std::vector<Mesh> elements(const Mesh& mesh) {
 std::vector<int> parent(mesh.faces.size());std::iota(parent.begin(),parent.end(),0);
 auto root=[&](int a){while(parent[a]!=a){parent[a]=parent[parent[a]];a=parent[a];}return a;};
 std::map<std::pair<int,int>,int> owner;
 for(int i=0;i<int(mesh.faces.size());++i){auto face=mesh.faces[i];
  for(int v:face)if(v<0||v>=int(mesh.vertices.size()))throw std::runtime_error("Invalid mesh indices.");
  for(int k=0;k<3;k++){auto edge=std::minmax(face[k],face[(k+1)%3]);auto found=owner.emplace(edge,i);if(!found.second)parent[root(i)]=root(found.first->second);}
 }
 std::map<int,int> groups;std::vector<Mesh> out;std::vector<std::map<int,int>> remaps;
 for(int i=0;i<int(mesh.faces.size());++i){int r=root(i);if(!groups.count(r)){groups[r]=int(out.size());out.emplace_back();remaps.emplace_back();}int group=groups[r];auto& part=out[group];auto& remap=remaps[group];std::array<int,3> face;
  for(int k=0;k<3;k++){int old=mesh.faces[i][k];if(!remap.count(old)){remap[old]=int(part.vertices.size());part.vertices.push_back(mesh.vertices[old]);}face[k]=remap[old];}part.faces.push_back(face);
 }
 return out;
}

// Global world-space exclusion includes points on neighboring elements and branch junctions.
class Spacing {
 double radius;V origin;bool started=false;
 using Key=std::tuple<int64_t,int64_t,int64_t>;
 std::map<Key,std::vector<V>> buckets;
public:
 explicit Spacing(double r):radius(r){}
 bool accept(V p,bool force=false){
  if(!started){origin=p;started=true;}V q=(p-origin)*(1/radius);
  if(!std::isfinite(q.x)||!std::isfinite(q.y)||!std::isfinite(q.z)||std::max({std::abs(q.x),std::abs(q.y),std::abs(q.z)})>1e15)throw std::runtime_error("Spacing radius too small for scene extent.");
  int64_t x=int64_t(std::floor(q.x)),y=int64_t(std::floor(q.y)),z=int64_t(std::floor(q.z));
  if(!force)for(int a=-1;a<=1;a++)for(int b=-1;b<=1;b++)for(int c=-1;c<=1;c++){auto it=buckets.find({x+a,y+b,z+c});if(it!=buckets.end())for(V other:it->second)if(len(p-other)<radius*(1-1e-10))return false;}
  buckets[{x,y,z}].push_back(p);return true;
 }
};

Result analyze(const Mesh& mesh,const Settings& settings) {
 if(mesh.faces.empty())throw std::runtime_error("Select a nonempty surface mesh.");
 if(!std::isfinite(settings.pointRadius)||settings.pointRadius<0)throw std::runtime_error("Point radius must be positive.");
 if(!std::isfinite(settings.fitRadius)||settings.fitRadius<0||settings.relaxIterations<0||settings.relaxIterations>200)throw std::runtime_error("Invalid fit radius or Relax iterations.");
 if(settings.minimumPoints<0||settings.minimumPoints>1000)throw std::runtime_error("Minimum points must be 0..1000.");
 Result result;Spacing spacing(settings.pointRadius>0?settings.pointRadius:1);size_t work=0;
 auto parts=elements(mesh);
 for(size_t index=0;index<parts.size();++index){Result part;
  try{part=analyzeElement(parts[index],settings);}catch(const std::exception&e){throw std::runtime_error("Element "+std::to_string(index+1)+": "+e.what());}
  V planeOrigin{},planeU{},planeV{};
  for(auto face:parts[index].faces){V a=parts[index].vertices[face[0]],u=parts[index].vertices[face[1]]-a,b=parts[index].vertices[face[2]]-a;
   auto cross=[](V x,V y){return V{x.y*y.z-x.z*y.y,x.z*y.x-x.x*y.z,x.x*y.y-x.y*y.x};};V n=cross(u,b);
   if(len(n)>1e-12&&len(u)>1e-12){planeOrigin=a;planeU=u*(1/len(u));planeV=cross(n*(1/len(n)),planeU);break;}
  }
  auto fits=[&](V q){
   if(settings.fitRadius==0 && settings.relaxIterations==0)return true;
   auto plane=[&](V x){x=x-planeOrigin;return V{dot(x,planeU),dot(x,planeV),0};};V point=plane(q);bool inside=false;double clearance=1e100;
   for(const auto& loop:part.boundaries)for(size_t j=0,k=loop.size()-1;j<loop.size();k=j++){
    V x=plane(loop[j]),y=plane(loop[k]);if((x.y>point.y)!=(y.y>point.y)&&point.x<(y.x-x.x)*(point.y-x.y)/(y.y-x.y)+x.x)inside=!inside;
    V d=loop[k]-loop[j];double t=dot(d,d)>0?std::clamp(dot(q-loop[j],d)/dot(d,d),0.,1.):0;clearance=std::min(clearance,len(q-loop[j]-d*t));
   }
   return inside && clearance>=settings.fitRadius;
  };
  std::optional<Spacing> before;if(settings.minimumPoints>0)before=spacing;
  if(settings.pointRadius>0){
   for(const auto& path:part.paths){if(path.size()<2)continue;std::vector<double> cumulative{0};for(size_t j=1;j<path.size();j++)cumulative.push_back(cumulative.back()+len(path[j]-path[j-1]));double length=cumulative.back();if(length<=0)continue;
    double requested=length/settings.pointRadius;bool closed=len(path.front()-path.back())<length*1e-8;
    if(requested>250000)throw std::runtime_error("Radius too small: increase it to reduce analysis work.");
    // For a ring choose evenly spaced candidates with sufficient chord distance.
    int n=closed?std::max(1,int(std::floor(requested))):std::max(1,int(std::ceil(requested*4)));
    auto at=[&](double target){auto upper=std::upper_bound(cumulative.begin(),cumulative.end(),target);size_t j=std::min(path.size()-1,size_t(upper-cumulative.begin()));j=std::max(size_t(1),j);double segment=cumulative[j]-cumulative[j-1];return path[j-1]+(path[j]-path[j-1])*(segment>0?(target-cumulative[j-1])/segment:0);};
    if(closed&&part.mode==2){while(n>1&&len(at(0)-at(length/n))<settings.pointRadius*(1-1e-10))--n;}
    int candidates=closed?n:(requested<1?1:n+1);work+=candidates;
    if(work>1000000)throw std::runtime_error("Radius too small: more than one million candidates. Increase radius.");
    for(int k=0;k<candidates;k++){double t=(!closed&&requested<1)?length*.5:length*k/n;V p=at(t);if(fits(p)&&spacing.accept(p))part.points.push_back(p);}
   }
  }
  bool relaxed=false;
  if(settings.pointRadius>0 && int(part.points.size())<settings.minimumPoints && part.pathLength>0){
   // Minimum has explicit priority over exclusion radius. Replace this element's samples.
   spacing=*before;part.points.clear();relaxed=true;
   std::vector<double> lengths;for(const auto& path:part.paths){double l=0;for(size_t j=1;j<path.size();j++)l+=len(path[j]-path[j-1]);lengths.push_back(l);}
   const int count=settings.minimumPoints;
   for(int k=0;k<count;k++){double target=part.pathLength*(k+(part.mode==2?0:.5))/count;size_t pathIndex=0;while(pathIndex+1<lengths.size()&&target>lengths[pathIndex])target-=lengths[pathIndex++];const auto& path=part.paths[pathIndex];
    for(size_t j=1;j<path.size();j++){double d=len(path[j]-path[j-1]);if(target<=d||j+1==path.size()){V p=path[j-1]+(path[j]-path[j-1])*(d>0?std::clamp(target/d,0.,1.):0);if(fits(p)){spacing.accept(p,true);part.points.push_back(p);}break;}target-=d;}
   }
  }
  result.elementRelaxed.push_back(relaxed?1:0);
  result.elementModes.push_back(part.mode);result.elementPointCounts.push_back(int(part.points.size()));
  result.area+=part.area;result.regionArea+=part.regionArea;result.pathLength+=part.pathLength;
  result.boundaries.insert(result.boundaries.end(),part.boundaries.begin(),part.boundaries.end());result.paths.insert(result.paths.end(),part.paths.begin(),part.paths.end());result.points.insert(result.points.end(),part.points.begin(),part.points.end());
 }
 result.mode=result.elementModes.front();for(int mode:result.elementModes)if(mode!=result.mode)result.mode=4;
 return result;
}
}





