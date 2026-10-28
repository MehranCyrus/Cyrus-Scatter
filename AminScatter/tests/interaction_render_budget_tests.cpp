#include "interaction_render_budget.h"
#include <iostream>
#include <stdexcept>
using cyrus::interactions::RenderSizing;
void require(bool value){if(!value)throw std::runtime_error("Render chunk budget regression");}
template<class F>void rejects(F fn){bool caught=false;try{fn();}catch(const std::exception&){caught=true;}require(caught);}
int main(){try{
    RenderSizing s{100000,200000,400000,64000000};
    rejects([&]{s.admit(100);});require(s.capacity()==2&&s.chunks(100)==50);
    std::size_t count=0;for(std::size_t b=0;b<s.chunks(101);++b){const auto n=std::min(s.capacity(),101-count);require(s.admit(n)<=RenderSizing::maximumBytes);count+=n;}require(count==101);
    require(s.chunks(0)==0);RenderSizing huge{21000000,1,1,1};require(huge.capacity()==1);rejects([&]{huge.admit(1);});
    RenderSizing heavy{1,1,0,RenderSizing::maximumBytes+1};require(heavy.capacity()==1);rejects([&]{heavy.admit(1);});
    RenderSizing overflow{1,1,64,SIZE_MAX/2};rejects([&]{overflow.admit(3);});
    for(std::size_t bytes:{1000u,1000000u,100000000u})for(std::size_t n:{1u,13u,1000u}){
        RenderSizing varied{27501,40000,300000,bytes};std::size_t observed=0;
        for(std::size_t b=0;b<varied.chunks(n);++b){const auto used=std::min(varied.capacity(),n-observed);varied.admit(used);observed+=used;}require(observed==n);}
    std::cout<<"PASS bounded exact-render chunks, complete counts, empty and overflow admission\n";return 0;
}catch(const std::exception& e){std::cerr<<e.what()<<'\n';return 1;}}
