module.exports=function(s){
 const start=s.indexOf('fn CyrusMake_updateUI '),end=s.indexOf('plugin simpleObject');
 let factories=s.slice(start,end);
 factories=factories.replace(/fn (CyrusMake\w+) target view( index)? = \([^]*?\n\)/g,(b,name)=>{
  if(!b.includes('rollout '))return b;
  const nested=!/^(CyrusMake_updateUI|CyrusMake_surfaceUI|CyrusMake_previewUI|CyrusMakeManager|CyrusMakeLayer_\d+)$/.test(name);
  const depth=nested?1:0;
  b=b.replace(' = (',' = (\n    CyrusUIBuildView=view');
  b=b.replace(/pos:\[(\d+),/g,(_,x)=>`pos:[(CyrusUISize ${Number(x)<=8?8:x} ${depth}),`);
  b=b.replace(/\b(width|fieldWidth):(\d+)/g,(_,kind,n)=>{
   let value=Number(n);
   if(kind==='width'&&value>=120&&value<=146)value=146;
   if(kind==='width'&&value===136)value=162;
   return `${kind}:(CyrusUISize ${value} ${depth})`;
  });
  // Rollout itself always spans the allocated width, including the old spacing UI.
  b=b.replace(/(rollout \w+ "[^"]*" width:)\([^\n]+?\) \(/,'$1(CyrusUISize 162 '+depth+') (');
  b=b.replace('addInside.pos=[if boundaryOnly then 8 else 84,addOutside.pos.y]',`addInside.pos=[(CyrusUISize (if boundaryOnly then 8 else 84) ${depth} view:parentView),addOutside.pos.y]`);
  b=b.replace('addInside.width=if boundaryOnly then 146 else 70',`addInside.width=CyrusUISize (if boundaryOnly then 146 else 70) ${depth} view:parentView`);
  return b;
 });
 s=s.slice(0,start)+factories+s.slice(end);
 s=s.replace('version:37','version:38');
 const helper='global CyrusUISize,CyrusUIBuildView\nfn CyrusUISize n depth view:CyrusUIBuildView = (local w=if view==undefined then 162 else amax 140 (view.width-16-depth*16);floor(n*w/162.0+0.5))\n';
 return helper+s;
};

