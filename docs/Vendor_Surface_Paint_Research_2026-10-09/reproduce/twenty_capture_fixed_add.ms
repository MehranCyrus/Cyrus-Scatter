RSAssert()
(
    if VChaos.FpInterface.getInstanceCount()!=10000 do throw "Wrong fixed-total population; refuse export"
    VCapture "split_twenty_fixed_add"
)
