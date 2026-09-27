const fs=require('fs');
module.exports=s=>{
 s=s.replace('version:40','version:41').replace('AminScatterLayerFields=#(','AminScatterLayerFields=#(#streetTrimStart,#streetTrimEnd,#centerStreetOffset,');
 // Methods follow streetEdgeMask so MAXScript resolves it locally.
 s=s.replace('    fn lineInputs plants',fs.readFileSync('tools/ui/templates/street-layout-methods.ms','utf8')+'\n    fn lineInputs plants');
 s=s.replace('3: (path.packedLines path.pathVertices path.pathCounts)','3: (centerStreetPaths path)');
 s=s.replace('                    append bands #(data,','                    if side==6 do (local trimmed=trimmedStreetData path;data=trimmed[1];mask=trimmed[2])\n                    append bands #(data,');
 // Earlier method must use this to resolve a later plugin method.
 s=s.replace('areaAnalyzer.packedLines areaAnalyzer.pathVertices areaAnalyzer.pathCounts','this.centerStreetPaths areaAnalyzer');
 s=s.replace(/rollout ((?:diversityUI|lineUI)(?:_\d+)?) "[^]*?\n    \)/g,b=>{
  const y=Number(b.match(/spinner cornerRadiusSpin[^\n]*pos:\[\d+,(\d+)\]/)[1])+30;
  b=b.replace('        checkbox faceOutCheck',`        spinner streetStartSpin "Trim start:" range:[0,1e9,0] type:#worldunits pos:[8,${y}] width:146 fieldWidth:62
        spinner streetEndSpin "Trim end:" range:[0,1e9,0] type:#worldunits pos:[8,${y+28}] width:146 fieldWidth:62
        spinner centerStreetSpin "Street offset:" range:[-1e9,1e9,0] type:#worldunits pos:[8,${y}] width:146 fieldWidth:62
        label streetLayoutHelp "Positive offset = away from street. Trim follows path direction." pos:[8,${y+60}] width:146 height:44
        checkbox faceOutCheck`);
  b=b.replace('            straightStreet.checked=',`            streetStartSpin.visible=obj.diversityMode==4 and analyzerChannel.selection==4
            streetEndSpin.visible=streetStartSpin.visible
            centerStreetSpin.visible=obj.diversityMode==4 and analyzerChannel.selection==2
            streetLayoutHelp.visible=streetStartSpin.visible or centerStreetSpin.visible
            streetStartSpin.value=obj.streetTrimStart;streetEndSpin.value=obj.streetTrimEnd;centerStreetSpin.value=obj.centerStreetOffset
            straightStreet.checked=`);
  b=b.replace('        on straightStreet changed',`        on streetStartSpin changed v do if not loadingStroke do (obj.streetTrimStart=v;redrawViews())
        on streetEndSpin changed v do if not loadingStroke do (obj.streetTrimEnd=v;redrawViews())
        on centerStreetSpin changed v do if not loadingStroke do (obj.centerStreetOffset=v;redrawViews())
        on straightStreet changed`);return b;
 });
 s=s.replace(/rollout (areaUI(?:_\d+)?) "[^]*?\n    \)/g,b=>{
  b=b.replace(/pos:\[(\d+),(\d+)\]/g,(m,x,y)=>+y>=572?`pos:[${x},${+y+32}]`:m);
  b=b.replace('        checkbox aaPoints','        spinner aaStreetOffset "Street offset:" range:[-1e9,1e9,0] type:#worldunits pos:[8,572] width:146 fieldWidth:62\n        checkbox aaPoints');
  b=b.replace('            aaWidth.value=','            aaStreetOffset.value=obj.centerStreetOffset;aaStreetOffset.enabled=obj.areaUseLine\n            aaWidth.value=');
  b=b.replace('        on aaWidth changed','        on aaStreetOffset changed v do if not loadingAnalyzerArea do (obj.centerStreetOffset=v;redrawViews())\n        on aaWidth changed');return b;
 });return s;
};
