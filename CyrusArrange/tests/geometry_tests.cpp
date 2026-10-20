#include "cyrus_arrange/geometry.h"

#include <algorithm>
#include <cmath>
#include <functional>
#include <iostream>
#include <limits>
#include <stdexcept>
#include <string>
#include <utility>
#include <vector>

using namespace cyrus::arrange;
namespace {
void check(bool condition, const char* message) { if (!condition) throw std::runtime_error(message); }
void near(double actual, double expected, const char* message) { check(std::abs(actual-expected) <= 1e-7, message); }
void rejects(const std::function<void()>& action) {
    bool rejected = false;
    try { action(); } catch (const std::exception&) { rejected = true; }
    check(rejected, "Expected invalid or over-budget request to throw");
}
void quad(Mesh& mesh, Vec3 a, Vec3 b, Vec3 c, Vec3 d) {
    const auto base = static_cast<std::uint32_t>(mesh.vertices.size());
    mesh.vertices.insert(mesh.vertices.end(), {a,b,c,d});
    mesh.triangles.push_back({{base,base+1,base+2}});
    mesh.triangles.push_back({{base,base+2,base+3}});
}
void plane(Mesh& mesh, double x0, double y0, double x1, double y1, double z, bool upward = true) {
    if (upward) quad(mesh,{x0,y0,z},{x1,y0,z},{x1,y1,z},{x0,y1,z});
    else quad(mesh,{x0,y0,z},{x0,y1,z},{x1,y1,z},{x1,y0,z});
}
void box(Mesh& mesh, double x0, double y0, double z0, double x1, double y1, double z1) {
    plane(mesh,x0,y0,x1,y1,z0,false); plane(mesh,x0,y0,x1,y1,z1);
    quad(mesh,{x0,y0,z0},{x1,y0,z0},{x1,y0,z1},{x0,y0,z1});
    quad(mesh,{x1,y0,z0},{x1,y1,z0},{x1,y1,z1},{x1,y0,z1});
    quad(mesh,{x1,y1,z0},{x0,y1,z0},{x0,y1,z1},{x1,y1,z1});
    quad(mesh,{x0,y1,z0},{x0,y0,z0},{x0,y0,z1},{x0,y1,z1});
}
const Region& at_height(const Result& result, double z) {
    const auto found = std::find_if(result.regions.begin(),result.regions.end(),[z](const Region& r) {
        return !r.cells.empty() && std::abs(r.cells.front().center.z-z) < 1e-7;
    });
    if (found == result.regions.end()) throw std::runtime_error("Expected support layer not present");
    return *found;
}
void repeat_equal(const Result& a, const Result& b) {
    check(a.regions.size()==b.regions.size() && a.sampled_cells==b.sampled_cells && a.work==b.work && a.warnings==b.warnings,
        "Repeated inspection must have identical statistics");
    for (std::size_t i=0; i<a.regions.size(); ++i) {
        const auto& x=a.regions[i]; const auto& y=b.regions[i];
        check(x.id==y.id && x.cells.size()==y.cells.size() && x.sampled_area_mm2==y.sampled_area_mm2 &&
            x.usable_area_mm2==y.usable_area_mm2 && x.minimum_clearance_mm==y.minimum_clearance_mm && x.open_above==y.open_above,
            "Repeated regions must match exactly");
        for (std::size_t j=0; j<x.cells.size(); ++j) {
            const auto& p=x.cells[j]; const auto& q=y.cells[j];
            check(p.center.x==q.center.x && p.center.y==q.center.y && p.center.z==q.center.z &&
                p.clearance_mm==q.clearance_mm && p.usable==q.usable,"Repeated cell order and values must match exactly");
        }
    }
}

void console_top() {
    Mesh mesh; box(mesh,0,0,0,100,100,20);
    const auto result=inspect(mesh);
    check(result.regions.size()==1 && result.sampled_cells==16,"Box has one 4 by 4 top and no underside");
    const auto& top=at_height(result,20);
    near(top.sampled_area_mm2,10000,"Known box top sampled area");
    near(top.usable_area_mm2,10000,"Open box top area is usable");
    check(top.open_above && std::isinf(top.minimum_clearance_mm),"Box top is open above");
    near(result.bounds.min.z,0,"Input lower bound"); near(result.bounds.max.z,20,"Input upper bound");
    near(top.bounds.min.x,0,"Region starts on grid origin"); near(top.bounds.max.x,100,"Region spans complete grid cells");
    check(result.input_triangles==12 && result.degenerate_triangles==0,"Box triangle counts");
    repeat_equal(result,inspect(mesh));
}
void shelf_layers() {
    Mesh mesh; box(mesh,0,0,0,100,100,20); box(mesh,0,0,200,100,100,220); box(mesh,0,0,500,100,100,520);
    const auto result=inspect(mesh);
    check(result.regions.size()==3 && result.sampled_cells==48,"All shelf layers must be sampled");
    near(at_height(result,20).minimum_clearance_mm,180,"Lower shelf sees underside of next board");
    near(at_height(result,220).minimum_clearance_mm,280,"Middle shelf sees underside of upper board");
    check(at_height(result,520).open_above,"Top shelf has no overhead");
    check(!at_height(result,20).open_above,"Finite clearance is not reported as open");
}
void half_overhead() {
    Mesh mesh; box(mesh,0,0,0,100,100,10); plane(mesh,50,0,100,100,90,false);
    const auto result=inspect(mesh); const auto& top=at_height(result,10);
    check(result.regions.size()==1 && top.cells.size()==16,"Blocked and unblocked cells retain the same support region");
    near(top.minimum_clearance_mm,80,"Clearance uses nearest overhead");
    near(top.usable_area_mm2,5000,"Only uncovered half clears 100 mm");
    check(std::count_if(top.cells.begin(),top.cells.end(),[](const Cell& c){return !c.usable;})==8,"Eight cells are blocked");
}
void corner_overhead() {
    Mesh mesh; box(mesh,0,0,0,100,100,10); plane(mesh,0,0,4,4,60,false);
    const auto result=inspect(mesh); const auto& surface=at_height(result,10);
    near(surface.minimum_clearance_mm,50,"Inset corner ray catches overhead absent at centre");
    near(surface.usable_area_mm2,9375,"One corner-blocked cell is unusable");
}
void hole_and_islands() {
    Mesh ring; plane(ring,0,0,100,25,0); plane(ring,0,75,100,100,0);
    plane(ring,0,25,25,75,0); plane(ring,75,25,100,75,0);
    const auto result=inspect(ring);
    check(result.regions.size()==1 && result.sampled_cells==12,"Ring is connected while its four-cell hole stays empty");
    near(result.regions[0].sampled_area_mm2,7500,"Hole is absent from sampled area");
    for (const auto& c:result.regions[0].cells) check(!(c.center.x>25 && c.center.x<75 && c.center.y>25 && c.center.y<75),"Hole cannot contain support cells");
    Mesh split; plane(split,0,0,50,100,0); plane(split,75,0,100,100,0);
    const auto islands=inspect(split);
    check(islands.regions.size()==2 && islands.sampled_cells==12,"A cell-wide gap separates islands");
    Mesh diagonal; plane(diagonal,0,0,25,25,0); plane(diagonal,25,25,50,50,0);
    check(inspect(diagonal).regions.size()==2,"Diagonal contact does not join 4-neighbour regions");
}
void support_corner_and_height_steps() {
    Mesh mesh;
    // The centre of one 25 mm cell is supported, but the inset corners are outside this small patch.
    plane(mesh,10,10,15,15,0);
    // Unused geometry contributes no bounds; these downward triangles establish the requested XY extent.
    plane(mesh,0,0,25,25,-20,false);
    check(inspect(mesh).regions.empty(),"Centre-only support cannot produce a cell");
    Mesh steps; plane(steps,0,0,25,25,0); plane(steps,25,0,50,25,10);
    check(inspect(steps).regions.size()==2,"Adjacent supports at incompatible heights remain separate");
}
void slopes_and_transforms() {
    Mesh slope; quad(slope,{0,0,0},{100,0,5},{100,100,5},{0,100,0});
    const auto result=inspect(slope);
    check(result.regions.size()==1 && result.sampled_cells==16,"Allowed slope stays connected using its plane prediction");
    Settings steep; steep.maximum_slope_degrees=1;
    check(inspect(slope,steep).regions.empty(),"Slope threshold excludes an excessive slope");
    Mesh mirrored; plane(mirrored,0,0,100,100,20);
    for (auto& p:mirrored.vertices) p.x=-p.x;
    for (auto& t:mirrored.triangles) std::swap(t.vertices[1],t.vertices[2]);
    const auto reflected=inspect(mirrored);
    check(reflected.sampled_cells==16,"Adapter-corrected mirror keeps upward support");
    near(reflected.bounds.min.x,-100,"Mirrored bounds");
    Mesh scaled; plane(scaled,0,0,100,100,20);
    for (auto& p:scaled.vertices) {p.x*=2; p.y*=0.5; p.z*=3;}
    const auto transformed=inspect(scaled);
    check(transformed.regions.size()==1 && transformed.sampled_cells==16,"Baked nonuniform scale uses physical dimensions");
    near(at_height(transformed,60).sampled_area_mm2,10000,"Nonuniform scale area");
    Mesh inverted; plane(inverted,0,0,100,100,20,false);
    check(inspect(inverted).regions.empty(),"Downward winding is not a support surface");
}
void close_cover_and_nearest_hit() {
    Mesh close; plane(close,0,0,100,100,0); plane(close,0,0,100,100,0.1,false);
    const auto covered=inspect(close);
    near(covered.regions[0].minimum_clearance_mm,0.1,"Height tolerance does not hide a thin overhead blocker");
    near(covered.regions[0].usable_area_mm2,0,"Covered surface has no usable cells");
    Mesh two; plane(two,0,0,100,100,0); plane(two,0,0,100,100,250,false); plane(two,0,0,100,100,70,false);
    near(inspect(two).regions[0].minimum_clearance_mm,70,"Nearest hit is independent of triangle insertion height order");
    Settings equality; equality.minimum_clearance_mm=70;
    near(inspect(two,equality).regions[0].usable_area_mm2,10000,"Exact minimum clearance is accepted");
}
void coincident_divider_and_crossing_occupancy() {
    Mesh touching; box(touching,0,0,0,100,100,20); box(touching,25,0,20,50,100,200);
    const auto touching_result=inspect(touching); const auto& shelf=at_height(touching_result,20);
    near(shelf.minimum_clearance_mm,0,"A downward divider bottom coincident with support blocks clearance");
    near(shelf.usable_area_mm2,7500,"Divider footprint is blocked while both shelf sides remain usable");
    for (const auto& cell:shelf.cells) {
        if (cell.center.x>25 && cell.center.x<50) check(!cell.usable && cell.clearance_mm==0,"Inside touching divider cannot be reported free");
        else check(cell.usable && std::isinf(cell.clearance_mm),"Clear sides of shelf remain open above");
    }
    near(at_height(touching_result,200).usable_area_mm2,2500,"Divider's own top remains usable");
    Settings zero_minimum; zero_minimum.minimum_clearance_mm=0;
    const auto zero_result=inspect(touching,zero_minimum); const auto& zero_shelf=at_height(zero_result,20);
    near(zero_shelf.usable_area_mm2,7500,"Zero minimum clearance must not make occupied divider cells usable");
    for (const auto& cell:zero_shelf.cells)
        if (cell.clearance_mm==0) check(!cell.usable,"Occupied zero-clearance cells are always unusable");
    Mesh overlap; box(overlap,0,0,0,100,100,20); box(overlap,25,0,10,50,100,200);
    const auto overlap_result=inspect(overlap);
    near(at_height(overlap_result,20).usable_area_mm2,7500,"Distinct-height oriented crossings block an interpenetrating panel");
    near(at_height(overlap_result,20).minimum_clearance_mm,0,"A support point inside a closed panel has zero clearance");
    Mesh open; plane(open,0,0,100,100,20); plane(open,0,0,100,100,200);
    Settings settings; settings.minimum_clearance_mm=100;
    const auto open_result=inspect(open,settings);
    near(at_height(open_result,20).minimum_clearance_mm,180,"An upward overhead sheet is clearance, not evidence of occupied solid");
    near(at_height(open_result,20).usable_area_mm2,10000,"Open sheets remain supported without invented solid volume");
    Mesh open_touch; plane(open_touch,0,0,100,100,20); box(open_touch,25,0,20,50,100,200);
    const auto open_touch_result=inspect(open_touch);
    near(at_height(open_touch_result,20).usable_area_mm2,7500,"Coincident downward blocker also protects an open support sheet");
}
void invalid_and_degenerate() {
    rejects([]{ inspect(Mesh{}); });
    Mesh mesh; plane(mesh,0,0,100,100,0);
    auto invalid=mesh; invalid.triangles[0].vertices[0]=1000;
    rejects([&]{inspect(invalid);});
    invalid=mesh; invalid.vertices[0].x=std::numeric_limits<double>::quiet_NaN();
    rejects([&]{inspect(invalid);});
    invalid=mesh; invalid.vertices[0].z=std::numeric_limits<double>::infinity();
    rejects([&]{inspect(invalid);});
    invalid=mesh; invalid.vertices[0].x=1000000001.0;
    rejects([&]{inspect(invalid);});
    mesh.triangles.push_back({{0,0,1}});
    const auto result=inspect(mesh);
    check(result.degenerate_triangles==1 && result.sampled_cells==16,"Degenerate faces are counted and ignored");
    Mesh degenerate; degenerate.vertices={{0,0,0},{1,0,0},{2,0,0}}; degenerate.triangles={{{0,1,2}}};
    check(inspect(degenerate).degenerate_triangles==1,"All-degenerate geometry returns an empty diagnosed result");
}
void invalid_settings() {
    Mesh mesh; plane(mesh,0,0,100,100,0);
    Settings s; s.cell_size_mm=0; rejects([&]{inspect(mesh,s);});
    s={}; s.cell_size_mm=std::numeric_limits<double>::infinity(); rejects([&]{inspect(mesh,s);});
    s={}; s.minimum_clearance_mm=-1; rejects([&]{inspect(mesh,s);});
    s={}; s.maximum_slope_degrees=46; rejects([&]{inspect(mesh,s);});
    s={}; s.height_tolerance_mm=0; rejects([&]{inspect(mesh,s);});
    s={}; s.height_tolerance_mm=std::numeric_limits<double>::quiet_NaN(); rejects([&]{inspect(mesh,s);});
    s={}; s.max_triangles=0; rejects([&]{inspect(mesh,s);});
    s={}; s.max_cells=1000001; rejects([&]{inspect(mesh,s);});
    s={}; s.max_regions=4097; rejects([&]{inspect(mesh,s);});
    s={}; s.max_work=50000001; rejects([&]{inspect(mesh,s);});
}
void budget_limits() {
    Mesh mesh; plane(mesh,0,0,100,100,0);
    Settings s; s.max_cells=15; rejects([&]{inspect(mesh,s);});
    s={}; s.max_triangles=1; rejects([&]{inspect(mesh,s);});
    s={}; s.max_work=5; rejects([&]{inspect(mesh,s);});
    Mesh layers=mesh; plane(layers,0,0,100,100,200);
    s={}; s.max_cells=20; rejects([&]{inspect(layers,s);});
    Mesh split; plane(split,0,0,25,25,0); plane(split,50,0,75,25,0);
    s={}; s.max_regions=1; rejects([&]{inspect(split,s);});
    Mesh huge; plane(huge,0,0,100000000,100000000,0);
    rejects([&]{inspect(huge);});
    Mesh dense; for (int i=0;i<100;++i) plane(dense,0,0,100,100,static_cast<double>(i));
    s={}; s.max_work=1000; rejects([&]{inspect(dense,s);});
    Mesh overlaps; for (int i=0;i<8193;++i) plane(overlaps,0,0,100,100,0);
    s={}; s.cell_size_mm=100; rejects([&]{inspect(overlaps,s);});
}
void automatic_sampling() {
    const Bounds small{{-300,-200,0},{300,200,20}},large{{0,0,0},{60000,40000,5000}};
    near(automatic_cell_size(small,30),5,"Small receivers retain prop-sized sampling");
    const auto coarse=automatic_cell_size(large,30);
    check(coarse>5,"Large assemblies coarsen automatically rather than failing the default grid");
    check(std::ceil(60000/coarse)*std::ceil(40000/coarse)<=1000000/64,"Automatic sampling reserves capacity for stacked surfaces");
    near(automatic_cell_size({{0,0,0},{0,0,0}},0.01),0.1,"Tiny dimensions respect the numeric resolution floor");
    check(automatic_cell_size({{0,0,0},{1000000,1,1}},1)>1,"Elongated receivers also respect the cell budget");
    rejects([&]{automatic_cell_size(small,0);});
    rejects([&]{automatic_cell_size(small,std::numeric_limits<double>::infinity());});
    rejects([&]{automatic_cell_size(small,30,0);});
    rejects([&]{automatic_cell_size(small,30,1000001);});
    rejects([&]{automatic_cell_size({{0,0,0},{-1,1,1}},30);});
    rejects([&]{automatic_cell_size({{0,0,0},{1e20,1e20,1}},30);});
}
void translated_geometry_and_unused_vertices() {
    Mesh mesh; plane(mesh,-100,-200,0,-100,25);
    mesh.vertices.push_back({100000,100000,100000});
    const auto result=inspect(mesh);
    check(result.sampled_cells==16,"Negative and translated frames retain the known grid");
    near(result.bounds.max.x,0,"Unused vertices do not expand analysis bounds");
    near(result.bounds.min.y,-200,"Input lower Y bound");
}
}

int main() {
    const std::vector<std::pair<const char*,std::function<void()>>> tests{
        {"console_top",console_top},{"shelf_layers",shelf_layers},{"half_overhead",half_overhead},
        {"corner_overhead",corner_overhead},{"hole_and_islands",hole_and_islands},
        {"support_corner_and_height_steps",support_corner_and_height_steps},{"slopes_and_transforms",slopes_and_transforms},
        {"close_cover_and_nearest_hit",close_cover_and_nearest_hit},{"invalid_and_degenerate",invalid_and_degenerate},
        {"coincident_divider_and_crossing_occupancy",coincident_divider_and_crossing_occupancy},
        {"invalid_settings",invalid_settings},{"budget_limits",budget_limits},
        {"automatic_sampling",automatic_sampling},{"translated_geometry_and_unused_vertices",translated_geometry_and_unused_vertices}};
    std::size_t passed=0;
    for (const auto& [name,test]:tests) {
        try {test(); ++passed; std::cout << "PASS " << name << '\n';}
        catch (const std::exception& error) {std::cerr << "FAIL " << name << ": " << error.what() << '\n'; return 1;}
    }
    std::cout << passed << " geometry suites passed\n";
    return 0;
}
