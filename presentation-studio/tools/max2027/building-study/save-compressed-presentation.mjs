// Fresh owned browser fallback for the CLI's observed download cancellation.
import { chromium } from '@playwright/test';
import { readFile, writeFile, access } from 'node:fs/promises';
import { resolve } from 'node:path';
import { createHash } from 'node:crypto';
import { deepStrictEqual } from 'node:assert';
import { projectFiles, packSync, readProjectArchive } from '../../../src/storage/archive.ts';
import { validateProject } from '../../../src/core/model.ts';
import { contentFingerprint } from '../../../src/core/hash.ts';
const folder = resolve('exports/building-20261016'), state = JSON.parse(await readFile(`${folder}/authoring-state-meshopt-v1.json`, 'utf8'));
const run = process.argv[2] ?? 'v1'; if (!/^v\d+$/.test(run)) throw Error('Choose a fresh vN run.');
const names = [`fixture-meshopt-${run}-input.cyrus-presentation.zip`, 'BAILEY-meshopt-editable.cyrus-presentation.zip', 'BAILEY-meshopt-presentation.zip', `downloads-meshopt-${run}.json`];
for (const name of names) { try { await access(`${folder}/${name}`); throw Error(`Preserve ${name}`); } catch (e) { if (e.code !== 'ENOENT') throw e; } }
const project = validateProject(state.project), blobs = new Map();
for (const file of ['building-meshopt-trial-v2.glb', 'building-hero.camera.json']) {
  const bytes = new Uint8Array(await readFile(`${folder}/${file}`)); blobs.set(createHash('sha256').update(bytes).digest('hex'), bytes);
}
const sameProject = actual => deepStrictEqual(contentFingerprint(actual), contentFingerprint(project));
const fixture = packSync(await projectFiles(project, blobs)); sameProject((await readProjectArchive(fixture)).project);
await writeFile(`${folder}/${names[0]}`, fixture, { flag: 'wx' });
const browser = await chromium.launch({ headless: true, channel: 'chromium' }), page = await browser.newPage({ viewport: { width: 1600, height: 1000 } }), errors = [], rows = [];
page.on('pageerror', e => errors.push(e.message));
try {
  await page.goto('http://127.0.0.1:5190/'); await page.waitForFunction(() => window.__cyrusStudio?.ready);
  await page.getByLabel('Open project archive', { exact: true }).setInputFiles(`${folder}/${names[0]}`);
  await page.waitForFunction(id => window.__cyrusStudio.controller.project.id === id && !window.__cyrusStudio.controller.pending, project.id);
  await page.waitForFunction(() => window.__cyrusStudio.controller.storageStatus === 'Saved locally');
  await page.reload(); await page.waitForFunction(() => window.__cyrusStudio?.ready);
  sameProject(await page.evaluate(() => window.__cyrusStudio.controller.project));
  for (const [menu, action, name] of [['project-menu', 'save-project', names[1]], ['output-menu', 'export-website', names[2]]]) {
    const event = page.waitForEvent('download'), began = performance.now(); await page.getByTestId(menu).click(); await page.getByTestId(action).click();
    const download = await event; await download.saveAs(`${folder}/${name}`); const bytes = await readFile(`${folder}/${name}`);
    rows.push({ name, bytes: bytes.length, sha256: createHash('sha256').update(bytes).digest('hex'), elapsedMs: performance.now() - began }); console.log(JSON.stringify(rows.at(-1)));
  }
  await page.getByLabel('Open project archive', { exact: true }).setInputFiles(`${folder}/${names[1]}`);
  await page.waitForFunction(() => window.__cyrusStudio.controller.status === 'Portable project opened' && !window.__cyrusStudio.controller.pending);
  sameProject(await page.evaluate(() => window.__cyrusStudio.controller.project));
  await page.getByTestId('output-menu').click(); await page.getByTestId('preview-export').click();
  const frame = page.frames().find(f => f.parentFrame() === page.mainFrame()); await frame.waitForFunction(() => window.__cyrusPlayer?.ready);
  await frame.evaluate(() => window.__cyrusPlayer.setTime(16));
  const preview = await frame.evaluate(() => ({ project: window.__cyrusPlayer.project, evaluation: window.__cyrusPlayer.evaluation, stats: { ...window.__cyrusPlayer.stats } }));
  if (preview.stats.rebuilds !== 1 || preview.project.segments[0].cameraClip.hash !== project.segments[0].cameraClip.hash) throw Error('Compiled preview did not load the building and camera.');
  await page.screenshot({ path: `${folder}/meshopt-browser-v4/compiled-preview.png` }); await page.getByTestId('close-preview').click();
  if (await page.getByTestId('error').isVisible()) throw Error(await page.getByTestId('error').innerText());
  await writeFile(`${folder}/${names[3]}`, JSON.stringify({ browser: browser.version(), channel: 'chromium', freshOwnedContext: true, autosaveReopen: true, exactPortableReopen: true, actualMenuDownloads: rows, compiledPreview: preview, errors }, null, 2) + '\n', { flag: 'wx' });
  if (errors.length) throw Error(errors.join('\n'));
} finally { await browser.close(); }
