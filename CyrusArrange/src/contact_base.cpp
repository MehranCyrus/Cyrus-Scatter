#include "cyrus_arrange/contact_base.h"
#include <algorithm>
#include <array>
#include <cmath>
#include <limits>
#include <stdexcept>

namespace cyrus::arrange {
namespace {
constexpr double pi=3.14159265358979323846,area_epsilon=1e-6;
double dot(Vec3 a,Vec3 b){return a.x*b.x+a.y*b.y;}
double cross(Vec3 a,Vec3 b,Vec3 c){return (b.x-a.x)*(c.y-b.y)-(b.y-a.y)*(c.x-b.x);}
std::vector<Vec3> rectangle(const Bounds& b,double z){return {{b.min.x,b.min.y,z},{b.max.x,b.min.y,z},{b.max.x,b.max.y,z},{b.min.x,b.max.y,z}};}
void include(Bounds& b,Vec3 p){b.min.x=std::min(b.min.x,p.x);b.min.y=std::min(b.min.y,p.y);b.max.x=std::max(b.max.x,p.x);b.max.y=std::max(b.max.y,p.y);}
}
ContactBase infer_contact_base(const Mesh& mesh,const AssetLimits& limits,std::uint64_t max_work){
    if(mesh.vertices.empty()||mesh.triangles.empty()||mesh.vertices.size()>std::min<std::size_t>(250000,limits.max_vertices_per_asset)||mesh.triangles.size()>std::min<std::size_t>(250000,limits.max_triangles_per_asset)||
       limits.max_footprint_vertices<4||limits.max_footprint_vertices>64||max_work>8000000||max_work<mesh.vertices.size()+4*mesh.triangles.size())
        throw std::invalid_argument("Automatic base exceeds geometry, footprint or work admission.");
    ContactBase out;out.work=mesh.vertices.size();const auto bounds=mesh_bounds(mesh);
    out.anchor={(bounds.min.x+bounds.max.x)*.5,(bounds.min.y+bounds.max.y)*.5,bounds.min.z};out.footprint=rectangle(bounds,out.anchor.z);
    const auto spend=[&](std::uint64_t n){if(n>max_work-out.work){out.work=max_work;out.limited=true;return false;}out.work+=n;return true;};
    bool contact=false;
    for(const auto& face:mesh.triangles){
        spend(4); // Admission reserves this complete contact/index preflight.
        for(auto index:face.vertices)if(index>=mesh.vertices.size())throw std::invalid_argument("Automatic base has an invalid triangle index.");
        const auto p=mesh.vertices[face.vertices[0]],q=mesh.vertices[face.vertices[1]],r=mesh.vertices[face.vertices[2]];
        if(std::min({p.z,q.z,r.z})>bounds.min.z+default_contact_tolerance_mm)continue;
        const Vec3 a{q.x-p.x,q.y-p.y,q.z-p.z},b{r.x-p.x,r.y-p.y,r.z-p.z};
        const Vec3 n{a.y*b.z-a.z*b.y,a.z*b.x-a.x*b.z,a.x*b.y-a.y*b.x};
        contact=contact||n.x*n.x+n.y*n.y+n.z*n.z>1e-18;
    }
    if(!contact){out.kind=ContactBaseKind::NoReferencedContact;return out;}
    const auto directions=std::min<std::size_t>(32,limits.max_footprint_vertices-4);
    std::array<Vec3,32> normals{};std::array<double,32> support;support.fill(-INFINITY);
    if(!spend(directions*4))return out;
    for(std::size_t i=0;i<directions;++i){const double a=2*pi*i/directions;normals[i]={std::cos(a),std::sin(a),0};}
    const double plane=bounds.min.z+0.5;
    Bounds base{{INFINITY,INFINITY,bounds.min.z},{-INFINITY,-INFINITY,bounds.min.z}};
    for(const auto& face:mesh.triangles){
        if(!spend(4))return out;
        for(auto index:face.vertices)if(index>=mesh.vertices.size())throw std::invalid_argument("Automatic base has an invalid triangle index.");
        const std::array<Vec3,3> t{mesh.vertices[face.vertices[0]],mesh.vertices[face.vertices[1]],mesh.vertices[face.vertices[2]]};
        if(std::min({t[0].z,t[1].z,t[2].z})>plane)continue;
        const Vec3 a{t[1].x-t[0].x,t[1].y-t[0].y,t[1].z-t[0].z},b{t[2].x-t[0].x,t[2].y-t[0].y,t[2].z-t[0].z};
        const Vec3 n{a.y*b.z-a.z*b.y,a.z*b.x-a.x*b.z,a.x*b.y-a.y*b.x};
        if(n.x*n.x+n.y*n.y+n.z*n.z<=1e-18)continue;
        std::array<Vec3,6> clipped{};std::size_t count=0;
        for(std::size_t i=0;i<3;++i){
            const auto p=t[i],q=t[(i+1)%3];const bool inside=p.z<=plane,other=q.z<=plane;
            if(inside)clipped[count++]=p;
            if(inside!=other){const double s=(plane-p.z)/(q.z-p.z);clipped[count++]={p.x+(q.x-p.x)*s,p.y+(q.y-p.y)*s,plane};}
        }
        for(std::size_t i=0;i<count;++i){
            if(!spend(1+directions))return out;
            include(base,clipped[i]);++out.contact_points;
            for(std::size_t j=0;j<directions;++j)support[j]=std::max(support[j],dot(clipped[i],normals[j]));
        }
    }
    if(base.max.x-base.min.x<=1e-6||base.max.y-base.min.y<=1e-6)return out;
    auto polygon=rectangle(base,bounds.min.z);std::vector<Vec3> next;next.reserve(limits.max_footprint_vertices);
    for(std::size_t direction=0;direction<directions;++direction){
        if(!spend(polygon.size()*4))return out;
        next.clear();const auto normal=normals[direction];
        const double pad=1e-7+64*std::numeric_limits<double>::epsilon()*std::max(1.0,std::abs(support[direction]));
        const double bound=support[direction]+pad;
        for(std::size_t i=0;i<polygon.size();++i){
            const auto p=polygon[i],q=polygon[(i+1)%polygon.size()];const double dp=dot(p,normal)-bound,dq=dot(q,normal)-bound;const bool inside=dp<=0,other=dq<=0;
            if(inside)next.push_back(p);
            if(inside!=other){const double s=dp/(dp-dq);next.push_back({p.x+(q.x-p.x)*s,p.y+(q.y-p.y)*s,bounds.min.z});}
        }
        if(next.size()<3||next.size()>limits.max_footprint_vertices)return out;
        polygon.swap(next);
    }
    if(!spend(polygon.size()*polygon.size()))return out;
    double area=0;bool stable=true;
    for(std::size_t i=0;i<polygon.size();++i){
        const auto a=polygon[i],b=polygon[(i+1)%polygon.size()],c=polygon[(i+2)%polygon.size()];
        stable=stable&&cross(a,b,c)>area_epsilon;area+=a.x*b.y-a.y*b.x;
        for(auto p:polygon)stable=stable&&((b.x-a.x)*(p.y-a.y)-(b.y-a.y)*(p.x-a.x)>=-area_epsilon);
    }
    // A base rectangle still encloses the entire contact band when near-collinear
    // clipping edges cannot satisfy the existing portable footprint precision.
    if(!stable||area<=area_epsilon)polygon=rectangle(base,bounds.min.z);
    const double width=base.max.x-base.min.x,depth=base.max.y-base.min.y;
    if(width*depth<=area_epsilon)return out;
    out.kind=ContactBaseKind::Refined;out.anchor={(base.min.x+base.max.x)*.5,(base.min.y+base.max.y)*.5,bounds.min.z};out.footprint=std::move(polygon);return out;
}
Bounds contact_base_bounds(const Asset& asset){
    if(asset.contact_footprint.empty()||asset.contact_footprint.size()>64)throw std::invalid_argument("Base center needs a validated contact envelope.");
    auto b=Bounds{asset.contact_footprint.front(),asset.contact_footprint.front()};for(auto p:asset.contact_footprint)include(b,p);
    return b;
}
Vec3 contact_base_center(const Asset& asset){
    const auto b=contact_base_bounds(asset);return {(b.min.x+b.max.x)*.5,(b.min.y+b.max.y)*.5,asset.anchor.z};
}
Vec3 placed_base_center(const Asset& asset,Vec3 position,double yaw,double scale){
    const auto center=contact_base_center(asset);const double a=std::remainder(yaw,360.0)*pi/180,c=std::cos(a),s=std::sin(a);
    const double x=(center.x-asset.anchor.x)*scale,y=(center.y-asset.anchor.y)*scale;
    return {position.x+c*x-s*y,position.y+s*x+c*y,position.z};
}
}
