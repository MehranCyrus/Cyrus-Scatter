#pragma once
#include "viewport_memory.h"

namespace cyrus::interactions {
// Numeric construction bounds. Returned meshes belong to the renderer; this
// limits construction per request, not all renderer-owned memory or process RSS.
struct RenderSizing {
    std::size_t vertices=0,faces=0,fixedBytes=0,instanceBytes=0;
    static constexpr std::size_t maximumElements=20000000;
    static constexpr std::size_t maximumBytes=1024ull*1024*1024;
    static constexpr std::size_t targetBytes=128ull*1024*1024;
    std::size_t bytes(std::size_t n)const{return viewport_memory::add(fixedBytes,viewport_memory::multiply(instanceBytes,n));}
    std::size_t admit(std::size_t n)const{
        if(viewport_memory::multiply(vertices,n)>maximumElements||viewport_memory::multiply(faces,n)>maximumElements)
            throw std::runtime_error("Posed full-mesh construction exceeds 20M vertices/faces in one render batch");
        const auto b=bytes(n);if(b>maximumBytes)throw std::runtime_error("Posed render construction exceeds 1 GiB in one batch; simplify the source mesh");return b;
    }
    std::size_t capacity()const{
        std::size_t n=maximumElements;
        if(vertices)n=std::min(n,maximumElements/vertices);if(faces)n=std::min(n,maximumElements/faces);
        if(instanceBytes)n=std::min(n,fixedBytes<targetBytes?(targetBytes-fixedBytes)/instanceBytes:0);
        // Do not reject a viewport publication because a future exact render
        // request is large. A single oversized source is diagnosed by admit().
        return std::max<std::size_t>(1,n);
    }
    std::size_t chunks(std::size_t n)const{const auto c=capacity();return n/c+std::size_t(n%c!=0);}
};
}
