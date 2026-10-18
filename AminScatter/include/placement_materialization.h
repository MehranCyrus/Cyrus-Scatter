#pragma once
#include <array>
#include <cstddef>
#include <cstdint>
namespace cyrus::placements {
enum class TransportStage : std::size_t {Generate,Orientation,Paint,Edit,Readback,Receiver,Source,Eligibility,Radii,Acceptance,Count};
struct Materializations {std::uint64_t rows=0,matrices=0,strings=0,populationArrays=0;};
void observeMaterializations(bool) noexcept;
bool observingMaterializations() noexcept;
std::array<Materializations,std::size_t(TransportStage::Count)> materializations() noexcept;
// Explicit opt-in, one aggregate atomic update per function, never per plant.
// Construction counters also publish completed allocations on exception exits.
class MaterializationScope {
    TransportStage stage_;bool active_;Materializations counts_;
public:
    explicit MaterializationScope(TransportStage) noexcept;
    ~MaterializationScope();
    void row() noexcept {if(active_)++counts_.rows;}
    void matrix() noexcept {if(active_)++counts_.matrices;}
    void string() noexcept {if(active_)++counts_.strings;}
    void populationArray() noexcept {if(active_)++counts_.populationArrays;}
    void add(Materializations c) noexcept {if(active_){counts_.rows+=c.rows;counts_.matrices+=c.matrices;counts_.strings+=c.strings;counts_.populationArrays+=c.populationArrays;}}
};
}
