(
    cvlStage "installed startup"
    if CVLOpen==undefined do throw "Installed launcher is unavailable."
    loadMaxFile (CVLTestDir+"Grass_Stone_Max2027.max") quiet:true
    local grass=(for node in objects where classof node==CyrusVegetationLab collect node)[1]
    if grass==undefined or grass.stoneNode==undefined do throw "Installed native scene did not reopen with its sphere binding."
    if (snapshotAsMesh grass).numfaces!=112 do throw "Installed scene mesh was lost."
    select grass;max modify mode;modPanel.setCurrentObject grass
    grass.labUI.fitButton.pressed()
    if findString (cvlStats grass.nativeState) "\"fitted\":true"==undefined do throw "Installed Fit did not publish."
    (dotNetClass "System.IO.File").WriteAllText (CVLTestDir+"restart-stats.json") (cvlStats grass.nativeState)
    fileIn (CVLTestDir+"package/OpenCyrusVegetationLab.ms")
    if not CVLLauncher.isDisplayed do throw "Installed opener did not open the launcher."
    destroyDialog CVLLauncher
    cvlStage "installed save"
    if not saveMaxFile (CVLTestDir+"Installed_Grass_Stone_Max2027.max") quiet:true do throw "Installed scene save failed."
)
