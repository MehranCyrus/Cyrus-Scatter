# Licensing experiments — never ship

This lab exercises the [licensing foundation](../../CyrusLicensing/README.md) against disposable Max scenes. The historical L0/signed fixtures below use script-controlled scenario/time inputs. The newer real-installation fixture uses CNG, DPAPI and actual UTC/monotonic time and does not register a fake-clock primitive. Neither is customer licensing authority.

Ordinary product targets keep all development authority off. `CYRUS_NATIVE_LICENSE_EXPERIMENT=ON` explicitly adds the private native adapter; `CYRUS_LICENSE_INSTALLATION_CONTEXT=ON` selects real installation context with its exact generated public key and private path. Standalone lab bridges require `CYRUS_BUILD_LICENSING_LAB=ON`. Never put a lab DLL or native experiment pair in an artist/customer plugin directory. Packaging rejects development markers; no customer signer secret is embedded.

## Current native/local campaigns

Use a fresh lowercase run name for every campaign. These commands freeze dirty and untracked source before building; tests must use that exact script/native/issuer pair.

```powershell
python tools/licensing_lab/run_core.py --run example01
python tools/licensing_lab/run_local_client.py --run example01
python tools/licensing_lab/run_installation.py --run example01
```

They require the compiler/SDK/Python prerequisites below and the pinned development issuer environment. `run_core.py` runs the expanded signature/policy/local suites and permit microbenchmarks for both SDK configurations. `run_local_client.py` verifies real activation, two long-lived CLI processes, device-copy denial, concurrent transactions and decision isolation from real disk contention. `run_installation.py` builds a matching Max 2027 recipe/Edit/Brush candidate, activates with a short test-only term, expires during a pending Brush gesture, reopens and renders without output caches, renews in a second Max process, and checks background refresh/checkpoint plus clean worker shutdown. A 60-second local maintenance interval is not a mandatory network refresh or a shorter offline license deadline.

The Max fixture compares every transform component/source/Edit ID, persisted Brush history and rendered images. Its image gate allows at most two 128×128 pixels to vary by one channel level, recording actual differences; earlier strict-equality failures remain preserved. The development panel's functions are exercised, not advertised as a complete customer login UI. Full product recipe ownership, Analyzer/PFlow/bake licensing, customer authentication, seat accounting, recovery, signer rotation and worker/renderer deployment remain outside the qualified slice. Read [the October 5 report](../../docs/licensing/NATIVE_FOUNDATION_2026-10-05.md) before interpreting pass counts.

## Reproduce the synthetic L0 experiment

From the repository root:

```powershell
python tools/licensing_lab/run.py --run example01
```

Requirements: pinned MSVC 14.38.33130 and Windows SDK 10.0.19041.0 as used by `tools/build_max.py`, CMake/CTest on PATH, Python with Pillow and psutil, unpacked Max 2026/2027 SDKs under `build/tooling`, and installed Max 2027 with an existing user INI. The run does not install plugins or replace the live artist scene.

Each run writes to a new `build/licensing-l0-2026-10-04/<run>/` directory, excluded from Git. It records a source snapshot and hashes, builds both SDK lab variants and standalone policy tests, builds the current product native modules for Max 2027, and starts two disposable batch processes using isolated script/startup/plugin configuration paths. The fixture records loaded modules; the runner verifies their exact paths and SHA-256 values.

The first process creates and saves the scene. The second opens it in a fresh process, discards the preview cache, checks retained identity/edit state, renders, and exercises synthetic renewal. Active and expired 128×128 Scanline images must match exactly. Changing the source geometry is a separate counterexample: the render must change even when placement positions do not.

For a script-only repair, an existing build can be reused explicitly:

```powershell
python tools/licensing_lab/run.py --run example02 --reuse-binaries-from example01
```

The runner rejects reuse when recorded native/build inputs differ or binary hashes do not match. Reuse is recorded; earlier build/test results are not relabeled as fresh builds. Failed runs remain available for diagnosis.

## Read the L0 results correctly

- `checks.tsv` distinguishes assertions (`PASS`), counterexamples (`OBSERVED`) and fixture failure (`FAIL`). `COMPLETE` alone does not establish licensing security.
- `result.json` is written only after both host processes, module identities and image comparisons pass.
- Public product calls still execute without commercial authorization. The fixture positively demonstrates direct Brush, generator and parameter-change bypasses of its optional wrappers.
- A fixture placement fingerprint is a diagnostic, not a cryptographic scene signature or entitlement proof. It covers positions/source indices, not complete evaluated geometry.
- This experiment does not install enforcement, contact an issuer, verify a signed token, measure viewport overhead, simulate real wall-clock rollback, test renderer workers, or qualify Max 2026 runtime.

See the [operation contract](../../docs/licensing/OPERATION_CONTRACT.md) for integration scope and the remaining native ownership problem.

## Signed-license experiment

This second experiment adds actual CNG signature verification and a strict signed-message profile. It reuses the same disposable product fixture; **device identity, time confidence and scene provenance remain synthetic**. It neither requires nor deploys a server.

Create the separate development issuer environment with Windows x64 Python 3.10. The wheel lock is specific to that tested environment; update and retest it deliberately for another interpreter/platform.

```powershell
python -m venv build/licensing-l1-tools-2026-10-04
build/licensing-l1-tools-2026-10-04/Scripts/python.exe -m pip install --require-hashes --only-binary=:all: -r tools/licensing_lab/requirements-signer.txt
python tools/licensing_lab/run_signed.py --run example01
```

The signed runner also requires the L0 runner's MSVC/SDK/Max/Python prerequisites above. By default it reuses the passed L0 `run04` source, product binaries and disposable scene from the same machine. To use another passed L0 run, supply `--baseline` with its absolute directory. It validates recorded product source and binary hashes before reuse. A clean checkout without those ignored artifacts must first generate a fresh L0 baseline. Original October 4 runtime evidence uses the recorded frozen baseline, not any later product edits.

Each signed run writes a new `build/licensing-l1-2026-10-04/<run>/` directory. It snapshots current licensing/lab code with the frozen baseline's product sources. This keeps concurrent product development out of the experiment; compatibility with that newer work is a separate test. The runner generates an ephemeral P-256 issuer in memory, writes public-key metadata and signed test vectors, builds the lab for SDK 2026/2027, runs twelve test groups per SDK, and starts fresh Max 2027 create/reopen batch processes. Direct file logs retain build diagnostics on timeout.

The generated private key is never written. Public fixture keys and their signed fake-account tokens are laboratory data, not customer authority. Do not regenerate fixtures while reusing an old signed binary: that binary trusts the previous public key. The normal runner rebuilds them together. Generating reusable customer licenses, persistent issuer-key storage, activation UI and server account/seat handling are outside this tool.

The fixture exercises valid and tampered imports, rejected replacement preserving the existing grant, exact synthetic expiry, real CS Edit mutations through wrappers, save/reopen/render continuity and a newly signed renewal. Three 128×128 Scanline renders must have identical pixels. A direct generation call deliberately still succeeds outside the wrapper and records the native enforcement gap. Build/load hashes establish what ran, not production security.

The optional signed target requires `CYRUS_BUILD_SIGNED_LICENSE_LAB=ON` and generated `CYRUS_SIGNED_FIXTURES`; lab source also requires `CYRUS_SIGNED_LICENSE_LAB_ONLY`. Product builds do not select these switches. The final production package still needs independent test-key exclusion and signing qualification.

See the [component choices](../../docs/licensing/IMPLEMENTATION_COMPONENTS.md) and [candidate profile](../../docs/licensing/SIGNED_TOKEN_PROFILE.md). Max 2026 runtime, real device binding, calendar rollback/recovery, all renderers, native entry-point enforcement and licensing performance are not qualified by this experiment.
