"""Test the exact upload ZIP on a plain static server at / and /preview/."""
from pathlib import Path
import argparse
import hashlib
import json
import subprocess
import sys
import time
from urllib.request import urlopen
from urllib.error import HTTPError
from urllib.parse import quote
import zipfile


def main():
    parser=argparse.ArgumentParser()
    parser.add_argument('--archive',required=True)
    parser.add_argument('--browser',required=True)
    parser.add_argument('--output',required=True)
    parser.add_argument('--port',type=int,default=5186)
    args=parser.parse_args()
    archive=Path(args.archive).resolve();target=Path(args.output).resolve()
    target.parent.mkdir(parents=True,exist_ok=True)
    root=target.parent/'static-host';root.mkdir(exist_ok=True)
    manifest=json.loads((archive.parent/'manifest.json').read_text(encoding='utf-8'))
    assert hashlib.sha256(archive.read_bytes()).hexdigest()==manifest['sha256']
    checks=[];session='cyrus-upload-'+str(int(time.time()));number=0

    def check(name,passed,evidence=None):
        checks.append({'name':name,'passed':passed,'evidence':evidence});assert passed,(name,evidence)

    with zipfile.ZipFile(archive) as zipped:
        check('ZIP integrity',zipped.testzip() is None)
        check('No Markdown or source snapshots in upload',not any(n.lower().endswith('.md') or n.startswith('sources/') for n in zipped.namelist()))
        for directory in [root,root/'preview']:
            directory.mkdir(exist_ok=True)
            for name in zipped.namelist():
                path=(directory/name).resolve()
                assert path.is_relative_to(directory.resolve()) and not name.startswith('/')
                path.parent.mkdir(parents=True,exist_ok=True);path.write_bytes(zipped.read(name))
    check('index.html is directly at ZIP root','index.html' in [f['path'] for f in manifest['files']])
    log=(target.parent/'static-server.log').open('w',encoding='utf-8')
    server=subprocess.Popen([sys.executable,'-m','http.server',str(args.port),'--bind','127.0.0.1','--directory',str(root)],stdout=log,stderr=subprocess.STDOUT)

    def run(*command):
        nonlocal number
        number+=1;path=target.parent/f'upload-cli-{number:03}.log'
        with path.open('w',encoding='utf-8') as stream:
            result=subprocess.run([args.browser,'--session',session,*command],stdout=stream,stderr=subprocess.STDOUT,timeout=30)
        output=path.read_text(encoding='utf-8').strip()
        if result.returncode:raise RuntimeError(output)
        return output

    def dom(expression):return json.loads(json.loads(run('eval','JSON.stringify('+expression+')')))
    host=f'http://127.0.0.1:{args.port}/'
    try:
        for attempt in range(50):
            if server.poll() is not None:raise RuntimeError('Owned static server failed to start; check the port.')
            try:
                with urlopen(host,timeout=1):break
            except OSError:time.sleep(.1)
        else:raise RuntimeError('Static server not ready')
        run('set','viewport','1440','1000')
        for prefix in ['', 'preview/']:
            base=host+prefix
            for file in manifest['files']:
                with urlopen(base+quote(file['path']),timeout=5) as response:
                    body=response.read()
                    assert response.status==200 and hashlib.sha256(body).hexdigest()==file['sha256'],file['path']
            check('Every packaged file served unchanged at /'+prefix,True,len(manifest['files']))
            for route in ['/', '/guide', '/controls?topic=painting', '/visuals/updates', '/changelog', '/guide/artist-guide', '/guide/layout-falloff', '/guide/surface-analyzer', '/guide/product-roadmap', '/guide/mcp', '/about']:
                url=base+'#'+route
                run('open',url);run('wait','--fn',"document.querySelector('main h1')!==null")
                if route=='/':run('wait','--fn',"document.querySelector('#courtyard-scene svg')!==null")
                result=dom("({heading:document.querySelector('main h1').textContent,overflow:document.documentElement.scrollWidth>innerWidth,broken:Array.from(document.images).filter(i=>i.getBoundingClientRect().top<innerHeight&&i.getBoundingClientRect().bottom>0&&i.complete&&i.currentSrc&&!i.naturalWidth).map(i=>i.currentSrc)})")
                check('Static route loads: /'+prefix+'#'+route,bool(result['heading']) and not result['overflow'] and not result['broken'],result)
                check('No raw document links: /'+prefix+'#'+route,dom("!Array.from(document.querySelectorAll('a[href]')).some(a=>/\\.md(?:$|[?#])|sources\\/|#\\/reference\\//i.test(a.getAttribute('href')))"))
            for removed in ['sources/current/artist-guide.md','sources/references/backlog-removed.json','assets/CREDITS.md','assets/fonts/README.md']:
                try:
                    urlopen(base+removed,timeout=5).close();absent=False
                except HTTPError as error:absent=error.code==404
                check('Removed public source is absent: /'+prefix+removed,absent)
            run('open',base+'#/changelog');run('wait','--fn',"document.querySelector('.release-row')!==null")
            check('Latest development entry first',dom("document.querySelector('.release-version').textContent==='0.79.5'"))
            run('find','role','button','click','--name','Fixed','--exact')
            check('Change type filter',dom("Array.from(document.querySelectorAll('.change-kind')).every(e=>e.textContent==='Fixed')"))
            run('find','role','button','click','--name','All changes','--exact');run('fill','.release-search input','0.78.3')
            check('Version search',dom("document.querySelectorAll('.release-row').length===1 && document.querySelector('.release-version').textContent==='0.78.3'"))
            run('fill','.release-search input','0.10')
            check('Early history opens for search',dom("document.querySelector('.history-era').open && document.getElementById('v0.10').getClientRects().length>0"))
            run('fill','.release-search input','no-version-zzzz');check('No-result state',dom("document.querySelectorAll('.release-row').length===0 && document.querySelector('.empty-state')!==null"))
            run('open',base+'#/changelog/v1.2.3');run('wait','--fn',"document.getElementById('v1.2.3')!==null")
            check('Historical deep link opens archive',dom("document.querySelector('.history-era').open && document.getElementById('v1.2.3').getClientRects().length>0 && document.getElementById('v1.2.3').textContent.includes('Historical label')"))
            if not prefix:
                run('open',base+'#/changelog');run('wait','--fn',"document.querySelector('.release-row')!==null")
                run('screenshot',str(target.parent/'changelog-desktop.png'))
            run('open',base+'#/visuals/updates');run('wait','--fn',"document.querySelector('#lesson-update-mode')!==null")
            run('scrollintoview','#lesson-update-mode');run('click','#lesson-update-mode');run('click','[role=option][data-value="Live"]')
            check('Interactive dropdown works at /'+prefix,dom("document.querySelector('#lesson-update-mode').dataset.value==='Live'"))
            run('set','viewport','390','844');run('open',base+'#/guide')
            run('wait','--fn',"document.querySelector('.planting-layer-study')!==null")
            check('Mobile guide fits at /'+prefix,dom('document.documentElement.scrollWidth<=innerWidth'))
            run('screenshot',str(target.parent/('guide-subfolder-mobile.png' if prefix else 'guide-root-mobile.png')))
            run('open',base+'#/changelog');run('wait','--fn',"document.querySelector('.release-row')!==null")
            check('Mobile changelog fits at /'+prefix,dom('document.documentElement.scrollWidth<=innerWidth'))
            if not prefix:run('screenshot',str(target.parent/'changelog-mobile.png'))
            run('set','viewport','1440','1000')
        check('No browser exceptions',not run('errors'))
        target.write_text(json.dumps({'status':'PASS','count':len(checks),'archiveSha256':manifest['sha256'],'httpFilesChecked':len(manifest['files'])*2,'checks':checks},indent=2)+'\n',encoding='utf-8')
        print(f'PASS: {len(checks)} upload assertions; {len(manifest["files"])*2} file/hash HTTP checks')
    finally:
        server.terminate();server.wait(timeout=10);log.close()
        run('close')


if __name__=='__main__':main()
