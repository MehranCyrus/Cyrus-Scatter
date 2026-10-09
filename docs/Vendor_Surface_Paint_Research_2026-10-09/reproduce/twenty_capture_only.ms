RSAssert()
(
    local count=VChaos.FpInterface.getInstanceCount()
    RSWrite "twenty-split-count.txt" (count as string)
    if count!=10000 do throw "Expected 10000 fresh placements; refuse stale export"
    VCapture "split_twenty_fixed_baseline"
)
