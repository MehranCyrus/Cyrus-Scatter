-- Failure, already-stopped and message-pumping cases without starting a render.
(
    P07Case="0.72 Corona stop exclusion"
    struct IR073Provider (
        kind=3,result=0,stopKind=0,busySeen=false,raises=false,reenter=false,stopCalls=0,
        fn getRenderType = kind,
        fn stopRender = (
            stopCalls+=1;busySeen=CyrusPFBusy
            if reenter do CyrusPFTickImpl undefined undefined
            if raises do throw "Injected stop failure"
            kind=stopKind;result
        )
    )
    local previousBusy=CyrusPFBusy,previousError=CyrusPFLastError,builds=CyrusPFBuilds,nodes=CyrusPFNodes as string
    CyrusPFBusy=false
    for mode in #(2,3) do for code in #(0,2) do (
        local provider=IR073Provider kind:mode result:code reenter:true
        P07Assert (CyrusPFStopIR renderer:provider) "Stopped renderer was treated as active"
        P07Assert (provider.stopCalls==1 and provider.busySeen and not CyrusPFBusy) "Stop did not exclude nested bridge mutation"
        P07Assert (CyrusPFBuilds==builds and CyrusPFNodes as string==nodes) "Nested tick changed bridge during Stop"
    )
    local stopped=IR073Provider kind:0 result:2
    P07Assert (CyrusPFStopIR renderer:stopped and stopped.stopCalls==0) "Already-stopped session issued another Stop"
    local failed=IR073Provider kind:3 result:2 stopKind:3
    P07Assert (not CyrusPFStopIR renderer:failed and not CyrusPFBusy and CyrusPFLastError!="") "Active renderer failure was suppressed"
    local production=IR073Provider kind:1
    P07Assert (not CyrusPFStopIR renderer:production and production.stopCalls==0) "Stopped a production renderer"
    local exception=IR073Provider raises:true
    P07Assert (not CyrusPFStopIR renderer:exception and not CyrusPFBusy) "Stop exception left bridge busy"
    P07Assert (CyrusPFNodes as string==nodes) "Failed stop deleted bridge nodes"
    CyrusPFBusy=previousBusy;CyrusPFLastError=previousError
    CSPWriteText (MCPFixtureDir+"corona-stop-073.json") (CSPObject #(#("passed",true),#("mocked_lifecycle_cases",8),#("real_IR_qualified",false)))
)
