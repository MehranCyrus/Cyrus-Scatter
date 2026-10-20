#define ENABLE_VHACD_IMPLEMENTATION 1
#include "../third_party/vhacd/VHACD.h"
#include "core.h"
#include <future>
#include <chrono>
#include <memory>
#include <map>

namespace cpl {
Source qualitySource(Mesh render,double thickness,unsigned quality,unsigned pieces,double volumeError){
 if(quality>2||pieces<1||pieces>16||!std::isfinite(volumeError)||volumeError<.1||volumeError>10)
  throw std::runtime_error("Invalid collision quality: mode 0..2, pieces 1..16, volume error 0.1..10 percent");
 // Existing validation bounds topology, finite values and mesh size before V-HACD.
 auto fast=proxySource(render,render,thickness,true);
 Input check;check.sources={fast};validate(check);
 if(!quality)return fast;
 Vec lo=render.vertices[0],hi=lo;
 for(auto p:render.vertices){lo={std::min(lo.x,p.x),std::min(lo.y,p.y),std::min(lo.z,p.z)};hi={std::max(hi.x,p.x),std::max(hi.y,p.y),std::max(hi.z,p.z)};}
 auto span=hi-lo;
 if(std::min({span.x,span.y,span.z})<thickness*2)
  throw std::runtime_error("Detailed collision needs a volumetric model. Use Fast or a custom thick proxy for thin/open cards.");
 std::unique_ptr<VHACD::IVHACD,void(*)(VHACD::IVHACD*)> cooker(VHACD::CreateVHACD(),[](auto* p){p->Release();});
 if(!cooker)throw std::runtime_error("Collision cooker allocation failed");
 auto task=std::async(std::launch::async,[&]{
  // Only copied numeric mesh data is accessed on this worker. No Max SDK calls.
  std::vector<double> points;points.reserve(render.vertices.size()*3);
  for(auto p:render.vertices){points.push_back(p.x);points.push_back(p.y);points.push_back(p.z);}
  std::vector<std::uint32_t> faces;faces.reserve(render.faces.size()*3);
  for(auto f:render.faces)for(auto v:f)faces.push_back(v);
  VHACD::IVHACD::Parameters p;p.m_maxConvexHulls=pieces;p.m_resolution=quality==1?100000:400000;
  p.m_maxRecursionDepth=quality==1?6:7;p.m_maxNumVerticesPerCH=quality==1?64:128;
  p.m_minimumVolumePercentErrorAllowed=volumeError;p.m_asyncACD=false;p.m_shrinkWrap=true;
  std::map<std::pair<unsigned,unsigned>,unsigned> edges;for(auto f:render.faces)for(unsigned j=0;j<3;++j)++edges[std::minmax(f[j],f[(j+1)%3])];bool closed=std::all_of(edges.begin(),edges.end(),[](auto& e){return e.second==2;});
  // Avoid voxelizing already convex solids. The bounded proof checks each face
  // plane against all source vertices, rather than guessing from a convex hull.
  bool convex=closed;double volume=0;for(auto f:render.faces)volume+=dot(render.vertices[f[0]],cross(render.vertices[f[1]],render.vertices[f[2]]));
  if(std::abs(volume)<1e-15)convex=false;
  std::size_t work=0;double tolerance=length(span)*1e-6;
  for(auto f:render.faces){if(!convex)break;auto a=render.vertices[f[0]],n=cross(render.vertices[f[1]]-a,render.vertices[f[2]]-a);if(length(n)<1e-15)continue;n=normalized(n)*(volume>0?1:-1);
   for(auto v:render.vertices){if(++work>4000000||dot(n,v-a)>tolerance){convex=false;break;}}}
  if(convex)return fast;
  p.m_fillMode=closed?VHACD::FillMode::FLOOD_FILL:VHACD::FillMode::RAYCAST_FILL;
  if(!cooker->Compute(points.data(),std::uint32_t(render.vertices.size()),faces.data(),std::uint32_t(render.faces.size()),p))
   throw std::runtime_error("Detailed collision preparation failed; previous result retained");
  Source result;result.render=std::move(render);
  auto count=cooker->GetNConvexHulls();if(!count||count>pieces)throw std::runtime_error("Detailed collision hull count exceeded its budget");
  for(unsigned i=0;i<count;++i){VHACD::IVHACD::ConvexHull hull;if(!cooker->GetConvexHull(i,hull)||hull.m_points.size()<4||hull.m_points.size()>p.m_maxNumVerticesPerCH)throw std::runtime_error("Invalid detailed collision hull");
   std::vector<Vec> vertices;vertices.reserve(hull.m_points.size());for(auto v:hull.m_points)vertices.push_back({v.mX,v.mY,v.mZ});result.hulls.push_back(std::move(vertices));}
  return result;
 });
 bool expired=task.wait_for(std::chrono::seconds(25))!=std::future_status::ready;
 if(expired)cooker->Cancel(); // Upstream cancellation is atomic. Always join before release.
 auto result=task.get();
 if(expired)throw std::runtime_error("Detailed collision preparation exceeded 25 seconds; reduce quality/pieces or use a custom proxy. Previous result retained.");
 check.sources={result};validate(check);return result;
}
}
