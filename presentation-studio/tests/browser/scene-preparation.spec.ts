import { test, expect } from '@playwright/test';
import { existsSync } from 'node:fs';
import { readFile } from 'node:fs/promises';
import { resolve } from 'node:path';
import { createHash } from 'node:crypto';
import { menuAction } from './ui-actions';
const fixture = resolve('exports/fixtures/scene-preparation/optimized.glb');
test.skip(!existsSync(fixture), 'Generate and collect the owned Max scene-preparation fixture first.');

test('the native preparation output imports with metre bounds, PBR colours, UV textures, layer reuse and portable reopen', async ({ page, browser }) => {
  const errors: string[] = []; page.on('pageerror', e => errors.push(e.message));
  await page.goto('/'); await page.waitForFunction(() => (window as any).__cyrusStudio?.ready);
  await page.evaluate(async () => (window as any).__cyrusStudio.controller.act('newProject'));
  await page.getByLabel('Import landscape GLB', { exact: true }).setInputFiles(fixture);
  await page.waitForFunction(() => !(window as any).__cyrusStudio.controller.pending && (window as any).__cyrusStudio.controller.project.assets.length === 1);
  await expect(page.getByTestId('error')).toBeHidden();
  const bytes = await readFile(fixture), expectedHash = createHash('sha256').update(bytes).digest('hex');
  const imported = await page.evaluate(() => { const c = (window as any).__cyrusStudio.controller; return { asset: c.project.assets[0], layers: c.project.layers.map((l: any) => l.name) }; });
  expect(imported.asset.hash).toBe(expectedHash); expect(imported.asset.triangles).toBe(7956);
  expect(imported.layers.sort()).toEqual(['Details', 'Protected', 'Reduce']);
  expect(imported.asset.bounds.max[0] - imported.asset.bounds.min[0]).toBeLessThan(2);
  expect(imported.asset.nodes.filter((n: any) => n.renderable)).toHaveLength(5);
  const materials = await page.evaluate(async () => {
    const c = (window as any).__cyrusStudio.controller;
    await c.act('updateProject', { opening: 0, revealDuration: 0, lighting: { exposure: 1, shadows: false } }); await c.act('time', 10); await c.act('mode', 'explore');
    c.host.perspective.position.set(1.1, 1, 1.2); c.host.perspective.lookAt(.45, .03, -.08); c.host.perspective.fov = 35; c.host.perspective.updateProjectionMatrix(); c.host.draw();
    await c.act('captureStop'); await c.act('deleteStop', c.project.stops[0].id);
    const coating = c.project.assets[0].nodes.find((n: any) => n.name === 'Explicit coating witness'), witness = c.project.assets[0].nodes.find((n: any) => n.name === 'Material ID witness'), mapped: any[] = [], slotColours: number[][] = []; let colour: number[] | undefined;
    c.host.scene.traverse((o: any) => {
      if (!o.isMesh) return;
      if (o.userData.cyrusNodeKey === coating.key) colour = o.material.color.toArray();
      let owner = o; while (owner && !owner.userData.cyrusNodeKey) owner = owner.parent;
      if (owner?.userData.cyrusNodeKey === witness.key) slotColours.push(o.material.color.toArray());
      if (o.material.map) mapped.push({ colourSpace: o.material.map.colorSpace, flipY: o.material.map.flipY, uv: o.geometry.getAttribute('uv')?.count, positions: o.geometry.getAttribute('position').count, normals: o.geometry.getAttribute('normal')?.count });
    });
    return { colour, mapped, slotColours };
  });
  const linear = (v: number) => v <= .04045 ? v / 12.92 : ((v + .055) / 1.055) ** 2.4;
  expect(materials.colour).toBeDefined(); for (let i = 0; i < 3; i++) expect(materials.colour![i]).toBeCloseTo(linear([.4, .5, .6][i]), 6);
  expect(materials.mapped.length).toBeGreaterThan(0);
  expect(materials.slotColours).toHaveLength(2);
  for (const expected of [[160, 40, 30], [30, 70, 150]]) expect(materials.slotColours.some(colour => colour.every((v, i) => Math.abs(v - expected[i] / 255) < .000001))).toBe(true);
  for (const map of materials.mapped) { expect(map.colourSpace).toBe('srgb'); expect(map.flipY).toBe(false); expect(map.uv).toBe(map.positions); expect(map.normals).toBe(map.positions); }
  await page.screenshot({ path: 'exports/fixtures/scene-preparation/studio.png' });
  const before = await page.evaluate(() => ({ ...(window as any).__cyrusStudio.controller.host.stats }));
  await page.getByTestId('scene-toggle').click(); await page.getByRole('checkbox', { name: 'Show Reduce initially', exact: true }).uncheck();
  await page.getByTestId('undo').click(); await page.getByTestId('redo').click(); await page.getByTestId('undo').click();
  await page.evaluate(async () => { const c = (window as any).__cyrusStudio.controller; for (const t of [0, 1, 2, 1, 0]) { await c.act('time', t); c.host.draw(); } });
  const after = await page.evaluate(() => ({ ...(window as any).__cyrusStudio.controller.host.stats })); expect(after.rebuilds).toBe(before.rebuilds); expect(after.uploads).toBe(before.uploads);
  const download = page.waitForEvent('download'); await menuAction(page, 'project-menu', 'save-project'); const file = await (await download).path();
  const context = await browser.newContext(), reopened = await context.newPage();
  try {
    await reopened.goto('/'); await reopened.waitForFunction(() => (window as any).__cyrusStudio?.ready);
    await reopened.getByLabel('Open project archive', { exact: true }).setInputFiles(file!);
    await reopened.waitForFunction(hash => (window as any).__cyrusStudio.controller.project.assets[0]?.hash === hash && !(window as any).__cyrusStudio.controller.pending, expectedHash);
    await expect(reopened.getByTestId('error')).toBeHidden();
  } finally { await context.close(); }
  await menuAction(page, 'output-menu', 'preview-export');
  const frame = page.frames().find(f => f.parentFrame() === page.mainFrame())!; await frame.waitForFunction(() => (window as any).__cyrusPlayer?.ready);
  expect(await frame.evaluate(() => (window as any).__cyrusPlayer.project.layers.map((l: any) => l.name).sort())).toEqual(['Details', 'Protected', 'Reduce']);
  expect(errors).toEqual([]);
});
