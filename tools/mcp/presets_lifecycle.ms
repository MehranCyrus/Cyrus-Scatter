global MCPPresetsLifecycleRun,CyrusMCPPresetLifecycleChecks
fn MCPPresetsLifecycleRun scenario = (
    if findItem #("reset","open","close") scenario==0 do throw "Unsupported preset lifecycle case"
    python.Execute "import presets_lifecycle_host; presets_lifecycle_host.capture()"
    case scenario of (
        "reset":(resetMaxFile #noPrompt)
        "open":(
            local path=maxFilePath+maxFileName
            local normalized=toLower (substituteString path "\\" "/"),root=toLower (substituteString MCPFixtureDir "\\" "/")
            if substring normalized 1 root.count!=root or not matchPattern normalized pattern:"*.max" do throw "An owned saved checkpoint is required"
            if not loadMaxFile path quiet:true do throw "Owned checkpoint failed to reopen"
        )
        "close":(python.Execute "import host_fixture; host_fixture.PANEL.close()")
    )
    python.Execute ("presets_lifecycle_host.verify('"+scenario+"')")
    QAssert CyrusMCPPresetLifecycleChecks[1] "preset_grant_revoked" "Preset grant cleared immediately"
    QAssert CyrusMCPPresetLifecycleChecks[2] "preset_handle_released" "Adapter no longer holds its reader"
    QAssert CyrusMCPPresetLifecycleChecks[3] "native_handle_rejected" "Closed native handle cannot inspect entries"
    QAssert CyrusMCPPresetLifecycleChecks[4] "task_refs_released" "Task and native scene references cleared"
    QAssert CyrusMCPPresetLifecycleChecks[5] "lifecycle_boundary" "Scope revoked or panel bridge/timer closed"
)
