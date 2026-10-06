# Isolated 0.7.1 Layer Editor preview

Run `Launch_Preview.cmd` on this workstation. It opens a **new Max 2027 process** with a disposable two-layer scene and the floating editor already open. Existing Max windows remain separate. No installer, normal-profile change or development command transport is used.

The launcher requires the locally qualified `build/ui-071/final01` artifacts and checks the exact script and all four native module hashes. It also verifies the actual loaded module paths before loading the script. A fresh Git checkout needs its own native build and qualification; the ignored DLLs and scenes are not source files.

In the demo, select **Cyrus 0.7.1 - Select me and Edit layer**. In Modify → **Layer Manager**, click **Edit layer** or double-click a layer. The top Layer and Paint set selectors keep the current owner explicit. Models and source rectangles are under **Assets**. Population, Paint, Transform, Spacing and Statistics each have their own topic. Resize the window or scroll each column independently. Advanced tools expand in place.

Global receiving surfaces, Manual/Live, Update and viewport/render controls remain in Modify. The floating editor stays attached to its layer when you select a scene model. Spacing fields save automatically when committed. Manual mode waits for **Update setup**; Live schedules calculation. Merely opening pages, resizing or refreshing fields reads cached data.

Close the separate Max window when finished. The preview's profile, scene and logs are under `build/user-tests/layer-editor-071/<session>/`.

For maintainers:

```powershell
python tools/procedural_lab/layer_editor_071/preview.py --verify-only
python tools/procedural_lab/layer_editor_071/preview.py --smoke-test
python tools/procedural_lab/layer_editor_071/qualify.py --run <new-id> --native-build build/ui-071/native01
```

Qualification freezes source, checks generation and MCP tests, verifies native identities, then runs the Max fixtures. `--reuse-session` requires identical script/module hashes and the exact private process command line. Pointer evidence is recorded separately; a scripted fixture pass does not certify visual layout. After qualifying a changed candidate, deliberately update the preview's pinned path and hashes.
