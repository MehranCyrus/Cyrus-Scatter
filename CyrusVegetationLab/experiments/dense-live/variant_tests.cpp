#include "geometry.hpp"
#include <chrono>
#include <iostream>
#include <stdexcept>
namespace v=cyrus::vegetation::prototype_v1;
namespace g=cyrus::vegetation::prototype_v1::delivery_detail;
void check(bool ok){if(!ok)throw std::runtime_error("ID admission regression");}
int main(){try{std::vector<v::BoundVertex> ids(577792);for(std::size_t i=0;i<ids.size();++i){ids[i].render_vertex_id=i+1;ids[i].logical_vertex_id=1;}
    auto start=std::chrono::steady_clock::now();check(g::unique_nonzero_render_ids(ids));
    std::cout<<"577792 IDs sorted validation ms: "<<std::chrono::duration<double,std::milli>(std::chrono::steady_clock::now()-start).count()<<'\n';
    ids.back().render_vertex_id=ids.front().render_vertex_id;check(!g::unique_nonzero_render_ids(ids));ids.back().render_vertex_id=577792;
    ids.front().render_vertex_id=0;check(!g::unique_nonzero_render_ids(ids));ids.front().render_vertex_id=1;
    ids.back().logical_vertex_id=0;check(!g::unique_nonzero_render_ids(ids));ids.back().logical_vertex_id=1;
    std::reverse(ids.begin(),ids.end());check(g::unique_nonzero_render_ids(ids));std::cout<<"PASS unique, late duplicate, zero render/logical IDs, repeated logical IDs and reversed order\n";return 0;
}catch(const std::exception& e){std::cerr<<e.what()<<'\n';return 1;}}
