/* Render only an owned procedural gallery in an isolated Max 2027 batch.
   Default: create the gallery through its tests if this runner has no saved
   gallery yet, then load that saved scene and render a genuine Max overview.
   A caller may set CA_GALLERY_SCENE to a previous owned gallery .max path.
*/
global CA_TEST_ROOT, CA_TEST_OUTPUT, CA_AUTO_SHOW_UI, CA_GALLERY_SCENE, CA_GALLERY_RENDER_DETAILS
global caGSetups, caGPasses, caGFailures
global caGRContext = "initialization", caGRLog = #(), caGRRecord
fn caGRRecord message =
(
    caGRContext = message
    append caGRLog message
    local progress = createFile (CA_TEST_OUTPUT+"gallery-render-progress.txt")
    for line in caGRLog do format "%\n" line to:progress
    flush progress
    close progress
)
try
(
    if CA_TEST_ROOT == undefined or CA_TEST_OUTPUT == undefined do throw "Owned gallery runner paths are required."
    if CA_GALLERY_SCENE == undefined do CA_GALLERY_SCENE = CA_TEST_OUTPUT+"CyrusArrange-Gallery.max"
    if not (doesFileExist CA_GALLERY_SCENE) do
    (
        caGRRecord "generate and test owned gallery"
        fileIn (CA_TEST_ROOT+"tests/max/arrange_gallery_tests.ms")
        if caGFailures != 0 do throw "Gallery generation checks failed; no showcase render qualified."
    )
    caGRRecord ("load owned gallery "+CA_GALLERY_SCENE)
    loadMaxFile CA_GALLERY_SCENE useFileUnits:true quiet:true
    local setups = for node in objects where (getUserProp node "CyrusArrangeSetup") == true collect node
    if setups.count != 5 do throw "Saved gallery does not contain five native setup owners."
    for setup in setups where (caOutputRows setup).count == 0 do throw "Saved gallery has an empty native setup."
    local overview = getNodeByName "CA_GALLERY_OVERVIEW"
    if not isValidNode overview do throw "Owned gallery overview camera is missing."
    caGRRecord "configure overview framing and camera-facing annotations"
    overview.fov = 40
    for node in objects where matchPattern node.name pattern:"CA_GALLERY_LABEL_*" do
    (
        node.renderable = true
        node.castShadows = false
        if node.material != undefined and isProperty node.material #twoSided do node.material.twoSided = true
        if node.name == "CA_GALLERY_LABEL_CYRUS ARRANGE" or matchPattern node.name pattern:"CA_GALLERY_LABEL_ORIGINAL GEOMETRY*" do
        (
            local labelMatrix = copy overview.transform
            labelMatrix.row4 = node.transform.row4
            node.transform = labelMatrix
        )
    )
    renderers.current = Default_Scanline_Renderer()
    renderWidth = 2400; renderHeight = 1000
    caGRRecord "render overview 2400x1000"
    local start = timeStamp()
    local image = render camera:overview outputFile:(CA_TEST_OUTPUT+"CyrusArrange-Gallery-Overview.png") vfb:false
    close image
    local overviewMS = timeStamp()-start
    local detailRows = #()
    if CA_GALLERY_RENDER_DETAILS == undefined do CA_GALLERY_RENDER_DETAILS = true
    if CA_GALLERY_RENDER_DETAILS == true do
    (
        renderWidth = 1400; renderHeight = 1050
        for label in #("TV","SHELF","COFFEE","DINING","KITCHEN") do
        (
            caGRRecord ("render detail "+label+" 1400x1050")
            local camera = getNodeByName ("CA_GALLERY_"+label+"_CAMERA")
            if not isValidNode camera do throw ("Missing gallery detail camera: "+label)
            start = timeStamp()
            image = render camera:camera outputFile:(CA_TEST_OUTPUT+"CyrusArrange-Gallery-"+label+".png") vfb:false
            close image
            append detailRows #(label,timeStamp()-start)
        )
    )
    local report = createFile (CA_TEST_OUTPUT+"result.txt")
    format "SUCCESS original five-category gallery and native scanline overview\nscene=%\noverview_ms=%\n" CA_GALLERY_SCENE overviewMS to:report
    if caGPasses != undefined do format "generation_passes=% generation_failures=%\n" caGPasses caGFailures to:report
    for row in detailRows do format "detail=% render_ms=%\n" row[1] row[2] to:report
    flush report
    close report
)
catch
(
    local message = getCurrentException() as string
    local stack = getCurrentExceptionStackTrace() as string
    local failure = createFile (CA_TEST_OUTPUT+"gallery-render-exception.txt")
    format "context=%\nexception=%\nstack=%\n" caGRContext message stack to:failure
    flush failure
    close failure
    local report = createFile (CA_TEST_OUTPUT+"result.txt")
    format "ERROR gallery render\ncontext=%\nexception=%\nstack=%\n" caGRContext message stack to:report
    flush report
    close report
)
