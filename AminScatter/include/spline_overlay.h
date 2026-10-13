#pragma once
#include "spline_bands.h"

namespace cyrus::bands {
// Copied host-thread input. No scene references survive overlay preparation.
struct ReceiverTriangle {
    amin::Vec3 a,b,c;
    std::uint64_t receiver=0;
    std::uint32_t face=0;
};
struct OverlayOptions {
    std::uint64_t band=0; // zero = combined occupancy; otherwise contribution
    std::size_t samples=4000;
    bool falloff=true,boundaries=true;
};
struct OverlayLimits {
    std::size_t faces=200000,samples=20000,lines=100000,work=50000000;
    std::size_t bytes=64u*1024u*1024u;
    OutlineLimits outlines;
};
struct OverlaySample {
    amin::Vec3 position,bary;
    std::uint64_t receiver=0;
    std::uint32_t face=0;
    double value=0,error=0;
};
struct OverlayLine {
    amin::Vec3 a,b,normal;
    std::uint64_t receiver=0;
    std::uint32_t face=0;
    // 0..32 density bins (zero is an explicit colored sample), 33 boundary.
    std::uint8_t color=0;
};
struct OverlayStats {
    std::size_t faces=0,degenerate=0,receivers=0,sampledReceivers=0,sampledFaces=0;
    std::size_t work=0,boundaryLines=0,preparationBytes=0,retainedBytes=0;
    double area=0;
    OutlineStats outlines;
};
struct Overlay {
    std::vector<OverlaySample> samples;
    std::vector<OverlayLine> lines;
    OverlayStats stats;
};
// Caller reserves this allowance against the existing point-preview budget
// BEFORE copying host meshes. It includes the input, index, output and slack;
// Clipper scratch has a separate lease on the existing field aggregate budget.
std::size_t overlayPreparationBytes(std::size_t faces,const OverlayOptions&,const OverlayLimits& = {});
Overlay buildOverlay(const Field&,const std::vector<ReceiverTriangle>&,const OverlayOptions&,const OverlayLimits& = {});
amin::Vec3 overlayColor(std::uint8_t);
}
