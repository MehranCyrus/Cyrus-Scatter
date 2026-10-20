import { menuAction } from './ui-actions';
import { test, expect, type Page } from '@playwright/test';
import { readFile, mkdir, writeFile } from 'node:fs/promises';
import { resolve } from 'node:path';
import { unzipSync, zipSync } from 'fflate';
import { createServer, type Server } from 'node:http';
import { demoGLB } from '../../src/assets/demo';
const app = (page: Page, fn: string): Promise<any> => page.evaluate(fn);
async function ready(page: Page) { await page.goto('/'); await page.waitForFunction(() => (window as any).__cyrusStudio?.ready); await expect(page.getByTestId('error')).toBeHidden(); }
async function action(page: Page, name: string, payload?: unknown) { await page.evaluate(async ({ name, payload }) => { await (window as any).__cyrusStudio.controller.act(name, payload); }, { name, payload }); }
test.beforeEach(async ({ page }) => { await ready(page); });

test('studio opens, layout fits and title command survives focused updates with undo/redo', async ({ page }) => {
  await expect(page.getByTestId('studio')).toBeVisible(); const title = page.getByRole('textbox', { name: 'Project title' });
  await title.fill('My courtyard'); await title.press('Tab'); await expect(title).toHaveValue('My courtyard');
  await page.getByTestId('undo').click(); await expect(title).toHaveValue('The courtyard garden'); await page.getByTestId('redo').click(); await expect(title).toHaveValue('My courtyard');
  await page.setViewportSize({ width: 1280, height: 625 }); const status = await page.getByTestId('status').boundingBox(); expect(status!.y + status!.height).toBeLessThanOrEqual(625);
  await page.screenshot({ path: 'test-results/studio-desktop.png' });
});

test('selection and ten-second static idle avoid renders, rebuilds and buffer uploads', async ({ page }) => {
  await page.getByRole('button', { name: /01 The masterplan/ }).click(); await page.waitForTimeout(300); const before = await app(page, '({...window.__cyrusStudio.controller.host.stats})');
  await page.waitForTimeout(10000);
  const after = await app(page, '({...window.__cyrusStudio.controller.host.stats})'); expect(after.renders).toBe(before.renders); expect(after.rebuilds).toBe(before.rebuilds); expect(after.uploads).toBe(before.uploads);
});

test('layer visibility reuses geometry and camera scrubbing does not upload static buffers', async ({ page }) => {
  await page.waitForTimeout(300); const before = await app(page, '({...window.__cyrusStudio.controller.host.stats})');
  await page.getByTestId('scene-toggle').click(); await page.getByRole('checkbox', { name: 'Show Trees initially', exact: true }).uncheck(); await page.waitForTimeout(200);
  await action(page, 'time', 17); await page.waitForTimeout(200); const after = await app(page, '({...window.__cyrusStudio.controller.host.stats})');
  expect(after.rebuilds).toBe(before.rebuilds); expect(after.uploads).toBe(before.uploads); expect(after.renders).toBeGreaterThan(before.renders);
});

test('Explore does not mutate authored stops; capture, retime, reverse and delete do', async ({ page }) => {
  const before = await app(page, 'JSON.stringify(window.__cyrusStudio.controller.project.stops)'); const box = await page.getByTestId('viewport').boundingBox();
  await page.mouse.move(box!.x + box!.width / 2, box!.y + box!.height / 2); await page.mouse.down(); await page.mouse.move(box!.x + box!.width / 2 + 60, box!.y + box!.height / 2 + 20, { steps: 8 }); await page.mouse.up();
  expect(await app(page, 'JSON.stringify(window.__cyrusStudio.controller.project.stops)')).toBe(before);
  await page.getByTestId('camera-primary-action').click(); expect(await app(page, 'window.__cyrusStudio.controller.project.stops.length')).toBe(5);
  const id = await app(page, 'window.__cyrusStudio.controller.cameraEditingStopId'); await action(page, 'moveTimelineKeys', { cameraIds: [id], delta: 12 });
  expect(await app(page, 'window.__cyrusStudio.controller.project.stops[1].id')).toBe(id); await action(page, 'deleteStop', id); expect(await app(page, 'window.__cyrusStudio.controller.project.stops.length')).toBe(4);
  await action(page, 'time', 20); await action(page, 'reverse'); await page.waitForTimeout(300); await action(page, 'pause'); expect(await app(page, 'window.__cyrusStudio.controller.time')).toBeLessThan(20);
});

test('portable archive preserves originals and restores in a fresh browser context', async ({ page, browser }) => {
  await page.getByRole('textbox', { name: 'Project title' }).fill('Portable garden'); await page.getByRole('textbox', { name: 'Project title' }).press('Tab');
  const download = page.waitForEvent('download'); await menuAction(page, 'project-menu', 'save-project'); const archive = await download, path = await archive.path(); const bytes = await readFile(path!), files = unzipSync(bytes), data = JSON.parse(new TextDecoder().decode(files['project.json']));
  expect(data.title).toBe('Portable garden'); expect(Object.keys(files).some(p => p.startsWith('blobs/'))).toBe(true);
  const context = await browser.newContext(), reopened = await context.newPage(); await ready(reopened); await reopened.getByLabel('Open project archive', { exact: true }).setInputFiles({ name: 'project.zip', mimeType: 'application/zip', buffer: bytes });
  await expect(reopened.getByRole('textbox', { name: 'Project title' })).toHaveValue('Portable garden'); expect(await app(reopened, 'window.__cyrusStudio.controller.project.id')).toBe(data.id); await context.close();
});

test('corrupt archive and GLB imports retain the previous complete project', async ({ page }) => {
  const before = await app(page, 'JSON.stringify(window.__cyrusStudio.controller.project)');
  await page.getByLabel('Open project archive', { exact: true }).setInputFiles({ name: 'bad.zip', mimeType: 'application/zip', buffer: Buffer.from('invalid') }); await expect(page.getByTestId('error')).toBeVisible();
  expect(await app(page, 'JSON.stringify(window.__cyrusStudio.controller.project)')).toBe(before);
  await page.getByLabel('Import landscape GLB', { exact: true }).setInputFiles({ name: 'bad.glb', mimeType: 'model/gltf-binary', buffer: Buffer.from('invalid') }); await expect(page.getByTestId('error')).toContainText('GLB'); expect(await app(page, 'JSON.stringify(window.__cyrusStudio.controller.project)')).toBe(before);
});

test('reviewed GLB replacement keeps layer IDs and undo restores the original asset', async ({ page }) => {
  const before = await app(page, '({hash:window.__cyrusStudio.controller.project.assets[0].hash,layers:window.__cyrusStudio.controller.project.layers.map(x=>x.id)})');
  await page.getByTestId('scene-toggle').click(); await page.locator('#hierarchy-body .asset-row').first().click();
  const choosing = page.waitForEvent('filechooser'); await page.getByRole('button', { name: 'Replace GLB…', exact: true }).click();
  await (await choosing).setFiles({ name: 'revision.glb', mimeType: 'model/gltf-binary', buffer: Buffer.from(demoGLB(1949)) });
  await expect(page.getByRole('dialog')).toBeVisible(); await page.getByRole('button', { name: 'Confirm replacement' }).click(); await expect(page.getByRole('dialog')).toBeHidden();
  expect(await app(page, 'window.__cyrusStudio.controller.project.layers.map(x=>x.id)')).toEqual(before.layers); await page.getByTestId('undo').click(); expect(await app(page, 'window.__cyrusStudio.controller.project.assets[0].hash')).toBe(before.hash);
});

test('compiled preview starts the actual built player and excludes editor controls', async ({ page }) => {
  const errors: string[] = []; page.on('pageerror', e => errors.push(e.message)); await menuAction(page, 'output-menu', 'preview-export');
  const frame = page.frameLocator('iframe'); await expect(frame.getByTestId('player')).toBeVisible();
  await expect(frame.getByRole('button', { name: 'Go to The pavilion' })).toBeVisible(); await frame.getByRole('button', { name: 'Go to The pavilion' }).click();
  await expect(frame.getByRole('heading', { name: 'The pavilion' })).toBeVisible(); await expect(frame.getByRole('button', { name: 'Save project' })).toHaveCount(0); expect(errors).toEqual([]);
  await page.getByRole('button', { name: 'Close preview' }).click(); expect(await app(page, 'window.__cyrusStudio.controller.mode')).toBe('explore');
});

test('export runs independently at a nested HTTP path with parity, layers, portrait and reduced motion', async ({ page, browser }) => {
  const downloading = page.waitForEvent('download'); await menuAction(page, 'output-menu', 'export-website'); const download = await downloading, files = unzipSync(await readFile((await download.path())!));
  expect(files['project.json']).toBeUndefined(); expect(Object.keys(files).some(path => /studio|originals|\.map$/.test(path))).toBe(false);
  const manifest = JSON.parse(new TextDecoder().decode(files['manifest.json'])); expect(manifest.project.schemaVersion).toBe(1);
  const server = createServer((req, res) => { const path = decodeURIComponent((req.url ?? '').split('?')[0]).replace(/^\/presentations\/example\//, '') || 'index.html', bytes = files[path]; if (!bytes) { res.writeHead(404); res.end(); return; } res.setHeader('Content-Type', path.endsWith('.js') ? 'text/javascript' : path.endsWith('.css') ? 'text/css' : path.endsWith('.html') ? 'text/html' : path.endsWith('.json') ? 'application/json' : 'application/octet-stream'); res.end(bytes); });
  await new Promise<void>(resolve => server.listen(0, '127.0.0.1', resolve)); const address = server.address() as { port: number }, origin = `http://127.0.0.1:${address.port}`;
  const context = await browser.newContext(), player = await context.newPage(), external: string[] = [], errors: string[] = [];
  player.on('request', req => { if (!req.url().startsWith(origin) && !req.url().startsWith('blob:')) external.push(req.url()); }); player.on('pageerror', error => errors.push(error.message));
  try {
    await player.goto(`${origin}/presentations/example/`); await player.waitForFunction(() => (window as any).__cyrusPlayer?.ready);
    await player.getByRole('button', { name: 'Go to The pavilion' }).click(); const e = await player.evaluate(() => (window as any).__cyrusPlayer.evaluation);
    const expected = await page.evaluate(time => (window as any).__cyrusStudio.controller.evaluator.evaluate(time), await player.evaluate(() => (window as any).__cyrusPlayer.time)); expect(e.position).toEqual(expected.position);
    await expect(player.locator('canvas')).toHaveCSS('touch-action', 'pan-y'); expect(await player.evaluate(() => scrollY)).toBeGreaterThan(0);
    await player.getByRole('button', { name: 'Layers' }).click(); await player.getByRole('checkbox', { name: 'Trees', exact: true }).uncheck(); expect(await player.evaluate(() => Object.values((window as any).__cyrusPlayer.choices))).toEqual([false]);
    await player.setViewportSize({ width: 390, height: 844 }); await player.getByRole('button', { name: 'Reduced motion' }).click(); await expect(player.getByRole('button', { name: 'Reduced motion' })).toHaveAttribute('aria-pressed', 'true');
    await player.screenshot({ path: 'test-results/player-mobile.png' }); expect(external).toEqual([]); expect(errors).toEqual([]);
  } finally { await context.close(); await new Promise<void>(resolve => server.close(() => resolve())); }
  await mkdir('exports', { recursive: true }); await writeFile(resolve('exports/presentation.zip'), zipSync(files));
});
