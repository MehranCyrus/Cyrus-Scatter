#include "cyrus/licensing/signed_license.h"
#include "cng_signature.h"
#include <nlohmann/json.hpp>
#include <algorithm>
#include <limits>
#include <set>
#include <utility>

namespace cyrus::licensing {
namespace {
using Json = nlohmann::json;
struct InvalidJson {};
Json parseStrict(const std::string& bytes) {
    if (bytes.size() >= 3 && static_cast<unsigned char>(bytes[0]) == 0xef &&
        static_cast<unsigned char>(bytes[1]) == 0xbb && static_cast<unsigned char>(bytes[2]) == 0xbf)
        throw InvalidJson{};
    std::vector<std::set<std::string>> objects;
    const auto callback = [&](int depth, Json::parse_event_t event, Json& parsed) {
        if (depth > 4) throw InvalidJson{};
        if (event == Json::parse_event_t::object_start) objects.emplace_back();
        else if (event == Json::parse_event_t::object_end) objects.pop_back();
        else if (event == Json::parse_event_t::key) {
            if (objects.empty() || !objects.back().insert(parsed.get<std::string>()).second)
                throw InvalidJson{};
        }
        return true;
    };
    return Json::parse(bytes.begin(), bytes.end(), callback, true, false);
}
bool keysAre(const Json& object, std::initializer_list<const char*> names) {
    if (!object.is_object() || object.size() != names.size()) return false;
    return std::all_of(names.begin(), names.end(), [&](const char* name) { return object.contains(name); });
}
bool textIs(const Json& value, std::string_view expected) {
    return value.is_string() && value.get_ref<const std::string&>() == expected;
}
bool boundedInteger(const Json& value, std::int64_t maximum, std::int64_t& result) {
    if (!value.is_number_integer()) return false;
    if (value.is_number_unsigned()) {
        const auto number = value.get<std::uint64_t>();
        if (number > static_cast<std::uint64_t>(maximum)) return false;
        result = static_cast<std::int64_t>(number);
    } else {
        result = value.get<std::int64_t>();
        if (result < 0 || result > maximum) return false;
    }
    return true;
}
bool identifier(const Json& value) {
    if (!value.is_string()) return false;
    const auto& text = value.get_ref<const std::string&>();
    if (text.empty() || text.size() > 64) return false;
    return std::all_of(text.begin(), text.end(), [](char c) {
        return (c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z') ||
               (c >= '0' && c <= '9') || c == '-' || c == '_';
    });
}
bool hex(char c) { return (c >= '0' && c <= '9') || (c >= 'a' && c <= 'f'); }
bool deviceId(const Json& value) {
    if (!value.is_string()) return false;
    const auto& text = value.get_ref<const std::string&>();
    return text.size() == 64 && std::all_of(text.begin(), text.end(), hex);
}
bool grantId(const Json& value) {
    if (!value.is_string()) return false;
    const auto& text = value.get_ref<const std::string&>();
    if (text.size() != 36 || text == "00000000-0000-0000-0000-000000000000") return false;
    for (std::size_t i = 0; i < text.size(); ++i) {
        const bool dash = i == 8 || i == 13 || i == 18 || i == 23;
        if (dash ? text[i] != '-' : !hex(text[i])) return false;
    }
    return true;
}
}

namespace {
struct Envelope { TokenError error; Json claims; };
Envelope verifyEnvelope(std::string_view token, const TrustProfile& trust) noexcept {
    if (token.empty() || token.size() > 8192) return {TokenError::Size, {}};
    const auto first = token.find('.');
    const auto second = first == token.npos ? token.npos : token.find('.', first + 1);
    if (first == token.npos || second == token.npos || token.find('.', second + 1) != token.npos)
        return {TokenError::Encoding, {}};
    try {
        std::string header_bytes, claims_bytes, signature;
        if (!detail::decodeBase64Url(token.substr(0, first), header_bytes) ||
            !detail::decodeBase64Url(token.substr(first + 1, second - first - 1), claims_bytes) ||
            !detail::decodeBase64Url(token.substr(second + 1), signature)) return {TokenError::Encoding, {}};
        if (header_bytes.size() > 1024 || claims_bytes.size() > 4096) return {TokenError::Size, {}};
        if (signature.size() != 64) return {TokenError::Signature, {}};
        Json header;
        try { header = parseStrict(header_bytes); } catch (...) { return {TokenError::Json, {}}; }
        if (!keysAre(header, {"alg", "typ", "kid"}) || !textIs(header["alg"], "ES256") ||
            !textIs(header["typ"], trust.token_type) || !identifier(header["kid"]))
            return {TokenError::Header, {}};
        // No jku/jwk/x5u, key files, remote lookup, algorithm negotiation or
        // token-controlled trust roots. Ambiguous configured key IDs also fail.
        const IssuerKey* selected = nullptr;
        for (const auto& key : trust.keys) if (textIs(header["kid"], key.id)) {
            if (selected) return {TokenError::UntrustedKey, {}};
            selected = &key;
        }
        if (!selected) return {TokenError::UntrustedKey, {}};
        const auto signature_error = detail::verifyES256(*selected, token.substr(0, second), signature);
        if (signature_error != TokenError::None) return {signature_error, {}};
        Json claims;
        try { claims = parseStrict(claims_bytes); } catch (...) { return {TokenError::Json, {}}; }
        return {TokenError::None,std::move(claims)};
    } catch (...) { return {TokenError::Json,{}}; }
}
}

Verification verifyLicense(std::string_view token, const TrustProfile& trust) noexcept {
    auto envelope=verifyEnvelope(token,trust);
    if(envelope.error!=TokenError::None)return {envelope.error,{}};
    try {
        const auto& claims=envelope.claims;
        std::int64_t version = 0, start = 0, end = 0, build = 0;
        if (!keysAre(claims, {"v", "iss", "aud", "jti", "sub", "tenant", "product", "device",
                              "nbf", "exp", "build_max", "rights", "mode"}) ||
            !boundedInteger(claims["v"], 1, version) || version != 1 ||
            !textIs(claims["iss"], trust.issuer) || !textIs(claims["aud"], trust.audience) ||
            !textIs(claims["mode"], "assigned_device") || !grantId(claims["jti"]) ||
            !identifier(claims["sub"]) || !identifier(claims["tenant"]) || !deviceId(claims["device"]) ||
            !(textIs(claims["product"], "cyrus-scatter") || textIs(claims["product"], "cyrus-analyzer")) ||
            !claims["rights"].is_array() || claims["rights"].size() != 1 ||
            !textIs(claims["rights"][0], "author") ||
            !boundedInteger(claims["nbf"], 253402300799LL, start) ||
            !boundedInteger(claims["exp"], 253402300799LL, end) || end <= start ||
            !boundedInteger(claims["build_max"], std::numeric_limits<std::uint32_t>::max(), build) || build == 0)
            return {TokenError::Claims, {}};
        return {TokenError::None, LicenseClaims{claims["jti"].get<std::string>(),
            claims["sub"].get<std::string>(), claims["tenant"].get<std::string>(),
            claims["product"].get<std::string>(), claims["device"].get<std::string>(),
            start, end, static_cast<std::uint32_t>(build)}};
    } catch (...) {
        return {TokenError::Json, {}};
    }
}

ActivationVerification verifyActivation(std::string_view token, const TrustProfile& trust,
    std::string_view nonce, std::string_view device) noexcept {
    if(nonce.size()!=64||device.size()!=64||!std::all_of(nonce.begin(),nonce.end(),hex)||!std::all_of(device.begin(),device.end(),hex))
        return {TokenError::Scope,0,{}};
    auto envelope=verifyEnvelope(token,trust);
    if(envelope.error!=TokenError::None)return {envelope.error,0,{}};
    try {
        const auto& c=envelope.claims;std::int64_t version=0,utc=0;
        if(!keysAre(c,{"v","iss","aud","nonce","device","server_utc","license"})||
            !boundedInteger(c["v"],1,version)||version!=1||!textIs(c["iss"],trust.issuer)||!textIs(c["aud"],trust.audience)||
            !textIs(c["nonce"],nonce)||!textIs(c["device"],device)||!boundedInteger(c["server_utc"],253402300799LL,utc)||utc==0||
            !c["license"].is_string()||c["license"].get_ref<const std::string&>().size()>8192)
            return {TokenError::Claims,0,{}};
        return {TokenError::None,utc,c["license"].get<std::string>()};
    } catch(...) { return {TokenError::Json,0,{}}; }
}

LicenseSession::LicenseSession(TrustProfile trust, HostContext host)
    : trust_(std::move(trust)), host_(std::move(host)) {}

TokenError LicenseSession::install(std::string_view token) noexcept {
    auto result = verifyLicense(token, trust_);
    if (result.error != TokenError::None) return result.error;
    if (!result.claims) return TokenError::Claims;
    const auto& claims = *result.claims;
    if (claims.subject != host_.subject || claims.tenant != host_.tenant || claims.product != host_.product)
        return TokenError::Scope;
    if (claims.device != host_.device) return TokenError::Device;
    if (host_.build_serial == 0 || host_.build_serial > claims.maximum_build) return TokenError::Build;
    // Admission is complete before replacing the current verified candidate.
    // An invalid renewal/import must not erase a still-valid installed grant.
    try {
        std::shared_ptr<const LicenseClaims> next =
            std::make_shared<const LicenseClaims>(std::move(*result.claims));
        current_.store(std::move(next), std::memory_order_release);
    } catch (...) {
        return TokenError::CryptoFailure;
    }
    return TokenError::None;
}

Decision LicenseSession::decide(Operation operation, ClockObservation clock, StateEvidence state) const noexcept {
    AuthorityFacts facts;
    const auto current = snapshot();
    if (current) {
        facts = {Authority::Verified,
                 current->product == "cyrus-scatter" ? ScatterAuthorRight : AnalyzerAuthorRight,
                 true, true, true, current->not_before, current->expires};
        // The fixed profile represents an issuer's assigned-device grant.
        // This trusts that assertion; it does not implement seat accounting.
    }
    return cyrus::licensing::decide(operation, facts, clock, state);
}

std::shared_ptr<const LicenseClaims> LicenseSession::snapshot() const noexcept {
    return current_.load(std::memory_order_acquire);
}

const char* tokenErrorName(TokenError error) noexcept {
    switch (error) {
    case TokenError::None: return "verified";
    case TokenError::Size: return "size";
    case TokenError::Encoding: return "encoding";
    case TokenError::Json: return "json";
    case TokenError::Header: return "header";
    case TokenError::UntrustedKey: return "untrusted_key";
    case TokenError::Signature: return "signature";
    case TokenError::CryptoFailure: return "crypto_failure";
    case TokenError::Claims: return "claims";
    case TokenError::Scope: return "scope";
    case TokenError::Device: return "device";
    case TokenError::Build: return "build";
    }
    return "unknown";
}
}
