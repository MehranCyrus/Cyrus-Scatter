const fs=require('fs');
let src=fs.readFileSync('tools/ui/templates/before.ms','utf8').replace(/\r/g,'');
// Stroke storage and editor replace the legacy single-band implementation.
let start=src.indexOf('    fn lineInputs plants ='),end=src.indexOf('    fn placements plants =',start);
src=src.slice(0,start)+fs.readFileSync('tools/ui/templates/strokes.ms','utf8')+'\n'+src.slice(end);
start=src.indexOf('    rollout lineUI ');end=src.indexOf('    rollout randomUI ',start);
src=src.slice(0,start)+fs.readFileSync('tools/ui/templates/stroke-ui.ms','utf8')+'\n'+src.slice(end);
// Put the stroke controls in the Diversity rollout, below its cluster controls.
let lineStart=src.indexOf('    rollout lineUI '),lineEnd=src.indexOf('    rollout randomUI ',lineStart);
let strokeBody=src.slice(lineStart,lineEnd);strokeBody=strokeBody.slice(strokeBody.indexOf('(')+1,strokeBody.lastIndexOf(')'));
strokeBody=strokeBody.replace(/        on lineUI open do updatePattern\(\)/,'').replace(/pos:\[([0-9]+),([0-9]+)\]/g,(_,x,y)=>'pos:['+x+','+(Number(y)+110)+']');
let diversityStart=src.indexOf('    rollout diversityUI '),diversity=src.slice(diversityStart,lineStart);
diversity=diversity.slice(0,diversity.lastIndexOf(')'))+strokeBody+'    )\n';
diversity=diversity.replace(/        fn updateControls = \([\s\S]*?\n        \)/,'');
const strokeControls=[...strokeBody.matchAll(/^        (?:label|dropdownlist|pickbutton|button|listbox|spinner|radiobuttons|multiListBox) (\w+)/gm)].map(m=>m[1]);
const clusterControls=['sizeSpin','divSeedSpin','roughSpin','blurSpin','noiseSpin','groupHint','fixedHint'];
diversity=diversity.replace('        local controlsReady=false','        local controlsReady=false,strokeExpandedHeight=0');
const update='        fn updateControls = (\n            for c in #('+clusterControls.join(',')+') do c.visible=diversityMode==2\n            for c in #('+strokeControls.join(',')+') do c.visible=(diversityMode==3 or diversityMode==4)\n            if strokeExpandedHeight>0 do diversityUI.height=if diversityMode>=3 then strokeExpandedHeight else (if diversityMode==2 then 310 else 124)*parentView.dpiScale\n            parentView.layoutPanels()\n        )\n';
diversity=diversity.replace(/        on diversityUI open do [^\n]+/,'');
// Functions precede their handlers; all controls are already declared here.
const handlerStart=diversity.indexOf('        on diversityRadio changed');
const handler=diversity.slice(handlerStart,diversity.indexOf('\n',handlerStart));
diversity=diversity.replace(handler,'');
const close=diversity.lastIndexOf(')');
diversity=diversity.slice(0,close)+update+handler+'\n        on diversityUI open do (controlsReady=true;strokeExpandedHeight=diversityUI.height;updateControls();updatePattern())\n    )\n';
src=src.slice(0,diversityStart)+diversity+src.slice(lineStart);
const block=(name)=>{let a=src.indexOf('    rollout '+name+' '),b=src.indexOf('\n    rollout ',a+1);if(b<0)b=src.indexOf('\n    on update do',a);return src.slice(a,b)};
const fields=[...src.matchAll(/^        (\w+) type:/gm)].map(x=>x[1]);
const funcs=[...src.slice(0,src.indexOf('    rollout surfaceUI')).matchAll(/^    fn (\w+)/gm)].map(x=>x[1]);
const qualify=new Set([...fields,...funcs,'dirty']);
const bindings=[...src.matchAll(/^        (\w+) type:[^\n]*? ui:(\w+)/gm)].map(x=>[x[1],x[2]]);
function mapTokens(s){return s.replace(/"(?:\\.|[^"\\])*"|\b[A-Za-z_]\w*\b/g,(t,off)=>t.startsWith('"')?t.replaceAll('Amin Scatter','Cyrus Scatter'):qualify.has(t)&&s[off-1]!=='.'?'obj.'+t:t==='this'?'obj':t)}
let factories='global CyrusUIBuildTarget,CyrusUIBuildView,CyrusUIBuildIndex\nglobal CyrusMakeLayer, CyrusMakeManager\n';
for(const name of ['updateUI','surfaceUI','previewUI','sourceUI','distributionUI','areaUI','diversityUI','lineUI','randomUI']){
 let s=block(name).replace('width:#cmdPanel','width:162');
 s=s.replace(/ensureLayers\(\);/g,'').replace(new RegExp(name+'\\.title=layerNames\\[activeLayer\\]\\+" \\| [^"]*";','g'),'');
 if(name==='surfaceUI')s=s.replace(/^        button newLayerButton.*\n/m,'').replace(/;newLayerButton.enabled=layerObjects.count<10/g,'').replace(/        on newLayerButton pressed do \([\s\S]*?\n        \)\n/,'');
 if(name==='previewUI'){
  s=s.replace(/        button buildButton.*\n/,'').replace(/        on buildButton pressed do \([\s\S]*?\n        \)\n/,'');
  s=s.replace(/        on clearBakedButton pressed do \([\s\S]*?\n        \)\n/,'        on clearBakedButton pressed do obj.clearAllBaked()\n');
 }
 let init='',handlers='';
 for(const [field,ctrl] of bindings){
  const control=s.match(new RegExp('^        (\\w+) '+ctrl+'\\b','m'));if(!control)continue;
  const kind=control[1];const prop=kind==='spinner'?'value':kind==='checkbox'?'checked':kind==='radiobuttons'?'state':kind==='mapbutton'?'map':'color';
  init+=`${ctrl}.${prop}=${field};`;
  const event=kind==='mapbutton'?'picked':'changed';
  const pat=new RegExp('(on '+ctrl+' '+event+' \\w+ do \\()');
  if(pat.test(s))s=s.replace(pat,'$1'+field+'=v;');
  else handlers+=`\n        on ${ctrl} ${event} v do (${field}=v;dirty=true;redrawViews())`;
 }
 s=s.replace(new RegExp('(on '+name+' open do \\()'),'$1'+init);
 s=s.slice(0,s.lastIndexOf('    )'))+handlers+`\n        on ${name} rolledUp state do parentView.layoutPanels()\n    )`;
 const opener=s.match(new RegExp('        on '+name+' open do [^\\n]+'));
 if(opener){s=s.replace(opener[0],'');s=s.slice(0,s.lastIndexOf('    )'))+opener[0]+'\n    )';}
 if(init) {
  s=s.replace(new RegExp('        on (?!'+name+'\\b)(\\w+) '), '        fn syncControls = ('+init+')\n        on $1 ');
  s=s.replaceAll('dirty=true;redrawViews()', 'dirty=true;syncControls();redrawViews()');
 }
 if(['updateUI','surfaceUI','previewUI'].includes(name)) s=s.replaceAll('width:146','width:138').replaceAll('pos:[8,','pos:[6,');
 s=mapTokens(s);
 if(['updateUI','previewUI'].includes(name))s=s.replaceAll('obj.refreshPreview()','obj.refreshAll()').replaceAll('obj.statusText()','obj.allStatus()');
 const titles={updateUI:'Update',surfaceUI:'Surface Scatter',previewUI:'Viewport and Render',sourceUI:'Source Object',distributionUI:'Point Generation',areaUI:'Area',diversityUI:'Diversity / Colors',lineUI:'Line Pattern',randomUI:'Randomize XYZ'};
 s=s.replace(new RegExp('rollout '+name+' "[^"]*"'),'rollout '+name+' "'+titles[name]+'"');
 factories+=`global CyrusMake_${name}\nfn CyrusMake_${name} target view = (\n${s.replace('width:162 (', 'width:162 (\n        local obj=CyrusUIBuildTarget,parentView=CyrusUIBuildView')}\n${name}.obj=target;${name}.parentView=view;${name}\n)\n`;
}

// A rollout declaration is a singleton. Give each slot its own declarations.
const baseFactories=factories;
for(let slot=1;slot<=10;slot++) {
 let f=baseFactories.slice(baseFactories.indexOf('global CyrusMake_sourceUI'));
 for(const name of ['sourceUI','distributionUI','areaUI','diversityUI','lineUI','randomUI']) f=f.replaceAll('CyrusMake_'+name,'CyrusMake_'+name+'_'+slot).replace(new RegExp('\\b'+name+'\\b','g'),name+'_'+slot);
 // Keep one coordinate system; responsive sizing is applied after all UI stages.
 factories+=f;
}
let core=src.slice(src.indexOf('plugin simpleObject'));
core=core.replace('name:"Amin Scatter"','name:"Cyrus Scatter"').replace('category:"Amin"','category:"Cyrus"').replace('version:12','version:16');
core=core.replace(/ rollout:\w+/g,'').replace(/ ui:\w+/g,'');
core=core.slice(0,core.indexOf('    rollout surfaceUI'))+fs.readFileSync('tools/ui/templates/host.ms','utf8')+core.slice(core.indexOf('    on update do'));
let a=core.indexOf('    fn ensureLayers ='),b=core.indexOf('    fn clearBaked ',a);
core=core.slice(0,a)+fs.readFileSync('tools/ui/templates/storage.ms','utf8')+core.slice(b);
core=core.replace('    on update do (','    on update do (\n        if version<13 do migrateLayers()\n        if version<15 do syncStrokes()');
core=core.replace('AminScatterRefreshLayerPanels n.baseObject','AminScatterRefreshLayerPanels n.baseObject');
const header=src.slice(0,src.indexOf('-- Rollout definitions'));
const helper='fn AminScatterRefreshLayerPanels obj reopen:true = (if obj.mainUI.controlsReady do obj.mainUI.rebuild())\n';
let containers=fs.readFileSync('tools/ui/templates/containers.ms','utf8');
const layerFactory=containers.slice(containers.indexOf('fn CyrusMakeLayer target'));
containers=containers.slice(0,containers.indexOf('fn CyrusMakeLayer target'));
for(let slot=1;slot<=10;slot++) {
 let f=layerFactory.replace('CyrusMakeLayer target','CyrusMakeLayer_'+slot+' target');
 for(const name of ['sourceUI','distributionUI','areaUI','diversityUI','lineUI','randomUI']) f=f.replaceAll('CyrusMake_'+name,'CyrusMake_'+name+'_'+slot);
 f=f.replace(/\blayerPanel\b/g,'layerPanel_'+slot);
 containers+='global CyrusMakeLayer_'+slot+'\n'+f+'\n';
}
containers+='fn CyrusMakeLayer target view index = (\n'+Array.from({length:10},(_,i)=>'if index=='+(i+1)+' then (CyrusMakeLayer_'+(i+1)+' target view index) else ').join('\n')+'undefined\n)\n';
fs.writeFileSync('scripts/AminScatterObject.ms',(header+helper+factories+containers+core).replaceAll('Amin Scatter','Cyrus Scatter'));












// Current render transport and spacing are maintained as explicit generator stages.
{
 let text=fs.readFileSync('scripts/AminScatterObject.ms','utf8');
 const a=text.indexOf('-- Final-render bridge:'),b=text.indexOf('-- Events mark only',a);
 if(a<0||b<0) throw Error('Missing render bridge generator markers');
 text=text.slice(0,a)+fs.readFileSync('tools/ui/templates/pflow.ms','utf8')+text.slice(b);
 text=text.replace('    fn refreshAll = (','    fn refreshAll = (\n        global CyrusPFManualRevision; if CyrusPFManualRevision!=undefined do CyrusPFManualRevision+=1');
 text=text.replace('else if entry[2].externalChanged nodes do redraw=true','else if entry[2].externalChanged nodes do (redraw=true;CyrusPFRevision+=1)');
 text=require('./spacing.cjs')(text);
 text=require('./centers.cjs')(text);
 text=require('./weights.cjs')(text);
 text=require('./source-transforms.cjs')(text);
 text=require('./overlaps.cjs')(text);
 text=require('./empty.cjs')(text);
 text=require('./point-source.cjs')(text);
 text=require('./radius.cjs')(text);
 text=require('./final.cjs')(text);
 text=require('./radius-display.cjs')(text);
 text=require('./edit.cjs')(text);
 text=require('./orientation.cjs')(text);
 text=require('./edge-border.cjs')(text);
 text=require('./display-modes.cjs')(text);
 text=require('./edge-corners.cjs')(text);
 text=require('./edge-rotation.cjs')(text);
 text=require('./source-refresh.cjs')(text);
 text=require('./boundary-falloff.cjs')(text);
 text=require('./area-falloff.cjs')(text);
 text=require('./whole-scale.cjs')(text);
 text=require('./analyzer-area.cjs')(text);
 text=require('./street-layout.cjs')(text);
 text=require('./activation.cjs')(text);
 text=require('./performance.cjs')(text);
 text=require('./compute-performance.cjs')(text);
 text=require('./viewport-performance.cjs')(text);
 text=require('./retained-points.cjs')(text);
 text=require('./layer-status.cjs')(text);
 text=require('./native-v1.cjs')(text);
 text=require('./procedural-brush.cjs')(text);
 text=require('./trace.cjs')(text);
 text=text.replace(/\r\n/g,'\n').replace(/^[ \t]+$/gm,'');
 fs.writeFileSync('scripts/AminScatterObject.ms',text);
}










