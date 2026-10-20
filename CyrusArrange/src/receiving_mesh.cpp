#include "cyrus_arrange/receiving_mesh.h"
#include "receiver_topology.h"
#include <algorithm>
#include <cmath>
#include <limits>
#include <map>
#include <numeric>
#include <set>
#include <stdexcept>
#include <tuple>

namespace cyrus::arrange {
namespace {
struct Budget {
    std::uint64_t used{},limit{};
    void charge(std::uint64_t n=1){if(n>limit-used)throw std::runtime_error("Receiving topology/preparation work limit exceeded; previous arrangement retained.");used+=n;}
};
Vec3 sub(Vec3 a,Vec3 b){return {a.x-b.x,a.y-b.y,a.z-b.z};}
Vec3 cross(Vec3 a,Vec3 b){return {a.y*b.z-a.z*b.y,a.z*b.x-a.x*b.z,a.x*b.y-a.y*b.x};}
double dot(Vec3 a,Vec3 b){return a.x*b.x+a.y*b.y+a.z*b.z;}
void include(Bounds& b,Vec3 p){b.min={std::min(b.min.x,p.x),std::min(b.min.y,p.y),std::min(b.min.z,p.z)};b.max={std::max(b.max.x,p.x),std::max(b.max.y,p.y),std::max(b.max.z,p.z)};}
bool zero_area(const Mesh& m,const Triangle& t){const auto n=cross(sub(m.vertices[t.vertices[1]],m.vertices[t.vertices[0]]),sub(m.vertices[t.vertices[2]],m.vertices[t.vertices[0]]));return dot(n,n)<1e-18;}
struct DisjointSet {
    std::vector<std::size_t> p;Budget& budget;
    DisjointSet(std::size_t n,Budget& b):p(n),budget(b){std::iota(p.begin(),p.end(),0);}
    std::size_t root(std::size_t a){budget.charge();while(p[a]!=a){budget.charge();p[a]=p[p[a]];a=p[a];}return a;}
    void join(std::size_t a,std::size_t b){a=root(a);b=root(b);if(a!=b)p[b]=a;}
};
bool potentially_nested_or_intersecting(const Bounds& a,const Bounds& b){
    constexpr double e=default_contact_tolerance_mm;
    const auto contains=[](const Bounds& x,const Bounds& y){return x.min.x<=y.min.x+e&&x.min.y<=y.min.y+e&&x.min.z<=y.min.z+e&&x.max.x>=y.max.x-e&&x.max.y>=y.max.y-e&&x.max.z>=y.max.z-e;};
    return contains(a,b)||contains(b,a)||
        (std::min(a.max.x,b.max.x)-std::max(a.min.x,b.min.x)>e&&std::min(a.max.y,b.max.y)-std::max(a.min.y,b.min.y)>e&&std::min(a.max.z,b.max.z)-std::max(a.min.z,b.min.z)>e);
}
}

detail::ReceiverTopology detail::append_receiver_topology(const Mesh& mesh,std::vector<ReceiverComponent>& components,
    std::uint64_t body_id,bool obstacle,double max_coordinate,std::uint64_t max_work){
    Budget budget{0,max_work};
    if(mesh.vertices.size()>3000000||mesh.triangles.size()>1000000)throw std::invalid_argument("Receiving topology input exceeds vertex/triangle admission.");
    budget.charge(mesh.triangles.size());DisjointSet groups(mesh.triangles.size(),budget);
    using PointKey=std::tuple<double,double,double>;
    std::map<PointKey,std::size_t> welded;std::vector<std::size_t> vertex_ids;vertex_ids.reserve(mesh.vertices.size());
    for(const auto p:mesh.vertices){
        budget.charge();if(!std::isfinite(p.x)||!std::isfinite(p.y)||!std::isfinite(p.z)||std::max({std::abs(p.x),std::abs(p.y),std::abs(p.z)})>max_coordinate)throw std::invalid_argument("Receiving vertices must be finite and within the configured coordinate limit.");
        const auto key=PointKey{static_cast<double>(std::llround(p.x*1000)),static_cast<double>(std::llround(p.y*1000)),static_cast<double>(std::llround(p.z*1000))};
        auto [it,added]=welded.emplace(key,welded.size());vertex_ids.push_back(it->second);
    }
    struct Edge{std::size_t first{},count{};int orientation{};};
    std::map<std::pair<std::size_t,std::size_t>,Edge> edges;
    const auto record=[&](const Triangle& t,std::size_t i){
        for(int k=0;k<3;++k)if(vertex_ids[t.vertices[k]]==vertex_ids[t.vertices[(k+1)%3]])return false;
        for(int k=0;k<3;++k){budget.charge();auto a=vertex_ids[t.vertices[k]],b=vertex_ids[t.vertices[(k+1)%3]];const int direction=a<b?1:-1;if(a>b)std::swap(a,b);auto [it,added]=edges.emplace(std::make_pair(a,b),Edge{i,0,0});if(!added)groups.join(i,it->second.first);++it->second.count;it->second.orientation+=direction;}
        return true;
    };
    bool exact=false;
    for(std::size_t i=0;i<mesh.triangles.size();++i){const auto& t=mesh.triangles[i];
        for(const auto index:t.vertices){budget.charge();if(index>=mesh.vertices.size())throw std::invalid_argument("Receiving triangle index outside vertex buffer.");}
        if(zero_area(mesh,t)){budget.charge();groups.p[i]=no_receiver_component;continue;}
        if(!exact&&!record(t,i))exact=true;
    }
    if(exact){
        budget.charge(welded.size()+edges.size()+groups.p.size());welded.clear();edges.clear();std::iota(groups.p.begin(),groups.p.end(),0);
        for(std::size_t i=0;i<mesh.vertices.size();++i){budget.charge();const auto p=mesh.vertices[i];auto [it,added]=welded.emplace(PointKey{p.x,p.y,p.z},welded.size());vertex_ids[i]=it->second;}
        for(std::size_t i=0;i<mesh.triangles.size();++i){budget.charge();const auto& t=mesh.triangles[i];if(zero_area(mesh,t)){groups.p[i]=no_receiver_component;continue;}if(!record(t,i))throw std::logic_error("Nonzero receiving triangle has identical exact endpoints.");}
    }
    // Finish root compression before reusing the same storage as component IDs.
    for(std::size_t i=0;i<groups.p.size();++i)if(groups.p[i]!=no_receiver_component)groups.p[i]=groups.root(i);
    std::map<std::size_t,std::size_t> ids;
    for(std::size_t i=0;i<groups.p.size();++i){budget.charge();const auto key=groups.p[i];if(key==no_receiver_component)continue;
        auto [it,added]=ids.emplace(key,components.size());if(added){components.emplace_back();components.back().body_id=body_id;components.back().obstacle=obstacle;}
        groups.p[i]=it->second;for(const auto index:mesh.triangles[i].vertices){budget.charge();include(components[it->second].bounds,mesh.vertices[index]);}
    }
    for(const auto& [key,edge]:edges){budget.charge();if(edge.count!=2||edge.orientation!=0)components[groups.p[edge.first]].closed=false;}
    return {std::move(groups.p),budget.used};
}

ReceivingMeshPreparation prepare_receiving_meshes(std::span<Mesh* const> meshes,const ReceivingMeshLimits& limits){
    if(!limits.max_bodies||limits.max_bodies>4096||!limits.max_vertices||limits.max_vertices>3000000||!limits.max_triangles||limits.max_triangles>1000000||!limits.max_work||limits.max_work>200000000||!std::isfinite(limits.max_coordinate_mm)||limits.max_coordinate_mm<=0||limits.max_coordinate_mm>1e9||meshes.size()>limits.max_bodies)
        throw std::invalid_argument("Invalid receiving preparation limits.");
    Budget budget{0,limits.max_work};std::size_t vertices=0,triangles=0;std::set<Mesh*> owners;
    for(auto* m:meshes){budget.charge();if(!m||!owners.insert(m).second||m->vertices.empty()||m->triangles.empty()||m->vertices.size()>limits.max_vertices-vertices||m->triangles.size()>limits.max_triangles-triangles)throw std::invalid_argument("Receiving preparation requires unique owned nonempty meshes within aggregate limits.");vertices+=m->vertices.size();triangles+=m->triangles.size();}
    std::vector<detail::ReceiverComponent> components;std::vector<detail::ReceiverTopology> bodies;bodies.reserve(meshes.size());
    for(std::size_t i=0;i<meshes.size();++i){auto topology=detail::append_receiver_topology(*meshes[i],components,i+1,false,limits.max_coordinate_mm,budget.limit-budget.used);budget.charge(topology.work);bodies.push_back(std::move(topology));}
    struct Volume{double sum{},correction{},absolute{};std::size_t faces{};};static_assert(sizeof(Volume)==32);
    std::vector<Volume> volumes(components.size());budget.charge(components.size());
    for(std::size_t i=0;i<meshes.size();++i)for(std::size_t f=0;f<meshes[i]->triangles.size();++f){budget.charge();const auto id=bodies[i].face_components[f];if(id==detail::no_receiver_component||!components[id].closed)continue;
        budget.charge(10);const auto& t=meshes[i]->triangles[f];const auto origin=components[id].bounds.min;const auto term=dot(sub(meshes[i]->vertices[t.vertices[0]],origin),cross(sub(meshes[i]->vertices[t.vertices[1]],origin),sub(meshes[i]->vertices[t.vertices[2]],origin)));
        auto& v=volumes[id];const auto y=term-v.correction,next=v.sum+y;v.correction=(next-v.sum)-y;v.sum=next;v.absolute+=std::abs(term);++v.faces;
    }
    // Bit 1: robustly inward. Bit 2: ambiguous; must retain authored winding.
    std::vector<unsigned char> flags(components.size());std::vector<std::size_t> negative,closed;
    ReceivingMeshPreparation result;
    for(std::size_t i=0;i<components.size();++i){budget.charge();const auto& c=components[i];if(!c.closed){++result.open_components;continue;}closed.push_back(i);
        const auto d=sub(c.bounds.max,c.bounds.min);const auto error=128*std::numeric_limits<double>::epsilon()*(volumes[i].absolute+6*d.x*d.y*d.z);
        if(std::abs(volumes[i].sum)<=error)flags[i]=2;
        else if(volumes[i].sum<0){flags[i]=1;negative.push_back(i);}
    }
    const auto screen=[&](std::size_t a,std::size_t b){budget.charge();if(a==b||!((flags[a]|flags[b])&1))return;if(potentially_nested_or_intersecting(components[a].bounds,components[b].bounds)){if(flags[a]&1)flags[a]|=2;if(flags[b]&1)flags[b]|=2;}};
    if(negative.size()<=32){for(auto a:negative)for(auto b:closed)screen(a,b);}
    else{
        std::sort(closed.begin(),closed.end(),[&](auto a,auto b){budget.charge();return std::tie(components[a].bounds.min.x,a)<std::tie(components[b].bounds.min.x,b);});
        std::vector<std::size_t> active;active.reserve(closed.size());
        for(auto b:closed){budget.charge(1+active.size());const auto x=components[b].bounds.min.x-default_contact_tolerance_mm;
            active.erase(std::remove_if(active.begin(),active.end(),[&](auto a){return components[a].bounds.max.x<x;}),active.end());
            for(auto a:active)screen(a,b);active.push_back(b);
        }
    }
    for(auto flag:flags){budget.charge();if(flag&2)++result.ambiguous_components;else if(flag&1)++result.reversed_components;}
    // No allocation, budget failure or validation may happen after this charge.
    budget.charge(triangles);
    for(std::size_t i=0;i<meshes.size();++i)for(std::size_t f=0;f<meshes[i]->triangles.size();++f){const auto id=bodies[i].face_components[f];if(id!=detail::no_receiver_component&&flags[id]==1){auto& t=meshes[i]->triangles[f];std::swap(t.vertices[1],t.vertices[2]);++result.reversed_faces;}}
    result.work=budget.used;return result;
}

void append_receiving_warnings(Result& result,const ReceivingMeshPreparation& prepared){
    if(prepared.reversed_components)result.warnings.emplace_back("Evaluated "+std::to_string(prepared.reversed_components)+" inward closed receiving shell(s) outward in native copies; original geometry/materials are unchanged.");
    if(prepared.ambiguous_components)result.warnings.emplace_back("Kept authored winding on "+std::to_string(prepared.ambiguous_components)+" ambiguous closed receiving shell(s); zero-volume or potentially nested/intersecting shells are not repaired.");
}
}
