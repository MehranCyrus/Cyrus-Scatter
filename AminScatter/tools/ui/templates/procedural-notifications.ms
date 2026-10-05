
-- Texture edits propagate through submaps. Watchers are transient and installed
-- lazily on a bound map after load/Undo; navigation only reads the revision.
global CyrusDensityMapChanged
fn CyrusDensityMapChanged texture = (
    for node in objects where classof node.baseObject==AminScatterObject do (
        for leaf in node.baseObject.layerObjects where leaf.procDensityMap==texture do (
            leaf.procDensityRevision+=1;leaf.dirty=true
        )
    )
)
