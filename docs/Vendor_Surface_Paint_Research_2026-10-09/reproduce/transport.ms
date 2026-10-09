-- Vendor-only test transport. No Cyrus orchestration script or UI is loaded.
global RSOwnerPID,RSCommandTimer,RSLastRequest="",RSAssert,RSWrite,RSCommandTick
fn RSWrite name value = ((dotNetClass "System.IO.File").WriteAllText (RSDir+name) value)
RSOwnerPID=((dotNetClass "System.Diagnostics.Process").GetCurrentProcess()).Id
fn RSAssert = (
    if ((dotNetClass "System.Diagnostics.Process").GetCurrentProcess()).Id!=RSOwnerPID do throw "Wrong research host"
    local cmd=substituteString (toLower (dotNetClass "System.Environment").CommandLine) "\\" "/"
    if findString cmd (toLower (RSDir+"max.ini"))==undefined do throw "Expected isolated profile"
    true
)
fn RSCommandTick sender args = (
    RSCommandTimer.Stop()
    try (
        RSAssert()
        if doesFileExist (RSDir+"request.txt") do (
            local command=(dotNetClass "System.IO.File").ReadAllText (RSDir+"request.txt")
            if command!=RSLastRequest do (
                RSLastRequest=command
                if not matchPattern command pattern:(RSDir+"*.ms") do throw "Outside owned directory"
                RSWrite "response.txt" ("RUNNING "+command)
                try(fileIn command;RSWrite "response.txt" ("SUCCESS "+command))catch(RSWrite "response.txt" ("ERROR "+command+"\n"+getCurrentException()+"\n"+getCurrentExceptionStackTrace()))
            )
        )
    )catch(RSWrite "transport-error.txt" (getCurrentException()))
    RSCommandTimer.Start()
)
try (
    RSAssert()
    local p=(dotNetClass "System.Diagnostics.Process").GetCurrentProcess(),s=stringStream ""
    for i=0 to p.Modules.Count-1 do (
        local m=p.Modules.Item[i]
        if matchPattern m.ModuleName pattern:"*Scatter*" or matchPattern m.ModuleName pattern:"*Forest*" do format "%\t%\n" m.ModuleName m.FileName to:s
    )
    RSWrite "loaded.tsv" (s as string);close s
    RSWrite "max-version.txt" (p.MainModule.FileVersionInfo.FileVersion as string)
    RSCommandTimer=dotNetObject "System.Windows.Forms.Timer";RSCommandTimer.Interval=500
    dotNet.addEventHandler RSCommandTimer "Tick" RSCommandTick;RSCommandTimer.Start()
    RSWrite "ready.txt" ("READY PID "+RSOwnerPID as string)
)catch(RSWrite "startup-error.txt" (getCurrentException()+"\n"+getCurrentExceptionStackTrace()))
