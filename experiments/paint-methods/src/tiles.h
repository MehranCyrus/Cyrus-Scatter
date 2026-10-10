#pragma once
#include "lab.h"
#include <map>
#include <algorithm>
namespace paintlab {
// Shared allocation utility only. B addresses projected pixels; D addresses
// face-local pixels. Each kernel independently decides which samples to edit.
struct Key {unsigned face;int x,y;bool operator<(const Key& b)const{return std::array<long long,3>{face,x,y}<std::array<long long,3>{b.face,b.x,b.y};}};
constexpr int tileSide=32;
struct Tile {std::array<float,tileSide*tileSide> value{};};
inline int floorDiv(int x){return int(std::floor(double(x)/tileSide));}
class Tiles {
public:
 std::map<Key,std::shared_ptr<Tile>> blocks;
 float get(unsigned f,int x,int y)const{int tx=floorDiv(x),ty=floorDiv(y);auto i=blocks.find({f,tx,ty});return i==blocks.end()?0:i->second->value[(y-ty*tileSide)*tileSide+x-tx*tileSide];}
 void set(unsigned f,int x,int y,float value){int tx=floorDiv(x),ty=floorDiv(y);auto& p=blocks[{f,tx,ty}];if(!p)p=std::make_shared<Tile>();else if(p.use_count()!=1)p=std::make_shared<Tile>(*p);p->value[(y-ty*tileSide)*tileSide+x-tx*tileSide]=value;}
 std::size_t bytes()const{return blocks.size()*(sizeof(Tile)+sizeof(Key)+64);}
 std::string save()const{std::ostringstream o;o.precision(9);o<<blocks.size()<<'\n';for(auto& [k,p]:blocks){o<<k.face<<' '<<k.x<<' '<<k.y<<' ';for(float v:p->value)o<<v<<' ';o<<'\n';}return o.str();}
 void load(const std::string& b,unsigned faces){std::istringstream in(b);std::size_t count;if(!(in>>count)||count>32768)throw std::runtime_error("Invalid tile count");std::map<Key,std::shared_ptr<Tile>> next;for(std::size_t i=0;i<count;++i){Key k;if(!(in>>k.face>>k.x>>k.y)||k.face>=faces||std::abs(double(k.x))>1e7||std::abs(double(k.y))>1e7||next.count(k))throw std::runtime_error("Invalid tile address");auto p=std::make_shared<Tile>();for(float& v:p->value)if(!(in>>v)||!std::isfinite(v)||v<0||v>1)throw std::runtime_error("Invalid tile value");next[k]=p;}blocks=std::move(next);}
};
inline double blend(double before,double a,bool erase){return erase?before*(1-a):before+(1-before)*a;}
inline void bounds(double lo,double hi,double h,int& a,int& b){if(!std::isfinite(lo)||!std::isfinite(hi)||std::max(std::abs(lo/h),std::abs(hi/h))>1e8)throw std::runtime_error("Pixel range exceeded");a=int(std::floor(lo/h));b=int(std::floor(hi/h));if(double(b-a+1)>2000000)throw std::runtime_error("Brush work budget exceeded");}
}
