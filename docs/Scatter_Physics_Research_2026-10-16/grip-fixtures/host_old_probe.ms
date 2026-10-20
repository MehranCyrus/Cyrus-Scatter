cplResetScene()
(
 local output=createFile (CPLTestDir+"old-probe.txt")
 local path=@"F:/Cursor/_Cyrus_Apps/CyrusScatter/build/physics-lab-host-20261016-25/PhysicsLab_Leaves_Max2027.max"
 format "exists %\n" (doesFileExist path) to:output
 local loaded=loadMaxFile path quiet:true
 format "loaded % nodes %\n" loaded objects.count to:output
 for n in objects do format "% %\n" n.name (classOf n) to:output
 close output
)
