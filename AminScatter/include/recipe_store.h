#pragma once
#include "recipes.h"
#include <functional>

namespace cyrus::recipes {
void validateEntryPresentation(const Json& presentation);
std::filesystem::path attachmentPath(const std::filesystem::path& manifest,const std::string& relative);
// Hash excludes library identity/name/revision/presentation, but includes all authored settings and Paint.
std::string contentFingerprint(const Json& hydrated);
// Atomic local-NTFS manifest publication. Expected hash empty means create, never overwrite.
// metadataOnly retains stored settings and immutable Paint descriptors without hydration.
// The test-only C++ callback is never exposed through the host bridge.
std::string writeEntry(const std::filesystem::path& path,const Json& document,
    const Json& metadata,const std::filesystem::path& image,const Json& capture,
    const std::string& expectedHash,bool metadataOnly=false,
    const std::function<void(const char*)>& checkpoint={});
}
