module.exports=function(s){
 s=s.replace('version:31','version:32');
 const tabs=['edgeOffsets','edgeAlong','edgeAcross'];
 for(const key of ['AminScatterLayerFields','AminScatterLayerTabs'])s=s.replace(key+'=#(',key+'=#('+tabs.map(x=>'#'+x).join(',')+',');
 s=s.replace('AminScatterLayerFields=#(','AminScatterLayerFields=#(#edgeFaceOut,#edgeCornerRadius,');
 s=s.replace('    parameters orientationSettings (',`    parameters edgeRowSettings (
        edgeOffsets type:#floatTab tabSize:0 tabSizeVariable:true
        edgeAlong type:#floatTab tabSize:0 tabSizeVariable:true
        edgeAcross type:#floatTab tabSize:0 tabSizeVariable:true
        edgeFaceOut type:#boolean default:true
        edgeCornerRadius type:#worldunits default:10.0
        on edgeOffsets set v i do dirty=true
        on edgeAlong set v i do dirty=true
        on edgeAcross set v i do dirty=true
        on edgeFaceOut set v do dirty=true
        on edgeCornerRadius set v do dirty=true
    )
    parameters orientationSettings (`);
 s=s.replace('    fn syncStrokes = (',`    fn syncStrokes = (
        while edgeOffsets.count<patternLines.count do append edgeOffsets 0.0
        while edgeAlong.count<patternLines.count do append edgeAlong 0.0
        while edgeAcross.count<patternLines.count do append edgeAcross 0.0`);
 s=s.replace('dirty=true;patternLines.count','syncStrokes();dirty=true;patternLines.count');
 s=s.replace('for key in #(#strokeSides,#patternLines','for key in #(#edgeOffsets,#edgeAlong,#edgeAcross,#strokeSides,#patternLines');
 s=s.replaceAll('#(0.0,0.0,0.0,0.0,0.0,0.0)','#(0.0,0.0,0.0,0.0,0.0,0.0,0.0)');
 s=s.replace('                        6: (path.packedLines path.boundaryVertices path.boundaryCounts)','                        6: (path.packedLines path.boundaryVertices path.boundaryCounts)\n                        7: (path.packedLines path.boundaryVertices path.boundaryCounts)');
 s=s.replace('else if side<=2 and isProperty path','else if (side<=2 or side==7) and isProperty path');
 s=s.replace('append bands #(data,totals[pathIndex][side]','append bands #(data,(if side==7 then patternWidths[i] else totals[pathIndex][side])');
 s=s.replace('(if side==6 then 2 else side),start,mask','(if side==7 then 6 else if side==6 then 2 else side),(if side==7 then 0 else start),mask');
 s=s.replace('if side==6 then streetFaceOut else','if side==7 then edgeFaceOut else if side==6 then streetFaceOut else');
 s=s.replace('(if side==6 then streetCornerRadius else borderCornerRadius)))','(if side==7 then edgeCornerRadius else if side==6 then streetCornerRadius else borderCornerRadius)),#(edgeOffsets[i],edgeAlong[i],edgeAcross[i]))');
 s=s.replace('(borderFaceOut or streetFaceOut)','(borderFaceOut or streetFaceOut or (findItem strokeSides 7>0))');
 s=s.replace(/rollout ((?:diversityUI|lineUI)(?:_\d+)?) "[^]*?\n    \)/g,b=>{
  b=b.replace('"Points","Street Side")','"Points","Street Side","Edge Border")');
  b=b.replace('(analyzerChannel.selection==4 and obj.strokeSides[i]==6))','(analyzerChannel.selection==4 and obj.strokeSides[i]==6) or (analyzerChannel.selection==5 and obj.strokeSides[i]==7))');
  b=b.replace('"Single ","Street ")','"Single ","Street ","Edge ")');
  b=b.replace('append labels (prefixes[side]+','append labels (if side==7 then ("Edge "+(strokeRows.count as string)+": spacing "+units.formatValue obj.patternWidths[i]) else (prefixes[side]+');
  b=b.replace('units.formatValue total[side])','units.formatValue total[side]))');
  b=b.replaceAll('analyzerChannel.selection==1 or analyzerChannel.selection==4','analyzerChannel.selection==1 or analyzerChannel.selection==4 or analyzerChannel.selection==5');
  b=b.replace('if boundaryOnly do addInside.text="Add Stroke Inside"','if boundaryOnly do addInside.text=if analyzerChannel.selection==5 then "Add Edge Row" else "Add Stroke Inside"');
  b=b.replace('local side=if obj.diversityMode==4 and analyzerChannel.selection==4','local side=if obj.diversityMode==4 and analyzerChannel.selection==5 then 7 else if obj.diversityMode==4 and analyzerChannel.selection==4');
  b=b.replaceAll('if analyzerChannel.selection==4 then obj.streetFaceOut','if analyzerChannel.selection==5 then obj.edgeFaceOut else if analyzerChannel.selection==4 then obj.streetFaceOut');
  b=b.replaceAll('if analyzerChannel.selection==4 then obj.streetCornerRadius','if analyzerChannel.selection==5 then obj.edgeCornerRadius else if analyzerChannel.selection==4 then obj.streetCornerRadius');
  // Both read and write branches are explicit; prevent assignment to a conditional expression.
  b=b.replace('then obj.edgeFaceOut else if analyzerChannel.selection==4 then obj.streetFaceOut=v','then obj.edgeFaceOut=v else if analyzerChannel.selection==4 then obj.streetFaceOut=v');
  b=b.replace('then obj.edgeCornerRadius else if analyzerChannel.selection==4 then obj.streetCornerRadius=v','then obj.edgeCornerRadius=v else if analyzerChannel.selection==4 then obj.streetCornerRadius=v');
  const y=Number(b.match(/spinner cornerRadiusSpin[^\n]*pos:\[\d+,(\d+)\]/)[1]);
  b=b.replace('        checkbox faceOutCheck',`        spinner edgeOffsetSpin "Offset inward:" range:[-1000000,1000000,0] type:#worldunits pos:[8,${y+30}] width:123 fieldWidth:52
        spinner edgeAlongSpin "Jitter along:" range:[0,1000000,0] type:#worldunits pos:[8,${y+58}] width:123 fieldWidth:52
        spinner edgeAcrossSpin "Jitter across:" range:[0,1000000,0] type:#worldunits pos:[8,${y+86}] width:123 fieldWidth:52
        label edgeRowHelp "Spacing sets count. Jitter 0 = exact." pos:[8,${y+114}] width:123 height:36
        checkbox faceOutCheck`);
  b=b.replace('            loadingStroke=true\n            local row=selectedStroke()',`            loadingStroke=true
            obj.syncStrokes()
            local edgeVisible=obj.diversityMode==4 and analyzerChannel.selection==5
            for c in #(edgeOffsetSpin,edgeAlongSpin,edgeAcrossSpin,edgeRowHelp) do c.visible=edgeVisible
            cornerRadiusSpin.text=if edgeVisible then "Blend radius:" else "Corner radius:"
            strokeWidth.text=if edgeVisible then "Spacing:" else "Width:"
            local row=selectedStroke()`);
  b=b.replace('            if active do (',`            for c in #(edgeOffsetSpin,edgeAlongSpin,edgeAcrossSpin) do c.enabled=active
            if active do (
                edgeOffsetSpin.value=obj.edgeOffsets[row];edgeAlongSpin.value=obj.edgeAlong[row];edgeAcrossSpin.value=obj.edgeAcross[row]`);
  // MAXScript must see selectedStroke before binding the control handlers.
  b=b.replace('        on strokeWidth changed',`        on edgeOffsetSpin changed v do if not loadingStroke do (local row=selectedStroke();if row>0 do obj.edgeOffsets[row]=v;redrawViews())
        on edgeAlongSpin changed v do if not loadingStroke do (local row=selectedStroke();if row>0 do obj.edgeAlong[row]=v;redrawViews())
        on edgeAcrossSpin changed v do if not loadingStroke do (local row=selectedStroke();if row>0 do obj.edgeAcross[row]=v;redrawViews())
        on strokeWidth changed`);
  b=b.replace('strokeHelp.text=if analyzed then','strokeHelp.text=if analyzed and analyzerChannel.selection==5 then "One row along the boundary." else if analyzed then');
  return b;
 });
 return s;
};
