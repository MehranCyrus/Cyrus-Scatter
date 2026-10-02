-- Grow the exact synthetic placement table while keeping the display budget fixed.
global HVPExactRows
(
    for plantCount in #(10000,100000,1000000) do (
        HVPMode "off"
        local clock=HVPClockClass.StartNew()
        local source=cone radius1:42 radius2:0 height:160 sides:8 heightsegs:1 capsegs:1
        local samples=for i=1 to 3 collect (aminScatterSourcePoints source 100 (27000+i))
        delete source
        local colors=#(color 57 113 38,color 74 136 51,color 91 159 64)
        local columns=ceil(sqrt plantCount) as integer, spacing=8000.0/columns
        seed 19471
        HVPExactRows=for i=0 to (plantCount-1) collect (
            local tm=rotateZMatrix (random 0.0 359.9)
            tm.translation=[((mod i columns)+0.5+random -0.3 0.3)*spacing-4000.0,((floor(i/columns as float))+0.5+random -0.3 0.3)*spacing-4000.0,0]
            #(tm,1+mod i 3)
        )
        local rowsReady=clock.Elapsed.TotalMilliseconds
        local cache=aminScatterBuildPreview HVPExactRows samples colors 250000
        HVPCaches=#(cache)
        local nativeReady=clock.Elapsed.TotalMilliseconds
        local exported=aminScatterPreviewPoints cache
        cyrusPointProbeSet HVPNode exported
        exported=undefined
        clock.Stop()
        HVPFixtureInfo=#(#("requested_points",250000),#("actual_points",aminScatterPreviewCount cache),#("plants",plantCount),#("source_groups",3),#("cache_count",1),#("synthetic_rows_ms",rowsReady),#("native_preview_ms",nativeReady-rowsReady),#("export_and_probe_copy_ms",clock.Elapsed.TotalMilliseconds-nativeReady),#("prepare_ms",clock.Elapsed.TotalMilliseconds),#("exact_rows_retained",HVPExactRows.count))
        gc light:true
        local name="points250000-population"+(plantCount as string)
        HVPMode "retained"; HVPCapture name
        HVPBenchmark name frames:120 repeats:3
        CSPWriteText (HVPDir+"population-progress.txt") name
    )
    CSPWriteText (HVPDir+"population-complete.txt") "SUCCESS"
)
