"""Phase 4C local transaction primitives. No installed retrieval imports."""
import json
import os
from pathlib import Path
import re
import stat
import tomllib
import uuid

import candidate_support as s

SCHEMA='cyrus.activation-plan/1'
OWN=('activate.py','activation_contract.py','activation_verify.py','activation_client.py',
     'candidate_support.py','refresh_inspect.py','refresh_boundary.py')
SERVER='cyrus_knowledge'
LIMIT=4*1024**2


def fail(issue,reason):raise s.Blocked(issue,reason)


def inside(root,path,base=None,missing=False):
    path=s.safe(path,missing);base=root if base is None else base
    if path==base or not path.is_relative_to(base):fail('wrong_root','Explicit path must be a child of '+str(base))
    return path


def fingerprint(path,limit=LIMIT):
    raw,stamp=s.reader().read(s.safe(path),limit)
    return {'sha256':s.sha(raw),'identity':list(stamp),'size':len(raw)}


def read_json(path,limit=LIMIT):return json.loads(s.reader().read(s.safe(path),limit)[0])


def configuration(root):
    """Only the actual literal-string args layout. Replace one token, no serializer."""
    path=inside(root,root/'.codex/config.toml');raw,stamp=s.reader().read(path,64*1024)
    text=raw.decode('utf-8');document=tomllib.loads(text)
    entry=document['mcp_servers'][SERVER];args=entry['args']
    if set(entry)-{'command','args','cwd','enabled_tools','startup_timeout_sec','tool_timeout_sec'}:
        fail('unsupported_configuration','Selected server contains unsupported launch settings')
    # A small supported syntax subset makes preservation provable by byte slicing.
    sections=list(re.finditer(r'(?m)^\[([^\r\n]+)\][ \t]*(?:#[^\r\n]*)?\r?$',text))
    selected=[m for m in sections if m.group(1)=='mcp_servers.'+SERVER]
    if len(selected)!=1:fail('unsupported_configuration','Expected one ordinary project server table')
    start=selected[0].end();end=next((m.start() for m in sections if m.start()>start),len(text))
    matches=list(re.finditer(r"(?m)^args[ \t]*=[ \t]*\[([^\r\n]*)\][ \t]*(?:#[^\r\n]*)?\r?$",text[start:end]))
    if len(matches)!=1:fail('unsupported_configuration','Use the supported single-line literal-string args array')
    match=matches[0];body=match.group(1);tokens=list(re.finditer(r"'([^'\r\n]*)'",body))
    residue=re.sub(r"'[^'\r\n]*'",'',body)
    if not re.fullmatch(r'[ \t]*(?:,[ \t]*)*',residue) or [t.group(1) for t in tokens]!=args:
        fail('unsupported_configuration','Args must be single-quoted literal strings; ambiguous syntax is rejected')
    if any(a.startswith('--index=') or a.startswith('--root=') for a in args):fail('ambiguous_binding','Inline index/root flags are unsupported')
    if args.count('--index')!=1 or args.count('--root')!=1:fail('ambiguous_binding','Exactly one index and root argument required')
    n=args.index('--index')+1
    if n>=len(args) or args.index('--root')+1>=len(args):fail('ambiguous_binding','Missing binding argument')
    index=inside(root,args[n],root/'_local/rag/indexes')
    expected=['-B',str(root/'tools/rag/adapter.py'),'--root',str(root),'--index',str(index)]
    refresh=(len(args)==11 and args[:7]==expected+['--follow-project']
             and args[7]=='--refresh-policy' and args[9]=='--refresh-policy-sha256'
             and re.fullmatch('[0-9a-f]{64}',args[10]))
    if refresh:
        proposal=inside(root,args[8],root/'_local/rag/refresh')
        if proposal.name!='policy.json':fail('unsupported_configuration','Refresh must name its explicit policy.json')
    if not refresh and args not in (expected,expected+['--follow-project']):
        fail('unsupported_configuration','Unsupported adapter selection/refresh arguments')
    if s.safe(entry['cwd'])!=root or set(entry.get('enabled_tools',[]))!={'knowledge_search','knowledge_status'}:
        fail('unsupported_configuration','Selected cwd and read-only tool allowlist must match the explicit root')
    command=s.safe(entry['command'])
    offset=start+match.start(1);token=tokens[n]
    left=len(text[:offset+token.start()].encode('utf-8'));right=len(text[:offset+token.end()].encode('utf-8'))
    return {'path':str(path),'server':SERVER,'index':str(index),'command':str(command),
            'fingerprint':{'sha256':s.sha(raw),'identity':list(stamp),'size':len(raw)},
            'span':[left,right]},raw,document


def replacement(root,binding,raw,target):
    target=inside(root,target,root/'_local/rag/indexes')
    token="'"+str(target)+"'"
    if "'" in str(target):fail('unsupported_path','Literal quote in target path is unsupported')
    a,b=binding['span'];after=raw[:a]+token.encode('utf-8')+raw[b:]
    before=tomllib.loads(raw.decode('utf-8'));parsed=tomllib.loads(after.decode('utf-8'))
    before['mcp_servers'][SERVER]['args'][5]=str(target)
    if parsed!=before:fail('unrelated_change','Proposed replacement changed unrelated configuration values')
    return after


class Ownership:
    def __init__(self,root,token):
        self.path=root/'_local/rag/activation.lock';self.token=token;self.stamp=None
    def acquire(self):
        s.safe(self.path,True);self.path.parent.mkdir(parents=True,exist_ok=True)
        try:s.create(self.path,{'schema':'cyrus.activation-owner/1','pid':os.getpid(),'token':self.token,'created':s.now()})
        except FileExistsError:fail('ownership_uncertain','Existing owner, including an abandoned owner; inspect before any manual release')
        self.stamp=s.identity(self.path.lstat())
    def check(self):
        if self.stamp is None or list(s.identity(s.safe(self.path).lstat()))!=list(self.stamp) or read_json(self.path).get('token')!=self.token:
            fail('ownership_uncertain','Operation ownership changed; preserve lock and inspect actual configuration')
    def release(self):
        self.check();self.path.unlink();self.stamp=None


def private_copy(path,raw):
    """Exclusive local backup with owner/system-only Windows DACL or POSIX 0600."""
    s.safe(path,True)
    descriptor=os.open(path,os.O_WRONLY|os.O_CREAT|os.O_EXCL|getattr(os,'O_BINARY',0),0o600)
    with os.fdopen(descriptor,'wb') as handle:
        if os.name=='nt':
            import ctypes
            from ctypes import wintypes
            api=ctypes.WinDLL('advapi32',use_last_error=True);kernel=ctypes.WinDLL('kernel32',use_last_error=True)
            descriptor_pointer=ctypes.c_void_p()
            convert=api.ConvertStringSecurityDescriptorToSecurityDescriptorW
            convert.argtypes=[wintypes.LPCWSTR,wintypes.DWORD,ctypes.POINTER(ctypes.c_void_p),ctypes.c_void_p]
            convert.restype=wintypes.BOOL
            apply=api.SetFileSecurityW;apply.argtypes=[wintypes.LPCWSTR,wintypes.DWORD,ctypes.c_void_p];apply.restype=wintypes.BOOL
            kernel.LocalFree.argtypes=[ctypes.c_void_p];kernel.LocalFree.restype=ctypes.c_void_p
            if not convert('D:P(A;;FA;;;OW)(A;;FA;;;SY)',1,ctypes.byref(descriptor_pointer),None):raise ctypes.WinError(ctypes.get_last_error())
            try:
                if not apply(str(path),0x80000004,descriptor_pointer):raise ctypes.WinError(ctypes.get_last_error())
            finally:kernel.LocalFree(descriptor_pointer)
        handle.write(raw);handle.flush();os.fsync(handle.fileno())


def sync_directory(path):
    if os.name!='nt':
        descriptor=os.open(path,os.O_RDONLY)
        try:os.fsync(descriptor)
        finally:os.close(descriptor)


def preserve_access(source,destination):
    """Replacement inherits the prior file's access policy; backup stays private."""
    os.chmod(destination,stat.S_IMODE(source.stat().st_mode))
    if os.name=='nt':
        import ctypes
        from ctypes import wintypes
        api=ctypes.WinDLL('advapi32',use_last_error=True)
        get=api.GetFileSecurityW;get.argtypes=[wintypes.LPCWSTR,wintypes.DWORD,ctypes.c_void_p,wintypes.DWORD,ctypes.POINTER(wintypes.DWORD)];get.restype=wintypes.BOOL
        needed=wintypes.DWORD();get(str(source),4,None,0,ctypes.byref(needed))
        if not 0<needed.value<=65536:raise ctypes.WinError(ctypes.get_last_error())
        buffer=ctypes.create_string_buffer(needed.value)
        if not get(str(source),4,buffer,needed,ctypes.byref(needed)):raise ctypes.WinError(ctypes.get_last_error())
        control=wintypes.WORD();revision=wintypes.DWORD()
        query=api.GetSecurityDescriptorControl;query.argtypes=[ctypes.c_void_p,ctypes.POINTER(wintypes.WORD),ctypes.POINTER(wintypes.DWORD)];query.restype=wintypes.BOOL
        if not query(buffer,ctypes.byref(control),ctypes.byref(revision)):raise ctypes.WinError(ctypes.get_last_error())
        put=api.SetFileSecurityW;put.argtypes=[wintypes.LPCWSTR,wintypes.DWORD,ctypes.c_void_p];put.restype=wintypes.BOOL
        flags=4|(0x80000000 if control.value&0x1000 else 0x20000000)
        if not put(str(destination),flags,buffer):raise ctypes.WinError(ctypes.get_last_error())


def publish_config(root,binding,raw,after,output,owner,checkpoint):
    """Explicit journal witnesses, no automatic restoration on uncertain failure."""
    path=Path(binding['path']);private_copy(output/'prior-config.bin',raw)
    # Atomic replacement must be on the destination filesystem, adjacent to it.
    temporary=path.with_name('.config.toml.activation-'+uuid.uuid4().hex+'.tmp')
    private_copy(temporary,after)
    preserve_access(path,temporary)
    s.create(output/'journal-prepared.json',{'config':str(path),'prior':binding['fingerprint'],
        'proposed_sha256':s.sha(after),'temporary':str(temporary),'backup':str(output/'prior-config.bin'),
        'note':'Backup can contain secrets; private local recovery input, never log or attach its bytes'})
    checkpoint('before_replace');owner.check()
    observed,body,_=configuration(root)
    if observed!=binding or body!=raw:fail('configuration_changed','Configuration changed immediately before replacement')
    # This check and os.replace are not an OS compare-and-swap. External writers
    # in this small interval cannot be excluded by a cooperative lock.
    os.replace(temporary,path);sync_directory(path.parent)
    checkpoint('after_replace')
    actual,body,_=configuration(root)
    if body!=after:fail('post_write_conflict','Configuration differs after replacement; never restore over a later edit')
    s.create(output/'journal-replaced.json',{'fingerprint':actual['fingerprint'],'index':actual['index']})
    checkpoint('after_confirmation')
    return actual
