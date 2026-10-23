# 0.86.9.2 — restore safe native column ownership

Authorized 23 October 2026 after the 0.86.9.1 crash report. User confirmed the
trigger includes a six-column Modify panel and selecting another Scatter object.
The user explicitly requests continued testing and fixing. A corrective patch
0.86.9.2 preserves independent Analyzer 0.14.2, schema 59, recipe 8, native Edit 2,
original Paint, calculation contracts, supported saved scenes and Undo.

## Evidence and diagnosis

The artist's 18:06 dump and owned `host01` 18:19 dump both fault at
`Qt6Widgets!QBoxLayout::setGeometry+0x460`, a null read during Qt/Max legacy rollup
layout. The installed script/native hashes match the delivered 0.86.9.1 pair.
Initial scripted mount checks returned success before the owned process later
failed. Success inside a driver callback does not prove queued Qt layout or
cross-owner teardown survived after that callback returns.

The width experiment was too invasive: it rewrote `WM_WINDOWPOSCHANGING`, fitted
every nested dialog while attaching navigation subclasses, bound the main root,
and took over its resize handler. Fresh controls could be clipped as well. A
diagnostic disabling the native binding calls alone also failed later in Qt focus
notification, so that comparison does not establish one unique crashing line.
It also stripped the script BOM and is excluded from final acceptance. Keep its
evidence rather than presenting it as a successful fix.

Historical 0.86.9 is the bounded comparison for the previous panel behavior;
it is not current engine qualification. Reproduce both first-open and cross-owner
switches in independent requests, with native event-loop idle between them.

## Correction

Restore the complete pre-0.86.9.1 column geometry path in `rollout_scroll.cpp`,
`approved-main-ui.ms` and the single changed width expression in `lazy-pages.cjs`.
Max again owns native dialog positioning and root auto layout. Navigation retains
its previous child-only ownership/lifetime protocol. Remove the forced-width
subclass behavior and root binding. Do not introduce another timer, native
reparenting, Qt patch, or bulk language rewrite as a substitute for evidence.

Keep the 0.86.9.1 density TextureMap controls, bounded preview cache/lifetime and
native Edit movement/release fixes. The thumbnail release on actual page close
remains in the generator. Source files, generated script and catalog stay matched.
The former request to remove all native column padding is deferred: stable native
column behavior takes precedence, and small Max-controlled insets may remain.

## Acceptance and delivery

- Fresh empty creation → Modify; populated setups; deselect/reselect and switching
  two independent controllers in single and six-column layouts.
- Return from each mutation, allow queued native UI work, then check process
  survival and owner/queue state in a separate read-only request. Also switch
  while lazy mounting is pending. Record timeouts, late results and actual crashes.
- Preserve both controllers' authored identity, pending Manual settings and
  complete publications while browsing; exercise Undo and saved scene roundtrip.
- Keep procedural previews, empty texture-map drag/drop and Edit live/release
  feedback. Run focused affected checks rather than claiming broad UI certification.
- Build/test only Max 2027. Build distinct untested 2024/2026 Scatter payloads and
  combine them with matching Analyzer in one EXE. Include the exact Max 2027 MZP.
  Never install into or restart artist profiles; do not overwrite 0.86.9.1 artifacts.

Evidence root: `build/crash-08691-20261023-01/`. Preserve original delivery receipts
and dump hashes. A final report must distinguish tested corrected bytes from
diagnostic scripts and historical baselines. No Git push or website publication
is authorized by this repair.
