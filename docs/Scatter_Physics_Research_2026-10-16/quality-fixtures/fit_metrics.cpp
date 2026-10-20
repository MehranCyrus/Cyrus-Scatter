#include "core.h"
#include <Jolt/Jolt.h>
#include <Jolt/Physics/Collision/Shape/ConvexHullShape.h>
#include <fstream>
#include <iostream>
#include <filesystem>
using namespace cpl;
struct Plane{Vec n;double d;};
using Hull=std::vector<Plane>;
std::vector<Hull> planes(const Source& source){std::vector<Hull> result;for(auto& points:source.hulls){JPH::Array<JPH::Vec3> values;for(auto v:points)values.push_back({float(v.x),float(v.y),float(v.z)});JPH::ConvexHullShapeSettings settings(values);settings.mMaxConvexRadius=.0001f;auto cooked=settings.Create();if(cooked.HasError())throw std::runtime_error(cooked.GetError().c_str());auto* h=static_cast<const JPH::ConvexHullShape*>(cooked.Get().GetPtr());auto cm=h->GetCenterOfMass();auto cv=[&](JPH::Vec3 v){return Vec{v.GetX()+cm.GetX(),v.GetY()+cm.GetY(),v.GetZ()+cm.GetZ()};};Hull hull;
 for(unsigned i=0;i<h->GetNumFaces();++i){JPH::uint ids[256];auto n=h->GetFaceVertices(i,256,ids);if(n<3)continue;auto a=cv(h->GetPoint(ids[0])),b=cv(h->GetPoint(ids[1])),c=cv(h->GetPoint(ids[2]));auto normal=cross(b-a,c-a);if(length(normal)<1e-12)continue;normal=normalized(normal);Vec center{cm.GetX(),cm.GetY(),cm.GetZ()};if(dot(normal,a-center)<0)normal=normal*-1;hull.push_back({normal,dot(normal,a)});}result.push_back(std::move(hull));}return result;}
bool inside(const std::vector<Hull>& hulls,Vec p,double tolerance=1e-6){for(auto& hull:hulls){bool found=true;for(auto q:hull)if(dot(q.n,p)>q.d+tolerance){found=false;break;}if(found)return true;}return false;}
int main(int argc,char** argv){try{if(argc!=3)throw std::runtime_error("fit_metrics result-directory report.json");Input init;init.sources={boxSource({1,1,1})};joltCollisionGeometry(init);Json report;for(auto name:{"pyramid","sphere","teapot"})for(int quality=0;quality<3;++quality){auto path=std::filesystem::path(argv[1])/(std::string(name)+"_q"+std::to_string(quality)+"-result.json");Json j;std::ifstream(path)>>j;auto in=decodeInput(j.at("input"));auto& s=in.sources.at(0);auto hulls=planes(s);Vec lo=s.render.vertices[0],hi=lo;for(auto p:s.render.vertices){lo={std::min(lo.x,p.x),std::min(lo.y,p.y),std::min(lo.z,p.z)};hi={std::max(hi.x,p.x),std::max(hi.y,p.y),std::max(hi.z,p.z)};}Vec span=hi-lo;unsigned occupied=0,verticesOutside=0;for(int x=0;x<40;++x)for(int y=0;y<40;++y)for(int z=0;z<40;++z)occupied+=inside(hulls,lo+Vec{span.x*(x+.5)/40,span.y*(y+.5)/40,span.z*(z+.5)/40});for(auto p:s.render.vertices)verticesOutside+=!inside(hulls,p,length(span)*.005);
 report[name][std::to_string(quality)]={{"pieces",s.hulls.size()},{"occupied_grid_cells",occupied},{"grid_cells",64000},{"render_vertices",s.render.vertices.size()},{"vertices_outside_0_5_percent_diagonal_plane_envelope",verticesOutside}};}
 std::ofstream(argv[2])<<report.dump(2)<<'\n';std::cout<<report.dump(2)<<'\n';return 0;}catch(const std::exception& e){std::cerr<<e.what()<<'\n';return 1;}}
