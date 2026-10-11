"""Offline owner issuance contract; temporary authorities never enter packages."""
import base64
import hashlib
import importlib.util
import json
import os
from pathlib import Path
from unittest.mock import patch

import pytest
pytest.importorskip('cryptography')
from cryptography.hazmat.primitives import hashes
from cryptography.hazmat.primitives.asymmetric import ec,utils

ROOT=Path(__file__).resolve().parents[2]
spec=importlib.util.spec_from_file_location('team_issuer',ROOT/'tools/licensing/issuer.py')
issuer=importlib.util.module_from_spec(spec);spec.loader.exec_module(issuer)
pytestmark=pytest.mark.skipif(os.name!='nt',reason='DPAPI owner store requires Windows')

def request():
    key=ec.generate_private_key(ec.SECP256R1());public=issuer.xy(key)
    value=dict(issuer.CONTEXT,device=hashlib.sha256(b'cyrus-installation-p256-v1:'+public).hexdigest(),
               nonce='a'*64,public_xy=public.hex())
    challenge='|'.join(value[k] for k in ['nonce','subject','tenant','product'])
    r,s=utils.decode_dss_signature(key.sign(('cyrus-device-proof-v1:'+challenge).encode(),ec.ECDSA(hashes.SHA256())))
    value['proof']=(r.to_bytes(32,'big')+s.to_bytes(32,'big')).hex()
    return value

def decode(token):
    return [base64.urlsafe_b64decode(part+'='*(-len(part)%4)) for part in token.split('.')]

def test_key_persists_and_cannot_be_silently_replaced(tmp_path):
    before=issuer.initialize(tmp_path)
    assert issuer.public_metadata(tmp_path)==before
    with pytest.raises(FileExistsError):issuer.initialize(tmp_path)
    assert issuer.public_metadata(tmp_path)==before
    issuer.export_header(tmp_path,tmp_path/'team_public_key.h')
    header=(tmp_path/'team_public_key.h').read_text()
    assert before['kid'] in header and 'private_der' not in header

def test_fixed_issuance_deadline_signature_and_retry(tmp_path):
    issuer.initialize(tmp_path);data=json.dumps(request()).encode()
    with patch.object(issuer.time,'time',return_value=2000000000):
        first=issuer.issue(tmp_path,data,'Team member')
    with patch.object(issuer.time,'time',return_value=2000009000):
        retry=issuer.issue(tmp_path,data,'Team member')
    assert retry['license']==first['license'] and retry['repeated_request']
    header,payload,signature=decode(first['license']);claims=json.loads(payload)
    assert claims['nbf']==2000000000 and claims['exp']==2000000000+2592000
    _,key=issuer.load_key(tmp_path)
    key.public_key().verify(utils.encode_dss_signature(int.from_bytes(signature[:32],'big'),
        int.from_bytes(signature[32:],'big')),first['license'].rsplit('.',1)[0].encode(),ec.ECDSA(hashes.SHA256()))
    with patch.object(issuer.time,'time',return_value=1999999900):
        with pytest.raises(ValueError,match='backwards'):issuer.issue(tmp_path,json.dumps(request()).encode(),'Another member')

@pytest.mark.parametrize('field,value',[('device','0'*64),('nonce','0'*64),('subject','another-account'),
                                     ('product','cyrus-analyzer'),('proof','0'*128),('public_xy','0'*128)])
def test_tampered_requests_rejected(field,value):
    data=request();data[field]=value
    with pytest.raises(Exception):issuer.validate_request(json.dumps(data).encode())

def test_ambiguous_and_oversized_requests_rejected():
    data=json.dumps(request())
    with pytest.raises(ValueError):issuer.validate_request(('{"device":"x",'+data[1:]).encode())
    with pytest.raises(ValueError):issuer.validate_request(b' '*16385)

def test_encrypted_backup_restores_same_authority_without_overwriting(tmp_path):
    original=tmp_path/'original';restored=tmp_path/'restored';backup=tmp_path/'private.cyrusissuer'
    public=issuer.initialize(original);password='Test-only passphrase 079!'
    issuer.backup(original,backup,password)
    assert 'private_der' not in backup.read_text()
    with pytest.raises(ValueError):issuer.restore(restored,backup.read_bytes(),'wrong password')
    assert not (restored/'issuer.dpapi').exists()
    assert issuer.restore(restored,backup.read_bytes(),password)==public
    with pytest.raises(FileExistsError):issuer.restore(restored,backup.read_bytes(),password)
    with pytest.raises(FileExistsError):issuer.backup(original,backup,password)
    with pytest.raises(ValueError):issuer.backup(original,tmp_path/'weak.cyrusissuer','weak')
