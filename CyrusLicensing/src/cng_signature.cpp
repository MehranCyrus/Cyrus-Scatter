#include "cng_signature.h"
#include <windows.h>
#include <bcrypt.h>
#include <wincrypt.h>
#include <algorithm>
#include <cstring>
#include <vector>

namespace cyrus::licensing::detail {
namespace {
struct Algorithm {
    BCRYPT_ALG_HANDLE value = nullptr;
    ~Algorithm() { if (value) BCryptCloseAlgorithmProvider(value, 0); }
};
struct Hash {
    BCRYPT_HASH_HANDLE value = nullptr;
    ~Hash() { if (value) BCryptDestroyHash(value); }
};
struct Key {
    BCRYPT_KEY_HANDLE value = nullptr;
    ~Key() { if (value) BCryptDestroyKey(value); }
};
bool success(NTSTATUS status) { return status >= 0; }
}

bool decodeBase64Url(std::string_view encoded, std::string& decoded) {
    if (encoded.empty() || encoded.size() > 8192 || encoded.size() % 4 == 1) return false;
    for (const char c : encoded)
        if (!((c >= 'A' && c <= 'Z') || (c >= 'a' && c <= 'z') ||
              (c >= '0' && c <= '9') || c == '-' || c == '_')) return false;
    std::string padded(encoded);
    std::replace(padded.begin(), padded.end(), '-', '+');
    std::replace(padded.begin(), padded.end(), '_', '/');
    while (padded.size() % 4) padded += '=';
    DWORD size = 0;
    const auto flags = CRYPT_STRING_BASE64 | CRYPT_STRING_STRICT;
    if (!CryptStringToBinaryA(padded.data(), static_cast<DWORD>(padded.size()), flags,
                             nullptr, &size, nullptr, nullptr)) return false;
    decoded.resize(size);
    if (!CryptStringToBinaryA(padded.data(), static_cast<DWORD>(padded.size()), flags,
                             reinterpret_cast<BYTE*>(decoded.data()), &size, nullptr, nullptr)) return false;
    decoded.resize(size);
    // Round-trip through the OS encoder to reject nonzero pad bits and other
    // alternate encodings. Compact JWS uses unpadded base64url, not base64.
    DWORD chars = 0;
    const auto output_flags = CRYPT_STRING_BASE64 | CRYPT_STRING_NOCRLF;
    if (!CryptBinaryToStringA(reinterpret_cast<const BYTE*>(decoded.data()), size,
                             output_flags, nullptr, &chars)) return false;
    std::string canonical(chars, '\0');
    if (!CryptBinaryToStringA(reinterpret_cast<const BYTE*>(decoded.data()), size,
                             output_flags, canonical.data(), &chars)) return false;
    while (!canonical.empty() && (canonical.back() == '\0' || canonical.back() == '=')) canonical.pop_back();
    std::replace(canonical.begin(), canonical.end(), '+', '-');
    std::replace(canonical.begin(), canonical.end(), '/', '_');
    return canonical == encoded;
}

TokenError verifyES256(const IssuerKey& key, std::string_view message,
                       std::string_view signature) noexcept {
    if (signature.size() != 64 || message.size() > 8192) return TokenError::Signature;
    try {
        Algorithm sha, curve;
        if (!success(BCryptOpenAlgorithmProvider(&sha.value, BCRYPT_SHA256_ALGORITHM, nullptr, 0)) ||
            !success(BCryptOpenAlgorithmProvider(&curve.value, BCRYPT_ECDSA_P256_ALGORITHM, nullptr, 0)))
            return TokenError::CryptoFailure;
        DWORD object_size = 0, written = 0;
        if (!success(BCryptGetProperty(sha.value, BCRYPT_OBJECT_LENGTH,
                reinterpret_cast<PUCHAR>(&object_size), sizeof(object_size), &written, 0)) ||
            object_size == 0 || object_size > 1048576) return TokenError::CryptoFailure;
        std::vector<unsigned char> object(object_size);
        Hash hash;
        std::array<unsigned char, 32> digest{};
        if (!success(BCryptCreateHash(sha.value, &hash.value, object.data(), object_size, nullptr, 0, 0)) ||
            !success(BCryptHashData(hash.value, reinterpret_cast<PUCHAR>(const_cast<char*>(message.data())),
                                   static_cast<ULONG>(message.size()), 0)) ||
            !success(BCryptFinishHash(hash.value, digest.data(), static_cast<ULONG>(digest.size()), 0)))
            return TokenError::CryptoFailure;
        const BCRYPT_ECCKEY_BLOB header{BCRYPT_ECDSA_PUBLIC_P256_MAGIC, 32};
        std::array<unsigned char, sizeof(header) + 64> blob{};
        std::memcpy(blob.data(), &header, sizeof(header));
        std::memcpy(blob.data() + sizeof(header), key.p256_xy.data(), key.p256_xy.size());
        Key imported;
        if (!success(BCryptImportKeyPair(curve.value, nullptr, BCRYPT_ECCPUBLIC_BLOB, &imported.value,
                                        blob.data(), static_cast<ULONG>(blob.size()), 0)))
            return TokenError::CryptoFailure;
        const auto status = BCryptVerifySignature(imported.value, nullptr, digest.data(),
            static_cast<ULONG>(digest.size()), reinterpret_cast<PUCHAR>(const_cast<char*>(signature.data())),
            static_cast<ULONG>(signature.size()), 0);
        return success(status) ? TokenError::None : TokenError::Signature;
    } catch (...) {
        return TokenError::CryptoFailure;
    }
}
}
