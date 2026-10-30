# Retained geometry selection

`PreviewGeometry.pickRows` maps each shared source instance back to its published
placement row. `MeshSnapshot.pickView` pins the immutable native view. Source/pose
successors borrow these mappings alongside the existing triangle and instance
streams. A hit carries the native owner token and output identity; Cyrus Edit
matches that identity against its displayed feedback, not an assumed row index.

The private PointDisplay helper implements Max's object HitTest. A selection callback
redirects its node to the real Scatter controller. Its name is synchronized only
when different, avoiding repeated name-change notifications. The modifier's point
HitTest uses the same native picker before its existing marker fallback. Its bounds
include the retained geometry so a far leaf can be hit beyond the pivot bounds.

The picker reads the last complete, submitted generation. It honors idle draw
quotas, sparse hidden instances, packed pose transforms and guide visibility. A ray
passes instance bounds before testing triangles. Unposed source triangles use
cached blocks of 64 faces; prepared poses evaluate only candidate triangles from
the shader's source/pose data. Repeated preselection/click queries reuse the same
ray result within that generation. Textured picking checks atlas opacity; it uses
a nearest alpha threshold, not pixel-identical GPU filtering.

Derived caches are main-thread-only and charged through viewport memory admission.
An entry inventory cannot exceed the existing one-million-placement bound. Failed
pick-cache admission yields no mesh hit; it does not replace or invalidate the
display. Geometry/source snapshots remain shared. There is no source EvalWorldState,
contact fit, placement solve or GPU upload in the hover query.

An 80 ms UI timer requests a redraw only when the hovered instance changes. It
stops highlighting during mouse-button navigation/dragging. Max's PickNode provides
frontmost-node occlusion; the native geometry ray is cached between that query and
highlight preparation. Cursor, viewport ray, edited controller and displayed-ticket
changes invalidate the hover query. The yellow mesh overlay samples at most 1,024
faces, and never limits picking accuracy.

The shared window captures controller references before callbacks, changes only
one requested property and reuses the existing display/update methods. It adds no
second settings store. Explicit Update consumes Manual pending changes; display
controls preserve them. Existing per-controller failure retention and Edit storage
continue to apply. There is no new scene or recipe schema and no change to solver
math, source preparation or the separate Edit modifier.

## Host API basis

Autodesk documents [sub-object hit testing](https://help.autodesk.com/cloudhelp/2024/ENU/Max-Developer-Help/3ds_max_sdk_features/viewports_and_graphics_windows/hit_testing/sub-object_hit_testing.html)
and [node picking through Interface](https://help.autodesk.com/cloudhelp/2025/ENU/MAXDEV-CPP-API-REF/class_interface.html).
The private qualification DLL exercises PickNode and SubObHitTest/SelectSubComponent;
it is never packaged. The authored shared change uses a named
[MAXScript Undo context](https://help.autodesk.com/cloudhelp/2020/ENU/3DSMax-MAXScript/files/GUID-C8517C4A-A75F-4D4E-A058-BE3EE61A2A11.htm).

## Verification boundaries

Read DELIVERY and QUALIFICATION for the exact frozen payload and executed tests.
Scripted ray and SDK selection checks do not measure physical mouse-to-screen
latency or Max's tooltip dwell timing. Point Cloud/Centers, rectangle selection,
renderer output and arbitrary external renderer graphs are not new geometry-picking
features. The environment-only CPU posed-batch qualification route is not the
production shared-pose viewport and is outside this selection qualification.
