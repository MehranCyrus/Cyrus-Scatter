#pragma once
#include <cstddef>
#include <map>
#include <string>
#include <string_view>
#include <vector>

namespace cyrus::editbinding {
// Current inventories remain bounded by native placement SourceCohort. The
// larger historical inventory preserves removed roles without recycling IDs.
inline constexpr std::size_t maxActiveSources=1024,maxSources=4096,
    maxIdentityBytes=256,maxSettingsBytes=65536,maxSignatureBytes=1048576,
    maxDescriptorBytes=8388608;
struct SourceSpec {std::string id,settings;};
struct Descriptor {
    std::string legacy,basis;
    std::map<std::string,std::string> sources;
};
struct Merge {Descriptor descriptor;bool legacyHydrated=false;};
bool isSourceAware(std::string_view) noexcept;
Descriptor parse(const std::string&);
std::string encode(const Descriptor&);
std::string make(const std::string& legacy,const std::string& basis,const std::vector<SourceSpec>&);
// Pure operation: caller installs only inside its existing transaction. Legacy
// compatibility proves the signature, not the ownership of an absent row.
// Hydrating each old row still requires its exact compatible native input.
Merge merge(const std::string& previous,const std::string& current);
const std::string* sourceRevision(const Descriptor&,const std::string& id) noexcept;
}
