-- Temporary joined snapshots use exact accepted source transforms; never saved in the editable demo.
(
    if not matchPattern MCPFixtureDir pattern:"*/build/mcp-qualification/foundation-roadmap-feature-demo0824-*/" do throw "Owned feature-demo host required."
    loadMaxFile (MCPFixtureDir+"CyrusScatter 0.82.4 Feature Demo.max") quiet:true useFileUnits:true
    local node=getNodeByName "CYRUS 0.82.4 | SELECT ME - five feature layers",root=node.baseObject
    root.updateMode=1;root.refreshAll()
    for layerIndex=1 to root.layerObjects.count do (
        local leaf=root.layerObjects[layerIndex],vertices=#(),faces=#(),materialIDs=#(),sourceMeshes=#()
        for source in leaf.sources do (
            local originCopy=copy source;originCopy.transform=matrix3 1
            append sourceMeshes (snapshotAsMesh originCopy);delete originCopy
        )
        for row in root.groupSnapshotRows[layerIndex] do (
            local sourceMesh=sourceMeshes[row[2]],offset=vertices.count,tm=row[1]
            for i=1 to sourceMesh.numverts do append vertices ((getVert sourceMesh i)*tm)
            for i=1 to sourceMesh.numfaces do (append faces ((getFace sourceMesh i)+[offset,offset,offset]);append materialIDs row[2])
        )
        local snapshot=mesh name:("TEMP PREVIEW | "+root.layerNames[layerIndex]) vertices:vertices faces:faces
        local mat=multiMaterial numsubs:leaf.sources.count
        for i=1 to leaf.sources.count do mat.materialList[i]=leaf.sources[i].material
        snapshot.material=mat
        for i=1 to materialIDs.count do setFaceMatID snapshot i materialIDs[i]
        update snapshot
    )
    for leaf in root.layerObjects do for source in leaf.sources do source.renderable=false
    root.autoRender=false
    renderers.current=Default_Scanline_Renderer()
    ambientLight=color 40 40 40
    omniLight name:"TEMP PREVIEW | Key" pos:[-20,-35,65] multiplier:1.0 color:(color 255 245 225)
    omniLight name:"TEMP PREVIEW | Fill" pos:[40,25,45] multiplier:0.7 color:(color 210 225 255)
    renderWidth=1600;renderHeight=1000
    for spec in #(#("CAM 01 | Overview","Preview - Overview.png"),#("CAM 02 | Plane - density Paint Bands","Preview - Plane.png"),#("CAM 03 | Mountain - normals and filters","Preview - Mountain.png"),#("CAM 04 | Top plan","Preview - Top.png")) do (
        local result=render camera:(getNodeByName spec[1]) outputFile:(MCPFixtureDir+spec[2]) vfb:false
        close result
    )
    (dotNetClass "System.IO.File").WriteAllText (MCPFixtureDir+"demo-render-preview.txt") "Temporary snapshots from exact accepted rows; Scanline previews only. Editable MAX file was not overwritten."
)
