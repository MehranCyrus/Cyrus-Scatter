# Physics Lab 0.1.8 — mountain testing guide

18 October 2026. Max 2027 only. This is the independent Physics Lab.

The final kit is in `dist/CyrusPhysicsLab-0.1.8-20261018-03/`:

- `CyrusPhysicsLab-0.1.8-Max2027.mzp`: the matched installer.
- `PhysicsLab-0.1.8-Mountain-Test.max`: a clean Lab ready for brushing.
- `PhysicsLab-0.1.8-Mountain-Results.max`: frozen diagnostic comparisons.
- `README-TESTING.md`: portable usage notes.

## Open and brush

1. Freeze/save any previous pending Lab session, then save your work.
2. Run the MZP through **Scripting > Run Script**, then restart Max 2027.
3. Open **Mountain-Test.max** and select **PhysicsLab_Brush_Ready**. Its icon is
   above the mountain. Use Scene Explorer if needed.
4. In **Objects > Models**, tick the models you want. All/None/Solo change the
   palette; the highlighted row targets the collision controls.
5. In **Collision and proxies**, choose Fast, Balanced or Detailed. The default
   scene has all three models in Detailed: convex pyramid/sphere keep one hull;
   the concave teapot uses up to 16 pieces. Show collision shapes is enabled.
6. Start brush, drag on the mountain, release and draw again while bodies move.
   Outside the receiver emits nothing. Existing bodies can still roll off its edges.

The actual receiver is 250 m across. The original pyramid is 10.462 m tall, the
Sphere32 radius is 0.6 m and teapot radius 1.2 m. Tested defaults include friction
0.6, bounce 0.05, grip 0%, scale 0.8–1.2, 1.5-m spacing and a 1,000-body limit.
Source meshes are hidden; unhide them through Scene Explorer to inspect them.

## Controls to try

- Use Solo on the sphere, then All to compare mixed brushing. Disabling a source
  keeps existing scattered bodies and material assignments.
- Compare Fast/Balanced/Detailed on the teapot in an empty Lab. Higher quality
  gives a tighter exterior, but the 16-piece cap still fills its handle opening.
  Volume error is not a distance tolerance. A custom single hull also fills holes.
- Pause preserves the world. Undo/Redo stroke restores full live motion state.
- Finish tries to settle within a finite bound. Freeze keeps current positions,
  including moving bodies. Low-grip hillside rolling may require Freeze.
- Finish/Freeze/cancel before editing palette or shapes. Shape changes to a
  completed result require Rebuild all strokes or Clear.
- Open logs preserves the diagnostic workflow if a problem occurs.

Mountain-Results.max contains intentionally Frozen snapshots; some bodies were
moving when captured. Use the clean Test scene to start your own experiment.

The [technical report](COLLISION_QUALITY_018.md) and
[evidence](COLLISION_QUALITY_018_EVIDENCE.json) distinguish measured behavior,
remaining accuracy/settle limits and untested physical mouse/pixel behavior.
