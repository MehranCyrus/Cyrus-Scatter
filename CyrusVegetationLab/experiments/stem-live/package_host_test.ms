(
    fn require ok message = (if not ok do throw message)
    fn write name value = ((dotNetClass "System.IO.File").WriteAllText (CVLTestDir+name) value)
    cvlStage "install into owned scripts profile"
    require (findString (toLower (getDir #userScripts)) (toLower (getFilenamePath (getMAXIniFile())))==1) "User scripts directory escaped owned profile."
    global CVPInstallKit,CVPOpen,CVPFileSHA
    fileIn (CVPKitRoot+"InstallCore.ms")
    local installed=CVPInstallKit quiet:true
    require (findString (toLower installed) (toLower (getDir #userScripts))==1) "Installer escaped owned profile."
    write "installed.txt" installed
    cvlStage "open installed test kit"
    fileIn (installed+"OpenTest.ms")
    fileIn ((getFilenamePath(getSourceFileName()))+"package_loaded_test.ms")
)
