"""Emit a traceable control inventory, preserving host evidence limits."""
from pathlib import Path
import json,re,subprocess,argparse
from control_meanings import meaning
ROOT=Path(__file__).resolve().parents[3]
p=argparse.ArgumentParser();p.add_argument('--host',type=Path);a=p.parse_args()
ui=ROOT/'AminScatter/tools/ui';dest=ROOT/'docs/plans/ui-settings-0876-20261028'
inventory=json.loads((ui/'layers-control-inventory.json').read_text())
tips=json.loads((ui/'control-tooltips.json').read_text())
manifest=json.loads((ui/'approved-layout-manifest.json').read_text())
presentation=json.loads(subprocess.check_output(['node','-e','process.stdout.write(JSON.stringify(require("./tools/ui/approved-layout-rows.cjs")))'],cwd=ROOT/'AminScatter',encoding='utf-8'))
script=(ROOT/'AminScatter/scripts/AminScatterObject.ms').read_text(encoding='utf-8-sig')
source=(ui/'templates/unified-core.ms').read_text(encoding='utf-8-sig')
reverse={'flow_layersUI':'manager','flow_surfaceUI':'surface','flow_previewUI':'previewUI','diagnosticsUI':'diagnostics'}
owners={'setsUI':'Paint Area membership in the selected layer','brushUI':'Selected Paint Area / its receiver',
 'flow_layersUI':'Scatter controller / selected layer','flow_surfaceUI':'Controller receivers / layer use',
 'sourceUI':'Selected source rows in this layer','sourceContainersUI':'Source pool in this layer',
 'instanceRadiusUI':'Selected Cyrus Edit instances in this layer','flow_previewUI':'Scatter controller display',
 'diagnosticsUI':'Local diagnostic recorder','collidersUI':'Scene collider list in this Scatter controller'}
results={}
focused={
 'flow_layersUI_copyButton':'layer copy button','flow_layersUI_nameEdit':'layer rename','flow_layersUI_removeButton':'layer remove button',
 'flow_surfaceUI_sharedPick':'receiver pick handler','sourceContainersUI_createContainer':'create inactive source rectangle','sourceContainersUI_removeContainer':'unlink source rectangle',
 'sourceUI_addPoint':'Add Point actual button','sourceUI_makePoint':'all Point publication','sourceUI_pickPlant':'replace Point keeps row identity','sourceUI_removePlant':'remove source and shared lists',
 'setsUI_paintedCheck':'enable Paint Areas','setsUI_addButton':'create Paint Area','brushUI_insideSpin':'inward fade changes density','brushUI_outsideSpin':'outward fade extends coverage',
 'brushUI_scaleFade':'size fade parameters persist','brushUI_scaleMin':'size fade parameters persist','brushUI_emptyButton':'clear and fill actual buttons','brushUI_fillButton':'clear and fill actual buttons','brushUI_densitySpin':'area enable and density',
 'placementUI_generatorList':'grid mode 4','diversityUI_diversityRadio':'cluster assignment','diversityUI_pickPath':'Band path and outward Band','diversityUI_addOutside':'Band path and outward Band',
 'diversityUI_strokeWidth':'Band width and source assignment','diversityUI_strokeChoices':'Band width and source assignment','diversityUI_fieldFalloffCheck':'Band preview is inspection only','diversityUI_fieldBoundaryCheck':'Band preview is inspection only',
 'diversityUI_removeStrokeButton':'remove Band then path','diversityUI_removePath':'remove Band then path','areaUI_pickArea':'include Area','areaUI_areaMode':'exclude Area','areaUI_removeArea':'remove Area',
 'randomUI_wholeMaxSpin':'transform scale roundtrip','randomUI_resetWholeScale':'transform scale roundtrip','distributionUI_meshPreviewButton':'density preview toggle','flow_previewUI_displayModeDrop':'display representation 5','detailsUI_refreshButton':'read cached statistics',
 'interactionsUI_prepareButton':'Prepare model actual button','interactionsUI_responseList':'response 3','interactionsUI_guideReviewButton':'source guide toggle','collidersUI_addButton':'scene collider pick','collidersUI_removeButton':'scene collider remove',
 'brushUI_densityCurve':'density programmed curve endpoint applies','brushUI_scaleCurve':'scale programmed curve endpoint applies','brushUI_overlayMode':'Paint preview mode 3','flow_layersUI_recipesButton':'Recipes button opens Library',
}
def priority(row):
 return (row['status']=='pass',not str(row.get('value','')).startswith('not exercised:'))
if a.host:
 for file in a.host.glob('*.json'):
  try:
   for row in json.loads(file.read_text(encoding='utf-8-sig')).get('checks',[]):
    if row['name'] not in results or priority(row)>priority(results[row['name']]):results[row['name']]=row
  except (ValueError,KeyError):pass
lines=['# 0.87.6 control ledger','',
 'This is the complete generated semantic-control inventory plus presentation-only controls. '
 'The descriptions originate in the maintained source contracts/help. Each row links to its generated '
 'binding for inspection; authoritative edits belong in the templates/generator. A host handler smoke '
 'is narrower than numerical validation or a visual pass. Inactive prerequisites are explicitly not counted as exercised.','',
 'Main header: Enable Cyrus Scatter controls evaluation; Manual/Live chooses scheduling; Update scatter '
 'publishes pending authoring; License/activation opens licensing. These remain at controller scope. '
 'Source containers have their own selected-node UI; the seven container properties remain independent of Scatter panels.','']
records=[]
for page in manifest['sections']:
 definition=next(x for x in presentation['pages'] if x['name']==page['name'])
 lines+=['## '+page['title'],'','| Control | Meaning / owner | Location and prerequisite | Evidence |','|---|---|---|---|']
 for item in page['controls']:
  component,name,identifier=item['component'],item['control'],item['presentation']
  bucket=inventory['layer'].get(component,inventory['general'].get(reverse.get(component,''),[]))
  semantic=next((c for c in bucket if c['name']==name),None)
  if not semantic:continue # status captions and decorative labels are covered below
  declaration=re.search(r'^        \w+ '+re.escape(identifier)+r' ([^\n]*)',script,re.M)
  caption=re.search(r'^"([^"]*)"',declaration[1]) if declaration else None
  label=caption[1] if caption and caption[1] else presentation['labels'].get(component+'.'+name,name)
  if label==name:
   separated=re.search(r'label '+re.escape(identifier)+r'_caption "([^"]*)"',script)
   if separated:label=separated[1]
  tip=tips.get(reverse.get(component,component),{}).get(name)
  if not tip:tip=meaning(component,name,label)
  if not tip:
   tip={'layerList':'Select a layer to edit; display its completed placement count and status.',
    'plantList':'Select source rows; supports Ctrl/Shift multiple selection.',
    'modelList':'The same source membership as Models & Points; prepare the original source.',
    'sourceName':'Name the selected source row without renaming library assets.',
    'idColor':'Change the source identification color; materials remain separate.',
    'nameEdit':'Rename the selected owner.', 'layerColor':'Layer identification color.',
    'copyVariation':'Choose whether copied layer variation is shared or independent.',
    'enabledCheck':'Enable this owner’s contribution.', 'visibleCheck':'Show this owner in preview.',
    'countSpin':'Requested candidates or accepted target according to population policy.',
    'seedSpin':'Deterministic population seed.', 'setList':'Select the receiver-bound Paint Area.',
    'targetList':'Choose the receiving surface for this Paint Area.',
    'areaList':'Select closed include/exclude shapes for this layer.',
    'previewCheck':'Show the retained viewport preview.',
    'autoRenderCheck':'Build automatic final-render geometry from the current setup.',
    'detailsToggle':'Retired component disclosure; its controls are composed into the current panel.'}.get(name,
      'Inspect the linked handler; '+semantic['kind']+' for '+label+'.')
  key=component+'.'+name
  row=next((x for x in definition['rows'] if key in x.get('controls',[])),{})
  hidden=key in definition.get('hidden',[]) or name in ('detailsToggle','containersToggle')
  condition=row.get('when',presentation.get('conditions',{}).get(key,'Relevant owner must exist'))
  location='Hidden helper / legacy presentation' if hidden else ('Secondary: '+definition.get('advancedLabel','More settings') if item['advanced'] else 'Primary / contextual')
  evidence=results.get(identifier)
  state='Binding documented; behavior not exercised in the generic host sweep'
  if evidence:state=('Inactive prerequisite; not exercised' if str(evidence.get('value','')).startswith('not exercised:') else 'Host handler '+evidence['status'])
  if focused.get(identifier) in results:
   evidence=results[focused[identifier]];state='Focused case '+evidence['status']+': '+focused[identifier]
  line=script[:declaration.start()].count('\n')+1 if declaration else 1
  records.append(dict(panel=page['title'],component=component,control=name,kind=semantic['kind'],label=label,meaning=tip,owner=owners.get(component,'Selected layer'),location=location,condition=condition,evidence=state,source_line=line))
  clean=lambda x:str(x).replace('|','/').replace('\n',' ')
  lines.append('| ['+clean(label)+'](../../../AminScatter/scripts/AminScatterObject.ms#L'+str(line)+') (`'+identifier+'`) | '+clean(tip)+' Owner: '+owners.get(component,'Selected layer')+'. | '+clean(location)+'; '+clean(condition)+' | '+state+' |')
 disclosures=[x['caption'] for x in definition['rows'] if 'toggle' in x]
 lines+=['','Presentation disclosures: '+(', '.join(disclosures) if disclosures else 'panel’s secondary settings toggle only')+'. These change visibility only; saved settings retain their effects.','']
lines+=['## Interpretation and secondary windows','','The host campaign separately records Add Point conversion/replacement/persistence, Paint edge counts, numeric source settings, grids/Bands/Areas, viewport representations, and unchanged publication during browsing. See QUALIFICATION.md for exact coverage.','',
 'File dialogs, licensing activation, renderer-specific output, remote library transactions, unsupported Analyzer inputs, and every possible imported asset combination are not certified by this UI pass. Preset, Library, preparation, memory and curve editors retain their existing independent ownership/contracts. No feature was deleted solely to shorten a panel.','',
 '## Container properties','','| Control | Meaning |','|---|---|']
for item in inventory['container']['properties']:
 lines.append('| `'+item['name']+'` | '+tips.get('properties',{}).get(item['name'],'Container '+item['kind']+'; see its original containerUI binding.')+' |')
dest.mkdir(parents=True,exist_ok=True)
(dest/'CONTROL_LEDGER.md').write_text('\n'.join(lines)+'\n',encoding='utf-8')
(dest/'control-ledger.json').write_text(json.dumps({'version':'0.87.6','controls':records,'scope':'Semantic inventory; evidence per row'},indent=2)+'\n',encoding='utf-8')
print('Documented',len(records),'panel semantic controls plus',len(inventory['container']['properties']),'container controls and the main header.')
