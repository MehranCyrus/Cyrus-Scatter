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
// Reusable exact cofactor inverse for an immutable admitted transform.
struct InverseTransform {
    Vec translation;std::array<Vec,3> cofactors;double determinant;
    explicit InverseTransform(const Transform&);
    Vec point(Vec)const;
};
struct Witness { Vec axis,surface,normal; double u=0,gap=0; };
// Geometry-only certificate: local triangle addresses and one vertex for each
// indexed connected component (including unused vertices). Rebuilt with the
// source, never with a pose. UV seams remain separate components, conservatively.
struct ContactTopology {
    unsigned vertices=0;
    std::vector<Tri> triangles;
    std::vector<unsigned> components;
    ContactTopology()=default;
    ContactTopology(unsigned,std::vector<Tri>);
};
struct MeshContactWork {
    std::size_t checks=0,pointTests=0,faceTests=0,transformedVertices=0,inverseVertices=0;
    double pointMs=0,faceMs=0;
};
class MeshGeometry {
    struct Impl;
    std::shared_ptr<const Impl> impl_;
public:
    std::shared_ptr<const void> allocationLease;
    MeshGeometry(std::vector<Vec>,std::vector<Tri>,bool requireSolid=true);
    const Bounds& bounds()const;
    bool solid()const; std::size_t bytes()const;
    // A collider may have an arbitrary nonsingular affine linear transform.
    // Bake it into private numeric geometry; scene/render nodes are untouched.
    std::shared_ptr<const MeshGeometry> bakeLinear(const Transform&,std::shared_ptr<const void> lease={})const;
    Witness point(Vec)const;
    // Equivalent to point(p).gap * scale < gap for a positive contact band,
    // without calculating a closest-point witness for distant points.
    bool occupied(Vec p,double scale,double gap)const;
    Witness segment(Vec,Vec)const;
    std::optional<Witness> contactSegment(Vec,Vec,double radius)const;
    // Strict segment/solid contact band without constructing a witness.
    bool segmentNear(Vec,Vec,double band)const;
    // Finite maximum returns min(actual distance, maximum), a contact-band proof.
    double triangleDistance(Vec,Vec,Vec,double maximum=std::numeric_limits<double>::infinity())const;
    // Strict contact-band predicate, equivalent to triangleDistance(...,band)
    // < band, with no nearest-distance calculation after a contact is proved.
    bool triangleNear(Vec,Vec,Vec,double band)const;
    bool rayHit(Vec origin,Vec direction,double maximumDistance)const;
    bool projectedNear(Vec origin,Vec direction,double radius)const;
    bool overlapsSolid(const Bounds&)const;
};
// A component cannot enter a closed solid without crossing its boundary. Test
// every triangle against the positive band and one point per component for
// containment; this also catches fully enclosed/disconnected and unused pieces.
bool meshNear(const MeshGeometry&,const std::vector<Vec>&,const ContactTopology&,
              double band,std::size_t& work,MeshContactWork&);
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
    struct ShapeQuery {
        Bounds bounds;InverseTransform inverse;double scale;
        explicit ShapeQuery(const Shape&);
    };
    std::uint64_t generation_;
    std::vector<Shape> shapes_;
    std::vector<ShapeQuery> cached_;
    std::size_t maxCalls_,maxContacts_;
    mutable std::size_t calls_=0;
    bool admit(v::Cancellation)const;
public:
    static constexpr std::size_t cachedShapeBytes(){return sizeof(ShapeQuery);}
    MeshWorld(std::uint64_t,std::vector<Shape>,std::size_t maxCalls=200000,std::size_t maxContacts=64);
    v::Generation generation()const noexcept override{return generation_;}
    v::BackendIdentity backend()const override;
    v::PointResult classify_point(Vec,double,v::Cancellation)const override;
    v::ContactResult query_capsule(const v::CapsuleQuery&,v::Cancellation)const override;
    // Equivalent clearance question for hinge search. Borderline similarities
    // fall back to the ordinary witness query rather than approximating it.
    std::optional<bool> capsuleClear(const v::CapsuleQuery&,v::Cancellation,double penetrationTolerance)const;
    std::size_t calls()const{return calls_;}
};
}
