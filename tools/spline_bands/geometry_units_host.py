"""Physical Sharp geometry stays equivalent across system-unit configurations."""
from pathlib import Path
import hashlib
import json
import math
import traceback
import uuid
from pymxs import runtime as r

ROOT = Path(__file__).resolve().parents[2]
OUT = Path(str(r.MCPFixtureDir)).resolve()
if OUT.parent != ROOT / 'build/mcp-qualification' or not OUT.name.startswith('foundation-spline-'):
    raise RuntimeError('Owned spline host required')
report = {'checks': [], 'cases': [], 'fixture_sha256': hashlib.sha256(Path(__file__).read_bytes()).hexdigest(),
          'launch': json.loads((OUT / 'launch.json').read_text())}
receipt = OUT / ('geometry-units-' + uuid.uuid4().hex + '.json')
old_type, old_scale = r.units.SystemType, r.units.SystemScale


def save():
    receipt.write_text(json.dumps(report, indent=2) + '\n', encoding='utf-8')


def check(ok, label):
    report['checks'].append({'passed': bool(ok), 'label': label}); save()
    if not ok: raise AssertionError(label)


try:
    r.resetMaxFile(r.Name('noPrompt'))
    script = ROOT / 'AminScatter/scripts/AminScatterObject.ms'
    report['script_sha256'] = hashlib.sha256(script.read_bytes()).hexdigest()
    r.fileIn(str(script))
    reference = None
    for unit in ('Millimeters', 'Centimeters', 'Meters', 'Inches'):
        r.resetMaxFile(r.Name('noPrompt')); r.units.SystemType = r.Name(unit); r.units.SystemScale = 1
        r.execute('''(
global UnitsNode=AminScatterObject name:"Physical Sharp fixture"
global UnitsRoot=UnitsNode.baseObject
UnitsRoot.updateMode=1;UnitsRoot.autoRender=false;UnitsRoot.newLayer()
global UnitsLeaf=UnitsRoot.selectedLayer()
local receiver=plane width:(units.decodeValue "508cm") length:(units.decodeValue "508cm") widthsegs:1 lengthsegs:1
local model=box width:(units.decodeValue "2.54cm") length:(units.decodeValue "2.54cm") height:(units.decodeValue "5.08cm")
local path=rectangle width:(units.decodeValue "254cm") length:(units.decodeValue "254cm") cornerRadius:(units.decodeValue "5.08cm")
UnitsRoot.setLayerSurfaces UnitsLeaf #(receiver)
UnitsLeaf.sources=#(model);UnitsLeaf.amount=10000;UnitsLeaf.diversityMode=3
UnitsLeaf.procReceiverNodes=#(receiver);UnitsLeaf.procReceiverIDs=#("physical-unit-receiver")
UnitsLeaf.randomSeed=37;UnitsLeaf.procSamplingSalt=0
UnitsLeaf.procSelfEnabled=false;UnitsLeaf.procLayerSelfEnabled=false
UnitsLeaf.addStroke path;UnitsLeaf.patternWidths=#(units.decodeValue "101.6cm")
UnitsLeaf.setStrokeSelection 1 2 #(model);UnitsLeaf.pathJoins[1]=2
UnitsRoot.evaluateProcedural()
)''')
        mm = float(r.units.decodeValue('1mm'))
        rows = {str(x[2]): (int(x[1]), int(x[5]), tuple(float(v)/mm for v in x[0].row4),
                           tuple(float(v) for axis in (x[0].row1, x[0].row2, x[0].row3) for v in axis))
                for x in r.UnitsRoot.groupSnapshotRows[0]}
        report['cases'].append({'units': unit, 'count': len(rows), 'field': [int(x) for x in r.UnitsLeaf.splineFieldStats()[2]]})
        check(len(rows) > 4000, unit + ': curved Sharp construction admits a nonempty physical field')
        if reference is None: reference = rows
        else:
            check(rows.keys() == reference.keys(), unit + ': identical physical scene preserves accepted candidate identities')
            check(all(row[:2] == reference[key][:2] and
                      all(math.isclose(a, b, rel_tol=2e-5, abs_tol=.02) for a,b in zip(row[2], reference[key][2])) and
                      all(math.isclose(a, b, rel_tol=2e-5, abs_tol=2e-5) for a,b in zip(row[3], reference[key][3]))
                      for key,row in rows.items()), unit + ': source, Band and complete physical transforms agree')
    report['passed'] = True
except Exception:
    report['passed'] = False; report['error'] = traceback.format_exc()
finally:
    r.resetMaxFile(r.Name('noPrompt')); r.units.SystemType = old_type; r.units.SystemScale = old_scale
    save()
if not report['passed']: raise RuntimeError(report['error'])
