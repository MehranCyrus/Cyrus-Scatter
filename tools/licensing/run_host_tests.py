"""Exercise actual offline license lifecycle in an already-owned Max process."""
import argparse,json,sys,time,uuid
from pathlib import Path
ROOT=Path(__file__).resolve().parents[2]
sys.path.insert(0,str(ROOT/'tools/procedural_lab'))
from runtime_driver import run_script
import issuer

p=argparse.ArgumentParser();p.add_argument('--host',required=True);p.add_argument('--issuer',type=Path,required=True)
a=p.parse_args();folder=ROOT/'build/mcp-qualification'/a.host
if folder.resolve().parent!=ROOT/'build/mcp-qualification':raise SystemExit('Invalid owned host')
if (issuer.DEFAULT_STORE/'issuer.dpapi').exists() and issuer.public_metadata(a.issuer)['kid']==issuer.public_metadata(issuer.DEFAULT_STORE)['kid']:
    raise SystemExit('Refusing short test grants from the real owner authority; use a separate test issuer')
def run(script):
    result=run_script(folder,script,timeout=180)
    print(result,flush=True)
    if not result.startswith('SUCCESS'):raise RuntimeError('Host assertion failed')
def ms(path):return '@"'+Path(path).as_posix()+'"'

run('fileIn '+ms(ROOT/'tools/licensing/host_fixture.ms'))
run('LTAssert (not cyrusLicenseAllows()) "Missing license denies authoring"\n'
    'local empty=createInstance AminScatterObject,denied=false\ntry(empty.newLayer())catch(denied=true)\n'
    'LTAssert (denied and empty.layerObjects.count==0) "Missing license permits empty host shell but denies scatter creation"\n'
    'CyrusOpenLicenseDialog()\nCyrusLicenseDialog.saveRequest '+ms(folder/'request.json'))
request=issuer.validate_request((folder/'request.json').read_bytes())
kid,key=issuer.load_key(a.issuer)
now=int(time.time())
def grant(start,end,device=None):
    return issuer.sign(key,kid,dict(v=1,iss=issuer.ISSUER,aud=issuer.AUDIENCE,jti=str(uuid.uuid4()),
        sub='team-seat',tenant='cyrus-team',product='cyrus-scatter',device=device or request['device'],
        nbf=start,exp=end,build_max=79,rights=['author'],mode='assigned_device'))
for name,token in [('expired',grant(now-100,now-10)),('other-device',grant(now,now+60,'0'*64)),
                   ('signature','invalid.license.signature')]:
    path=folder/(name+'.cyruslicense');path.write_text(token)
    run('local denied=false\ntry(CyrusLicenseDialog.importLicense '+ms(path)+')catch(denied=true)\n'
        'LTAssert (denied and not cyrusLicenseAllows()) "Rejected '+name+' license without unlocking"')
# The short term exists only in this test authority's fixtures. The owner GUI
# and normal issue command always issue exactly 30 days.
start=int(time.time());end=start+90
active=folder/'short-test.cyruslicense';active.write_text(grant(start,end))
run('CyrusLicenseDialog.importLicense '+ms(active)+'\nLTAssert (cyrusLicenseAllows()) "Native import admits correct installation"\nLTCreate()')
run('cyrusBrushSettings LTArea.paintDocument 8 true\n'
    'LTAssert (cyrusBrushDab LTArea.paintDocument [0,0,100] [0,0,-1] false) "Begin staged stroke before expiry"\n'
    'LTAssert ((cyrusBrushStats LTArea.paintDocument)[6]==1) "Stroke remains staged"')
time.sleep(32)
run('LTAssert (cyrusBrushDab LTArea.paintDocument [2,0,100] [0,0,-1] true) "Active stroke over 30 seconds commits"\n'
    'LTAssert ((cyrusBrushStats LTArea.paintDocument)[6]==0) "Long stroke clears staging"\n'
    'cyrusBrushFill LTArea.paintDocument 1\nLTRoot.refreshAll()\n'
    'LTAssert (LTFingerprint()==LTExpected) "Long stroke reset retains baseline publication"\n'
    'cyrusBrushDab LTArea.paintDocument [0,0,100] [0,0,-1] false')
print('Waiting for the real signed test deadline; no fake clock is used',flush=True)
while time.time()<=end:time.sleep(min(.5,end+1-time.time()))
run('LTLocked()')
now=int(time.time());late=folder/'delayed.cyruslicense';late.write_text(grant(now-86400,now-86400+issuer.TERM_SECONDS))
run('CyrusOpenLicenseDialog()\nCyrusLicenseDialog.importLicense '+ms(late)+'\n'
    'LTAssert (cyrusLicenseAllows()) "Delayed file import renews without fresh online time anchor"\n'
    'LTAssert ((cyrusLicenseStatus())[4]=='+str(now-86400+issuer.TERM_SECONDS)+'L) "Import preserves signed expiry rather than starting a fresh month"\n'
    'LTLayer.amount=110\nLTRoot.refreshAll()\nLTAssert (LTRoot.groupSnapshotRows[1].count==110) "Renewal restores existing layer editing"')
(folder/'lifecycle.json').write_text(json.dumps({'passed':True,'short_test_expiry':end,'delayed_license_expiry':now-86400+issuer.TERM_SECONDS},indent=2))
print('PASS licensed/expired/reopened/renewed host lifecycle',flush=True)
