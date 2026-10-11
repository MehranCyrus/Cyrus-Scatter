"""Check the exact owner builds; use only the explicitly named private profiles."""
import argparse,json,sys,time
from pathlib import Path
ROOT=Path(__file__).resolve().parents[2]
sys.path.insert(0,str(ROOT/'tools/procedural_lab'))
from runtime_driver import run_script
import issuer

def main():
    p=argparse.ArgumentParser();p.add_argument('--host26',required=True);p.add_argument('--host27',required=True)
    p.add_argument('--fixture26',required=True);p.add_argument('--fixture27',required=True)
    p.add_argument('--reuse-license',action='store_true');a=p.parse_args()
    def folder(name):
        if Path(name).name!=name or name in ('.','..'):raise ValueError('Expected owned profile name')
        return ROOT/'build/mcp-qualification'/name
    def ms(path):return '@"'+Path(path).as_posix()+'"'
    def run(f,script):
        result=run_script(f,script,timeout=180);print(result,flush=True)
        if not result.startswith('SUCCESS'):raise RuntimeError('Host assertion failed')
    hosts=[folder(a.host26),folder(a.host27)]
    for f,fixture in zip(hosts,[folder(a.fixture26),folder(a.fixture27)]):
        run(f,'fileIn '+ms(ROOT/'tools/licensing/host_fixture.ms'))
        initial=('LTAssert (cyrusLicenseAllows()) "Owner build reopens existing valid license"\n' if a.reuse_license else
                 'LTAssert (not cyrusLicenseAllows()) "Owner build starts locked without a license"\n')
        locked=('' if a.reuse_license else 'local amount=LTLayer.amount\nLTLayer.amount=999\n'
                'LTAssert (LTLayer.amount==amount) "Missing owner license prevents direct scalar edit"\n')
        run(f,initial+
            'loadMaxFile '+ms(fixture/'licensed.max')+' quiet:true\nLTBind();LTRoot.refreshDisplay()\n'
            'LTExpected=LTRead '+ms(fixture/'fingerprint.txt')+'\n'
            'LTAssert (LTFingerprint()==LTExpected) "Owner build cold-opens complete saved scene"\n'+locked+
            'LTRender (MCPFixtureDir+"before-import.png")')
    primary=hosts[1];request=primary/'owner-request.json';license=primary/'owner.cyruslicense'
    run(primary,'CyrusOpenLicenseDialog();CyrusLicenseDialog.saveRequest '+ms(request))
    result=issuer.issue(issuer.DEFAULT_STORE,request.read_bytes(),'Local private Max 2026/2027 qualification')
    license.write_text(result['license'],encoding='ascii')
    run(primary,'CyrusLicenseDialog.importLicense '+ms(license)+'\n'
        'CyrusLicenseDialog.importLicense '+ms(license)+'\n'
        'LTAssert (cyrusLicenseAllows()) "Owner-issued 30-day license imports and repeats safely"\n'
        'LTAssert ((cyrusLicenseStatus())[4]=='+str(result['expires'])+'L) "Owner issuance deadline is preserved"')
    print('Waiting for the second already-open Max to observe activation',flush=True)
    deadline=time.monotonic()+75
    while time.monotonic()<deadline:
        path=hosts[0]/'observed.txt'
        run(hosts[0],'local f=createFile (MCPFixtureDir+"observed.txt");format "%|%" (cyrusLicenseAllows()) (cyrusLicenseStatus())[4] to:f;close f')
        observed=path.read_text().strip().split('|')
        if observed[0]=='true' and observed[1].rstrip('L')==str(result['expires']):break
        time.sleep(5)
    else:raise RuntimeError('Second Max did not observe activation')
    for f in hosts:
        run(f,'LTAssert (cyrusLicenseAllows()) "Already-open owner host observes shared activation"\n'
            'LTRender (MCPFixtureDir+"licensed.png")\n'
            'LTLayer.amount=110;LTRoot.refreshAll()\n'
            'LTAssert (LTRoot.groupSnapshotRows[1].count==110) "Owner license enables current authoring"')
        (f/'owner-smoke.json').write_text(json.dumps({'passed':True,'issued':result['issued'],'expires':result['expires'],
            'term_seconds':result['expires']-result['issued'],'initially_licensed':a.reuse_license},indent=2))

if __name__=='__main__':main()
