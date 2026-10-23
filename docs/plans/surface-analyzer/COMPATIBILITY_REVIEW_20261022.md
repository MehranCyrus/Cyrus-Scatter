# Surface Analyzer compatibility review — 22 October 2026

## Result and scope

The artist's **“Update the Surface Analyzer script to the matching package”**
error is reproduced with the Analyzer installed in the normal Max 2027 profile
and Scatter 0.86.8.2. The installed Analyzer script lacks `analysisCurrent()`.
The current repository Analyzer script implements it, and a fresh matching
Max 2027 native build works with the tested Scatter integrations.

This is an investigation, not a new product delivery. No Scatter or Analyzer
product source was changed, no installer was replaced, and no artist installation
or session was modified or restarted. Test drivers, builds and scenes are in the
ignored, owned `build/analyzer-review-20261022-01/` directory. Only the two
disposable Max processes were used for scripted scene mutations.

Baseline: branch `codex/workflow-0.75`, HEAD
`3d387550cacf37fe1aeae7a01455f7644d9cf08b`, Scatter 0.86.8.2 / schema 59.
Analyzer is independently labeled 0.14. Pre-existing Arrange, Physics, knowledge,
website, private-asset and planning changes were preserved.

## Cause and source evidence

Scatter's authoritative
[`requireCurrentAnalyzers`](../../../AminScatter/tools/ui/templates/unified-core.ms)
requires an enabled referenced Analyzer to expose `analysisCurrent()`. Its exact
missing-function exception matches the screenshot. The Layout panel independently
shows **Update Analyzer script** for this condition. Calling **Update Analyzer**
in that panel invokes `guide.runAnalysis()`; it recalculates guides and cannot
install missing script functions.

The current
[`Analyzer script`](../../../CyrusSurfaceAnalyzer/scripts/CyrusSurfaceAnalyzer.ms)
records pending state, input references, settings and validity intervals. Its
`analysisCurrent()` validates that saved publication against current dependencies.
This is the F12 producer/consumer boundary: Scatter consumes published guides;
it must not secretly Analyze to repair a stale dependency. Cached Scatter reads
can retain their existing result, while a successor solve validates freshness.

The normal Max 2027 profile contains an older script and native module. The
existing `dist/CyrusSurfaceAnalyzer-0.14-Max2027.mzp`, dated 1 October 2026,
contains exactly that same older script. Its archive CRC check passes; it is
an outdated payload rather than a corrupt ZIP. Reinstalling it repeats the
mismatch. A version caption of 0.14 therefore does not establish the interface.

[`tools/build_max.py`](../../../tools/build_max.py) explicitly treats Analyzer
as a separate package. Current Scatter package instructions say that its
installation does not change Analyzer. The artist can consequently update
Scatter successfully while retaining this incompatible Analyzer script.

| Artifact | SHA-256 |
| --- | --- |
| Installed / existing MZP Analyzer script | `b9a1f1aa2ba7847566eb8f36bee711f9c64753572955ed4549f2f68669e5f923` |
| Current repository Analyzer script | `716a78868a78ea01842bdfa680baa628316530ca774aea7b537c7fef3db0d7ae` |
| Installed Analyzer native module | `e2318bd967cf8b17ce1b1208e156c61a9f6361a80b8160c34c54bd2eb2a886de` |
| Fresh review Analyzer native module | `53591846865cb85b981c4f208be7167fed835111cc81a3449629425b1ca1f6fb` |
| Existing Max 2027 Analyzer MZP | `3f79019751a85974beb8b52332ba93af3f10ecdddbde282af2569d2ad931f4e9` |

## Executed checks

Built current Analyzer with:

```powershell
python tools/procedural_lab/offline_build.py --project analyzer --year 2027 --output build/analyzer-review-20261022-01/native
```

Configuration, SDK compilation and the `analyzer_core` CTest executable pass.
This is **one executable containing the existing native checks**, not 49
separately registered Analyzer tests.

Two fresh redirected Max 2027 profiles loaded the qualified Scatter native
modules from the 0.86.8.2 build. One received copies of the artist's installed
Analyzer pair; the other received the current repository script and fresh
Analyzer native build. Launch checks verify loaded module paths; source and
binary hashes are checked against build receipts. Both copied artist INI
templates retain their launch-time hashes after testing.

The installed-pair host passes five diagnostic assertions: native analysis still
produces guides; unmasked Scatter works; the required freshness API is absent;
referencing the Analyzer reproduces the exact exception; and rejection preserves
the previous complete Scatter publication and epoch.

The current-pair host passes 31 assertions across the completed scenario logs:

- Publishing boundary, center-path and sample-point data, plus a 1,000-placement
  unmasked Scatter baseline.
- Inside-border bands (290 accepted in this fixture), centerline bands,
  sample-point radius bands, Single anchors and Edge Row anchors.
- Analyzer line/point Area masks and boundary deletion falloff over native
  candidate storage.
- Unchanged cached evaluation reuses the publication without Analyze or a new
  Scatter epoch.
- Pending Analyzer parameters make guides stale. An unchanged cached Scatter
  read remains available; a changed successor recipe rejects stale guides and
  preserves the previous publication without implicit Analyze. Explicit Analyze
  followed by Scatter evaluation recovers.
- Fresh and pending freshness states survive save/reopen using saved system
  units. The published Scatter fingerprint survives the fresh round trip.
- Real-time parameter edits publish one result, the timer stops afterward,
  unrelated object edits/idle do not Analyze, and Manual edits remain pending.
- A solid input is rejected while retaining the previous boundary cache, and
  restoring the planar input recovers.

The first lifecycle attempt failed because the fixture reset changed scene
system units from centimetres to the profile's millimetres. World-unit parameters
scaled by ten while the saved string signature retained its original numeric
values. The test was corrected to preserve saved system units; it then passed.
This is not evidence of unit-rescale-stable cached guides. Keep the documented
saved-unit constraint and Analyze again after relevant unit changes.

Machine-readable identities and per-scenario log hashes:
[`review-receipt.json`](../../../build/analyzer-review-20261022-01/review-receipt.json).
The initial failed request file and diagnostic log remain beside the completed
logs; the receipt records the failed observation and its cause.

These are bounded scripted planar-fixture checks. They do not qualify physical
pickers, every UI control, high DPI, renderer output, merge, Undo/Redo, arbitrary
production scenes or long sessions. No Max 2024/2026 build or test was performed.

## Recommended repair

1. Prepare a separately identified **Max 2027 Analyzer compatibility package**
   from the current script and matching native module. Preserve the existing MZP
   as historical evidence. Do not distribute a loose script over the older DLL:
   the current script also requires `cyrusAnalyzerInputValidity`, which the old
   installed native module does not expose in the reproduced host.
2. Verify every payload hash, host guard, immutable binary folder, startup path,
   installation and restart in a disposable profile. Test the actual Layout
   picker, Select and Update Analyzer handlers, as well as Undo/Redo and merge,
   before a user-testing delivery. Choose the independent Analyzer patch version
   through the release policy; Scatter's version need not advance for a separate
   Analyzer packaging correction.
3. Align Analyzer's release identity and artist wording. Current source still
   says `Schematic v0.4` in its output rollout and `0.5` in CMake/native module
   description while maintained guidance labels it 0.14. These labels are
   confusing but are not the cause of the reproduced missing-function failure.
   Clarify that **Update Analyzer** means recompute, while **Update Analyzer
   script** requires installation of a compatible package.
4. Add a maintained integration/packaging regression for this exact stale-payload
   case, and make the separate Analyzer requirement visible alongside Scatter's
   current download/install guidance. A package version string alone is an
   inadequate compatibility check.

After installing the eventual qualified package and restarting Max, the artist
workflow is **Analyze / Update Analyzer**, then **Update scatter** in Manual
mode, with an Analyzer band/row and its model assignment configured.

The existing geometry scope remains explicit: Analyzer accepts independently
planar mesh elements, including holes and differing element orientations. It
does not analyze a continuously curved receiver like the surface Paint system.
Scatter's Analyzer area adapter evaluates paths and point-radius masks in world
XY. Fit radius, Analyzer point spacing and Scatter source clearance are distinct
settings; replacing the installer does not unify their semantics.
