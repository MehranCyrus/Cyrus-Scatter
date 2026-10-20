/* Owned, disposable scene only. Genuine Max render; no desktop automation. */
global CA_TEST_ROOT, CA_TEST_OUTPUT, CA_AUTO_SHOW_UI
global caFxTVConsole, caFxOpenShelf
(
    if CA_TEST_ROOT == undefined or CA_TEST_OUTPUT == undefined do throw "Owned runner paths required."
    -- Compile installer bodies without executing installation or displaying prompts.
    for script in #("install.ms", "CyrusArrangeStartup.ms") do
    (
        local body = (dotNetClass "System.IO.File").ReadAllText (CA_TEST_ROOT + "installer/" + script)
        execute ("fn caInstallerSyntaxProbe = (\n" + body + "\n)")
    )
    resetMaxFile #noPrompt
    units.SystemType = #millimeters
    units.SystemScale = 1.0
    fileIn (CA_TEST_ROOT + "tests/max/fixtures.ms")
    local tv = caFxTVConsole offsetMM:[-1100,0,0] grouped:true
    local shelf = caFxOpenShelf offsetMM:[1000,0,0] grouped:true
    local wood = standardMaterial name:"Arrange fixture | walnut" diffuse:(color 105 72 49) specularLevel:20 glossiness:30
    local white = standardMaterial name:"Arrange fixture | warm white" diffuse:(color 210 206 192) specularLevel:15 glossiness:25
    local sample = standardMaterial name:"Arrange sampled support | mint" diffuse:(color 60 215 156) selfIllumAmount:55 opacity:85
    for node in tv[2] do node.material = wood
    for node in shelf[2] do node.material = white
    local summaries = #()
    for fixture in #(tv,shelf) do
    (
        append summaries (caInspect #(fixture[1]) 25 100 5)
        local overlay = caCreateOverlay()
        overlay.material = sample
        -- Inspector output is non-renderable by default. Enable only in this illustrative scene.
        overlay.renderable = true
    )
    caExport (CA_TEST_OUTPUT + "demo-shelf.json")
    local ground = box name:"Arrange demo | ground" width:6500 length:3500 height:40 pos:[0,400,-50]
    ground.material = standardMaterial name:"Arrange demo | ground material" diffuse:(color 48 56 62)
    local aim = targetObject name:"Arrange demo | camera target" pos:[0,0,750]
    local camera = targetCamera name:"Arrange demo | overview" pos:[3500,-6500,3200] target:aim fov:43
    omniLight name:"Arrange demo | key" pos:[-1500,-3500,5000] multiplier:1.0 color:(color 255 240 220)
    omniLight name:"Arrange demo | fill" pos:[3500,-500,3000] multiplier:0.6 color:(color 205 225 255)
    ambientLight = color 65 65 65
    backgroundColor = color 24 30 35
    renderers.current = Default_Scanline_Renderer()
    renderWidth = 1400
    renderHeight = 950
    saveMaxFile (CA_TEST_OUTPUT + "CyrusArrange-Inspector-Demo.max") quiet:true
    local bitmap = render camera:camera outputFile:(CA_TEST_OUTPUT + "CyrusArrange-Inspector-Demo.png") vfb:false
    close bitmap
    local report = createFile (CA_TEST_OUTPUT + "result.txt")
    format "SUCCESS\nNative inspection + procedural demo render\nTV regions: %; usable cells: %\nShelf regions: %; usable cells: %\n" summaries[1][4] summaries[1][6] summaries[2][4] summaries[2][6] to:report
    close report
)
