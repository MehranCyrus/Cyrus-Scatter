-- Repair only this owned copy's dependency paths before the Library snapshot.
-- Preserve the shader graph and actual image files; never save the artist input.
(
    if not matchPattern GardenRun pattern:"*/build/interactions08753-20261028-01/host-*/" do throw "Owned fixture required."
    if theHold.Holding() do throw "Resolve copied-scene assets outside an authored hold."
    local bases=#(@"F:\Cursor\_Cyrus_Apps\CyrusScatter\Test Scene\Organized Models\Plants\Outdoor\Outdoor_Plants_01\",@"F:\Cursor\_Cyrus_Apps\CyrusScatter\Test Scene\Rock_Boulder_10\")
    local maps=#(),log=stringStream "",file=(dotNetClass "System.IO.File"),path=(dotNetClass "System.IO.Path"),directory=(dotNetClass "System.IO.Directory")
    -- The copied MAX file also carries parked models/material-editor maps.
    -- Resolve that owned scene's maps before Max's file dependency enumeration.
    maps=getClassInstances Bitmaptexture processAllAnimatables:true
    if (try(CoronaBitmap!=undefined)catch(false)) do join maps (getClassInstances CoronaBitmap processAllAnimatables:true)
    if maps.count>4096 do throw "Owned fixture exceeds 4,096 texture maps."
    for map in maps do (
        local raw=map.filename
        if not (path.IsPathRooted raw and file.Exists raw) do (
            local matches=#()
            for base in bases do (
                if file.Exists (base+raw) do appendIfUnique matches (base+raw)
            )
            if matches.count==0 do for base in bases do for candidate in (directory.GetFiles base ((getFilenameFile raw)+(getFilenameType raw)) (dotNetClass "System.IO.SearchOption").AllDirectories) do appendIfUnique matches candidate
            if matches.count!=1 do throw ("Copied fixture asset is missing or ambiguous: "+raw)
            map.filename=matches[1];format "% => %\n" raw matches[1] to:log
        )
    )
    WFRoot.refreshAll();CyrusPointSync()
    format "status=pass maps=% holding=%" maps.count (theHold.Holding()) to:log
    file.WriteAllText (GardenRun+"resolved-dependency-assets.txt") (log as string)
)
