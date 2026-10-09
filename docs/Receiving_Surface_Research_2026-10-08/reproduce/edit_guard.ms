RSAssert()
(
    RSLeaf.paintEnabled=false;RSLeaf.amount=100;RSLeaf.populationMode=1
    local targets=for i=1 to 3 collect (getNodeByName ("RS_Receiver_"+i as string) exact:true)
    RSRoot.surfaceNodes=#(targets[1],targets[2]);RSRoot.evaluateGroups()
    local controller=(for node in refs.dependentNodes RSRoot where node.baseObject==RSRoot collect node)[1]
    local edit=CyrusScatterEdit();addModifier controller edit;RSRoot.evaluateGroups()
    cyrusEditSelect edit #(1,2);cyrusEditCommand edit 4 (transMatrix [3,4,5])
    local before=(RSRoot.evaluateGroups())[1],signature=cyrusEditFingerprint before "receivers-edit"
    RSRoot.surfaceNodes=#(targets[1],targets[2],targets[3])
    local failure=""
    try(RSRoot.evaluateGroups())catch(failure=getCurrentException())
    local retained=(RSRoot.procReadSnapshot())[1]
    RSRoot.surfaceNodes=#(targets[1],targets[2])
    local restored=(RSRoot.evaluateGroups())[1]
    RSWrite "edit-guard.txt" ("error "+failure+"\nretained exact "+((signature==cyrusEditFingerprint retained "receivers-edit") as string)+" restored exact "+((signature==cyrusEditFingerprint restored "receivers-edit") as string))
)
