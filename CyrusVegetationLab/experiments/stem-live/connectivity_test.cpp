#include "connectivity.hpp"
#include <iostream>
void require(bool b,const char* text){if(!b)throw std::runtime_error(text);}
prep::Tube tube(std::initializer_list<prep::Point> p,std::initializer_list<double> r){return {p,r};}
int main(){try{
    std::atomic_bool cancel=false;
    std::vector<prep::Tube> tubes{
        tube({{.12,0,.35},{.06,0,.28},{.004,0,.2}},{.0006,.0008,.001}),
        tube({{0,0,0},{0,0,.25},{0,0,.5}},{.004,.004,.004}),
        tube({{.005,0,.38},{.05,0,.32},{.09,0,.29}},{.001,.0008,.0006}),
        tube({{.2,0,0},{.2,0,.2},{.2,0,.4}},{.003,.003,.003}),
        tube({{.5,0,.3},{.6,0,.4},{.7,0,.5}},{.001,.0008,.0006})};
    auto f=prep::connect(tubes,cancel);require(f.roots==2&&f.unresolved==1,"Independent roots / aerial orphan classification");require(f.links[0].parent==1&&f.links[0].reversed,"Reversed authored rings / parent after child");require(f.links[2].parent==1&&!f.links[2].reversed,"Descending branch was rooted at tip");require(!f.links[4].resolved&&!f.links[4].basal,"Aerial orphan became a ground root");
    std::vector<unsigned> rank(tubes.size());for(unsigned i=0;i<f.order.size();++i)rank[f.order[i]]=i;require(rank[1]<rank[0]&&rank[1]<rank[2],"Parent traversal ordering");
    std::vector<unsigned> permutation{4,2,0,3,1};std::vector<prep::Tube> shuffled;for(auto i:permutation)shuffled.push_back(tubes[i]);auto s=prep::connect(shuffled,cancel);require(s.roots==2&&s.unresolved==1,"Shuffled source roots");for(unsigned i=0;i<permutation.size();++i){const auto& a=f.links[permutation[i]];const auto& b=s.links[i];require(a.resolved==b.resolved&&a.basal==b.basal&&a.reversed==b.reversed,"Source-order changed orientation/classification");if(a.parent>=0)require(permutation[b.parent]==unsigned(a.parent),"Source-order changed geometric parent");}
    auto repeat=prep::connect(tubes,cancel);require(repeat.order==f.order,"Connectivity not deterministic");cancel=true;bool cancelled=false;try{prep::connect(tubes,cancel);}catch(...){cancelled=true;}require(cancelled,"Connectivity cancellation ignored");
    std::cout<<"PASS multiple basal roots, late parent, reversed tube, descending branch, aerial orphan, reordered source, deterministic forest, cancellation\n";return 0;
}catch(const std::exception& e){std::cerr<<e.what()<<'\n';return 1;}}
