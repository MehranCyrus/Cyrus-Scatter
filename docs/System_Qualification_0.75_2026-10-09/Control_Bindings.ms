-- Load only in an owned host after P07 definitions.
(
P07Case="All-control binding audit";P07New count:50
select P07Node;max modify mode;modPanel.setCurrentObject P07Root
if not P07Root.mainUI.controlsReady do P07Root.mainUI.mountTimer.tick()
for page in P07Root.mainUI.editors do (page.open=true;P07Root.mainUI.bindSection page)
local f=createFile (MCPFixtureDir+"control-bindings.tsv")
if not isProperty P07Root.displayUI #flow_previewUI_previewCheck do throw "Missing binding: general.previewUI.previewCheck"
format "general.previewUI.previewCheck\tBOUND\n" to:f
if not isProperty P07Root.displayUI #flow_previewUI_displayModeDrop do throw "Missing binding: general.previewUI.displayModeDrop"
format "general.previewUI.displayModeDrop\tBOUND\n" to:f
if not isProperty P07Root.displayUI #flow_previewUI_proxyShapeDrop do throw "Missing binding: general.previewUI.proxyShapeDrop"
format "general.previewUI.proxyShapeDrop\tBOUND\n" to:f
if not isProperty P07Root.displayUI #flow_previewUI_instancesLimitSpin do throw "Missing binding: general.previewUI.instancesLimitSpin"
format "general.previewUI.instancesLimitSpin\tBOUND\n" to:f
if not isProperty P07Root.displayUI #flow_previewUI_faceLimitSpin do throw "Missing binding: general.previewUI.faceLimitSpin"
format "general.previewUI.faceLimitSpin\tBOUND\n" to:f
if not isProperty P07Root.displayUI #flow_previewUI_identificationDrop do throw "Missing binding: general.previewUI.identificationDrop"
format "general.previewUI.identificationDrop\tBOUND\n" to:f
if not isProperty P07Root.displayUI #flow_previewUI_pointColorRadio do throw "Missing binding: general.previewUI.pointColorRadio"
format "general.previewUI.pointColorRadio\tBOUND\n" to:f
if not isProperty P07Root.displayUI #flow_previewUI_solidColorPicker do throw "Missing binding: general.previewUI.solidColorPicker"
format "general.previewUI.solidColorPicker\tBOUND\n" to:f
if not isProperty P07Root.displayUI #flow_previewUI_budgetSpin do throw "Missing binding: general.previewUI.budgetSpin"
format "general.previewUI.budgetSpin\tBOUND\n" to:f
if not isProperty P07Root.displayUI #flow_previewUI_pointsSpin do throw "Missing binding: general.previewUI.pointsSpin"
format "general.previewUI.pointsSpin\tBOUND\n" to:f
if not isProperty P07Root.displayUI #flow_previewUI_radiusLimitSpin do throw "Missing binding: general.previewUI.radiusLimitSpin"
format "general.previewUI.radiusLimitSpin\tBOUND\n" to:f
if not isProperty P07Root.displayUI #flow_previewUI_radiusAllCheck do throw "Missing binding: general.previewUI.radiusAllCheck"
format "general.previewUI.radiusAllCheck\tBOUND\n" to:f
if not isProperty P07Root.displayUI #flow_previewUI_iconSpin do throw "Missing binding: general.previewUI.iconSpin"
format "general.previewUI.iconSpin\tBOUND\n" to:f
if not isProperty P07Root.displayUI #flow_previewUI_refreshButton do throw "Missing binding: general.previewUI.refreshButton"
format "general.previewUI.refreshButton\tBOUND\n" to:f
if not isProperty P07Root.displayUI #flow_previewUI_autoRenderCheck do throw "Missing binding: general.previewUI.autoRenderCheck"
format "general.previewUI.autoRenderCheck\tBOUND\n" to:f
if not isProperty P07Root.displayUI #flow_previewUI_clearBakedButton do throw "Missing binding: general.previewUI.clearBakedButton"
format "general.previewUI.clearBakedButton\tBOUND\n" to:f
if not isProperty P07Root.surfacesUI #flow_surfaceUI_receiversList do throw "Missing binding: general.surface.receiversList"
format "general.surface.receiversList\tBOUND\n" to:f
if not isProperty P07Root.surfacesUI #flow_surfaceUI_removeSurfaces do throw "Missing binding: general.surface.removeSurfaces"
format "general.surface.removeSurfaces\tBOUND\n" to:f
if not isProperty P07Root.surfacesUI #flow_surfaceUI_sharedPick do throw "Missing binding: general.surface.sharedPick"
format "general.surface.sharedPick\tBOUND\n" to:f
if not isProperty P07Root.surfacesUI #flow_surfaceUI_surfacesButton do throw "Missing binding: general.surface.surfacesButton"
format "general.surface.surfacesButton\tBOUND\n" to:f
if not isProperty P07Root.surfacesUI #flow_surfaceUI_containersToggle do throw "Missing binding: general.surface.containersToggle"
format "general.surface.containersToggle\tBOUND\n" to:f
if not isProperty P07Root.surfacesUI #flow_surfaceUI_globalContainers do throw "Missing binding: general.surface.globalContainers"
format "general.surface.globalContainers\tBOUND\n" to:f
if not isProperty P07Root.surfacesUI #flow_surfaceUI_createContainer do throw "Missing binding: general.surface.createContainer"
format "general.surface.createContainer\tBOUND\n" to:f
if not isProperty P07Root.surfacesUI #flow_surfaceUI_pickContainer do throw "Missing binding: general.surface.pickContainer"
format "general.surface.pickContainer\tBOUND\n" to:f
if not isProperty P07Root.surfacesUI #flow_surfaceUI_removeContainer do throw "Missing binding: general.surface.removeContainer"
format "general.surface.removeContainer\tBOUND\n" to:f
if not isProperty P07Root.managerUI #flow_layersUI_layerList do throw "Missing binding: general.manager.layerList"
format "general.manager.layerList\tBOUND\n" to:f
if not isProperty P07Root.managerUI #flow_layersUI_editButton do throw "Missing binding: general.manager.editButton"
format "general.manager.editButton\tBOUND\n" to:f
if not isProperty P07Root.managerUI #flow_layersUI_addButton do throw "Missing binding: general.manager.addButton"
format "general.manager.addButton\tBOUND\n" to:f
if not isProperty P07Root.managerUI #flow_layersUI_copyButton do throw "Missing binding: general.manager.copyButton"
format "general.manager.copyButton\tBOUND\n" to:f
if not isProperty P07Root.managerUI #flow_layersUI_removeButton do throw "Missing binding: general.manager.removeButton"
format "general.manager.removeButton\tBOUND\n" to:f
if not isProperty P07Root.managerUI #flow_layersUI_layerColor do throw "Missing binding: general.manager.layerColor"
format "general.manager.layerColor\tBOUND\n" to:f
if not isProperty P07Root.managerUI #flow_layersUI_nameEdit do throw "Missing binding: general.manager.nameEdit"
format "general.manager.nameEdit\tBOUND\n" to:f
if not isProperty P07Root.managerUI #flow_layersUI_visibleCheck do throw "Missing binding: general.manager.visibleCheck"
format "general.manager.visibleCheck\tBOUND\n" to:f
if not isProperty P07Root.managerUI #flow_layersUI_enabledCheck do throw "Missing binding: general.manager.enabledCheck"
format "general.manager.enabledCheck\tBOUND\n" to:f
if not isProperty P07Root.managerUI #flow_layersUI_upButton do throw "Missing binding: general.manager.upButton"
format "general.manager.upButton\tBOUND\n" to:f
if not isProperty P07Root.managerUI #flow_layersUI_downButton do throw "Missing binding: general.manager.downButton"
format "general.manager.downButton\tBOUND\n" to:f
if not isProperty P07Root.statisticsUI #diagnosticsUI_startButton do throw "Missing binding: general.diagnostics.startButton"
format "general.diagnostics.startButton\tBOUND\n" to:f
if not isProperty P07Root.statisticsUI #diagnosticsUI_stopButton do throw "Missing binding: general.diagnostics.stopButton"
format "general.diagnostics.stopButton\tBOUND\n" to:f
if not isProperty P07Root.statisticsUI #diagnosticsUI_saveButton do throw "Missing binding: general.diagnostics.saveButton"
format "general.diagnostics.saveButton\tBOUND\n" to:f
if not isProperty P07Root.statisticsUI #diagnosticsUI_refreshButton do throw "Missing binding: general.diagnostics.refreshButton"
format "general.diagnostics.refreshButton\tBOUND\n" to:f
if not isProperty P07Root.coverageUI #setsUI_paintedCheck do throw "Missing binding: layer.setsUI.paintedCheck"
format "layer.setsUI.paintedCheck\tBOUND\n" to:f
if not isProperty P07Root.coverageUI #setsUI_importButton do throw "Missing binding: layer.setsUI.importButton"
format "layer.setsUI.importButton\tBOUND\n" to:f
if not isProperty P07Root.coverageUI #setsUI_setList do throw "Missing binding: layer.setsUI.setList"
format "layer.setsUI.setList\tBOUND\n" to:f
if not isProperty P07Root.coverageUI #setsUI_addButton do throw "Missing binding: layer.setsUI.addButton"
format "layer.setsUI.addButton\tBOUND\n" to:f
if not isProperty P07Root.coverageUI #setsUI_removeButton do throw "Missing binding: layer.setsUI.removeButton"
format "layer.setsUI.removeButton\tBOUND\n" to:f
if not isProperty P07Root.coverageUI #setsUI_nameEdit do throw "Missing binding: layer.setsUI.nameEdit"
format "layer.setsUI.nameEdit\tBOUND\n" to:f
if not isProperty P07Root.coverageUI #setsUI_targetList do throw "Missing binding: layer.setsUI.targetList"
format "layer.setsUI.targetList\tBOUND\n" to:f
if not isProperty P07Root.coverageUI #setsUI_enabledCheck do throw "Missing binding: layer.setsUI.enabledCheck"
format "layer.setsUI.enabledCheck\tBOUND\n" to:f
if not isProperty P07Root.modelsUI #sourceUI_sourceName do throw "Missing binding: layer.sourceUI.sourceName"
format "layer.sourceUI.sourceName\tBOUND\n" to:f
if not isProperty P07Root.modelsUI #sourceUI_idColor do throw "Missing binding: layer.sourceUI.idColor"
format "layer.sourceUI.idColor\tBOUND\n" to:f
if not isProperty P07Root.modelsUI #sourceUI_plantList do throw "Missing binding: layer.sourceUI.plantList"
format "layer.sourceUI.plantList\tBOUND\n" to:f
if not isProperty P07Root.modelsUI #sourceUI_selectFromScene do throw "Missing binding: layer.sourceUI.selectFromScene"
format "layer.sourceUI.selectFromScene\tBOUND\n" to:f
if not isProperty P07Root.modelsUI #sourceUI_addPlant do throw "Missing binding: layer.sourceUI.addPlant"
format "layer.sourceUI.addPlant\tBOUND\n" to:f
if not isProperty P07Root.modelsUI #sourceUI_addSelected do throw "Missing binding: layer.sourceUI.addSelected"
format "layer.sourceUI.addSelected\tBOUND\n" to:f
if not isProperty P07Root.modelsUI #sourceUI_removePlant do throw "Missing binding: layer.sourceUI.removePlant"
format "layer.sourceUI.removePlant\tBOUND\n" to:f
if not isProperty P07Root.modelsUI #sourceUI_selectPlant do throw "Missing binding: layer.sourceUI.selectPlant"
format "layer.sourceUI.selectPlant\tBOUND\n" to:f
if not isProperty P07Root.modelsUI #sourceUI_addPoint do throw "Missing binding: layer.sourceUI.addPoint"
format "layer.sourceUI.addPoint\tBOUND\n" to:f
if not isProperty P07Root.modelsUI #sourceUI_addEmpty do throw "Missing binding: layer.sourceUI.addEmpty"
format "layer.sourceUI.addEmpty\tBOUND\n" to:f
if not isProperty P07Root.modelsUI #sourceUI_replacePoint do throw "Missing binding: layer.sourceUI.replacePoint"
format "layer.sourceUI.replacePoint\tBOUND\n" to:f
if not isProperty P07Root.modelsUI #sourceUI_existingGroups do throw "Missing binding: layer.sourceUI.existingGroups"
format "layer.sourceUI.existingGroups\tBOUND\n" to:f
if not isProperty P07Root.modelsUI #sourceUI_groupColor do throw "Missing binding: layer.sourceUI.groupColor"
format "layer.sourceUI.groupColor\tBOUND\n" to:f
if not isProperty P07Root.modelsUI #sourceUI_applyColor do throw "Missing binding: layer.sourceUI.applyColor"
format "layer.sourceUI.applyColor\tBOUND\n" to:f
if not isProperty P07Root.modelsUI #sourceUI_weightSpin do throw "Missing binding: layer.sourceUI.weightSpin"
format "layer.sourceUI.weightSpin\tBOUND\n" to:f
if not isProperty P07Root.modelsUI #sourceUI_sourceZSpin do throw "Missing binding: layer.sourceUI.sourceZSpin"
format "layer.sourceUI.sourceZSpin\tBOUND\n" to:f
if not isProperty P07Root.modelsUI #sourceUI_sourceScaleSpin do throw "Missing binding: layer.sourceUI.sourceScaleSpin"
format "layer.sourceUI.sourceScaleSpin\tBOUND\n" to:f
if not isProperty P07Root.modelsUI #sourceUI_radiusSourceSpin do throw "Missing binding: layer.sourceUI.radiusSourceSpin"
format "layer.sourceUI.radiusSourceSpin\tBOUND\n" to:f
if not isProperty P07Root.modelsUI #sourceUI_followRadiusCheck do throw "Missing binding: layer.sourceUI.followRadiusCheck"
format "layer.sourceUI.followRadiusCheck\tBOUND\n" to:f
if not isProperty P07Root.modelsUI #sourceUI_showRadiusCheck do throw "Missing binding: layer.sourceUI.showRadiusCheck"
format "layer.sourceUI.showRadiusCheck\tBOUND\n" to:f
if not isProperty P07Root.modelsUI #sourceUI_forwardAxis do throw "Missing binding: layer.sourceUI.forwardAxis"
format "layer.sourceUI.forwardAxis\tBOUND\n" to:f
if not isProperty P07Root.modelsUI #sourceUI_detailsToggle do throw "Missing binding: layer.sourceUI.detailsToggle"
format "layer.sourceUI.detailsToggle\tBOUND\n" to:f
if not isProperty P07Root.modelsUI #sourceContainersUI_modeList do throw "Missing binding: layer.sourceContainersUI.modeList"
format "layer.sourceContainersUI.modeList\tBOUND\n" to:f
if not isProperty P07Root.modelsUI #sourceContainersUI_containersList do throw "Missing binding: layer.sourceContainersUI.containersList"
format "layer.sourceContainersUI.containersList\tBOUND\n" to:f
if not isProperty P07Root.modelsUI #sourceContainersUI_createContainer do throw "Missing binding: layer.sourceContainersUI.createContainer"
format "layer.sourceContainersUI.createContainer\tBOUND\n" to:f
if not isProperty P07Root.modelsUI #sourceContainersUI_pickContainer do throw "Missing binding: layer.sourceContainersUI.pickContainer"
format "layer.sourceContainersUI.pickContainer\tBOUND\n" to:f
if not isProperty P07Root.modelsUI #sourceContainersUI_removeContainer do throw "Missing binding: layer.sourceContainersUI.removeContainer"
format "layer.sourceContainersUI.removeContainer\tBOUND\n" to:f
if not isProperty P07Root.populationUI #distributionUI_modeRadio do throw "Missing binding: layer.distributionUI.modeRadio"
format "layer.distributionUI.modeRadio\tBOUND\n" to:f
if not isProperty P07Root.populationUI #distributionUI_populationRadio do throw "Missing binding: layer.distributionUI.populationRadio"
format "layer.distributionUI.populationRadio\tBOUND\n" to:f
if not isProperty P07Root.populationUI #distributionUI_countSpin do throw "Missing binding: layer.distributionUI.countSpin"
format "layer.distributionUI.countSpin\tBOUND\n" to:f
if not isProperty P07Root.populationUI #distributionUI_densitySpin do throw "Missing binding: layer.distributionUI.densitySpin"
format "layer.distributionUI.densitySpin\tBOUND\n" to:f
if not isProperty P07Root.populationUI #distributionUI_seedSpin do throw "Missing binding: layer.distributionUI.seedSpin"
format "layer.distributionUI.seedSpin\tBOUND\n" to:f
if not isProperty P07Root.populationUI #distributionUI_densityButton do throw "Missing binding: layer.distributionUI.densityButton"
format "layer.distributionUI.densityButton\tBOUND\n" to:f
if not isProperty P07Root.populationUI #distributionUI_invertCheck do throw "Missing binding: layer.distributionUI.invertCheck"
format "layer.distributionUI.invertCheck\tBOUND\n" to:f
if not isProperty P07Root.populationUI #populationPolicyUI_populationList do throw "Missing binding: layer.populationPolicyUI.populationList"
format "layer.populationPolicyUI.populationList\tBOUND\n" to:f
if not isProperty P07Root.populationUI #populationPolicyUI_attemptSpin do throw "Missing binding: layer.populationPolicyUI.attemptSpin"
format "layer.populationPolicyUI.attemptSpin\tBOUND\n" to:f
if not isProperty P07Root.populationUI #populationPolicyUI_roundSpin do throw "Missing binding: layer.populationPolicyUI.roundSpin"
format "layer.populationPolicyUI.roundSpin\tBOUND\n" to:f
if not isProperty P07Root.populationUI #populationPolicyUI_repairCheck do throw "Missing binding: layer.populationPolicyUI.repairCheck"
format "layer.populationPolicyUI.repairCheck\tBOUND\n" to:f
if not isProperty P07Root.areasUI #areaUI_areaList do throw "Missing binding: layer.areaUI.areaList"
format "layer.areaUI.areaList\tBOUND\n" to:f
if not isProperty P07Root.areasUI #areaUI_addAreaScene do throw "Missing binding: layer.areaUI.addAreaScene"
format "layer.areaUI.addAreaScene\tBOUND\n" to:f
if not isProperty P07Root.areasUI #areaUI_pickArea do throw "Missing binding: layer.areaUI.pickArea"
format "layer.areaUI.pickArea\tBOUND\n" to:f
if not isProperty P07Root.areasUI #areaUI_removeArea do throw "Missing binding: layer.areaUI.removeArea"
format "layer.areaUI.removeArea\tBOUND\n" to:f
if not isProperty P07Root.areasUI #areaUI_areaMode do throw "Missing binding: layer.areaUI.areaMode"
format "layer.areaUI.areaMode\tBOUND\n" to:f
if not isProperty P07Root.areasUI #areaUI_refreshAreas do throw "Missing binding: layer.areaUI.refreshAreas"
format "layer.areaUI.refreshAreas\tBOUND\n" to:f
if not isProperty P07Root.areasUI #areaUI_aaPick do throw "Missing binding: layer.areaUI.aaPick"
format "layer.areaUI.aaPick\tBOUND\n" to:f
if not isProperty P07Root.areasUI #areaUI_aaRemove do throw "Missing binding: layer.areaUI.aaRemove"
format "layer.areaUI.aaRemove\tBOUND\n" to:f
if not isProperty P07Root.areasUI #areaUI_aaLine do throw "Missing binding: layer.areaUI.aaLine"
format "layer.areaUI.aaLine\tBOUND\n" to:f
if not isProperty P07Root.areasUI #areaUI_aaWidth do throw "Missing binding: layer.areaUI.aaWidth"
format "layer.areaUI.aaWidth\tBOUND\n" to:f
if not isProperty P07Root.areasUI #areaUI_aaCaps do throw "Missing binding: layer.areaUI.aaCaps"
format "layer.areaUI.aaCaps\tBOUND\n" to:f
if not isProperty P07Root.areasUI #areaUI_aaStreetOffset do throw "Missing binding: layer.areaUI.aaStreetOffset"
format "layer.areaUI.aaStreetOffset\tBOUND\n" to:f
if not isProperty P07Root.areasUI #areaUI_aaPoints do throw "Missing binding: layer.areaUI.aaPoints"
format "layer.areaUI.aaPoints\tBOUND\n" to:f
if not isProperty P07Root.areasUI #areaUI_aaRadius do throw "Missing binding: layer.areaUI.aaRadius"
format "layer.areaUI.aaRadius\tBOUND\n" to:f
if not isProperty P07Root.areasUI #areaUI_fallTarget do throw "Missing binding: layer.areaUI.fallTarget"
format "layer.areaUI.fallTarget\tBOUND\n" to:f
if not isProperty P07Root.areasUI #areaUI_fallPick do throw "Missing binding: layer.areaUI.fallPick"
format "layer.areaUI.fallPick\tBOUND\n" to:f
if not isProperty P07Root.areasUI #areaUI_fallRemove do throw "Missing binding: layer.areaUI.fallRemove"
format "layer.areaUI.fallRemove\tBOUND\n" to:f
if not isProperty P07Root.areasUI #areaUI_fallDeleteCheck do throw "Missing binding: layer.areaUI.fallDeleteCheck"
format "layer.areaUI.fallDeleteCheck\tBOUND\n" to:f
if not isProperty P07Root.areasUI #areaUI_fallDeleteSpin do throw "Missing binding: layer.areaUI.fallDeleteSpin"
format "layer.areaUI.fallDeleteSpin\tBOUND\n" to:f
if not isProperty P07Root.areasUI #areaUI_fallScaleCheck do throw "Missing binding: layer.areaUI.fallScaleCheck"
format "layer.areaUI.fallScaleCheck\tBOUND\n" to:f
if not isProperty P07Root.areasUI #areaUI_fallScaleSpin do throw "Missing binding: layer.areaUI.fallScaleSpin"
format "layer.areaUI.fallScaleSpin\tBOUND\n" to:f
if not isProperty P07Root.areasUI #areaUI_fallScaleEdit do throw "Missing binding: layer.areaUI.fallScaleEdit"
format "layer.areaUI.fallScaleEdit\tBOUND\n" to:f
if not isProperty P07Root.areasUI #areaUI_fallDensityCheck do throw "Missing binding: layer.areaUI.fallDensityCheck"
format "layer.areaUI.fallDensityCheck\tBOUND\n" to:f
if not isProperty P07Root.areasUI #areaUI_fallDensitySpin do throw "Missing binding: layer.areaUI.fallDensitySpin"
format "layer.areaUI.fallDensitySpin\tBOUND\n" to:f
if not isProperty P07Root.areasUI #areaUI_fallDensityEdit do throw "Missing binding: layer.areaUI.fallDensityEdit"
format "layer.areaUI.fallDensityEdit\tBOUND\n" to:f
if not isProperty P07Root.areasUI #areaUI_detailsToggle do throw "Missing binding: layer.areaUI.detailsToggle"
format "layer.areaUI.detailsToggle\tBOUND\n" to:f
if not isProperty P07Root.coverageUI #brushUI_modeRadio do throw "Missing binding: layer.brushUI.modeRadio"
format "layer.brushUI.modeRadio\tBOUND\n" to:f
if not isProperty P07Root.coverageUI #brushUI_radiusSpin do throw "Missing binding: layer.brushUI.radiusSpin"
format "layer.brushUI.radiusSpin\tBOUND\n" to:f
if not isProperty P07Root.coverageUI #brushUI_strengthSpin do throw "Missing binding: layer.brushUI.strengthSpin"
format "layer.brushUI.strengthSpin\tBOUND\n" to:f
if not isProperty P07Root.coverageUI #brushUI_softSpin do throw "Missing binding: layer.brushUI.softSpin"
format "layer.brushUI.softSpin\tBOUND\n" to:f
if not isProperty P07Root.coverageUI #brushUI_beginButton do throw "Missing binding: layer.brushUI.beginButton"
format "layer.brushUI.beginButton\tBOUND\n" to:f
if not isProperty P07Root.coverageUI #brushUI_stopButton do throw "Missing binding: layer.brushUI.stopButton"
format "layer.brushUI.stopButton\tBOUND\n" to:f
if not isProperty P07Root.coverageUI #brushUI_fillButton do throw "Missing binding: layer.brushUI.fillButton"
format "layer.brushUI.fillButton\tBOUND\n" to:f
if not isProperty P07Root.coverageUI #brushUI_emptyButton do throw "Missing binding: layer.brushUI.emptyButton"
format "layer.brushUI.emptyButton\tBOUND\n" to:f
if not isProperty P07Root.coverageUI #brushUI_densitySpin do throw "Missing binding: layer.brushUI.densitySpin"
format "layer.brushUI.densitySpin\tBOUND\n" to:f
if not isProperty P07Root.coverageUI #brushUI_overlayMode do throw "Missing binding: layer.brushUI.overlayMode"
format "layer.brushUI.overlayMode\tBOUND\n" to:f
if not isProperty P07Root.coverageUI #brushUI_overlayColor do throw "Missing binding: layer.brushUI.overlayColor"
format "layer.brushUI.overlayColor\tBOUND\n" to:f
if not isProperty P07Root.transformsUI #randomUI_rotXMinSpin do throw "Missing binding: layer.randomUI.rotXMinSpin"
format "layer.randomUI.rotXMinSpin\tBOUND\n" to:f
if not isProperty P07Root.transformsUI #randomUI_rotXMaxSpin do throw "Missing binding: layer.randomUI.rotXMaxSpin"
format "layer.randomUI.rotXMaxSpin\tBOUND\n" to:f
if not isProperty P07Root.transformsUI #randomUI_rotYMinSpin do throw "Missing binding: layer.randomUI.rotYMinSpin"
format "layer.randomUI.rotYMinSpin\tBOUND\n" to:f
if not isProperty P07Root.transformsUI #randomUI_rotYMaxSpin do throw "Missing binding: layer.randomUI.rotYMaxSpin"
format "layer.randomUI.rotYMaxSpin\tBOUND\n" to:f
if not isProperty P07Root.transformsUI #randomUI_rotZMinSpin do throw "Missing binding: layer.randomUI.rotZMinSpin"
format "layer.randomUI.rotZMinSpin\tBOUND\n" to:f
if not isProperty P07Root.transformsUI #randomUI_rotZMaxSpin do throw "Missing binding: layer.randomUI.rotZMaxSpin"
format "layer.randomUI.rotZMaxSpin\tBOUND\n" to:f
if not isProperty P07Root.transformsUI #randomUI_sclXMinSpin do throw "Missing binding: layer.randomUI.sclXMinSpin"
format "layer.randomUI.sclXMinSpin\tBOUND\n" to:f
if not isProperty P07Root.transformsUI #randomUI_sclXMaxSpin do throw "Missing binding: layer.randomUI.sclXMaxSpin"
format "layer.randomUI.sclXMaxSpin\tBOUND\n" to:f
if not isProperty P07Root.transformsUI #randomUI_sclYMinSpin do throw "Missing binding: layer.randomUI.sclYMinSpin"
format "layer.randomUI.sclYMinSpin\tBOUND\n" to:f
if not isProperty P07Root.transformsUI #randomUI_sclYMaxSpin do throw "Missing binding: layer.randomUI.sclYMaxSpin"
format "layer.randomUI.sclYMaxSpin\tBOUND\n" to:f
if not isProperty P07Root.transformsUI #randomUI_sclZMinSpin do throw "Missing binding: layer.randomUI.sclZMinSpin"
format "layer.randomUI.sclZMinSpin\tBOUND\n" to:f
if not isProperty P07Root.transformsUI #randomUI_sclZMaxSpin do throw "Missing binding: layer.randomUI.sclZMaxSpin"
format "layer.randomUI.sclZMaxSpin\tBOUND\n" to:f
if not isProperty P07Root.transformsUI #randomUI_wholeMinSpin do throw "Missing binding: layer.randomUI.wholeMinSpin"
format "layer.randomUI.wholeMinSpin\tBOUND\n" to:f
if not isProperty P07Root.transformsUI #randomUI_wholeMaxSpin do throw "Missing binding: layer.randomUI.wholeMaxSpin"
format "layer.randomUI.wholeMaxSpin\tBOUND\n" to:f
if not isProperty P07Root.transformsUI #randomUI_movXMinSpin do throw "Missing binding: layer.randomUI.movXMinSpin"
format "layer.randomUI.movXMinSpin\tBOUND\n" to:f
if not isProperty P07Root.transformsUI #randomUI_movXMaxSpin do throw "Missing binding: layer.randomUI.movXMaxSpin"
format "layer.randomUI.movXMaxSpin\tBOUND\n" to:f
if not isProperty P07Root.transformsUI #randomUI_movYMinSpin do throw "Missing binding: layer.randomUI.movYMinSpin"
format "layer.randomUI.movYMinSpin\tBOUND\n" to:f
if not isProperty P07Root.transformsUI #randomUI_movYMaxSpin do throw "Missing binding: layer.randomUI.movYMaxSpin"
format "layer.randomUI.movYMaxSpin\tBOUND\n" to:f
if not isProperty P07Root.transformsUI #randomUI_movZMinSpin do throw "Missing binding: layer.randomUI.movZMinSpin"
format "layer.randomUI.movZMinSpin\tBOUND\n" to:f
if not isProperty P07Root.transformsUI #randomUI_movZMaxSpin do throw "Missing binding: layer.randomUI.movZMaxSpin"
format "layer.randomUI.movZMaxSpin\tBOUND\n" to:f
if not isProperty P07Root.transformsUI #randomUI_projectCheck do throw "Missing binding: layer.randomUI.projectCheck"
format "layer.randomUI.projectCheck\tBOUND\n" to:f
if not isProperty P07Root.transformsUI #randomUI_alignCheck do throw "Missing binding: layer.randomUI.alignCheck"
format "layer.randomUI.alignCheck\tBOUND\n" to:f
if not isProperty P07Root.transformsUI #randomUI_resetRotation do throw "Missing binding: layer.randomUI.resetRotation"
format "layer.randomUI.resetRotation\tBOUND\n" to:f
if not isProperty P07Root.transformsUI #randomUI_resetScale do throw "Missing binding: layer.randomUI.resetScale"
format "layer.randomUI.resetScale\tBOUND\n" to:f
if not isProperty P07Root.transformsUI #randomUI_resetWholeScale do throw "Missing binding: layer.randomUI.resetWholeScale"
format "layer.randomUI.resetWholeScale\tBOUND\n" to:f
if not isProperty P07Root.transformsUI #randomUI_resetMovement do throw "Missing binding: layer.randomUI.resetMovement"
format "layer.randomUI.resetMovement\tBOUND\n" to:f
if not isProperty P07Root.layoutUI #diversityUI_diversityRadio do throw "Missing binding: layer.diversityUI.diversityRadio"
format "layer.diversityUI.diversityRadio\tBOUND\n" to:f
if not isProperty P07Root.layoutUI #diversityUI_selectAnalyzer do throw "Missing binding: layer.diversityUI.selectAnalyzer"
format "layer.diversityUI.selectAnalyzer\tBOUND\n" to:f
if not isProperty P07Root.layoutUI #diversityUI_updateAnalyzer do throw "Missing binding: layer.diversityUI.updateAnalyzer"
format "layer.diversityUI.updateAnalyzer\tBOUND\n" to:f
if not isProperty P07Root.layoutUI #diversityUI_sizeSpin do throw "Missing binding: layer.diversityUI.sizeSpin"
format "layer.diversityUI.sizeSpin\tBOUND\n" to:f
if not isProperty P07Root.layoutUI #diversityUI_divSeedSpin do throw "Missing binding: layer.diversityUI.divSeedSpin"
format "layer.diversityUI.divSeedSpin\tBOUND\n" to:f
if not isProperty P07Root.layoutUI #diversityUI_roughSpin do throw "Missing binding: layer.diversityUI.roughSpin"
format "layer.diversityUI.roughSpin\tBOUND\n" to:f
if not isProperty P07Root.layoutUI #diversityUI_blurSpin do throw "Missing binding: layer.diversityUI.blurSpin"
format "layer.diversityUI.blurSpin\tBOUND\n" to:f
if not isProperty P07Root.layoutUI #diversityUI_noiseSpin do throw "Missing binding: layer.diversityUI.noiseSpin"
format "layer.diversityUI.noiseSpin\tBOUND\n" to:f
if not isProperty P07Root.layoutUI #diversityUI_pathsDrop do throw "Missing binding: layer.diversityUI.pathsDrop"
format "layer.diversityUI.pathsDrop\tBOUND\n" to:f
if not isProperty P07Root.layoutUI #diversityUI_analyzerChannel do throw "Missing binding: layer.diversityUI.analyzerChannel"
format "layer.diversityUI.analyzerChannel\tBOUND\n" to:f
if not isProperty P07Root.layoutUI #diversityUI_pickAnalyzer do throw "Missing binding: layer.diversityUI.pickAnalyzer"
format "layer.diversityUI.pickAnalyzer\tBOUND\n" to:f
if not isProperty P07Root.layoutUI #diversityUI_pickPath do throw "Missing binding: layer.diversityUI.pickPath"
format "layer.diversityUI.pickPath\tBOUND\n" to:f
if not isProperty P07Root.layoutUI #diversityUI_removePath do throw "Missing binding: layer.diversityUI.removePath"
format "layer.diversityUI.removePath\tBOUND\n" to:f
if not isProperty P07Root.layoutUI #diversityUI_strokesList do throw "Missing binding: layer.diversityUI.strokesList"
format "layer.diversityUI.strokesList\tBOUND\n" to:f
if not isProperty P07Root.layoutUI #diversityUI_addOutside do throw "Missing binding: layer.diversityUI.addOutside"
format "layer.diversityUI.addOutside\tBOUND\n" to:f
if not isProperty P07Root.layoutUI #diversityUI_addInside do throw "Missing binding: layer.diversityUI.addInside"
format "layer.diversityUI.addInside\tBOUND\n" to:f
if not isProperty P07Root.layoutUI #diversityUI_removeStrokeButton do throw "Missing binding: layer.diversityUI.removeStrokeButton"
format "layer.diversityUI.removeStrokeButton\tBOUND\n" to:f
if not isProperty P07Root.layoutUI #diversityUI_strokeWidth do throw "Missing binding: layer.diversityUI.strokeWidth"
format "layer.diversityUI.strokeWidth\tBOUND\n" to:f
if not isProperty P07Root.layoutUI #diversityUI_strokeMode do throw "Missing binding: layer.diversityUI.strokeMode"
format "layer.diversityUI.strokeMode\tBOUND\n" to:f
if not isProperty P07Root.layoutUI #diversityUI_strokeChoices do throw "Missing binding: layer.diversityUI.strokeChoices"
format "layer.diversityUI.strokeChoices\tBOUND\n" to:f
if not isProperty P07Root.layoutUI #diversityUI_strokeScaleMin do throw "Missing binding: layer.diversityUI.strokeScaleMin"
format "layer.diversityUI.strokeScaleMin\tBOUND\n" to:f
if not isProperty P07Root.layoutUI #diversityUI_strokeScaleMax do throw "Missing binding: layer.diversityUI.strokeScaleMax"
format "layer.diversityUI.strokeScaleMax\tBOUND\n" to:f
if not isProperty P07Root.layoutUI #diversityUI_refreshGroups do throw "Missing binding: layer.diversityUI.refreshGroups"
format "layer.diversityUI.refreshGroups\tBOUND\n" to:f
if not isProperty P07Root.layoutUI #diversityUI_edgeOffsetSpin do throw "Missing binding: layer.diversityUI.edgeOffsetSpin"
format "layer.diversityUI.edgeOffsetSpin\tBOUND\n" to:f
if not isProperty P07Root.layoutUI #diversityUI_edgeAlongSpin do throw "Missing binding: layer.diversityUI.edgeAlongSpin"
format "layer.diversityUI.edgeAlongSpin\tBOUND\n" to:f
if not isProperty P07Root.layoutUI #diversityUI_edgeAcrossSpin do throw "Missing binding: layer.diversityUI.edgeAcrossSpin"
format "layer.diversityUI.edgeAcrossSpin\tBOUND\n" to:f
if not isProperty P07Root.layoutUI #diversityUI_keepCornerCheck do throw "Missing binding: layer.diversityUI.keepCornerCheck"
format "layer.diversityUI.keepCornerCheck\tBOUND\n" to:f
if not isProperty P07Root.layoutUI #diversityUI_cornerAngleSpin do throw "Missing binding: layer.diversityUI.cornerAngleSpin"
format "layer.diversityUI.cornerAngleSpin\tBOUND\n" to:f
if not isProperty P07Root.layoutUI #diversityUI_cornerCountSpin do throw "Missing binding: layer.diversityUI.cornerCountSpin"
format "layer.diversityUI.cornerCountSpin\tBOUND\n" to:f
if not isProperty P07Root.layoutUI #diversityUI_edgeRotXSpin do throw "Missing binding: layer.diversityUI.edgeRotXSpin"
format "layer.diversityUI.edgeRotXSpin\tBOUND\n" to:f
if not isProperty P07Root.layoutUI #diversityUI_edgeRotYSpin do throw "Missing binding: layer.diversityUI.edgeRotYSpin"
format "layer.diversityUI.edgeRotYSpin\tBOUND\n" to:f
if not isProperty P07Root.layoutUI #diversityUI_edgeRotZSpin do throw "Missing binding: layer.diversityUI.edgeRotZSpin"
format "layer.diversityUI.edgeRotZSpin\tBOUND\n" to:f
if not isProperty P07Root.layoutUI #diversityUI_streetStartSpin do throw "Missing binding: layer.diversityUI.streetStartSpin"
format "layer.diversityUI.streetStartSpin\tBOUND\n" to:f
if not isProperty P07Root.layoutUI #diversityUI_streetEndSpin do throw "Missing binding: layer.diversityUI.streetEndSpin"
format "layer.diversityUI.streetEndSpin\tBOUND\n" to:f
if not isProperty P07Root.layoutUI #diversityUI_centerStreetSpin do throw "Missing binding: layer.diversityUI.centerStreetSpin"
format "layer.diversityUI.centerStreetSpin\tBOUND\n" to:f
if not isProperty P07Root.layoutUI #diversityUI_faceOutCheck do throw "Missing binding: layer.diversityUI.faceOutCheck"
format "layer.diversityUI.faceOutCheck\tBOUND\n" to:f
if not isProperty P07Root.layoutUI #diversityUI_cornerRadiusSpin do throw "Missing binding: layer.diversityUI.cornerRadiusSpin"
format "layer.diversityUI.cornerRadiusSpin\tBOUND\n" to:f
if not isProperty P07Root.layoutUI #diversityUI_straightStreet do throw "Missing binding: layer.diversityUI.straightStreet"
format "layer.diversityUI.straightStreet\tBOUND\n" to:f
if not isProperty P07Root.spacingUI #proceduralUI_scopeList do throw "Missing binding: layer.proceduralUI.scopeList"
format "layer.proceduralUI.scopeList\tBOUND\n" to:f
if not isProperty P07Root.spacingUI #proceduralUI_peerList do throw "Missing binding: layer.proceduralUI.peerList"
format "layer.proceduralUI.peerList\tBOUND\n" to:f
if not isProperty P07Root.spacingUI #proceduralUI_enabledCheck do throw "Missing binding: layer.proceduralUI.enabledCheck"
format "layer.proceduralUI.enabledCheck\tBOUND\n" to:f
if not isProperty P07Root.spacingUI #proceduralUI_multiplierSpin do throw "Missing binding: layer.proceduralUI.multiplierSpin"
format "layer.proceduralUI.multiplierSpin\tBOUND\n" to:f
if not isProperty P07Root.spacingUI #proceduralUI_gapSpin do throw "Missing binding: layer.proceduralUI.gapSpin"
format "layer.proceduralUI.gapSpin\tBOUND\n" to:f
if not isProperty P07Root.spacingUI #proceduralUI_planarCheck do throw "Missing binding: layer.proceduralUI.planarCheck"
format "layer.proceduralUI.planarCheck\tBOUND\n" to:f
if not isProperty P07Root.spacingUI #proceduralUI_resetRule do throw "Missing binding: layer.proceduralUI.resetRule"
format "layer.proceduralUI.resetRule\tBOUND\n" to:f
if not isProperty P07Root.spacingUI #instanceRadiusUI_radiusMode do throw "Missing binding: layer.instanceRadiusUI.radiusMode"
format "layer.instanceRadiusUI.radiusMode\tBOUND\n" to:f
if not isProperty P07Root.spacingUI #instanceRadiusUI_radiusSpin do throw "Missing binding: layer.instanceRadiusUI.radiusSpin"
format "layer.instanceRadiusUI.radiusSpin\tBOUND\n" to:f
if not isProperty P07Root.spacingUI #instanceRadiusUI_applyRadius do throw "Missing binding: layer.instanceRadiusUI.applyRadius"
format "layer.instanceRadiusUI.applyRadius\tBOUND\n" to:f
if not isProperty P07Root.spacingUI #instanceRadiusUI_resetRadius do throw "Missing binding: layer.instanceRadiusUI.resetRadius"
format "layer.instanceRadiusUI.resetRadius\tBOUND\n" to:f
if not isProperty P07Root.spacingUI #instanceRadiusUI_clearRadius do throw "Missing binding: layer.instanceRadiusUI.clearRadius"
format "layer.instanceRadiusUI.clearRadius\tBOUND\n" to:f
if not isProperty P07Root.spacingUI #spacingUI_relaxCheck do throw "Missing binding: layer.spacingUI.relaxCheck"
format "layer.spacingUI.relaxCheck\tBOUND\n" to:f
if not isProperty P07Root.spacingUI #spacingUI_spacingSpin do throw "Missing binding: layer.spacingUI.spacingSpin"
format "layer.spacingUI.spacingSpin\tBOUND\n" to:f
if not isProperty P07Root.spacingUI #spacingUI_iterationsSpin do throw "Missing binding: layer.spacingUI.iterationsSpin"
format "layer.spacingUI.iterationsSpin\tBOUND\n" to:f
if not isProperty P07Root.spacingUI #spacingUI_strengthSpin do throw "Missing binding: layer.spacingUI.strengthSpin"
format "layer.spacingUI.strengthSpin\tBOUND\n" to:f
if not isProperty P07Root.spacingUI #spacingUI_boundaryRelaxCheck do throw "Missing binding: layer.spacingUI.boundaryRelaxCheck"
format "layer.spacingUI.boundaryRelaxCheck\tBOUND\n" to:f
if not isProperty P07Root.spacingUI #spacingUI_finalStrengthSpin do throw "Missing binding: layer.spacingUI.finalStrengthSpin"
format "layer.spacingUI.finalStrengthSpin\tBOUND\n" to:f
if not isProperty P07Root.spacingUI #spacingUI_finalIterSpin do throw "Missing binding: layer.spacingUI.finalIterSpin"
format "layer.spacingUI.finalIterSpin\tBOUND\n" to:f
if not isProperty P07Root.spacingUI #spacingUI_finalMoveSpin do throw "Missing binding: layer.spacingUI.finalMoveSpin"
format "layer.spacingUI.finalMoveSpin\tBOUND\n" to:f
if not isProperty P07Root.spacingUI #separationUI_cleanCheck do throw "Missing binding: layer.separationUI.cleanCheck"
format "layer.separationUI.cleanCheck\tBOUND\n" to:f
if not isProperty P07Root.spacingUI #separationUI_neighborSpin do throw "Missing binding: layer.separationUI.neighborSpin"
format "layer.separationUI.neighborSpin\tBOUND\n" to:f
if not isProperty P07Root.spacingUI #separationUI_minNeighborSpin do throw "Missing binding: layer.separationUI.minNeighborSpin"
format "layer.separationUI.minNeighborSpin\tBOUND\n" to:f
if not isProperty P07Root.spacingUI #separationUI_minIslandSpin do throw "Missing binding: layer.separationUI.minIslandSpin"
format "layer.separationUI.minIslandSpin\tBOUND\n" to:f
if not isProperty P07Root.spacingUI #separationUI_planarCheck do throw "Missing binding: layer.separationUI.planarCheck"
format "layer.separationUI.planarCheck\tBOUND\n" to:f
if not isProperty P07Root.statisticsUI #detailsUI_refreshButton do throw "Missing binding: layer.detailsUI.refreshButton"
format "layer.detailsUI.refreshButton\tBOUND\n" to:f
if not isProperty P07Root.statisticsUI #detailsUI_helpButton do throw "Missing binding: layer.detailsUI.helpButton"
format "layer.detailsUI.helpButton\tBOUND\n" to:f
close f
)
