-- Private pointer evidence, synchronized with PresentMon's QPC timebase.
global TOwner,TRoot,TEdit,TRocks,PInspectOffset,PWatching,PTrace,PRead,PObserve
PWatching=false
try(unregisterRedrawViewsCallback PObserve)catch()
fn PRead = (
    local handle=cyrusEditHandleMatrix TEdit TRocks.editLayerKey 1
    if handle==undefined do return undefined
    local clock=dotNetClass "System.Diagnostics.Stopwatch"
    local qpcMs=((clock.GetTimestamp() as double)*1000.0)/(clock.Frequency as double)
    local json=TRoot.interactionsStatistics(),m=(dotNetClass "System.Text.RegularExpressions.Regex").Match json "\"generation\":([0-9]+)"
    local row=(cyrusEditInspect TEdit PInspectOffset 1)[4][1],presented=if row[13]==undefined then undefined else row[13].translation
    #((formattedPrint qpcMs format:".3f" userLocale:false),CyrusInteractionHeld(),handle.translation,(getTransformAxis TOwner 0).translation,m.Groups.Item[1].Value as integer64,TRoot.procEpoch,TRoot.groupBuilds,cyrusEditLocalRevision TEdit,json,presented)
)
fn PObserve=(if PWatching and PTrace.count<2000 do (local row=PRead();if row!=undefined do append PTrace row))
