-- Run only after inspecting artist-mesh-200k-initial.png: foliage must be visible.
(
    global MIBenchmark
    fileIn (RIRoot+"tools/performance/mesh_integration/benchmark.ms")
    MIBenchmark "artist-mesh-200k" frames:30
    for node in objects where classof node.baseObject==AminScatterObject do (node.viewportFaces=2000000;node.refreshDisplay())
    MISettle();MIBenchmark "artist-mesh-2m" frames:15 repeats:3
)
