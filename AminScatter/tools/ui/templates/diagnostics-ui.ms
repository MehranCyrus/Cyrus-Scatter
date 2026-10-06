    rollout diagnosticsUI "Diagnostics" width:#cmdPanel category:220 autoLayoutOnResize:true (
        local root=CyrusLayerUIRoot,controlsReady=false
        button startButton "Start recording" pos:[8,8] width:(diagnosticsUI.width-16) tooltip:"Record engineering events in this Max process. Off by default; at most ten minutes, 4,096 events and 4 MiB."
        button stopButton "Stop" pos:[8,38] width:((diagnosticsUI.width-22)/2) tooltip:"Stop recording and retain the bounded history in memory."
        button saveButton "Save report..." pos:[diagnosticsUI.width/2+3,38] width:((diagnosticsUI.width-22)/2) tooltip:"Choose a local JSON file, stop recording and save its retained pages. No MCP or upload is required."
        button refreshButton "Read recording status" pos:[8,68] width:(diagnosticsUI.width-16) tooltip:"Read recorder state without evaluating the scene. Status has no polling timer."
        label statusInfo "Recording is off." pos:[8,98] width:(diagnosticsUI.width-16) height:74
        label scopeInfo "Records all Scatter setups in this Max process. Engineering events are not training data. Save reports explicitly; closing this panel keeps the session." pos:[8,178] width:(diagnosticsUI.width-16) height:84
        fn field page name = (
            local pattern="\""+name+"\":(\"[^\"]*\"|[0-9]+|true|false)"
            local match=(dotNetClass "System.Text.RegularExpressions.Regex").Match page pattern
            if not match.Success do throw ("Missing diagnostic field: "+name)
            match.Groups.Item[1].Value
        )
        fn refresh = (
            local page=cyrusDiagnosticSnapshot 0 0,active=cyrusDiagnosticActive(),session=field page "session_id"
            startButton.enabled=not active;stopButton.enabled=active;saveButton.enabled=session!="\"\""
            statusInfo.text=(if active then "Recording" else "Stopped / off")+" | "+(field page "retained")+" retained\nEvicted: "+(field page "evicted")+" | Lock drops: "+(field page "lock_drops")+"\nFailures: "+(field page "failures")+" | Truncated: "+(field page "truncated")+"\nUse Read recording status to refresh."
            controlsReady=true;true
        )
        fn startRecording = (
            local identifier=(dotNetClass "System.Guid").NewGuid(),session="trace_"+(identifier.ToString "N")
            cyrusDiagnosticStart session 4096 4194304 600000
            refresh();session
        )
        fn nativeIdentity = (
            local process=(dotNetClass "System.Diagnostics.Process").GetCurrentProcess(),pairs=#()
            local names=#("AminScatter.dlx","CyrusBrush.dlx","CyrusBrushStorage.dlh","CyrusScatterEdit.dlm")
            for i=0 to process.Modules.Count-1 do (
                local module=process.Modules.Item[i],name=filenameFromPath module.FileName
                if findItem names name>0 do (
                    local sha=(dotNetClass "System.Security.Cryptography.SHA256").Create(),hash
                    try(hash=sha.ComputeHash ((dotNetClass "System.IO.File").ReadAllBytes module.FileName))catch(sha.Dispose();throw())
                    sha.Dispose()
                    append pairs ("\""+name+"\":\""+(toLower (substituteString ((dotNetClass "System.BitConverter").ToString hash) "-" ""))+"\"")
                )
            )
            if pairs.count!=names.count do throw "Cannot identify the four loaded Cyrus native modules."
            local json="{"
            for i=1 to pairs.count do json+=(if i==1 then "" else ",")+pairs[i]
            json+"}"
        )
        fn saveReport path = (
            if path==undefined or path=="" do return false
            local initial=cyrusDiagnosticSnapshot 0 0,session=field initial "session_id"
            if session=="\"\"" do throw "Start a diagnostic recording first."
            cyrusDiagnosticStop()
            local identifier=(dotNetClass "System.Guid").NewGuid(),temporary=path+"."+(identifier.ToString "N")+".tmp",stream=undefined
            try (
                stream=dotNetObject "System.IO.StreamWriter" temporary false (dotNetObject "System.Text.UTF8Encoding" false)
                local header="{\"schema\":\"cyrus.diagnostic-bundle/1.0\",\"training_eligible\":false,\"development_version\":\""+root.uiVersion()+"\",\"script_payload_sha256\":\""+CyrusLoadedScriptFingerprint+"\",\"native_file_sha256\":"+(nativeIdentity())+",\"pages\":["
                stream.Write header
                local cursor=0L,pageCount=0,bytes=header.count,finished=false,last=undefined,retained=undefined
                while not finished do (
                    local page=cyrusDiagnosticSnapshot cursor 500
                    if field page "session_id"!=session or field page "active"!="false" do throw "Diagnostic session changed while saving."
                    if last==undefined then (last=field page "last_sequence";retained=field page "retained")
                    else if field page "last_sequence"!=last or field page "retained"!=retained do throw "Diagnostic history changed while saving."
                    pageCount+=1;bytes+=(dotNetClass "System.Text.Encoding").UTF8.GetByteCount page
                    if pageCount>33 or bytes>16777100 do throw "Diagnostic report exceeds its export limit."
                    if pageCount>1 do stream.Write ","
                    stream.Write page
                    local next=(field page "next_sequence") as integer64
                    finished=(field page "has_more")=="false"
                    if not finished and next<=cursor do throw "Diagnostic page did not advance."
                    cursor=next
                )
                stream.Write "]}";stream.Flush();stream.Close();stream=undefined
                local cleanupNote=""
                if (dotNetClass "System.IO.File").Exists path then (
                    local backup=temporary+".previous"
                    (dotNetClass "System.IO.File").Replace temporary path backup
                    try((dotNetClass "System.IO.File").Delete backup)catch(cleanupNote="\nThe previous report backup remains beside the saved file.")
                )
                else (dotNetClass "System.IO.File").Move temporary path
                refresh();statusInfo.text="Saved "+(pageCount as string)+" diagnostic pages locally.\nRecording stopped. Inspect page health for any dropped or evicted events."+cleanupNote
                true
            )catch(
                if stream!=undefined do stream.Close()
                if (dotNetClass "System.IO.File").Exists temporary do (dotNetClass "System.IO.File").Delete temporary
                refresh();throw()
            )
        )
        on diagnosticsUI open do (root=this;controlsReady=false)
        on diagnosticsUI close do controlsReady=false
        on diagnosticsUI rolledUp state do if diagnosticsUI.open do refresh()
        on startButton pressed do try(startRecording())catch(messageBox (getCurrentException()) title:"Cyrus diagnostics")
        on stopButton pressed do (cyrusDiagnosticStop();refresh())
        on saveButton pressed do try(
            local path=getSaveFileName caption:"Save Cyrus engineering report" types:"JSON report (*.json)|*.json|" filename:"Cyrus-diagnostics.json"
            saveReport path
        )catch(messageBox (getCurrentException()) title:"Cyrus diagnostics")
        on refreshButton pressed do refresh()
    )
