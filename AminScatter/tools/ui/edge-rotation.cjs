module.exports=function(s){
 s=s.replace('version:34','version:35');
 const keys=['edgeRotX','edgeRotY','edgeRotZ'];
 for(const list of ['AminScatterLayerFields','AminScatterLayerTabs'])s=s.replace(list+'=#(',list+'=#('+keys.map(k=>'#'+k).join(',')+',');
 s=s.replace('    parameters edgeRowSettings (','    parameters edgeRowSettings (\n'+keys.map(k=>`        ${k} type:#floatTab tabSize:0 tabSizeVariable:true\n        on ${k} set v i do dirty=true`).join('\n'));
 s=s.replace('    fn syncStrokes = (','    fn syncStrokes = (\n'+keys.map(k=>`        while ${k}.count<patternLines.count do append ${k} 0.0`).join('\n'));
 s=s.replace('for key in #(#edgeOffsets,','for key in #(#edgeRotX,#edgeRotY,#edgeRotZ,#edgeOffsets,');
 s=s.replace('edgeKeepCorners,edgeCornerAngle,edgeCornerCount)','edgeKeepCorners,edgeCornerAngle,edgeCornerCount,edgeRotX[i],edgeRotY[i],edgeRotZ[i])');
 s=s.replace(/rollout ((?:diversityUI|lineUI)(?:_\d+)?) "[^]*?\n    \)/g,b=>{
  const y=Number(b.match(/label cornerHelp[^\n]*pos:\[\d+,(\d+)\]/)[1])+42;
  b=b.replace('        checkbox faceOutCheck',keys.map((k,i)=>`        spinner ${k}Spin "Local ${'XYZ'[i]} (deg):" range:[-36000,36000,0] type:#float pos:[8,${y+i*28}] width:123 fieldWidth:52`).join('\n')+'\n        checkbox faceOutCheck');
  b=b.replace('cornerCountSpin,cornerHelp)','cornerCountSpin,cornerHelp,edgeRotXSpin,edgeRotYSpin,edgeRotZSpin)');
  b=b.replace('edgeAlongSpin,edgeAcrossSpin) do c.enabled','edgeAlongSpin,edgeAcrossSpin,edgeRotXSpin,edgeRotYSpin,edgeRotZSpin) do c.enabled');
  b=b.replace('            if active do (','            if active do (\n'+keys.map(k=>`                ${k}Spin.value=obj.${k}[row]`).join('\n'));
  b=b.replace('        on strokeWidth changed',keys.map(k=>`        on ${k}Spin changed v do if not loadingStroke do (local row=selectedStroke();if row>0 do obj.${k}[row]=v;redrawViews())`).join('\n')+'\n        on strokeWidth changed');return b;
 });return s;
};
