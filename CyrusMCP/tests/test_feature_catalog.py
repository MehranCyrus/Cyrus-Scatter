import json
import re
from pathlib import Path


def test_catalog_accounts_for_every_current_control_and_feature_family():
    root=Path(__file__).resolve().parents[2]
    catalog=json.loads((root/"CyrusMCP/cyrus_mcp/feature-catalog.json").read_text(encoding="utf-8"))
    inventory=json.loads((root/"AminScatter/tools/ui/layers-control-inventory.json").read_text(encoding="utf-8"))
    expected={(group,section,c["name"],c["kind"]) for group,sections in inventory.items() if isinstance(sections,dict)
              for section,controls in sections.items() for c in controls}
    actual={(c["group"],c["section"],c["name"],c["kind"]) for c in catalog["controls"]}
    assert expected==actual
    assert len(actual)==len(catalog["controls"]),"Feature catalog contains duplicate controls"
    assert catalog['development_version']==re.search(r'project\(CyrusScatter VERSION ([0-9.]+)',(root/'AminScatter/CMakeLists.txt').read_text())[1]
    assert catalog['calculation_model']=='CyrusUnified2'
    features={f["feature_id"] for f in catalog["features"]}
    assert features=={f"C{i:02}" for i in range(1,38)}
    assert all(set(c["capabilities"])<=features and c["remote_control"] for c in catalog["controls"])
