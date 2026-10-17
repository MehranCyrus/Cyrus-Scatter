// Allocation failure seam belongs to this executable only. No product fault
// switch or replacement allocator is linked into any Max plugin/package.
#include "placement_store.h"
#include <cstdlib>
#include <cstdio>
#include <new>
#include <stdexcept>
namespace {thread_local long failAfter=-1;}
void* operator new(std::size_t n) {
    if(failAfter==0)throw std::bad_alloc();if(failAfter>0)--failAfter;
    if(auto* p=std::malloc(n?n:1))return p;throw std::bad_alloc();
}
void* operator new[](std::size_t n){return ::operator new(n);}
void operator delete(void* p) noexcept {std::free(p);}
void operator delete[](void* p) noexcept {std::free(p);}
void operator delete(void* p,std::size_t) noexcept {std::free(p);}
void operator delete[](void* p,std::size_t) noexcept {std::free(p);}
using namespace cyrus::placements;
namespace {
void check(bool v){if(!v)std::abort();}
Record row(std::uint64_t id){Record r;r.identity=id;r.transform={1,0,0,0,1,0,0,0,1,2,3,4};return r;}
template<class F> void exhaust(const View& old,F operation) {
    const auto before=metrics();const auto token=old.token();int failures=0;bool passed=false;
    for(long n=0;n<150&&!passed;++n) {
        try{failAfter=n;{auto successor=operation();check(successor.size()>0);}failAfter=-1;passed=true;}
        catch(const std::bad_alloc&){failAfter=-1;++failures;}
        catch(...){failAfter=-1;throw;}
        check(old.token()==token&&old.size()==3&&old.textIdentity(1)=="copy:original"&&old.at(0).transform[9]==2);
        const auto after=metrics();check(after.liveBytes==before.liveBytes&&after.liveAllocations==before.liveAllocations&&after.liveStores==before.liveStores&&after.liveSelections==before.liveSelections);
    }
    check(passed&&failures>0);std::printf("%d allocation boundaries rejected without predecessor change or leak\n",failures);
}
}
int main(){try{
    const auto start=metrics();
    {
        Builder b(newOwner(),Stage::Edited,1,3);b.appendGenerated(row(1));b.appendAuthored(row(0),"copy:original");b.appendGenerated(row(3));auto old=b.freeze();
        exhaust(old,[&]{return old.compact();});
        exhaust(old,[&]{return old.select({2,0});});
        exhaust(old,[&]{Builder next(old);auto changed=next.get(0);changed.transform[9]=5;next.replace(0,changed);next.appendAuthored(row(0),"copy:successor");return next.freeze();});
        // Keep using a builder after an interrupted new-ID append. Capacity may
        // legitimately have grown, but membership and previous values stay valid.
        for(long n=0;n<20;++n) {
            Builder next(old);const auto count=next.size();
            try{failAfter=n;next.appendAuthored(row(0),"copy:retry-after-failure");failAfter=-1;}
            catch(const std::bad_alloc&){failAfter=-1;check(next.size()==count);next.appendAuthored(row(0),"copy:retry-after-failure");}
            auto complete=next.freeze();check(complete.size()==4&&complete.textIdentity(3)=="copy:retry-after-failure");
        }
    }
    check(metrics().liveBytes==start.liveBytes&&metrics().liveStores==start.liveStores&&metrics().liveSelections==start.liveSelections);
    std::puts("Native placement allocation-failure, retry and last-owner release passed");return 0;
}catch(const std::exception& e){failAfter=-1;std::fprintf(stderr,"%s\n",e.what());return 1;}}
