# Cyrus Presentation Studio



Private browser MVP **0.3.0**, built with Three.js, TypeScript and Vite. Import a prepared landscape, author its presentation locally, and export an independent static player. This application has its own package and builds; it does not modify or integrate with `website/` or the native Scatter products.



Read the maintained [implementation plan](../docs/plans/landscape-presentation/README.md), [dated research](../docs/plans/landscape-presentation/RESEARCH_2026-10-15.md) and [implementation evidence and remaining gates](../docs/plans/landscape-presentation/PROGRESS.md). Automated browser results are not physical-device certification.



The [camera desk follow-up](../docs/plans/landscape-presentation/CAMERA_DESK.md) documents resizable timeline height, safe-frame composition, Orbit/Plan camera review and measured viewport work.



The [BAILEY heavy-building delivery](../docs/plans/landscape-presentation/BUILDING_DELIVERY.md) contains the optimized 35.35 MiB GLB, prepared Max 2027 scene/camera, editable project and independently tested website ZIP. It records baseline comparisons, desktop performance and limits. The separate [scene preparation tool](tools/max2027/scene-preparation/README.md) reproduces the Max-to-GLB process with explicit recipes and an owned host.



## Run locally



Use Node **22.14.0 or later** and npm. From this directory:



```powershell

npm ci

npm run build:player

npm run dev:studio

```



Open **http://127.0.0.1:5190/**. Keep the terminal running. The studio is bound to loopback; it has no account/authentication server and must not be exposed publicly as an admin service. No API key or paid service is required.



The initial sample garden is an owned synthetic fixture. It demonstrates the presentation workflow and is not a claim of realistic planting quality or artist-scene capacity. Autosave can restore your previous local project on subsequent visits.



For the user's selected earlier model, use **Project > Open project** with [the prepared Botanical Islands project](exports/qualification/botanical-islands-project.cyrus-presentation.zip). It contains the unchanged original GLB, calibrated plan, six layers, the sixteen original route waypoints plus an overhead stop, and four artistic images. Its [standalone public ZIP](exports/qualification/botanical-islands-presentation.zip) is also ready to unpack and serve. These generated local files are ignored by Git.



`npm run build` typechecks, builds the public player, embeds that exact player shell for compilation, and builds the studio into `dist/studio/`. `dist/player/` is a reusable player shell, not a complete landscape presentation: it needs the manifest and assets produced by **Export website**. Rebuild the player before rebuilding the studio after player changes.



## Author a presentation



1. Choose **Project > New project**, or explore the sample. Open **Scene** for assets, layers and the plan. Set **Import orientation & units** before importing a self-contained `.glb`. Standard glTF uses metres and Y-up; only change these controls when the prepared source genuinely uses another convention. Select an asset to edit its root position, quaternion rotation and uniform scale.

2. Assign imported groups/nodes to presentation layers. Children inherit their nearest assigned ancestor unless explicitly overridden. A merged mesh cannot be separated into species/layers here; prepare that separation upstream. Names are labels; project IDs and revision-scoped node records retain identity.

3. Set each layer's initial visibility, inclusion in export, viewer-toggle permission, reveal start and reveal transition. Excluded content is pruned from the public GLB. Included hidden optional layers can still be shown by the viewer when permitted.

4. Import a PNG/JPEG/WebP plan. In **Plan**, enter two pixel correspondences, their metric separation, world origin and rotation. An optional third correspondence reports alignment error. This is manual calibration; a photographed drawing may need upstream perspective correction.

5. **Camera** is the default viewport mode. Left/right drag looks around; **middle drag** or **Shift + left drag** pans; the **mouse wheel** moves forward/backward through the scene. Click the viewport to use **WASD** movement and **Q/E** height. **Shift** increases movement speed. The right camera inspector holds the live field of view and movement speed. Wheel movement preserves the lens; use Field of view to change it. **Capture view** saves the visible perspective position, orientation, lens and frame aspect at the playhead time. Capturing at an existing editable key updates that key. Move the playhead before composing the next view. Navigation alone leaves authored cameras unchanged. Select a saved view and choose **Edit in viewport**, move to the revised view, then use the same top button, now **Save view**. The toolbar names the editing owner even if another view is selected. Its dropdown offers **Capture as new view** and **Finish editing**. Use **Orbit** for object-centred navigation (left drag orbit, right/Shift-left drag pan, wheel/middle drag zoom). **Plan** uses left/right drag to pan and wheel/middle drag to zoom; it cannot capture a different hidden perspective camera. Numerical pose/orientation and path handles remain in collapsed detail sections. Each capture/save is one undo command.

6. The stacked **Timeline** has a ruler, camera diamonds, and a visibility track for every presentation layer. Move the playhead, choose **Compose at playhead**, navigate the viewport, then **Capture view**. Drag diamonds to retime; Shift-click selects several, and Escape cancels a drag. Snap uses frames; Zoom expands the time axis. Choose Linear, Ease or Hold for motion to the next camera key. Expanded Position/Orientation/Lens rows are linked full-pose keys. Track eye controls add Show/Hide keys at the playhead. Ctrl/Cmd+C/V, Delete and undo work within the timeline. Its options menu contains frame rate, duration, restart, reverse and reduced motion. **Focus** hides side panels and keeps the timeline; its collapse control frees more viewport space. Scene, Focus, zoom and selection affect only the workspace, not the saved project. Drag the separator above Timeline to see more layers; arrow keys adjust its height and double-click restores the default. Collapse retains the chosen height. Play, reverse, restart and scrub in **Orbit** or **Plan** to watch the moving camera/frustum/path without changing your observer view. Choose **Playback** explicitly to see through the saved camera. Pause before Capture or Save. **Frame** selects a composition aspect (FHD 16:9, Vertical 9:16, Square, 4:3, Cinema or free viewport) and toggles 90% action / 80% title safe guides. These are aspect presets, not fixed pixel output resolutions. Capture stores this aspect; playback of an imported Max camera retains its recorded frame. The inspector’s Presentation frame control still selects saved landscape/portrait compositions. Leaving playback restores the temporary editor camera. Reduced motion uses discrete views instead of automatic travel. The public player uses native scroll, stop buttons, keyboard arrows, play/pause and restart; it has no free-orbit editor.

7. Optionally import an artistic photo for a selected key and a portrait variant. Set **Hold at key · seconds** inside Artistic impression; a hold must fit before the next camera key. A hold at the final key extends the presentation duration. Review it, then **Approve for current scene**. It is publicly labelled **Artist impression**. Scene/pose/framing/visibility/lighting changes stale the approval; camera timing changes do not. Layer visibility keys change the approved scene and require review. A stale photo must be approved again or removed before export. Viewer layer changes immediately yield to the actual 3D scene while visibility differs from the approved image.

8. **Project > Save project** downloads an editable portable ZIP. **Project > Open project** restores it, including originals, IDs, calibration and authored settings. **Restore autosave** is also in Project. Autosave is local browser storage, not a substitute for this backup.

9. **Output > Compiled preview** runs the actual built public player. **Output > Export website** downloads a separate ZIP containing only the public player, manifest, prepared resources, notices and hosting instructions.



Changing a GLB is an explicit **Replace GLB…** action. Review persistent-ID or unique-path suggestions and resolve every new node's layer. Confirmation retains root transforms, world cameras and layer IDs through that mapping. Undo restores the previous revision. Invalid/cancelled preparation retains the previous complete scene.



Camera movement keys operate only while the viewport canvas has focus. Clicking a text field, leaving the window, hiding the tab or changing mode stops movement; **Escape** stops and releases viewport focus. Camera view is free flight, with explicit height control; it does not add collision avoidance or terrain following. Capture and Save remain explicit, so a navigated draft does not change the saved project or an approved image until committed.



The **Controls** menu lists gestures for the current viewport mode. Space activates a focused menu/button normally; with the viewport focused, Space toggles playback. Ctrl/Cmd+Z undoes an authored change outside text inputs. Viewport gestures are disabled during playback and compiled preview.



See the [timeline contract and current verification](../docs/plans/landscape-presentation/TIMELINE.md) for persistence, protected clip behavior and limits. Independent property curves, curve editing, arbitrary clip retiming and camera cuts remain deferred.



## Import an animated Max camera



Run [CyrusCameraExporter.ms](tools/max2027/CyrusCameraExporter.ms) in **3ds Max 2027 > Scripting > Run Script**. Choose a native Free, Target or Physical camera, frame range and sampling rate, then export JSON. In the studio use **Project > Import camera animation…**, review, and **Use camera animation**. No Max install or restart is required.



The imported camera retains world motion, roll, lens changes, source timestamps and render aspect. It replaces the journey in one undoable change; the plan/reveal introduction stays before it. Use matching GLB scene origins and avoid subsequently moving the landscape root. Scrub/play/reverse the track; **Use frame in viewport** lets you navigate from a frame. Capture additional editable camera keys outside the protected clip; extend the timeline duration in its options menu when needed. Its endpoint diamonds and time range cannot be moved, split, or retimed. Source motion controls stay read-only. Removing the animation explicitly restores an editable straight path between its endpoints.



See [exporter instructions and supported limits](tools/max2027/README.md) for sampling accuracy, supported projections, file format and reproduction. Studio/player 0.3.0 reads schema 1/2 archives without changing their old timing. The first timeline edit saves schema 3 with absolute camera and layer keys (camera format 1 / Max exporter 0.1.1 unchanged). The separate sampled JSON survives autosave, portable save/reopen, compiled preview and standalone output. Animated GLB scenes remain unsupported.



## Use the exported website



Unpack the **complete ZIP** into a separate folder. Serve it through HTTP/HTTPS; opening `index.html` with `file://` is unsupported. For example, in the extracted directory:



```powershell

python -m http.server 5193 --bind 127.0.0.1

```



Open `http://127.0.0.1:5193/`. Uploading that complete folder to a static host also works under nested paths such as `/presentations/courtyard/`. Publishing is a separate action; this implementation does not deploy or alter the existing website.



The player runs without the studio, login, cloud API or collaboration service. Layer choices are session-only and resettable. Public assets are downloadable browser resources; the absence of editing UI is not an asset-encryption or licensing system. Without WebGL2, or after a failed 3D load, it retains the plan and available artistic views and disables unavailable 3D layer controls.



## Supported input and bounds



The admitted runtime subset is static, self-contained GLB 2.0 with standard metallic-roughness materials, embedded PNG/JPEG/WebP, alpha mask/blend, normals, unlit materials, texture transforms, quantized attributes, bounded `EXT_meshopt_compression` and preserved `EXT_mesh_gpu_instancing`. Meshopt uses Three.js's bundled decoder; declared ranges and decoded sizes are checked before allocation, then decoded indices and positions receive numeric admission. Public layer pruning keeps the compressed payload. Required Draco and KTX2/Basis are rejected until their decoders and roundtrips are qualified. External URIs, animation, skins, morph targets and sparse accessors require upstream static preparation. Optional unsupported appearance extensions produce a warning.



Starting protective limits include 250 MiB per input/compressed archive, 512 MiB expanded archive/resources, 8192-pixel input image edges, 32 MiB separate plan/photo files, 10 million submitted source triangles, 100,000 nodes per asset, 500,000 admitted scene node visits, 8 MiB project metadata and 16 MiB retained undo metadata. Limits are also constrained by estimated decoded resources and successor preparation headroom. These ceilings are not promises that an arbitrary asset at the ceiling will render on a phone.



Balanced caps DPR at 1.5 and admits an estimated GPU budget of 384 MiB; Mobile caps DPR at 1 and uses 192 MiB with lighter shadows and smaller image derivatives. Adaptive resolution uses sustained thresholds and hysteresis. Neither profile changes authored density, count, positions, layers or timing. GPU estimates include shared resources, instance buffers, render targets and bounded image reserves; they are not measured driver VRAM.



Import/packing runs in owned workers where supported. One heavy operation is admitted at a time, and stale results cannot commit. Cancellation terminates those workers; third-party GLTF parsing/image/GPU preparation has bounded admission but may finish its current main-thread operation before cancellation can be observed. Browser storage availability and quota vary; an explicit error leaves portable save available.



Procedural planting, density/region/mask/terrain editors, per-plant overrides, customer accounts, cloud storage, collaboration, image-generation providers and commercial licensing remain deferred.



## Prepare and verify assets



```powershell

npx tsx tools/make-fixtures.ts

npm run prepare:asset -- exports/fixtures/medium.glb exports/fixtures/medium-prepared.glb

npx tsx tools/check-prepared.ts exports/fixtures/medium.glb exports/fixtures/medium-prepared.glb

npm run verify:export -- exports/presentation.zip

```



Preparation preserves the source, deduplicates/welds/prunes resources, resizes supported textures and quantizes geometry. Use `--mobile` for the smaller texture recipe; `--force` explicitly permits overwriting an existing derivative. It does not thin plants, simplify meshes or move roots. A prepared file may be larger when the source is already compact. The geometry verifier checks persistent IDs, instance-row count, triangle count and global world bounds within 2 cm; it does **not** yet prove equality of every vertex or plant transform. Review real assets visually before substituting their derivatives.



The export verifier checks bounded ZIP structure, CRC/lengths, schema/player version, relative paths, excluded private files and resource hashes. Actual rendering and interaction are covered separately by browser tests.



## Tests and evidence



```powershell

npm run typecheck

npm run test:unit

npm run test:integration

npx playwright install chromium firefox webkit

node tools/fetch-test-assets.mjs

npm run build

npm run test:browser

```



The optional fixture fetcher downloads three Khronos GLBs and their legal/readme files into ignored `exports/fixtures/khronos/`; the compatibility test explicitly skips if they are absent. [Fixture provenance](fixtures/README.md) identifies sources and observed hashes. Foreign fixtures are test inputs, not product assets.



To reproduce the previous-study acceptance fixture while that source is available in this checkout, run `node --import tsx tools/previous-study-fixture.ts`, then `npx playwright test previous-study.spec.ts`. This reads the prior study and writes only this app's ignored exports. Use `$env:CYRUS_TEST_CHANNEL = 'chromium'` to select full Chromium's newer headless mode for local hardware-accelerated desktop checks; the default test shell used software graphics on this machine. The selected run identified the RTX 3090 explicitly. A fast result on that GPU does not qualify mainstream integrated graphics.



For another engine, set `$env:CYRUS_TEST_BROWSER = 'firefox'` or `'webkit'` before `npx playwright test`; remove that environment variable afterwards. The test server uses loopback port 5190 and reuses the already running owned studio. Playwright WebKit on Windows is not Safari/iPhone qualification.



A production benchmark is available after a build:



```powershell

node --import tsx tools/benchmark-production.mjs 600

```



It opens the production studio, exports the sample, closes the studio, cold-loads the independent public artifact at 10 Mbps/80 ms, and repeats its camera journey for the requested seconds. Results, exact ZIP, screenshots and hashes go to ignored `exports/qualification/`. RAF intervals are not presented FPS; JS heap excludes native/image/driver memory; a local desktop run does not establish physical-phone or thermal acceptance. The maintained evidence record states which gates remain open.



Vite currently reports the player/studio main chunks above its 500 kB warning threshold. The warning is retained. Compressed transfer, useful opening and actual rendering are measured separately instead of treating chunk size alone as qualification.

