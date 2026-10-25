# Installed model preparation and approved use — contract

24 October 2026. In progress; no release/artist installation or M03 completion.

Reuse the installed individual catalog and existing native portable package
engine. Prepare model derivatives only in an owned Max 2027 content-build scene;
never open or merge `.max` source files in the artist's document. Preserve original
model/catalog bytes. A bounded sidecar index links each prepared package to its
original catalog ID, source-scene SHA-256 and catalog SHA-256. Catalog availability
is not import readiness; full native package, physical-scale, adapter and resource
checks still precede a proposal.

The intended artist workflow is: share the installed catalog, separately permit
source preparation/proposals for that exact catalog, let the assistant choose
opaque model references, prepare selected vetted packages asynchronously, review
and approve actual source copies, then continue the same task. Model tools cannot
choose paths, prepare `.max` files, grant authority or bypass exact approval.

At most three selected source packages are prepared serially, with aggregate
source/image/byte admission. Their native handles own immutable data; revoke,
reset/open/disconnect and panel close release only those handles. Scene staging
uses one authored transaction across the selected cohort, tracks created nodes
immediately, preserves existing objects/selection/Auto Key and reports committed,
rolled-back or uncertain outcomes through the existing journal. Native bitmap
cache files remain for saved scene references. No new shared storage service or
SL01–SL09 library redesign is introduced.

Content preparation initially admits source scenes up to 64 MiB per owned build
step, then applies actual native geometry/material/portable limits. This is a
preparation-work ceiling, not proof that larger scenes are unsupported. Record
every omitted catalog entry and its reason; do not infer readiness from `.max`
file size or silently reduce geometry. Larger builds require measured admission.
The complete 96-entry catalog remains discoverable even when a derivative is
missing or unqualified. M03's remaining source types/workloads remain open.

Final qualification must cover catalog/prepared revision binding, changed or
escaping index/package paths, local permission, stale/revoked refs, mixed packages,
failure after earlier-package staging, truthful physical scale and identity,
idempotency, Undo/Redo and lifecycle/resource retention through the real client.

## Native snapshot ownership correction

F05/F06/F07/F10/F11 apply. The first real three-package campaign
(`build/mcp-installed-source-use-20261024-01`) prepared/reviewed all three but
import rolled back: the existing `PackageTask` owns only its latest worker
snapshot. Serial preparation alone cannot retain earlier package handles.
The failed operation and private traceback are preserved; no source nodes committed.

The correction adds explicit native retained package leases (API 1), separate
from the existing single file worker and its replaceable job token. Leases own
`shared_ptr<const PreparedPackage>` only: copied native metadata/mesh data and
owned cache paths, with no SDK nodes, open file handles or MAXScript values.
The package-task mutex guards the lease registry. No geometry is copied merely
to retain a package. The worker keeps its existing limits; at most three leases
add 64 MiB aggregate compressed payload, 128 MiB native mesh storage, 64,000,000
map-instance pixels, 128 maps and 64 materials. Native admission independently
checks these totals before accepting another lease. Shared worker/lease pointers
refer to one allocation. Active worker and retained allocations both count toward
process peak; image/SDK/Undo allocations still require their separate admission.

Replacing a file job cannot replace a lease. Exact release is idempotent and
never releases another handle; shutdown joins the worker before destroying leases.
Preparation has no scene/Undo effect. Import still creates new native nodes inside
one authored hold, tracks every created node across packages and preserves prior
history; Undo/Redo own the resulting scene data independently of leases. Failure
must preserve earlier leases and published scene work. The adapter retains each
ready snapshot, releases its worker token, then starts the next worker. Revocation
releases all task-owned leases and keeps persistent cache files for scene references.
Older matching source-use builds retain their single-package capability but cannot
enable installed-source selection without the new native lease API.

Qualification requires its native build, lease tests, real-client three-package
transaction, partial-stage rollback and lifecycle evidence; see the successor below.

## Content-build evidence and remaining admission

`build/mcp-installed-models-20261024-01/host01/content-preparation.json` is terminal:
96 original catalog entries, 38 portable exports, 45 native preparation rejections
and 13 source scenes deferred above the initial 64 MiB build-step ceiling. All
original model/catalog bytes remain preserved; immutable source files were viewed
through hardlinks in the owned content folder. The preparation host was closed.
An initial missing-parent fixture error is preserved separately and was corrected
before the actual model preparation run; it is not asset incompatibility evidence.

The bounded source-admission index contains all 96 entries: 13 available
derivatives, 38 deferred and 45 rejected. Its SHA-256 is
`a4039c88d53deee36dfe8c1076898c341e942239ebb5f81a4f5212972c84eabd`;
original catalog SHA-256 is
`ea0e2320fad53a18af2951de64d297c56a15ff3c7868c93fbb522222d04b67d6`.
Availability does not prove native readiness or import approval. The three actual
plant derivatives A062/A068/A069 together declare 18,244,991 payload bytes and
52,081,314 map-instance pixels; no texture or mesh was silently reduced.

The 45 native rejections include 23 unsupported shader enum values, five finite
mesh-profile failures and 17 other specific adapter/static-derivative requirements:
OCIO CoronaBitmap legacy configuration, finite coordinates, Gradient Ramp,
keyed transform controllers, Fresnel IOR, anisotropy, translucency mapping and
real-world mapping. These remain required compatibility work, not permanent
exclusions from M03. Of the 38 exported packages, 24 exceed current MCP admission
and one needs descriptor review; 13 pass bounded descriptor admission. Larger
native profiles do not automatically qualify broader MCP memory/latency limits.
The 680 derivative/staging files total 738,413,781 logical bytes in this build;
this is build-folder accounting, not peak process memory or a delivery size claim.

The maintained source now offers twenty tools and seven resources. Local
installed-source permission is tied to the exact scope/task/catalog snapshot,
with eight preparations per task and three distinct catalog refs per request.
Requests are bounded and keyed; uncertain retries observe the same preparation,
and failed/retired keys never restart jobs. Revoke/refresh/reset invalidates
installed-origin grants and approvals. Manual package sharing remains independent.
Source-node creation uses the existing exact approval/apply/status journal.
Pure tests cover permission, scope/revision/reference checks, retry/conflict,
budgets, stale/escaping descriptors, serial readiness and request-order staging.

Native successor `build/mcp-retained-sources-20261024-01` passes all 58 suites
(321 package assertions, including lease ownership/admission); its input-manifest
SHA-256 is `59fe46eee1e3ce406ca16cff3db24697cf50d6637e37b09cf1d8c56e2856024e`.
The Python/tool successor passes 519 tests in 49.36 s:
`build/mcp-installed-sources-20261024-03-offline.xml`.
## Real-client retained-snapshot successor

`build/mcp-installed-source-use-20261024-02/host01/installed-sources.json` passes
five real SDK/Max 2027 cases, with scripted local permission and approval widgets:

1. A062/A068/A069 discovered from the installed index, prepared as three distinct
   native snapshots, exact review/approval, three source copies committed in one
   authored Undo, reversed request-order correspondence and verified Undo/Redo.
   Selection, prior history, Auto Key and time remain unchanged. Native staging
   and completion took 2,438.39 ms in this owned case; this is not broad latency
   or rendering qualification.
2. Failure injected after the first package stages a node produces verified
   rollback of the entire cohort and preserves the original scene/history.
3. Installed permission revoke drops all three native leases, invalidates grants
   and denies further preparations using the revoked permission.
4. Disconnect during a new preparation releases its task-owned cohort and grants.
5. The existing manually shared two-source package still imports under exact
   approval, with one retained snapshot and verified Undo/Redo after its release.

This campaign's artifact SHA-256 is
`ab3d2d85994f1759e5e90988289c3e4417c5db15c4c5d58278f101ce3a4d324a`.
The loaded successor AminScatter DLL SHA-256 is
`ba8c934e2040fd350522b156edb177c881c076e02642512ee2957697e509cf0a`.
The earlier failed singleton-handle campaign remains preserved and does not
qualify this successor. Source/package/loaded identities are separate from the
unchanged internal version caption; this is not a release or artist installation.

Broader native admission/adapter compatibility, real artist interaction, returning
task context, settings presets/full recipe application, explicit old-pair host
denial of this new lease workflow and final delivery remain open. Existing older
source-use API support is retained; pure tests deny installed permission when the
new lease API is absent. M03 is still in progress and the full M00–M13 goal is open.

## Same-task installed-content planting

`build/mcp-installed-source-use-20261024-02/host01/installed-planting.json` passes
the full scoped chain through the actual external SDK: local catalog sharing and
source-preparation permission, opaque A069/A062 discovery, native retained-package
preparation, exact source-copy approval/import, same-task source-role confirmation,
separate reviewed design handoff, approved two-layer native generation and actual
execution export. The design handoff releases source leases and preparation
authority while keeping the imported native scene sources and confirmed task.

From 160 candidates in the picked region, the native result publishes and exports
137 matching rows: 68 grass and 69 flowers. These are actual filtered results,
not exact density or per-zone targets. No automatic flower-patch authoring was
performed. Import took 1,935.64 ms and generation/completion 521.25 ms in this
single owned scene; these measurements do not qualify larger workloads or UI FPS.

Final artifact SHA-256:
`388e0eeb2ca40a740dabc9b4f726a548020174395310e8e8c25a43f57a4a95fd`.
The adjacent `increment-receipt.json` confirms all 31 frozen runtime files equal
current source and all five actually loaded native modules match their bound
hashes. The content builder, first failed client host and final successor host
are closed. Historical receipts retain their original hashes/results. No artist
profile, installed client registration, version delivery or release package changed.

Next acceptance: complete settings-preset discovery/application and qualified
recipe use, then broaden installed-content adapter/resource coverage from these
measured omissions. Retain old-native/lifecycle/material/artist and final packaging
gates; the successful two-layer slice does not close M03 or M04.
