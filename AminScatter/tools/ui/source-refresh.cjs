module.exports=function(s){
 return s.replace(/rollout (sourceUI(?:_\d+)?) "Source Object"[^]*?\n    \)/g,b=>{
  const old=b.match(/        fn addSources nodes = \([^]*?\n        \)/);
  if(!old)throw Error('Source add helper not found');
  b=b.replace(old[0],'');
  // Place after showSelectedColor: MAXScript binds function names at declaration.
  b=b.replace('        on addPoint pressed',`        fn addSources nodes = (
            local before=obj.sources.count
            if nodes!=undefined do for n in nodes do addSource n
            updateList()
            if obj.sources.count>before do (
                local rows=#{}
                for i=before+1 to obj.sources.count do rows[i]=true
                plantList.selection=rows;focusedRow=before+1
            )
            showSelectedColor();redrawViews()
        )
        on addPoint pressed`);
  return b;
 });
};
