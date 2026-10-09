RSAssert()
(
    local first=getNodeByName "RS_Receiver_1" exact:true,second=getNodeByName "RS_Receiver_2" exact:true
    RSRoot.surfaceNodes=#(first);RSLeaf.populationMode=1;RSLeaf.amount=2000
    RSRoot.setGroupCoverage RSLeaf true
    local document=RSLeaf.paintDocument
    cyrusBrushFill document 0
    cyrusBrushSettings document 30 1 0 false 1
    -- Programmatic Dab takes a ray in the receiver's object coordinates.
    if not cyrusBrushDab document [0,0,500] [0,0,-1] true do throw "Paint fixture missed"
    local before=(RSRoot.evaluateGroups())[1],beforeFingerprint=cyrusEditFingerprint before "receiver-research"
    RSRoot.surfaceNodes=#(first,second)
    local failure=""
    try(RSRoot.evaluateGroups())catch(failure=getCurrentException())
    local retained=(RSRoot.procReadSnapshot())[1]
    local report=stringStream ""
    format "painted count % retained count % identical snapshot % same document % same paint target %\nerror %\n" before.count retained.count (beforeFingerprint==cyrusEditFingerprint retained "receiver-research") (RSLeaf.paintDocument==document) (cyrusBrushTarget document==first) failure to:report
    RSRoot.surfaceNodes=#(first)
    local restored=(RSRoot.evaluateGroups())[1]
    format "restored count % restored fingerprint %\n" restored.count (beforeFingerprint==cyrusEditFingerprint restored "receiver-research") to:report
    RSWrite "paint-guard.txt" (report as string);close report
    local p=((dotNetClass "System.Diagnostics.Process").GetCurrentProcess())
    RSWrite "max-version.txt" (p.MainModule.FileVersionInfo.FileVersion as string)
)
