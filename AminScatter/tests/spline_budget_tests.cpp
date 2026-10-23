#include "spline_bands.h"
#include "segment_index.h"
#include "clipper2/clipper.h"
#include <cmath>
#include <iostream>
#include <stdexcept>
#include <cstdlib>
#include <new>
#include <cstddef>

// Executable-only allocation probes: no fault controls enter a shipping module.
namespace {
    struct alignas(std::max_align_t) Allocation {std::size_t bytes;};
    std::size_t liveBytes=0,peakBytes=0;
    long failAfter=-1;
}
void* operator new(std::size_t bytes){
    if(failAfter==0)throw std::bad_alloc();
    if(failAfter>0)--failAfter;
    auto* block=static_cast<Allocation*>(std::malloc(sizeof(Allocation)+(bytes?bytes:1)));
    if(!block)throw std::bad_alloc();
    block->bytes=bytes;liveBytes+=bytes;peakBytes=(std::max)(peakBytes,liveBytes);
    return block+1;
}
void* operator new[](std::size_t bytes){return ::operator new(bytes);}
void operator delete(void* pointer)noexcept{if(pointer){auto* block=static_cast<Allocation*>(pointer)-1;liveBytes-=block->bytes;std::free(block);}}
void operator delete[](void* pointer)noexcept{::operator delete(pointer);}
void operator delete(void* pointer,std::size_t)noexcept{::operator delete(pointer);}
void operator delete[](void* pointer,std::size_t)noexcept{::operator delete(pointer);}

static void check(bool value,const char* reason){if(!value)throw std::runtime_error(reason);}
int main(){try{
    using namespace Clipper2Lib;using namespace cyrus::bands;
    Paths64 input(1);for(int i=0;i<8192;++i){const double a=6.2831853071795864769*i/8192;input[0].push_back({std::llround(std::cos(a)*1000000),std::llround(std::sin(a)*1000000)});}
    {
        OperationBudget budget(256u*1024u*1024u,250000000);Paths64 output;
        {Clipper64 clip(&budget);clip.AddSubject(input);check(clip.Execute(ClipType::Union,FillRule::EvenOdd,output),"Dense governed union failed");}
        check(!output.empty()&&budget.bytes<=budget.byteLimit&&budget.work<=budget.workLimit,"Clipping admission failed");
        check(budget.outstanding.empty(),"Normal clipping left detached points");
    }
    // Fail at successive production allowances. No context escapes the loop;
    // destructors must remain safe when partially linked geometry is rejected.
    Paths64 crossing{{{0,0},{1000,1000},{0,1000},{1000,0},{500,-500},{500,1500}}};
    for(std::size_t steps=0;steps<128;++steps){
        OperationBudget budget(2u*1024u*1024u+steps*1024,250000000);
        try{Clipper64 clip(&budget);clip.AddSubject(crossing);Paths64 output;clip.Execute(ClipType::Union,FillRule::EvenOdd,output);}catch(const std::runtime_error&){}
    }
    Paths64 oracle;{Clipper64 clip;clip.AddSubject(crossing);check(clip.Execute(ClipType::Union,FillRule::EvenOdd,oracle),"Null-context oracle failed");}
    bool success=false;int failures=0;
    for(long boundary=0;boundary<2000&&!success;++boundary){
        const auto before=liveBytes;peakBytes=before;
        try{
            OperationBudget budget(256u*1024u*1024u,250000000);
            failAfter=boundary;
            {Clipper64 clip(&budget);Paths64 output;clip.AddSubject(crossing);check(clip.Execute(ClipType::Union,FillRule::EvenOdd,output),"Fault retry failed");check(output==oracle,"Governed clipping changed exact geometry/order");}
            failAfter=-1;check(peakBytes-before<=budget.bytes,"Actual allocation peak exceeded admitted envelope");success=true;
        }catch(const std::bad_alloc&){failAfter=-1;++failures;}
        catch(...){failAfter=-1;throw;}
        check(liveBytes==before,"Clipping allocation failure leaked storage");
    }
    check(success&&failures>20,"Allocation campaign did not traverse the engine");
    success=false;failures=0;
    for(std::size_t allowance=0;allowance<20000&&!success;++allowance){
        const auto before=liveBytes;
        try{OperationBudget budget(256u*1024u*1024u,allowance);Clipper64 clip(&budget);Paths64 output;clip.AddSubject(crossing);clip.Execute(ClipType::Union,FillRule::EvenOdd,output);check(output==oracle,"Work retry geometry changed");success=true;}
        catch(const std::runtime_error&){++failures;}
        check(liveBytes==before,"Clipping work failure leaked storage");
    }
    check(success&&failures>100,"Work campaign did not traverse the engine");
    // The index is a broad phase only: compare it with an independent complete
    // segment scan at ordinary and translated large coordinates, including ties.
    for(double origin:{0.,1.e9}){
        std::vector<cyrus::geometry::Segment2> edges;
        for(int i=0;i<512;++i){const double a=6.2831853071795864769*i/512,b=6.2831853071795864769*(i+1)/512;
            edges.push_back({{origin+100*std::cos(a),origin+70*std::sin(a)},{origin+100*std::cos(b),origin+70*std::sin(b)},0,std::uint32_t(i)});}
        cyrus::geometry::SegmentIndex index(edges);
        for(int sample=0;sample<1024;++sample){
            const cyrus::geometry::Point2 point{origin+((sample*67)%401)-200.,origin+((sample*101)%401)-200.};
            double brute=INFINITY;int crossings=0,indexedCrossings=0;std::size_t work=0;
            for(const auto& edge:edges){brute=(std::min)(brute,cyrus::geometry::segmentDistance(point,edge.a,edge.b));
                if((edge.a.y>point.y)!=(edge.b.y>point.y)&&point.x<edge.a.x+(point.y-edge.a.y)*(edge.b.x-edge.a.x)/(edge.b.y-edge.a.y))++crossings;}
            check(index.nearest(point,work,100000)==brute,"Index pruned a nearest segment");
            index.ray(point,[&](std::uint32_t,const cyrus::geometry::Segment2& edge){
                if((edge.a.y>point.y)!=(edge.b.y>point.y)&&point.x<edge.a.x+(point.y-edge.a.y)*(edge.b.x-edge.a.x)/(edge.b.y-edge.a.y))++indexedCrossings;},work,100000);
            check(indexedCrossings==crossings,"Index changed ray crossing parity");
        }
    }
    cyrus::bands::Path path;path.id=1;path.join=Join::Rounded;path.area.loops.emplace_back();
    for(int i=0;i<8192;++i){const double a=6.2831853071795864769*i/8192;path.area.loops[0].push_back({std::cos(a)*100,std::sin(a)*100,0});}
    Band band;band.id=1;band.path=1;band.inside=true;band.end=20;band.sources.push_back({"model",0,1,false});
    const auto before=reservedFieldBytes();
    {Field field({path},{band},Arrangement::Consecutive);const auto q=field.inspect({95,0,0});check(q.occupancy==1,"Dense index lost membership");check(!field.inspect({0,0,0}).occupancy,"Dense index inflated support");}
    check(reservedFieldBytes()==before,"Dense field reservation leaked");
    std::cout<<"PASS 8192 governed clipping/index and successive admission failures\n";return 0;
}catch(const std::exception& e){std::cerr<<e.what()<<'\n';return 1;}}
