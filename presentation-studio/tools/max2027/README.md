# 3ds Max 2027 camera exporter — 0.1.1

In **3ds Max 2027**, choose **Scripting > Run Script** and open [CyrusCameraExporter.ms](CyrusCameraExporter.ms). No installation or Max restart is needed. This standalone tool does not load or change the Scatter plugin.

1. Choose a native **Free**, **Target** or **Physical** camera.
2. Set the start/end frames. Defaults come from the scene animation range. Both endpoint poses are included; elapsed duration is the difference between their native times, without an extra end-frame hold.
3. Keep **4 samples per frame** for most camera work. The 1× and 2× settings reduce file size for longer/simpler motion.
4. Choose **Export camera animation…** and save a `.json` file.
5. In the studio, choose **Project > Import camera animation…**, select that file, review its duration and framing, then **Use camera animation**.

Export your static landscape GLB from the same scene origin and world placement. The camera exports world coordinates in metres, Y-up: Max `(X,Y,Z)` becomes `(X,Z,-Y)`. A standard glTF landscape already follows this convention. Do not apply a second Z-up conversion to a standard glTF file. If you move/rotate/scale the landscape root afterwards in the studio, the world-space camera does not automatically follow it.

Import replaces the camera journey in one undoable change; assets, layers and plan stay in place. The clip has two endpoint views, zero automatic holds and one continuous track with its original duration. The existing plan opening and landscape reveal play before the clip. Set their durations to zero if you want the camera animation to begin immediately.

Scrub or play the imported track, including reverse. **Use frame in viewport** opens the currently evaluated frame for navigation; **Capture view** saves at the playhead. Add editable keys outside the protected clip range; extend duration in Timeline options if needed. Captures inside the clip are rejected to protect the source motion. Imported source motion remains unchanged. **Animation options > Remove animation** replaces the clip with the ordinary editable straight path between its endpoint views; Undo restores it. Names remain editable, while imported pose/lens/portrait/path/timing controls are read-only. Save project and Export website both retain the sampled motion resource.

## Fidelity and supported scope

The exporter reads the evaluated world transform at each native tick sample. Animated parents, camera targets, roll and path/other controllers therefore do not need a separate browser rig. It reads native evaluated horizontal FOV, including Physical focal length/zoom/focus breathing, and converts it to vertical degrees using render width, height and pixel aspect. The camera frame aspect remains fixed in portrait and landscape output; the viewer letterboxes instead of inventing another composition.

Playback uses original sample timestamps, linear position/FOV interpolation and shortest-path quaternion interpolation. It does not run the studio's Bézier constant-speed or easing calculations on imported tracks. Forward, reverse and random seeks evaluate the same data. A sampled track is an approximation between samples; default 4× sampling preserves all native frame times at the qualified 30 fps. Very fast turns, discontinuous controller changes or unusual frame rates need visual review and suitable sampling. This version does not encode explicit camera cuts: use separate presentations for discontinuous shots.

Supported bounds: 4 MiB per file, 2–20,000 samples, up to one hour, vertical FOV 10–110°, aspect 0.3–4, 100,000 distinct active camera samples per project. Native sample ticks remain authoritative when frame rates do not divide 4,800 ticks/second evenly. The file's FPS is descriptive; playback never reconstructs time from frame index.

Orthographic projection, mirrored/nonuniform/sheared rigs, Physical lens shift/tilt/correction/distortion and third-party camera classes are explicitly rejected. Bake a third-party camera's evaluated pose and lens to a supported native camera upstream. Renderer exposure, DOF, motion blur, lens effects, custom clipping planes, environment and render materials are not transferred; this is camera movement/lens import, not Max render parity. The scene's time, selection, animation keys and render settings are not changed by exporting. Output is staged and atomically replaced only after every sample has passed.

## File and version contract

The closed UTF-8 JSON format is `cyrus-camera-animation`, version 1, with canonical metres/Y-up, render aspect/FPS, bounded Max 2027 source-range metadata and samples `{time, position, quaternion, fov}`. Quaternions use Three.js `[x,y,z,w]`, camera looks down local `-Z`, up is local `+Y`. The exporter does not gather scene filenames, absolute paths or executable scripts; only the chosen camera label and sampled data are carried. The file is immutable and SHA-256 addressed in author archives and public output.

Studio/player are **0.3.0**; the independently versioned Max camera exporter remains **0.1.1**. Existing camera-bearing schema **2** and ordinary schema **1** projects remain readable. Explicit timeline edits save schema **3** with absolute camera and visibility keys; older studios reject that schema. The camera JSON format and public manifest remain version 1; public `playerVersion` is 0.3.0 and must match the built shell. Native Scatter numbering and installers are separate.

## Reproduce the owned host test

From the repository root:

```powershell
python presentation-studio/tools/max2027/host-workflow.py launch
python presentation-studio/tools/max2027/host-workflow.py status --session <returned-run-directory>
python presentation-studio/tools/max2027/host-workflow.py qualify --session <returned-run-directory>
python presentation-studio/tools/max2027/host-workflow.py status --session <returned-run-directory>
python presentation-studio/tools/max2027/host-workflow.py collect --session <returned-run-directory>
```

Wait for `ready.txt` before qualification and for the exact queued request's `SUCCESS` plus `qualification-complete.txt` before collection. The launcher creates a hidden, separate Max 2027 process with isolated directories and no Scatter native payload. **qualification.ms resets its disposable scene; never run it in an artist's session.** Collection preserves real native exports, independent evaluated basis references, hashes and checks under ignored `exports/fixtures/max-camera` and `exports/qualification/max-camera`.

Then, from `presentation-studio/`:

```powershell
npm run test:unit
npm run test:integration
npm run build
$env:CYRUS_TEST_CHANNEL = 'chromium'
npx playwright test
npm run verify:export -- exports/qualification/max-camera/botanical-camera-presentation.zip
```

The native integration cases skip when the generated Max fixtures are absent; the camera browser workflow requires them and the previous-study fixture. Generate the latter with `node --import tsx tools/previous-study-fixture.ts`. After testing, close only the owned process with `host-workflow.py close --session <returned-run-directory>`. Historical frozen camera-focus/mouse-control receipts remain separate.

Native API references: [camera FOV and projection](https://help.autodesk.com/cloudhelp/2027/ENU/MAXScript-Help/files/3ds-Max-Objects-and-Interfaces/Node-MAXWrapper/Node-Subclasses/Camera-Node/GUID-17350E60-DF84-4B3F-8A4D-772914FF2A1C.html), [Physical camera properties](https://help.autodesk.com/cloudhelp/2027/ENU/MAXScript-Help/files/3ds-Max-Objects-and-Interfaces/Node-MAXWrapper/Node-Subclasses/Camera-Node/GUID-14D75437-7ED8-46D9-9A74-2C495A7BAFF8.html). The native glTF exporter does not carry this camera animation; the separate camera JSON is intentional.
