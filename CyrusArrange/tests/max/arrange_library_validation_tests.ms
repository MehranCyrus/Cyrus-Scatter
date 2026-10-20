/* Independent format-1 fixtures: geometrically unsupported stack tops must not import. */
global CA_TEST_ROOT, CA_TEST_OUTPUT
global caLibLog = #(), caLibPasses = 0, caLibFailures = 0
fn caLibCheck label condition =
(
    if condition then (caLibPasses += 1; append caLibLog ("PASS " + label))
    else (caLibFailures += 1; append caLibLog ("FAIL " + label))
    condition
)
try
(
    resetMaxFile #noPrompt
    units.SystemType = #millimeters
    units.SystemScale = 1
    local shelf = box name:"CA_LIBRARY_SUPPORT" width:900 length:400 height:20
    local setup = caCreateSetup #(shelf) 2
    caLoadAssetLibrary setup (CA_TEST_ROOT + "tests/data/stack-closed.cyalib")
    caLibCheck "Independent closed-top library imports" ((caAssetRows setup).count == 1)
    caLibCheck "Imported library has explicit embedded provenance" ((caAssetDetail setup (caAssetRows setup)[1][1])[10] == 2)
    local generated = caGenerate setup #()
    caLibCheck "Validated embedded source generates" (generated[2] > 0)
    local prior = caSetupSummary setup
    local outputs = caOutputRows setup
    local rejected = false
    local errorText = ""
    try (caLoadAssetLibrary setup (CA_TEST_ROOT + "tests/data/stack-open.cyalib"))
    catch (rejected = true; errorText = getCurrentException())
    caLibCheck "Unsupported imported stack top rejects" (rejected and matchPattern errorText pattern:"*fully covered planar*")
    caLibCheck "Rejected import retains catalog and authored revision" ((caSetupSummary setup)[3] == prior[3] and (caSetupSummary setup)[4] == prior[4])
    local current = caOutputRows setup
    local retained = current.count == outputs.count
    for i = 1 to outputs.count while retained do retained = current[i][1] == outputs[i][1] and current[i][9] == outputs[i][9] and isValidNode outputs[i][9]
    caLibCheck "Rejected import retains actual published nodes" retained
)
catch (caLibFailures += 1; append caLibLog ("EXCEPTION " + getCurrentException()))
(
    local report = createFile (CA_TEST_OUTPUT + "result.txt")
    format "% passes=% failures=%\n" (if caLibFailures == 0 then "SUCCESS" else "ERROR") caLibPasses caLibFailures to:report
    for line in caLibLog do format "%\n" line to:report
    close report
)
