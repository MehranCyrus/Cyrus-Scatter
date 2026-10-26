#pragma once
#include <array>
#include <algorithm>
#include <cmath>
#include <cstddef>
#include <limits>
#include <stdexcept>

namespace cyrus::source_measurement {
inline constexpr std::size_t maxVertices=1000000,maxFaces=2000000;
using Point=std::array<double,3>;
inline void storage(std::size_t vertices,std::size_t faces,std::size_t vertexLimit,std::size_t faceLimit){
    if(!vertices||!faces||vertices>maxVertices||faces>maxFaces||vertices>vertexLimit||faces>faceLimit)
        throw std::invalid_argument("Source measurement exceeds its vertex/triangle admission.");
}
inline void index(std::size_t value,std::size_t vertices){if(value>=vertices)throw std::invalid_argument("Source mesh has an invalid face index.");}
struct Bounds {
    Point minimum{std::numeric_limits<double>::infinity(),std::numeric_limits<double>::infinity(),std::numeric_limits<double>::infinity()};
    Point maximum{-std::numeric_limits<double>::infinity(),-std::numeric_limits<double>::infinity(),-std::numeric_limits<double>::infinity()};
    double radiusXY=0,radiusXYZ=0;
    std::size_t count=0;
    void add(Point p){
        for(std::size_t i=0;i<3;++i){
            if(!std::isfinite(p[i])||std::abs(p[i])>1000000)throw std::invalid_argument("Source measurement contains a nonfinite or out-of-range metre coordinate.");
            minimum[i]=std::min(minimum[i],p[i]);maximum[i]=std::max(maximum[i],p[i]);
        }
        radiusXY=std::max(radiusXY,std::hypot(p[0],p[1]));radiusXYZ=std::max(radiusXYZ,std::hypot(p[0],p[1],p[2]));++count;
    }
};
}
