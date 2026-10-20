import { test, expect, type Page, type Locator } from '@playwright/test';
import { existsSync } from 'node:fs';
import { mkdir, readFile, writeFile } from 'node:fs/promises';
import { resolve } from 'node:path';
import { menuAction } from './ui-actions';
import type { Project } from '../../src/core/model';
import { createServer } from 'node:http';
import { extname } from 'node:path';
import { unzipSync } from 'fflate';

const state = (page: Page) => page.evaluate(() => { const c = (window as any).__cyrusStudio.controller; return { project: c.project as Project, time: c.time, stats: { ...c.host.stats }, pose: c.host.capture(), editing: c.cameraEditingStopId, mode: c.mode }; });
async function seek(page: Page, time: number) { const input = page.getByRole('spinbutton', { name: 'Playhead time in seconds', exact: true }); await input.fill(String(time)); await input.press('Tab'); expect((await state(page)).time).toBeCloseTo(time, 10); }
async function key(page: Page, index: number): Promise<Locator> { return page.locator('.tl-camera-row [data-tl-key="camera"]').nth(index); }
async function dragKey(page: Page, target: Locator, seconds: number, cancel = false) {
  await target.scrollIntoViewIfNeeded(); const box = (await target.boundingBox())!, track = (await page.locator('.tl-camera-row .tl-track').boundingBox())!;
  const duration = (await state(page)).project.timeline?.duration ?? 38;
  const scale = await target.evaluate(el => { const keys = [...el.parentElement!.querySelectorAll<HTMLElement>('[data-time]')]; return (parseFloat(keys[1].style.left) - parseFloat(keys[0].style.left)) / (Number(keys[1].dataset.time) - Number(keys[0].dataset.time)); });
  expect(track.width).toBeGreaterThan(100); expect(duration).toBeGreaterThan(0);
  await page.mouse.move(box.x + box.width / 2, box.y + box.height / 2); await page.mouse.down();
  const before = (await state(page)).project;
  await page.mouse.move(box.x + box.width / 2 + seconds * scale, box.y + box.height / 2, { steps: 8 });
  expect((await state(page)).project).toEqual(before);
  if (cancel) await page.keyboard.press('Escape'); await page.mouse.up();
}
test.beforeEach(async ({ page }) => { await page.goto('/'); await page.waitForFunction(() => (window as any).__cyrusStudio?.ready); });

test('stacked tracks, linked properties, frame seeking, zoom and collapse are usable without changing project data', async ({ page }) => {
  const before = await state(page); await expect(page.locator('.tl-layer-row')).toHaveCount(before.project.layers.length);
  await page.getByRole('button', { name: 'Expand linked camera properties' }).click(); await expect(page.locator('.tl-property-row')).toHaveCount(3);
  await expect(page.locator('.tl-property-row [data-key-id]')).toHaveCount(before.project.stops.length * 3);
  await seek(page, 4.2); await page.getByRole('slider', { name: 'Timeline playhead', exact: true }).focus(); await page.keyboard.press('ArrowRight');
  expect((await state(page)).time).toBeCloseTo(4.2 + 1 / 30, 9);
  const initialWidth = await page.locator('.tl-content').evaluate(e => e.clientWidth); await page.getByRole('combobox', { name: 'Timeline zoom' }).selectOption('4');
  expect(await page.locator('.tl-content').evaluate(e => e.clientWidth)).toBeGreaterThan(initialWidth * 2);
  await page.getByRole('button', { name: 'Collapse animation timeline' }).click(); await expect(page.locator('.tl-scroll')).toBeHidden();
  await page.getByRole('button', { name: 'Expand animation timeline' }).click(); await expect(page.locator('.tl-scroll')).toBeVisible(); expect((await state(page)).project).toEqual(before.project);
});
test('viewport composition captures at playhead, updates the existing key and saves the selected owner without GPU rebuilding', async ({ page }) => {
  await seek(page, 4.2); await page.getByTestId('compose-at-playhead').click(); const canvas = page.locator('[data-testid="viewport"] canvas');
  await canvas.focus(); await page.keyboard.down('KeyD'); await page.waitForTimeout(150); await page.keyboard.up('KeyD');
  const before = await state(page); await page.getByTestId('camera-primary-action').click(); const captured = await state(page), id = captured.editing;
  expect(captured.project.timeline!.keys.find(k => k.stopId === id)!.time).toBe(4.2); expect(captured.project.stops.find(s => s.id === id)!.position).toEqual(before.pose.position);
  await page.getByTestId('camera-primary-action').click(); expect((await state(page)).project.stops.length).toBe(captured.project.stops.length);
  await page.getByTestId('edit-camera-stop').click(); await canvas.focus(); await page.keyboard.down('KeyE'); await page.waitForTimeout(150); await page.keyboard.up('KeyE');
  const changed = await state(page); await page.getByTestId('camera-primary-action').click(); const saved = await state(page);
  expect(saved.project.stops.find(s => s.id === id)!.position).toEqual(changed.pose.position); expect(saved.stats.rebuilds).toBe(before.stats.rebuilds); expect(saved.stats.uploads).toBe(before.stats.uploads);
});
test('dragging retimes once, Escape cancels, multi-selection keeps relative offsets and undo restores the group', async ({ page }) => {
  let before = await state(page); await dragKey(page, await key(page, 0), 1); let moved = await state(page);
  expect(moved.project.revision).toBe(before.project.revision + 1); expect(moved.project.timeline!.keys[0].time).toBe(8);
  await dragKey(page, await key(page, 0), .5, true); expect((await state(page)).project).toEqual(moved.project);
  await (await key(page, 1)).click(); await (await key(page, 2)).click({ modifiers: ['Shift'] }); before = await state(page);
  await dragKey(page, await key(page, 1), 1); moved = await state(page);
  expect(moved.project.revision).toBe(before.project.revision + 1); expect(moved.project.timeline!.keys[1].time).toBe(18); expect(moved.project.timeline!.keys[2].time).toBe(26);
  await page.getByTestId('undo').click(); expect((await state(page)).project).toEqual(before.project);
});
test('layer visibility keys play at exact boundaries, survive autosave and use retained render resources', async ({ page }) => {
  const before = await state(page), layer = before.project.layers[1]; await seek(page, 12); await page.getByRole('button', { name: `Key hide ${layer.name} at playhead`, exact: true }).click();
  await seek(page, 20); await page.getByRole('button', { name: `Key show ${layer.name} at playhead`, exact: true }).click();
  const visible = () => page.evaluate(id => (window as any).__cyrusStudio.controller.evaluator.evaluate((window as any).__cyrusStudio.controller.time).visible[id], layer.id);
  await seek(page, 11.999); expect(await visible()).toBe(true); await seek(page, 12); expect(await visible()).toBe(false); await seek(page, 20); expect(await visible()).toBe(true);
  const edited = await state(page); expect(edited.stats.rebuilds).toBe(before.stats.rebuilds); expect(edited.stats.uploads).toBe(before.stats.uploads);
  await expect(page.getByText('Saved locally', { exact: true })).toBeVisible(); await page.reload(); await page.waitForFunction(() => (window as any).__cyrusStudio?.ready);
  expect((await state(page)).project.timeline).toEqual(edited.project.timeline);
});
test('scoped keyboard copy/paste/delete and interpolation edit the selected keys, with undo and unchanged viewport shortcuts', async ({ page }) => {
  await (await key(page, 1)).click(); await page.keyboard.press('Control+c'); await seek(page, 0); await page.locator('.tl-scroll').focus(); await page.keyboard.press('Control+v');
  const pasted = await state(page); expect(pasted.project.stops).toHaveLength(5); expect(pasted.project.timeline!.keys[0].time).toBe(0);
  await (await key(page, 0)).click(); await page.getByRole('combobox', { name: 'Selected camera key interpolation' }).selectOption('hold');
  expect((await state(page)).project.timeline!.keys[0].interpolation).toBe('hold'); await (await key(page, 0)).focus(); await page.keyboard.press('Delete');
  expect((await state(page)).project.stops).toHaveLength(4); await page.getByTestId('undo').click(); expect((await state(page)).project.stops).toHaveLength(5);
  await page.getByRole('textbox', { name: 'Project title' }).fill('Delete stays text'); await page.keyboard.press('Backspace'); expect((await state(page)).project.stops).toHaveLength(5);
});
test('layer labels clear stale camera selection and deleting a new visibility key affects only that layer', async ({ page }) => {
  await (await key(page, 0)).click(); const before = await state(page), layer = before.project.layers[1];
  await page.locator(`.tl-layer-name[data-layer="${layer.id}"]`).click(); await expect(page.locator('.tl-key.selected')).toHaveCount(0); await page.keyboard.press('Delete'); expect((await state(page)).project).toEqual(before.project);
  await seek(page, 12); await page.getByRole('button', { name: `Key hide ${layer.name} at playhead`, exact: true }).click();
  await expect(page.locator('.tl-key.selected')).toHaveCount(1); await expect(page.getByRole('button', { name: `Key hide ${layer.name} at playhead`, exact: true })).toBeFocused();
  await page.locator('.tl-key.selected').focus(); await page.keyboard.press('Delete');
  const after = await state(page); expect(after.project.stops).toEqual(before.project.stops); expect(after.project.timeline!.layers[0].keys).toHaveLength(0); await expect(page.getByTestId('error')).toBeHidden();
});
test('public viewer controls follow visibility keys and reset restores the authored schedule', async ({ page }) => {
  const p = (await state(page)).project, layer = p.layers.find(l => l.viewerToggle && l.defaultVisible)!;
  await seek(page, 12); await page.getByRole('button', { name: `Key hide ${layer.name} at playhead`, exact: true }).click();
  await menuAction(page, 'output-menu', 'preview-export'); const frame = page.frames().find(f => f.parentFrame() === page.mainFrame())!; await frame.waitForFunction(() => (window as any).__cyrusPlayer?.ready);
  await frame.evaluate(() => (window as any).__cyrusPlayer.setTime(12)); const ui = page.frameLocator('iframe'); await ui.getByRole('button', { name: 'Layers', exact: false }).click();
  const checkbox = ui.getByRole('checkbox', { name: layer.name, exact: true }); await expect(checkbox).not.toBeChecked(); await checkbox.check();
  expect(await frame.evaluate(id => (window as any).__cyrusPlayer.evaluation.visible[id], layer.id)).toBe(true);
  await ui.getByRole('button', { name: 'Reset layers', exact: true }).click(); await expect(checkbox).not.toBeChecked(); expect(await frame.evaluate(id => (window as any).__cyrusPlayer.evaluation.visible[id], layer.id)).toBe(false);
});
test('a hold on the final captured key extends duration while overlapping holds fail atomically', async ({ page }) => {
  await page.getByTestId('project-menu').click(); await page.getByRole('button', { name: 'New project', exact: true }).click();
  await seek(page, 20); await page.getByTestId('compose-at-playhead').click(); await page.getByTestId('camera-primary-action').click();
  if (await page.locator('.photo-section').getAttribute('open') === null) await page.locator('.photo-section summary').click(); const hold = page.getByLabel('Hold at key · seconds', { exact: true }); await hold.fill('8'); await hold.press('Tab');
  const held = await state(page); expect(held.project.timeline!.duration).toBe(28); expect(held.project.stops.at(-1)!.hold).toBe(8);
  await (await key(page, 0)).click(); if (await page.locator('.photo-section').getAttribute('open') === null) await page.locator('.photo-section summary').click(); await hold.fill('25'); await hold.press('Tab');
  expect((await state(page)).project).toEqual(held.project); await expect(page.getByTestId('error')).toContainText('overlap');
});

const bailey = resolve('exports/building-20261016/final-presentation-v1/BAILEY-editable-v2.cyrus-presentation.zip');
test('BAILEY Max motion stays exact with layered timing through portable reopen, compiled preview and export', async ({ page, browser }) => {
  test.skip(!existsSync(bailey), 'Owned BAILEY archive is local qualification data'); test.setTimeout(240000);
  await page.getByLabel('Open project archive', { exact: true }).setInputFiles(bailey); await page.waitForFunction(() => !(window as any).__cyrusStudio.controller.pending && (window as any).__cyrusStudio.controller.project.title.includes('BAILEY'));
  const before = await state(page), samples = await page.evaluate(() => { const c = (window as any).__cyrusStudio.controller; return [2, 2.135, 8.731, 18.5, 37.99, 38].map(t => c.evaluator.evaluate(t)); });
  const layer = before.project.layers.find(l => l.defaultVisible)!; await seek(page, 12); await page.getByRole('button', { name: `Key hide ${layer.name} at playhead`, exact: true }).click(); await seek(page, 16); await page.getByRole('button', { name: `Key show ${layer.name} at playhead`, exact: true }).click();
  const after = await state(page); expect(after.project.segments).toEqual(before.project.segments); expect(after.project.stops).toEqual(before.project.stops); expect(after.stats.rebuilds).toBe(before.stats.rebuilds); expect(after.stats.uploads).toBe(before.stats.uploads);
  const poses = await page.evaluate(() => { const c = (window as any).__cyrusStudio.controller; return [2, 2.135, 8.731, 18.5, 37.99, 38].map(t => c.evaluator.evaluate(t)); });
  poses.forEach((e, i) => { expect(e.position).toEqual(samples[i].position); expect(e.quaternion).toEqual(samples[i].quaternion); expect(e.fov).toEqual(samples[i].fov); });
  const folder = resolve('exports/camera-desk-20261016'); await mkdir(folder, { recursive: true });
  const saved = page.waitForEvent('download'); await menuAction(page, 'project-menu', 'save-project'); const portable = await readFile((await (await saved).path())!); await writeFile(resolve(folder, 'BAILEY-timeline.cyrus-presentation.zip'), portable);
  await page.getByLabel('Open project archive', { exact: true }).setInputFiles({ name: 'BAILEY-timeline.cyrus-presentation.zip', mimeType: 'application/zip', buffer: portable });
  await page.waitForFunction(revision => !(window as any).__cyrusStudio.controller.pending && (window as any).__cyrusStudio.controller.project.revision === revision, after.project.revision);
  expect((await state(page)).project.timeline).toEqual(after.project.timeline);
  await seek(page, 8.731); await page.screenshot({ path: resolve(folder, 'BAILEY-timeline-desktop.png') });
  await menuAction(page, 'output-menu', 'preview-export'); const frame = page.frames().find(f => f.parentFrame() === page.mainFrame())!; await frame.waitForFunction(() => (window as any).__cyrusPlayer?.ready);
  const actual = await frame.evaluate(() => { (window as any).__cyrusPlayer.setTime(8.731); return (window as any).__cyrusPlayer.evaluation; }); expect(actual.position).toEqual(samples[2].position); expect(actual.quaternion).toEqual(samples[2].quaternion);
  expect(await frame.evaluate(id => { (window as any).__cyrusPlayer.setTime(12); return (window as any).__cyrusPlayer.evaluation.visible[id]; }, layer.id)).toBe(false);
  await page.getByTestId('close-preview').click(); const exported = page.waitForEvent('download'); await menuAction(page, 'output-menu', 'export-website'); await (await exported).saveAs(resolve(folder, 'BAILEY-timeline-website.zip'));
  const files = unzipSync(new Uint8Array(await readFile(resolve(folder, 'BAILEY-timeline-website.zip')))), prefix = '/owned/bailey-timeline/', mime: Record<string, string> = { '.html': 'text/html', '.js': 'text/javascript', '.css': 'text/css', '.json': 'application/json', '.glb': 'model/gltf-binary' };
  const server = createServer((request, response) => { const url = new URL(request.url!, 'http://localhost'), path = url.pathname.startsWith(prefix) ? url.pathname.slice(prefix.length) || 'index.html' : '', bytes = files[path]; if (!bytes) response.writeHead(404).end(); else { response.setHeader('Content-Type', mime[extname(path)] ?? 'application/octet-stream'); response.end(bytes); } });
  await new Promise<void>(done => server.listen(0, '127.0.0.1', done)); const origin = `http://127.0.0.1:${(server.address() as { port: number }).port}`, context = await browser.newContext({ viewport: { width: 1440, height: 900 } });
  const external: string[] = [], errors: string[] = [];
  try {
    const standalone = await context.newPage(); standalone.on('pageerror', e => errors.push(e.message)); standalone.on('request', r => { if (!r.url().startsWith(origin) && !r.url().startsWith('blob:') && !r.url().startsWith('data:')) external.push(r.url()); });
    await standalone.goto(`${origin}${prefix}`); await standalone.waitForFunction(() => (window as any).__cyrusPlayer?.ready && (window as any).__cyrusPlayer.stats.rebuilds === 1, null, { timeout: 90000 });
    await standalone.evaluate(async () => { for (const t of [2, 8.731, 12, 16, 38]) { (window as any).__cyrusPlayer.setTime(t); await new Promise(requestAnimationFrame); } });
    const initial = await standalone.evaluate(() => ({ ...(window as any).__cyrusPlayer.stats }));
    for (const t of [38, 16, 12, 8.731, 2, 8.731, 12, 16]) {
      const e = await standalone.evaluate(time => { (window as any).__cyrusPlayer.setTime(time); return (window as any).__cyrusPlayer.evaluation; }, t);
      const expected = await page.evaluate(time => (window as any).__cyrusStudio.controller.evaluator.evaluate(time), t); expect(e).toEqual(expected);
    }
    const final = await standalone.evaluate(() => ({ ...(window as any).__cyrusPlayer.stats })); expect(final.uploads).toBe(initial.uploads); expect(final.rebuilds).toBe(initial.rebuilds);
    await standalone.screenshot({ path: resolve(folder, 'BAILEY-timeline-standalone.png') });
    expect(external).toEqual([]); expect(errors).toEqual([]); await writeFile(resolve(folder, 'standalone-workflow.json'), JSON.stringify({ nestedHTTP: true, randomReverseSeeks: true, visibilityBoundaries: true, initial, final, errors, external }, null, 2));
  } finally { await context.close(); server.closeAllConnections(); await new Promise<void>(done => server.close(() => done())); }
  await writeFile(resolve(folder, 'bailey-timeline-evidence.json'), JSON.stringify({ version: '0.3.0', schema: after.project.schemaVersion, cameraUnchanged: true, posesChecked: samples.length, timeline: after.project.timeline, beforeStats: before.stats, afterStats: after.stats }, null, 2));
});
