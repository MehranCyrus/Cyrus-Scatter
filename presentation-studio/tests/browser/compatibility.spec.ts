import { menuAction } from './ui-actions';
import { test, expect } from '@playwright/test';
import { existsSync } from 'node:fs';
import { resolve } from 'node:path';
import { readFile } from 'node:fs/promises';
import { createServer } from 'node:http';
import { unzipSync } from 'fflate';

test('Khronos embedded textures, alpha modes and normals survive actual compiled playback', async ({ page }) => {
  const names = ['BoxTextured', 'AlphaBlendModeTest', 'NormalTangentTest'];
  test.skip(names.some(name => !existsSync(resolve(`exports/fixtures/khronos/${name}.glb`))), 'Opt-in fixtures: run node tools/fetch-test-assets.mjs');
  await page.goto('/'); await page.waitForFunction(() => (window as any).__cyrusStudio?.ready);
  for (const name of names) {
    await page.evaluate(async () => { await (window as any).__cyrusStudio.controller.act('newProject'); });
    await page.getByLabel('Import landscape GLB', { exact: true }).setInputFiles(resolve(`exports/fixtures/khronos/${name}.glb`));
    await expect(page.getByTestId('status')).toContainText(`Imported ${name}.glb`); await expect(page.getByTestId('error')).toBeHidden();
    const before = await page.evaluate(async () => {
      const c = (window as any).__cyrusStudio.controller, asset = c.project.assets[0], min = asset.bounds.min, max = asset.bounds.max;
      const target = min.map((n: number, i: number) => (n + max[i]) / 2), extent = Math.max(...max.map((n: number, i: number) => n - min[i]), 1);
      await c.act('updateStop', { id: c.project.stops[0].id, patch: { position: [target[0] + extent, target[1] + extent * .6, target[2] + extent * 1.5] } });
      await c.act('lookTarget', { id: c.project.stops[0].id, target }); await c.act('updateProject', { opening: 0, revealDuration: 0 });
      const materials: any[] = []; c.host.active.group.traverse((o: any) => { for (const m of [].concat(o.material ?? [])) materials.push(m); });
      return { calls: c.host.stats.calls, position: c.project.stops[0].position, mapped: materials.some(m => !!m.map), normal: materials.some(m => !!m.normalMap), alpha: materials.some(m => m.transparent || m.alphaTest > 0) };
    });
    if (name === 'BoxTextured') expect(before.mapped).toBe(true);
    if (name === 'AlphaBlendModeTest') expect(before.alpha).toBe(true);
    if (name === 'NormalTangentTest') expect(before.normal).toBe(true);
    await menuAction(page, 'output-menu', 'preview-export'); const frame = page.frameLocator('iframe');
    await expect(frame.getByTestId('player')).toBeVisible();
    await expect.poll(() => page.frames()[1]?.evaluate(() => (window as any).__cyrusPlayer?.ready).catch(() => false)).toBe(true);
    await expect.poll(() => page.frames()[1]?.evaluate(() => (window as any).__cyrusPlayer?.stats.calls ?? 0).catch(() => 0)).toBeGreaterThan(0);
    expect(await page.frames()[1].evaluate(() => (window as any).__cyrusPlayer.evaluation.position)).toEqual(before.position);
    await frame.locator('canvas').screenshot({ path: `test-results/khronos-${name}.png` });
    await page.getByRole('button', { name: 'Close preview', exact: true }).click();
  }
});

test('public player without WebGL2 keeps the plan and stop navigation available', async ({ page }) => {
  await page.goto('/'); await page.waitForFunction(() => (window as any).__cyrusStudio?.ready);
  await page.addInitScript(() => {
    const getContext = HTMLCanvasElement.prototype.getContext;
    HTMLCanvasElement.prototype.getContext = function (this: HTMLCanvasElement, kind: any, ...args: any[]) { return kind === 'webgl2' ? null : (getContext as any).call(this, kind, ...args); } as any;
  });
  await menuAction(page, 'output-menu', 'preview-export'); const frame = page.frameLocator('iframe');
  await expect(frame.getByRole('status')).toContainText('cannot display WebGL2');
  await expect(frame.locator('img[alt="Calibrated landscape plan"]')).toHaveCSS('opacity', '1');
  await frame.getByRole('button', { name: 'Go to The pavilion' }).click(); await expect(frame.getByRole('heading', { name: 'The pavilion' })).toBeVisible();
  await frame.getByRole('button', { name: 'Layers', exact: true }).click(); await expect(frame.getByRole('checkbox', { name: 'Trees', exact: true })).toBeDisabled();
});

test('a corrupt public GLB keeps the plan navigable and disables unavailable 3D layer controls', async ({ page, browser }) => {
  await page.goto('/'); await page.waitForFunction(() => (window as any).__cyrusStudio?.ready);
  const download = page.waitForEvent('download'); await menuAction(page, 'output-menu', 'export-website'); const files = unzipSync(await readFile((await (await download).path())!));
  const manifest = JSON.parse(new TextDecoder().decode(files['manifest.json'])), asset = manifest.project.assets[0]; files[manifest.resources[asset.hash].path][0] ^= 1;
  const server = createServer((req, res) => { const path = (req.url ?? '/').slice(1) || 'index.html', bytes = files[path]; if (!bytes) { res.writeHead(404).end(); return; } res.setHeader('Content-Type', path.endsWith('.js') ? 'text/javascript' : path.endsWith('.css') ? 'text/css' : path.endsWith('.html') ? 'text/html' : 'application/octet-stream'); res.end(bytes); });
  await new Promise<void>(r => server.listen(0, '127.0.0.1', r)); const context = await browser.newContext(), player = await context.newPage();
  try {
    await player.goto(`http://127.0.0.1:${(server.address() as { port: number }).port}/`);
    await expect(player.getByRole('alert')).toContainText('Corrupt or missing resource');
    await player.getByRole('button', { name: 'Go to The pavilion' }).click(); await expect(player.getByRole('heading', { name: 'The pavilion' })).toBeVisible();
    await expect(player.locator('img[alt="Calibrated landscape plan"]')).toHaveCSS('opacity', '1');
    await player.getByRole('button', { name: 'Layers', exact: true }).click(); await expect(player.getByRole('checkbox', { name: 'Trees', exact: true })).toBeDisabled();
  } finally { await context.close(); await new Promise<void>(r => server.close(() => r())); }
});
