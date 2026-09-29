# 28 — Implementation Roadmap and Estimates

**Estimates are engineering planning ranges, not commitments.**

| Phase | Work | Estimate |
|---|---|---:|
| 0 | baseline build/tests, version cleanup, repo/security hygiene | 2–4 days |
| 1 | LicenseCore DLL, policy, Fake provider, tests | 4–7 days |
| 2 | native Scatter/CS Edit/Analyzer gates | 3–5 days |
| 3 | generated licensing UI + diagnostics | 2–4 days |
| 4 | Cryptlex POC | 3–5 days |
| 5 | Keygen POC + comparison | 3–5 days |
| 6 | commerce provisioning/webhooks | 3–6 days |
| 7 | render-worker/runtime-context hardening | 4–8 days |
| 8 | offline/floating studio workflows | 3–6 days |
| 9 | signing/CI/package + Max 2027 | 4–8 days |
| 10 | integration/farm/beta fixes | 5–10 days |

A disciplined first commercial release is roughly **6–10 experienced developer-weeks** if runtime surprises are moderate. Enterprise on-prem floating, multiple render managers, and broader Max-version support can push beyond that.

## Critical path

Baseline → version metadata → LicenseCore/Fake → native gates → render context → provider POC → provider choice → commerce → signing/package → beta.

## Rollback points

After every phase, product should still build with Fake/offline development mode and should not require irreversible scene changes.
