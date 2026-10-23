# Scatter 0.86.8.4 — rollout order and installer correction

22 October 2026. Max 2027 correction; independently versioned Analyzer remains
0.14.1. Schema 59, recipe 8, calculation behavior and content 0.86.7 are retained.
Original Paint is unchanged. The user explicitly selected this patch version.

## Rollout order and column behavior

`cyrusSetRolloutVisible` previously assigned the declared default category on
every mount/visibility refresh. That replaced the artist's saved dragged order.
Visibility now leaves categories alone. The main rollout declares its initial
category explicitly; Max normalizes its zero category to one, preceding Layers.
Native Max owns the saved order, rollout lifetime and column packing; see [Autodesk rollout ordering](https://help.autodesk.com/cloudhelp/2017/ENU/MAXScript-Help/files/GUID-FF0CBCCD-4968-41F0-8765-B41391BC2715.htm). There is
no new layout manager, scene parameter, polling loop or placement invalidation.

The owned SDK witness saves Source containers between Layers and Surfaces,
calls the actual visibility primitive with the former default category, and
reselects three times. The saved category, published fingerprint/epoch and a
pending Manual Count of 500 remain intact. This is SDK-driven order acceptance;
the attempted Computer Use drags did not establish a reliable physical reorder.
A Computer Use collapse showed Layout moving directly beneath Source containers
in a preliminary matched candidate. It is not a full physical/DPI qualification.

Max places whole open rollouts into columns. It can leave a gap when the next
rollout does not fit. This correction preserves the native packing behavior and
does not promise a separate freely positioned layout for each column.

## Installer migration and presentation

Without a receipt, the preceding installer accepted only exact 0.85.0 wrappers.
The reported profile contained an official 0.81.6 macro and no receipt. The
current finite allowlist recognizes exact wrapper pairs from 0.81.6, 0.85.0,
0.86.8.2 and 0.86.8.3; [archived package identities](LEGACY_WRAPPERS_08684.json)
record provenance. No Max 2026 binary is built, launched or qualified here.

Before migrating, existing original wrapper bytes are preserved under
`scripts/CyrusScatter/Backups/wrappers-<hash>/`. A missing recognized wrapper is
supported. Repeats/retries verify and reuse the same backup. Backups survive
rollback; the existing journal restores registration after interrupted
publication. Valid receipts continue to own their exact recorded files.
Unknown/custom files are retained, with the Max version and affected paths in
the error details. Recognition is exact, not a filename or script-pattern match.

The host-card count follows the packaged hosts, and card captions have additional
space. The title/subtitle size to their text. The actual EXE fixture reproduced
the original title's 39-pixel height against a 41-pixel text measurement; the
corrected title fits. Configured 100/150% offscreen renders are preserved; they
do not establish physical monitor/DPI behavior.

## Test infrastructure and evidence

Owned run: `build/installer-panels-08684-20261022/`. The [delivery seal](../../../build/installer-panels-08684-20261022/delivery-seal.json) binds source, build, loaded modules, scenarios and exact package hashes.

- Clean `scatter-final02/`: 51 native tests pass on the Max 2027 SDK.
- Python regression: 192 tests pass after regenerating current version metadata.
- Exact final package migration fixtures: 55 checks pass, including unknown/edit
  rejection, backups, repeat updates and interruption/recovery at the journal and
  each of the four registration publication checkpoints.
- Actual EXE handler: 10 checks pass, including legacy migration, repeated update,
  informative conflict failure and preservation of a custom macro.
- `host-final03/` binds the final script/native pair and private fixtures. The
  final scenario record and delivery seal document **42 passing scenarios**; the longest took 47.23 seconds. This is a scripted fixture duration, not presented FPS.
- The exact packaged installer core migrates old wrappers inside owned Max 2027,
  retains backups and reuses its immutable runtime on repeat installation.

The test launcher now additionally redirects Max user data, user settings and
user tools through their [documented per-session environment variables](https://help.autodesk.com/cloudhelp/2024/ENU/3DSMax-Customizing/files/GUID-EB50FC81-2E90-4CEA-884D-A8C6DE45BC0D.htm). An INI-only launch
does not isolate rollout/workspace preferences. The preliminary INI-only host
was retired before deliberate order writes. Final order tests write into owned
`userdata/en-US/UI/RollupOrder.cfg`. Private SDK witnesses are not shipped.
Managed SDK witness attempts and their failures remain as diagnostic evidence;
the final order witness uses the native SDK directly.

## Packages and limits

`dist/CyrusScatter-0.86.8.4-20261022/` contains the Scatter EXE, matching Max 2027
MZP and independently versioned Analyzer MZP, with archive/payload hashes.
Close Max before running the EXE. Alternatively use **Scripting > Run Script**
with the matching MZP, then restart Max. Existing plant content is reused.
Analyzer users also need its independently installed 0.14.1 package.

This correction does not extend the preceding release to Max 2024/2026 or close
the broader physical/DPI, renderer, device-loss, long-session, shader or panel
performance acceptance work. No overall 10/10 quality claim is made. Artist
sessions and profiles were not installation targets. No Git commit/push,
website build/deployment or artist restart is included in this request.

The [knowledge refresh and live-consumer receipt](../../../tools/rag/CURRENT_REFRESH_08684_20261022.md) records the activated current index and 48/48 full-parent verification. Retrieval tradeoffs, source freshness and product qualification remain separately scoped.
