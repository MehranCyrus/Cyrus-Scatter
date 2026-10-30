"""Owned Max 2027 driver; requires the isolated test-authority native build."""
from pathlib import Path
from pymxs import runtime as r
import json, time, traceback

ROOT=Path(__file__).resolve().parents[4]
OUT=Path(str(r.GardenRun))
AUTH=ROOT/'build/full-system-review-08763-20261029-01/test-authority'
result={}
try:
    assert not r.cyrusLicenseAllows(), 'Fresh test installation should start unlicensed'
    result['initial_authoring_denied']=True
    rejected=False
    try:r.cyrusLicenseImport('not-a-signed-grant')
    except Exception:rejected=True
    assert rejected and not r.cyrusLicenseAllows()
    result['malformed_import_denied']=True
    request=AUTH/'request-host.json'
    request.write_text(str(r.cyrusLicenseRequest()),encoding='utf-8')
    target=request.with_suffix('.test-license');until=time.monotonic()+45
    while not target.exists() and time.monotonic()<until:
        r.windows.processPostedMessages();time.sleep(.1)
    assert target.exists(),'Ephemeral test authority did not respond'
    r.cyrusLicenseImport(target.read_text(encoding='ascii'))
    assert r.cyrusLicenseAllows()
    result['synthetic_grant_admitted']=True
    for script,receipt in [('host_regressions.py','host-regressions.json'),('selection_smoke.py','smoke.json')]:
        path=ROOT/'tools/procedural_lab/review08763'/script
        exec(compile(path.read_text(),str(path),'exec'),{'__file__':str(path),'__name__':'__review__'})
        data=json.loads((OUT/receipt).read_text());assert data['status']=='complete',data
        result[script]='executed'
    result['status']='complete'
    (OUT/'completed.json').write_text(json.dumps(result,indent=2))
except Exception:
    result.update(status='failed',error=traceback.format_exc())
    (OUT/'error.txt').write_text(result['error'])
finally:
    (OUT/'host-review.json').write_text(json.dumps(result,indent=2))
