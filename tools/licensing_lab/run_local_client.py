"""Qualify protected local activation/renewal with a memory-only test issuer."""
from pathlib import Path
import argparse,json,re,subprocess,time,uuid,concurrent.futures,shutil
from run import ROOT,snapshot,run_command,write_json,digest,compiler_environment

def main():
    parser=argparse.ArgumentParser(description=__doc__);parser.add_argument('--run',required=True);args=parser.parse_args()
    if not re.fullmatch(r'[a-z0-9-]+',args.run):raise SystemExit('Invalid run name')
    out=ROOT/'build/licensing-local-20261005'/args.run;out.mkdir(parents=True,exist_ok=False)
    source=snapshot(out);fixtures=out/'fixtures';fixtures.mkdir()
    issuer=subprocess.Popen([str(ROOT/'build/licensing-l1-tools-2026-10-04/Scripts/python.exe'),str(source/'tools/licensing_lab/local_issuer.py')],
        stdin=subprocess.PIPE,stdout=subprocess.PIPE,stderr=subprocess.PIPE,text=True)
    watches=[];keys={};exe=None;results=[]
    def check(condition,label,**detail):
        if not condition:raise RuntimeError(label+': '+str(detail))
        results.append({'check':label,**detail});print('PASS '+label,flush=True)
    try:
        info=json.loads(issuer.stdout.readline());write_json(out/'issuer.json',info)
        public=bytes.fromhex(info['public_xy'])
        (fixtures/'lab_public_key.h').write_text('#pragma once\ninline constexpr unsigned char CyrusLabPublicXY[]={'+','.join(map(str,public))+'};\n')
        env=compiler_environment(Path('C:/Program Files/Microsoft Visual Studio/2022/Community'),'14.38.33130','10.0.19041.0')
        target=out/'native';sdk=ROOT/'build/tooling/max2027-sdk/Program Files/Autodesk/3ds Max 2027 SDK/maxsdk'
        run_command(['cmake','-S',source/'tools/licensing_lab','-B',target,'-G','NMake Makefiles','-DCMAKE_BUILD_TYPE=Release',
            '-DCYRUS_BUILD_LICENSING_LAB=ON','-DCYRUS_BUILD_LOCAL_CLIENT_LAB=ON',f'-DCYRUS_SIGNED_FIXTURES={fixtures}',
            '-DCYRUS_MAX_YEAR=2027',f'-DMAXSDK_ROOT={sdk}'],out/'configure',env)
        run_command(['cmake','--build',target],out/'build',env,timeout=600)
        run_command(['ctest','--test-dir',target,'--output-on-failure','-V'],out/'tests',env)
        exe=target/'CyrusLocalClientLab.exe'
        for device in ['a','b']:keys[device]='CyrusLicensing-PRIVATE-TEST-'+uuid.uuid4().hex
        def command(action,device='a',file=None,expected=0):
            cmd=[str(exe),action,str(out/('device-'+device)),keys[device]]
            if file:cmd.append(str(file))
            r=subprocess.run(cmd,capture_output=True,text=True,timeout=15)
            if r.returncode!=expected:raise RuntimeError(f'{action}: {r.returncode} {r.stderr}')
            return json.loads(r.stdout if r.returncode==0 else r.stderr)
        def issue(request,duration):
            issuer.stdin.write(json.dumps({'request':request,'duration':duration})+'\n');issuer.stdin.flush()
            reply=json.loads(issuer.stdout.readline())
            if 'error' in reply:raise RuntimeError(reply['error'])
            return reply
        request=command('request');write_json(out/'device-request.json',request)
        check(command('status')['reason']=='authority_absent','request_is_not_authority')
        reply=issue(request,6)
        response=out/'activation.response';response.write_text(reply['response'])
        check(command('activate',file=response)['allowed'],'real_key_proof_and_authenticated_activation')
        check('No pending' in command('activate',file=response,expected=1)['error'],'activation_response_cannot_replay')
        for i in range(2):
            p=subprocess.Popen([str(exe),'watch',str(out/'device-a'),keys['a']],stdin=subprocess.PIPE,stdout=subprocess.PIPE,stderr=subprocess.PIPE,text=True)
            watches.append(p);check(json.loads(p.stdout.readline())['allowed'],'process_'+str(i)+'_shares_activation')
        deadline=reply['expires']+1
        while time.time()<deadline:time.sleep(min(.5,deadline-time.time()))
        for i,p in enumerate(watches):
            p.stdin.write('status\n');p.stdin.flush();status=json.loads(p.stdout.readline())
            check(status['reason']=='expired','prolonged_process_'+str(i)+'_expires_without_network')
        renewed=issue(request,3600);renewal=out/'renewal.license';renewal.write_text(renewed['license'])
        check(command('renew',file=renewal)['allowed'],'verified_renewal_import_restores_authoring')
        for i,p in enumerate(watches):
            p.stdin.write('refresh\n');p.stdin.flush();status=json.loads(p.stdout.readline())
            check(status['allowed'] and status['device']==request['device'],'process_'+str(i)+'_refreshes_same_installation')
        invalid=out/'invalid.license';invalid.write_text(renewed['license'][:-1]+'!')
        check(bool(command('renew',file=invalid,expected=1)['error']),'malformed_replacement_denied')
        check(command('status')['allowed'],'rejected_import_preserves_persisted_grant')
        probe=command('io-probe');write_json(out/'contended-io-probe.json',probe)
        check(probe['overlapping_io'] and probe['elapsed_ms']<250,'disk_contention_does_not_block_decisions',**probe)
        probe=command('decision-probe');write_json(out/'decision-benchmark.json',probe)
        check(probe['allowed']==900000,'real_clock_permit_microbenchmark_completes',**probe)
        request_b=command('request','b');write_json(out/'device-b-request.json',request_b)
        check(request_b['device']!=request['device'],'different_installation_has_different_device_key')
        check(bool(command('activate','b',response,expected=1)['error']),'copied_activation_response_denied')
        reply_b=issue(request_b,3600);response_b=out/'device-b.response';response_b.write_text(reply_b['response'])
        check(command('activate','b',response_b)['allowed'],'independent_development_device_B_activated')
        check(bool(command('renew','b',renewal,expected=1)['error']),'copied_device_A_license_denied_on_B')
        check(command('status','a')['allowed'] and command('status','b')['allowed'],
              'B08_demo_immediate_second_issuance_leaves_two_valid_offline_grants',
              note='Test issuer has no seat ledger; portal deletion cannot revoke device A offline authority')
        local=target/'policy/license_local_tests.exe';counter=out/'interprocess-state'
        def increment(_):
            result=subprocess.run([str(local),'increment',str(counter)],capture_output=True,text=True,timeout=15)
            if result.returncode:raise RuntimeError(result.stderr)
        with concurrent.futures.ThreadPoolExecutor(max_workers=8) as pool:list(pool.map(increment,range(32)))
        value=subprocess.check_output([str(local),'read',str(counter)],text=True).strip()
        check(value=='32 32','32_transactions_across_processes_have_no_lost_updates')
        write_json(out/'result.json',{'status':'PASS','checks':results,'binary_sha256':digest(exe),
            'development_only':True,'real_key_and_dpapi':True,'authenticated_clock_anchor':True,
            'host':'Native CLI processes on Windows; not Max integration or cross-user hardware attestation',
            'limitations':['No customer authentication/seat service','Software key does not defeat local-admin extraction',
                           'Whole protected-state replay across restarts remains possible','Offline transfer overlap needs policy']})
    finally:
        for p in watches:
            if p.poll() is None:
                p.stdin.write('quit\n');p.stdin.flush();p.wait(timeout=10)
        if exe and exe.exists():
            for device,name in keys.items():
                r=subprocess.run([str(exe),'delete-test-key',str(out/('device-'+device)),name],capture_output=True,text=True,timeout=15)
                if r.returncode:print('TEST KEY CLEANUP FAILED '+name,flush=True)
        issuer.stdin.close();issuer.wait(timeout=10)
    print('PASS protected local client: '+str(out),flush=True)

if __name__=='__main__':main()
