# M03 — Typed recipe discovery through local grants

24 October 2026. **Scoped implementation/qualification, not full M03 completion.**
Current source: eighteen development tools / seven resources, package identity
0.73.0 and authoring schema 0.73. No newly versioned installable release is claimed.

## Artist and AI workflow

The native task dialog now has **Scene objects** and **Shared content** tabs.
Intent remains above both. Shared content holds the existing installed-model grant
and new **Share My recipes**, **Choose recipe folder…**, and **Revoke recipes**
actions. These explicitly share names, descriptions, tags and saved role/layer
labels. They do not share file paths, image pixels or permission to import.

The artist connects an idle task and shares one folder locally. A separate native
file worker scans it; the artist sees progress, invalid count, limits and failure.
The AI reads `recipe_catalog` in connection/context. While scanning it polls
`connection_get_status` with backoff; these cached progress reads do not consume
the normal scope read budget. No remote call can choose a path, start/advance a
scan, grant sharing, refresh or cancel it.

Once complete, the AI uses:

- `recipes_search(scope_id, library_id, query, category, offset, limit)`: substring
  search of shared clipped names/IDs/category/tags/description/layer/role labels,
  exact category filter, offset 0–256 and at most twelve rows / 32 KiB. Page with
  the same filters and `next_offset`. Omitted text is not searched.
- `recipes_inspect_entry(scope_id, library_id, recipe_ref)`: one opaque reference,
  manifest SHA/revision, bounded metadata, layer/role/Paint counts, channel/Paint
  guidance, thumbnail declaration, package hint, metadata warning and explicit
  omissions. Response remains at most 32 KiB.

Both consume the existing **24-call scope budget**. They search a frozen Python
metadata grant without filesystem access, geometry evaluation, selection, solve
or redraw. A full 256-entry catalog takes 22 twelve-entry pages; targeted search
is usually more useful. Sharing/refresh alone does not reset the read budget.

**Metadata ready is not application ready.** `use_supported` and
`ready_for_application` remain false. Model/map/Paint payloads, image integrity,
physical scale, renderer dependencies and destination compatibility are unchecked.
`Packaged; checked on Load` is a native manifest-level hint, not an integrity
verdict. Recipe application and selective settings-preset discovery/use remain
separate unfinished work. The normal native Recipes browser is the current
handoff for full details and supported loading.

## Ownership and validation

The adapter requires Max 2027 and `cyrusRecipeCatalogVersion()==1`, uses the
[independent native readers](M03_RECIPE_READER.md), and never falls back to the
gallery singleton. Builds without that API disable the recipe-sharing buttons;
local attempted sharing returns `UNSUPPORTED_CAPABILITY`. Connection reports the
loaded native API version separately from the source tool catalog.

The artist's personal directory resolves through existing `CyrusRecipeDirectory`;
custom selection uses the native folder picker. The adapter admits short absolute
paths on fixed/removable local drives. The confined native reader rejects linked
ancestors/files/sidecars/package directories and relative/UNC roots. Network/mapped
drives are denied by the adapter. The root is never an MCP argument or result.

Native limits remain two active/retiring owners, 256 candidate recipes, 8,192
directory entries, 2 MiB native cached metadata and 8 MiB per recipe manifest.
One local Qt timer polls every 250 ms while idle, with a 60-second adapter deadline.
It skips busy/dispatching periods. Cancellation requests do not join running
workers; stopping workers remain inside the native owner budget.

The native page is filtered on the Max side before Python conversion: 128 rows
per native page, at most two pages, bounded scalar/list fields, no thumbnail
payload or raw native error text. A public grant appears only after complete
collection and closed-shape validation, at most 256 entries / 2 MiB Python
metadata. No partial entry references escape while scanning/freezing. A missing
folder is a failed grant; a valid empty folder is a ready empty snapshot. Invalid
files and catalog limits stay visible rather than becoming a full-library claim.

Names/descriptions are untrusted data. Display clips and control-character
normalization are reported as omissions. The snapshot hash covers canonical
admitted metadata/counts and opaque private entry keys; it is not a live directory
hash. References are bound to that exact snapshot. The recipe manifest SHA is
observed at scan time; filesystem changes afterward do not update cached metadata.
Any future application must independently revalidate exact files and dependencies.

Refresh revokes the earlier grant before opening a new reader. Failures discard
all unpublished entries and return generic errors without private filesystem
paths. Ready snapshots close their native reader and retain bounded metadata only.
Revocation, reset/open, disconnect, unrelated enrollment and panel/bridge close
clear the grant and request closure of the exact owned reader. Explicit same-task
design handoff retains a grant or in-progress scan with a new scope ID. It does
not grant recipe application or change normal proposal approval.

These operations create no scene object, setting or Undo entry. F06 resource
bounds, F07 worker/host lifetime and F11 transient-versus-saved identity apply;
existing F01 layer/area owners and publications remain unaffected. Admission
limits are not measured peak-memory or universal latency guarantees.

## Native correction and exact evidence

The first reader increment's Windows attribute check did not use the extended
path form. The successor checks long paths through the existing `nativePath`
helper and fails closed on attribute errors other than missing files/ancestors.
An actual long symlink beyond 260 characters is rejected. The old gallery's
default unconfined behavior is unchanged.

- `build/mcp-recipe-catalog-20261024-03/receipt.json`: complete clean Max 2027 SDK
  build and **57 native tests pass in 24.60 s**. New reader executable: **33 checks**,
  including actual Windows long/short links, independent gallery/readers,
  entry/metadata admission, stale/closed handles, cancellation and destruction.
  Native input manifest:
  `e7a2a6203f7ff54d6cb3db98f0b8baf2aefda92307fd09903f39acbcb2124907`.
- `build/mcp-recipes-20261024-01/offline.xml`: **458 Python tests pass in 45.11 s**,
  including 26 new recipe cases and actual SDK eighteen-tool schema discovery.
- Owned Max 2027 **PID 21752**, now closed, matched internal prototype:
  `host01/recipes-workflow.json`. Real SDK and scripted native buttons/picker test
  pending read denial, complete/sanitized metadata, invalid files, false package
  readiness, historical metadata after a controlled file edit, explicit refresh,
  stale references, same-task design handoff, revoke, missing/empty folders and
  disconnect before metadata publication. The personal-folder fixture temporarily
  resolves to owned data and restores the original resolver; it never reads or
  modifies the artist's actual Documents library.
- The full admitted **256-entry** personal-folder fixture pages in **22 calls**;
  its limit is explicit, inspection/empty offset complete the normal 24 calls and
  the next call is rejected. An independent gallery keeps its **301-entry** page
  digest unchanged through the small-grant operations.
- Small-grant native before/after comparisons preserve node count, transforms,
  selected handles, Undo names and initially false save-required flag. An owned
  header claiming packaged content without actual payloads still reports
  `ready_for_application=false`. Changing a recipe leaves the cached inspection
  exactly unchanged until explicit local refresh; the successor reference/hash
  changes and stale sidecar metadata produces a warning.
- `host01/recipes-lifecycle.json`: actual Max **reset, file reopen and panel close**
  before snapshot publication immediately revoke the grant, clear task/native
  references and make the old native handle reject reads. Close also stops the
  polling timer/bridge. The real SDK rejects old scopes after reset/open and
  reports `NOT_CONNECTED` after close. This proves handle revocation; native file
  IO may already have completed and is not claimed to be interrupted mid-call.
- `host01/increment-receipt.json`: all **27 frozen runtime files** match source;
  all **five actually loaded native module hashes** match the staged pair, using
  the startup host witness and owned module paths. Workflow final artifact:
  `26da580a26748a2dfebaa5763d4f4f2217f11315faf090a4f6a398c6a5f5f987`.
  Later lifecycle artifact:
  `6ff9cae064dc225261e39a077a885a91eb3321a402d0717651f708f13238387a`.
- Owned historical packaged-pair negative case, **PID 5420**, also closed:
  `build/mcp-recipes-old-20261024-01/host01/recipes-unsupported.json`. Current source
  client discovers eighteen tools but loaded API is absent; both sharing buttons
  are disabled, local share denies without a native reader, scene/Undo/clean flag
  remain unchanged, and remote search has no content grant. Artifact:
  `fca6f7583f0e3db68203f7825d0496e7ae1f059f9cd28b3c0c26f3fb3e703078`.

Run `mcp-recipe-catalog-20261024-02` remains a failed/pending receipt: confinement
checks passed, but long-link fixture cleanup failed. The corrected test explicitly
unlinks the long fixture before ordinary directory cleanup; run 03 is the passing
successor. The first lifecycle close attempt had a private fixture `NameError`
before close; its source and passing reset/open snapshots are preserved in
`driver-history`, along with protocol failure receipts. The corrected complete
lifecycle suite passes. Controlled recipe fixture edits and script repair use
explicit suite rebinds, with earlier qualification manifests retained.

This is scripted API/widget evidence, not physical artist consent or a general
usability study. The native payload retains the internal 0.86.9.2 caption with
exact new hashes; it does not replace the original packaged baseline's receipts.
No new release label/package, artist installation/restart, commit/push or deployment
is claimed. Prior physical task-input evidence does not qualify the new tab layout.

## Remaining M03 acceptance

Finish settings-preset discovery, asset dimensions/source-unit and material/proxy/
renderer readiness, high-poly native source metadata, and approved asset/recipe
use through existing engines. Define import destination/ownership, memory,
selection, Undo and failure behavior before enabling it; do not assume `.max`
merge preserves arbitrary prior Undo history. Full recipe Paint/path/role/units
compatibility and O67/O68 atomic application remain open. Qualify actual planting
assets, M04's grass-and-flower workflow, physical interaction, durable task roots,
long-session memory/responsiveness and intended installed clients/packages in the
affected milestones. O66 and the complete M03 milestone remain pending full gates.
