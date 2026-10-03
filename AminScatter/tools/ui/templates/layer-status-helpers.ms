global CyrusLayerStatusData,CyrusUICount,CyrusUILayerState
struct CyrusLayerStatusData (
    hasResult=false,placements=0,previewCount=0,mode=0,buildMs=0,
    needsUpdate=true,errorText="",densityCapped=false,inputOff=false
)
fn CyrusUICount value compact:false = (
    if compact and value>=1000000 do return ((formattedPrint (value/1000000.0) format:".1f")+"m")
    if compact and value>=1000 do return ((formattedPrint (value/1000.0) format:".1f")+"k")
    local digits=substituteString (value as string) "L" "",result=""
    for i=1 to digits.count do (
        result+=substring digits i 1
        if i<digits.count and mod (digits.count-i) 3==0 do result+=","
    )
    result
)
fn CyrusUILayerState stats enabled controllerEnabled previewVisible = (
    if not controllerEnabled do return #("Off","Controller disabled")
    if not enabled do return #("Off","Layer disabled")
    if stats.inputOff do return #("Off","Analyzer input disabled")
    if stats.errorText!="" do return #("Error","Preview error")
    if not previewVisible do return #("Hidden",if stats.needsUpdate then "Preview hidden; needs Update" else "Preview hidden")
    if not stats.hasResult do return #("--","Not built")
    if stats.needsUpdate do return #("Stale","Needs update")
    if stats.mode>1 and stats.previewCount<stats.placements do return #("Limited","Preview displays a subset")
    if stats.placements==0 do return #("Empty","Empty")
    #("OK","Cached")
)
