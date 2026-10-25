#pragma once
#include <cyrus_vegetation/prototype_v1.hpp>
#include <nlohmann/json.hpp>
#include <array>
#include <memory>
#include <string>
#include <vector>
namespace stem {
namespace v=cyrus::vegetation::prototype_v1;
using Json=nlohmann::json;using Vec=v::Vec3;using Quat=v::Quat;
struct Rigid {Quat q;Vec shift;};
struct Guide {v::RestGuide rest;int parent=-1,parentSpan=0;double parentU=0;std::vector<unsigned> anchors;};
struct Part {unsigned guide=0,span=0;double u=0;bool stem=false;Vec restCentre;Quat restFrame;};
struct Binding {unsigned part=0,span=0;double u=0;Vec offset;};
struct Prepared {
    std::vector<Vec> positions;
    std::vector<std::array<unsigned,3>> triangles;
    std::vector<Guide> guides;std::vector<Part> parts;std::vector<unsigned> order;
    std::vector<Binding> bindings;
    std::vector<std::array<unsigned,3>> previewTriangles;std::vector<unsigned> previewMaterials;
    std::vector<unsigned> previewVertices,previewRemap;
    std::string sourceHash;
};
struct Pose {std::vector<v::GuidePose> guides;std::vector<Rigid> rigid;std::vector<bool> moved;std::uint64_t generation=1;};
struct Solved {Pose pose;Json metrics;bool ok=false;std::string error;};
std::shared_ptr<const Prepared> prepare(Json,const std::vector<Vec>&,const std::vector<std::array<unsigned,3>>&,const std::vector<unsigned>& labels);
Pose restPose(const Prepared&);
Solved solve(const Prepared&,Vec centre,double radius,double clearance,double stiffness,std::uint64_t generation);
Vec point(const Prepared&,const Pose&,unsigned vertex);
Json audit(const Prepared&,const Pose&,Vec centre,double radius,double deliveryUnit=0);
Json savePose(const Pose&);Pose loadPose(const Prepared&,const Json&);
Vec apply(Rigid,Vec);Rigid transform(const v::RestGuide&,const v::GuidePose&,unsigned,double);
}
