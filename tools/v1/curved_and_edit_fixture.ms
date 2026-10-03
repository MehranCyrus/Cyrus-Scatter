(
    local results=#()
    local sphereNode=sphere name:"CYRUS_V1_CURVED_TARGET" radius:50 segs:48 pos:[300,0,0]
    sphereNode.scale=[1.3,.8,1.1]
    local source=CyrusV1BrushSource
    local node=CyrusScatterObject name:"CYRUS_V1_CURVED_SCATTER"
    local root=node.baseObject
    root.surfaceNodes=#(sphereNode);root.viewportMode=3;root.autoRender=false;root.newLayer()
    local layer=root.layerObjects[1]
    layer.sources=#(source);layer.amount=6000;layer.paintDocument=cyrusBrushCreate sphereNode;layer.paintIdentity=true;layer.paintEnabled=true
    root.syncLayerSurface layer
    viewport.setType #view_persp_user
    local eye=[300,-250,150],look=normalize([300,0,0]-eye),right=normalize(cross look [0,0,1]),up=cross right look
    viewport.setTM (inverse(matrix3 right up (-look) eye))
    cyrusBrushSettings layer.paintDocument 45 1 .5 false 1
    if not (cyrusBrushDab layer.paintDocument [0,-200,100] [0,1,-.5] true) do throw "Curved Brush missed sphere"
    local curved=layer.placements #(source) previewOnly:true
    if curved.count<50 or curved.count>=6000 do throw "Curved Brush footprint missing or leaked globally"
    local originalID=layer.layerID
    local fullHistory=cyrusBrushHistory layer.paintDocument
    local oldSegs=sphereNode.segs
    sphereNode.segs=32
    local rejected=false
    try(cyrusBrushBind layer.paintDocument)catch(rejected=true)
    if not rejected do throw "Changed topology was silently accepted"
    if (cyrusBrushHistory layer.paintDocument) as string!=fullHistory as string do throw "Topology validation destroyed strokes"
    sphereNode.segs=oldSegs;cyrusBrushBind layer.paintDocument
    if (layer.placements #(source) previewOnly:true).count!=curved.count do throw "Restored topology lost Brush output"
    hide sphereNode
    if (layer.placements #(source) previewOnly:true).count!=curved.count do throw "Hiding receiving mesh disabled final density"
    unhide sphereNode
    append results #("curved_scaled_surface",curved.count)

    local editRoot=CyrusV1BrushNode.baseObject,editLayer=CyrusV1BrushLayer
    cyrusBrushFill editLayer.paintDocument 0.0
    cyrusBrushSettings editLayer.paintDocument 45 1 0 false 1
    cyrusBrushDab editLayer.paintDocument [0,0,100] [0,0,-1] true
    cyrusBrushSettings editLayer.paintDocument 18 1 0 true 1
    cyrusBrushDab editLayer.paintDocument [0,0,100] [0,0,-1] true
    while CyrusV1BrushNode.modifiers.count>0 do deleteModifier CyrusV1BrushNode 1
    local modifier=CyrusScatterEdit()
    addModifier CyrusV1BrushNode modifier
    local initial=editLayer.placements #(CyrusV1BrushSource) previewOnly:true
    if initial.count==0 or initial[1].count!=3 do throw "CS Edit did not accept keyed candidates"
    local identity=initial[1][3],position=initial[1][1].row4
    cyrusEditSelect modifier #(1)
    cyrusEditCommand modifier 4 (transMatrix [3,4,0])
    local moved=editLayer.placements #(CyrusV1BrushSource) previewOnly:true
    if moved[1][3]!=identity or distance moved[1][1].row4 (position+[3,4,0])>0.001 do throw "Keyed CS Edit move failed"
    cyrusBrushStroke editLayer.paintDocument 1 false 1 45 0 false
    local dormant=editLayer.placements #(CyrusV1BrushSource) previewOnly:true
    if dormant.count!=0 do throw "Masked-out edited plant stayed visible"
    cyrusBrushStroke editLayer.paintDocument 1 true 1 45 0 false
    local restored=editLayer.placements #(CyrusV1BrushSource) previewOnly:true
    if restored[1][3]!=identity or distance restored[1][1].row4 moved[1][1].row4>0.001 do throw "Dormant CS Edit was not restored by identity"
    if not (cyrusEditCommand modifier 5 (matrix3 1)) do throw "Brush membership invalidated CS Edit"
    -- Stable edit-layer keys survive deletion of a different layer.
    editRoot.newLayer();editRoot.layerObjects[2].sources=#(CyrusV1BrushSource)
    local key=editLayer.editLayerKey
    editRoot.activeLayer=2;editRoot.removeLayer()
    if editLayer.editLayerKey!=key do throw "Layer deletion changed edit binding"
    local priorSeed=editLayer.randomSeed
    editLayer.randomSeed+=1
    editLayer.placements #(CyrusV1BrushSource) previewOnly:true
    if cyrusEditCommand modifier 5 (matrix3 1) do throw "True base-generation change bypassed CS Edit safety"
    editLayer.randomSeed=priorSeed
    cyrusEditCommand modifier 0 (matrix3 1)
    editLayer.placements #(CyrusV1BrushSource) previewOnly:true
    append results #("cs_edit_stable_dormant",restored.count)
    append results #("seed_change_requires_reset",true)
    saveMaxFile (BLDir+"brush-curved-edit.max") quiet:true
    CSPWriteText (BLDir+"curved-edit-acceptance.json") (CSPObject results)
)
