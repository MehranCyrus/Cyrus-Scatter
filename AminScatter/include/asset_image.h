#pragma once
#include <cstdint>
#include <string>
#include <vector>

namespace cyrus::assets {
enum class ImageFormat { png, jpeg };
struct ImageInfo {
    std::uint32_t width=0,height=0,bitsPerPixel=0,channels=0;
    ImageFormat format=ImageFormat::png;
};
// Explicit real-model profile, separate from inspectPNG and legacy admission.
// Original encoded bytes and input colour interpretation remain caller-owned.
// Validates a complete single-frame 8-bit Gray/RGB/RGBA PNG/JPEG by decoding
// all rows. PNG uses one row plus 32 KiB deflate history; WIC may cache data.
// JPEG uses a warning-fatal pinned static codec with a separate 256 MiB request
// budget (including progressive coefficient storage). Input is never rewritten.
ImageInfo inspectPortableImage(const std::vector<unsigned char>& bytes,const std::string& suffix);
}
