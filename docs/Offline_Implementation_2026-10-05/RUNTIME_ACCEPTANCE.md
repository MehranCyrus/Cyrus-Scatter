# Next private host campaign — not run yet

The user is working in Max and explicitly prohibited computer use during this coding pass. The tests below are queued for a later authorized session. An SDK build, offline protocol test, delimiter check or a previous 0.7.1 UI receipt does not satisfy them.

## Pin the isolated host first

1. Use a disposable Max 2027 profile and copied scene. Preserve the current artist process and original scene. Do not copy binaries into the artist profile.
2. Read `evidence/verification.json` and the matching `build/offline-implementation-20261005/max2027/receipt.json`. Hash the staged DLLs and script before starting. Compare loaded module-file hashes and `CyrusLoadedScriptFingerprint` inside that process; the latter hashes the script payload without its first line.
3. The script now requires `cyrusProceduralPublicationVersion()==1`; do not hot-load it over an older native DLL. Identify unchanged dependencies, including Analyzer and Edit, as well as Scatter/Brush/BrushStorage. Existing MZPs are older snapshots and are not a matching delivery of this work.
4. Keep a build/scene/renderer/profile manifest and the original failing evidence. The loaded-file manifest is not memory attestation. No automatic production license-mode change belongs to this campaign.

## Run the prepared fixtures

- [MAXScript fixture](../../tools/procedural_lab/Max_Offline_Implementation_Acceptance.ms) is definitions-only and requires an empty scene plus the expected script fingerprint. Call `CyrusOfflineImplementationFixture "<payload sha256>"` explicitly. It checks cached page counts/identities/transforms/radii, Manual pending values, stale handles, failed-successor retention, direct notification classification and source parking/reentry.
- [Python adapter fixture](../../tools/procedural_lab/Max_Offline_MCP_Acceptance.py) is also definitions-only. Run its `run(expected_script_payload_sha256, private_output_directory)` on Max's main thread after the MAXScript fixture. The output directory must be under `build/offline-implementation-20261005`. It checks actual adapter paging, unchanged preparation/publication counters and diagnostic sharing denial/grant.
- Re-run the existing 0.7.1 UI acceptance and Brush/Live fixtures against this exact pair. Run real stdio/IPC enrollment, new resource/tool discovery, revocation, expiry and host-busy cases. The new offline mock tests do not replace this stage.

## Acceptance matrix

| Case | Required result |
| --- | --- |
| Diagnostics off/on/stop/idle expiry | Same placements, publication/preparation/upload counts; bounded event loss reported; stop/expiry retains readable history. Measure overhead separately. |
| Recording lifecycle | One owner per panel/session; active new-start refused; no duplicates after reload; close/reset/open stops the panel's session and revokes sharing. Saving/canceling a report does not start a renderer. |
| Read-only publication and scope | All pages reconstruct exactly the native rows and radii for one ID. Unrelated controller denied. No `containerRefresh`, source reconciliation, new solve, preview upload or geometry snapshot induced by a read. |
| Manual/Live/failure/Undo | Manual pending edits preserve old values. Explicit Update and relevant Live edits publish new IDs. Failed successor preserves old complete result. Undo/Redo and reopen have correct identity/cache semantics. |
| Containers | Source inside/outside/on boundary, global/inherited/own rectangles, parent moves, rectangle movement/rotation/scale, descendants, overlapping pools, new geometry, deleted source/rectangle, zero scale and >512-node fallback. No unrelated helper invalidation. Settings/IDs survive parking and reentry. |
| Editor navigation | All six topics, switching layers/sets, resize/scroll, viewport orbit/pan and idle retain the same generation and unchanged retained buffers. Report false Pending separately. |
| Corona production | Matching exact output/count/material/texture preflight; successful actual file with correct camera/profile. Render completion alone is not appearance validity. |
| Corona IR | Stable-camera idle soak; one real edit settles once; navigation/UI browsing do not resample. Trace explicit bridge stop/start versus renderer notifications and find the first initiating event. Preserve baseline and candidate traces. |
| Brush persistence | Signed zero, subnormal and ordinary-coordinate save/reopen versus real topology edits; do not bypass fingerprint validation or alter artist histories to make the test pass. |
| Memory/thread/lifecycle | High population and source counts, long Brush histories, retained mesh/points, additional cached radii, recording overflow and shutdown. Host APIs stay on the main thread; distinguish CPU time, draw callbacks, uploads and unavailable presentation/GPU metrics. |

A failure drives the smallest correction and a repeat of the affected acceptance slice. Keep source/native hashes with every receipt. Qualify Max 2026 independently after 2027; both SDKs compile, but neither new runtime integration was exercised here. Packaging and installation come after the review of these results.
