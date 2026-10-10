-- Paint Methods Lab 0.1.0; requires matching PaintLab4.dlx at Max startup.
global PL_D
try(destroyDialog PL_D)catch()
rollout PL_D "D · Baked Surface Field — 0.1.0" width:310 (
    local api=paintLabD, ids=#(), labels=#(), current=0
    fn region = (if current<1 or current>ids.count do throw "Pick a receiver first";ids[current])
    fn attempt action = (try(action())catch(messageBox (getCurrentException()) title:"Paint Methods Lab"))
    pickButton pickReceiver "Pick receiver / new region" width:280 autoDisplay:false
    dropdownList regions "Active region" items:#() width:280
    editText regionName "Name:" text:"Region" width:280
    spinner resolution "Paint precision / pixel size:" range:[0.001,10000,5] type:#worldunits fieldwidth:75
    label note "Precision is fixed when the region is created." align:#left
    radioButtons mode "Brush" labels:#("Paint","Erase") columns:2
    spinner radius "Radius:" range:[0.01,100000,80] type:#worldunits fieldwidth:85
    spinner strength "Strength:" range:[0,1,1] type:#float scale:0.05 enabled:true
    spinner softness "Soft edge:" range:[0,1,0] type:#float scale:0.05 enabled:true
    button start "Start painting" across:2 width:135
    button stop "Stop" width:135
    button undoPaint "Undo paint" across:2 width:135
    button redoPaint "Redo paint" width:135
    button clearPaint "Clear region (undoable)" width:280
    checkbox boundary "Boundary (50% for soft)" checked:true across:2
    checkbox fill "Fill" checked:false
    checkbox points "Coverage samples" checked:true
    spinner displayStep "Display step (independent):" range:[0.01,100000,25] type:#worldunits fieldwidth:75
    button refresh "Refresh preview" width:280
    button savePaint "Save region..." across:2 width:135
    button loadPaint "Load region..." width:135
    label stats "No receiver selected" width:280 height:85
    label limits "Face-local tiles; restricted Euclidean footprint. Geodesic painting is not implemented." width:280 height:48
    timer statusTimer interval:500 active:true
    fn updateStats = (
        if current>0 do (
            local s=api "stats" #(region())
            stats.text="Items: "+((s[2] as integer) as string)+" | State: "+(formattedPrint (s[3]/1048576.0) format:".2f")+" MiB\nEdit: "+(formattedPrint s[7] format:".2f")+" ms | Preview: "+(formattedPrint s[8] format:".2f")+" ms\nLines: "+((s[9] as integer) as string)+" | Samples: "+((s[11] as integer) as string)+"\n"+(api "error" #(region()))
        )
    )
    fn showPreview = (api "boundary" #(region(),boundary.checked);api "refresh" #(region(),displayStep.value,points.checked,fill.checked);updateStats())
    fn addReceiver obj = (
        local id=api "create" #(obj,resolution.value)
        append ids id;append labels (obj.name+" / "+regionName.text);current=ids.count
        regions.items=labels;regions.selection=current;showPreview();id
    )
    fn beginPainting = (api "start" #(region(),radius.value,mode.state==2,strength.value,softness.value))
    fn endPainting = (api "stop" #(region());showPreview())
    on pickReceiver picked obj do try(addReceiver obj)catch(messageBox (getCurrentException()) title:"Paint Methods Lab")
    on regions selected i do try(if current>0 do api "stop" #(region());current=i;showPreview())catch(messageBox (getCurrentException()))
    on regionName entered text do (if current>0 do (labels[current]=text;regions.items=labels;regions.selection=current))
    on start pressed do try(beginPainting())catch(messageBox (getCurrentException()))
    on stop pressed do try(endPainting())catch(messageBox (getCurrentException()))
    on undoPaint pressed do try(api "undo" #(region());updateStats())catch(messageBox (getCurrentException()))
    on redoPaint pressed do try(api "redo" #(region());updateStats())catch(messageBox (getCurrentException()))
    on clearPaint pressed do try(api "clear" #(region());updateStats())catch(messageBox (getCurrentException()))
    on refresh pressed do try(showPreview())catch(messageBox (getCurrentException()))
    on boundary changed value do (if current>0 do try(showPreview())catch(messageBox (getCurrentException())))
    on fill changed value do (if current>0 do try(showPreview())catch(messageBox (getCurrentException())))
    on points changed value do (if current>0 do try(showPreview())catch(messageBox (getCurrentException())))
    on savePaint pressed do try(local path=getSaveFileName caption:"Save independent paint region" types:"Paint Lab (*.plab)|*.plab|";if path!=undefined do api "save" #(region(),path))catch(messageBox (getCurrentException()))
    on loadPaint pressed do try(local path=getOpenFileName caption:"Load into matching receiver and resolution" types:"Paint Lab (*.plab)|*.plab|";if path!=undefined do (api "load" #(region(),path);updateStats()))catch(messageBox (getCurrentException()))
    on statusTimer tick do (if current>0 do try(updateStats())catch(stats.text=getCurrentException()))
    on PL_D close do (statusTimer.active=false;for id in ids do try(api "delete" #(id))catch())
)
createDialog PL_D
