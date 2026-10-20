#pragma once
#include <array>
#include <cstddef>
#include <cstdint>
#include <vector>

namespace cyrus::density {
enum class Coordinates { UV=0, World=1, Local=2, Map=3 };
enum class Wrapping { Clamp=0, Repeat=1 };
struct Mapping {
    Coordinates coordinates=Coordinates::UV;
    Wrapping wrapping=Wrapping::Clamp;
    double sizeX=1,sizeY=1,repeatX=1,repeatY=1;
    double rotation=0,offsetX=0,offsetY=0;
    // Host copies the world-to-projection transform. Workers never access Max.
    std::array<double,12> worldToFrame{1,0,0,0,1,0,0,0,1,0,0,0};
    std::vector<double> curve{0,1};
};
struct ImageData { std::size_t width=0,height=0;std::vector<double> pixels; };
// Bounded portable scalar snapshot: 16-bit RGB PNG, explicit linear gamma,
// lossless stored DEFLATE. No host colour pipeline or image encoder settings.
std::vector<std::uint8_t> encodeLinearPNG(const ImageData&);
void validate(const Mapping&);

// Immutable borrowed view: caller owns pixels for this sampler's entire life.
// Pixels are scalar linear data, rows from v=1 to v=0. No population-sized copy.
class ImageSampler {
    const std::vector<double>& pixels_;
    std::size_t width_,height_;
    Mapping mapping_;
    double cosine_,sine_;
public:
    ImageSampler(const std::vector<double>&,std::size_t width,std::size_t height,const Mapping&);
    double sample(double u,double v,double x,double y,double z) const;
};
}
