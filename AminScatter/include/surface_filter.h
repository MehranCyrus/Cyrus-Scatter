#pragma once
#include "scatter.h"

namespace cyrus::surface_filter {
struct Interval {
    bool enabled=false;
    double minimum=0, maximum=180, lowerFade=0, upperFade=0;
};
struct Settings { Interval slope, altitude; };
void validate(const Settings&);
double intervalWeight(double value, const Interval&);
double slopeDegrees(const amin::Triangle&);
double anchorAltitude(const amin::Triangle&, amin::Vec3 barycentric);
// One independent eligibility channel. Call after movement/reprojection and
// Edit replay; protected edits bypass this predicate in the host adapter.
bool accepts(const Settings&, double slope, double altitude, std::uint32_t seed,
             std::uint64_t ordinal, std::uint64_t receiverSalt);
}
