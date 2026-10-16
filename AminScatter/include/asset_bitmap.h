#pragma once
#include <cstdint>
#include <vector>

namespace cyrus::assets {
constexpr std::uint64_t maxBitmapPixels=16*1024*1024,maxPackageBitmapPixels=16*1024*1024;
struct BitmapInfo { std::uint32_t width=0,height=0; };
// Header/chunk admission, not a substitute for the host image decoder.
// Initial adapter: static, noninterlaced 8/16-bit RGB/RGBA PNG up to 4096 each side.
BitmapInfo inspectPNG(const std::vector<unsigned char>& bytes);
}
