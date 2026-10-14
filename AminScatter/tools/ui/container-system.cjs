// Selecting a palette is a placement operation. Its small properties editor
// shares the model; the full Scatter editor belongs to the Scatter controller.
const fs=require('fs');
const read=n=>fs.readFileSync('tools/ui/templates/'+n+'.ms','utf8').replace(/\r/g,'');
module.exports=function(s){
 const container=read('container-node').replace('    -- __CONTAINER_PANEL__',read('container-properties-ui'));
 return s.trimEnd()+'\n\n'+container;
};
