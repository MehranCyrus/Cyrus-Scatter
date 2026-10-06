// Presentation only. The factories retain their original feature handlers.
const tips=require('./layer-editor-tooltips.json');
module.exports=(r,name)=>{
 const move=(control,x,y,w=132)=>{
  const re=new RegExp('^(\\s*(?:checkbox|spinner|button|pickbutton|dropdownlist|radiobuttons|mapbutton|multiListBox|listbox|colorpicker|edittext|label) '+control+' .+)$','m');
  if(!re.test(r))throw Error('Missing layout control '+name+'.'+control);
  r=r.replace(re,line=>line.replace(/pos:\[\d+,\d+\]/,`pos:[${x},${y}]`).replace(/\bwidth:\d+/,`width:${w}`));
 };
 if(name==='sourceUI'){
  r=r.replace('"Plant assets"','"Models and settings - paint set"');
  const full={plantList:8,removePlant:200,forwardAxis:326,
   groupHeading:496,existingGroups:518,groupColor:572,applyColor:600,colorHelp:630,replacePoint:456};
  for(const [n,y] of Object.entries(full))move(n,4,y);
  for(const [a,b,y] of [['addPlant','addSelected',140],['selectFromScene','selectPlant',170],['weightSpin','sourceScaleSpin',236],['sourceZSpin','radiusSourceSpin',266],['followRadiusCheck','showRadiusCheck',294],['addPoint','addEmpty',426]]){move(a,4,y,64);move(b,72,y,64);}
  move('weightHelp',4,378);move('sourceTransformHelp',4,398);
  r=r.replace('"Select From Scene..."','"Choose from list..."').replace('"Add: pick in viewport"','"Pick model"').replace('"Add selected objects"','"Add selection"').replace('"Remove selected rows"','"Remove rows"').replace('"Collision radius:"','"Radius:"');
 }
 if(name==='sourceContainersUI'){
  r=r.replace('"Source containers"','"Source rectangles - own / inherited"');
  move('membershipInfo',4,244);move('helpInfo',4,286);
  r=r.replace('height:78','height:44');
 }
 if(name==='distributionUI'){
  r=r.replace('"Population" width:','"Population and seed - layer" width:').replace('"Candidates: "','"Requested count: "');
  r=r.replace(/(radiobuttons (?:populationRadio|modeRadio) [^\n]+)columns:1/g,'$1columns:2');
  for(const [control,y] of Object.entries({populationRadio:8,countSpin:62,densitySpin:62,seedSpin:92,modeRadio:130,densityHeading:180,densityButton:204,invertCheck:234,uvHint:260,mapHint:282,showCenterCheck:312}))move(control,4,y);
  const marker='        fn syncControls = (';
  const arrange=`        fn arrangePopulation = (
            local textured=obj.distributionMode==3
            countSpin.visible=obj.populationMode==1;densitySpin.visible=obj.populationMode==2
            for c in #(densityHeading,densityButton,invertCheck,uvHint,mapHint) do c.visible=textured
            showCenterCheck.visible=not obj.sharedSpacing()
            showCenterCheck.pos=[4,if textured then 312 else 180]
            distributionUI.height=if obj.sharedSpacing() then (if textured then 308 else 184) else (if textured then 340 else 208)
        )
`;
  r=r.replace(marker,arrange+marker);
  r=r.replace(/fn syncControls = \(([^\n]*)\)/,(_,body)=>`fn syncControls = (${body};arrangePopulation())`);
  r=r.replace('        fn bind layer = (','        fn bindFeatures layer = (');
  r=r.replace('        on distributionUI open','        fn bind layer = (bindFeatures layer;arrangePopulation())\n        on distributionUI open');
 }
 if(name==='areaUI')r=r.replace('"Area" width:','"Include / exclude areas - layer" width:');
 if(name==='brushUI')r=r.replace('"Coverage / Brush"','"Brush coverage and strokes - paint set"');
 if(name==='randomUI')r=r.replace('"Randomize XYZ"','"Random transforms - layer"');
 if(name==='diversityUI')r=r.replace('"Diversity / Colors"','"Source assignment - layer"');
 if(name==='spacingUI'){
  r=r.replace('"Collision / Relax"','"Inherited self-spacing / legacy Relax"');
  r=r.replace('        fn bind layer = (','        fn bindModel layer = (');
  const end=r.lastIndexOf('        on spacingUI open');
  r=r.slice(0,end)+`        fn bind layer = (
            bindModel layer
            local legacy=root.groupPolicy!=3
            for c in #(relaxCheck,spacingSpin,iterationsSpin,strengthSpin,orderHint,layerHint) do c.visible=legacy
            spacingUI.height=if legacy then 280 else 90
            spacingUI.title=if legacy then "Collision and Relax (legacy)" else "Inherited self-spacing - layer"
            radiusHint.text=if legacy then "Min gap = 2 x radius" else "Default until a paint set overrides self-spacing."
        )
`+r.slice(end);
 }
 if(name==='separationUI'){
  r=r.replace('"Spacing / Cleanup"','"Final cleanup / legacy pair rules"');
  r=r.replace('        fn bind layer = (','        fn bindModel layer = (');
  const end=r.lastIndexOf('        on separationUI open');
  r=r.slice(0,end)+`        fn bind layer = (
            local legacy=root.groupPolicy!=3
            for c in #(policyInfo,prioritySpin,peerList,blockerList,overlapCheck,radiusMode,gapSpin,radiusSpin,planarCheck,overlapInfo,overlapCounts,statsButton,boundaryRelaxCheck,finalStrengthSpin,finalIterSpin,finalMoveSpin,relaxHint) do c.visible=legacy
            bindModel layer
            if not legacy do (peerList.visible=false;blockerList.visible=false;radiusSpin.visible=false)
            local fields=#(finalTitle,cleanCheck,neighborSpin,minNeighborSpin,minIslandSpin),ys=#(440,466,494,522,550)
            for i=1 to fields.count do fields[i].pos=[4,ys[i]-(if legacy then 0 else 432)]
            separationUI.height=if legacy then 756 else 154
            separationUI.title=if legacy then "Spacing and cleanup (legacy)" else "Final cleanup - layer"
        )
`+r.slice(end);
 }
 if(name==='detailsUI'){
  move('refreshButton',4,8);move('helpButton',4,38);move('info',4,74);
  r=r.replace('info.text=text;controlsReady=true','info.text=text;info.height=amax 300 ((filterString text "\\n").count*17+20);detailsUI.height=info.height+86;controlsReady=true');
 }
 // Rare tools stay available without forcing every artist through their fields.
 const folds={sourceUI:[426,650,'Point / Empty sources and color groups'],brushUI:[436,872,'Paint feedback and editable stroke history'],areaUI:[378,1160,'Analyzer masks and edge falloff']};
 if(folds[name]){
  const [cut,height,caption]=folds[name],fields=[];
  r=r.replace(/^\s*(?:checkbox|spinner|button|pickbutton|dropdownlist|radiobuttons|mapbutton|multiListBox|listbox|colorpicker|edittext|label) (\w+) .+$/gm,(line,control)=>{
   const m=line.match(/pos:\[(\d+),(\d+)\]/);
   if(m && Number(m[2])>=cut){fields.push(control);return line.replace(m[0],`pos:[${m[1]},${Number(m[2])+34}]`);}
   return line;
  });
  r=r.replace('        fn bind layer = (','        fn bindFeatures layer = (');
  const at=r.indexOf('        on '+name+' open');
  if(at<0)throw Error('Missing folded section lifecycle: '+name);
  r=r.slice(0,at)+`        checkbutton detailsToggle ${JSON.stringify(caption)} pos:[4,${cut}] width:132 height:26 tooltip:"Show or hide these advanced controls; their saved settings are preserved."
        fn arrangeDetails = (
            for c in #(${fields.join(',')}) do c.visible=detailsToggle.checked
            ${name}.height=if detailsToggle.checked then ${height+42} else ${cut+34}
        )
        fn bind layer = (bindFeatures layer;arrangeDetails())
        on detailsToggle changed value do arrangeDetails()
`+r.slice(at);
 }
 // Wider fields in the floating editor keep world units and large counts legible.
 r=r.replace(/fieldWidth:(?:44|45|48|52|54|58|64|65)\b/g,'fieldWidth:82');
 for(const [control,tip] of Object.entries(tips[name]||{})){
  const re=new RegExp('^(\\s*(?:checkbox|spinner|button|pickbutton|dropdownlist|mapbutton|colorpicker|edittext) '+control+' .+)$','m');
  if(!re.test(r))throw Error('Missing tooltip target '+name+'.'+control);
  r=r.replace(re,line=>line.replace(/ tooltip:"(?:[^"\\\\]|\\\\.)*"/g,'')+' tooltip:'+JSON.stringify(tip));
 }
 return r;
};
