#include "cyrus_arrange/geometry.h"

#include <algorithm>
#include <array>
#include <cmath>
#include <limits>
#include <stdexcept>
#include <utility>

namespace cyrus::arrange {
double automatic_cell_size(const Bounds& bounds,double feature,std::size_t max_cells) {
    const double width=bounds.max.x-bounds.min.x,depth=bounds.max.y-bounds.min.y;
    if(!std::isfinite(width)||!std::isfinite(depth)||width<0||depth<0||!std::isfinite(feature)||feature<=0||!max_cells||max_cells>1000000)
        throw std::invalid_argument("Cannot derive sampling from invalid receiver bounds or prop size.");
    const double target=static_cast<double>(std::max<std::size_t>(1,max_cells/64));
    double cell=std::max({0.1,std::min(50.0,feature/6),std::sqrt(width*depth/target),width/target,depth/target});
    for(unsigned attempt=0;attempt<16;++attempt) {
        const double nx=std::max(1.0,std::ceil(width/cell)),ny=std::max(1.0,std::ceil(depth/cell));
        if(nx*ny<=target){if(cell>1000000)break;return cell;}
        cell*=1.25;
    }
    throw std::runtime_error("Receiver extent exceeds automatic sampling limits; check its units or choose a smaller receiving assembly.");
}
namespace {
constexpr std::size_t hard_triangles = 1000000;
constexpr std::size_t hard_cells = 1000000;
constexpr std::size_t hard_regions = 4096;
constexpr std::uint64_t hard_work = 50000000;
constexpr std::size_t hard_hits_per_ray = 16384;
constexpr double hard_coordinate_mm = 1000000000.0;
constexpr double pi = 3.14159265358979323846;

struct Budget {
    std::uint64_t limit{}, used{};
    void require(std::uint64_t amount) const {
        if (amount > limit - used)
            throw std::runtime_error("Arrange inspection work limit exceeded; increase cell size or simplify the selected geometry.");
    }
    void spend(std::uint64_t amount = 1) { require(amount); used += amount; }
};

void validate(const Settings& s) {
    if (!std::isfinite(s.cell_size_mm) || s.cell_size_mm < 0.1 || s.cell_size_mm > 1000000.0)
        throw std::invalid_argument("cell_size_mm must be finite and between 0.1 and 1000000 mm.");
    if (!std::isfinite(s.minimum_clearance_mm) || s.minimum_clearance_mm < 0.0 || s.minimum_clearance_mm > hard_coordinate_mm)
        throw std::invalid_argument("minimum_clearance_mm must be finite and between 0 and 1000000000 mm.");
    if (!std::isfinite(s.maximum_slope_degrees) || s.maximum_slope_degrees < 0.0 || s.maximum_slope_degrees > 45.0)
        throw std::invalid_argument("maximum_slope_degrees must be finite and between 0 and 45 degrees.");
    if (!std::isfinite(s.height_tolerance_mm) || s.height_tolerance_mm <= 0.0 || s.height_tolerance_mm > 1000.0)
        throw std::invalid_argument("height_tolerance_mm must be finite, positive, and at most 1000 mm.");
    if (s.max_triangles == 0 || s.max_triangles > hard_triangles || s.max_cells == 0 || s.max_cells > hard_cells ||
        s.max_regions == 0 || s.max_regions > hard_regions || s.max_work == 0 || s.max_work > hard_work)
        throw std::invalid_argument("Inspection limits must be positive and cannot exceed 1000000 triangles/cells, 4096 regions, or 50000000 work units.");
}

Vec3 subtract(const Vec3& a, const Vec3& b) { return {a.x-b.x, a.y-b.y, a.z-b.z}; }
Vec3 cross(const Vec3& a, const Vec3& b) { return {a.y*b.z-a.z*b.y, a.z*b.x-a.x*b.z, a.x*b.y-a.y*b.x}; }
double norm(const Vec3& a) { return std::hypot(a.x, a.y, a.z); }

void include(Bounds& bounds, const Vec3& p) {
    bounds.min.x = std::min(bounds.min.x, p.x); bounds.max.x = std::max(bounds.max.x, p.x);
    bounds.min.y = std::min(bounds.min.y, p.y); bounds.max.y = std::max(bounds.max.y, p.y);
    bounds.min.z = std::min(bounds.min.z, p.z); bounds.max.z = std::max(bounds.max.z, p.z);
}

struct ProjectedTriangle {
    std::uint32_t source{}, x0{}, x1{}, y0{}, y1{};
    double inverse_determinant{}, gx{}, gy{};
    bool support{};
};
struct Hit { double z{}; std::uint32_t projected{}; };
struct Crossing { double z{}; int balance{}; bool downward{}; };
struct Span { std::size_t begin{}, end{}; };
struct SupportCell {
    Cell value;
    std::size_t grid{};
    double gx{}, gy{}, minimum_z{}, maximum_z{};
};

std::size_t grid_dimension(double extent, double cell, std::size_t cap) {
    const double n = std::ceil(extent / cell);
    if (!std::isfinite(n) || n > static_cast<double>(cap))
        throw std::runtime_error("Arrange XY grid exceeds the cell limit; increase cell size or reduce selection extent.");
    return static_cast<std::size_t>(std::max(1.0, n));
}

std::uint32_t grid_index(double coordinate, double origin, double cell, std::size_t count) {
    const double index = std::floor((coordinate-origin) / cell);
    if (index <= 0.0) return 0;
    if (index >= static_cast<double>(count-1)) return static_cast<std::uint32_t>(count-1);
    return static_cast<std::uint32_t>(index);
}

bool ray_height(const Mesh& mesh, const ProjectedTriangle& projected, double x, double y, double& z) {
    const auto& triangle = mesh.triangles[projected.source];
    const auto& a = mesh.vertices[triangle.vertices[0]];
    const auto& b = mesh.vertices[triangle.vertices[1]];
    const auto& c = mesh.vertices[triangle.vertices[2]];
    const double px = x-a.x, py = y-a.y;
    const double u = (px*(c.y-a.y) - py*(c.x-a.x))*projected.inverse_determinant;
    const double v = ((b.x-a.x)*py - (b.y-a.y)*px)*projected.inverse_determinant;
    constexpr double barycentric_epsilon = 1e-10;
    if (u < -barycentric_epsilon || v < -barycentric_epsilon || u+v > 1.0+barycentric_epsilon) return false;
    z = a.z + u*(b.z-a.z) + v*(c.z-a.z);
    return true;
}
}

Result inspect(const Mesh& mesh, const Settings& settings) {
    validate(settings);
    if (mesh.vertices.empty() || mesh.triangles.empty())
        throw std::invalid_argument("Inspection requires vertices and triangle faces.");
    if (mesh.triangles.size() > settings.max_triangles)
        throw std::runtime_error("Arrange triangle limit exceeded; simplify the selected analysis geometry.");
    if (mesh.vertices.size() > hard_triangles*3)
        throw std::runtime_error("Arrange vertex limit exceeded (3000000 vertices).");

    Budget budget{settings.max_work};
    budget.require(static_cast<std::uint64_t>(mesh.vertices.size()) + 2*static_cast<std::uint64_t>(mesh.triangles.size()));
    for (const auto& vertex : mesh.vertices) {
        budget.spend();
        if (!std::isfinite(vertex.x) || !std::isfinite(vertex.y) || !std::isfinite(vertex.z) ||
            std::abs(vertex.x) > hard_coordinate_mm || std::abs(vertex.y) > hard_coordinate_mm || std::abs(vertex.z) > hard_coordinate_mm)
            throw std::invalid_argument("Vertices must be finite and within +/-1000000000 mm of the analysis origin.");
    }
    Result result;
    result.input_triangles = mesh.triangles.size();
    const double infinity = std::numeric_limits<double>::infinity();
    result.bounds = {{infinity, infinity, infinity}, {-infinity, -infinity, -infinity}};
    for (const auto& triangle : mesh.triangles) {
        budget.spend();
        for (const auto index : triangle.vertices) {
            if (index >= mesh.vertices.size()) throw std::invalid_argument("Triangle vertex index is out of range.");
            include(result.bounds, mesh.vertices[index]);
        }
    }
    const double largest_coordinate = std::max({std::abs(result.bounds.min.x), std::abs(result.bounds.min.y),
        std::abs(result.bounds.min.z), std::abs(result.bounds.max.x), std::abs(result.bounds.max.y), std::abs(result.bounds.max.z)});
    const double ray_epsilon = std::max(1e-7, largest_coordinate*64*std::numeric_limits<double>::epsilon());
    const double width = result.bounds.max.x-result.bounds.min.x;
    const double depth = result.bounds.max.y-result.bounds.min.y;
    const auto nx = grid_dimension(width, settings.cell_size_mm, settings.max_cells);
    const auto ny = grid_dimension(depth, settings.cell_size_mm, settings.max_cells);
    if (nx > settings.max_cells/ny)
        throw std::runtime_error("Arrange XY grid exceeds the cell limit; increase cell size or reduce selection extent.");
    const std::size_t grid_count = nx*ny;
    budget.require(static_cast<std::uint64_t>(grid_count));

    std::vector<ProjectedTriangle> triangles;
    triangles.reserve(mesh.triangles.size());
    std::uint64_t reference_count = 0;
    const double cosine_limit = std::cos(settings.maximum_slope_degrees*pi/180.0);
    for (std::size_t index = 0; index < mesh.triangles.size(); ++index) {
        budget.spend();
        const auto& triangle = mesh.triangles[index];
        const auto& a = mesh.vertices[triangle.vertices[0]];
        const auto& b = mesh.vertices[triangle.vertices[1]];
        const auto& c = mesh.vertices[triangle.vertices[2]];
        const auto ab = subtract(b, a), ac = subtract(c, a);
        const auto normal = cross(ab, ac);
        const double length = norm(normal);
        const double edge = std::max({norm(ab), norm(ac), norm(subtract(c, b))});
        const double area_epsilon = std::max(1e-12, edge*edge*64*std::numeric_limits<double>::epsilon());
        if (length <= area_epsilon) { ++result.degenerate_triangles; continue; }
        // A vertical triangle has no area under a vertical ray. It remains part of input bounds.
        if (std::abs(normal.z) <= area_epsilon) continue;
        ProjectedTriangle projected;
        projected.source = static_cast<std::uint32_t>(index);
        projected.x0 = grid_index(std::min({a.x,b.x,c.x}), result.bounds.min.x, settings.cell_size_mm, nx);
        projected.x1 = grid_index(std::max({a.x,b.x,c.x}), result.bounds.min.x, settings.cell_size_mm, nx);
        projected.y0 = grid_index(std::min({a.y,b.y,c.y}), result.bounds.min.y, settings.cell_size_mm, ny);
        projected.y1 = grid_index(std::max({a.y,b.y,c.y}), result.bounds.min.y, settings.cell_size_mm, ny);
        projected.inverse_determinant = 1.0/normal.z;
        projected.gx = -normal.x/normal.z; projected.gy = -normal.y/normal.z;
        // Imported level boards can contain sub-micron vertex jitter. For the
        // arrangement's zero-degree mode, admit only a complete triangle whose
        // Z range fits the default 2-micron numerical contact tolerance. Final
        // footprint support still requires the precise query's full height band.
        const double height_span = std::max({a.z,b.z,c.z})-std::min({a.z,b.z,c.z});
        projected.support = normal.z > 0.0 && (normal.z/length >= cosine_limit-1e-14 ||
            (settings.maximum_slope_degrees == 0.0 && height_span <= default_contact_tolerance_mm));
        const std::uint64_t references = (std::uint64_t(projected.x1)-projected.x0+1)*(std::uint64_t(projected.y1)-projected.y0+1);
        // Known indexing and five-ray costs are checked before allocating their storage.
        if (references > settings.max_work/7 || reference_count > settings.max_work/7-references)
            throw std::runtime_error("Arrange projected-triangle coverage exceeds the work limit; increase cell size or simplify geometry.");
        reference_count += references;
        budget.require(reference_count*7 + grid_count);
        triangles.push_back(projected);
    }
    result.warnings.emplace_back("Sampled support only: five rays per cell can miss gaps or obstacles between samples; cells do not certify object fit or exact polygon area.");
    result.warnings.emplace_back("Open/nonmanifold surfaces retain authored winding. Accessibility, closed doors, material thickness and geometry outside the captured assembly are not inferred.");
    result.warnings.emplace_back("Coincident downward faces block support. Oriented crossing checks are conservative; open/nonmanifold meshes and independent shells sharing crossing heights can leave solid occupancy ambiguous.");
    if (result.degenerate_triangles != 0)
        result.warnings.emplace_back("Skipped " + std::to_string(result.degenerate_triangles) + " degenerate triangle(s).");
    if (triangles.empty()) {
        result.warnings.emplace_back("No nonvertical projected triangles were available for support sampling.");
        result.work = budget.used;
        return result;
    }

    budget.spend(reference_count*2 + grid_count);
    std::vector<std::size_t> offsets(grid_count+1, 0);
    for (const auto& triangle : triangles)
        for (std::size_t y = triangle.y0; y <= triangle.y1; ++y)
            for (std::size_t x = triangle.x0; x <= triangle.x1; ++x) ++offsets[y*nx+x+1];
    for (std::size_t i = 1; i < offsets.size(); ++i) offsets[i] += offsets[i-1];
    auto cursors = offsets;
    std::vector<std::uint32_t> references(static_cast<std::size_t>(reference_count));
    for (std::size_t index = 0; index < triangles.size(); ++index) {
        const auto& triangle = triangles[index];
        for (std::size_t y = triangle.y0; y <= triangle.y1; ++y)
            for (std::size_t x = triangle.x0; x <= triangle.x1; ++x)
                references[cursors[y*nx+x]++] = static_cast<std::uint32_t>(index);
    }
    std::vector<std::size_t>().swap(cursors);
    std::vector<SupportCell> cells;
    std::vector<Span> cell_ranges(grid_count);
    std::array<std::vector<Hit>, 5> hits;
    std::array<std::vector<Crossing>, 5> crossings;
    const double corner_offset = settings.cell_size_mm*0.45;
    const std::array<std::pair<double,double>,5> samples{{{0,0},{-corner_offset,-corner_offset},
        {corner_offset,-corner_offset},{corner_offset,corner_offset},{-corner_offset,corner_offset}}};
    std::size_t candidate_count = 0;
    for (std::size_t grid = 0; grid < grid_count; ++grid) {
        budget.spend();
        cell_ranges[grid].begin = cells.size();
        const double x = result.bounds.min.x+(static_cast<double>(grid%nx)+0.5)*settings.cell_size_mm;
        const double y = result.bounds.min.y+(static_cast<double>(grid/nx)+0.5)*settings.cell_size_mm;
        for (auto& ray : hits) ray.clear();
        for (std::size_t ref = offsets[grid]; ref < offsets[grid+1]; ++ref) {
            budget.spend(5);
            const auto index = references[ref];
            for (std::size_t sample = 0; sample < samples.size(); ++sample) {
                double z;
                if (!ray_height(mesh, triangles[index], x+samples[sample].first, y+samples[sample].second, z)) continue;
                if (hits[sample].size() >= hard_hits_per_ray)
                    throw std::runtime_error("Arrange per-ray intersection limit exceeded (16384); simplify overlapping analysis geometry.");
                hits[sample].push_back({z,index});
            }
        }
        for (auto& ray : hits) std::sort(ray.begin(), ray.end(), [&budget](const Hit& a, const Hit& b) {
            budget.spend(); return a.z < b.z || (a.z == b.z && a.projected < b.projected);
        });
        for (std::size_t sample = 0; sample < samples.size(); ++sample) {
            auto& events = crossings[sample]; events.clear();
            const auto& ray = hits[sample];
            int balance = 0;
            for (std::size_t first = 0; first < ray.size();) {
                const double z = ray[first].z;
                bool downward = false, upward = false;
                std::size_t next = first;
                // Triangles sharing a face diagonal must not count as two solid crossings.
                // Independent coincident shells are consequently ambiguous without solid IDs.
                do {
                    budget.spend();
                    if (triangles[ray[next].projected].inverse_determinant < 0) downward = true;
                    else upward = true;
                    ++next;
                } while (next < ray.size() && ray[next].z-z <= ray_epsilon);
                balance += static_cast<int>(downward)-static_cast<int>(upward);
                events.push_back({z,balance,downward}); first = next;
            }
        }
        double previous_support = -infinity;
        for (const auto& center_hit : hits[0]) {
            budget.spend();
            const auto& plane = triangles[center_hit.projected];
            if (!plane.support || center_hit.z-previous_support <= ray_epsilon) continue;
            previous_support = center_hit.z;
            if (++candidate_count > settings.max_cells)
                throw std::runtime_error("Arrange layered support-cell limit exceeded; increase cell size or simplify the selection.");
            std::array<double,5> support_heights{};
            support_heights[0] = center_hit.z;
            bool supported = true;
            for (std::size_t sample = 1; sample < samples.size(); ++sample) {
                const double expected = center_hit.z + plane.gx*samples[sample].first + plane.gy*samples[sample].second;
                const auto& ray = hits[sample];
                auto it = std::lower_bound(ray.begin(), ray.end(), expected-settings.height_tolerance_mm,
                    [&budget](const Hit& hit, double height) { budget.spend(); return hit.z < height; });
                double closest = infinity;
                for (; it != ray.end() && it->z <= expected+settings.height_tolerance_mm; ++it) {
                    budget.spend();
                    const double distance = std::abs(it->z-expected);
                    if (triangles[it->projected].support && distance < closest) {
                        closest = distance; support_heights[sample] = it->z;
                    }
                }
                if (!std::isfinite(closest)) { supported = false; break; }
            }
            if (!supported) continue;
            double clearance = infinity;
            for (std::size_t sample = 0; sample < samples.size(); ++sample) {
                const auto& ray = hits[sample];
                const double height = support_heights[sample];
                const auto& events = crossings[sample];
                const auto coincident = std::lower_bound(events.begin(),events.end(),height-ray_epsilon,
                    [&budget](const Crossing& event,double z) {budget.spend(); return event.z < z;});
                if (coincident != events.end() && coincident->z <= height+ray_epsilon && coincident->downward) {
                    // A divider beginning on the shelf is material immediately above support,
                    // not an overhead distance equal to the divider's complete height.
                    clearance = 0.0; break;
                }
                const auto after = std::upper_bound(events.begin(),events.end(),height+ray_epsilon,
                    [&budget](double z,const Crossing& event) {budget.spend(); return z < event.z;});
                const int balance = after == events.begin() ? 0 : (after-1)->balance;
                const int final_balance = events.empty() ? 0 : events.back().balance;
                // Oriented closed shells enter at downward faces and leave at upward faces.
                // Require both a positive entry balance and remaining net exits; an isolated
                // upward overhead sheet alone must never imply occupied volume.
                if (balance > 0 && balance > final_balance) {clearance = 0.0; break;}
                const auto overhead = std::upper_bound(ray.begin(), ray.end(), height+ray_epsilon,
                    [&budget](double z, const Hit& hit) { budget.spend(); return z < hit.z; });
                if (overhead != ray.end()) clearance = std::min(clearance, std::max(0.0, overhead->z-height));
            }
            const auto [min_height,max_height] = std::minmax_element(support_heights.begin(), support_heights.end());
            cells.push_back({{{x,y,center_hit.z}, clearance, clearance > ray_epsilon && clearance+ray_epsilon >= settings.minimum_clearance_mm},
                grid,plane.gx,plane.gy,*min_height,*max_height});
        }
        cell_ranges[grid].end = cells.size();
    }
    result.sampled_cells = cells.size();
    // The ray index is no longer needed while output cells coexist with internal samples.
    std::vector<std::uint32_t>().swap(references);
    std::vector<std::size_t>().swap(offsets);
    std::vector<ProjectedTriangle>().swap(triangles);
    for (auto& ray : hits) std::vector<Hit>().swap(ray);
    for (auto& events : crossings) std::vector<Crossing>().swap(events);
    std::vector<unsigned char> visited(cells.size(), 0);
    std::vector<std::size_t> queue;
    const double half = settings.cell_size_mm*0.5;
    const double maximum_step = std::tan(settings.maximum_slope_degrees*pi/180.0)*settings.cell_size_mm + settings.height_tolerance_mm;
    for (std::size_t seed = 0; seed < cells.size(); ++seed) {
        budget.spend();
        if (visited[seed]) continue;
        if (result.regions.size() >= settings.max_regions)
            throw std::runtime_error("Arrange region limit exceeded; increase cell size or reduce disconnected geometry.");
        Region region;
        region.id = static_cast<std::uint32_t>(result.regions.size()+1);
        region.bounds = {{infinity,infinity,infinity},{-infinity,-infinity,-infinity}};
        region.minimum_clearance_mm = infinity;
        region.open_above = true;
        queue.clear(); queue.push_back(seed); visited[seed] = 1;
        for (std::size_t head = 0; head < queue.size(); ++head) {
            budget.spend();
            const auto& current = cells[queue[head]];
            region.cells.push_back(current.value);
            region.sampled_area_mm2 += settings.cell_size_mm*settings.cell_size_mm;
            if (current.value.usable) region.usable_area_mm2 += settings.cell_size_mm*settings.cell_size_mm;
            region.minimum_clearance_mm = std::min(region.minimum_clearance_mm, current.value.clearance_mm);
            region.open_above = region.open_above && std::isinf(current.value.clearance_mm);
            include(region.bounds, {current.value.center.x-half,current.value.center.y-half,current.minimum_z});
            include(region.bounds, {current.value.center.x+half,current.value.center.y+half,current.maximum_z});
            const auto column = current.grid%nx, row = current.grid/nx;
            const std::array<std::pair<bool,std::size_t>,4> neighbors{{{column>0,current.grid-(column>0 ? 1 : 0)},
                {column+1<nx,current.grid+1},{row>0,current.grid-(row>0 ? nx : 0)},{row+1<ny,current.grid+nx}}};
            for (const auto [exists,grid] : neighbors) {
                if (!exists) continue;
                const auto span = cell_ranges[grid];
                auto begin = cells.begin()+static_cast<std::ptrdiff_t>(span.begin);
                auto end = cells.begin()+static_cast<std::ptrdiff_t>(span.end);
                auto match = std::lower_bound(begin,end,current.value.center.z-maximum_step,
                    [&budget](const SupportCell& cell,double z) { budget.spend(); return cell.value.center.z < z; });
                for (; match != end && match->value.center.z <= current.value.center.z+maximum_step; ++match) {
                    budget.spend();
                    const auto next = static_cast<std::size_t>(match-cells.begin());
                    if (visited[next]) continue;
                    const double dx = match->value.center.x-current.value.center.x, dy = match->value.center.y-current.value.center.y;
                    if (std::abs(match->value.center.z-current.value.center.z-current.gx*dx-current.gy*dy) > settings.height_tolerance_mm ||
                        std::abs(current.value.center.z-match->value.center.z+match->gx*dx+match->gy*dy) > settings.height_tolerance_mm) continue;
                    visited[next] = 1; queue.push_back(next);
                }
            }
        }
        result.regions.push_back(std::move(region));
    }
    if (result.regions.empty()) result.warnings.emplace_back("No cells had qualifying upward support at all five sample positions; inspect winding or use a finer cell size.");
    result.work = budget.used;
    return result;
}
}
