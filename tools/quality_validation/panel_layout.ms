fileIn ((getFilenamePath(getSourceFileName()))+"common.ms")
global QPanelBefore,QPanelEpoch,QPanelOrder,QExpectedPanelOrder
fn QPanelOrder = (
    local rows=for i=1 to QRoot.mainUI.slots.count collect (
        local rectangle=windows.getWindowPos QRoot.mainUI.slots[i].hwnd
        #(rectangle.x,rectangle.y,i)
    )
    fn compare a b = (if a[1]!=b[1] then (if a[1]<b[1] then -1 else 1) else if a[2]==b[2] then 0 else if a[2]<b[2] then -1 else 1)
    qsort rows compare
    for row in rows collect row[3]
)
(
case QScenarioID of (
 "UI84-PREPARE": (
    QSetup();QMount pages:#("managerUISlot","surfacesUISlot","containersUISlot","layoutUISlot")
    QLayer.amount=500
    QPanelBefore=QFingerprint();QPanelEpoch=QRoot.procEpoch
    python.executeFile ((getFilenamePath(getSourceFileName()))+"panel_state.py")
 )
 "UI84-CAPTURE": (
    QExpectedPanelOrder=QPanelOrder()
    python.executeFile ((getFilenamePath(getSourceFileName()))+"panel_state.py")
 )
 "UI84-RESELECT": (
    for repetition=1 to 3 do (
        clearSelection();QSettle 200;select QNode;max modify mode;QSettle 700
        QRequire QRoot.mainUI.controlsReady "Reselection did not mount"
        QRequire (QPanelOrder()==QExpectedPanelOrder) ("Dragged rollout order was reset: "+(QPanelOrder() as string))
    )
    python.executeFile ((getFilenamePath(getSourceFileName()))+"panel_state.py")
 )
 "UI84-SDKORDER": (
    QSetup();QMount pages:#("managerUISlot","surfacesUISlot","containersUISlot","layoutUISlot")
    QLayer.amount=500;QPanelBefore=QFingerprint();QPanelEpoch=QRoot.procEpoch
    dotNet.loadAssembly (MCPFixtureDir+"../RolloutOrderFixture.dll")
    local sdk=dotNetClass "OwnedRolloutLayout"
    -- Max normalizes category zero to one; compare the intended ordering.
    QRequire ((sdk.Category QRoot.mainUI.hwnd)<(sdk.Category QRoot.managerUISlot.hwnd)) "Main rollout default must precede Layers"
    sdk.ArrangeContainer QRoot.containersUISlot.hwnd 15
    cyrusSetRolloutVisible QRoot.containersUISlot.hwnd true 40
    QRequire ((sdk.Category QRoot.containersUISlot.hwnd)==15) "Visibility reset the custom category"
    for repetition=1 to 3 do (
        clearSelection();QSettle 200;select QNode;max modify mode;QSettle 700
        QRequire ((sdk.Category QRoot.containersUISlot.hwnd)==15) "Reselection reset the saved custom category"
    )
    python.executeFile ((getFilenamePath(getSourceFileName()))+"panel_state.py")
 )
 default:throw "Unknown panel-layout scenario"
)
QAssert (QFingerprint()==QPanelBefore and QRoot.procEpoch==QPanelEpoch and QLayer.amount==500) (QScenarioID+"-01") "Panel operations preserve publication and pending Manual amount"
)
