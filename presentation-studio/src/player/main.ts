import './style.css';
import { loadCameraClips } from '../presentation/camera-clip';
import { manifestSchema, imageMime, type Manifest } from '../compiler/compile';
import { sha256 } from '../core/hash';
import { validateProject, type Files } from '../core/model';
import { Evaluator, duration, stopTime } from '../presentation/evaluate';
import { authoredVisibility } from '../presentation/timeline';
import { RenderHost } from '../render/host';
import { PresentationOverlay } from '../render/overlay';

const root = document.querySelector<HTMLElement>('#app')!;
root.innerHTML = `<main class="presentation" data-testid="player"><div class="landscape" data-testid="player-viewport"></div><header class="masthead"><a class="wordmark" href="#">CYRUS <span>PRESENTATION</span></a><div class="title"></div><span class="quality"></span></header><div class="chapter"><span class="chapter-kicker">A PLACE IN SEQUENCE</span><h1></h1><p class="chapter-note">Scroll to explore</p></div><aside class="layer-panel" aria-label="Presentation layers"><button class="layer-toggle" aria-expanded="false">Layers <span aria-hidden="true">＋</span></button><div class="layer-options" hidden></div></aside><nav class="transport" aria-label="Presentation controls"><button aria-label="Previous stop">←</button><button aria-label="Play presentation">Play</button><button aria-label="Next stop">→</button><div class="stops"></div><button class="motion" aria-pressed="false">Reduced motion</button><button class="restart">Restart</button></nav><div class="progress"><i></i></div><p class="load-status" role="status">Loading the scene…</p></main><div class="scroll-length" aria-hidden="true"></div>`;
const mount = root.querySelector<HTMLElement>('.landscape')!, status = root.querySelector<HTMLElement>('.load-status')!;
let manifest: Manifest, evaluator: Evaluator, host: RenderHost, overlay: PresentationOverlay;
let time = 0, playing = false, raf = 0, last = 0, selected = 0, ready3D = false, fallback = false, choices: Record<string, boolean> = {}, stopButtons: HTMLButtonElement[] = [], reduced = matchMedia('(prefers-reduced-motion: reduce)').matches;
const resourceCache = new Map<string, Promise<{ bytes: Uint8Array; mime: string }>>();
let rawFiles: Files | undefined;
const base = new URL('./', document.baseURI);
const trustedOrigin = new URL(document.baseURI).origin;
async function resource(hash: string) {
  if (!resourceCache.has(hash)) resourceCache.set(hash, (async () => {
    const spec = manifest.resources[hash]; if (!spec || !/^assets\/[a-f0-9]{64}\.(glb|png|jpeg|webp|json)$/.test(spec.path)) throw new Error('Invalid presentation resource path');
    const bytes = rawFiles?.get(spec.path) ?? new Uint8Array(await (await fetch(new URL(spec.path, base))).arrayBuffer());
    if (bytes.length !== spec.bytes || await sha256(bytes) !== hash) throw new Error(`Corrupt or missing resource: ${hash.slice(0, 12)}`); return { bytes, mime: spec.mime };
  })());
  const result = resourceCache.get(hash)!;
  if (manifest.resources[hash]?.mime.startsWith('image/')) void result.then(() => resourceCache.delete(hash), () => resourceCache.delete(hash));
  return result;
}
function syncScroll() { if (!reduced) scrollTo({ top: time / Math.max(0.001, duration(manifest.project)) * Math.max(0, document.documentElement.scrollHeight - innerHeight), behavior: 'auto' }); }
function update() {
  if (!manifest) return;
  const e = evaluator.evaluate(time, innerWidth < innerHeight, choices, reduced); host.setEvaluation(e); overlay.update(manifest.project, e);
  if (fallback && !e.photo) { e.planOpacity = 1; overlay.update(manifest.project, e); }
  root.querySelector<HTMLElement>('.progress i')!.style.width = `${100 * time / Math.max(1, duration(manifest.project))}%`;
  const stop = manifest.project.stops.find(s => s.id === e.stopId); if (stop) selected = manifest.project.stops.indexOf(stop);
  root.querySelector('h1')!.textContent = e.phase === 'plan' || e.phase === 'reveal' ? manifest.project.title : stop?.name ?? 'Explore the scene';
  root.querySelector<HTMLElement>('.chapter')!.classList.toggle('chapter--scene', !fallback && e.phase !== 'plan' && e.phase !== 'reveal');
  root.querySelector<HTMLElement>('.chapter')!.style.opacity = e.photo ? '0' : '1';
  root.querySelector<HTMLElement>('.chapter-note')!.textContent = reduced ? 'Choose a view below' : e.phase === 'travel' ? 'Moving through the scene' : 'Scroll to explore';
  stopButtons.forEach((b, index) => { b.setAttribute('aria-current', String(index === selected)); });
  root.querySelectorAll<HTMLInputElement>('.layer-options input').forEach(input => { const id = input.dataset.layerId!; input.checked = choices[id] ?? authoredVisibility(manifest.project, id, time); });
  (window as any).__cyrusPlayer = { time, evaluation: e, stats: host.stats, project: manifest.project, choices, openingReady: true, ready: ready3D || fallback, setTime: (t: number) => { time = t; update(); }, toggle: (id: string, value: boolean) => { choices[id] = value; update(); } };
}
function pause() { playing = false; cancelAnimationFrame(raf); root.querySelector('[aria-label="Play presentation"]')!.textContent = 'Play'; }
function seek(index: number) { pause(); selected = Math.max(0, Math.min(manifest.project.stops.length - 1, index)); time = stopTime(manifest.project, manifest.project.stops[selected].id); syncScroll(); update(); }
function tick(now: number) { if (!playing) return; time = Math.min(duration(manifest.project), time + Math.max(0, (now - last) / 1000)); last = now; syncScroll(); update(); if (time >= duration(manifest.project)) pause(); else raf = requestAnimationFrame(tick); }
function setMotion(value: boolean) { reduced = value; pause(); root.querySelector('.motion')!.setAttribute('aria-pressed', String(value)); root.querySelector<HTMLElement>('.scroll-length')!.hidden = value; if (value) seek(selected); else { syncScroll(); update(); } }

async function start(input: unknown, files?: Files) {
  manifest = manifestSchema.parse(input); validateProject(manifest.project); rawFiles = files;
  const cameraFiles: Files = new Map();
  for (const hash of new Set(manifest.project.segments.flatMap(s => s.cameraClip ? [s.cameraClip.hash] : []))) cameraFiles.set(hash, (await resource(hash)).bytes);
  evaluator = new Evaluator(manifest.project, await loadCameraClips(manifest.project, cameraFiles));
  document.title = manifest.project.title; root.querySelector('.title')!.textContent = manifest.project.title; root.querySelector('.quality')!.textContent = manifest.project.profile === 'mobile' ? 'MOBILE' : 'BALANCED';
  host = new RenderHost(mount, false, message => { status.textContent = message; status.hidden = false; }); fallback = !host.renderer;
  host.onFrame = () => { if (host.stats.rebuilds > 0) { ready3D = true; if ((window as any).__cyrusPlayer) (window as any).__cyrusPlayer.ready = true; status.hidden = true; } };
  overlay = new PresentationOverlay(mount, resource); host.mode('playback');
  update();
  const options = root.querySelector<HTMLElement>('.layer-options')!;
  for (const layer of manifest.project.layers.filter(l => l.viewerToggle && l.included)) {
    const label = document.createElement('label'), input = document.createElement('input'), text = document.createElement('span'); input.type = 'checkbox'; input.dataset.layerId = layer.id; input.checked = authoredVisibility(manifest.project, layer.id, time); input.disabled = !host.renderer; input.setAttribute('aria-label', layer.name); input.onchange = () => { choices[layer.id] = input.checked; update(); }; text.textContent = layer.name; label.append(input, text); options.append(label);
  }
  const reset = document.createElement('button'); reset.textContent = 'Reset layers'; reset.onclick = () => { choices = {}; options.querySelectorAll('input').forEach((i, n) => { i.checked = manifest.project.layers.filter(l => l.viewerToggle && l.included)[n].defaultVisible; }); update(); }; options.append(reset);
  const layersButton = root.querySelector<HTMLButtonElement>('.layer-toggle')!; layersButton.onclick = () => { options.hidden = !options.hidden; layersButton.setAttribute('aria-expanded', String(!options.hidden)); };
  stopButtons = manifest.project.stops.map((s, index) => { const button = document.createElement('button'); button.textContent = String(index + 1).padStart(2, '0'); button.title = s.name; button.setAttribute('aria-label', `Go to ${s.name}`); button.onclick = () => seek(index); root.querySelector('.stops')!.append(button); return button; });
  const nav = root.querySelectorAll<HTMLButtonElement>('.transport > button'); nav[0].onclick = () => seek(selected - 1); nav[2].onclick = () => seek(selected + 1);
  nav[1].onclick = () => { if (playing) pause(); else if (reduced) seek(selected + 1); else { if (time >= duration(manifest.project)) time = 0; playing = true; last = performance.now(); nav[1].textContent = 'Pause'; raf = requestAnimationFrame(tick); } };
  root.querySelector<HTMLButtonElement>('.motion')!.onclick = () => setMotion(!reduced);
  root.querySelector<HTMLButtonElement>('.restart')!.onclick = () => { pause(); time = 0; selected = 0; scrollTo(0, 0); update(); };
  addEventListener('scroll', () => { if (reduced || playing) return; time = Math.max(0, scrollY / Math.max(1, document.documentElement.scrollHeight - innerHeight)) * duration(manifest.project); update(); }, { passive: true });
  addEventListener('wheel', () => { if (playing) pause(); }, { passive: true }); addEventListener('touchstart', () => { if (playing) pause(); }, { passive: true });
  addEventListener('resize', update); addEventListener('keydown', e => { if ((e.target as HTMLElement).matches('input,button,a')) return; if (e.key === 'ArrowRight' || e.key === 'ArrowDown') { e.preventDefault(); seek(selected + 1); } else if (e.key === 'ArrowLeft' || e.key === 'ArrowUp') { e.preventDefault(); seek(selected - 1); } else if (e.code === 'Space') { e.preventDefault(); nav[1].click(); } });
  document.addEventListener('visibilitychange', () => { if (document.hidden) pause(); }); matchMedia('(prefers-reduced-motion: reduce)').addEventListener('change', e => setMotion(e.matches));
  setMotion(reduced);
  if (host.renderer) {
    const blobs: Files = new Map(); let index = 0;
    for (const asset of manifest.project.assets) { status.textContent = `Loading 3D assets · ${++index}/${manifest.project.assets.length}`; blobs.set(asset.hash, (await resource(asset.hash)).bytes); }
    host.publish(await host.prepare(manifest.project, blobs)); update(); status.hidden = true;
  } else { status.textContent = 'This device cannot display WebGL2. Showing the plan; 3D layer controls are unavailable.'; }
  addEventListener('pagehide', () => { pause(); overlay.dispose(); host.dispose(); }, { once: true });
  if (rawFiles) parent.postMessage({ type: 'cyrus-loaded', token: document.querySelector<HTMLMetaElement>('meta[name="cyrus-preview-token"]')?.content }, trustedOrigin);
}
const previewToken = document.querySelector<HTMLMetaElement>('meta[name="cyrus-preview-token"]')?.content;
if (previewToken) {
  const receive = (event: MessageEvent) => {
    if (event.source !== parent || event.origin !== trustedOrigin || event.data?.type !== 'cyrus-preview' || event.data.token !== previewToken || !Array.isArray(event.data.files)) return;
    removeEventListener('message', receive); const files: Files = new Map(event.data.files);
    const bytes = files.get('manifest.json'); if (!bytes) return; start(JSON.parse(new TextDecoder().decode(bytes)), files).catch(fail);
  };
  addEventListener('message', receive); parent.postMessage({ type: 'cyrus-ready', token: previewToken }, trustedOrigin);
} else fetch(new URL('manifest.json', base)).then(r => { if (!r.ok) throw new Error('No compiled presentation found. Export a website from the studio first.'); return r.json(); }).then(data => start(data)).catch(fail);
function fail(error: unknown) {
  const message = error instanceof Error ? error.message : String(error);
  if (manifest && host && overlay) {
    fallback = true; pause(); host.mode('preview'); root.querySelectorAll<HTMLInputElement>('.layer-options input').forEach(input => { input.disabled = true; }); update();
    status.textContent = `${message}. 3D is unavailable; plan and available artistic views remain accessible.`;
  } else status.textContent = message;
  status.hidden = false; status.setAttribute('role', 'alert');
}
