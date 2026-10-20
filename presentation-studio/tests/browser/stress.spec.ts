import { test, expect } from '@playwright/test';
import { demoGLB } from '../../src/assets/demo';
test('large-site stress remains bounded and repeated asset lifecycle releases render resources', async ({ page }) => {
  test.setTimeout(120000); await page.goto('/'); await page.waitForFunction(() => (window as any).__cyrusStudio?.ready);
  await page.evaluate(async () => (window as any).__cyrusStudio.controller.act('newProject'));
  const started = Date.now(); await page.getByLabel('Import landscape GLB', { exact: true }).setInputFiles({ name: 'large-500m.glb', mimeType: 'model/gltf-binary', buffer: Buffer.from(demoGLB(25000, 500)) });
  await page.waitForFunction(() => !(window as any).__cyrusStudio.controller.pending && (window as any).__cyrusStudio.controller.project.instances.length === 1);
  await expect(page.getByTestId('error')).toBeHidden(); const elapsed = Date.now() - started; expect(elapsed).toBeLessThan(30000);
  const report = await page.evaluate(() => {
    const c = (window as any).__cyrusStudio.controller, gl = c.host.renderer.getContext(), ext = gl.getExtension('WEBGL_debug_renderer_info');
    return { elapsed: 0, asset: c.project.assets[0], stats: c.host.stats, gpu: ext ? gl.getParameter(ext.UNMASKED_RENDERER_WEBGL) : gl.getParameter(gl.RENDERER), userAgent: navigator.userAgent };
  }); report.elapsed = elapsed; await test.info().attach('large-site-report', { body: JSON.stringify(report, null, 2), contentType: 'application/json' });
  const counts: number[] = [];
  for (let i = 0; i < 6; i++) { await page.evaluate(async () => { const c = (window as any).__cyrusStudio.controller; await c.act('newProject'); await c.act('demo'); }); await page.waitForTimeout(80); counts.push(await page.evaluate(() => (window as any).__cyrusStudio.controller.host.renderer.info.memory.geometries)); }
  expect(Math.max(...counts.slice(2)) - Math.min(...counts.slice(2))).toBeLessThanOrEqual(2);
});
