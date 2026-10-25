global MCPModelMergeBoundaryRun
fn MCPModelMergeBoundaryRun scenario = (
    if findItem #("library","raw","undo_block","raw_noheader","undo_noheader") scenario==0 do throw "Unsupported merge boundary case"
    local input=openFile (MCPFixtureDir+"model-import-root.txt"),directory=readLine input
    close input
    resetMaxFile #noPrompt;units.systemType=#Meters;units.systemScale=1.0
    dotNet.loadAssembly (pathConfig.appendPath CyrusRecipeScriptDirectory "CyrusGallery.dll")
    local catalog=dotNetObject "CyrusScatter.UI.IndividualModelCatalog"
    catalog.Load directory (CyrusLibraryVersion()) 2027
    local entry=catalog.MatchingAt "" "" 0
    if entry.Id!="A027" do throw "Owned Standard model fixture differs"
    local sentinel=box width:0.1 length:0.1 height:0.1
    clearUndoBuffer()
    undo "MCP direct pre-import edit" on sentinel.pos=[7,0,0]
    local before=theHold.GetUndoNames(),names=#()
    if findItem #("raw_noheader","undo_noheader") scenario==0 do names=getMAXFileObjectNames entry.Scene quiet:true missingDLLsAction:#logmsg
    local afterHeader=theHold.GetUndoNames(),model=undefined,merged=#()
    case scenario of (
        "library":(model=CyrusModelMerge catalog entry)
        "raw":(mergeMAXFile entry.Scene #(entry.NodeName) #autoRenameDups #renameMtlDups #neverReparent quiet:true missingDLLsAction:#logmsg;merged=getLastMergedNodes();model=merged[1])
        "undo_block":(undo "MCP direct merge block" on (
            mergeMAXFile entry.Scene #(entry.NodeName) #autoRenameDups #renameMtlDups #neverReparent quiet:true missingDLLsAction:#logmsg
            merged=getLastMergedNodes();model=merged[1]
        ))
        "raw_noheader":(mergeMAXFile entry.Scene #(entry.NodeName) #autoRenameDups #renameMtlDups #neverReparent quiet:true missingDLLsAction:#logmsg;merged=getLastMergedNodes();model=merged[1])
        "undo_noheader":(undo "MCP direct merge block" on (
            mergeMAXFile entry.Scene #(entry.NodeName) #autoRenameDups #renameMtlDups #neverReparent quiet:true missingDLLsAction:#logmsg
            merged=getLastMergedNodes();model=merged[1]
        ))
    )
    local afterImport=theHold.GetUndoNames(),nodesAfter=objects.count
    max undo
    local afterUndo=#(isValidNode model,objects.count,sentinel.pos.x,theHold.GetUndoNames())
    max undo
    local secondUndo=#(sentinel.pos.x,theHold.GetUndoNames())
    local out=createFile (MCPFixtureDir+"merge-boundary-"+scenario+".txt")
    format "mode=%\nbefore=%\nafter_header=%\nafter_import=%\nnodes_after=%\nafter_undo=%\nsecond_undo=%\n" scenario before afterHeader afterImport nodesAfter afterUndo secondUndo to:out
    close out
    QAssert true "merge_boundary_measured" "Direct MAXScript merge/header/Undo effects measured in owned profile"
)
