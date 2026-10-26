# CyrusScatter 0.87.2 — tree colliders and rooted plants

Max 2027 artist-test workflow. Use the matching 0.87.2 MZP, restart Max, then open
the supplied saved trial copy. The original Small Test Interaction scene is kept.
Saved scenes use schema 61; preserve originals and do not save them through older
plugins. Analyzer and installed content keep their independent versions.

## Trees: keep the visual model and build a collider

1. Select the tree layer and enable **Collider**.
2. Click **Build trunk colliders**. Each unique source gets a small, closed,
   tapered trunk mesh; all of its instances reuse it. Full tree geometry remains
   unchanged in the viewport and renderer. Existing assigned proxies are retained.
3. Select a source in **Source model**, then **Review collider** to see a frozen
   overlay at a published instance. **Hide guide review** removes this overlay.
4. Use **Cyrus Edit** to move an individual tree. Its collision shape follows the
   same placement identity, position, rotation and supported uniform scale.

Automatic trunks are approximations of a tall connected component and its basal
section, covering the lower 35% of source height. Ground-reaching foliage is
excluded from the basal estimate. Curved or unusual trunks need review; the canopy
and every branch are not represented by this simple shape.

**Pick closed collider mesh** assigns a custom mesh to the selected visual source.
Author it relative to the original source/prototype, not an arbitrary scattered
instance: its transform relative to that source defines the shape. Generated
proxy nodes are named for the source, parented to it, hidden and non-renderable.
They remain saved scene references. Editing a proxy affects that source's
instances; it does not edit the visual model. Deleting a required proxy rejects a
successor and retains the preceding complete result; Undo can restore the link.

The automatic source scan is bounded to 4M vertices / 8M triangles. A custom proxy
admits 100k vertices / 200k triangles and must be closed after seam welding.
Custom/box collider capture does not copy the original high-poly tree first.
Closed source mesh mode retains its separate 1M-vertex / 2M-triangle source limit.
Bounding boxes remain an explicit coarse choice and can cover the whole canopy.

## Grass and flowers: analyze, review, accept

1. Choose a reacting layer's source. For a schema-60 scene, use **Repair preparation
   settings**, or let **Analyze model** request that repair before analysis.
2. Click **Analyze model** and inspect the green guides, planted bases and foliage
   attachments. The tested Arthropodium profile combines round flower stalks with
   dense ordered folded basal leaves; the grass uses ordered folded blades.
3. Click **Accept reviewed guides**, then enable **React to colliders**. Repeat for
   each distinct model. Different instances share the prepared source and keep
   independent poses. Unsupported/unresolved geometry is still rejected.

Tree colliders do not need plant stem analysis. The panel separates collider
construction from plant guide preparation. Analysis requires geometric review;
successful inference is not a guarantee of botanical correctness for other assets.

## Units and controls

The minimum source stem distance is stored in metres and displayed using Max's
world-unit controls. It applies to the original model before scatter instance
scale. The allowed range is **1–100 mm**; preview foliage is **1–25%**. Valid legacy
physical settings are retained. Invalid legacy minimums are repaired to **5 mm**,
with a notice and incompatible preparation cleared for a new review. Invalid
preview fractions restore 5%. No geometry is silently resized.

**Contact gap** on a reacting layer adds world-space clearance beyond its prepared
envelope. **Hide roots under colliders** suppresses covered rooted groups and
restores them when the obstacle leaves. Search bounds, root coverage and visible
clearance remain separate. **Preview leaves / blades** affects preparation of the
light preview; full visible source faces remain available to render/Bake.

The supplied scene retains its original physical scale: approximately 10 cm-high
Maple, 11 mm-high flowers and 2.5 mm-high grass. Millimetres are valid; those are
miniature scene dimensions. Decide intended real-world sizes before rebuilding
another scene. Display-unit labels alone do not resize geometry, and existing
Paint/Edit bindings retain their unit/rescale guards.

## Trial use and limits

The trial copy is prepared for its two tree sources, small grass and Arthropodium.
Choose the Trees layer and its Cyrus Edit modifier to move either tree. Pending
Manual amount/seed changes still require **Update scatter**. Mesh face budgets
can substitute boxes; use the supplied preview settings when judging full trees.

Prepared definitions and collider links are saved in the Max scene. Recipes and
Apply Style reject these links even with roles off, rather than losing data.
Separate lab/older-host reports retain their original scope. This remains static
rooted contact: no wind, inertia, two-way tree dynamics or plant self-collision.
Use the delivery report for exact package/scene identities, actual tests, measured
costs and open artist/renderer/soak acceptance.
