#pragma once
#include <cmath>
#include <cstddef>
#include <cstdint>
#include <stdexcept>
#include <string>

namespace cyrus::receiver_mesh {
// Shared by the SDK extraction adapter and numerical boundary tests. These
// checks must precede unsigned conversion, reserve and any indexed vertex read.
inline void storage(int vertices,int faces,bool vertexBuffer,bool faceBuffer,std::size_t faceLimit) {
    if(vertices<0||faces<0)throw std::invalid_argument("negative geometry vertex/face count");
    if(vertices>0&&!vertexBuffer)throw std::invalid_argument("missing geometry vertex buffer");
    if(faces>0&&!faceBuffer)throw std::invalid_argument("missing geometry face buffer");
    if(static_cast<std::size_t>(faces)>faceLimit)throw std::invalid_argument("geometry exceeds the surface filter face limit");
}
inline void index(std::uint64_t value,int vertices,std::size_t face,unsigned corner) {
    if(vertices<0||value>=static_cast<std::uint64_t>(vertices))
        throw std::invalid_argument("geometry face "+std::to_string(face+1)+", corner "+std::to_string(corner+1)+
            " references invalid vertex index "+std::to_string(value)+" (vertex count "+std::to_string(vertices)+")");
}
inline void position(double x,double y,double z,const char* kind,std::size_t index) {
    if(!std::isfinite(x)||!std::isfinite(y)||!std::isfinite(z))
        throw std::invalid_argument(std::string("nonfinite ")+kind+" "+std::to_string(index+1));
}
}
