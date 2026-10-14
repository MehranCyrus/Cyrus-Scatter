(
    if not matchPattern MCPFixtureDir pattern:"*/build/mcp-qualification/foundation-roadmap-p03-*/" do throw "Owned P03 host required"
    local log=createFile (MCPFixtureDir+"phase03-saved-baseline.txt")
    fn verify value label log = (format "%: %\n" (if value then "PASS" else "FAIL") label to:log;flush log;if not value do throw label)
    try (
        local suffix=if (maxVersion())[1]>=29000 then "2027-01" else "2026-02"
        local parent=pathConfig.appendPath MCPFixtureDir ".."
        local scene=pathConfig.appendPath parent ("foundation-roadmap-p02-max"+suffix+"/P02_persisted_settings.max")
        if not doesFileExist scene do throw "Qualified owned P02 scene is unavailable"
        CyrusPerfHeadless=true;resetMaxFile #noPrompt;loadMaxFile scene quiet:true
        local node=getNodeByName "P02 persisted presets",root=node.baseObject,leaf=root.layerObjects[1]
        verify (root.uiVersion()=="0.83.0" and root.procSchemaValid) "Saved schema 58 uses the current P03 definition" log
        verify (leaf.amount==55 and leaf.randomSeed==8765) "P02 population fields retain their meaning" log
        verify (not leaf.slopeEnabled and not leaf.altitudeEnabled) "New filters are neutral in a saved P02 scene" log
        verify (abs(leaf.movXMinWU-0.2*(units.decodeValue "1m"))<0.0001 and abs(leaf.wholeScaleMin-0.8)<0.0001) "P02 physical and dimensionless transforms survive new parameter fields" log
        root.refreshAll()
        verify (leaf.generatedCount==55 and leaf.previewError=="") "Previous schema-58 setup reconstructs its unfiltered result" log
        format "COMPLETE\n" to:log;close log
    )catch(format "ERROR: %\n" (getCurrentException()) to:log;close log;throw())
)
