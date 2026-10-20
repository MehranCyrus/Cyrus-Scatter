import { BoxGeometry, BufferGeometry, Color, Group, Line, LineSegments, LineBasicMaterial, Mesh, MeshBasicMaterial, Raycaster, SphereGeometry, Vector2, Vector3, Vector4 } from 'three';
import { OrbitControls } from 'three/addons/controls/OrbitControls.js';
import { TransformControls } from 'three/addons/controls/TransformControls.js';
import type { Project, Vec3 } from '../core/model';
import { canonical } from '../core/hash';
import { cameraAt, type CameraClips } from '../presentation/camera-clip';
import { bezier, type Evaluation } from '../presentation/evaluate';
import type { RenderHost } from '../render/host';
import type { Mode, NavigationMode } from './contracts';
import { ViewportCamera } from './viewport-camera';
import { fitFrame } from '../render/framing';

/** Editor-only navigation and path handles; this module is excluded from the public player. */
export class EditorNavigation {
  readonly orbit: OrbitControls;
  readonly plan: OrbitControls;
  readonly gizmo: TransformControls;
  readonly camera: ViewportCamera;
  navigationMode: NavigationMode = 'camera';
  private path = new Group();
  readonly animatedCamera = new Group();
  private frustum = new Group();
  private cameraBodyGeometry = new BoxGeometry(.18, .12, .22);
  private cameraBodyMaterial = new MeshBasicMaterial({ color: 0x215f50, depthTest: false });
  private frustumGeometry = new BufferGeometry();
  private frustumMaterial = new LineBasicMaterial({ color: 0xb46e3b, depthTest: false });
  private lockedMaterial = new MeshBasicMaterial({ color: 0xb46e3b, depthTest: false });
  private helperDistance = 5;
  private playing = false;
  private viewportObserver: ResizeObserver;
  private sphere = new SphereGeometry(0.6, 10, 6);
  private handles: Mesh[] = [];
  private lineMaterial = new LineBasicMaterial({ color: 0xb27955, depthTest: false });
  private stopMaterial = new MeshBasicMaterial({ color: 0x234e43, depthTest: false });
  private handleMaterial = new MeshBasicMaterial({ color: 0xc18661, depthTest: false });
  private key = '';
  private mode: Mode = 'explore';
  private drag: { object: Mesh; owner: string; field: string; before: Vec3 } | null = null;
  private deferredSync: [Project, string | null, Mode] | null = null;
  constructor(private host: RenderHost, private commit: (kind: 'stop' | 'segment', id: string, field: string, value: Vec3) => void, private clips: () => CameraClips = () => new Map()) {
    this.orbit = new OrbitControls(host.perspective, host.canvas); this.orbit.target.set(0, 0, -5); this.orbit.enableDamping = false; this.orbit.maxDistance = 2000;
    this.plan = new OrbitControls(host.planCamera, host.canvas); this.plan.enabled = false; this.plan.enableRotate = false; this.plan.screenSpacePanning = true;
    host.attachNavigation(this.orbit, this.plan); this.camera = new ViewportCamera(host); this.gizmo = new TransformControls(host.perspective, host.canvas); this.gizmo.setSize(0.75);
    const corners = [new Vector3(-1, -1, -1), new Vector3(1, -1, -1), new Vector3(1, 1, -1), new Vector3(-1, 1, -1)], edges: Vector3[] = [];
    corners.forEach((c, i) => edges.push(new Vector3(), c, c, corners[(i + 1) % 4]));
    edges.push(new Vector3(-.25, 1, -1), new Vector3(0, 1.35, -1), new Vector3(0, 1.35, -1), new Vector3(.25, 1, -1));
    this.frustumGeometry.setFromPoints(edges); const frustumLines = new LineSegments(this.frustumGeometry, this.frustumMaterial); frustumLines.frustumCulled = false; this.frustum.add(frustumLines);
    const body = new Mesh(this.cameraBodyGeometry, this.cameraBodyMaterial); body.frustumCulled = false; body.renderOrder = 202; this.frustum.children[0].renderOrder = 201;
    this.animatedCamera.add(this.frustum, body); this.animatedCamera.name = 'Animated presentation camera';
    host.scene.add(this.path, this.animatedCamera, this.gizmo.getHelper()); this.path.visible = this.animatedCamera.visible = false;
    this.gizmo.addEventListener('change', host.invalidate);
    this.gizmo.addEventListener('mouseDown', () => { const object = this.gizmo.object as Mesh | undefined; if (!object) return; this.drag = { object, owner: object.userData.owner, field: object.userData.field, before: object.position.toArray() as Vec3 }; this.orbit.enabled = this.plan.enabled = false; });
    this.gizmo.addEventListener('mouseUp', () => {
      const drag = this.drag; this.drag = null; this.orbit.enabled = this.mode === 'explore' && this.navigationMode === 'orbit'; this.plan.enabled = this.mode === 'plan';
      const value = drag?.object.position.toArray() as Vec3 | undefined;
      const pending = this.deferredSync; this.deferredSync = null; if (pending) this.sync(...pending);
      const validOwner = !pending || (drag?.field === 'position' ? pending[0].stops : pending[0].segments).some(s => s.id === drag?.owner);
      if (drag && value && validOwner && new Vector3().fromArray(value).distanceTo(new Vector3().fromArray(drag.before)) > 1e-7) this.commit(drag.field === 'position' ? 'stop' : 'segment', drag.owner, drag.field, value);
    });
    host.canvas.addEventListener('pointerdown', this.updateViewport, { capture: true });
    host.canvas.addEventListener('pointerdown', this.pick);
    this.viewportObserver = new ResizeObserver(this.updateViewport); this.viewportObserver.observe(host.canvas);
  }
  updateViewport = () => {
    const rect = this.host.canvas.getBoundingClientRect(), f = fitFrame(rect.width, rect.height, this.mode === 'plan' ? null : this.host.frameAspect);
    (this.gizmo.viewport ??= new Vector4()).set(f.x, rect.height - f.y - f.height, f.width, f.height);
  };
  private pick = (event: PointerEvent) => {
    if (!this.path.visible || this.playing || this.gizmo.dragging || event.button !== 0) return;
    const rect = this.host.canvas.getBoundingClientRect(), f = fitFrame(rect.width, rect.height, this.mode === 'plan' ? null : this.host.frameAspect);
    const pointer = new Vector2((event.clientX - rect.left - f.x) / f.width * 2 - 1, -(event.clientY - rect.top - f.y) / f.height * 2 + 1), ray = new Raycaster();
    if (Math.abs(pointer.x) > 1 || Math.abs(pointer.y) > 1) return;
    ray.setFromCamera(pointer, this.mode === 'plan' ? this.host.planCamera : this.host.perspective);
    const hit = ray.intersectObjects(this.handles)[0]; if (hit) { this.gizmo.attach(hit.object); this.host.invalidate(); }
  };
  setNavigationMode(mode: NavigationMode) {
    if (mode === 'orbit' && this.navigationMode === 'camera') this.alignOrbit();
    this.navigationMode = mode;
  }
  alignOrbit() {
    const distance = Math.max(1, Math.min(100, this.orbit.target.distanceTo(this.host.perspective.position)));
    this.orbit.target.copy(this.host.perspective.position).addScaledVector(new Vector3(0, 0, -1).applyQuaternion(this.host.perspective.quaternion), distance);
  }
  setPlaying(playing: boolean) { this.playing = playing; if (playing) this.gizmo.detach(); this.gizmo.enabled = !playing && !(this.mode === 'explore' && this.navigationMode === 'camera'); }
  setEvaluation(e: Evaluation) {
    this.animatedCamera.position.fromArray(e.position); this.animatedCamera.quaternion.fromArray(e.quaternion);
    const halfHeight = Math.tan(e.fov * Math.PI / 360) * this.helperDistance;
    this.frustum.scale.set(halfHeight * e.aspect, halfHeight, this.helperDistance);
    this.animatedCamera.children[1].scale.setScalar(this.helperDistance);
  }
  sync(project: Project, selectedStop: string | null, mode: Mode) {
    this.mode = mode; this.updateViewport(); if (this.drag) { this.deferredSync = [project, selectedStop, mode]; return; }
    const camera = mode === 'explore' && this.navigationMode === 'camera';
    this.camera.setEnabled(camera); this.orbit.enabled = mode === 'explore' && !camera; this.plan.enabled = mode === 'plan'; this.gizmo.enabled = !camera && !this.playing;
    this.gizmo.camera = mode === 'plan' ? this.host.planCamera : this.host.perspective;
    const visible = (mode === 'explore' || mode === 'plan') && !camera;
    this.animatedCamera.visible = visible;
    const sizes = project.instances.map(i => { const a = project.assets.find(a => a.revisionId === i.assetRevision)!; return new Vector3().fromArray(a.bounds.max).sub(new Vector3().fromArray(a.bounds.min)).length() * i.transform.scale * .06; });
    this.helperDistance = Math.max(2, Math.min(30, sizes.length ? Math.max(...sizes) : 5));
    if (this.path.visible !== visible) { this.path.visible = visible; this.host.invalidate(); }
    if (!visible) this.gizmo.detach();
    const key = canonical({ positions: project.stops.map(s => [s.id, s.position]), segments: project.segments.map(s => [s.id, s.control1, s.control2, s.from, s.to, s.cameraClip?.hash]) });
    if (key === this.key) return; this.key = key; this.gizmo.detach();
    for (const object of this.path.children) if (object instanceof Line) object.geometry.dispose();
    this.path.clear(); this.handles = [];
    // Tiny editor guides render once when Orbit opens, even outside the view. This warms their
    // retained buffers before a later rotation brings them on-screen; landscape culling stays enabled.
    const handle = (position: Vec3, owner: string, field: string) => { const mesh = new Mesh(this.sphere, field === 'position' ? this.stopMaterial : this.handleMaterial); mesh.frustumCulled = false; mesh.position.fromArray(position); mesh.userData = { owner, field, ...(field === 'position' ? { stopId: owner } : {}) }; mesh.renderOrder = 200; this.path.add(mesh); this.handles.push(mesh); };
    for (const stop of project.stops) if (!project.segments.some(s => s.cameraClip && (s.from === stop.id || s.to === stop.id))) handle(stop.position, stop.id, 'position');
    else { const marker = new Mesh(this.sphere, this.lockedMaterial); marker.frustumCulled = false; marker.position.fromArray(stop.position); marker.userData = { stopId: stop.id, protected: true }; marker.renderOrder = 200; this.path.add(marker); }
    for (const segment of project.segments) {
      const a = project.stops.find(s => s.id === segment.from)!, b = project.stops.find(s => s.id === segment.to)!;
      const clip = segment.cameraClip ? this.clips().get(segment.cameraClip.hash) : undefined;
      const points = clip ? Array.from({ length: Math.min(1025, clip.samples.length) }, (_, i) => new Vector3().fromArray(cameraAt(clip, i / (Math.min(1025, clip.samples.length) - 1) * segment.duration).position)) : Array.from({ length: 129 }, (_, i) => new Vector3().fromArray(bezier(a.position, segment.control1, segment.control2, b.position, i / 128)));
      const line = new Line(new BufferGeometry().setFromPoints(points), this.lineMaterial); line.frustumCulled = false; line.renderOrder = 199; this.path.add(line);
      if (!clip) { handle(segment.control1, segment.id, 'control1'); handle(segment.control2, segment.id, 'control2'); }
    }
    if (visible) this.host.invalidate();
  }
  dispose() { this.viewportObserver.disconnect(); this.host.canvas.removeEventListener('pointerdown', this.updateViewport, { capture: true }); this.camera.dispose(); this.host.canvas.removeEventListener('pointerdown', this.pick); this.gizmo.dispose(); this.host.scene.remove(this.path, this.animatedCamera, this.gizmo.getHelper()); for (const object of this.path.children) if (object instanceof Line) object.geometry.dispose(); this.frustumGeometry.dispose(); this.cameraBodyGeometry.dispose(); this.frustumMaterial.dispose(); this.cameraBodyMaterial.dispose(); this.lockedMaterial.dispose(); this.sphere.dispose(); this.lineMaterial.dispose(); this.stopMaterial.dispose(); this.handleMaterial.dispose(); }
}
