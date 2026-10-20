import { test, expect, type Page } from '@playwright/test';
import { readFile, writeFile, mkdir } from 'node:fs/promises';
import { resolve } from 'node:path';
import { createServer } from 'node:http';
import { unzipSync } from 'fflate';
import { cameraAt, parseCameraClip } from '../../src/presentation/camera-clip';
import { menuAction } from './ui-actions';

const fixture = resolve('exports/fixtures/max-camera/free.json');
const action = (page: Page, name: string, payload?: unknown) => page.evaluate(async ({ name, payload }) => (window as any).__cyrusStudio.controller.act(name, payload), { name, payload });
const state = (page: Page) => page.evaluate(() => { const c = (window as any).__cyrusStudio.controller; return { project: c.project, pose: c.host.capture(), time: c.time, mode: c.mode, stats: { ...c.host.stats } }; });
async function importCamera(page: Page, name = 'free') {
  await page.getByTestId('project-menu').click(); const choosing = page.waitForEvent('filechooser'); await page.getByTestId('import-camera-animation').click();
  await (await choosing).setFiles(resolve(`exports/fixtures/max-camera/${name}.json`)); await expect(page.getByTestId('camera-import-dialog')).toBeVisible();
}
test.beforeEach(async ({ page }) => { await page.goto('/'); await page.waitForFunction(() => (window as any).__cyrusStudio?.ready); });

test('camera import review owns keyboard focus, cancels without mutation and rejects invalid/oversized data', async ({ page }) => {
  const before = await state(page); await importCamera(page);
  await page.keyboard.press('Control+z'); await page.keyboard.press('Space'); expect((await state(page)).project).toEqual(before.project);
  await page.keyboard.press('Tab'); await expect(page.getByTestId('cancel-camera-animation')).toBeFocused();
  await page.keyboard.press('Escape'); await expect(page.getByTestId('camera-import-dialog')).toBeHidden(); await expect(page.getByTestId('project-menu')).toBeFocused();
  expect((await state(page)).project).toEqual(before.project);
  for (const bytes of [Buffer.from('{"format":"wrong"}'), Buffer.alloc(4 * 1024 * 1024 + 1, 32)]) {
    await page.getByLabel('Import camera animation', { exact: true }).setInputFiles({ name: 'invalid.json', mimeType: 'application/json', buffer: bytes });
    await expect(page.getByTestId('error')).toBeVisible(); expect((await state(page)).project).toEqual(before.project);
  }
  expect((await state(page)).stats.uploads).toBe(before.stats.uploads);
});

test('native clips preserve playback/seek/reverse, fixed framing, original timing and static GPU resources', async ({ page }) => {
  const uploads = (await state(page)).stats.uploads;
  for (const name of ['free', 'target', 'physical', 'path']) {
    const clip = parseCameraClip(new Uint8Array(await readFile(`exports/fixtures/max-camera/${name}.json`)));
    await importCamera(page, name); await page.getByTestId('confirm-camera-animation').click(); await expect(page.getByTestId('imported-camera-track')).toBeVisible();
    const p = (await state(page)).project; expect(p.stops).toHaveLength(2); expect(p.stops.map((s: any) => s.hold)).toEqual([0, 0]); expect(p.segments[0].duration).toBe(2); expect(p.segments[0].ease).toBe(0);
    for (const t of [0, .135, .5, 1.177, 1.999, 2, 1, .25]) {
      await action(page, 'time', p.opening + p.revealDuration + t); const actual = (await state(page)).pose, expected = cameraAt(clip, t);
      actual.position.forEach((v: number, i: number) => expect(v).toBeCloseTo(expected.position[i], 9)); actual.quaternion.forEach((v: number, i: number) => expect(v).toBeCloseTo(expected.quaternion[i], 9)); expect(actual.fov).toBeCloseTo(expected.fov, 9);
    }
    await page.getByLabel('Presentation preview framing', { exact: true }).selectOption('portrait');
    expect(await page.evaluate(() => (window as any).__cyrusStudio.controller.evaluator.evaluate((window as any).__cyrusStudio.controller.time, true).aspect)).toBe(clip.aspect);
    await page.getByLabel('Presentation preview framing', { exact: true }).selectOption('auto');
  }
  const clock = await page.evaluate(async () => {
    const c = (window as any).__cyrusStudio.controller; await c.act('time', c.project.opening + c.project.revealDuration + .2); await c.act('play'); cancelAnimationFrame(c.raf);
    const start = c.time; c.tick(c.last + 350); cancelAnimationFrame(c.raf); const forward = c.time - start; await c.act('pause'); await c.act('reverse'); cancelAnimationFrame(c.raf);
    const reverseStart = c.time; c.tick(c.last + 275); cancelAnimationFrame(c.raf); const reverse = reverseStart - c.time; await c.act('pause'); return { forward, reverse };
  });
  expect(clock.forward).toBeCloseTo(.35, 9); expect(clock.reverse).toBeCloseTo(.275, 9); expect((await state(page)).stats.uploads).toBe(uploads);
});

test('import is one undo step, source motion is guarded, capture outside the clip adds an editable key and removal is undoable', async ({ page }) => {
  const before = (await state(page)).project;
  await importCamera(page); await page.getByTestId('confirm-camera-animation').click(); await expect(page.getByTestId('imported-camera-track')).toBeVisible();
  const imported = (await state(page)).project, start = imported.stops[0].id, segment = imported.segments[0].id;
  await page.getByTestId('undo').click(); expect((await state(page)).project.stops).toEqual(before.stops); await action(page, 'redo');
  const errors = await page.evaluate(async ({ start, segment }) => {
    const c = (window as any).__cyrusStudio.controller, errors: string[] = [];
    for (const [name, payload] of [['editCameraStop', start], ['updateFromView', start], ['capturePortrait', start], ['lookTarget', { id: start, target: [0, 0, 0] }], ['updateStop', { id: start, patch: { fov: 50 } }], ['moveStop', { id: start, direction: 1 }], ['deleteStop', start], ['updateSegment', { id: segment, patch: { duration: 8 } }], ['segmentSpeed', { id: segment, speed: 5 }]]) {
      try { await c.act(name, payload); errors.push(''); } catch (e) { errors.push(String(e)); }
    } return errors;
  }, { start, segment });
  expect(errors.every(Boolean)).toBe(true); expect((await state(page)).project).toEqual(imported);
  await action(page, 'time', imported.opening + imported.revealDuration + .75); const frame = (await state(page)).pose;
  await page.getByTestId('animation-frame-to-viewport').click(); expect((await state(page)).mode).toBe('explore'); expect((await state(page)).pose.position).toEqual(frame.position);
  const error = await page.evaluate(async () => { try { await (window as any).__cyrusStudio.controller.act('captureStop'); return ''; } catch (e) { return String(e); } }); expect(error).toContain('protected');
  await action(page, 'setTimelineOptions', { duration: 12 }); await action(page, 'time', 10); await page.getByTestId('compose-at-playhead').click(); await page.getByTestId('camera-primary-action').click(); expect((await state(page)).project.stops).toHaveLength(3); expect((await state(page)).project.segments[0].cameraClip).toEqual(imported.segments[0].cameraClip);
  await action(page, 'selectStop', start); await page.locator('.animation-options summary').click(); await page.getByTestId('remove-camera-animation').click();
  expect((await state(page)).project.segments[0].cameraClip).toBeUndefined(); await page.getByTestId('undo').click(); expect((await state(page)).project.segments[0].cameraClip).toEqual(imported.segments[0].cameraClip);
});

test('an imported camera can be replaced from compiled preview without leaving a stale player or changing the landscape', async ({ page }) => {
  await importCamera(page); await page.getByTestId('confirm-camera-animation').click(); const before = (await state(page)).project;
  await menuAction(page, 'output-menu', 'preview-export'); await page.frameLocator('iframe').getByTestId('player').waitFor();
  await importCamera(page, 'physical'); await page.getByTestId('confirm-camera-animation').click(); await expect(page.getByTestId('imported-camera-track')).toBeVisible();
  const after = await state(page); expect(after.mode).toBe('playback'); expect(after.project.segments[0].cameraClip!.name).toBe('Owned physical camera');
  expect(after.project.assets).toEqual(before.assets); expect(after.project.layers).toEqual(before.layers); expect(await page.locator('iframe').getAttribute('srcdoc')).toBe('');
  await page.getByTestId('undo').click(); expect((await state(page)).project.segments[0].cameraClip).toEqual(before.segments[0].cameraClip);
});

test('real Max animation survives Botanical GLB import, autosave, portable reopen, preview and nested standalone HTTP output', async ({ page, browser }) => {
  test.setTimeout(180000); const errors: string[] = []; page.on('pageerror', e => errors.push(e.message));
  await page.getByLabel('Open project archive', { exact: true }).setInputFiles(resolve('exports/fixtures/previous-study/botanical-islands.cyrus-presentation.zip'));
  await expect(page.getByRole('textbox', { name: 'Project title' })).toHaveValue('Botanical Islands — presentation MVP', { timeout: 60000 });
  const landscape = (await state(page)).project; await importCamera(page); await page.getByTestId('confirm-camera-animation').click(); await expect(page.getByTestId('imported-camera-track')).toBeVisible();
  const authored = (await state(page)).project; expect(authored.assets).toEqual(landscape.assets); expect(authored.layers).toEqual(landscape.layers); expect(authored.plan).toEqual(landscape.plan);
  const q = 'exports/qualification/max-camera'; await mkdir(q, { recursive: true });
  const saved = page.waitForEvent('download'); await menuAction(page, 'project-menu', 'save-project'); const editable = await readFile((await (await saved).path())!); await writeFile(`${q}/botanical-camera-project.cyrus-presentation.zip`, editable);
  await expect(page.getByText('Saved locally', { exact: true })).toBeVisible(); await page.reload(); await page.waitForFunction(() => (window as any).__cyrusStudio?.ready); expect((await state(page)).project.segments[0].cameraClip).toEqual(authored.segments[0].cameraClip);
  const offset = authored.opening + authored.revealDuration, seek = offset + .731; await action(page, 'time', seek); const expected = (await state(page)).pose;
  await menuAction(page, 'output-menu', 'preview-export'); const frame = page.frameLocator('iframe'); await frame.locator('[data-testid="player"]').waitFor();
  const embedded = page.frames().find(f => f.parentFrame() === page.mainFrame())!; await embedded.waitForFunction(() => (window as any).__cyrusPlayer?.ready);
  const preview = await embedded.evaluate(t => { (window as any).__cyrusPlayer.setTime(t); return (window as any).__cyrusPlayer.evaluation; }, seek);
  preview.position.forEach((v: number, i: number) => expect(v).toBeCloseTo(expected.position[i], 9)); await page.getByTestId('close-preview').click();
  const exported = page.waitForEvent('download'); await menuAction(page, 'output-menu', 'export-website'); const publicBytes = await readFile((await (await exported).path())!); await writeFile(`${q}/botanical-camera-presentation.zip`, publicBytes);
  const files = unzipSync(publicBytes), manifest = JSON.parse(new TextDecoder().decode(files['manifest.json'])), hash = authored.segments[0].cameraClip!.hash;
  expect(files[`assets/${hash}.json`]).toEqual(new Uint8Array(await readFile(fixture))); expect(manifest.project.segments[0].cameraClip).toEqual(authored.segments[0].cameraClip);
  const server = createServer((req, res) => { const path = (req.url ?? '').replace(/^\/owned\/garden\//, '') || 'index.html', bytes = files[path]; if (!bytes) { res.writeHead(404).end(); return; } res.setHeader('Content-Type', path.endsWith('.js') ? 'text/javascript' : path.endsWith('.css') ? 'text/css' : path.endsWith('.html') ? 'text/html' : 'application/octet-stream'); res.end(bytes); });
  await new Promise<void>(r => server.listen(0, '127.0.0.1', r)); const context = await browser.newContext(), player = await context.newPage(), origin = `http://127.0.0.1:${(server.address() as { port: number }).port}`, external: string[] = [];
  player.on('pageerror', e => errors.push(e.message)); player.on('request', req => { if (!req.url().startsWith(origin) && !req.url().startsWith('blob:')) external.push(req.url()); });
  try {
    await player.goto(`${origin}/owned/garden/`); await player.waitForFunction(() => (window as any).__cyrusPlayer?.ready);
    const clip = parseCameraClip(new Uint8Array(await readFile(fixture))), initial = await player.evaluate(() => ({ ...(window as any).__cyrusPlayer.stats }));
    for (const t of [0, .135, .5, 1.177, 2, .731, .25]) {
      const actual = await player.evaluate(time => { (window as any).__cyrusPlayer.setTime(time); return (window as any).__cyrusPlayer.evaluation; }, offset + t), expectedFrame = cameraAt(clip, t);
      actual.position.forEach((v: number, i: number) => expect(v).toBeCloseTo(expectedFrame.position[i], 9)); expect(actual.fov).toBeCloseTo(expectedFrame.fov, 9);
    }
    await player.getByRole('button', { name: 'Layers', exact: true }).click(); await player.getByRole('checkbox', { name: 'Trees', exact: true }).uncheck();
    await player.evaluate(time => (window as any).__cyrusPlayer.setTime(time), seek); await player.screenshot({ path: `${q}/standalone-native-camera.png` });
    const final = await player.evaluate(() => ({ ...(window as any).__cyrusPlayer.stats })); expect(final.uploads).toBe(initial.uploads); expect(final.rebuilds).toBe(initial.rebuilds);
    await writeFile(`${q}/browser-workflow.json`, JSON.stringify({ maxClipHash: hash, staticGLBHash: authored.assets[0].hash, samples: authored.segments[0].cameraClip!.sampleCount, sourceDuration: 2, introOffset: offset, editableBytes: editable.length, publicBytes: publicBytes.length, initial, final, errors, external }, null, 2));
    expect(external).toEqual([]); expect(errors).toEqual([]);
    // A missing sampled resource must fail visibly, never silently play the endpoint Bézier fallback.
    const cameraPath = `assets/${hash}.json`, originalCamera = files[cameraPath]; delete files[cameraPath];
    const missing = await context.newPage(); await missing.goto(`${origin}/owned/garden/`);
    await expect(missing.getByRole('alert')).toContainText('Corrupt or missing resource');
    expect(await missing.evaluate(() => !!(window as any).__cyrusPlayer?.ready)).toBe(false); await missing.close(); files[cameraPath] = originalCamera;
  } finally { await context.close(); await new Promise<void>(r => server.close(() => r())); }
  const restoredContext = await browser.newContext(), restored = await restoredContext.newPage();
  try { await restored.goto('/'); await restored.waitForFunction(() => (window as any).__cyrusStudio?.ready); await restored.getByLabel('Open project archive', { exact: true }).setInputFiles({ name: 'owned-camera.zip', mimeType: 'application/zip', buffer: editable }); await expect.poll(async () => (await state(restored)).project.segments[0]?.cameraClip?.hash, { timeout: 60000 }).toBe(hash); await action(restored, 'time', seek); expect((await state(restored)).pose.position).toEqual(expected.position); } finally { await restoredContext.close(); }
});
