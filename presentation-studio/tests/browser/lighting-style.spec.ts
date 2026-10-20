import { test, expect } from '@playwright/test';

test('the Shadows control changes the rendered image and undo restores it without scene uploads', async ({ page }) => {
  await page.goto('/'); await page.waitForFunction(() => (window as any).__cyrusStudio?.ready);
  await page.evaluate(async () => { const c = (window as any).__cyrusStudio.controller; await c.act('time', 100); await c.act('mode', 'explore'); });
  await page.getByText('Presentation settings', { exact: true }).click();
  const capture = () => page.evaluate(() => { const h = (window as any).__cyrusStudio.controller.host; h.draw(); return { image: h.canvas.toDataURL(), ...h.stats }; });
  const on = await capture();
  await page.getByLabel('Shadows', { exact: true }).uncheck();
  const off = await capture(); expect(off.image).not.toBe(on.image);
  await page.getByTestId('undo').click(); await expect(page.getByLabel('Shadows', { exact: true })).toBeChecked();
  const restored = await capture(); expect(restored.image).toBe(on.image);
  expect(restored.rebuilds).toBe(on.rebuilds); expect(restored.uploads).toBe(on.uploads);
});

test('architectural lighting is editable, reuses its environment and restores the soft style through undo', async ({ page }) => {
  await page.goto('/'); await page.waitForFunction(() => (window as any).__cyrusStudio?.ready);
  await page.getByText('Presentation settings', { exact: true }).click();
  const style = page.getByLabel('Lighting style', { exact: true });
  await style.selectOption('architectural');
  await page.waitForFunction(() => (window as any).__cyrusStudio.controller.host.scene.environment !== null);
  const first = await page.evaluate(async () => {
    await new Promise(requestAnimationFrame); await new Promise(requestAnimationFrame);
    const c = (window as any).__cyrusStudio.controller;
    return { environment: c.host.scene.environment.uuid, ...c.host.stats };
  });
  await page.evaluate(async () => { const c = (window as any).__cyrusStudio.controller; for (const time of [9, 10, 11, 12, 10, 9]) await c.act('time', time); });
  const after = await page.evaluate(() => { const c = (window as any).__cyrusStudio.controller; return { environment: c.host.scene.environment.uuid, ...c.host.stats }; });
  expect(after.environment).toBe(first.environment); expect(after.rebuilds).toBe(first.rebuilds); expect(after.uploads).toBe(first.uploads);
  await page.getByTestId('undo').click();
  await expect(style).toHaveValue('soft');
  expect(await page.evaluate(() => (window as any).__cyrusStudio.controller.host.scene.environment)).toBeNull();
  await page.getByTestId('redo').click(); await expect(style).toHaveValue('architectural');
  await expect(page.getByTestId('error')).toBeHidden();
});

test('architectural reflections regenerate after graphics context restoration', async ({ page }) => {
  await page.goto('/'); await page.waitForFunction(() => (window as any).__cyrusStudio?.ready);
  await page.evaluate(async () => { const c = (window as any).__cyrusStudio.controller; await c.act('updateProject', { lighting: { ...c.project.lighting, style: 'architectural' } }); });
  const before = await page.evaluate(() => (window as any).__cyrusStudio.controller.host.scene.environment.uuid);
  await page.evaluate(() => { const c = (window as any).__cyrusStudio.controller; (window as any).__lightingContext = c.host.renderer.getContext().getExtension('WEBGL_lose_context'); (window as any).__lightingContext.loseContext(); });
  await page.waitForFunction(() => (window as any).__cyrusStudio.controller.host.lost);
  await page.waitForTimeout(150);
  await page.evaluate(() => (window as any).__lightingContext.restoreContext());
  await page.waitForFunction(() => { const host = (window as any).__cyrusStudio.controller.host; return !host.lost && host.scene.environment !== null; });
  expect(await page.evaluate(() => (window as any).__cyrusStudio.controller.host.scene.environment.uuid)).not.toBe(before);
  await expect(page.getByTestId('error')).toBeHidden();
});
