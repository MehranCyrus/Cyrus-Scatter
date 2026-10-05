# Reuse standard components; own Cyrus policy

**2026-10-04.** The user approved an isolated prototype before product integration. The recommendation is to implement Cyrus's product/seat/continuity rules ourselves and reuse maintained cryptography and data-format components. Owning the licensing service does not mean writing cryptographic algorithms or a JSON parser.

## Components selected for this experiment

| Component | Role and reason | Provenance / limits |
| --- | --- | --- |
| Windows CNG | Native P-256/SHA-256 signature verification; already provided by the plugin's Windows platform | [Microsoft verification API](https://learn.microsoft.com/en-us/windows/win32/api/bcrypt/nf-bcrypt-bcryptverifysignature). Platform API, not a newly vendored open-source library. This prototype imports `bcrypt` and `crypt32`; no third-party crypto DLL is added to Max. |
| nlohmann/json **3.12.0** | JSON parsing, with our bounded profile, type checks and duplicate-member rejection layered on top | [Official release](https://github.com/nlohmann/json/releases/tag/v3.12.0). Exact unmodified single header is pinned by the publisher's SHA-256 and checked by CMake. [MIT notice retained](../../CyrusLicensing/third_party/nlohmann/LICENSE.MIT). |
| Python cryptography **50.0.2** | Development-only issuer using a separate cryptographic implementation, so native verification is checked against independently generated signatures | [Official changelog](https://cryptography.io/en/stable/changelog/) describes the 2026-09-30 release and OpenSSL 4.0.3 wheels. Installed into a separate ignored lab environment; it is not shipped with the plugin. [Wheel/hash lock](../../tools/licensing_lab/requirements-signer.txt) records the tested Windows x64 Python 3.10 dependencies. |
| Compact JWS with **ES256** | Standard signed-message framing and P-256/SHA-256 signature representation | [RFC 7515](https://www.rfc-editor.org/rfc/rfc7515), [RFC 7518 §3.4](https://www.rfc-editor.org/rfc/rfc7518#section-3.4). Cyrus defines a strict application profile; this is not a general-purpose JOSE implementation. |

The C++ client does not implement elliptic-curve arithmetic, SHA-256 or base64 conversion primitives. Windows implements those primitives; nlohmann handles JSON syntax/Unicode. Our code supplies size/format constraints, trust-key selection, application claims, context matching and the connection to the existing policy core. That code is security-sensitive and still needs review even though the primitives are reused.

The old Microsoft signing example contains SHA-1 sample code. We did not copy that algorithm choice; the candidate uses ES256's SHA-256 requirement. A vendor sample is not automatically the right complete application protocol.

## Alternatives considered

| Option | Published facts | Decision for this Windows prototype |
| --- | --- | --- |
| libsodium | Supports [Ed25519 detached signatures](https://doc.libsodium.org/public-key_cryptography/public-key_signatures), [Windows builds](https://doc.libsodium.org/installation) and a [permissive license](https://github.com/jedisct1/libsodium/blob/master/LICENSE) | Credible alternative if portability or a different signature profile justifies it. Not added alongside CNG; two production signature stacks are unnecessary for this experiment. No performance/security ranking was established. |
| jwt-cpp | [Project documentation](https://github.com/Thalhammer/jwt-cpp) lists an MIT-licensed C++ JWT library and OpenSSL/LibreSSL/wolfSSL dependencies | A candidate if a general JWT client is needed. Our current bounded Windows verifier uses CNG and a small explicit profile. We have not tested jwt-cpp or declared it unsuitable in general. |
| Whole licensing framework/server | May include account, activation or commercial assumptions beyond signature verification | No framework has been selected or evaluated exhaustively. Continue to reuse maintained authentication/database components when L2 begins; the owned-service decision does not authorize copying a provider's private implementation. |

## Dependency stewardship

The vendored header is unchanged. Its SHA-256 is `aaf127c04cb31c406e5b04a63f1ae89369fccde6d8fa7cdda1ed4f32dfc5de63`; the retained MIT text hash is `46a65cffd1ea955132d95a8dd921640714a8d6b537d2e4e482d31145ae95b603`. The notice permits the listed uses under its stated conditions; preserve its copyright and permission notice in any eventual distribution containing this code. This document is not a complete legal or dependency-security audit.

Version pinning establishes reproducibility, not permanent safety. Track upstream fixes and advisories, update deliberately, rerun parser/signature and actual host tests, and include dependency notices/SBOM in the eventual package. No broad claim that all dependencies are vulnerability-free follows from these tests.

## Adoption boundary

The [candidate token profile](SIGNED_TOKEN_PROFILE.md) and lab implement real signature verification. Device identity, time confidence and scene provenance still use laboratory assumptions. Direct product entry points remain outside the licensing boundary. Passing the verifier tests does not permit automatic promotion of the laboratory DLL or test issuer into the product.

The next product integration work remains a native owner for admitted authored state, followed by a separately configured real trust profile, protected device identity and the L1/L3 acceptance work. The active [roadmap](ROADMAP.md) remains the governing plan.
