#pragma once
#include <algorithm>
#include <cstddef>
#include <cstdint>
#include <limits>
#include <stdexcept>
#include <type_traits>
#include <utility>

namespace cyrus::viewport_memory {
inline constexpr std::size_t MiB=1024ull*1024;
inline std::size_t add(std::size_t a,std::size_t b) {
    if(b>std::numeric_limits<std::size_t>::max()-a)throw std::overflow_error("Viewport resource size overflow");
    return a+b;
}
inline std::size_t multiply(std::size_t a,std::size_t b) {
    if(a&&b>std::numeric_limits<std::size_t>::max()/a)throw std::overflow_error("Viewport resource size overflow");
    return a*b;
}
struct Cost {
    std::size_t cpu=0,device=0;
    std::size_t total() const { return add(cpu,device); }
};
// The uploaded instance payload contains all four matrix rows and one Band
// slot per placement, in a deterministic permutation determined by the count.
// A different snapshot wrapper may share that payload only when its complete
// ordered values match. Matrix equality must be exact, never epsilon-based.
template<class Group,class=void>struct HasSparseInstances:std::false_type{};
template<class Group>struct HasSparseInstances<Group,std::void_t<decltype(std::declval<const Group&>().sameInstances(std::declval<const Group&>()))>>:std::true_type{};
template<class Group>
bool sameInstancePayload(const Group& a,const Group& b) {
    if constexpr(HasSparseInstances<Group>::value)return a.sameInstances(b);
    else return a.instances.size()==a.bandSlots.size()&&b.instances.size()==b.bandSlots.size()&&
        a.instances==b.instances&&a.bandSlots==b.bandSlots;
}
struct SystemMemory {
    bool available=false;
    std::size_t totalPhysical=0,availablePhysical=0,availableCommit=0;
};
struct Calibration {
    std::size_t automaticMaximum=0,deviceFallback=0,metadataFaces=0;
    std::size_t minimumPhysicalReserve=0,commitReserve=0;
    unsigned automaticPhysicalDivisor=1,physicalReserveDivisor=1;
};
struct SystemHeadroom {
    std::size_t available=0,physicalReserve=0,commitReserve=0;
};
inline SystemHeadroom systemHeadroom(const SystemMemory& system,const Calibration& calibration) {
    if(!calibration.physicalReserveDivisor)throw std::invalid_argument("Invalid system memory reserve policy");
    SystemHeadroom result;
    result.physicalReserve=std::max(calibration.minimumPhysicalReserve,
        system.totalPhysical/calibration.physicalReserveDivisor);
    result.commitReserve=calibration.commitReserve;
    if(system.available&&system.availablePhysical>result.physicalReserve&&system.availableCommit>result.commitReserve)
        result.available=std::min(system.availablePhysical-result.physicalReserve,
            system.availableCommit-result.commitReserve);
    return result;
}
struct Policy {
    std::size_t total=0,device=0,cpuHeadroom=0,physicalReserve=0,commitReserve=0,metadataFaces=0;
    SystemMemory system;
};
inline Policy policy(const SystemMemory& system,std::size_t requestedMiB,const Calibration& calibration) {
    if(!calibration.automaticMaximum||!calibration.deviceFallback||!calibration.metadataFaces||
       !calibration.automaticPhysicalDivisor||!calibration.physicalReserveDivisor)
        throw std::invalid_argument("Invalid viewport memory policy");
    Policy result;result.system=system;result.metadataFaces=calibration.metadataFaces;
    result.total=requestedMiB?multiply(requestedMiB,MiB):calibration.automaticMaximum;
    if(!requestedMiB&&system.available)
        result.total=std::min(result.total,system.totalPhysical/calibration.automaticPhysicalDivisor);
    // This is a finite application allowance, not a reading of installed/free VRAM.
    // No adapter is guessed when the active Nitrous device cannot be identified.
    result.device=std::min(result.total,calibration.deviceFallback);
    const auto headroom=systemHeadroom(system,calibration);
    result.physicalReserve=headroom.physicalReserve;result.commitReserve=headroom.commitReserve;
    result.cpuHeadroom=headroom.available;
    return result;
}
inline void validateMesh(std::int64_t faces,std::int64_t vertices,bool faceBuffer,bool vertexBuffer) {
    if(faces<0||vertices<0)throw std::runtime_error("Viewport source has a negative mesh count");
    if((faces&&!faceBuffer)||(vertices&&!vertexBuffer)||(faces&&!vertices))
        throw std::runtime_error("Viewport source has an incomplete mesh buffer");
}
inline void inspectFaces(std::size_t count,std::size_t& inspected,std::size_t limit) {
    if(inspected>limit||count>limit-inspected)
        throw std::runtime_error("Source geometry exceeds the finite inspected-face work allowance");
    inspected+=count;
}
inline void validateDrawCounts(std::size_t faces,std::size_t instances) {
    if(faces>std::size_t(std::numeric_limits<int>::max())/3||instances>std::size_t(std::numeric_limits<int>::max()))
        throw std::runtime_error("Viewport source exceeds the SDK draw-count range");
}
inline void validateIndex(std::uint64_t index,std::size_t vertices) {
    if(index>=vertices)throw std::runtime_error("Viewport source has an invalid face vertex");
}
struct MeshPlan {
    Cost geometry,instances,appearance;
    std::size_t geometryScratch=0,instanceScratch=0,appearanceScratch=0;
    std::size_t scratch(bool geometryNew,bool instancesNew,bool appearanceNew) const {
        return std::max({geometryNew?geometryScratch:0,instancesNew?instanceScratch:0,
            appearanceNew?appearanceScratch:0});
    }
    std::size_t total() const {
        return add(add(geometry.total(),instances.total()),add(appearance.total(),scratch(true,true,true)));
    }
};
inline MeshPlan meshPlan(std::size_t faces,std::size_t instances,bool full,std::size_t appearanceBytes,
                         std::size_t pointBytes=12,std::size_t instanceBytes=52) {
    validateDrawCounts(faces,instances);
    MeshPlan result;
    const auto sourceFaces=full?faces:0;
    const auto geometry=multiply(add(sourceFaces,12),multiply(9,pointBytes));
    const auto transforms=multiply(instances,instanceBytes);
    result.geometry={geometry,geometry};result.instances={transforms,transforms};
    // RealizeToHWMemory(true) retains the SDK system copy. UV and atlas CPU
    // originals belong to SourceAppearance and are charged separately.
    if(full)result.appearance={multiply(appearanceBytes,2),appearanceBytes};
    result.geometryScratch=multiply(std::max<std::size_t>(sourceFaces,12),multiply(3,pointBytes));
    result.instanceScratch=transforms;
    // The SDK exposes no upload-completion fence here. Keep a conservative
    // texture/UV upload-copy allowance with the resource lease, not a temporary
    // that is assumed to disappear when Realize returns.
    return result;
}
}
