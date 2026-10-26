# Vegetation Preparation Lab 0.3.1 — Max 2027

This corrective independent prototype improves root and branch connectivity. It supports the tested Lavender 01 and Lavender 05 ordered-tube assets. It is separate from CyrusScatter and does not implement wind, time integration or a general tree rig.

## Try Lavender 01 from scratch

Run the MZP through **Max 2027 > Scripting > Run Script**. Save and restart Max if an earlier Stem Lab is loaded, then run the installed **OpenLab.ms** for your own scene or **OpenTest.ms** for the supplied prepared test. The portable launchers also work; keep the kit together. They verify hashes and reject a different loaded native pair before loading another class registration. This prototype reads scenes saved by its matching 0.3.1 kit; keep older scenes and kits as separate copies.

For a new source:

1. Select the plant and click **Add selected model(s)**.
2. Click **Analyze model**. Minimum stem length and preview foliage settings apply when you analyze; defaults are 5 mm and 5%.
3. Inspect the guide overlay. **Orange** marks grounded guides, **green** connected branches, and **red** unresolved guides. The panel reports root and unresolved counts. Unresolved elevated stems block preparation; they are not automatically pinned as roots.
4. Click **Accept reviewed guides**, then **Create test sphere** (or pick a complete standard Sphere).
5. Click **Prepare interactive model**, then **Select collider to drag**. Turn off the guide overlay to inspect the bent mesh alone; the overlay shows the analyzed rest structure.

**Pause interaction**, **Full viewport geometry** and **Validate full mesh** are available. Rendering/conversion request full source topology; the lighter preview is approximate. Rooted fitting starts from rest for each collider change and includes a bounded child-socket hinge fallback. A failed successor retains an earlier pose and reports an error; that retained pose can be stale relative to the collider.

## What changed

Lavender 01 contains three independent basal clusters. The old single-root, source-predecessor rule connected two of them across about 86.6 mm of open space and rejected the model. The revised analyzer detects the basal plane from thicker tubes, identifies grounded shoots, and builds a bounded spatial forest using tube endpoints, local radii and taper. Parent guides can appear anywhere in the source mesh. A separate parent-before-child traversal controls preparation and fitting; stable guide/component IDs remain unchanged. Taper prevents attaching a visibly thinner tip as a branch base. The 25 mm connection ceiling was not increased. Native output creation also explicitly uses an identity world transform, including after Sphere creation in a Front viewport, so the plant stays aligned with its analyzed guides.

For Lavender 01, native analysis finds 560 guides, three grounded roots, no unresolved guides and a maximum branch attachment near 4.98 mm. Default preview: 44,086 triangles; full source: 365,902 vertices / 563,380 triangles. Lavender 05 retains 1,290 guides, one grounded root and a 69,736-triangle preview from 832,240 full triangles.

## Limits

The source still needs recognizable separated round tubes with consecutive vertex rings and corresponding connectivity. Geometry/taper infer anatomy; visual review remains necessary. The basal-plane heuristic assumes an upright plant in Max's Z-up world. Severely cropped, horizontal, top-heavy or ambiguous plants may require another profile or future authored-guide tools. There is no manual guide editor yet. "Connections need review" means inference or another explicit admission condition failed; it does not prove that manual rigging is the only solution.

Keep source geometry, transforms and system units unchanged after preparation. Source edits require Analyze/Review/Prepare again. Move the collider; the UI locks prepared output transforms. Use a complete standard Sphere with uniform positive scale and no modifiers, Hemisphere/Slice/Base-to-Pivot off; admitted radius 1 mm–2 m. Test clearance is 1 mm with an internal fitting guard.

Eight monotonically allocated model slots are available per catalog. Removing a row keeps scene objects and supports Undo, but does not reuse its ID. Source bounds: 1M vertices, 2M triangles, 40k parts, 2048 guides, 160k preview triangles. Connectivity retains at most eight parent candidates per endpoint (32,768 overall); candidate search is bounded by admitted guides/spans and cooperatively cancellable. One analysis worker/catalog consumes copied numbers; host capture/publication remain on the Max thread. Metadata is limited to 16 MiB/model and serialized catalogs to 32 MiB. These are payload/work bounds; process peak memory and total history/catalog pressure are not measured.

Simple test materials are supplied. Original Corona materials, textures/opacity, explicit normals and arbitrary renderers are unqualified. Rigid foliage holds shape well in the executed tests, while thin stem triangle edges can distort significantly under stronger bends. Sphere clearance does not certify tube volume preservation. See **REPORT_031.md** for actual execution, timing, distortion and remaining acceptance, including sustained mouse-held publication and cold missing-source recovery.
