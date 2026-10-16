-- Scoped Scanline/Standard material fidelity, not arbitrary renderer qualification.
(
    if not matchPattern MCPFixtureDir pattern:"*/build/mcp-qualification/foundation-roadmap-gallery0851-*/" do throw "Owned host required."
    local log=createFile (MCPFixtureDir+"package-bitmap-render-"+(timeStamp() as string)+".txt"),movedPNG="",movedPackage="",directory=""
    fn check value message log = (format "%: %\n" (if value then "PASS" else "FAIL") message to:log;flush log;if not value do throw message)
    try (
        local original=GalleryBitmapOriginalMaterial,imported=GalleryBitmapImportedMaterial
        check (original!=undefined and imported!=undefined) "Both source and imported materials are available" log
        resetMaxFile #noPrompt
        local model=box name:"Owned material witness" width:70 length:70 height:30 mapCoords:true material:original
        local camera=targetCamera name:"Owned material camera" pos:[120,-160,130] target:(targetObject pos:[0,0,15]) fov:35
        omniLight pos:[-80,-110,150] multiplier:1.1
        omniLight pos:[100,60,120] multiplier:0.6
        renderers.current=Default_Scanline_Renderer();renderWidth=512;renderHeight=320;backgroundColor=color 32 38 44;ambientLight=color 35 35 35
        local beforePath=MCPFixtureDir+"material-before.png",afterPath=MCPFixtureDir+"material-after.png",reopenPath=MCPFixtureDir+"material-reopened.png"
        local frame=render camera:camera outputFile:beforePath vfb:false;close frame
        model.material=imported
        frame=render camera:camera outputFile:afterPath vfb:false;close frame
        local error=""
        check (compareBitmaps beforePath afterPath 0 0 useAlpha:true errorMsg:&error) ("Original/imported Scanline pixels match: "+error) log
        check (saveMaxFile (MCPFixtureDir+"owned-imported-material.max") quiet:true) "Independent textured material scene saves" log
        directory=(dotNetClass "System.IO.File").ReadAllText (MCPFixtureDir+"portable-package-path.txt")
        check (matchPattern directory pattern:"*build*mcp-qualification*foundation-roadmap-gallery0851-*") "Owned package for unavailable-source test" log
        check (matchPattern GalleryBitmapSourcePNG pattern:(MCPFixtureDir+"*")) "Owned original PNG" log
        movedPackage=directory+"-temporarily-unavailable";(dotNetClass "System.IO.Directory").Move directory movedPackage
        movedPNG=GalleryBitmapSourcePNG+".unavailable";(dotNetClass "System.IO.File").Move GalleryBitmapSourcePNG movedPNG
        resetMaxFile #noPrompt
        check (loadMaxFile (MCPFixtureDir+"owned-imported-material.max") quiet:true useFileUnits:true) "Recipient scene opens without original PNG or package" log
        frame=render camera:(getNodeByName "Owned material camera") outputFile:reopenPath vfb:false;close frame
        error="";check (compareBitmaps beforePath reopenPath 0 0 useAlpha:true errorMsg:&error) ("Independent reopened render matches: "+error) log
        (dotNetClass "System.IO.File").Move movedPNG GalleryBitmapSourcePNG;movedPNG=""
        (dotNetClass "System.IO.Directory").Move movedPackage directory;movedPackage=""
        format "PASS: complete\n" to:log;close log
    )catch(
        if movedPNG!="" and doesFileExist movedPNG and not doesFileExist GalleryBitmapSourcePNG do (dotNetClass "System.IO.File").Move movedPNG GalleryBitmapSourcePNG
        if movedPackage!="" and doesDirectoryExist movedPackage and not doesDirectoryExist directory do (dotNetClass "System.IO.Directory").Move movedPackage directory
        format "ERROR: %\n" (getCurrentException()) to:log;close log;throw()
    )
)
