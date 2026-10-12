"""Compare rendered reference sections with the approved plugin presentation."""
from pathlib import Path
import argparse
import json
import subprocess
import time
from urllib.request import urlopen


def main():
    parser=argparse.ArgumentParser()
    parser.add_argument('--browser',required=True)
    parser.add_argument('--url',default='http://127.0.0.1:5180/')
    parser.add_argument('--output',required=True)
    args=parser.parse_args()
    site=Path(__file__).resolve().parents[1]
    layout=json.loads((site.parent/'AminScatter/tools/ui/approved-layout-manifest.json').read_text())
    data=json.loads((site/'src/content/reference.json').read_text(encoding='utf-8'))
    ids=['layers','surfaces','models','containers','layout','amount','painting','areas','transforms','spacing','viewport','statistics']
    aliases={'flow_layersUI':'general.manager','flow_surfaceUI':'general.surface','flow_previewUI':'general.previewUI','diagnosticsUI':'general.diagnostics'}
    target=Path(args.output);target.parent.mkdir(parents=True,exist_ok=True)
    session='cyrus-reference-'+str(int(time.time()));number=0;checks=[]

    def run(*command):
        nonlocal number
        number+=1;log=target.parent/f'reference-cli-{number:03}.log'
        with log.open('w',encoding='utf-8') as stream:
            result=subprocess.run([args.browser,'--session',session,*command],stdout=stream,stderr=subprocess.STDOUT,timeout=30)
        output=log.read_text(encoding='utf-8').strip()
        if result.returncode:raise RuntimeError(output)
        return output

    def dom(expression):return json.loads(json.loads(run('eval','JSON.stringify('+expression+')')))
    def check(name,condition,evidence=None):
        checks.append({'name':name,'passed':condition,'evidence':evidence});assert condition,(name,evidence)
    def open_page(route):
        run('open',args.url+'?review='+session+'#'+route)
        run('wait','--fn',"document.querySelector('main h1')!==null")

    try:
        run('set','viewport','1440','1000');open_page('/controls')
        sidebar=dom("Array.from(document.querySelectorAll('.nav-link.sub')).map(e=>({text:e.querySelectorAll('span')[1].textContent,href:e.getAttribute('href'),number:e.querySelector('.nav-number').textContent}))")
        check('Sidebar matches all 12 approved sections',sidebar==[{'text':s['title'],'href':'#/controls?topic='+ids[i],'number':str(i+1).zfill(2)} for i,s in enumerate(layout['sections'])],sidebar)
        all_ids=dom("Array.from(document.querySelectorAll('.control-entry')).map(e=>e.id)")
        check('Complete catalog without lost or duplicate controls',len(all_ids)==len(set(all_ids))==len(data['controls']) and set(all_ids)=={c['id'] for c in data['controls']},len(all_ids))
        check('Current count and license control are present',dom("document.querySelector('.nav-count').textContent")==str(len(all_ids)) and 'control-general-host-licensebutton' in all_ids)
        check('Overview section index uses sidebar order',dom("Array.from(document.querySelectorAll('.reference-section-index a')).map(e=>e.getAttribute('href'))")==[x['href'] for x in sidebar])
        run('screenshot',str((target.parent/'overview-desktop.png').resolve()))
        for width in [1440,768,320]:
            run('set','viewport',str(width),'1000')
            for index,section in enumerate(layout['sections']):
                topic=ids[index]
                keys=[aliases.get(c['component'],'layer.'+c['component'])+'.'+c['control'] for c in section['controls']]
                expected=[c for c in data['controls'] if c['sourceKey'] in keys or (topic=='containers' and c['group']=='container')]
                expected.sort(key=lambda c:keys.index(c['sourceKey']) if c['sourceKey'] in keys else 999)
                open_page('/controls?topic='+topic)
                run('wait','--fn',"document.querySelector('main h1').textContent==="+json.dumps(section['title']))
                record=dom("({ids:Array.from(document.querySelectorAll('.control-entry')).map(e=>e.id),active:document.querySelector('.nav-link.sub.active')?.getAttribute('href'),crumb:document.querySelector('.crumb-current').textContent,title:document.title,overflow:document.documentElement.scrollWidth>innerWidth,links:Array.from(document.querySelectorAll('.reference-topic-links a')).map(e=>e.getAttribute('href'))})")
                check(f'{width}px / {section["title"]}: exact controls, order, active navigation and layout',record['ids']==[c['id'] for c in expected] and record['active']=='#/controls?topic='+topic and record['crumb']==section['title'] and record['title'].startswith(section['title']) and not record['overflow'],record)
                if width==1440:
                    for href in record['links']:
                        if not href.startswith('#/guide/'):continue
                        parts=href[2:].split('/');doc=next(d for d in data['documents'] if d['id']==parts[1])
                        check(topic+' guide destination exists',len(parts)==2 or parts[2] in {h['anchor'] for h in doc['headings']},href)
                if topic=='painting' and width in [1440,320]:run('screenshot',str((target.parent/f'painting-{width}.png').resolve()))
            if width==320:
                run('click','.mobile-menu');run('scrollintoview','.nav-link[href="#/controls?topic=painting"]');run('click','.nav-link[href="#/controls?topic=painting"]')
                check('Mobile topic navigation closes drawer and opens Painting',dom("!document.querySelector('.sidebar.mobile-open')&&location.hash==='#/controls?topic=painting'"))
        open_page('/controls?topic=painting&owner=Paint+Area')
        check('Topic remains selected with additional filters',dom("document.querySelector('.nav-link.sub.active').getAttribute('href')==='#/controls?topic=painting'"))
        open_page('/controls?topic=statistics')
        check('Statistics includes recording diagnostics',dom("Array.from(document.querySelectorAll('.control-entry')).some(e=>e.id.startsWith('control-general-diagnostics-'))"))
        for ref in data['references']:
            if ref['kind']!='source-provenance':continue
            with urlopen(args.url+'sources/references/'+ref['id']+'.json') as response:payload=json.load(response)
            check('Owner-only document remains metadata only: '+ref['path'],payload['text'] is None)
            open_page('/reference/'+ref['id'])
            run('wait','--fn',"document.querySelector('.implementation-provenance')!==null")
            check('Metadata-only reference has an honest source card',dom("document.querySelector('.implementation-provenance h2').textContent==='Source record'&&!document.querySelector('.reference-text')"))
        check('No runtime errors',not run('errors'))
        target.write_text(json.dumps({'status':'PASS','count':len(checks),'checks':checks},indent=2)+'\n',encoding='utf-8')
        print(f'PASS: {len(checks)} reference assertions')
    finally:run('close')


if __name__=='__main__':main()
