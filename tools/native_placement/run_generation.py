"""Serialized native producer parity in a fresh owned Max 2027 host."""
from pathlib import Path
import argparse,os,sys,time,uuid
ROOT=Path(__file__).resolve().parents[2]
def send(host,script,command):
    pointer=host/'dev-request.txt';response=host/'dev-result.txt'
    if pointer.exists():
        previous=pointer.read_text(encoding='utf-8-sig');state=response.read_text(encoding='utf-8-sig')
        assert previous in state and state.startswith(('SUCCESS','ERROR')),'Observe prior request; never duplicate a pending command'
    (host/'generation-command.txt').write_text(command)
    request=host/f'generation-{uuid.uuid4().hex}.ms';request.write_text(script.read_text(encoding='utf-8-sig'),encoding='utf-8-sig')
    pending=host/f'pointer-{uuid.uuid4().hex}.tmp';pending.write_text(request.as_posix(),encoding='utf-8-sig')
    publish_deadline=time.monotonic()+5
    while True:
        try:os.replace(pending,pointer);break
        except PermissionError:
            # The host's short ReadAllText can deny replacement on Windows.
            # Retry only publication of this same, still-unpublished pointer;
            # never create/replay a request after the host may have observed it.
            if not pending.exists() or time.monotonic()>publish_deadline:raise
            time.sleep(.05)
    end=time.monotonic()+180
    while time.monotonic()<end:
        try:state=response.read_text(encoding='utf-8-sig') if response.exists() else ''
        except PermissionError:time.sleep(.1);continue
        if request.as_posix() in state:
            if not state.startswith('SUCCESS'):raise RuntimeError(command+'\n'+state)
            print(command,flush=True);return
        time.sleep(.15)
    raise TimeoutError(f'Observation expired for {request}; retain/observe it before another request')
def ready(host):
    end=time.monotonic()+120
    while not (host/'ready.json').exists():
        if (host/'startup-error.txt').exists():raise RuntimeError((host/'startup-error.txt').read_text())
        if time.monotonic()>end:raise TimeoutError('Observe the owned startup process before retrying')
        time.sleep(.2)
def main():
    parser=argparse.ArgumentParser(description=__doc__);parser.add_argument('host');args=parser.parse_args()
    assert args.host.startswith(('foundation-memory0854-nativegenerate-','foundation-memory0854-nativeaccept-'))
    host=ROOT/'build/mcp-qualification'/args.host;ready(host)
    script=ROOT/'tools/native_placement/generation.ms'
    for kind in ['plane','mountain']:
        send(host,script,'setup '+kind)
        for label,count,mode in [('simple',5000,1),('advanced',5000,2),('slot128',5000,3),('cluster',5000,1),('uv',5000,2),('empty',5000,3),('areas',5000,1),('project',200,2),('rectangular',0,3),('staggered',0,1),('hexagonal',0,2),('simple',50000,2),('simple',200000,3)]:
            send(host,script,f'case {label} {count} {mode}')
        send(host,script,'release')
    print('NATIVE GENERATION/PREPARATION PARITY PASSED',flush=True)
if __name__=='__main__':main()
