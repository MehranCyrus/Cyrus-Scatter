#include "density_image.h"
#include <algorithm>
#include <cmath>
#include <limits>
#include <stdexcept>

namespace cyrus::density {
std::vector<std::uint8_t> encodeLinearPNG(const ImageData& image){
    if(!image.width||!image.height||image.width>512||image.height>512||image.pixels.size()!=image.width*image.height)
        throw std::invalid_argument("Density snapshot requires 1..512 pixels per side");
    using Bytes=std::vector<std::uint8_t>;
    const auto number=[](Bytes& out,std::uint32_t value){for(int shift:{24,16,8,0})out.push_back(std::uint8_t(value>>shift));};
    Bytes raw;raw.reserve(image.height*(1+image.width*6));
    for(std::size_t y=0;y<image.height;++y){raw.push_back(0);for(std::size_t x=0;x<image.width;++x){
        const double v=image.pixels[y*image.width+x];
        if(!std::isfinite(v)||v<0||v>1)throw std::invalid_argument("Density snapshot has invalid scalar data");
        const auto sample=std::uint16_t(std::lround(v*65535));
        for(int channel=0;channel<3;++channel){raw.push_back(std::uint8_t(sample>>8));raw.push_back(std::uint8_t(sample));}
    }}
    Bytes compressed{0x78,0x01};compressed.reserve(raw.size()+raw.size()/65535*5+16);
    for(std::size_t offset=0;offset<raw.size();){
        const auto length=std::uint16_t(std::min(std::size_t(65535),raw.size()-offset)),inverse=std::uint16_t(~length);
        compressed.push_back(offset+length==raw.size()?1:0);
        for(auto value:{length,inverse}){compressed.push_back(std::uint8_t(value));compressed.push_back(std::uint8_t(value>>8));}
        compressed.insert(compressed.end(),raw.begin()+offset,raw.begin()+offset+length);offset+=length;
    }
    std::uint32_t a=1,b=0;for(auto byte:raw){a=(a+byte)%65521;b=(b+a)%65521;}number(compressed,(b<<16)|a);
    Bytes png{137,80,78,71,13,10,26,10};
    const auto chunk=[&](const char* kind,const Bytes& bytes){
        number(png,std::uint32_t(bytes.size()));const auto begin=png.size();
        for(int i=0;i<4;++i)png.push_back(std::uint8_t(kind[i]));png.insert(png.end(),bytes.begin(),bytes.end());
        std::uint32_t crc=0xffffffffu;for(std::size_t i=begin;i<png.size();++i){crc^=png[i];for(int j=0;j<8;++j)crc=(crc>>1)^((crc&1)?0xedb88320u:0u);}number(png,crc^0xffffffffu);
    };
    Bytes header;number(header,std::uint32_t(image.width));number(header,std::uint32_t(image.height));
    header.insert(header.end(),{16,2,0,0,0});chunk("IHDR",header);Bytes gamma;number(gamma,100000);chunk("gAMA",gamma);chunk("IDAT",compressed);chunk("IEND",{});return png;
}
void validate(const Mapping& m) {
    if(m.coordinates!=Coordinates::UV&&m.coordinates!=Coordinates::World&&m.coordinates!=Coordinates::Local)
        throw std::invalid_argument("Image density: unsupported coordinate mode");
    if(m.wrapping!=Wrapping::Clamp&&m.wrapping!=Wrapping::Repeat)
        throw std::invalid_argument("Image density: choose Clamp or Repeat");
    for(double v:{m.sizeX,m.sizeY,m.repeatX,m.repeatY})
        if(!std::isfinite(v)||v<=0)throw std::invalid_argument("Image density: tile sizes and repeats must be positive finite values");
    for(double v:{m.rotation,m.offsetX,m.offsetY})
        if(!std::isfinite(v))throw std::invalid_argument("Image density: nonfinite mapping control");
    for(double v:m.worldToFrame)if(!std::isfinite(v))throw std::invalid_argument("Image density: nonfinite projection frame");
    if(m.curve.size()<2||m.curve.size()>257)throw std::invalid_argument("Image density: response needs 2..257 samples");
    for(double v:m.curve)if(!std::isfinite(v)||v<0||v>1)throw std::invalid_argument("Image density: response must be within 0..1");
}
ImageSampler::ImageSampler(const std::vector<double>& pixels,std::size_t w,std::size_t h,const Mapping& m)
    :pixels_(pixels),width_(w),height_(h),mapping_(m),cosine_(std::cos(m.rotation*3.14159265358979323846/180)),sine_(std::sin(m.rotation*3.14159265358979323846/180)) {
    validate(m);
    if(!w||!h||w>4096||h>4096||w>std::numeric_limits<std::size_t>::max()/h||pixels.size()!=w*h)
        throw std::invalid_argument("Image density: invalid or oversized image dimensions");
    for(double v:pixels)if(!std::isfinite(v)||v<0||v>1)throw std::invalid_argument("Image density: nonfinite or out-of-range pixel");
}
double ImageSampler::sample(double u,double v,double x,double y,double z) const {
    const auto& m=mapping_;
    if(m.coordinates!=Coordinates::UV) {
        const auto& a=m.worldToFrame;
        u=x*a[0]+y*a[3]+z*a[6]+a[9];
        v=x*a[1]+y*a[4]+z*a[7]+a[10];
    }
    if(!std::isfinite(u)||!std::isfinite(v))throw std::invalid_argument("Image density: nonfinite sample coordinates");
    u-=m.offsetX;v-=m.offsetY;
    const double rotatedU=cosine_*u+sine_*v,rotatedV=-sine_*u+cosine_*v;
    u=m.coordinates==Coordinates::UV?rotatedU*m.repeatX:rotatedU/m.sizeX;
    v=m.coordinates==Coordinates::UV?rotatedV*m.repeatY:rotatedV/m.sizeY;
    if(!std::isfinite(u)||!std::isfinite(v))throw std::invalid_argument("Image density: mapping overflow");
    const bool repeat=m.wrapping==Wrapping::Repeat;
    if(repeat){u-=std::floor(u);v-=std::floor(v);}
    else {u=std::clamp(u,0.0,1.0);v=std::clamp(v,0.0,1.0);}
    // Repeat samples across both sides of a seam. Clamp preserves the existing
    // endpoint convention exactly; image resolution never determines tile size.
    const double fx=repeat?u*double(width_)-.5:u*double(width_-1);
    const double fy=repeat?(1-v)*double(height_)-.5:(1-v)*double(height_-1);
    const auto ix=static_cast<long long>(std::floor(fx)),iy=static_cast<long long>(std::floor(fy));
    const double ax=fx-double(ix),ay=fy-double(iy);
    const auto index=[&](long long p,std::size_t n) {
        const auto size=static_cast<long long>(n);
        return std::size_t(repeat?(p%size+size)%size:std::clamp(p,0LL,size-1));
    };
    const auto at=[&](long long xx,long long yy){return pixels_[index(yy,height_)*width_+index(xx,width_)];};
    const double value=std::clamp((at(ix,iy)*(1-ax)+at(ix+1,iy)*ax)*(1-ay)+(at(ix,iy+1)*(1-ax)+at(ix+1,iy+1)*ax)*ay,0.0,1.0);
    const double response=value*double(m.curve.size()-1);
    const auto i=std::min(std::size_t(response),m.curve.size()-2);
    return std::clamp(m.curve[i]+(m.curve[i+1]-m.curve[i])*(response-double(i)),0.0,1.0);
}
}
