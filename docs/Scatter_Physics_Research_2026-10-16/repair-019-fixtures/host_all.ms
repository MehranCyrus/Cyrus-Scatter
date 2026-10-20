-- One owned host avoids repeating cold startup and competing scene profiles.
fileIn @"F:/Cursor/_Cyrus_Apps/CyrusScatter/docs/Scatter_Physics_Research_2026-10-16/repair-019-fixtures/host_popup.ms"
copyFile (CPLTestDir+"popup-layout.json") (CPLTestDir+"initial-popup-layout.json")
cplResetScene()
loadDllsFromDir @"F:/Cursor/_Cyrus_Apps/CyrusScatter/build/physics-lab-brush-probe-013/" "CyrusPhysicsProbe.dlx"
fileIn @"F:/Cursor/_Cyrus_Apps/CyrusScatter/docs/Scatter_Physics_Research_2026-10-16/repair-019-fixtures/host_order.ms"
cplStage "reused-hole ordering complete"
cplResetScene()
fileIn @"F:/Cursor/_Cyrus_Apps/CyrusScatter/docs/Scatter_Physics_Research_2026-10-16/repair-019-fixtures/host_artist.ms"
copyFile (CPLTestDir+"assertions.txt") (CPLTestDir+"artist-assertions.txt")
cplStage "artist checks complete; reset begin"
cplResetScene()
cplStage "artist reset complete"
fileIn @"F:/Cursor/_Cyrus_Apps/CyrusScatter/docs/Scatter_Physics_Research_2026-10-16/repair-019-fixtures/host_matrix.ms"
copyFile (CPLTestDir+"assertions.txt") (CPLTestDir+"mountain-assertions.txt")
cplStage "mountain checks complete; reset begin"
cplResetScene()
cplStage "mountain reset complete"
cplStage "all checks complete"
