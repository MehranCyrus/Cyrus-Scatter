#include "cyrus_arrange/placement_queries.h"
#include "query_retained_allocator.h"
#include "receiver_topology.h"
#include <clipper2/clipper.h>
#include <algorithm>
#include <array>
#include <cmath>
#include <limits>
#include <map>
#include <numeric>
#include <set>
#include <stdexcept>
#include <tuple>

namespace cyrus::arrange {
namespace {
namespace cp = Clipper2Lib;
constexpr double polygon_scale=1000.0, max_coordinate=10000000.0;
constexpr double pi=3.14159265358979323846;
Vec3 add(Vec3 a,Vec3 b){return {a.x+b.x,a.y+b.y,a.z+b.z};}
Vec3 sub(Vec3 a,Vec3 b){return {a.x-b.x,a.y-b.y,a.z-b.z};}
Vec3 mul(Vec3 a,double s){return {a.x*s,a.y*s,a.z*s};}
double dot(Vec3 a,Vec3 b){return a.x*b.x+a.y*b.y+a.z*b.z;}
Vec3 cross(Vec3 a,Vec3 b){return {a.y*b.z-a.z*b.y,a.z*b.x-a.x*b.z,a.x*b.y-a.y*b.x};}
double axis(Vec3 p,int a){return a==0?p.x:a==1?p.y:p.z;}
bool finite(Vec3 p){return std::isfinite(p.x)&&std::isfinite(p.y)&&std::isfinite(p.z);}
Vec3 normalized_front(Vec3 direction){
    const double length=std::hypot(direction.x,direction.y);
    if(!finite(direction)||std::abs(direction.z)>1e-9||length<1e-9||length>1e6)
        throw std::invalid_argument("Fit front direction must be finite, horizontal and have length in [1e-9,1000000].");
    return {direction.x/length,direction.y/length,0};
}
void valid_point(Vec3 p){if(!finite(p)||std::max({std::abs(p.x),std::abs(p.y),std::abs(p.z)})>max_coordinate)throw std::invalid_argument("Fit geometry must be finite and within 10 km of its local origin.");}
Bounds empty_bounds(){return {{INFINITY,INFINITY,INFINITY},{-INFINITY,-INFINITY,-INFINITY}};}
void include(Bounds& b,Vec3 p){b.min={std::min(b.min.x,p.x),std::min(b.min.y,p.y),std::min(b.min.z,p.z)};b.max={std::max(b.max.x,p.x),std::max(b.max.y,p.y),std::max(b.max.z,p.z)};}
void include(Bounds& b,const Bounds& a){include(b,a.min);include(b,a.max);}
bool overlap(const Bounds& a,const Bounds& b){return a.min.x<=b.max.x&&a.max.x>=b.min.x&&a.min.y<=b.max.y&&a.max.y>=b.min.y&&a.min.z<=b.max.z&&a.max.z>=b.min.z;}
bool contains(const Bounds& b,Vec3 p){return p.x>=b.min.x&&p.x<=b.max.x&&p.y>=b.min.y&&p.y<=b.max.y&&p.z>=b.min.z&&p.z<=b.max.z;}
struct Budget {
    std::uint64_t used{},limit{};
    void charge(std::uint64_t n=1){if(n>limit-used)throw std::runtime_error("Furniture fit work budget exceeded; previous arrangement retained.");used+=n;}
};
std::int64_t quantize(double v){return static_cast<std::int64_t>(std::llround(v*polygon_scale));}
cp::Path64 path(std::span<const Vec3> points){cp::Path64 out;out.reserve(points.size());for(auto p:points){valid_point(p);out.emplace_back(quantize(p.x),quantize(p.y));}return out;}
std::size_t vertices(const cp::Paths64& paths){std::size_t n=0;for(const auto& p:paths)n+=p.size();return n;}
std::uint64_t polygon_cost(std::size_t n){if(n>65536)throw std::runtime_error("Fit polygon complexity exceeds admission limit.");return std::uint64_t(n)*n+1;}
void admit_round_inset(cp::Paths64& paths,double radius,std::size_t subject_vertices,Budget& budget){
    // Mirror the pinned ClipperOffset::Group / OffsetPoint / DoRound branches,
    // before InflatePaths allocates its tessellated join paths. This admits raw
    // join output, not every internal allocation in Clipper's finishing union.
    cp::Point64 lowest(INT64_MAX,INT64_MIN);bool reversed=false;
    for(auto& p:paths){
        budget.charge(p.size());cp::StripDuplicates(p,true);
        budget.charge(p.size());const double area=cp::Area(p);
        if(p.size()<3||area==0)throw std::runtime_error("Fit offset preflight requires nondegenerate closed support outlines.");
        for(const auto& point:p){budget.charge();
            if(point.y>lowest.y||(point.y==lowest.y&&point.x<lowest.x)){lowest=point;reversed=area<0;}}
    }
    const double delta=reversed?radius:-radius;
    // Exactly the requested ceil(mm * 1000) radius and the existing 0.25
    // integer-unit arc tolerance; admission never reduces physical clearance.
    const double steps_per_radian=std::min(pi/std::acos(1-std::min(radius,0.25)/radius),radius*pi)/(2*pi);
    const auto normal=[](const cp::Point64& a,const cp::Point64& b){
        const double dx=static_cast<double>(b.x-a.x),dy=static_cast<double>(b.y-a.y);
        const double inverse=1/std::sqrt(dx*dx+dy*dy);return cp::PointD(dy*inverse,-dx*inverse);
    };
    std::size_t generated=0;
    for(const auto& p:paths)for(std::size_t j=0,k=p.size()-1;j<p.size();k=j++){
        budget.charge();const auto current=normal(p[j],p[(j+1)%p.size()]),previous=normal(p[k],p[j]);
        const double sine=std::clamp(cp::CrossProduct(current,previous),-1.0,1.0),cosine=cp::DotProduct(current,previous);
        double count=3; // Inward convex joins use three points, then union cleanup.
        if(!(cosine>-.999&&sine*delta<0)){
            // DoRound emits max(1, ceil(steps * angle)) + 1 vertices. Reserve
            // one additional vertex against a floating-point ceil boundary.
            count=std::max(1.0,std::ceil(steps_per_radian*std::abs(std::atan2(sine,cosine))))+2;
        }
        if(!std::isfinite(count)||count>static_cast<double>(65536-generated))
            throw std::runtime_error("Fit offset preflight exceeds generated-join vertex admission limit.");
        generated+=static_cast<std::size_t>(count);
    }
    if(subject_vertices>65536-generated)
        throw std::runtime_error("Fit offset preflight exceeds polygon vertex admission limit.");
    budget.charge(generated);
    if(polygon_cost(generated+subject_vertices)>budget.limit-budget.used)
        throw std::runtime_error("Fit offset preflight exceeds remaining polygon work admission limit.");
}
bool contained(std::span<const Vec3> footprint,const cp::Paths64& support,double inset,Budget& budget){
    const auto subject=path(footprint);
    if(subject.size()<3||std::abs(cp::Area(subject))<1)return false;
    budget.charge(polygon_cost(vertices(support)+subject.size()));
    auto allowed=support;
    // Round joins preserve the requested Euclidean distance at concave boundaries.
    if(inset>0){const double radius=std::ceil(inset*polygon_scale);admit_round_inset(allowed,radius,subject.size(),budget);
        allowed=cp::InflatePaths(allowed,-radius,cp::JoinType::Round,cp::EndType::Polygon,2.0,0.25);}
    budget.charge(polygon_cost(vertices(allowed)+subject.size()));
    const auto outside=cp::Difference(cp::Paths64{subject},allowed,cp::FillRule::NonZero);
    // No area tolerance: even a single quantized nonzero outside contour rejects.
    return std::none_of(outside.begin(),outside.end(),[](const auto& p){return std::abs(cp::Area(p))>0;});
}
Vec3 local_vector(Vec3 p,double yaw){const double r=std::remainder(yaw,360.0)*pi/180,c=std::cos(r),s=std::sin(r);return {c*p.x+s*p.y,-s*p.x+c*p.y,p.z};}
Vec3 world_vector(Vec3 p,double yaw){return local_vector(p,-yaw);}
Bounds box_bounds(const OrientedBox& box,Vec3 motion={}){Bounds b=empty_bounds();for(int i=0;i<8;++i){const Vec3 v{(i&1?1:-1)*box.half_extents.x,(i&2?1:-1)*box.half_extents.y,(i&4?1:-1)*box.half_extents.z};const auto p=add(box.center,world_vector(v,box.yaw_degrees));include(b,p);include(b,add(p,motion));}return b;}
// Continuous SAT: triangle vs a translating OBB. All separating axes are fixed
// for translation, so their time intervals intersect iff the swept solids meet.
bool triangle_hits(const std::array<Vec3,3>& world,const OrientedBox& box,Vec3 motion,double eps){
    std::array<Vec3,3> v;for(int i=0;i<3;++i)v[i]=local_vector(sub(world[i],box.center),box.yaw_degrees);
    const auto move=local_vector(motion,box.yaw_degrees);
    const Vec3 e0=sub(v[1],v[0]),e1=sub(v[2],v[1]),e2=sub(v[0],v[2]);
    const std::array<Vec3,3> basis{{{1,0,0},{0,1,0},{0,0,1}}};
    std::array<Vec3,13> axes{};axes[0]=basis[0];axes[1]=basis[1];axes[2]=basis[2];axes[3]=cross(e0,e1);
    int n=4;for(auto e:{e0,e1,e2})for(auto b:basis)axes[n++]=cross(e,b);
    double lo=0,hi=1;
    for(auto a:axes){const double norm=std::sqrt(dot(a,a));if(norm<1e-14)continue;a=mul(a,1/norm);
        const double p0=dot(v[0],a),p1=dot(v[1],a),p2=dot(v[2],a);
        const double mn=std::min({p0,p1,p2}),mx=std::max({p0,p1,p2});
        const double r=std::abs(a.x)*box.half_extents.x+std::abs(a.y)*box.half_extents.y+std::abs(a.z)*box.half_extents.z-eps;
        const double d=dot(move,a);
        if(std::abs(d)<1e-14){if(mn>=r||mx<=-r)return false;}
        else {double first=(mn-r)/d,last=(mx+r)/d;if(first>last)std::swap(first,last);lo=std::max(lo,first);hi=std::min(hi,last);if(lo>=hi)return false;}
    }
    return true;
}
bool boxes_overlap(const OrientedBox& a,const OrientedBox& b,double gap,double eps){
    if(std::abs(a.center.z-b.center.z)>=a.half_extents.z+b.half_extents.z-eps)return false;
    for(double yaw:{a.yaw_degrees,b.yaw_degrees})for(Vec3 dir:std::array<Vec3,2>{{{1,0,0},{0,1,0}}}){
        dir=world_vector(dir,yaw);const auto ax=world_vector({1,0,0},a.yaw_degrees),ay=world_vector({0,1,0},a.yaw_degrees);
        const auto bx=world_vector({1,0,0},b.yaw_degrees),by=world_vector({0,1,0},b.yaw_degrees);
        const double ra=std::abs(dot(dir,ax))*a.half_extents.x+std::abs(dot(dir,ay))*a.half_extents.y;
        const double rb=std::abs(dot(dir,bx))*b.half_extents.x+std::abs(dot(dir,by))*b.half_extents.y;
        if(std::abs(dot(sub(a.center,b.center),dir))>=ra+rb+gap-eps)return false;
    }return true;
}
struct TriangleData{std::array<Vec3,3> v;Bounds bounds;std::size_t component{};};
using Component=detail::ReceiverComponent;
struct TreeNode{Bounds bounds;std::size_t begin{},end{},left{},right{};};

}
struct FurniturePlacementQuery::Impl {
    // Must outlive supports and its rebound allocators; Impl never moves.
    detail::RetainedAllocationCounter support_allocations;
    QuerySettings settings;
    QueryDiagnostics stats;
    Bounds bounds=empty_bounds();
    std::vector<TriangleData> triangles;
    std::vector<Component> components;
    struct SupportBin {
        cp::Paths64 paths;
        double minimum_z{INFINITY}, maximum_z{-INFINITY};
    };
    using SupportValue=std::pair<const std::int64_t,SupportBin>;
    using SupportAllocator=detail::RetainedAllocator<SupportValue>;
    std::map<std::int64_t,SupportBin,std::less<std::int64_t>,SupportAllocator> supports{std::less<std::int64_t>{},SupportAllocator{&support_allocations}};
    std::vector<std::size_t> order;
    std::vector<TreeNode> tree;
    QueryRetainedStorage storage;
    Impl()=default;
    Impl(const Impl&)=delete;
    Impl& operator=(const Impl&)=delete;
    Impl(Impl&&)=delete;
    Impl& operator=(Impl&&)=delete;
    QueryRetainedStorage measure_retained() const noexcept;
    bool supports_footprint(const PlacementProbe& p,Budget& budget)const{
        // Settings cap contact tolerance at0.1mm. Quantization plus two guard
        // bins can therefore visit at most205 integer height bins. The common
        // single-bin path allocates nothing here and retains its old work units.
        std::array<const cp::Paths64*,205> eligible{};
        std::size_t count=0,visited=0;
        const double lo=p.support_z-settings.contact_tolerance_mm,hi=p.support_z+settings.contact_tolerance_mm;
        const auto first=quantize(lo)-1,last=quantize(hi)+1;
        for(auto it=supports.lower_bound(first);it!=supports.end()&&it->first<=last;++it){
            if(visited++)budget.charge(); // First bin is covered by containment's existing fixed charge.
            const auto& bin=it->second;
            // Compare differences directly: support_z +/- tolerance can round
            // outward at large admitted coordinates and admit too large a gap.
            if(std::abs(bin.minimum_z-p.support_z)>settings.contact_tolerance_mm||
               std::abs(bin.maximum_z-p.support_z)>settings.contact_tolerance_mm)continue;
            if(count==eligible.size())throw std::runtime_error("Fit height-bin scan exceeds its fixed admission.");
            eligible[count++]=&bin.paths;
        }
        if(count==0){if(visited)budget.charge();return false;}
        if(count==1)return contained(p.footprint_world,*eligible[0],p.edge_clearance_mm,budget);
        budget.charge();
        std::size_t point_count=0,path_count=0;
        for(std::size_t i=0;i<count;++i){
            const auto n=vertices(*eligible[i]);
            if(n>settings.max_support_vertices-point_count)throw std::runtime_error("Fit combined support outline exceeds vertex admission.");
            point_count+=n;path_count+=eligible[i]->size();
        }
        // Admit quadratic polygon work BEFORE any temporary path copies/union.
        budget.charge(polygon_cost(point_count));
        cp::Paths64 joined;joined.reserve(path_count);
        for(std::size_t i=0;i<count;++i)joined.insert(joined.end(),eligible[i]->begin(),eligible[i]->end());
        const auto allowed=cp::Union(joined,cp::FillRule::NonZero);
        if(vertices(allowed)>settings.max_support_vertices)throw std::runtime_error("Fit combined support union exceeds vertex admission.");
        // Union before inset: a numerical height-bin seam is not an outer edge.
        return contained(p.footprint_world,allowed,p.edge_clearance_mm,budget);
    }
    std::size_t build_tree(std::size_t begin,std::size_t end,Budget& budget){
        const auto id=tree.size();tree.emplace_back();Bounds b=empty_bounds();
        for(auto i=begin;i<end;++i){include(b,triangles[order[i]].bounds);budget.charge();}
        tree[id]={b,begin,end,0,0};if(end-begin<=8)return id;
        const auto size=sub(b.max,b.min);const int dimension=size.x>=size.y&&size.x>=size.z?0:size.y>=size.z?1:2;
        const auto middle=begin+(end-begin)/2;
        std::nth_element(order.begin()+begin,order.begin()+middle,order.begin()+end,[&](auto a,auto c){budget.charge();const auto& x=triangles[a].bounds;const auto& y=triangles[c].bounds;const auto v=axis(add(x.min,x.max),dimension),w=axis(add(y.min,y.max),dimension);return v==w?a<c:v<w;});
        const auto left=build_tree(begin,middle,budget),right=build_tree(middle,end,budget);tree[id].left=left;tree[id].right=right;return id;
    }
    template<class F> bool visit(const Bounds& region,Budget& budget,F&& f,std::size_t node=0)const{
        budget.charge();const auto& n=tree[node];if(!overlap(n.bounds,region))return false;
        if(n.left)return visit(region,budget,f,n.left)||visit(region,budget,f,n.right);
        for(auto i=n.begin;i<n.end;++i){budget.charge();const auto& t=triangles[order[i]];if(overlap(t.bounds,region)&&f(t))return true;}return false;
    }
    bool intersects(const OrientedBox& box,Vec3 motion,Budget& budget,FitWitness* witness=nullptr)const{
        const auto broad=box_bounds(box,motion);const double bottom=box.center.z-box.half_extents.z;
        return visit(broad,budget,[&](const TriangleData& t){
            if(t.bounds.max.z<=bottom+settings.contact_tolerance_mm)return false;
            if(!triangle_hits(t.v,box,motion,settings.contact_tolerance_mm))return false;
            if(witness){
                const auto& body=components[t.component];*witness={FitIssue::Occupied,body.body_id,0,body.bounds,true};
                const auto n=cross(sub(t.v[1],t.v[0]),sub(t.v[2],t.v[0]));
                if(n.z< -100*std::hypot(n.x,n.y)&&t.bounds.min.z>bottom+settings.contact_tolerance_mm)witness->issue=FitIssue::Height;
                else if(!body.obstacle){
                    if(std::abs(n.z)<.01*std::hypot(n.x,n.y)){
                        const double a=box.yaw_degrees*pi/180,c=std::cos(a),s=std::sin(a);
                        witness->issue=std::abs(n.x*c+n.y*s)>=std::abs(-n.x*s+n.y*c)?FitIssue::Width:FitIssue::Depth;
                    }
                }
            }
            return true;
        });
    }
    bool inside(Vec3 p,Budget& budget,FitWitness* witness=nullptr)const{
        std::set<std::size_t> possible;
        for(std::size_t i=0;i<components.size();++i){budget.charge();if(components[i].closed&&contains(components[i].bounds,p))possible.insert(i);}
        if(possible.empty())return false;
        std::map<std::size_t,std::vector<double>> crossings;
        const Bounds ray{{p.x,p.y,p.z},{p.x,p.y,bounds.max.z+1}};
        visit(ray,budget,[&](const TriangleData& t){
            if(!possible.contains(t.component))return false;
            const auto a=t.v[0],u=sub(t.v[1],a),v=sub(t.v[2],a);const double den=u.x*v.y-u.y*v.x;
            if(std::abs(den)<1e-14)return false;
            const double x=p.x-a.x,y=p.y-a.y,s=(x*v.y-y*v.x)/den,r=(u.x*y-u.y*x)/den;
            if(s<-1e-10||r<-1e-10||s+r>1+1e-10)return false;
            const double z=a.z+s*u.z+r*v.z;if(z>p.z+settings.contact_tolerance_mm)crossings[t.component].push_back(z);
            return false;
        });
        for(auto& [id,hits]:crossings){budget.charge(hits.size());std::sort(hits.begin(),hits.end());std::size_t n=0;double last=-INFINITY;for(auto z:hits)if(z-last>settings.contact_tolerance_mm){++n;last=z;}if(n%2){if(witness)*witness={FitIssue::Occupied,components[id].body_id,0,components[id].bounds,true};return true;}}return false;
    }
};

QueryRetainedStorage FurniturePlacementQuery::Impl::measure_retained() const noexcept {
    QueryRetainedStorage out;out.complete=support_allocations.complete;
#if defined(_MSC_VER) && defined(_ITERATOR_DEBUG_LEVEL) && _ITERATOR_DEBUG_LEVEL != 0
    // Plain vector iterator-debug proxies are not routed through our map allocator.
    // Retention stays optional: do not advertise complete accounting in this mode.
    out.complete=false;
#endif
    out.wrapper_bytes=sizeof(FurniturePlacementQuery);out.implementation_bytes=sizeof(Impl);
    out.tracking_state_bytes=sizeof(support_allocations);out.support_map_bytes=support_allocations.live_bytes;
    out.support_map_allocations=support_allocations.live_allocations;
    out.triangle_capacity=triangles.capacity();out.component_capacity=components.capacity();
    out.order_capacity=order.capacity();out.tree_capacity=tree.capacity();
    const auto product=[&](std::size_t n,std::size_t element_size,std::size_t& bytes){
        if(!detail::checked_product(n,element_size,bytes))out.complete=false;
    };
    const auto add=[&](std::size_t& total,std::size_t value){if(!detail::checked_add(total,value))out.complete=false;};
    product(out.triangle_capacity,sizeof(TriangleData),out.triangle_bytes);
    product(out.component_capacity,sizeof(Component),out.component_bytes);
    product(out.order_capacity,sizeof(std::size_t),out.order_bytes);
    product(out.tree_capacity,sizeof(TreeNode),out.tree_bytes);
    for(const auto& [height,bin]:supports){(void)height;const auto& paths=bin.paths;
        add(out.support_path_count,paths.size());add(out.support_path_capacity,paths.capacity());
        std::size_t bytes{};product(paths.capacity(),sizeof(cp::Path64),bytes);add(out.support_path_objects_bytes,bytes);
        for(const auto& p:paths){add(out.support_point_count,p.size());add(out.support_point_capacity,p.capacity());
            product(p.capacity(),sizeof(cp::Point64),bytes);add(out.support_point_bytes,bytes);}
    }
    for(const auto bytes:{out.wrapper_bytes,out.implementation_bytes,out.triangle_bytes,out.component_bytes,
        out.order_bytes,out.tree_bytes,out.support_map_bytes,out.support_path_objects_bytes,out.support_point_bytes})add(out.accounted_bytes,bytes);
    return out;
}

FurniturePlacementQuery::FurniturePlacementQuery(std::span<const FurnitureBody> bodies,const QuerySettings& settings,std::span<const FurnitureBody> obstacle_bodies):impl_(std::make_unique<Impl>()){
    if((bodies.empty()&&settings.require_support)||bodies.size()>4096||obstacle_bodies.size()>4096-bodies.size()||!settings.max_triangles||settings.max_triangles>1000000||!settings.max_vertices||settings.max_vertices>3000000||!settings.max_build_work||settings.max_build_work>200000000||!settings.max_support_vertices||settings.max_support_vertices>32768||!std::isfinite(settings.contact_tolerance_mm)||settings.contact_tolerance_mm<0.001||settings.contact_tolerance_mm>0.1)
        throw std::invalid_argument("Invalid furniture fit settings or body count.");
    auto& out=*impl_;out.settings=settings;out.settings.front_direction=normalized_front(settings.front_direction);Budget budget{0,settings.max_build_work};
    std::set<std::uint64_t> ids;
    std::size_t triangle_count=0,vertex_count=0;
    // Admit both complete scopes before any per-mesh welding/topology buffers.
    for(const auto scope:{bodies,obstacle_bodies})for(const auto& body:scope){
        budget.charge();
        if(!body.id||!ids.insert(body.id).second||body.mesh.triangles.empty()||
           body.mesh.triangles.size()>settings.max_triangles-triangle_count||
           body.mesh.vertices.size()>settings.max_vertices-vertex_count)
            throw std::invalid_argument("Invalid/duplicate body identity or aggregate furniture/obstacle geometry limit exceeded.");
        triangle_count+=body.mesh.triangles.size();vertex_count+=body.mesh.vertices.size();
    }
    out.triangles.reserve(triangle_count);
    const auto capture=[&](std::span<const FurnitureBody> scope,bool contributes_support){for(const auto& body:scope){
        const auto start=out.triangles.size();
        const auto topology=detail::append_receiver_topology(body.mesh,out.components,body.id,!contributes_support,max_coordinate,budget.limit-budget.used);budget.charge(topology.work);
        for(std::size_t i=0;i<body.mesh.triangles.size();++i){
            const auto component=topology.face_components[i];if(component==detail::no_receiver_component)continue;
            const auto& face=body.mesh.triangles[i];TriangleData t{};t.bounds=empty_bounds();t.component=component;
            for(int k=0;k<3;++k){budget.charge();t.v[k]=body.mesh.vertices[face.vertices[k]];include(t.bounds,t.v[k]);}
            const auto normal=cross(sub(t.v[1],t.v[0]),sub(t.v[2],t.v[0]));
            include(out.bounds,t.bounds);out.triangles.push_back(t);
            if(contributes_support&&normal.z>0&&t.bounds.max.z-t.bounds.min.z<=settings.contact_tolerance_mm){
                auto& bin=out.supports[quantize((t.bounds.min.z+t.bounds.max.z)/2)];
                bin.paths.push_back(path(t.v));bin.minimum_z=std::min(bin.minimum_z,t.bounds.min.z);bin.maximum_z=std::max(bin.maximum_z,t.bounds.max.z);
            }
        }
        if(out.triangles.size()==start)throw std::invalid_argument("Furniture/obstacle body has no nondegenerate triangles.");
    }};
    capture(bodies,true);capture(obstacle_bodies,false);
    for(auto& [height,bin]:out.supports){auto& polygons=bin.paths;budget.charge(polygon_cost(vertices(polygons)));polygons=cp::Union(polygons,cp::FillRule::NonZero);out.stats.support_vertices+=vertices(polygons);if(out.stats.support_vertices>settings.max_support_vertices)throw std::runtime_error("Furniture support outline exceeds vertex budget.");}
    out.order.resize(out.triangles.size());std::iota(out.order.begin(),out.order.end(),0);out.tree.reserve(out.triangles.size()*2);if(!out.triangles.empty())out.build_tree(0,out.order.size(),budget);
    out.stats.bodies=bodies.size()+obstacle_bodies.size();out.stats.support_bodies=bodies.size();out.stats.obstacle_bodies=obstacle_bodies.size();out.stats.vertices=vertex_count;
    out.stats.triangles=out.triangles.size();out.stats.support_planes=out.supports.size();out.stats.build_work=budget.used;
    for(const auto& c:out.components)++(c.closed?out.stats.closed_components:out.stats.open_components);
    out.storage=out.measure_retained();
}
FurniturePlacementQuery::~FurniturePlacementQuery()=default;
FurniturePlacementQuery::FurniturePlacementQuery(FurniturePlacementQuery&&)noexcept=default;
FurniturePlacementQuery& FurniturePlacementQuery::operator=(FurniturePlacementQuery&&)noexcept=default;
QueryDiagnostics FurniturePlacementQuery::diagnostics()const{return impl_->stats;}
QueryRetainedStorage FurniturePlacementQuery::retained_storage()const noexcept{
    if(impl_)return impl_->storage;
    QueryRetainedStorage out;out.wrapper_bytes=out.accounted_bytes=sizeof(FurniturePlacementQuery);return out;
}
SupportCenterHint FurniturePlacementQuery::support_center(Vec3 near,std::uint64_t remaining_work)const{
    valid_point(near);const auto& out=*impl_;SupportCenterHint hint;
    if(!out.settings.require_support)return hint;
    const auto limit=std::min<std::uint64_t>(remaining_work,200000);
    const auto spend=[&](std::uint64_t n){if(n>limit-hint.work_units){if(remaining_work<200000)throw std::runtime_error("Support-center proposal exceeds the remaining Arrange work budget; previous arrangement retained.");hint.center.reset();hint.limited=true;return false;}hint.work_units+=n;return true;};
    const auto first=quantize(near.z-out.settings.contact_tolerance_mm)-1,last=quantize(near.z+out.settings.contact_tolerance_mm)+1;
    double distance=INFINITY;
    for(auto it=out.supports.lower_bound(first);it!=out.supports.end()&&it->first<=last;++it){
        if(!spend(1))return hint;const auto& bin=it->second;
        if(std::abs(bin.minimum_z-near.z)>out.settings.contact_tolerance_mm||std::abs(bin.maximum_z-near.z)>out.settings.contact_tolerance_mm)continue;
        for(const auto& polygon:bin.paths){
            if(!spend(polygon.size()*4+1))return hint;
            double area=0;Bounds b=empty_bounds();
            const auto origin=polygon.front();
            for(std::size_t i=0;i<polygon.size();++i){const auto p=polygon[i],q=polygon[(i+1)%polygon.size()];area+=static_cast<double>(p.x-origin.x)*(q.y-origin.y)-static_cast<double>(p.y-origin.y)*(q.x-origin.x);include(b,Vec3{p.x/polygon_scale,p.y/polygon_scale,near.z});}
            if(area<=0)continue; // Union holes do not propose centers.
            const Vec3 center{(b.min.x+b.max.x)*.5,(b.min.y+b.max.y)*.5,near.z};const double d=std::hypot(center.x-near.x,center.y-near.y);
            if(d<distance){distance=d;hint.center=center;}
        }
    }
    return hint;
}
QueryResult FurniturePlacementQuery::validate(const PlacementProbe& p)const{
    const auto& out=*impl_;Budget budget{0,p.remaining_work};
    const auto front=p.front_direction_override?normalized_front(*p.front_direction_override):out.settings.front_direction;
    valid_point(p.collision.center);valid_point(p.collision.half_extents);
    if(!std::isfinite(p.collision.yaw_degrees)||p.collision.half_extents.x<=0||p.collision.half_extents.y<=0||p.collision.half_extents.z<=0||p.footprint_world.size()<3||p.footprint_world.size()>64||p.parent_support_world.size()>64||p.accepted.size()>10000||!std::isfinite(p.support_z)||!std::isfinite(p.edge_clearance_mm)||!std::isfinite(p.spacing_mm)||p.edge_clearance_mm<0||p.spacing_mm<0||p.edge_clearance_mm>1000000||p.spacing_mm>1000000)throw std::invalid_argument("Invalid placement fit probe.");
    validate_collision_pose(p.collision,p.collider);
    // Bound the plane before height-bin quantization, including finite values
    // whose scaled magnitude would exceed llround's representable domain.
    valid_point({0,0,p.support_z});
    if(p.same_group_spacing&&(!p.same_group_spacing->group_id||p.support_parent_id||
        !std::isfinite(p.same_group_spacing->gap_mm)||p.same_group_spacing->gap_mm<0||p.same_group_spacing->gap_mm>1000000))
        throw std::invalid_argument("Invalid same-group spacing descriptor; composition members cannot be stack children.");
    for(auto point:p.footprint_world)if(std::abs(point.z-p.support_z)>0.001)throw std::invalid_argument("Placement footprint must be planar at support height.");
    FitWitness witness;
    const auto result=[&](Rejection reason,FitIssue issue=FitIssue::None){if(issue!=FitIssue::None)witness.issue=issue;return QueryResult{reason,budget.used,witness};};
    if(p.support_parent_id){
        if(p.parent_support_world.empty())return result(Rejection::Stack,FitIssue::Stack);
        for(auto point:p.parent_support_world)if(std::abs(point.z-p.support_z)>0.001)return result(Rejection::Stack,FitIssue::Stack);
        if(!contained(p.footprint_world,cp::Paths64{path(p.parent_support_world)},p.edge_clearance_mm,budget))return result(Rejection::Stack,FitIssue::Stack);
    }else if(out.settings.require_support){
        if(!out.supports_footprint(p,budget))return result(Rejection::Boundary,FitIssue::Support);
    }
    if(p.collision.center.z-p.collision.half_extents.z<p.support_z-out.settings.contact_tolerance_mm)return result(Rejection::Unsupported,FitIssue::Support);
    const auto static_hit=[&](Vec3 motion,bool inside){
        FitWitness hit;
        if(out.triangles.empty()||!(out.intersects(p.collision,motion,budget,&hit)||(inside&&out.inside(p.collision.center,budget,&hit))))return false;
        if(!p.collider.source){witness=hit;return true;}
        const auto shape=p.collider.source->proxy(budget.limit-budget.used);budget.charge(shape.build_work);
        for(const auto& local:shape.pieces){budget.charge();const auto box=collision_piece(p.collider,local,out.settings.contact_tolerance_mm);if(out.intersects(box,motion,budget,&hit)||(inside&&out.inside(box.center,budget,&hit))){witness=hit;return true;}}return false;
    };
    if(static_hit({},true))return result(Rejection::Obstacle);
    for(const auto& other:p.accepted){budget.charge();const bool parent=other.stable_id==p.support_parent_id;
        validate_collision_pose(other.box,other.collider);
        const auto refined_hit=[&](double gap){if(!p.collider.source&&!other.collider.source)return true;const auto hit=collision_overlap(p.collision,p.collider,other.box,other.collider,gap,out.settings.contact_tolerance_mm,budget.limit-budget.used);budget.charge(hit.work);return hit.overlaps;};
        if(boxes_overlap(p.collision,other.box,0,out.settings.contact_tolerance_mm)&&refined_hit(0)){witness={FitIssue::Occupied,0,other.stable_id,box_bounds(other.box,{}),true};return result(Rejection::Obstacle);}
        const double gap=p.same_group_spacing&&p.same_group_spacing->group_id==other.composition_group_id?
            p.same_group_spacing->gap_mm:p.spacing_mm;
        if(!parent&&gap>0&&boxes_overlap(p.collision,other.box,gap,out.settings.contact_tolerance_mm)&&refined_hit(gap)){witness={FitIssue::Spacing,0,other.stable_id,box_bounds(other.box,{}),true};return result(Rejection::Spacing);}
    }
    if(out.settings.require_front_access&&!out.triangles.empty()){
        const double distance=std::hypot(out.bounds.max.x-out.bounds.min.x,out.bounds.max.y-out.bounds.min.y)+2*std::hypot(p.collision.half_extents.x,p.collision.half_extents.y)+1;
        if(static_hit(mul(front,distance),false))return result(Rejection::Obstacle,FitIssue::Access);
    }
    return result(Rejection::None);
}
}
