#include "core.h"
#include <algorithm>
#include <cmath>
#include <limits>
#include <set>
#include <map>
#include <numeric>
#include <stdexcept>
namespace cpl {
double dot(Vec a,Vec b){return a.x*b.x+a.y*b.y+a.z*b.z;}
double length(Vec a){return std::sqrt(dot(a,a));}
Vec cross(Vec a,Vec b){return{a.y*b.z-a.z*b.y,a.z*b.x-a.x*b.z,a.x*b.y-a.y*b.x};}
Vec normalized(Vec a){const double n=length(a);if(n<1e-12)throw std::runtime_error("Zero direction");return a*(1/n);}
Vec rotate(Quat q,Vec p){const Vec v{q.x,q.y,q.z};return p+cross(v,p)*(2*q.w)+cross(v,cross(v,p))*2;}
static bool finite(Vec a){return std::isfinite(a.x)&&std::isfinite(a.y)&&std::isfinite(a.z)&&length(a)<1e8;}
static void require(bool value,const char* message){if(!value)throw std::runtime_error(message);}
static void meshValid(const Mesh& m){require(m.vertices.size()<=200000&&m.faces.size()<=200000,"Mesh admission exceeded");
 for(auto p:m.vertices)require(finite(p),"Invalid mesh coordinate");for(auto f:m.faces)for(auto i:f)require(i<m.vertices.size(),"Invalid face index");
 require(m.smoothing.empty()||m.smoothing.size()==m.faces.size(),"Invalid smoothing groups");
 require(m.uv.size()<=200000&&(m.uvFaces.empty()||m.uvFaces.size()==m.faces.size()),"Invalid UV topology");for(auto p:m.uv)require(finite(p),"Invalid UV coordinate");for(auto f:m.uvFaces)for(auto i:f)require(i<m.uv.size(),"Invalid UV face");}
void validate(const Input& in){auto s=in.settings;
 require(!in.sources.empty()&&in.sources.size()<=64,"Choose 1 to 64 sources");
 require(in.colliders.size()<=64&&in.frozen.size()<=s.maxBodies,"Collider admission exceeded");
 for(double v:{s.dt,s.friction,s.bounce,s.damping,s.gravity,s.quietLinear,s.quietAngular,s.radius,s.spacing,s.height,s.thickness,s.scaleMin,s.scaleMax,s.stickiness})require(std::isfinite(v),"Non-finite setting");
 require(s.stickiness>=0&&s.stickiness<=1,"Stickiness must be between 0 and 100 percent");
 require(s.dt>=1./1000&&s.dt<=1./30&&s.maxBodies>0&&s.maxBodies<=5000&&s.maxSteps>0&&s.maxSteps<=30000&&s.quietSteps>0&&s.quietSteps<=s.maxSteps,"Invalid solve bounds");
 require(s.collisionSteps>=1&&s.collisionSteps<=8,"Invalid collision substeps");
 require(s.maxPairs>0&&s.maxContacts>0&&s.maxPairs<=65536&&s.maxContacts<=65536,"Invalid contact bounds");
 require(s.friction>=0&&s.friction<=2&&s.bounce>=0&&s.bounce<=1&&s.damping>=0&&s.damping<=10&&s.gravity>0&&s.gravity<=100,"Invalid physical setting");
 require(s.radius>0&&s.radius<=100&&s.spacing>=.0001&&s.height>=0&&s.height<=100&&s.thickness>=.00001&&s.thickness<=1&&s.scaleMin>=.01&&s.scaleMax>=s.scaleMin&&s.scaleMax<=100,"Invalid emitter setting");
 std::size_t triangles=0,sourceVertices=0,sourceFaces=0;double totalWeight=0;
 for(auto& source:in.sources){meshValid(source.render);sourceVertices+=source.render.vertices.size();sourceFaces+=source.render.faces.size();require(sourceVertices<=200000&&sourceFaces<=200000,"Combined source geometry admission exceeded");require(!source.render.vertices.empty()&&!source.render.faces.empty(),"Source mesh is empty");require(!source.hulls.empty()&&source.hulls.size()<=16,"Choose 1 to 16 proxy hulls");
 require(std::isfinite(source.weight)&&source.weight>=0,"Invalid source weight");totalWeight+=source.weight;
 for(auto& hull:source.hulls){require(hull.size()>=4&&hull.size()<=256,"Hull needs 4 to 256 points");for(auto p:hull)require(finite(p),"Invalid hull point");
 Vec a=hull[0];double volume=0;for(std::size_t i=1;i+2<hull.size();++i)volume=std::max(volume,std::abs(dot(hull[i]-a,cross(hull[i+1]-a,hull[i+2]-a))));require(volume>1e-15,"Degenerate proxy hull");}}
 require(std::isfinite(totalWeight)&&totalWeight>0,"Invalid or all-zero source weights");for(auto& m:in.colliders){meshValid(m);triangles+=m.faces.size();}require(triangles<=200000,"Combined collider triangle limit");
 std::set<std::uint64_t> ids;for(auto& row:in.frozen){require(row.id>0&&ids.insert(row.id).second,"Duplicate frozen identity");require(row.source<in.sources.size()&&finite(row.position)&&std::isfinite(row.scale)&&row.scale>0,"Invalid frozen row");}
}
Mesh boxMesh(Vec h,Vec c){Mesh m;for(int z:{-1,1})for(int y:{-1,1})for(int x:{-1,1})m.vertices.push_back(c+Vec{x*h.x,y*h.y,z*h.z});
 m.faces={{0,2,3},{0,3,1},{4,5,7},{4,7,6},{0,1,5},{0,5,4},{2,6,7},{2,7,3},{0,4,6},{0,6,2},{1,3,7},{1,7,5}};return m;}
Source boxSource(Vec h){Source s;s.render=boxMesh(h);s.hulls.push_back(s.render.vertices);return s;}
bool exactBox(const Mesh& m,Vec& half,Vec& center){if(m.vertices.size()!=8||m.faces.size()!=12)return false;Vec lo=m.vertices[0],hi=lo;for(auto p:m.vertices){lo={std::min(lo.x,p.x),std::min(lo.y,p.y),std::min(lo.z,p.z)};hi={std::max(hi.x,p.x),std::max(hi.y,p.y),std::max(hi.z,p.z)};}half=(hi-lo)*.5;center=(hi+lo)*.5;if(std::min({half.x,half.y,half.z})<1e-6)return false;double tolerance=std::max(1e-8,length(half)*1e-7);unsigned mask=0;for(auto p:m.vertices){unsigned corner=0;for(int axis=0;axis<3;++axis){double v=axis==0?p.x:axis==1?p.y:p.z,a=axis==0?lo.x:axis==1?lo.y:lo.z,b=axis==0?hi.x:axis==1?hi.y:hi.z;if(std::abs(v-a)<tolerance){}else if(std::abs(v-b)<tolerance)corner|=1u<<axis;else return false;}if(mask&(1u<<corner))return false;mask|=1u<<corner;}std::array<double,6> area{};std::map<std::pair<unsigned,unsigned>,unsigned> edges;for(auto f:m.faces){for(auto index:f)if(index>=8)return false;Vec a=m.vertices[f[0]],b=m.vertices[f[1]],c=m.vertices[f[2]];if(dot(cross(b-a,c-a),a-center)<=0)return false;int plane=-1;for(int axis=0;axis<3;++axis){auto value=[&](Vec v){return axis==0?v.x:axis==1?v.y:v.z;};double low=axis==0?lo.x:axis==1?lo.y:lo.z,high=axis==0?hi.x:axis==1?hi.y:hi.z;if(std::abs(value(a)-low)<tolerance&&std::abs(value(b)-low)<tolerance&&std::abs(value(c)-low)<tolerance)plane=axis*2;if(std::abs(value(a)-high)<tolerance&&std::abs(value(b)-high)<tolerance&&std::abs(value(c)-high)<tolerance)plane=axis*2+1;}if(plane<0)return false;area[plane]+=length(cross(b-a,c-a))*.5;for(int i=0;i<3;++i)++edges[std::minmax(f[i],f[(i+1)%3])];}for(auto [edge,count]:edges){(void)edge;if(count!=2)return false;}for(int axis=0;axis<3;++axis){double expected=axis==0?4*half.y*half.z:axis==1?4*half.x*half.z:4*half.x*half.y;for(int side=0;side<2;++side)if(std::abs(area[axis*2+side]-expected)>std::max(1e-10,expected*1e-6))return false;}return true;}
// Certify a filled upward horizontal rectangle before adding a 10 cm slab below
// it. Boundary edges inside the rectangle (including holes) reject this path.
bool flatRectangle(const Mesh& mesh,Vec& half,Vec& center){
 if(mesh.vertices.size()<4||mesh.faces.size()<2)return false;
 Vec lo=mesh.vertices[0],hi=lo;for(auto p:mesh.vertices){lo={std::min(lo.x,p.x),std::min(lo.y,p.y),std::min(lo.z,p.z)};hi={std::max(hi.x,p.x),std::max(hi.y,p.y),std::max(hi.z,p.z)};}
 double tolerance=std::max(1e-8,length(hi-lo)*1e-7);
 if(hi.x-lo.x<tolerance||hi.y-lo.y<tolerance||hi.z-lo.z>tolerance)return false;
 struct Edge{unsigned count=0;int orientation=0;};
 std::map<std::pair<unsigned,unsigned>,Edge> edges;double area=0;
 for(auto f:mesh.faces){for(auto index:f)if(index>=mesh.vertices.size())return false;
  auto a=mesh.vertices[f[0]],b=mesh.vertices[f[1]],c=mesh.vertices[f[2]];double twice=cross(b-a,c-a).z;if(twice<=0)return false;area+=twice*.5;
  for(unsigned i=0;i<3;++i){unsigned first=f[i],second=f[(i+1)%3];auto& edge=edges[std::minmax(first,second)];++edge.count;edge.orientation+=first<second?1:-1;}}
 double expected=(hi.x-lo.x)*(hi.y-lo.y);if(std::abs(area-expected)>expected*1e-6)return false;
 std::array<double,4> boundary{};
 for(auto [indices,edge]:edges){if(edge.count==2){if(edge.orientation!=0)return false;continue;}if(edge.count!=1)return false;
  auto a=mesh.vertices[indices.first],b=mesh.vertices[indices.second];int side=-1;
  if(std::abs(a.x-lo.x)<tolerance&&std::abs(b.x-lo.x)<tolerance)side=0;
  if(std::abs(a.x-hi.x)<tolerance&&std::abs(b.x-hi.x)<tolerance)side=1;
  if(std::abs(a.y-lo.y)<tolerance&&std::abs(b.y-lo.y)<tolerance)side=2;
  if(std::abs(a.y-hi.y)<tolerance&&std::abs(b.y-hi.y)<tolerance)side=3;
  if(side<0)return false;boundary[side]+=length(b-a);}
 for(unsigned i=0;i<4;++i)if(std::abs(boundary[i]-(i<2?hi.y-lo.y:hi.x-lo.x))>tolerance)return false;
 half={(hi.x-lo.x)*.5,(hi.y-lo.y)*.5,.05};center={(hi.x+lo.x)*.5,(hi.y+lo.y)*.5,lo.z-.05};return true;
}
// A conservative outer convex proxy: intersect 98 support half-spaces in an
// AABB-normalized frame. The six axis planes bound the polytope. At most 192
// vertices result (Euler), below both engines' convex limits. Fixed plane/triple
// counts bound cooking work; source points are already subject to mesh admission.
static std::vector<Vec> automaticHull(const std::vector<Vec>& points){
 Vec lo=points[0],hi=lo;for(auto p:points){lo={std::min(lo.x,p.x),std::min(lo.y,p.y),std::min(lo.z,p.z)};hi={std::max(hi.x,p.x),std::max(hi.y,p.y),std::max(hi.z,p.z)};}
 Vec center=(lo+hi)*.5,half=(hi-lo)*.5;
 require(std::min({half.x,half.y,half.z})>1e-12,"Automatic collision shape is degenerate; choose a valid mesh or custom proxy");
 std::vector<Vec> unit;unit.reserve(points.size());for(auto p:points)unit.push_back({(p.x-center.x)/half.x,(p.y-center.y)/half.y,(p.z-center.z)/half.z});
 struct Plane{Vec n;double d;};std::vector<Plane> planes;planes.reserve(98);
 for(int x=-2;x<=2;++x)for(int y=-2;y<=2;++y)for(int z=-2;z<=2;++z){
  if(std::gcd(std::gcd(std::abs(x),std::abs(y)),std::abs(z))!=1)continue;
  Vec n=normalized({double(x),double(y),double(z)});double d=-1e100;for(auto p:unit)d=std::max(d,dot(n,p));
  planes.push_back({n,d+1e-6}); // Relative outward padding for roundoff, not an artist thickness.
 }
 std::vector<Vec> hull;hull.reserve(192);
 for(std::size_t i=0;i<planes.size();++i)for(std::size_t j=i+1;j<planes.size();++j)for(std::size_t k=j+1;k<planes.size();++k){
  auto a=planes[i],b=planes[j],c=planes[k];Vec bc=cross(b.n,c.n);double determinant=dot(a.n,bc);if(std::abs(determinant)<1e-10)continue;
  Vec p=(bc*a.d+cross(c.n,a.n)*b.d+cross(a.n,b.n)*c.d)*(1/determinant);
  bool inside=true;for(auto plane:planes)if(dot(plane.n,p)>plane.d+1e-9){inside=false;break;}if(!inside)continue;
  bool duplicate=false;for(auto other:hull)if(length(other-p)<1e-8){duplicate=true;break;}if(duplicate)continue;
  require(hull.size()<192,"Automatic collision proxy exceeded its vertex budget; use a custom proxy");hull.push_back(p);
 }
 require(hull.size()>=4,"Automatic collision shape could not be prepared; use a custom proxy");
 for(auto& p:hull)p={center.x+p.x*half.x,center.y+p.y*half.y,center.z+p.z*half.z};return hull;
}
Source proxySource(Mesh render,Mesh proxy,double thickness,bool automatic){meshValid(render);meshValid(proxy);require(!proxy.vertices.empty(),"Empty collision proxy");
 require(std::isfinite(thickness)&&thickness>=.00001&&thickness<=1,"Invalid collision thickness");
 if(!automatic&&proxy.vertices.size()>128)throw std::runtime_error("Custom collision proxy has "+std::to_string(proxy.vertices.size())+" vertices; limit is 128. Use a simpler proxy or Use auto.");
 Vec lo=proxy.vertices[0],hi=lo;for(auto p:proxy.vertices){lo={std::min(lo.x,p.x),std::min(lo.y,p.y),std::min(lo.z,p.z)};hi={std::max(hi.x,p.x),std::max(hi.y,p.y),std::max(hi.z,p.z)};}
 // Custom proxies describe the moving model, not the receiving surface. Catch
 // gross size/pivot mistakes before cooking; never silently resize artist data.
 // Use the full diagonal so legitimate thin leaves and coarse boxes still fit.
 if(!automatic){require(!render.vertices.empty(),"Source mesh is empty");Vec rlo=render.vertices[0],rhi=rlo;for(auto p:render.vertices){rlo={std::min(rlo.x,p.x),std::min(rlo.y,p.y),std::min(rlo.z,p.z)};rhi={std::max(rhi.x,p.x),std::max(rhi.y,p.y),std::max(rhi.z,p.z)};}
  double size=length(rhi-rlo);require(size>1.e-12,"Source mesh has no usable extent");
  require(length(hi-lo)<=8*size&&length((hi+lo-rhi-rlo)*.5)<=4*size,"Custom proxy is much larger than the model or its pivot is misaligned. Pick a simplified copy of the model, or Use auto. Add receiving surfaces under Objects, not as model proxies.");}
 Vec span=hi-lo;int axis=span.x<span.y?0:1;if(span.z<(axis==0?span.x:span.y))axis=2;
 std::map<std::pair<unsigned,unsigned>,unsigned> edges;for(auto f:proxy.faces)for(int i=0;i<3;++i)++edges[std::minmax(f[i],f[(i+1)%3])];bool closed=!edges.empty()&&std::all_of(edges.begin(),edges.end(),[](auto edge){return edge.second==2;});
 std::vector<Vec> hull=proxy.vertices;double width=axis==0?span.x:axis==1?span.y:span.z;
 if(width<thickness||!closed){hull.clear();for(auto p:proxy.vertices){auto a=p,b=p;double shift=closed?(thickness-width)*.5:thickness*.5;if(axis==0){a.x=lo.x-shift;b.x=hi.x+shift;}else if(axis==1){a.y=lo.y-shift;b.y=hi.y+shift;}else{a.z=lo.z-shift;b.z=hi.z+shift;}hull.push_back(a);hull.push_back(b);}}
 if(automatic&&proxy.vertices.size()>128)hull=automaticHull(hull);
 return{std::move(render),{std::move(hull)},1};}
static Json v(Vec p){return Json::array({p.x,p.y,p.z});}
static Vec pv(const Json& j){require(j.is_array()&&j.size()==3,"Invalid vector payload");Vec p{j[0].get<double>(),j[1].get<double>(),j[2].get<double>()};require(finite(p),"Invalid vector value");return p;}
Json encodeRow(const Row& r){return{{"id",r.id},{"gesture",r.gesture},{"source",r.source},{"p",v(r.position)},{"q",{r.rotation.x,r.rotation.y,r.rotation.z,r.rotation.w}},{"scale",r.scale}};}
Row decodeRow(const Json& j){Row r;r.id=j.at("id");r.gesture=j.at("gesture");r.source=j.at("source");r.position=pv(j.at("p"));auto q=j.at("q");require(q.size()==4,"Invalid quaternion");r.rotation={q[0],q[1],q[2],q[3]};double norm=r.rotation.x*r.rotation.x+r.rotation.y*r.rotation.y+r.rotation.z*r.rotation.z+r.rotation.w*r.rotation.w;require(std::isfinite(norm)&&std::abs(norm-1)<.001,"Invalid quaternion norm");r.scale=j.at("scale");require(r.id>0&&std::isfinite(r.scale)&&r.scale>.0&&r.scale<=100,"Invalid row");return r;}
Json encodeBirth(const Birth& b){auto j=encodeRow(b);j["step"]=b.step;j["velocity"]=v(b.velocity);j["spin"]=v(b.spin);return j;}
Birth decodeBirth(const Json& j){Birth b;static_cast<Row&>(b)=decodeRow(j);b.step=j.at("step");b.velocity=pv(j.at("velocity"));b.spin=pv(j.at("spin"));return b;}
static Json meshJson(const Mesh& m){Json j; j["vertices"]=Json::array();for(auto p:m.vertices)j["vertices"].push_back(v(p));j["faces"]=m.faces;j["uv"]=Json::array();for(auto p:m.uv)j["uv"].push_back(v(p));j["uvFaces"]=m.uvFaces;j["smoothing"]=m.smoothing;return j;}
static Mesh parseMesh(const Json& j){Mesh m;require(j.at("vertices").size()<=200000&&j.at("faces").size()<=200000,"Mesh payload limit");for(auto& p:j.at("vertices"))m.vertices.push_back(pv(p));m.faces=j.at("faces").get<decltype(m.faces)>();if(j.contains("uv")){require(j.at("uv").size()<=200000&&j.at("uvFaces").size()<=200000,"UV payload limit");for(auto& p:j.at("uv"))m.uv.push_back(pv(p));m.uvFaces=j.at("uvFaces").get<decltype(m.uvFaces)>();}if(j.contains("smoothing")){require(j["smoothing"].size()<=200000,"Smoothing payload limit");m.smoothing=j["smoothing"].get<std::vector<unsigned>>();}meshValid(m);return m;}
Json encodeInput(const Input& in){auto s=in.settings;Json j={{"version",2},{"settings",{{"stickiness",s.stickiness},{"dt",s.dt},{"friction",s.friction},{"bounce",s.bounce},{"damping",s.damping},{"gravity",s.gravity},{"quietLinear",s.quietLinear},{"quietAngular",s.quietAngular},{"radius",s.radius},{"spacing",s.spacing},{"height",s.height},{"thickness",s.thickness},{"scaleMin",s.scaleMin},{"scaleMax",s.scaleMax},{"maxBodies",s.maxBodies},{"maxPairs",s.maxPairs},{"maxContacts",s.maxContacts},{"maxSteps",s.maxSteps},{"quietSteps",s.quietSteps},{"seed",s.seed},{"collisionSteps",s.collisionSteps},{"ccd",s.ccd}}},{"sources",Json::array()},{"colliders",Json::array()},{"frozen",Json::array()}};
 for(auto& source:in.sources){Json hulls=Json::array();for(auto& h:source.hulls){Json points=Json::array();for(auto p:h)points.push_back(v(p));hulls.push_back(points);}j["sources"].push_back({{"render",meshJson(source.render)},{"hulls",hulls},{"weight",source.weight}});}for(auto& m:in.colliders)j["colliders"].push_back(meshJson(m));for(auto r:in.frozen)j["frozen"].push_back(encodeRow(r));return j;}
Input decodeInput(const Json& j){require(j.at("version")==1||j.at("version")==2,"Unsupported Physics Lab schema");Input in;auto& s=in.settings;auto a=j.at("settings");
#define CPL_READ(field) s.field=a.at(#field).get<decltype(s.field)>()
 CPL_READ(dt);CPL_READ(friction);CPL_READ(bounce);CPL_READ(damping);CPL_READ(gravity);CPL_READ(quietLinear);CPL_READ(quietAngular);CPL_READ(radius);CPL_READ(spacing);CPL_READ(height);CPL_READ(thickness);CPL_READ(scaleMin);CPL_READ(scaleMax);CPL_READ(maxBodies);CPL_READ(maxPairs);CPL_READ(maxContacts);CPL_READ(maxSteps);CPL_READ(quietSteps);CPL_READ(seed);CPL_READ(collisionSteps);CPL_READ(ccd);if(j.at("version")==2){CPL_READ(stickiness);}
#undef CPL_READ
 require(j.at("sources").size()<=64&&j.at("colliders").size()<=64&&j.at("frozen").size()<=5000,"Payload admission exceeded");
 for(auto& aSource:j.at("sources")){Source source;source.render=parseMesh(aSource.at("render"));source.weight=aSource.at("weight");require(aSource.at("hulls").size()<=16,"Hull count limit");for(auto& h:aSource.at("hulls")){require(h.size()<=256,"Hull point limit");std::vector<Vec> hull;for(auto& p:h)hull.push_back(pv(p));source.hulls.push_back(std::move(hull));}in.sources.push_back(std::move(source));}for(auto& m:j.at("colliders"))in.colliders.push_back(parseMesh(m));for(auto& r:j.at("frozen"))in.frozen.push_back(decodeRow(r));validate(in);return in;}
bool rayHit(const Mesh& mesh,Vec origin,Vec direction,Hit& hit){bool found=false;double best=std::numeric_limits<double>::max();for(unsigned i=0;i<mesh.faces.size();++i){auto f=mesh.faces[i];Vec a=mesh.vertices[f[0]],e1=mesh.vertices[f[1]]-a,e2=mesh.vertices[f[2]]-a,p=cross(direction,e2);double d=dot(e1,p);if(std::abs(d)<1e-12)continue;Vec t=origin-a;double u=dot(t,p)/d;if(u<0||u>1)continue;Vec q=cross(t,e1);double w=dot(direction,q)/d;if(w<0||u+w>1)continue;double distance=dot(e2,q)/d;if(distance>=0&&distance<best){best=distance;found=true;hit={origin+direction*distance,normalized(cross(e1,e2)),distance,i};}}return found;}
Surface::Surface(Mesh value):mesh(std::move(value)){meshValid(mesh);order.resize(mesh.faces.size());for(unsigned i=0;i<order.size();++i)order[i]=i;if(!order.empty())build(0,unsigned(order.size()));}
unsigned Surface::build(unsigned begin,unsigned end){Node node;node.begin=begin;node.count=end-begin;node.lo={1e100,1e100,1e100};node.hi={-1e100,-1e100,-1e100};for(unsigned i=begin;i<end;++i)for(auto v:mesh.faces[order[i]]){auto p=mesh.vertices[v];node.lo={std::min(node.lo.x,p.x),std::min(node.lo.y,p.y),std::min(node.lo.z,p.z)};node.hi={std::max(node.hi.x,p.x),std::max(node.hi.y,p.y),std::max(node.hi.z,p.z)};}unsigned index=unsigned(nodes.size());nodes.push_back(node);if(end-begin>8){Vec span=node.hi-node.lo;int axis=span.x>span.y?0:1;if(span.z>(axis==0?span.x:span.y))axis=2;auto center=[&](unsigned i){auto f=mesh.faces[i];Vec p=mesh.vertices[f[0]]+mesh.vertices[f[1]]+mesh.vertices[f[2]];return axis==0?p.x:axis==1?p.y:p.z;};unsigned mid=begin+(end-begin)/2;std::nth_element(order.begin()+begin,order.begin()+mid,order.begin()+end,[&](unsigned a,unsigned b){auto x=center(a),y=center(b);return x==y?a<b:x<y;});nodes[index].left=build(begin,mid);nodes[index].right=build(mid,end);nodes[index].count=0;}return index;}
bool Surface::hit(Vec origin,Vec direction,Hit& result)const{if(nodes.empty())return false;bool found=false;double best=1e100;std::vector<unsigned> stack{0};unsigned visits=0;while(!stack.empty()){require(++visits<=1000000,"Ray query work admission exceeded");auto n=nodes[stack.back()];stack.pop_back();double lower=0,upper=best;for(int axis=0;axis<3;++axis){double o=axis==0?origin.x:axis==1?origin.y:origin.z,d=axis==0?direction.x:axis==1?direction.y:direction.z,lo=axis==0?n.lo.x:axis==1?n.lo.y:n.lo.z,hi=axis==0?n.hi.x:axis==1?n.hi.y:n.hi.z;if(std::abs(d)<1e-15){if(o<lo||o>hi){upper=-1;break;}}else{double a=(lo-o)/d,b=(hi-o)/d;if(a>b)std::swap(a,b);lower=std::max(lower,a);upper=std::min(upper,b);}}if(lower>upper)continue;if(!n.count){stack.push_back(n.left);stack.push_back(n.right);continue;}for(unsigned i=n.begin;i<n.begin+n.count;++i){unsigned face=order[i];auto f=mesh.faces[face];Vec a=mesh.vertices[f[0]],e1=mesh.vertices[f[1]]-a,e2=mesh.vertices[f[2]]-a,p=cross(direction,e2);double determinant=dot(e1,p);if(std::abs(determinant)<1e-12)continue;Vec t=origin-a;double u=dot(t,p)/determinant;if(u<0||u>1)continue;Vec q=cross(t,e1);double v=dot(direction,q)/determinant;if(v<0||u+v>1)continue;double distance=dot(e2,q)/determinant;if(distance>=0&&(distance<best||(distance==best&&face<result.face))){best=distance;found=true;result={origin+direction*distance,normalized(cross(e1,e2)),distance,face};}}}return found;}
static std::uint64_t mix(std::uint64_t x){x+=0x9e3779b97f4a7c15ULL;x=(x^(x>>30))*0xbf58476d1ce4e5b9ULL;x=(x^(x>>27))*0x94d049bb133111ebULL;return x^(x>>31);}
Emitter::Emitter(const Settings& s,std::uint64_t g,std::uint64_t first,const std::vector<Source>& sources):settings(s),gesture(g),next(first){double sum=0;for(auto& source:sources){sum+=source.weight;weights.push_back(sum);}if(sum<=0)throw std::runtime_error("No weighted sources");for(auto& w:weights)w/=sum;}
bool Surface::heightBound(Vec lo,Vec hi,double& result)const{
 if(nodes.empty())return false;bool found=false;double highest=-1e100;std::vector<unsigned> stack{0};unsigned visits=0;
 while(!stack.empty()){require(++visits<=1000000,"Footprint query work admission exceeded");const auto& n=nodes[stack.back()];stack.pop_back();
  if(n.hi.x<lo.x||n.lo.x>hi.x||n.hi.y<lo.y||n.lo.y>hi.y||n.hi.z<=highest)continue;
  if(n.lo.x>=lo.x&&n.hi.x<=hi.x&&n.lo.y>=lo.y&&n.hi.y<=hi.y){highest=n.hi.z;found=true;continue;}
  if(!n.count){stack.push_back(n.left);stack.push_back(n.right);continue;}
  for(unsigned i=n.begin;i<n.begin+n.count;++i){Vec a=mesh.vertices[mesh.faces[order[i]][0]],b=mesh.vertices[mesh.faces[order[i]][1]],c=mesh.vertices[mesh.faces[order[i]][2]];
   if(std::max({a.x,b.x,c.x})<lo.x||std::min({a.x,b.x,c.x})>hi.x||std::max({a.y,b.y,c.y})<lo.y||std::min({a.y,b.y,c.y})>hi.y)continue;
   highest=std::max({highest,a.z,b.z,c.z});found=true;
  }
 }
 if(found)result=highest;return found;
}
Birth Emitter::birth(Vec point,Vec normal,unsigned step){require(next>0&&next<std::numeric_limits<std::uint64_t>::max()&&gesture>0&&gesture<std::numeric_limits<std::uint64_t>::max(),"Emission identity exhausted; create a new node");Birth b;b.id=next++;b.gesture=gesture;b.step=step;
 auto random=[&](unsigned channel){return double(mix(b.id^mix(gesture)^mix(settings.seed)^mix(channel))>>11)*(1./9007199254740992.);};
 b.source=unsigned(std::upper_bound(weights.begin(),weights.end(),random(0))-weights.begin());b.scale=settings.scaleMin+(settings.scaleMax-settings.scaleMin)*random(1);
 double yaw=random(2)*6.28318530718;b.rotation={0,0,std::sin(yaw*.5),std::cos(yaw*.5)};
 Vec n=normalized(normal),u=normalized(cross(n,std::abs(n.z)<.9?Vec{0,0,1}:Vec{1,0,0})),v=cross(n,u);double angle=random(3)*6.28318530718,radius=std::sqrt(random(4))*settings.radius;
 b.position=point+u*(radius*std::cos(angle))+v*(radius*std::sin(angle))+Vec{0,0,settings.height};return b;}
std::vector<Birth> Emitter::sample(Vec p,Vec n,bool hit,unsigned step){std::vector<Birth> out;if(!hit){connected=false;remainder=0;return out;}require(finite(p),"Invalid stroke point");
 if(!connected){out.push_back(birth(p,n,step));connected=true;last=p;remainder=0;return out;}Vec delta=p-last;double distance=length(delta);if(distance<1e-12)return out;
 require(distance/settings.spacing<=256,"Stroke sample exceeds queue admission");double travel=settings.spacing-remainder;while(travel<=distance+1e-10){out.push_back(birth(last+delta*(travel/distance),n,step));travel+=settings.spacing;}remainder=distance-(travel-settings.spacing);last=p;return out;}
Session::Session(Input in,std::unique_ptr<World> (*factory)(const Input&)):input(std::move(in)){validate(input);world=factory(input);}
void Session::emit(const std::vector<Birth>& values){require(!released&&!cancelled,"Session is closed for emission");require(births.size()+values.size()+input.frozen.size()<=input.settings.maxBodies,"Physics body admission exceeded; stroke cancelled");
 std::set<std::uint64_t> ids;for(auto& b:births)ids.insert(b.id);for(auto& b:input.frozen)ids.insert(b.id);for(auto b:values){decodeBirth(encodeBirth(b));require(b.source<input.sources.size()&&ids.insert(b.id).second,"Invalid birth identity/source");world->add(b);births.push_back(b);}quiet=0;}
bool Session::tick(unsigned count){require(!cancelled,"Session cancelled");if(completed)return true;require(count>0&&count<=120,"Step slice outside bound");for(unsigned i=0;i<count;++i){require(steps<input.settings.maxSteps,"Settle timeout; previous result preserved");world->step();++steps;bool isQuiet=released;double maximumLinear=0,maximumAngular=0;unsigned active=0;for(auto& state:world->states()){require(finite(state.row.position)&&finite(state.velocity)&&finite(state.spin),"Non-finite solver result");maximumLinear=std::max(maximumLinear,length(state.velocity));maximumAngular=std::max(maximumAngular,length(state.spin));if(!state.sleeping)++active;if(!state.sleeping&&(length(state.velocity)>input.settings.quietLinear||length(state.spin)>input.settings.quietAngular))isQuiet=false;}motion={{"active",active},{"max_linear_mps",maximumLinear},{"max_angular_radps",maximumAngular},{"steps",steps},{"quiet_steps",quiet}};quiet=isQuiet?quiet+1:0;if(quiet>=input.settings.quietSteps){completed=true;return true;}}return false;}
std::vector<Row> Session::rows()const{require(!cancelled,"Session cancelled");std::vector<Row> out;for(auto& state:world->states())out.push_back(state.row);return out;}
}
