# Candidate signed-license profile v1 — laboratory only

**2026-10-04.** Implemented by the optional [signed-license component](../../CyrusLicensing/include/cyrus/licensing/signed_license.h). This is an experiment profile, not a production issuer, stable public protocol, final license contract or completed L1 milestone.

**October 5 extension:** [The native/local foundation](NATIVE_FOUNDATION_2026-10-05.md) adds a separate activation response, using the same bounded JWS framing and pinned key selection but a distinct `.activation` token type. Its closed payload is `v`, `iss`, `aud`, `nonce`, `device`, `server_utc`, `license`; `nonce` and `device` are 64 lowercase hexadecimal characters. The response must match the pending protected nonce and real installation identity. The embedded license is independently verified against the license profile/account/product/build. Activation consumes the nonce atomically and rejects a server time over two seconds ahead or more than 120 seconds behind the host. These are development freshness/tolerance values, not commercial subscription durations or an implemented general clock-recovery service. License `nbf` alone never establishes current time. Earlier synthetic device/time limitations below describe the October 4 fixture; the current report separates real installation proof from remaining rollback/attestation limits.

## Wire and trust rules

Use compact JWS: `BASE64URL(protected-header).BASE64URL(payload).BASE64URL(signature)`. The exact received header/payload segments are signed; the verifier does not reserialize JSON before checking the signature. JWS framing follows [RFC 7515](https://www.rfc-editor.org/rfc/rfc7515). ES256 is P-256 with SHA-256 and a 64-byte `R || S` signature as specified by [RFC 7518](https://www.rfc-editor.org/rfc/rfc7518#section-3.4).

The native verifier accepts only unpadded, canonical base64url. OS decode/encode round-trip rejects alternate encodings and nonzero padding bits. Exactly three nonempty segments are required. Limits are 8,192 total token bytes, 1,024 decoded header bytes, 4,096 decoded payload bytes and 64 signature bytes. JSON must be valid UTF-8 without BOM, comments or trailing documents. Duplicate members, including escaped duplicate names, are rejected. Parser depth is capped at four.

The protected header must contain exactly `alg`, `typ` and `kid`. The only algorithm is `ES256`; there is no `none`/HMAC/algorithm fallback. For the laboratory, `typ` is `cyrus-license-lab+jwt`. `kid` selects a unique key from a caller-supplied **trusted application profile**, never from the token, a path, an environment variable or a URL. `jwk`, `jku`, `x5u`, `crit`, `b64` and every extra header member are rejected in this profile. There is no network key lookup.

`TrustProfile` is an integration boundary, not a customer configuration format. The final native application must own its issuer/type/audience and trusted public keys. The reusable verifier library contains no issuer key; only the explicitly enabled lab/test targets compile the generated ephemeral public key. A profile with no keys rejects the lab token. This does not yet qualify the final product's key distribution, rotation or binary packaging.

## Required claims

All members below are required; extra members are rejected for this prototype. Unknown critical semantics must never become an implicit unlock. New algorithms using the existing product authoring permission do not need new token fields.

| Member | Profile constraint |
| --- | --- |
| `v` | Integer `1`, not a boolean, string or floating-point number |
| `iss`, `aud` | Exact scalar strings matching the trusted profile; lab values are `urn:cyrus:license-lab` and `cyrus-license-lab` |
| `jti` | Nonzero canonical lowercase UUID-shaped grant identifier; issuer remains responsible for uniqueness/accounting |
| `sub`, `tenant` | Nonempty ASCII identifiers, at most 64 characters using letters, digits, `_` or `-` |
| `product` | `cyrus-scatter` or `cyrus-analyzer`; must match the installed session's application context |
| `device` | 64 lowercase hexadecimal characters; matched against host context. The lab uses a synthetic value, **not actual hardware or device-key proof**. |
| `nbf`, `exp` | Nonnegative integer UTC seconds, at most `253402300799`, with `exp > nbf`; no fractional/string/boolean coercion |
| `build_max` | Integer 1 through `4294967295`; checked against a native context's positive build serial. Serial 7 is a lab value, not the actual product's release eligibility policy. |
| `rights` | Exactly `["author"]` for the selected product |
| `mode` | Exactly `assigned_device`; no floating, checkout or borrowing semantics implied |

A correctly signed assigned-device grant expresses the issuer's reservation assertion. The client cannot independently prove that the issuer's database allocated seats correctly. No such database exists in this experiment; E06–E10 remain open.

## Admission and continued operation

`LicenseSession::install()` checks signature/profile first, then account, tenant, product, device-context match and build eligibility. Failure does not replace a previously admitted grant. A cryptographically valid but expired or future-dated grant can be installed as data; `decide()` separately reports expired/not-yet-valid and denies authoring. Import success is therefore called **verified**, not automatically “active.”

Expiry uses the policy core's half-open interval `[nbf, exp)`. Renewal supplies a newly signed grant and then reevaluates policy. Reimporting an old grant does not restart its term. Anti-rollback selection among several authentic grants, trusted calendar observation, storage recovery and operation lifetime are separate unfinished work. The laboratory passes synthetic time explicitly; it does not claim an unforgeable offline clock.

The session verifies on import and holds the resulting claims in memory. Ordinary decisions do not reread the file or repeat signature verification. The class assumes one owner/thread for install/decision calls; multi-thread/process publication and persistence are not implemented. No production viewport callback was modified or benchmarked here.

ES256 may have two mathematically valid signature encodings for the same message. Tests accept the standard equivalent `s`/`n-s` signatures. Future issuance/idempotency accounting must use the signed grant identity, not raw signature bytes as a unique seat identifier.

## Render and device limitations

`RenderExisting` still requires separate approved-scene evidence. The lab passes synthetic evidence; a signed authoring token does not prove that a loaded `.max` scene was authored legitimately. The [native ownership gap](OPERATION_CONTRACT.md) is unchanged.

Copy rejection currently tests a mismatch against a synthetic device identifier. Real device-key generation, protected storage, possession checks, machine recovery, multi-process sharing and D13 transfer accounting are not implemented. IP addresses and bare Windows UUIDs are not promoted to sufficient authority by this profile.

The MAXScript lab bridge is a test transport, not the production file importer or activation UI. Do not distribute it. The future importer needs bounded raw-byte input, safe persistence and recovery; account/device context must not be caller-supplied script data.
