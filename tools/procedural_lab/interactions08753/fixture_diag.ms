(
    if CVProfileCase=="fixture-publish" do (WFRoot.refreshAll();CyrusPointSync())
    local result=stringStream ""
    format "owner=% root=% collider=%\n" WFOwner WFRoot WFCollider to:result
    format "sameBase=% current=% sameCurrent=%\n" (WFRoot==WFOwner.baseObject) (modPanel.getCurrentObject()) ((modPanel.getCurrentObject())==WFRoot) to:result
    format "mainUI root=% view=% ready=% displayed=% hwnd=% timer=%\n" WFRoot.mainUI.root WFRoot.mainUI.view WFRoot.mainUI.controlsReady WFRoot.mainUI.isDisplayed WFRoot.mainUI.hwnd WFRoot.mainUI.mountTimer.active to:result
    format "nodeUI ready=% hwnd=% root=%\n" WFOwner.mainUI.controlsReady WFOwner.mainUI.hwnd WFOwner.mainUI.root to:result
    format "holds=%\n" (theHold.Holding()) to:result
    (dotNetClass "System.IO.File").WriteAllText (GardenRun+"fixture-diag.txt") (result as string)
)
