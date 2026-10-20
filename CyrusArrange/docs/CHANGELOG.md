# Changes

## 0.3.1 — Modify controls and real model scene (qualified)

- Add a public native Cyrus Arrange modifier and automatically created viewport
  icon for new arrangements. A compact MAXScript parameter view in Modify uses
  the existing native document and placement commands.
- Keep panel selection, display and refresh passive. Capture document identity
  for commands and Props windows; clear closed views and guard stale callbacks.
- Add real prepared-model fixtures for two tables, books, a plant and decor,
  local texture dependencies and independent world-geometry checks.
- Preserve document 4, library 2, registry 1 and existing registration identities.
  Added presentation classes have new IDs. Acceptance is tracked in
  [the current contract](REAL_WORLD_0.3.1.md).

## 0.3.0 — bulk props and reusable decor groups (qualified)

- Add selected original models and complete groups together. Native code
  normalizes duplicates, skips existing sources and commits a validated batch
  atomically without changing existing prop metadata.
- Create a named decor source group from copies of a prepared selection.
  Originals remain intact; the source group can be reused across arrangements
  and retained in the Max scene. Group creation and catalog registration share
  one Undo step.
- Main Generate keeps fresh variations as the default. Repeat seed reveals the
  exact seed field; detailed controls remain under Advanced and the library.
- Existing source appearance, physical scale, complete fit checks and saved
  scene/library formats remain. Fresh status and scoped evidence are recorded
  in [0.3.0 validation](RELEASE_VALIDATION_0.3.0.md).

## 0.2.0 — simplified arrangement workflow (qualified)

- Compact main window, automatic existing-setup discovery from furniture/output and a quick prop library.
- Generate creates a new seed by default; Keep seed repeats it. Native generation commits settings, seed and output together.
- Detailed settings remain under Advanced. Existing scene formats and class identities are preserved.
- Fresh validation and installer status: [0.2.0 report](RELEASE_VALIDATION_0.2.0.md).

## 0.1.3 — geometry reuse and imported-model workflow (qualified)

Selected before metadata changes: a transient cache, bounded accounting and dependency/command safety milestone. Document4/library2/registry1 and existing placement contracts remain unchanged. Exact acceptance is in [release validation](RELEASE_VALIDATION_0.1.3.md); measured preparation and whole-command effects are in [performance](PERFORMANCE.md).

- Reuses validated same-time numerical furniture/obstacle geometry and placement
  queries, with bounded retained storage, dependency epochs and passive native
  phase/work diagnostics. Source assets and placement solving still refresh for
  each command. Relevant edits invalidate reuse and stale previews.
- Retains transient observation of newly discovered group descendants, guards
  owner/cycle lifetimes and stages publication atomically. Actual WSM evaluation,
  clone/merge/delete, Undo, callback edits and failure retention have dedicated
  host regressions.
- Accepts imported level boards with sub-micron vertex variation within the
  existing numerical contact tolerance. Original support-height extrema bound
  eligible polygons; multiple eligible bins unite before edge inset. Original
  geometry and full collision checks are preserved. See
  [numerical support](NUMERICAL_SUPPORT.md).
- Reports requested, accepted, kept and underfilled counts for Preview and
  Commit as well as Generate, with readable integer counts and a native warning.
  Managed-output Live recovery names the available Lock and Generate controls.
- Adds hash-pinned CC0 imported cabinet/shelf/frame/vase/bowl fixtures, complete
  source/output geometry and appearance-data checks, portable texture relocation
  and four actual Standard/Scanline example renders. These are bounded material
  and model trials; original PBR and arbitrary renderers are not qualified.

Native46 passes twelve native executables / 117 cases, sixteen final functional suites / 3,034 assertions and five independent JSON exports. Two opposite-order performance runs pass 1,109 checks each; imported probe and workflow/render pass 432/0 and 612/0 separately, and the fresh book-row gallery passes 35 with six images. The exact MZP also passes 43 private installation and 12 automatic-startup checks. Historical receipts remain intact.

## 0.1.2 — qualified individual book rows

Adds native row relationships for explicitly marked upright Book assets on TV consoles/open shelves, whole-row locking/removal and an optional bounded row-height-balance pass. Existing ordinary scatter controls and array contracts remain. The current source writes document4/library2 and explicitly loads the delivered document3/library1 baseline with new features disabled. Native28 passed the complete thirteen-suite functional collection; the exact immutable MZP passed private installation and automatic startup. See [release validation](RELEASE_VALIDATION_0.1.2.md). The earlier 0.1.1 r3 package remains preserved.

Also fixes clustered anchors crossing into a different sampled support region while retaining the original region policy. Rounded clearance joins are admitted before Clipper constructs their expanded paths, preserving requested precision and clearance. Valid older golden poses remain exact; explicitly invalid old outputs are corrected. Supported delivered scene/library inputs stay unchanged during loading and migration tests.

Adds separate book-row and measurement guides, procedural research findings, original modeled examples and an 86-command performance/equivalence harness. The measurements disclose background load and complete command costs; geometry/query caching remains a separate unfinished milestone.

## 0.1.1 arrangement baseline

This version extends the qualified 0.1.0 geometry inspector into a native
interior arrangement workflow. See [release validation](RELEASE_VALIDATION_0.1.1.md)
and the external qualification receipt for the exact tested build/archive.

- **Generate accessories on furniture.** Seeded native placement supports TV
  consoles, open shelves, coffee tables, kitchen counters and dining tables.
  Eleven accessory categories cover Book, Book stack, Plant, Candle, Frame,
  Vase, Accessory, Bowl, Tableware, Kitchenware and Tray. Choose density, spacing,
  edge gap, grouping, scale variation and empty space, then reroll variations.
- **Prepare a reusable asset library.** Register scene models or groups; edit
  their category, allowed furniture, yaw angles, selection weight and scale.
  Author contact and stack support patches. Rebind missing sources or explicitly
  retain stored geometry, and save or append portable `.cyalib` libraries.
- **Control each support surface.** Analyze furniture, label sampled surfaces
  and compartments, exclude regions, set allowed accessory categories, adjust
  density and stacking, and author a horizontal front direction. Category rules
  also control relative frequency and maximum counts.
- **Declare collision obstacles.** Add explicit scene geometry independently
  of the supporting furniture. An optional clear horizontal approach checks
  shelf access from each surface's authored front direction.
- **Preview and preserve chosen results.** Preview estimated bounds before
  committing, lock selected outputs and connected stacks, or regenerate selected
  surface IDs. Reusing a seed and unchanged inputs reproduces placement records.
  Failed generation retains the previous complete output.
- **Keep native scene state.** Setups save source references, assets, rules and
  placement records in the `.max` scene, with Undo/Redo. Manual mode uses explicit
  Generate; Live responds to relevant changes after a successful Generate.
  Preview pauses Live until Commit or Generate.

Important boundaries:

- **3ds Max 2027 only.** This version is not qualified for other Max versions.
- Assets remain upright. Collision uses conservative oriented bounding boxes,
  which can reject a close fit that exact accessory triangles would permit.
  Sampling resolution still limits detection of small support features. There
  is no gravity simulation, balance solver or automatic dining place-setting
  relationship.
- Portable libraries contain geometry and placement metadata, without materials,
  textures, UV channels or modifier stacks. Preserve the source `.max` library
  for appearance; bound scene sources provide evaluated material and map data.
- The current arrangement document uses schema 3. Earlier internal schema-1
  and schema-2 arrangement documents have no migration path and are rejected.
  The qualified 0.1.0 delivery contained the inspector rather than these native
  arrangement documents.

## 0.1.0 qualified inspector

The earlier delivery analyzes selected furniture geometry and groups, reports
world-axis dimensions, sampled support regions and overhead clearance, creates
an inspection overlay and exports JSON. It does not generate decorations.
Its preserved scope and evidence are in [QUALIFICATION.md](QUALIFICATION.md).
