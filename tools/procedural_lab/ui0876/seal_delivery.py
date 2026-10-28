"""Seal observed 0.87.6 UI evidence without changing historical receipts."""
from pathlib import Path
import hashlib,json,re,shutil
ROOT=Path(__file__).resolve().parents[3]
RUN=ROOT/'build/ui0876-20261028-01'
HOST=RUN/'host-03'
DEST=ROOT/'docs/plans/ui-settings-0876-20261028'
OUT=ROOT/'dist/CyrusScatter-0.87.6-20261028-final'
sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
read=lambda p:json.loads(p.read_text(encoding='utf-8-sig'))
evidence=DEST/'evidence';evidence.mkdir(exist_ok=True)
cases=['points','paint_edges','paint_tools','panels','settings','settings_expanded','negative','layout','swatches','interactions','library',
       'point-action','point-record','point-undo-check','point-redo-check']
reports={}
for case in cases:
    path=HOST/(case+'.json');data=read(path)
    assert data['status']=='pass',(case,data)
    rows=data.get('checks',[]);assert all(r['status']=='pass' for r in rows)
    reports[case]={'path':'evidence/'+path.name,'sha256':sha(path),
                  'checked':sum(not str(r.get('value','')).startswith('not exercised:') for r in rows),
                  'inactive_not_exercised':sum(str(r.get('value','')).startswith('not exercised:') for r in rows)}
    shutil.copy2(path,evidence/path.name)
native=RUN/'final/native-2027/Testing/Temporary/LastTest.log'
assert native.read_text().count('Test Passed.')==23
shutil.copy2(native,evidence/'native-tests.log')
for name in ['ready.json','loaded-identity.json']:
    shutil.copy2(HOST/name,evidence/name)
generated=RUN/'generated/generated-check.json'
generation=read(generated)
assert generation['passed'] and generation['generated_sha256']==sha(RUN/'payload-03/CyrusScatter.ms')
shutil.copy2(generated,evidence/'generated-check.json')
package=read(OUT/'DELIVERY_RECEIPT.json');assert package['status']=='passed'
shutil.copy2(OUT/'DELIVERY_RECEIPT.json',evidence/'installer-receipt.json')
for item in read(HOST/'loaded-identity.json')['modules'].values():
    assert sha(Path(item['path']))==item['sha256']
before=read(RUN/'before.json')['files']
protected={}
for name,digest in before.items():
    stem=Path(name).name
    applies=(name.startswith('CyrusVegetationLab/') and Path(name).suffix in ('.cpp','.h','.hpp','.inc')) or (
        name.startswith(('AminScatter/src/','AminScatter/include/')) and
        (stem.startswith(('interaction','preparation','deformation')) or stem in ('mesh_display.inc','point_display.cpp','point_preview.h')))
    if applies:
        assert sha(ROOT/name)==digest,'Performance baseline changed: '+name
        protected[name]=digest
assert len(protected)>20
(evidence/'protected-sources.json').write_text(json.dumps(protected,indent=2)+'\n',encoding='utf-8')
layout=read(HOST/'layout.json')
result={
 'schema':'cyrus.ui-qualification/1','status':'scoped_pass','version':'0.87.6','max_year':2027,
 'scene_schema':65,'interactions':15,'recipe_format':9,'edit_storage':3,
 'host_evidence':reports,'loaded_identity':'evidence/loaded-identity.json',
 'script_sha256':sha(RUN/'payload-03/CyrusScatter.ms'),
 'native_suites':{'passed':23,'failed':0,'path':'evidence/native-tests.log','sha256':sha(native)},
 'generated_check':{'path':'evidence/generated-check.json','sha256':sha(generated)},
 'layout':{'measured_visible_control_samples':layout['measured_controls'],'bounds_issues':len(layout['bounds_issues']),
           'observed_logical_widths':sorted(set(r['actual_layout'] for r in layout['widths'])),
           'limit':'Command-panel shell clamped all requested widths to 154. Repeated samples are not unique controls. Spinner anchors/controls lacking width were skipped; native swatches are checked separately. No screenshot or DPI matrix.'},
 'performance_preservation':{'reference':'0.87.5.6','unchanged_native_sources':len(protected),'hashes':'evidence/protected-sources.json',
     'scope':'Core interaction/preparation/display source bytes match the pre-task snapshot. Panel browsing retained publication counters. No new drag/orbit performance campaign or renderer qualification.'},
 'installer':{'receipt':'evidence/installer-receipt.json','exe_sha256':package['exe_sha256'],'packages':package['packages'],
              'scope':'Distinct SDK builds. 2027 runtime UI tests; 2024/2026 compile/package only. Embedded resource and archive/hash/guard checks; installer UI was not executed.'},
 'limits':[
   'Control inventory is not universal behavioral acceptance. Inactive controls, external Analyzer dependencies, renderer paths, remote Library transactions, physical curve dragging and arbitrary imported assets were not exhaustively tested. Paint curve opening and programmatic endpoint publication passed separately.',
   'Native notifications and MAXScript handlers were used in disposable profiles. No Computer Use, physical mouse measurement or artist-session installation.',
   'The Library baseline remains its separately scoped 0.87.5.1 qualification; native Scene presets retain Max 2027-only support.',
   'The website and knowledge indexes were not rebuilt by this delivery. Original maintained sources and delivered facts are authoritative pending a separate corpus refresh.',
 ]}
(DEST/'QUALIFICATION.json').write_text(json.dumps(result,indent=2)+'\n',encoding='utf-8')
facts={'schema':'cyrus.delivery-facts/1','status':'scoped_pass','version':'0.87.6','max_year':2027,
       'scene_schema':65,'recipe_format':9,'edit_storage':3,'interactions':15,
       'qualification':'Max 2027 UI/settings smoke and 23 focused native suites; Max 2024/2026 compiled and package checked only.',
       'qualification_receipt':'docs/plans/ui-settings-0876-20261028/QUALIFICATION.json',
       'qualification_sha256':sha(DEST/'QUALIFICATION.json'),
       'package_sha256':package['packages']['CyrusScatter-0.87.6-Max2027.mzp']}
(DEST/'KNOWLEDGE_FACTS_0876.json').write_text(json.dumps(facts,indent=2)+'\n',encoding='utf-8')
print(json.dumps({'cases':len(reports),'native_suites':23,'protected_sources':len(protected),'status':'scoped_pass'}))
