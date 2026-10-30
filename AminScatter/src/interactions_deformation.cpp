#include "interactions_deformation.h"
#include "geometry.hpp"
#include "math.hpp"
#include <cmath>
#include <limits>
#include <set>

namespace cyrus::interactions {
namespace f=v::fitter_detail;
namespace g=v::delivery_detail;
namespace {
constexpr unsigned indexLimit=1u<<24;
DeformationWord word(Vec p,float flag=0){DeformationWord result{float(p.x),float(p.y),float(p.z),flag};for(float x:result)if(!std::isfinite(x))throw std::runtime_error("Compact display coordinate exceeds finite float range");return result;}
DeformationWord word(v::Quat q){auto n=g::normalized(q);if(!n)throw std::runtime_error("Invalid compact pose frame");return {float(n->x),float(n->y),float(n->z),float(n->w)};}
Vec point(const DeformationWord& w){return {w[0],w[1],w[2]};}
v::Quat quaternion(const DeformationWord& w){return {w[0],w[1],w[2],w[3]};}
}
std::shared_ptr<const DeformationSource> deformationSource(std::shared_ptr<const Source> source){
    if(!source||!source->rig)throw std::runtime_error("Missing prepared source for compact display");
    auto result=std::make_shared<DeformationSource>();result->source=std::move(source);const auto& s=*result->source;const auto& rig=*s.rig;
    std::size_t nodes=2;for(const auto& guide:rig.guides)nodes+=guide.rest.nodes.size()*2;
    if(nodes>=indexLimit)throw std::runtime_error("Compact source node indices exceed exact float range");
    result->rest.reserve(nodes);result->guideSlots.reserve(rig.guides.size());
    result->rest={DeformationWord{0,0,0,0},DeformationWord{0,0,0,1}};
    result->offsetRadius.assign(rig.guides.size(),0);
    for(const auto& guide:rig.guides){
        if(result->rest.size()+guide.rest.nodes.size()*2>=indexLimit)throw std::runtime_error("Compact source node indices exceed exact float range");
        result->guideSlots.push_back(unsigned(result->rest.size()));
        for(unsigned j=0;j<guide.rest.nodes.size();++j){result->rest.push_back(word(guide.rest.nodes[j]));result->rest.push_back(word(guide.rest.material_frames[j]));}
    }
    result->faces=s.previewFaces;
    // Face addresses are native shader uints, not encoded float indices.
    if(result->faces.size()>std::numeric_limits<unsigned>::max()/10)throw std::runtime_error("Compact source binding index budget exceeded");
    result->corners.reserve(result->faces.size()*10);
    for(auto face:result->faces){const auto& triangle=rig.triangles.at(face);DeformationWord roots{};
        for(unsigned k=0;k<3;++k){unsigned vertex=triangle[k];const auto& binding=rig.bindings.at(vertex);const auto& part=rig.parts.at(binding.part);Vec offset{};DeformationWord meta{};bool fixed=part.fixed||s.anchors.at(vertex);
            if(!part.fixed)roots[k]=float(result->guideSlots.at(part.guide));
            if(!fixed){unsigned span=part.stem?binding.span:part.span;double u=part.stem?binding.u:part.u;const auto& guide=rig.guides.at(part.guide).rest;
                if(span+1>=guide.nodes.size())throw std::runtime_error("Compact binding is outside its guide");
                if(part.stem)offset=binding.offset;
                else {auto q=g::shortest_slerp(guide.material_frames[span],guide.material_frames[span+1],u);if(!q)throw std::runtime_error("Invalid compact attachment frame");offset=f::rotate(f::conjugate(*q),sub(rig.positions[vertex],f::lerp(guide.nodes[span],guide.nodes[span+1],u)));}
                auto base=result->guideSlots[part.guide];meta={float(base+2*span),float(base+2*(span+1)),float(u),float(base)};
                result->offsetRadius[part.guide]=std::max(result->offsetRadius[part.guide],length(offset));
            }
            result->corners.push_back(word(rig.positions[vertex],fixed?0.f:1.f));result->corners.push_back(meta);result->corners.push_back(word(offset));
        }
        result->corners.push_back(roots);
    }
    result->bytes=sizeof(*result)+result->corners.capacity()*sizeof(DeformationWord)+result->rest.capacity()*sizeof(DeformationWord)+(result->guideSlots.capacity()+result->faces.capacity())*sizeof(unsigned)+result->offsetRadius.capacity()*sizeof(double);
    return result;
}
std::vector<DeformationWord> deformationPose(const DeformationSource& data,const Pose& pose){
    const auto& source=*data.source;const auto& rig=*source.rig;if(pose.guides.size()!=rig.guides.size()||pose.hiddenRoots.size()!=rig.guides.size())throw std::runtime_error("Compact pose/source correspondence differs");
    auto words=data.rest;
    for(unsigned i=0;i<rig.guides.size();++i){const auto& rest=rig.guides[i];unsigned base=data.guideSlots[i];bool hidden=pose.hiddenRoots[source.guideRoot[i]]||(!pose.hiddenGuides.empty()&&pose.hiddenGuides.at(i));
        const auto& fitted=pose.guides[i];if(fitted&&(fitted->nodes.size()!=rest.rest.nodes.size()||fitted->material_frames.size()!=rest.rest.nodes.size()))throw std::runtime_error("Compact pose node correspondence differs");
        if(!fitted&&!hidden)continue;
        for(unsigned j=0;j<rest.rest.nodes.size();++j){words[base+2*j]=word(fitted?fitted->nodes[j]:rest.rest.nodes[j],hidden?-1.f:fitted?1.f:0.f);
            if(fitted){bool smooth=j==0&&i<pose.smoothedRoots.size()&&pose.smoothedRoots[i]&&rest.parent<0&&!rest.anchors.empty();words[base+2*j+1]=word(smooth?rest.rest.material_frames[j]:fitted->material_frames[j]);}}
    }
    return words;
}
Bounds deformationBounds(const DeformationSource& data,const std::vector<DeformationWord>& words){
    if(words.size()!=data.rest.size())throw std::runtime_error("Compact bounds pose length differs");Bounds b=data.source->bounds;
    const auto& guides=data.source->rig->guides;
    for(unsigned i=0;i<guides.size();++i){double radius=data.offsetRadius[i]+1e-5;
        for(unsigned j=0;j<guides[i].rest.nodes.size();++j){auto p=point(words[data.guideSlots[i]+2*j]);b.include(sub(p,{radius,radius,radius}));b.include(add(p,{radius,radius,radius}));}}
    return b;
}
Vec deformationPoint(const DeformationSource& data,const std::vector<DeformationWord>& pose,unsigned face,unsigned corner,unsigned offset){
    if(corner>2||face>=data.faces.size())throw std::runtime_error("Compact corner outside source");unsigned base=face*10+corner*3;const auto& rest=data.corners[base];const auto& meta=data.corners[base+1];
    if(rest[3]==0||pose.at(offset+unsigned(meta[3]))[3]<=0)return point(rest);
    const auto& a=pose.at(offset+unsigned(meta[0]));const auto& b=pose.at(offset+unsigned(meta[1]));auto q=g::shortest_slerp(quaternion(pose.at(offset+unsigned(meta[0])+1)),quaternion(pose.at(offset+unsigned(meta[1])+1)),meta[2]);
    if(!q)throw std::runtime_error("Invalid compact interpolated frame");return add(f::lerp(point(a),point(b),meta[2]),f::rotate(*q,point(data.corners[base+2])));
}
bool deformationVisible(const DeformationSource& data,const std::vector<DeformationWord>& pose,unsigned face,unsigned offset){const auto& roots=data.corners.at(face*10+9);for(unsigned k=0;k<3;++k)if(pose.at(offset+unsigned(roots[k]))[3]<0)return false;return true;}
DeformationChanges deformationChanges(const std::vector<DeformationChange>& changes){
    if(changes.size()>indexLimit/10)throw std::runtime_error("Compact changed-instance admission exceeded");
    DeformationChanges result;result.capacity=1;while(result.capacity<std::max<std::size_t>(1,changes.size()*2))result.capacity*=2;
    if(result.capacity>=indexLimit/5)throw std::runtime_error("Compact changed-instance table exceeds exact float index budget");
    result.words.resize(std::size_t(result.capacity)*5);std::set<unsigned> seen;
    for(const auto& c:changes){if(c.slot>=indexLimit-1||c.pose>=indexLimit||!seen.insert(c.slot).second)throw std::runtime_error("Invalid/duplicate compact instance key");
        unsigned bucket=(c.slot*2654435761u)&(result.capacity-1);while(result.words[bucket*5][0]!=0)bucket=(bucket+1)&(result.capacity-1);
        result.words[bucket*5]={float(c.slot+1),float(c.pose),c.enabled?1.f:-1.f,0};
        for(unsigned r=0;r<4;++r){auto& w=result.words[bucket*5+1+r];for(unsigned k=0;k<3;++k){float value=c.transform[r*3+k];if(!std::isfinite(value))throw std::runtime_error("Nonfinite compact transform");w[k]=value;}}
    }
    unsigned run=0,maximum=0;for(unsigned i=0;i<result.capacity*2;++i){if(result.words[(i&(result.capacity-1))*5][0])maximum=std::max(maximum,++run);else run=0;}
    result.probes=std::min(result.capacity,maximum+1);return result;
}
int deformationFind(const DeformationChanges& data,unsigned slot){if(!data.capacity)return -1;unsigned b=(slot*2654435761u)&(data.capacity-1);for(unsigned i=0;i<data.probes;++i){float key=data.words[b*5][0];if(key==0)return -1;if(key==float(slot+1))return int(b*5);b=(b+1)&(data.capacity-1);}return -1;}
}
