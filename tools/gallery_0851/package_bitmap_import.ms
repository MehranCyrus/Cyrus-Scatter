(
    if not matchPattern MCPFixtureDir pattern:"*/build/mcp-qualification/foundation-roadmap-gallery0851-*/" do throw "Owned gallery host required."
    local log=createFile (MCPFixtureDir+"package-bitmap-import-"+(timeStamp() as string)+".txt"),moved="",directory=""
    fn check value message log = (format "%: %\n" (if value then "PASS" else "FAIL") message to:log;flush log;if not value do throw message)
    fn settle editor = (
        local started=timeStamp()
        while editor.progress.active and (timeStamp()-started)<30000 do ((dotNetClass "System.Threading.Thread").Sleep 10;if editor.progress.active do editor.progress.tick())
        if editor.progress.active do throw "Owned preparation timeout."
    )
    try (
        CyrusPerfHeadless=true
        directory=(dotNetClass "System.IO.File").ReadAllText (MCPFixtureDir+"portable-package-path.txt")
        check (matchPattern directory pattern:"*build*mcp-qualification*foundation-roadmap-gallery0851-*") "Owned portable package" log
        local package=cyrusAssetPackageRead directory,graph=CyrusRecipeGet package "graph"
        check ((CyrusRecipeGet graph "maps").count==1 and (CyrusRecipeGet graph "materials").count==1) "Shared material and bitmap are each captured once" log
        check (loadMaxFile @"F:/Cursor/_Cyrus_Apps/CyrusScatter/AminScatter/library/borders.max" quiet:true useFileUnits:true) "Independent destination has no source PNG references" log
        local node=undefined;for n in objects where classof n.baseObject==AminScatterObject do node=n
        local root=node.baseObject;root.refreshAll()
        local before=objects as array,layers=root.layerObjects.count
        CyrusOpenAssetImport root directory;local editor=CyrusAssetImportEditor;settle editor
        editor.suggest.pressed();editor.variation.selection=2;editor.review.pressed();check editor.commit.enabled "Textured package review validates colour context" log
        editor.commit.pressed();settle editor;format "Load status: %\n" editor.status.text to:log
        check (matchPattern editor.status.text pattern:"Loaded*") "Actual Load imports texture/material/source graph" log
        local imported=for i=(layers+1) to root.layerObjects.count collect root.layerObjects[i],models=#()
        for owner in imported do for model in owner.sources do appendIfUnique models model
        local material=models[1].material,texture=material.diffuseMap
        for model in models do check (model.material==material) "Packaged material sharing survives" log
        check (texture==material.opacityMap and texture==imported[1].densityMap) "Source slots and density role share one imported map" log
        check (texture!=GalleryBitmapOriginalTexture and material!=GalleryBitmapOriginalMaterial) "Imported materials/maps are independently owned" log
        check (cyrusAssetBitmapEqual texture.bitmap GalleryBitmapOriginalTexture.bitmap) "Decoded bitmap pixels match the source colour interpretation" log
        for key in #(#diffuse,#ambient,#specular,#specularLevel,#glossiness,#soften,#opacity,#twoSided,#diffuseMapEnable,#diffuseMapAmount,#opacityMapEnable,#opacityMapAmount,#adTextureLock,#adLock,#dsLock) do check (CyrusAssetSettingsEqual (getProperty material key) (getProperty GalleryBitmapOriginalMaterial key)) ("Material setting retained: "+key as string) log
        for key in #(#U_Offset,#V_Offset,#U_Tiling,#V_Tiling,#W_Angle,#mapChannel,#U_Mirror,#blur) do check (CyrusAssetSettingsEqual (getProperty texture.coords key) (getProperty GalleryBitmapOriginalTexture.coords key)) ("Map coordinate retained: "+key as string) log
        for key in #(#RGB_Level,#RGB_Offset,#clamp) do check (CyrusAssetSettingsEqual (getProperty texture.output key) (getProperty GalleryBitmapOriginalTexture.output key)) ("Map output retained: "+key as string) log
        check ((dotNetClass "System.IO.Path").GetFullPath (getFilenamePath texture.filename)==((dotNetClass "System.IO.Path").GetFullPath ((CyrusAssetBitmapDirectory())+"\\"))) "Bitmap refers to the owned persistent asset store" log
        moved=directory+"-temporarily-unavailable";(dotNetClass "System.IO.Directory").Move directory moved
        max undo;check (CyrusPresetSameValues before (objects as array)) "One Undo removes textured imported sources" log
        max redo;check (isValidNode models[1] and models[1].material.diffuseMap==texture) "Redo restores the same texture references without package access" log
        destroyDialog editor;root.refreshAll()
        check (saveMaxFile (MCPFixtureDir+"portable-textured-scene.max") quiet:true) "Textured result saves with owned asset paths" log
        local savedLayerID=imported[1].layerID,bitmapPath=texture.filename
        check (loadMaxFile (MCPFixtureDir+"portable-textured-scene.max") quiet:true useFileUnits:true) "Textured scene reopens without the package" log
        local restored=undefined
        for n in objects where classof n.baseObject==AminScatterObject do for owner in n.baseObject.layerObjects where owner.layerID==savedLayerID do restored=owner.sources[1]
        format "Reopened source: %; map: %; expected map: %\n" restored (if restored==undefined then undefined else restored.material.diffuseMap.filename) bitmapPath to:log;flush log
        check (isValidNode restored and restored.material.diffuseMap.filename==bitmapPath and restored.material.diffuseMap.bitmap!=undefined) "Reopened model resolves its owned PNG" log
        check (cyrusAssetBitmapEqual restored.material.diffuseMap.bitmap GalleryBitmapOriginalTexture.bitmap) "Reopened PNG retains decoded colour values" log
        (dotNetClass "System.IO.Directory").Move moved directory;moved=""
        global GalleryBitmapImportedMaterial;GalleryBitmapImportedMaterial=restored.material
        format "PASS: complete\n" to:log;close log
    )catch(
        if moved!="" and doesDirectoryExist moved and not doesDirectoryExist directory do (dotNetClass "System.IO.Directory").Move moved directory
        format "ERROR: %\n" (getCurrentException()) to:log;close log;throw()
    )
)
