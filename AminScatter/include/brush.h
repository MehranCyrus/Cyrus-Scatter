#pragma once
#include "scatter.h"
#include <memory>
#include <limits>
// Canonical vector regions. No stroke history or raster mask is authoritative.
namespace cyrus::brush {
using amin::Vec3;
struct Mesh { std::vector<Vec3> vertices; std::vector<std::array<std::uint32_t,3>> faces; };
struct Ray { Vec3 origin, direction; };
struct Anchor { std::uint32_t face{}; Vec3 bary{1,0,0}; };
struct Hit { Anchor anchor; double distance{}; };
struct QueryStats { std::uint64_t triangles=0,fieldQueries=0,segments=0; };
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
};
using Point=std::array<double,2>;
using Contour=std::vector<Point>;
using Contours=std::vector<Contour>;
struct Falloff {
    double inside=0,outside=0,scaleMin=0,scaleMax=1;
    bool density=true,scale=false;
    std::vector<double> densityCurve{0,1},scaleCurve{0,1};
};
struct Document { std::uint64_t surface=0; Contours contours; Falloff falloff; };
// Local XY projection. Metric includes object scale/shear; distances use the
// transformed projection plane. Terrain height does not inflate feather width.
struct Metric {
    double xx=1,xy=0,yy=1;
    static Metric fromBasis(Vec3 x,Vec3 y);
    Point map(Point p)const;
    Point unmap(Point p)const;
};
constexpr std::size_t maxVertices=200000;
std::size_t vertexCount(const Document&);
void validate(const Falloff&);
void validateProjection(const Surface&);
Contours domain(const Surface&);
Document constrain(const Document&,const Contours& receiverDomain);
// Produces a complete successor or throws, leaving the input unchanged.
Document paint(const Document&,Point center,double radius,bool erase,Metric={},const Point* previous=nullptr);
struct Evaluation { double density=0,scale=1; };
class Field {
    struct Impl; std::shared_ptr<const Impl> impl;
public:
    Field(const Surface&,const Document&,Metric={});
    Evaluation query(Anchor,QueryStats* stats=nullptr)const;
    Evaluation queryPoint(Point,QueryStats* stats=nullptr)const;
    double evaluate(Anchor a,QueryStats* s=nullptr)const {return query(a,s).density;}
    bool accepts(Anchor,double threshold,double density=1,QueryStats* stats=nullptr)const;
    double signedDistance(Point,QueryStats* stats=nullptr)const;
};
// Border feedback is prepared separately. Drawing never queries the field.
std::vector<std::array<Vec3,2>> boundary(const Surface&,const Document&,std::size_t budget=400000);
double threshold(std::uint64_t population,std::uint64_t candidate);
bool accepted(std::uint64_t population,std::uint64_t candidate,double mask,double density=1);
std::vector<std::uint8_t> encode(const Document&);
Document decode(const std::vector<std::uint8_t>&);
}
