#pragma once
#include "scatter.h"
#include <memory>
#include <limits>

// Host-independent prototype. A document is bound to one static indexed mesh.
// No Max pointers, UI state, or preview limits are part of the painted field.
namespace cyrus::brush {
using amin::Vec3;
struct Mesh { std::vector<Vec3> vertices; std::vector<std::array<std::uint32_t,3>> faces; };
struct Ray { Vec3 origin, direction; };
struct Anchor { std::uint32_t face{}; Vec3 bary{1,0,0}; };
struct Hit { Anchor anchor; double distance{}; };
struct View { Vec3 eye, direction; bool perspective=true; };
struct Sample {
    Anchor anchor;
    std::array<Vec3,3> basis{{{1,0,0},{0,1,0},{0,0,1}}}; // captured local -> world linear map
    View view;
    Ray ray{}; // captured unnormalised projection ray, linear in screen coordinates
    std::array<double,2> screen{};
    bool hasPath=false,connected=false;
};
struct Stroke {
    std::uint64_t id{};
    bool enabled=true,erase=false;
    double radius=10,strength=1,softness=.5;
    std::vector<Sample> samples;
};
struct Document { std::uint64_t surface{}; std::vector<Stroke> strokes; };
struct QueryStats { std::uint64_t triangles=0,fieldQueries=0; };
class Surface {
    struct Impl; std::shared_ptr<const Impl> impl;
public:
    explicit Surface(Mesh mesh);
    const Mesh& mesh() const;
    std::uint64_t fingerprint() const;
    Vec3 position(Anchor) const;
    Vec3 normal(std::uint32_t face) const;
    bool hit(Ray,Hit&,double maxDistance=std::numeric_limits<double>::infinity(),QueryStats* stats=nullptr) const;
    bool hitReference(Ray,Hit&,double maxDistance=std::numeric_limits<double>::infinity()) const;
    std::vector<std::uint32_t> patch(const Sample&,double radius) const;
    bool visible(Anchor,const View&,QueryStats* stats=nullptr) const;
};
// Index stroke dabs by connected affected faces. Full ordered replay remains the oracle.
class Field {
    struct Impl; std::shared_ptr<const Impl> impl;
public:
    Field(const Surface&,const Document&);
    double evaluate(Anchor,QueryStats* stats=nullptr) const;
    double evaluateReference(Anchor,QueryStats* stats=nullptr) const;
};
double influence(const Surface&,const Sample&,const Stroke&,Anchor,QueryStats* stats=nullptr);
double apply(double before,double influence,bool erase);
double threshold(std::uint64_t population,std::uint64_t candidate);
bool accepted(std::uint64_t population,std::uint64_t candidate,double mask,double density=1);
std::vector<std::uint8_t> encode(const Document&);
Document decode(const std::vector<std::uint8_t>&);
void validate(const Stroke&);
// Re-hit interpolated cursor rays at spacing derived from the current radius.
// Source records remain unchanged so radius edits never reuse old sparse dabs.
Stroke resample(const Surface&,const Stroke&);
}
