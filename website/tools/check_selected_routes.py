"""Headless DOM/browser sweep for the selected website design; never touches Max."""
from pathlib import Path
import argparse,json,subprocess,time

def main():
    parser=argparse.ArgumentParser()
    parser.add_argument('--browser',required=True,help='agent-browser CLI path')
    parser.add_argument('--url',default='http://127.0.0.1:5178/')
    parser.add_argument('--output',required=True)
    args=parser.parse_args()
    session='cyrus-selected-sweep'
    output=Path(args.output);output.parent.mkdir(parents=True,exist_ok=True)
    command_number=0
    def run(*command):
        nonlocal command_number
        command_number+=1
        # Regular log files avoid inherited Windows daemon pipes keeping communicate open.
        log=output.parent/f'browser-cli-{command_number:03}.log'
        with log.open('w',encoding='utf-8') as stream:
            result=subprocess.run([args.browser,'--session',session,*command],stdout=stream,stderr=subprocess.STDOUT,timeout=30)
        text=log.read_text(encoding='utf-8').strip()
        if result.returncode:raise RuntimeError(text)
        return text
    routes=['/','/guide','/workflow','/visuals/layers','/visuals/containers','/visuals/coverage','/visuals/spacing','/visuals/updates','/visuals/viewport','/gallery','/examples','/checklist','/glossary','/troubleshooting','/guide/artist-guide/vector-painting','/controls?feature=C19','/features/painting','/roadmap','/about']
    results=[]
    for width in (320,390,768,1440):
        run('set','viewport',str(width),'1000')
        for route in routes:
            run('open',args.url+'?selected-sweep='+str(width)+'#'+route)
            run('wait','--fn',"document.querySelector('main h1')!==null")
            record=json.loads(json.loads(run('eval',"JSON.stringify({title:document.title,heading:document.querySelector('main h1')?.textContent,width:innerWidth,scrollWidth:document.documentElement.scrollWidth,overflow:document.documentElement.scrollWidth>innerWidth,brokenVisibleImages:Array.from(document.images).filter(i=>{const r=i.getBoundingClientRect();return i.currentSrc&&i.complete&&!i.naturalWidth&&r.top<innerHeight&&r.bottom>0}).map(i=>i.currentSrc),replacementCharacters:document.body.textContent.includes('�')})")))
            record['route']=route
            results.append(record)
        print(f'{width}px: {len(routes)} routes checked',flush=True)
    errors=run('errors')
    report={'scope':'Selected React design browser DOM sweep; not plugin testing','cases':results,'caseCount':len(results),'errors':errors,'status':'PASS' if not errors and all(not r['overflow'] and not r['brokenVisibleImages'] and not r['replacementCharacters'] for r in results) else 'FAIL'}
    output.write_text(json.dumps(report,indent=2)+'\n',encoding='utf-8')
    print(report['status'],flush=True)
    if report['status']!='PASS':
        print(json.dumps([r for r in results if r['overflow'] or r['brokenVisibleImages'] or r['replacementCharacters']],indent=2))
        raise SystemExit(1)

if __name__=='__main__':main()
