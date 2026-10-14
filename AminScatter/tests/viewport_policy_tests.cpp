#include "viewport_policy.h"
#include "preview_budget.h"
#include <iostream>
#include <random>
#include <set>
#include <stdexcept>

void require(bool value,const char* message){if(!value)throw std::runtime_error(message);}
int main() {
    try {
        using namespace cyrus;
        require(pointPreviewPreparationLimit>0,"point preparation must have a usable capacity");
        require(pointPreviewPreparationLimit*100+8ull*1024*1024<=pointPreviewOwnerLimit,"point preparation and retained copies must fit owner admission");
        const std::vector<ViewportDemand> garden={{100000,800},{22,1500000},{5,700000},{6000,4000}};
        auto all=viewportQuotas(garden,0,true);
        for(std::size_t i=0;i<garden.size();++i)require(all[i].count==garden[i].count&&!all[i].box,"zero must remove user cap");
        auto reduced=viewportQuotas(garden,500000,true);
        require(reduced[1].box&&reduced[1].count==22,"palms must remain represented");
        require(reduced[2].box&&reduced[2].count==5,"large trees must remain represented");
        auto memory=viewportQuotas(garden,0,true,true);
        for(std::size_t i=0;i<garden.size();++i)require(memory[i].box&&memory[i].count==garden[i].count,"memory fallback must preserve instance coverage");
        std::mt19937 rng(816);
        for(int test=0;test<2000;++test) {
            std::vector<ViewportDemand> input;
            for(unsigned i=0,n=1+rng()%40;i<n;++i)input.push_back({rng()%100000,1+rng()%1500000});
            const std::uint64_t budget=1+rng()%3000000;
            for(bool mesh:{false,true}) {
                const auto a=viewportQuotas(input,budget,mesh),b=viewportQuotas(input,budget,mesh);
                std::uint64_t total=0;
                for(std::size_t i=0;i<input.size();++i) {
                    require(a[i].count<=input[i].count,"draw count exceeds prepared data");
                    require(a[i].count==b[i].count&&a[i].box==b[i].box,"unstable allocation");
                    total+=a[i].count*a[i].cost;
                }
                require(total<=budget,"controller budget exceeded");
            }
        }
        for(std::size_t count=1;count<1200;++count) {
            const auto stride=viewportStride(count);std::set<std::size_t> seen;
            for(std::size_t i=0;i<count;++i)require(seen.insert(i*stride%count).second,"display sampling repeated a placement");
            require(seen.size()==count,"display sampling lost a placement");
        }
        require(viewportQuotas({},0,true).empty(),"empty preview");
        std::cout<<"viewport budgets, zero, coverage, deterministic prefixes and memory fallback passed\n";
        return 0;
    } catch(const std::exception& e){std::cerr<<e.what()<<'\n';return 1;}
}
