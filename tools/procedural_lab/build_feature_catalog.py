"""Build help from current reviewed docs and generated semantic controls.

Offline authoring only. Documentation never expands MCP tool authority.
"""
from pathlib import Path
import hashlib
import json
import re

ROOT=Path(__file__).resolve().parents[2]
SECTION_CAPS={
    'host':['C01'],'editor':['C24','C26','C27'],'updateUI':['C24'],
    'previewUI':['C25','C28','C29'],'surface':['C02','C07'],'manager':['C03','C26'],
    'diagnostics':['C32'],'setsUI':['C04'],'sourceUI':['C05','C06','C08'],
    'sourceContainersUI':['C07'],'distributionUI':['C09','C11'],
    'populationPolicyUI':['C10'],'areaUI':['C12','C13'],'brushUI':['C14','C15'],
    'backgroundUI':['C16'],'randomUI':['C19'],'diversityUI':['C17','C18'],
    'proceduralUI':['C20'],'instanceRadiusUI':['C21'],'spacingUI':['C23'],
    'separationUI':['C22'],'detailsUI':['C27'],'workflowUI':['C26'],
    'properties':['C07','C26'],
}

def build():
    source=ROOT/'docs/Current_System_2026-10-05/CAPABILITY_MATRIX.md'
    rows=[]
    for line in source.read_text(encoding='utf-8').splitlines():
        if line.startswith('| C'):
            columns=[s.strip() for s in line.strip('|').split('|')]
            if len(columns)==5 and columns[0][1:].isdigit():
                rows.append(dict(feature_id=columns[0],title=columns[1],native=columns[2],mcp=columns[3],qualification_or_extension=columns[4]))
    assert len(rows)==34 and len({r['feature_id'] for r in rows})==34
    inventory_path=ROOT/'AminScatter/tools/ui/layers-control-inventory.json'
    inventory=json.loads(inventory_path.read_text(encoding='utf-8'))
    old=json.loads((ROOT/'docs/Current_System_2026-10-05/evidence/control-inventory.json').read_text(encoding='utf-8'))
    ownership={(r['group'],r['section'],r['name']):r for r in old['rows']}
    tooltips=json.loads((ROOT/'AminScatter/tools/ui/layer-editor-tooltips.json').read_text(encoding='utf-8'))
    controls=[]
    for group,sections in inventory.items():
        if not isinstance(sections,dict):continue
        for section,entries in sections.items():
            for entry in entries:
                previous=ownership.get((group,section,entry['name']),{})
                caps=SECTION_CAPS[section] if section in ('spacingUI','separationUI','proceduralUI','properties') else previous.get('capabilities',SECTION_CAPS[section])
                owner=previous.get('owner_context','Selected layer recipe' if group=='layer' else 'Local container view' if group=='container' else 'Controller / local view')
                if section=='setsUI':owner='Selected layer / named Paint Area; older model-owning sets are distinct'
                elif section=='brushUI':owner='Selected Paint Area and its receiver; shared layer models'
                elif section in ('sourceUI','sourceContainersUI'):owner='Selected layer model collection; older groups retain independent metadata'
                elif section=='surface' and entry['name'] in ('sharedPick','removeSurfaces','surfacesButton','receiversList'):owner='Selected layer receiving surfaces'
                controls.append(dict(group=group,section=section,**entry,capabilities=caps,owner_context=owner,
                    help=tooltips.get(section,{}).get(entry['name']),
                    view='Modify selected layer, selected container and optional popup' if group=='layer' else 'Local setup/editor controls',
                    remote_control="No UI-control invocation; closed plan 0.73 and local approval define the supported authoring subset."))
    return dict(schema='cyrus.feature-catalog/1.0',authority='Help only. Tool dispatch, closed schema and local approval determine authority.',
                capability_source_sha256=hashlib.sha256(source.read_bytes()).hexdigest(),
                control_inventory_sha256=hashlib.sha256(inventory_path.read_bytes()).hexdigest(),
                development_version='0.76',mcp_version='0.73.0',calculation_model='CyrusUnified1',features=rows,controls=controls)

if __name__=='__main__':
    target=ROOT/'CyrusMCP/cyrus_mcp/feature-catalog.json'
    target.write_text(json.dumps(build(),indent=2,ensure_ascii=False)+'\n',encoding='utf-8')
    print(target)
