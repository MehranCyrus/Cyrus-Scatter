#pragma once

// Deliberately opt-in isolated experiment. The ordinary 0.7 product does not
// acquire a development issuer or synthetic clock by including this header.
#ifdef CYRUS_NATIVE_LICENSE_EXPERIMENT
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
