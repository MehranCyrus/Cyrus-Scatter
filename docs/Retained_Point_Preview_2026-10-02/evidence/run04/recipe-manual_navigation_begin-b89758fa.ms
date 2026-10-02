-- Run only after quality.ms in the private fixture; then pan by mouse in Max.
(
    global RIManualBefore,RIManualView,RIManualBuilds
    RIAssert (isValidNode RIQualityNode) "Run the quality fixture first"
    -- Improve contrast for the visual check without altering the point payload.
    RIQualityNode.layerObjects[1].sourceColors=#(color 20 80 35)
    RIQualityNode.refreshAll();CyrusPointSync();completeRedraw()
    RICapture "manual-pan-before"
    RIManualBefore=RIStats RIQualityNode
    RIManualView=viewport.getTM()
    RIManualBuilds=(RIQualityNode.layerObjects[1].previewStats())[1]
)
