// Fallback for agent-browser's observed cancelled download; a fresh owned context.
import {chromium} from '@playwright/test';
import {readFile,writeFile} from 'node:fs/promises';
import {resolve} from 'node:path';
import {createHash} from 'node:crypto';
const folder=resolve('exports/building-20261016'),state=JSON.parse(await readFile(`${folder}/authoring-state-v1.json`,'utf8'));
const browser=await chromium.launch({headless:true}),page=await browser.newPage({viewport:{width:1600,height:1000}}),errors=[],rows=[];
page.on('pageerror',e=>errors.push(e.message));
try {
    await page.goto('http://127.0.0.1:5190/');await page.waitForFunction(()=>window.__cyrusStudio?.ready);
    await page.getByLabel('Open project archive',{exact:true}).setInputFiles(`${folder}/fixture-input.cyrus-presentation.zip`);
    await page.waitForFunction(id=>window.__cyrusStudio.controller.project.id===id,state.project.id);
    await page.waitForFunction(()=>window.__cyrusStudio.controller.storageStatus==='Saved locally');
    await page.reload();await page.waitForFunction(()=>window.__cyrusStudio?.ready);
    const reopened=await page.evaluate(()=>({id:window.__cyrusStudio.controller.project.id,lighting:window.__cyrusStudio.controller.project.lighting,clip:window.__cyrusStudio.controller.project.segments[0]?.cameraClip}));
    if(reopened.id!==state.project.id||reopened.clip?.hash!==state.project.segments[0].cameraClip.hash||reopened.lighting.style!=='architectural')throw Error('Autosave reopen differs.');
    for(const [menu,action,name] of [['project-menu','save-project','BAILEY-editable.cyrus-presentation.zip'],['output-menu','export-website','BAILEY-presentation.zip']]) {
        const event=page.waitForEvent('download'),started=performance.now();await page.getByTestId(menu).click();await page.getByTestId(action).click();
        const download=await event;await download.saveAs(`${folder}/${name}`);const bytes=await readFile(`${folder}/${name}`);
        rows.push({name,bytes:bytes.length,sha256:createHash('sha256').update(bytes).digest('hex'),elapsedMs:performance.now()-started});console.log(JSON.stringify(rows.at(-1)));
    }
    await page.getByLabel('Open project archive',{exact:true}).setInputFiles(`${folder}/BAILEY-editable.cyrus-presentation.zip`);
    await page.waitForFunction(()=>window.__cyrusStudio.controller.status==='Portable project opened');
    if(await page.getByTestId('error').isVisible())throw Error(await page.getByTestId('error').innerText());
    await writeFile(`${folder}/downloads-v2.json`,JSON.stringify({browser:browser.version(),freshOwnedContext:true,autosaveReopen:reopened,actualMenuDownloads:rows,portableReopen:true,errors},null,2)+'\n');
    if(errors.length)throw Error(errors.join('\n'));
} finally {await browser.close();}
