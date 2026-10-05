# Source containers: private Max 2027 preview

The launcher source is tracked here. Runtime profiles and scenes are written under `build/user-tests/source-containers-20261005/`, which remains ignored. Python must be available as `python` on PATH. The pinned local qualification files under `build/qualification-07-20261005/final02/` and `build/mcp-qualification/procedural07-ui-final02-ordinary/` are prerequisites, not part of the Git backup. This preserves the launcher code; a new machine still needs its own matching build and qualification.

Double-click `Launch_Source_Containers.cmd` in File Explorer. This opens a separate Max 2027 process with the verified ordinary 0.7 script and four matching DLLs. It creates a fresh private profile and demo for each launch. It does not install into or replace your normal Max profile, and does not close another Max process.

The demo has a receiving plane, a rectangle with a tree-shaped cone and shrub-shaped sphere, and 64 scattered instances. The Scatter controller is selected and Live is enabled. These primitives are demonstration assets, not your artist models.

1. In Modify, expand `Layer_01`, then **Source containers**, between **Procedural / Rules** and **Statistics / help**.
2. Its **Source pool** is **Layer containers**. **Create rectangle** makes another container; **Pick rectangle** uses an ordinary Rectangle spline.
3. Move the original cone's pivot outside the blue rectangle. Its scattered instances disappear after the scene-event batch. Move it back; its settings and source identity are retained.
4. Select the Scatter controller again to change source settings in **Plant assets**. Keep source rows registered when temporarily parking models.
5. For a shared pool, use **Surface Scatter > Global source containers > Create source rectangle**, and choose **Global containers** in each participating layer's **Source pool**.

Height is ignored; the source pivot determines membership in rectangle-local XY. In Manual mode, press Update to publish changes. The rectangle selects source models; receiving surfaces determine where instances grow. New sources added after saved CS Edit changes may encounter the existing binding guard.

Each session's scene is saved under `build/user-tests/source-containers-20261005/sessions/<session>/project/scenes/Source_Containers_Demo.max`. Use a copy of your own scene for experiments. These are private development files; no new MZP was built. The launcher uses this machine's existing Python runtime and Max installation, not a portable customer installer.

The local `build/user-tests/source-containers-20261005/smoke-test.json` records a fresh private startup check; earlier full feature/UI qualification is in `docs/Independent_Review_0.7_2026-10-05/IMPLEMENTATION_RESULTS.md` in the repository. This launcher does not load the development script transport or run the regression suites in your interactive session.

The first startup attempt stopped at a bootstrap class-name binding check. After declaring the loaded script class as a global, a new session passed module/script loading, source registration, parking/reentry and normal exit. This does not add new pointer/DPI coverage. The first startup of a fresh profile can take about a minute.
