#pragma once

// Team builds use the real local client; isolated experiments retain their
// separate authority. No development issuer or synthetic clock is implicit.
#if defined(CYRUS_NATIVE_LICENSE_EXPERIMENT) || defined(CYRUS_TEAM_LICENSE)
#include "cyrus/licensing/signed_license.h"
#ifdef CYRUS_LICENSE_BOUNDARY_IMPORT
#define CYRUS_BOUNDARY_API __declspec(dllimport)
#else
#define CYRUS_BOUNDARY_API __declspec(dllexport)
#endif
CYRUS_BOUNDARY_API cyrus::licensing::OperationPermit cyrusBoundaryBegin(const void* owner) noexcept;
CYRUS_BOUNDARY_API bool cyrusBoundaryCommit(cyrus::licensing::OperationPermit&, const void* owner) noexcept;
CYRUS_BOUNDARY_API bool cyrusBoundaryAllows(const void* owner) noexcept;
#else
inline bool cyrusBoundaryAllows(const void*) noexcept { return true; }
#endif
