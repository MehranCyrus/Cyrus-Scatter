import { test, expect, type Page, type Locator } from '@playwright/test';
import { menuAction } from './ui-actions';
import { demoGLB } from '../../src/assets/demo';

const read = (page: Page) => page.evaluate(() => {
  const c = (window as any).__cyrusStudio.controller;
  return { project: c.project, pose: c.host.capture(), stats: { ...c.host.stats }, mode: c.mode, time: c.time, playing: c.playing,
    plan: { position: c.host.planCamera.position.toArray(), zoom: c.host.planCamera.zoom }, orbitTarget: c.navigation.orbit.target.toArray() };
});
const distance = (a: number[], b: number[]) => Math.hypot(...a.map((v, i) => v - b[i]));
async function field(control: Locator, value: string) { await control.fill(value); await control.press('Tab'); }
async function drag(page: Page, button: 'left' | 'right' | 'middle', dx = 75, dy = 25) {
  const box = (await page.locator('[data-testid="viewport"] canvas').boundingBox())!;
  await page.mouse.move(box.x + box.width * .45, box.y + box.height * .45);
  await page.mouse.down({ button }); await page.mouse.move(box.x + box.width * .45 + dx, box.y + box.height * .45 + dy, { steps: 8 }); await page.mouse.up({ button });
}
async function wheel(page: Page, dy: number) {
  const box = (await page.locator('[data-testid="viewport"] canvas').boundingBox())!;
  await page.mouse.move(box.x + box.width / 2, box.y + box.height / 2); await page.mouse.wheel(0, dy); await page.waitForTimeout(100);
}
async function summary(page: Page, name: string | RegExp) { const control = page.locator('summary').filter({ hasText: name }); if (!await control.evaluate(el => el.parentElement!.hasAttribute('open'))) await control.click(); }
const pageErrors = new WeakMap<Page, string[]>();
test.beforeEach(async ({ page }) => { const errors: string[] = []; pageErrors.set(page, errors); page.on('pageerror', e => errors.push(e.message)); await page.goto('/'); await page.waitForFunction(() => (window as any).__cyrusStudio?.ready); await page.waitForTimeout(200); });
test.afterEach(async ({ page }) => { expect(pageErrors.get(page)).toEqual([]); });

test.use({ video: 'on' });
test('Camera supports look, middle/Shift-pan, wheel in/out, speed and Shift boost without authoring or uploading', async ({ page }) => {
  const before = await read(page);
  const lens = page.getByLabel('Viewport camera field of view in degrees'), speed = page.getByLabel('Camera movement speed in metres per second');
  await field(lens, '47.5'); await field(speed, '3.15'); expect((await read(page)).pose.fov).toBe(47.5); expect(await page.evaluate(() => (window as any).__cyrusStudio.controller.navigation.camera.speed)).toBe(3.15);
  await field(lens, '120'); expect((await read(page)).pose.fov).toBe(47.5); await field(lens, String(before.pose.fov)); await field(speed, '3');
  await drag(page, 'left'); const looked = await read(page); expect(looked.pose.quaternion).not.toEqual(before.pose.quaternion); expect(looked.pose.position).toEqual(before.pose.position);
  await drag(page, 'right', -35, 10); const rightLook = await read(page); expect(rightLook.pose.quaternion).not.toEqual(looked.pose.quaternion);
  await drag(page, 'middle'); const panned = await read(page); expect(distance(panned.pose.position, rightLook.pose.position)).toBeGreaterThan(.1); expect(panned.pose.quaternion).toEqual(rightLook.pose.quaternion);
  await page.keyboard.down('Shift'); await drag(page, 'left', -40, 15); await page.keyboard.up('Shift'); const shiftPan = await read(page); expect(shiftPan.pose.position).not.toEqual(panned.pose.position); expect(shiftPan.pose.quaternion).toEqual(panned.pose.quaternion);
  await wheel(page, -240); const zoomed = await read(page); expect(distance(zoomed.pose.position, shiftPan.pose.position)).toBeCloseTo(1.8, 6); expect(zoomed.pose.fov).toBe(before.pose.fov); expect(zoomed.pose.quaternion).toEqual(shiftPan.pose.quaternion);
  await wheel(page, 240); expect(distance((await read(page)).pose.position, shiftPan.pose.position)).toBeLessThan(1e-10);
  await field(page.getByLabel('Camera movement speed in metres per second'), '6'); await wheel(page, -120); const faster = await read(page); expect(distance(faster.pose.position, shiftPan.pose.position)).toBeCloseTo(1.8, 6);
  await page.keyboard.down('Shift'); await wheel(page, -120); await page.keyboard.up('Shift'); const boosted = await read(page); expect(distance(boosted.pose.position, faster.pose.position)).toBeCloseTo(7.2, 6);
  expect(boosted.project).toEqual(before.project); expect(boosted.stats.rebuilds).toBe(before.stats.rebuilds); expect(boosted.stats.uploads).toBe(before.stats.uploads);
  await page.getByRole('textbox', { name: 'Project title' }).hover(); await page.mouse.wheel(0, -240); await page.waitForTimeout(100); expect((await read(page)).pose).toEqual(boosted.pose);
  await page.waitForTimeout(250); const idle = await read(page); await page.waitForTimeout(500); expect((await read(page)).stats.renders).toBe(idle.stats.renders);
});

test('Orbit rotates/pans/zooms; Plan pans/zooms its own camera; Playback cannot move the camera with editor gestures', async ({ page }) => {
  const mode = page.getByTestId('viewport-mode'); await mode.selectOption('orbit'); const before = await read(page);
  await drag(page, 'left'); const rotated = await read(page); expect(rotated.pose.position).not.toEqual(before.pose.position); expect(rotated.pose.quaternion).not.toEqual(before.pose.quaternion);
  await drag(page, 'right'); const pan = await read(page); expect(pan.orbitTarget).not.toEqual(rotated.orbitTarget);
  await wheel(page, -240); const zoom = await read(page); expect(distance(zoom.pose.position, zoom.orbitTarget)).toBeLessThan(distance(pan.pose.position, pan.orbitTarget));
  await mode.selectOption('plan'); const plan = await read(page); await drag(page, 'left'); await wheel(page, -240); const planMoved = await read(page);
  expect(planMoved.plan.position).not.toEqual(plan.plan.position); expect(planMoved.plan.zoom).toBeGreaterThan(plan.plan.zoom); expect(planMoved.pose).toEqual(plan.pose);
  await mode.selectOption('camera'); await wheel(page, -120); expect((await read(page)).pose.position).not.toEqual(zoom.pose.position);
  await mode.selectOption('playback'); await page.waitForTimeout(100); const playing = await read(page); await drag(page, 'left'); await drag(page, 'middle'); await wheel(page, -240);
  expect((await read(page)).pose).toEqual(playing.pose); expect((await read(page)).project).toEqual(before.project); await expect(page.getByTestId('camera-primary-action')).toBeDisabled();
});

test('saved camera numerical fields, portrait capture, preserved path, timeline timing and deletion reach the authored owner', async ({ page }) => {
  await page.getByRole('button', { name: /01 The masterplan/ }).click(); const before = await read(page), id = before.project.stops[0].id;
  await field(page.getByLabel('View name', { exact: true }), 'Courtyard arrival'); await field(page.getByLabel('Camera key time in seconds', { exact: true }), '8');
  await summary(page, /^Advanced camera$/); await field(page.getByLabel('Saved field of view · °', { exact: true }), '57'); await field(page.getByLabel('Frame aspect', { exact: true }), '1.8');
  await field(page.getByLabel('Camera position · metres X', { exact: true }), '12.34567'); await field(page.getByLabel('Look target · world metres X', { exact: true }), '1.23456');
  let s = (await read(page)).project.stops.find((v: any) => v.id === id); expect(s).toMatchObject({ name: 'Courtyard arrival', hold: 3, fov: 57, aspect: 1.8 }); expect(s.position[0]).toBe(12.34567); expect(s.quaternion).not.toEqual(before.project.stops[0].quaternion);
  await page.getByTestId('edit-camera-stop').click(); await summary(page, /^Portrait framing/); await page.getByRole('button', { name: 'Capture portrait from view', exact: true }).click();
  await field(page.getByLabel('Portrait FOV · °', { exact: true }), '49'); await field(page.getByLabel('Portrait aspect', { exact: true }), '0.6'); await field(page.getByLabel('Portrait position Y', { exact: true }), '7.12345');
  s = (await read(page)).project.stops.find((v: any) => v.id === id); expect(s.portrait).toMatchObject({ fov: 49, aspect: .6 }); expect(s.portrait.position[1]).toBe(7.12345);
  await summary(page, /^Preserved camera path/); await field(page.getByLabel('Departure handle X', { exact: true }), '2.12345'); await field(page.getByLabel('Arrival handle Z', { exact: true }), '-3.45678');
  const segment = (await read(page)).project.segments[0]; expect(segment.duration).toBe(6); expect(segment.control1[0]).toBe(2.12345); expect(segment.control2[2]).toBe(-3.45678);
  await page.getByLabel('Camera key interpolation', { exact: true }).selectOption('ease'); expect((await read(page)).project.segments[0].ease).toBe(.2);
  await page.getByLabel('Keyframe options', { exact: true }).click(); await page.getByRole('button', { name: 'Delete camera key', exact: true }).click(); expect((await read(page)).project.stops.some((v: any) => v.id === id)).toBe(false);
  await page.getByTestId('undo').click(); expect((await read(page)).project.stops[0].id).toBe(id);
});

test('layer names, ordering, export/default/viewer options, reveal, isolate and Show all are active controls', async ({ page }) => {
  await page.getByTestId('scene-toggle').click(); await page.getByRole('button', { name: '07 Trees V', exact: true }).click(); const original = await read(page), id = original.project.layers[6].id;
  await field(page.getByLabel('Layer name', { exact: true }), 'Canopy');
  for (const name of ['Include in published presentation', 'Initially visible', 'Allow visitors to show or hide']) await page.getByRole('checkbox', { name, exact: false }).uncheck();
  await field(page.getByLabel('Reveal position · 0 to 1', { exact: true }), '0.6'); await field(page.getByLabel('Reveal transition · %', { exact: true }), '25');
  expect((await read(page)).project.layers.find((l: any) => l.id === id)).toMatchObject({ name: 'Canopy', included: false, defaultVisible: false, viewerToggle: false, reveal: .6, fade: .25 });
  await page.getByRole('button', { name: 'Move layer up', exact: true }).click(); expect((await read(page)).project.layers[5].id).toBe(id);
  await page.getByRole('button', { name: 'Move layer down', exact: true }).click(); expect((await read(page)).project.layers[6].id).toBe(id);
  await page.getByRole('complementary', { name: 'Selection inspector' }).getByRole('button', { name: 'Isolate initially', exact: true }).click(); expect((await read(page)).project.layers.filter((l: any) => l.defaultVisible).map((l: any) => l.id)).toEqual([id]);
  await page.getByRole('button', { name: 'Show all initially', exact: true }).click(); expect((await read(page)).project.layers.every((l: any) => l.defaultVisible)).toBe(true); await expect(page.getByTestId('error')).toBeHidden();
});

test('asset transforms, node search/paging/assignment and removal operate through their actual UI', async ({ page }) => {
  await page.getByTestId('scene-toggle').click(); await page.locator('#hierarchy-body .asset-row').first().click(); const before = await read(page);
  await field(page.getByLabel('Asset name', { exact: true }), 'Owned garden'); await field(page.getByLabel('Position · metres X', { exact: true }), '2.12345'); await field(page.getByLabel('Rotation · degrees Y', { exact: true }), '23.5'); await field(page.getByLabel('Uniform scale', { exact: true }), '1.1');
  let instance = (await read(page)).project.instances[0]; expect(instance.name).toBe('Owned garden'); expect(instance.transform.position[0]).toBe(2.12345); expect(instance.transform.scale).toBe(1.1); expect(instance.transform.rotation).not.toEqual(before.project.instances[0].transform.rotation);
  await summary(page, /^Advanced rotation/); await field(page.getByLabel('Rotation W', { exact: true }), '0.95'); expect((await read(page)).project.instances[0].transform.rotation[3]).toBe(.95);
  const filter = page.getByRole('searchbox', { name: 'Find a node', exact: true }); await filter.fill('not-a-node'); await expect(page.getByText('No matching nodes.', { exact: true })).toBeVisible(); await filter.fill('');
  const next = page.locator('#inspector-body').getByRole('button', { name: 'Next', exact: true }); if (await next.count()) { await next.click(); await page.locator('#inspector-body').getByRole('button', { name: 'Previous', exact: true }).click(); }
  const assignment = page.locator('select[data-scope="node"]').first(), node = await assignment.getAttribute('data-node'), layer = before.project.layers[1].id;
  await assignment.selectOption(layer); instance = (await read(page)).project.instances[0]; expect(instance.membership[node!]).toBe(layer);
  await page.getByRole('button', { name: 'Remove asset', exact: true }).click(); await expect.poll(async () => (await read(page)).project.instances.length).toBe(0);
  await page.getByTestId('undo').click(); await expect.poll(async () => (await read(page)).project.instances.length).toBe(1); expect((await read(page)).project.instances[0].name).toBe('Owned garden');
});

test('plan calibration fields, alignment witness and remove/undo preserve the owned plan', async ({ page }) => {
  await page.getByTestId('scene-toggle').click(); await page.locator('.plan-summary').getByRole('button', { name: 'Edit', exact: true }).click();
  await page.getByTestId('viewport-mode').selectOption('plan'); const before = await read(page);
  await field(page.getByLabel('Point A · pixels X', { exact: true }), '10.5'); await field(page.getByLabel('Point B · pixels Y', { exact: true }), '20.25'); await field(page.getByLabel('A–B distance · metres', { exact: true }), '75.125');
  await field(page.getByLabel('Point A world origin · metres Z', { exact: true }), '-22.34567'); await field(page.getByLabel('World rotation · radians', { exact: true }), '0.125');
  await summary(page, /^Third-point alignment check/); await field(page.getByLabel('Check point · pixels X', { exact: true }), '500'); await field(page.getByLabel('Expected position · metres Z', { exact: true }), '15.25');
  const plan = (await read(page)).project.plan; expect(plan.a[0]).toBe(10.5); expect(plan.b[1]).toBe(20.25); expect(plan.distance).toBe(75.125); expect(plan.origin[2]).toBe(-22.34567); expect(plan.rotation).toBe(.125); expect(plan.third.world[2]).toBe(15.25); expect(plan.hash).toBe(before.project.plan.hash);
  await expect(page.getByText(/Third-point alignment difference:/)).toBeVisible();
  await page.getByRole('button', { name: 'Remove plan', exact: true }).click(); expect((await read(page)).project.plan).toBeUndefined(); await page.getByTestId('undo').click(); expect((await read(page)).project.plan).toEqual(plan);
});

test('presentation settings, framing, transport and reduced motion operate through the visible workspace', async ({ page }) => {
  await summary(page, /^Presentation settings$/); await field(page.getByLabel('Plan opening · s', { exact: true }), '3.25'); await field(page.getByLabel('Landscape reveal · s', { exact: true }), '6.5'); await field(page.getByLabel('Light exposure', { exact: true }), '1.4');
  await page.getByRole('checkbox', { name: 'Shadows', exact: true }).uncheck(); await page.getByLabel('Output quality').selectOption('mobile');
  expect((await read(page)).project).toMatchObject({ opening: 3.25, revealDuration: 6.5, lighting: { exposure: 1.4, shadows: false }, profile: 'mobile' });
  await page.getByLabel('Output quality').selectOption('balanced');
  const draft = (await read(page)).pose; await page.getByTestId('viewport-mode').selectOption('playback'); await page.getByLabel('Presentation preview framing', { exact: true }).selectOption('portrait');
  await expect.poll(async () => { const b = (await page.getByTestId('viewport').boundingBox())!; return b.width / b.height; }).toBeCloseTo(9 / 16, 3);
  await page.getByLabel('Presentation preview framing', { exact: true }).selectOption('landscape');
  const slider = page.getByRole('slider', { name: 'Timeline playhead', exact: true }); await slider.focus(); await slider.press('End'); expect((await read(page)).time).toBeGreaterThan(30);
  await page.getByLabel('Timeline options', { exact: true }).click(); await page.getByRole('button', { name: 'Play in reverse', exact: true }).click(); const time = (await read(page)).time; await page.waitForTimeout(250); await page.getByTestId('play').click(); expect((await read(page)).time).toBeLessThan(time); expect((await read(page)).playing).toBe(false);
  await page.getByLabel('Timeline options', { exact: true }).click(); await page.getByRole('button', { name: 'Restart presentation', exact: true }).click(); expect((await read(page)).time).toBe(0);
  await page.getByTestId('play').click(); await page.waitForTimeout(150); await page.getByTestId('play').click(); expect((await read(page)).time).toBeGreaterThan(0);
  await page.getByLabel('Timeline options', { exact: true }).click(); await page.getByRole('checkbox', { name: 'Reduced motion', exact: true }).check(); await page.getByLabel('Timeline options', { exact: true }).click();
  await page.getByTestId('play').click(); expect((await read(page)).playing).toBe(false);
  await page.getByTestId('viewport-mode').selectOption('camera'); expect((await read(page)).pose.position).toEqual(draft.position); await expect(page.getByTestId('error')).toBeHidden();
});

test('Project file picker/new/autosave and menu keyboard controls work from their actual menu items', async ({ page }) => {
  await page.getByTestId('project-menu').click(); const chooser = page.waitForEvent('filechooser'); await page.getByTestId('open-project').click(); await (await chooser).setFiles([]);
  await field(page.getByRole('textbox', { name: 'Project title' }), 'Locally retained garden'); await expect(page.getByText('Saved locally', { exact: true })).toBeVisible();
  await page.getByTestId('project-menu').click(); await page.getByRole('button', { name: 'Restore autosave', exact: true }).click(); await expect(page.getByRole('textbox', { name: 'Project title' })).toHaveValue('Locally retained garden');
  await page.getByTestId('project-menu').click(); await page.keyboard.press('Escape'); await expect(page.getByTestId('save-project')).toBeHidden(); await expect(page.getByTestId('project-menu')).toBeFocused();
  await page.getByTestId('project-menu').click(); await page.getByRole('button', { name: 'New project', exact: true }).click(); await expect(page.getByRole('textbox', { name: 'Project title' })).toHaveValue('Untitled landscape'); expect((await read(page)).project.instances).toHaveLength(0);
  await page.getByRole('button', { name: 'Explore the sample', exact: true }).click(); await expect(page.getByRole('textbox', { name: 'Project title' })).toHaveValue('The courtyard garden');
  const saved = page.waitForEvent('download'); await menuAction(page, 'project-menu', 'save-project'); expect((await saved).suggestedFilename()).toBe('project.cyrus-presentation.zip');
});

test('Space activates menus and buttons normally; viewport Space still plays/pauses and Ctrl-Z still undoes', async ({ page }) => {
  const projectMenu = page.getByTestId('project-menu'); await projectMenu.focus(); await page.keyboard.press('Space');
  await expect(page.getByTestId('save-project')).toBeVisible(); expect((await read(page)).mode).toBe('explore'); expect((await read(page)).playing).toBe(false);
  await page.keyboard.press('Escape'); await page.getByTestId('scene-toggle').focus(); await page.keyboard.press('Space'); await expect(page.getByTestId('scene-toggle')).toHaveAttribute('aria-pressed', 'true'); expect((await read(page)).mode).toBe('explore');
  await field(page.getByRole('textbox', { name: 'Project title' }), 'Undo from viewport'); const canvas = page.locator('[data-testid="viewport"] canvas'); await canvas.focus(); await page.keyboard.press('Control+z'); await expect(page.getByRole('textbox', { name: 'Project title' })).toHaveValue('The courtyard garden');
  await canvas.focus(); await page.keyboard.press('Space'); expect((await read(page)).playing).toBe(true); await page.keyboard.press('Space'); expect((await read(page)).playing).toBe(false);
});

test('zero/earlier initial animation timestamps keep playback running toward its destination', async ({ page }) => {
  const result = await page.evaluate(async () => {
    const c = (window as any).__cyrusStudio.controller;
    await c.act('reset'); await c.act('play'); cancelAnimationFrame(c.raf); const start = c.last;
    c.tick(start - 1); cancelAnimationFrame(c.raf); const forward = { playing: c.playing, time: c.time };
    c.tick(start + 50); cancelAnimationFrame(c.raf); const advanced = c.time; await c.act('pause');
    await c.act('time', Number(document.querySelector<HTMLInputElement>('#timeline')!.max));
    await c.act('reverse'); cancelAnimationFrame(c.raf); c.tick(c.last); cancelAnimationFrame(c.raf); const reverse = { playing: c.playing, time: c.time }; await c.act('pause');
    return { forward, advanced, reverse };
  });
  expect(result.forward).toEqual({ playing: true, time: 0 }); expect(result.advanced).toBeGreaterThan(0); expect(result.reverse.playing).toBe(true); expect(result.reverse.time).toBeGreaterThan(0);
});

test('actual import buttons route GLB units/up, plan replacement, artistic photo/caption/approval and portrait upload', async ({ page }) => {
  await page.getByTestId('project-menu').click(); await page.getByRole('button', { name: 'New project', exact: true }).click(); await page.getByTestId('scene-toggle').click();
  await summary(page, /^Import orientation/); await page.getByLabel('GLB source units').selectOption('0.01'); await page.getByLabel('GLB source up axis').selectOption('Z');
  let choosing = page.waitForEvent('filechooser'); await page.getByRole('complementary', { name: 'Scene hierarchy' }).getByRole('button', { name: 'Import landscape GLB', exact: true }).click(); await (await choosing).setFiles({ name: 'owned-cm-z.glb', mimeType: 'model/gltf-binary', buffer: Buffer.from(demoGLB(1949)) });
  await expect.poll(async () => (await read(page)).project.instances.length).toBe(1); const imported = (await read(page)).project.instances[0]; expect(imported.transform.scale).toBe(.01); expect(imported.transform.rotation[0]).toBeCloseTo(-Math.SQRT1_2, 12);
  const image = Buffer.from(await page.evaluate(() => { const canvas = document.createElement('canvas'); canvas.width = 128; canvas.height = 96; canvas.getContext('2d')!.fillRect(0, 0, 128, 96); return canvas.toDataURL('image/png').split(',')[1]; }), 'base64');
  choosing = page.waitForEvent('filechooser'); await page.getByRole('complementary', { name: 'Scene hierarchy' }).getByRole('button', { name: 'Import plan image', exact: true }).click(); await (await choosing).setFiles({ name: 'owned-plan.png', mimeType: 'image/png', buffer: image }); await expect.poll(async () => (await read(page)).project.plan?.width).toBe(128);
  choosing = page.waitForEvent('filechooser'); await page.getByRole('button', { name: 'Replace plan image', exact: true }).click(); await (await choosing).setFiles({ name: 'owned-plan-revision.png', mimeType: 'image/png', buffer: image }); await expect(page.getByTestId('error')).toBeHidden();
  await page.getByRole('button', { name: /01 Arrival/ }).click(); await summary(page, /^Artistic impression/);
  choosing = page.waitForEvent('filechooser'); await page.locator('.photo-section').getByRole('button', { name: 'Import artistic photo', exact: true }).click(); await (await choosing).setFiles({ name: 'owned-impression.png', mimeType: 'image/png', buffer: image }); await expect(page.getByRole('button', { name: 'Approve for current scene', exact: true })).toBeVisible();
  await field(page.getByLabel('Caption', { exact: true }), 'Owned courtyard impression'); await page.getByRole('button', { name: 'Approve for current scene', exact: true }).click(); expect((await read(page)).project.stops[0].photo.caption).toBe('Owned courtyard impression');
  await page.getByRole('checkbox', { name: 'Use upload as portrait variant', exact: true }).check(); choosing = page.waitForEvent('filechooser'); await page.locator('.photo-section').getByRole('button', { name: 'Replace artistic photo', exact: true }).click(); await (await choosing).setFiles({ name: 'owned-portrait.png', mimeType: 'image/png', buffer: image });
  await expect.poll(async () => !!(await read(page)).project.stops[0].photo.portraitHash).toBe(true); expect((await read(page)).project.stops[0].photo.approvedFingerprint).toBeUndefined();
  await page.getByRole('button', { name: 'Remove photo', exact: true }).click(); expect((await read(page)).project.stops[0].photo).toBeUndefined();
});
