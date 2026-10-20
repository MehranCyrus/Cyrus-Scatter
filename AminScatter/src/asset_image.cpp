#include "asset_image.h"
#include "asset_jpeg.h"
#include <algorithm>
#include <array>
#include <stdexcept>
#ifndef NOMINMAX
#define NOMINMAX
#endif
#include <windows.h>
#include <wincodec.h>
#include <wrl/client.h>

namespace cyrus::assets {
namespace {
using Microsoft::WRL::ComPtr;
constexpr std::size_t encodedLimit=32u*1024u*1024u;
constexpr std::uint32_t edgeLimit=8192;
constexpr std::uint64_t pixelLimit=64ull*1024ull*1024ull;
void require(bool ok,const char* message){if(!ok)throw std::invalid_argument(message);}
void success(HRESULT result,const char* message){require(SUCCEEDED(result),message);}
void dimensions(std::uint32_t width,std::uint32_t height){require(width>0&&height>0&&width<=edgeLimit&&height<=edgeLimit&&static_cast<std::uint64_t>(width)*height<=pixelLimit,"Real-model image exceeds 8192 edge or 64 Mpixels.");}
std::uint32_t be32(const std::vector<unsigned char>& b,std::size_t at){return(static_cast<std::uint32_t>(b[at])<<24)|(static_cast<std::uint32_t>(b[at+1])<<16)|(static_cast<std::uint32_t>(b[at+2])<<8)|b[at+3];}
std::uint32_t crc(const unsigned char* data,std::size_t count){
    static const auto table=[](){std::array<std::uint32_t,256> r{};for(std::uint32_t i=0;i<256;++i){auto n=i;for(int j=0;j<8;++j)n=(n>>1)^((n&1)?0xedb88320u:0u);r[i]=n;}return r;}();
    std::uint32_t n=0xffffffffu;for(std::size_t i=0;i<count;++i)n=table[(n^data[i])&255]^(n>>8);return n^0xffffffffu;
}
// WIC tolerates some malformed PNG deflate streams. Verify their compressed
// pixel stream independently with a 32 KiB history, without retaining pixels.
struct DeflateInput {
    const std::vector<unsigned char>& bytes;const std::vector<std::pair<std::size_t,std::size_t>>& chunks;
    std::size_t chunk=0,offset=0;unsigned bits=0,held=0;
    unsigned byte(){while(chunk<chunks.size()&&offset==chunks[chunk].second){++chunk;offset=0;}require(chunk<chunks.size(),"Truncated PNG deflate stream.");return bytes[chunks[chunk].first+offset++];}
    unsigned read(unsigned n){unsigned value=0;for(unsigned i=0;i<n;++i){if(!bits){held=byte();bits=8;}value|=(held&1)<<i;held>>=1;--bits;}return value;}
    void align(){bits=0;held=0;}
    bool done()const{return chunk==chunks.size()||(chunk+1==chunks.size()&&offset==chunks[chunk].second);}
};
struct Huffman {
    std::array<unsigned,16> counts{};std::array<unsigned,288> symbols{};
    explicit Huffman(const std::vector<unsigned>& lengths){
        require(lengths.size()<=symbols.size(),"PNG deflate tree exceeds its bound.");
        for(auto n:lengths){require(n<=15,"Invalid PNG deflate code length.");++counts[n];}
        int left=1;for(unsigned n=1;n<=15;++n){left=(left<<1)-static_cast<int>(counts[n]);require(left>=0,"Oversubscribed PNG deflate tree.");}
        require(left==0||counts[0]==lengths.size()||(counts[1]==1&&counts[0]+1==lengths.size()),"Incomplete PNG deflate tree.");
        std::array<unsigned,16> offsets{};for(unsigned n=1;n<15;++n)offsets[n+1]=offsets[n]+counts[n];
        for(unsigned i=0;i<lengths.size();++i)if(lengths[i])symbols[offsets[lengths[i]]++]=i;
    }
    unsigned decode(DeflateInput& in)const{
        unsigned code=0,first=0,index=0;
        for(unsigned length=1;length<=15;++length){code|=in.read(1);const auto count=counts[length];if(code>=first&&code-first<count)return symbols[index+code-first];index+=count;first=(first+count)<<1;code<<=1;}
        throw std::invalid_argument("Invalid PNG deflate symbol.");
    }
};
void verifyDeflate(const std::vector<unsigned char>& bytes,const std::vector<std::pair<std::size_t,std::size_t>>& chunks,const ImageInfo& image){
    DeflateInput in{bytes,chunks};const auto cmf=in.byte(),flg=in.byte();
    require((cmf&15)==8&&(cmf>>4)<=7&&((cmf<<8)|flg)%31==0&&(flg&32)==0,"Unsupported PNG zlib header.");
    const auto windowLimit=1u<<((cmf>>4)+8);const std::uint64_t rowBytes=static_cast<std::uint64_t>(image.width)*image.channels+1,expected=rowBytes*image.height;
    std::array<unsigned char,32768> history{};std::uint64_t produced=0;std::uint32_t a=1,b=0;
    auto output=[&](unsigned value){require(produced<expected,"PNG expands beyond declared image dimensions.");if(produced%rowBytes==0)require(value<=4,"Invalid PNG scanline filter.");history[static_cast<std::size_t>(produced&32767)]=static_cast<unsigned char>(value);++produced;a+=value;if(a>=65521)a-=65521;b+=a;if(b>=65521)b-=65521;};
    static constexpr unsigned lengths[]={3,4,5,6,7,8,9,10,11,13,15,17,19,23,27,31,35,43,51,59,67,83,99,115,131,163,195,227,258};
    static constexpr unsigned lengthBits[]={0,0,0,0,0,0,0,0,1,1,1,1,2,2,2,2,3,3,3,3,4,4,4,4,5,5,5,5,0};
    static constexpr unsigned distances[]={1,2,3,4,5,7,9,13,17,25,33,49,65,97,129,193,257,385,513,769,1025,1537,2049,3073,4097,6145,8193,12289,16385,24577};
    static constexpr unsigned distanceBits[]={0,0,0,0,1,1,2,2,3,3,4,4,5,5,6,6,7,7,8,8,9,9,10,10,11,11,12,12,13,13};
    bool final=false;std::size_t blocks=0;
    while(!final){
        require(++blocks<=1048576,"PNG deflate block count exceeds its bound.");final=in.read(1)!=0;const auto type=in.read(2);require(type!=3,"Reserved PNG deflate block.");
        if(type==0){in.align();const auto lo=in.byte(),hi=in.byte(),length=lo|(hi<<8),invLo=in.byte(),invHi=in.byte();require((length^((invHi<<8)|invLo))==65535,"Invalid PNG stored block length.");for(unsigned i=0;i<length;++i)output(in.byte());continue;}
        std::vector<unsigned> literalLengths,distanceLengths;
        if(type==1){literalLengths.resize(288);for(unsigned i=0;i<288;++i)literalLengths[i]=i<=143?8u:(i<=255?9u:(i<=279?7u:8u));distanceLengths.assign(32,5);}
        else{
            const auto literals=257+in.read(5),distanceCount=1+in.read(5),codes=4+in.read(4);require(literals<=286,"Invalid PNG literal tree size.");
            static constexpr unsigned order[]={16,17,18,0,8,7,9,6,10,5,11,4,12,3,13,2,14,1,15};std::vector<unsigned> codeLengths(19);
            for(unsigned i=0;i<codes;++i)codeLengths[order[i]]=in.read(3);const Huffman codeTree(codeLengths);std::vector<unsigned> all;
            while(all.size()<literals+distanceCount){const auto symbol=codeTree.decode(in);if(symbol<=15)all.push_back(symbol);else{unsigned value=0,count=0;if(symbol==16){require(!all.empty(),"PNG repeat has no preceding length.");value=all.back();count=3+in.read(2);}else if(symbol==17)count=3+in.read(3);else if(symbol==18)count=11+in.read(7);else throw std::invalid_argument("Invalid PNG code-length symbol.");require(count<=literals+distanceCount-all.size(),"PNG code repeat exceeds its tree.");all.insert(all.end(),count,value);}}
            literalLengths.assign(all.begin(),all.begin()+literals);distanceLengths.assign(all.begin()+literals,all.end());require(literalLengths[256]!=0,"PNG literal tree has no end symbol.");
        }
        const Huffman literals(literalLengths),distanceTree(distanceLengths);
        while(true){const auto symbol=literals.decode(in);if(symbol<256){output(symbol);continue;}if(symbol==256)break;require(symbol>=257&&symbol<=285,"Invalid PNG length symbol.");const auto index=symbol-257,length=lengths[index]+in.read(lengthBits[index]),distanceSymbol=distanceTree.decode(in);require(distanceSymbol<30,"Invalid PNG distance symbol.");const auto distance=distances[distanceSymbol]+in.read(distanceBits[distanceSymbol]);require(distance<=produced&&distance<=windowLimit,"PNG back-reference exceeds its history.");for(unsigned i=0;i<length;++i)output(history[static_cast<std::size_t>((produced-distance)&32767)]);}
    }
    require(produced==expected,"PNG pixel stream does not fill declared dimensions.");in.align();std::uint32_t checksum=0;for(unsigned i=0;i<4;++i)checksum=(checksum<<8)|in.byte();require(checksum==((b<<16)|a)&&in.done(),"PNG zlib checksum mismatch or trailing compressed data.");
}
ImageInfo pngHeader(const std::vector<unsigned char>& b){
    constexpr unsigned char signature[]={137,80,78,71,13,10,26,10};
    require(b.size()>=57&&std::equal(std::begin(signature),std::end(signature),b.begin()),"PNG suffix does not match image bytes.");
    ImageInfo result;bool header=false,pixels=false,afterPixels=false,end=false;std::size_t at=8,chunks=0;std::vector<std::pair<std::size_t,std::size_t>> pixelChunks;
    while(at<b.size()){
        require(b.size()-at>=12&&++chunks<=65536,"Invalid or excessive PNG chunks.");const auto n=be32(b,at);require(n<=b.size()-at-12,"Truncated PNG chunk.");
        const std::string type(b.begin()+at+4,b.begin()+at+8);
        require(crc(b.data()+at+4,static_cast<std::size_t>(n)+4)==be32(b,at+8+n),"PNG checksum mismatch.");
        require(type!="acTL"&&type!="fcTL"&&type!="fdAT","Animated PNG is unsupported.");
        if(!header){
            require(type=="IHDR"&&n==13,"Invalid PNG header.");result.width=be32(b,at+8);result.height=be32(b,at+12);dimensions(result.width,result.height);
            require(b[at+16]==8&&(b[at+17]==0||b[at+17]==2||b[at+17]==6)&&b[at+18]==0&&b[at+19]==0&&b[at+20]==0,"Real-model PNG requires noninterlaced 8-bit Gray/RGB/RGBA.");
            result.channels=b[at+17]==0?1u:(b[at+17]==2?3u:4u);result.bitsPerPixel=result.channels*8;result.format=ImageFormat::png;header=true;
        }else require(type!="IHDR","Duplicate PNG header.");
        if((b[at+4]&32)==0)require(type=="IHDR"||type=="PLTE"||type=="IDAT"||type=="IEND","Unsupported critical PNG chunk.");
        if(type=="IDAT"){require(!afterPixels&&!end&&n>0,"Invalid PNG pixel sequence.");pixels=true;pixelChunks.emplace_back(at+8,n);}
        else if(pixels)afterPixels=true;
        if(type=="IEND"){require(n==0&&pixels,"Invalid PNG end.");end=true;}
        at+=static_cast<std::size_t>(n)+12;
        if(end){require(at==b.size(),"Trailing PNG bytes.");break;}
    }
    require(header&&pixels&&end,"Incomplete PNG image.");verifyDeflate(b,pixelChunks,result);return result;
}
ImageInfo jpegHeader(const std::vector<unsigned char>& b){
    require(b.size()>=4&&b[0]==0xff&&b[1]==0xd8,"JPEG suffix does not match image bytes.");
    ImageInfo result;result.format=ImageFormat::jpeg;bool header=false,scan=false,entropy=false;std::size_t at=2,segments=0;
    while(at<b.size()){
        require(++segments<=1048576,"JPEG marker count exceeds its bound.");
        if(entropy){
            while(at<b.size()&&b[at]!=0xff)++at;
            require(at<b.size(),"JPEG entropy data has no end marker.");
        }
        require(b[at]==0xff,"Invalid JPEG marker.");while(at<b.size()&&b[at]==0xff)++at;require(at<b.size(),"Truncated JPEG marker.");const auto marker=b[at++];
        if(entropy&&(marker==0||(marker>=0xd0&&marker<=0xd7)))continue;
        entropy=false;
        if(marker==0xd9){require(header&&scan&&at==b.size(),"Incomplete JPEG or trailing image bytes.");return result;}
        require(marker!=0&&marker!=0xd8&&marker!=1&&!(marker>=0xd0&&marker<=0xd7),"Unsupported JPEG marker sequence.");
        require(b.size()-at>=2,"Truncated JPEG segment.");const auto length=static_cast<std::size_t>((b[at]<<8)|b[at+1]);require(length>=2&&length<=b.size()-at,"Truncated JPEG segment payload.");
        const bool frame=marker>=0xc0&&marker<=0xcf&&marker!=0xc4&&marker!=0xc8&&marker!=0xcc;
        if(frame){
            require(!header&&(marker==0xc0||marker==0xc1||marker==0xc2)&&length>=8,"Unsupported JPEG frame encoding.");
            const auto components=b[at+7];require(b[at+2]==8&&(components==1||components==3)&&length==8u+3u*components,"Real-model JPEG requires 8-bit Gray/RGB.");
            result.height=static_cast<std::uint32_t>((b[at+3]<<8)|b[at+4]);result.width=static_cast<std::uint32_t>((b[at+5]<<8)|b[at+6]);dimensions(result.width,result.height);result.channels=components;result.bitsPerPixel=components*8u;header=true;
        }
        if(marker==0xda){require(header&&length>=6,"Invalid JPEG scan header.");const auto components=b[at+2];require(components>0&&components<=result.channels&&length==6u+2u*components,"Invalid JPEG scan component count.");scan=true;entropy=true;}
        at+=length;
    }
    throw std::invalid_argument("JPEG is missing its end marker.");
}
struct Apartment {
    bool balanced=false;
    Apartment(){const auto result=CoInitializeEx(nullptr,COINIT_MULTITHREADED);balanced=SUCCEEDED(result);require(balanced||result==RPC_E_CHANGED_MODE,"Cannot initialize image validation COM apartment.");}
    ~Apartment(){if(balanced)CoUninitialize();}
    Apartment(const Apartment&)=delete;Apartment& operator=(const Apartment&)=delete;
};
}
ImageInfo inspectPortableImage(const std::vector<unsigned char>& bytes,const std::string& suffix){
    require(!bytes.empty()&&bytes.size()<=encodedLimit,"Real-model image must be no larger than 32 MiB encoded.");
    require(suffix=="png"||suffix=="jpg"||suffix=="jpeg","Real-model image suffix requires PNG or JPEG.");
    auto info=suffix=="png"?pngHeader(bytes):jpegHeader(bytes);
    if(info.format==ImageFormat::jpeg){
        CyrusJpegInfo decoded{};std::array<char,256> error{};
        if(!cyrus_strict_jpeg(bytes.data(),bytes.size(),256ull*1024ull*1024ull,&decoded,error.data(),error.size(),nullptr,nullptr))throw std::invalid_argument(error.data());
        require(decoded.width==info.width&&decoded.height==info.height&&decoded.channels==info.channels&&decoded.bits_per_channel==8,"JPEG decoded representation differs from its encoded header.");
        return info;
    }
    Apartment apartment;
    ComPtr<IWICImagingFactory> factory;success(CoCreateInstance(CLSID_WICImagingFactory,nullptr,CLSCTX_INPROC_SERVER,IID_PPV_ARGS(factory.GetAddressOf())),"Cannot create Windows image validator.");
    ComPtr<IWICStream> stream;success(factory->CreateStream(stream.GetAddressOf()),"Cannot create image input stream.");
    // The borrowed buffer outlives stream/decoder/frame; decoding never writes it.
    success(stream->InitializeFromMemory(const_cast<BYTE*>(bytes.data()),static_cast<DWORD>(bytes.size())),"Cannot initialize bounded image input.");
    ComPtr<IWICBitmapDecoder> decoder;success(factory->CreateDecoderFromStream(stream.Get(),&GUID_VendorMicrosoft,WICDecodeMetadataCacheOnDemand,decoder.GetAddressOf()),"Cannot decode real-model image.");
    GUID container{};success(decoder->GetContainerFormat(&container),"Cannot identify image container.");require(IsEqualGUID(container,info.format==ImageFormat::png?GUID_ContainerFormatPng:GUID_ContainerFormatJpeg),"Decoded image container differs from suffix.");
    ComPtr<IWICBitmapDecoderInfo> decoderInfo;success(decoder->GetDecoderInfo(decoderInfo.GetAddressOf()),"Cannot identify image decoder.");GUID vendor{};success(decoderInfo->GetVendorGUID(&vendor),"Cannot identify decoder vendor.");require(IsEqualGUID(vendor,GUID_VendorMicrosoft),"Real-model validation requires the Windows built-in image decoder.");
    UINT frames=0;success(decoder->GetFrameCount(&frames),"Cannot count image frames.");require(frames==1,"Real-model images must contain one frame.");
    ComPtr<IWICBitmapFrameDecode> frame;success(decoder->GetFrame(0,frame.GetAddressOf()),"Cannot read image frame.");UINT width=0,height=0;success(frame->GetSize(&width,&height),"Cannot read image dimensions.");require(width==info.width&&height==info.height,"Image dimensions disagree with its encoded header.");
    WICPixelFormatGUID format{};success(frame->GetPixelFormat(&format),"Cannot read image pixel format.");
    std::uint32_t channels=0;
    if(IsEqualGUID(format,GUID_WICPixelFormat8bppGray))channels=1;
    else if(IsEqualGUID(format,GUID_WICPixelFormat24bppBGR)||IsEqualGUID(format,GUID_WICPixelFormat24bppRGB))channels=3;
    else if(IsEqualGUID(format,GUID_WICPixelFormat32bppBGRA)||IsEqualGUID(format,GUID_WICPixelFormat32bppRGBA))channels=4;
    require(channels!=0&&(channels==info.channels||(info.format==ImageFormat::png&&info.channels==3&&channels==4)),"Decoded image is not supported 8-bit Gray/RGB/RGBA.");
    info.channels=channels;info.bitsPerPixel=channels*8;
    const auto stride=width*channels;std::vector<BYTE> row(stride);
    for(UINT y=0;y<height;++y){WICRect rect{0,static_cast<INT>(y),static_cast<INT>(width),1};success(frame->CopyPixels(&rect,stride,stride,row.data()),"Real-model image pixel data is truncated or invalid.");}
    return info;
}
}
