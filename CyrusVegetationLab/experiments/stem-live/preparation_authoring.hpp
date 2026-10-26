#pragma once
#include "analysis.hpp"
#include <map>
namespace prep {
struct Piece {
    std::vector<unsigned> vertices,faces;
    unsigned material=0;
    bool mixed=false;
};
struct Pieces { std::vector<unsigned> labels;std::vector<Piece> parts; };
Pieces inspectPieces(const Snapshot&,Settings,const std::atomic_bool&);
// Sparse intent is bound to the exact source indexing/geometry generation.
// 1 Bend, 2 rigid Follow, 3 Fixed. Absence means Automatic.
stem::Json canonicalAuthoring(const Snapshot&,const Pieces&,const stem::Json&);
std::map<unsigned,stem::Json> authoringRows(const stem::Json&);
}
