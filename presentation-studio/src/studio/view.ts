import type { Project, Vec3 } from '../core/model';
import { resolveLayer } from '../core/model';
import { Euler, Quaternion, Vector3 } from 'three';
import type { StudioActions, StudioView, ViewState } from './contracts';
import './style.css';
import { mountTimeline } from './timeline-view';
import { cameraLocked, timelineOf } from '../presentation/timeline';
import { FRAME_PRESETS, fitFrame } from '../render/framing';

const esc = (value: unknown) => String(value ?? '').replace(/[&<>"']/g, c => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[c]!));
const fmt = (value: number, digits = 2) => Number.isFinite(value) ? Number(value.toFixed(digits)).toString() : '0';
const checked = (value: boolean) => value ? ' checked' : '';
const disabled = (value: boolean) => value ? ' disabled' : '';
const selected = (value: boolean) => value ? ' selected' : '';
const icons: Record<string, string> = {
  leaf: '<path d="M19 4C10 3 4 7 5 13c1 6 8 7 12 1 2-3 2-7 2-10Z"/><path d="m5 20 9-11"/>',
  plus: '<path d="M12 5v14M5 12h14"/>',
  upload: '<path d="M12 16V3m-5 5 5-5 5 5M4 15v5h16v-5"/>',
  save: '<path d="M5 3h12l4 4v14H3V3h2Zm2 0v7h10V3M7 21v-7h10v7"/>',
  open: '<path d="M3 7V4h7l2 3h9v13H3V7Zm0 4h18"/>',
  export: '<path d="M14 3h7v7m0-7L10 14M10 3H3v18h18v-7"/>',
  undo: '<path d="m8 4-5 5 5 5M3 9h10a7 7 0 0 1 0 14"/>',
  redo: '<path d="m16 4 5 5-5 5m5-5H11a7 7 0 0 0 0 14"/>',
  eye: '<path d="M2 12s4-7 10-7 10 7 10 7-4 7-10 7S2 12 2 12Z"/><circle cx="12" cy="12" r="3"/>',
  cube: '<path d="m12 2 9 5v10l-9 5-9-5V7l9-5Zm0 10 9-5M12 12 3 7m9 5v10"/>',
  plan: '<path d="M3 3h18v18H3V3Zm0 7h10V3m0 7v11m0-6h8"/>',
  camera: '<path d="M3 7h4l2-3h6l2 3h4v14H3V7Z"/><circle cx="12" cy="13" r="4"/>',
  play: '<path d="m7 4 13 8-13 8V4Z"/>',
  pause: '<path d="M8 4v16M16 4v16"/>',
  reverse: '<path d="M17 4 4 12l13 8V4Z"/>',
  reset: '<path d="M4 4v6h6M4 10a8 8 0 1 1 0 5"/>',
  down: '<path d="m6 9 6 6 6-6"/>',
  up: '<path d="m6 15 6-6 6 6"/>',
  close: '<path d="m5 5 14 14M19 5 5 19"/>',
  trash: '<path d="M3 6h18M9 6V3h6v3M6 6l1 15h10l1-15M10 10v7m4-7v7"/>',
  layers: '<path d="m12 3 10 5-10 5L2 8l10-5ZM2 12l10 5 10-5M2 16l10 5 10-5"/>',
  image: '<rect x="3" y="3" width="18" height="18" rx="1"/><circle cx="8" cy="8" r="2"/><path d="m3 17 6-6 4 4 3-3 5 5"/>',
  check: '<path d="m5 12 4 4L19 6"/>',
};
const icon = (name: string) => `<svg aria-hidden="true" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.55" stroke-linecap="round" stroke-linejoin="round">${icons[name] ?? icons.leaf}</svg>`;
const action = (name: string, payload?: unknown) => `data-action="${esc(name)}"${payload === undefined ? '' : ` data-payload="${esc(JSON.stringify(payload))}"`}`;
const button = (label: string, name: string, options: { payload?: unknown; icon?: string; class?: string; disabled?: boolean; test?: string; title?: string } = {}) => `<button type="button" class="${esc(options.class ?? 'button')}" ${action(name, options.payload)}${disabled(!!options.disabled)}${options.test ? ` data-testid="${esc(options.test)}"` : ''}${options.title ? ` title="${esc(options.title)}"` : ''}>${options.icon ? icon(options.icon) : ''}<span>${esc(label)}</span></button>`;
const iconButton = (label: string, name: string, glyph: string, payload?: unknown, isDisabled = false) => `<button type="button" class="icon-button" ${action(name, payload)} aria-label="${esc(label)}" title="${esc(label)}"${disabled(isDisabled)}>${icon(glyph)}</button>`;
const textField = (label: string, value: string, scope: string, field: string, id = '') => `<label class="field"><span>${esc(label)}</span><input type="text" value="${esc(value)}" data-scope="${scope}" data-field="${field}" data-id="${esc(id)}" data-key="${scope}-${id}-${field}" maxlength="${field === 'caption' ? 2000 : 200}" /></label>`;
const numberField = (label: string, value: number, scope: string, field: string, id = '', min?: number, max?: number, step = 0.1) => `<label class="field"><span>${esc(label)}</span><input type="number" value="${fmt(value, 3)}" step="any" data-step="${step}"${min === undefined ? '' : ` min="${min}"`}${max === undefined ? '' : ` max="${max}"`} data-scope="${scope}" data-field="${field}" data-id="${esc(id)}" data-key="${scope}-${id}-${field}" /></label>`;
const checkField = (label: string, value: boolean, scope: string, field: string, id = '', note = '') => `<label class="check-field"><input type="checkbox"${checked(value)} data-scope="${scope}" data-field="${field}" data-id="${esc(id)}" data-key="${scope}-${id}-${field}" /><span>${esc(label)}${note ? `<small>${esc(note)}</small>` : ''}</span></label>`;
const vectorField = (label: string, values: readonly number[], scope: string, field: string, id: string, axes = ['X', 'Y', 'Z']) => `<fieldset class="vector-field"><legend>${esc(label)}</legend><div class="vector-inputs${values.length === 4 ? ' four' : ''}">${values.map((v, i) => `<label><span>${axes[i]}</span><input type="number" aria-label="${esc(`${label} ${axes[i]}`)}" step="any" value="${fmt(v, 3)}" data-original="${v}" data-scope="${scope}" data-vector="${field}" data-index="${i}" data-id="${esc(id)}" data-key="${scope}-${id}-${field}-${i}" /></label>`).join('')}</div></fieldset>`;

/** Reconcile generated chrome while keeping focused controls, the canvas and iframe alive. */
function patchMarkup(container: Element, html: string): void {
  const template = document.createElement('template'); template.innerHTML = html;
  const patch = (parent: Node, desired: Node[]) => {
    const old = Array.from(parent.childNodes);
    const used = new Set<Node>();
    desired.forEach((fresh, index) => {
      const key = fresh instanceof Element ? fresh.getAttribute('data-key') : null;
      let live: Node | undefined = key ? old.find(n => !used.has(n) && n instanceof Element && n.getAttribute('data-key') === key && n.nodeName === fresh.nodeName) : old[index];
      if (!live || used.has(live) || live.nodeType !== fresh.nodeType || live.nodeName !== fresh.nodeName || (live instanceof Element && live.hasAttribute('data-key') && live.getAttribute('data-key') !== key)) live = fresh.cloneNode(true);
      used.add(live);
      if (parent.childNodes[index] !== live) parent.insertBefore(live, parent.childNodes[index] ?? null);
      if (live instanceof Element && fresh instanceof Element) {
        const focused = document.activeElement === live;
        for (const attr of Array.from(live.attributes)) if (!fresh.hasAttribute(attr.name) && attr.name !== 'open' && !(focused && attr.name === 'value')) live.removeAttribute(attr.name);
        for (const attr of Array.from(fresh.attributes)) if (live.getAttribute(attr.name) !== attr.value && !(focused && attr.name === 'value') && attr.name !== 'open') live.setAttribute(attr.name, attr.value);
        if (live instanceof HTMLInputElement && fresh instanceof HTMLInputElement) {
          if (!focused && live.type !== 'file') live.value = fresh.value;
          if (live.type === 'checkbox') live.checked = fresh.checked;
        }
        patch(live, Array.from(fresh.childNodes));
        if (live instanceof HTMLSelectElement && fresh instanceof HTMLSelectElement && !focused) live.value = fresh.value;
      } else if (live.nodeType === Node.TEXT_NODE && live.textContent !== fresh.textContent) live.textContent = fresh.textContent;
    });
    for (const child of Array.from(parent.childNodes)) if (!used.has(child)) parent.removeChild(child);
  };
  patch(container, Array.from(template.content.childNodes));
}

export function mountStudio(root: HTMLElement, actions: StudioActions): StudioView {
  root.innerHTML = `
    <div class="studio" data-testid="studio" data-scene="closed" data-focus="false">
      <header class="app-header">
        <a class="brand" href="#" aria-label="Cyrus Presentation Studio">${icon('leaf')}<span>CYRUS</span></a>
        <details class="menu project-menu"><summary data-testid="project-menu">Project ${icon('down')}</summary><div class="menu-popover">${button('Open project…', 'fileOpen', { icon: 'open', test: 'open-project' })}${button('Save project', 'saveProject', { icon: 'save', test: 'save-project' })}<hr />${button('Import camera animation…', 'fileCamera', { icon: 'camera', test: 'import-camera-animation' })}<hr />${button('New project', 'newProject', { icon: 'plus' })}${button('Restore autosave', 'restoreAutosave', { icon: 'reset' })}</div></details>
        <div class="project-heading"><label class="sr-only" for="project-title">Project title</label><input id="project-title" data-testid="project-title" data-scope="title" placeholder="Untitled landscape" maxlength="200" /></div>
        <div class="history-controls"><button type="button" class="icon-button" data-action="undo" data-testid="undo" aria-label="Undo" title="Undo">${icon('undo')}</button><button type="button" class="icon-button" data-action="redo" data-testid="redo" aria-label="Redo" title="Redo">${icon('redo')}</button></div>
        <span class="header-separator"></span>
        <button type="button" class="button chrome-button" data-action="uiScene" data-testid="scene-toggle" aria-pressed="false">${icon('layers')}<span>Scene</span></button>
        <button type="button" class="button chrome-button" data-action="uiFocus" data-testid="focus-view" aria-pressed="false" title="Focus on the viewport">${icon('eye')}<span>Focus</span></button>
        <details class="menu output-menu"><summary data-testid="output-menu">Output ${icon('down')}</summary><div class="menu-popover">${button('Compiled preview', 'preview', { icon: 'play', test: 'preview-export' })}${button('Export website', 'exportWebsite', { icon: 'export', test: 'export-website' })}</div></details>
      </header>
      <div class="camera-authoring" id="camera-authoring" aria-label="Viewport camera authoring"></div>
      <div class="workspace">
        <aside class="hierarchy-panel" aria-label="Scene hierarchy"><div class="panel-heading"><h2>Scene</h2><span class="panel-count" id="scene-count">0 assets</span></div><div id="hierarchy-body"></div></aside>
        <main class="stage" aria-label="Landscape viewport">
          <div class="viewport" data-testid="viewport" tabindex="0" aria-label="Landscape camera viewport. Drag to look, WASD to move."><div class="safe-frame-overlay" data-testid="safe-frame-overlay" aria-hidden="true" hidden><div class="safe-output-frame" data-testid="safe-output-frame"><div class="safe-action-guide"><span>Action safe · 90%</span></div><div class="safe-title-guide"><span>Title safe · 80%</span></div><span class="safe-frame-label"></span></div></div></div>
          <iframe class="compiled-preview" title="Compiled public presentation preview" hidden></iframe>
          <div class="empty-stage" id="empty-stage"><div class="empty-mark">${icon('leaf')}</div><h1>A new perspective.</h1><p>Bring in your landscape, find a view,<br />and capture it as a camera keyframe.</p><div>${button('Import landscape', 'fileGLB', { icon: 'upload', class: 'button primary' })}${button('Explore the sample', 'demo', { class: 'button subtle' })}</div><small>Self-contained GLB · Metric scale · Layered scenes</small></div>
          <div class="job-overlay" id="job-overlay" hidden><span class="spinner" aria-hidden="true"></span><span>Preparing…</span>${button('Cancel', 'cancelJob', { class: 'button subtle small' })}</div>
        </main>
        <aside class="inspector-panel" aria-label="Selection inspector"><div class="panel-heading"><h2 id="inspector-type">Camera</h2><span class="panel-caption">Compose your view</span></div><div id="inspector-tabs" class="inspector-tabs" role="group" aria-label="Inspector selection"></div><div id="camera-settings"></div><div id="inspector-body"></div><div id="presentation-settings"></div></aside>
      </div>
      <footer class="animation-timeline" aria-label="Animation timeline" data-testid="animation-timeline"></footer>
      <div class="status-bar"><div class="status-main"><span class="status-dot" id="status-dot"></span><span data-testid="status" id="status" role="status" aria-live="polite">Ready to compose</span><span data-testid="error" id="error" class="error-message" role="alert" hidden></span></div><span id="storage-status">Local autosave</span><details class="menu stats-menu"><summary aria-label="Rendering statistics" title="Rendering statistics">${icon('cube')}</summary><div class="menu-popover" id="resource-stats">0 draws · 0 triangles</div></details></div>
      <div id="replacement-root"></div>
      <div id="camera-import-root"></div>
      <div class="file-inputs"><input type="file" id="file-glb" aria-label="Import landscape GLB" data-testid="import-glb" accept=".glb" /><input type="file" id="file-replace" aria-label="Replace selected landscape GLB" accept=".glb" /><input type="file" id="file-open" aria-label="Open project archive" accept=".zip,.cyrus,.cyrusp,.cyrus-project" /><input type="file" id="file-camera" aria-label="Import camera animation" accept=".json,.cyrus-camera" /><input type="file" id="file-plan" aria-label="Import plan image" accept="image/png,image/jpeg,image/webp" /><input type="file" id="file-photo" aria-label="Import artistic photo" accept="image/png,image/jpeg,image/webp" /></div>
    </div>`;
  const query = <T extends Element = HTMLElement>(selector: string) => root.querySelector<T>(selector)!;
  const animationTimeline = mountTimeline(query('.animation-timeline'), { act(name, payload) {
    if (name === 'selectLayer' || name === 'selectStop') {
      inspector = name === 'selectLayer' ? 'layer' : 'stop'; showingPlan = false; previousChrome = '';
    }
    actions.act(name, payload);
    if (name === 'selectLayer' || name === 'selectStop') refreshChrome();
  } });
  const viewport = query<HTMLElement>('.viewport'), preview = query<HTMLIFrameElement>('.compiled-preview');
  const studioElement = query<HTMLElement>('.studio'), stage = query<HTMLElement>('.stage'), statusBar = query<HTMLElement>('.status-bar');
  const statusElement = query('#status'), errorElement = query<HTMLElement>('#error'), statusDot = query('#status-dot');
  const storageElement = query('#storage-status'), statsElement = query('#resource-stats');
  const sceneToggle = query('[data-testid="scene-toggle"]'), focusToggle = query('[data-testid="focus-view"]');
  const safeOverlay = query<HTMLElement>('.safe-frame-overlay'), outputFrame = query<HTMLElement>('.safe-output-frame'), frameLabel = query('.safe-frame-label');
  let previousFrameGeometry = '', previousFrameState = '', previousStatusHeight = -1;
  const statusObserver = new ResizeObserver(() => {
    const height = Math.ceil(statusBar.getBoundingClientRect().height);
    if (height !== previousStatusHeight) { previousStatusHeight = height; studioElement.style.setProperty('--status-height', `${height}px`); }
  });
  statusObserver.observe(statusBar);
  const frameObserver = new ResizeObserver(() => layoutFraming());
  frameObserver.observe(stage); frameObserver.observe(viewport);
  let current: ViewState | null = null;
  let previousProject: Project | null = null;
  let previousChrome = '';
  let inspector: 'layer' | 'instance' | 'stop' = 'stop';
  let selectedSnapshot = '';
  let importUnits = 1, importUp = 'Y', portraitPhoto = false;
  let replacementInstance = '';
  let photoStopId = '', photoPortrait = false;
  let replacementSignature = '';
  let cameraImportSignature = '';
  let sceneOpen = false, focusView = false;
  let nodeFilter = '', nodePage = 0;
  let replacementFilter = '', previousNodeFilter = '', replacementPage = 0;
  let beforeDialog: HTMLElement | null = null;
  let beforeCameraDialog: HTMLElement | null = null;
  let cameraImportTrigger: HTMLElement | null = null;
  let reviewMappings: Record<string, string> = {}, reviewAssignments: Record<string, string> = {};
  const lookTargets = new Map<string, Vec3>();
  const narrowScreens = window.matchMedia('(max-width: 900px)');
  const pageSize = () => narrowScreens.matches ? 10 : 60;
  const pager = (page: number, total: number, name: string) => total > pageSize() ? `<div class="node-pagination">${button('Previous', name, { payload: page - 1, class: 'text-button', disabled: page === 0 })}<span>${page * pageSize() + 1}–${Math.min((page + 1) * pageSize(), total)} of ${total}</span>${button('Next', name, { payload: page + 1, class: 'text-button', disabled: (page + 1) * pageSize() >= total })}</div>` : '';

  const fileButton = (label: string, kind: string, glyph: string, busy = false, small = false) => button(label, kind, { icon: glyph, disabled: busy, class: `button ${small ? 'subtle small' : 'subtle full'}` });

  function layoutFraming(): void {
    const portrait = current?.framing === 'portrait' && (current.mode === 'playback' || current.mode === 'preview');
    const framing = portrait ? 'portrait' : 'full';
    if (stage.dataset.framing !== framing) stage.dataset.framing = framing;
    if (portrait) {
      const width = Math.min(Math.max(1, stage.clientWidth - 24), Math.max(1, stage.clientHeight - 24) * 9 / 16);
      if (stage.style.getPropertyValue('--frame-width') !== `${width}px`) stage.style.setProperty('--frame-width', `${width}px`);
      if (stage.style.getPropertyValue('--frame-height') !== `${width * 16 / 9}px`) stage.style.setProperty('--frame-height', `${width * 16 / 9}px`);
    }
    const visible = !!current?.safeFrame && current.mode !== 'plan' && current.mode !== 'preview';
    if (safeOverlay.hidden === visible) safeOverlay.hidden = !visible;
    if (!visible || !current) return;
    const width = viewport.clientWidth, height = viewport.clientHeight;
    if (!width || !height) return;
    const signature = `${width}|${height}|${current.effectiveFrameAspect}|${current.framePreset}|${current.mode}`;
    if (signature === previousFrameGeometry) return;
    previousFrameGeometry = signature;
    const frame = fitFrame(width, height, current.effectiveFrameAspect ?? width / height);
    outputFrame.style.left = `${frame.x}px`; outputFrame.style.top = `${frame.y}px`;
    outputFrame.style.width = `${frame.width}px`; outputFrame.style.height = `${frame.height}px`;
    const preset = FRAME_PRESETS.find(p => p.id === current!.framePreset);
    const label = current.mode === 'playback' ? 'Saved camera frame' : preset?.label ?? 'Viewport';
    frameLabel.textContent = `${label} · ${fmt(current.effectiveFrameAspect ?? width / height, 3)}:1`;
  }

  function cameraAuthoring(s: ViewState): string {
    const isExplore = s.mode === 'explore';
    const editing = s.cameraSession === 'edit' && !s.project.segments.some(segment => segment.cameraClip && (segment.from === s.cameraEditingStopId || segment.to === s.cameraEditingStopId)) ? s.project.stops.find(stop => stop.id === s.cameraEditingStopId) : undefined;
    const importedTrack = s.mode === 'playback' ? s.project.segments.find(segment => segment.cameraClip)?.cameraClip : undefined;
    const mode = isExplore ? s.navigationMode : s.mode;
    const cameraControls = isExplore && s.navigationMode === 'camera';
    const reviewing = (isExplore && s.navigationMode === 'orbit') || s.mode === 'plan';
    const frameMenu = `<details class="menu frame-menu" data-key="frame-menu"><summary data-testid="frame-menu" title="Output composition and safe guides">Frame ${icon('down')}</summary><div class="menu-popover"><label class="field"><span>Composition aspect</span><select data-scope="framePreset" aria-label="Composition aspect" data-testid="frame-preset"${disabled(s.pending)}>${FRAME_PRESETS.map(p => `<option value="${p.id}"${selected(s.framePreset === p.id)}>${esc(p.label)}</option>`).join('')}</select></label><label class="check-field"><input type="checkbox" data-scope="safeFrame" data-testid="safe-frame-toggle"${checked(s.safeFrame)} /><span>Safe frame guides<small>90% action · 80% title</small></span></label><p class="field-note">Applies when composing. Playback follows the saved camera frame.</p></div></details>`;
    const gestures = cameraControls ? '<dt>Look</dt><dd>Left / right drag</dd><dt>Pan</dt><dd>Middle / Shift + left drag</dd><dt>Move in / out</dt><dd>Mouse wheel</dd><dt>Move</dt><dd><kbd>W A S D</kbd></dd><dt>Height</dt><dd><kbd>Q / E</kbd></dd><dt>Faster</dt><dd><kbd>Shift</kbd></dd><dt>Release</dt><dd><kbd>Esc</kbd></dd>' : s.mode === 'plan' ? '<dt>Pan</dt><dd>Left / right drag</dd><dt>Zoom</dt><dd>Mouse wheel / middle drag</dd>' : isExplore ? '<dt>Orbit</dt><dd>Left drag</dd><dt>Pan</dt><dd>Right / Shift + left drag</dd><dt>Zoom</dt><dd>Mouse wheel / middle drag</dd>' : '<dt>Review</dt><dd>Use the timeline and Play controls.</dd>';
    return `<label class="viewport-mode"><span class="sr-only">Viewport mode</span><select data-scope="viewportMode" aria-label="Viewport mode" data-testid="viewport-mode"${disabled(s.pending)}><option value="camera"${selected(mode === 'camera')}>Camera</option><option value="orbit"${selected(mode === 'orbit')}>Orbit</option><option value="plan"${selected(mode === 'plan')}>Plan</option><option value="playback"${selected(mode === 'playback')}>Playback</option>${s.mode === 'preview' ? '<option value="preview" selected>Compiled preview</option>' : ''}</select></label><span class="camera-session" data-testid="camera-session">${reviewing && s.playing ? `<span class="session-dot"></span><strong>${s.mode === 'plan' ? 'Plan' : 'Orbit'} review</strong>` : editing ? `<span class="session-dot"></span>Editing <strong>${esc(editing.name)}</strong>` : importedTrack ? `<span class="session-dot"></span>Imported <strong>${esc(importedTrack.name)}</strong>` : '<span class="session-dot"></span>New view'}</span>${frameMenu}<details class="menu controls-menu"><summary title="Viewport controls">Controls ${icon('down')}</summary><div class="menu-popover"><strong>${isExplore && s.navigationMode === 'camera' ? 'Navigate as the camera' : s.mode === 'plan' ? 'Orient the plan' : 'Viewport controls'}</strong><p>${isExplore && s.navigationMode === 'camera' ? 'Drag to look, pan to reposition, and scroll to move through the scene.' : s.mode === 'plan' ? 'Drag to pan. Scroll to zoom.' : 'Drag to orbit. Scroll to zoom.'}</p><dl>${gestures}</dl><p class="field-note">Capture and Save store the current perspective frame.</p></div></details><div class="camera-commit">${s.mode === 'preview' ? button('Close preview', 'closePreview', { icon: 'close', class: 'button subtle small', test: 'close-preview' }) : `${button(editing ? 'Save view' : 'Capture view', editing ? 'updateFromView' : 'captureStop', { payload: editing?.id, icon: editing ? 'save' : 'camera', class: 'button primary small', test: 'camera-primary-action', disabled: !isExplore || s.pending || s.playing })}<details class="menu camera-action-menu"><summary data-testid="camera-action-menu" aria-label="Camera action options"${s.pending ? ' aria-disabled="true"' : ''}>${icon('down')}</summary><div class="menu-popover">${button('Capture as new view', 'captureStop', { icon: 'plus', test: 'capture-new-view', disabled: !isExplore || s.pending || s.playing })}${editing ? button('Finish editing', 'finishCameraEdit', { icon: 'check', disabled: s.pending }) : ''}</div></details>`}</div>`;
  }

  function cameraSettings(s: ViewState): string {
    return `<section class="live-camera-settings"><div class="section-heading"><h3>Viewport camera</h3><span>${s.mode === 'explore' ? 'Live' : s.mode === 'plan' ? 'Plan' : 'Playback'}</span></div><div class="field-grid"><label class="field"><span>Field of view · °</span><input type="number" aria-label="Viewport camera field of view in degrees" data-scope="cameraFov" data-key="viewport-camera-fov" min="10" max="110" step="any" data-step="1" value="${fmt(s.cameraFov, 3)}"${disabled(s.mode !== 'explore' || s.pending)} /></label><label class="field"><span>Move speed · m/s</span><input type="number" aria-label="Camera movement speed in metres per second" data-scope="cameraSpeed" data-key="viewport-camera-speed" min="0.1" max="100" step="any" data-step="0.1" value="${fmt(s.cameraSpeed, 3)}"${disabled(s.pending)} /></label></div><label class="field framing-field"><span>Presentation frame</span><select aria-label="Presentation preview framing" data-scope="framing"><option value="auto"${selected(s.framing === 'auto')}>Automatic</option><option value="landscape"${selected(s.framing === 'landscape')}>Desktop · landscape</option><option value="portrait"${selected(s.framing === 'portrait')}>Mobile · portrait</option></select></label></section>`;
  }

  function hierarchy(s: ViewState): string {
    const p = s.project;
    return `<section class="hierarchy-section"><div class="section-heading"><h2>Scene assets</h2><span>${p.instances.length.toString().padStart(2, '0')}</span></div>
      ${p.instances.length ? `<div class="asset-list">${p.instances.map(i => {
        const asset = p.assets.find(a => a.revisionId === i.assetRevision);
        return `<button type="button" class="asset-row${s.selectedInstance === i.id ? ' selected' : ''}" ${action('selectInstance', i.id)} data-key="asset-${esc(i.id)}" aria-pressed="${s.selectedInstance === i.id}">${icon('cube')}<span><strong>${esc(i.name)}</strong><small>${asset ? `${fmt(asset.triangles, 0)} triangles` : 'Missing asset'}</small></span>${icon('down')}</button>`;
      }).join('')}</div>` : '<p class="section-empty">Import a landscape or a prepared asset to begin.</p>'}
      ${fileButton('Import landscape GLB', 'fileGLB', 'upload', s.pending)}
      <details class="import-options"><summary>Import orientation &amp; units</summary><div class="field-grid"><label class="field"><span>Source units</span><select data-local="units" aria-label="GLB source units"><option value="1"${selected(importUnits === 1)}>Metres</option><option value="0.01"${selected(importUnits === 0.01)}>Centimetres</option><option value="0.001"${selected(importUnits === 0.001)}>Millimetres</option><option value="0.3048"${selected(importUnits === 0.3048)}>Feet</option></select></label><label class="field"><span>Source up</span><select data-local="up" aria-label="GLB source up axis"><option value="Y"${selected(importUp === 'Y')}>Y up</option><option value="Z"${selected(importUp === 'Z')}>Z up</option></select></label></div><p class="field-note">Converted once at import. The project uses metres and Y up.</p></details>
      </section><section class="hierarchy-section"><div class="section-heading"><h2>Presentation layers</h2>${icon('layers')}</div><div data-testid="layer-list" class="layer-list">${p.layers.length ? p.layers.map((layer, index) => `<div class="layer-row${s.selectedLayer === layer.id ? ' selected' : ''}${!layer.included ? ' excluded' : ''}" data-key="layer-${esc(layer.id)}"><label class="layer-visibility" title="Initial visibility"><input type="checkbox" aria-label="Show ${esc(layer.name)} initially"${checked(layer.defaultVisible)} data-scope="layer" data-field="defaultVisible" data-id="${esc(layer.id)}" />${icon('eye')}</label><button type="button" ${action('selectLayer', layer.id)} aria-pressed="${s.selectedLayer === layer.id}"><span class="layer-index">${(index + 1).toString().padStart(2, '0')}</span><span class="layer-name">${esc(layer.name)}</span>${layer.viewerToggle ? '<span class="viewer-mark" title="Viewer can toggle this layer">V</span>' : ''}</button></div>`).join('') : '<p class="section-empty">Layers follow your imported groups. You can refine their assignments.</p>'}</div>${p.layers.length ? `<div class="layer-actions">${button('Show all initially', 'showAll', { class: 'text-button' })}${s.selectedLayer ? button('Isolate initially', 'isolateLayer', { payload: s.selectedLayer, class: 'text-button' }) : ''}</div>` : ''}</section>
      <section class="hierarchy-section plan-section"><div class="section-heading"><h2>Architectural plan</h2>${icon('plan')}</div>${p.plan ? `<div class="plan-summary">${icon('image')}<span>Calibrated plan<small>${p.plan.width} × ${p.plan.height} px</small></span><button type="button" class="text-button" data-action="uiPlan">Edit</button></div>` : '<p class="section-empty">Add a plan image for the opening and top-down composition.</p>'}${fileButton(p.plan ? 'Replace plan image' : 'Import plan image', 'filePlan', 'upload', s.pending, true)}${p.plan ? button('Remove plan', 'removePlan', { class: 'text-button danger' }) : ''}</section>
      <div class="sidebar-note"><span class="admin-dot"></span><span>Local studio <strong>· Admin workspace</strong></span></div>`;
  }

  function layerInspector(s: ViewState): string {
    const l = s.project.layers.find(x => x.id === s.selectedLayer);
    if (!l) return emptyInspector('layers', 'Choose a layer', 'Select a presentation layer to adjust its visibility and reveal.');
    const index = s.project.layers.indexOf(l);
    return `<div class="selection-heading"><span class="selection-kind">LAYER ${String(index + 1).padStart(2, '0')}</span><h2>${esc(l.name)}</h2><div>${iconButton('Move layer up', 'moveLayer', 'up', { id: l.id, direction: -1 }, index === 0)}${iconButton('Move layer down', 'moveLayer', 'down', { id: l.id, direction: 1 }, index === s.project.layers.length - 1)}</div></div>${textField('Layer name', l.name, 'layer', 'name', l.id)}<div class="check-group">${checkField('Include in published presentation', l.included, 'layer', 'included', l.id)}${checkField('Initially visible', l.defaultVisible, 'layer', 'defaultVisible', l.id)}${checkField('Allow visitors to show or hide', l.viewerToggle, 'layer', 'viewerToggle', l.id, 'Changes in the player last for that visit.')}</div>${numberField('Reveal position · 0 to 1', l.reveal, 'layer', 'reveal', l.id, 0, 1, 0.05)}${numberField('Reveal transition · %', (l.fade ?? 0.12) * 100, 'layerFade', 'fade', l.id, 0, 100, 1)}<p class="field-note">Initial visibility applies until the first show or hide key. Transition is the share of the landscape reveal used to dissolve this layer into view. Set 0% for an immediate reveal. Layers keep their own visibility through import, playback and export; revealing them does not change their geometry.</p>${button('Isolate initially', 'isolateLayer', { payload: l.id, icon: 'eye', class: 'button subtle full' })}`;
  }

  function instanceInspector(s: ViewState): string {
    const i = s.project.instances.find(x => x.id === s.selectedInstance);
    if (!i) return emptyInspector('cube', 'Choose an asset', 'Select an imported asset to place it or map its nodes to layers.');
    const a = s.project.assets.find(x => x.revisionId === i.assetRevision);
    const rotation = new Euler().setFromQuaternion(new Quaternion(...i.transform.rotation).normalize(), 'YXZ');
    const rotationDegrees = [rotation.x, rotation.y, rotation.z].map(v => v * 180 / Math.PI);
    const nodes = a?.nodes.filter(n => `${n.name} ${n.path}`.toLocaleLowerCase().includes(nodeFilter.toLocaleLowerCase())) ?? [];
    nodePage = Math.min(nodePage, Math.max(0, Math.ceil(nodes.length / pageSize()) - 1));
    return `<div class="selection-heading"><span class="selection-kind">IMPORTED ASSET</span><h2>${esc(i.name)}</h2></div>${textField('Asset name', i.name, 'instance', 'name', i.id)}${vectorField('Position · metres', i.transform.position, 'instance', 'position', i.id)}${vectorField('Rotation · degrees', rotationDegrees, 'instanceEuler', 'rotationDegrees', i.id)}${numberField('Uniform scale', i.transform.scale, 'instance', 'scale', i.id, 0.00001, 100000, 0.01)}<details class="advanced-fields"><summary>Advanced rotation · quaternion</summary>${vectorField('Rotation', i.transform.rotation, 'instance', 'rotation', i.id, ['X', 'Y', 'Z', 'W'])}</details><div class="inspector-divider"></div><div class="section-heading"><h3>Node assignments</h3><span>${a?.nodes.length ?? 0}</span></div><p class="field-note">Child assignments override inherited group assignments. ${narrowScreens.matches ? 'Showing 10 nodes per page; search to find a specific group.' : ''}</p><label class="field"><span>Find a node</span><input type="search" data-local="nodeFilter" data-key="node-filter" value="${esc(nodeFilter)}" placeholder="Name or hierarchy path" /></label><div class="node-list">${nodes.slice(nodePage * pageSize(), (nodePage + 1) * pageSize()).map(n => {
      const effective = resolveLayer(n.key, a!, i);
      return `<label class="node-row" data-key="node-${esc(i.id)}-${esc(n.key)}"><span title="${esc(n.path)}">${n.parent ? '<i aria-hidden="true">↳</i>' : icon('layers')}<span>${esc(n.name || 'Unnamed node')}<small>${n.renderable ? 'Mesh' : 'Group'}${i.membership[n.key] ? '' : ' · inherited'}</small></span></span><select aria-label="Layer for ${esc(n.name)}" data-scope="node" data-id="${esc(i.id)}" data-node="${esc(n.key)}"><option value=""${selected(!i.membership[n.key])}>Inherit${effective ? ` · ${esc(s.project.layers.find(l => l.id === effective)?.name)}` : ''}</option>${s.project.layers.map(l => `<option value="${esc(l.id)}"${selected(i.membership[n.key] === l.id)}>${esc(l.name)}</option>`).join('')}</select></label>`;
    }).join('') || '<p class="section-empty">No matching nodes.</p>'}</div>${pager(nodePage, nodes.length, 'uiNodePage')}${a?.warnings.length ? `<div class="import-report"><strong>Import notes</strong><ul>${a.warnings.map(w => `<li>${esc(w)}</li>`).join('')}</ul></div>` : ''}<div class="inspector-divider"></div>${fileButton('Replace GLB…', 'fileReplace', 'upload', s.pending)}<p class="field-note">The current scene stays in place until you review and confirm the replacement.</p>${button('Remove asset', 'removeInstance', { payload: i.id, icon: 'trash', class: 'button danger subtle full', disabled: s.pending })}`;
  }

  const emptyInspector = (glyph: string, title: string, body: string) => `<div class="empty-inspector">${icon(glyph)}<h2>${esc(title)}</h2><p>${esc(body)}</p></div>`;

  function cameraAnimationBlock(segment: Project['segments'][number], pending: boolean): string {
    const clip = segment.cameraClip!;
    return `<section class="camera-animation-block" data-testid="imported-camera-track"><div class="animation-label">${icon('camera')}<span>Imported motion</span><span class="preserved-mark">Preserved</span></div><h3>${esc(clip.name)}</h3><p class="animation-facts">${fmt(clip.duration, 3)} s <span>·</span> ${fmt(clip.fps, 3)} fps <span>·</span> ${clip.sampleCount.toLocaleString()} samples</p><p class="field-note">Original movement, lens and timing are kept. Use the timeline to choose a frame.</p>${button('Use frame in viewport', 'animationFrameToViewport', { icon: 'camera', class: 'button subtle full', test: 'animation-frame-to-viewport', disabled: pending })}<details class="animation-options" data-key="animation-options-${esc(segment.id)}"><summary>Animation options ${icon('down')}</summary><div>${button('Replace import…', 'fileCamera', { icon: 'upload', class: 'text-button', test: 'replace-camera-animation', disabled: pending })}${button('Remove animation', 'removeCameraAnimation', { payload: segment.id, icon: 'trash', class: 'text-button danger', test: 'remove-camera-animation', disabled: pending })}<p class="field-note">Removing the animation leaves these endpoint views as an editable straight path. You can undo this.</p></div></details></section>`;
  }

  function stopInspector(s: ViewState): string {
    const stop = s.project.stops.find(x => x.id === s.selectedStop);
    if (!stop) return emptyInspector('camera', s.project.stops.length ? 'Compose a camera view' : 'Find your first view', s.project.stops.length ? 'Select a saved view below to refine it, or navigate and capture a new view.' : 'Navigate in the viewport, then choose Capture view.');
    const index = s.project.stops.indexOf(stop), seg = s.project.segments[index];
    const key = timelineOf(s.project).keys.find(k => k.stopId === stop.id);
    const imported = s.project.segments.find(segment => segment.cameraClip && (segment.from === stop.id || segment.to === stop.id));
    const forward = new Vector3(0, 0, -1).applyQuaternion(new Quaternion(...stop.quaternion).normalize()).normalize();
    let target = lookTargets.get(stop.id);
    if (!target || new Vector3(...target).sub(new Vector3(...stop.position)).normalize().dot(forward) < 0.999999) target = new Vector3(...stop.position).addScaledVector(forward, 10).toArray() as Vec3;
    lookTargets.set(stop.id, target);
    const editingThis = !imported && s.cameraSession === 'edit' && s.cameraEditingStopId === stop.id;
    const viewFields = `${textField('View name', stop.name, 'stop', 'name', stop.id)}<div class="saved-view-timing"><label class="field"><span>Key time · seconds</span><input type="number" aria-label="Camera key time in seconds" data-scope="cameraKeyTime" data-id="${esc(stop.id)}" data-key="key-time-${esc(stop.id)}" min="0" max="${s.duration}" step="any" value="${fmt(key?.time ?? 0, 3)}"${disabled(!!imported || s.pending)} /></label>${imported ? '<span class="editing-indicator imported-indicator">Protected camera</span>' : editingThis ? '<span class="editing-indicator">Editing in viewport</span>' : button('Edit in viewport', 'editCameraStop', { payload: stop.id, icon: 'camera', class: 'button subtle small', test: 'edit-camera-stop', disabled: s.pending || s.mode === 'preview' })}</div><label class="field key-time-interpolation"><span>Motion to next key</span><select aria-label="Camera key interpolation" data-scope="cameraKeyInterpolation" data-id="${esc(stop.id)}"${disabled(!!imported || s.pending)}><option value="legacy"${selected(key?.interpolation === 'legacy')}>Preserved path</option><option value="linear"${selected(key?.interpolation === 'linear')}>Linear</option><option value="ease"${selected(key?.interpolation === 'ease')}>Ease</option><option value="hold"${selected(key?.interpolation === 'hold')}>Hold</option></select></label>`;
    const cameraFields = imported ? `<details class="inspector-section camera-details" data-key="camera-details-${esc(stop.id)}"><summary>Endpoint camera <span>Read only</span></summary><dl class="readonly-camera"><div><dt>Field of view</dt><dd>${fmt(stop.fov, 3)}°</dd></div><div><dt>Frame aspect</dt><dd>${fmt(stop.aspect, 3)}</dd></div><div class="full"><dt>Position · metres</dt><dd>${stop.position.map(v => fmt(v, 3)).join(' · ')}</dd></div><div class="full"><dt>Orientation · quaternion</dt><dd>${stop.quaternion.map(v => fmt(v, 3)).join(' · ')}</dd></div></dl><p class="field-note">This endpoint follows the imported animation. Remove the animation to edit its camera or add portrait framing.</p></details>` : `<details class="inspector-section camera-details" data-key="camera-details-${esc(stop.id)}"><summary>Advanced camera</summary>${numberField('Saved field of view · °', stop.fov, 'stop', 'fov', stop.id, 10, 110, 1)}${numberField('Frame aspect', stop.aspect, 'stop', 'aspect', stop.id, 0.3, 4, 0.01)}${vectorField('Camera position · metres', stop.position, 'stop', 'position', stop.id)}${vectorField('Look target · world metres', target, 'lookTarget', 'target', stop.id)}${vectorField('Orientation', stop.quaternion, 'stop', 'quaternion', stop.id, ['X', 'Y', 'Z', 'W'])}</details><details class="inspector-section"><summary>Portrait framing <span>${stop.portrait ? 'Authored' : 'Optional'}</span></summary><p class="field-note">Capture an explicit perspective view for narrow screens. Desktop framing stays separate.</p>${button(stop.portrait ? 'Update portrait from view' : 'Capture portrait from view', 'capturePortrait', { payload: stop.id, icon: 'camera', class: 'button subtle full', disabled: s.mode !== 'explore' || s.pending || s.playing })}${stop.portrait ? `${vectorField('Portrait position', stop.portrait.position, 'portrait', 'position', stop.id)}<div class="field-grid">${numberField('Portrait FOV · °', stop.portrait.fov, 'portrait', 'fov', stop.id, 10, 110, 1)}${numberField('Portrait aspect', stop.portrait.aspect, 'portrait', 'aspect', stop.id, 0.3, 1, 0.01)}</div>${vectorField('Portrait orientation', stop.portrait.quaternion, 'portrait', 'quaternion', stop.id, ['X', 'Y', 'Z', 'W'])}` : ''}</details>`;
    return `<div class="selection-heading stop-heading"><span class="selection-kind">${imported ? 'ANIMATION ENDPOINT' : 'CAMERA KEY'} ${String(index + 1).padStart(2, '0')}</span><h2>${esc(stop.name)}</h2><details class="menu keyframe-menu"><summary aria-label="Keyframe options" title="Keyframe options">···</summary><div class="menu-popover">${button('Copy camera key', 'copyTimelineKeys', { payload: { cameraIds: [stop.id], layerKeyIds: [] }, icon: 'camera', disabled: !!imported || s.pending })}${button('Delete camera key', 'deleteTimelineKeys', { payload: { cameraIds: [stop.id], layerKeyIds: [] }, icon: 'trash', class: 'button danger', disabled: !!imported || s.project.stops.length <= 1 || s.pending })}${imported ? '<p class="field-note">Imported movement and timing stay protected. Compose a new camera key outside the clip.</p>' : ''}</div></details></div>${imported ? cameraAnimationBlock(imported, s.pending) : ''}${viewFields}${cameraFields}
      ${seg && !seg.cameraClip && key?.interpolation === 'legacy' ? `<details class="inspector-section" data-key="path-details-${esc(seg.id)}"><summary>Preserved camera path <span>Bézier</span></summary>${vectorField('Departure handle', seg.control1, 'segment', 'control1', seg.id)}${vectorField('Arrival handle', seg.control2, 'segment', 'control2', seg.id)}<p class="field-note">This existing path keeps its shape. Drag its timeline keys to retime it, or choose Linear, Ease or Hold for new motion.</p></details>` : '<p class="end-note">Position, orientation and lens are captured together in one camera key.</p>'}
      <details class="inspector-section photo-section"><summary>Artistic impression <span>${stop.photo ? 'Added' : 'Optional'}</span></summary>${!imported ? numberField('Hold at key · seconds', stop.hold, 'stop', 'hold', stop.id, 0, 120, 0.5) + '<p class="field-note">The image appears while the camera holds here. The hold must fit before the next camera key.</p>' : ''}${stop.photo ? `<div class="photo-state ${s.photoStale ? 'stale' : stop.photo.approvedFingerprint ? 'approved' : 'unapproved'}"><span></span>${s.photoStale ? 'Review needed · scene has changed' : stop.photo.approvedFingerprint ? 'Approved for this scene' : 'Awaiting your approval'}</div>${textField('Caption', stop.photo.caption, 'photo', 'caption', stop.id)}${button('Approve for current scene', 'approvePhoto', { payload: stop.id, icon: 'check', class: 'button subtle full' })}` : '<p class="field-note">A still image can appear while the camera holds here. It yields to 3D when visitors change visible layers.</p>'}${fileButton(stop.photo ? 'Replace artistic photo' : 'Import artistic photo', 'filePhoto', 'upload', s.pending)}<label class="check-field compact"><input type="checkbox" data-local="portraitPhoto"${checked(portraitPhoto)} /><span>Use upload as portrait variant</span></label>${stop.photo ? button('Remove photo', 'removePhoto', { payload: stop.id, class: 'text-button danger' }) : ''}</details>`;
  }

  function planInspector(p: Project): string {
    const plan = p.plan;
    if (!plan) return emptyInspector('plan', 'Add your plan', 'Import a plan image from the scene panel to calibrate its scale and placement.');
    let residual = '';
    if (plan.third) {
      const angle = Math.atan2(plan.b[1] - plan.a[1], plan.b[0] - plan.a[0]);
      const scale = plan.distance / Math.hypot(plan.b[0] - plan.a[0], plan.b[1] - plan.a[1]);
      const dx = (plan.third.pixel[0] - plan.a[0]) * scale, dz = (plan.third.pixel[1] - plan.a[1]) * scale;
      const r = plan.rotation - angle;
      const point = [plan.origin[0] + dx * Math.cos(r) - dz * Math.sin(r), plan.origin[1], plan.origin[2] + dx * Math.sin(r) + dz * Math.cos(r)];
      residual = `<p class="field-note">Third-point alignment difference: ${fmt(Math.hypot(...point.map((v, i) => v - plan.third!.world[i])), 3)} m. A photo of a drawing may need upstream perspective correction.</p>`;
    }
    return `<div class="selection-heading"><span class="selection-kind">ARCHITECTURAL PLAN</span><h2>Scale &amp; alignment</h2></div><p class="field-note">Choose two points on the image and enter their real-world separation. Pixel coordinates begin at the top-left.</p>${vectorField('Point A · pixels', plan.a, 'plan', 'a', 'plan', ['X', 'Y'])}${vectorField('Point B · pixels', plan.b, 'plan', 'b', 'plan', ['X', 'Y'])}${numberField('A–B distance · metres', plan.distance, 'plan', 'distance', 'plan', 0.0001, undefined, 0.1)}${vectorField('Point A world origin · metres', plan.origin, 'plan', 'origin', 'plan')}${numberField('World rotation · radians', plan.rotation, 'plan', 'rotation', 'plan', undefined, undefined, 0.01)}<details class="inspector-section"><summary>Third-point alignment check</summary>${vectorField('Check point · pixels', plan.third?.pixel ?? [0, 0], 'planThird', 'pixel', 'plan', ['X', 'Y'])}${vectorField('Expected position · metres', plan.third?.world ?? [0, 0, 0], 'planThird', 'world', 'plan')}${residual || '<p class="field-note">Optional: enter a third correspondence to check the alignment away from the first two points.</p>'}</details>`;
  }

  let showingPlan = false;
  function presentationSettings(s: ViewState): string {
    return `<details class="global-settings"><summary><span>${icon('leaf')}Presentation settings</span></summary><div class="settings-content"><div class="field-grid">${numberField('Plan opening · s', s.project.opening, 'project', 'opening', '', 0, 120, 0.5)}${numberField('Landscape reveal · s', s.project.revealDuration, 'project', 'revealDuration', '', 0, 120, 0.5)}</div><label class="field"><span>Output quality</span><select data-scope="project" data-field="profile"><option value="balanced"${selected(s.project.profile === 'balanced')}>Balanced · mainstream devices</option><option value="mobile"${selected(s.project.profile === 'mobile')}>Mobile · lighter rendering</option></select></label><label class="field"><span>Lighting style</span><select aria-label="Lighting style" data-scope="lighting" data-field="style"><option value="soft"${selected(s.project.lighting.style !== 'architectural')}>Soft daylight</option><option value="architectural"${selected(s.project.lighting.style === 'architectural')}>Architectural · defined light</option></select></label>${numberField('Light exposure', s.project.lighting.exposure, 'lighting', 'exposure', '', 0.1, 3, 0.1)}${checkField('Shadows', s.project.lighting.shadows, 'lighting', 'shadows')}<p class="field-note">Quality changes rendering costs. Authored layers, plant density and camera timing stay yours.</p></div></details>`;
  }

  function cameraImport(s: ViewState): string {
    const review = s.cameraImport;
    if (!review) return '';
    return `<div class="dialog-backdrop camera-import-backdrop"><section class="camera-import-dialog" role="dialog" aria-modal="true" aria-labelledby="camera-import-title" aria-describedby="camera-import-description" tabindex="-1" data-testid="camera-import-dialog"><header><span class="eyebrow">CAMERA ANIMATION · 3DS MAX</span><h2 id="camera-import-title">Bring your camera<br />into the landscape.</h2><p id="camera-import-description">The original movement, lens changes and timing will play as one continuous camera track.</p></header><div class="camera-import-preview"><div class="import-camera-mark">${icon('camera')}</div><div><span class="selection-kind">CAMERA</span><h3>${esc(review.name)}</h3></div></div><dl class="camera-import-facts"><div><dt>Duration</dt><dd>${fmt(review.duration, 3)} <small>seconds</small></dd></div><div><dt>Frame rate</dt><dd>${fmt(review.fps, 3)} <small>fps</small></dd></div><div><dt>Samples</dt><dd>${review.sampleCount.toLocaleString()}</dd></div><div><dt>Frame aspect</dt><dd>${fmt(review.aspect, 3)}<small> : 1</small></dd></div></dl><p class="camera-import-consequence">This replaces the current camera journey. Your landscape stays in place, and <strong>Undo</strong> restores the previous journey.</p><footer>${button('Cancel', 'cancelCameraAnimation', { class: 'button subtle', test: 'cancel-camera-animation' })}${button('Use camera animation', 'acceptCameraAnimation', { icon: 'check', class: 'button primary', test: 'confirm-camera-animation' })}</footer></section></div>`;
  }

  function restoreDialogFocus(element: HTMLElement | null): void {
    if (!element?.isConnected) return;
    const menu = element.closest<HTMLDetailsElement>('details.menu');
    if (menu && !menu.open) menu.querySelector<HTMLElement>('summary')?.focus();
    else element.focus();
  }

  function replacement(s: ViewState): string {
    const review = s.replacement;
    if (!review) return '';
    const nodes = review.asset.nodes.filter(n => `${n.name} ${n.path}`.toLocaleLowerCase().includes(replacementFilter.toLocaleLowerCase()));
    const previousOptions = Object.entries(review.previousNames).filter(([key, name]) => `${name} ${key}`.toLocaleLowerCase().includes(previousNodeFilter.toLocaleLowerCase())).slice(0, 100);
    replacementPage = Math.min(replacementPage, Math.max(0, Math.ceil(nodes.length / pageSize()) - 1));
    return `<div class="dialog-backdrop"><section class="replacement-dialog" role="dialog" aria-modal="true" aria-labelledby="replacement-title" tabindex="-1"><header><span class="eyebrow">REVIEW ASSET REVISION</span><h2 id="replacement-title">A new landscape,<br />with your composition intact.</h2><p>Match the replacement nodes to their previous identities. Assign a layer for anything new. Your existing asset stays active until you confirm.</p></header><div class="field-grid"><label class="field"><span>Find a replacement node</span><input type="search" data-local="replacementFilter" data-key="replacement-filter" value="${esc(replacementFilter)}" placeholder="Name or hierarchy path" /></label><label class="field"><span>Filter previous-node choices · first 100 matches</span><input type="search" data-local="previousNodeFilter" data-key="previous-node-filter" value="${esc(previousNodeFilter)}" placeholder="Previous name or identity" /></label></div><div class="replacement-columns"><span>Replacement node</span><span>Previous node</span><span>New node layer</span></div><div class="replacement-rows">${nodes.slice(replacementPage * pageSize(), (replacementPage + 1) * pageSize()).map(n => {
      const options = previousOptions.some(([key]) => key === reviewMappings[n.key]) || !reviewMappings[n.key] ? previousOptions : [[reviewMappings[n.key], review.previousNames[reviewMappings[n.key]]], ...previousOptions];
      return `<div class="replacement-row" data-key="replace-${esc(n.key)}"><span><strong>${esc(n.name || 'Unnamed node')}</strong><small>${n.renderable ? 'Mesh' : 'Group'} · ${esc(n.path)}</small></span><label><span class="sr-only">Previous identity for ${esc(n.name)}</span><select data-replacement-map="${esc(n.key)}"><option value="">New / unmatched node</option>${options.map(([key, name]) => `<option value="${esc(key)}"${selected(reviewMappings[n.key] === key)}>${esc(name)}</option>`).join('')}</select></label><label><span class="sr-only">Layer for new node ${esc(n.name)}</span><select data-replacement-layer="${esc(n.key)}"><option value="">Inherit from group</option>${s.project.layers.map(l => `<option value="${esc(l.id)}"${selected(reviewAssignments[n.key] === l.id)}>${esc(l.name)}</option>`).join('')}</select></label></div>`;
    }).join('') || '<p class="section-empty">No matching nodes.</p>'}</div>${pager(replacementPage, nodes.length, 'uiReplacementPage')}<footer>${button('Keep current asset', 'cancelReplacement', { class: 'button subtle' })}${button('Confirm replacement', 'uiAcceptReplacement', { icon: 'check', class: 'button primary' })}</footer></section></div>`;
  }

  function update(s: ViewState): void {
    current = s;
    const nextSelected = `${s.selectedLayer}|${s.selectedInstance}|${s.selectedStop}`;
    if (nextSelected !== selectedSnapshot) {
      if (s.selectedLayer && s.selectedLayer !== selectedSnapshot.split('|')[0]) inspector = 'layer';
      else if (sceneOpen && s.selectedInstance && s.selectedInstance !== selectedSnapshot.split('|')[1]) { inspector = 'instance'; nodeFilter = ''; nodePage = 0; }
      else if (s.selectedStop && s.selectedStop !== selectedSnapshot.split('|')[2]) inspector = 'stop';
      showingPlan = false; selectedSnapshot = nextSelected;
    }
    const cameraLensSignature = s.mode === 'explore' ? s.cameraFov : 'inactive';
    const cameraImportKey = s.cameraImport ? JSON.stringify(s.cameraImport) : '';
    const chrome = `${s.project.revision}|${s.mode}|${s.framing}|${s.framePreset}|${s.safeFrame}|${s.playing}|${nextSelected}|${s.pending}|${s.canUndo}|${s.canRedo}|${s.photoStale}|${s.navigationMode}|${s.cameraEditingStopId}|${s.cameraSession}|${sceneOpen}|${focusView}|${s.cameraSpeed}|${cameraLensSignature}|${inspector}|${showingPlan}|${cameraImportKey}`;
    const sceneValue = sceneOpen ? 'open' : 'closed';
    if (studioElement.dataset.scene !== sceneValue) { studioElement.dataset.scene = sceneValue; sceneToggle.setAttribute('aria-pressed', String(sceneOpen)); }
    if (studioElement.dataset.focus !== String(focusView)) { studioElement.dataset.focus = String(focusView); focusToggle.setAttribute('aria-pressed', String(focusView)); }
    if (previousProject !== s.project || previousChrome !== chrome) {
      patchMarkup(query('#camera-authoring'), cameraAuthoring(s));
      patchMarkup(query('#camera-settings'), cameraSettings(s));
      query<HTMLElement>('#camera-settings').hidden = showingPlan || inspector !== 'stop';
      patchMarkup(query('#hierarchy-body'), hierarchy(s));
      query<HTMLElement>('#inspector-tabs').hidden = !sceneOpen;
      patchMarkup(query('#inspector-tabs'), `<button type="button" data-action="uiInspector" data-payload='"layer"' class="${!showingPlan && inspector === 'layer' ? 'active' : ''}" aria-pressed="${!showingPlan && inspector === 'layer'}">Layer</button><button type="button" data-action="uiInspector" data-payload='"instance"' class="${!showingPlan && inspector === 'instance' ? 'active' : ''}" aria-pressed="${!showingPlan && inspector === 'instance'}">Asset</button><button type="button" data-action="uiInspector" data-payload='"stop"' class="${!showingPlan && inspector === 'stop' ? 'active' : ''}" aria-pressed="${!showingPlan && inspector === 'stop'}">Camera</button>`);
      patchMarkup(query('#inspector-body'), showingPlan ? planInspector(s.project) : inspector === 'layer' ? layerInspector(s) : inspector === 'instance' ? instanceInspector(s) : stopInspector(s));
      root.querySelectorAll<HTMLOptionElement>('[data-scope="cameraKeyInterpolation"] option[value="legacy"]').forEach(option => option.disabled = true);
      patchMarkup(query('#presentation-settings'), presentationSettings(s));
      query('#scene-count').textContent = `${s.project.instances.length} ${s.project.instances.length === 1 ? 'asset' : 'assets'}`;
      query('#inspector-type').textContent = showingPlan ? 'Plan calibration' : inspector === 'layer' ? 'Layer' : inspector === 'instance' ? 'Asset' : 'Camera';
      const title = query<HTMLInputElement>('#project-title'); if (document.activeElement !== title) title.value = s.project.title;
      query<HTMLElement>('#empty-stage').hidden = s.project.instances.length > 0 || s.mode === 'preview';
      query<HTMLElement>('#job-overlay').hidden = !s.pending;
      preview.hidden = s.mode !== 'preview';
      query<HTMLSelectElement>('[data-scope="framing"]').value = s.framing;
      query<HTMLElement>('.stage').classList.toggle('previewing', s.mode === 'preview');
      viewport.setAttribute('aria-label', s.mode === 'explore' && s.navigationMode === 'camera' ? 'Landscape camera viewport. Focus or click here. Drag to look; middle or Shift-left drag to pan; mouse wheel to move in and out; W A S D to move; Q and E for height; Shift to move faster; Escape to release.' : s.mode === 'playback' ? 'Landscape animation playback viewport. Use the timeline to review camera movement.' : s.mode === 'plan' ? 'Landscape orthographic plan viewport. Drag to pan; scroll to zoom.' : 'Landscape 3D viewport. Drag to orbit; scroll to zoom.');
      root.querySelectorAll<HTMLButtonElement>('[data-action="mode"]').forEach(b => b.setAttribute('aria-pressed', String(JSON.parse(b.dataset.payload!) === s.mode)));
      root.querySelectorAll<HTMLButtonElement>('[data-action="undo"]').forEach(b => b.disabled = !s.canUndo || s.pending);
      root.querySelectorAll<HTMLButtonElement>('[data-action="redo"]').forEach(b => b.disabled = !s.canRedo || s.pending);
      root.querySelectorAll<HTMLButtonElement>('[data-action="newProject"], [data-action="fileOpen"], [data-action="fileGLB"], [data-action="fileCamera"], [data-action="exportWebsite"], [data-action="preview"], [data-action="demo"], [data-action="saveProject"]').forEach(b => b.disabled = s.pending);
      root.querySelectorAll<HTMLButtonElement>('[data-action="captureStop"], [data-action="updateFromView"], [data-action="capturePortrait"]').forEach(b => b.disabled = s.mode !== 'explore' || s.pending || s.playing);
      previousProject = s.project; previousChrome = chrome;
    }
    const reviewKey = s.replacement ? `${s.replacement.asset.revisionId}|${s.replacement.instanceId}` : '';
    if (replacementSignature !== reviewKey) {
      if (s.replacement) beforeDialog = document.activeElement instanceof HTMLElement ? document.activeElement : null;
      reviewMappings = { ...s.replacement?.suggestions }; reviewAssignments = {}; replacementFilter = ''; previousNodeFilter = ''; replacementPage = 0;
      patchMarkup(query('#replacement-root'), replacement(s)); replacementSignature = reviewKey;
      if (s.replacement) query<HTMLElement>('.replacement-dialog').focus();
      else restoreDialogFocus(beforeDialog);
    }
    if (cameraImportSignature !== cameraImportKey) {
      if (s.cameraImport) beforeCameraDialog = cameraImportTrigger?.isConnected ? cameraImportTrigger : document.activeElement instanceof HTMLElement && !document.activeElement.closest('.file-inputs') ? document.activeElement : query<HTMLElement>('[data-testid="project-menu"]');
      patchMarkup(query('#camera-import-root'), cameraImport(s)); cameraImportSignature = cameraImportKey;
      if (s.cameraImport) query<HTMLElement>('.camera-import-dialog').focus();
      else { restoreDialogFocus(beforeCameraDialog); cameraImportTrigger = null; }
    }
    const frameState = `${s.mode}|${s.framing}|${s.framePreset}|${s.safeFrame}|${s.effectiveFrameAspect}`;
    if (previousFrameState !== frameState) { previousFrameState = frameState; layoutFraming(); }
    animationTimeline.update(s);
    if (statusElement.textContent !== s.status) statusElement.textContent = s.status;
    if (errorElement.hidden !== !s.error) errorElement.hidden = !s.error;
    if (errorElement.textContent !== (s.error ?? '')) errorElement.textContent = s.error ?? '';
    if (statusDot.classList.contains('error') !== !!s.error) statusDot.classList.toggle('error', !!s.error);
    if (statusDot.classList.contains('busy') !== s.pending) statusDot.classList.toggle('busy', s.pending);
    if (storageElement.textContent !== s.storageStatus) storageElement.textContent = s.storageStatus;
    const stats = `${s.stats.calls.toLocaleString()} draws · ${s.stats.triangles.toLocaleString()} triangles · ${fmt(s.stats.gpuBytes / 1048576, 1)} MiB`;
    if (statsElement.textContent !== stats) statsElement.textContent = stats;
  }

  function refreshChrome(): void { previousChrome = ''; if (current) update(current); }
  function resizePanels(): void { nodePage = 0; replacementPage = 0; refreshChrome(); if (current?.replacement) patchMarkup(query('#replacement-root'), replacement(current)); }
  function click(event: Event): void {
    const target = event.target instanceof Element ? event.target.closest<HTMLElement>('[data-action]') : null;
    if (!target || target instanceof HTMLButtonElement && target.disabled) return;
    const name = target.dataset.action!, payload = target.dataset.payload ? JSON.parse(target.dataset.payload) : undefined;
    closeMenus();
    if (name === 'uiScene') { sceneOpen = !sceneOpen; if (!sceneOpen) { inspector = 'stop'; showingPlan = false; } focusView = false; refreshChrome(); return; }
    if (name === 'uiFocus') { focusView = !focusView; refreshChrome(); return; }
    if (name === 'uiInspector') { inspector = payload; showingPlan = false; refreshChrome(); return; }
    if (name === 'uiPlan') { showingPlan = true; sceneOpen = true; refreshChrome(); return; }
    if (name === 'uiNodePage') { nodePage = Math.max(0, Number(payload)); refreshChrome(); return; }
    if (name === 'uiReplacementPage') { replacementPage = Math.max(0, Number(payload)); if (current) patchMarkup(query('#replacement-root'), replacement(current)); return; }
    const fileTargets: Record<string, string> = { fileGLB: '#file-glb', fileOpen: '#file-open', fileCamera: '#file-camera', filePlan: '#file-plan', filePhoto: '#file-photo', fileReplace: '#file-replace' };
    if (name in fileTargets) {
      if (name === 'fileCamera') cameraImportTrigger = target;
      if (name === 'fileReplace') replacementInstance = current?.selectedInstance ?? '';
      if (name === 'filePhoto') { photoStopId = current?.selectedStop ?? ''; photoPortrait = portraitPhoto; }
      query<HTMLInputElement>(fileTargets[name]).click(); return;
    }
    if (name === 'uiAcceptReplacement') {
      actions.act('acceptReplacement', { mapping: { ...reviewMappings }, assignments: { ...reviewAssignments } }); return;
    }
    if (name === 'selectLayer' || name === 'selectInstance' || name === 'selectStop') {
      inspector = name === 'selectLayer' ? 'layer' : name === 'selectInstance' ? 'instance' : 'stop';
      showingPlan = false;
      previousChrome = '';
      actions.act(name, payload);
      refreshChrome();
      return;
    }
    actions.act(name, payload);
  }

  function change(event: Event): void {
    const el = event.target;
    if (!(el instanceof HTMLInputElement || el instanceof HTMLSelectElement) || !current) return;
    if (el instanceof HTMLInputElement && el.type === 'file') {
      const file = el.files?.[0]; if (!file) return;
      if (el.id === 'file-glb') actions.act('importGLB', { file, units: importUnits, up: importUp });
      if (el.id === 'file-replace') actions.act('replaceAsset', { file, instanceId: replacementInstance, units: importUnits, up: importUp });
      if (el.id === 'file-open') actions.act('openProject', file);
      if (el.id === 'file-camera') actions.act('importCameraAnimation', file);
      if (el.id === 'file-plan') actions.act('importPlan', file);
      if (el.id === 'file-photo') {
        const stopId = photoStopId || current.selectedStop;
        if (stopId) actions.act('importPhoto', { file, stopId, portrait: photoStopId ? photoPortrait : portraitPhoto });
        photoStopId = '';
      }
      el.value = ''; return;
    }
    if (el.dataset.local === 'units') { importUnits = Number(el.value); return; }
    if (el.dataset.local === 'up') { importUp = el.value; return; }
    if (el.dataset.local === 'portraitPhoto') { portraitPhoto = (el as HTMLInputElement).checked; return; }
    if (el.dataset.replacementMap) { if (el.value) reviewMappings[el.dataset.replacementMap] = el.value; else delete reviewMappings[el.dataset.replacementMap]; return; }
    if (el.dataset.replacementLayer) { if (el.value) reviewAssignments[el.dataset.replacementLayer] = el.value; else delete reviewAssignments[el.dataset.replacementLayer]; return; }
    if (!el.dataset.scope) return;
    if (el instanceof HTMLInputElement && !el.checkValidity()) { el.reportValidity(); return; }
    const scope = el.dataset.scope, field = el.dataset.vector ?? el.dataset.field!, id = el.dataset.id ?? '';
    let value: unknown = el instanceof HTMLInputElement && el.type === 'checkbox' ? el.checked : el instanceof HTMLInputElement && (el.type === 'number' || el.type === 'range') ? el.valueAsNumber : el.value;
    if (el.dataset.vector) {
      const inputs = Array.from(root.querySelectorAll<HTMLInputElement>('[data-vector]')).filter(input => input.dataset.scope === scope && input.dataset.vector === field && input.dataset.id === id).sort((a, b) => Number(a.dataset.index) - Number(b.dataset.index));
      if (inputs.some(input => !input.checkValidity() || !Number.isFinite(input.valueAsNumber))) return;
      value = inputs.map(input => input === el ? input.valueAsNumber : Number(input.dataset.original));
    }
    if (typeof value === 'number' && !Number.isFinite(value)) return;
    if (scope === 'viewportMode') { actions.act(value === 'camera' || value === 'orbit' ? 'navigationMode' : 'mode', value); return; }
    if (scope === 'title') { actions.act('title', value); return; }
    if (scope === 'time') { actions.act('time', value); return; }
    if (scope === 'reducedMotion') { actions.act('reducedMotion', value); return; }
    if (scope === 'framing') { actions.act('framing', value); return; }
    if (scope === 'framePreset') { actions.act('framePreset', value); return; }
    if (scope === 'safeFrame') { actions.act('safeFrame', value); return; }
    if (scope === 'cameraSpeed') { actions.act('cameraSpeed', value); return; }
    if (scope === 'cameraFov') { actions.act('cameraFov', value); return; }
    if (scope === 'layer') actions.act('updateLayer', { id, patch: { [field]: value } });
    if (scope === 'layerFade') actions.act('updateLayer', { id, patch: { fade: Number(value) / 100 } });
    if (scope === 'stop') actions.act('updateStop', { id, patch: { [field]: value } });
    if (scope === 'cameraKeyTime') actions.act('updateCameraKey', { id, time: Number(value) });
    if (scope === 'cameraKeyInterpolation' && value !== 'legacy') actions.act('updateCameraKey', { id, interpolation: value });
    if (scope === 'lookTarget') { lookTargets.set(id, value as Vec3); actions.act('lookTarget', { id, target: value }); }
    if (scope === 'segment') actions.act('updateSegment', { id, patch: { [field]: value } });
    if (scope === 'speed') actions.act('segmentSpeed', { id, speed: value });
    if (scope === 'instance') {
      const instance = current.project.instances.find(i => i.id === id); if (!instance) return;
      actions.act('updateInstance', { id, patch: field === 'name' ? { name: value } : { transform: { ...instance.transform, [field]: value } } });
    }
    if (scope === 'instanceEuler') {
      const instance = current.project.instances.find(i => i.id === id); if (!instance) return;
      const angles = (value as number[]).map(v => v * Math.PI / 180);
      actions.act('updateInstance', { id, patch: { transform: { ...instance.transform, rotation: new Quaternion().setFromEuler(new Euler(angles[0], angles[1], angles[2], 'YXZ')).toArray() } } });
    }
    if (scope === 'node') actions.act('assignNode', { instanceId: id, nodeKey: el.dataset.node, layerId: value });
    if (scope === 'project') actions.act('updateProject', { [field]: value });
    if (scope === 'lighting') actions.act('updateProject', { lighting: { ...current.project.lighting, [field]: value } });
    if (scope === 'portrait') { const stop = current.project.stops.find(s => s.id === id); if (stop?.portrait) actions.act('updateStop', { id, patch: { portrait: { ...stop.portrait, [field]: value } } }); }
    if (scope === 'plan') actions.act('updatePlan', { [field]: value });
    if (scope === 'planThird') actions.act('updatePlan', { third: { pixel: current.project.plan?.third?.pixel ?? [0, 0], world: current.project.plan?.third?.world ?? [0, 0, 0] as Vec3, [field]: value } });
    if (scope === 'photo') actions.act('photoCaption', { stopId: id, caption: value });
  }

  function input(event: Event): void {
    if (event.target instanceof HTMLInputElement && event.target.dataset.scope === 'time') actions.act('time', event.target.valueAsNumber);
    if (event.target instanceof HTMLInputElement && event.target.dataset.local === 'nodeFilter') { nodeFilter = event.target.value; nodePage = 0; refreshChrome(); }
    if (event.target instanceof HTMLInputElement && event.target.dataset.local === 'replacementFilter') { replacementFilter = event.target.value; replacementPage = 0; if (current) patchMarkup(query('#replacement-root'), replacement(current)); }
    if (event.target instanceof HTMLInputElement && event.target.dataset.local === 'previousNodeFilter') { previousNodeFilter = event.target.value; if (current) patchMarkup(query('#replacement-root'), replacement(current)); }
  }
  function closeMenus(): void { root.querySelectorAll<HTMLDetailsElement>('details.menu[open]').forEach(menu => menu.open = false); }
  function outsideClick(event: Event): void { if (!(event.target instanceof Element) || !event.target.closest('.menu')) closeMenus(); }
  function menuToggle(event: Event): void { const menu = event.target; if (menu instanceof HTMLDetailsElement && menu.classList.contains('menu') && menu.open) root.querySelectorAll<HTMLDetailsElement>('details.menu[open]').forEach(other => { if (other !== menu) other.open = false; }); }
  function keydown(event: KeyboardEvent): void {
    if (event.key === 'Escape') { const open = root.querySelector<HTMLDetailsElement>('details.menu[open]'); if (open) { event.preventDefault(); closeMenus(); open.querySelector<HTMLElement>('summary')?.focus(); return; } }
    const dialog = root.querySelector<HTMLElement>('.camera-import-dialog, .replacement-dialog');
    if (dialog) {
      if (event.key === 'Escape') { event.preventDefault(); actions.act(dialog.classList.contains('camera-import-dialog') ? 'cancelCameraAnimation' : 'cancelReplacement'); return; }
      if (event.key === 'Tab') {
        const controls = Array.from(dialog.querySelectorAll<HTMLElement>('button:not([disabled]), select, input, [tabindex="0"]'));
        const first = controls[0], last = controls[controls.length - 1];
        if (event.shiftKey && (document.activeElement === first || document.activeElement === dialog)) { event.preventDefault(); last?.focus(); }
        else if (!event.shiftKey && document.activeElement === last) { event.preventDefault(); first?.focus(); }
      }
    }
  }
  root.addEventListener('click', click); root.addEventListener('change', change); root.addEventListener('input', input); root.addEventListener('keydown', keydown);
  narrowScreens.addEventListener('change', resizePanels);
  document.addEventListener('click', outsideClick); root.addEventListener('toggle', menuToggle, true);
  return { viewport, preview, update, dispose() { animationTimeline.dispose(); statusObserver.disconnect(); frameObserver.disconnect(); document.removeEventListener('click', outsideClick); root.removeEventListener('toggle', menuToggle, true); narrowScreens.removeEventListener('change', resizePanels); root.removeEventListener('click', click); root.removeEventListener('change', change); root.removeEventListener('input', input); root.removeEventListener('keydown', keydown); root.replaceChildren(); } };
}
