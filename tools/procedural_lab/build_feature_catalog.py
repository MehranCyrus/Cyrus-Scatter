"""Build the packaged agent help from reviewed product/control documentation.

This is an authoring tool, never executed by MCP or inside Max. Source changes
must be reviewed together with regenerated help; documents grant no authority.
"""
from pathlib import Path
import hashlib
import json

ROOT=Path(__file__).resolve().parents[2]


def build():
    source=ROOT/"docs/Current_System_2026-10-05/CAPABILITY_MATRIX.md"
    rows=[]
    for line in source.read_text(encoding="utf-8").splitlines():
        if line.startswith("| C"):
            columns=[s.strip() for s in line.strip("|").split("|")]
            if len(columns)==5 and columns[0][1:].isdigit():
                rows.append(dict(feature_id=columns[0],title=columns[1],native=columns[2],
                                 mcp=columns[3],qualification_or_extension=columns[4]))
    assert len(rows)==34 and len({r["feature_id"] for r in rows})==34
    by_id={r["feature_id"]:r for r in rows}
    by_id["C07"]["mcp"]="Read configured references/mode plus cached active/parked/missing/placeholder rows and membership revision when available. Stale row alignment is unavailable; no reconciliation or current-containment query. Bounded private Max 2027 reads were qualified in the 6 October Live runtime campaign."
    by_id["C26"]["native"]="One selected layer in sixteen native Modify sections; optional popup with six topics. Warm retarget binds the current owner. Browsing preserves publications and retained buffers; pointer/DPI latency is a separate qualification."
    by_id["C31"]["mcp"]="Legacy owned records remain supported. MCP 1.2 get_publication/read_publication_page reads policy-3 cached transforms, effective radii, stable IDs and compact metadata. Bounded private Max 2027 paging was qualified in the 6 October Live runtime campaign. Full reconstructable recipe/asset export remains unavailable."
    by_id["C32"]["native"]="Bounded process-wide native event recorder. Scatter Modify > Diagnostics starts/stops/exports a local paged bundle without MCP; Automation retains its own canonical report format. Off by default; no polling, automatic upload or training eligibility."
    by_id["C32"]["mcp"]="MCP 1.2 reads explicitly shared diagnostic event pages. Local controls own recording and file export. Bounded sharing and host lifecycle were qualified in the 6 October Live runtime campaign; no remote start, stop, grant or file write. A full causal archive is future work."
    documented=json.loads((ROOT/"docs/Current_System_2026-10-05/evidence/control-inventory.json").read_text(encoding="utf-8"))
    inventory_path=ROOT/"AminScatter/tools/ui/layers-control-inventory.json"
    inventory=json.loads(inventory_path.read_text(encoding="utf-8"))
    ownership={(item['group'],item['section'],item['name']):item for item in documented['rows']}
    tooltips=json.loads((ROOT/"AminScatter/tools/ui/layer-editor-tooltips.json").read_text(encoding="utf-8"))
    controls=[]
    for group,sections in inventory.items():
        if not isinstance(sections,dict):continue
        for section,entries in sections.items():
            for entry in entries:
                key=(group,section,entry['name'])
                if section=='diagnostics':
                    item=dict(group=group,section=section,**entry,capabilities=['C32'],owner_context='Process-wide local recording')
                else:
                    item=ownership[key]
                    assert item['kind']==entry['kind'],key
                assert set(item["capabilities"]) <= by_id.keys()
                controls.append(dict(item, help=tooltips.get(section,{}).get(entry['name']),
                                     view='Modify selected layer and optional popup' if group=='layer' else 'Local setup/editor controls',
                                     remote_control="No direct UI-control invocation; consult the feature's typed plan support."))
    return dict(schema="cyrus.feature-catalog/1.0", authority="Help only. Tool dispatch, closed schemas and local approval determine authority.",
                capability_source_sha256=hashlib.sha256(source.read_bytes()).hexdigest(),
                control_inventory_sha256=hashlib.sha256(inventory_path.read_bytes()).hexdigest(),
                development_version="0.72", mcp_version="1.2.0", features=rows,controls=controls)


if __name__=="__main__":
    target=ROOT/"CyrusMCP/cyrus_mcp/feature-catalog.json"
    target.write_text(json.dumps(build(),indent=2,ensure_ascii=False)+"\n",encoding="utf-8")
    print(target)
