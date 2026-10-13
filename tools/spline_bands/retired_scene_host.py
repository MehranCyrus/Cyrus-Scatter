"""An older scene is read only to prove explicit rejection; never re-save it."""
from pathlib import Path
import hashlib
import json
import traceback
from pymxs import runtime as r

ROOT = Path(__file__).resolve().parents[2]
OUT = Path(str(r.MCPFixtureDir)).resolve()
if OUT.parent != ROOT / "build/mcp-qualification" or not OUT.name.startswith("foundation-spline-"):
    raise RuntimeError("Owned spline host required")
year = json.loads((OUT / "launch.json").read_text())["max_year"]
source = ROOT / f"build/mcp-qualification/foundation-spline-transport-{year}-01/schema56-scene.max"
before = hashlib.sha256(source.read_bytes()).hexdigest()
report = {"source": str(source), "source_sha256": before, "assertions": [], "errors": []}


def check(value, label):
    report["assertions"].append({"passed": bool(value), "label": label})
    if not value:
        raise AssertionError(label)


try:
    r.CyrusStopBrush()
    r.resetMaxFile(r.Name("noPrompt"))
    script = ROOT / "AminScatter/scripts/AminScatterObject.ms"
    report["script_sha256"] = hashlib.sha256(script.read_bytes()).hexdigest()
    r.fileIn(str(script))
    # Max may continue loading despite an update-handler exception. The
    # persisted validity flag must still prevent evaluation and requalification.
    try:
        r.loadMaxFile(str(source), quiet=True)
    except Exception as error:
        report["load_exception"] = str(error)
    node = r.getNodeByName("Schema56 spline witness")
    check(node is not None, "The retired-scene witness was read")
    root = node.baseObject
    check(not bool(root.procSchemaValid), "Retired scene remains persistently invalid")
    denied = False
    try:
        root.evaluateProcedural()
    except Exception as error:
        denied = "schema 58" in str(error) and "Create a new" in str(error)
        report["evaluation_exception"] = str(error)
    check(denied, "Evaluation rejects the retired schema with actionable guidance")
    check(hashlib.sha256(source.read_bytes()).hexdigest() == before, "Original scene bytes are preserved")
    report["passed"] = True
except Exception:
    report["passed"] = False
    report["errors"].append(traceback.format_exc())
finally:
    (OUT / "retired-scene-results.json").write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
    r.resetMaxFile(r.Name("noPrompt"))
if not report.get("passed"):
    raise RuntimeError(report["errors"][-1])
