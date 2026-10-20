# 0.86.8.2 focused qualification

These drivers require local matched SDK builds and the owned transport fixture.
They never install into artist profiles. Run commands from the repository root.
See `docs/plans/source-clearance/DELIVERY_08682.md` for evidence and limits.

1. Generate from `AminScatter/`, rebuild the feature catalog, run generated/layout
   checks and Python tests. Freeze product sources before SDK builds.
2. Run `offline_build.py --project scatter --year YEAR --output
   build/clearance-relax-08682-20261021/maxYEAR` for each explicitly authorized host.
3. `host.py 2027 final launch`, then `setup`, `identity`, `bounds`,
   `calculations`, `lifecycle`. Each host action is serialized.
4. `package.py`, `embedded.ps1`, `installer.ps1` create and verify exact matched
   packages and disposable installed paths. The existing ZIP is hard-linked;
   the installer shares existing content. Fresh owned paths are required.
5. `host.py YEAR installed launch` uses byte-verified installed files. Run the
   same integration actions for 2024 and 2026.
6. Max 2027 `numeric` requires prior actual UI edits: first source factor 1.5,
   gap 3 cm, XY distance; layer Relax distance 30 cm. `wide` checks the same
   generated page in a bounded 320-pixel test host. `ui-state` is a diagnostic
   action that explicitly reopens the test's selected pages.
7. Capture the actual UI, run `seal.py`, then `close` each task-owned host.

`baseline` and `dev` preserve the initial reproduction and exploratory logs;
they are not final identity qualification. `checks.ms` resets a scene only in
`setup`, guarded by the task-specific owned profile. Failures are retained as
diagnostic files rather than relabeled as passes. The source fixtures are
bounded to 500 placement rows.
