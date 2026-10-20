# Cyrus Arrange 0.3.0 workflow improvements

Status: qualified for the documented Max 2027 workflow. Native, Python, all
18 functional suites and separate capacity checks passed. The unchanged MZP
passed private installation and automatic startup. See the [release report](RELEASE_VALIDATION_0.3.0.md).
Historical 0.2.0 packages and evidence remain preserved.

## Scope and version

The supplied videos were reviewed visually in the browser; the
[timestamped report](research/UX_VIDEO_PLAYBACK_REVIEW_2026-10-18.md) separates
observations from inference. This delivery adds bulk prop intake and explicit
reusable decor groups, with simpler main controls. It is independent Arrange
version **0.3.0** because these are additive artist workflows and native APIs.
It does not change other Cyrus products, document format 4, library format 2,
registration identities or the existing placement algorithm.

## Ownership and behavior

- Native C++ owns normalization, source guards, geometry capture, bounded batch
  registration, group copying, catalog publication and Undo. MAXScript captures
  the selected nodes and explicit category, invokes the command and presents its
  result. There is no script placement loop or post-placement jitter.
- Bulk intake stages every new asset before publishing once. Selected outer
  groups remain one asset. Repeated selected nodes and selected descendants of
  selected group heads do not create duplicate entries. Existing actual source
  references in the same catalog are skipped without editing their metadata.
- Each catalog has at most 256 assets. Source assembly admission remains 4,096
  nodes and the native mesh limits. Furniture, obstacles, setup owners and
  managed generated output cannot become quick props. Scene names are labels,
  not ownership evidence. Arbitrary ambiguous non-group parenting is rejected.
- Creating a decor group is an explicit authored action. The artist first
  arranges its pieces, then selects them. Native code copies that selection into
  a new source group and registers it as one asset. Its relative geometry,
  physical size and source appearance are retained; originals remain intact.
  The group is reusable by selecting it for another arrangement, and it saves
  in the Max scene. A generated placement is the existing flattened mesh output,
  not a new group hierarchy per placement.
- One Undo restores an entire successful batch or group operation. Failure
  retains the previous complete catalog, authored settings and output. Opaque
  monotonic ID reservations may advance on failed work; IDs are not counters.
- Main Generate still stages the settings and fresh seed with output atomically.
  Repeat seed is optional. Every group pose passes the same native whole-footprint
  support, clearance and conservative collision checks as other props.
- Placement computation, geometry cache invalidation and saved scene formats
  retain their existing native owners. Intake does not solve placements.
  Passive UI discovery must not capture geometry, create assets or solve.

Portable asset libraries retain geometry/metadata. Full source appearance and
the reusable source hierarchy live in the Max scene; missing sources require
explicit rebinding or choosing stored geometry. New names do not imply a new
cross-scene material package format.

## Acceptance

Use the exact built C++/script pair in owned, disposable Max 2027 profiles.
Exercise actual UI buttons, bulk normalization/idempotence, complete mixed-batch
failure, copied and nested group preservation, materials, source reuse across
two arrangements, Undo/Redo and save/reopen. Independently measure output bounds,
support containment and non-overlap in TV/open-shelf fixtures, verify fresh and
repeated seeds, stale-window ownership and ungenerated draft preservation.
Re-run the prior functional collection and native tests. Qualify the unchanged
MZP installation and automatic startup in private profiles, then deliver that
installer without modifying or restarting the artist's Max session.

This acceptance is bounded to the recorded fixtures and host. It does not assert
universal aesthetic quality, arbitrary renderer support or zero defects.
