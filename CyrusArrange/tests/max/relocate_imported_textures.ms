/* Explicit relocation helper for these six pinned CC0 diffuse/artwork maps.
   No automatic execution, scene load, file dialog, calculation or download.
   Call caRelocateImportedTextures <folder containing inputs/assets/> in a
   working copy of the imported example. Stage/verify all updates before Undo.
   Original PBR materials and arbitrary external maps are outside this helper.
*/
global caImportedTexturePaths,caRelocateImportedTextures
caImportedTexturePaths=#(
    #(@"modern_wooden_cabinet_diff_1k.jpg",@"inputs/assets/modern_wooden_cabinet/textures/modern_wooden_cabinet_diff_1k.jpg",@"e494b67439da73775413d6aaea369ae05a8ebd7705be8df08dbcd2ee4fd545e4"),
    #(@"wooden_bookshelf_worn_diff_1k.jpg",@"inputs/assets/wooden_bookshelf_worn/textures/wooden_bookshelf_worn_diff_1k.jpg",@"970f60178decadd0d8fb1e5872f718350a49b027fd69469210c41ead350cba56"),
    #(@"standing_picture_frame_02_artwork_diff_1k.png",@"inputs/assets/standing_picture_frame_02/textures/standing_picture_frame_02_artwork_diff_1k.png",@"e5655ab3a732751e817718e2655501e8485feb5fc64508535a2a3ac22fe5f869"),
    #(@"standing_picture_frame_02_diff_1k.jpg",@"inputs/assets/standing_picture_frame_02/textures/standing_picture_frame_02_diff_1k.jpg",@"9090300e8397c6ff14262276e4b162d9adfd128b785aeca255006fe06a1b2945"),
    #(@"ceramic_vase_02_diff_1k.jpg",@"inputs/assets/ceramic_vase_02/textures/ceramic_vase_02_diff_1k.jpg",@"12320e404c744095945b164293e522baadb6a0b393648f5908bfea2903f7fcc0"),
    #(@"wooden_bowl_02_diff_1k.jpg",@"inputs/assets/wooden_bowl_02/textures/wooden_bowl_02_diff_1k.jpg",@"a3bb80f6ea747491fe91628badc0b98d320fc6d427682564095aba6033a523dc")
)
fn caRelocateImportedTextures exampleRoot =
(
    local io=dotNetClass "System.IO.Path",fileIO=dotNetClass "System.IO.File"
    local root=substituteString (io.GetFullPath exampleRoot) "\\" "/"
    if not (matchPattern root pattern:"*/") do root+="/"
    local materialQueue=#(),seen=#(),updates=#(),seenMaps=#(),seenNames=#()
    for node in objects where isProperty node #material do if node.material!=undefined do append materialQueue node.material
    while materialQueue.count>0 do
    (
        local materialValue=materialQueue[materialQueue.count];deleteItem materialQueue materialQueue.count
        if (findItem seen materialValue)==0 do
        (
            append seen materialValue
            if seen.count>4096 do throw "Imported texture helper material bound exceeded."
            local subCount=getNumSubMtls materialValue,mapCount=getNumSubTexmaps materialValue
            if subCount>128 or mapCount>128 do throw "Imported texture helper slot bound exceeded."
            for slot=1 to subCount do
            (
                local child=getSubMtl materialValue slot
                if child!=undefined do append materialQueue child
            )
            for slot=1 to mapCount do
            (
                local mapValue=getSubTexmap materialValue slot
                if mapValue!=undefined and (classOf mapValue)==Bitmaptexture and (findItem seenMaps mapValue)==0 do
                (
                    append seenMaps mapValue
                    if matchPattern mapValue.name pattern:"CA_IMPORTED_MAP_*" do
                    (
                        local basename=(getFilenameFile mapValue.filename)+(getFilenameType mapValue.filename),binding=undefined
                        for row in caImportedTexturePaths where (toLower row[1])==(toLower basename) do binding=row
                        if binding==undefined do throw ("Unknown declared imported map: "+basename)
                        local path=substituteString (io.GetFullPath (root+binding[2])) "\\" "/"
                        if (findString (toLower path) (toLower root))!=1 or not (doesFileExist path) do throw ("Missing/bad relocated texture: "+path)
                        local stream=undefined,hasher=undefined,digest=undefined,problem=undefined
                        try
                        (
                            stream=fileIO.OpenRead path;hasher=(dotNetClass "System.Security.Cryptography.SHA256").Create()
                            digest=toLower (substituteString ((dotNetClass "System.BitConverter").ToString (hasher.ComputeHash stream)) "-" "")
                        ) catch(problem=getCurrentException() as string)
                        if stream!=undefined do stream.Close()
                        if hasher!=undefined do hasher.Dispose()
                        if problem!=undefined do throw problem
                        if digest!=binding[3] do throw ("Relocated texture differs from pinned CC0 bytes: "+path)
                        appendIfUnique seenNames (toLower binding[1])
                        append updates #(mapValue,path)
                    )
                )
            )
        )
    )
    if updates.count==0 do throw "No declared imported example diffuse maps found."
    for binding in caImportedTexturePaths do
        if (findItem seenNames (toLower binding[1]))==0 do throw ("Declared example texture not assigned in this scene: "+binding[1])
    undo "Cyrus Arrange example: relocate pinned diffuse textures" on
    (
        for update in updates do update[1].filename=update[2]
    )
    updates.count
)
