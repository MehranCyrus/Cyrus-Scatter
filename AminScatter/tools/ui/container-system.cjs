// Container Modify views use the same pages and readiness guards.
const fs=require('fs'),util=require('./maxscript-blocks.cjs');
const read=n=>fs.readFileSync('tools/ui/templates/'+n+'.ms','utf8').replace(/\r/g,'');
module.exports=function(s){
 const names=['mainUI',...require('./approved-layout-rows.cjs').pages.map(p=>p.name)];
 const panel=names.map(name=>{
  const [a,b]=util.span(s,new RegExp('^    rollout '+name+' \"[^\"\\n]+\"[^\\n]*\\(','m'));
  return s.slice(a,b);
 }).join('\n\n');
 const container=read('container-node').replace('    -- __CONTAINER_PANEL__',read('container-properties-ui')+'\n'+panel);
 return s.trimEnd()+'\n\n'+container;
};
