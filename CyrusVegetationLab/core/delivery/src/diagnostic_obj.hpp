#pragma once
#include <cyrus_vegetation/prototype_v1.hpp>
#include <filesystem>
#include <string>

namespace cyrus::vegetation::prototype_v1::delivery_detail {
bool write_diagnostic_obj(const EvaluatedMesh& mesh, const std::filesystem::path& path, std::string& error);
}
