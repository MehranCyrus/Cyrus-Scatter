#pragma once
#ifndef CYRUS_SIGNED_LICENSE_LAB_ONLY
#error Synthetic host context and issuer must never ship
#endif
#include "cyrus/licensing/signed_license.h"
#include "lab_public_key.h"
#include <algorithm>

inline cyrus::licensing::TrustProfile signedLabTrust() {
    cyrus::licensing::IssuerKey key;
    key.id = "cyrus-ephemeral-lab-key";
    std::copy(std::begin(CyrusLabPublicXY), std::end(CyrusLabPublicXY), key.p256_xy.begin());
    return {"urn:cyrus:license-lab", "cyrus-license-lab", "cyrus-license-lab+jwt", {key}};
}
inline cyrus::licensing::HostContext signedLabHost() {
    return {"lab-account", "lab-studio", "cyrus-scatter", std::string(64, 'a'), 7};
}
