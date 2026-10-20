import { test, expect, type Page } from '@playwright/test';

const authored = (page: Page) => page.evaluate(() => JSON.stringify((window as any).__cyrusStudio.controller.project));
const viewport = (page: Page) => page.getByTestId('viewport').boundingBox();
test.beforeEach(async ({ page }) => { await page.goto('/'); await page.waitForFunction(() => (window as any).__cyrusStudio?.ready); });

test('camera workspace opens uncluttered; Focus expands the same canvas and restores scene tools without edits', async ({ page }) => {
  await expect(page.getByTestId('scene-toggle')).toHaveAttribute('aria-pressed', 'false');
  await expect(page.getByRole('complementary', { name: 'Scene hierarchy' })).toBeHidden();
  await expect(page.getByRole('complementary', { name: 'Selection inspector' })).toBeVisible();
  await expect(page.getByTestId('camera-primary-action')).toHaveText('Capture view');
  await expect(page.getByRole('button', { name: 'Capture view', exact: true })).toHaveCount(1);
  const before = await authored(page), normal = (await viewport(page))!;
  expect(normal.y).toBeLessThanOrEqual(100);
  await page.getByTestId('scene-toggle').click();
  await expect(page.getByRole('complementary', { name: 'Scene hierarchy' })).toBeVisible();
  await page.locator('[data-testid="viewport"] canvas').evaluate(canvas => { (canvas as any).__identity = 'same-canvas'; });
  await page.getByTestId('focus-view').click();
  await expect(page.getByTestId('focus-view')).toHaveAttribute('aria-pressed', 'true');
  await expect(page.getByRole('complementary', { name: 'Selection inspector' })).toBeHidden();
  await expect(page.getByTestId('animation-timeline')).toBeVisible();
  const focused = (await viewport(page))!;
  expect(focused.width * focused.height).toBeGreaterThan(normal.width * normal.height * 1.2);
  expect(await page.locator('[data-testid="viewport"] canvas').evaluate(canvas => (canvas as any).__identity)).toBe('same-canvas');
  await expect(page.getByTestId('camera-primary-action')).toBeVisible();
  await page.getByTestId('focus-view').click();
  await expect(page.getByRole('complementary', { name: 'Scene hierarchy' })).toBeVisible();
  await expect(page.getByTestId('animation-timeline')).toBeVisible();
  expect(await authored(page)).toBe(before);
});

test('one commit control captures successive views, explicitly edits an owner, and finishes editing without changing it', async ({ page }) => {
  const initial = await page.evaluate(() => (window as any).__cyrusStudio.controller.project.stops.length);
  const frame = (await viewport(page))!;
  const primary = page.getByTestId('camera-primary-action');
  await primary.click();
  await expect(primary).toHaveText('Capture view');
  await primary.click();
  expect(await page.evaluate(() => (window as any).__cyrusStudio.controller.project.stops.length)).toBe(initial + 1);
  const capturedFrame = (await viewport(page))!;
  expect(capturedFrame).toEqual(frame);
  await page.getByTestId('edit-camera-stop').click();
  await expect(primary).toHaveText('Save view');
  const before = await authored(page);
  await page.getByTestId('camera-action-menu').click();
  await page.getByRole('button', { name: 'Finish editing', exact: true }).click();
  await expect(primary).toHaveText('Capture view');
  expect(await authored(page)).toBe(before);
  expect(await viewport(page)).toEqual(frame);
  await expect(page.getByRole('button', { name: 'Save view', exact: true })).toHaveCount(0);
});
