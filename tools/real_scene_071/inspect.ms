-- Read the user's saved scene only in the redirected private host.
(
    local rows=#(),maps=#()
    for node in objects do (
        local bounds=try(nodeGetBoundingBox node (matrix3 1))catch(#([0,0,0],[0,0,0]))
        local polygons=try(getPolygonCount node)catch(#(0,0))
   append rows #(node.name,(getHandleByAnim node) as string,(classof node.baseObject) as string,
            (superclassof node) as string,node.pos as string,bounds[1] as string,bounds[2] as string,
            polygons,node.isHidden,isGroupHead node,isGroupMember node,
            if node.parent==undefined then "" else node.parent.name,
            if node.material==undefined then "" else node.material.name,
            if node.material==undefined then "" else (classof node.material) as string)
    )
    for map in getClassInstances Bitmaptexture do append maps #(map.filename,doesFileExist map.filename)
    local materials=for material in sceneMaterials collect #(material.name,(classof material) as string)
    CSPWriteText (MCPFixtureDir+"scene-inventory.json") (CSPObject #(
        #("scene",maxFilePath+maxFileName),#("unit",units.SystemType as string),#("unit_scale",units.SystemScale),
        #("renderer",(classof renderers.current) as string),#("nodes",rows),#("materials",materials),#("bitmaps",maps)))
    local log=createFile (MCPFixtureDir+"renderer-properties.txt")
    showProperties renderers.current to:log
    format "\nAvailable renderer classes:\n" to:log
    for c in RendererClass.classes do format "%\n" c to:log
    close log
)
