module.exports=s=>{
 s=s.replace('version:37','version:39').replace('AminScatterLayerFields=#(','AminScatterLayerFields=#(#wholeScaleMin,#wholeScaleMax,');
 s=s.replace('    parameters areaFalloffSettings (',`    parameters wholeScaleSettings (
        wholeScaleMin type:#float default:1.0
        wholeScaleMax type:#float default:1.0
        on wholeScaleMin set v do dirty=true
        on wholeScaleMax set v do dirty=true
    )
    parameters areaFalloffSettings (`);
 s=s.replace('        result=applyFalloff result','        if wholeScaleMin!=1.0 or wholeScaleMax!=1.0 do result=cyrusWholeScale result wholeScaleMin wholeScaleMax randomSeed\n        result=applyFalloff result');
 s=s.replace(/rollout (randomUI(?:_\d+)?) "[^]*?\n    \)/g,(b,name)=>{
  b=b.replace(/pos:\[(\d+),(\d+)\]/g,(m,x,y)=>+y>=256?`pos:[${x},${+y+76}]`:m);
  b=b.replace('        label movTitle',`        label wholeTitle "Whole Scale (uniform)" pos:[8,252] width:146
        label wholeMinTitle "Min" pos:[24,274] width:58
        label wholeMaxTitle "Max" pos:[94,274] width:58
        spinner wholeMinSpin "" range:[0.001,1000,1] scale:0.01 pos:[24,296] fieldWidth:46 width:58
        spinner wholeMaxSpin "" range:[0.001,1000,1] scale:0.01 pos:[94,296] fieldWidth:46 width:58
        on wholeMinSpin changed v do (obj.wholeScaleMin=v;if v>obj.wholeScaleMax do (obj.wholeScaleMax=v;wholeMaxSpin.value=v);redrawViews())
        on wholeMaxSpin changed v do (obj.wholeScaleMax=v;if v<obj.wholeScaleMin do (obj.wholeScaleMin=v;wholeMinSpin.value=v);redrawViews())
        label movTitle`);
  return b.replace(`on ${name} open do (`,`on ${name} open do (wholeMinSpin.value=obj.wholeScaleMin;wholeMaxSpin.value=obj.wholeScaleMax;`);
 });return s;
};

