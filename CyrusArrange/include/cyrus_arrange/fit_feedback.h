#pragma once
#include "cyrus_arrange/arrangement.h"
#include <functional>
#include <map>

namespace cyrus::arrange {
struct FitFeedbackLimits {
    std::uint64_t max_work{5000000};
    std::size_t max_probes{4096};
};
// The callback may normalize the trial's anchor (path base centers). It must
// validate the complete final pose, including final accepted output, within work.
using FitProbe = std::function<QueryResult(const Placement& seed,Placement& trial,std::uint64_t work)>;
class FitFailureRecorder {
    struct Seed { Placement pose; QueryResult checked; Bounds space; bool has_space{}; double score{}; };
    struct Source { std::size_t attempts{}; std::vector<Seed> seeds; };
    std::map<std::uint64_t,Source> sources_;
public:
    explicit FitFailureRecorder(std::span<const Asset>);
    // Synchronous copied values; at most 8 region/yaw representatives per source.
    void note(const Placement&,const QueryResult&,const Bounds* sampled_space=nullptr);
    FitFeedback finish(const ArrangementResult&,std::span<const AssetMinimum>,const ArrangeSettings&,
                       const FitProbe&,const FitFeedbackLimits& = {}) const;
};
std::string fit_report_message(const FitReport&);
}
