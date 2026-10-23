#pragma once
#include "scatter.h"
#include <string>

namespace cyrus::spline_export {
using Loops=std::vector<std::vector<amin::Vec3>>;
struct Limits {std::size_t vertices=200000,bytes=64u*1024u*1024u,work=50000000;};
struct Result {
    // Kept source indices, not resampled points. Index 0 remains on each ring.
    std::vector<std::vector<std::uint32_t>> indices;
    std::size_t input=0,output=0,work=0,bytes=0;
    double bound=0;
    bool optimized=false;
    std::string reason;
};
Result optimize(const Loops& world,double tolerance,const Limits& ={});
// Certifies original spans plus final host endpoint-rounding error. The
// triangle inequality extends the continuous chain/chord certificate to the
// geometry Max actually receives, in the complete world-space metric.
double certify(const Loops& original,const Loops& published,const Result&,double tolerance,std::size_t workLimit=50000000);
}
