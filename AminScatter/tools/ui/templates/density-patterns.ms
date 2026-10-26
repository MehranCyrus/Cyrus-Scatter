-- Pattern browsing is file-only. Only an explicit choice authors layer settings.
global CyrusDensityPatternEditor,CyrusDensityPatternTarget,CyrusChooseDensityPattern,CyrusSetDensityImage,CyrusLoadDensityImage,CyrusBakeDensityImage
global CyrusRecipeScriptDirectory,CyrusRecipeOwnerNode,CyrusRecipeCheckRoot,CyrusViewportRedraw,AminScatterObject
fn CyrusSetDensityImage target path pattern:"" revision:"" = (
    local root=if target.overlapOwner==undefined then target else target.overlapOwner,node=undefined
    node=CyrusRecipeOwnerNode root;CyrusRecipeCheckRoot root node
    if findItem root.layerObjects target==0 do throw "The density layer was removed."
    if not doesFileExist path do throw "The selected density image is missing."
    local image=undefined,map=undefined
    try (
        image=openBitmap path colorSpace:ColorPipelineMgr.DataColorSpace
        if image==undefined do throw "The image could not be opened."
        if image.width>8192 or image.height>8192 or image.numframes!=1 do throw "Density images must be single-frame images up to 8192 x 8192."
        map=bitmaptexture name:(if pattern=="" then getFilenameFile path else "Cyrus / "+pattern) bitmap:image
    )catch(if image!=undefined do close image;throw())
    -- The map owns the open image. Pattern selection never consumes randomness.
    undo "Cyrus density image" on (
        target.densityMap=map;target.distributionMode=3
        target.densityCoordinateMode=1;target.densityWrapMode=1
        target.densityPatternID=pattern;target.densityPatternRevision=revision
        target.densityMapProvenance="linear image / "+(getFilenameFile path)
    )
    root.bindNativeUI();CyrusViewportRedraw();true
)
fn CyrusLoadDensityImage target = (
    local path=getOpenFileName caption:"Choose a density image (white permits / black excludes)" types:"Images|*.png;*.jpg;*.jpeg;*.tif;*.tiff;*.bmp;*.exr|All files|*.*|"
    if path!=undefined do CyrusSetDensityImage target path
)
fn CyrusBakeDensityImage target directory:undefined = (
    if target.densityMap==undefined do throw "Choose a texture map first."
    if target.densityCoordinateMode==3 do throw "Receiver-aware maps cannot be saved as a context-free image tile. Choose an explicit image projection before baking a tile."
    local root=if target.overlapOwner==undefined then target else target.overlapOwner,node=CyrusRecipeOwnerNode root
    CyrusRecipeCheckRoot root node
    if findItem root.layerObjects target==0 do throw "The density layer was removed."
    local documents=(dotNetClass "System.Environment").GetFolderPath ((dotNetClass "System.Environment+SpecialFolder").MyDocuments)
    if directory==undefined do directory=pathConfig.appendPath documents "CyrusScatter\\Maps"
    makeDir directory all:true
    local token=(dotNetClass "System.Guid").NewGuid()
    local path=pathConfig.appendPath directory (token.ToString()+".png"),image=undefined,map=undefined
    local provenance="baked 2D tile / "+((classof target.densityMap) as string)+" / "+(currentTime as string)+" / "+(target.densityResolution as string)+" squared"
    try (
        image=renderMap target.densityMap size:[target.densityResolution,target.densityResolution]
        if image==undefined do throw "This map cannot be evaluated as a 2D density tile."
        -- Preserve numeric eligibility, independently of Max's output colour
        -- conversion and remembered PNG export settings. Invert/curve stay authored.
        cyrusWriteDensityImage (cyrusCaptureDensityImage image) path
        close image;image=undefined
        image=openBitmap path colorSpace:ColorPipelineMgr.DataColorSpace
        map=bitmaptexture name:"Cyrus density snapshot" bitmap:image
    )catch(if image!=undefined do close image;if doesFileExist path do deleteFile path;throw())
    undo "Cyrus bake density tile" on (target.densityMap=map;target.densityPatternID="";target.densityPatternRevision="";target.densityMapProvenance=provenance)
    root.bindNativeUI();CyrusViewportRedraw();true
)
fn CyrusChooseDensityPattern target = (
    local assembly=dotNet.loadAssembly (pathConfig.appendPath CyrusRecipeScriptDirectory "CyrusGallery.dll")
    if CyrusDensityPatternEditor!=undefined do try(destroyDialog CyrusDensityPatternEditor)catch()
    rollout picker "Cyrus density patterns" width:650 height:485 (
        local target,root,node
        dotNetControl panel "CyrusScatter.UI.DensityPatternPanel" pos:[8,8] width:634 height:396
        label help "Original masks. White permits; black excludes. Pattern grids are density masks, not placement layouts." pos:[8,410] width:634 height:32
        button inspect "Inspect" pos:[8,450] width:120
        button usePattern "Use pattern" pos:[390,450] width:122
        button cancel "Cancel" pos:[522,450] width:120
        fn applyChoice = (
            if panel.SelectedPath!="" do (
                CyrusRecipeCheckRoot root node
                CyrusSetDensityImage target panel.SelectedPath pattern:panel.SelectedPattern revision:panel.SelectedHash
                destroyDialog picker
            )
        )
        on picker open do (
            target=CyrusDensityPatternTarget;root=if target.overlapOwner==undefined then target else target.overlapOwner;node=CyrusRecipeOwnerNode root
            panel.LoadPatterns (pathConfig.appendPath CyrusRecipeScriptDirectory "Patterns")
            if panel.Gallery.ItemCount==0 do help.text="No patterns were found. Choose Image or Map in Amount, or reinstall the complete Cyrus package."
        )
        on panel ItemActivated sender args do try(applyChoice())catch(messageBox (getCurrentException()) title:"Cyrus density pattern")
        on inspect pressed do panel.InspectSelected()
        on usePattern pressed do try(applyChoice())catch(messageBox (getCurrentException()) title:"Cyrus density pattern")
        on cancel pressed do destroyDialog picker
        on picker close do (panel.Dispose();CyrusDensityPatternEditor=undefined;CyrusDensityPatternTarget=undefined)
    )
    CyrusDensityPatternTarget=target;CyrusDensityPatternEditor=picker
    createDialog picker style:#(#style_titlebar,#style_sysmenu,#style_toolwindow)
)
