import { menuAction } from './ui-actions';
import { test, expect } from '@playwright/test';
import { existsSync } from 'node:fs';
import { readFile, writeFile, mkdir } from 'node:fs/promises';
import { resolve } from 'node:path';
import { createServer } from 'node:http';
import { unzipSync } from 'fflate';

test('the previous Botanical Islands GLB saves, reopens and independently presents its layers and artistic stops', async ({ page, browser }) => {
  test.setTimeout(180000);
  const fixture = resolve('exports/fixtures/previous-study/botanical-islands.cyrus-presentation.zip');
  test.skip(!existsSync(fixture), 'Run node --import tsx tools/previous-study-fixture.ts with the previous study available');
  const errors: string[] = []; page.on('pageerror', e => errors.push(e.message));
  await page.goto('/'); await page.waitForFunction(() => (window as any).__cyrusStudio?.ready);
  const began = Date.now(); await page.getByLabel('Open project archive', { exact: true }).setInputFiles(fixture);
  await expect(page.getByRole('textbox', { name: 'Project title' })).toHaveValue('Botanical Islands — presentation MVP', { timeout: 60000 });
  await expect(page.getByTestId('error')).toBeHidden();
  const source = await page.evaluate(() => {
    const c = (window as any).__cyrusStudio.controller; let rows = 0; c.host.active.group.traverse((o: any) => { if (o.isInstancedMesh) rows += o.count; });
    const gl = c.host.renderer.getContext(), ext = gl.getExtension('WEBGL_debug_renderer_info');
    return { projectId: c.project.id, hash: c.project.assets[0].hash, triangles: c.project.assets[0].triangles, nodeCount: c.project.assets[0].nodes.length, rows, layers: c.project.layers.map((l: any) => ({ id: l.id, name: l.name })), stops: c.project.stops.length, gpu: ext ? gl.getParameter(ext.UNMASKED_RENDERER_WEBGL) : gl.getParameter(gl.RENDERER) };
  });
  expect(source.hash).toBe('a4ae0b17d3bbff359df72360d549f90e99f2fc6878249df6e59d3428551de93d'); expect(source.rows).toBe(2330); expect(source.nodeCount).toBe(99); expect(source.stops).toBe(17);
  const openedMs = Date.now() - began;
  const draftBefore = await page.evaluate(() => { const c = (window as any).__cyrusStudio.controller; return { pose: c.host.capture(), project: JSON.stringify(c.project), uploads: c.host.stats.uploads }; });
  const box = (await page.locator('[data-testid="viewport"] canvas').boundingBox())!;
  await page.mouse.move(box.x + box.width / 2, box.y + box.height / 2); await page.mouse.down({ button: 'middle' }); await page.mouse.move(box.x + box.width / 2 + 70, box.y + box.height / 2 + 20, { steps: 6 }); await page.mouse.up({ button: 'middle' });
  const pan = await page.evaluate(() => (window as any).__cyrusStudio.controller.host.capture()); expect(pan.position).not.toEqual(draftBefore.pose.position);
  await page.mouse.wheel(0, -180); await page.waitForTimeout(100);
  const navigated = await page.evaluate(() => { const c = (window as any).__cyrusStudio.controller; return { pose: c.host.capture(), project: JSON.stringify(c.project), uploads: c.host.stats.uploads }; });
  expect(navigated.pose.position).not.toEqual(pan.position); expect(navigated.pose.quaternion).toEqual(draftBefore.pose.quaternion); expect(navigated.pose.fov).toBe(draftBefore.pose.fov); expect(navigated.project).toBe(draftBefore.project); expect(navigated.uploads).toBe(draftBefore.uploads);
  await mkdir('exports/qualification', { recursive: true });
  const saved = page.waitForEvent('download'); await menuAction(page, 'project-menu', 'save-project'); const editable = await readFile((await (await saved).path())!);
  await writeFile('exports/qualification/botanical-islands-project.cyrus-presentation.zip', editable);
  await menuAction(page, 'output-menu', 'preview-export'); const frame = page.frameLocator('iframe');
  await frame.getByRole('button', { name: 'Go to Western meadow', exact: true }).click(); await expect(frame.locator('img[alt="Artist impression"]')).toHaveCSS('opacity', '1');
  await frame.getByRole('button', { name: 'Layers', exact: true }).click(); await frame.getByRole('checkbox', { name: 'Trees', exact: true }).uncheck(); await expect(frame.locator('img[alt="Artist impression"]')).toHaveCSS('opacity', '0');
  await page.getByRole('button', { name: 'Close preview', exact: true }).click();
  const download = page.waitForEvent('download'); await menuAction(page, 'output-menu', 'export-website'); const publicBytes = await readFile((await (await download).path())!), files = unzipSync(publicBytes);
  await writeFile('exports/qualification/botanical-islands-presentation.zip', publicBytes);
  const manifest = JSON.parse(new TextDecoder().decode(files['manifest.json'])); expect(manifest.project.layers.map((l: any) => l.name)).toEqual(source.layers.map((l: any) => l.name));
  const server = createServer((req, res) => { const path = (req.url ?? '').replace(/^\/presentations\/botanical\//, '') || 'index.html', bytes = files[path]; if (!bytes) { res.writeHead(404).end(); return; } res.setHeader('Content-Type', path.endsWith('.js') ? 'text/javascript' : path.endsWith('.css') ? 'text/css' : path.endsWith('.html') ? 'text/html' : 'application/octet-stream'); res.end(bytes); });
  await new Promise<void>(r => server.listen(0, '127.0.0.1', r)); const context = await browser.newContext({ viewport: { width: 1440, height: 900 } }), player = await context.newPage();
  const origin = `http://127.0.0.1:${(server.address() as { port: number }).port}`, external: string[] = [];
  player.on('pageerror', e => errors.push(e.message)); player.on('request', req => { if (!req.url().startsWith(origin) && !req.url().startsWith('blob:')) external.push(req.url()); });
  try {
    await player.goto(`${origin}/presentations/botanical/`); await player.waitForFunction(() => (window as any).__cyrusPlayer?.ready);
    await player.getByRole('button', { name: 'Go to Pavilion approach', exact: true }).click(); await expect(player.locator('img[alt="Artist impression"]')).toHaveCSS('opacity', '1');
    await player.screenshot({ path: 'exports/qualification/botanical-islands-artistic.png' });
    const telemetry = await player.evaluate(async () => {
      const p = (window as any).__cyrusPlayer.project, end = p.opening + p.revealDuration + p.stops.reduce((n: number, s: any) => n + s.hold, 0) + p.segments.reduce((n: number, s: any) => n + s.duration, 0);
      (window as any).__cyrusPlayer.setTime(end - p.stops.at(-1).hold); await new Promise(r => requestAnimationFrame(() => requestAnimationFrame(r)));
      const first = { ...(window as any).__cyrusPlayer.stats }, start = performance.now(), intervals: number[] = []; let last = start;
      await new Promise<void>(resolve => { const frame = (now: number) => { intervals.push(now - last); last = now; (window as any).__cyrusPlayer.setTime((end - 12) + (now - start) / 1000); if (now - start > 10000) resolve(); else requestAnimationFrame(frame); }; requestAnimationFrame(frame); });
      const sorted = intervals.slice(2).sort((a, b) => a - b), final = { ...(window as any).__cyrusPlayer.stats };
      const gl = document.querySelector('canvas')!.getContext('webgl2')!, ext = gl.getExtension('WEBGL_debug_renderer_info');
      return { initial: first, final, rafIntervalP95Ms: sorted[Math.floor(sorted.length * .95)], gpu: ext ? gl.getParameter(ext.UNMASKED_RENDERER_WEBGL) : gl.getParameter(gl.RENDERER), userAgent: navigator.userAgent };
    });
    expect(telemetry.final.rebuilds).toBe(telemetry.initial.rebuilds); expect(telemetry.final.uploads).toBe(telemetry.initial.uploads);
    await player.evaluate(() => { const p = (window as any).__cyrusPlayer.project, end = p.opening + p.revealDuration + p.stops.reduce((n: number, s: any) => n + s.hold, 0) + p.segments.reduce((n: number, s: any) => n + s.duration, 0); (window as any).__cyrusPlayer.setTime(end - p.stops.at(-1).hold); });
    await player.screenshot({ path: 'exports/qualification/botanical-islands-live-3d.png' });
    await player.setViewportSize({ width: 390, height: 844 }); await player.getByRole('button', { name: 'Reduced motion', exact: true }).click(); await player.getByRole('button', { name: 'Go to Pavilion approach', exact: true }).click();
    await expect(player.locator('img[alt="Artist impression"]')).toHaveCSS('opacity', '1'); await player.screenshot({ path: 'exports/qualification/botanical-islands-mobile-browser.png' });
    expect(external).toEqual([]); expect(errors).toEqual([]);
    await writeFile('exports/qualification/botanical-islands-browser.json', JSON.stringify({ source, openedMs, publicBytes: publicBytes.length, editableBytes: editable.length, telemetry, errors, external, mobile: '390x844 browser viewport only, per user direction; physical mobile qualification deferred' }, null, 2));
  } finally { await context.close(); await new Promise<void>(r => server.close(() => r())); }
  const reopened = await browser.newContext(), restored = await reopened.newPage();
  try { await restored.goto('/'); await restored.waitForFunction(() => (window as any).__cyrusStudio?.ready); await restored.getByLabel('Open project archive', { exact: true }).setInputFiles({ name: 'Botanical-Islands.zip', mimeType: 'application/zip', buffer: editable }); await expect(restored.getByRole('textbox', { name: 'Project title' })).toHaveValue('Botanical Islands — presentation MVP', { timeout: 60000 }); expect(await restored.evaluate(() => (window as any).__cyrusStudio.controller.project.id)).toBe(source.projectId); } finally { await reopened.close(); }
});
