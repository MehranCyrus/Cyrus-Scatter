# 0.86.7.1 — shared content and panel responsiveness

**Historical first delivery.** The artist subsequently reproduced disappearing
lists and requested a simpler installer. Use the
[corrected 0.86.7.1 delivery](DELIVERY_08671_CORRECTION.md). The original
instructions, measurements and hashes below describe the first artifacts;
they do not qualify the later correction.

20 October 2026. The scoped installer and host checks below passed.
User-selected patch version; schema 58 and
CyrusUnified1 are unchanged. The preceding delivery remains
[0.86.7](DELIVERY_0867.md).

## What changed

The EXE and Max-hosted installer now offer:

- **Update plugin only** — the default. It retains existing content and does not
  scan or copy model/texture payloads.
- **Update plugin and library**, with either **Use existing library in place**
  or **Install / repair shared library**.
- **Manage library only** — select, install or repair content independently of
  the plugin.

The EXE selects multiple installed Max versions. Each receives its own matched
native/script/managed payload. Standard profiles share a small per-user library
registration at `%LOCALAPPDATA%\CyrusScatter\library-state.txt`. A selected content
folder can be on another drive. Custom test/relocated profiles retain explicit
separate registration paths.

Content revision is independent of plugin version. The existing **0.86.7 plant
content** remains unchanged: 96 prepared model files representing 104 catalog
cards. No models were resaved or reconverted for this patch. The catalog still
validates its format, bounds and required Max version; relaxing the plugin-version
comparison does not permit newer Max files in older hosts.

Existing content is suggested from the shared registration or a recognized older
installation receipt. An older Max-2027-only library remains usable in Max 2027;
choose the supplied Max-2024-compatible 0.86.7 content to share across all three
supported hosts.

The panel now caches layout by width, DPI, disclosure states, conditional rows,
text and relevant control geometry. Numeric changes do not automatically move
every control. Common Amount, inclusion and transform edits coalesce their
dependent page updates; structural/unknown changes retain the full-refresh path.
Opening many saved sections creates later bodies in batches of two complete
sections, with a host event-loop turn between batches. Queued work resolves the
current layer and is cancelled when the panel closes.

## Use this delivery

Run `dist/CyrusScatter-0.86.7.1-20261020/CyrusScatter-0.86.7.1-Setup.exe`.
Select Max 2024, 2026 and/or 2027, review **Analyze**, then **Apply**. Restart
selected Max versions after installation.

For the individual MZP, use **Scripting > Run Script**, choose the package matching
the running Max version, and use the same Analyze/Apply choices. Restart Max.

On this workstation, the prepared shared content is already at:

```text
F:\Cursor\_Cyrus_Apps\CyrusScatter\dist\CyrusScatter-0.86.7-20261020\Content
```

Choose **Use existing library in place** and that folder to use it without a
second model copy. **Install / repair shared library** is for a chosen managed
destination. Same-volume verified files can be reused with NTFS hard links;
another volume needs physical copies of the missing unique bytes.

The EXE and MZPs contain the plugin, not the multi-gigabyte content. Share the
existing content separately when a recipient does not already have it. Keep its
manifest and folder structure together. Personal recipes stay separate.

## Storage, publication and failure contracts

`AminScatter/shared/LibraryLocation.cs` is shared source compiled into the
installer and host-specific gallery. It reads bounded, data-only registrations.
Each runtime has a `LibraryBinding.txt` pointing to the shared state, with a
verified compatible legacy fallback where available. An open catalog retains
its root; Refresh resolves the current registration again.

Explicit content actions validate the bounded inventory and stream SHA-256
verification/copying in fixed-size chunks, with cancellation checkpoints.
Managed storage separates immutable hash-named objects from catalog folder
views. A complete verified pack is published before its registration changes.
Content and plugin updates are separate transactions; a later host failure does
not undo a completed content update or a completed earlier host update.

Disk admission counts missing runtime files and unique missing content bytes
on their destination volumes. It includes working-space allowances, checks
Windows temporary storage before extracting the small plugin payload, and
rejects overlong content destinations before copying. No models are extracted
into Windows TEMP. Registration publication retains the prior recovery journal,
ownership checks and rollback behavior.

Previous releases and library paths are retained. Saved scenes can reference
their textures by absolute path, so deleting old folders automatically would
break those scenes. This patch prevents new unnecessary copies; it does not
claim that every old folder is safe to delete. Removing a Max registration
retains shared content and other hosts.

UI views continue to bind the same scene model. The main panel owns bounded
refresh/mount queues; caches live with their control bodies. Controls and live
scene access remain on Max's thread. Installer filesystem work runs in a worker
and reports results on the form's owner thread. No placement algorithm, scene
schema, Undo ownership or native worker boundary changed.

## Evidence and limits

Evidence directory: `build/update-08671-20261020/`.
Host profiles: `build/mcp-qualification/update08671-test-*`.

- Generator/control inventory: 320 controls accounted for; generated source
  matches its templates.
- Python regression suite: 175 passed.
- Native Max-2027 SDK test build: 48/48 CTest cases passed.
- Inert installer suite: 39 checks passed, including no-content plugin update,
  independent content revision, three-host shared resolution, missing-file
  repair, injected publication failure, cancellation, lock contention, modified
  content preservation and long-path rejection. Low-space arithmetic uses
  synthetic available-space inputs; the user's drive was not filled.
- Real EXE transactions: 20 checks passed, including all three exact installed
  native/script identities, repair, one adopted content root and an actual C:
  runtime using F: content.
- Full managed-content test reused the actual model/texture files on F:. Its
  preflight admitted **204,764 bytes of new manifest data**, plus filesystem
  metadata, rather than another multi-gigabyte model copy. The real A027 model's
  NTFS file ID matches the source.
- Max 2024, 2026 and 2027 passed textured-preview regression, source
  Point/model replacement, panel lifecycle, thumbnail loading and real browser
  resolution of content revision 0.86.7 with plugin 0.86.7.1.
- The actual hosted installer Analyze and Apply controls passed in all three
  Max hosts, against disposable destinations.
- Max 2027 passed the real A027 Corona leaf test from both the existing library
  and the new managed folder: Color Correction editing, diffuse clearing,
  opacity off/on, Undo, animation, retained navigation and Manual pending edits.
  The moved-folder test confirms the opacity path is rebound to that folder.

- Max 2027 panel lifecycle checks passed at configured 100%, 150% and 200%
  scaling. Settled native rectangles for all twelve Advanced-open sections
  reported **zero clipped controls and zero overlaps** at each scale.
  This is configured-scale evidence, not physical multi-monitor/tablet testing.
- Every MZP passed CRC and all member hashes. The final seal compares generated
  source, compiled Gallery/shared helper, installed binaries and host-loaded
  identities with the exact packages. The EXE embeds those exact three MZPs.

### Exact artifacts and evidence

All four installers are in `dist/CyrusScatter-0.86.7.1-20261020/`.
They contain small core payloads; the existing content is deliberately kept
outside this folder.

| Artifact | SHA-256 |
| --- | --- |
| CyrusScatter-0.86.7.1-Setup.exe | `60f20560d221b9f7c5defe278390abc48ba97bb8e52072f9e6345e2ba5f29c20` |
| CyrusScatter-0.86.7.1-Max2024.mzp | `c12be1daf0cf0c5c01bf0d52a823f74512f874d171eaec4f2150f1b21bf09ebe` |
| CyrusScatter-0.86.7.1-Max2026.mzp | `c975461e95269e79aceceaec0311723f9b50f8d00ea07eb1e9ad2280436b00f6` |
| CyrusScatter-0.86.7.1-Max2027.mzp | `a5f402fa920315f49c742c9535577fd66fe8942600fd68d3bfc166edb95ba13a` |

The EXE is unsigned. `SHA256SUMS.txt` and `README.md` accompany the installers.
The generated script SHA-256 is
`863c5372fe7130980ba922c17ee1061868398af9304c2fef405e1b3a638db6de`.
Content revision 0.86.7 manifest SHA-256 remains
`010f43f09172c084ba15407227f9776e359b013e1f1a9583d31a2d4458e9a361`.

Reproduction/receipts:

- `tools/update_08671/` contains build, installer, host and timing fixtures.
- `build/update-08671-20261020/final-receipt.json` seals artifacts and 29
  source/host/installer/layout receipts; `package-checks.json` records the archive checks.
- `installer-3be9278fde/result.json`, `real-installer-final/result.json` and
  `real-managed/result.json` under that directory own the storage/transaction results.
- `build/mcp-qualification/update08671-test-final-{2024,2026,2027}/`
  owns host functional evidence and matching `launch.json` identities.
- The final 100% layout receipt is `layout-settled2.json` in the final Max 2027
  profile; 150%/200% receipts are `layout-settled.json` in
  `update08671-test-dpi150b-2027` and `update08671-test-dpi200b-2027`.
- Earlier DPI attempts and immediate, unsettled rectangle snapshots are retained
  as failed harness evidence, excluded from acceptance. The corrected fixture
  bounds queue draining and observes settled controls in a separate command
  without reselecting/remounting the node.

### Panel timing and remaining performance gate

`build/update-08671-20261020/panel-comparison.json` summarizes sequential
`update08671-baseline-final` and `update08671-panel-final` private Max 2027 runs.
Each condition has ten observations on an empty Manual controller. The table
contains medians; OS load is uncontrolled, so it is not a controlled benchmark.

| Condition / measurement | 0.86.7 | 0.86.7.1 |
| --- | ---: | ---: |
| Two sections: ready | 814 ms | 963 ms |
| Two sections: warm full bind | 34.82 ms | 12.94 ms |
| All twelve: first usable sections | 6,648 ms | 1,568 ms |
| All twelve: fully mounted | 6,649 ms | 8,262 ms |
| All twelve: warm full bind | 396.59 ms | 290.77 ms |

Warm binding improved and the queued first sections became available earlier.
Full all-open completion and two-section cold readiness did **not** improve.
The new run also contains approximately 21-second outliers; the raw samples
retain them. No geometry, placement, preview preparation, map baking or GPU
upload stage was recorded in either probe, and publication epochs were stable.

The plan's proposed 50% all-open warm-bind improvement and 30% full-readiness
improvement are **not achieved**. Its deeper optional-control prototype and
old-content retirement report are not completed by this patch. Do not interpret
the passed functional checks as full acceptance of every roadmap gate. This
release provides independent content updates and a bounded UI refresh/first-access
improvement; B21 cold construction remains open. Further work should target
hidden Advanced control construction and repeated list binding, with the same
ownership and layout regressions, before claiming faster complete opening.

These are scoped qualification results, not a promise of flawless behavior in
every production scene. The local older hosts lack the Corona/Forest dependencies
used by the real leaf; those material tests establish Max 2027 evidence only.
The panel still creates hidden Advanced controls inside a mounted body; this
patch does not claim complete lazy construction of every optional control.
Queued opening improves access to the first sections with the completion-time
tradeoff measured above.

No artist-profile installation, original-model modification, artist-scene reset,
artist-session restart, automatic old-content deletion, commit or push was
performed. Website artist-reference sources were synchronized; no website
build or publication is claimed.
