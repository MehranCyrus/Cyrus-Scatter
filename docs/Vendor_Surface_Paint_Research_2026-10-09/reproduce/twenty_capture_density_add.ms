RSAssert()
(
    if VChaos.FpInterface.getInstanceCount()!=10500 do throw "Wrong density added population; refuse stale export"
    VCapture "split_twenty_density_add"
)
