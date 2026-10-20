#pragma once
#include "cyrus_arrange/arrangement.h"
#include "cyrus_arrange/region_registry.h"
#include "cyrus_arrange/path.h"
#include <array>
#include <cstdint>
#include <memory>
#include <string>
#include <utility>
#include <vector>

namespace cyrus::arrange::host {
inline constexpr std::size_t max_furniture_nodes = 4096;
inline constexpr std::size_t max_obstacle_nodes = 4096;
inline constexpr std::size_t max_document_assets = 256;
inline constexpr std::size_t max_document_placements = 10000;
inline constexpr std::size_t max_document_composition_groups = max_document_placements / 2;
inline constexpr std::size_t max_document_bytes = 160u*1024u*1024u;

// Immutable document copies share captured asset geometry. An explicit mutable
// catalog access detaches once; const reads and settings/lock edits do not.
class AssetCatalog {
    std::shared_ptr<std::vector<Asset>> values_{std::make_shared<std::vector<Asset>>()};
    std::vector<Asset>& write() {
        if(values_.use_count()!=1)values_=std::make_shared<std::vector<Asset>>(*values_);
        return *values_;
    }
public:
    using value_type=Asset;
    using iterator=std::vector<Asset>::iterator;
    using const_iterator=std::vector<Asset>::const_iterator;
    AssetCatalog()=default;
    AssetCatalog(std::vector<Asset> values):values_(std::make_shared<std::vector<Asset>>(std::move(values))){}
    AssetCatalog& operator=(std::vector<Asset> values){values_=std::make_shared<std::vector<Asset>>(std::move(values));return *this;}
    operator const std::vector<Asset>&()const noexcept{return *values_;}
    const std::vector<Asset>& read()const noexcept{return *values_;}
    std::size_t size()const noexcept{return values_->size();}
    bool empty()const noexcept{return values_->empty();}
    const Asset* data()const noexcept{return values_->data();}
    Asset* data(){return write().data();}
    const_iterator begin()const noexcept{return values_->begin();}
    const_iterator end()const noexcept{return values_->end();}
    const_iterator cbegin()const noexcept{return values_->cbegin();}
    const_iterator cend()const noexcept{return values_->cend();}
    iterator begin(){return write().begin();}
    iterator end(){return write().end();}
    const Asset& operator[](std::size_t index)const{return (*values_)[index];}
    Asset& operator[](std::size_t index){return write()[index];}
    const Asset& back()const{return values_->back();}
    Asset& back(){return write().back();}
    const Asset& at(std::size_t index)const{return values_->at(index);}
    Asset& at(std::size_t index){return write().at(index);}
    void push_back(Asset value){write().push_back(std::move(value));}
    void reserve(std::size_t count){write().reserve(count);}
    void clear(){values_=std::make_shared<std::vector<Asset>>();}
    iterator erase(const_iterator position) {
        const auto offset=position-values_->cbegin();return write().erase(values_->cbegin()+offset);
    }
    iterator erase(const_iterator first,const_iterator last) {
        const auto begin_offset=first-values_->cbegin(),end_offset=last-values_->cbegin();
        auto& values=write();return values.erase(values.cbegin()+begin_offset,values.cbegin()+end_offset);
    }
};

struct AssetCapturePolicy {
    bool source_required{}; // Imported geometry is deliberately unbound; deleted scene sources are errors.
    bool authored_contact{}; // Retain artist anchor/contact patch when refreshing geometry.
    bool authored_stack{}; // Retain and revalidate an artist-authored top patch.
};
struct PathLayout {
    std::uint32_t curve_index{};
    std::size_t lane_count{1};
    PathSettings settings;
    std::array<PathLane,2> lanes = []{
        std::array<PathLane,2> result{};
        result[0]={1,100,0,3000,5000,false,false};
        result[1]={2,3,-1750,3000,5000,true,true};return result;
    }();
};
struct DocumentState {
    std::string document_id; // GUID namespace; clone/duplicate merge gets a new GUID.
    std::uint64_t revision{1}, next_id{1};
    std::string label{"Cyrus Arrange"};
    Settings inspection;
    ArrangeSettings arrangement;
    std::array<std::vector<CategoryRule>,static_cast<std::size_t>(FurnitureCategory::Count)> category_rules = []{
        std::array<std::vector<CategoryRule>,static_cast<std::size_t>(FurnitureCategory::Count)> rows;
        for(auto& categories:rows)for(std::uint32_t i=0;i<static_cast<std::uint32_t>(AssetCategory::Count);++i)categories.push_back({static_cast<AssetCategory>(i),1.0,0,false});
        for(const auto& preset:default_furniture_presets())for(const auto& rule:preset.rules)rows[static_cast<std::size_t>(preset.furniture)][static_cast<std::size_t>(rule.category)]=rule;
        return rows;
    }();
    bool live{}; // Manual is the default. Load requires one explicit successful update.
    AssetCatalog assets;
    std::vector<AssetCapturePolicy> asset_capture;
    std::vector<std::uint64_t> furniture_source_keys;
    std::shared_ptr<const RegionRegistry> regions{std::make_shared<RegionRegistry>()};
    std::vector<Placement> placements;
    Vec3 frame_origin_mm{}; // Add to placement.position to obtain world-mm contact.
    std::size_t furniture_count{};
    std::size_t obstacle_count{};
    bool require_front_access{}; // Explicit optional access sweep, never inferred from a furniture label.
    std::int32_t capture_time{};
    double captured_mm_per_system_unit{1.0};
    CompositionOptions composition;
    std::vector<CompositionGroup> composition_groups;
    std::optional<PathLayout> path; // Present iff one real path-reference slot exists.
    std::vector<AssetMinimum> minimums; // Per-arrangement counts; not library tags.
};
// Schema7 appends bounded per-source minimum counts after the schema6 path footer.
// Decode publishes only after success, including high-water recovery.
inline constexpr std::uint32_t document_schema_version = 7;
void validate_document_state(const DocumentState&);
std::vector<std::uint8_t> encode_document_state(const DocumentState&,std::uint64_t id_high_water);
std::shared_ptr<const DocumentState> decode_document_state(const std::vector<std::uint8_t>&,std::uint64_t& id_high_water);
}
