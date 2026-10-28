# CyrusScatter 0.87.5 — interactive plant display

Install the Max 2027 MZP with **Scripting > Run Script**, then **restart Max**. Use
the complete package so the script, native modules and Gallery match. This delivery
is for Max 2027. The dated delivery contains package identity and test scope.

The normal workflow is unchanged:

1. Give the stone/sphere layer the **Collider** role. Keep the full visual model;
   trees can use a separate lightweight trunk or custom closed proxy.
2. Give the plant layer **React to colliders**. Select its original source and use
   **Prepare model**. Preparation is shared by all its rotated/scaled instances.
3. Use **Edit preparation…** when automatic inference needs a correction. For a
   plant with a rigid base, select the leaves to bend and keep its base fixed.
4. Choose **Mesh** or **Textured mesh**, then use **Cyrus Scatter Edit** to move a
   collider instance. Nearby plants update automatically during movement.

The displayed geometry is still made of polygons. Max keeps one shared source mesh
on the GPU and deforms its instances from compact stem poses. It no longer needs to
build a separate triangle batch for every bent plant on every move. Final render
and Bake geometry use the same accepted poses through the existing CPU mesh path.

## Controls that matter

**Preview leaves / blades (%)** controls displayed source foliage. Use 100% to
inspect the complete plant, or lower it for a lighter view. It is not a percentage
of stems allowed to interact. Existing saved percentages are preserved.

**Contact gap** controls bending clearance. **Hide margin** independently expands
root exclusion when root hiding is enabled. **Inside solid** checks actual solid
occupation; **Under collider** also clears roots below the collider's footprint.
These do not detach a fixed root so it can move freely through an obstacle.

**Minimum stem** and **Branch connection** affect preparation. Extremely small
minimums can mistake small details for stems. The tested large Brainea fern used
5 mm minimum and 15 cm connection reach; those are example settings, not a universal
botanical preset. Unresolved guides still need review instead of forced acceptance.
At 100% preview, that fern also needs a Preview triangles allowance of at least
600,000; the supplied test used 2,000,000 in Preparation limits.
**Refinement stiffness** affects contact fitting. Supported setting changes retain
the automatic update behavior from the preceding versions.

Use the viewport triangle budgets for dense gardens. More shared instances consume
less duplicated geometry, but drawing millions of visible triangles and solving
many simultaneous contacts still takes time. First preparation and the first GPU
upload can be slower than subsequent movement. F3 Wireframe works with both mesh
modes. Save/reopen rebuilds derived display buffers normally.

Use a copy of your scene for testing. The supplied grass and fern scenes contain
prepared examples; select their collider layer's instance in Cyrus Scatter Edit
and move it through the leaves. Existing source preparation, library, Hide margin
and recipe workflows remain available.
