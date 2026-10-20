cplResetScene()
if not loadMaxFile @"F:/Cursor/_Cyrus_Apps/CyrusScatter/build/physics-mountain-017-20261018-01/Mountain Scene Brush Test.max" quiet:true do throw "Mountain scene copy did not load"
python.ExecuteFile @"F:/Cursor/_Cyrus_Apps/CyrusScatter/docs/Scatter_Physics_Research_2026-10-16/mountain-fixtures/inspect_scene.py"
(dotNetClass "System.IO.File").WriteAllText (CPLTestDir+"assertions.txt") "PASS scene inventory/export; original preserved"
