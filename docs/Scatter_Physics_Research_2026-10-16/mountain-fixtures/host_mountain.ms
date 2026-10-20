cplResetScene()
if not loadMaxFile @"F:/Cursor/_Cyrus_Apps/CyrusScatter/build/physics-mountain-017-20261018-01/Mountain Scene Brush Test.max" quiet:true do throw "Artist mountain copy did not load"
loadDllsFromDir @"F:/Cursor/_Cyrus_Apps/CyrusScatter/build/physics-lab-brush-probe-013/" "CyrusPhysicsProbe.dlx"
global CPLMountainLab
python.ExecuteFile @"F:/Cursor/_Cyrus_Apps/CyrusScatter/docs/Scatter_Physics_Research_2026-10-16/mountain-fixtures/host_mountain.py"
