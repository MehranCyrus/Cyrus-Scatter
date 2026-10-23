#include "spline_bands.h"
#include "clipper2/clipper.h"
#include "segment_index.h"
#include <algorithm>
#include <atomic>
#include <cmath>
#include <limits>
#include <map>
#include <set>
#include <stdexcept>

namespace cyrus::bands {
namespace {
using namespace Clipper2Lib;
bool finite(amin::Vec3 p) { return std::isfinite(p.x)&&std::isfinite(p.y)&&std::isfinite(p.z); }
void require(bool ok,const char* message) { if(!ok) throw std::invalid_argument(message); }
void consume(std::size_t& used,std::size_t n,std::size_t cap,const char* message) {
    require(used<=cap && n<=cap-used,message);used+=n;
}
constexpr std::size_t aggregateBytes=512u*1024u*1024u,bookkeepingBytes=64u*1024u*1024u;
std::atomic<std::size_t> reservedBytes{0};
struct Reservation {
    std::size_t bytes=0;
    ~Reservation(){reservedBytes.fetch_sub(bytes,std::memory_order_relaxed);}
    void acquire(std::size_t wanted){
        auto used=reservedBytes.load(std::memory_order_relaxed);
        do {require(used<=aggregateBytes&&wanted<=aggregateBytes-used,"Retained and staged spline fields exceed the aggregate memory allowance; simplify fields or release unused setups");}
        while(!reservedBytes.compare_exchange_weak(used,used+wanted,std::memory_order_relaxed));
        bytes=wanted;
    }
    void retain(std::size_t wanted){require(wanted<=bytes,"Spline reservation accounting overflow");reservedBytes.fetch_sub(bytes-wanted,std::memory_order_relaxed);bytes=wanted;}
};
// Input admission is linear. The explicit clipping context admits produced
// storage and actual numerical work before those operations can grow memory.
void admitClip(std::size_t edges,Stats& stats,const Limits& limits){
    require(edges<=65536,"Spline clipping edge limit exceeded");
    consume(stats.constructionWork,edges,limits.constructionWork,"Spline construction work allowance exceeded; simplify Paths, curves or overlapping Bands");
    const auto bytes=edges*1024+2u*1024u*1024u;
    require(bytes<=limits.constructionBytes,"Spline construction scratch allowance exceeded; simplify Path geometry");
    stats.scratchAllowance=std::max(stats.scratchAllowance,bytes);
}
struct ClipOperation {
    Stats& stats;
    OperationBudget budget;
    ClipOperation(Stats& s,const Limits& limits):stats(s),budget(limits.constructionBytes,limits.constructionWork-s.constructionWork){}
    ~ClipOperation(){stats.constructionWork+=budget.work;stats.scratchAllowance=std::max(stats.scratchAllowance,budget.bytes);}
};
struct Point { double x=0,y=0; };
struct Region { std::vector<std::vector<Point>> loops; double x0=INFINITY,y0=INFINITY,x1=-INFINITY,y1=-INFINITY; std::shared_ptr<const geometry::SegmentIndex> index; };
struct Location { bool inside=false,boundary=false; double distance=INFINITY; };
Location locate(const Region& r,Point p,double epsilon,std::size_t& work,std::size_t limit,bool needDistance=false) {
    Location result;
    if(!needDistance && (p.x<r.x0-epsilon||p.x>r.x1+epsilon||p.y<r.y0-epsilon||p.y>r.y1+epsilon)) return result;
    if(r.index){
        result.distance=r.index->nearest({p.x,p.y},work,limit);
        r.index->ray({p.x,p.y},[&](std::uint32_t,const geometry::Segment2& s){
            const auto a=s.a,b=s.b;
            if((a.y>p.y)!=(b.y>p.y)&&p.x<a.x+(p.y-a.y)*(b.x-a.x)/(b.y-a.y))result.inside=!result.inside;
        },work,limit);
        result.boundary=result.distance<=epsilon;if(result.distance==0)result.inside=true;
        return result;
    }
    for(const auto& loop:r.loops) for(std::size_t i=0,j=loop.size()-1;i<loop.size();j=i++) {
        consume(work,1,limit,"Spline field query limit exceeded; reduce path complexity");
        const auto a=loop[j],b=loop[i];const double dx=b.x-a.x,dy=b.y-a.y,den=dx*dx+dy*dy;
        const double t=den>0?std::clamp(((p.x-a.x)*dx+(p.y-a.y)*dy)/den,0.,1.):0;
        const double distance=std::hypot(p.x-a.x-t*dx,p.y-a.y-t*dy);
        result.distance=std::min(result.distance,distance);
        if((a.y>p.y)!=(b.y>p.y) && p.x<a.x+(p.y-a.y)*dx/dy) result.inside=!result.inside;
    }
    result.boundary=result.distance<=epsilon;
    // Exact edge belongs to Inside. The larger uncertainty zone is reported,
    // not used to silently inflate geometric support.
    if(result.distance==0) result.inside=true;
    return result;
}
Region unpack(const Paths64& paths,double quantum,Stats& stats,const Limits& limits) {
    Region r;
    consume(stats.bytes,paths.size()*sizeof(std::vector<Point>),limits.bytes,"Spline field memory limit exceeded");
    r.loops.reserve(paths.size());
    for(const auto& path:paths) {
        if(path.size()<3) continue;
        consume(stats.vertices,path.size(),limits.vertices,"Spline offset vertex limit exceeded");
        consume(stats.bytes,path.size()*sizeof(Point),limits.bytes,"Spline field memory limit exceeded");
        std::vector<Point> loop;loop.reserve(path.size());
        for(auto p:path) {
            Point q{p.x*quantum,p.y*quantum};loop.push_back(q);
            r.x0=std::min(r.x0,q.x);r.y0=std::min(r.y0,q.y);r.x1=std::max(r.x1,q.x);r.y1=std::max(r.y1,q.y);
        }
        r.loops.push_back(std::move(loop));
    }
    return r;
}
Paths64 boolean(ClipType operation,const Paths64& a,const Paths64& b,Stats& stats,const Limits& limits,FillRule fill=FillRule::NonZero) {
    ClipOperation resources(stats,limits);
    Clipper64 clip(&resources.budget);
    std::size_t input=0;for(const auto& path:a)input+=path.size();for(const auto& path:b)input+=path.size();
    // Inputs beyond the former 720-point admission have no older accepted
    // representation to preserve. Exact redundant quantized vertices need not
    // multiply every Sharp level and displayed outline on these new admissions.
    if(input>720)clip.PreserveCollinear(false);
    clip.AddSubject(a);clip.AddClip(b);Paths64 output;
    if(!clip.Execute(operation,fill,output)) throw std::runtime_error("Spline polygon normalization failed");
    return output;
}
std::size_t vertices(const Paths64& paths) { std::size_t n=0;for(const auto& p:paths)n+=p.size();return n; }
struct Level { double q=0;Region region; };
struct PreparedPath {
    std::uint64_t id=0;Join join=Join::Rounded;Point origin;
    Region original;std::array<std::vector<Level>,2> levels;
};
struct Coordinate { bool available=false,boundary=false;double q=0,error=0; };
Coordinate coordinate(const PreparedPath& path,Point p,bool inside,double tolerance,std::size_t& work,const Limits& limits) {
    const auto original=locate(path.original,p,tolerance,work,limits.queryVisits,true);
    if(original.inside!=inside) return {};
    if(path.join==Join::Rounded) return {true,original.boundary,original.distance,0};
    const auto& levels=path.levels[inside?1:0];if(levels.empty()) return {};
    // Expanded families change false -> true, eroded families true -> false.
    // Ambiguous intermediate contours widen the bracket in BOTH searches.
    const auto crossed=[&](std::size_t i,bool definitely) {
        const auto where=locate(levels[i].region,p,tolerance,work,limits.queryVisits);
        if(where.boundary) return !definitely;
        return inside?!where.inside:where.inside;
    };
    const auto first=[&](bool definitely) {
        std::size_t lo=0,hi=levels.size();
        while(lo<hi) {const auto mid=lo+(hi-lo)/2;if(crossed(mid,definitely))hi=mid;else lo=mid+1;}
        return lo;
    };
    const auto possible=first(false),certain=first(true);
    if(possible==levels.size()) return {};
    const double lower=possible?levels[possible-1].q:0;
    const double upper=certain==levels.size()?levels.back().q:levels[certain].q;
    return {true,original.boundary||certain==levels.size(),(lower+upper)*.5,(upper-lower)*.5};
}
double slope(const std::vector<double>& values) {
    double s=0;for(std::size_t i=1;i<values.size();++i)s=std::max(s,std::abs(values[i]-values[i-1]));
    return s*double(values.size()-1);
}
void validateCurve(const std::vector<double>& values) {
    require(values.size()>=2&&values.size()<=257,"Band density curve needs 2..257 samples");
    for(double x:values)require(std::isfinite(x)&&x>=0&&x<=1,"Band density curve must be finite and in 0..1");
}
void validateScaleCurve(const std::vector<double>& values) {
    require(values.size()>=2&&values.size()<=257,"Band scale curve needs 2..257 samples");
    for(double x:values)require(std::isfinite(x)&&x>=0&&x<=100,"Band scale curve must be finite and in 0..100 (0..10000 percent)");
}
// Fields validate stored traces once at construction, outside candidate loops.
double sampleValidatedCurve(const std::vector<double>& values,double progress) {
    const double x=std::clamp(progress,0.,1.)*double(values.size()-1);
    const auto i=std::min(values.size()-2,std::size_t(x));
    return values[i]+(values[i+1]-values[i])*(x-double(i));
}
}

double curveValue(const std::vector<double>& values,double progress) {
    require(std::isfinite(progress),"Invalid Band progress");validateCurve(values);
    return sampleValidatedCurve(values,progress);
}
std::vector<amin::Vec3> tessellate(const std::vector<Cubic>& segments,double tolerance,std::size_t maxVertices) {
    require(std::isfinite(tolerance)&&tolerance>0,"Spline tessellation tolerance must be finite and positive");
    require(!segments.empty()&&segments.size()<=maxVertices&&maxVertices<=8192,"Spline segment budget exceeded");
    std::vector<amin::Vec3> output;output.reserve(std::min<std::size_t>(maxVertices,256));
    const auto same=[](amin::Vec3 a,amin::Vec3 b){return a.x==b.x&&a.y==b.y&&a.z==b.z;};
    const auto distance=[](amin::Vec3 p,amin::Vec3 a,amin::Vec3 b){
        const double dx=b.x-a.x,dy=b.y-a.y,n=dx*dx+dy*dy;
        require(std::isfinite(n),"Spline tessellation coordinate overflow");
        const double t=n?std::clamp(((p.x-a.x)*dx+(p.y-a.y)*dy)/n,0.,1.):0;
        return std::hypot(p.x-a.x-t*dx,p.y-a.y-t*dy);
    };
    std::size_t visits=0;
    struct Pending {Cubic curve;unsigned depth;};
    std::array<Pending,32> stack;
    for(std::size_t i=0;i<segments.size();++i){
        const auto& input=segments[i];for(auto p:{input.a,input.b,input.c,input.d})require(finite(p),"Nonfinite spline control point");
        require(same(input.d,segments[(i+1)%segments.size()].a),"Spline cubic chain is not closed");
        std::size_t count=1;stack[0]={input,0};
        while(count){
            consume(visits,1,maxVertices*2,"Spline tessellation work limit exceeded; simplify Path or widen narrow Bands");
            const auto current=stack[--count];const auto& c=current.curve;
            if(std::max(distance(c.b,c.a,c.d),distance(c.c,c.a,c.d))<=tolerance){
                require(output.size()<maxVertices,"Spline tessellation vertex limit exceeded; simplify Path or widen narrow Bands");
                output.push_back(c.a);continue;
            }
            require(current.depth<24,"Spline tessellation precision cannot be reached");
            const auto ab=c.a*.5+c.b*.5,bc=c.b*.5+c.c*.5,cd=c.c*.5+c.d*.5;
            const auto abc=ab*.5+bc*.5,bcd=bc*.5+cd*.5,middle=abc*.5+bcd*.5;
            stack[count++]={{middle,bcd,cd,c.d},current.depth+1};
            stack[count++]={{c.a,ab,abc,middle},current.depth+1};
        }
    }
    require(output.size()>=3,"Spline tessellation has no closed XY region");return output;
}
struct Field::Data {
    Reservation reservation;
    std::vector<PreparedPath> paths;
    std::vector<Band> bands;
    std::vector<std::size_t> pathIndices;
    std::vector<double> slopes,scaleSlopes,weights;
    Arrangement arrangement;Limits limits;Stats stats;
};

Field::Field(std::vector<Path> inputs,std::vector<Band> bands,Arrangement arrangement,const Limits& limits) {
    require(limits.paths<=32&&limits.bands<=64&&limits.inputVertices<=8192&&limits.memberships<=65536,"Spline admission limits exceed the supported maximum");
    require(std::isfinite(limits.quantum)&&limits.quantum>0,"Spline physical precision must be positive");
    require(std::isfinite(limits.aggregateError)&&limits.aggregateError>0&&limits.aggregateError<=.005,"Invalid aggregate Band error budget");
    require(std::isfinite(limits.progressError)&&limits.progressError>0&&limits.progressError<=1./256,"Invalid Band progress error budget");
    require(std::isfinite(limits.scaleError)&&limits.scaleError>0&&limits.scaleError<=.005,"Invalid Band scale error budget");
    require(inputs.size()<=limits.paths&&bands.size()<=limits.bands,"Spline Path/Band count limit exceeded");
    require(limits.bytes<=128u*1024u*1024u&&limits.constructionBytes<=256u*1024u*1024u&&limits.constructionWork<=250000000,"Spline resource limits exceed the supported maximum");
    auto data=std::make_shared<Data>();data->limits=limits;data->arrangement=arrangement;
    data->reservation.acquire(limits.bytes+limits.constructionBytes+bookkeepingBytes);
    std::map<std::uint64_t,std::size_t> pathIds;std::set<std::uint64_t> bandIds;
    for(std::size_t i=0;i<inputs.size();++i)require(inputs[i].id&&pathIds.emplace(inputs[i].id,i).second,"Duplicate or missing Path identity");
    if(arrangement==Arrangement::Independent)std::sort(bands.begin(),bands.end(),[](const Band& a,const Band& b){return a.id<b.id;});
    const double allocatedError=limits.aggregateError/double(std::max<std::size_t>(1,bands.size()));
    // Endpoints and bounded interior levels are shared by all Bands on a Path.
    std::vector<std::array<std::set<double>,2>> offsets(inputs.size());
    std::size_t totalLevels=0,totalMemberships=0;
    consume(data->stats.bytes,inputs.size()*sizeof(PreparedPath)+bands.size()*(sizeof(Band)+sizeof(std::size_t)+3*sizeof(double)),limits.bytes,"Spline field memory limit exceeded");
    for(auto& band:bands) {
        require(band.id&&bandIds.insert(band.id).second,"Duplicate or missing Band identity");
        const auto found=pathIds.find(band.path);require(found!=pathIds.end(),"Band has no Path");
        require(std::isfinite(band.start)&&std::isfinite(band.end)&&band.start>=0&&band.end>band.start,"Band needs 0 <= Start < End");
        require(std::isfinite(band.strength)&&band.strength>=0&&band.strength<=1,"Band strength must be in 0..1");
        require(std::isfinite(band.scale.min)&&std::isfinite(band.scale.max)&&band.scale.min>0&&band.scale.max>=band.scale.min,"Invalid Band scale range");
        validateCurve(band.curve);validateScaleCurve(band.scaleCurve);const double width=band.end-band.start;
        require(std::isfinite(band.scale.max * *std::max_element(band.scaleCurve.begin(),band.scaleCurve.end())),"Band scale multiplier overflow");
        require(limits.quantum*8<=width*limits.progressError,"Band is too narrow for the declared physical precision");
        consume(totalMemberships,band.sources.size(),limits.memberships,"Band source-membership limit exceeded");
        consume(data->stats.bytes,band.sources.size()*sizeof(Source)+(band.curve.size()+band.scaleCurve.size())*sizeof(double),limits.bytes,"Spline field memory limit exceeded");
        std::set<std::string> sourceIds;double total=0;
        for(const auto& source:band.sources) {
            require(!source.id.empty()&&source.id.size()<=128&&sourceIds.insert(source.id).second,"Duplicate, missing or oversized Band source identity");
            consume(data->stats.bytes,source.id.size()+1,limits.bytes,"Spline field memory limit exceeded");
            require(std::isfinite(source.weight)&&source.weight>=0,"Invalid Band source weight");total+=source.weight;
        }
        require(std::isfinite(total),"Band source weight overflow");
        if(arrangement==Arrangement::Independent)std::sort(band.sources.begin(),band.sources.end(),[](const Source& a,const Source& b){return a.id<b.id;});
        data->pathIndices.push_back(found->second);data->slopes.push_back(slope(band.curve));data->weights.push_back(total);
        data->scaleSlopes.push_back(slope(band.scaleCurve));
        if(inputs[found->second].join==Join::Sharp) {
            auto& levels=offsets[found->second][band.inside?1:0];
            const auto add=[&](double q) {if(levels.find(q)==levels.end()){consume(totalLevels,1,limits.levels,"Aggregate Sharp level limit exceeded");levels.insert(q);}};
            add(0);add(band.start);add(band.end);
            // Quarter-size intervals leave room for an ambiguous intermediate
            // contour and its two adjacent decisive levels without losing the
            // advertised per-query error bound. No offsets are made at query time.
            // Scale uses this same certified coordinate without changing its
            // subdivision: editing size must not perturb density/owner lotteries.
            // A scale trace too steep for a queried bracket fails explicitly.
            const double error=std::min(limits.progressError,band.strength*data->slopes.back()>0?allocatedError/(band.strength*data->slopes.back()):limits.progressError);
            const double segments=std::ceil(4/error);
            require(std::isfinite(segments)&&segments<=double(limits.levels),"Sharp curve accuracy exceeds level budget; simplify curve or overlap");
            for(std::size_t k=1;k<std::size_t(segments);++k)add(band.start+width*(double(k)/segments));
            require(levels.size()<=limits.levels,"Sharp offset level limit exceeded");
        }
    }
    data->bands=std::move(bands);data->paths.reserve(inputs.size());
    for(std::size_t i=0;i<inputs.size();++i) {
        const auto& input=inputs[i];PreparedPath path;path.id=input.id;path.join=input.join;
        require(!input.area.loops.empty()&&!input.area.loops.front().empty(),"Spline Path is empty");
        path.origin={input.area.loops.front().front().x,input.area.loops.front().front().y};
        Paths64 raw;Region rounded;
        for(const auto& loop:input.area.loops) {
            require(loop.size()>=3,"Spline Path needs a closed polygon");
            consume(data->stats.inputVertices,loop.size(),limits.inputVertices,"Spline input vertex limit exceeded");
            Path64 packed;packed.reserve(loop.size());std::vector<Point> exact;exact.reserve(loop.size());double twiceArea=0;
            for(auto p:loop) {
                require(finite(p),"Nonfinite spline point");const double x=(p.x-path.origin.x)/limits.quantum,y=(p.y-path.origin.y)/limits.quantum;
                require(std::isfinite(x)&&std::isfinite(y)&&std::max(std::abs(x),std::abs(y))<=1e12,"Spline coordinates exceed declared precision");
                const Point64 q{std::llround(x),std::llround(y)};if(packed.empty()||q!=packed.back())packed.push_back(q);
                const Point local{p.x-path.origin.x,p.y-path.origin.y};exact.push_back(local);
                rounded.x0=std::min(rounded.x0,local.x);rounded.y0=std::min(rounded.y0,local.y);rounded.x1=std::max(rounded.x1,local.x);rounded.y1=std::max(rounded.y1,local.y);
            }
            if(packed.size()>1&&packed.front()==packed.back())packed.pop_back();
            require(packed.size()>=3,"Spline Path collapses at declared precision");raw.push_back(std::move(packed));
            if(input.join==Join::Rounded){
                for(std::size_t j=0;j<exact.size();++j){const auto a=exact[j],b=exact[(j+1)%exact.size()];twiceArea+=a.x*b.y-b.x*a.y;}
                require(std::abs(twiceArea)>1e-12,"Rounded Path has no XY footprint");
                consume(data->stats.vertices,exact.size(),limits.vertices,"Spline vertex limit exceeded");
                consume(data->stats.bytes,exact.size()*sizeof(Point)+sizeof(std::vector<Point>),limits.bytes,"Spline field memory limit exceeded");
                rounded.loops.push_back(std::move(exact));
            }
        }
        admitClip(vertices(raw),data->stats,limits);
        auto normalized=boolean(ClipType::Union,raw,{},data->stats,limits,FillRule::EvenOdd);
        require(!normalized.empty(),"Spline has no filled XY region");
        require(vertices(normalized)<=limits.inputVertices,"Normalized spline vertex limit exceeded");
        // Rounded keeps the actual sampled segments, including exact floating
        // coordinates. Sharp alone consumes normalized quantized contours.
        path.original=input.join==Join::Rounded?std::move(rounded):unpack(normalized,limits.quantum,data->stats,limits);
        if(input.join==Join::Rounded&&vertices(raw)>=64){
            std::vector<geometry::Segment2> segments;
            for(std::size_t r=0;r<path.original.loops.size();++r){const auto& loop=path.original.loops[r];
                for(std::size_t j=0;j<loop.size();++j){const auto a=loop[j],b=loop[(j+1)%loop.size()];segments.push_back({{a.x,a.y},{b.x,b.y},std::uint32_t(r),std::uint32_t(j)});}}
            path.original.index=std::make_shared<const geometry::SegmentIndex>(std::move(segments),&data->stats.constructionWork,limits.constructionWork);
            consume(data->stats.bytes,path.original.index->bytes(),limits.bytes,"Spline query index memory allowance exceeded");
        }
        for(std::size_t side=0;side<2;++side) {
            consume(data->stats.levels,offsets[i][side].size(),limits.levels,"Aggregate Sharp level limit exceeded");
            consume(data->stats.bytes,offsets[i][side].size()*sizeof(Level),limits.bytes,"Spline field memory limit exceeded");
            path.levels[side].reserve(offsets[i][side].size());Paths64 previous;
            for(double q:offsets[i][side]) {
                require(q/limits.quantum<=1e12,"Sharp offset exceeds declared precision");
                Paths64 shape;
                if(q==0)shape=normalized;
                else {
                    admitClip(vertices(normalized)*3,data->stats,limits);
                    ClipOperation resources(data->stats,limits);
                    ClipperOffset offset(2,0,false,false,&resources.budget);offset.AddPaths(normalized,JoinType::Miter,EndType::Polygon);
                    offset.Execute((side?-q:q)/limits.quantum,shape);
                    if(offset.ErrorCode())throw std::runtime_error("Sharp polygon offset failed; empty output is not collapse");
                }
                require(vertices(shape)<=limits.vertices,"Sharp level vertex limit exceeded");
                if(!path.levels[side].empty()) {
                    admitClip(vertices(shape)+vertices(previous),data->stats,limits);
                    const auto difference=side?boolean(ClipType::Difference,shape,previous,data->stats,limits):boolean(ClipType::Difference,previous,shape,data->stats,limits);
                    require(difference.empty(),"Sharp offset family is not nested at the declared precision");
                }
                path.levels[side].push_back({q,unpack(shape,limits.quantum,data->stats,limits)});previous=std::move(shape);
            }
        }
        data->paths.push_back(std::move(path));
    }
    // Retain actual container capacities, not just element counts. Temporary
    // preparation containers are covered by the larger construction reservation.
    std::size_t retained=sizeof(Data)+128+data->paths.capacity()*sizeof(PreparedPath)+data->bands.capacity()*sizeof(Band)+data->pathIndices.capacity()*sizeof(std::size_t)+(data->slopes.capacity()+data->scaleSlopes.capacity()+data->weights.capacity())*sizeof(double);
    const auto regionBytes=[](const Region& r){std::size_t bytes=r.loops.capacity()*sizeof(std::vector<Point>);for(const auto& loop:r.loops)bytes+=loop.capacity()*sizeof(Point);if(r.index)bytes+=r.index->bytes();return bytes;};
    for(const auto& path:data->paths){retained+=regionBytes(path.original);for(const auto& side:path.levels){retained+=side.capacity()*sizeof(Level);for(const auto& level:side)retained+=regionBytes(level.region);}}
    for(const auto& band:data->bands){retained+=(band.curve.capacity()+band.scaleCurve.capacity())*sizeof(double)+band.sources.capacity()*sizeof(Source);for(const auto& source:band.sources)retained+=source.id.capacity()+1;}
    require(retained<=limits.bytes,"Spline retained capacity exceeds its memory allowance");data->stats.bytes=retained;
    std::vector<Path>().swap(inputs);std::vector<Band>().swap(bands);decltype(offsets)().swap(offsets);pathIds.clear();bandIds.clear();
    data->reservation.retain(retained);data_=std::move(data);
}
std::size_t reservedFieldBytes(){return reservedBytes.load(std::memory_order_relaxed);}

bool Field::hasBand(std::uint64_t id) const {
    return std::any_of(data_->bands.begin(),data_->bands.end(),[&](const Band& b){return b.id==id;});
}
OutlineStats Field::visitOutlines(std::uint64_t selected,
    const std::function<void(amin::Vec3,amin::Vec3)>& emit,const OutlineLimits& cap) const {
    require(!selected||hasBand(selected),"Selected Band no longer exists");
    require(cap.segments<=32768&&cap.work<=50000000&&cap.bytes<=128u*1024u*1024u,
        "Field outline limits exceed the supported maximum");
    require(bool(emit),"Field outline visitor is missing");
    const auto& data=*data_;OutlineStats result;Stats scratch;
    Limits limits=data.limits;limits.constructionWork=cap.work;limits.constructionBytes=cap.bytes;
    Reservation reservation;bool reserved=false;
    const auto reserve=[&]{if(!reserved){reservation.acquire(cap.bytes);reserved=true;}};
    const auto send=[&](const Region& region,const PreparedPath& path) {
        for(const auto& loop:region.loops){
            consume(result.segments,loop.size(),cap.segments,"Field boundary display exceeds 32,768 segments; simplify Paths or select one Band");
            for(std::size_t i=0;i<loop.size();++i){const auto a=loop[i],b=loop[(i+1)%loop.size()];
                emit({a.x+path.origin.x,a.y+path.origin.y,0},{b.x+path.origin.x,b.y+path.origin.y,0});}
        }
    };
    for(std::size_t p=0;p<data.paths.size();++p){
        const auto& path=data.paths[p];std::array<std::map<double,double>,2> offsets;
        for(std::size_t i=0;i<data.bands.size();++i){const auto& band=data.bands[i];
            if(data.pathIndices[i]!=p||(selected&&band.id!=selected))continue;
            // Tolerance is tied to the narrowest Band sharing this contour.
            const double tolerance=std::max(4*limits.quantum,(band.end-band.start)/256);
            for(double q:{band.start,band.end}){
                auto [at,added]=offsets[q==0?0:(band.inside?1:0)].emplace(q,tolerance);
                if(!added)at->second=std::min(at->second,tolerance);
            }
        }
        if(offsets[0].empty()&&offsets[1].empty())continue;
        Paths64 raw,normalized;
        if(path.join==Join::Rounded){
            reserve();raw.reserve(path.original.loops.size());
            for(const auto& loop:path.original.loops){Path64 packed;packed.reserve(loop.size());
                for(auto pt:loop)packed.emplace_back(std::llround(pt.x/limits.quantum),std::llround(pt.y/limits.quantum));
                raw.push_back(std::move(packed));}
            admitClip(vertices(raw),scratch,limits);
            normalized=boolean(ClipType::Union,raw,{},scratch,limits,FillRule::EvenOdd);
        }
        for(std::size_t side=0;side<2;++side)for(const auto [q,tolerance]:offsets[side]){
            ++result.levels;
            if(path.join==Join::Sharp){
                if(q==0){send(path.original,path);result.error=std::max(result.error,4*limits.quantum);continue;}
                const auto& levels=path.levels[side];
                const auto found=std::lower_bound(levels.begin(),levels.end(),q,[](const Level& a,double b){return a.q<b;});
                require(found!=levels.end()&&found->q==q,"Prepared Sharp endpoint is missing");
                send(found->region,path);result.error=std::max(result.error,4*limits.quantum);continue;
            }
            Paths64 shape;
            if(q==0)shape=normalized;
            else {
                require(std::isfinite(q/limits.quantum)&&q/limits.quantum<=1e12,"Boundary offset exceeds declared precision");
                // Joined polylines form tubes around ALL original segments.
                // Offsetting only the normalized filled polygon would lose
                // internal segments that still participate in Rounded distance.
                const double delta=q/limits.quantum,arc=std::min(tolerance/limits.quantum,delta*.25);
                constexpr double pi=3.14159265358979323846;
                const double steps=std::ceil(pi/std::acos(1-arc/delta));
                require(std::isfinite(steps)&&steps<=32768,"Rounded boundary accuracy exceeds the display allowance");
                // Bound the actual turns, rather than pretending every corner
                // sweeps a full circle. Ordinary joins have one rounded and
                // one three-vertex concave side; reversals round BOTH sides.
                // Extra vertices cover zero-length/straight quantized joins.
                // This preflight follows this bundled Clipper's Joined path.
                std::size_t edges=0;
                for(const auto& loop:raw)for(std::size_t j=0;j<loop.size();++j){
                    const auto prev=loop[(j+loop.size()-1)%loop.size()],at=loop[j],next=loop[(j+1)%loop.size()];
                    const double ax=double(at.x-prev.x),ay=double(at.y-prev.y),bx=double(next.x-at.x),by=double(next.y-at.y);
                    const double divisor=std::hypot(ax,ay)*std::hypot(bx,by);
                    if(divisor==0){edges+=std::size_t(steps)+8;continue;}
                    const double cosine=std::clamp((ax*bx+ay*by)/divisor,-1.,1.);
                    const double angle=std::acos(cosine);
                    const auto roundVertices=std::size_t(std::ceil(steps*angle/(2*pi)))+2;
                    edges+=cosine<=-.998?2*roundVertices+4:roundVertices+4;
                }
                admitClip(edges,scratch,limits);
                Paths64 tube;
                {
                    ClipOperation resources(scratch,limits);
                    ClipperOffset offset(2,arc,false,false,&resources.budget);offset.AddPaths(raw,JoinType::Round,EndType::Joined);
                    offset.Execute(delta,tube);
                    if(offset.ErrorCode())throw std::runtime_error("Rounded boundary construction failed");
                }
                admitClip(vertices(tube)+vertices(normalized),scratch,limits);
                shape=boolean(side?ClipType::Difference:ClipType::Union,normalized,tube,scratch,limits);
            }
            // Clipper output remains ephemeral. Bound conversion and callback
            // work before allocating a second representation of the contours.
            const auto n=vertices(shape);
            require(n<=cap.segments-result.segments,"Field boundary display exceeds 32,768 segments; simplify Paths or select one Band");
            Stats unpackStats;Limits unpackLimits=limits;unpackLimits.vertices=cap.segments;unpackLimits.bytes=cap.bytes;
            auto region=unpack(shape,limits.quantum,unpackStats,unpackLimits);send(region,path);
            result.error=std::max(result.error,(q==0?0:tolerance)+4*limits.quantum);
        }
    }
    result.work=scratch.constructionWork;result.scratchAllowance=scratch.scratchAllowance;return result;
}

Inspection Field::inspect(amin::Vec3 position,std::size_t visitLimit) const {
    require(finite(position),"Nonfinite spline query");const auto& data=*data_;Inspection result;
    auto queryLimits=data.limits;queryLimits.queryVisits=std::min(queryLimits.queryVisits,visitLimit);
    std::array<std::array<Coordinate,2>,32> coordinates{};
    std::array<std::array<bool,2>,32> ready{};
    for(std::size_t i=0;i<data.bands.size();++i) {
        const auto& band=data.bands[i];const auto index=data.pathIndices[i];const auto& path=data.paths[index];const std::size_t side=band.inside?1:0;
        const Point p{position.x-path.origin.x,position.y-path.origin.y};const double tolerance=4*data.limits.quantum;
        if(!ready[index][side]) {coordinates[index][side]=coordinate(path,p,band.inside,tolerance,result.visits,queryLimits);ready[index][side]=true;}
        const auto c=coordinates[index][side];if(!c.available)continue;
        bool support=c.q>=band.start&&c.q<=band.end;bool boundary=c.boundary;
        if(path.join==Join::Sharp) {
            const auto& levels=path.levels[side];
            const auto at=[&](double q) {const auto found=std::lower_bound(levels.begin(),levels.end(),q,[](const Level& a,double b){return a.q<b;});return locate(found->region,p,tolerance,result.visits,queryLimits.queryVisits);};
            const auto begin=at(band.start),end=at(band.end);boundary|=begin.boundary||end.boundary;
            const bool beginEdge=begin.distance==0,endEdge=end.distance==0;
            support=band.inside?begin.inside&&(!end.inside||endEdge):end.inside&&(!begin.inside||beginEdge);
        }
        if(!support)continue;
        const double width=band.end-band.start,t=std::clamp((c.q-band.start)/width,0.,1.);
        const double error=band.strength*data.slopes[i]*c.error/width;
        // At authored support boundaries the declared geometric uncertainty is
        // exposed; elsewhere a wide ambiguous bracket must fail, never guess.
        if(!boundary) {
            require(c.error/width<=data.limits.progressError,"Sharp progress cannot be certified at this point");
            require(error<=data.limits.aggregateError/double(std::max<std::size_t>(1,data.bands.size())),"Sharp density error budget exceeded");
            require(data.scaleSlopes[i]*c.error/width<=data.limits.scaleError,"Sharp scale error budget exceeded");
        }
        const double value=data.weights[i]>0?band.strength*sampleValidatedCurve(band.curve,t):0;
        result.contributions.push_back({band.id,value,t,data.weights[i]>0?error:0,boundary});result.occupancy+=value;result.error+=data.weights[i]>0?error:0;
        if(data.arrangement==Arrangement::Consecutive)break; // Empty owner reserves its interval.
    }
    result.occupancy=std::min(1.,result.occupancy);return result;
}
Decision Field::select(amin::Vec3 position,double occupancy,double owner,double source,double scale) const {
    for(double x:{occupancy,owner,source,scale})require(std::isfinite(x)&&x>=0&&x<1,"Band random channels must be in [0,1)");
    const auto field=inspect(position);Decision result;result.occupancy=field.occupancy;
    if(occupancy>=field.occupancy)return result;
    double sum=0;for(const auto& c:field.contributions)sum+=c.value;
    double cursor=owner*sum;const Contribution* selected=nullptr;
    for(const auto& c:field.contributions)if(c.value>0) {selected=&c;cursor-=c.value;if(cursor<0)break;}
    if(!selected)return result;
    const auto found=std::find_if(data_->bands.begin(),data_->bands.end(),[&](const Band& b){return b.id==selected->band;});
    const auto index=std::size_t(found-data_->bands.begin());cursor=source*data_->weights[index];const Source* model=nullptr;
    for(const auto& s:found->sources)if(s.weight>0) {model=&s;cursor-=s.weight;if(cursor<0)break;}
    if(!model)return result;
    result.band=found->id;result.source=model->index;result.sourceId=model->id;result.emitted=!model->empty;
    result.scale=(found->scale.min+(found->scale.max-found->scale.min)*scale)*sampleValidatedCurve(found->scaleCurve,selected->progress);return result;
}
const Stats& Field::stats() const { return data_->stats; }
Decision Field::sample(amin::Vec3 position,std::uint32_t seed,std::uint64_t ordinal,std::uint64_t receiver) const {
    // Separate keyed channels. Changes in source count, acceptance, scale or
    // traversal order never consume another channel's state.
    return select(position,amin::stableUnit(seed,ordinal,101,receiver),amin::stableUnit(seed,ordinal,102,receiver),
                  amin::stableUnit(seed,ordinal,103,receiver),amin::stableUnit(seed,ordinal,104,receiver));
}

}
