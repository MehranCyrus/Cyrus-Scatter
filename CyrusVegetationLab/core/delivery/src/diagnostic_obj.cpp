#include "diagnostic_obj.hpp"

#include <fstream>
#include <iomanip>
#include <limits>

namespace cyrus::vegetation::prototype_v1::delivery_detail {

bool write_diagnostic_obj(const EvaluatedMesh& mesh, const std::filesystem::path& path, std::string& error) {
    std::ofstream out(path, std::ios::binary | std::ios::trunc);
    if (!out) { error = "Could not open diagnostic OBJ output."; return false; }
    out << std::setprecision(17);
    out << "# Cyrus vegetation delivery diagnostic only; not renderer/Bake qualification\n";
    for (const Vec3 p : mesh.positions) out << "v " << p.x << ' ' << p.y << ' ' << p.z << '\n';
    for (const UV uv : mesh.uvs) out << "vt " << uv.u << ' ' << uv.v << '\n';
    for (const Vec3 n : mesh.normals) out << "vn " << n.x << ' ' << n.y << ' ' << n.z << '\n';
    std::uint32_t active_material = std::numeric_limits<std::uint32_t>::max();
    for (std::size_t i = 0; i < mesh.triangles.size(); ++i) {
        if (mesh.face_material_ids[i] != active_material) {
            active_material = mesh.face_material_ids[i];
            out << "usemtl material_" << active_material << '\n';
        }
        const auto tri = mesh.triangles[i];
        out << "f";
        for (std::uint32_t idx : tri) {
            const std::uint64_t one = static_cast<std::uint64_t>(idx) + 1U;
            out << ' ' << one << '/' << one << '/' << one;
        }
        out << '\n';
    }
    if (!out) { error = "Failed while writing diagnostic OBJ output."; return false; }
    return true;
}

} // namespace cyrus::vegetation::prototype_v1::delivery_detail
