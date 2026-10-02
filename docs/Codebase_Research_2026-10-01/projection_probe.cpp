// Standalone diagnostic; includes current source unchanged to access its private
// SurfaceTree/closest implementations. This is NOT a replacement scatter path.
#include "../../AminScatter/src/scatter.cpp"
#include <chrono>
#include <iostream>
#include <iomanip>
#include <cstring>
using namespace amin;
using Clock = std::chrono::steady_clock;
double elapsed(Clock::time_point t) {return std::chrono::duration<double,std::milli>(Clock::now()-t).count();}
bool exact(Vec3 a, Vec3 b) {return std::memcmp(&a.x,&b.x,8)==0 && std::memcmp(&a.y,&b.y,8)==0 && std::memcmp(&a.z,&b.z,8)==0;}
std::pair<Vec3,std::uint32_t> scan(const std::vector<Triangle>& mesh,Vec3 p) {
    Vec3 q{};std::uint32_t tri=0;double best=INFINITY;
    for(std::uint32_t j=0;j<mesh.size();++j) {
        auto candidate=closest(p,mesh[j]);double d=dot(candidate-p,candidate-p);
        if(d<best) {best=d;q=candidate;tri=j;}
    }
    return {q,tri};
}
int main() {
    try {
        std::cout<<std::setprecision(12);
        // A shared vertex with two differently oriented triangles makes identity
        // observable: a later hint wins in SurfaceTree, earliest index in scan.
        std::vector<Triangle> tied{{{0,0,0},{1,0,0},{0,1,0}},{{0,0,0},{0,1,0},{0,0,1}}};
        auto a=scan(tied,{0,0,0});SurfaceTree t(tied);auto b=t.project({0,0,0},1);
        if(a.second!=0 || b.second!=1 || !exact(a.first,b.first)) throw std::runtime_error("Tie recipe changed");
        std::cout<<"{\"type\":\"tie\",\"scan_triangle\":"<<a.second<<",\"tree_triangle\":"<<b.second
                 <<",\"position_equal\":true,\"drop_in_identity_equivalent\":false}\n";
        constexpr std::size_t count=2048;
        for(int side:{1,8,32,64}) {
            std::vector<Triangle> mesh;
            for(int y=0;y<side;++y) for(int x=0;x<side;++x) {
                Vec3 p{double(x),double(y),0},q{double(x+1),double(y),0},r{double(x),double(y+1),0},s{double(x+1),double(y+1),0};
                mesh.push_back({p,q,r});mesh.push_back({q,s,r});
            }
            Random rng(47291);std::vector<Vec3> queries;
            for(std::size_t i=0;i<count;++i) queries.push_back({rng.next()*side,rng.next()*side,.25+rng.next()});
            std::vector<std::pair<Vec3,std::uint32_t>> reference(count),candidate(count);
            for(int repeat=-2;repeat<9;++repeat) {
                double scanMs=0,buildMs=0,queryMs=0,totalMs=0;
                auto runScan=[&] {auto begin=Clock::now();for(std::size_t i=0;i<count;++i) reference[i]=scan(mesh,queries[i]);scanMs=elapsed(begin);};
                auto runTree=[&] {auto begin=Clock::now();SurfaceTree tree(mesh);buildMs=elapsed(begin);auto queryStart=Clock::now();for(std::size_t i=0;i<count;++i) candidate[i]=tree.project(queries[i],0);queryMs=elapsed(queryStart);totalMs=elapsed(begin);};
                if(repeat%2==0) {runTree();runScan();} else {runScan();runTree();}
                std::size_t positions=0,ids=0;
                for(std::size_t i=0;i<count;++i) {positions+=!exact(reference[i].first,candidate[i].first);ids+=reference[i].second!=candidate[i].second;}
                if(repeat>=0) std::cout<<"{\"type\":\"projection\",\"triangles\":"<<mesh.size()<<",\"queries\":"<<count<<",\"repeat\":"<<repeat
                    <<",\"order\":\""<<(repeat%2==0?"tree-scan":"scan-tree")<<"\",\"scan_ms\":"<<scanMs<<",\"tree_build_ms\":"<<buildMs
                    <<",\"tree_query_ms\":"<<queryMs<<",\"tree_build_query_ms\":"<<totalMs<<",\"position_mismatches\":"<<positions<<",\"triangle_mismatches\":"<<ids<<"}\n";
            }
        }
        std::cout<<"{\"type\":\"sizes\",\"Triangle_bytes\":"<<sizeof(Triangle)<<",\"Instance_bytes\":"<<sizeof(Instance)<<"}\n";
    } catch(const std::exception& e) {std::cerr<<e.what()<<'\n';return 1;}
}
