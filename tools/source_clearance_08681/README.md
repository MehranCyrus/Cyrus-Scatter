# 0.86.8.1 correction campaign

The original scripts operate only in recorded disposable Max 2027 profiles.
The `compatibility_*` scripts extend the campaign to the explicitly requested
Max 2024 and 2026 hosts and a combined installer. They
require the local SDK, compiler, permitted library assets and task fixtures;
they are not end-user commands or portable installer tests.

- `build.py` incrementally builds the native development/core targets.
  The delivered build uses `tools/procedural_lab/offline_build.py` and its
  complete source-hash receipt instead.
- `profile.ms` creates the original two-real-leaf fixture. `profile_saved.ms`
  reopens the frozen fixture for the same-scene baseline/final comparison.
  Baseline map-counter zeros mean unavailable, not measured zero work.
- `viewport_checks.ms` adds the third opacity-card leaf and tests material
  correction plus display-mode reuse.
- `steps.py HOST PHASE...` serializes `viewport_steps.ms` commands, leaving a
  presentation opportunity between them. It verifies actual stream changes
  separately from nested redraw timing.
- `installed_checks.ms` checks zero-weight preference and three-leaf
  persistence after loading exact installed bytes in a disposable profile.
- `identity.ms` records loaded native/Gallery hashes and script fingerprint.
- `installer.ps1 -Run NAME` tests installer operations only in campaign-owned
  redirected paths.
- `package.py` verifies the frozen receipt and creates matched installers,
  hard-linking the unchanged optional content ZIP.
- `seal.py` verifies existing build/package/installed/host receipts and writes
  the initial Max 2027 evidence index. Its package state is preserved under
  `final/max2027-only/` after extending the EXE.
- `compatibility_package.py`, `compatibility_installer.ps1`,
  `compatibility_host.py` and `compatibility_fixture.ms` prepare and qualify
  matched additional hosts. The fixture uses Standard materials with existing
  leaf images, without requiring Corona in older hosts.
- `compatibility_seal.py` is the final three-host evidence verifier.
- `backup_check.py` verifies all qualified source inputs are present in the Git
  index and explicitly records pre-existing newline normalization.

Final inputs/results are under
`build/clearance-performance-08681-20261020/final/`.
The delivery scope, measurements and limitations are in
`docs/plans/source-clearance/DELIVERY_08681.md`.

Final host commands ran in this order: `profile_saved.ms`,
`viewport_checks.ms`, then presentation phases:

```text
texture radius check-radius check-selection opacity check-opacity
geometry update-geometry uv live-radius check-live check-time save
animate-map animate-frame check-animated restore-animation save
```

The installed-byte host additionally ran `installed_checks.ms`, then the
presentation phases through `save`; shared animated-map phases were exercised
in the final-build host. Existing `source_clearance_0868/host_acceptance.ms` and
`host_lifecycle.ms` were rerun in the final-build host. Failed developmental
receipts remain historical and are excluded from the final seal.
