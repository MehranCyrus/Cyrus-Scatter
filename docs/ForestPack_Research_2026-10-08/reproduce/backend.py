"""Operate an isolated loopback Ghidra backend; never executes target binaries."""
import argparse
import json
import os
import socket
import subprocess
import urllib.error
import urllib.parse
import urllib.request
from pathlib import Path


def request(port, method, endpoint, params, timeout):
    url = f'http://127.0.0.1:{port}{endpoint}'
    body = None
    if method == 'GET' and params:
        url += '?' + urllib.parse.urlencode(params)
    elif method == 'POST':
        body = json.dumps(params).encode()
    query = urllib.request.Request(url, data=body, method=method, headers={'Content-Type':'application/json'})
    try:
        with urllib.request.urlopen(query, timeout=timeout) as response:
            return response.read().decode('utf-8', errors='replace')
    except urllib.error.HTTPError as error:
        raise RuntimeError(f'{error.code}: {error.read().decode()}') from error


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('action', choices=['start','request'])
    parser.add_argument('--run', type=Path, required=True)
    parser.add_argument('--port', type=int, default=18091)
    parser.add_argument('--method', choices=['GET','POST'], default='GET')
    parser.add_argument('--endpoint')
    parser.add_argument('--params', type=Path)
    parser.add_argument('--output', type=Path)
    parser.add_argument('--timeout', type=int, default=60)
    args = parser.parse_args()
    run = args.run.resolve()
    if not run.is_relative_to(Path.cwd()/'build') or not run.is_dir():
        raise ValueError('Use an existing owned run under build/')
    if args.action == 'request':
        params = json.loads(args.params.read_text(encoding='utf-8-sig')) if args.params else {}
        result = request(args.port,args.method,args.endpoint,params,args.timeout)
        if args.output:
            destination = args.output.resolve()
            if not destination.is_relative_to(run):
                raise ValueError('Responses must stay in the run')
            destination.parent.mkdir(parents=True, exist_ok=True)
            destination.write_text(result,encoding='utf-8')
        print(result[:2000])
        return
    with socket.socket() as probe:
        probe.bind(('127.0.0.1',args.port))
    config = json.loads(Path('C:/Users/Mehran/Documents/ChatGPT/Play/tyflow-analysis/tools.json').read_text())
    ghidra = Path(config['ghidra'])
    java = Path(config['java'])/'bin/java.exe'
    classpath = list(config['mcp_jars'])
    classpath += [str(p/'*') for p in (ghidra/'Ghidra').glob('*/*/lib')]
    classpath += [str(p/'*') for p in (ghidra/'Ghidra').glob('*/lib')]
    userhome = run/'userhome'
    userhome.mkdir(exist_ok=False)
    (run/'projects').mkdir(exist_ok=False)
    arguments = ['-Xmx4g','-XX:+UseG1GC',f'-Dghidra.home={ghidra}',f'-Duser.home={userhome}',
                 '-Dapplication.name=GhidraMCP','-classpath',os.pathsep.join(classpath),
                 'com.xebyte.headless.GhidraMCPHeadlessServer','--bind','127.0.0.1','--port',str(args.port)]
    argument_file = run/'launch.args'
    argument_file.write_text('\n'.join('"'+x.replace('\\','/').replace('"','\\"')+'"' for x in arguments),encoding='utf-8')
    environment = os.environ.copy()
    environment['GHIDRA_MCP_FILE_ROOT'] = str(run)
    environment['GHIDRA_MCP_ALLOW_SCRIPTS'] = '1'
    with (run/'headless.log').open('w',encoding='utf-8') as log:
        process = subprocess.Popen([str(java),'@'+str(argument_file)],cwd=str(ghidra),env=environment,
                                   stdout=log,stderr=subprocess.STDOUT,creationflags=subprocess.CREATE_NO_WINDOW)
    state = dict(pid=process.pid,port=args.port,java=str(java),ghidra=str(ghidra),jar=config['mcp_jars'],run=str(run))
    (run/'server-start.json').write_text(json.dumps(state,indent=2),encoding='utf-8')
    print(json.dumps(state))


if __name__ == '__main__':
    main()
