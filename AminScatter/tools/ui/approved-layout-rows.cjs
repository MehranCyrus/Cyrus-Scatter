// Basic controls follow the approved artist workflow. Remaining fields stay
// reachable under Advanced; conditional rows retain their original mode gates.
const rows=(key,names,advanced=false)=>names.map(names=>({controls:(Array.isArray(names)?names:[names]).map(n=>key+'.'+n),advanced}));
const heading=(text,advanced=false)=>({heading:text,advanced});
const axisRows=prefix=>['X','Y','Z'].map(axis=>({controls:['Min','Max'].map(end=>'randomUI.'+prefix+axis+end+'Spin'),pair:true}));
module.exports={
 labels:{'flow_layersUI.addButton':'Add','flow_layersUI.copyButton':'Copy','flow_layersUI.removeButton':'Remove','flow_layersUI.enabledCheck':'Enabled','flow_layersUI.visibleCheck':'Visible','setsUI.enabledCheck':'Enabled','setsUI.visibleCheck':'Visible','setsUI.setList':'','sourceContainersUI.modeList':'','sourceContainersUI.createContainer':'Create','sourceContainersUI.pickContainer':'Pick','sourceContainersUI.removeContainer':'Unlink','flow_layersUI.upButton':'Move up','flow_layersUI.downButton':'Move down','sourceUI.addSelected':'Add selected','distributionUI.countSpin':'Count: ','distributionUI.populationRadio':'Amount','flow_updateUI.updateNow':'Update scatter'},
 pages:[
  {name:'managerUI',title:'Layers',parts:['flow_layersUI'],layerPage:false,noAdvanced:true,rows:[heading('Layers - evaluation order'),...rows('flow_layersUI',['layerList',['addButton','copyButton','removeButton','upButton','downButton'],['nameEdit','layerColor'],['enabledCheck','visibleCheck'],'copyVariation','recipesButton'])]},
  {name:'surfacesUI',title:'Surfaces',parts:['flow_surfaceUI'],layerPage:true,rows:[...rows('flow_surfaceUI',['receiversList',['sharedPick','removeSurfaces','surfacesButton'],'sharedInfo','countInfo'])]},
  {name:'modelsUI',title:'Models & Points',parts:['sourceUI'],layerPage:true,noAdvanced:true,rows:[...rows('sourceUI',[['addPoint','addPlant'],'plantList',['removePlant','selectFromScene','addSelected','selectPlant'],['sourceName','idColor'],['replacePoint','makePoint']]),heading('Source settings'),...rows('sourceUI',[['weightSpin','sourceScaleSpin'],'radiusModeDrop','radiusModeHelp',['radiusSourceSpin','sourceZSpin'],['followRadiusCheck','showRadiusCheck'],'forwardAxis','weightHelp','sourceTransformHelp','addEmpty']),{toggle:'groupsToggle',caption:'Assignment groups'},...rows('sourceUI',['groupHeading','existingGroups','groupColor','applyColor','colorHelp']).map(r=>({...r,when:'groupsToggle.checked'}))]},
  {name:'containersUI',title:'Source containers',parts:['sourceContainersUI'],layerPage:true,noAdvanced:true,rows:[...rows('sourceContainersUI',['modeList',['createContainer','pickContainer','removeContainer'],'containersList','enabledCheck','membershipInfo','helpInfo'])]},
  {name:'layoutUI',title:'Layout',parts:['diversityUI'],layerPage:true,rows:[...rows('diversityUI',['diversityRadio','layoutHelp','sizeSpin','divSeedSpin','groupHint','pathsList',['pickPath','removePath'],'cornerMode','arrangementMode','pickAnalyzer','analyzerStatus',['selectAnalyzer','updateAnalyzer'],'analyzerChannel','strokeTitle','strokesList',['addOutside','addInside','removeStrokeButton'],'strokeWidth',['bandStart','bandEnd'],'bandAssignmentHelp','strokeMode','strokeChoices','refreshGroups','bandStrength',['bandCurveCheck','bandCurveEdit']]),{heading:'Scale',when:'diversityUI.diversityRadio.state>=3'},{controls:['diversityUI.strokeScaleMin','diversityUI.strokeScaleMax'],pair:true,when:'diversityUI.diversityRadio.state>=3'},...rows('diversityUI',['bandScaleMode','bandScaleEdit','bandColor',['fieldFalloffCheck','fieldBoundaryCheck'],'fieldView','fieldSampleSpin','fieldLegend','fieldInfo','strokeHelp']),...rows('diversityUI',[['bandUp','bandDown']],true)]},
  {name:'populationUI',title:'Amount',parts:['distributionUI','populationPolicyUI'],layerPage:true,rows:[heading('Count or density'),...rows('distributionUI',['presetsButton','populationRadio','countSpin','densitySpin','seedSpin']),heading('Mesh channel density'),...rows('distributionUI',['meshCheck','meshChannelSpin','meshComponentList','meshMinSpin','meshMaxSpin','meshInvertCheck','meshCurveButton',['meshPreviewButton','meshHideButton'],'meshHint'])]},
  {name:'coverageUI',title:'Painting',parts:['setsUI','brushUI'],layerPage:true,noAdvanced:true,rows:[...rows('setsUI',['paintedCheck','setList',['addButton','removeButton'],'nameEdit','targetList','enabledCheck','info']).map(r=>r.controls[0]==='setsUI.paintedCheck'?r:{...r,when:'setsUI.paintedCheck.checked'}),...rows('brushUI',['targetInfo','densitySpin','modeRadio','radiusSpin',['beginButton','stopButton'],['fillButton','emptyButton'],'exportSpline','importMode','splineTolerance','importSpline','brushState','insideSpin','outsideSpin',['densityFade','densityCurve'],['scaleFade','scaleCurve'],['scaleMin','scaleMax'],'overlayMode','overlayColor','brushHelp']).map(r=>({...r,when:'setsUI.paintedCheck.checked'}))]},
  {name:'areasUI',title:'Include / exclude',parts:['areaUI'],layerPage:true,rows:[heading('Area limits - layer'),...rows('areaUI',['areaList',['pickArea','addAreaScene'],'removeArea','areaMode','areaHint']),heading('Surface eligibility'),...rows('areaUI',['slopeCheck',['slopeMinSpin','slopeMaxSpin'],['slopeLowerSpin','slopeUpperSpin'],'altitudeCheck',['altitudeMinSpin','altitudeMaxSpin'],['altitudeLowerSpin','altitudeUpperSpin'],'filterInfo']),heading('Boundary falloff'),...rows('areaUI',['fallTarget',['fallPick','fallRemove'],'fallTargetName',['fallDeleteCheck','fallDeleteSpin'],['fallScaleCheck','fallScaleSpin'],'fallScaleEdit',['fallDensityCheck','fallDensitySpin'],'fallDensityEdit','fallHelp','refreshAreas'])]},
  {name:'transformsUI',title:'Transforms',parts:['randomUI'],layerPage:true,noAdvanced:true,hidden:['rotMinTitle','rotMaxTitle','sclMinTitle','sclMaxTitle','movMinTitle','movMaxTitle','wholeMinTitle','wholeMaxTitle',...['rot','scl','mov'].flatMap(p=>['X','Y','Z'].map(a=>p+a+'Label'))].map(n=>'randomUI.'+n),rows:[...rows('randomUI',['presetsButton','rotTitle']),...axisRows('rot'),...rows('randomUI',['resetRotation','sclTitle']),...axisRows('scl'),...rows('randomUI',['resetScale','wholeTitle']),{controls:['randomUI.wholeMinSpin','randomUI.wholeMaxSpin'],pair:true},...rows('randomUI',['resetWholeScale','movTitle']),...axisRows('mov'),...rows('randomUI',['resetMovement','projectCheck']),heading('Orientation'),...rows('randomUI',['orientationList','alignCheck','normalBlendSpin','directionXSpin','directionYSpin','directionZSpin',['targetPickButton','targetClearButton'],'targetInfo','orientationHelp'])]},
  {name:'spacingUI',title:'Spacing & cleanup',parts:['proceduralUI','instanceRadiusUI','spacingUI','separationUI'],layerPage:true,rows:[heading('Spacing - selected scope'),...rows('proceduralUI',['presetsButton','scopeList','peerList','enabledCheck',['multiplierSpin','gapSpin'],'planarCheck','ruleInfo'])]},
  {name:'displayUI',title:'Viewport & render',parts:['flow_previewUI'],layerPage:false,rows:[...rows('flow_previewUI',['displayModeDrop','navigationPointsSpin','budgetSpin','navigationInstancesSpin','instancesLimitSpin','navigationFacesSpin','faceLimitSpin','limitsHint','identificationDrop','previewCheck','autoRenderCheck','status'])]},
  {name:'statisticsUI',title:'Stats & diagnostics',parts:['detailsUI','workflowUI','diagnosticsUI'],layerPage:false,rows:[...rows('detailsUI',['info',['refreshButton','helpButton']]),heading('Local diagnostic recording - setup',true),...rows('diagnosticsUI',[['startButton','stopButton'],['saveButton','refreshButton'],'statusInfo','scopeInfo'],true),{toggle:'workflowToggle',caption:'Workflow & ownership',advanced:true},...rows('workflowUI',['steps','help'],true).map(r=>({...r,when:'workflowToggle.checked'}))]}
 ],
 captions:{flow_surfaceUI:'Global model palettes - setup',flow_layersUI:'Layer management',setsUI:'Paint Areas',sourceUI:'Source details - layer',sourceContainersUI:'Source pool help',distributionUI:'Sampling - layer',populationPolicyUI:'Target and bounded retry - layer',brushUI:'Paint feedback',backgroundUI:'Background coverage help',areaUI:'Analyzer and area falloff',randomUI:'Per-axis scale and movement',diversityUI:'Source assignment - layer',proceduralUI:'Rule management',instanceRadiusUI:'Instance radii - layer',spacingUI:'Candidate Relax - layer',separationUI:'Cleanup settings - layer',flow_previewUI:'Display budgets and feedback - setup',detailsUI:'Statistics help',workflowUI:'Workflow and ownership',diagnosticsUI:'Local diagnostic recording - setup'},
 conditions:{
  ...Object.fromEntries(['setList','addButton','removeButton','nameEdit','targetList','enabledCheck','info'].map(n=>['setsUI.'+n,'setsUI.paintedCheck.checked'])),
  ...Object.fromEntries(['targetInfo','modeRadio','radiusSpin','insideSpin','outsideSpin','densityFade','densityCurve','scaleFade','scaleMin','scaleMax','scaleCurve','beginButton','stopButton','fillButton','emptyButton','exportSpline','importMode','splineTolerance','importSpline','brushState','brushHelp','densitySpin','overlayMode','overlayColor'].map(n=>['brushUI.'+n,'setsUI.paintedCheck.checked'])),
  'distributionUI.countSpin':'distributionUI.populationRadio.state==1','distributionUI.densitySpin':'distributionUI.populationRadio.state==2',
  'flow_previewUI.proxyShapeDrop':'flow_previewUI.displayModeDrop.selection==2',
  'flow_previewUI.instancesLimitSpin':'flow_previewUI.displayModeDrop.selection==2','flow_previewUI.faceLimitSpin':'flow_previewUI.displayModeDrop.selection==3',
  'flow_previewUI.navigationInstancesSpin':'flow_previewUI.displayModeDrop.selection==2','flow_previewUI.navigationFacesSpin':'flow_previewUI.displayModeDrop.selection==3',
  'flow_previewUI.navigationPointsSpin':'flow_previewUI.displayModeDrop.selection==1 or flow_previewUI.displayModeDrop.selection==4','flow_previewUI.budgetSpin':'flow_previewUI.displayModeDrop.selection==1 or flow_previewUI.displayModeDrop.selection==4',
  ...Object.fromEntries(['densityHeading','densityButton','invertCheck','uvChannelSpin','resolutionList','uvHint','mapHint'].map(n=>['distributionUI.'+n,'distributionUI.modeRadio.state==2'])),
  'flow_previewUI.solidColorPicker':'flow_previewUI.pointColorRadio.state==1',
  ...Object.fromEntries(['sizeSpin','divSeedSpin','roughSpin','blurSpin','noiseSpin','groupHint','fixedHint'].map(n=>['diversityUI.'+n,'diversityUI.diversityRadio.state==2'])),
  ...Object.fromEntries(['pathsList','cornerMode','arrangementMode','bandStrength','bandCurveCheck','bandCurveEdit','bandScaleMode','bandScaleEdit','bandColor','fieldFalloffCheck','fieldBoundaryCheck','fieldView','fieldSampleSpin','fieldLegend','fieldInfo','bandAssignmentHelp','bandUp','bandDown'].map(n=>['diversityUI.'+n,'diversityUI.diversityRadio.state==3'])),
  ...Object.fromEntries(['analyzerChannel','pickAnalyzer','analyzerStatus','selectAnalyzer','updateAnalyzer'].map(n=>['diversityUI.'+n,'diversityUI.diversityRadio.state==4'])),
  ...Object.fromEntries(['strokeTitle','removePath','strokesList','addOutside','addInside','removeStrokeButton','strokeWidth','strokeMode','strokeChoices','strokeScaleMin','strokeScaleMax','refreshGroups','strokeHelp'].map(n=>['diversityUI.'+n,'diversityUI.diversityRadio.state>=3'])),
  'diversityUI.addOutside':'diversityUI.diversityRadio.state>=3',
  'diversityUI.pickPath':'diversityUI.diversityRadio.state>=3',
  'diversityUI.strokeWidth':'diversityUI.diversityRadio.state==4 or (diversityUI.diversityRadio.state==3 and diversityUI.arrangementMode.selection==1)',
  ...Object.fromEntries(['bandStart','bandEnd'].map(n=>['diversityUI.'+n,'diversityUI.diversityRadio.state==3 and diversityUI.arrangementMode.selection==2'])),
  ...Object.fromEntries(['edgeOffsetSpin','edgeAlongSpin','edgeAcrossSpin','edgeRowHelp','keepCornerCheck','cornerAngleSpin','cornerCountSpin','cornerHelp','edgeRotXSpin','edgeRotYSpin','edgeRotZSpin'].map(n=>['diversityUI.'+n,'diversityUI.diversityRadio.state==4 and diversityUI.analyzerChannel.selection==5'])),
  ...Object.fromEntries(['streetStartSpin','streetEndSpin','streetLayoutHelp','straightStreet'].map(n=>['diversityUI.'+n,'diversityUI.diversityRadio.state==4 and diversityUI.analyzerChannel.selection==4'])),
  'diversityUI.centerStreetSpin':'diversityUI.diversityRadio.state==4 and diversityUI.analyzerChannel.selection==2',
  ...Object.fromEntries(['faceOutCheck','cornerRadiusSpin'].map(n=>['diversityUI.'+n,'diversityUI.diversityRadio.state==4 and (diversityUI.analyzerChannel.selection==1 or diversityUI.analyzerChannel.selection>=4)']))
 }
};
// Compact actions share a single row. Tooltips retain their full meaning.
Object.assign(module.exports.labels,{
 'diversityUI.pickPath':'+','diversityUI.removePath':'\u00d7','diversityUI.addOutside':'\u2197','diversityUI.addInside':'\u2199','diversityUI.removeStrokeButton':'\u00d7','diversityUI.bandUp':'\u25b2','diversityUI.bandDown':'\u25bc',
 'flow_surfaceUI.sharedPick':'+','flow_surfaceUI.removeSurfaces':'\u00d7','flow_surfaceUI.surfacesButton':'\u2637',
 'flow_layersUI.addButton':'+','flow_layersUI.copyButton':'\u29c9','flow_layersUI.removeButton':'\u00d7','flow_layersUI.upButton':'\u25b2','flow_layersUI.downButton':'\u25bc',
 'setsUI.addButton':'+','setsUI.removeButton':'\u00d7','setsUI.upButton':'\u25b2','setsUI.downButton':'\u25bc',
 'sourceUI.addPlant':'Add Model','sourceUI.removePlant':'\u00d7','sourceUI.selectFromScene':'\u2637','sourceUI.addSelected':'\u2295','sourceUI.selectPlant':'\u2316'
});
for(const prefix of ['rot','scl','mov'])for(const axis of ['X','Y','Z'])for(const end of ['Min','Max'])module.exports.labels['randomUI.'+prefix+axis+end+'Spin']=axis+' '+end;
Object.assign(module.exports.labels,{'randomUI.wholeMinSpin':'Min','randomUI.wholeMaxSpin':'Max'});
// Multi-control rows share one mode condition.
const layoutPage=module.exports.pages.find(p=>p.name==='layoutUI');
for(const row of layoutPage.rows)if(row.controls?.length>1)row.when=module.exports.conditions[row.controls[0]];

Object.assign(module.exports.labels,{'sourceUI.addEmpty':'Add Empty (gap)','sourceUI.weightSpin':'Weight:','sourceUI.radiusSourceSpin':'Radius:','sourceUI.existingGroups':'Use group','sourceContainersUI.modeList':'Model collection'});
Object.assign(module.exports.conditions,{...Object.fromEntries(['containersList','enabledCheck','removeContainer'].map(n=>['sourceContainersUI.'+n,'sourceContainersUI_modeList.selection>1'])),...Object.fromEntries(['fallPick','fallRemove'].map(n=>['areaUI.'+n,'areaUI_fallTarget.selection==1']))});

// Explanations belong in artist documentation/tooltips, not permanent panel
// paragraphs. Keep the component fields for status/binding contracts, but give
// these help-only labels no presentation row or reserved space.
const helpOnly={
 flow_surfaceUI:['containerInfo'],
 sourceContainersUI:['helpInfo'],
 sourceUI:['radiusModeHelp','weightHelp','sourceTransformHelp','colorHelp'],
 diversityUI:['layoutHelp','groupHint','fixedHint','fieldLegend','strokeHelp','edgeRowHelp','cornerHelp','streetLayoutHelp'],
 populationPolicyUI:['info'],distributionUI:['uvHint','mapHint'],
 setsUI:['info'],brushUI:['brushHelp'],
 areaUI:['areaHint','projectionHint','aaHelp','fallHelp'],
 proceduralUI:['ruleInfo'],instanceRadiusUI:['info'],spacingUI:['orderHint'],separationUI:['helpInfo'],
 flow_previewUI:['radiusHint'],workflowUI:['steps','help'],diagnosticsUI:['scopeInfo']
};
for(const page of module.exports.pages){
 const hidden=page.parts.flatMap(part=>(helpOnly[part]||[]).map(name=>part+'.'+name));
 page.hidden=[...(page.hidden||[]),...hidden];
 page.rows=page.rows.filter(row=>row.toggle!=='workflowToggle').map(row=>row.controls?{...row,controls:row.controls.filter(name=>!hidden.includes(name))}:row).filter(row=>!row.controls||row.controls.length);
}

Object.assign(module.exports.labels,{'diversityUI.strokeScaleMin':'Min:','diversityUI.strokeScaleMax':'Max:'});
