// Inventory semantic controls once; Modify, container and popup share them.
const fs=require('fs'),util=require('./maxscript-blocks.cjs');
const kinds='button|checkbox|checkbutton|colorpicker|dropdownlist|edittext|listbox|mapbutton|multiListBox|pickbutton|radiobuttons|spinner';
const controls=body=>[...body.matchAll(new RegExp('^        ('+kinds+') (\\w+)\\b','gm'))].map(m=>({kind:m[1],name:m[2]}));
module.exports=function(s,{check=false}={}){
 const inventory={general:{},layer:{},container:{},set:['setsUI','sourceUI','brushUI','proceduralUI','sourceContainersUI']};
 const tooltips={};
 const block=re=>{const [a,b]=util.span(s,re);return s.slice(a,b);};
 const section=(name,body)=>{
  tooltips[name]={};
  for(const match of body.matchAll(new RegExp('^        (?:'+kinds+') (\\w+) [^\\n]*?tooltip:("(?:\\\\.|[^"\\\\])*")','gm'))){
   tooltips[name][match[1]]=JSON.parse(match[2]);
  }
  return controls(body);
 };
 const general={host:'mainUI',updateUI:'flow_updateUI',previewUI:'flow_previewUI',surface:'flow_surfaceUI',manager:'flow_layersUI',diagnostics:'diagnosticsUI'};
 for(const [key,name] of Object.entries(general))inventory.general[key]=section(key,block(new RegExp('^    rollout '+name+' "[^"\\n]+"[^\\n]*\\(','m')));
 inventory.general.editor=section('editor',block(/^    rollout editor "Cyrus Scatter [^"\n]+"[^\n]*\(/m));
 for(const name of ['setsUI','sourceUI','sourceContainersUI','distributionUI','populationPolicyUI','areaUI','brushUI','randomUI','diversityUI','proceduralUI','instanceRadiusUI','spacingUI','separationUI','detailsUI','workflowUI'])inventory.layer[name]=section(name,block(new RegExp('^    rollout selected_'+name+' "[^"\\n]+"[^\\n]*\\(','m')));
 inventory.container.properties=section('properties',block(/^    rollout containerUI "[^"\n]+"[^\n]*\(/m));
 for(const [path,value] of [['tools/ui/layers-control-inventory.json',inventory],['tools/ui/layer-editor-tooltips.json',tooltips]]){
  const output=JSON.stringify(value,null,2)+'\n';
  if(check){if(fs.readFileSync(path,'utf8')!==output)throw new Error('Generated metadata is stale: '+path);}
  else fs.writeFileSync(path,output);
 }
 return inventory;
};
