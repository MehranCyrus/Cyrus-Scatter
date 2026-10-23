#pragma once
#include "edit_binding.h"
#include "placement_store.h"
#include <memory>
#include <optional>
#include <string>
#include <vector>

namespace cyrus::sourceradius {
inline constexpr std::size_t maxOverrides=placements::maxRecords,maxBindingBytes=64u*1024u*1024u;
struct Lineage {std::string id,source;};
struct Binding {editbinding::Descriptor generation;std::vector<Lineage> entries;};
bool isSourceAware(std::string_view) noexcept;
Binding parse(const std::string&);
std::string encode(const Binding&);
// Pure hydration/reconciliation. Legacy IDs must all resolve in the exact
// compatible prepared view. Versioned dormant entries need not be present.
Binding bind(const placements::View&,const std::string& current,const std::string& previous,const std::vector<std::string>& ids);
struct Authored {
    std::vector<std::string> ids;
    std::vector<int> modes;
    std::vector<double> values,distances;
    std::string binding;
};
Authored author(const placements::View&,const std::string& current,const std::string& previous,
    const std::vector<std::string>& ids,const std::vector<int>& modes,const std::vector<double>& values,
    const std::vector<double>& distances,const std::vector<std::string>& selected,int mode,double value,bool reset);
// Call-owned native lookup. No placement arrays or generated textual IDs are
// materialized. Returned indices address the caller's existing override arrays.
class Replay {
    struct Impl;std::unique_ptr<Impl> impl_;
public:
    Replay(const placements::View&,const std::string& current,const std::string& previous,const std::vector<std::string>& ids);
    ~Replay();
    Replay(const Replay&)=delete;Replay& operator=(const Replay&)=delete;
    std::optional<std::size_t> find(const placements::View&,std::size_t row) const;
};
}
