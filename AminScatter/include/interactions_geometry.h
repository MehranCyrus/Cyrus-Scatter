#pragma once
#include <cyrus_vegetation/prototype_v1.hpp>
#include <array>
#include <memory>
#include <vector>
#include <optional>
#include <limits>

namespace cyrus::interactions {
namespace v=cyrus::vegetation::prototype_v1;
using Vec=v::Vec3;
using Tri=std::array<unsigned,3>;
Vec add(Vec,Vec); Vec sub(Vec,Vec); Vec mul(Vec,double);
double dot(Vec,Vec); double length(Vec); Vec cross(Vec,Vec); Vec unit(Vec);
struct Bounds {
    Vec lo{1e100,1e100,1e100},hi{-1e100,-1e100,-1e100};
    void include(Vec); void include(const Bounds&); Bounds expanded(double)const;
    bool overlaps(const Bounds&)const; double distanceSq(const Bounds&)const;
};
// Row-vector similarity, translation in metres. Nonuniform/sheared/mirrored
// transforms are rejected; inverse radii/distances are therefore unambiguous.
struct Transform {
    std::array<Vec,4> rows{{{1,0,0},{0,1,0},{0,0,1},{0,0,0}}};
    double scale()const;
    Vec point(Vec)const; Vec vector(Vec)const;
    Vec inversePoint(Vec)const; Vec inverseVector(Vec)const;
    Bounds bounds(const Bounds&)const;
};
struct Witness { Vec axis,surface,normal; double u=0,gap=0; };
class MeshGeometry {
    struct Impl;
    std::shared_ptr<const Impl> impl_;
public:
    MeshGeometry(std::vector<Vec>,std::vector<Tri>,bool requireSolid=true);
    const Bounds& bounds()const;
    bool solid()const; std::size_t bytes()const;
    Witness point(Vec)const;
    Witness segment(Vec,Vec)const;
    std::optional<Witness> contactSegment(Vec,Vec,double radius)const;
    // Finite maximum returns min(actual distance, maximum), a contact-band proof.
    double triangleDistance(Vec,Vec,Vec,double maximum=std::numeric_limits<double>::infinity())const;
    bool rayHit(Vec origin,Vec direction,double maximumDistance)const;
    bool projectedNear(Vec origin,Vec direction,double radius)const;
    bool overlapsSolid(const Bounds&)const;
};
struct Shape {
    std::uint64_t id=0;
    std::shared_ptr<const MeshGeometry> geometry;
    Transform transform;
    bool coverRoots=true;
};
// Numerical mesh adapter for the frozen fitter contract. Mesh admission and
// signed-distance semantics are explicit here; the frozen obstacle enum stays
// unchanged. Geometry is shared and immutable; calls are serialized per world.
class MeshWorld final:public v::CollisionWorld {
    std::uint64_t generation_;
    std::vector<Shape> shapes_;
    std::size_t maxCalls_,maxContacts_;
    mutable std::size_t calls_=0;
    bool admit(v::Cancellation)const;
public:
    MeshWorld(std::uint64_t,std::vector<Shape>,std::size_t maxCalls=200000,std::size_t maxContacts=64);
    v::Generation generation()const noexcept override{return generation_;}
    v::BackendIdentity backend()const override;
    v::PointResult classify_point(Vec,double,v::Cancellation)const override;
    v::ContactResult query_capsule(const v::CapsuleQuery&,v::Cancellation)const override;
    std::size_t calls()const{return calls_;}
};
}
