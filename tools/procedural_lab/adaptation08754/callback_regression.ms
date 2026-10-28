-- Directly exercise the application callbacks, including a fresh empty setup.
-- Capture the unfixed failure before testing the successor with the same script.
global ADCbOwner,ADCbRoot
(
    if not matchPattern GardenRun pattern:"*/build/*/host-*/" do throw "Owned callback test host required."
    local before=sliderTime,rows=#(),failure="",expected=CVProfileCase=="callback-baseline",message=""
    try (
        ADCbOwner=AminScatterObject name:"AD_Callback_Empty_Controller"
        ADCbRoot=ADCbOwner.baseObject;ADCbRoot.updateMode=1
        local count=ADCbRoot.interactionSceneColliders.count
        try(ADCbRoot.liveTimeChanged())catch(message=getCurrentException())
        append rows #("actual_member_count",count);append rows #("empty_callback_error",message)
        if expected then (
            if not matchPattern message pattern:"*count*undefined*" do throw "Unfixed callback failure was not reproduced."
        ) else (
            if message!="" do throw message
            ADCbRoot.cyrusEnabled=false
            ADCbRoot.liveTimeChanged()
            ADCbRoot.cyrusEnabled=true
            ADCbRoot.updateMode=2;ADCbRoot.liveTimeChanged()
            AminScatterLiveTime()
            sliderTime=before+1f;AminScatterLiveTime();sliderTime=before
            local wall=box name:"AD_Callback_Wall" width:10 length:10 height:20
            ADCbRoot.interactionsSceneCommand #(wall)
            ADCbRoot.interactionSceneDirty=false
            ADCbRoot.liveTimeChanged()
            if not ADCbRoot.interactionSceneDirty do throw "Collider time invalidation did not reach the controller member."
            ADCbRoot.interactionsSceneCommand #() removeIndex:1
            ADCbRoot.liveTimeChanged()
            append rows #("disabled_manual_live_time_and_scene_reference_callbacks",true)
        )
    )catch(failure=getCurrentException())
    sliderTime=before
    local text="{\"status\":\""+(if failure=="" then "pass" else "failed")+"\",\"expected_unfixed_failure\":"+(if expected then "true" else "false")+",\"observations\":\""+(substituteString (substituteString (rows as string) "\\" "\\\\") "\"" "\\\"")+"\",\"error\":\""+(substituteString (substituteString failure "\\" "\\\\") "\"" "\\\"")+"\"}"
    (dotNetClass "System.IO.File").WriteAllText (GardenRun+CVProfileCase+".json") text
    if failure!="" do throw failure
)
