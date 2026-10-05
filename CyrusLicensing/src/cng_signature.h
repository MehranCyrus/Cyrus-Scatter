#pragma once
#include "cyrus/licensing/signed_license.h"

namespace cyrus::licensing::detail {
TokenError verifyES256(const IssuerKey& key, std::string_view message,
                       std::string_view signature) noexcept;
bool decodeBase64Url(std::string_view encoded, std::string& decoded);
}
