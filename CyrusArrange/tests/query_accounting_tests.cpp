#include "cyrus_arrange/placement_queries.h"
#include "query_retained_allocator.h"
#include <clipper2/clipper.h>
#include <array>
#include <cstdlib>
#include <filesystem>
#include <fstream>
#include <functional>
#include <iostream>
#include <limits>
#include <map>
#include <memory>
#include <new>
#include <set>
#include <sstream>
#include <stdexcept>
#include <tuple>
#include <utility>
#ifdef _WIN32
#include <malloc.h>
#endif

// Test-executable-only allocation tracing/fault injection. No product hook or
// host SDK is involved; query construction/destruction runs on this one thread.
namespace allocation_test {
std::size_t live{},attempts{},failure_index=std::numeric_limits<std::size_t>::max();
bool armed{};
void before(){if(armed&&attempts++==failure_index)throw std::bad_alloc();}
void* allocate(std::size_t bytes){before();if(auto* p=std::malloc(bytes?bytes:1)){++live;return p;}throw std::bad_alloc();}
void release(void* p)noexcept{if(p){--live;std::free(p);}}
void* aligned_allocate(std::size_t bytes,std::size_t alignment){
    before();
#ifdef _WIN32
    auto* p=_aligned_malloc(bytes?bytes:1,alignment);
#else
    if(bytes>std::numeric_limits<std::size_t>::max()-(alignment-1))throw std::bad_alloc();
    auto* p=std::aligned_alloc(alignment,((bytes?bytes:1)+alignment-1)/alignment*alignment);
#endif
    if(!p)throw std::bad_alloc();++live;return p;
}
void aligned_release(void* p)noexcept{if(p){--live;
#ifdef _WIN32
    _aligned_free(p);
#else
    std::free(p);
#endif
}}
struct FaultScope {
    explicit FaultScope(std::size_t index){attempts=0;failure_index=index;armed=true;}
    ~FaultScope(){armed=false;}
};
}
void* operator new(std::size_t bytes){return allocation_test::allocate(bytes);}
void operator delete(void* p)noexcept{allocation_test::release(p);}
void operator delete(void* p,std::size_t)noexcept{::operator delete(p);}
void* operator new[](std::size_t bytes){return ::operator new(bytes);}
void operator delete[](void* p)noexcept{::operator delete(p);}
void operator delete[](void* p,std::size_t)noexcept{::operator delete(p);}
void* operator new(std::size_t bytes,std::align_val_t alignment){return allocation_test::aligned_allocate(bytes,static_cast<std::size_t>(alignment));}
void* operator new[](std::size_t bytes,std::align_val_t alignment){return ::operator new(bytes,alignment);}
void operator delete(void* p,std::align_val_t)noexcept{allocation_test::aligned_release(p);}
void operator delete[](void* p,std::align_val_t alignment)noexcept{::operator delete(p,alignment);}
void operator delete(void* p,std::size_t,std::align_val_t alignment)noexcept{::operator delete(p,alignment);}
void operator delete[](void* p,std::size_t,std::align_val_t alignment)noexcept{::operator delete(p,alignment);}

using namespace cyrus::arrange;
namespace {
void check(bool value,const char* message){if(!value)throw std::runtime_error(message);}
Mesh box(double x0,double y0,double z0,double x1,double y1,double z1){
    Mesh m;m.vertices={{x0,y0,z0},{x1,y0,z0},{x1,y1,z0},{x0,y1,z0},{x0,y0,z1},{x1,y0,z1},{x1,y1,z1},{x0,y1,z1}};
    m.triangles={{{0,2,1}},{{0,3,2}},{{4,5,6}},{{4,6,7}},{{0,1,5}},{{0,5,4}},{{1,2,6}},{{1,6,5}},{{2,3,7}},{{2,7,6}},{{3,0,4}},{{3,4,7}}};return m;
}
void plane(Mesh& m,double x0,double y0,double x1,double y1,double z){
    const auto i=static_cast<std::uint32_t>(m.vertices.size());m.vertices.insert(m.vertices.end(),{{x0,y0,z},{x1,y0,z},{x1,y1,z},{x0,y1,z}});
    m.triangles.push_back({{i,i+1,i+2}});m.triangles.push_back({{i,i+2,i+3}});
}
auto fields(const QueryRetainedStorage& s){return std::tie(s.accounted_bytes,s.wrapper_bytes,s.implementation_bytes,
    s.triangle_bytes,s.component_bytes,s.order_bytes,s.tree_bytes,s.support_map_bytes,s.support_path_objects_bytes,s.support_point_bytes,
    s.support_map_allocations,s.triangle_capacity,s.component_capacity,s.order_capacity,s.tree_capacity,
    s.support_path_count,s.support_path_capacity,s.support_point_count,s.support_point_capacity,s.tracking_state_bytes,s.complete);}
void checked_arithmetic(){
    const auto max=std::numeric_limits<std::size_t>::max();std::size_t value=max-1;
    check(detail::checked_add(value,1)&&value==max,"Exact final byte is admitted");
    check(!detail::checked_add(value,1)&&value==max,"Addition overflow fails without wrapping");
    check(detail::checked_product(max,1,value)&&value==max,"Exact product is admitted");
    check(!detail::checked_product(max,2,value)&&value==0,"Product overflow is explicit, not a wrapped retained size");
    check(detail::checked_product(max,0,value)&&value==0,"Zero-sized product is safe");
}
void allocator_requests_and_lifetime(){
    detail::RetainedAllocationCounter counter;
    using Value=std::pair<const int,std::vector<int>>;
    using Allocator=detail::RetainedAllocator<Value>;
    {
        std::map<int,std::vector<int>,std::less<int>,Allocator> map{std::less<int>{},Allocator{&counter}};
        const auto empty_bytes=counter.live_bytes,empty_blocks=counter.live_allocations;
        map.emplace(1,std::vector<int>(100,1));const auto node_bytes=counter.live_bytes-empty_bytes;
        check(counter.complete&&node_bytes>sizeof(Value),"Rebound map node request includes actual linkage/padding, not sizeof(value_type)");
        check(counter.live_allocations==empty_blocks+1,"First map element is one additional retained node request on the pinned standard library");
        map.emplace(2,std::vector<int>(200,2));
        check(counter.live_bytes==empty_bytes+2*node_bytes&&counter.live_allocations==empty_blocks+2,"Identical actual rebound nodes have identical retained requested bytes");
        map.clear();check(counter.live_bytes==empty_bytes&&counter.live_allocations==empty_blocks,"Clear releases all element nodes while retaining the library's empty-map storage");
    }
    check(counter.complete&&counter.live_bytes==0&&counter.live_allocations==0,"Map destruction deallocates its sentinel/proxy and nodes before the embedded counter dies");
    struct alignas(64) Wide{std::byte value[64];};
    using Rebound=std::allocator_traits<Allocator>::rebind_alloc<Wide>;
    Rebound wide{Allocator{&counter}};Wide* p=wide.allocate(3);
    check(counter.live_bytes==3*sizeof(Wide)&&counter.live_allocations==1,"Allocator rebinding counts the allocated type and requested element count");
    check(reinterpret_cast<std::uintptr_t>(p)%alignof(Wide)==0,"Rebinding preserves over-aligned allocation semantics");
    wide.deallocate(p,3);check(counter.live_bytes==0&&counter.live_allocations==0,"Rebound allocation releases exactly its request");
}
void overflow_and_failed_allocation(){
    detail::RetainedAllocationCounter counter;detail::RetainedAllocator<std::uint64_t> allocator{&counter};
    auto* p=allocator.allocate(2);const auto bytes=counter.live_bytes,blocks=counter.live_allocations;bool failed=false;
    try{auto* invalid=allocator.allocate(std::numeric_limits<std::size_t>::max());allocator.deallocate(invalid,std::numeric_limits<std::size_t>::max());}
    catch(const std::bad_array_new_length&){failed=true;}
    check(failed&&counter.complete&&counter.live_bytes==bytes&&counter.live_allocations==blocks,"Invalid allocation size fails before allocation and leaves prior accounting unchanged");
    allocator.deallocate(p,2);check(counter.live_bytes==0&&counter.live_allocations==0,"Prior live allocation remains releasable after a failed request");
    detail::RetainedAllocationCounter overflow;overflow.allocated(std::numeric_limits<std::size_t>::max());overflow.allocated(1);
    check(!overflow.complete&&overflow.live_bytes==std::numeric_limits<std::size_t>::max(),"Synthetic accounting overflow latches incomplete without wrapping or throwing");
    overflow.deallocated(1);check(!overflow.complete,"Incomplete accounting is sticky and cannot accidentally become admissible");
    detail::RetainedAllocationCounter underflow;underflow.allocated(4);underflow.deallocated(5);
    check(!underflow.complete&&underflow.live_bytes==4,"Mismatched accounting cannot underflow into apparently valid retained bytes");
    detail::RetainedAllocationCounter blocks_overflow;blocks_overflow.live_allocations=std::numeric_limits<std::size_t>::max();blocks_overflow.allocated(0);
    check(!blocks_overflow.complete&&blocks_overflow.live_allocations==std::numeric_limits<std::size_t>::max()&&blocks_overflow.live_bytes==0,
        "Allocation-count saturation is independently sticky and cannot wrap into a valid block count");
}
void snapshot_breakdown_and_capacities(){
    std::vector<FurnitureBody> supports{{1,box(0,0,-5,100,100,0)}},obstacles{{2,box(200,0,0,220,20,30)}};
    QuerySettings settings;settings.require_front_access=false;FurniturePlacementQuery q(supports,settings,obstacles);
    const auto d=q.diagnostics();const auto s=q.retained_storage();
    check(s.complete&&s.wrapper_bytes==sizeof(FurniturePlacementQuery)&&s.implementation_bytes>0,"Complete snapshot counts wrapper and allocated Impl separately");
    std::size_t expected=0;for(auto n:{s.wrapper_bytes,s.implementation_bytes,s.triangle_bytes,s.component_bytes,s.order_bytes,s.tree_bytes,
        s.support_map_bytes,s.support_path_objects_bytes,s.support_point_bytes})check(detail::checked_add(expected,n),"Fixture sum cannot overflow");
    check(expected==s.accounted_bytes&&s.tracking_state_bytes==sizeof(detail::RetainedAllocationCounter)&&s.tracking_state_bytes<s.implementation_bytes,
        "Retained components sum exactly; embedded tracking bytes are an informational subset, never added twice");
    check(d.triangles==24&&s.triangle_capacity>=24&&s.order_capacity>=24&&s.tree_capacity>=48,"Counts include both scopes and all reserved BVH capacity, not just populated nodes");
    check(s.component_capacity>=2&&s.component_bytes>=2*sizeof(Bounds),"Connected-component vector capacity is retained storage");
    check(s.support_path_count==1&&s.support_point_count==4&&s.support_path_capacity>=1&&s.support_point_capacity>=4,"Only the support plate contributes retained support paths/points");
    check(s.support_path_objects_bytes==s.support_path_capacity*sizeof(Clipper2Lib::Path64)&&
        s.support_point_bytes==s.support_point_capacity*sizeof(Clipper2Lib::Point64),"Nested vector object and point allocations count actual capacities, not sizes");
    check(s.support_map_allocations>=d.support_planes&&s.support_map_bytes>=d.support_planes*sizeof(std::pair<const std::int64_t,Clipper2Lib::Paths64>),
        "Support map separately reports allocator-requested retained allocations including node overhead");
    check(s.order_bytes==s.order_capacity*sizeof(std::size_t),"Order storage uses allocated index capacity");
    supports.clear();obstacles.clear();check(fields(q.retained_storage())==fields(s),"Source body buffers are independent and never included in the query's retained snapshot");
    std::cout<<"ACCOUNTED_QUERY_BYTES="<<s.accounted_bytes<<" MAP_BYTES="<<s.support_map_bytes<<" MAP_REQUESTS="<<s.support_map_allocations<<'\n';
}
void passive_probe_and_empty_support(){
    const std::vector<FurnitureBody> bodies{{1,box(0,0,-5,100,100,0)}};QuerySettings settings;settings.require_front_access=false;FurniturePlacementQuery q(bodies,settings);
    const std::vector<Vec3> footprint{{40,40,0},{60,40,0},{60,60,0},{40,60,0}};
    PlacementProbe probe{footprint,{{50,50,10},{10,10,10},0},0,1,{},0,{},5,10,50000000};
    const auto before=q.retained_storage();const auto result=q.validate(probe);const auto build_work=q.diagnostics().build_work;
    for(int i=0;i<100;++i)check(fields(q.retained_storage())==fields(before),"Passive getter returns unchanged immutable storage");
    const auto repeated=q.validate(probe);check(result.reason==Rejection::None&&repeated.reason==result.reason&&repeated.work_units==result.work_units&&q.diagnostics().build_work==build_work,
        "Reading retained bytes never changes geometry, fit work or historical build-work counters");
    check(fields(q.retained_storage())==fields(before),"Per-probe temporary polygons/maps are excluded from retained bytes");
    Mesh wall;wall.vertices={{0,0,0},{100,0,0},{100,0,100},{0,0,100}};wall.triangles={{{0,1,2}},{{0,2,3}}};
    const std::vector<FurnitureBody> walls{{3,wall}};FurniturePlacementQuery no_support(walls,settings);const auto empty=no_support.retained_storage();
    check(empty.complete&&no_support.diagnostics().support_planes==0&&empty.support_path_count==0&&empty.support_point_count==0&&empty.support_path_objects_bytes==0&&empty.support_point_bytes==0,
        "A valid query without horizontal supports still accounts empty-map storage and all other retained allocations");
}
void moves_and_lease_lifetime(){
    const std::vector<FurnitureBody> bodies{{1,box(0,0,-5,100,100,0)}};QuerySettings settings;settings.require_front_access=false;
    FurniturePlacementQuery first(bodies,settings);const auto expected=first.retained_storage();
    FurniturePlacementQuery second(std::move(first));check(fields(second.retained_storage())==fields(expected),"Moving the unique Impl preserves embedded allocator counter addresses and snapshot");
    const auto moved=first.retained_storage();check(!moved.complete&&moved.accounted_bytes==sizeof(FurniturePlacementQuery)&&moved.implementation_bytes==0,"Moved-from query is safely incomplete and reports wrapper-only storage");
    FurniturePlacementQuery third(bodies,settings);third=std::move(second);check(fields(third.retained_storage())==fields(expected)&&!second.retained_storage().complete,"Move assignment releases the old Impl and transfers the immutable storage without rebinding its counter");
    auto owner=std::make_shared<const FurniturePlacementQuery>(std::move(third));std::weak_ptr<const FurniturePlacementQuery> weak=owner;auto lease=owner;owner.reset();
    check(!weak.expired()&&fields(lease->retained_storage())==fields(expected),"An active numeric lease owns storage after cache ownership is dropped");
    lease.reset();check(weak.expired(),"Final lease release destroys the complete query without an external counter/control-block dependency");
}
void multiple_planes_paths_and_hole(){
    Mesh ring;plane(ring,-50,-50,-10,50,0);plane(ring,10,-50,50,50,0);plane(ring,-10,-50,10,-10,0);plane(ring,-10,10,10,50,0);
    Mesh island;plane(island,100,0,120,20,0);Mesh upper;plane(upper,0,0,20,20,50);
    const std::vector<FurnitureBody> bodies{{1,ring},{2,island},{3,upper}};QuerySettings settings;settings.require_front_access=false;
    FurniturePlacementQuery q(bodies,settings);const auto s=q.retained_storage();const auto d=q.diagnostics();
    using Point=std::pair<std::int64_t,std::int64_t>;using Points=std::set<Point>;using Polygons=std::multiset<Points>;
    const std::map<std::int64_t,Polygons> expected{
        {0,{
            {{-50000,-50000},{-10000,-50000},{10000,-50000},{50000,-50000},{50000,50000},{10000,50000},{-10000,50000},{-50000,50000}},
            {{-10000,-10000},{-10000,10000},{10000,10000},{10000,-10000}},
            {{100000,0},{120000,0},{120000,20000},{100000,20000}}}},
        {50,{{{0,0},{20000,0},{20000,20000},{0,20000}}}}};
    std::map<std::int64_t,Clipper2Lib::Paths64> inputs;
    for(const auto& body:bodies)for(const auto& triangle:body.mesh.triangles){Clipper2Lib::Path64 path;
        for(auto index:triangle.vertices){const auto& point=body.mesh.vertices[index];path.emplace_back(static_cast<std::int64_t>(point.x*1000),static_cast<std::int64_t>(point.y*1000));}
        inputs[static_cast<std::int64_t>(body.mesh.vertices[triangle.vertices[0]].z)].push_back(std::move(path));}
    std::map<std::int64_t,Polygons> actual;
    for(const auto& [height,paths]:inputs)for(const auto& path:Clipper2Lib::Union(paths,Clipper2Lib::FillRule::NonZero)){
        Points points;for(const auto& point:path)points.emplace(point.x,point.y);actual[height].insert(std::move(points));}
    check(actual==expected,"Independent polygon point sets include the ring's four retained collinear seam corners, hole, island and upper rectangle");
    check(s.complete&&d.support_planes==2&&d.support_vertices==20&&s.support_path_count==4&&s.support_point_count==20,
        "Known support polygons yield two planes, four outer/inner paths and twenty retained vertices");
    check(s.support_path_capacity>=4&&s.support_point_capacity>=20&&s.support_path_objects_bytes==s.support_path_capacity*sizeof(Clipper2Lib::Path64)&&
        s.support_point_bytes==s.support_point_capacity*sizeof(Clipper2Lib::Point64),"Accounting visits every plane and hole/island path, including unused capacity");
    std::size_t sum=0;for(auto bytes:{s.wrapper_bytes,s.implementation_bytes,s.triangle_bytes,s.component_bytes,s.order_bytes,s.tree_bytes,
        s.support_map_bytes,s.support_path_objects_bytes,s.support_point_bytes})check(detail::checked_add(sum,bytes),"Small fixture total is representable");
    check(sum==s.accounted_bytes&&s.support_map_allocations>=2,"Multi-plane map storage and all dynamic arrays enter the retained total exactly once");
}
void clipper_failed_append_preserves_previous(){
    const Clipper2Lib::Paths64 previous{{{0,0},{20,0},{20,20},{0,20}}};
    const Clipper2Lib::Paths64 incoming{{{100,0},{120,0},{120,20},{100,20}},{{200,0},{220,0},{220,20},{200,20}}};
    std::size_t attempts=0;
    {Clipper2Lib::Clipper64 clipper;clipper.AddSubject(previous);allocation_test::FaultScope trace(std::numeric_limits<std::size_t>::max());
        clipper.AddSubject(incoming);attempts=allocation_test::attempts;}
    check(attempts>2&&attempts<=64,"Small direct AddPaths failure sweep has a fixed bounded allocation count");
    const auto baseline=allocation_test::live;
    for(std::size_t index=0;index<attempts;++index){
        {
            Clipper2Lib::Clipper64 clipper;clipper.AddSubject(previous);bool failed=false;
            {allocation_test::FaultScope fault(index);try{clipper.AddSubject(incoming);}catch(const std::bad_alloc&){failed=true;}}
            check(failed,"Every AddPaths append allocation point is reached by fault injection");
            Clipper2Lib::Paths64 result;check(clipper.Execute(Clipper2Lib::ClipType::Union,Clipper2Lib::FillRule::NonZero,result),"A failed append leaves the prior clipper inputs usable");
            std::set<std::pair<std::int64_t,std::int64_t>> points;
            check(result.size()==1&&Clipper2Lib::Area(result.front())==400,"Rollback preserves only the original polygon and removes owned partial minima");
            for(const auto& point:result.front())points.emplace(point.x,point.y);
            check(points==std::set<std::pair<std::int64_t,std::int64_t>>{{0,0},{20,0},{20,20},{0,20}},"No dangling or newly appended vertex is used after rollback");
        }
        check(allocation_test::live==baseline,"Failed append and later Execute/destruction release all owned vertices and minima");
    }
}
void constructor_allocation_failures(){
    const std::vector<FurnitureBody> bodies{{1,box(0,0,-5,100,100,0)}},obstacles{{2,box(200,0,0,220,20,30)}};
    QuerySettings settings;settings.require_front_access=false;const auto baseline=allocation_test::live;std::size_t attempts=0;
    {
        allocation_test::FaultScope trace(std::numeric_limits<std::size_t>::max());
        {FurniturePlacementQuery q(bodies,settings,obstacles);check(q.retained_storage().complete,"Healthy failure fixture has complete retained accounting");}
        attempts=allocation_test::attempts;
    }
    check(allocation_test::live==baseline&&attempts>10&&attempts<=1024,"Healthy construction releases all allocations and bounds the subsequent failure sweep");
    for(std::size_t index=0;index<attempts;++index){
        bool failed=false;
        {
            allocation_test::FaultScope fault(index);
            try{FurniturePlacementQuery q(bodies,settings,obstacles);}
            catch(const std::bad_alloc&){failed=true;}
        }
        if(!failed||allocation_test::live!=baseline)std::cerr<<"constructor allocation failure index="<<index<<" total="<<attempts<<" live="<<allocation_test::live<<" expected="<<baseline<<'\n';
        check(failed&&allocation_test::live==baseline,"Every injected map/geometry/BVH constructor failure releases prior allocations without dangling counter ownership");
    }
    std::cout<<"CONSTRUCTOR_FAILURE_POINTS="<<attempts<<'\n';
}
void exact_012_query_behavior(){
    Mesh mesh;plane(mesh,0,0,100,100,0);const std::vector<FurnitureBody> bodies{{1,mesh}};QuerySettings settings;settings.require_front_access=false;
    FurniturePlacementQuery q(bodies,settings);const auto d=q.diagnostics();std::ostringstream actual;
    actual<<d.bodies<<' '<<d.vertices<<' '<<d.triangles<<' '<<d.closed_components<<' '<<d.open_components<<' '<<d.support_planes<<' '<<d.support_vertices<<' '<<d.build_work<<'\n';
    for(double x:{5.,20.,50.,90.})for(double gap:{0.,5.,10.}){
        const std::vector<Vec3> footprint{{x-10,40,0},{x+10,40,0},{x+10,60,0},{x-10,60,0}};
        const PlacementProbe probe{footprint,{{x,50,10},{10,10,10},0},0,1,{},0,{},gap,0,50000000};
        const auto result=q.validate(probe);actual<<x<<' '<<gap<<' '<<static_cast<int>(result.reason)<<' '<<result.work_units<<'\n';
    }
    const auto path=std::filesystem::path(__FILE__).parent_path()/"data"/"query_behavior_012.golden";
    std::ifstream input(path,std::ios::binary);check(bool(input),"Immutable 0.1.2 query behavior fixture is present");std::string line;std::ostringstream expected;
    // Keep the raw historical fixture immutable. Shared topology now charges
    // DSU/face-label/copy processing explicitly (55 -> 82 constructor units).
    // Geometry fields and every one of the twelve query/work rows stay exact.
    bool header=true;
    while(std::getline(input,line)){if(!line.empty()&&line.back()=='\r')line.pop_back();
        if(header){check(line=="1 4 2 0 1 1 4 55","Frozen 0.1.2 constructor reference remains unchanged");line="1 4 2 0 1 1 4 82";header=false;}
        expected<<line<<'\n';}
    check(actual.str()==expected.str(),"Historical geometry/probe behavior and current charged topology build work remain exact");
}
void numeric_multibin_probe_allocation_failures(){
    Mesh mesh;plane(mesh,0,0,50,100,0);plane(mesh,50,0,100,100,0.0009);
    const std::vector<FurnitureBody> bodies{{1,mesh}};QuerySettings settings;settings.require_front_access=false;
    FurniturePlacementQuery q(bodies,settings);const auto retained=q.retained_storage();
    const std::vector<Vec3> footprint{{40,40,0.00045},{60,40,0.00045},{60,60,0.00045},{40,60,0.00045}};
    PlacementProbe probe{footprint,{{50,50,10.00045},{10,10,10},0},0.00045,1,{},0,{},5,0,50000000};
    check(q.diagnostics().support_planes==2&&retained.complete,"Failure fixture retains two precise height bins through the counted map allocator");
    const auto baseline=allocation_test::live;std::size_t attempts=0;QueryResult expected;
    {allocation_test::FaultScope trace(std::numeric_limits<std::size_t>::max());expected=q.validate(probe);attempts=allocation_test::attempts;}
    check(expected.reason==Rejection::None&&attempts>10&&attempts<=1024&&allocation_test::live==baseline,"Healthy multi-bin union plus inset uses a fixed bounded number of temporary allocations and releases them all");
    for(std::size_t index=0;index<attempts;++index){
        bool failed=false;
        {allocation_test::FaultScope fault(index);try{q.validate(probe);}catch(const std::bad_alloc&){failed=true;}}
        if(!failed||allocation_test::live!=baseline)std::cerr<<"numeric probe allocation failure index="<<index<<" total="<<attempts<<" live="<<allocation_test::live<<" expected="<<baseline<<'\n';
        check(failed&&allocation_test::live==baseline,"Every injected temporary union/inset allocation failure releases all scratch without damaging retained support bins");
        check(fields(q.retained_storage())==fields(retained),"Failed fit probes leave actual map/path/capacity accounting immutable");
    }
    const auto recovered=q.validate(probe);check(recovered.reason==expected.reason&&recovered.work_units==expected.work_units&&allocation_test::live==baseline,
        "The same query remains usable and deterministic after the complete failure sweep");
    std::cout<<"NUMERIC_MULTIBIN_PROBE_FAILURE_POINTS="<<attempts<<'\n';
}
static_assert(noexcept(std::declval<const FurniturePlacementQuery&>().retained_storage()));
}
int main(){int failed=0;for(const auto& test:std::vector<std::pair<const char*,void(*)()>>{
    {"checked_arithmetic",checked_arithmetic},{"allocator_requests_and_lifetime",allocator_requests_and_lifetime},
    {"overflow_and_failed_allocation",overflow_and_failed_allocation},{"snapshot_breakdown_and_capacities",snapshot_breakdown_and_capacities},
    {"passive_probe_and_empty_support",passive_probe_and_empty_support},{"moves_and_lease_lifetime",moves_and_lease_lifetime},
    {"multiple_planes_paths_and_hole",multiple_planes_paths_and_hole},{"constructor_allocation_failures",constructor_allocation_failures},
    {"exact_012_query_behavior",exact_012_query_behavior},{"clipper_failed_append_preserves_previous",clipper_failed_append_preserves_previous},
    {"numeric_multibin_probe_allocation_failures",numeric_multibin_probe_allocation_failures}}){
    try{test.second();std::cout<<"PASS "<<test.first<<'\n';}catch(const std::exception& e){++failed;std::cerr<<"FAIL "<<test.first<<": "<<e.what()<<'\n';}}
    return failed?1:0;
}
