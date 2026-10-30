-- Explicit scene-source commands. Catalog provenance is never node identity.
global CyrusCaptureSourceAccess,CyrusValidateSourceAccess,CyrusShowSourceAccess,CyrusEditSourceMaterial
fn CyrusCaptureSourceAccess controller layer rows = (
    if controller==undefined or layer==undefined or findItem controller.layerObjects layer==0 do throw "Select an active source layer."
    local records=#()
    for row in rows where row>0 and row<=layer.sources.count do (
        local node=layer.sources[row]
        if not layer.isPointSource row and not layer.isEmptySource row and isValidNode node do
            append records #(layer.sourceRowIDs[row],node,getHandleByAnim node)
    )
    #(controller,controller.layerID,layer,layer.layerID,records,rows.numberSet)
)
fn CyrusValidateSourceAccess context = (
    local controller=context[1],layer=context[3],alive=false,nodes=#()
    for node in refs.dependentNodes controller where isValidNode node and node.baseObject==controller do alive=true
    if not alive or controller.layerID!=context[2] or findItem controller.layerObjects layer==0 or layer.layerID!=context[4] do throw "The source owner changed. Select its sources again."
    for record in context[5] do (
        local row=findItem layer.sourceRowIDs record[1],node=record[2]
        if row==0 or not isValidNode node or getHandleByAnim node!=record[3] or layer.sources[row]!=node or layer.isPointSource row or layer.isEmptySource row do
            throw "The selected source changed. Select it again."
        appendIfUnique nodes node
    )
    nodes
)
fn CyrusShowSourceAccess context show = (
    local nodes=CyrusValidateSourceAccess context
    if nodes.count==0 do throw "Select at least one existing model source."
    if theHold.Holding() do throw "Finish the current scene command before changing source visibility."
    theHold.Begin()
    try (
        -- Host hide flags only. In particular, never set renderable=false here.
        if show then unhide nodes else hide nodes
        theHold.Accept (if show then "Cyrus show sources" else "Cyrus hide sources")
    )catch(theHold.Cancel();throw())
    redrawViews();nodes.count
)
fn CyrusEditSourceMaterial context = (
    local nodes=CyrusValidateSourceAccess context
    if context[6]!=1 or nodes.count!=1 or nodes[1].material==undefined do throw "Select one model with an assigned scene material."
    local node=nodes[1],material=node.material
    sme.Open()
    -- Opening an editor can dispatch messages and retire/rebind the source view.
    nodes=CyrusValidateSourceAccess context
    if nodes.count!=1 or node.material!=material do throw "The source material changed while opening the editor. Select it again."
    sme.SetMtlInParamEditor material
    material
)
