/* Actual MZP execution in a root-created private profile; never run in an artist session. */
global CA_TEST_OUTPUT, CA_INSTALL_QA_ROOT, CA_INSTALL_ARCHIVE, CA_INSTALL_BAD_ARCHIVE, CA_INSTALL_FILES
global CA_INSTALL_QUIET, CA_INSTALL_RESULT, caInstallerSupportsHost
global caILog, caIPasses, caIFailures, caIFinished, caIWrite, caINote, caICheck, caIRequire, caIHash, caIInside, caIExecute, caIRun
caILog = #();caIPasses = 0;caIFailures = 0;caIFinished = false
fn caIWrite =
(
    local report = createFile (CA_TEST_OUTPUT+"result.txt")
    format "% passes=% failures=%\n" (if caIFinished then (if caIFailures == 0 then "SUCCESS" else "ERROR") else "RUNNING") caIPasses caIFailures to:report
    for line in caILog do format "%\n" line to:report
    close report
)
fn caINote line = (append caILog line;caIWrite())
fn caICheck label condition =
(
    if condition then (caIPasses += 1;caINote ("PASS "+label)) else (caIFailures += 1;caINote ("FAIL "+label))
    condition
)
fn caIRequire label condition = (caICheck label condition;if not condition do throw ("Required installer prerequisite: "+label);true)
fn caIHash path =
(
    local algorithm = (dotNetClass "System.Security.Cryptography.SHA256").Create()
    local digest = algorithm.ComputeHash ((dotNetClass "System.IO.File").ReadAllBytes path)
    algorithm.Dispose()
    toLower (substituteString ((dotNetClass "System.BitConverter").ToString digest) "-" "")
)
fn caIInside path root =
(
    local paths = dotNetClass "System.IO.Path"
    local absoluteRoot = (paths.GetFullPath root) as string
    while absoluteRoot.count > 0 and (absoluteRoot[absoluteRoot.count] == "\\" or absoluteRoot[absoluteRoot.count] == "/") do absoluteRoot = substring absoluteRoot 1 (absoluteRoot.count-1)
    (findString (toLower ((paths.GetFullPath path) as string)) (toLower (absoluteRoot+"\\"))) == 1
)
fn caIExecute archive =
(
    CA_INSTALL_RESULT = undefined
    fileIn archive
    caINote ("INSTALL_RESULT "+(CA_INSTALL_RESULT as string))
    caIRequire "installer returned seven-field stage diagnostics" (classOf CA_INSTALL_RESULT == Array and CA_INSTALL_RESULT.count == 7)
    CA_INSTALL_RESULT
)
fn caIRun =
(
    if CA_TEST_OUTPUT == undefined or CA_INSTALL_QA_ROOT == undefined do throw "Private installer runner paths are required."
    if (maxVersion())[1] != 29000 do throw "Installer tests require Max 2027 only."
    local io = dotNetClass "System.IO.File"
    local dirs = dotNetClass "System.IO.Directory"
    local startup = (getDir #userStartupScripts)+"/CyrusArrangeStartup.ms"
    local macro = (getDir #userMacros)+"/CyrusArrange.mcr"
    local ini = (getFilenamePath (getMAXIniFile()))+"Plugin.UserSettings.ini"
    caINote "STAGE verify mapped profile before any installer execution"
    caIRequire "all installer destinations belong to private profile" ((caIInside startup CA_INSTALL_QA_ROOT) and (caIInside macro CA_INSTALL_QA_ROOT) and (caIInside ini CA_INSTALL_QA_ROOT) and (caIInside (getDir #userScripts) CA_INSTALL_QA_ROOT) and (caIInside (getMAXIniFile()) CA_INSTALL_QA_ROOT))
    CA_INSTALL_QUIET = true
    local sentinelDirectory = CA_INSTALL_QA_ROOT+"/unrelated-plugin-sentinel/"
    dirs.CreateDirectory sentinelDirectory
    io.WriteAllText ini ("[Directories]\nAdditional MAX plug-ins="+(getDir #maxroot)+"/PlugIns\nOtherInstallerSentinel="+sentinelDirectory+"\n")
    io.WriteAllText startup "-- previous private startup sentinel\n"
    io.WriteAllText macro "-- previous private macro sentinel\n"
    local originalINI = caIHash ini
    local originalStartup = caIHash startup
    local originalMacro = caIHash macro
    caINote "BEGIN actual tampered MZP execution"
    caIExecute CA_INSTALL_BAD_ARCHIVE
    caICheck "tampered payload fails before publication" (CA_INSTALL_RESULT[1] == false and CA_INSTALL_RESULT[6])
    caICheck "tampered preflight identifies the altered UI file" (CA_INSTALL_RESULT[7] == "package-preflight" and (findString CA_INSTALL_RESULT[2] "ArrangeRegions.ms") != undefined)
    caICheck "tampered archive preserves exact configuration bytes" ((caIHash ini) == originalINI and (caIHash startup) == originalStartup and (caIHash macro) == originalMacro)
    local destination = CA_INSTALL_RESULT[3]
    caIRequire "computed payload destination is private" (caIInside destination CA_INSTALL_QA_ROOT)
    caICheck "failed preflight creates no payload directory" (not (dirs.Exists destination))
    caICheck "host guard accepts only Max 2027 code" ((caInstallerSupportsHost 29000) and not (caInstallerSupportsHost 28000) and not (caInstallerSupportsHost 30000))

    caINote "STAGE real macro-path failure after startup copy and exact rollback"
    local macroBackup = macro+".qa-backup"
    io.Move macro macroBackup
    dirs.CreateDirectory macro
    caIExecute CA_INSTALL_ARCHIVE
    caICheck "directory at macro path fails actual installer" (CA_INSTALL_RESULT[1] == false and CA_INSTALL_RESULT[6])
    caICheck "macro conflict reaches macro publication" (CA_INSTALL_RESULT[7] == "publish-macro")
    caICheck "macro failure rolls back startup and INI exactly" ((caIHash startup) == originalStartup and (caIHash ini) == originalINI and (dirs.Exists macro))
    caICheck "failed transaction removes only its new payload" (not (dirs.Exists destination))
    dirs.Delete macro false
    io.Move macroBackup macro

    caINote "STAGE real registration-path failure after both script copies"
    local iniBackup = ini+".qa-backup"
    io.Move ini iniBackup
    dirs.CreateDirectory ini
    caIExecute CA_INSTALL_ARCHIVE
    caICheck "directory at INI path fails actual installer" (CA_INSTALL_RESULT[1] == false and CA_INSTALL_RESULT[6])
    caICheck "INI conflict reaches native registration" (CA_INSTALL_RESULT[7] == "register-native")
    caICheck "registration failure restores both script preimages" ((caIHash startup) == originalStartup and (caIHash macro) == originalMacro and (dirs.Exists ini))
    caICheck "registration failure removes new payload directory" (not (dirs.Exists destination))
    dirs.Delete ini false
    io.Move iniBackup ini

    caINote "STAGE absent startup and macro parents with a later registration failure"
    local paths = dotNetClass "System.IO.Path"
    local startupParent = (paths.GetDirectoryName startup) as string
    local macroParent = (paths.GetDirectoryName macro) as string
    local startupParentBackup = startupParent+".qa-previous"
    local macroParentBackup = macroParent+".qa-previous"
    caIRequire "absent-parent fixtures use distinct private directories" (startupParent != macroParent and (caIInside startupParent CA_INSTALL_QA_ROOT) and (caIInside macroParent CA_INSTALL_QA_ROOT) and (caIInside startupParentBackup CA_INSTALL_QA_ROOT) and (caIInside macroParentBackup CA_INSTALL_QA_ROOT))
    dirs.Move startupParent startupParentBackup
    dirs.Move macroParent macroParentBackup
    io.Move ini iniBackup
    dirs.CreateDirectory ini
    caIExecute CA_INSTALL_ARCHIVE
    caICheck "absent parents are created through actual native registration" (CA_INSTALL_RESULT[1] == false and CA_INSTALL_RESULT[6] and CA_INSTALL_RESULT[7] == "register-native")
    caICheck "rollback removes its newly created empty startup and macro parents" (not (dirs.Exists startupParent) and not (dirs.Exists macroParent))
    caICheck "absent-parent rollback retains preexisting backup directories and bytes" ((caIHash (startupParentBackup+"/CyrusArrangeStartup.ms")) == originalStartup and (caIHash (macroParentBackup+"/CyrusArrange.mcr")) == originalMacro)
    caICheck "absent-parent failed transaction removes its new payload" (not (dirs.Exists destination))
    dirs.Delete ini false
    io.Move iniBackup ini

    caINote "STAGE install original archive and verify every installed byte"
    caIExecute CA_INSTALL_ARCHIVE
    caIRequire "actual candidate MZP installs successfully" CA_INSTALL_RESULT[1]
    caICheck "successful installation creates absent startup and macro parents" ((dirs.Exists startupParent) and (dirs.Exists macroParent) and CA_INSTALL_RESULT[7] == "complete")
    caICheck "installer reports exact 0.3.2 candidate version" (CA_INSTALL_RESULT[5] == "0.3.2")
    local filesValid = true
    for item in CA_INSTALL_FILES where not (io.Exists (destination+item[1])) or (caIHash (destination+item[1])) != item[2] do filesValid = false
    caICheck "both modules all six UIs and docs match candidate hashes" filesValid
    caICheck "native registration targets immutable native-only bin directory" ((getINISetting ini "Directories" "CyrusArrange2027") == (destination+"bin/"))
    caICheck "registered native directory contains only two files and no subdirectories" ((dirs.GetFiles (destination+"bin/")).count == 2 and (dirs.GetDirectories (destination+"bin/")).count == 0)
    caICheck "unrelated plugin registration remains unchanged" ((getINISetting ini "Directories" "OtherInstallerSentinel") == sentinelDirectory)
    caICheck "shared startup and macro match immutable payload copies" ((caIHash startup) == (caIHash (destination+"CyrusArrangeStartup.ms")) and (caIHash macro) == (caIHash (destination+"CyrusArrange.mcr")))
    local installedINI = caIHash ini
    local installedStartup = caIHash startup
    local installedMacro = caIHash macro
    caINote "BEGIN identical MZP repeated install"
    caIExecute CA_INSTALL_ARCHIVE
    caICheck "repeat installation succeeds" CA_INSTALL_RESULT[1]
    caICheck "repeat installation preserves exact configuration bytes" ((caIHash ini) == installedINI and (caIHash startup) == installedStartup and (caIHash macro) == installedMacro)

    caINote "STAGE immutable destination mismatch rejects without overwriting"
    local conflict = destination+"ArrangeRegions.ms"
    local originalConflict = io.ReadAllBytes conflict
    local originalConflictHash = caIHash conflict
    io.WriteAllText conflict "-- owned QA conflicting immutable file\n"
    local conflictHash = caIHash conflict
    caIExecute CA_INSTALL_ARCHIVE
    caICheck "conflicting immutable payload rejects actual installer" (CA_INSTALL_RESULT[1] == false and CA_INSTALL_RESULT[6])
    caICheck "immutable conflict reaches existing-payload verification" (CA_INSTALL_RESULT[7] == "verify-existing-payload" and (findString CA_INSTALL_RESULT[2] "ArrangeRegions.ms") != undefined)
    caICheck "existing conflicting file is preserved" ((caIHash conflict) == conflictHash)
    caICheck "immutable mismatch retains accepted registration and scripts" ((caIHash ini) == installedINI and (caIHash startup) == installedStartup and (caIHash macro) == installedMacro)
    io.WriteAllBytes conflict originalConflict
    caICheck "owned conflict fixture restored to exact candidate" ((caIHash conflict) == originalConflictHash and (caIHash conflict) != conflictHash)
    local pending = dirs.GetDirectories ((getDir #userScripts)+"/CyrusArrange/") ".pending-*"
    caICheck "all staging directories are cleaned" (pending.count == 0)
    local output = createFile (CA_TEST_OUTPUT+"installed-dir.txt")
    format "%\n" destination to:output
    close output
    caINote "INSTALLER_DESTINATIONS_PRIVATE"
    true
)
try (caIRun()) catch
(
    caIFailures += 1
    caINote ("EXCEPTION "+(getCurrentException() as string))
    caINote ("STACK "+(getCurrentExceptionStackTrace() as string))
)
caIFinished = true
caIWrite()
