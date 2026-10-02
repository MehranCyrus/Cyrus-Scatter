-- Real foliage from the artist file, displayed without changing its source mesh.
(
    local controllers=for n in objects where classof n.baseObject==AminScatterObject collect n
    local original=controllers[1]
    local source=getNodeByName "crp_MT_PM_Sambucus_nigra_02_01"
    RIAssert (isValidNode source) "Expected artist shrub is missing"
    local sourceTransform=source.transform
    -- Preserve original scene data in memory, but isolate preview draw cost from
    -- visible source assets and wire/selection overlays for this separate case.
    hide (objects as array)
    local surface=plane name:"RI_Quality_Surface" width:18000 length:18000 widthsegs:1 lengthsegs:1
    global RIQualityNode=AminScatterObject name:"RI_Quality_Controller"
    RIQualityNode.surfaceNodes=#(surface);RIQualityNode.newLayer()
    local layer=RIQualityNode.layerObjects[1]
    layer.sources=#(source);layer.amount=10000;layer.sourceColors=#(color 80 190 100)
    RIQualityNode.previewBudget=500000;RIQualityNode.pointsPerPlant=1000;RIQualityNode.autoRender=false
    RIQualityNode.refreshAll();CyrusPointSync();completeRedraw()
    local camera=targetCamera pos:[16000,-18000,18000] target:(targetObject pos:[0,0,40])
    local cameraTarget=camera.target
    viewport.setType #view_persp_user;viewport.setTM (inverse camera.transform)
    delete camera;if isValidNode cameraTarget do delete cameraTarget
    viewport.setRenderLevel #smoothhighlights
    RICapture "real-shrubs-10000-wide"
    local rows=layer.placements (layer.validSources()) previewOnly:true
    local nearest=rows[1][1].translation
    local best=length nearest
    for row in rows where length row[1].translation<best do (nearest=row[1].translation;best=length nearest)
    hide surface
    camera=targetCamera pos:(nearest+[260,-330,170]) target:(targetObject pos:(nearest+[0,0,45]))
    cameraTarget=camera.target
    viewport.setTM (inverse camera.transform)
    delete camera;if isValidNode cameraTarget do delete cameraTarget
    RICapture "real-shrubs-10000-close"
    local denseStats=RIStats RIQualityNode
    -- A focused inspection fixture, explicitly a different population. This
    -- tests source sample detail; it is NOT evidence of automatic camera LOD.
    surface.width=900;surface.length=900;layer.amount=50
    RIQualityNode.pointsPerPlant=10000;RIQualityNode.refreshAll();CyrusPointSync();completeRedraw()
    local focusedRows=layer.placements (layer.validSources()) previewOnly:true
    local focusedTarget=focusedRows[1][1].translation
    hide surface
    camera=targetCamera pos:(focusedTarget+[160,-220,100]) target:(targetObject pos:(focusedTarget+[0,0,35]))
    cameraTarget=camera.target
    viewport.setTM (inverse camera.transform)
    delete camera;if isValidNode cameraTarget do delete cameraTarget
    RICapture "real-shrubs-50-detail"
    CSPWriteText (RIDir+"quality.json") (CSPObject #(#("source",source.name),#("source_transform_unchanged",source.transform==sourceTransform),#("landscape_instances",10000),#("landscape_stats",denseStats),#("focused_instances",50),#("focused_stats",RIStats RIQualityNode),#("automatic_camera_lod",false)))
)
