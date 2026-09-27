module.exports=function(s) {
 s=s.replace('version:17','version:18');
 s=s.replace('AminScatterLayerFields=#(','AminScatterLayerFields=#(#showCenters,');
 s=s.replace('    parameters spacingSettings (',`    parameters centerDisplay (
        showCenters type:#boolean default:false
        on showCenters set v do (dirty=true;previewBuildCount=0)
    )
    parameters spacingSettings (`);
 s=s.replace('fn lineInputs plants = (','fn lineInputs plants previewOnly:false = (');
 s=s.replace('                if choices.count==0 do throw','                if previewOnly and plants.count==0 do choices=#(1)\n                if choices.count==0 do throw');
 s=s.replace('fn placements plants = (','fn placements plants previewOnly:false = (');
 s=s.replace('if plants.count==0 do throw "Add a plant mesh."','if plants.count==0 and not previewOnly do throw "Add a plant mesh."\n        local sourceCount=amax 1 plants.count');
 s=s.replaceAll('requestedCount randomSeed plants.count','requestedCount randomSeed sourceCount');
 s=s.replace('local groups=for n in plants collect (colorKey (sourceColor (findItem sources n)))','local groups=if plants.count==0 then #(0) else (for n in plants collect (colorKey (sourceColor (findItem sources n))))');
 s=s.replace('(lineInputs plants) #(collisionEnabled','(lineInputs plants previewOnly:previewOnly) #(collisionEnabled');
 s=s.replace('local data=placements plants\n','local data=placements plants previewOnly:showCenters\n');
 s=s.replace('local samples=for n in plants collect (aminScatterSourcePoints n pointsPerPlant randomSeed)', 'local samples=if showCenters then (for i=1 to (amax 1 plants.count) collect #([0,0,0])) else (for n in plants collect (aminScatterSourcePoints n pointsPerPlant randomSeed))');
 s=s.replace('local colors=for n in plants collect (sourceColor (findItem sources n))','local colors=if plants.count==0 then #(solidPointColor) else (for n in plants collect (sourceColor (findItem sources n)))');
 s=s.replace('aminScatterBuildPreview data samples colors previewBudget','aminScatterBuildPreview data samples colors (if showCenters then 500000 else previewBudget)');
 s=s.replace('if obj.showPoints do (','if obj.showPoints or obj.showCenters do (');
 // Insert near Count / Density, shifting the existing controls uniformly.
 s=s.replace(/rollout (distributionUI(?:_\d+)?) "Point Generation"[^]*?\n    \)/g,block=>{
  const name=block.match(/rollout (\w+)/)[1];
  block=block.replace(/pos:\[(\d+),(\d+)\]/g,(m,x,y)=>Number(y)>=148?`pos:[${x},${Number(y)+26}]`:m);
  block=block.replace('        spinner countSpin',`        checkbox showCenterCheck "Show Point" pos:[8,148] width:120
        on showCenterCheck changed v do (obj.showCenters=v;redrawViews())
        spinner countSpin`);
  block=block.replace(`on ${name} open do (`,`on ${name} open do (showCenterCheck.checked=obj.showCenters;`);
  return block;
 });
 return s;
};
