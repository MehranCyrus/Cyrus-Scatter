import { test, expect, type Page } from '@playwright/test';
import { mkdir, readFile, writeFile } from 'node:fs/promises';
import { resolve } from 'node:path';
import { createServer } from 'node:http';
import { unzipSync } from 'fflate';
import sharp from 'sharp';
import { meshoptFixture } from '../helpers/meshopt-fixture';
import { inspectGLB, readGLB, writeGLB } from '../../src/assets/glb';
import { MESHOPT } from '../../src/assets/meshopt';
import { menuAction } from './ui-actions';
const folder = resolve('exports/fixtures/meshopt');
test.beforeAll(async () => { const data = await meshoptFixture(); await mkdir(folder, { recursive: true }); await writeFile(`${folder}/source.glb`, data.original); await writeFile(`${folder}/compressed.glb`, data.compressed); });
async function ready(page: Page) { await page.goto('/'); await page.waitForFunction(() => (window as any).__cyrusStudio?.ready); }
async function importFile(page: Page, file: string) { await page.evaluate(async () => { await (window as any).__cyrusStudio.controller.act('newProject'); }); await page.getByLabel('Import landscape GLB', { exact: true }).setInputFiles(`${folder}/${file}`); await page.waitForFunction(() => !(window as any).__cyrusStudio.controller.pending && (window as any).__cyrusStudio.controller.project.assets.length === 1); await expect(page.getByTestId('error')).toBeHidden(); }

test('compressed geometry matches the original render and survives layer pruning, compiled preview and standalone HTTP', async ({ page, browser }) => {
  const errors: string[] = []; page.on('pageerror', e => errors.push(e.message)); await ready(page);
  const captures: Buffer[] = [];
  for (const name of ['source.glb', 'compressed.glb']) {
    await importFile(page, name);
    const image = await page.evaluate(async () => {
      const c = (window as any).__cyrusStudio.controller;
      await c.act('updateProject', { lighting: { exposure: 1, shadows: false } }); await c.act('mode', 'explore'); await c.act('time', 100);
      c.host.perspective.position.set(65, 65, 85); c.host.perspective.lookAt(0, 0, 0); c.host.draw(); return c.host.canvas.toDataURL('image/png');
    }); captures.push(Buffer.from(image.split(',')[1], 'base64'));
  }
  await writeFile(`${folder}/source-render.png`, captures[0]); await writeFile(`${folder}/compressed-render.png`, captures[1]);
  const a = await sharp(captures[0]).raw().toBuffer(), b = await sharp(captures[1]).raw().toBuffer(); let difference = 0;
  expect(b.length).toBe(a.length); for (let i = 0; i < a.length; i++) difference += Math.abs(a[i] - b[i]); expect(difference / a.length).toBeLessThan(.1);
  await page.evaluate(async () => { const c = (window as any).__cyrusStudio.controller; await c.act('updateStop', { id: c.project.stops[0].id, patch: c.host.capture() }); for (const layer of c.project.layers) if (layer.name !== 'Site') await c.act('updateLayer', { id: layer.id, patch: { included: false } }); });
  const before = await page.evaluate(() => ({ ...(window as any).__cyrusStudio.controller.host.stats }));
  await page.evaluate(async () => { const c = (window as any).__cyrusStudio.controller; for (const time of [9, 10, 12, 11, 10]) { await c.act('time', time); c.host.draw(); } });
  const after = await page.evaluate(() => ({ ...(window as any).__cyrusStudio.controller.host.stats })); expect(after.rebuilds).toBe(before.rebuilds); expect(after.uploads).toBe(before.uploads);
  await menuAction(page, 'output-menu', 'preview-export');
  const preview = page.frames().find(f => f.parentFrame() === page.mainFrame())!;
  await preview.waitForFunction(() => (window as any).__cyrusPlayer?.ready); await preview.evaluate(() => (window as any).__cyrusPlayer.setTime(100));
  expect(await preview.evaluate(() => (window as any).__cyrusPlayer.project.layers.map((l: any) => l.name))).toEqual(['Site']);
  await page.getByTestId('close-preview').click();
  const download = page.waitForEvent('download'); await menuAction(page, 'output-menu', 'export-website'); const files = unzipSync(await readFile((await (await download).path())!));
  const manifest = JSON.parse(new TextDecoder().decode(files['manifest.json'])), model = manifest.resources[manifest.project.assets[0].hash], raw = readGLB(files[model.path]); expect(raw.json.extensionsRequired).toContain(MESHOPT);
  const published = await inspectGLB(files[model.path], 'pruned fixture'); expect(published.triangles).toBe(24); // Ground box and reflection-basin box.
  const server = createServer((req, res) => { const path = new URL(req.url!, 'http://local').pathname.replace(/^\/nested\/meshopt\//, '') || 'index.html', bytes = files[path]; if (!bytes) { res.writeHead(404).end(); return; } res.setHeader('Content-Type', path.endsWith('.js') ? 'text/javascript' : path.endsWith('.html') ? 'text/html' : path.endsWith('.css') ? 'text/css' : 'application/octet-stream'); res.end(bytes); });
  await new Promise<void>(r => server.listen(0, '127.0.0.1', r)); const origin = `http://127.0.0.1:${(server.address() as any).port}`, context = await browser.newContext(), player = await context.newPage(), external: string[] = [];
  player.on('pageerror', e => errors.push(e.message)); player.on('request', r => { if (!r.url().startsWith(origin) && !r.url().startsWith('blob:')) external.push(r.url()); });
  try { await player.goto(`${origin}/nested/meshopt/`); await player.waitForFunction(() => (window as any).__cyrusPlayer?.ready); await player.evaluate(() => (window as any).__cyrusPlayer.setTime(100)); await player.waitForFunction(triangles => (window as any).__cyrusPlayer.stats.triangles === triangles, published.triangles); expect(external).toEqual([]); expect(errors).toEqual([]); }
  finally { try { await context.close(); } finally { server.closeAllConnections(); await new Promise<void>(r => server.close(() => r())); } }
});

test('bad compressed data and understated archive resources retain the published scene', async ({ page }) => {
  await ready(page); await importFile(page, 'compressed.glb');
  const result = await page.evaluate(async () => {
    const c = (window as any).__cyrusStudio.controller, p = structuredClone(c.project), mount = document.createElement('div'); mount.style.cssText = 'width:600px;height:400px'; document.body.append(mount);
    const host = new (c.host.constructor as any)(mount, false); p.assets[0].gpuBytes = p.assets[0].instanceBytes ?? 0; let error = '';
    try { await host.prepare(p, c.blobs); } catch (e) { error = String(e); } finally { host.dispose(); mount.remove(); } return error;
  }); expect(result).toContain('understates decoded resources');
  const before = await page.evaluate(() => ({ id: (window as any).__cyrusStudio.controller.project.id, ...(window as any).__cyrusStudio.controller.host.stats }));
  const source = readGLB(await readFile(`${folder}/compressed.glb`)), view = source.json.bufferViews.find((v: any) => v.extensions?.[MESHOPT]), broken = source.bin.slice(); broken[view.extensions[MESHOPT].byteOffset ?? 0] = 0;
  await page.getByLabel('Import landscape GLB', { exact: true }).setInputFiles({ name: 'broken.glb', mimeType: 'model/gltf-binary', buffer: Buffer.from(writeGLB(source.json, broken)) });
  await expect(page.getByTestId('error')).toBeVisible(); const after = await page.evaluate(() => ({ id: (window as any).__cyrusStudio.controller.project.id, ...(window as any).__cyrusStudio.controller.host.stats }));
  expect(after.id).toBe(before.id); expect(after.rebuilds).toBe(before.rebuilds); expect(after.uploads).toBe(before.uploads);
});
