# 0.87.6.5 — mesh hover and persistent selection

The yellow hover cue follows one displayed instance's mesh again. Clicking
selects its layer and enters the separate Cyrus Scatter Edit modifier. The
selected outline remains when the pointer leaves, hides during a transform
gesture and returns afterward. The shared render helper still cannot cause
whole-scatter preselection.

- [EXE — Max 2024, 2026 and 2027](../../../dist/CyrusScatter-0.87.6.5-20261029/CyrusScatter-0.87.6.5-Setup.exe)
- MZP: [2024](../../../dist/CyrusScatter-0.87.6.5-20261029/CyrusScatter-0.87.6.5-Max2024.mzp), [2026](../../../dist/CyrusScatter-0.87.6.5-20261029/CyrusScatter-0.87.6.5-Max2026.mzp), [2027](../../../dist/CyrusScatter-0.87.6.5-20261029/CyrusScatter-0.87.6.5-Max2027.mzp)
- [Artist guide](ARTIST_GUIDE.md), [exact qualification and hashes](QUALIFICATION.json), [implementation scope](IMPLEMENTATION.md).

## Evidence

Matching frozen run `build/mesh-selection-08765-20261029-02` passed 62 native
suites and generated-source checks. Max 2027 loaded paths, module hashes and
script fingerprint match the packaged payload.

The owned Max 2027 fixture exercised actual SDK mouse messages, correct
layer/instance selection, new/existing Edit entry with Manual changes pending,
and persistent selection after the pointer moved away. Native gesture callbacks
verified hiding while held, restoration after movement, Undo/Redo and exiting
Edit. The before/during/after screenshots were inspected. A prepared two-blade
fixture verified the posed triangle cue, warm reuse and clearing selection.

Twenty-four warm redraw submissions reused the outline cache and left placement
epoch and retained stream counters unchanged. The median CPU submission time
was 18.33 ms in this small fixture; this is not physical input latency or GPU FPS.
No interaction/placement algorithm was changed.

The EXE's three embedded MZPs, archive integrity, host guards and payload hashes
were checked. Max 2024 and 2026 were compiled with their respective SDKs and
packaged; those applications were not launched. The installer was not run in an
artist profile.

## Bounds and installation

Hover uses at most 1,024 sampled triangles. Selected outlines share a 4,096-line
budget for up to 128 selected instances. Other selected instances retain center
markers and remain editable. Warm draws reuse the cache; a changed selection or
display generation rebuilds it. Displayed box proxies retain their box outlines.
This bounds highlight work, not exact mesh picking or the number of editable
instances. Arbitrary models, renderer output and physical input latency were not
requalified in this visual patch.

Save work and close the Max versions you select in the EXE. Alternatively use
**Scripting > Run Script** with the matching MZP, then restart Max.
Existing Library content is reused. Scene 65, Interactions 16, Edit capability
4/storage 3, viewport selection 2 and recipe 9 are unchanged. The prior
0.87.6.4 delivery retains its original packages and qualification.

Current documentation sources are updated. This task did not rebuild or publish
the website or indexed knowledge. No code was pushed to Git in this task.
