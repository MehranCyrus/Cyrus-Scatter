#include "cyrus_arrange/fit_feedback.h"
#include <algorithm>
#include <cmath>
#include <iomanip>
#include <limits>
#include <sstream>
#include <stdexcept>

namespace cyrus::arrange {
namespace {
FitIssue issue_for(const QueryResult& q) {
    if(q.witness.issue!=FitIssue::None)return q.witness.issue;
    switch(q.reason){
    case Rejection::Unsupported:case Rejection::Boundary:return FitIssue::Support;
    case Rejection::Obstacle:return FitIssue::Occupied;
    case Rejection::Spacing:return FitIssue::Spacing;
    case Rejection::Stack:return FitIssue::Stack;
    case Rejection::Category:return FitIssue::Excluded;
    default:return FitIssue::Search;
    }
}
bool finite(Vec3 p){return std::isfinite(p.x)&&std::isfinite(p.y)&&std::isfinite(p.z);}
std::string percent(double scale){std::ostringstream s;s<<std::fixed<<std::setprecision(1)<<scale*100;return s.str()+"%";}
}
FitFailureRecorder::FitFailureRecorder(std::span<const Asset> assets) {
    if(assets.size()>256)throw std::invalid_argument("Fit feedback admits at most 256 sources.");
    for(const auto& a:assets)if(!a.id||!sources_.try_emplace(a.id).second)throw std::invalid_argument("Fit feedback source IDs must be distinct and nonzero.");
}
void FitFailureRecorder::note(const Placement& p,const QueryResult& q,const Bounds* space) {
    if(q.reason==Rejection::None)return;
    auto it=sources_.find(p.asset_id);if(it==sources_.end())throw std::logic_error("Unknown fit-feedback source.");
    if(q.reason>=Rejection::Count||q.witness.issue>=FitIssue::Count||!finite(p.position)||!std::isfinite(p.yaw_degrees)||!std::isfinite(p.scale)||p.scale<=0)
        throw std::logic_error("Invalid fit-feedback witness.");
    auto& source=it->second;if(source.attempts<std::numeric_limits<std::size_t>::max())++source.attempts;
    Seed next{p,q};
    if(space){
        if(!finite(space->min)||!finite(space->max)||space->min.x>space->max.x||space->min.y>space->max.y||space->min.z>space->max.z)throw std::logic_error("Invalid sampled fit space.");
        next.space=*space;next.has_space=true;
        const double x=(space->min.x+space->max.x)*.5,y=(space->min.y+space->max.y)*.5;
        next.score=std::hypot(p.position.x-x,p.position.y-y);
    }
    const auto same=std::find_if(source.seeds.begin(),source.seeds.end(),[&](const auto& s){return s.pose.region_id==p.region_id&&std::abs(std::remainder(s.pose.yaw_degrees-p.yaw_degrees,360.0))<1e-8;});
    if(same!=source.seeds.end()){if(next.score<same->score)*same=next;return;}
    if(source.seeds.size()<8){if(source.seeds.empty())source.seeds.reserve(8);source.seeds.push_back(next);return;}
    const auto worst=std::max_element(source.seeds.begin(),source.seeds.end(),[](const auto& a,const auto& b){return a.score<b.score;});
    if(next.score<worst->score)*worst=next;
}
FitFeedback FitFailureRecorder::finish(const ArrangementResult& result,std::span<const AssetMinimum> minimums,
    const ArrangeSettings& settings,const FitProbe& probe,const FitFeedbackLimits& limits)const {
    if(limits.max_work>5000000||limits.max_probes>4096||!probe)throw std::invalid_argument("Fit feedback limits exceed hard bounds.");
    if(result.placements.size()>10000||minimums.size()>256)throw std::invalid_argument("Fit feedback result exceeds admission.");
    FitFeedback out;if(!result.stats.underfilled)return out;
    std::map<std::uint64_t,std::size_t> counts,minima;
    for(const auto& p:result.placements){if(!sources_.contains(p.asset_id))throw std::invalid_argument("Unknown fit-feedback output source.");++counts[p.asset_id];}
    for(const auto& m:minimums)if(!sources_.contains(m.asset_id)||m.quantity>10000||!minima.emplace(m.asset_id,m.quantity).second)throw std::invalid_argument("Invalid fit-feedback minimum.");
    const auto test=[&](const Placement& seed,Placement& trial)->std::optional<QueryResult>{
        if(out.probes>=limits.max_probes||out.work>=limits.max_work){out.limited=true;return std::nullopt;}
        const auto remaining=limits.max_work-out.work;++out.probes;
        try{
            const auto checked=probe(seed,trial,remaining);
            if(checked.work_units>remaining||checked.reason>=Rejection::Count||checked.witness.issue>=FitIssue::Count)
                throw std::runtime_error("Invalid diagnostic physical query result.");
            out.work+=checked.work_units;return checked;
        }catch(const std::exception&){
            // Optional advice cannot reject validated output. Charge the entire
            // admitted remainder conservatively; never treat an exception as fit.
            out.work=limits.max_work;out.limited=true;return std::nullopt;
        }
    };
    out.reports.reserve(sources_.size());
    for(const auto& [id,source]:sources_){
        FitReport report;report.asset_id=id;report.placed=counts[id];report.minimum=minima[id];report.failed_attempts=source.attempts;
        report.allowed_minimum=settings.scale_min;
        for(const auto& seed:source.seeds){
            auto original=seed.pose;const auto failed=test(seed.pose,original);
            if(!failed){report.limited=true;break;}
            if(!report.has_failure){report.failed=original;report.has_failure=true;report.witness=failed->witness;report.issue=issue_for(*failed);report.sampled_space=seed.space;report.has_space=seed.has_space;}
            if(failed->reason==Rejection::None){
                report.failed=original;report.issue=FitIssue::Search;report.witness={};report.has_suggestion=true;report.suggested=original;report.preferred_fits=true;report.sampled_space=seed.space;report.has_space=seed.has_space;break;
            }
            std::optional<Placement> best;double invalid=seed.pose.scale;
            for(unsigned step=1;seed.pose.scale>.01&&step<=16;++step){
                auto trial=seed.pose;trial.scale=step==16?.01:seed.pose.scale*std::pow(.01/seed.pose.scale,static_cast<double>(step)/16);
                const auto checked=test(seed.pose,trial);if(!checked){report.limited=true;break;}
                if(checked->reason==Rejection::None){best=trial;break;}invalid=trial.scale;
            }
            if(best){
                for(unsigned refine=0;refine<12;++refine){
                    auto trial=*best;trial.scale=(best->scale+invalid)*.5;
                    const auto checked=test(seed.pose,trial);if(!checked){report.limited=true;break;}
                    if(checked->reason==Rejection::None)best=trial;else invalid=trial.scale;
                }
                if(!report.has_suggestion||best->scale>report.suggested.scale){
                    report.has_suggestion=true;report.suggested=*best;report.failed=original;report.witness=failed->witness;report.issue=issue_for(*failed);
                    report.sampled_space=seed.space;report.has_space=seed.has_space;
                }
            }
            if(out.limited)break;
        }
        report.limited=report.limited||out.limited;
        if(report.has_suggestion&&!report.preferred_fits&&!out.limited){
            float percent=static_cast<float>(std::min(1.0,report.suggested.scale)*100.0);
            for(unsigned step=0;step<3&&percent>=1;++step){
                auto trial=report.suggested;trial.scale=static_cast<double>(percent)/100.0;
                const auto checked=test(report.failed,trial);
                if(!checked){report.limited=true;break;}
                if(checked->reason==Rejection::None){report.suggested=trial;report.apply_percent=percent;break;}
                percent=std::nextafter(percent,0.0f);
            }
        }
        report.below_minimum=report.has_suggestion&&report.suggested.scale+1e-6<report.allowed_minimum;
        out.reports.push_back(report);
    }
    return out;
}
std::string fit_report_message(const FitReport& r) {
    std::string s="Last Generate: "+std::to_string(r.placed)+" placed";
    if(r.minimum)s+=" / "+std::to_string(r.minimum)+" minimum";
    s+=". ";
    switch(r.issue){
    case FitIssue::Support:s+="Footprint is not fully supported at the tested position.";break;
    case FitIssue::Width:s+="Width is blocked at the tested position.";break;
    case FitIssue::Depth:s+="Depth is blocked at the tested position.";break;
    case FitIssue::Height:s+="Not enough height at the tested position.";break;
    case FitIssue::Occupied:s+="The tested space is occupied.";break;
    case FitIssue::Spacing:s+="The tested position leaves too little gap.";break;
    case FitIssue::Access:s+="The approach to the tested position is blocked.";break;
    case FitIssue::Stack:s+="The tested stack lacks suitable support.";break;
    case FitIssue::Excluded:s+="The tested region is excluded.";break;
    case FitIssue::Lane:s+="The footprint extends outside the lane at the tested position.";break;
    default:s+="The bounded search left copies unfilled.";break;
    }
    if(r.has_suggestion){s+=" A physically checked fit is "+percent(r.suggested.scale)+".";if(r.below_minimum)s+=" Current minimum is "+percent(r.allowed_minimum)+".";}
    else if(r.has_failure&&r.issue!=FitIssue::Search)s+=" No smaller fit was verified.";
    if(r.limited)s+=" Feedback reached its check limit.";
    return s;
}
}
