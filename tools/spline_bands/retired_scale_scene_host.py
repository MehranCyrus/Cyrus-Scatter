"""Reject an owned schema-57 witness without changing its original bytes."""
from pathlib import Path
import hashlib,json,traceback,uuid
from pymxs import runtime as r

ROOT=Path(__file__).resolve().parents[2]
OUT=Path(str(r.MCPFixtureDir)).resolve()
if OUT.parent!=ROOT/'build/mcp-qualification' or not OUT.name.startswith('foundation-spline-'):
    raise RuntimeError('Owned spline host required')
year=json.loads((OUT/'launch.json').read_text(encoding='utf-8'))['max_year']
source=ROOT/f'build/mcp-qualification/foundation-spline-ui-simplification-{year}-final-01/source-conversion.max'
before=hashlib.sha256(source.read_bytes()).hexdigest()
receipt=OUT/('retired-scale-scene-'+uuid.uuid4().hex+'.json')
report={'source':str(source),'source_sha256':before,'checks':[]}
def check(value,label):
    report['checks'].append({'passed':bool(value),'label':label})
    if not value:raise AssertionError(label)
try:
    r.resetMaxFile(r.Name('noPrompt'))
    try:r.loadMaxFile(str(source),quiet=True)
    except Exception as error:report['load_exception']=str(error)
    node=r.getNodeByName('Source conversion regression')
    check(node is not None,'Owned schema-57 witness was read')
    check(not bool(node.baseObject.procSchemaValid),'Old scene remains persistently invalid')
    denied=False
    try:node.baseObject.evaluateProcedural()
    except Exception as error:
        report['evaluation_exception']=str(error)
        denied='schema 58' in str(error) and 'Create a new' in str(error)
    check(denied,'Evaluation rejects schema 57 with actionable guidance')
    check(hashlib.sha256(source.read_bytes()).hexdigest()==before,'Original schema-57 bytes remain unchanged')
    report['passed']=True
except Exception:
    report['passed']=False;report['error']=traceback.format_exc()
finally:
    receipt.write_text(json.dumps(report,indent=2)+'\n',encoding='utf-8')
    r.resetMaxFile(r.Name('noPrompt'))
if not report['passed']:raise RuntimeError(report['error'])
