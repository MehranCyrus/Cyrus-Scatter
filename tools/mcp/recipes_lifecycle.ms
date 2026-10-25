global MCPRecipesLifecycleRun,CyrusMCPRecipeLifecycleChecks
fn MCPRecipesLifecycleRun scenario = (
    if findItem #("reset","open","close") scenario==0 do throw "Unsupported recipe lifecycle case"
    python.Execute "import recipes_lifecycle_host; recipes_lifecycle_host.capture()"
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
    python.Execute ("recipes_lifecycle_host.verify('"+scenario+"')")
    QAssert CyrusMCPRecipeLifecycleChecks[1] "recipe_grant_revoked" "Recipe grant cleared immediately"
    QAssert CyrusMCPRecipeLifecycleChecks[2] "recipe_handle_released" "Adapter no longer holds its reader"
    QAssert CyrusMCPRecipeLifecycleChecks[3] "native_handle_rejected" "Closed native handle cannot read cached entries"
    QAssert CyrusMCPRecipeLifecycleChecks[4] "task_refs_released" "Task and native scene references cleared"
    QAssert CyrusMCPRecipeLifecycleChecks[5] "lifecycle_boundary" "Scope revoked or panel bridge/timer closed"
)
