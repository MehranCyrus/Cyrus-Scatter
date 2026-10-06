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
    by_id["C07"]["mcp"]="Read configured references/mode plus cached active/parked/missing/placeholder rows and membership revision when available. Stale row alignment is reported as unavailable; no reconciliation or current-containment query. New cached-row adapter awaits isolated Max qualification."
    by_id["C31"]["mcp"]="Legacy owned records remain supported. MCP 1.2 source adds get_publication/read_publication_page for policy-3 cached transforms, effective radii, stable IDs and compact metadata. Full reconstructable recipe/asset export remains unavailable. New host adapter awaits isolated Max qualification."
    by_id["C32"]["mcp"]="MCP 1.2 source adds explicitly shared diagnostic event pages. Local panel starts/stops/saves bounded process-wide recording. Offline tests pass; runtime overhead/lifecycle/renderer acceptance remains pending. No remote start, stop, grant or file write."
    inventory=json.loads((ROOT/"docs/Current_System_2026-10-05/evidence/control-inventory.json").read_text(encoding="utf-8"))
    tooltips=json.loads((ROOT/"AminScatter/tools/ui/layer-editor-tooltips.json").read_text(encoding="utf-8"))
    controls=[]
    for item in inventory["rows"]:
        assert set(item["capabilities"]) <= by_id.keys()
        controls.append(dict(item, help=tooltips.get(item["section"],{}).get(item["name"]),
                             remote_control="No direct UI-control invocation; consult the feature's typed plan support."))
    return dict(schema="cyrus.feature-catalog/1.0", authority="Help only. Tool dispatch, closed schemas and local approval determine authority.",
                capability_source_sha256=hashlib.sha256(source.read_bytes()).hexdigest(),
                control_inventory_sha256=inventory["source_sha256"],
                development_version="0.7.1", mcp_version="1.2.0", features=rows,controls=controls)


if __name__=="__main__":
    target=ROOT/"CyrusMCP/cyrus_mcp/feature-catalog.json"
    target.write_text(json.dumps(build(),indent=2,ensure_ascii=False)+"\n",encoding="utf-8")
    print(target)
