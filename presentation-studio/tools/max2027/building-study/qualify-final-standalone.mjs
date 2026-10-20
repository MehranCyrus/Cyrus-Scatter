import { chromium } from '@playwright/test';
import { createServer } from 'node:http';
import { readFile, writeFile, mkdir } from 'node:fs/promises';
import { resolve, extname } from 'node:path';
import { createHash } from 'node:crypto';
import { gzipSync } from 'node:zlib';
import { deepStrictEqual, strict as assert } from 'node:assert';
import { unpackSync } from '../../../src/storage/archive.ts';
import { loadCameraClips } from '../../../src/presentation/camera-clip.ts';
import { Evaluator, duration } from '../../../src/presentation/evaluate.ts';
import { contentFingerprint } from '../../../src/core/hash.ts';

const seconds = Number(process.argv[2] ?? 180), run = process.argv[3] ?? 'v1';
if (!Number.isFinite(seconds) || seconds < 120 || seconds > 1800 || !/^v\d+$/.test(run)) throw Error('Use 120–1800 seconds and a fresh vN run.');
const archiveName=process.argv[4]??'BAILEY-presentation.zip';if(!/^BAILEY-presentation(?:-v\d+)?\.zip$/.test(archiveName))throw Error('Invalid local archive name');
const folder = resolve('exports/building-20261016/final-presentation-v1'), out = `${folder}/standalone-${run}`; await mkdir(out);
const zip = await readFile(`${folder}/${archiveName}`), files = unpackSync(zip), manifest = JSON.parse(new TextDecoder().decode(files.get('manifest.json')));
const cameraFiles = new Map();
for (const segment of manifest.project.segments) if (segment.cameraClip) cameraFiles.set(segment.cameraClip.hash, files.get(manifest.resources[segment.cameraClip.hash].path));
const evaluator = new Evaluator(manifest.project, await loadCameraClips(manifest.project, cameraFiles)), total = duration(manifest.project);
assert.equal(total, 38);
const root = '/presentations/bailey/';
const mime = { '.html': 'text/html', '.js': 'text/javascript', '.css': 'text/css', '.json': 'application/json', '.glb': 'model/gltf-binary' };
const server = createServer((req, res) => {
  const url = new URL(req.url, 'http://local'), path = url.pathname.startsWith(root) ? url.pathname.slice(root.length) || 'index.html' : '', original = files.get(path);
  if (!original) { res.writeHead(404).end(); return; }
  let bytes = original; res.setHeader('Content-Type', mime[extname(path)] ?? 'application/octet-stream'); res.setHeader('Cache-Control', 'no-store');
  if (/\.(html|js|css|json)$/.test(path) && req.headers['accept-encoding']?.includes('gzip')) { bytes = gzipSync(bytes); res.setHeader('Content-Encoding', 'gzip'); }
  res.end(bytes);
});
await new Promise(r => server.listen(0, '127.0.0.1', r)); const origin = `http://127.0.0.1:${server.address().port}`;
const browser = await chromium.launch({ headless: true, channel: 'chromium' }), errors = [], external = [], failures = [];
try {
  const context = await browser.newContext({ viewport: { width: 1366, height: 768 }, deviceScaleFactor: 1.5 });
  await context.addInitScript(() => {
    const counters = {}; window.__glResources = counters;
    for (const kind of ['Buffer', 'Texture', 'Framebuffer', 'Renderbuffer', 'Program', 'Shader', 'VertexArray']) {
      const p = WebGL2RenderingContext.prototype, create = p[`create${kind}`], remove = p[`delete${kind}`], live = new Set();
      counters[kind] = { created: 0, deleted: 0, live: 0 };
      p[`create${kind}`] = function (...args) { const item = create.apply(this, args); if (item) { live.add(item); counters[kind].created++; counters[kind].live = live.size; } return item; };
      p[`delete${kind}`] = function (item) { if (live.delete(item)) { counters[kind].deleted++; counters[kind].live = live.size; } return remove.call(this, item); };
    }
  });
  const page = await context.newPage(); page.on('pageerror', e => errors.push(e.message));
  page.on('request', r => { if (!r.url().startsWith(origin) && !r.url().startsWith('blob:') && !r.url().startsWith('data:')) external.push(r.url()); });
  page.on('requestfailed', r => failures.push({ url: r.url(), failure: r.failure() }));
  const cdp = await context.newCDPSession(page); await cdp.send('Network.enable'); await cdp.send('Network.setCacheDisabled', { cacheDisabled: true });
  await cdp.send('Network.emulateNetworkConditions', { offline: false, latency: 80, downloadThroughput: 10_000_000 / 8, uploadThroughput: 10_000_000 / 8 });
  let transferred = 0; cdp.on('Network.loadingFinished', e => { transferred += e.encodedDataLength; });
  const began = performance.now(); await page.goto(`${origin}${root}`, { waitUntil: 'domcontentloaded', timeout: 120000 });
  await page.waitForFunction(() => window.__cyrusPlayer?.openingReady, null, { timeout: 120000 }); const openingMs = performance.now() - began;
  await page.waitForFunction(() => window.__cyrusPlayer?.ready && window.__cyrusPlayer.stats.rebuilds === 1, null, { timeout: 120000 }); const ready3DMs = performance.now() - began;
  await cdp.send('Network.emulateNetworkConditions', { offline: false, latency: 0, downloadThroughput: -1, uploadThroughput: -1 });
  const model = await page.evaluate(() => ({ project: window.__cyrusPlayer.project, ua: navigator.userAgent, viewport: [innerWidth, innerHeight], dpr: devicePixelRatio, gpu: (() => { const gl = document.querySelector('canvas').getContext('webgl2'), ext = gl.getExtension('WEBGL_debug_renderer_info'); return ext ? gl.getParameter(ext.UNMASKED_RENDERER_WEBGL) : gl.getParameter(gl.RENDERER); })() }));
  assert.equal(contentFingerprint(model.project), contentFingerprint(manifest.project));
  const seeking = [];
  for (const time of [38, 29, 16, 7, 2, 0, 9.123, 35.777, 17.531, 24.275]) {
    const actual = await page.evaluate(t => { window.__cyrusPlayer.setTime(t); const e = window.__cyrusPlayer.evaluation; return { position: e.position, quaternion: e.quaternion, fov: e.fov, aspect: e.aspect }; }, time), expected = evaluator.evaluate(time);
    for (const field of ['position', 'quaternion', 'fov', 'aspect']) deepStrictEqual(actual[field], expected[field]); seeking.push({ time, ...actual });
  }
  await page.evaluate(() => window.__cyrusPlayer.setTime(16)); await page.getByRole('button', { name: 'Layers', exact: true }).click();
  const toggles = manifest.project.layers.filter(l => l.viewerToggle && l.included); assert.equal(toggles.length, 4);
  const beforeLayers = await page.evaluate(() => ({ ...window.__cyrusPlayer.stats }));
  for (const layer of toggles) {
    const checkbox = page.getByRole('checkbox', { name: layer.name, exact: true }); await checkbox.setChecked(!layer.defaultVisible);
    assert.equal(await page.evaluate(id => window.__cyrusPlayer.evaluation.visible[id], layer.id), !layer.defaultVisible);
    await page.getByRole('button', { name: 'Reset layers', exact: true }).click();
    assert.equal(await page.evaluate(id => window.__cyrusPlayer.evaluation.visible[id], layer.id), layer.defaultVisible);
  }
  await page.getByRole('button', { name: 'Layers', exact: true }).click();
  await page.getByRole('button', { name: 'Next stop', exact: true }).click(); assert.equal(await page.evaluate(() => window.__cyrusPlayer.time), 38);
  await page.getByRole('button', { name: 'Previous stop', exact: true }).click(); assert.equal(await page.evaluate(() => window.__cyrusPlayer.time), 2);
  await page.getByRole('button', { name: 'Restart', exact: true }).click(); assert.equal(await page.evaluate(() => window.__cyrusPlayer.time), 0);
  await page.getByRole('button', { name: 'Play presentation', exact: true }).click(); await page.waitForFunction(() => window.__cyrusPlayer.time > .3);
  await page.getByRole('button', { name: 'Play presentation', exact: true }).click();
  // Let the last programmatic native-scroll event settle at its pixel resolution.
  await page.evaluate(async () => { await new Promise(requestAnimationFrame); await new Promise(requestAnimationFrame); });
  const paused = await page.evaluate(() => window.__cyrusPlayer.time);
  await page.waitForTimeout(200); assert.equal(await page.evaluate(() => window.__cyrusPlayer.time), paused);
  await page.getByRole('button', { name: 'Reduced motion', exact: true }).click(); assert.equal(await page.getByRole('button', { name: 'Reduced motion', exact: true }).getAttribute('aria-pressed'), 'true');
  await page.getByRole('button', { name: 'Go to The final composition', exact: true }).click(); assert.equal(await page.evaluate(() => window.__cyrusPlayer.time), 38);
  await page.getByRole('button', { name: 'Reduced motion', exact: true }).click();
  await page.setViewportSize({ width: 390, height: 844 }); await page.evaluate(() => window.__cyrusPlayer.setTime(16));
  await page.screenshot({ path: `${out}/portrait-browser.png` });
  const portrait = await page.evaluate(() => ({ ...window.__cyrusPlayer.evaluation })); assert.equal(portrait.aspect, evaluator.evaluate(16, true).aspect);
  await page.setViewportSize({ width: 1366, height: 768 });
  const afterLayers = await page.evaluate(() => ({ ...window.__cyrusPlayer.stats })); assert.equal(afterLayers.rebuilds, beforeLayers.rebuilds);
  // Warm every camera view and both visibility states before measuring steady playback.
  await page.evaluate(async () => { for (let i = 0; i <= 120; i++) { window.__cyrusPlayer.setTime(i * 38 / 120); await new Promise(requestAnimationFrame); await new Promise(requestAnimationFrame); } });
  const heapStart = await cdp.send('Runtime.getHeapUsage');
  console.log(JSON.stringify({ phase: 'sustained-playback', seconds, gpu: model.gpu, ready3DMs }));
  const steady = await page.evaluate(async ({ seconds, total }) => {
    const initial = { ...window.__cyrusPlayer.stats }, resourcesStart = structuredClone(window.__glResources), intervals = [], cpu = [], gpu = [], samples = [], start = performance.now(); let last = start, sampleAt = start, renders = initial.renders;
    return new Promise(resolve => {
      function frame(now) {
        const stats = window.__cyrusPlayer.stats;
        if (stats.renders !== renders) { intervals.push(now - last); cpu.push(stats.cpuMs); if (stats.gpuMs !== null) gpu.push(stats.gpuMs); last = now; renders = stats.renders; }
        if (now - sampleAt >= 30000) { samples.push({ seconds: (now - start) / 1000, stats: { ...stats }, resources: structuredClone(window.__glResources), heap: performance.memory?.usedJSHeapSize }); sampleAt = now; }
        if (now - start >= seconds * 1000) { resolve({ elapsedSeconds: (now - start) / 1000, initial, final: { ...stats }, resourcesStart, resourcesEnd: structuredClone(window.__glResources), intervals, cpu, gpu, samples }); return; }
        // Alternate complete forward/reverse traversals without rebuilding scene state.
        const cycle = (now - start) / 1000 / total, part = cycle % 1; window.__cyrusPlayer.setTime((Math.floor(cycle) % 2 ? 1 - part : part) * total); requestAnimationFrame(frame);
      } requestAnimationFrame(frame);
    });
  }, { seconds, total });
  const heapEnd = await cdp.send('Runtime.getHeapUsage'); await page.evaluate(() => window.__cyrusPlayer.setTime(7)); await page.screenshot({ path: `${out}/desktop-player.png` });
  const summary = values => { const a = [...values].sort((a, b) => a - b), p = n => a.length ? a[Math.min(a.length - 1, Math.floor(a.length * n))] : null; return { count: a.length, p50: p(.5), p95: p(.95), p99: p(.99), maximum: p(1) }; };
  const report = { date: new Date().toISOString(), archive: `${folder}/${archiveName}`, archiveSha256: createHash('sha256').update(zip).digest('hex'), archiveBytes: zip.length, browser: browser.version(), channel: 'chromium', model, network: { bandwidthMbps: 10, latencyMs: 80, cacheDisabled: true, gzipText: true, openingMs, ready3DMs, transferred }, controls: { reverseRandomSeek: seeking, viewerLayers: toggles.map(l => l.name), playPause: true, stopNavigation: true, restart: true, reducedMotion: true, portraitBrowser: true }, elapsedSeconds: steady.elapsedSeconds, completeTraversals: steady.elapsedSeconds / total, rafObservedRenderIntervalMs: summary(steady.intervals), cpuSubmitMs: summary(steady.cpu), gpuQueryMs: summary(steady.gpu), heapStart, heapEnd, initial: steady.initial, final: steady.final, resourcesStart: steady.resourcesStart, resourcesEnd: steady.resourcesEnd, samples: steady.samples, errors, external, failures, limits: ['RAF observations are not presented FPS.', 'GPU accounting is an estimate, not driver VRAM.', 'JavaScript heap excludes native/image/driver allocations.', 'This RTX desktop and emulated portrait viewport do not qualify mainstream devices or physical phones.'] };
  await writeFile(`${out}/report.json`, JSON.stringify(report, null, 2));
  console.log(JSON.stringify({ report: `${out}/report.json`, intervals: report.rafObservedRenderIntervalMs, cpu: report.cpuSubmitMs, gpu: report.gpuQueryMs, heapStart, heapEnd, errors, external, failures }, null, 2));
  assert.equal(steady.final.rebuilds, steady.initial.rebuilds); assert.equal(steady.final.uploads, steady.initial.uploads); deepStrictEqual(steady.resourcesEnd, steady.resourcesStart);
  assert.equal(errors.length, 0); assert.equal(external.length, 0); assert.equal(failures.length, 0); assert.ok(report.rafObservedRenderIntervalMs.p95 <= 33.4, 'Local desktop frame interval target failed.');
  await context.close();
} catch (error) {
  await writeFile(`${out}/failure.json`, JSON.stringify({ error: String(error), stack: error.stack, errors, external, failures }, null, 2)); throw error;
} finally { await browser.close(); server.closeAllConnections(); await new Promise(r => server.close(r)); }
