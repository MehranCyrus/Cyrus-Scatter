import { Quaternion } from 'three';
import { imageSize, replacementSuggestions, planPoint, LIMITS } from '../assets/glb';
import { inspectInWorker } from '../assets/worker-import';
import { prepareImage } from '../assets/images';
import { createDemo } from '../assets/demo';
import { compile, imageMime } from '../compiler/compile';
import { playerShell, previewHTML } from '../compiler/shell';
import { History } from '../core/history';
import { sha256 } from '../core/hash';
import { emptyProject, identityTransform, reconnect, resolveLayer, uuid, validateProject, type Files, type Project, type Stop, type Asset, type Vec3 } from '../core/model';
import { CAMERA_FILE_LIMIT, cameraReference, parseCameraClip, loadCameraClips, validateCameraBindings, type CameraClip } from '../presentation/camera-clip';
import { Evaluator, duration, photoFingerprint, stalePhoto, stopTime, lookQuaternion } from '../presentation/evaluate';
import { timelineOf, ensureTimeline, syncTimeline, insertCameraKey, moveTimelineKeys, deleteTimelineKeys, captureLayerKey, copyTimelineKeys, pasteTimelineKeys, authoredVisibility, cameraLocked, type TimelineClipboard } from '../presentation/timeline';
import { RenderHost } from '../render/host';
import { PresentationOverlay } from '../render/overlay';
import { archiveWork, projectFiles, readProjectArchive, referencedHashes } from '../storage/archive';
import { LocalStore } from '../storage/local';
import { mountStudio } from './view';
import type { Mode, ViewState, CameraPose } from './contracts';
import { EditorNavigation } from './navigation';
import { FRAME_PRESETS, presetAspect, type FramePreset } from '../render/framing';

function workspaceFrame() {
  try { const p = JSON.parse(localStorage.getItem('cyrus-studio.frame') ?? '{}'); return { preset: FRAME_PRESETS.some(f => f.id === p.preset) ? p.preset as FramePreset : 'free' as FramePreset, safe: typeof p.safe === 'boolean' ? p.safe : true }; }
  catch { return { preset: 'free' as FramePreset, safe: true }; }
}

class Studio {
  history = new History(emptyProject()); blobs: Files = new Map(); clips = new Map<string, CameraClip>(); evaluator = new Evaluator(this.project, this.clips);
  view = mountStudio(document.querySelector<HTMLElement>('#app')!, { act: (name, payload) => { void this.act(name, payload).catch(error => this.fail(error)); } });
  host = new RenderHost(this.view.viewport, true, message => { this.status = message; this.emit(); });
  navigation = new EditorNavigation(this.host, (kind, id, field, value) => { void this.act(kind === 'stop' ? 'updateStop' : 'updateSegment', { id, patch: { [field]: value } }).catch(e => this.fail(e)); }, () => this.clips);
  overlay = new PresentationOverlay(this.view.viewport, async hash => { const bytes = this.blobs.get(hash); if (!bytes) throw new Error('Missing image'); const display = await prepareImage(bytes, this.project.profile); return { bytes: display, mime: imageMime(display) }; });
  store = new LocalStore();
  time = 0; mode: Mode = 'explore'; playing = false; pending = false; status = 'Preparing the studio'; storageStatus = 'Checking local storage'; error: string | null = null;
  selectedLayer: string | null = null; selectedStop: string | null = null; selectedInstance: string | null = null;
  cameraEditingStopId: string | null = null;
  cameraSession: 'new' | 'edit' = 'new';
  replacement: ViewState['replacement'] = null;
  cameraImport: ViewState['cameraImport'] = null;
  private pendingCamera: { bytes: Uint8Array; clip: CameraClip; hash: string } | null = null;
  private timelineClipboard: TimelineClipboard | null = null;
  reducedMotion = matchMedia('(prefers-reduced-motion: reduce)').matches;
  framing: ViewState['framing'] = 'auto';
  private framePreference = workspaceFrame();
  framePreset: FramePreset = this.framePreference.preset;
  safeFrame = this.framePreference.safe;
  private lastFrameEmit = 0;
  private replacementBytes: Uint8Array | null = null;
  private abort: AbortController | null = null; private epoch = 0; private raf = 0; private last = 0; private direction = 1;
  private saveTimer: ReturnType<typeof setTimeout> | undefined;
  private explored: CameraPose | null = null; private previewRevoke: (() => void) | null = null;
  private previewReceive: ((event: MessageEvent) => void) | null = null;
  private viewportObserver: ResizeObserver | null = null;
  get project() { return this.history.current; }
  constructor() {
    // Transport emits once per tick. Orbit-only frames need only occasional statistics, not a full UI update.
    this.host.onFrame = () => { const now = performance.now(); if (!this.playing && now - this.lastFrameEmit >= 250) { this.lastFrameEmit = now; this.emit(); } }; this.host.setFrameAspect(presetAspect(this.framePreset)); this.emit();
    this.viewportObserver = new ResizeObserver(() => { if (this.mode === 'playback' && this.framing === 'auto') this.evaluate(); }); this.viewportObserver.observe(this.view.viewport);
    addEventListener('pagehide', () => { this.pause(); this.abort?.abort(); clearTimeout(this.saveTimer); this.viewportObserver?.disconnect(); if (this.previewReceive) removeEventListener('message', this.previewReceive); this.previewRevoke?.(); this.navigation.dispose(); this.overlay.dispose(); this.host.dispose(); }, { once: true });
    addEventListener('keydown', e => {
      const target = e.target as HTMLElement; if (target.matches('input,textarea,select') || this.replacement || this.cameraImport || this.mode === 'preview') return;
      if ((e.ctrlKey || e.metaKey) && e.key.toLowerCase() === 'z') { e.preventDefault(); void this.act(e.shiftKey ? 'redo' : 'undo').catch(x => this.fail(x)); }
      if (e.code === 'Space' && !target.closest('button,summary,a,[role="button"]')) { e.preventDefault(); void this.act(this.playing ? 'pause' : 'play').catch(x => this.fail(x)); }
    });
    document.addEventListener('visibilitychange', () => { if (document.hidden) this.pause(); });
    (window as any).__cyrusStudio = { controller: this, ready: false };
    void this.initialize();
  }
  private async initialize() {
    try {
      const saved = await this.store.load();
      if (saved) { await this.activate(saved.project, saved.blobs, 'Restored local autosave'); this.storageStatus = 'Restored local autosave'; }
      else { const demo = await createDemo(); await this.activate(demo.project, demo.blobs, 'Sample garden ready · import your landscape to begin'); this.storageStatus = 'Autosave ready'; }
    } catch (error) {
      this.storageStatus = 'Local storage unavailable · save a portable project';
      const demo = await createDemo(); await this.activate(demo.project, demo.blobs, 'Sample garden ready'); this.error = error instanceof Error ? error.message : String(error);
    }
    (window as any).__cyrusStudio.ready = true; this.emit();
  }
  private emit() {
    if (!this.view) return;
    this.view.update({ project: this.project, time: this.time, duration: duration(this.project), mode: this.mode, playing: this.playing, selectedLayer: this.selectedLayer, selectedStop: this.selectedStop, selectedInstance: this.selectedInstance, pending: this.pending, status: this.status, error: this.error, storageStatus: this.storageStatus, canUndo: this.history.canUndo, canRedo: this.history.canRedo, stats: this.host?.stats ?? { renders: 0, rebuilds: 0, uploads: 0, calls: 0, triangles: 0, gpuBytes: 0 }, replacement: this.replacement, cameraImport: this.cameraImport, photoStale: !!this.selectedStop && this.evaluator.photoStale(this.selectedStop), reducedMotion: this.reducedMotion, framing: this.framing, framePreset: this.framePreset, safeFrame: this.safeFrame, effectiveFrameAspect: this.host?.frameAspect ?? null, navigationMode: this.navigation?.navigationMode ?? 'camera', cameraSpeed: this.navigation?.camera.speed ?? 3, cameraFov: this.host?.perspective.fov ?? 45, cameraEditingStopId: this.cameraEditingStopId ?? null, cameraSession: this.cameraSession ?? 'new' });
  }
  private fail(error: unknown) { this.error = error instanceof Error ? error.message : String(error); this.status = error instanceof DOMException && error.name === 'AbortError' ? 'Operation cancelled; previous project retained' : 'Action could not complete; previous valid state retained'; this.emit(); }
  private autosave() {
    this.collectBlobs();
    clearTimeout(this.saveTimer); this.storageStatus = 'Unsaved changes';
    this.saveTimer = setTimeout(() => { const snapshot = this.project; this.storageStatus = 'Saving locally…'; this.emit(); this.store.save(snapshot, this.blobs).then(() => { if (this.project === snapshot) this.storageStatus = 'Saved locally'; this.emit(); }).catch(error => { this.storageStatus = 'Autosave failed · save a portable project'; this.error = String(error); this.emit(); }); }, 700);
  }
  private collectBlobs() {
    const retained = () => new Set(this.history.retained.flatMap(referencedHashes));
    let hashes = retained();
    const bytes = () => [...hashes].reduce((sum, hash) => sum + (this.blobs.get(hash)?.length ?? 0), 0);
    while (bytes() > 512 * 1024 * 1024 && this.history.pruneOldest()) hashes = retained();
    for (const hash of this.blobs.keys()) if (!hashes.has(hash)) { this.blobs.delete(hash); this.clips.delete(hash); }
    if (this.history.pruned) this.status += ` · ${this.history.pruned} oldest history records released within memory budget`;
  }
  private refresh() {
    // Decode only active clips; undo retains immutable bytes rather than unbounded decoded histories.
    const activeClips = new Map<string, CameraClip>();
    for (const segment of this.project.segments) if (segment.cameraClip && !activeClips.has(segment.cameraClip.hash)) {
      const hash = segment.cameraClip.hash, bytes = this.blobs.get(hash); if (!bytes) throw new Error('Missing imported camera animation');
      activeClips.set(hash, this.clips.get(hash) ?? parseCameraClip(bytes));
    }
    this.clips = activeClips;
    this.evaluator = new Evaluator(this.project, this.clips); this.time = Math.min(this.time, duration(this.project));
    if (this.selectedStop && !this.project.stops.some(s => s.id === this.selectedStop)) this.selectedStop = this.project.stops[0]?.id ?? null;
    if (this.cameraEditingStopId && !this.project.stops.some(s => s.id === this.cameraEditingStopId)) { this.cameraEditingStopId = null; this.cameraSession = 'new'; }
    if (!this.project.layers.some(s => s.id === this.selectedLayer)) this.selectedLayer = null;
    if (!this.project.instances.some(s => s.id === this.selectedInstance)) this.selectedInstance = null;
    this.host.syncProject(this.project); this.host.setPlan(this.project.plan, this.project.plan ? this.blobs.get(this.project.plan.hash) : undefined); this.navigation.sync(this.project, this.selectedStop, this.mode); this.evaluate(); this.emit();
  }
  private evaluate() {
    const preview = this.mode === 'playback';
    const portrait = this.framing === 'portrait' || this.framing === 'auto' && this.view.viewport.clientWidth < this.view.viewport.clientHeight;
    const e = this.evaluator.evaluate(this.time, portrait, {}, this.reducedMotion);
    this.navigation.setEvaluation(e);
    if (!preview) {
      // Author the visibility at the playhead without hiding the working scene behind its opening reveal.
      for (const l of this.project.layers) { e.visible[l.id] = l.included && authoredVisibility(this.project, l.id, this.time); e.layerFade[l.id] = +e.visible[l.id]; }
      e.reveal = 1;
    }
    this.host.setEvaluation(e); this.overlay.update(this.project, e, preview); this.emit();
  }
  private edit(label: string, change: (p: Project) => void) {
    if (this.mode === 'preview') throw new Error('Close compiled preview before editing');
    if (this.playing) this.pause();
    this.history.commit(p => { change(p); syncTimeline(p); validateCameraBindings(p, this.clips); const bytes = referencedHashes(p).reduce((sum, hash) => sum + (this.blobs.get(hash)?.length ?? 0), 0); if (bytes > LIMITS.expandedBytes) throw new Error('Editable project resources exceed 512 MiB; prepare smaller assets first'); }); this.epoch++; this.status = label; this.error = null; this.refresh(); this.autosave();
  }
  private async job<T>(label: string, work: (signal: AbortSignal, check: () => void) => Promise<T>): Promise<T> {
    if (this.pending) throw new Error('Wait for the current operation or cancel it');
    this.pending = true; this.status = label; this.error = null; const controller = new AbortController(), epoch = this.epoch; this.abort = controller; this.emit();
    const check = () => { controller.signal.throwIfAborted(); if (this.epoch !== epoch) throw new Error('Project changed during preparation; stale result discarded'); };
    try { return await work(controller.signal, check); } finally { this.pending = false; this.abort = null; this.emit(); }
  }
  private async activate(project: Project, blobs: Files, label: string) {
    await this.job('Preparing landscape…', async (signal, check) => {
      validateProject(project); const clips = await loadCameraClips(project, blobs);
      for (const a of project.assets) { const bytes = blobs.get(a.hash); if (!bytes) throw new Error('Missing GLB'); const actual = await inspectInWorker(bytes, a.name, a.id, signal); a.nodes = actual.nodes; delete a.nodeKeys; a.bounds = actual.bounds; a.triangles = actual.triangles; a.gpuBytes = actual.gpuBytes; a.instanceBytes = actual.instanceBytes; a.warnings = actual.warnings; }
      await this.validateImages(project, blobs, signal);
      validateProject(project); const prepared = await this.host.prepare(project, blobs, signal);
      try { check(); this.host.publish(prepared); } catch (error) { prepared.dispose(); throw error; }
      this.history.replace(project); this.blobs = blobs; this.clips = clips; this.pendingCamera = null; this.cameraImport = null; this.epoch++; this.time = 0; this.cameraEditingStopId = null; this.cameraSession = 'new'; this.selectedStop = project.instances.length ? null : project.stops[0].id; this.selectedInstance = project.instances[0]?.id ?? null; this.selectedLayer = null; this.status = label; this.refresh();
    });
  }
  private async structural(label: string, project: Project, blobs: Files = this.blobs) {
    await this.job(label, async (signal, check) => {
      validateProject(project); const clips = await loadCameraClips(project, blobs, this.clips); const prepared = await this.host.prepare(project, blobs, signal);
      try { check(); this.host.publish(prepared); } catch (error) { prepared.dispose(); throw error; }
      this.blobs = blobs; for (const [hash, clip] of clips) this.clips.set(hash, clip); this.history.commit(p => Object.assign(p, project)); this.epoch++; this.status = label; this.refresh(); this.autosave();
    });
  }
  private pause() { this.playing = false; cancelAnimationFrame(this.raf); this.navigation.setPlaying(false); this.emit(); }
  private captureViewport() {
    if (this.pending) throw new Error('Finish or cancel preparation before saving a camera view');
    if (this.playing) throw new Error('Pause the timeline before capturing a camera key');
    if (this.mode !== 'explore') throw new Error('Switch to Camera view or Explore before capturing the perspective viewport');
    this.navigation.camera.stop(); const pose = this.host.capture();
    if (pose.aspect < .3 || pose.aspect > 4) throw new Error('Resize the viewport before capturing; frame aspect must be between 0.3 and 4');
    return pose;
  }
  private changeMode(mode: Mode) {
    this.pause();
    if (this.mode === 'preview' && mode !== 'preview') { if (this.previewReceive) removeEventListener('message', this.previewReceive); this.previewReceive = null; this.view.preview.srcdoc = ''; this.previewRevoke?.(); this.previewRevoke = null; }
    if (mode === 'playback' && this.mode !== 'playback' && !this.explored) this.explored = this.host.capture();
    if ((mode === 'explore' || mode === 'plan') && (this.mode === 'playback' || this.mode === 'preview') && this.explored) { this.host.restore(this.explored); this.explored = null; }
    this.mode = mode; this.host.mode(mode); this.navigation.sync(this.project, this.selectedStop, mode); this.evaluate();
  }
  private play(direction: number) {
    const review = this.mode === 'plan' || this.mode === 'explore' && this.navigation.navigationMode === 'orbit';
    if (this.reducedMotion) { const index = this.project.stops.findIndex(s => s.id === this.selectedStop), next = this.project.stops[Math.max(0, Math.min(this.project.stops.length - 1, index + direction))]; this.selectedStop = next.id; this.time = stopTime(this.project, next.id); if (review) { this.pause(); this.evaluate(); } else this.changeMode('playback'); return; }
    if (review) this.pause(); else this.changeMode('playback'); this.direction = direction; if (direction > 0 && this.time >= duration(this.project)) this.time = 0; if (direction < 0 && this.time <= 0) this.time = duration(this.project);
    this.playing = true; this.navigation.setPlaying(true); this.last = performance.now(); this.raf = requestAnimationFrame(this.tick); this.emit();
  }
  private tick = (now: number) => {
    if (!this.playing) return;
    const end = duration(this.project), dt = Math.max(0, (now - this.last) / 1000);
    this.time = Math.min(end, Math.max(0, this.time + dt * this.direction)); this.last = Math.max(this.last, now); this.evaluate();
    if (this.direction > 0 ? this.time >= end : this.time <= 0) this.pause(); else this.raf = requestAnimationFrame(this.tick);
  };
  private async image(file: File): Promise<{ hash: string; width: number; height: number }> {
    if (file.size > 32 * 1024 * 1024) throw new Error('Image exceeds 32 MiB; prepare a smaller image');
    const bytes = new Uint8Array(await file.arrayBuffer()), mime = imageMime(bytes), [width, height] = imageSize(bytes, mime);
    if (width > 8192 || height > 8192) throw new Error('Image exceeds 8192 pixels');
    const decoded = await createImageBitmap(new Blob([bytes], { type: mime })); decoded.close();
    const hash = await sha256(bytes); this.blobs.set(hash, bytes); return { hash, width, height };
  }
  private async validateImages(project: Project, blobs: Files, signal: AbortSignal) {
    const hashes = new Set([...(project.plan ? [project.plan.hash] : []), ...project.stops.flatMap(s => s.photo ? [s.photo.hash, ...(s.photo.portraitHash ? [s.photo.portraitHash] : [])] : [])]);
    for (const hash of hashes) {
      signal.throwIfAborted(); const bytes = blobs.get(hash); if (!bytes || bytes.length > 32 * 1024 * 1024) throw new Error('Missing or oversized project image');
      const mime = imageMime(bytes), [width, height] = imageSize(bytes, mime); if (width > 8192 || height > 8192) throw new Error('Project image exceeds 8192 pixels');
      const bitmap = await createImageBitmap(new Blob([bytes as Uint8Array<ArrayBuffer>], { type: mime })); bitmap.close(); signal.throwIfAborted();
    }
  }
  private async download(files: Files, filename: string, signal: AbortSignal) {
    const retained = [...this.blobs.values()].reduce((sum, b) => sum + b.length, 0), payload = [...files.values()].reduce((sum, b) => sum + b.length, 0);
    if (retained + payload * 3 > 768 * 1024 * 1024) throw new Error('Archive preparation exceeds 768 MiB estimated CPU headroom; optimize source assets first');
    const bytes = await archiveWork('pack', files, signal) as Uint8Array; signal.throwIfAborted();
    const url = URL.createObjectURL(new Blob([bytes as Uint8Array<ArrayBuffer>], { type: 'application/zip' })), link = document.createElement('a'); link.href = url; link.download = filename; link.click(); setTimeout(() => URL.revokeObjectURL(url), 30000);
  }
  async act(name: string, payload?: any): Promise<void> {
    if (name !== 'cancelJob') this.error = null;
    const stop = () => { const s = this.project.stops.find(s => s.id === (payload?.id ?? payload?.stopId ?? payload)); if (!s) throw new Error('Select a valid camera stop'); return s; };
    const imported = (id: string) => this.project.segments.some(s => s.cameraClip && (s.from === id || s.to === id));
    const editable = (id: string) => { if (imported(id)) throw new Error('Use frame in viewport to create a new view, or remove the imported animation before editing its endpoints'); };
    if (this.cameraImport && !['acceptCameraAnimation', 'cancelCameraAnimation', 'cancelJob'].includes(name)) throw new Error('Confirm or cancel the camera import first');
    if (this.pending && ['moveTimelineKeys', 'deleteTimelineKeys', 'pasteTimelineKeys', 'captureLayerKey', 'setTimelineOptions', 'setKeyInterpolation', 'updateCameraKey'].includes(name)) throw new Error('Finish or cancel preparation before editing the timeline');
    switch (name) {
      case 'importCameraAnimation': await this.job('Reading camera animation…', async (_signal, check) => {
        const file: File = payload; if (file.size > CAMERA_FILE_LIMIT) throw new Error('Camera animation exceeds the 4 MiB limit');
        const bytes = new Uint8Array(await file.arrayBuffer()), clip = parseCameraClip(bytes), hash = await sha256(bytes); check();
        this.pause(); this.pendingCamera = { bytes, clip, hash }; this.cameraImport = cameraReference(hash, clip); this.navigation.camera.stop(); this.status = 'Review the original camera animation before replacing the journey';
      }); break;
      case 'cancelCameraAnimation': this.cameraImport = null; this.pendingCamera = null; this.status = 'Camera import cancelled'; break;
      case 'acceptCameraAnimation': {
        if (this.pending || !this.pendingCamera) throw new Error('No camera animation is ready to import');
        const { bytes, clip, hash } = this.pendingCamera, ref = cameraReference(hash, clip);
        if (this.mode === 'preview') this.changeMode('explore');
        const first: Stop = { id: uuid(), name: `${clip.name} · Start`.slice(0, 200), ...clip.samples[0], aspect: clip.aspect, hold: 0 };
        const last: Stop = { id: uuid(), name: `${clip.name} · End`.slice(0, 200), ...clip.samples.at(-1)!, aspect: clip.aspect, hold: 0 };
        this.blobs.set(hash, bytes); this.clips.set(hash, clip);
        this.edit('Camera animation imported with its original movement and timing', p => { const previous = p.timeline; delete p.timeline; p.schemaVersion = 2; p.stops = [first, last]; p.segments = []; reconnect(p); Object.assign(p.segments[0], { duration: ref.duration, ease: 0, cameraClip: ref }); if (previous) { const t = ensureTimeline(p); t.fps = previous.fps; t.duration = Math.max(t.duration, previous.duration); t.layers = previous.layers; } });
        this.cameraImport = null; this.pendingCamera = null; this.selectedStop = first.id; this.cameraEditingStopId = null; this.cameraSession = 'new'; this.selectedInstance = this.selectedLayer = null;
        this.time = this.project.opening + this.project.revealDuration; this.changeMode('playback'); break;
      }
      case 'animationFrameToViewport': {
        const frame = this.evaluator.evaluate(this.time); this.changeMode('explore'); this.host.restore(frame); this.navigation.setNavigationMode('camera'); this.navigation.alignOrbit(); this.navigation.sync(this.project, this.selectedStop, this.mode); this.cameraEditingStopId = null; this.cameraSession = 'new';
        this.status = 'Compose at the playhead · navigate, then capture a camera key at this time'; break;
      }
      case 'removeCameraAnimation': {
        const segment = this.project.segments.find(s => s.id === payload); if (!segment?.cameraClip) throw new Error('Select an imported camera animation');
        this.edit('Imported animation removed · endpoint views are now connected by an editable straight path', p => { delete p.segments.find(s => s.id === payload)!.cameraClip; }); break;
      }
      case 'cancelJob': this.abort?.abort(); this.status = 'Cancelling preparation…'; break;
      case 'title': this.edit('Project renamed', p => { p.title = payload; }); break;
      case 'mode': this.changeMode(payload); break;
      case 'navigationMode': {
        if (payload !== 'camera' && payload !== 'orbit') throw new Error('Choose Camera view or Orbit');
        this.changeMode('explore'); this.navigation.setNavigationMode(payload); this.navigation.sync(this.project, this.selectedStop, this.mode);
        this.status = payload === 'camera' ? 'Camera view · click viewport, drag to look, WASD to move, Q/E for height · capture when ready' : 'Orbit view · navigate, then capture the current viewport'; break;
      }
      case 'cameraSpeed': {
        const value = Number(payload); if (!Number.isFinite(value) || value < .1 || value > 100) throw new Error('Camera speed must be between 0.1 and 100 m/s'); this.navigation.camera.speed = value; break;
      }
      case 'cameraFov': {
        const value = Number(payload); if (this.mode !== 'explore' || !Number.isFinite(value) || value < 10 || value > 110) throw new Error('Set the viewport lens in Explore between 10 and 110 degrees');
        this.host.perspective.fov = value; this.host.perspective.updateProjectionMatrix(); this.host.invalidate(); this.status = 'Viewport lens changed · capture or save the current view when ready'; break;
      }
      case 'editCameraStop': {
        if (this.pending) throw new Error('Finish or cancel preparation before editing a camera view');
        const s = stop(); editable(s.id); this.changeMode('explore'); this.host.restore(s); this.navigation.setNavigationMode('camera'); this.navigation.alignOrbit();
        this.selectedStop = s.id; this.time = timelineOf(this.project).keys.find(k => k.stopId === s.id)!.time; this.selectedInstance = this.selectedLayer = null; this.cameraEditingStopId = s.id; this.cameraSession = 'edit'; this.navigation.sync(this.project, s.id, this.mode);
        this.status = `Editing ${s.name} in the viewport · navigate, then Save view`; break;
      }
      case 'finishCameraEdit': this.navigation.camera.stop(); this.cameraEditingStopId = null; this.cameraSession = 'new'; this.status = 'Ready to capture a new view'; break;
      case 'framing': this.framing = payload; this.evaluate(); break;
      case 'framePreset': if (!FRAME_PRESETS.some(f => f.id === payload)) throw new Error('Choose a supported frame format'); this.framePreset = payload; this.host.setFrameAspect(presetAspect(this.framePreset)); this.navigation.updateViewport(); try { localStorage.setItem('cyrus-studio.frame', JSON.stringify({ preset: this.framePreset, safe: this.safeFrame })); } catch {} break;
      case 'safeFrame': this.safeFrame = !!payload; try { localStorage.setItem('cyrus-studio.frame', JSON.stringify({ preset: this.framePreset, safe: this.safeFrame })); } catch {} break;
      case 'pause': this.pause(); break;
      case 'play': this.play(1); break;
      case 'reverse': this.play(-1); break;
      case 'time': if (!Number.isFinite(payload)) throw new Error('Time must be finite'); this.pause(); this.time = Math.max(0, Math.min(duration(this.project), payload)); this.cameraEditingStopId = null; this.cameraSession = 'new'; if (this.mode === 'plan' || this.mode === 'explore' && this.navigation.navigationMode === 'orbit') this.evaluate(); else this.changeMode('playback'); break;
      case 'reset': await this.act('time', 0); break;
      case 'reducedMotion': this.reducedMotion = payload; this.pause(); this.evaluate(); break;
      case 'selectLayer': this.selectedLayer = payload; this.selectedInstance = null; this.selectedStop = null; this.navigation.sync(this.project, null, this.mode); break;
      case 'selectInstance': this.selectedInstance = payload; this.selectedLayer = null; this.selectedStop = null; this.navigation.sync(this.project, null, this.mode); break;
      case 'selectStop': this.pause(); this.selectedStop = payload; this.selectedLayer = null; this.selectedInstance = null; this.time = timelineOf(this.project).keys.find(k => k.stopId === payload)?.time ?? 0; this.navigation.sync(this.project, payload, this.mode); this.evaluate(); break;
      case 'updateLayer': this.edit('Layer updated', p => { Object.assign(p.layers.find(l => l.id === payload.id)!, payload.patch); }); break;
      case 'moveLayer': this.edit('Layer order updated', p => { const index = p.layers.findIndex(l => l.id === payload.id), next = Math.max(0, Math.min(p.layers.length - 1, index + payload.direction)); const [item] = p.layers.splice(index, 1); p.layers.splice(next, 0, item); }); break;
      case 'isolateLayer': this.edit('Initial visibility isolated to this layer', p => { p.layers.forEach(l => { l.defaultVisible = l.id === payload; }); }); break;
      case 'showAll': this.edit('All layers initially visible', p => { p.layers.forEach(l => { l.defaultVisible = true; }); }); break;
      case 'updateInstance': this.edit('Asset placement updated', p => { Object.assign(p.instances.find(i => i.id === payload.id)!, payload.patch); }); break;
      case 'assignNode': this.edit('Node layer assigned', p => { const i = p.instances.find(i => i.id === payload.instanceId)!; if (payload.layerId) i.membership[payload.nodeKey] = payload.layerId; else delete i.membership[payload.nodeKey]; }); break;
      case 'removeInstance': { const p = structuredClone(this.project); p.instances = p.instances.filter(i => i.id !== payload); p.assets = p.assets.filter(a => p.instances.some(i => i.assetRevision === a.revisionId)); await this.structural('Asset removed', p); break; }
      case 'updateProject': {
        if (payload.profile) { const estimate = this.host.estimatedGpu({ ...this.project, profile: payload.profile }); if (estimate > (payload.profile === 'mobile' ? 192 : 384) * 1024 * 1024) throw new Error('Scene exceeds this profile; optimize its assets first'); }
        this.edit('Presentation settings updated', p => Object.assign(p, payload)); break;
      }
      case 'captureStop': { const pose = this.captureViewport(); let id = ''; this.edit('Viewport captured as a camera key at the playhead', p => { id = insertCameraKey(p, pose, this.time); }); this.selectedStop = this.cameraEditingStopId = id; this.cameraSession = 'new'; this.selectedInstance = this.selectedLayer = null; this.navigation.sync(this.project, id, this.mode); break; }
      case 'moveTimelineKeys': this.pause(); this.edit('Timeline keys moved', p => moveTimelineKeys(p, payload, payload.delta)); break;
      case 'deleteTimelineKeys': this.pause(); this.edit('Timeline keys deleted', p => deleteTimelineKeys(p, payload)); break;
      case 'copyTimelineKeys': this.timelineClipboard = copyTimelineKeys(this.project, payload); this.status = 'Timeline keys copied · move the playhead and paste'; break;
      case 'pasteTimelineKeys': if (!this.timelineClipboard) throw new Error('Copy timeline keys first'); else this.edit('Timeline keys pasted', p => pasteTimelineKeys(p, this.timelineClipboard!, payload?.time ?? this.time)); break;
      case 'captureLayerKey': this.edit('Layer visibility keyed at the playhead', p => captureLayerKey(p, payload.layerId, payload.time ?? this.time, payload.visible)); break;
      case 'setTimelineOptions': this.edit('Timeline settings updated', p => { const t = ensureTimeline(p); if (payload.fps !== undefined) t.fps = payload.fps; if (payload.duration !== undefined) t.duration = payload.duration; }); break;
      case 'setKeyInterpolation': this.edit('Camera key interpolation updated', p => { if (!['linear', 'ease', 'hold'].includes(payload.value)) throw new Error('Choose Linear, Ease or Hold'); if (payload.ids.some((id: string) => cameraLocked(p, id))) throw new Error('Imported Max interpolation is protected'); const t = ensureTimeline(p); for (const k of t.keys) if (payload.ids.includes(k.stopId)) k.interpolation = payload.value; }); break;
      case 'updateCameraKey': this.edit('Camera key timing updated', p => { const k = ensureTimeline(p).keys.find(k => k.stopId === payload.id); if (!k) throw new Error('Select a valid camera key'); if (payload.time !== undefined) moveTimelineKeys(p, { cameraIds: [payload.id] }, payload.time - k.time); if (payload.interpolation !== undefined) { if (cameraLocked(p, payload.id)) throw new Error('Imported Max interpolation is protected'); if (!['linear', 'ease', 'hold', 'legacy'].includes(payload.interpolation)) throw new Error('Choose a valid interpolation'); k.interpolation = payload.interpolation; } }); break;
      case 'updateFromView': { const id = stop().id; editable(id); const pose = this.captureViewport(); this.edit('Camera keyframe saved from the current viewport', p => Object.assign(p.stops.find(s => s.id === id)!, pose)); this.cameraEditingStopId = id; this.cameraSession = 'edit'; break; }
      case 'capturePortrait': { const id = stop().id; editable(id); const pose = this.captureViewport(); this.edit('Portrait composition captured', p => { p.stops.find(s => s.id === id)!.portrait = { ...pose, aspect: 9 / 16 }; }); break; }
      case 'lookTarget': { const s = stop(); editable(s.id); const quaternion = lookQuaternion(s.position, payload.target); this.edit('Look target updated', p => { p.stops.find(x => x.id === s.id)!.quaternion = quaternion; }); break; }
      case 'updateStop': if (Object.keys(payload.patch).some(k => !['name', 'hold', 'photo'].includes(k))) editable(payload.id); this.edit('Camera key updated', p => { const s = p.stops.find(s => s.id === payload.id)!; Object.assign(s, payload.patch); if (p.timeline && payload.patch.hold !== undefined && p.stops.at(-1)!.id === s.id) p.timeline.duration = Math.max(p.timeline.duration, p.timeline.keys.at(-1)!.time + s.hold); }); break;
      case 'moveStop': if (this.project.timeline) throw new Error('Drag the camera key in the timeline to change its time'); { const index = this.project.stops.findIndex(s => s.id === payload.id), next = Math.max(0, Math.min(this.project.stops.length - 1, index + payload.direction)); editable(payload.id); editable(this.project.stops[next].id); } this.edit('Camera stops reordered', p => { const index = p.stops.findIndex(s => s.id === payload.id), next = Math.max(0, Math.min(p.stops.length - 1, index + payload.direction)); const [s] = p.stops.splice(index, 1); p.stops.splice(next, 0, s); reconnect(p); }); break;
      case 'deleteStop': editable(payload); this.edit('Camera key deleted', p => deleteTimelineKeys(p, { cameraIds: [payload] })); break;
      case 'updateSegment': if (this.project.segments.find(s => s.id === payload.id)?.cameraClip) throw new Error('Imported camera timing and path are read-only'); if (this.project.timeline && payload.patch.duration !== undefined) throw new Error('Drag camera keys in the timeline to set travel timing'); this.edit('Camera travel updated', p => Object.assign(p.segments.find(s => s.id === payload.id)!, payload.patch)); break;
      case 'segmentSpeed': { const s = this.project.segments.find(s => s.id === payload.id)!; if (s?.cameraClip) throw new Error('Imported camera timing is read-only'); if (this.project.timeline) throw new Error('Drag the camera key in the timeline to set travel timing'); if (!s || payload.speed <= 0) throw new Error('Speed must be positive'); const seconds = this.evaluator.table(s).length / payload.speed; this.edit('Travel speed updated', p => { p.segments.find(x => x.id === s.id)!.duration = seconds; }); break; }
      case 'importPlan': { const image = await this.image(payload); this.edit('Plan imported', p => { p.plan = { ...image, a: [0, 0], b: [image.width, 0], distance: 100, origin: [-50, 0, -50], rotation: 0 }; }); break; }
      case 'updatePlan': this.edit('Plan calibration updated', p => { if (!p.plan) throw new Error('Import a plan first'); Object.assign(p.plan, payload); if (p.plan.third) { const actual = planPoint(p.plan, p.plan.third.pixel); this.status = `Calibration check residual: ${Math.hypot(...actual.map((v, i) => v - p.plan!.third!.world[i])).toFixed(3)} m`; } }); break;
      case 'removePlan': this.edit('Plan removed', p => { delete p.plan; }); break;
      case 'importPhoto': { const id = stop().id, image = await this.image(payload.file); this.edit('Artistic photo imported · review and approve', p => { const s = p.stops.find(s => s.id === id)!; if (payload.portrait) { if (!s.photo) throw new Error('Import the primary artistic photo first'); s.photo.portraitHash = image.hash; delete s.photo.approvedFingerprint; } else s.photo = { hash: image.hash, caption: '' }; }); break; }
      case 'approvePhoto': { const s = stop(); if (!s.photo) throw new Error('Import an artistic photo first'); const fingerprint = photoFingerprint(this.project, s); this.edit('Artistic interpretation approved for this scene', p => { p.stops.find(x => x.id === s.id)!.photo!.approvedFingerprint = fingerprint; }); break; }
      case 'photoCaption': this.edit('Photo caption updated', p => { p.stops.find(s => s.id === payload.stopId)!.photo!.caption = payload.caption; }); break;
      case 'removePhoto': { const id = stop().id; this.edit('Photo removed', p => { delete p.stops.find(s => s.id === id)!.photo; }); break; }
      case 'undo': case 'redo': {
        if (this.pending) throw new Error('Cancel or finish preparation before changing history');
        const original = this.project; name === 'undo' ? this.history.undo() : this.history.redo(); const next = this.project;
        if (next === original) break;
        const signature = (p: Project) => p.instances.map(i => `${i.id}:${i.assetRevision}`).join('|');
        if (signature(next) !== signature(original)) { name === 'undo' ? this.history.redo() : this.history.undo(); await this.job('Restoring scene history…', async (signal, check) => { const prepared = await this.host.prepare(next, this.blobs, signal); try { check(); this.host.publish(prepared); } catch (e) { prepared.dispose(); throw e; } name === 'undo' ? this.history.undo() : this.history.redo(); }); }
        this.epoch++; this.status = name === 'undo' ? 'Undo applied' : 'Redo applied'; this.refresh(); this.autosave(); break;
      }
      case 'demo': { const demo = await createDemo(); await this.activate(demo.project, demo.blobs, 'Sample garden ready'); this.autosave(); break; }
      case 'newProject': { const p = emptyProject(); p.stops[0].hold = 0; const t = ensureTimeline(p); t.keys[0].time = 0; t.keys[0].interpolation = 'ease'; t.duration = 20; await this.activate(p, new Map(), 'New presentation · compose your first camera key at 0 seconds'); this.autosave(); break; }
      case 'restoreAutosave': { const saved = await this.store.load(); if (!saved) throw new Error('No local autosave exists'); await this.activate(saved.project, saved.blobs, 'Local autosave restored'); break; }
      case 'openProject': await this.job('Reading portable project…', async (signal, check) => {
        const data = await readProjectArchive(new Uint8Array(await payload.arrayBuffer()), signal, [...this.blobs.values()].reduce((sum, b) => sum + b.length, 0)); check();
        for (const a of data.project.assets) { const actual = await inspectInWorker(data.blobs.get(a.hash)!, a.name, a.id, signal); a.nodes = actual.nodes; delete a.nodeKeys; a.bounds = actual.bounds; a.triangles = actual.triangles; a.gpuBytes = actual.gpuBytes; a.instanceBytes = actual.instanceBytes; a.warnings = actual.warnings; }
        await this.validateImages(data.project, data.blobs, signal);
        validateProject(data.project); const clips = await loadCameraClips(data.project, data.blobs); const prepared = await this.host.prepare(data.project, data.blobs, signal); try { check(); this.host.publish(prepared); } catch (e) { prepared.dispose(); throw e; }
        this.history.replace(data.project); this.blobs = data.blobs; this.clips = clips; this.cameraImport = null; this.pendingCamera = null; this.time = 0; this.epoch++; this.cameraEditingStopId = null; this.cameraSession = 'new'; this.selectedInstance = data.project.instances[0]?.id ?? null; this.selectedLayer = null; this.selectedStop = data.project.instances.length ? null : data.project.stops[0].id; this.status = 'Portable project opened'; this.refresh(); this.autosave();
      }); break;
      case 'importGLB': case 'replaceAsset': await this.job(name === 'importGLB' ? 'Validating GLB…' : 'Reviewing replacement…', async (signal, check) => {
        const file: File = payload.file; if (file.size > LIMITS.fileBytes) throw new Error('GLB exceeds 250 MiB'); const bytes = new Uint8Array(await file.arrayBuffer()), instance = this.project.instances.find(i => i.id === payload.instanceId), previous = instance ? this.project.assets.find(a => a.revisionId === instance.assetRevision) : undefined;
        const asset = await inspectInWorker(bytes, file.name, previous?.id, signal); check();
        if (name === 'replaceAsset') { if (!instance || !previous) throw new Error('Select an imported asset to replace'); this.replacementBytes = bytes; this.replacement = { asset, instanceId: instance.id, suggestions: replacementSuggestions(previous, asset), previousNames: Object.fromEntries(previous.nodes.map(n => [n.key, n.path])) }; this.status = 'Review node correspondence before replacing'; return; }
        const p = structuredClone(this.project), membership: Record<string, string> = {};
        for (const n of asset.nodes.filter(n => !n.parent)) {
          const layer = { id: uuid(), name: n.externalLayer ?? n.name, included: true, defaultVisible: true, viewerToggle: true, reveal: 0.2 }; p.layers.push(layer); membership[n.key] = layer.id;
        }
        for (const n of asset.nodes.filter(n => n.parent && n.externalLayer)) { const layer = p.layers.find(l => l.name === n.externalLayer) ?? { id: uuid(), name: n.externalLayer!, included: true, defaultVisible: true, viewerToggle: true, reveal: 0.2 }; if (!p.layers.includes(layer)) p.layers.push(layer); membership[n.key] = layer.id; }
        const transform = identityTransform(); transform.scale = payload.units ?? 1; if (payload.up === 'Z') transform.rotation = new Quaternion().setFromAxisAngle({ x: 1, y: 0, z: 0 } as any, -Math.PI / 2).toArray() as any;
        p.assets.push(asset); const imported = { id: uuid(), assetRevision: asset.revisionId, name: file.name, transform, membership }; p.instances.push(imported); validateProject(p);
        const blobs = new Map(this.blobs); blobs.set(asset.hash, bytes); const prepared = await this.host.prepare(p, blobs, signal); try { check(); this.host.publish(prepared); } catch (e) { prepared.dispose(); throw e; }
        this.blobs = blobs; this.history.commit(d => Object.assign(d, p)); this.epoch++; this.selectedInstance = imported.id; this.selectedStop = null; this.status = `Imported ${file.name}${asset.warnings.length ? ` · ${asset.warnings.join('; ')}` : ''}`; this.refresh(); this.autosave();
      }); break;
      case 'acceptReplacement': {
        const review = this.replacement, bytes = this.replacementBytes; if (!review || !bytes) throw new Error('No replacement pending');
        const p = structuredClone(this.project), chosen = p.instances.find(i => i.id === review.instanceId)!, old = p.assets.find(a => a.revisionId === chosen.assetRevision)!, next = review.asset;
        const used = new Set<string>();
        for (const [newKey, oldKey] of Object.entries(payload.mapping) as [string, string][]) { if (!next.nodes.some(n => n.key === newKey) || !old.nodes.some(n => n.key === oldKey) || used.has(oldKey)) throw new Error('Invalid or ambiguous node mapping'); used.add(oldKey); }
        for (const instance of p.instances.filter(i => i.assetRevision === old.revisionId)) {
          const membership: Record<string, string> = { ...payload.assignments };
          for (const [newKey, oldKey] of Object.entries(payload.mapping) as [string, string][]) { const layer = resolveLayer(oldKey, old, instance); if (layer) membership[newKey] = layer; }
          instance.assetRevision = next.revisionId; instance.membership = membership;
        }
        p.assets = p.assets.filter(a => a.revisionId !== old.revisionId); p.assets.push(next);
        const blobs = new Map(this.blobs); blobs.set(next.hash, bytes); await this.structural('Asset revision replaced', p, blobs); this.replacement = null; this.replacementBytes = null; break;
      }
      case 'cancelReplacement': this.replacement = null; this.replacementBytes = null; this.status = 'Replacement cancelled'; break;
      case 'saveProject': await this.job('Saving portable project…', async (signal, check) => { const files = await projectFiles(this.project, this.blobs); check(); await this.download(files, 'project.cyrus-presentation.zip', signal); this.status = 'Portable project saved'; }); break;
      case 'exportWebsite': await this.job('Compiling website…', async (signal, check) => { const output = await compile(this.project, this.blobs, await playerShell(), signal); check(); await this.download(output.files, 'presentation.zip', signal); this.status = 'Website ZIP exported · unpack and serve through HTTP'; }); break;
      case 'preview': await this.job('Compiling player preview…', async (signal, check) => {
        const output = await compile(this.project, this.blobs, await playerShell(), signal); check();
        const retained = [...this.blobs.values()].reduce((sum, bytes) => sum + bytes.length, 0), size = [...output.files.values()].reduce((sum, bytes) => sum + bytes.length, 0); if (retained + size * 2 > 768 * 1024 * 1024) throw new Error('Compiled preview exceeds estimated CPU headroom; prepare smaller assets');
        const token = uuid(), preview = previewHTML(output.files, token); this.previewRevoke?.(); this.previewRevoke = preview.revoke;
        this.changeMode('preview'); this.overlay.hide();
        this.previewReceive = event => { if (event.source === this.view.preview.contentWindow && event.origin === location.origin && event.data?.type === 'cyrus-ready' && event.data.token === token) this.view.preview.contentWindow!.postMessage({ type: 'cyrus-preview', token, files: [...output.files] }, location.origin); };
        addEventListener('message', this.previewReceive); this.view.preview.srcdoc = preview.html; this.status = 'Compiled player preview';
      }); break;
      case 'closePreview': if (this.previewReceive) removeEventListener('message', this.previewReceive); this.previewReceive = null; this.view.preview.srcdoc = ''; this.previewRevoke?.(); this.previewRevoke = null; this.changeMode('explore'); break;
      default: throw new Error(`Unknown action: ${name}`);
    }
    this.emit();
  }
}
new Studio();
