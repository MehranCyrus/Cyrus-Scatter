-- Run only in the private probe session after visual validation.
(
    local configurations=#(#(25000,3),#(100000,3),#(250000,3),#(500000,3),#(1000000,3),#(500000,32))
    for config in configurations do (
        HVPBuild config[1] config[2]
        local name="points"+(config[1] as string)+"-sources"+(config[2] as string)
        HVPMode "gw"; HVPCapture (name+"-gw")
        HVPMode "retained"; HVPCapture (name+"-retained")
        HVPBenchmark name frames:120 repeats:3
        CSPWriteText (HVPDir+"matrix-progress.txt") name
    )
    CSPWriteText (HVPDir+"matrix-complete.txt") "SUCCESS"
)
