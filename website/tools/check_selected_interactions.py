"""Exercise the selected visual guide with normal headless browser interactions."""
from pathlib import Path
import argparse,json,subprocess,time

def main():
    parser=argparse.ArgumentParser();parser.add_argument('--browser',required=True);parser.add_argument('--url',default='http://127.0.0.1:5178/');parser.add_argument('--output',required=True);args=parser.parse_args()
    target=Path(args.output);target.parent.mkdir(parents=True,exist_ok=True);number=0;checks=[]
    download_dir=target.parent.resolve()/'downloads';download_dir.mkdir(exist_ok=True)
    session='cyrus-selected-final-'+str(int(time.time()))
    def run(*command):
        nonlocal number
        number+=1;log=target.parent/f'interaction-cli-{number:03}.log'
        with log.open('w',encoding='utf-8') as stream:result=subprocess.run([args.browser,'--session',session,*(['--download-path',str(download_dir)] if number==1 else []),*command],stdout=stream,stderr=subprocess.STDOUT,timeout=30)
        text=log.read_text(encoding='utf-8').strip()
        if result.returncode:raise RuntimeError(text)
        return text
    def dom(expression):return json.loads(json.loads(run('eval','JSON.stringify('+expression+')')))
    def test(name,condition,evidence):
        checks.append({'name':name,'status':'PASS' if condition else 'FAIL','evidence':evidence})
        assert condition,(name,evidence)
    def open(route):
        run('open',args.url+'?interaction-review=selected#'+route);run('wait','--fn',"document.querySelector('main h1')!==null")
        if route=='/':run('wait','--fn',"document.querySelector('#courtyard-scene svg')!==null")
    def click(selector):
        run('scrollintoview',selector)
        # The selected reference deliberately uses smooth scrolling; wait for a stable hit target.
        run('wait','--fn',"new Promise(resolve=>{let prior,stable=0;function tick(){const r=document.querySelector("+json.dumps(selector)+").getBoundingClientRect();const y=Math.round(r.top*10);stable=y===prior?stable+1:0;prior=y;if(stable>=3)resolve(true);else requestAnimationFrame(tick)}tick()})")
        run('click',selector)
    def key(selector,value):run('scrollintoview',selector);run('focus',selector);run('wait','--fn','document.activeElement===document.querySelector('+json.dumps(selector)+')');run('press',value)
    def text(selector):return run('get','text',selector)
    def read(selector,attribute):return run('get','attr',selector,attribute)
    def select(selector,value):
        click(selector)
        click('[role="option"][data-value='+json.dumps(value)+']')
    def count_points():return dom("Array.from(document.querySelectorAll('#courtyard-scene circle')).map(e=>[e.getAttribute('cx'),e.getAttribute('cy'),e.getAttribute('r')].join(','))")
    run('set','viewport','1440','1000');open('/checklist');click('.checklist-toolbar .row button:last-child');click('.callout.warning .row button:first-child');open('/')
    click('#step-0');key('#step-0','ArrowRight');test('Workflow roving stage keys',read('#step-1','aria-selected')=='true',read('#step-1','aria-selected'))
    click('#step-2');key('#density','End');run('wait','--fn',"document.querySelector('#density-value').value==='100%'");all_points=count_points()
    key('#density','Home');run('wait','--fn',"document.querySelector('#density-value').value==='15%'");few_points=count_points()
    test('Density keeps a stable subset',0<len(few_points)<len(all_points) and set(few_points).issubset(all_points),{'low':len(few_points),'high':len(all_points)})
    click('#reset-scene');run('wait','--fn',"document.querySelector('#step-3').getAttribute('aria-selected')==='true'")
    before=text('#scene-count');run('uncheck','#layer-canopy');run('wait','--fn',"document.querySelector('#scene-count').textContent!=='"+before+"'")
    test('Layer visibility changes the illustration',before!=text('#scene-count'),{'before':before,'after':text('#scene-count')})
    click('[data-variation="0"]');test('Source character switch',read('[data-variation="0"]','aria-pressed')=='true','Uniform selected')
    click('#reset-scene');test('Composition reset',run('get','value','#density')=='70' and run('is','checked','#layer-canopy')=='true',text('#scene-count'))
    key('#boundary-inset','Home');near=text('#boundary-count');key('#boundary-inset','End');far=text('#boundary-count')
    test('Boundary inset filters points',int(far.split()[0])<int(near.split()[0]),{'near':near,'far':far})
    for mode in ('elements','boundaries','guides'):
        click('[data-analysis="'+mode+'"]');test('Analyzer '+mode,read('[data-analysis="'+mode+'"]','aria-pressed')=='true',text('#analyzer-description'))
    key('#selected-instance','ArrowRight');moved=read('#selected-instance','transform');run('press','R');rotated=read('#editable-botanical','transform');run('press','Home')
    test('Local edit keyboard move/rotate/reset',moved!='translate(302 223)' and 'rotate(15' in rotated and read('#selected-instance','transform')=='translate(302 223)',{'moved':moved,'rotated':rotated,'reset':read('#selected-instance','transform')})
    click('[data-gallery="0"]');run('press','ArrowRight');test('Environment viewer next',text('#gallery-dialog-title')=='A looser rhythm',text('#gallery-dialog-title'));run('press','Escape')
    test('Environment viewer Escape/focus',dom("!document.querySelector('#gallery-dialog').open&&document.activeElement.dataset.gallery==='0'"),'Closed and restored focus to courtyard opener')
    open('/guide');click('.planting-layer-study [data-view="layers"]');test('Planting layer study',run('get','count','.pls-artwork .layer-plane')=='4' and all(name in text('.pls-artwork') for name in ('Trees','Shrubs','Meadow','Ground cover')),'Four closer planting planes with Garden / Layers and Build up')
    open('/visuals/containers');test('Container collection begins off','Collection is disabled' in text('.lab-status'),text('.lab-status'));click('.lab-controls input[type="checkbox"]');test('Container inside membership','Inside' in text('.lab-status'),text('.lab-status'));key('#lesson-containers-position','Home');test('Container outside parking','Outside' in text('.lab-status'),text('.lab-status'))
    open('/visuals/coverage');key('#lesson-coverage-radius','Home');low=read('.teaching-drawing svg','aria-label');key('#lesson-coverage-radius','End');high=read('.teaching-drawing svg','aria-label');test('Coverage radius alters accepted result',low!=high,{'small':low,'large':high})
    open('/visuals/spacing');click('.lab-controls input[type="checkbox"]');key('#lesson-spacing-factor','End');select('#lesson-spacing-scope','layers');between=run('is','checked','.lab-controls input[type="checkbox"]');select('#lesson-spacing-scope','within');within=run('get','value','#lesson-spacing-factor');test('Independent spacing scopes',between=='false' and within=='2',{'betweenEnabled':between,'withinFactor':within})
    open('/visuals/updates');key('#lesson-updates-requested','End');pending=text('.lab-visual');test('Manual retains completed drawing','Last completed: 40' in pending and 'Current request: 100' in pending,pending);click('.lab-controls .btn.primary');test('Explicit update publishes','Last completed: 100' in text('.lab-visual'),text('.lab-status'));select('#lesson-update-mode','Live');key('#lesson-updates-requested','Home');run('wait','--text','Last completed drawing is current');test('Live publishes relevant edit','Last completed: 10' in text('.lab-visual'),text('.lab-visual'))
    open('/visuals/viewport');key('#lesson-viewport-budget','Home');test('Preview cap preserves accepted count','64 accepted' in text('.lab-status') and '0 shown' in text('.lab-status'),text('.lab-status'))
    for mode in ('Plant centres','Point Cloud','Proxy','Mesh'):
        select('#lesson-viewport-mode',mode);test('Display mode '+mode,read('#lesson-viewport-mode','data-value')==mode,mode)
    open('/gallery');test('All 19 posters',run('get','count','.poster-card')=='19','19 concept cards');click('button[aria-label="Enlarge Layered planting study"]');run('press','ArrowRight');test('Poster viewer current reading','Historical workflow sketch'==text('#poster-viewer-title') and 'retired' in text('.poster-viewer-copy'),text('#poster-viewer-title'));run('press','Escape');test('Poster Escape/focus',dom("!document.querySelector('.poster-viewer').open&&document.activeElement.getAttribute('aria-label')==='Enlarge Layered planting study'"),'Closed and restored focus');click('.poster-filter button:last-child');test('Poster series filter',0<int(run('get','count','.poster-card'))<19,run('get','count','.poster-card'))
    for cap,expected in [('C19','Rotation/scale/movement'),('C21','Edit/instance radius'),('C27','Statistics')]:
        open('/controls?feature='+cap);test('Semantic family '+cap,expected in text('.selected-capability') and int(run('get','count','.control-entry'))>0,text('.results-heading'))
    open('/controls?section=editor');test('Exact editor section filter',int(run('get','count','.control-entry'))>0,text('.results-heading'))
    run('press','Control+k');run('fill','.search-input input','nonexistentzzzz');run('press','ArrowDown');run('fill','.search-input input','Manual');run('press','Enter');run('wait','--fn',"location.hash!=='#/controls?section=editor'");test('Search empty-state then Enter',not dom("document.querySelector('.search-dialog').open"),run('get','url'))
    open('/checklist');click('.walkthrough-step:first-of-type>summary');click('#main .walkthrough-step:first-of-type input[type="checkbox"]');run('fill','#review-note-0','Selected design regression: receiver ownership observed.');open('/checklist');click('.walkthrough-step:first-of-type>summary');test('Local checklist persistence',run('is','checked','.walkthrough-step:first-of-type input')=='true' and 'receiver ownership observed' in run('get','value','#review-note-0'),text('.testing-progress'))
    # The CLI download subcommand cancels its own save; use an ordinary user click and the configured browser directory.
    download=download_dir/'cyrus-artist-walkthrough.txt'
    if download.is_file():download.unlink()
    click('.checklist-toolbar .row button:first-child')
    for _ in range(50):
        if download.is_file():break
        time.sleep(.1)
    test('Native file-save export',download.is_file() and 'receiver ownership observed' in download.read_text(encoding='utf-8'),str(download))
    click('.checklist-toolbar .row button:last-child');click('.callout.warning .row button:last-child');test('Reset cancellation retains notes','1 / 24' in text('.testing-progress'),text('.testing-progress'));click('.checklist-toolbar .row button:last-child');click('.callout.warning .row button:first-child');test('Confirmed local reset','0 / 24' in text('.testing-progress'),text('.testing-progress'))
    run('set','viewport','390','844');open('/guide');click('button[aria-label="Open documentation navigation"]');test('Mobile drawer opens',read('.sidebar','aria-modal')=='true','Modal drawer');run('press','Escape');test('Mobile drawer Escape/focus',dom("document.activeElement.getAttribute('aria-label')==='Open documentation navigation'"),'Focus returned to trigger');click('button[aria-label="Open documentation navigation"]');click('.sidebar a[href="#/workflow"]');test('Mobile link closes drawer',read('.sidebar','class')=='sidebar',run('get','url'))
    open('/');click('.menu-button');test('Landing mobile menu opens',read('.menu-button','aria-expanded')=='true','Expanded');run('press','Escape');test('Landing mobile menu Escape',read('.menu-button','aria-expanded')=='false','Collapsed')
    errors=run('errors');test('No browser runtime errors',not errors,errors or 'None')
    report={'scope':'Headless selected React design interaction checks, not plugin qualification','checks':checks,'count':len(checks),'status':'PASS'};target.write_text(json.dumps(report,indent=2)+'\n',encoding='utf-8');print(f'PASS: {len(checks)} interaction assertions')

if __name__=='__main__':main()
