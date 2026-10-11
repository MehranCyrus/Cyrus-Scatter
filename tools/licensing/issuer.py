"""Owner-only offline team issuer. Never distribute this tool or its key store."""
from __future__ import annotations

import argparse
import base64
import ctypes
from ctypes import wintypes
import hashlib
import json
import os
from pathlib import Path
import sqlite3
import time
import uuid

from cryptography.hazmat.primitives import hashes, serialization
from cryptography.hazmat.primitives.asymmetric import ec, utils

TERM_SECONDS = 30 * 24 * 60 * 60
ISSUER = 'urn:cyrus:team-offline:v1'
AUDIENCE = 'cyrus-team-offline'
TOKEN_TYPE = 'cyrus-team-license+jwt'
CONTEXT = dict(subject='team-seat', tenant='cyrus-team', product='cyrus-scatter')
DEFAULT_STORE = Path(os.environ.get('USERPROFILE', str(Path.home()))) / '.CyrusScatter' / 'LicenseIssuer'


def strict_json(data):
    def pairs(items):
        result = {}
        for key, value in items:
            if key in result:
                raise ValueError('Duplicate JSON field')
            result[key] = value
        return result
    if len(data) > 16384:
        raise ValueError('Input exceeds 16 KiB')
    return json.loads(data, object_pairs_hook=pairs)


def protect(data: bytes, decrypt=False) -> bytes:
    if os.name != 'nt':
        raise RuntimeError('The owner key store requires Windows DPAPI')
    class Blob(ctypes.Structure):
        _fields_ = [('size', wintypes.DWORD), ('data', ctypes.POINTER(ctypes.c_ubyte))]
    buffer = (ctypes.c_ubyte * len(data)).from_buffer_copy(data)
    source, target = Blob(len(data), buffer), Blob()
    dll = ctypes.WinDLL('crypt32', use_last_error=True)
    call = dll.CryptUnprotectData if decrypt else dll.CryptProtectData
    call.argtypes = [ctypes.POINTER(Blob), ctypes.c_void_p, ctypes.c_void_p,
                     ctypes.c_void_p, ctypes.c_void_p, wintypes.DWORD, ctypes.POINTER(Blob)]
    call.restype = wintypes.BOOL
    if not call(ctypes.byref(source), None, None, None, None, 1, ctypes.byref(target)):
        raise ctypes.WinError(ctypes.get_last_error())
    kernel = ctypes.WinDLL('kernel32', use_last_error=True)
    kernel.LocalFree.argtypes = [ctypes.c_void_p]
    kernel.LocalFree.restype = ctypes.c_void_p
    try:
        return ctypes.string_at(target.data, target.size)
    finally:
        ctypes.memset(target.data, 0, target.size)
        kernel.LocalFree(target.data)
        ctypes.memset(buffer, 0, len(data))


def xy(key):
    values = key.public_key().public_numbers()
    return values.x.to_bytes(32, 'big') + values.y.to_bytes(32, 'big')


def initialize(store: Path):
    store.mkdir(parents=True, exist_ok=True)
    # Exclusive creation prevents changing the authority behind an existing build.
    key = ec.generate_private_key(ec.SECP256R1())
    metadata = {'v': 1, 'kid': 'cyrus-team-' + uuid.uuid4().hex,
                'private_der': key.private_bytes(serialization.Encoding.DER,
                    serialization.PrivateFormat.PKCS8, serialization.NoEncryption()).hex()}
    encrypted = protect(json.dumps(metadata).encode())
    with (store / 'issuer.dpapi').open('xb') as stream:
        stream.write(encrypted)
        stream.flush()
        os.fsync(stream.fileno())
    return public_metadata(store)


def load_key(store: Path):
    data = (store / 'issuer.dpapi').read_bytes()
    record = strict_json(protect(data, decrypt=True))
    if set(record) != {'v', 'kid', 'private_der'} or record['v'] != 1:
        raise ValueError('Unrecognized owner key store')
    key = serialization.load_der_private_key(bytes.fromhex(record['private_der']), password=None)
    if not isinstance(key, ec.EllipticCurvePrivateKey) or not isinstance(key.curve, ec.SECP256R1):
        raise ValueError('Expected P-256 issuer key')
    return record['kid'], key


def public_metadata(store: Path):
    kid, key = load_key(store)
    return {'v': 1, 'kid': kid, 'public_xy': xy(key).hex()}


def backup(store: Path, output: Path, password: str):
    if len(password)<16:
        raise ValueError('Use a backup passphrase of at least 16 characters')
    kid,key=load_key(store)
    encrypted=key.private_bytes(serialization.Encoding.DER,serialization.PrivateFormat.PKCS8,
                               serialization.BestAvailableEncryption(password.encode('utf-8')))
    with output.open('x',encoding='ascii') as stream:
        json.dump({'v':1,'kid':kid,'encrypted_pkcs8':encrypted.hex()},stream)


def restore(store: Path, backup_bytes: bytes, password: str):
    record=strict_json(backup_bytes)
    if set(record)!={'v','kid','encrypted_pkcs8'} or record['v']!=1:
        raise ValueError('Unrecognized issuer backup')
    kid=record['kid']
    if not isinstance(kid,str) or not kid.startswith('cyrus-team-') or len(kid)!=43 or any(c not in '0123456789abcdef' for c in kid[11:]):
        raise ValueError('Unrecognized issuer key ID')
    key=serialization.load_der_private_key(bytes.fromhex(record['encrypted_pkcs8']),password.encode('utf-8'))
    if not isinstance(key,ec.EllipticCurvePrivateKey) or not isinstance(key.curve,ec.SECP256R1):
        raise ValueError('Expected P-256 issuer key')
    data={'v':1,'kid':kid,'private_der':key.private_bytes(serialization.Encoding.DER,
          serialization.PrivateFormat.PKCS8,serialization.NoEncryption()).hex()}
    store.mkdir(parents=True,exist_ok=True)
    with (store/'issuer.dpapi').open('xb') as stream:
        stream.write(protect(json.dumps(data).encode()));stream.flush();os.fsync(stream.fileno())
    return public_metadata(store)


def export_header(store: Path, output: Path):
    public = public_metadata(store)
    text = ('#pragma once\n// Public verification key only; generated by the owner issuer.\n'
            'inline constexpr char CyrusTeamKeyID[]="' + public['kid'] + '";\n'
            'inline constexpr unsigned char CyrusTeamPublicXY[]={' +
            ','.join(str(n) for n in bytes.fromhex(public['public_xy'])) + '};\n')
    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_text(text, encoding='utf-8')
    return public


def validate_request(data):
    request = strict_json(data)
    expected = {'device', 'nonce', 'subject', 'tenant', 'product', 'public_xy', 'proof'}
    if not isinstance(request, dict) or set(request) != expected:
        raise ValueError('Unrecognized activation request')
    if any(request.get(k) != v for k, v in CONTEXT.items()):
        raise ValueError('Request belongs to another product or context')
    for name, size in [('device', 64), ('nonce', 64), ('public_xy', 128), ('proof', 128)]:
        value = request[name]
        if not isinstance(value, str) or len(value) != size or any(c not in '0123456789abcdef' for c in value):
            raise ValueError('Invalid request field: ' + name)
    public = bytes.fromhex(request['public_xy'])
    if hashlib.sha256(b'cyrus-installation-p256-v1:' + public).hexdigest() != request['device']:
        raise ValueError('Installation identity mismatch')
    key = ec.EllipticCurvePublicNumbers(int.from_bytes(public[:32], 'big'),
             int.from_bytes(public[32:], 'big'), ec.SECP256R1()).public_key()
    proof = bytes.fromhex(request['proof'])
    challenge = '|'.join(request[k] for k in ['nonce', 'subject', 'tenant', 'product'])
    key.verify(utils.encode_dss_signature(int.from_bytes(proof[:32], 'big'),
               int.from_bytes(proof[32:], 'big')), ('cyrus-device-proof-v1:' + challenge).encode(),
               ec.ECDSA(hashes.SHA256()))
    return request


def sign(key, kid, payload):
    def part(value):
        return base64.urlsafe_b64encode(json.dumps(value, separators=(',', ':')).encode()).rstrip(b'=')
    message = part({'alg': 'ES256', 'typ': TOKEN_TYPE, 'kid': kid}) + b'.' + part(payload)
    r, s = utils.decode_dss_signature(key.sign(message, ec.ECDSA(hashes.SHA256())))
    return (message + b'.' + base64.urlsafe_b64encode(r.to_bytes(32, 'big') +
            s.to_bytes(32, 'big')).rstrip(b'=')).decode('ascii')


def issue(store: Path, request_bytes, recipient: str):
    request = validate_request(request_bytes)
    if not isinstance(recipient, str) or not recipient.strip() or len(recipient) > 200:
        raise ValueError('Enter a recipient name (1 to 200 characters)')
    kid, key = load_key(store)
    identity = hashlib.sha256(json.dumps(request, sort_keys=True).encode()).hexdigest()
    # Serialize issuance. Repeating the same request returns the same grant/deadline.
    with sqlite3.connect(store / 'issued.sqlite3', timeout=10) as db:
        db.execute('CREATE TABLE IF NOT EXISTS grants (request TEXT PRIMARY KEY, kid TEXT NOT NULL, '
                   'recipient TEXT NOT NULL, device TEXT NOT NULL, issued INTEGER NOT NULL, '
                   'expires INTEGER NOT NULL, license TEXT NOT NULL)')
        db.execute('BEGIN IMMEDIATE')
        old = db.execute('SELECT kid,issued,expires,license FROM grants WHERE request=?', (identity,)).fetchone()
        if old:
            if old[0] != kid:
                raise ValueError('Issuer key differs from the issuance ledger')
            return dict(issued=old[1], expires=old[2], license=old[3], repeated_request=True)
        now = int(time.time())
        latest = db.execute('SELECT MAX(issued) FROM grants').fetchone()[0]
        if latest is not None and now < latest:
            raise ValueError('Owner clock moved backwards; correct it before issuing')
        payload = dict(v=1, iss=ISSUER, aud=AUDIENCE, jti=str(uuid.uuid4()),
            sub=request['subject'], tenant=request['tenant'], product=request['product'],
            device=request['device'], nbf=now, exp=now + TERM_SECONDS, build_max=79,
            rights=['author'], mode='assigned_device')
        token = sign(key, kid, payload)
        db.execute('INSERT INTO grants VALUES (?,?,?,?,?,?,?)',
                   (identity, kid, recipient.strip(), request['device'], now, now + TERM_SECONDS, token))
        return dict(issued=now, expires=now + TERM_SECONDS, license=token, repeated_request=False)


def gui(store: Path):
    import tkinter as tk
    from tkinter import filedialog, messagebox, simpledialog
    from datetime import datetime, timezone
    root = tk.Tk()
    root.title('Cyrus 0.79 - Owner License Generator')
    root.geometry('550x290')
    tk.Label(root, text='Generate a 30-day team license', font=('Segoe UI', 16)).pack(pady=18)
    tk.Label(root, text='Select the activation request your teammate sent you.\n'
             'The 30 days begin when you generate the license.\n'
             'Keep this generator and its owner key store private.', font=('Segoe UI', 10)).pack()
    def generate():
        try:
            request = filedialog.askopenfilename(title='Select team activation request', filetypes=[('Cyrus request', '*.json')])
            if not request:
                return
            recipient = simpledialog.askstring('Recipient', 'Team member name:', parent=root)
            if not recipient:
                return
            output = filedialog.asksaveasfilename(title='Save license to send', defaultextension='.cyruslicense',
                initialfile='Cyrus-team.cyruslicense', filetypes=[('Cyrus license', '*.cyruslicense')])
            if not output:
                return
            result = issue(store, Path(request).read_bytes(), recipient)
            Path(output).write_text(result['license'] + '\n', encoding='ascii')
            expiry = datetime.fromtimestamp(result['expires'], timezone.utc).isoformat()
            messagebox.showinfo('License saved', 'Send only the license file to your teammate.\nExpires: ' + expiry, parent=root)
        except Exception as error:
            messagebox.showerror('Cannot issue license', str(error), parent=root)
    tk.Button(root, text='Generate license from request...', command=generate, padx=20, pady=10).pack(pady=18)
    def backup_key():
        try:
            output=filedialog.asksaveasfilename(title='Save encrypted owner backup',defaultextension='.cyrusissuer',
                filetypes=[('Encrypted issuer backup','*.cyrusissuer')])
            if not output:return
            password=simpledialog.askstring('Backup passphrase','At least 16 characters; keep this separately:',show='*',parent=root)
            if password is None:return
            confirm=simpledialog.askstring('Confirm passphrase','Repeat the backup passphrase:',show='*',parent=root)
            if password!=confirm:raise ValueError('Passphrases differ')
            backup(store,Path(output),password)
            messagebox.showinfo('Backup saved','Store this privately. Also back up issued.sqlite3 from your owner store.\nNever send the backup to a teammate.',parent=root)
        except Exception as error:messagebox.showerror('Backup failed',str(error),parent=root)
    tk.Button(root,text='Back up owner key...',command=backup_key).pack()
    root.mainloop()


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--store', type=Path, default=DEFAULT_STORE)
    sub = parser.add_subparsers(dest='command', required=True)
    sub.add_parser('init')
    sub.add_parser('gui')
    header = sub.add_parser('public-header'); header.add_argument('output', type=Path)
    backup_parser=sub.add_parser('backup');backup_parser.add_argument('output',type=Path)
    restore_parser=sub.add_parser('restore');restore_parser.add_argument('input',type=Path)
    issue_parser = sub.add_parser('issue')
    issue_parser.add_argument('--request', type=Path, required=True)
    issue_parser.add_argument('--recipient', required=True)
    issue_parser.add_argument('--output', type=Path, required=True)
    args = parser.parse_args()
    if args.command == 'init':
        print(json.dumps(initialize(args.store)))
    elif args.command == 'public-header':
        print(json.dumps(export_header(args.store, args.output)))
    elif args.command == 'gui':
        gui(args.store)
    elif args.command in ('backup','restore'):
        from getpass import getpass
        password=getpass('Backup passphrase: ')
        if args.command=='backup':
            if password!=getpass('Confirm passphrase: '):raise ValueError('Passphrases differ')
            backup(args.store,args.output,password)
            print('Encrypted backup saved. Back up the issuance ledger separately.')
        else:print(json.dumps(restore(args.store,args.input.read_bytes(),password)))
    else:
        result = issue(args.store, args.request.read_bytes(), args.recipient)
        args.output.write_text(result.pop('license') + '\n', encoding='ascii')
        print(json.dumps(result))


if __name__ == '__main__':
    main()
