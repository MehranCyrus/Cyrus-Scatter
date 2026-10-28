global DGControlTimer,DGControlTick,DGControlStep,DGControlFile
(
    DGControlStep=0
    DGControlFile=createFile (GardenRun+"trunk-controls.txt")
    WFRoot.identificationMode=1;WFRoot.setGroupDisplay 3
    fn DGControlTick sender args = (
        try(
            DGControlStep+=1
            local tree=WFRoot.layerObjects[3]
            if DGControlStep==1 then (
                tree.interactionsResponseSetting #interactionTrunkBend 0.0
                tree.interactionsResponseSetting #interactionFixedBase 0.0
                tree.interactionsResponseSetting #interactionBendTransition 0.25
            ) else if DGControlStep==4 then tree.interactionsResponseSetting #interactionTrunkBend 1.0
            else if DGControlStep==7 then tree.interactionsResponseSetting #interactionFixedBase 1.0
            else if DGControlStep==10 then (
                tree.interactionsResponseSetting #interactionTrunkBend 0.2
                tree.interactionsResponseSetting #interactionFixedBase 0.3
                tree.interactionsResponseSetting #interactionBendTransition 0.3
            )
            if findItem #(1,4,7,10) DGControlStep>0 do (WFRoot.interactionsEnsure();CyrusPointSync())
            redrawViews()
            if findItem #(3,6,9,12) DGControlStep>0 do (
                format "CONTROL % trunk:% base:% fade:% stats:%\nFRAME %\n" DGControlStep tree.interactionTrunkBend tree.interactionFixedBase tree.interactionBendTransition (WFRoot.interactionsStatistics()) (cyrusRetainedPresentationStats (CyrusPointOwner WFOwner)) to:DGControlFile
                local bitmap=gw.getViewportDib();bitmap.filename=GardenRun+"trunk-"+(DGControlStep as string)+".png";save bitmap;close bitmap;flush DGControlFile
            )
            if DGControlStep>=12 do (DGControlTimer.Stop();close DGControlFile)
        )catch(DGControlTimer.Stop();format "ERROR %\n" (getCurrentException()) to:DGControlFile;close DGControlFile)
    )
    DGControlTimer=dotNetObject "System.Windows.Forms.Timer";DGControlTimer.Interval=250
    dotNet.addEventHandler DGControlTimer "Tick" DGControlTick;DGControlTimer.Start()
)
