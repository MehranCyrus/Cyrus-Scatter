// Basic controls follow the approved artist workflow. Remaining fields stay
// reachable under Advanced; conditional rows retain their original mode gates.
const rows=(key,names,advanced=false)=>names.map(names=>({controls:(Array.isArray(names)?names:[names]).map(n=>key+'.'+n),advanced}));
const heading=(text,advanced=false)=>({heading:text,advanced});
module.exports={
 labels:{'flow_layersUI.addButton':'Add','flow_layersUI.copyButton':'Copy','flow_layersUI.removeButton':'Remove','flow_layersUI.enabledCheck':'Enabled','flow_layersUI.visibleCheck':'Visible','setsUI.enabledCheck':'Enabled','setsUI.visibleCheck':'Visible','setsUI.setList':'','sourceContainersUI.modeList':'','sourceContainersUI.createContainer':'Create','sourceContainersUI.pickContainer':'Pick','sourceContainersUI.removeContainer':'Unlink','flow_layersUI.upButton':'Move up','flow_layersUI.downButton':'Move down','sourceUI.addSelected':'Add selected'},
 pages:[
  {name:'managerUI',title:'Layers',parts:['flow_layersUI'],layerPage:false,rows:[heading('Layers - evaluation order'),...rows('flow_layersUI',['layerList',['addButton','copyButton','removeButton','upButton','downButton'],['nameEdit','layerColor']]),{toggle:'propertiesToggle',caption:'Properties'},...rows('flow_layersUI',[['enabledCheck','visibleCheck']]).map(r=>({...r,when:'propertiesToggle.checked'}))]},
  {name:'surfacesUI',title:'Surfaces',parts:['flow_surfaceUI'],layerPage:true,rows:[...rows('flow_surfaceUI',['receiversList',['sharedPick','removeSurfaces','surfacesButton'],'sharedInfo','countInfo'])]},
  {name:'modelsUI',title:'Models',parts:['sourceContainersUI','sourceUI','diversityUI'],layerPage:true,rows:[heading('Source pool - layer'),...rows('sourceContainersUI',['modeList',['createContainer','pickContainer','removeContainer'],'containersList','membershipInfo']),heading('Selected source - layer'),...rows('sourceUI',['plantList',['addPlant','removePlant','selectFromScene','addSelected','selectPlant'],['sourceName','idColor']]),{toggle:'propertiesToggle',caption:'Properties'},...rows('sourceUI',[['weightSpin','sourceScaleSpin'],['radiusSourceSpin','sourceZSpin'],['followRadiusCheck','showRadiusCheck']]).map(r=>({...r,when:'propertiesToggle.checked'}))]},
  {name:'populationUI',title:'Population',parts:['distributionUI','populationPolicyUI'],layerPage:true,rows:[heading('Population - layer'),...rows('distributionUI',['populationRadio','countSpin','densitySpin','seedSpin'])]},
  {name:'coverageUI',title:'Painting',parts:['setsUI','brushUI'],layerPage:true,rows:[...rows('setsUI',['paintedCheck','importButton','setList',['addButton','removeButton'],'nameEdit','targetList','enabledCheck','info']),...rows('brushUI',['targetInfo','modeRadio',['radiusSpin','strengthSpin'],'softSpin',['beginButton','stopButton'],['fillButton','emptyButton'],'brushState'])]},
  {name:'areasUI',title:'Include / exclude areas',parts:['areaUI'],layerPage:true,rows:[heading('Area limits - layer'),...rows('areaUI',['areaList',['pickArea','addAreaScene'],'removeArea','areaMode','areaHint'])]},
  {name:'transformsUI',title:'Transforms',parts:['randomUI'],layerPage:true,rows:[heading('Transforms - layer'),...rows('randomUI',['rotTitle',['rotMinTitle','rotMaxTitle'],['rotZLabel','rotZMinSpin','rotZMaxSpin'],'wholeTitle',['wholeMinTitle','wholeMaxTitle'],['wholeMinSpin','wholeMaxSpin'],['alignCheck','projectCheck']])]},
  {name:'spacingUI',title:'Spacing & cleanup',parts:['proceduralUI','instanceRadiusUI','spacingUI','separationUI'],layerPage:true,rows:[heading('Spacing - selected scope'),...rows('proceduralUI',['scopeList','peerList','enabledCheck',['multiplierSpin','gapSpin'],'planarCheck','ruleInfo'])]},
  {name:'displayUI',title:'Viewport & render',parts:['flow_previewUI'],layerPage:false,rows:[...rows('flow_previewUI',['displayModeDrop','identificationDrop','previewCheck','autoRenderCheck','status'])]},
  {name:'statisticsUI',title:'Statistics & diagnostics',parts:['detailsUI','workflowUI','diagnosticsUI'],layerPage:false,rows:[...rows('detailsUI',['info',['refreshButton','helpButton']]),heading('Local diagnostic recording - setup',true),...rows('diagnosticsUI',[['startButton','stopButton'],['saveButton','refreshButton'],'statusInfo','scopeInfo'],true),{toggle:'workflowToggle',caption:'Workflow & ownership',advanced:true},...rows('workflowUI',['steps','help'],true).map(r=>({...r,when:'workflowToggle.checked'}))]}
 ],
 popupSets:{name:'setsUI',title:'Paint Areas',parts:['setsUI'],layerPage:true,rows:rows('setsUI',['paintedCheck','importButton','setList',['addButton','removeButton'],'nameEdit','targetList','enabledCheck','info'])},
 captions:{flow_surfaceUI:'Global model palettes - setup',flow_layersUI:'Layer management',setsUI:'Paint Areas',sourceUI:'Source details - layer',sourceContainersUI:'Source pool help',distributionUI:'Sampling - layer',populationPolicyUI:'Target and bounded retry - layer',brushUI:'Paint feedback',backgroundUI:'Background coverage help',areaUI:'Analyzer and area falloff',randomUI:'Per-axis scale and movement',diversityUI:'Source assignment - layer',proceduralUI:'Rule management',instanceRadiusUI:'CS Edit instance radii - paint set',spacingUI:'Candidate Relax - layer',separationUI:'Cleanup settings - layer',flow_previewUI:'Display budgets and feedback - setup',detailsUI:'Statistics help',workflowUI:'Workflow and ownership',diagnosticsUI:'Local diagnostic recording - setup'},
 conditions:{
  'setsUI.importButton':'setsUI.owner!=undefined and setsUI.owner.paintDocument!=undefined and not setsUI.owner.areaMode',
  'distributionUI.countSpin':'distributionUI.populationRadio.state==1','distributionUI.densitySpin':'distributionUI.populationRadio.state==2',
  'flow_previewUI.proxyShapeDrop':'flow_previewUI.displayModeDrop.selection==2',
  'flow_previewUI.instancesLimitSpin':'flow_previewUI.displayModeDrop.selection!=1','flow_previewUI.faceLimitSpin':'flow_previewUI.displayModeDrop.selection!=1',
  ...Object.fromEntries(['densityHeading','densityButton','invertCheck','uvHint','mapHint'].map(n=>['distributionUI.'+n,'distributionUI.modeRadio.state==2'])),
  'flow_previewUI.solidColorPicker':'flow_previewUI.pointColorRadio.state==1',
  ...Object.fromEntries(['sizeSpin','divSeedSpin','roughSpin','blurSpin','noiseSpin','groupHint','fixedHint'].map(n=>['diversityUI.'+n,'diversityUI.diversityRadio.state==2'])),
  ...Object.fromEntries(['pathsDrop','pickPath'].map(n=>['diversityUI.'+n,'diversityUI.diversityRadio.state==3'])),
  ...Object.fromEntries(['analyzerChannel','pickAnalyzer'].map(n=>['diversityUI.'+n,'diversityUI.diversityRadio.state==4'])),
  ...Object.fromEntries(['strokeTitle','removePath','strokesList','addOutside','addInside','removeStrokeButton','strokeWidth','strokeMode','strokeChoices','strokeScaleMin','strokeScaleMax','refreshGroups','strokeHelp'].map(n=>['diversityUI.'+n,'diversityUI.diversityRadio.state>=3'])),
  'diversityUI.addOutside':'diversityUI.diversityRadio.state==3 or (diversityUI.diversityRadio.state==4 and (diversityUI.analyzerChannel.selection==2 or diversityUI.analyzerChannel.selection==3))',
  ...Object.fromEntries(['edgeOffsetSpin','edgeAlongSpin','edgeAcrossSpin','edgeRowHelp','keepCornerCheck','cornerAngleSpin','cornerCountSpin','cornerHelp','edgeRotXSpin','edgeRotYSpin','edgeRotZSpin'].map(n=>['diversityUI.'+n,'diversityUI.diversityRadio.state==4 and diversityUI.analyzerChannel.selection==5'])),
  ...Object.fromEntries(['streetStartSpin','streetEndSpin','streetLayoutHelp','straightStreet'].map(n=>['diversityUI.'+n,'diversityUI.diversityRadio.state==4 and diversityUI.analyzerChannel.selection==4'])),
  'diversityUI.centerStreetSpin':'diversityUI.diversityRadio.state==4 and diversityUI.analyzerChannel.selection==2',
  ...Object.fromEntries(['faceOutCheck','cornerRadiusSpin'].map(n=>['diversityUI.'+n,'diversityUI.diversityRadio.state==4 and (diversityUI.analyzerChannel.selection==1 or diversityUI.analyzerChannel.selection>=4)']))
 }
};
// Compact actions share a single row. Tooltips retain their full meaning.
Object.assign(module.exports.labels,{
 'flow_surfaceUI.sharedPick':'+','flow_surfaceUI.removeSurfaces':'\u00d7','flow_surfaceUI.surfacesButton':'\u2637',
 'flow_layersUI.addButton':'+','flow_layersUI.copyButton':'\u29c9','flow_layersUI.removeButton':'\u00d7','flow_layersUI.upButton':'\u25b2','flow_layersUI.downButton':'\u25bc',
 'setsUI.addButton':'+','setsUI.removeButton':'\u00d7','setsUI.upButton':'\u25b2','setsUI.downButton':'\u25bc',
 'sourceUI.addPlant':'+','sourceUI.removePlant':'\u00d7','sourceUI.selectFromScene':'\u2637','sourceUI.addSelected':'\u2295','sourceUI.selectPlant':'\u2316'
});
