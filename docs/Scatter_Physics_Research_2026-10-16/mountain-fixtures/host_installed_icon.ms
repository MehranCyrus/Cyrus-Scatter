-- Exact installed pair: complete continuous workflow, then selectable-icon/render workflow.
fileIn @"F:/Cursor/_Cyrus_Apps/CyrusScatter/CyrusPhysicsLab/tests/host_continuous.ms"
(dotNetClass "System.IO.File").Copy (CPLTestDir+"assertions.txt") (CPLTestDir+"continuous-assertions.txt") true
fileIn @"F:/Cursor/_Cyrus_Apps/CyrusScatter/docs/Scatter_Physics_Research_2026-10-16/mountain-fixtures/host_icon.ms"
(dotNetClass "System.IO.File").Copy (CPLTestDir+"assertions.txt") (CPLTestDir+"icon-assertions.txt") true
(dotNetClass "System.IO.File").AppendAllText (CPLTestDir+"assertions.txt") ("\n"+(dotNetClass "System.IO.File").ReadAllText (CPLTestDir+"continuous-assertions.txt"))
