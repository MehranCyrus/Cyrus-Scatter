#include "cyrus_arrange/collision_proxy.h"
#include <algorithm>
#include <cmath>
#include <limits>
#include <numeric>
#include <stdexcept>
#include <tuple>

namespace cyrus::arrange {
namespace {
constexpr double pi=3.14159265358979323846;
constexpr std::uint64_t maximum_build_work=20000000;
constexpr std::size_t maximum_pieces=128;
struct Limit {};
struct Budget {std::uint64_t limit{},used{};void charge(std::uint64_t n=1){if(n>limit-used)throw Limit{};used+=n;}};
Bounds empty(){return {{INFINITY,INFINITY,INFINITY},{-INFINITY,-INFINITY,-INFINITY}};}
void include(Bounds& b,Vec3 p){b.min={std::min(b.min.x,p.x),std::min(b.min.y,p.y),std::min(b.min.z,p.z)};b.max={std::max(b.max.x,p.x),std::max(b.max.y,p.y),std::max(b.max.z,p.z)};}
void include(Bounds& a,const Bounds& b){include(a,b.min);include(a,b.max);}
bool finite(Vec3 p){return std::isfinite(p.x)&&std::isfinite(p.y)&&std::isfinite(p.z);}
Vec3 rotate(Vec3 p,double yaw){const double a=std::remainder(yaw,360.0)*pi/180,c=std::cos(a),s=std::sin(a);return {c*p.x-s*p.y,s*p.x+c*p.y,p.z};}
double dot(Vec3 a,Vec3 b){return a.x*b.x+a.y*b.y+a.z*b.z;}
bool overlap(const OrientedBox& a,const OrientedBox& b,double gap,double eps,double vertical_gap=0){
    if(std::abs(a.center.z-b.center.z)>=a.half_extents.z+b.half_extents.z+vertical_gap-eps)return false;
    const auto ax=rotate({1,0,0},a.yaw_degrees),ay=rotate({0,1,0},a.yaw_degrees),bx=rotate({1,0,0},b.yaw_degrees),by=rotate({0,1,0},b.yaw_degrees);
    const Vec3 d{a.center.x-b.center.x,a.center.y-b.center.y,a.center.z-b.center.z};
    for(auto v:{ax,ay,bx,by}){const double r=std::abs(dot(v,ax))*a.half_extents.x+std::abs(dot(v,ay))*a.half_extents.y+std::abs(dot(v,bx))*b.half_extents.x+std::abs(dot(v,by))*b.half_extents.y+gap;if(std::abs(dot(d,v))>=r-eps)return false;}return true;
}
struct Key {Vec3 point;std::size_t index;};
struct Edge {std::size_t a{},b{};int orientation{};};
struct Dsu {
    std::vector<std::size_t> parent,size;
    Dsu(std::size_t n,Budget& b):parent(n),size(n,1){b.charge(n);std::iota(parent.begin(),parent.end(),0);}
    std::size_t root(std::size_t a,Budget& b){while(parent[a]!=a){b.charge();parent[a]=parent[parent[a]];a=parent[a];}return a;}
    void join(std::size_t a,std::size_t c,Budget& b){b.charge();a=root(a,b);c=root(c,b);if(a==c)return;if(size[a]<size[c]||(size[a]==size[c]&&a>c))std::swap(a,c);parent[c]=a;size[a]+=size[c];}
};
bool topology(const Asset& a,std::vector<std::size_t>& ids,std::size_t& count,Budget& budget){
    // Asset admission bounds these temporary arrays before allocation: at most
    // 250k vertex keys and 750k edge records, never a triangle-pair table.
    std::vector<Key> keys;keys.reserve(a.mesh.vertices.size());ids.resize(a.mesh.vertices.size());
    for(std::size_t i=0;i<a.mesh.vertices.size();++i){budget.charge();keys.push_back({a.mesh.vertices[i],i});}
    std::sort(keys.begin(),keys.end(),[&](const auto& x,const auto& y){budget.charge();return std::tie(x.point.x,x.point.y,x.point.z,x.index)<std::tie(y.point.x,y.point.y,y.point.z,y.index);});
    count=0;Vec3 prior{INFINITY,INFINITY,INFINITY};
    for(auto k:keys){budget.charge();if(k.point.x!=prior.x||k.point.y!=prior.y||k.point.z!=prior.z){++count;prior=k.point;}ids[k.index]=count-1;}
    std::vector<Edge> edges;edges.reserve(a.mesh.triangles.size()*3);
    for(const auto& face:a.mesh.triangles)for(int k=0;k<3;++k){budget.charge();auto x=ids.at(face.vertices[k]),y=ids.at(face.vertices[(k+1)%3]);if(x==y)return false;const int sign=x<y?1:-1;if(x>y)std::swap(x,y);edges.push_back({x,y,sign});}
    std::sort(edges.begin(),edges.end(),[&](auto x,auto y){budget.charge();return std::tie(x.a,x.b)<std::tie(y.a,y.b);});
    for(std::size_t i=0;i<edges.size();){budget.charge();auto j=i+1;int orientation=edges[i].orientation;while(j<edges.size()&&edges[j].a==edges[i].a&&edges[j].b==edges[i].b){budget.charge();orientation+=edges[j++].orientation;}if(j-i!=2||orientation!=0)return false;i=j;}return true;
}
std::size_t clip(const std::array<Vec3,8>& in,std::size_t count,std::array<Vec3,8>& out,double plane,bool above){
    std::size_t n=0;for(std::size_t i=0;i<count;++i){const auto a=in[i],b=in[(i+1)%count];const bool ia=above?a.z>=plane:a.z<=plane,ib=above?b.z>=plane:b.z<=plane;
        if(ia)out[n++]=a;
        if(ia!=ib){const double t=std::clamp((plane-a.z)/(b.z-a.z),0.0,1.0);out[n++]={a.x+(b.x-a.x)*t,a.y+(b.y-a.y)*t,plane};}
    }return n;
}
struct Clipped {Bounds box;std::size_t vertex;};
std::vector<Bounds> build(const Asset& asset,std::uint64_t allowance,std::uint64_t& work){
    Budget budget{std::min(allowance,maximum_build_work)};std::vector<std::size_t> ids;std::size_t vertex_count=0;bool closed=false;
    // Topology is optional precision, never an admission to drop geometry. Its
    // spent work remains charged even when a sub-budget requests coarser bands.
    const auto n=asset.mesh.vertices.size(),t=asset.mesh.triangles.size();
    if((n+t)*64<=budget.limit/2){Budget topo{budget.limit/2};try{closed=topology(asset,ids,vertex_count,topo);}catch(const Limit&){}budget.charge(topo.used);}
    if(!closed){work=budget.used;return {asset.bounds};}
    const auto band_estimate=t*64+n*2+1;const auto bands=std::min<std::uint64_t>(16,(budget.limit-budget.used)/band_estimate);
    if(!bands){work=budget.used;return {asset.bounds};}
    std::vector<Bounds> result;result.reserve(maximum_pieces);std::vector<Clipped> clipped;clipped.reserve(t);
    const auto add_piece=[&](Bounds b){
        const auto& full=asset.bounds;const double magnitude=std::max({1.0,std::abs(full.min.x),std::abs(full.min.y),std::abs(full.min.z),std::abs(full.max.x),std::abs(full.max.y),std::abs(full.max.z)}),pad=std::max(1e-6,magnitude*16*std::numeric_limits<double>::epsilon());
        b.min={std::max(full.min.x,b.min.x-pad),std::max(full.min.y,b.min.y-pad),std::max(full.min.z,b.min.z-pad)};b.max={std::min(full.max.x,b.max.x+pad),std::min(full.max.y,b.max.y+pad),std::min(full.max.z,b.max.z+pad)};
        for(auto& p:result){budget.charge();if(p.min.x==b.min.x&&p.max.x==b.max.x&&p.min.y==b.min.y&&p.max.y==b.max.y&&p.max.z>=b.min.z&&b.max.z>=p.min.z){include(p,b);return;}}
        if(result.size()==maximum_pieces)throw std::logic_error("Compound collider piece admission failed.");result.push_back(b);
    };
    for(std::size_t band=0;band<bands;++band){
        const double lo=asset.bounds.min.z+(asset.bounds.max.z-asset.bounds.min.z)*band/bands,hi=band+1==bands?asset.bounds.max.z:asset.bounds.min.z+(asset.bounds.max.z-asset.bounds.min.z)*(band+1)/bands;if(hi<=lo)continue;
        clipped.clear();Dsu groups(vertex_count,budget);Bounds whole=empty();
        for(const auto& face:asset.mesh.triangles){budget.charge(8);std::array<Vec3,8> p{},q{};for(int i=0;i<3;++i)p[i]=asset.mesh.vertices.at(face.vertices[i]);const auto a=clip(p,3,q,lo,true),b=clip(q,a,p,hi,false);if(!b)continue;
            Bounds box=empty();for(std::size_t i=0;i<b;++i)include(box,p[i]);box.min.z=lo;box.max.z=hi;include(whole,box);
            const auto v=ids[face.vertices[0]];groups.join(v,ids[face.vertices[1]],budget);groups.join(v,ids[face.vertices[2]],budget);clipped.push_back({box,v});
        }
        if(!std::isfinite(whole.min.x))continue;
        struct Group {std::size_t id{};Bounds box;};std::array<Group,8> pieces{};std::size_t count=0;bool merged=false;
        for(const auto& c:clipped){const auto root=groups.root(c.vertex,budget);std::size_t i=0;for(;i<count;++i){budget.charge();if(pieces[i].id==root){include(pieces[i].box,c.box);break;}}if(i==count){if(count==pieces.size()){merged=true;break;}pieces[count++]={root,c.box};}}
        if(merged)add_piece(whole);else for(std::size_t i=0;i<count;++i)add_piece(pieces[i].box);
    }
    work=budget.used;if(result.empty())return {asset.bounds};return result;
}
}
CollisionProxyLease CollisionSource::proxy(std::uint64_t remaining)const{
    if(built_)return {pieces_,0};
    // Existing asset admission proves these bounds; low allowance retains the
    // complete source envelope instead of approximating by missing triangles.
    if(remaining<64||asset_->mesh.triangles.size()>250000||asset_->mesh.vertices.size()>250000)return {root_,0};
    std::uint64_t work=0;try{pieces_=build(*asset_,remaining,work);built_=true;return {pieces_,work};}catch(const Limit&){throw std::runtime_error("Compound source refinement exceeded its admitted work; previous output retained.");}
}
OrientedBox collision_piece(const CollisionPose& pose,const Bounds& bounds,double tolerance){
    const auto anchor=pose.source?pose.source->anchor():Vec3{};const auto c=rotate({((bounds.min.x+bounds.max.x)*.5-anchor.x)*pose.scale,((bounds.min.y+bounds.max.y)*.5-anchor.y)*pose.scale,((bounds.min.z+bounds.max.z)*.5-anchor.z)*pose.scale},pose.yaw_degrees);
    OrientedBox box{{pose.position.x+c.x,pose.position.y+c.y,pose.position.z+c.z},{(bounds.max.x-bounds.min.x)*pose.scale*.5,(bounds.max.y-bounds.min.y)*pose.scale*.5,(bounds.max.z-bounds.min.z)*pose.scale*.5},pose.yaw_degrees};
    if(tolerance>0&&pose.source){const auto root=pose.source->bounds();const double lo=std::max(pose.position.z+(root.min.z-anchor.z)*pose.scale,box.center.z-box.half_extents.z-2*tolerance),hi=std::min(pose.position.z+(root.max.z-anchor.z)*pose.scale,box.center.z+box.half_extents.z+2*tolerance);box.center.z=(lo+hi)*.5;box.half_extents.z=(hi-lo)*.5;}
    return box;
}
void validate_collision_pose(const OrientedBox& box,const CollisionPose& p){
    if(!finite(box.center)||!finite(box.half_extents)||!std::isfinite(box.yaw_degrees)||box.half_extents.x<=0||box.half_extents.y<=0||box.half_extents.z<=0)throw std::invalid_argument("Collision bounds must have finite positive dimensions.");
    if(!p.source)return;
    if(!finite(p.position)||!std::isfinite(p.yaw_degrees)||!std::isfinite(p.scale)||p.scale<=0||p.scale>1000)throw std::invalid_argument("Invalid compound collision pose.");
    const auto actual=collision_piece(p,p.source->bounds());const double tolerance=std::max(1e-6,16*std::numeric_limits<double>::epsilon()*std::max({1.0,std::abs(box.center.x),std::abs(box.center.y),std::abs(box.center.z)}));
    for(const auto d:{actual.center.x-box.center.x,actual.center.y-box.center.y,actual.center.z-box.center.z,actual.half_extents.x-box.half_extents.x,actual.half_extents.y-box.half_extents.y,actual.half_extents.z-box.half_extents.z})if(!std::isfinite(d)||std::abs(d)>tolerance)throw std::invalid_argument("Compound collider differs from its complete placement bounds.");
    if(std::abs(std::remainder(std::remainder(p.yaw_degrees,360.0)-std::remainder(box.yaw_degrees,360.0),360.0))>1e-6)throw std::invalid_argument("Compound collider differs from its placement heading.");
}
CollisionOverlap collision_overlap(const OrientedBox& a,const CollisionPose& pa,const OrientedBox& b,const CollisionPose& pb,double gap,double tolerance,std::uint64_t remaining){
    if(!std::isfinite(gap)||gap<0||gap>1000000||!std::isfinite(tolerance)||tolerance<0||!remaining)throw std::invalid_argument("Invalid compound collision query allowance or gap.");
    validate_collision_pose(a,pa);validate_collision_pose(b,pb);Budget budget{remaining};
    try{budget.charge(8);if(!overlap(a,b,gap,tolerance))return {false,budget.used};
        if(!pa.source&&!pb.source)return {true,budget.used};
        CollisionProxyLease x{},y{};if(pa.source){x=pa.source->proxy(budget.limit-budget.used);budget.charge(x.build_work);}if(pb.source){y=pb.source->proxy(budget.limit-budget.used);budget.charge(y.build_work);}
        const auto xn=pa.source?x.pieces.size():1,yn=pb.source?y.pieces.size():1;
        // Whole-object height filtering retains normal stack behavior. Once a
        // broad pair needs refinement, artificial band cuts must not authorize
        // a smaller gap merely because two pieces are vertically disjoint.
        for(std::size_t i=0;i<xn;++i){const auto left=pa.source?collision_piece(pa,x.pieces[i],tolerance):a;for(std::size_t j=0;j<yn;++j){budget.charge(8);const auto right=pb.source?collision_piece(pb,y.pieces[j],tolerance):b;if(overlap(left,right,gap,tolerance,gap))return {true,budget.used};}}return {false,budget.used};
    }catch(const Limit&){throw std::runtime_error("Compound collision work budget exceeded; previous output retained.");}
}
}
