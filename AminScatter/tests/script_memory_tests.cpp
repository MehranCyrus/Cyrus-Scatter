#include "script_memory_budget.h"
#include <iostream>
#include <limits>
#include <stdexcept>
using cyrus::script_memory::target;
void require(bool v){if(!v)throw std::runtime_error("workspace accounting assertion");}
template<class F> void rejects(F f){bool failed=false;try{f();}catch(const std::exception&){failed=true;}require(failed);}
int main(){try{
    constexpr std::uint64_t MiB=1024*1024,commit=8ULL*1024*MiB;
    cyrus::script_memory::admitNative(0,256*MiB);
    cyrus::script_memory::admitNative(commit-256*MiB,commit);
    rejects([&]{cyrus::script_memory::admitNative(1,256*MiB);});
    rejects([&]{cyrus::script_memory::admitNative(0,255*MiB);});
    rejects([&]{cyrus::script_memory::admitNative(std::numeric_limits<std::uint64_t>::max(),commit);});
    require(target(100*MiB,60*MiB,40*MiB,commit)==100*MiB);
    auto next=target(100*MiB,54*MiB,140*MiB,commit);
    require(next==256*MiB&&54*MiB+(next-100*MiB)>=140*MiB);
    require(target(next,210*MiB,140*MiB,commit)==next);
    require(target(512*MiB,64*MiB,2752000000ULL,commit)>2752000000ULL);
    rejects([&]{target(100*MiB,101*MiB,140*MiB,commit);});
    rejects([&]{target(100*MiB,54*MiB,140*MiB,300*MiB);});
    rejects([&]{target(std::numeric_limits<std::uint64_t>::max()-16,0,100,commit);});
    rejects([&]{target(100*MiB,0,std::numeric_limits<std::uint64_t>::max(),commit);});
    rejects([&]{target(std::uint64_t(std::numeric_limits<std::int64_t>::max()),0,MiB,std::numeric_limits<std::uint64_t>::max());});
    std::cout<<"Session workspace reuse, bounded growth, commit reserve and overflow passed\n";return 0;
}catch(const std::exception& e){std::cerr<<e.what();return 1;}}
