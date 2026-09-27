module.exports=function(s){
 s=s.replace('version:30','version:31');
 for(const key of ['AminScatterLayerFields','AminScatterLayerTabs'])s=s.replace(key+'=#(',key+'=#(#sourceForwardAxes,');
 s=s.replace('AminScatterLayerFields=#(','AminScatterLayerFields=#(#borderFaceOut,#streetFaceOut,#borderCornerRadius,#streetCornerRadius,');
 s=s.replace('    parameters sourceTransformSettings (',`    parameters orientationSettings (
        sourceForwardAxes type:#intTab tabSize:0 tabSizeVariable:true
        borderFaceOut type:#boolean default:false
        streetFaceOut type:#boolean default:false
        borderCornerRadius type:#worldunits default:10.0
        streetCornerRadius type:#worldunits default:10.0
        on sourceForwardAxes set v i do dirty=true
        on borderFaceOut set v do dirty=true
        on streetFaceOut set v do dirty=true
        on borderCornerRadius set v do dirty=true
        on streetCornerRadius set v do dirty=true
    )
    fn sourceForward i = (if i>0 and i<=sourceForwardAxes.count then amax 1 (amin 4 sourceForwardAxes[i]) else 1)
    fn assignSourceForward rows value = (
        undo "Cyrus source forward axis" on (
            while sourceForwardAxes.count<sources.count do append sourceForwardAxes 1
            for i in rows where i>0 and i<=sources.count do sourceForwardAxes[i]=value
        )
        dirty=true
    )
    parameters sourceTransformSettings (`);
 s=s.replace('(side==6 and streetStraight))','(side==6 and streetStraight),#((if side==6 then streetFaceOut else if side<=2 then borderFaceOut else false),(if side==6 then streetCornerRadius else borderCornerRadius)))');
 s=s.replace('        if not rawOnly do result=CyrusEditApplyLayer',`        if not rawOnly and diversityMode==4 and (borderFaceOut or streetFaceOut) and result.count>0 do (
            local forward=if plants.count==0 then #(1) else for n in plants collect sourceForward (sourceRow n)
            local offsets=if plants.count==0 then #(0.0) else for n in plants collect sourceZOffset (sourceRow n)
            result=cyrusOrientRows result (lineInputs plants previewOnly:true) forward offsets
        )
        if not rawOnly do result=CyrusEditApplyLayer`);
 s=s.replace(/rollout (sourceUI(?:_\d+)?) "Source Object"[^]*?\n    \)/g,block=>{
  block=block.replace(/pos:\[(\d+),(\d+)\]/g,(m,x,y)=>Number(y)>=634?'pos:['+x+','+(Number(y)+52)+']':m);
  block=block.replace('        fn colorLabel',`        dropdownlist forwardAxis "Forward axis:" items:#("+Y","-Y","+X","-X") pos:[8,634] width:123
        fn colorLabel`);
  block=block.replace('sourceScaleSpin.enabled=rows.numberSet>0','sourceScaleSpin.enabled=rows.numberSet>0;forwardAxis.enabled=rows.numberSet>0');
  block=block.replace('sourceScaleSpin.value=obj.sourceScale focusedRow','sourceScaleSpin.value=obj.sourceScale focusedRow;forwardAxis.selection=obj.sourceForward focusedRow');
  block=block.replace('        on sourceZSpin changed',`        on forwardAxis selected v do if not loadingColor do (obj.assignSourceForward plantList.selection v;redrawViews())
        on sourceZSpin changed`);
  block=block.replace('if rows[k]<=obj.sourceScales.count do deleteItem obj.sourceScales rows[k]','if rows[k]<=obj.sourceScales.count do deleteItem obj.sourceScales rows[k]\n                    if rows[k]<=obj.sourceForwardAxes.count do deleteItem obj.sourceForwardAxes rows[k]');
  return block;
 });
 s=s.replace(/rollout ((?:diversityUI|lineUI)(?:_\d+)?) "[^]*?\n    \)/g,block=>{
  const m=block.match(/checkbox straightStreet[^\n]*pos:\[(\d+),(\d+)\]/);if(!m)return block;
  const y=Number(m[2]);
  block=block.replace('        checkbox straightStreet',`        checkbox faceOutCheck "Face outward" pos:[8,${y+26}] width:123
        spinner cornerRadiusSpin "Corner radius:" type:#worldunits range:[0,1000000,10] pos:[8,${y+54}] width:123 fieldWidth:52
        checkbox straightStreet`);
  block=block.replace('            straightStreet.checked=',`            faceOutCheck.visible=obj.diversityMode==4 and (analyzerChannel.selection==1 or analyzerChannel.selection==4)
            cornerRadiusSpin.visible=faceOutCheck.visible
            faceOutCheck.checked=if analyzerChannel.selection==4 then obj.streetFaceOut else obj.borderFaceOut
            cornerRadiusSpin.value=if analyzerChannel.selection==4 then obj.streetCornerRadius else obj.borderCornerRadius
            cornerRadiusSpin.enabled=faceOutCheck.checked
            straightStreet.checked=`);
  block=block.replace('        on straightStreet changed',`        on faceOutCheck changed v do (
            if analyzerChannel.selection==4 then obj.streetFaceOut=v else obj.borderFaceOut=v
            cornerRadiusSpin.enabled=v;obj.dirty=true;redrawViews()
        )
        on cornerRadiusSpin changed v do (
            if analyzerChannel.selection==4 then obj.streetCornerRadius=v else obj.borderCornerRadius=v
            obj.dirty=true;redrawViews()
        )
        on straightStreet changed`);
  return block;
 });
 return s;
};
