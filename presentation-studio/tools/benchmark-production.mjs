import { chromium } from '@playwright/test';
import { createServer } from 'node:http';
import { readFile, writeFile, mkdir } from 'node:fs/promises';
import { resolve, extname, relative } from 'node:path';
import { createHash } from 'node:crypto';
import { gzipSync } from 'node:zlib';
import { unpackSync } from '../src/storage/archive.ts';

const seconds = Number(process.argv[2] ?? 600);
if (!Number.isFinite(seconds) || seconds < 10 || seconds > 3600) throw new Error('Choose a duration between 10 and 3600 seconds');
const studioRoot = resolve('dist/studio'), resultRoot = resolve('exports/qualification'); await mkdir(resultRoot, { recursive: true });
const mime = { '.html': 'text/html', '.js': 'text/javascript', '.css': 'text/css', '.json': 'application/json', '.png': 'image/png', '.glb': 'model/gltf-binary' };
let files = new Map();
const server = createServer(async (req, res) => {
  try {
    let path = decodeURIComponent(new URL(req.url, 'http://local').pathname), bytes;
    if (path.startsWith('/studio/')) {
      path = path.slice(8) || 'index.html'; const target = resolve(studioRoot, path);
      if (relative(studioRoot, target).startsWith('..')) throw new Error('Invalid path'); bytes = await readFile(target);
    } else if (path.startsWith('/presentations/courtyard/')) { path = path.slice(25) || 'index.html'; bytes = files.get(path); }
    if (!bytes) { res.writeHead(404).end(); return; }
    res.setHeader('Content-Type', mime[extname(path)] ?? 'application/octet-stream'); res.setHeader('Cache-Control', 'no-store');
    if (/\.(js|css|html|json)$/.test(path) && req.headers['accept-encoding']?.includes('gzip')) { bytes = gzipSync(bytes); res.setHeader('Content-Encoding', 'gzip'); }
    res.end(bytes);
  } catch { res.writeHead(404).end(); }
});
await new Promise(r => server.listen(0, '127.0.0.1', r)); const origin = `http://127.0.0.1:${server.address().port}`;
const browser = await chromium.launch({ headless: true });
const errors = [], external = [];
try {
  const editor = await browser.newContext({ viewport: { width: 1440, height: 900 } }), page = await editor.newPage();
  page.on('pageerror', e => errors.push(e.message)); await page.goto(`${origin}/studio/`); await page.waitForFunction(() => window.__cyrusStudio?.ready);
  const source = await page.evaluate(() => { const c = window.__cyrusStudio.controller, gl = c.host.renderer.getContext(), ext = gl.getExtension('WEBGL_debug_renderer_info'); return { gpu: ext ? gl.getParameter(ext.UNMASKED_RENDERER_WEBGL) : gl.getParameter(gl.RENDERER), assets: c.project.assets.map(a => ({ hash: a.hash, bytes: a.bytes, triangles: a.triangles, gpuBytes: a.gpuBytes, instanceBytes: a.instanceBytes, nodes: a.nodes.length })), userAgent: navigator.userAgent }; });
  const projectDownload = page.waitForEvent('download'); await page.getByTestId('project-menu').click(); await page.getByTestId('save-project').click();
  const projectZip = await readFile(await (await projectDownload).path()); await writeFile(resolve(resultRoot, 'courtyard-project.cyrus-presentation.zip'), projectZip);
  const download = page.waitForEvent('download'); await page.getByTestId('output-menu').click(); await page.getByTestId('export-website').click();
  const zip = await readFile(await (await download).path()); files = unpackSync(zip);
  const archivePath = resolve(resultRoot, 'courtyard-presentation.zip'); await writeFile(archivePath, zip);
  await page.screenshot({ path: resolve(resultRoot, 'studio-production.png') }); await editor.close();
  const context = await browser.newContext({ viewport: { width: 1366, height: 768 }, deviceScaleFactor: 1.5 }), player = await context.newPage();
  player.on('pageerror', e => errors.push(e.message)); player.on('request', r => { if (!r.url().startsWith(origin) && !r.url().startsWith('blob:')) external.push(r.url()); });
  const cdp = await context.newCDPSession(player); await cdp.send('Network.enable'); await cdp.send('Network.setCacheDisabled', { cacheDisabled: true });
  await cdp.send('Network.emulateNetworkConditions', { offline: false, latency: 80, downloadThroughput: 10_000_000 / 8, uploadThroughput: 10_000_000 / 8 });
  let transferred = 0; cdp.on('Network.loadingFinished', e => { transferred += e.encodedDataLength; });
  const began = performance.now(); await player.goto(`${origin}/presentations/courtyard/`);
  await player.waitForFunction(() => window.__cyrusPlayer?.openingReady && [...document.querySelectorAll('img')].some(i => i.alt === 'Calibrated landscape plan' && i.complete && i.naturalWidth > 0));
  const openingMs = performance.now() - began, openingTransferBytes = transferred;
  await player.waitForFunction(() => window.__cyrusPlayer?.ready); const complete3DMs = performance.now() - began;
  await cdp.send('Network.emulateNetworkConditions', { offline: false, latency: 0, downloadThroughput: -1, uploadThroughput: -1 });
  const heapStart = await cdp.send('Runtime.getHeapUsage');
  const result = await player.evaluate(async seconds => {
    const start = performance.now(), initial = { ...window.__cyrusPlayer.stats }, intervals = [], cpu = [], gpu = [], samples = [];
    const project = window.__cyrusPlayer.project;
    const duration = project.opening + project.revealDuration + project.stops.reduce((n, s) => n + s.hold, 0) + project.segments.reduce((n, s) => n + s.duration, 0);
    let last = start, lastSample = start, renders = initial.renders, maxEstimate = initial.gpuBytes;
    return new Promise(resolve => {
      const frame = now => {
        const publicPlayer = window.__cyrusPlayer, stats = publicPlayer.stats;
        if (stats.renders !== renders) { intervals.push(now - last); cpu.push(stats.cpuMs); if (stats.gpuMs !== null) gpu.push(stats.gpuMs); renders = stats.renders; last = now; }
        maxEstimate = Math.max(maxEstimate, stats.gpuBytes);
        if (now - lastSample >= 30000) { samples.push({ seconds: (now - start) / 1000, stats: { ...stats }, heap: performance.memory?.usedJSHeapSize ?? null }); lastSample = now; }
        if (now - start >= seconds * 1000) { resolve({ elapsedSeconds: (now - start) / 1000, initial, final: { ...stats }, maxEstimatedGpuBytes: maxEstimate, intervals, cpu, gpu, samples, viewport: [innerWidth, innerHeight], dpr: devicePixelRatio }); return; }
        publicPlayer.setTime(((now - start) / 1000) % Math.max(duration, 1)); requestAnimationFrame(frame);
      }; requestAnimationFrame(frame);
    });
  }, seconds);
  const heapEnd = await cdp.send('Runtime.getHeapUsage');
  await player.screenshot({ path: resolve(resultRoot, 'player-production.png') });
  const percentile = (values, p) => { if (!values.length) return null; const sorted = [...values].sort((a, b) => a - b); return sorted[Math.min(sorted.length - 1, Math.floor(sorted.length * p))]; };
  const summary = values => ({ samples: values.length, p50: percentile(values, .5), p95: percentile(values, .95), p99: percentile(values, .99), max: values.length ? Math.max(...values) : null });
  const report = { date: new Date().toISOString(), platform: process.platform, node: process.version, browser: browser.version(), mode: 'headless local Chromium; physical-device qualification pending', archivePath, archiveSha256: createHash('sha256').update(zip).digest('hex'), archiveBytes: zip.length, editableArchiveSha256: createHash('sha256').update(projectZip).digest('hex'), source, network: { bandwidthMbps: 10, latencyMs: 80, coldCache: true, gzipText: true, openingMs, openingTransferBytes, complete3DMs, transferBytes: transferred }, elapsedSeconds: result.elapsedSeconds, viewport: result.viewport, dpr: result.dpr, rafObservedRenderIntervalMs: summary(result.intervals), cpuSubmitMs: summary(result.cpu), gpuQueryMs: summary(result.gpu), maxEstimatedGpuBytes: result.maxEstimatedGpuBytes, heapStart, heapEnd, initial: result.initial, final: result.final, samples: result.samples, errors, external, limits: ['RAF observations do not measure presented FPS.', 'JavaScript heap excludes native decoder, image, driver and GPU memory.', 'Estimated GPU accounting is not actual VRAM.', 'A desktop headless run does not qualify phones or establish thermal performance on a physical target device.'] };
  await writeFile(resolve(resultRoot, 'production-benchmark.json'), JSON.stringify(report, null, 2));
  console.log(JSON.stringify({ archiveSha256: report.archiveSha256, elapsedSeconds: report.elapsedSeconds, gpu: source.gpu, network: report.network, intervals: report.rafObservedRenderIntervalMs, cpu: report.cpuSubmitMs, gpuTiming: report.gpuQueryMs, errors, output: resolve(resultRoot, 'production-benchmark.json') }, null, 2));
  if (errors.length || external.length || result.final.rebuilds !== result.initial.rebuilds || result.final.uploads !== result.initial.uploads) process.exitCode = 1;
  await context.close();
} finally { await browser.close(); await new Promise(r => server.close(r)); }
