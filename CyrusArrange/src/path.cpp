#include "cyrus_arrange/path.h"
#include "cyrus_arrange/fit_feedback.h"
#include "cyrus_arrange/contact_base.h"
#include <clipper2/clipper.h>
#include <algorithm>
#include <cmath>
#include <limits>
#include <map>
#include <set>
#include <stdexcept>
#include <tuple>

namespace cyrus::arrange {
namespace {
namespace cp=Clipper2Lib;
constexpr double pi=3.14159265358979323846,coordinate_limit=10000000.0,quantization=1000.0;
constexpr std::uint64_t hard_work=50000000;
struct Budget {
    std::uint64_t used{},limit{};
    void charge(std::uint64_t n=1){if(n>limit-used)throw std::runtime_error("Path work budget exceeded; previous arrangement retained.");used+=n;}
};
Vec3 add(Vec3 a,Vec3 b){return {a.x+b.x,a.y+b.y,a.z+b.z};}
Vec3 sub(Vec3 a,Vec3 b){return {a.x-b.x,a.y-b.y,a.z-b.z};}
Vec3 mul(Vec3 a,double s){return {a.x*s,a.y*s,a.z*s};}
double dot(Vec3 a,Vec3 b){return a.x*b.x+a.y*b.y+a.z*b.z;}
double norm(Vec3 a){return std::sqrt(dot(a,a));}
Vec3 mix(Vec3 a,Vec3 b,double t){return add(mul(a,1-t),mul(b,t));}
bool equal_point(Vec3 a,Vec3 b){return a.x==b.x&&a.y==b.y&&a.z==b.z;}
void valid_point(Vec3 p){if(!std::isfinite(p.x)||!std::isfinite(p.y)||!std::isfinite(p.z)||std::max({std::abs(p.x),std::abs(p.y),std::abs(p.z)})>coordinate_limit)throw std::invalid_argument("Path geometry must be finite and within 10km of its arrangement origin.");}
void finite_range(double n,double lo,double hi,const char* label){if(!std::isfinite(n)||n<lo||n>hi)throw std::invalid_argument(label);}
void validate_build(const PathBuildSettings& s){
    finite_range(s.position_tolerance_mm,.001,100,"Path position tolerance must be in 0.001..100mm.");
    finite_range(s.length_tolerance_mm,.001,100,"Path length tolerance must be in 0.001..100mm.");
    if(!s.max_segments||s.max_segments>4096||s.max_samples<2||s.max_samples>65536||s.max_ribbon_vertices<4||s.max_ribbon_vertices>32768||!s.max_work||s.max_work>hard_work)throw std::invalid_argument("Invalid bounded path build limits.");
}
Vec3 evaluate(const CubicBezier& c,double t){const auto& p=c.control;return mix(mix(mix(p[0],p[1],t),mix(p[1],p[2],t),t),mix(mix(p[1],p[2],t),mix(p[2],p[3],t),t),t);}
Vec3 derivative(const CubicBezier& c,double t){const auto& p=c.control;return mul(mix(mix(sub(p[1],p[0]),sub(p[2],p[1]),t),mix(sub(p[2],p[1]),sub(p[3],p[2]),t),t),3);}
std::pair<CubicBezier,CubicBezier> split(const CubicBezier& c){const auto& p=c.control;const auto a=mix(p[0],p[1],.5),b=mix(p[1],p[2],.5),d=mix(p[2],p[3],.5),e=mix(a,b,.5),f=mix(b,d,.5),g=mix(e,f,.5);return {{{p[0],a,e,g}},{{g,f,d,p[3]}}};}
double segment_distance(Vec3 p,Vec3 a,Vec3 b){const auto v=sub(b,a);const double d=dot(v,v);return norm(sub(p,mix(a,b,d>0?std::clamp(dot(sub(p,a),v)/d,0.0,1.0):0)));}
Vec3 horizontal_unit(Vec3 v){const double length=std::hypot(v.x,v.y);if(length<1e-9)throw std::invalid_argument("Path has a vertical/degenerate direction; upright placement requires a horizontal heading.");return {v.x/length,v.y/length,0};}
std::int64_t quantize(double x){return static_cast<std::int64_t>(std::llround(x*quantization));}
cp::Point64 quantize(Vec3 p){valid_point(p);return {quantize(p.x),quantize(p.y)};}
std::uint64_t polygon_build_cost(std::size_t n){if(n>32768)throw std::runtime_error("Path ribbon exceeds its vertex limit.");return static_cast<std::uint64_t>(n)*n+1;}
void admit_ribbon_intersections(const cp::Paths64& paths,std::size_t maximum_vertices){
    struct Edge {cp::Point64 a,b;std::size_t polygon{},index{},count{};};
    std::vector<Edge> edges;std::size_t bound=0;
    for(std::size_t p=0;p<paths.size();++p){if(paths[p].size()>maximum_vertices-bound)throw std::runtime_error("Path ribbon input exceeds its vertex admission.");bound+=paths[p].size();for(std::size_t i=0;i<paths[p].size();++i)edges.push_back({paths[p][i],paths[p][(i+1)%paths[p].size()],p,i,paths[p].size()});}
    // Bounding-box overlap deliberately overestimates crossings. Skipping only
    // adjacent edges, every possible nontrivial intersection reserves four
    // output vertices before Clipper allocates any intersection/output data.
    // Its quadratic preflight is already admitted by polygon_build_cost.
    for(std::size_t i=0;i<edges.size();++i)for(std::size_t j=i+1;j<edges.size();++j){const auto& a=edges[i];const auto& b=edges[j];
        if(a.polygon==b.polygon&&(b.index==a.index+1||(a.index==0&&b.index+1==a.count)))continue;
        if(std::max(a.a.x,a.b.x)<std::min(b.a.x,b.b.x)||std::max(b.a.x,b.b.x)<std::min(a.a.x,a.b.x)||std::max(a.a.y,a.b.y)<std::min(b.a.y,b.b.y)||std::max(b.a.y,b.b.y)<std::min(a.a.y,a.b.y))continue;
        if(maximum_vertices-bound<4)throw std::runtime_error("Path ribbon intersection/output admission exceeded; simplify the crossing curve.");bound+=4;
    }
}
std::uint64_t polygon_query_cost(std::size_t n){return (static_cast<std::uint64_t>(n)+4)*32;}
double side(const cp::Point64& a,const cp::Point64& b,const cp::Point64& p){return static_cast<double>(b.x-a.x)*static_cast<double>(p.y-a.y)-static_cast<double>(b.y-a.y)*static_cast<double>(p.x-a.x);}
bool crosses_open_rectangle(const cp::Point64& a,const cp::Point64& b,const cp::Path64& rectangle){
    double enter=0,leave=1;
    for(std::size_t i=0;i<4;++i){
        const auto& p=rectangle[i];const auto& q=rectangle[(i+1)%4];const double start=side(p,q,a),end=side(p,q,b),delta=end-start;
        if(delta==0){if(start<=0)return false;continue;}
        const double crossing=-start/delta;if(delta>0)enter=std::max(enter,crossing);else leave=std::min(leave,crossing);
        if(enter>=leave)return false;
    }
    const double middle=(enter+leave)*.5;
    for(std::size_t i=0;i<4;++i){const auto& p=rectangle[i];const auto& q=rectangle[(i+1)%4];if(side(p,q,a)*(1-middle)+side(p,q,b)*middle<=0)return false;}
    return true;
}
std::array<Vec3,4> box_corners(const OrientedBox& b,double margin){
    valid_point(b.center);valid_point(b.half_extents);finite_range(b.yaw_degrees,-1e12,1e12,"Invalid path output yaw.");
    if(b.half_extents.x<=0||b.half_extents.y<=0||b.half_extents.z<=0)throw std::invalid_argument("Path output bounds must have positive dimensions.");
    const double r=std::remainder(b.yaw_degrees,360.0)*pi/180,c=std::cos(r),s=std::sin(r),x=b.half_extents.x+margin,y=b.half_extents.y+margin;
    const auto point=[&](double px,double py){return Vec3{b.center.x+c*px-s*py,b.center.y+s*px+c*py,b.center.z};};
    return {point(-x,-y),point(x,-y),point(x,y),point(-x,y)};
}
std::uint64_t hash(std::uint64_t x){x+=0x9e3779b97f4a7c15ULL;x=(x^(x>>30))*0xbf58476d1ce4e5b9ULL;x=(x^(x>>27))*0x94d049bb133111ebULL;return x^(x>>31);}
struct Random {std::uint64_t state;double unit(){state=hash(state);return static_cast<double>(state>>11)*0x1.0p-53;}double signed_unit(){return 2*unit()-1;}};
bool overlaps(const OrientedBox& a,const OrientedBox& b,double gap){
    if(std::abs(a.center.z-b.center.z)>=a.half_extents.z+b.half_extents.z-1e-6)return false;
    const auto axis=[](double angle){const double r=std::remainder(angle,360.0)*pi/180;return Vec3{std::cos(r),std::sin(r),0};};
    const auto ax=axis(a.yaw_degrees),ay=Vec3{-ax.y,ax.x,0},bx=axis(b.yaw_degrees),by=Vec3{-bx.y,bx.x,0},delta=sub(b.center,a.center);
    for(auto direction:{ax,ay,bx,by}){
        const double radius=std::abs(dot(direction,ax))*a.half_extents.x+std::abs(dot(direction,ay))*a.half_extents.y+std::abs(dot(direction,bx))*b.half_extents.x+std::abs(dot(direction,by))*b.half_extents.y+gap;
        if(std::abs(dot(delta,direction))>=radius-1e-6)return false;
    }
    return true;
}
}
struct PathCurve::Impl {
    struct Span {double end{},t0{},t1{};std::size_t segment{};};
    std::vector<CubicBezier> curves;
    std::vector<Vec3> points;
    std::vector<Span> spans;
    bool closed{};
    PathBuildStats stats;
};
PathCurve::PathCurve(std::shared_ptr<const Impl> impl):impl_(std::move(impl)){}
PathCurve PathCurve::build(std::span<const CubicBezier> curves,bool closed,const PathBuildSettings& settings){
    validate_build(settings);if(curves.empty()||curves.size()>settings.max_segments)throw std::invalid_argument("Choose a nonempty curve within the 4096-segment limit.");
    Budget budget{0,settings.max_work};auto out=std::make_shared<Impl>();out->closed=closed;out->curves.assign(curves.begin(),curves.end());
    for(std::size_t i=0;i<curves.size();++i){budget.charge(4);for(auto p:curves[i].control)valid_point(p);if(i&&!equal_point(curves[i-1].control[3],curves[i].control[0]))throw std::invalid_argument("Path segments are disconnected.");}
    if(closed&&!equal_point(curves.back().control[3],curves.front().control[0]))throw std::invalid_argument("Closed path has an open seam.");
    out->points.push_back(curves.front().control[0]);
    struct Pending {CubicBezier curve;double a{},b{},length_allowance{};unsigned depth{};};
    std::vector<Pending> pending;double total=0;
    for(std::size_t i=0;i<curves.size();++i){
        pending.push_back({curves[i],0,1,settings.length_tolerance_mm/static_cast<double>(curves.size()),0});
        while(!pending.empty()){
            budget.charge(32);const auto item=pending.back();pending.pop_back();const auto& p=item.curve.control;const auto chord=sub(p[3],p[0]);const double length=norm(chord);
            const double polygon=norm(sub(p[1],p[0]))+norm(sub(p[2],p[1]))+norm(sub(p[3],p[2]));
            if(polygon<1e-9)throw std::invalid_argument("Path contains a zero-length segment; remove duplicate knots.");
            const double error=std::max(0.0,polygon-length),deviation=std::max(segment_distance(p[1],p[0],p[3]),segment_distance(p[2],p[0],p[3]));
            bool monotone=length>1e-9;
            for(int edge=0;edge<3;++edge)monotone=monotone&&dot(sub(p[edge+1],p[edge]),chord)>=0;
            if(monotone&&error<=item.length_allowance&&deviation<=settings.position_tolerance_mm){
                horizontal_unit(chord);
                if(out->points.size()>=settings.max_samples)throw std::runtime_error("Path sampling exceeds its sample limit; simplify the curve.");
                total+=length;out->points.push_back(p[3]);out->spans.push_back({total,item.a,item.b,i});out->stats.length_error_bound_mm+=error;
                out->stats.maximum_deviation_bound_mm=std::max(out->stats.maximum_deviation_bound_mm,deviation);
            }else{
                if(item.depth>=32)throw std::runtime_error("Path subdivision cannot resolve a degenerate cusp within its depth limit.");
                const auto [left,right]=split(item.curve);const double middle=(item.a+item.b)*.5;
                pending.push_back({right,middle,item.b,item.length_allowance*.5,item.depth+1});pending.push_back({left,item.a,middle,item.length_allowance*.5,item.depth+1});
            }
        }
    }
    if(total<1e-6||!std::isfinite(total))throw std::invalid_argument("Path length is too small or nonfinite.");
    out->stats.segments=curves.size();out->stats.samples=out->points.size();out->stats.work=budget.used;return PathCurve(std::move(out));
}
double PathCurve::length_mm()const noexcept{return impl_->spans.back().end;}
bool PathCurve::closed()const noexcept{return impl_->closed;}
PathBuildStats PathCurve::diagnostics()const noexcept{return impl_->stats;}
std::span<const Vec3> PathCurve::polyline()const noexcept{return impl_->points;}
PathFrame PathCurve::at(double s,std::uint64_t allowance)const{
    if(!std::isfinite(s)||!allowance||allowance>hard_work)throw std::invalid_argument("Invalid path distance or work allowance.");
    Budget budget{0,allowance};const double length=length_mm();
    if(closed()){s=std::fmod(s,length);if(s<0)s+=length;}else if(s<0||s>length)throw std::invalid_argument("Open path distance lies beyond its endpoints.");
    auto found=std::lower_bound(impl_->spans.begin(),impl_->spans.end(),s,[&](const auto& span,double value){budget.charge();return span.end<value;});
    if(found==impl_->spans.end())found=std::prev(impl_->spans.end());const auto index=static_cast<std::size_t>(found-impl_->spans.begin());const double start=index?impl_->spans[index-1].end:0;
    const auto chord=sub(impl_->points[index+1],impl_->points[index]);const double chord_length=found->end-start,desired=(s-start)/chord_length;
    double lo=found->t0,hi=found->t1,t=lo;
    if(desired>=1)t=hi;else if(desired>0){for(unsigned iteration=0;iteration<48;++iteration){budget.charge(16);t=(lo+hi)*.5;const double fraction=dot(sub(evaluate(impl_->curves[found->segment],t),impl_->points[index]),chord)/(chord_length*chord_length);if(fraction<desired)lo=t;else hi=t;}t=(lo+hi)*.5;}
    budget.charge(32);const auto position=evaluate(impl_->curves[found->segment],t);auto tangent=derivative(impl_->curves[found->segment],t);if(norm(tangent)<1e-9)tangent=chord;
    tangent=mul(tangent,1/norm(tangent));const auto horizontal=horizontal_unit(tangent);return {position,tangent,{-horizontal.y,horizontal.x,0},s,t,found->segment,budget.used};
}
void validate_path_lane(const PathLane& lane){
    if(!lane.id||lane.quantity>10000)throw std::invalid_argument("Path lane requires a stable nonzero ID and at most 10000 copies.");
    finite_range(lane.offset_mm,-1000000,1000000,"Path offset must be in +/-1000000mm.");finite_range(lane.width_mm,.001,1000000,"Lane width must be positive and at most 1000000mm.");finite_range(lane.center_spacing_mm,.001,1000000,"Path center spacing must be positive and at most 1000000mm.");
}
void validate_path_settings(const PathSettings& s){
    if(s.amount>=PathAmount::Count||!s.attempts_per_slot||s.attempts_per_slot>64)throw std::invalid_argument("Invalid path amount mode or retry limit.");
    finite_range(s.source_forward_degrees,-360,360,"Source forward angle must be in +/-360 degrees.");
    for(double n:{s.start_inset_mm,s.end_inset_mm,s.lateral_jitter_mm,s.longitudinal_jitter_mm})finite_range(n,0,1000000,"Path inset/random spread must be finite in 0..1000000mm.");
}
struct PathLaneMask::Impl {cp::Paths64 polygons;std::vector<int> winding;std::size_t vertices{};std::uint64_t work{};bool enabled{};};
PathLaneMask::PathLaneMask(std::shared_ptr<const Impl> impl):impl_(std::move(impl)){}
PathLaneMask PathLaneMask::build(const PathCurve& curve,const PathLane& lane,const PathBuildSettings& settings){
    validate_build(settings);validate_path_lane(lane);auto out=std::make_shared<Impl>();out->enabled=lane.limit_width;if(!lane.limit_width)return PathLaneMask(std::move(out));
    Budget budget{0,settings.max_work};const auto points=curve.polyline();const std::size_t count=points.size()-(curve.closed()?1:0);
    if(count<2||count>settings.max_ribbon_vertices/2)throw std::runtime_error("Path ribbon exceeds its admitted vertices.");
    std::vector<Vec3> joins;joins.reserve(count);
    for(std::size_t i=0;i<count;++i){budget.charge(24);Vec3 join;
        if(!curve.closed()&&(i==0||i+1==count)){const auto direction=horizontal_unit(i==0?sub(points[1],points[0]):sub(points[i],points[i-1]));join={-direction.y,direction.x,0};}
        else {const auto before=horizontal_unit(sub(points[i],points[(i+count-1)%count])),after=horizontal_unit(sub(points[(i+1)%count],points[i]));const double denominator=1+dot(before,after);if(denominator<.125)throw std::runtime_error("Path reverses too sharply to define an admitted lane ribbon.");join=mul(Vec3{-before.y-after.y,before.x+after.x,0},1/denominator);}
        joins.push_back(join);
    }
    cp::Path64 a,b;a.reserve(count);b.reserve(count);const double lo=lane.offset_mm-lane.width_mm*.5,hi=lane.offset_mm+lane.width_mm*.5;
    for(std::size_t i=0;i<count;++i){budget.charge(2);a.push_back(quantize(add(points[i],mul(joins[i],lo))));b.push_back(quantize(add(points[i],mul(joins[i],hi))));}
    for(std::size_t i=0;i<(curve.closed()?count:count-1);++i){
        const auto next=(i+1)%count;const auto source=sub(points[next],points[i]);budget.charge(8);
        for(const auto* boundary:{&a,&b}){
            const Vec3 edge{static_cast<double>((*boundary)[next].x-(*boundary)[i].x)/quantization,static_cast<double>((*boundary)[next].y-(*boundary)[i].y)/quantization,0};
            if(dot(edge,source)<=0)throw std::runtime_error("Lane width/offset folds across this bend; reduce the width/offset or widen the bend.");
        }
    }
    cp::Paths64 input;
    if(curve.closed()){
        // Equal orientation in nested offset loops would incorrectly fill the
        // hole. Their relative winding follows the source curve, not area sign.
        std::reverse(b.begin(),b.end());input.push_back(std::move(a));input.push_back(std::move(b));
    }else {a.insert(a.end(),b.rbegin(),b.rend());input.push_back(std::move(a));}
    budget.charge(polygon_build_cost(count*2));admit_ribbon_intersections(input,settings.max_ribbon_vertices);cp::Clipper64 clip;clip.AddSubject(input);
    if(!clip.Execute(cp::ClipType::Union,cp::FillRule::NonZero,out->polygons)||clip.ErrorCode())throw std::runtime_error("Path ribbon construction failed.");
    for(const auto& polygon:out->polygons){if(polygon.size()>settings.max_ribbon_vertices-out->vertices)throw std::runtime_error("Path ribbon output exceeds its vertex admission.");out->vertices+=polygon.size();out->winding.push_back(cp::IsPositive(polygon)?1:-1);}
    if(out->polygons.empty())throw std::runtime_error("Path lane has no usable area.");out->work=budget.used;return PathLaneMask(std::move(out));
}
QueryResult PathLaneMask::validate(const OrientedBox& box,double margin,std::uint64_t allowance)const{
    finite_range(margin,0,1000000,"Path lane margin must be finite in 0..1000000mm.");if(!allowance||allowance>hard_work)throw std::invalid_argument("Invalid path lane query allowance.");
    const auto corners=box_corners(box,margin+.002);if(!impl_->enabled)return {Rejection::None,1};Budget budget{0,allowance};budget.charge(polygon_query_cost(impl_->vertices));
    cp::Path64 rectangle;for(auto p:corners)rectangle.push_back(quantize(p));
    const auto contains=[&](const cp::Point64& point){int winding=0;bool boundary=false;for(std::size_t i=0;i<impl_->polygons.size();++i){const auto value=cp::PointInPolygon(point,impl_->polygons[i]);if(value==cp::PointInPolygonResult::IsOn)boundary=true;else if(value==cp::PointInPolygonResult::IsInside)winding+=impl_->winding[i];}return boundary||winding!=0;};
    for(const auto& corner:rectangle)if(!contains(corner))return {Rejection::Boundary,budget.used};
    const cp::Point64 center{(rectangle[0].x+rectangle[2].x)/2,(rectangle[0].y+rectangle[2].y)/2};
    if(!contains(center))return {Rejection::Boundary,budget.used};
    // Any canonical lane boundary entering the open rectangle partitions its
    // interior into permitted/forbidden areas. This also finds enclosed holes
    // and concave notches when all corners and the center happen to be inside.
    for(const auto& polygon:impl_->polygons)for(std::size_t i=0;i<polygon.size();++i)
        if(crosses_open_rectangle(polygon[i],polygon[(i+1)%polygon.size()],rectangle))return {Rejection::Boundary,budget.used};
    return {Rejection::None,budget.used};
}
std::size_t PathLaneMask::vertices()const noexcept{return impl_->vertices;}
std::uint64_t PathLaneMask::build_work()const noexcept{return impl_->work;}
namespace {
Placement centered_placement(const Asset& asset,Vec3 center,double yaw,double scale,std::uint32_t lane,std::uint64_t id){
    const auto base=contact_base_center(asset);const double r=std::remainder(yaw,360.0)*pi/180,c=std::cos(r),s=std::sin(r),x=(base.x-asset.anchor.x)*scale,y=(base.y-asset.anchor.y)*scale;
    return {id,asset.id,0,lane,{center.x-c*x+s*y,center.y-s*x-c*y,center.z},yaw,scale,false};
}
double closest_distance(const PathCurve& curve,Vec3 point,Budget& budget){
    double best=INFINITY,answer=0,distance=0;const auto points=curve.polyline();
    for(std::size_t i=1;i<points.size();++i){budget.charge(8);const auto segment=sub(points[i],points[i-1]);const double squared=dot(segment,segment),f=std::clamp(dot(sub(point,points[i-1]),segment)/squared,0.0,1.0),length=std::sqrt(squared);const double error=norm(sub(point,mix(points[i-1],points[i],f)));if(error<best){best=error;answer=distance+f*length;}distance+=length;}
    return answer;
}
}
PathArrangementResult arrange_path(const PathRequest& request,const ArrangeSettings& settings,const PathSettings& path,const PathBuildSettings& build){
    validate_arrange_settings(settings);validate_path_settings(path);validate_build(build);
    if(request.lanes.empty()||request.lanes.size()>2||request.assets.size()>256||request.minimums.size()>256||request.previous.size()>settings.max_placements||request.locked_ids.size()>settings.max_placements)throw std::invalid_argument("Path supports one/two lanes, 256 sources/minimum policies and the configured output limit.");
    Budget budget{0,settings.max_work};budget.charge(request.curve.diagnostics().work);
    budget.charge((request.assets.size()+request.minimums.size())*16);
    const auto minimum_total=validate_asset_minimums(request.minimums,request.assets);
    const double length=request.curve.length_mm(),usable=length-path.start_inset_mm-path.end_inset_mm;
    if(usable<=0)throw std::invalid_argument("Path endpoint insets leave no usable length.");
    if(request.curve.closed()&&(path.start_inset_mm!=0||path.end_inset_mm!=0))throw std::invalid_argument("Closed paths have no endpoints; clear the endpoint insets.");
    PathArrangementResult out;auto& result=out.result;
    FitFailureRecorder failures(request.assets);
    std::map<std::uint32_t,std::size_t> lanes;std::vector<PathLaneMask> masks;masks.reserve(request.lanes.size());std::size_t total_requested=0;
    for(std::size_t i=0;i<request.lanes.size();++i){
        const auto& lane=request.lanes[i];validate_path_lane(lane);if(!lanes.emplace(lane.id,i).second)throw std::invalid_argument("Path lane IDs must be distinct.");
        const double requested=path.amount==PathAmount::Quantity?static_cast<double>(lane.quantity):std::floor(usable/lane.center_spacing_mm);
        if(requested>static_cast<double>(settings.max_placements-total_requested))throw std::invalid_argument("Path lanes request more than the configured output limit.");
        out.requested_per_lane[i]=static_cast<std::size_t>(requested);total_requested+=out.requested_per_lane[i];
        auto limited=build;limited.max_work=std::min(limited.max_work,budget.limit-budget.used);if(!limited.max_work)budget.charge();
        masks.push_back(PathLaneMask::build(request.curve,lane,limited));budget.charge(masks.back().build_work());
    }
    result.stats.requested=total_requested;
    if(minimum_total>total_requested)throw std::invalid_argument("Minimum copies exceed the active path total. Increase lane copies or reduce center spacing/minimums.");
    std::map<std::uint64_t,const Asset*> assets;std::vector<const Asset*> weighted;std::size_t vertices=0,triangles=0;double total_weight=0;
    for(const auto& asset:request.assets){
        if(asset.mesh.vertices.size()>1000000-vertices||asset.mesh.triangles.size()>1000000-triangles)throw std::invalid_argument("Path sources exceed aggregate mesh admission.");
        vertices+=asset.mesh.vertices.size();triangles+=asset.mesh.triangles.size();budget.charge(1+asset.mesh.vertices.size()+asset.mesh.triangles.size()+asset.contact_footprint.size()+asset.stack_footprint.size());validate_asset(asset);
        if(!assets.emplace(asset.id,&asset).second)throw std::invalid_argument("Path source IDs must be unique.");
        if(asset.weight>0){weighted.push_back(&asset);total_weight+=asset.weight;}
    }
    if(!std::isfinite(total_weight))throw std::invalid_argument("Path source weights overflow.");
    budget.charge(weighted.size()*16);std::sort(weighted.begin(),weighted.end(),[](const Asset* a,const Asset* b){return a->id<b->id;});
    total_weight=0;for(auto* asset:weighted)total_weight+=asset->weight;
    std::map<std::uint64_t,CollisionSource> colliders;for(const auto& a:request.assets){budget.charge();colliders.try_emplace(a.id,a);}
    const auto collider_pose=[&](const Placement& p){return CollisionPose{&colliders.at(p.asset_id),p.position,p.yaw_degrees,p.scale};};
    std::map<std::uint64_t,const Placement*> previous;std::set<std::uint64_t> protected_ids,explicit_ids,published_ids;
    for(const auto& p:request.previous){budget.charge();valid_point(p.position);if(!p.stable_id||!previous.emplace(p.stable_id,&p).second||!std::isfinite(p.yaw_degrees)||!std::isfinite(p.scale)||p.scale<=0||p.scale>1000)throw std::invalid_argument("Invalid previous path placement.");if(p.locked)protected_ids.insert(p.stable_id);}
    for(auto id:request.locked_ids){budget.charge();if(!previous.contains(id)||!explicit_ids.insert(id).second)throw std::invalid_argument("Locked path IDs must exist and be unique.");protected_ids.insert(id);}
    std::map<std::uint64_t,std::size_t> asset_counts;
    std::vector<PlacedObstacle> accepted;accepted.reserve(settings.max_placements);result.placements.reserve(std::min(settings.max_placements,total_requested+protected_ids.size()));
    const auto probe_pose=[&](const Asset& asset,const Placement& p,std::size_t lane,std::uint64_t remaining){
        Budget local{0,remaining};const auto box=placement_bounds(asset,p);auto checked=masks[lane].validate(box,settings.edge_clearance_mm,local.limit-local.used);local.charge(checked.work_units);
        if(checked.reason!=Rejection::None)checked.witness.issue=FitIssue::Lane;
        if(checked.reason==Rejection::None)for(const auto& other:accepted){local.charge(8);
            if(overlaps(box,other.box,0)){const auto hit=collision_overlap(box,collider_pose(p),other.box,other.collider,0,1e-6,local.limit-local.used);local.charge(hit.work);if(hit.overlaps){checked.reason=Rejection::Obstacle;checked.witness={FitIssue::Occupied,0,other.stable_id};break;}}
            if(settings.spacing_mm>0&&overlaps(box,other.box,settings.spacing_mm)){const auto hit=collision_overlap(box,collider_pose(p),other.box,other.collider,settings.spacing_mm,1e-6,local.limit-local.used);local.charge(hit.work);if(hit.overlaps){checked.reason=Rejection::Spacing;checked.witness={FitIssue::Spacing,0,other.stable_id};break;}}
        }
        if(checked.reason==Rejection::None&&request.physical){
            const auto footprint=placement_footprint(asset,p);const PlacementProbe probe{footprint,box,p.position.z,p.region_id,accepted,0,{},settings.edge_clearance_mm,settings.spacing_mm,local.limit-local.used,{},{},collider_pose(p)};
            checked=request.physical->validate(probe);local.charge(checked.work_units);
            if(checked.reason>=Rejection::Count)throw std::runtime_error("Path physical query returned an invalid rejection code.");
        }
        checked.work_units=local.used;return checked;
    };
    const auto check_pose=[&](const Asset& asset,const Placement& p,std::size_t lane,bool protected_pose,bool record_failure=true){
        if(!protected_pose){if(result.stats.candidates>=settings.max_candidates)return false;++result.stats.candidates;}
        budget.charge();const auto checked=probe_pose(asset,p,lane,budget.limit-budget.used);budget.charge(checked.work_units);
        if(checked.reason!=Rejection::None){++result.stats.rejections[static_cast<std::size_t>(checked.reason)];if(protected_pose)throw std::runtime_error("Protected path output no longer passes lane/support/clearance/collision validation; previous result retained.");if(record_failure)failures.note(p,checked);return false;}
        return true;
    };
    const auto publish=[&](const Asset& asset,const Placement& p,std::size_t lane,double s,double lateral){
        if(result.placements.size()>=settings.max_placements||!published_ids.insert(p.stable_id).second)throw std::runtime_error("Path output exceeds its identity/count admission.");
        result.placements.push_back(p);accepted.push_back({p.stable_id,placement_bounds(asset,p),0,collider_pose(p)});out.locations.push_back({p.stable_id,p.region_id,s,lateral});++out.accepted_per_lane[lane];++asset_counts[asset.id];
    };
    for(auto id:protected_ids){
        auto p=*previous.at(id);p.locked=true;
        if(p.parent_stack_id||!assets.contains(p.asset_id)||!lanes.contains(p.region_id))throw std::runtime_error("Protected output has a missing path lane/source or incompatible surface stack.");
        const auto index=lanes.at(p.region_id);const auto& asset=*assets.at(p.asset_id);
        if(check_pose(asset,p,index,true)){
            const auto box=placement_bounds(asset,p);const auto s=closest_distance(request.curve,{box.center.x,box.center.y,box.center.z-box.half_extents.z},budget);const auto frame=request.curve.at(s,budget.limit-budget.used);budget.charge(frame.work);
            publish(asset,p,index,s,dot(sub(box.center,frame.position),frame.left));
        }
    }
    result.stats.kept=result.placements.size();
    if(weighted.empty()&&minimum_total==0)result.warnings.push_back("Add at least one prop source with a positive weight.");
    const auto choose=[&](Random& random)->const Asset& {budget.charge();double value=random.unit()*total_weight;for(auto* asset:weighted){budget.charge();if(value<asset->weight)return *asset;value-=asset->weight;}return *weighted.back();};
    const auto full=[&](std::size_t lane){return out.accepted_per_lane[lane]>=out.requested_per_lane[lane];};
    // Reserve required copies before weighted optional demand. A rejected
    // required copy never turns into a substitute small prop. Numeric slots and
    // demand stay inside the same admitted 10k output cap; all probes are charged.
    struct Slot {std::size_t lane{},index{};bool filled{};};
    std::vector<Slot> slots;slots.reserve(total_requested);
    std::size_t remaining=0;for(std::size_t i=0;i<request.lanes.size();++i){budget.charge(out.requested_per_lane[i]+1);remaining+=out.requested_per_lane[i]-std::min(out.requested_per_lane[i],out.accepted_per_lane[i]);for(std::size_t j=0;j<out.requested_per_lane[i];++j)slots.push_back({i,j});}
    remaining=std::min(remaining,settings.max_placements-result.placements.size());
    std::map<std::uint64_t,std::size_t> required,optional;
    std::size_t missing=0;for(const auto& m:request.minimums){budget.charge();const auto count=asset_counts[m.asset_id];if(count<m.quantity){required[m.asset_id]=m.quantity-count;missing+=m.quantity-count;}}
    if(missing>remaining)throw std::invalid_argument("Protected path output and minimum copies exceed available lane copies. Raise lane copies or lower minimums/unprotect output.");
    Random demand_random{hash(settings.seed^0x5041544844454d41ULL)};
    for(std::size_t i=missing;i<remaining&&!weighted.empty();++i){budget.charge();++optional[choose(demand_random).id];}
    std::vector<const Asset*> order;order.reserve(assets.size());for(const auto& [id,a]:assets)order.push_back(a);
    std::sort(order.begin(),order.end(),[&](const Asset* a,const Asset* b){budget.charge();auto key=[](const Asset& a){const double x=a.bounds.max.x-a.bounds.min.x,y=a.bounds.max.y-a.bounds.min.y,z=a.bounds.max.z-a.bounds.min.z;return std::tuple{x*y*z,x*y,z};};const auto ka=key(*a),kb=key(*b);return ka!=kb?ka>kb:a->id<b->id;});
    std::size_t ordinal=0;
    const auto try_copy=[&](const Asset& asset){
        const auto start=slots.empty()?0:ordinal++%slots.size();
        for(unsigned phase=0;phase<(settings.fit_to_space?2u:1u);++phase){
            for(std::size_t offset=0;offset<slots.size()&&result.stats.candidates<settings.max_candidates&&result.placements.size()<settings.max_placements;++offset){
                budget.charge();auto& candidate_slot=slots[(start+offset)%slots.size()];const auto lane_index=candidate_slot.lane,slot=candidate_slot.index;
                if(candidate_slot.filled||full(lane_index))continue;
                const auto& lane=request.lanes[lane_index];const auto target=out.requested_per_lane[lane_index];
                const auto slot_seed=hash(hash(hash(settings.seed^0x50415448534c4f54ULL)^lane.id)^slot);
                Random random{slot_seed};
                double base=path.amount==PathAmount::Quantity?(request.curve.closed()?static_cast<double>(slot)*usable/target:(static_cast<double>(slot)+.5)*usable/target):(request.curve.closed()?static_cast<double>(slot)*lane.center_spacing_mm:(static_cast<double>(slot)+.5)*lane.center_spacing_mm);
                if(lane.reverse)base=usable-base;base+=path.start_inset_mm;
                const auto attempts=path.lateral_jitter_mm==0&&path.longitudinal_jitter_mm==0&&!settings.random_scale&&weighted.size()==1?1:path.attempts_per_slot;
                for(std::size_t attempt=0;attempt<attempts&&!full(lane_index)&&result.stats.candidates<settings.max_candidates;++attempt){
                    budget.charge(12);random.unit();const double preferred=settings.random_scale?settings.scale_min+(settings.scale_max-settings.scale_min)*random.unit():1;
                    double s=base+random.signed_unit()*path.longitudinal_jitter_mm*(lane.reverse?-1:1);if(!request.curve.closed())s=std::clamp(s,path.start_inset_mm,length-path.end_inset_mm);
                    const auto frame=request.curve.at(s,budget.limit-budget.used);budget.charge(frame.work);const double lateral=lane.offset_mm+random.signed_unit()*path.lateral_jitter_mm;const auto center=add(frame.position,mul(frame.left,lateral));
                    const double yaw=path.align?std::atan2(frame.tangent.y,frame.tangent.x)*180/pi-path.source_forward_degrees+(lane.reverse?180:0):asset.allowed_yaws_degrees[std::min(asset.allowed_yaws_degrees.size()-1,static_cast<std::size_t>(random.unit()*asset.allowed_yaws_degrees.size()))];
                    const auto raw_id=hash(hash(hash(slot_seed^0x504154484f555450ULL)^asset.id)^attempt);const auto id=raw_id?raw_id:1;
                    if(published_ids.contains(id))continue;
                    const auto make=[&](double scale){return centered_placement(asset,center,yaw,scale,lane.id,id);};
                    auto candidate=make(preferred);
                    if(phase==0){if(check_pose(asset,candidate,lane_index,false)){publish(asset,candidate,lane_index,frame.distance_mm,lateral);candidate_slot.filled=true;return true;}}
                    else if(settings.scale_min<preferred){
                        std::optional<Placement> best;double valid=0,invalid=preferred;
                        for(unsigned probe=1;probe<=16&&result.stats.candidates<settings.max_candidates;++probe){const double scale=probe==16?settings.scale_min:std::max(settings.scale_min,preferred*std::pow(settings.scale_min/preferred,static_cast<double>(probe)/16));auto trial=make(scale);if(check_pose(asset,trial,lane_index,false,false)){best=trial;valid=scale;break;}invalid=scale;}
                        if(best){for(unsigned refine=0;refine<12&&result.stats.candidates<settings.max_candidates;++refine){const double scale=(valid+invalid)*.5;auto trial=make(scale);if(check_pose(asset,trial,lane_index,false,false)){best=trial;valid=scale;}else invalid=scale;}publish(asset,*best,lane_index,frame.distance_mm,lateral);++result.stats.scaled_to_fit;candidate_slot.filled=true;return true;}
                    }
                }
            }
        }
        return false;
    };
    for(const auto* demand:{&required,&optional})for(const auto* asset:order){const auto it=demand->find(asset->id);if(it==demand->end())continue;for(std::size_t i=0;i<it->second;++i){budget.charge();if(result.stats.candidates>=settings.max_candidates)break;try_copy(*asset);}}
    const auto missing_required=[&]{std::size_t count=0;for(const auto& m:request.minimums){budget.charge();if(asset_counts[m.asset_id]<m.quantity)count+=m.quantity-asset_counts[m.asset_id];}return count;};
    // Optional weighted choices are preferences, not required counts. If a
    // sampled source cannot fit, fill remaining unreserved slots with another
    // selected source. One failed full search ends each fallback source batch.
    for(const auto* asset:order)while(result.stats.candidates<settings.max_candidates&&result.placements.size()<settings.max_placements){
        budget.charge();std::size_t open=0;for(std::size_t i=0;i<request.lanes.size();++i)open+=out.requested_per_lane[i]-std::min(out.requested_per_lane[i],out.accepted_per_lane[i]);
        if(open<=missing_required()||!try_copy(*asset))break;
    }
    for(const auto& m:request.minimums)if(asset_counts[m.asset_id]<m.quantity){const auto deficit=m.quantity-asset_counts[m.asset_id];result.stats.minimum_unfilled+=deficit;result.warnings.push_back("Required prop '"+assets.at(m.asset_id)->name+"' is missing "+std::to_string(deficit)+" copies; lane, size, support or collision checks rejected them.");}
    result.stats.accepted=result.placements.size();result.stats.underfilled=0;
    for(std::size_t i=0;i<request.lanes.size();++i){if(out.accepted_per_lane[i]<out.requested_per_lane[i])result.stats.underfilled+=out.requested_per_lane[i]-out.accepted_per_lane[i];else if(out.accepted_per_lane[i]>out.requested_per_lane[i])result.warnings.push_back("Protected path output exceeds this lane's requested quantity.");}
    if(result.stats.underfilled)result.warnings.push_back("Some path copies could not pass the requested lane, size, support or collision limits.");
    if(result.stats.candidates>=settings.max_candidates&&result.stats.underfilled)result.warnings.push_back("Path candidate limit reached; reduce quantity or random spread.");
    result.stats.work=budget.used;
    result.feedback=failures.finish(result,request.minimums,settings,[&](const Placement& seed,Placement& trial,std::uint64_t remaining){
        const auto& asset=*assets.at(trial.asset_id);const auto center=placed_base_center(asset,seed.position,seed.yaw_degrees,seed.scale);
        trial=centered_placement(asset,center,seed.yaw_degrees,trial.scale,seed.region_id,seed.stable_id);
        return probe_pose(asset,trial,lanes.at(trial.region_id),remaining);
    });
    return out;
}
} // namespace cyrus::arrange
