-- Definition-only helper for owned high-poly fixtures. Library files and the
-- saved .6 baseline remain immutable. Only detached material copies are relinked
-- and assigned to the disposable loaded test scene, matching Gallery MapPath.
global QHighPolyLibraryRoot,QMapleTextureInputs,QMapleTextureMaps,QResolveMapleTextureInputs
fn QMapleTextureMaps rootMaterial = (
    local maps=getClassInstances Bitmaptexture target:rootMaterial
    if (try(CoronaBitmap!=undefined)catch(false)) do join maps (getClassInstances CoronaBitmap target:rootMaterial)
    QRequire (maps.count<=4096) "Maple fixture exceeds Gallery's image-map limit"
    maps
)
fn QResolveMapleTextureInputs scatter = (
    QRequire (matchPattern MCPFixtureDir pattern:"*/build/*") "Owned high-poly profile required"
    QRequire (QHighPolyLibraryRoot!=undefined and doesDirectoryExist QHighPolyLibraryRoot) "hpm-input.ms must provide the measured installed QHighPolyLibraryRoot"
    QRequire (scatter.layerObjects.count==1 and scatter.layerObjects[1].sources.count==2) "Resolve the original two-source maple baseline before adding test populations"
    -- Load the Gallery paired with the already-loaded script, using the same
    -- version/location checks as its public open command. No product fileIn.
    local galleryPath=pathConfig.appendPath CyrusRecipeScriptDirectory "CyrusGallery.dll",assembly=dotNet.loadAssembly galleryPath
    QRequire (assembly!=undefined) "Matching staged Gallery assembly is unavailable"
    local assemblyName=assembly.GetName()
    QRequire (assemblyName.Version.ToString()==CyrusLibraryVersion() and toLower assembly.Location==toLower galleryPath) "Gallery identity differs from the staged product"
    local catalog=dotNetObject "CyrusScatter.UI.IndividualModelCatalog"
    catalog.Load QHighPolyLibraryRoot (CyrusLibraryVersion()) 2027
    for id in #("A097","A098") do catalog.VerifyScene (catalog.MatchingAt id "" 0)
    local sources=for source in scatter.layerObjects[1].sources collect source
    local originals=for source in sources collect source.material
    for materialRoot in originals do QRequire (materialRoot!=undefined) "Measured source has no material"
    local originalMaps=for materialRoot in originals collect (QMapleTextureMaps materialRoot)
    local originalNames=for maps in originalMaps collect (for map in maps collect map.filename)
    local metadata=cyrusSourceGeometryInfo sources
    local fingerprint=cyrusPlacementPublicationFingerprint scatter.groupSnapshotRows scatter.procPublishedRadii #("refinement") #(),epoch=scatter.procEpoch
    local sceneName=maxFilePath+maxFileName,copies=#(),pathRows=#(),uniqueImages=#(),mapCount=0,assigned=false
    try (
        for sourceIndex=1 to sources.count do (
            QRequire (originals[sourceIndex]!=undefined) "Measured source has no material"
            local detached=copy originals[sourceIndex],maps=QMapleTextureMaps detached
            QRequire (maps.count==originalMaps[sourceIndex].count and maps.count>0) "Detached source material lost image-map instances"
            for map in maps do (
                for inputMaps in originalMaps do QRequire (findItem inputMaps map==0) "Detached material shares an original image map"
                local raw=map.filename,resolved=catalog.MapPath raw
                QRequire (doesFileExist resolved) "Gallery-resolved image is unavailable"
                map.filename=resolved
                QRequire (map.filename==resolved and doesFileExist map.filename) "Detached image did not bind its Gallery path"
                append pathRows #(sourceIndex,(classof map) as string,raw,resolved)
                appendIfUnique uniqueImages (toLower resolved);mapCount+=1
            )
            append copies detached
        )
        -- All dependencies are checked before changing even the disposable scene.
        assigned=true
        with redraw off (with undo off (for i=1 to sources.count do sources[i].material=copies[i]))
        local originalsUnchanged=true
        for i=1 to originalMaps.count do for j=1 to originalMaps[i].count where originalMaps[i][j].filename!=originalNames[i][j] do originalsUnchanged=false
        local metadataSame=((cyrusSourceGeometryInfo sources) as string)==(metadata as string)
        local after=cyrusPlacementPublicationFingerprint scatter.groupSnapshotRows scatter.procPublishedRadii #("refinement") #()
        QRequire (originalsUnchanged and metadataSame and after==fingerprint and scatter.procEpoch==epoch and (maxFilePath+maxFileName)==sceneName) "Relink changed an original asset, source geometry or placement publication"
        QMapleTextureInputs=#(1,sources.count,mapCount,uniqueImages.count,true,originalsUnchanged,metadataSame,fingerprint,after,epoch,scatter.procEpoch)
        local output=openFile (MCPFixtureDir+"maple-gallery-paths.txt") mode:"a"
        format "Scenario: %\nLibrary: %\nResult: %\nPaths: %\nOriginal metadata: %\n" QScenarioID catalog.Root QMapleTextureInputs pathRows metadata to:output
        close output;QMapleTextureInputs
    ) catch (
        if assigned do with redraw off (with undo off (for i=1 to sources.count where isValidNode sources[i] do sources[i].material=originals[i]))
        throw()
    )
)
