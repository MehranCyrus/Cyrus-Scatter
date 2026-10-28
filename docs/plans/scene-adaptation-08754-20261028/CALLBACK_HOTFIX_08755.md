# 0.87.5.5 — application callback scope correction

The user reported `Unknown property: count in undefined` from the installed
0.87.5.4 `liveTimeChanged` handler. In a fresh owned Max 2027 profile using the
unchanged delivered MZP, a new controller's real scene-collider list has count
zero, while directly calling this handler reproduces that exception.

The handler precedes the appended interaction parameter/local declarations.
Unqualified `interactionSceneColliders` and `interactionSceneDirty` therefore
bind forward globals instead of controller members. Explicit `this.` access
fixes both reading the reference list and marking the correct controller dirty.
A transitional undefined list is treated as empty. No exception is swallowed
around the application callback and no artist state is reset.

The successor is **0.87.5.5**, following the version policy for a changed build
after delivery. Scene 64, Interactions 14, source Undo 2, source transform 2,
Edit capability/storage 4/3, portable recipe 9 and Scene preset metadata 1 remain.
Independent products remain unchanged. Preserve the original 0.87.5.4 artifacts
and test receipts; their completed checks missed this callback path.

Regression acceptance: explicit handler calls on a fresh empty controller,
disabled/Manual/Live behavior, time callbacks, a real enrolled scene reference,
removal, a loaded grass field, and source/instance changes. Qualify the matched
Max 2027 pair and package distinct Max 2024/2026 payloads without running those
older hosts, consistent with the user's existing test waiver. Update the public
site to the corrected EXE, with clear runtime scope, and prepare a local upload
bundle. No artist installation, host publishing or Git push is authorized.

## Delivery and evidence

- [Combined EXE — Max 2024, 2026 and 2027](../../../dist/CyrusScatter-0.87.5.5-20261028/CyrusScatter-0.87.5.5-Setup.exe)
- [Max 2027 MZP](../../../dist/CyrusScatter-0.87.5.5-20261028/CyrusScatter-0.87.5.5-Max2027.mzp)
- [Exact qualification and hashes](QUALIFICATION_08755.json)

Save work and close selected hosts for the EXE, install, then reopen Max. The
MZP alternative uses **Scripting > Run Script**, followed by a restart. Use the
complete matched package. The EXE is unsigned and keeps existing independent
Library content and Analyzer installations.

The exact Max 2027 package passes 62 native suites and 577 Python checks. Owned
automatic installed startup verifies loaded script/native identities. The same
direct regression which reproduces the old error now passes on fresh empty,
disabled, Manual and Live controllers, time callbacks and collider add/remove.
The real 1,000-grass trial also passes direct application/node/time callbacks,
wall movement, pending Manual population preservation and empty-layer creation.

Max 2024/2026 are compilation/package only. No older host was launched or tested.
No artist profile was installed or restarted. This patch changes callback scope
and metadata; it does not rerun every earlier plant, physical-drag or renderer
campaign. The broader numerical/viewport observations retain their 0.87.5.4
labels. Full renderer, arbitrary topology, animation/soak and million-object
realtime limits remain unchanged.

