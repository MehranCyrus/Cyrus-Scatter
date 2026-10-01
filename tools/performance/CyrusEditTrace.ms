-- Loaded by the recorder. Does not rebuild, install or redefine any plugin.
global CyrusPerf,CyrusPerfTraceBegin,CyrusPerfTraceEnd,CyrusPerfTraceInput,CSPTrace
global CSPElapsed,CSPRow,CSPWriter,CSPWriteText,CSPObject,CSPJson,CSPText,CSPMark
struct CSPTraceState (writer,buffer=#(),stack=#(),actors=#(),watched=#(),sequence=0,editSequence=0,edit=0,label="unmarked",dropped=0,errors=0,stageErrors=0,active=false)
CSPTrace=CSPTraceState()
fn CSPTraceActor obj = (
    local key=getHandleByAnim obj
    for item in CSPTrace.actors where item[1]==key do return item[2]
    undefined
)
fn CSPTraceWatch node = (
    if isValidNode node and findItem CSPTrace.watched node==0 do append CSPTrace.watched node
)
fn CSPTraceRow kind id parent actor stage duration detail atTime:undefined = (
    if CSPTrace.buffer.count>=100000 then CSPTrace.dropped+=1
    else append CSPTrace.buffer #((if atTime==undefined then CSPElapsed() else atTime),kind,id,parent,CSPTrace.edit,CSPTrace.label,actor,stage,duration,detail)
)
fn CSPTraceFlush = (
    if CSPTrace.writer!=undefined do (
        for row in CSPTrace.buffer do CSPRow CSPTrace.writer row
        CSPTrace.buffer=#()
        CSPTrace.writer.Flush()
    )
)
fn CSPTraceBeginImpl obj stage = (
    if not CSPTrace.active do return undefined
    local actor=CSPTraceActor obj
    if actor==undefined do return undefined
    CSPTrace.sequence+=1
    local parent=if CSPTrace.stack.count>0 then CSPTrace.stack[CSPTrace.stack.count][1] else 0
    local token=#(CSPTrace.sequence,parent,actor,stage,CSPElapsed(),CSPTrace.edit,CSPTrace.label)
    append CSPTrace.stack token
    CSPTraceRow "start" token[1] parent actor stage undefined "" atTime:token[5]
    token
)
fn CSPTraceEndImpl token detail = (
    local ended=CSPElapsed()
    if (isKindOf detail Array and detail.count>0 and detail[1]!="") or (classof detail==String and matchPattern detail pattern:"EXCEPTION:*") do CSPTrace.stageErrors+=1
    -- Preserve the start's edit association even if nested work pumps UI messages.
    if CSPTrace.buffer.count>=100000 then CSPTrace.dropped+=1 else
        append CSPTrace.buffer #(ended,"end",token[1],token[2],token[6],token[7],token[3],token[4],ended-token[5],(if isKindOf detail Array then CSPJson detail else detail))
    local index=findItem CSPTrace.stack token
    if index>0 do deleteItem CSPTrace.stack index
)
fn CSPTraceInputImpl stage event handles = (
    if not CSPTrace.active do return false
    local matches=#()
    for handle in handles do (
        local node=try(getAnimByHandle handle)catch(undefined)
        if findItem CSPTrace.watched node>0 do append matches ("anim="+(handle as string)+" node="+(node.handle as string)+" "+node.name)
    )
    if matches.count>0 do CSPTraceRow "input_received" 0 0 "dependency" stage undefined ((event as string)+" "+CSPText matches)
    matches.count>0
)
fn CSPTraceBeginEdit label = (
    if not CSPTrace.active do throw "Start a recording with detailed edit tracing first."
    if CSPTrace.edit!=0 do throw "Click Result visible for the current edit before beginning another."
    CSPTrace.editSequence+=1;CSPTrace.edit=CSPTrace.editSequence;CSPTrace.label=label
    CSPTraceRow "edit_begin" 0 0 "artist" "manual_marker" undefined label
    CSPMark ("Begin edit "+(CSPTrace.edit as string)+": "+label)
)
fn CSPTraceVisible = (
    if not CSPTrace.active or CSPTrace.edit==0 do throw "Begin a named edit first."
    CSPTraceRow "result_seen" 0 0 "artist" "manual_marker" undefined "Artist clicked Result visible; includes reaction time, not GPU timing."
    CSPMark ("Result visible for edit "+(CSPTrace.edit as string))
    CSPTrace.edit=0;CSPTrace.label="unmarked"
)
fn CSPTraceStop = (
    CyrusPerfTraceBegin=undefined;CyrusPerfTraceEnd=undefined;CyrusPerfTraceInput=undefined
    if CSPTrace.active do (
        CSPTrace.active=false
        CSPTraceFlush()
        CSPTrace.writer.Dispose();CSPTrace.writer=undefined
        CSPWriteText (CyrusPerf.folder+"/trace-summary.json") (CSPObject #(
            #("schema_version",1),#("spans_started",CSPTrace.sequence),#("unclosed_spans",CSPTrace.stack.count),
            #("dropped_rows",CSPTrace.dropped),#("collector_errors",CSPTrace.errors),
            #("stage_errors",CSPTrace.stageErrors),
            #("unfinished_edit",CSPTrace.edit),#("timing_scope","Synchronous script hooks; input callbacks are received after Max dispatch delay. Manual markers include human delay. No mouse-release or GPU completion measurement.")))
    )
    CSPTrace.actors=#();CSPTrace.watched=#();CSPTrace.stack=#()
)
fn CSPTraceStart target = (
    CSPTrace=CSPTraceState()
    local root=target.baseObject
    if (try(root.performanceTraceVersion())catch(0))!=1 do throw "Detailed tracing needs the tracing plugin scripts. Run Install-CyrusPerformanceTracing.ms, restart Max, then reopen the recorder."
    append CSPTrace.actors #(getHandleByAnim root,"controller:"+target.name)
    local inspect=#(root)
    for i=1 to root.layerObjects.count do (
        local layer=root.layerObjects[i]
        if (try(layer.performanceTraceVersion())catch(0))!=1 do throw "A layer has no tracing hooks. Restart Max after installing tracing scripts."
        append CSPTrace.actors #(getHandleByAnim layer,"layer:"+(i as string)+":"+root.layerNames[i])
        append inspect layer
    )
    for obj in inspect do for key in #(#surfaceNodes,#surface,#sources,#areaNodes,#patternLines,#strokeSourceNodes,#analyzerNode,#fallAnalyzer,#areaAnalyzer) where isProperty obj key do (
        local value=getProperty obj key
        if isValidNode value then CSPTraceWatch value else try(for node in value do CSPTraceWatch node)catch()
    )
    local initial=copy CSPTrace.watched #noMap
    for node in initial where isProperty node #samplePoints and isProperty node #pathCounts do (
        local obj=node.baseObject
        if (try(obj.performanceTraceVersion())catch(0))!=1 do throw "An Analyzer has no tracing hooks. Restart Max after installing both tracing scripts."
        append CSPTrace.actors #(getHandleByAnim obj,"analyzer:"+node.name)
        CSPTraceWatch obj.surface;CSPTraceWatch obj.streetLine
    )
    CSPTrace.writer=CSPWriter (CyrusPerf.folder+"/trace.csv") "elapsed_ms,kind,span_id,parent_span_id,edit_id,edit_label,actor,stage,duration_ms,detail"
    -- Buffer writes while work blocks the UI. Logging failures never alter plugin calculations.
    CSPTrace.writer.AutoFlush=false
    CSPTrace.active=true
    CyrusPerfTraceBegin=fn traceBegin obj stage = (try(CSPTraceBeginImpl obj stage)catch(CSPTrace.errors+=1;undefined))
    CyrusPerfTraceEnd=fn traceEnd token detail = (try(CSPTraceEndImpl token detail)catch(CSPTrace.errors+=1))
    CyrusPerfTraceInput=fn traceInput stage event handles = (try(CSPTraceInputImpl stage event handles)catch(CSPTrace.errors+=1))
    CSPTraceRow "trace_started" 0 0 "recorder" "capability" undefined "Preview, placements, external invalidation and Analyzer hooks available."
)
