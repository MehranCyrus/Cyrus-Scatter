import { menuAction } from './ui-actions';
import { test, expect, type Page } from '@playwright/test';
import { readFile } from 'node:fs/promises';
import { createHash } from 'node:crypto';
import { unzipSync, zipSync } from 'fflate';
async function ready(page: Page) { await page.goto('/'); await page.waitForFunction(() => (window as any).__cyrusStudio?.ready); }
test.beforeEach(async ({ page }) => { await ready(page); });
test('failed publication restores the previous scene and project, then a successor succeeds', async ({ page }) => {
  const result = await page.evaluate(async () => {
    const c = (window as any).__cyrusStudio.controller, old = c.project, stats = { ...c.host.stats }, group = c.host.active.group, sync = c.host.syncProject.bind(c.host);
    let fail = true; c.host.syncProject = (...args: any[]) => { if (fail) { fail = false; throw new Error('Injected publication failure'); } return sync(...args); };
    let error = ''; try { await c.act('newProject'); } catch (e) { error = String(e); }
    const retained = c.project === old && c.host.active.group === group && c.host.scene.children.includes(group), rebuilds = c.host.stats.rebuilds;
    c.host.syncProject = sync; await c.act('newProject'); return { error, retained, rebuilds, oldRebuilds: stats.rebuilds, recovered: c.project.assets.length === 0 };
  });
  expect(result.error).toContain('Injected'); expect(result.retained).toBe(true); expect(result.rebuilds).toBe(result.oldRebuilds); expect(result.recovered).toBe(true);
});
test('stale asynchronous scene preparation cannot replace a more recent edit', async ({ page }) => {
  const result = await page.evaluate(async () => {
    const c = (window as any).__cyrusStudio.controller, prepare = c.host.prepare.bind(c.host), old = c.project.id;
    let release!: () => void, started!: () => void; const waiting = new Promise<void>(r => { started = r; });
    c.host.prepare = async (...args: any[]) => { const prepared = await prepare(...args); started(); await new Promise<void>(r => { release = r; }); return prepared; };
    const job = c.act('newProject').catch((e: unknown) => String(e)); await waiting; await c.act('title', 'Newer authored title'); release(); const error = await job; c.host.prepare = prepare;
    return { error, sameProject: c.project.id === old, title: c.project.title, pending: c.pending };
  });
  expect(result.error).toContain('stale result discarded'); expect(result.sameProject).toBe(true); expect(result.title).toBe('Newer authored title'); expect(result.pending).toBe(false);
});
test('cancelling archive work retains the original complete scene and responds promptly', async ({ page }) => {
  const result = await page.evaluate(async () => {
    const c = (window as any).__cyrusStudio.controller, old = c.project.id, started = performance.now();
    const saving = c.act('saveProject').catch((e: unknown) => String(e)); await c.act('cancelJob'); const error = await saving;
    return { elapsed: performance.now() - started, error, retained: c.project.id === old, pending: c.pending };
  });
  expect(result.error).toContain('AbortError'); expect(result.elapsed).toBeLessThan(500); expect(result.retained).toBe(true); expect(result.pending).toBe(false);
});
test('graphics context restores at the same authored time with layer visibility preserved', async ({ page }) => {
  const available = await page.evaluate(() => { const c = (window as any).__cyrusStudio.controller; return !!c.host.renderer?.getContext().getExtension('WEBGL_lose_context'); });
  test.skip(!available, 'The current graphics implementation has no context-loss test extension');
  await page.evaluate(async () => { const c = (window as any).__cyrusStudio.controller; await c.act('time', 21); const gl = c.host.renderer.getContext(), ext = gl.getExtension('WEBGL_lose_context'); (window as any).__restoreGraphics = () => ext.restoreContext(); ext.loseContext(); });
  await page.waitForFunction(() => (window as any).__cyrusStudio.controller.host.lost); await page.evaluate(() => (window as any).__restoreGraphics());
  await page.waitForFunction(() => !(window as any).__cyrusStudio.controller.host.lost); expect(await page.evaluate(() => (window as any).__cyrusStudio.controller.time)).toBe(21); await expect(page.locator('canvas')).toBeVisible();
});
test('autosave failure keeps the last committed record and portable saving remains available', async ({ page }) => {
  await page.evaluate(async () => { const c = (window as any).__cyrusStudio.controller; await c.store.save(c.project, c.blobs); c.store.save = async () => { throw new DOMException('Injected quota failure', 'QuotaExceededError'); }; await c.act('title', 'Pending quota failure'); });
  await expect(page.getByText('Autosave failed · save a portable project', { exact: true })).toBeVisible();
  const savedTitle = await page.evaluate(async () => (await (window as any).__cyrusStudio.controller.store.load()).project.title); expect(savedTitle).toBe('The courtyard garden');
  const download = page.waitForEvent('download'); await menuAction(page, 'project-menu', 'save-project'); expect((await download).suggestedFilename()).toBe('project.cyrus-presentation.zip');
});
test('a path-handle gesture captures its owner and commits one undo record across selection changes', async ({ page }) => {
  const result = await page.evaluate(async () => {
    const c = (window as any).__cyrusStudio.controller, segment = c.project.segments[0], original = [...segment.control1];
    await c.act('navigationMode', 'orbit'); await c.act('selectStop', segment.from); const handle = c.navigation.handles.find((h: any) => h.userData.owner === segment.id && h.userData.field === 'control1');
    c.navigation.gizmo.attach(handle); c.navigation.gizmo.dispatchEvent({ type: 'mouseDown' }); handle.position.x += 2;
    await c.act('selectStop', c.project.stops[2].id); c.navigation.gizmo.dispatchEvent({ type: 'mouseUp' });
    const updated = [...c.project.segments[0].control1], revision = c.project.revision; await c.act('undo');
    return { original, updated, restored: c.project.segments[0].control1, revision };
  });
  expect(result.updated[0]).toBeCloseTo(result.original[0] + 2); expect(result.restored).toEqual(result.original); expect(result.revision).toBe(1);
});

test('an archive image with valid content hash but invalid pixels cannot replace the active project', async ({ page }) => {
  const before = await page.evaluate(() => JSON.stringify((window as any).__cyrusStudio.controller.project));
  const download = page.waitForEvent('download'); await menuAction(page, 'project-menu', 'save-project');
  const files = unzipSync(await readFile((await (await download).path())!)), project = JSON.parse(new TextDecoder().decode(files['project.json']));
  const bad = Buffer.alloc(32); bad.writeUInt32BE(0x89504e47, 0); bad.writeUInt32BE(128, 16); bad.writeUInt32BE(128, 20);
  const hash = createHash('sha256').update(bad).digest('hex'); delete files[`blobs/${project.plan.hash}`]; project.plan.hash = hash;
  files[`blobs/${hash}`] = bad; files['project.json'] = new TextEncoder().encode(JSON.stringify(project));
  await page.getByLabel('Open project archive', { exact: true }).setInputFiles({ name: 'invalid-pixels.zip', mimeType: 'application/zip', buffer: Buffer.from(zipSync(files)) });
  await expect(page.getByTestId('error')).toBeVisible(); expect(await page.evaluate(() => JSON.stringify((window as any).__cyrusStudio.controller.project))).toBe(before);
});
