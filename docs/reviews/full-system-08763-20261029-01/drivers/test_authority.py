"""Ephemeral review authority. Never loads an owner key or writes a private key."""
from pathlib import Path
import argparse, hashlib, importlib.util, json, os, time, uuid
from cryptography.hazmat.primitives.asymmetric import ec

p=argparse.ArgumentParser();p.add_argument('--root',type=Path,required=True);p.add_argument('--output',type=Path,required=True)
a=p.parse_args();root=a.root.resolve();out=a.output.resolve()
assert out.is_relative_to(root/'build')
out.mkdir(parents=True,exist_ok=False)
spec=importlib.util.spec_from_file_location('review_issuer',root/'tools/licensing/issuer.py')
issuer=importlib.util.module_from_spec(spec);spec.loader.exec_module(issuer)
key=ec.generate_private_key(ec.SECP256R1());public=issuer.xy(key)
kid='review-08763-'+uuid.uuid4().hex[:20]
(out/'team_public_key.h').write_text('#pragma once\n// TEST AUTHORITY: DO NOT PACKAGE\ninline constexpr char CyrusTeamKeyID[]="'+kid+'";\ninline constexpr unsigned char CyrusTeamPublicXY[]={'+','.join(str(b) for b in public)+'};\n')
(out/'public-authority.json').write_text(json.dumps({'kid':kid,'pid':os.getpid(),'public_sha256':hashlib.sha256(public).hexdigest(),'private_key_persisted':False,'owner_store_accessed':False},indent=2))
print('Ephemeral test authority ready',flush=True)
until=time.monotonic()+3600
while time.monotonic()<until and not (out/'stop').exists():
    for request_path in out.glob('request-*.json'):
        target=request_path.with_suffix('.test-license')
        if target.exists():continue
        request=issuer.validate_request(request_path.read_bytes());now=int(time.time())
        claims=dict(v=1,iss=issuer.ISSUER,aud=issuer.AUDIENCE,jti=str(uuid.uuid4()),sub=request['subject'],tenant=request['tenant'],product=request['product'],device=request['device'],nbf=now-1,exp=now+1800,build_max=79,rights=['author'],mode='assigned_device')
        temporary=target.with_suffix('.tmp');temporary.write_text(issuer.sign(key,kid,claims),encoding='ascii');temporary.replace(target)
        print('Issued one isolated review grant',flush=True)
    time.sleep(.25)
print('Ephemeral authority stopped',flush=True)
