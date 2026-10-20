global CA_INSTALL_QUIET, CA_INSTALL_RESULT, caInstallerSupportsHost
fn caInstallerSupportsHost code = (code == 29000)
(
    local io = dotNetClass "System.IO.File"
    local dirs = dotNetClass "System.IO.Directory"
    local paths = dotNetClass "System.IO.Path"
    local packageDir = getFilenamePath (getSourceFileName())
    local productRoot = (getDir #userScripts) + "/CyrusArrange/"
    local destination = productRoot + "__VERSION__-__PAYLOAD_ID__/"
    local nativeDirectory = destination + "bin/"
    local startupPath = (getDir #userStartupScripts) + "/CyrusArrangeStartup.ms"
    local macroPath = (getDir #userMacros) + "/CyrusArrange.mcr"
    local iniPath = (getFilenamePath (getMAXIniFile())) + "Plugin.UserSettings.ini"
    local installFiles = __INSTALL_FILES__
    local staging = undefined
    local destinationCreated = false
    local configurationChanged = false
    local previous = #()
    local createdDirectories = #()
    local succeeded = false
    local rollbackOK = true
    local message = ""
    local stage = "host-check"
    fn hashFile io path =
    (
        local algorithm = (dotNetClass "System.Security.Cryptography.SHA256").Create()
        local bytes = algorithm.ComputeHash (io.ReadAllBytes path)
        algorithm.Dispose()
        toLower (substituteString ((dotNetClass "System.BitConverter").ToString bytes) "-" "")
    )
    fn restoreFile io path bytes =
    (
        if bytes == undefined then (if io.Exists path do io.Delete path)
        else io.WriteAllBytes path bytes
    )
    fn removeOwnedTree dirs paths folder root =
    (
        local absoluteRoot = (paths.GetFullPath root) as string
        while absoluteRoot.count > 0 and (absoluteRoot[absoluteRoot.count] == "\\" or absoluteRoot[absoluteRoot.count] == "/") do
            absoluteRoot = substring absoluteRoot 1 (absoluteRoot.count-1)
        local absolute = (paths.GetFullPath folder) as string
        local prefix = toLower (absoluteRoot+"\\")
        if (findString (toLower absolute) prefix) != 1 do throw "Refusing cleanup outside the Cyrus Arrange product directory."
        if dirs.Exists absolute do dirs.Delete absolute true
    )
    fn ensureDirectory dirs paths target created =
    (
        local cursor = (paths.GetFullPath target) as string
        while cursor.count > 3 and (cursor[cursor.count] == "\\" or cursor[cursor.count] == "/") do cursor = substring cursor 1 (cursor.count-1)
        local missing = #()
        while not (dirs.Exists cursor) do
        (
            if missing.count >= 64 do throw "Too many absent parent directories."
            append missing cursor
            local parent = paths.GetDirectoryName cursor
            if parent == undefined or parent == "" or parent == cursor do throw "Cannot resolve the installation directory's existing parent."
            cursor = parent as string
        )
        for i = missing.count to 1 by -1 do
        (
            dirs.CreateDirectory missing[i]
            append created missing[i]
        )
    )
    CA_INSTALL_RESULT = #(false,"Installation has not completed.",destination,"__PAYLOAD_ID__","__VERSION__",false,stage)
    try
    (
        if not (caInstallerSupportsHost (maxVersion())[1]) do throw "Cyrus Arrange __VERSION__ requires 3ds Max 2027."
        -- Admit the complete archive payload before touching configuration or installed files.
        stage = "package-preflight"
        for item in installFiles do
            if (hashFile io (packageDir+item[1])) != item[2] do throw ("Package hash mismatch: "+item[1])
        stage = "capture-preimages"
        for path in #(iniPath,startupPath,macroPath) do
            append previous #(path,(if io.Exists path then io.ReadAllBytes path else undefined))
        stage = "create-install-directories"
        ensureDirectory dirs paths productRoot createdDirectories
        ensureDirectory dirs paths (paths.GetDirectoryName startupPath) createdDirectories
        ensureDirectory dirs paths (paths.GetDirectoryName macroPath) createdDirectories
        stage = "stage-payload"
        staging = productRoot+".pending-"+(((dotNetClass "System.Guid").NewGuid()).ToString "N")+"/"
        dirs.CreateDirectory staging
        for item in installFiles do
        (
            local target = staging+item[1]
            dirs.CreateDirectory (paths.GetDirectoryName target)
            io.Copy (packageDir+item[1]) target false
            if (hashFile io target) != item[2] do throw ("Staged payload verification failed: "+item[1])
        )
        if dirs.Exists destination then
        (
            stage = "verify-existing-payload"
            for item in installFiles do
                if not (io.Exists (destination+item[1])) or (hashFile io (destination+item[1])) != item[2] do
                    throw ("Different or missing file at immutable install path: "+item[1])
            removeOwnedTree dirs paths staging productRoot
            staging = undefined
        )
        else
        (
            stage = "publish-payload"
            dirs.Move staging destination
            staging = undefined
            destinationCreated = true
        )
        stage = "verify-native-directory"
        if (dirs.GetFiles nativeDirectory).count != 2 or (dirs.GetDirectories nativeDirectory).count != 0 do
            throw "The native plugin directory must contain only the two matched Cyrus Arrange modules."
        configurationChanged = true
        stage = "publish-startup"
        io.Copy (destination+"CyrusArrangeStartup.ms") startupPath true
        stage = "publish-macro"
        io.Copy (destination+"CyrusArrange.mcr") macroPath true
        stage = "register-native"
        if not (setINISetting iniPath "Directories" "CyrusArrange2027" nativeDirectory) do throw "Could not register the native module directory."
        stage = "verify-publication"
        if (getINISetting iniPath "Directories" "CyrusArrange2027") != nativeDirectory do throw "Native module registration did not verify."
        if (hashFile io startupPath) != (hashFile io (destination+"CyrusArrangeStartup.ms")) do throw "Startup publication did not verify."
        if (hashFile io macroPath) != (hashFile io (destination+"CyrusArrange.mcr")) do throw "Macro publication did not verify."
        succeeded = true
        stage = "complete"
        message = "Cyrus Arrange __VERSION__ installed. Restart 3ds Max 2027.\n\nIn Customize User Interface, category Cyrus, add Create Cyrus Arrange or Cyrus Arrange to your toolbar. Select receiving geometry and run Create Cyrus Arrange. Add props and Generate in Modify > Cyrus Arrange. Arrange Parameters opens the same parameters.\n\nExisting versions are retained. This installer does not load new native modules into the current session."
    )
    catch
    (
        message = "["+stage+"] "+(getCurrentException() as string)
        if configurationChanged do
            for row in previous do
                try (restoreFile io row[1] row[2]) catch
                (
                    rollbackOK = false
                    message += "\nRollback: "+(getCurrentException() as string)
                )
        if staging != undefined do
            try (removeOwnedTree dirs paths staging productRoot) catch
            (
                rollbackOK = false
                message += "\nStaging cleanup: "+(getCurrentException() as string)
            )
        if destinationCreated do
            try (removeOwnedTree dirs paths destination productRoot) catch
            (
                rollbackOK = false
                message += "\nPayload cleanup: "+(getCurrentException() as string)
            )
        for i = createdDirectories.count to 1 by -1 do
            try
            (
                local created = createdDirectories[i]
                if dirs.Exists created do
                (
                    if (dirs.GetFiles created).count != 0 or (dirs.GetDirectories created).count != 0 then
                    (
                        rollbackOK = false
                        message += "\nCreated-directory cleanup: Created directory is no longer empty; retained: "+created
                    )
                    else dirs.Delete created false
                )
            )
            catch
            (
                rollbackOK = false
                message += "\nCreated-directory cleanup: "+(getCurrentException() as string)
            )
    )
    CA_INSTALL_RESULT = #(succeeded,message,destination,"__PAYLOAD_ID__","__VERSION__",rollbackOK,stage)
    if CA_INSTALL_QUIET != true do
        messageBox message title:(if succeeded then "Cyrus Arrange" else "Cyrus Arrange installation failed")
)
