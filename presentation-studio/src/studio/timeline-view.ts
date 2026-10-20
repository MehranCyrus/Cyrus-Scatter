import type { StudioActions, ViewState } from './contracts';
import { authoredVisibility, cameraLocked, clipRanges, snapTime, timelineOf } from '../presentation/timeline';
import './timeline.css';

const esc = (value: unknown) => String(value ?? '').replace(/[&<>"']/g, c => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[c]!));
const number = (value: number) => Number(value.toFixed(3)).toString();
const glyphs: Record<string, string> = {
  play: '<path d="m8 4 12 8-12 8V4Z"/>', pause: '<path d="M8 4v16M16 4v16"/>',
  camera: '<path d="M3 7h4l2-3h6l2 3h4v14H3V7Z"/><circle cx="12" cy="13" r="4"/>',
  down: '<path d="m6 9 6 6 6-6"/>', reset: '<path d="M4 4v6h6M4 10a8 8 0 1 1 0 5"/>',
  layers: '<path d="m12 3 10 5-10 5L2 8l10-5ZM2 12l10 5 10-5M2 16l10 5 10-5"/>',
  eye: '<path d="M2 12s4-7 10-7 10 7 10 7-4 7-10 7S2 12 2 12Z"/><circle cx="12" cy="12" r="3"/>',
  hide: '<path d="m3 3 18 18M9.5 5.3A12 12 0 0 1 12 5c6 0 10 7 10 7a21 21 0 0 1-3 4M6 6c-3 2-4 6-4 6s4 7 10 7c2 0 4-.7 5.5-1.7M10 10a3 3 0 0 0 4 4"/>',
  lock: '<rect x="5" y="10" width="14" height="11" rx="1"/><path d="M8 10V7a4 4 0 0 1 8 0v3"/>',
  diamond: '<path d="m12 3 9 9-9 9-9-9 9-9Z"/>',
};
const icon = (name: string) => `<svg aria-hidden="true" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.6" stroke-linecap="round" stroke-linejoin="round">${glyphs[name] ?? glyphs.diamond}</svg>`;
type Selection = { cameraIds: string[]; layerKeyIds: string[] };
type Drag = { pointer: number; kind: 'key' | 'scrub'; x: number; activeTime: number; delta: number; moved: boolean; min: number; max: number; selection: Selection };

/** A retained timeline: animation updates only move the playhead and update readouts. */
export function mountTimeline(root: HTMLElement, actions: StudioActions): { update(s: ViewState): void; dispose(): void } {
  root.innerHTML = `<div class="tl-resize-handle" role="separator" aria-label="Timeline height" aria-orientation="horizontal" aria-controls="timeline-tracks" tabindex="0" data-testid="timeline-resize" title="Drag to resize the timeline · double-click to reset"><span></span></div><div class="tl-toolbar">
    <button type="button" class="tl-title" data-tl-action="collapse" aria-expanded="true" aria-label="Collapse animation timeline">${icon('down')}<span>Timeline</span></button>
    <button type="button" class="tl-play" data-tl-action="play" data-testid="play" aria-label="Play presentation">${icon('play')}</button>
    <div class="tl-time"><label><span class="sr-only">Playhead time in seconds</span><input type="number" data-tl-input="time" aria-label="Playhead time in seconds" min="0" step="any" value="0" /></label><span class="tl-seconds">s</span><span class="tl-total">/ <span id="total-time">00:00</span></span><span id="current-time" class="sr-only">00:00</span></div>
    <button type="button" class="tl-compose" data-tl-action="animationFrameToViewport" data-testid="compose-at-playhead" title="Use this frame in the viewport, navigate, then Capture view">${icon('camera')}<span>Compose at playhead</span></button>
    <span class="tl-selection" aria-live="polite">Full camera pose</span>
    <label class="tl-interpolation"><span class="sr-only">Selected camera key interpolation</span><select data-tl-input="interpolation" aria-label="Selected camera key interpolation"><option value="legacy" disabled>Preserved path</option><option value="mixed" disabled>Mixed motion</option><option value="linear">Linear</option><option value="ease">Ease</option><option value="hold">Hold</option></select></label>
    <div class="tl-tools"><label class="tl-snap" title="Snap key movement and seeking to frames"><input type="checkbox" data-tl-input="snap" checked /><span>Snap</span></label><label class="tl-zoom"><span class="sr-only">Timeline zoom</span><select data-tl-input="zoom" aria-label="Timeline zoom"><option value="1">Fit</option><option value="2">200%</option><option value="4">400%</option><option value="8">800%</option></select></label><details class="menu tl-menu"><summary aria-label="Timeline options" title="Timeline options">···</summary><div class="menu-popover"><button type="button" data-tl-action="copy">Copy selected keys <kbd>Ctrl C</kbd></button><button type="button" data-tl-action="paste">Paste at playhead <kbd>Ctrl V</kbd></button><button type="button" data-tl-action="delete" class="danger">Delete selected keys <kbd>Del</kbd></button><hr /><button type="button" data-tl-action="reset">Restart presentation</button><button type="button" data-tl-action="reverse">Play in reverse</button><label class="check-field"><input type="checkbox" id="reduced-motion" data-tl-input="reducedMotion" /><span>Reduced motion</span></label><hr /><label class="tl-option"><span>Frame rate</span><select data-tl-input="fps" aria-label="Timeline frame rate"><option value="24">24 fps</option><option value="25">25 fps</option><option value="30">30 fps</option><option value="60">60 fps</option></select></label><label class="tl-option"><span>Duration · s</span><input type="number" data-tl-input="duration" aria-label="Timeline duration in seconds" min="0.01" max="864000" step="any" /></label><p>Drag diamonds to retime. Shift-click to select several. Camera properties share one full-pose key.</p></div></details></div>
  </div><div class="tl-scroll" id="timeline-tracks" tabindex="0" aria-label="Animation tracks. Use arrow keys to seek by frame; Shift selects multiple keys."><div class="tl-content"><div class="tl-rows" data-testid="stop-list"></div><div class="tl-playhead" aria-hidden="true"><span></span></div></div></div><div class="tl-footnote"><span class="tl-hint">Navigate → capture at playhead → refine</span><span class="tl-frame">30 fps</span></div><input type="range" id="timeline" data-testid="timeline" data-scope="time" class="sr-only" tabindex="-1" aria-label="Presentation time in seconds" min="0" max="1" step="0.01" value="0" />`;
  const get = <T extends HTMLElement = HTMLElement>(selector: string) => root.querySelector<T>(selector)!;
  const scroll = get('.tl-scroll'), content = get('.tl-content'), rows = get('.tl-rows');
  const studio = root.closest<HTMLElement>('.studio')!;
  const resizeHandle = get('.tl-resize-handle'), collapseButton = get<HTMLButtonElement>('.tl-title');
  const playhead = get('.tl-playhead'), timeInput = get<HTMLInputElement>('[data-tl-input="time"]');
  const currentTime = get('#current-time'), totalTime = get('#total-time'), timeRange = get<HTMLInputElement>('#timeline');
  const playButton = get<HTMLButtonElement>('[data-testid="play"]'), composeButton = get<HTMLButtonElement>('[data-testid="compose-at-playhead"]');
  const reducedMotionInput = get<HTMLInputElement>('[data-tl-input="reducedMotion"]'), frameReadout = get('.tl-frame');
  const heightStorageKey = 'cyrus-studio.timeline-height';
  let expandedHeight = 258;
  try { const saved = Number(localStorage.getItem(heightStorageKey)); if (Number.isFinite(saved) && saved >= 140) expandedHeight = saved; } catch { /* Workspace preferences are optional. */ }
  let resizeDrag: { pointer: number; y: number; height: number } | null = null;
  let lastScrollWidth = -1, lastTimeSignature = '', lastTimeProject: ViewState['project'] | null = null;
  let ruler: HTMLElement | null = null;
  let layerRows: HTMLElement[] = [];
  let state: ViewState | null = null, project: ViewState['project'] | null = null;
  let timelineProject: ViewState['project'] | null = null, cachedTimeline: ReturnType<typeof timelineOf> | null = null;
  let selection: Selection = { cameraIds: [], layerKeyIds: [] };
  let cameraExpanded = false, collapsed = false, snapping = true, zoom = 1, scale = 20, width = 700;
  let drag: Drag | null = null, ignoreClickUntil = 0, previousSelected: string | null = null;
  let previousDisabled = false, lastLayerStates = '', lastSignature = '';
  const labelWidth = 230, axisInset = 12;
  const unavailable = () => !state || state.pending || state.mode === 'preview';
  const currentTimeline = () => {
    if (timelineProject !== state!.project || !cachedTimeline) { timelineProject = state!.project; cachedTimeline = timelineOf(state!.project); }
    return cachedTimeline;
  };
  const payload = (): Selection => ({ cameraIds: [...selection.cameraIds], layerKeyIds: [...selection.layerKeyIds] });
  const hasSelection = () => !!(selection.cameraIds.length + selection.layerKeyIds.length);
  const keyTime = (kind: string, id: string): number => {
    if (!state) return 0;
    const timeline = currentTimeline();
    return kind === 'camera' ? timeline.keys.find(k => k.stopId === id)?.time ?? 0 : timeline.layers.flatMap(l => l.keys).find(k => k.id === id)?.time ?? 0;
  };
  const clock = (time: number) => `${Math.floor(time / 60).toString().padStart(2, '0')}:${Math.floor(time % 60).toString().padStart(2, '0')}`;
  const timeLabel = (time: number) => `${number(time)} seconds`;

  function maximumHeight(): number {
    const chromeHeight = ['.app-header', '.camera-authoring', '.status-bar'].reduce((height, selector) => height + (studio.querySelector(selector)?.getBoundingClientRect().height ?? 0), 0);
    const workspace = studio.querySelector<HTMLElement>('.workspace'), stage = studio.querySelector<HTMLElement>('.stage');
    const stackedPanels = workspace && stage && window.innerWidth > 650 ? Math.max(0, workspace.clientHeight - stage.clientHeight) : 0;
    return Math.max(140, Math.floor(studio.clientHeight - chromeHeight - stackedPanels - 220));
  }
  function setHeight(height: number, remember = false): void {
    expandedHeight = Math.max(140, Math.min(maximumHeight(), Math.round(height)));
    const value = collapsed ? '42px' : `${expandedHeight}px`;
    if (studio.style.getPropertyValue('--timeline-height') !== value) studio.style.setProperty('--timeline-height', value);
    const attributes = { 'aria-valuemin': '140', 'aria-valuemax': String(maximumHeight()), 'aria-valuenow': String(expandedHeight), 'aria-valuetext': `${expandedHeight} pixels${collapsed ? ', collapsed' : ''}` };
    for (const [name, value] of Object.entries(attributes)) if (resizeHandle.getAttribute(name) !== value) resizeHandle.setAttribute(name, value);
    if (remember) try { localStorage.setItem(heightStorageKey, String(expandedHeight)); } catch { /* Keep the session preference when storage is unavailable. */ }
  }
  function setCollapsed(value: boolean): void {
    collapsed = value; root.dataset.collapsed = String(collapsed);
    collapseButton.setAttribute('aria-expanded', String(!collapsed));
    collapseButton.setAttribute('aria-label', `${collapsed ? 'Expand' : 'Collapse'} animation timeline`);
    setHeight(expandedHeight);
  }
  function resizeWindow(): void { setHeight(expandedHeight); }
  function doubleclick(event: MouseEvent): void { if (event.target instanceof Element && event.target.closest('.tl-resize-handle')) { setCollapsed(false); setHeight(258, true); } }

  function keyButton(kind: 'camera' | 'layer', id: string, time: number, name: string, locked = false, visible = true, property = ''): string {
    return `<button type="button" class="tl-key${locked ? ' locked' : ''}${!visible ? ' hidden-key' : ''}${property ? ' property-key' : ''}" data-tl-key="${kind}" data-key-id="${esc(id)}" data-time="${time}"${property ? ` data-property="${property}"` : ''} style="left:${axisInset + time * scale}px" aria-label="${esc(`${name}, ${timeLabel(time)}${locked ? ', protected imported camera endpoint' : ''}${property ? ', linked full camera pose' : ''}`)}" title="${esc(`${name} · ${number(time)} s${locked ? ' · Protected' : ''}${property ? ' · Linked camera pose' : ''}`)}" aria-pressed="false"${unavailable() ? ' disabled' : ''}><span></span></button>`;
  }

  function visibleAt(layerId: string): boolean {
    return state ? authoredVisibility(state.project, layerId, state.time) : false;
  }

  function renderRows(): void {
    if (!state || drag) return;
    const active = document.activeElement instanceof HTMLElement ? document.activeElement : null;
    const focusKey = active?.dataset.keyId, focusProperty = active?.dataset.property;
    const focusAction = active && rows.contains(active) ? active.dataset.tlAction : undefined, focusLayer = active?.dataset.layer;
    const timeline = currentTimeline(), duration = Math.max(.01, state.duration);
    width = Math.max(260, scroll.clientWidth - labelWidth - 25) * zoom;
    scale = width / duration;
    const tickTarget = 68 / scale;
    const power = Math.pow(10, Math.floor(Math.log10(Math.max(.001, tickTarget))));
    const step = [1, 2, 5, 10].map(v => v * power).find(v => v >= tickTarget) ?? power * 10;
    const tickCount = Math.min(500, Math.floor(duration / step));
    const ticks = Array.from({ length: tickCount + 1 }, (_, i) => `<span class="tl-tick" style="left:${axisInset + i * step * scale}px">${step < 1 ? number(i * step) : clock(i * step)}</span>`).join('');
    const cameraKeys = (property = '') => timeline.keys.map(k => {
      const index = state!.project.stops.findIndex(s => s.id === k.stopId), stop = state!.project.stops[index];
      return keyButton('camera', k.stopId, k.time, `${String(index + 1).padStart(2, '0')} ${stop?.name ?? 'Camera key'}`, cameraLocked(state!.project, k.stopId), true, property);
    }).join('');
    const clips = clipRanges(state.project).map(c => `<button type="button" class="tl-clip" style="left:${axisInset + c.start * scale}px;width:${Math.max(3, (c.end - c.start) * scale)}px" data-tl-action="selectClip" data-segment="${esc(c.id)}" data-testid="imported-camera-segment" aria-label="${esc(`Imported camera ${c.name}, ${number(c.end - c.start)} seconds, protected original timing`)}" title="${esc(`${c.name} · ${number(c.end - c.start)} s · original timing protected`)}"${unavailable() ? ' disabled' : ''}>${icon('lock')}<span>${esc(c.name)}</span><small>${number(c.end - c.start)} s · protected</small></button>`).join('');
    const row = (label: string, track: string, className = '', id = '') => `<div class="tl-row ${className}"${id ? ` data-layer-id="${esc(id)}"` : ''}><div class="tl-label">${label}</div><div class="tl-track" data-tl-track="true">${track}</div></div>`;
    rows.innerHTML = `<div class="tl-row tl-ruler-row"><div class="tl-label tl-ruler-label"><span>TRACK</span><span>KEY AT PLAYHEAD</span></div><div class="tl-track tl-ruler" data-tl-ruler="true" role="slider" tabindex="0" aria-label="Timeline playhead" aria-valuemin="0" aria-valuemax="${duration}" aria-valuenow="${state.time}" aria-valuetext="${timeLabel(state.time)}">${ticks}</div></div>` +
      row(`<button type="button" class="tl-group" data-tl-action="cameraGroup" aria-expanded="${cameraExpanded}" aria-label="${cameraExpanded ? 'Collapse' : 'Expand'} linked camera properties">${icon('down')}${icon('camera')}<strong>Camera</strong></button><span class="tl-linked" title="Position, orientation and lens share one key">Full pose</span>`, clips + cameraKeys(), 'tl-camera-row') +
      (cameraExpanded ? ['Position', 'Orientation', 'Lens'].map(property => row(`<span class="tl-property-name">${property}</span><span class="tl-linked">Linked</span>`, cameraKeys(property.toLowerCase()), 'tl-property-row')).join('') : '') +
      row(`${icon('layers')}<strong>Presentation layers</strong><span class="tl-layer-count">${state.project.layers.length}</span>`, `<span class="tl-track-note">${state.project.layers.length ? 'Show / hide keys · step changes' : 'Import a layered GLB to animate visibility.'}</span>`, 'tl-layer-group') +
      state.project.layers.map((layer, index) => {
        const keys = timeline.layers.find(l => l.layerId === layer.id)?.keys ?? [];
        let start = 0, visible = layer.defaultVisible;
        const intervals: string[] = [];
        for (const key of [...keys, { time: duration, visible: false }]) {
          if (visible && key.time > start) intervals.push(`<span class="tl-visible-span" style="left:${axisInset + start * scale}px;width:${(key.time - start) * scale}px"></span>`);
          start = key.time; visible = key.visible;
        }
        return row(`<button type="button" class="tl-layer-name" data-tl-action="selectLayer" data-layer="${esc(layer.id)}" title="${esc(layer.name)}"><span class="tl-layer-index">${String(index + 1).padStart(2, '0')}</span><span>${esc(layer.name)}</span></button><div class="tl-layer-key-controls"><button type="button" data-tl-action="layerShow" data-layer="${esc(layer.id)}" aria-label="Key show ${esc(layer.name)} at playhead" title="Add show key at playhead"${unavailable() || !layer.included ? ' disabled' : ''}>${icon('eye')}</button><button type="button" data-tl-action="layerHide" data-layer="${esc(layer.id)}" aria-label="Key hide ${esc(layer.name)} at playhead" title="Add hide key at playhead"${unavailable() || !layer.included ? ' disabled' : ''}>${icon('hide')}</button></div>`, intervals.join('') + keys.map(k => keyButton('layer', k.id, k.time, `${layer.name} · ${k.visible ? 'show' : 'hide'}`, false, k.visible)).join(''), `tl-layer-row${!layer.included ? ' excluded' : ''}`, layer.id);
      }).join('');
    content.style.width = `${labelWidth + width + 25}px`;
    root.style.setProperty('--tl-width', `${width + 25}px`);
    root.style.setProperty('--tl-grid', `${step * scale}px`);
    root.dataset.cameraExpanded = String(cameraExpanded);
    ruler = rows.querySelector<HTMLElement>('[data-tl-ruler]');
    layerRows = Array.from(rows.querySelectorAll<HTMLElement>('.tl-layer-row'));
    lastTimeSignature = '';
    lastLayerStates = '';
    applySelection(); updateTime();
    if (focusKey) Array.from(rows.querySelectorAll<HTMLButtonElement>('[data-key-id]')).find(el => el.dataset.keyId === focusKey && el.dataset.property === focusProperty)?.focus({ preventScroll: true });
    else if (focusAction) Array.from(rows.querySelectorAll<HTMLButtonElement>('[data-tl-action]')).find(el => el.dataset.tlAction === focusAction && el.dataset.layer === focusLayer)?.focus({ preventScroll: true });
  }

  function applySelection(): void {
    if (!state) return;
    rows.querySelectorAll<HTMLButtonElement>('[data-key-id]').forEach(button => {
      const chosen = (button.dataset.tlKey === 'camera' ? selection.cameraIds : selection.layerKeyIds).includes(button.dataset.keyId!);
      button.classList.toggle('selected', chosen); button.setAttribute('aria-pressed', String(chosen));
    });
    rows.querySelectorAll<HTMLElement>('.tl-layer-row').forEach(row => row.classList.toggle('selected-layer', row.dataset.layerId === state!.selectedLayer));
    const count = selection.cameraIds.length + selection.layerKeyIds.length;
    get('.tl-selection').textContent = count ? `${count} ${count === 1 ? 'key' : 'keys'} selected` : 'Full camera pose';
    const interpolation = get<HTMLSelectElement>('[data-tl-input="interpolation"]');
    const first = currentTimeline().keys.find(k => selection.cameraIds.includes(k.stopId));
    const values = currentTimeline().keys.filter(k => selection.cameraIds.includes(k.stopId)).map(k => k.interpolation);
    interpolation.value = new Set(values).size > 1 ? 'mixed' : first?.interpolation ?? 'legacy';
    interpolation.disabled = unavailable() || !first || selection.cameraIds.some(id => cameraLocked(state!.project, id));
    interpolation.title = new Set(values).size > 1 ? 'Mixed interpolation; choose a value for all selected camera keys' : 'Interpolation from the selected key to the next key';
    root.querySelectorAll<HTMLButtonElement>('[data-tl-action="copy"], [data-tl-action="delete"]').forEach(el => el.disabled = unavailable() || !hasSelection() || selection.cameraIds.some(id => cameraLocked(state!.project, id)));
  }

  function updateTime(): void {
    if (!state) return;
    const signature = `${state.time}|${state.duration}|${state.playing}|${state.reducedMotion}|${unavailable()}`;
    if (lastTimeSignature === signature && lastTimeProject === state.project) return;
    lastTimeSignature = signature; lastTimeProject = state.project;
    const timeline = currentTimeline();
    playhead.style.left = `${labelWidth + axisInset + state.time * scale}px`;
    ruler?.setAttribute('aria-valuenow', String(state.time)); ruler?.setAttribute('aria-valuetext', timeLabel(state.time));
    if (timeInput.max !== String(state.duration)) timeInput.max = String(state.duration);
    if (document.activeElement !== timeInput && timeInput.value !== number(state.time)) timeInput.value = number(state.time);
    if (currentTime.textContent !== clock(state.time)) currentTime.textContent = clock(state.time);
    if (totalTime.textContent !== clock(state.duration)) totalTime.textContent = clock(state.duration);
    if (timeRange.max !== String(Math.max(.01, state.duration))) timeRange.max = String(Math.max(.01, state.duration));
    if (document.activeElement !== timeRange && timeRange.value !== String(state.time)) timeRange.value = String(state.time);
    if (playButton.dataset.playing !== String(state.playing)) { playButton.innerHTML = icon(state.playing ? 'pause' : 'play'); playButton.dataset.playing = String(state.playing); playButton.setAttribute('aria-label', state.playing ? 'Pause presentation' : 'Play presentation'); }
    composeButton.disabled = unavailable() || state.playing;
    if (reducedMotionInput.checked !== state.reducedMotion) reducedMotionInput.checked = state.reducedMotion;
    const frameText = `${number(timeline.fps)} fps · frame ${Math.round(state.time * timeline.fps)}`;
    if (frameReadout.textContent !== frameText) frameReadout.textContent = frameText;
    const layerStates = state.project.layers.map(l => `${l.id}:${visibleAt(l.id)}`).join('|');
    if (layerStates !== lastLayerStates) {
      layerRows.forEach(row => {
        const visible = visibleAt(row.dataset.layerId!);
        row.querySelector('[data-tl-action="layerShow"]')?.setAttribute('aria-pressed', String(visible));
        row.querySelector('[data-tl-action="layerHide"]')?.setAttribute('aria-pressed', String(!visible));
      }); lastLayerStates = layerStates;
    }
  }

  function selectKey(button: HTMLElement, additive: boolean, toggle: boolean): void {
    const kind = button.dataset.tlKey!, id = button.dataset.keyId!;
    const list = kind === 'camera' ? selection.cameraIds : selection.layerKeyIds;
    if (!additive && !list.includes(id)) selection = { cameraIds: [], layerKeyIds: [] };
    const selected = kind === 'camera' ? selection.cameraIds : selection.layerKeyIds;
    if (toggle && selected.includes(id)) selected.splice(selected.indexOf(id), 1);
    else if (!selected.includes(id)) selected.push(id);
    applySelection();
    if (kind === 'camera') { previousSelected = id; actions.act('selectStop', id); }
    else { const layerId = button.closest<HTMLElement>('[data-layer-id]')?.dataset.layerId; if (layerId) actions.act('selectLayer', layerId); actions.act('time', keyTime(kind, id)); }
  }

  function seek(clientX: number): void {
    if (!state || unavailable()) return;
    const x = clientX - content.getBoundingClientRect().left - labelWidth - axisInset;
    const time = Math.max(0, Math.min(state.duration, x / scale));
    actions.act('time', snapping ? Math.min(state.duration, snapTime(time, currentTimeline().fps)) : time);
  }
  function pointerdown(event: PointerEvent): void {
    if (event.button === 0 && event.target instanceof Element && event.target.closest('.tl-resize-handle')) {
      event.preventDefault(); event.stopPropagation(); resizeHandle.focus({ preventScroll: true });
      setCollapsed(false); resizeDrag = { pointer: event.pointerId, y: event.clientY, height: expandedHeight };
      root.dataset.resizing = 'true'; resizeHandle.setPointerCapture(event.pointerId); return;
    }
    if (event.button !== 0 || !(event.target instanceof Element) || unavailable()) return;
    const key = event.target.closest<HTMLElement>('[data-tl-key]');
    if (key) {
      event.preventDefault(); event.stopPropagation(); key.focus({ preventScroll: true });
      selectKey(key, event.shiftKey || event.ctrlKey || event.metaKey, event.ctrlKey || event.metaKey);
      ignoreClickUntil = performance.now() + 250;
      if (selection.cameraIds.some(id => cameraLocked(state!.project, id))) { get('.tl-hint').textContent = 'Imported camera timing is protected. Select editable keys to retime.'; return; }
      const times = [...selection.cameraIds.map(id => keyTime('camera', id)), ...selection.layerKeyIds.map(id => keyTime('layer', id))];
      if (!times.length) return;
      drag = { pointer: event.pointerId, kind: 'key', x: event.clientX, activeTime: Number(key.dataset.time), delta: 0, moved: false, min: -Math.min(...times), max: state!.duration - Math.max(...times), selection: payload() };
    } else if (event.target.closest('[data-tl-track]') && !event.target.closest('.tl-clip') || event.target.closest('[data-tl-ruler]')) {
      event.preventDefault(); event.stopPropagation(); scroll.focus({ preventScroll: true }); seek(event.clientX);
      drag = { pointer: event.pointerId, kind: 'scrub', x: event.clientX, activeTime: 0, delta: 0, moved: false, min: 0, max: 0, selection: payload() };
    } else return;
    root.setPointerCapture(event.pointerId);
  }
  function pointermove(event: PointerEvent): void {
    if (resizeDrag?.pointer === event.pointerId) { event.preventDefault(); event.stopPropagation(); setHeight(resizeDrag.height + resizeDrag.y - event.clientY); return; }
    if (!drag || event.pointerId !== drag.pointer) return;
    event.preventDefault(); event.stopPropagation();
    if (drag.kind === 'scrub') { seek(event.clientX); return; }
    const raw = (event.clientX - drag.x) / scale;
    if (Math.abs(event.clientX - drag.x) < 3 && !drag.moved) return;
    const delta = snapping ? snapTime(drag.activeTime + raw, currentTimeline().fps) - drag.activeTime : raw;
    drag.delta = Math.max(drag.min, Math.min(drag.max, delta)); drag.moved = true;
    rows.querySelectorAll<HTMLElement>('[data-key-id]').forEach(el => {
      const selected = (el.dataset.tlKey === 'camera' ? drag!.selection.cameraIds : drag!.selection.layerKeyIds).includes(el.dataset.keyId!);
      if (selected) { el.style.transform = `translateX(${drag!.delta * scale}px)`; el.classList.add('dragging'); }
    });
    get('.tl-hint').textContent = `Move selected keys ${drag.delta >= 0 ? '+' : ''}${number(drag.delta)} s · Escape cancels`;
  }
  function finishDrag(commit: boolean): void {
    const finished = drag; if (!finished) return;
    drag = null; if (root.hasPointerCapture(finished.pointer)) root.releasePointerCapture(finished.pointer);
    rows.querySelectorAll<HTMLElement>('.dragging').forEach(el => { el.style.transform = ''; el.classList.remove('dragging'); });
    get('.tl-hint').textContent = 'Navigate → capture at playhead → refine';
    ignoreClickUntil = performance.now() + 250;
    if (commit && finished.kind === 'key' && finished.moved && Math.abs(finished.delta) > 1e-8) actions.act('moveTimelineKeys', { ...finished.selection, delta: finished.delta });
    if (project !== state?.project) { project = state?.project ?? null; renderRows(); }
  }
  function finishResize(event: PointerEvent): boolean {
    if (resizeDrag?.pointer !== event.pointerId) return false;
    event.stopPropagation(); resizeDrag = null; delete root.dataset.resizing;
    if (resizeHandle.hasPointerCapture(event.pointerId)) resizeHandle.releasePointerCapture(event.pointerId);
    setHeight(expandedHeight, true); return true;
  }
  function pointerup(event: PointerEvent): void { if (finishResize(event)) return; if (drag?.pointer === event.pointerId) { event.stopPropagation(); finishDrag(true); } }
  function pointercancel(event: PointerEvent): void { if (finishResize(event)) return; if (drag?.pointer === event.pointerId) finishDrag(false); }

  function click(event: MouseEvent): void {
    if (!(event.target instanceof Element)) return;
    const key = event.target.closest<HTMLElement>('[data-tl-key]');
    if (key) { event.stopPropagation(); if (performance.now() > ignoreClickUntil && !unavailable()) selectKey(key, event.shiftKey || event.ctrlKey || event.metaKey, event.ctrlKey || event.metaKey); return; }
    const target = event.target.closest<HTMLElement>('[data-tl-action]');
    if (!target) return;
    event.stopPropagation(); if (target instanceof HTMLButtonElement && target.disabled) return;
    const name = target.dataset.tlAction!;
    if (name === 'collapse') { setCollapsed(!collapsed); return; }
    if (name === 'cameraGroup') { cameraExpanded = !cameraExpanded; renderRows(); return; }
    if (unavailable()) return;
    if (name === 'play') actions.act(state!.playing ? 'pause' : 'play');
    else if (name === 'selectClip') { const segment = state!.project.segments.find(s => s.id === target.dataset.segment); if (segment) { actions.act('selectStop', segment.from); if (event.detail > 0) seek(event.clientX); } }
    else if (name === 'selectLayer') { selection = { cameraIds: [], layerKeyIds: [] }; applySelection(); actions.act('selectLayer', target.dataset.layer); }
    else if (name === 'copy' || name === 'delete') actions.act(name === 'copy' ? 'copyTimelineKeys' : 'deleteTimelineKeys', payload());
    else if (name === 'paste') actions.act('pasteTimelineKeys', { time: state!.time });
    else if (name === 'layerShow' || name === 'layerHide') {
      const layerId = target.dataset.layer!, at = snapping ? snapTime(state!.time, currentTimeline().fps) : state!.time;
      selection = { cameraIds: [], layerKeyIds: [] };
      actions.act('captureLayerKey', { layerId, time: at, visible: name === 'layerShow' });
      const key = currentTimeline().layers.find(l => l.layerId === layerId)?.keys.find(k => Math.abs(k.time - Math.min(at, state!.duration)) < 1e-7);
      if (key) selection.layerKeyIds = [key.id];
      applySelection(); actions.act('selectLayer', layerId);
    }
    else actions.act(name);
    target.closest<HTMLDetailsElement>('details')?.removeAttribute('open');
  }
  function change(event: Event): void {
    const input = event.target;
    if (!(input instanceof HTMLInputElement || input instanceof HTMLSelectElement) || !input.dataset.tlInput || !state) return;
    event.stopPropagation();
    const kind = input.dataset.tlInput;
    if (kind === 'snap') { snapping = (input as HTMLInputElement).checked; return; }
    if (kind === 'zoom') { zoom = Number(input.value); renderRows(); return; }
    if (unavailable() || !input.checkValidity()) { input.reportValidity(); return; }
    if (kind === 'time') actions.act('time', Math.max(0, Math.min(state.duration, Number(input.value))));
    if (kind === 'interpolation' && ['linear', 'ease', 'hold'].includes(input.value)) actions.act('setKeyInterpolation', { ids: [...selection.cameraIds], value: input.value });
    if (kind === 'fps' || kind === 'duration') actions.act('setTimelineOptions', { [kind]: Number(input.value) });
    if (kind === 'reducedMotion') actions.act('reducedMotion', (input as HTMLInputElement).checked);
  }
  function keydown(event: KeyboardEvent): void {
    if (event.target === resizeHandle && ['ArrowUp', 'ArrowDown', 'Home', 'End'].includes(event.key)) {
      event.preventDefault(); event.stopPropagation(); setCollapsed(false);
      const step = event.shiftKey ? 50 : 20;
      setHeight(event.key === 'Home' ? 140 : event.key === 'End' ? maximumHeight() : expandedHeight + (event.key === 'ArrowUp' ? step : -step), true); return;
    }
    if (event.key === 'Escape' && drag) { event.preventDefault(); event.stopPropagation(); finishDrag(false); return; }
    if (event.target instanceof Element && event.target.closest('input, select, textarea, summary') || unavailable()) return;
    const modified = event.ctrlKey || event.metaKey, key = event.key.toLowerCase();
    let handled = true;
    if (modified && key === 'c') actions.act('copyTimelineKeys', payload());
    else if (modified && key === 'v') actions.act('pasteTimelineKeys', { time: state!.time });
    else if (modified && key === 'z') actions.act(event.shiftKey ? 'redo' : 'undo');
    else if (modified && key === 'a') { const timeline = currentTimeline(); selection = { cameraIds: timeline.keys.map(k => k.stopId), layerKeyIds: timeline.layers.flatMap(l => l.keys.map(k => k.id)) }; applySelection(); }
    else if (event.key === 'Delete' || event.key === 'Backspace') { if (hasSelection()) actions.act('deleteTimelineKeys', payload()); }
    else if (event.key === 'ArrowLeft' || event.key === 'ArrowRight') actions.act('time', Math.max(0, Math.min(state!.duration, state!.time + (event.key === 'ArrowLeft' ? -1 : 1) * (event.shiftKey ? 10 : 1) / currentTimeline().fps)));
    else if (event.key === 'Home' || event.key === 'End') actions.act('time', event.key === 'Home' ? 0 : state!.duration);
    else if (event.key === ' ' && !(event.target instanceof HTMLButtonElement)) actions.act(state!.playing ? 'pause' : 'play');
    else handled = false;
    if (handled) { event.preventDefault(); event.stopPropagation(); }
  }
  function update(s: ViewState): void {
    state = s;
    const timeline = currentTimeline();
    if (project !== s.project) {
      selection.cameraIds = selection.cameraIds.filter(id => timeline.keys.some(k => k.stopId === id));
      selection.layerKeyIds = selection.layerKeyIds.filter(id => timeline.layers.some(l => l.keys.some(k => k.id === id)));
    }
    if (s.selectedStop !== previousSelected) { if (s.selectedStop && !selection.cameraIds.includes(s.selectedStop)) selection = { cameraIds: [s.selectedStop], layerKeyIds: [] }; previousSelected = s.selectedStop; }
    const disabled = unavailable(), signature = `${s.project.revision}|${s.selectedStop}|${s.selectedLayer}|${disabled}`;
    if (!drag && project !== s.project) {
      project = s.project; renderRows();
      const fps = get<HTMLSelectElement>('[data-tl-input="fps"]');
      if (![...fps.options].some(o => Number(o.value) === timeline.fps)) fps.add(new Option(`${number(timeline.fps)} fps`, String(timeline.fps)));
      fps.value = String(timeline.fps); get<HTMLInputElement>('[data-tl-input="duration"]').value = number(s.duration);
    }
    if (signature !== lastSignature && !drag) { applySelection(); lastSignature = signature; }
    if (disabled !== previousDisabled || root.dataset.disabled === undefined) {
      root.dataset.disabled = String(disabled);
      root.querySelectorAll<HTMLButtonElement | HTMLInputElement | HTMLSelectElement>('.tl-toolbar button:not(.tl-title), .tl-toolbar input, .tl-toolbar select').forEach(el => el.disabled = disabled);
      rows.querySelectorAll<HTMLButtonElement>('[data-tl-key], [data-tl-action="selectLayer"], [data-tl-action="layerShow"], [data-tl-action="layerHide"]').forEach(el => el.disabled = disabled || !!el.closest('.excluded'));
      previousDisabled = disabled; applySelection();
    }
    updateTime();
  }
  root.addEventListener('pointerdown', pointerdown); root.addEventListener('pointermove', pointermove); root.addEventListener('pointerup', pointerup); root.addEventListener('pointercancel', pointercancel);
  root.addEventListener('click', click); root.addEventListener('change', change); root.addEventListener('keydown', keydown);
  const observer = new ResizeObserver(() => { if (scroll.clientWidth !== lastScrollWidth) { lastScrollWidth = scroll.clientWidth; setHeight(expandedHeight); renderRows(); } }); observer.observe(scroll);
  root.addEventListener('dblclick', doubleclick); window.addEventListener('resize', resizeWindow); setHeight(expandedHeight);
  return { update, dispose() { observer.disconnect(); finishDrag(false); window.removeEventListener('resize', resizeWindow); root.removeEventListener('dblclick', doubleclick); root.removeEventListener('pointerdown', pointerdown); root.removeEventListener('pointermove', pointermove); root.removeEventListener('pointerup', pointerup); root.removeEventListener('pointercancel', pointercancel); root.removeEventListener('click', click); root.removeEventListener('change', change); root.removeEventListener('keydown', keydown); root.replaceChildren(); } };
}
