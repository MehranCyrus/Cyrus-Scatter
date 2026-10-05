"""Generate development-only ES256 licenses with an ephemeral Python issuer.

Only public keys and test tokens are written. No issuer private key is saved.
This is not a customer issuance service or a seat-allocation authority.
"""
from pathlib import Path
import argparse
import base64
import hashlib
import json
import uuid

import cryptography
from cryptography.hazmat.backends.openssl.backend import backend
from cryptography.hazmat.primitives import hashes
from cryptography.hazmat.primitives.asymmetric import ec, utils

START = 1800000000
END = START + 3600
KID = 'cyrus-ephemeral-lab-key'
TYPE = 'cyrus-license-lab+jwt'
DEVICE = 'a' * 64


def b64(data):
    return base64.urlsafe_b64encode(data).rstrip(b'=').decode('ascii')


def compact(value):
    return json.dumps(value, separators=(',', ':'), ensure_ascii=True).encode('utf-8')


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('output', type=Path)
    args = parser.parse_args()
    args.output.mkdir(parents=True, exist_ok=False)
    issuer = ec.generate_private_key(ec.SECP256R1())
    wrong_issuer = ec.generate_private_key(ec.SECP256R1())
    header = {'alg': 'ES256', 'typ': TYPE, 'kid': KID}
    claims = {'v': 1, 'iss': 'urn:cyrus:license-lab', 'aud': 'cyrus-license-lab',
              'jti': 'a1111111-2222-4333-8444-555555555555', 'sub': 'lab-account',
              'tenant': 'lab-studio', 'product': 'cyrus-scatter', 'device': DEVICE,
              'nbf': START, 'exp': END, 'build_max': 7, 'rights': ['author'],
              'mode': 'assigned_device'}

    def sign(h=None, p=None, key=None):
        h = header if h is None else h
        p = claims if p is None else p
        message = (b64(h if isinstance(h, bytes) else compact(h)) + '.' +
                   b64(p if isinstance(p, bytes) else compact(p))).encode('ascii')
        signer = key or issuer
        der = signer.sign(message, ec.ECDSA(hashes.SHA256()))
        signer.public_key().verify(der, message, ec.ECDSA(hashes.SHA256()))
        r, s = utils.decode_dss_signature(der)
        return message.decode('ascii') + '.' + b64(r.to_bytes(32, 'big') + s.to_bytes(32, 'big'))

    active = sign()
    renewed = sign(p={**claims, 'exp': END + 3600, 'jti': str(uuid.uuid4())})
    wrong_device = sign(p={**claims, 'device': 'b' * 64})
    parts = active.split('.')
    tampered = '.'.join([parts[0], b64(compact({**claims, 'exp': END + 999999})), parts[2]])
    transferred = sign(p={**claims, 'device': 'b' * 64, 'jti': str(uuid.uuid4())})
    samples = {'active': active, 'renewed': renewed, 'tampered': tampered, 'wrong-device': wrong_device,
               'transferred': transferred}
    for name, token in samples.items():
        (args.output / (name + '.license')).write_text(token, encoding='ascii')

    cases = []

    def case(name, token, verify='verified', install=None, group='profile', **extra):
        install = verify if install is None else install
        cases.append({'name': name, 'token': token, 'verify': verify, 'install': install,
                      'group': group, 'now': START + 100, 'allowed': install == 'verified', **extra})

    case('active', active)
    case('signed_whitespace_and_key_order', sign(h=json.dumps(dict(reversed(list(header.items())))).encode(),
                                               p=json.dumps(dict(reversed(list(claims.items()))), indent=2).encode()))
    case('empty', '', 'size')
    case('oversized', 'A' * 8193, 'size')
    case('missing_segment', '.'.join(parts[:2]), 'encoding')
    case('extra_segment', active + '.AA', 'encoding')
    case('empty_segment', parts[0] + '..' + parts[2], 'encoding')
    case('padded_base64', active + '=', 'encoding')
    case('ordinary_base64_character', '+' + active[1:], 'encoding')
    case('trailing_newline', active + '\n', 'encoding')
    case('embedded_nul', active[:10] + '\0' + active[10:], 'encoding')
    alphabet = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_'
    last = alphabet.index(parts[2][-1])
    assert last % 16 == 0
    case('noncanonical_pad_bits', active[:-1] + alphabet[last + 1], 'encoding')
    for key, value in [('alg', 'none'), ('alg', 'HS256'), ('alg', 'ES384'), ('typ', 'JWT'),
                       ('typ', 'cyrus-refresh+jwt'), ('kid', '../other-key')]:
        case('header_' + key + '_' + value, sign(h={**header, key: value}), 'header')
    for key, value in [('jku', 'https://invalid.example/keys'), ('jwk', {}),
                       ('x5u', 'https://invalid.example/key'), ('crit', ['unknown']), ('b64', False)]:
        case('forbidden_header_' + key, sign(h={**header, key: value}), 'header')
    case('missing_header_field', sign(h={'alg': 'ES256', 'kid': KID}), 'header')
    case('unknown_kid', sign(h={**header, 'kid': 'not-trusted'}), 'untrusted_key')
    case('duplicate_header', sign(h=compact(header)[:-1] + b',"alg":"ES256"}'), 'json')
    case('oversized_header', sign(h={**header, 'padding': 'a' * 1200}), 'size')

    case('payload_tamper', tampered, 'signature', group='signature')
    case('wrong_signing_key', sign(key=wrong_issuer), 'signature', group='signature')
    raw = base64.urlsafe_b64decode(parts[2] + '==')
    for i in range(64):
        changed = bytearray(raw); changed[i] ^= 1
        case(f'signature_bitflip_{i}', '.'.join(parts[:2]) + '.' + b64(changed), 'signature', group='signature')
    for name, sig in [('zero', bytes(64)), ('short', raw[:-1]), ('long', raw + b'\0'),
                      ('der', utils.encode_dss_signature(int.from_bytes(raw[:32], 'big'), int.from_bytes(raw[32:], 'big')))]:
        case('signature_' + name, '.'.join(parts[:2]) + '.' + b64(sig), 'signature', group='signature')
    # JWA ES256 permits both s and order-s. A grant's jti, not signature bytes,
    # must identify it in future issuance/replay accounting.
    order = int('ffffffff00000000ffffffffffffffffbce6faada7179e84f3b9cac2fc632551', 16)
    alternate = raw[:32] + (order - int.from_bytes(raw[32:], 'big')).to_bytes(32, 'big')
    issuer.public_key().verify(utils.encode_dss_signature(int.from_bytes(alternate[:32], 'big'),
        int.from_bytes(alternate[32:], 'big')), '.'.join(parts[:2]).encode(), ec.ECDSA(hashes.SHA256()))
    case('equivalent_ecdsa_signature', '.'.join(parts[:2]) + '.' + b64(alternate), group='signature')

    invalid = [('v', 2), ('v', 1.0), ('v', True), ('iss', 'urn:not:cyrus'), ('aud', ['cyrus-license-lab']),
               ('aud', 'other-app'), ('mode', 'floating'), ('product', 'other-product'), ('jti', ''),
               ('jti', '00000000-0000-0000-0000-000000000000'), ('sub', ''), ('tenant', ''),
               ('device', 'a' * 63), ('device', 'A' * 64), ('rights', ['author', 'admin']),
               ('rights', 'author'), ('rights', []), ('rights', ['author', 'author']),
               ('nbf', -1), ('nbf', START + 0.5), ('exp', END + 0.5), ('exp', str(END)),
               ('exp', True), ('exp', START), ('exp', START - 1), ('exp', 2**64-1),
               ('build_max', 0), ('build_max', -1), ('build_max', 2**32), ('build_max', 7.0)]
    for i, (key, value) in enumerate(invalid):
        case(f'claim_{key}_{i}', sign(p={**claims, key: value}), 'claims', group='claims')
    case('unknown_claim', sign(p={**claims, 'admin': True}), 'claims', group='claims')
    case('missing_claim', sign(p={k: v for k, v in claims.items() if k != 'device'}), 'claims', group='claims')
    case('duplicate_claim', sign(p=compact(claims)[:-1] + b',"exp":1800003600}'), 'json', group='claims')
    case('escaped_duplicate_claim', sign(p=compact(claims)[:-1] + b',"\\u0065xp":1800003600}'), 'json', group='claims')
    for name, payload in [('trailing_json', compact(claims) + b'{}'), ('comments', b'/*hi*/' + compact(claims)),
                          ('bad_utf8', b'{"x":"\xff"}'), ('bom', b'\xef\xbb\xbf' + compact(claims)),
                          ('deep', b'[' * 8 + b'0' + b']' * 8), ('bad_json', b'{')]:
        case(name, sign(p=payload), 'json', group='claims')
    case('array_payload', sign(p=[]), 'claims', group='claims')
    case('oversized_payload', sign(p={**claims, 'padding': 'a' * 4300}), 'size', group='claims')

    case('wrong_device', wrong_device, install='device', group='scope')
    case('wrong_account', sign(p={**claims, 'sub': 'someone-else'}), install='scope', group='scope')
    case('wrong_tenant', sign(p={**claims, 'tenant': 'another-studio'}), install='scope', group='scope')
    case('wrong_product', sign(p={**claims, 'product': 'cyrus-analyzer'}), install='scope', group='scope')
    case('unsupported_build', sign(p={**claims, 'build_max': 6}), install='build', group='scope')
    case('expiry_boundary', active, group='scope', now=END, allowed=False)
    case('before_start', active, group='scope', now=START-1, allowed=False)
    case('renewed', renewed, group='scope', now=END+100, allowed=True)

    activation_header={**header,'typ':TYPE+'.activation'}
    activation_claims={'v':1,'iss':claims['iss'],'aud':claims['aud'],'nonce':'c'*64,
                       'device':DEVICE,'server_utc':START+100,'license':active}
    activation_cases=[]
    def activation_case(name,p=None,h=None,error='verified',key=None,nested_valid=True):
        activation_cases.append({'name':name,'token':sign(h=activation_header if h is None else h,
            p=activation_claims if p is None else p,key=key),'error':error,'nested_valid':nested_valid})
    activation_case('valid')
    activation_case('wrong_purpose',h=header,error='header')
    activation_case('wrong_signer',key=wrong_issuer,error='signature')
    for field,value in [('v',2),('v',1.0),('iss','other'),('aud','other'),('nonce','d'*64),
                        ('device','b'*64),('server_utc',0),('server_utc',-1),('server_utc',1.5),
                        ('server_utc',True),('server_utc',253402300800),('license',[]),('license',None)]:
        activation_case('invalid_'+field+'_'+str(value),p={**activation_claims,field:value},error='claims')
    activation_case('duplicate_nonce',p=compact(activation_claims)[:-1]+b',"nonce":"'+b'c'*64+b'"}',error='json')
    activation_case('unknown_claim',p={**activation_claims,'admin':True},error='claims')
    activation_case('missing_nonce',p={k:v for k,v in activation_claims.items() if k!='nonce'},error='claims')
    activation_case('oversized',p={**activation_claims,'license':'a'*4300},error='size')
    activation_case('nested_tampered_license',p={**activation_claims,'license':tampered},nested_valid=False)

    public = issuer.public_key().public_numbers()
    xy = public.x.to_bytes(32, 'big') + public.y.to_bytes(32, 'big')
    generated = ('#pragma once\n#ifndef CYRUS_SIGNED_LICENSE_LAB_ONLY\n#error Test issuer must never ship\n#endif\n' +
                 'inline constexpr unsigned char CyrusLabPublicXY[64] = {' + ','.join(str(b) for b in xy) + '};\n')
    (args.output / 'lab_public_key.h').write_text(generated, encoding='ascii')
    (args.output / 'vectors.json').write_text(json.dumps({'cases': cases, 'samples': samples,'activation_cases':activation_cases}, indent=2), encoding='utf-8')
    metadata = {'cryptography': cryptography.__version__, 'openssl': backend.openssl_version_text(),
                'algorithm': 'ES256 / P-256 / SHA-256', 'profile': 'lab only, JWS compact',
                'public_xy_sha256': hashlib.sha256(xy).hexdigest(), 'private_key_persisted': False,
                'cases': len(cases), 'activation_cases':len(activation_cases), 'term_values': [START, END], 'synthetic_device_id': DEVICE}
    (args.output / 'issuer.json').write_text(json.dumps(metadata, indent=2), encoding='utf-8')
    print(json.dumps(metadata, indent=2))


if __name__ == '__main__':
    main()
