#pragma once
#include "analysis.hpp"
#include <limits>
namespace prep {
using Point=std::array<double,3>;
struct Tube {std::vector<Point> nodes;std::vector<double> radii;bool basalBlade=false;bool canParent=true;bool orientedRoot=false;};
struct Connection {int parent=-1;unsigned parentSpan=0;double parentU=0,distance=0;bool reversed=false,basal=false,resolved=false;};
struct Forest {std::vector<Connection> links;std::vector<unsigned> order;double ground=0,basalBand=0;unsigned roots=0,unresolved=0,candidates=0;};
// Numeric geometry only. Source guide IDs stay unchanged; order is a validated forest traversal.
Forest connect(const std::vector<Tube>&,const std::atomic_bool& cancel,Limits limits={},double connectionReach=.025,double basalFraction=.01,double groundOverride=std::numeric_limits<double>::quiet_NaN(),double bandOverride=std::numeric_limits<double>::quiet_NaN());
}
