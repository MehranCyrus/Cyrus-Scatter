-- Current 0.73 playback fixture with a matching private Analyzer script/DLL.
global PTAnalyzerNode,PTAnalyzer,PTAnalyzerSurface
fn PTAnalyzerNew = (
    resetMaxFile #noPrompt;sliderTime=0
    AminScatterNodeEvents.enabled=false;CyrusAnalyzerEvents.enabled=false
    PTAnalyzerSurface=plane name:"PT_AnalyzerSurface" width:1000 length:1000 widthsegs:2 lengthsegs:2
    PTAnalyzerNode=CyrusSurfaceAnalyzer name:"PT_Analyzer"
    PTAnalyzer=PTAnalyzerNode.baseObject
    PTAnalyzer.surface=PTAnalyzerSurface;PTAnalyzer.pointRadius=10;PTAnalyzer.fitRadius=20
    PTAnalyzer.resolution=48;PTAnalyzer.relaxIterations=0
    PTAnalyzer.updateMode=2;CyrusAnalyzerPulse undefined undefined
    PTAssert (PTAnalyzer.boundaryVertices.count>0) "Analyzer fixture has no boundary"
    PTAssert (findItem CyrusAnalyzerOwners PTAnalyzerNode>0) "Analyzer was not registered"
    PTAssert (not CyrusAnalyzerTimer.Enabled) "Settled Analyzer timer kept running"
    PTAssert ((PTAnalyzer.getLiveStats())[5][3]) "Static Analyzer inputs did not report FOREVER"
)
fn PTAnalyzerIdle = (
    PTAnalyzerNew()
    local car=box name:"PT_AnalyzerUnrelatedCar" pos:[2000,0,0]
    with animate on (at time 0 car.pos=[2000,0,0];at time 20 car.pos=[3000,0,0])
    local before=PTAnalyzer.getLiveStats()
    CyrusAnalyzerChanged #controllerOtherEvent #(getHandleByAnim car)
    for frame in #(1,5,10,20,5,0) do (
        sliderTime=frame
        PTAssert (not CyrusAnalyzerTimeChanged()) "Unrelated animation invalidated Analyzer"
        PTAssert (not CyrusAnalyzerTimer.Enabled) "Unrelated animation armed Analyzer timer"
        PTAssert ((PTAnalyzer.getLiveStats() as string)==(before as string)) "Unrelated animation did Analyzer work"
    )
    local endTime=timeStamp()+350
    while timeStamp()<endTime do (dotNetClass "System.Windows.Forms.Application").DoEvents()
    PTAssert ((PTAnalyzer.getLiveStats() as string)==(before as string)) "Settled Analyzer did background work"
    PTRecord "Analyzer unrelated animation, rewind and settled message-loop idle"
    PTAnalyzer.resolution=64
    PTAssert (CyrusAnalyzerTimer.Enabled) "Analyzer parameter change did not request work"
    endTime=timeStamp()+600
    while timeStamp()<endTime do (dotNetClass "System.Windows.Forms.Application").DoEvents()
    PTAssert (PTAnalyzer.getAnalysisRuns()==before[1]+1) "Analyzer timer did not publish exactly once"
    PTAssert (not CyrusAnalyzerTimer.Enabled) "Analyzer timer did not stop after its update"
    PTRecord "Analyzer real parameter edit and one-shot timer"
)
fn PTAnalyzerAnimation parented:false = (
    PTAnalyzerNew()
    local target=PTAnalyzerSurface
    if parented do (target=point name:"PT_AnalyzerParent";PTAnalyzerSurface.parent=target)
    with animate on (at time 0 target.pos=[0,0,0];at time 10 target.pos=[0,0,100])
    CyrusAnalyzerChanged #controllerOtherEvent #(getHandleByAnim target)
    PTAssert (CyrusAnalyzerTimer.Enabled) "Relevant Analyzer input/parent change was missed"
    CyrusAnalyzerPulse undefined undefined
    local before=PTAnalyzer.getAnalysisRuns()
    sliderTime=10
    CyrusAnalyzerTimeChanged() -- sliderTime already delivers the registered callback
    PTAssert (CyrusAnalyzerTimer.Enabled and PTAnalyzer.livePending()) "Animated Analyzer input did not request time work"
    CyrusAnalyzerPulse undefined undefined
    PTAssert (PTAnalyzer.getAnalysisRuns()==before+1) "Animated Analyzer did not update once"
    for p in PTAnalyzer.boundaryVertices do PTAssert (abs(p.z-100)<0.01) "Animated Analyzer boundary was stale"
    before=PTAnalyzer.getLiveStats();CyrusAnalyzerTimeChanged()
    PTAssert (not CyrusAnalyzerTimer.Enabled) "Same-time Analyzer notification armed another update"
    PTAssert ((PTAnalyzer.getLiveStats() as string)==(before as string)) "Same-time Analyzer notification did work"
    PTAnalyzer.updateMode=1;before=PTAnalyzer.getLiveStats()
    for frame in #(1,5,10,0) do (sliderTime=frame;CyrusAnalyzerTimeChanged())
    PTAssert (not CyrusAnalyzerTimer.Enabled) "Manual Analyzer armed its timer"
    PTAssert ((PTAnalyzer.getLiveStats() as string)==(before as string)) "Manual Analyzer did time work"
    PTAnalyzer.updateMode=2;CyrusAnalyzerPulse undefined undefined
    for p in PTAnalyzer.boundaryVertices do PTAssert (abs p.z<0.01) "Analyzer did not catch up when returning to Live"
    PTRecord (if parented then "Analyzer parent animation and Manual freeze" else "Analyzer receiver animation and Manual freeze")
)
fn PTAnalyzerFailure = (
    PTAnalyzerNew();PTAnalyzer.surface=undefined
    CyrusAnalyzerPulse undefined undefined
    PTAssert (matchPattern PTAnalyzer.resultText pattern:"Update failed:*") "Analyzer failure did not report an error"
    PTAssert (not CyrusAnalyzerTimer.Enabled) "Failed Analyzer input caused repeated retry"
    local before=PTAnalyzer.getLiveStats()
    for frame in #(1,5,10) do (sliderTime=frame;CyrusAnalyzerTimeChanged())
    PTAssert ((PTAnalyzer.getLiveStats() as string)==(before as string)) "Failed Analyzer input retried on unrelated time"
    PTAnalyzer.surface=PTAnalyzerSurface;CyrusAnalyzerPulse undefined undefined
    PTAssert (not matchPattern PTAnalyzer.resultText pattern:"Update failed:*") "Analyzer did not recover after a real correction"
    PTRecord "Analyzer failure stops retrying and recovers on a real correction"
)
fn PTAnalyzerLifecycle = (
    PTAnalyzerNew()
    local cloned=copy PTAnalyzerNode
    PTAssert (CyrusAnalyzerOwners.count==2 and findItem CyrusAnalyzerOwners cloned>0) "Cloned Analyzer was not registered"
    delete cloned;CyrusAnalyzerPruneOwners()
    local scene=PTDir+"analyzer-disposable.max"
    PTAssert (saveMaxFile scene quiet:true) "Analyzer disposable scene did not save"
    resetMaxFile #noPrompt
    PTAssert (CyrusAnalyzerOwners.count==0 and not CyrusAnalyzerTimer.Enabled) "Reset retained Analyzer owners or timer work"
    PTAssert (loadMaxFile scene quiet:true) "Analyzer disposable scene did not reopen"
    PTAnalyzerNode=getNodeByName "PT_Analyzer";PTAnalyzer=PTAnalyzerNode.baseObject
    PTAnalyzerSurface=getNodeByName "PT_AnalyzerSurface"
    PTAssert (CyrusAnalyzerOwners.count==1 and CyrusAnalyzerOwners[1]==PTAnalyzerNode) "Reopened Analyzer registry differs"
    CyrusAnalyzerPulse undefined undefined
    PTAssert (not CyrusAnalyzerTimer.Enabled) "Reopened Analyzer did not settle"
    delete PTAnalyzerNode;CyrusAnalyzerPruneOwners();CyrusAnalyzerRequest()
    PTAssert (CyrusAnalyzerOwners.count==0 and not CyrusAnalyzerTimer.Enabled) "Deleted Analyzer retained registry or timer work"
    PTRecord "Analyzer clone/save/reopen/reset/delete lifecycle"
)
fn PTAnalyzerAsPublishedInput = (
    PTNew()
    PTAnalyzerSurface=plane name:"PT_ManualAnalyzerReceiver" width:700 length:700
    PTAnalyzerNode=CyrusSurfaceAnalyzer name:"PT_ManualAnalyzer"
    PTAnalyzer=PTAnalyzerNode.baseObject
    PTAnalyzer.surface=PTAnalyzerSurface;PTAnalyzer.pointRadius=10;PTAnalyzer.fitRadius=20
    PTAnalyzer.resolution=48;PTAnalyzer.relaxIterations=0;PTAnalyzer.updateMode=1
    PTAnalyzer.runAnalysis()
    PTLeaf.areaAnalyzer=PTAnalyzerNode;PTLeaf.areaUseLine=true
    PTDraw();PTStopQueues()
    PTAssert (PTLeaf.generatedCount>0 and PTLeaf.generatedCount<120 and PTLeaf.previewError=="") "Analyzer Area fixture did not filter the population"
    with animate on (at time 0 PTAnalyzerSurface.pos=[0,0,0];at time 10 PTAnalyzerSurface.pos=[3000,0,0])
    CyrusAnalyzerChanged #controllerOtherEvent #(getHandleByAnim PTAnalyzerSurface)
    local before=PTCounts(),layout=PTLayout()
    sliderTime=10;AminScatterLiveTime();CyrusAnalyzerTimeChanged();PTDraw()
    PTAssert ((PTCounts() as string)==(before as string) and PTLayout()==layout) "Manual Analyzer receiver animation invalidated its cached Scatter output"
    PTAnalyzer.runAnalysis();PTDraw()
    PTAssert (PTLeaf.generatedCount==0) "Scatter did not consume a newly published Analyzer boundary"
    PTRecord "Scatter consumes Analyzer publication and preserves Analyzer Manual mode"
)
PTAssert (cyrusAnalyzerInputValidity!=undefined) "Analyzer validity primitive is missing"
PTAnalyzerIdle();PTAnalyzerAnimation();PTAnalyzerAnimation parented:true;PTAnalyzerFailure();PTAnalyzerAsPublishedInput();PTAnalyzerLifecycle()
