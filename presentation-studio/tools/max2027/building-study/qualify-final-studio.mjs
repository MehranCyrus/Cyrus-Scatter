import {chromium} from '@playwright/test';
import {readFile,writeFile} from 'node:fs/promises';
import assert from 'node:assert/strict';
import {contentFingerprint} from '../../../src/core/hash.ts';
const folder='exports/building-20261016',out=folder+'/final-presentation-v1',browser=await chromium.launch({headless:true,channel:'chromium'}),page=await browser.newPage({viewport:{width:1600,height:1000}}),errors=[];
page.on('pageerror',e=>errors.push(e.message));
const state=()=>page.evaluate(()=>{const c=window.__cyrusStudio.controller;return {project:c.project,pose:c.host.capture(),plan:{position:c.host.planCamera.position.toArray(),zoom:c.host.planCamera.zoom},mode:c.mode,stats:{...c.host.stats},editing:c.cameraEditingStopId};});
const settle=()=>page.evaluate(async()=>{await new Promise(requestAnimationFrame);await new Promise(requestAnimationFrame);});
try{
 await page.goto('http://127.0.0.1:5190/');await page.waitForFunction(()=>window.__cyrusStudio?.ready);const sample=await state();
 await page.getByLabel('Import landscape GLB',{exact:true}).setInputFiles(folder+'/baseline-native.glb');await page.waitForFunction(()=>!window.__cyrusStudio.controller.pending&&Boolean(window.__cyrusStudio.controller.error));
 const baselineRejection=await page.getByTestId('error').innerText();assert.match(baselineRejection,/250 MiB/);assert.equal(contentFingerprint((await state()).project),contentFingerprint(sample.project));
 const began=performance.now();await page.getByLabel('Import landscape GLB',{exact:true}).setInputFiles(folder+'/reproduction-v4/delivery/optimized.glb');await page.waitForFunction(()=>!window.__cyrusStudio.controller.pending&&window.__cyrusStudio.controller.project.assets.some(a=>a.hash==='d8e30599ddc541a5c6170ec1fc27fd4c52423c02e2c0c5f218624a164056727e'));
 const localGLBImportMs=performance.now()-began;assert.ok(localGLBImportMs<=15000);const imported=(await state()).project.assets.find(a=>a.hash==='d8e30599ddc541a5c6170ec1fc27fd4c52423c02e2c0c5f218624a164056727e');assert.equal(imported.triangles,2840802);
 await page.getByLabel('Open project archive',{exact:true}).setInputFiles(out+'/BAILEY-editable.cyrus-presentation.zip');await page.waitForFunction(()=>window.__cyrusStudio.controller.project.title.startsWith('BAILEY')&&!window.__cyrusStudio.controller.pending);
 const original=await state(),fingerprint=contentFingerprint(original.project),canvas=page.locator('[data-testid=viewport] canvas');await page.getByTestId('viewport-mode').selectOption('camera');
 const navigation=[];
 async function drag(button='left',dx=70,dy=25){const b=await canvas.boundingBox();await page.mouse.move(b.x+b.width*.5,b.y+b.height*.5);await page.mouse.down({button});await page.mouse.move(b.x+b.width*.5+dx,b.y+b.height*.5+dy,{steps:8});await page.mouse.up({button});await settle();}
 for(const gesture of ['look','pan','wheel','keyboard']){
  const before=await state();
  if(gesture==='look')await drag();else if(gesture==='pan')await drag('middle');else if(gesture==='wheel'){const b=await canvas.boundingBox();await page.mouse.move(b.x+b.width*.5,b.y+b.height*.5);await page.mouse.wheel(0,-180);await settle();}else{await canvas.focus();await page.keyboard.down('KeyW');await page.waitForTimeout(250);await page.keyboard.up('KeyW');await settle();}
  const after=await state();assert.notDeepEqual(after.pose,before.pose,gesture);assert.equal(contentFingerprint(after.project),fingerprint);assert.equal(after.stats.rebuilds,before.stats.rebuilds);assert.equal(after.stats.uploads,before.stats.uploads);navigation.push({gesture,before:before.pose,after:after.pose});
 }
 const moved=await state();await page.getByTestId('camera-primary-action').click();let captured=await state();assert.deepEqual(captured.project.stops.at(-1).position,moved.pose.position);assert.deepEqual(captured.project.stops.at(-1).quaternion,moved.pose.quaternion);assert.equal(captured.editing,captured.project.stops.at(-1).id);
 await drag('middle',25,-10);const draft=await state();await page.getByTestId('camera-primary-action').click();assert.deepEqual((await state()).project.stops.at(-1).position,draft.pose.position);
 await page.getByTestId('undo').click();await page.getByTestId('undo').click();assert.equal(contentFingerprint((await state()).project),fingerprint);
 for(const mode of ['orbit','plan']){
  await page.getByTestId('viewport-mode').selectOption(mode);const before=await state();await drag();const b=await canvas.boundingBox();await page.mouse.move(b.x+b.width*.5,b.y+b.height*.5);await page.mouse.wheel(0,-180);await settle();const after=await state();
  if(mode==='orbit')assert.notDeepEqual(after.pose,before.pose);
  else {assert.notDeepEqual(after.plan,before.plan);assert.equal(await page.getByTestId('camera-primary-action').isDisabled(),true);}
  assert.equal(contentFingerprint(after.project),fingerprint);navigation.push({gesture:mode+' pan/orbit and zoom',before:before.pose,after:after.pose});
 }
 await page.getByTestId('scene-toggle').click();const visible=page.getByRole('checkbox',{name:'Show Street furniture',exact:true});const checked=await visible.isChecked();await visible.setChecked(!checked);await page.getByTestId('undo').click();assert.equal(await visible.isChecked(),checked);
 assert.equal(contentFingerprint((await state()).project),fingerprint);await page.getByTestId('viewport-mode').selectOption('playback');
 await page.evaluate(async()=>{const c=window.__cyrusStudio.controller;await c.act('time',2);});const beforeSeek=await state();
 for(const t of [38,29,16,7,2,9.123,35.777])await page.getByRole('slider',{name:'Presentation time in seconds',exact:true}).evaluate((e,t)=>{e.value=String(t);e.dispatchEvent(new Event('input',{bubbles:true}));},t);
 const afterSeek=await state();assert.equal(afterSeek.stats.rebuilds,beforeSeek.stats.rebuilds);assert.equal(afterSeek.stats.uploads,beforeSeek.stats.uploads);assert.equal(contentFingerprint(afterSeek.project),fingerprint);
 await page.screenshot({path:out+'/studio-workflow.png'});assert.equal(errors.length,0);
 const report={browser:browser.version(),freshOwnedContext:true,baselineRejection,baselineRetainsPublishedSample:true,localGLBImportMs,sourceTriangles:imported.triangles,navigation,captureSaveUndo:true,layerUndo:true,seekReuse:true,authoredProjectPreserved:true,errors};await writeFile(out+'/studio-workflow.json',JSON.stringify(report,null,2));console.log(JSON.stringify({localGLBImportMs,baselineRejection,navigation:navigation.map(n=>n.gesture),captureSaveUndo:true,layerUndo:true,errors}));
}finally{await browser.close();}
