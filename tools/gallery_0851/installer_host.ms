-- Load the actual packaged installer core inside Max; all destinations are owned.
(
    if not matchPattern MCPFixtureDir pattern:"*/build/mcp-qualification/foundation-roadmap-gallery0851-*/" do throw "Owned host required."
    local log=createFile (MCPFixtureDir+"installer-host-"+(timeStamp() as string)+".txt")
    try (
        local file=dotNetClass "System.IO.File",directory=file.ReadAllText (MCPFixtureDir+"installer-pilot-payload.txt")
        local inventory=file.ReadAllBytes (pathConfig.appendPath directory "InstallInventory.txt")
        dotNet.loadAssembly (pathConfig.appendPath directory "CyrusInstaller.dll")
        local hash=(dotNetClass "Cyrus.Setup.InstallEngine").Hash inventory
        local root=MCPFixtureDir+"installer-recipient",paths=dotNetObject "Cyrus.Setup.InstallPaths" (root+"/scripts") (root+"/startup") (root+"/macros") (root+"/profile")
        local engine=dotNetObject "Cyrus.Setup.InstallEngine" directory hash
        local release=engine.Install paths
        if not doesFileExist (release+"/bin/AminScatter.dlx") do throw "Installed native payload missing."
        if not doesDirectoryExist (release+"/Library-0.85.1") do throw "Installed library missing."
        if engine.Install paths!=release do throw "Identical repair changed release identity."
        file.WriteAllText (MCPFixtureDir+"installer-recipient-release.txt") release
        format "PASS: net48 installer core loads in Max 2027 .NET runtime; actual payload installs/repairs in owned destinations.\nRelease: %\n" release to:log
        close log
    )catch(format "ERROR: %\n" (getCurrentException()) to:log;close log;throw())
)
