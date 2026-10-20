import { menuAction } from './ui-actions';
import { test, expect, type Page } from '@playwright/test';
const state = (page: Page) => page.evaluate(() => { const c = (window as any).__cyrusStudio.controller; return { pose: c.host.capture(), project: c.project, stats: { ...c.host.stats }, editing: c.cameraEditingStopId, mode: c.mode }; });
const action = (page: Page, name: string, payload?: unknown) => page.evaluate(async ({ name, payload }) => { await (window as any).__cyrusStudio.controller.act(name, payload); }, { name, payload });
test.beforeEach(async ({ page }) => { await page.goto('/'); await page.waitForFunction(() => (window as any).__cyrusStudio?.ready); });

test('first-person movement and drag change only the viewport; Capture saves pose, lens and actual framing', async ({ page }) => {
  await expect(page.getByTestId('viewport-mode')).toHaveValue('camera');
  const lens = page.getByRole('spinbutton', { name: 'Viewport camera field of view in degrees' }); await lens.fill('61'); await lens.press('Tab');
  const canvas = page.locator('[data-testid="viewport"] canvas'); await canvas.focus(); await page.waitForTimeout(120); const before = await state(page);
  await page.keyboard.down('KeyW'); await page.waitForTimeout(350); await page.keyboard.up('KeyW');
  const box = await canvas.boundingBox(); await page.mouse.move(box!.x + box!.width / 2, box!.y + box!.height / 2); await page.mouse.down(); await page.mouse.move(box!.x + box!.width / 2 + 70, box!.y + box!.height / 2 + 20, { steps: 8 }); await page.mouse.up(); await page.waitForTimeout(120);
  const moved = await state(page); expect(moved.pose.position).not.toEqual(before.pose.position); expect(moved.pose.quaternion).not.toEqual(before.pose.quaternion); expect(moved.project).toEqual(before.project);
  expect(moved.stats.rebuilds).toBe(before.stats.rebuilds); expect(moved.stats.uploads).toBe(before.stats.uploads);
  await page.getByTestId('camera-primary-action').click(); const captured = await state(page), stop = captured.project.stops.find((s: any) => s.id === captured.editing)!;
  expect(stop.position).toEqual(moved.pose.position); expect(stop.quaternion).toEqual(moved.pose.quaternion); expect(stop.fov).toBe(61); expect(stop.aspect).toBeCloseTo(moved.pose.aspect!, 5); expect(captured.pose.aspect).toBeCloseTo(stop.aspect, 5);
  expect(captured.editing).toBe(stop.id); await page.getByTestId('undo').click(); expect((await state(page)).project.stops).toEqual(before.project.stops);
});

test('Edit in viewport then Save updates the named owner once even after a different stop is selected', async ({ page }) => {
  await page.getByRole('button', { name: /04 The pavilion/ }).click(); const before = await state(page), original = before.project.stops[3];
  await page.getByTestId('edit-camera-stop').click(); const loaded = await state(page); expect(loaded.pose.position).toEqual(original.position); expect(loaded.pose.quaternion).toEqual(original.quaternion);
  const canvas = page.locator('[data-testid="viewport"] canvas'); await canvas.focus(); await page.keyboard.down('KeyE'); await page.waitForTimeout(300); await page.keyboard.up('KeyE');
  await page.getByRole('button', { name: /01 The masterplan/ }).click(); const draft = await state(page); expect(draft.project).toEqual(before.project); expect(draft.editing).toBe(original.id);
  await page.getByTestId('camera-primary-action').click(); const saved = await state(page); expect(saved.project.stops[3].position).toEqual(draft.pose.position); expect(saved.project.stops[3].position[1]).toBeGreaterThan(original.position[1]); expect(saved.project.stops[0]).toEqual(before.project.stops[0]);
  await page.getByTestId('undo').click(); expect((await state(page)).project.stops).toEqual(before.project.stops);
});

test('camera input stops on blur and playback; idle stays still, Plan cannot capture a different camera', async ({ page }) => {
  await page.getByTestId('viewport-mode').selectOption('camera'); const canvas = page.locator('[data-testid="viewport"] canvas'); await canvas.focus();
  await page.keyboard.down('KeyW'); await page.waitForTimeout(150); await page.getByRole('textbox', { name: 'Project title' }).focus(); await page.keyboard.up('KeyW');
  await page.waitForTimeout(150); const stopped = await state(page); await page.waitForTimeout(700); const idle = await state(page); expect(idle.pose).toEqual(stopped.pose); expect(idle.stats.renders).toBe(stopped.stats.renders);
  await action(page, 'time', 14); await action(page, 'navigationMode', 'camera'); expect((await state(page)).pose).toEqual(stopped.pose);
  await page.getByTestId('viewport-mode').selectOption('plan'); await expect(page.getByTestId('camera-primary-action')).toBeDisabled();
  const rejection = await page.evaluate(async () => { try { await (window as any).__cyrusStudio.controller.act('captureStop'); return ''; } catch (e) { return String(e); } }); expect(rejection).toContain('perspective viewport');
  expect((await state(page)).project.stops).toEqual(stopped.project.stops);
});

test('new viewport keyframe reaches the actual compiled player without editor navigation controls', async ({ page }) => {
  await page.getByTestId('viewport-mode').selectOption('camera'); const canvas = page.locator('[data-testid="viewport"] canvas'); await canvas.focus(); await page.keyboard.down('KeyD'); await page.waitForTimeout(180); await page.keyboard.up('KeyD');
  await page.getByTestId('camera-primary-action').click(); const captureState = await state(page), captured = captureState.project.stops.find((s: any) => s.id === captureState.editing)!;
  await menuAction(page, 'output-menu', 'preview-export'); const frame = page.frameLocator('iframe'); await frame.getByRole('button', { name: `Go to ${captured.name}`, exact: true }).click();
  const evaluation = await page.frames()[1].evaluate(() => (window as any).__cyrusPlayer.evaluation); expect(evaluation.position).toEqual(captured.position); evaluation.quaternion.forEach((value: number, i: number) => expect(value).toBeCloseTo(captured.quaternion[i], 12)); expect(evaluation.aspect).toBe(captured.aspect); expect(evaluation.fov).toBe(captured.fov);
  await expect(frame.getByRole('button', { name: 'Camera view', exact: true })).toHaveCount(0);
});
