(
    local layer=RIQualityNode.layerObjects[1],source=layer.sources[1]
    local rows=layer.placements (layer.validSources()) previewOnly:true
    local samples=aminScatterSourcePoints source 16 42
    CSPWriteText (RIDir+"quality-inspect.json") (CSPObject #(#("source_tm",source.transform),#("samples",samples),#("placements",for i=1 to (amin 3 rows.count) collect rows[i]),#("range",#(layer.wholeScaleMin,layer.wholeScaleMax)),#("status",layer.statusText())))
    local targetPosition=rows[1][1].translation
    hide (getNodeByName "RI_Quality_Surface")
    local camera=targetCamera pos:(targetPosition+[160,-220,100]) target:(targetObject pos:(targetPosition+[0,0,35]))
    local target=camera.target
    viewport.setType #view_persp_user;viewport.setTM (inverse camera.transform)
    delete camera;if isValidNode target do delete target
    RICapture "real-shrubs-50-detail-corrected"
)
