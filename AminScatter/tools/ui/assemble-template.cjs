// Build-time expansion only: keep plugin local scope and declaration order.
const fs=require('fs'),path=require('path');
function expand(source,resolve){
 const seen=new Set();
 const output=source.replace(/^-- @include ([a-z0-9-]+\.ms)\n/gm,(_,name)=>{
  if(seen.has(name))throw new Error('Duplicate template include: '+name);
  seen.add(name);return resolve(name);
 });
 if(output.includes('-- @include '))throw new Error('Malformed/unresolved template include');
 return output;
}
module.exports=function assemble(filename,stack=[],visited=new Set()){
 const resolved=path.resolve(filename),root=path.resolve('tools/ui/templates');
 if(!resolved.startsWith(root+path.sep)||stack.includes(resolved)||visited.has(resolved))throw new Error('Invalid/cyclic/duplicate template include: '+filename);
 visited.add(resolved);
 const source=fs.readFileSync(resolved,'utf8').replace(/\r/g,'');
 return expand(source,name=>assemble(path.join(path.dirname(resolved),name),[...stack,resolved],visited));
};
module.exports.expand=expand;
