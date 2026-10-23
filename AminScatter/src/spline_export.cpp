#include "spline_export.h"
#include "segment_index.h"
#include <numeric>

namespace cyrus::spline_export {
static double spanCertificate(const Loops&,const Loops&,const Result&,double,std::size_t);
namespace {
using amin::Vec3;using geometry::Point2;using geometry::Segment2;
double distance(Vec3 p,Vec3 a,Vec3 b){
    const auto d=b-a;const double den=amin::dot(d,d);
    const double t=den>0?std::clamp(amin::dot(p-a,d)/den,0.,1.):0;
    return amin::length(p-(a+d*t));
}
bool finite(Vec3 p){return std::isfinite(p.x)&&std::isfinite(p.y)&&std::isfinite(p.z);}
std::vector<Segment2> segments(const std::vector<std::vector<Point2>>& loops){
    std::vector<Segment2> out;std::size_t n=0;for(const auto& ring:loops)n+=ring.size();out.reserve(n);
    for(std::size_t r=0;r<loops.size();++r)for(std::size_t i=0;i<loops[r].size();++i)
        out.push_back({loops[r][i],loops[r][(i+1)%loops[r].size()],std::uint32_t(r),std::uint32_t(i)});
    return out;
}
bool simple(const geometry::SegmentIndex& index,const std::vector<std::vector<Point2>>& loops,std::size_t& work,std::size_t limit){
    bool valid=true;const auto& all=index.segments();
    for(std::size_t i=0;i<all.size()&&valid;++i){
        const auto& a=all[i];if(a.a.x==a.b.x&&a.a.y==a.b.y)return false;
        index.overlap(geometry::bounds(a),[&](std::uint32_t j,const Segment2& b){
            if(j<=i||!valid)return;
            const auto n=loops[a.loop].size();
            if(a.loop==b.loop&&((a.edge+1)%n==b.edge||(b.edge+1)%n==a.edge)){
                // Straight continuation is fine; immediate retracing is not.
                const double dot=(a.b.x-a.a.x)*(b.b.x-b.a.x)+(a.b.y-a.a.y)*(b.b.y-b.a.y);
                if(geometry::orientation(a.a,a.b,b.a)==0&&geometry::orientation(a.a,a.b,b.b)==0&&dot<=0)valid=false;
            }else if(geometry::contact(a,b))valid=false;
        },work,limit);
    }
    return valid;
}
double area(const std::vector<Point2>& loop){double a=0;for(std::size_t i=0;i<loop.size();++i){const auto p=loop[i],q=loop[(i+1)%loop.size()];a+=p.x*q.y-q.x*p.y;}return a;}
std::size_t depth(const geometry::SegmentIndex& index,Point2 p,std::uint32_t own,std::size_t& work,std::size_t limit){
    // Count crossings per other contour, so nested islands do not cancel depth.
    std::vector<std::uint32_t> crossings;
    index.ray(p,[&](std::uint32_t,const Segment2& s){
        if(s.loop==own)return;
        if((s.a.y>p.y)!=(s.b.y>p.y)&&p.x<s.a.x+(p.y-s.a.y)*(s.b.x-s.a.x)/(s.b.y-s.a.y))crossings.push_back(s.loop);
    },work,limit);
    std::sort(crossings.begin(),crossings.end());std::size_t count=0;
    for(std::size_t i=0;i<crossings.size();){auto j=i+1;while(j<crossings.size()&&crossings[j]==crossings[i])++j;count+=(j-i)%2;i=j;}
    return count;
}
}

Result optimize(const Loops& world,double tolerance,const Limits& cap){
    if(!std::isfinite(tolerance)||tolerance<=0)throw std::invalid_argument("Export maximum deviation must be finite and positive");
    if(cap.vertices>200000||cap.bytes>64u*1024u*1024u||cap.work>50000000)throw std::invalid_argument("Export optimizer limits exceed the supported maximum");
    Result result;
    for(const auto& loop:world){
        if(loop.size()<3||loop.size()>cap.vertices-result.input)throw std::invalid_argument("Paint export contour limit exceeded");
        result.input+=loop.size();for(auto p:loop)if(!finite(p))throw std::invalid_argument("Nonfinite Paint contour");
        result.indices.emplace_back(loop.size());std::iota(result.indices.back().begin(),result.indices.back().end(),0u);
    }
    result.output=result.input;
    if(world.empty())return result;
    // Conservative peak for two indexes, copied projections, spans and output.
    if(result.input>cap.bytes/256){result.reason="Optimizer scratch allowance: Exact snapshot retained";return result;}
    result.bytes=result.input*256;
    const auto fallback=[&](const char* reason){result.reason=reason;result.optimized=false;result.output=result.input;result.bound=0;
        for(std::size_t r=0;r<world.size();++r){result.indices[r].resize(world[r].size());std::iota(result.indices[r].begin(),result.indices[r].end(),0u);}return result;};
    const Vec3 origin=world.front().front();Vec3 u{},normal{};double longest=0;
    for(const auto& loop:world)for(auto p:loop){const auto d=p-origin;const double l=amin::dot(d,d);if(l>longest){longest=l;u=d;}}
    if(!(longest>0))return fallback("Degenerate footprint: Exact snapshot retained");
    u=u*(1/std::sqrt(longest));double bestNormal=0;
    for(const auto& loop:world)for(auto p:loop){const auto d=p-origin;const Vec3 n{u.y*d.z-u.z*d.y,u.z*d.x-u.x*d.z,u.x*d.y-u.y*d.x};const double l=amin::dot(n,n);if(l>bestNormal){bestNormal=l;normal=n;}}
    if(!(bestNormal>0))return fallback("Collinear footprint: Exact snapshot retained");
    normal=normal*(1/std::sqrt(bestNormal));const Vec3 v{normal.y*u.z-normal.z*u.y,normal.z*u.x-normal.x*u.z,normal.x*u.y-normal.y*u.x};
    std::vector<std::vector<Point2>> projected;projected.reserve(world.size());
    for(const auto& loop:world){projected.emplace_back();projected.back().reserve(loop.size());for(auto p:loop){const auto d=p-origin;
        if(std::abs(amin::dot(d,normal))>std::max(1e-10,std::sqrt(longest)*1e-10))return fallback("Nonplanar boundary: Exact snapshot retained");
        projected.back().push_back({amin::dot(d,u),amin::dot(d,v)});
    }}
    try{
        geometry::SegmentIndex original(segments(projected),&result.work,cap.work);
        if(!simple(original,projected,result.work,cap.work))return fallback("Touching or ambiguous topology: Exact snapshot retained");
        std::vector<std::vector<Point2>> reduced;reduced.reserve(world.size());
        for(std::size_t r=0;r<world.size();++r){
            const auto& loop=world[r];const auto n=loop.size();std::vector<bool> keep(n,false);keep[0]=true;
            std::vector<std::size_t> anchors{0};std::size_t far=1;double farDistance=0;
            for(std::size_t i=1;i<n;++i){const auto d=loop[i]-loop[0];const auto l=amin::dot(d,d);if(l>farDistance){farDistance=l;far=i;}}
            for(std::size_t i=1;i<n;++i){
                const auto a=loop[i]-loop[(i+n-1)%n],b=loop[(i+1)%n]-loop[i];const double den=amin::length(a)*amin::length(b);
                if(i==far||(den>0&&amin::dot(a,b)<den*0.8660254037844386))anchors.push_back(i);
            }
            anchors.push_back(n);struct Span{std::size_t a,b;};std::vector<Span> pending;pending.reserve(n);
            for(std::size_t k=1;k<anchors.size();++k){keep[anchors[k-1]]=true;pending.push_back({anchors[k-1],anchors[k]});}
            while(!pending.empty()){
                const auto span=pending.back();pending.pop_back();double error=0;std::size_t split=span.a;
                for(auto i=span.a+1;i<span.b;++i){geometry::charge(result.work,cap.work);const auto d=distance(loop[i%n],loop[span.a%n],loop[span.b%n]);if(d>error){error=d;split=i;}}
                // Leave half the physical budget for final SDK knot/frame rounding.
                if(error>tolerance*.5&&split>span.a){keep[split%n]=true;pending.push_back({span.a,split});pending.push_back({split,span.b});}
            }
            auto& indices=result.indices[r];indices.clear();reduced.emplace_back();
            for(std::size_t i=0;i<n;++i)if(keep[i]){indices.push_back(std::uint32_t(i));reduced.back().push_back(projected[r][i]);}
            if(indices.size()<3||area(projected[r])*area(reduced.back())<=0)return fallback("Reduction would collapse a contour: Exact snapshot retained");
        }
        geometry::SegmentIndex candidate(segments(reduced),&result.work,cap.work);
        if(!simple(candidate,reduced,result.work,cap.work))return fallback("Reduction would alter boundary contacts: Exact snapshot retained");
        for(std::size_t r=0;r<world.size();++r)if(depth(original,projected[r][0],std::uint32_t(r),result.work,cap.work)!=depth(candidate,reduced[r][0],std::uint32_t(r),result.work,cap.work))
            return fallback("Reduction would alter contour nesting: Exact snapshot retained");
        result.output=0;Loops published;published.reserve(world.size());
        for(std::size_t r=0;r<world.size();++r){published.emplace_back();for(auto i:result.indices[r])published.back().push_back(world[r][i]);result.output+=result.indices[r].size();}
        result.bound=spanCertificate(world,published,result,tolerance,cap.work-result.work);
        result.work+=result.input+result.output;
        result.optimized=result.output<result.input;result.reason=result.optimized?"Optimized independent planar spline":"No safe knot reduction was needed";
        return result;
    }catch(const geometry::WorkLimit&){return fallback("Geometry proof work allowance: Exact snapshot retained");}
}

static double spanCertificate(const Loops& original,const Loops& published,const Result& result,double tolerance,std::size_t workLimit){
    if(original.size()!=published.size()||original.size()!=result.indices.size())throw std::invalid_argument("Export certificate contour mismatch");
    double bound=0;std::size_t work=0;
    for(std::size_t r=0;r<original.size();++r){
        const auto& source=original[r];const auto& kept=result.indices[r];const auto& output=published[r];
        if(output.size()!=kept.size()||kept.size()<3||kept.front()!=0)throw std::invalid_argument("Export certificate knot mismatch");
        for(std::size_t k=0;k<kept.size();++k){const auto a=kept[k];const auto b=k+1<kept.size()?std::size_t(kept[k+1]):source.size();
            if(a>=source.size()||b<=a||b>source.size()||!finite(output[k]))throw std::invalid_argument("Invalid export certificate span");
            const double rounding=std::max(amin::length(source[a]-output[k]),amin::length(source[b%source.size()]-output[(k+1)%output.size()]));double deviation=0;
            for(auto i=std::size_t(a);i<=b;++i){geometry::charge(work,workLimit);deviation=std::max(deviation,distance(source[i%source.size()],source[a],source[b%source.size()]));}
            bound=std::max(bound,deviation+rounding);
        }
    }
    if(!std::isfinite(bound)||bound>tolerance)throw std::runtime_error("Maximum deviation cannot survive Max spline precision; use a larger tolerance or Exact snapshot");
    return bound;
}

double certify(const Loops& original,const Loops& published,const Result& result,double tolerance,std::size_t workLimit){
    const double bound=spanCertificate(original,published,result,tolerance,workLimit);
    if(original.empty())return bound;
    const auto origin=original.front().front();amin::Vec3 u{},normal{};double longest=0,bestNormal=0;
    for(const auto& loop:original)for(auto p:loop){const auto d=p-origin;const auto l=amin::dot(d,d);if(l>longest){longest=l;u=d;}}
    if(!(longest>0))throw std::runtime_error("Export certificate has a degenerate footprint");
    u=u*(1/std::sqrt(longest));
    for(const auto& loop:original)for(auto p:loop){const auto d=p-origin;const amin::Vec3 n{u.y*d.z-u.z*d.y,u.z*d.x-u.x*d.z,u.x*d.y-u.y*d.x};const double l=amin::dot(n,n);if(l>bestNormal){bestNormal=l;normal=n;}}
    if(!(bestNormal>0))throw std::runtime_error("Export certificate has no planar footprint");
    normal=normal*(1/std::sqrt(bestNormal));const amin::Vec3 v{normal.y*u.z-normal.z*u.y,normal.z*u.x-normal.x*u.z,normal.x*u.y-normal.y*u.x};
    const auto project=[&](const Loops& loops){std::vector<std::vector<geometry::Point2>> out;out.reserve(loops.size());
        for(const auto& loop:loops){out.emplace_back();out.back().reserve(loop.size());for(auto p:loop){const auto d=p-origin;out.back().push_back({amin::dot(d,u),amin::dot(d,v)});}}return out;};
    const auto source=project(original),output=project(published);
    std::size_t work=result.input+result.output;
    geometry::SegmentIndex before(segments(source),&work,workLimit),after(segments(output),&work,workLimit);
    if(!simple(after,output,work,workLimit))throw std::runtime_error("Max knot rounding would alter boundary topology; use Exact snapshot or move nearer the origin");
    for(std::size_t r=0;r<source.size();++r){
        if(area(source[r])*area(output[r])<=0||depth(before,source[r][0],std::uint32_t(r),work,workLimit)!=depth(after,output[r][0],std::uint32_t(r),work,workLimit))
            throw std::runtime_error("Max knot rounding would alter contour nesting; use Exact snapshot");
    }
    return bound;
}
}
