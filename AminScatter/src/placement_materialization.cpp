#include "placement_materialization.h"
#include <atomic>
namespace cyrus::placements {
namespace {
std::atomic<bool> enabled{false};
struct Counts {std::atomic<std::uint64_t> rows{0},matrices{0},strings{0},populationArrays{0};};
std::array<Counts,std::size_t(TransportStage::Count)> counts;
}
void observeMaterializations(bool value) noexcept {enabled.store(value,std::memory_order_relaxed);}
bool observingMaterializations() noexcept {return enabled.load(std::memory_order_relaxed);}
std::array<Materializations,std::size_t(TransportStage::Count)> materializations() noexcept {
    std::array<Materializations,std::size_t(TransportStage::Count)> result{};
    for(std::size_t i=0;i<result.size();++i)result[i]={counts[i].rows.load(),counts[i].matrices.load(),counts[i].strings.load(),counts[i].populationArrays.load()};
    return result;
}
MaterializationScope::MaterializationScope(TransportStage stage) noexcept:stage_(stage),active_(observingMaterializations()){}
MaterializationScope::~MaterializationScope(){
    if(!active_)return;auto& c=counts[std::size_t(stage_)];
    c.rows.fetch_add(counts_.rows,std::memory_order_relaxed);c.matrices.fetch_add(counts_.matrices,std::memory_order_relaxed);c.strings.fetch_add(counts_.strings,std::memory_order_relaxed);
    c.populationArrays.fetch_add(counts_.populationArrays,std::memory_order_relaxed);
}
}
