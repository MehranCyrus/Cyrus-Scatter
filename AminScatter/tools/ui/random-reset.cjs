// Standard native buttons. Each group changes only its own selected-layer data.
module.exports=function(s){
 const unique=(a,b)=>{if(s.split(a).length!==2)throw Error('Random reset anchor must be unique: '+a);s=s.replace(a,b);};
 unique('    fn selectedLayer = (',`    fn resetRandomization group = (
        local values=case group of (
            #rotation: #(#(#rotXMin,0.0),#(#rotXMax,0.0),#(#rotYMin,0.0),#(#rotYMax,0.0),#(#rotZMin,0.0),#(#rotZMax,0.0),#(#tiltDegrees,0.0),#(#yawMinimum,0.0),#(#yawMaximum,0.0))
            #scale: #(#(#sclXMin,1.0),#(#sclXMax,1.0),#(#sclYMin,1.0),#(#sclYMax,1.0),#(#sclZMin,1.0),#(#sclZMax,1.0),#(#scaleMinimum,1.0),#(#scaleMaximum,1.0))
            #wholeScale: #(#(#wholeScaleMin,1.0),#(#wholeScaleMax,1.0))
            #movement: #(#(#movXMin,0.0),#(#movXMax,0.0),#(#movYMin,0.0),#(#movYMax,0.0),#(#movZMin,0.0),#(#movZMax,0.0),#(#movementRange,0.0))
            default: undefined
        )
        if values==undefined do return false
        local priorTransfer=layerTransfer
        layerTransfer=true
        try (for row in values do setProperty this row[1] row[2]) catch(layerTransfer=priorTransfer;throw())
        layerTransfer=priorTransfer;dirty=true;true
    )
    fn resetSelectedRandomization group = (
        local layer=this.selectedLayer()
        if layer==undefined do return false
        local caption=case group of (#rotation:"Cyrus reset rotation";#scale:"Cyrus reset XYZ scale";#wholeScale:"Cyrus reset whole scale";#movement:"Cyrus reset movement";default:undefined)
        if caption==undefined do return false
        undo caption on layer.resetRandomization group
        if this.randomUI.controlsReady do this.randomUI.bind layer
        if this.mainUI.controlsReady do this.mainUI.refreshStats()
        CyrusViewportRedraw();true
    )
    fn selectedLayer = (`);
 const start=s.indexOf('    rollout randomUI "Randomize XYZ"'),end=s.indexOf('    rollout spacingUI ',start);
 if(start<0||end<0)throw Error('Missing native Randomize editor');
 let r=s.slice(start,end);
 // Leave ordinary Max control sizing; add one row below each existing group.
 r=r.replace(/pos:\[(\d+),(\d+)\]/g,(_,x,y)=>{
  const v=Number(y),offset=v>=456?120:v>=332?90:v>=252?60:v>=132?30:0;
  return `pos:[${x},${v+offset}]`;
 });
 r=r.replace('        fn syncControls = (',`        button resetRotation "Reset rotation" pos:[8,124] width:146 height:20
        button resetScale "Reset XYZ scale" pos:[8,278] width:146 height:20
        button resetWholeScale "Reset whole scale" pos:[8,382] width:146 height:20
        button resetMovement "Reset movement" pos:[8,536] width:146 height:20
        on resetRotation pressed do this.resetSelectedRandomization #rotation
        on resetScale pressed do this.resetSelectedRandomization #scale
        on resetWholeScale pressed do this.resetSelectedRandomization #wholeScale
        on resetMovement pressed do this.resetSelectedRandomization #movement
        fn syncControls = (`);
 s=s.slice(0,start)+r+s.slice(end);
 return s;
};
