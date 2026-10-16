#include "asset_bitmap.h"
#include <algorithm>
#include <array>
#include <stdexcept>
#include <string>

namespace cyrus::assets {
namespace {
void require(bool value,const char* error){if(!value)throw std::invalid_argument(error);}
std::uint32_t number(const std::vector<unsigned char>& bytes,std::size_t at){return(static_cast<std::uint32_t>(bytes[at])<<24)|(static_cast<std::uint32_t>(bytes[at+1])<<16)|(static_cast<std::uint32_t>(bytes[at+2])<<8)|bytes[at+3];}
std::uint32_t crc(const unsigned char* data,std::size_t count){
    static const auto table=[](){std::array<std::uint32_t,256> result{};for(std::uint32_t i=0;i<256;++i){auto value=i;for(int j=0;j<8;++j)value=(value>>1)^((value&1)?0xedb88320u:0u);result[i]=value;}return result;}();
    std::uint32_t value=0xffffffffu;for(std::size_t i=0;i<count;++i)value=table[(value^data[i])&255]^(value>>8);return value^0xffffffffu;
}
}
BitmapInfo inspectPNG(const std::vector<unsigned char>& bytes){
    static constexpr unsigned char signature[]={137,80,78,71,13,10,26,10};
    require(bytes.size()>=57&&bytes.size()<=32*1024*1024&&std::equal(std::begin(signature),std::end(signature),bytes.begin()),"Portable bitmap requires a PNG no larger than 32 MiB.");
    BitmapInfo result;bool header=false,pixels=false,end=false;std::size_t at=8,chunks=0;
    while(at<bytes.size()){
        require(bytes.size()-at>=12&&++chunks<=65536,"Invalid or excessive PNG chunks.");const auto length=number(bytes,at);
        require(length<=bytes.size()-at-12,"Truncated PNG chunk.");const std::string kind(bytes.begin()+at+4,bytes.begin()+at+8);
        require(crc(bytes.data()+at+4,static_cast<std::size_t>(length)+4)==number(bytes,at+8+length),"PNG chunk checksum mismatch.");
        require(kind!="acTL"&&kind!="fcTL"&&kind!="fdAT","Animated PNG needs a separate asset adapter.");
        if(!header){require(kind=="IHDR"&&length==13,"Invalid PNG header.");result={number(bytes,at+8),number(bytes,at+12)};
            require(result.width>0&&result.height>0&&result.width<=4096&&result.height<=4096&&static_cast<std::uint64_t>(result.width)*result.height<=maxBitmapPixels,"Portable bitmap dimensions exceed 4096 or 16 Mpixels.");
            require((bytes[at+16]==8||bytes[at+16]==16)&&(bytes[at+17]==2||bytes[at+17]==6)&&bytes[at+18]==0&&bytes[at+19]==0&&bytes[at+20]==0,"Portable PNG requires noninterlaced 8/16-bit RGB/RGBA.");header=true;
        }else require(kind!="IHDR","Duplicate PNG header.");
        if(kind=="IDAT"){require(!end&&length>0,"Invalid PNG pixel chunk.");pixels=true;}
        if(kind=="IEND"){require(length==0&&pixels&&!end,"Invalid PNG end.");end=true;}
        at+=static_cast<std::size_t>(length)+12;
        if(end){require(at==bytes.size(),"Trailing PNG data.");break;}
    }
    require(end&&pixels,"PNG is missing pixels or its end marker.");return result;
}
}
