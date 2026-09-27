const fs=require('fs');
const fields={areaAnalyzer:['node',''],areaUseLine:['boolean','false'],areaLineWidth:['worldunits','100'],areaLineCaps:['integer','1'],areaUsePoints:['boolean','false'],areaPointRadius:['worldunits','100']};
module.exports=s=>{
 s=s.replace('version:39','version:40').replace('AminScatterLayerFields=#(','AminScatterLayerFields=#('+Object.keys(fields).map(k=>'#'+k).join(',')+',');
 s=s.replace('    parameters areaFalloffSettings (',`    local cachedAreaAnalyzerRun=-1
    parameters analyzerAreaSettings (
${Object.entries(fields).map(([k,[t,d]])=>`        ${k} type:#${t} ${d?'default:'+d:'useNodeTmValidity:true useNodeOsValidity:true'}\n        on ${k} set v do dirty=true`).join('\n')}
    )
    fn applyAnalyzerArea rows = (
        if not (areaUseLine or areaUsePoints) then rows else (
            if not (CyrusAnalyzerFilter areaAnalyzer) do throw "Area: pick a Surface Analyzer."
            local paths=if areaUseLine then areaAnalyzer.packedLines areaAnalyzer.pathVertices areaAnalyzer.pathCounts else #()
            local pts=if areaUsePoints then areaAnalyzer.samplePoints as array else #()
            cyrusAnalyzerArea rows paths pts (areaLineWidth/2.0) areaPointRadius areaLineCaps
        )
    )
    parameters areaFalloffSettings (`);
 s=s.replace('        result=applyFalloff result','        result=applyAnalyzerArea result\n        result=applyFalloff result');
 s=s.replace('            join inputs (areaNodes as array)','            join inputs (areaNodes as array)\n            if isValidNode areaAnalyzer do append inputs areaAnalyzer');
 s=s.replace('        cachedFallRun=','        cachedAreaAnalyzerRun=if isValidNode areaAnalyzer then areaAnalyzer.getAnalysisRuns() else -1\n        cachedFallRun=');
 s=s.replace('    fn previewCache = (','    fn previewCache = (\n        if updateMode==2 and isValidNode areaAnalyzer and (areaUseLine or areaUsePoints) do if cachedAreaAnalyzerRun!=areaAnalyzer.getAnalysisRuns() do dirty=true');
 s=s.replace('     if isValidNode obj.fallAnalyzer','     if isValidNode obj.areaAnalyzer and (obj.areaUseLine or obj.areaUsePoints) do format "|AnalyzerArea:%|" (obj.areaAnalyzer.getAnalysisRuns()) to:s\n     if isValidNode obj.fallAnalyzer');
 s=s.replace(/rollout (areaUI(?:_\d+)?) "[^]*?\n    \)/g,(b,name)=>{
  b=b.replace(/pos:\[(\d+),(\d+)\]/g,(m,x,y)=>+y>=378?`pos:[${x},${+y+294}]`:m);
  b=b.replace('        local loadingFall=false',fs.readFileSync('tools/ui/templates/analyzer-area-ui.ms','utf8')+'\n        local loadingFall=false');
  return b.replace(`on ${name} open do (`,`on ${name} open do (syncAnalyzerArea();`);
 });return s;
};
