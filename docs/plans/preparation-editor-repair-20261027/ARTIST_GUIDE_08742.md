# Preparing leaves around a fixed trunk — 0.87.4.2

Open **Interactions > Edit preparation** for the original plant source. The editor works on complete connected pieces. A source can contain thousands of bark fragments as well as its visible leaves; selecting everything and pressing Bend also asks those fragments to become stems.

For the reported Neottopteris Nidus Bush05 model:

1. Press **Select problem guides**. At the tested 50 mm Minimum stem and 1 mm Branch connection, this selects the 46 leaf pieces whose inferred parent connection failed.
2. Press **Prepare selected only**. Those leaves receive bending guides; the trunk and remaining pieces stay fixed. All original triangles are retained.
3. Inspect the green guides. Roots should be at the crown rather than the ends of drooping leaves. Press **Use preparation** to save the result for the layer's instances.

You can instead select the desired pieces by Click, Box, Brush or Same material. **Prepare selected only** intentionally replaces the draft's scope: everything outside the chosen set becomes fixed. One editor Undo restores the previous draft. Use the individual Bend, Follow stem or Keep fixed behavior controls when you want to change selected pieces within a larger existing preparation.

**Isolate** changes visibility. While isolated, **Prepare isolated only** prepares that isolated set even if the current selection has been cleared. **Show all** restores visibility and frames the full source. On the full source, **Automatic behavior** resets the selected pieces to normal inference; it does not restrict analysis to those pieces.

Failed preparation retains its guide/attachment counts and partial guides for inspection. **Select problem guides** is available when the report identifies unresolved guide pieces. It is not a general detector of every possible mesh defect. A failed draft cannot replace the previously saved preparation. Use Cancel to discard it.

## Editor navigation

- Choose **Orbit** or **Pan**, then drag with the left mouse button.
- Right drag or Alt+middle drag also orbits; middle drag pans.
- **Frame** or **F** frames the selected pieces, otherwise the isolated set, otherwise the full source.
- Wheel zoom keeps the plane point under the cursor in place. The framed orbit pivot remains stable after panning, and world up is preserved.

The popup displays the full original geometry. The layer's **Preview leaves / blades (%)** still controls its lightweight interaction preview; choose 100% when judging the complete scene geometry. Preparation and collider fit times are separate from viewport frame rate and the complete-mesh diagnostic's cost.

This workflow is useful when the trunk should remain fixed while its leaves react. A collider intersecting that fixed trunk or a fixed leaf root can still be physically impossible to resolve. Whole welded branching networks do not automatically become separate editable leaves; they still need supported geometry or separately authored guides. See the delivery report for the exact tested scope.
