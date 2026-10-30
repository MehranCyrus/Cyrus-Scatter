# Cyrus Scatter 0.87.6.4 â€” individual instance hover and selection

Hovering a displayed scattered object highlights only that instance with a
twelve-edge box. A plain click selects its layer and stable instance identity,
opens the separate Cyrus Scatter Edit modifier and enters Instances. The SC
icon still selects the setup for editing its parameters. Shared multi-controller
controls remain available.

## Packages

- [Combined EXE â€” Max 2024, 2026, 2027](../../../dist/CyrusScatter-0.87.6.4-20261029/CyrusScatter-0.87.6.4-Setup.exe)
- MZP alternatives: [2024](../../../dist/CyrusScatter-0.87.6.4-20261029/CyrusScatter-0.87.6.4-Max2024.mzp), [2026](../../../dist/CyrusScatter-0.87.6.4-20261029/CyrusScatter-0.87.6.4-Max2026.mzp), [2027](../../../dist/CyrusScatter-0.87.6.4-20261029/CyrusScatter-0.87.6.4-Max2027.mzp)
- [Artist workflow and installation](ARTIST_GUIDE.md)
- [Exact qualification, hashes and limits](QUALIFICATION.json)

Close the selected Max versions before using the EXE. For an MZP use **Scripting
> Run Script**, choose the matching host package, then restart Max. This delivery
does not install into or restart the artist's Max session.

## Why the whole scene turned yellow

All displayed instances share a native render helper. Making that helper directly
pickable let Nitrous apply its object preselection effect to the entire helper.
Max's legacy DoOwnSelectHilite override did not suppress that effect in the
observed viewport. Changing only the custom hover overlay could not fix it.

The render helper now remains unpickable. A separate private helper, with no
render items, forwards hits to the committed displayed geometry. The custom
hover overlay draws twelve box edges from the instance's cached bounds. The
helpers share the existing publication; there is no additional source geometry,
placement solve or full-mesh upload for the hover. Both helpers retire together
on scene changes, saving and deletion.

Click routing uses controller, native layer owner, stable output identity and
visible-generation ticket. It waits for pointer release and rejects stale hits.
A newly added Edit binds retained final views so selecting a displayed instance
does not apply pending Manual Count/settings. Subsequent editing uses the existing
native transform, Undo and publication paths.

## Verification scope

The final exact script/native pair is qualified by the linked receipt. It covers
62 passing Max 2027 native suites; generated-source checks; SDK viewport hit and
mouse-message selection; visually inspected single-box hover; Move/Rotate/Scale
and Undo/Redo; ordinary-object occlusion; hidden previews; shared controller
selection; save/reload with explicit Update; helper retirement; and retained
Terraces garden picking/navigation counters.

The retained garden contained **18,229 placements across five populated controllers**. The 77-ray sweep and 24 scripted camera redraws left placement epochs and geometry streams unchanged. Across six inspected controller nodes, ray batches had a 0.052 ms median and 22.38 ms maximum; most rays missed vegetation. Camera redraw submission had a 21.03 ms median. These CPU/host measurements are not input-to-screen latency or GPU-presented FPS.

Max 2024 and 2026 have distinct matching SDK builds and package integrity checks.
Neither older application was launched. EXE embedded-resource hashes match the
three MZPs. Installer execution in artist profiles is not part of this check.

Earlier run-01/run-02 artifacts were rejected. Run 01 retained whole-object yellow
preselection; run 02 exposed a MAXScript nested-collection cleanup error. The
delivered run 03 separates picking and uses explicit local helper cleanup.
Those intermediate artifacts are not the delivered packages.

This patch preserves scene 65, recipe 9, Edit storage 3 and Interactions 16.
Viewport selection capability advances to 2 to require its matching native
modules. The user selected the four-part patch version. Bend/Trim algorithms,
Library and independently versioned products are unchanged.

Exact geometry hit testing still costs work, particularly with dense overlapping
foliage; this is not a claim of constant-time picking or measured GPU FPS.
Point Cloud/Centers keep their previous behavior. New renderer-wide, licensing,
Library and device-loss/long-session qualification remain outside this patch.
Website and indexed knowledge have not been rebuilt.
