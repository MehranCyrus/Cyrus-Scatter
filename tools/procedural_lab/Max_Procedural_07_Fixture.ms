-- Definitions only. Run in a NEW DISPOSABLE EMPTY Max session AFTER approval.
-- Load the matching 0.7 package, then call CyrusProcedural07Fixture().
-- Does not load/save/reset a scene or install any binaries.
global CyrusProcedural07Fixture
fn CyrusProcedural07Fixture = (
    if objects.count!=0 do throw "This fixture requires an empty disposable scene."
    if cyrusEvaluateProcedural==undefined do throw "Load the matching 0.7 native package first."
    local passed=#()
    fn verify condition text = (if not condition do throw ("Fixture failed: "+text);true)
    local surface=plane length:1000 width:1000 lengthsegs:1 widthsegs:1 name:"Cyrus07_Fixture_Surface"
    local source=box length:8 width:8 height:20 pos:[1200,0,0] name:"Cyrus07_Fixture_Source"
    local node=AminScatterObject name:"Cyrus07_Fixture_Controller",root=node.baseObject
    verify (root.uiVersion()=="0.72") "UI version"
    root.setLayerTransfer true
    root.updateMode=1;root.surfaceNodes=#(surface);root.newLayer()
    local parent=root.selectedLayer()
    parent.amount=100;parent.sources=#(source);parent.sourceWeights=#(1.0);parent.paintEnabled=false
    parent.randomSeed=42;parent.collisionEnabled=false
    root.setLayerTransfer false;root.procUpgrade()
    local rows=root.evaluateGroups(),builds=(root.groupCounters())[1]
    verify (rows[1].count==100) "candidate-budget count"
    root.evaluateGroups();verify ((root.groupCounters())[1]==builds) "warm controller cache"
    append passed "base generation and warm cache"
    local key=root.groupInputKey(),prepared=(parent.procStatistics())[3]
    parent.paintSetName="Renamed base";root.layerNames[1]="Renamed layer";parent.paintSetVisible=false
    verify (root.groupInputKey()==key) "name/visibility excluded from calculation key"
    parent.paintSetVisible=true
    root.setGroupDisplay 3;root.setGroupDisplay 2;root.setGroupDisplay 1
    verify ((parent.procStatistics())[3]==prepared) "display changes reuse prepared candidates"
    append passed "presentation and three display adapters"
    local child=root.addPaintSet parent label:"Flowers"
    child.sources=#(source);child.sourceWeights=#(1.0);child.paintEnabled=false
    local allocation=#((root.populationAllocation parent)[1],(root.populationAllocation child)[1])
    root.procMove child -1 sets:true
    verify (allocation[1]==(root.populationAllocation parent)[1] and allocation[2]==(root.populationAllocation child)[1]) "order does not change allocation ties"
    root.procSetPair 1 child parent true 0.0 1e6 false
    rows=root.evaluateGroups()
    verify (rows[findItem root.layerObjects child].count==50 and rows[findItem root.layerObjects parent].count==0) "earlier sibling owns spacing"
    root.procMove parent -1 sets:true;rows=root.evaluateGroups()
    verify (rows[findItem root.layerObjects parent].count==50 and rows[findItem root.layerObjects child].count==0) "visible set order changes winner"
    append passed "independent sibling rule and stable reordering"
    root.procSetPair 1 child parent false 1.0 0.0 false
    parent.procPopulation=2;parent.procAttemptFactor=4;parent.procRounds=4
    parent.procSelfOverride=true;parent.procSelfEnabled=true;parent.procSelfMultiplier=0;parent.procSelfGap=1e6
    rows=root.evaluateGroups()
    verify ((parent.procStatistics())[1][11]==49) "bounded target shortfall"
    parent.procSelfEnabled=false;root.evaluateGroups()
    append passed "accepted target and explicit underfill"
    local beforeEpoch=(parent.procStatistics())[5],beforeCache=(parent.cacheSnapshot())[1]
    parent.sourceRadii=#(-1.0)
    local rejected=false
    try(root.evaluateGroups())catch(rejected=true)
    verify rejected "invalid radius rejected"
    verify ((parent.procStatistics())[5]==beforeEpoch and (parent.cacheSnapshot())[1]==beforeCache) "failed successor preserves published result"
    parent.sourceRadii=#(0.0);root.evaluateGroups()
    append passed "transaction rollback and previous viewport retention"
    -- Edit bindings must survive quota changes, while each clone has its own ID.
    local edit=CyrusScatterEdit()
    addModifier node edit;root.evaluateGroups()
    cyrusEditCommand edit 1 (matrix3 1)
    cyrusEditCommand edit 4 (transMatrix [0,0,2])
    cyrusEditCommand edit 3 (matrix3 1)
    root.evaluateGroups()
    local protectedBefore=(parent.procStatistics())[1][3]
    verify (protectedBefore>0) "edited plants are protected"
    parent.amount=0;root.evaluateGroups()
    verify ((parent.procStatistics())[1][2]==protectedBefore) "zero quota retains valid protected inputs"
    parent.procSelectedRadius 1 3.0
    verify (parent.procRadiusIDs.count>0) "per-instance radius overrides"
    root.evaluateGroups()
    append passed "CS Edit clones, zero quota and selected radii"
    format "Cyrus 0.7 runtime fixture passed: %\n" passed
    #(node,passed)
)
