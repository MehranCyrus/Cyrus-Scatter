RSAssert()
(
    if VChaos.FpInterface.getInstanceCount()!=10000 do throw "Wrong density baseline; refuse export"
    VCapture "split_twenty_density_baseline"
)
