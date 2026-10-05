"""Ephemeral, pipe-only DEVELOPMENT issuer. It has no customer auth or seats."""
import base64,hashlib,json,sys,time,uuid
import cryptography
from cryptography.hazmat.primitives import hashes
from cryptography.hazmat.primitives.asymmetric import ec,utils

key=ec.generate_private_key(ec.SECP256R1())
public=key.public_key().public_numbers()
def xy(value):return value.x.to_bytes(32,'big')+value.y.to_bytes(32,'big')
def b64(data):return base64.urlsafe_b64encode(data).rstrip(b'=').decode()
def sign(payload,purpose='cyrus-license-lab+jwt'):
    header={'alg':'ES256','typ':purpose,'kid':'cyrus-ephemeral-lab-key'}
    message='.'.join(b64(json.dumps(x,separators=(',',':')).encode()) for x in [header,payload]).encode()
    r,s=utils.decode_dss_signature(key.sign(message,ec.ECDSA(hashes.SHA256())))
    return message.decode()+'.'+b64(r.to_bytes(32,'big')+s.to_bytes(32,'big'))
print(json.dumps({'public_xy':xy(public).hex(),'cryptography':cryptography.__version__,'private_key_persisted':False}),flush=True)
for line in sys.stdin:
    try:
        command=json.loads(line);request=command['request']
        if request['subject']!='lab-account' or request['tenant']!='lab-studio' or request['product']!='cyrus-scatter':raise ValueError('Only synthetic account supported')
        public_bytes=bytes.fromhex(request['public_xy']);signature=bytes.fromhex(request['proof'])
        if len(public_bytes)!=64 or len(signature)!=64 or len(request['nonce'])!=64:raise ValueError('Invalid request')
        device=hashlib.sha256(b'cyrus-installation-p256-v1:'+public_bytes).hexdigest()
        if device!=request['device']:raise ValueError('Device/key mismatch')
        device_key=ec.EllipticCurvePublicNumbers(int.from_bytes(public_bytes[:32],'big'),int.from_bytes(public_bytes[32:],'big'),ec.SECP256R1()).public_key()
        challenge='|'.join(request[k] for k in ['nonce','subject','tenant','product'])
        device_key.verify(utils.encode_dss_signature(int.from_bytes(signature[:32],'big'),int.from_bytes(signature[32:],'big')),
            ('cyrus-device-proof-v1:'+challenge).encode(),ec.ECDSA(hashes.SHA256()))
        now=int(time.time());duration=int(command.get('duration',3600))
        if not 3<=duration<=86400:raise ValueError('Development term bounds')
        license=sign({'v':1,'iss':'urn:cyrus:license-lab','aud':'cyrus-license-lab','jti':str(uuid.uuid4()),
            'sub':request['subject'],'tenant':request['tenant'],'product':request['product'],'device':device,
            'nbf':now-60,'exp':now+duration,'build_max':7,'rights':['author'],'mode':'assigned_device'})
        response=sign({'v':1,'iss':'urn:cyrus:license-lab','aud':'cyrus-license-lab','nonce':request['nonce'],
            'device':device,'server_utc':now,'license':license},'cyrus-license-lab+jwt.activation')
        print(json.dumps({'license':license,'response':response,'expires':now+duration}),flush=True)
    except Exception as error:print(json.dumps({'error':type(error).__name__+': '+str(error)}),flush=True)
