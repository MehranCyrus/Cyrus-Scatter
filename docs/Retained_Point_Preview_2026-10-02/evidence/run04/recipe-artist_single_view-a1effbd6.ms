(
    global RIBenchmarkLabel="artist-single-view"
    local viewTM=viewport.getTM()
    viewport.setLayout #layout_1
    viewport.setType #view_persp_user;viewport.setTM viewTM
    completeRedraw();windows.processPostedMessages()
    fileIn (RIRoot+"tools/performance/retained_integration/benchmark.ms")
)
