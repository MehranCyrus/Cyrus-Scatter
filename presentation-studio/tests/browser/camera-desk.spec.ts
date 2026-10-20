import { expect, test, type Page } from '@playwright/test';
import { resolve } from 'node:path';
import { menuAction } from './ui-actions';

const action = (page: Page, name: string, payload?: unknown) => page.evaluate(async ({ name, payload }) => (window as any).__cyrusStudio.controller.act(name, payload), { name, payload });
const state = (page: Page) => page.evaluate(() => {
  const c = (window as any).__cyrusStudio.controller, rig = c.navigation.animatedCamera;
  return { project: c.project, pose: c.host.capture(), time: c.time, mode: c.mode, nav: c.navigation.navigationMode, playing: c.playing,
    stats: { ...c.host.stats }, rig: { visible: rig.visible, position: rig.position.toArray(), quaternion: rig.quaternion.toArray() },
    evaluation: c.evaluator.evaluate(c.time), cameraAspect: c.host.perspective.aspect };
});
async function seek(page: Page, time: number) { const input = page.getByRole('spinbutton', { name: 'Playhead time in seconds', exact: true }); await input.fill(String(time)); await input.press('Tab'); }
async function framePreset(page: Page, preset: string) { const menu = page.getByTestId('frame-menu'); if (!await menu.evaluate(e => e.parentElement!.hasAttribute('open'))) await menu.click(); await page.getByTestId('frame-preset').selectOption(preset); await menu.click(); await page.evaluate(() => new Promise(requestAnimationFrame)); }
async function dragOrbit(page: Page) { const b = (await page.locator('[data-testid="viewport"] canvas').boundingBox())!; await page.mouse.move(b.x + b.width * .5, b.y + b.height * .55); await page.mouse.down(); await page.mouse.move(b.x + b.width * .6, b.y + b.height * .6, { steps: 12 }); await page.mouse.up(); }

test.beforeEach(async ({ page }) => { await page.goto('/'); await page.waitForFunction(() => (window as any).__cyrusStudio?.ready); });

test('timeline height is adjustable, keyboard accessible and persistent without changing the project or canvas', async ({ page }) => {
  const before = await state(page), grip = page.getByTestId('timeline-resize'), canvas = page.locator('[data-testid="viewport"] canvas');
  await canvas.evaluate(e => e.setAttribute('data-owned-identity', 'retained'));
  const initial = Number(await grip.getAttribute('aria-valuenow')), box = (await grip.boundingBox())!;
  await page.mouse.move(box.x + box.width / 2, box.y + box.height / 2); await page.mouse.down(); await page.mouse.move(box.x + box.width / 2, box.y + box.height / 2 - 120, { steps: 8 }); await page.mouse.up();
  expect(Number(await grip.getAttribute('aria-valuenow'))).toBe(initial + 120);
  await page.getByRole('button', { name: 'Collapse animation timeline' }).click(); await page.getByRole('button', { name: 'Expand animation timeline' }).click();
  expect(Number(await grip.getAttribute('aria-valuenow'))).toBe(initial + 120);
  await grip.focus(); await grip.press('ArrowUp'); expect(Number(await grip.getAttribute('aria-valuenow'))).toBe(initial + 140);
  await grip.press('End'); expect((await canvas.boundingBox())!.height).toBeGreaterThanOrEqual(220);
  await grip.dblclick(); expect(Number(await grip.getAttribute('aria-valuenow'))).toBe(258);
  expect(await canvas.getAttribute('data-owned-identity')).toBe('retained'); expect((await state(page)).project).toEqual(before.project);
  expect((await state(page)).stats.rebuilds).toBe(before.stats.rebuilds);
  await page.reload(); await page.waitForFunction(() => (window as any).__cyrusStudio?.ready); expect(Number(await grip.getAttribute('aria-valuenow'))).toBe(258);
  await page.setViewportSize({ width: 841, height: 700 }); await grip.focus(); await grip.press('End'); expect((await canvas.boundingBox())!.height).toBeGreaterThanOrEqual(220);
});

test('safe guides match rendered aspect and captured camera frame through portable reopen and compiled output', async ({ page }) => {
  const before = await state(page);
  for (const [preset, aspect] of [['fhd', 16 / 9], ['vertical', 9 / 16], ['square', 1], ['classic', 4 / 3], ['cinema', 2.39]] as const) {
    await framePreset(page, preset);
    const b = (await page.getByTestId('safe-output-frame').boundingBox())!;
    expect(b.width / b.height).toBeCloseTo(aspect, 3); expect((await state(page)).cameraAspect).toBeCloseTo(aspect, 8);
  }
  expect((await state(page)).project).toEqual(before.project);
  await framePreset(page, 'vertical'); await page.getByTestId('frame-menu').click(); await page.getByTestId('safe-frame-toggle').uncheck(); await expect(page.getByTestId('safe-frame-overlay')).toBeHidden(); await page.getByTestId('safe-frame-toggle').check(); await page.getByTestId('frame-menu').click();
  await seek(page, 4.2); await page.getByTestId('compose-at-playhead').click(); await page.getByTestId('camera-primary-action').click();
  const captured = await state(page), stop = captured.project.stops.find((s: any) => Math.abs(s.aspect - 9 / 16) < 1e-10)!;
  expect(stop).toBeDefined(); expect(captured.project.timeline.keys.find((k: any) => k.stopId === stop.id).time).toBe(4.2);
  const download = page.waitForEvent('download'); await menuAction(page, 'project-menu', 'save-project'); const file = await (await download).path();
  await page.getByLabel('Open project archive', { exact: true }).setInputFiles(file!); await page.waitForFunction(id => !(window as any).__cyrusStudio.controller.pending && (window as any).__cyrusStudio.controller.project.stops.some((s: any) => s.id === id), stop.id);
  expect((await state(page)).project.stops.find((s: any) => s.id === stop.id).aspect).toBe(9 / 16);
  await menuAction(page, 'output-menu', 'preview-export'); const f = page.frames().find(f => f.parentFrame() === page.mainFrame())!; await f.waitForFunction(() => (window as any).__cyrusPlayer?.ready);
  const output = await f.evaluate(() => { (window as any).__cyrusPlayer.setTime(4.2); return (window as any).__cyrusPlayer.evaluation; });
  expect(output.aspect).toBe(9 / 16); expect(output.position).toEqual(stop.position); expect(output.fov).toBe(stop.fov);
});

test('Orbit playback, reverse and scrubbing preserve the observer camera while the scene camera moves on its keyed path', async ({ page }) => {
  await page.getByTestId('viewport-mode').selectOption('orbit'); await seek(page, 10); await page.evaluate(() => new Promise(requestAnimationFrame)); const before = await state(page);
  await page.getByTestId('play').click(); await page.waitForTimeout(400); const playing = await state(page);
  expect(playing.mode).toBe('explore'); expect(playing.nav).toBe('orbit'); expect(playing.playing).toBe(true); expect(playing.time).toBeGreaterThan(before.time);
  expect(playing.pose).toEqual(before.pose); expect(playing.rig.visible).toBe(true); expect(playing.rig.position).toEqual(playing.evaluation.position); expect(playing.rig.quaternion).toEqual(playing.evaluation.quaternion);
  await expect(page.getByTestId('camera-primary-action')).toBeDisabled(); await expect(page.getByTestId('compose-at-playhead')).toBeDisabled();
  await dragOrbit(page); expect((await state(page)).pose.position).not.toEqual(before.pose.position); await page.getByTestId('play').click();
  const observer = (await state(page)).pose; await seek(page, 16); expect((await state(page)).pose).toEqual(observer);
  await page.getByRole('slider', { name: 'Timeline playhead', exact: true }).focus(); await page.keyboard.press('ArrowRight'); expect((await state(page)).pose).toEqual(observer);
  await page.locator('.tl-menu summary').click(); await page.getByRole('button', { name: 'Play in reverse', exact: true }).click(); await page.waitForTimeout(250); expect((await state(page)).time).toBeLessThan(16 + 1 / 30); expect((await state(page)).mode).toBe('explore'); await action(page, 'pause');
  await action(page, 'reset'); expect((await state(page)).pose).toEqual(observer); expect((await state(page)).time).toBe(0); expect((await state(page)).project).toEqual(before.project);
  await seek(page, 12); await page.getByTestId('viewport-mode').selectOption('playback'); const followed = await state(page); expect(followed.pose.position).toEqual(followed.evaluation.position); expect(followed.rig.visible).toBe(false);
});

test('Plan review and normal camera key markers remain available without taking over the plan camera', async ({ page }) => {
  await page.getByTestId('viewport-mode').selectOption('plan'); await seek(page, 10);
  const plan = await page.evaluate(() => { const c = (window as any).__cyrusStudio.controller; return { position: c.host.planCamera.position.toArray(), quaternion: c.host.planCamera.quaternion.toArray(), zoom: c.host.planCamera.zoom, markers: c.navigation.path.children.filter((o: any) => o.userData.stopId).length }; });
  expect(plan.markers).toBe((await state(page)).project.stops.length); await expect(page.getByTestId('safe-frame-overlay')).toBeHidden();
  await page.getByTestId('play').click(); await page.waitForTimeout(250); await page.getByTestId('play').click();
  const after = await page.evaluate(() => { const c = (window as any).__cyrusStudio.controller; return { position: c.host.planCamera.position.toArray(), quaternion: c.host.planCamera.quaternion.toArray(), zoom: c.host.planCamera.zoom, markers: c.navigation.path.children.filter((o: any) => o.userData.stopId).length }; });
  expect(after).toEqual(plan); expect((await state(page)).mode).toBe('plan'); expect((await state(page)).rig.visible).toBe(true);
});

test('imported Max rig follows original motion while the observer and workspace frame remain independent', async ({ page }) => {
  await page.getByLabel('Import camera animation', { exact: true }).setInputFiles(resolve('exports/fixtures/max-camera/free.json')); await page.getByTestId('confirm-camera-animation').click();
  const source = await state(page); await framePreset(page, 'vertical'); expect((await state(page)).cameraAspect).toBeCloseTo(source.evaluation.aspect, 8);
  await page.getByTestId('viewport-mode').selectOption('orbit'); await seek(page, source.project.opening + source.project.revealDuration + .135); await page.evaluate(() => new Promise(requestAnimationFrame));
  const before = await state(page); expect(before.cameraAspect).toBeCloseTo(9 / 16, 8); expect(before.rig.position).toEqual(before.evaluation.position);
  expect(await page.evaluate(() => (window as any).__cyrusStudio.controller.navigation.path.children.filter((o: any) => o.userData.protected).length)).toBe(2);
  await page.getByTestId('play').click(); await page.waitForTimeout(300); await page.getByTestId('play').click(); const after = await state(page);
  expect(after.pose).toEqual(before.pose); expect(after.rig.position).toEqual(after.evaluation.position); expect(after.rig.position).not.toEqual(before.rig.position); expect(after.project).toEqual(source.project);
  expect(after.stats.uploads).toBe(before.stats.uploads); expect(after.stats.rebuilds).toBe(before.stats.rebuilds);
  await page.getByTestId('viewport-mode').selectOption('playback'); await page.evaluate(() => new Promise(requestAnimationFrame)); expect((await state(page)).cameraAspect).toBeCloseTo(source.evaluation.aspect, 8);
});

test('Orbit produces no idle timeline writes or geometry rebuilds and stops rendering after input', async ({ page }) => {
  await page.getByTestId('viewport-mode').selectOption('orbit'); await dragOrbit(page); await page.evaluate(() => new Promise(requestAnimationFrame));
  await page.evaluate(() => { (window as any).__tlMutations = 0; new MutationObserver(r => (window as any).__tlMutations += r.length).observe(document.querySelector('.animation-timeline')!, { subtree: true, childList: true, attributes: true, characterData: true }); });
  const before = await state(page); await dragOrbit(page); await page.waitForTimeout(250); const after = await state(page);
  expect(after.pose.position).not.toEqual(before.pose.position); expect(after.project).toEqual(before.project); expect(after.stats.uploads).toBe(before.stats.uploads); expect(after.stats.rebuilds).toBe(before.stats.rebuilds);
  expect(await page.evaluate(() => (window as any).__tlMutations)).toBe(0); await page.waitForTimeout(300); expect((await state(page)).stats.renders).toBe(after.stats.renders);
});

test('off-centre camera key picking and transform controls use the fitted portrait frame', async ({ page }) => {
  await page.getByTestId('viewport-mode').selectOption('orbit'); await framePreset(page, 'vertical'); const before = await state(page);
  const id = await page.evaluate(() => {
    const c = (window as any).__cyrusStudio.controller, stop = c.project.stops[0];
    c.host.perspective.position.fromArray(stop.position).add({ x: 0, y: 0, z: 20 });
    c.navigation.orbit.target.fromArray(stop.position).add({ x: -2, y: 0, z: 0 }); c.navigation.orbit.update(); c.host.invalidate(); return stop.id;
  });
  await page.evaluate(() => new Promise(requestAnimationFrame));
  const point = await page.evaluate(id => {
    const c = (window as any).__cyrusStudio.controller, marker = c.navigation.handles.find((o: any) => o.userData.stopId === id);
    const p = marker.position.clone().project(c.host.perspective), frame = document.querySelector('[data-testid="safe-output-frame"]')!.getBoundingClientRect();
    return { x: frame.x + (p.x + 1) * frame.width / 2, y: frame.y + (1 - p.y) * frame.height / 2, ndc: p.x };
  }, id);
  expect(Math.abs(point.ndc)).toBeGreaterThan(.1); expect(Math.abs(point.ndc)).toBeLessThan(.9); await page.mouse.click(point.x, point.y);
  const picked = await page.evaluate(() => { const c = (window as any).__cyrusStudio.controller; return { owner: c.navigation.gizmo.object?.userData.owner, viewport: c.navigation.gizmo.viewport.toArray() }; });
  expect(picked.owner).toBe(id); expect(picked.viewport[2] / picked.viewport[3]).toBeCloseTo(9 / 16, 8);
  expect((await state(page)).project).toEqual(before.project);
});
