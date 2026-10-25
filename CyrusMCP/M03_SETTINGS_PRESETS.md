# Settings preset discovery and application contract

24 October 2026. M03 in progress; not a release, installation or full acceptance.

Settings presets (`.cspreset.json`) are distinct from complete planting recipes
(`.csrecipe.json`). Reuse the native `presets::parse/serialize` contract and the
existing bounded, confined native file-catalog worker. Keep normal gallery,
recipe metadata readers and preset readers independently owned; never borrow or
replace another reader's job. F04–F07/F10/F11 apply.

The local artist shares My settings presets or one selected local folder. Sharing
authorizes metadata and selected frozen typed settings inspection only. No path,
folder-opening, sharing, approval, arbitrary property or script API is exposed to
the model. Names are untrusted labels. Source bytes are preserved. Discovery covers
the five existing native categories: population, transforms, spacing, density_curve
and scale_curve, without inventing a common effect for these different owners.

Native workers own copied local paths and immutable JSON, never SDK objects or
MAXScript values. Each preset is at most 64 KiB. A confined, nonrecursive scan has
512 preset/8192 directory-entry/8 MiB serialized owned-data ceilings; all invalid
and omitted counts are explicit. At most two preset-reader owners, including
retiring workers, are retained. Closing revokes the exact handle immediately;
cancellation does not claim that a worker already terminated. Only terminal workers
are reaped on the host thread; shutdown joins before DLL unload.

Freeze metadata only after the whole bounded scan completes. Search/pages consume
cached metadata; selected inspection reads the worker's frozen native typed
document, not the filesystem or scene. Original-file SHA, normalized-document SHA,
category, physical-distance semantics and source-version normalization are distinct
facts. Frozen inspection is not live-file freshness or destination compatibility.
Refresh/revoke/reset/open/disconnect/close invalidate the corresponding grant.
The explicit same-task design handoff may retain read-only discovery, issuing the
new scope ID; it never carries application approval.

Application remains required work: resolve exact destination owner/category,
inheritance or spacing peer and curve target; inspect a complete before/after diff;
validate unsupported dependencies, units, animation/controllers and resources;
obtain exact local approval; reuse the native preset engine; preserve untouched
fields, Manual pending publications, identities, failure retention and Undo.
Read discovery alone cannot close O67 or silently apply settings that the MCP's
authoritative authored-state readback cannot represent. Full recipe application
remains a separate O68 operation with its asset/Paint/receiver effects.

## Implementation and offline evidence

The native catalog extends the existing file-only `Library` worker with a closed
settings-preset mode. Its default recipe/gallery behavior stays separate. Preset
catalogs have their own two-slot registry; the normal gallery and recipe readers
retain their existing owners and limits. Native selected-entry inspection reads
only the retained validated document. Source bytes and normalized version-3 bytes
have different hashes; supported earlier preset versions normalize through the
existing native parser without rewriting their files. Public native pages and MCP
responses omit paths and full document payloads until one entry is inspected.

The source adds `presets_search` and `presets_inspect_entry` (22 tools/seven
resources total). The completed snapshot exposes at most 512 entries, with up to
24 per search page, so a complete catalog needs 22 reads within the existing
24-call scope budget. Native freezing uses at most four 128-entry pages. Cached
metadata is capped at 1 MiB in Python; selected inspection is capped at 96 KiB.
Curve samples/graph dimensions and scalar field kinds/ranges are bounded. Local
controls and a native timer start/poll/revoke the reader. Shared content now scrolls
inside the task dialog; the added controls do not force an oversized window.

Native build `build/mcp-preset-catalog-20261024-01` passes 58 suites in 25.62 s,
including 46 independent catalog checks. Its input-manifest SHA-256 is
`812bd8e288f74701b369f66a0112d0a37478604ca08dd91f46504aa150c6dedf`;
AminScatter DLL SHA-256 is
`b14cb2ec11418d3b70cbe0a7c3a42f796d9c27d564dfc077e549ff5af0c6e090`.
These remain internal matched prototype identities, not a new version delivery.
The current Python/tool successor passes 546 tests in 49.22 s:
`build/mcp-preset-discovery-20261024-02-offline.xml`.

The exact older packaged Max 2027 pair denies settings-preset discovery before
opening even a nonexistent folder. Its native feature flag is absent, local
sharing buttons are disabled, the remote read lacks a grant and the scene is
unchanged: `build/mcp-preset-old-20261024-01/host01/presets-old.json`, artifact
`e17f42a9d458a55ce59215a5fb89ed76f93dd3f1cdb5b0d19bd27116c81816af`.
The capability-resource declaration was subsequently aligned with both installed
source preparation and settings discovery; final current-source identity belongs
to the successor campaign. The earlier startup-only profile was closed before any
discovery workflow and is not qualification evidence.

## Real-client/native successor

`build/mcp-preset-discovery-20261024-02/host01/presets-workflow.json` passes
five real SDK/Max cases:

1. All five existing categories plus a supported v1 transform preset are parsed,
   discovered and inspected as native normalized v3 documents. Six valid and three
   invalid entries are reported. Scalar metre flags and curve data match the
   retained documents. A deliberately clean scene stays clean, while the normal
   gallery and separate recipe reader remain unchanged.
2. Changing a working preset file leaves frozen inspection unchanged. Explicit
   refresh creates a new grant, reports five valid/four invalid entries and rejects
   the old grant; revoke releases the reader and denies further inspection.
3. A linked root is rejected without publishing a grant.
4. A 520-file folder reports its 512-entry ceiling and `limited=true`; all 512
   distinct refs page through the same scope in 22 calls.
5. Disconnect revokes sharing and releases the native reader.

Workflow artifact SHA-256:
`ab73921f000f2572bc387273efbe3ef808e100beaad13b365bafff96ee73a1b9`.
The adjacent `increment-receipt.json` confirms all 32 frozen runtime files equal
current source and all five actually loaded native modules match their bound
hashes before lifecycle testing.

`presets-lifecycle-sdk.json` adds three passing native reset, owned save/reopen and
panel-close cases. Each immediately clears the grant and host handle, rejects the
closed native handle and releases task references before UI refresh. The external
SDK rejects the old scope/grant with `UNKNOWN_REFERENCE` after reset/open and
`NOT_CONNECTED` after close. It also reads and verifies the updated capability
resource through the SDK. Final lifecycle artifact SHA-256:
`9ef811ef3d61cf28c44fd2b28df881f8eaa3a20542e2fdfec03f11a681f8eb51`.
Paused metadata publication is distinct from interrupting native file IO; the
worker can already be terminal when the lifecycle event occurs.

Physical artist interaction, broader workload/performance and final delivery
remain open. Discovery never qualifies settings-preset application. Next implement
faithful native category/settings readback and approved typed application without
discarding untouched fields or losing Manual pending/publication state, then the
separate complete-recipe compatibility/application path. Neither O67/O68 nor M03
is complete merely because this reader and its lifecycle are qualified.
