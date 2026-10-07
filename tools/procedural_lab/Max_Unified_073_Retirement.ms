-- Only an old ignored fixture; do not open an artist file for this probe.
global U73Retirement
fn U73Retirement = (
    local path="F:/Cursor/_Cyrus_Apps/CyrusScatter/build/mcp-qualification/procedural07-ui-final02-ordinary/SC-Persistence.max"
    if not doesFileExist path do throw "Old private scene fixture is missing"
    local io=dotNetClass "System.IO.File",convert=dotNetClass "System.Convert"
    local before=convert.ToBase64String (io.ReadAllBytes path)
    local opened=false,errorText=""
    try(opened=loadMaxFile path quiet:true)catch(errorText=getCurrentException())
    local rows=#(),rejected=0
    for n in objects where classof n.baseObject==AminScatterObject do (
        local r=n.baseObject,model="",failure=""
        try(model=r.calculationModel();r.procReadSnapshot())catch(failure=getCurrentException())
        if findString failure "retired Cyrus settings schema"!=undefined and not r.procSchemaValid do rejected+=1
        append rows #(#("node",n.name),#("version",try(r.version)catch(undefined)),#("model",model),#("failure",failure))
    )
    local same=before==(convert.ToBase64String (io.ReadAllBytes path))
    if not same do throw "Read-only retirement probe changed the original fixture"
    CSPWriteText (MCPFixtureDir+"retirement073.json") (CSPObject #(#("load_result",opened),#("error",errorText),#("controllers",rows),#("original_unchanged",same)))
    if rows.count==0 or rejected!=rows.count do throw "Max continued loading unsupported Scatter settings without a persistent denial"
    -- Max permits ordinary scene geometry to load, but denial must survive
    -- re-saving as version54, copying, cold output and another reopen.
    local saved=MCPFixtureDir+"Denied-Development-Scene.max",copyDenied=false
    local old=(getNodeByName "P07_Controller").baseObject
    try(AminScatterCopyLayer old (createInstance AminScatterObject))catch(copyDenied=(findString (getCurrentException()) "retired Cyrus settings schema"!=undefined))
    if not copyDenied do throw "Copy bypassed the development-schema denial"
    saveMaxFile saved quiet:true;loadMaxFile saved quiet:true
    old=(getNodeByName "P07_Controller").baseObject
    local outputDenied=false
    try(old.procReadSnapshot())catch(outputDenied=(findString (getCurrentException()) "retired Cyrus settings schema"!=undefined))
    if not outputDenied or old.procSchemaValid do throw "Re-save/reopen cleared the development-schema denial"
    CSPWriteText (MCPFixtureDir+"retirement073.json") (CSPObject #(#("passed",true),#("scene_geometry_may_load",opened),#("denied_controllers",rejected),#("copy_denied",copyDenied),#("resave_output_denied",outputDenied),#("original_unchanged",same)))
    true
)
