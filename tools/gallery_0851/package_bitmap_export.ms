(
    if not matchPattern MCPFixtureDir pattern:"*/build/mcp-qualification/foundation-roadmap-gallery0851-*/" do throw "Owned gallery host required."
    local log=createFile (MCPFixtureDir+"package-bitmap-export-"+(timeStamp() as string)+".txt")
    fn check value message log = (format "%: %\n" (if value then "PASS" else "FAIL") message to:log;flush log;if not value do throw message)
    try (
        CyrusPerfHeadless=true
        check (loadMaxFile @"F:/Cursor/_Cyrus_Apps/CyrusScatter/AminScatter/library/borders.max" quiet:true useFileUnits:true) "Owned painted border fixture opens" log
        local node=undefined;for n in objects where classof n.baseObject==AminScatterObject do node=n
        local root=node.baseObject,png=MCPFixtureDir+"owned-texture-"+CyrusNewLayerID()+".png",pixels=bitmap 64 64 filename:png
        for y=0 to 63 do setPixels pixels [0,y] (for x=0 to 63 collect (color (30+x*3) (45+y*2) (160-x) 255))
        check (save pixels quiet:true) "Owned gradient PNG saves" log;close pixels
        local texture=bitmaptexture name:"Owned shared PNG" filename:png
        texture.coords.U_Offset=0.125;texture.coords.V_Offset=-0.2;texture.coords.U_Tiling=1.7;texture.coords.V_Tiling=0.8;texture.coords.W_Angle=17
        texture.coords.U_Mirror=true;texture.coords.blur=0.7;texture.output.RGB_Level=0.8;texture.output.RGB_Offset=0.05;texture.output.clamp=true
        local material=standardMaterial name:"Owned textured Standard" diffuse:(color 90 170 50) twoSided:true glossiness:23 specularLevel:19
        material.adLock=false;material.ambient=(color 24 35 48);material.diffuseMap=texture;material.diffuseMapAmount=83;material.diffuseMapEnable=true
        material.opacityMap=texture;material.opacityMapAmount=72;material.opacityMapEnable=true
        for owner in root.layerObjects do for source in owner.sources do source.material=material
        root.layerObjects[1].densityMap=texture;root.refreshAll()
        global GalleryBitmapOriginalMaterial,GalleryBitmapOriginalTexture,GalleryBitmapSourcePNG,GalleryExportRoot,GalleryExportCounters,GalleryExportRecipe,GalleryExportOutput,GalleryExportJob,GalleryExportDocument,GalleryExportNodes
        GalleryBitmapOriginalMaterial=material;GalleryBitmapOriginalTexture=texture;GalleryBitmapSourcePNG=png
        GalleryExportRoot=root;GalleryExportCounters=#(root.procEpoch,root.groupBuilds);GalleryExportNodes=objects as array
        GalleryExportDocument=CyrusRecipeCapture root (root.logicalLayers()) "Portable textured painted borders"
        GalleryExportRecipe=MCPFixtureDir+"textured-"+CyrusNewLayerID()+".csrecipe.json"
        local metadata=CyrusRecipeObject #(#("category","Package fixture"),#("tags",#("paint","texture")),#("description","Owned textured portable witness"))
        local digest=cyrusRecipeEntryWrite GalleryExportRecipe GalleryExportDocument metadata "" undefined "" false
        undo "Preceding user action" on node.name="Portable export Undo sentinel"
        CyrusOpenAssetExport root GalleryExportRecipe digest
        local editor=CyrusAssetExportEditor;editor.matchNames.pressed()
        for pair in editor.bindings do check (pair[2]!=undefined) "Source/map role has an explicit suggestion" log
        editor.destination=MCPFixtureDir;editor.folderName.text="portable-textured-"+CyrusNewLayerID();editor.permitted.checked=true
        GalleryExportOutput=pathConfig.appendPath MCPFixtureDir editor.folderName.text
        editor.exportPackage.pressed();format "Export status: %\n" editor.status.text to:log;flush log
        check (editor.job>0 and editor.progress.active) "Actual Export captures the supported texture and starts its worker" log
        GalleryExportJob=editor.job
        format "PASS: waiting for file worker\n" to:log;close log
    )catch(format "ERROR: %\n" (getCurrentException()) to:log;close log;throw())
)
