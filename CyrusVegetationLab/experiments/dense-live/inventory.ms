(
    local library=@"F:/Cursor/_Cyrus_Apps/CyrusScatter/dist/CyrusScatter-0.86.7-20261020/Content/Library/Models/"
    local files=#("Flowers/A065 - Creeping Phlox - 02/model.max","Flowers/A066 - Herb Robert Geranium - 04/model.max","Flowers/A067 - Spotted Deadnettle - 04/model.max","Grasses/A068 - Grass - Bushy Clump/model.max","Shrubs/A083 - Lavender - 01/model.max","Shrubs/A084 - Lavender - 05/model.max")
    local log=createFile (CVLTestDir+"inventory.tsv")
    format "file\tnode\tvertices\ttriangles\tmin\tmax\n" to:log
    for relative in files do
    (
        cvlStage relative
        loadMaxFile (library+relative) quiet:true useFileUnits:true
        for node in geometry where canConvertTo node Editable_Mesh do
        (
            local m=snapshotAsMesh node, bounds=nodeGetBoundingBox node (matrix3 1)
            format "%\t%\t%\t%\t%\t%\n" relative node.name m.numverts m.numfaces bounds[1] bounds[2] to:log
        )
        flush log
    )
    close log
)
