import {
  AmbientLight, Box3, BufferGeometry, Color, DirectionalLight, DoubleSide, Float32BufferAttribute, GridHelper, Group, HemisphereLight, Matrix4, MeshBasicMaterial, TextureLoader,
  Mesh, Object3D, OrthographicCamera, PCFSoftShadowMap, PerspectiveCamera, Scene, SRGBColorSpace,
  Vector3, WebGLRenderer, WebGLRenderTarget, PMREMGenerator, ACESFilmicToneMapping, type Material, type Texture,
} from 'three';
import type { OrbitControls } from 'three/addons/controls/OrbitControls.js';
import { GLTFLoader, type GLTF } from 'three/addons/loaders/GLTFLoader.js';
import { RoomEnvironment } from 'three/addons/environments/RoomEnvironment.js';
import { MeshoptDecoder } from 'three/addons/libs/meshopt_decoder.module.js';
import { resolveLayer, type Files, type Project, type Vec3, type Quat } from '../core/model';
import type { Evaluation } from '../presentation/evaluate';
import { canonical } from '../core/hash';
import { planPoint, inspectGLB, readGLB, LIMITS } from '../assets/glb';
import { planMeshopt } from '../assets/meshopt';
import { QualityGovernor } from './quality';
import { prepareImage } from '../assets/images';
import { sourceGpuEstimate } from './resources';
import { fitFrame } from './framing';

export interface PreparedScene { group: Group; hashes: string[]; project: Project; dispose(): void; }
export class RenderHost {
  readonly scene = new Scene();
  readonly perspective = new PerspectiveCamera(45, 1, 0.05, 5000);
  readonly planCamera = new OrthographicCamera(-65, 65, 65, -65, 0.1, 5000);
  readonly stats = { renders: 0, rebuilds: 0, uploads: 0, calls: 0, triangles: 0, gpuBytes: 0, gpuMs: null as number | null, cpuMs: 0, renderScale: 1 };
  readonly canvas = document.createElement('canvas');
  readonly renderer: WebGLRenderer | null;
  controls: OrbitControls | null = null;
  private planControls: OrbitControls | null = null;
  private planMesh: Mesh<BufferGeometry, MeshBasicMaterial> | null = null;
  private planKey = '';
  private planGeneration = 0;
  private presentationMode = false;
  private cache = new Map<string, { gltf: GLTF; references: number }>();
  private active: PreparedScene | null = null;
  private raf = 0;
  private observer: ResizeObserver;
  private planMode = false;
  private suspended = false;
  private lost = false;
  private presentation: Evaluation | null = null;
  private compositionAspect: number | null = null;
  private visibilityKey = '';
  get frameAspect(): number | null { return this.presentation && (!this.editing || this.presentationMode) ? this.presentation.aspect : this.compositionAspect; }
  setFrameAspect(aspect: number | null) { if (aspect !== null && (!Number.isFinite(aspect) || aspect < .3 || aspect > 4)) throw new Error('Invalid camera composition aspect'); this.compositionAspect = aspect; this.invalidate(); }
  private style = { value: 1 };
  private layerFades = new Map<string, { value: number }>();
  private sun = new DirectionalLight(0xfff5df, 2.3);
  private ambient = new AmbientLight(0xffffff, 0.5);
  private hemisphere = new HemisphereLight(0xfff4dc, 0x657763, 2.2);
  private environment: WebGLRenderTarget | null = null;
  private lightingStyle: 'soft' | 'architectural' = 'soft';
  private project: Project | null = null;
  private quality = new QualityGovernor();
  private lastDraw = 0;
  private gpuExtension: any = null;
  private gpuQueries: WebGLQuery[] = [];
  gpuMs: number | null = null;
  private grid = new GridHelper(120, 24, 0xc0c6b7, 0xd6dbcf);
  private onLost = (event: Event) => { event.preventDefault(); this.lost = true; this.gpuQueries = []; this.gpuMs = null; this.onStatus('Graphics context lost. Waiting to restore the prepared scene.'); };
  private onRestored = () => { this.lost = false; this.gpuExtension = this.renderer?.getContext().getExtension('EXT_disjoint_timer_query_webgl2'); this.environment?.dispose(); this.environment = null; this.scene.environment = null; if (this.project) this.syncProject(this.project); this.onStatus('Graphics context restored'); this.invalidate(); };
  onFrame: () => void = () => {};
  constructor(private mount: HTMLElement, private editing = false, private onStatus: (message: string) => void = () => {}) {
    this.canvas.setAttribute('aria-label', editing ? 'Landscape editing viewport' : 'Landscape presentation');
    this.canvas.style.cssText = 'display:block;width:100%;height:100%;touch-action:none';
    if (!editing) this.canvas.style.touchAction = 'pan-y';
    mount.append(this.canvas);
    this.scene.background = new Color('#eef0e5');
    this.scene.add(this.ambient, this.hemisphere);
    this.sun.position.set(-35, 70, 35); this.sun.castShadow = true;
    this.sun.shadow.camera.left = this.sun.shadow.camera.bottom = -65; this.sun.shadow.camera.right = this.sun.shadow.camera.top = 65;
    this.sun.shadow.camera.near = 1; this.sun.shadow.camera.far = 200; this.sun.shadow.bias = -0.0005; this.sun.shadow.normalBias = 0.04;
    this.scene.add(this.sun, this.sun.target); this.grid.position.y = -0.05; this.grid.visible = editing; this.scene.add(this.grid);
    let renderer: WebGLRenderer | null = null;
    try {
      renderer = new WebGLRenderer({ canvas: this.canvas, antialias: true, alpha: false, powerPreference: 'default' });
      renderer.outputColorSpace = SRGBColorSpace; renderer.toneMapping = ACESFilmicToneMapping; renderer.shadowMap.type = PCFSoftShadowMap; renderer.shadowMap.autoUpdate = false;
      const gl = renderer.getContext(), oldBuffer = gl.bufferData.bind(gl), oldSub = gl.bufferSubData.bind(gl);
      this.gpuExtension = gl.getExtension('EXT_disjoint_timer_query_webgl2');
      // Count actual GL buffer transfer calls, rather than inferring reuse from scene equality.
      gl.bufferData = ((...args: any[]) => { this.stats.uploads++; return (oldBuffer as any)(...args); }) as typeof gl.bufferData;
      gl.bufferSubData = ((...args: any[]) => { this.stats.uploads++; return (oldSub as any)(...args); }) as typeof gl.bufferSubData;
    } catch { this.onStatus('WebGL2 is unavailable. The plan and stop navigation remain available.'); }
    this.renderer = renderer;
    this.perspective.position.set(65, 65, 85); this.perspective.lookAt(0, 0, -5);
    this.planCamera.position.set(0, 200, 0); this.planCamera.up.set(0, 0, -1); this.planCamera.lookAt(0, 0, 0);
    this.canvas.addEventListener('webglcontextlost', this.onLost); this.canvas.addEventListener('webglcontextrestored', this.onRestored);
    this.observer = new ResizeObserver(this.invalidate); this.observer.observe(mount); this.invalidate();
  }
  attachNavigation(orbit: OrbitControls, plan: OrbitControls) {
    this.controls = orbit; this.planControls = plan; orbit.addEventListener('change', this.invalidate); plan.addEventListener('change', this.invalidate);
  }
  private release(hash: string) {
    const entry = this.cache.get(hash); if (!entry || --entry.references > 0) return;
    const geometries = new Set<any>(), materials = new Set<Material>(), textures = new Set<Texture>();
    entry.gltf.scene.traverse((o: any) => { if (o.geometry) geometries.add(o.geometry); for (const material of [].concat(o.material ?? [])) { materials.add(material); for (const value of Object.values(material)) if ((value as Texture)?.isTexture) textures.add(value as Texture); } });
    for (const g of geometries) g.dispose(); for (const m of materials) m.dispose();
    for (const t of textures) { const image = t.source?.data as { close?: () => void } | undefined; image?.close?.(); t.dispose(); }
    this.cache.delete(hash);
  }
  estimatedGpu(project: Project) {
    const scene = sourceGpuEstimate(project), dpr = Math.min(devicePixelRatio, project.profile === 'mobile' ? 1 : 1.5) * this.quality.scale;
    const shadowEdge = project.lighting.style === 'architectural' ? 2048 : 1024;
    const framebuffer = this.mount.clientWidth * this.mount.clientHeight * dpr * dpr * 8, shadows = project.lighting.shadows && project.profile === 'balanced' ? shadowEdge * shadowEdge * 8 : 0, edge = project.profile === 'mobile' ? 1600 : 2560;
    const plan = project.plan ? project.plan.width * project.plan.height * Math.min(1, edge / Math.max(project.plan.width, project.plan.height)) ** 2 * 4 * 4 / 3 : 0;
    const photos = project.stops.some(s => s.photo) ? edge * edge * 4 * (project.plan ? 2 : 3) : 0;
    const environment = project.lighting.style === 'architectural' ? 8 * 1024 * 1024 : 0;
    return Math.ceil(scene + framebuffer + shadows + plan + photos + environment);
  }
  async prepare(project: Project, blobs: Files, signal?: AbortSignal): Promise<PreparedScene> {
    const gpuBytes = this.estimatedGpu(project), max = project.profile === 'mobile' ? 192 : 384;
    if (gpuBytes > max * 1024 * 1024 || gpuBytes + this.stats.gpuBytes > 768 * 1024 * 1024) throw new Error('Estimated GPU resources exceed the chosen profile or replacement headroom');
    const group = new Group(), hashes: string[] = [], variants = new Map<string, Material>(); group.userData.variants = variants;
    const dispose = () => { group.traverse((o: any) => { if (o.isInstancedMesh) o.dispose(); }); for (const material of variants.values()) material.dispose(); variants.clear(); for (const hash of hashes.splice(0)) this.release(hash); group.clear(); const keep = new Set(this.active?.project.layers.map(l => l.id)); for (const layer of this.layerFades.keys()) if (!keep.has(layer)) this.layerFades.delete(layer); };
    try {
      for (const instance of project.instances) {
        signal?.throwIfAborted(); const asset = project.assets.find(a => a.revisionId === instance.assetRevision)!;
        let entry = this.cache.get(asset.hash);
        if (!entry) {
          const bytes = blobs.get(asset.hash); if (!bytes) throw new Error(`Missing asset: ${asset.name}`);
          if (planMeshopt(readGLB(bytes), LIMITS.expandedBytes)) {
            // Archives and public manifests must not understate decoded resources.
            const actual = await inspectGLB(bytes, asset.name, asset.id); signal?.throwIfAborted();
            if (actual.gpuBytes > asset.gpuBytes + 1 || actual.triangles > asset.triangles) throw new Error('Compressed asset metadata understates decoded resources');
          }
          const loader = new GLTFLoader().setMeshoptDecoder(MeshoptDecoder); const gltf = await loader.parseAsync(bytes.slice().buffer, '');
          entry = { gltf, references: 0 }; this.cache.set(asset.hash, entry);
          gltf.scene.traverse((o: any) => {
            const association = gltf.parser.associations.get(o); const key = association?.nodes !== undefined ? asset.nodeKeys?.[association.nodes] ?? `n:${association.nodes}` : undefined;
            if (key) o.userData.cyrusNodeKey = key;
            if (o.isMesh || o.isLine || o.isPoints) {
              o.castShadow = o.isMesh; o.receiveShadow = o.isMesh; o.frustumCulled = true;
              o.geometry?.computeBoundingSphere(); o.geometry?.computeBoundingBox(); o.computeBoundingSphere?.(); o.computeBoundingBox?.();
              const list = Array.isArray(o.material) ? o.material : [o.material];
              for (const material of list) {
                material.onBeforeCompile = (shader: any) => { shader.uniforms.cyrusColour = this.style; shader.fragmentShader = `uniform float cyrusColour;\n${shader.fragmentShader}`.replace('#include <dithering_fragment>', '#include <dithering_fragment>\nfloat cyrusGrey=dot(gl_FragColor.rgb,vec3(0.2126,0.7152,0.0722)); gl_FragColor.rgb=mix(vec3(cyrusGrey)*0.85+0.12,gl_FragColor.rgb,cyrusColour);'); };
                material.customProgramCacheKey = () => 'cyrus-presentation-style-v1';
              }
            }
          });
        }
        entry.references++; hashes.push(asset.hash); const root = entry.gltf.scene.clone(true); root.userData.instanceId = instance.id;
        root.position.fromArray(instance.transform.position); root.quaternion.fromArray(instance.transform.rotation).normalize(); root.scale.setScalar(instance.transform.scale);
        root.traverse((o: any) => {
          if (!o.isMesh && !o.isLine && !o.isPoints) return;
          let parent: Object3D | null = o, key: string | undefined;
          while (parent && !key) { key = parent.userData.cyrusNodeKey; parent = parent.parent; }
          o.userData.layerId = key ? resolveLayer(key, asset, instance) : undefined; o.userData.sourceMaterial = o.material;
          if (!o.userData.layerId || !project.layers.some(l => l.id === o.userData.layerId)) throw new Error('A rendered primitive could not bind its presentation layer');
          o.material = this.variant(o.material, o.userData.layerId, variants);
        });
        group.add(root);
      }
      signal?.throwIfAborted(); group.updateMatrixWorld(true); const bounds = new Box3().setFromObject(group);
      if (!bounds.isEmpty() && (!Number.isFinite(bounds.min.length()) || bounds.getSize(new Vector3()).length() > 1000000)) throw new Error('Invalid or extreme world bounds');
      // Prepare programs before publication; this also exposes shader errors without losing the current scene.
      if (this.renderer) {
        const staging = new Scene(); staging.add(group); const target = new WebGLRenderTarget(8, 8), previousTarget = this.renderer.getRenderTarget();
        try {
          await this.renderer.compileAsync(staging, this.perspective, this.scene);
          const culling: [Object3D, boolean][] = []; group.traverse(object => { culling.push([object, object.frustumCulled]); object.frustumCulled = false; });
          this.renderer.setRenderTarget(target); this.renderer.render(staging, this.perspective);
          for (const [object, value] of culling) object.frustumCulled = value;
          if (this.renderer.getContext().getError() === this.renderer.getContext().OUT_OF_MEMORY) throw new Error('GPU preparation ran out of memory');
        } finally { this.renderer.setRenderTarget(previousTarget); target.dispose(); staging.remove(group); }
      }
      signal?.throwIfAborted(); return { group, hashes, project, dispose };
    } catch (error) { dispose(); throw error; }
  }
  private variant(source: Material | Material[], layer: string, variants: Map<string, Material>): Material | Material[] {
    if (Array.isArray(source)) return source.map(m => this.variant(m, layer, variants) as Material);
    const key = `${source.uuid}:${layer}`;
    if (!variants.has(key)) {
      const material = source.clone(); if (!this.layerFades.has(layer)) this.layerFades.set(layer, { value: 1 });
      const fade = this.layerFades.get(layer)!;
      material.onBeforeCompile = (shader: any) => {
        shader.uniforms.cyrusColour = this.style; shader.uniforms.cyrusFade = fade;
        shader.fragmentShader = `uniform float cyrusColour;\nuniform float cyrusFade;\n${shader.fragmentShader}`.replace('#include <dithering_fragment>', '#include <dithering_fragment>\nfloat cyrusNoise=fract(sin(dot(gl_FragCoord.xy,vec2(12.9898,78.233)))*43758.5453); if(cyrusNoise>cyrusFade) discard; float cyrusGrey=dot(gl_FragColor.rgb,vec3(0.2126,0.7152,0.0722)); gl_FragColor.rgb=mix(vec3(cyrusGrey)*0.85+0.12,gl_FragColor.rgb,cyrusColour);');
      };
      material.customProgramCacheKey = () => 'cyrus-presentation-layer-style-v1'; variants.set(key, material);
    }
    return variants.get(key)!;
  }
  publish(prepared: PreparedScene) {
    const previous = this.active, oldProject = this.project, oldStats = { ...this.stats };
    this.scene.add(prepared.group); if (previous) this.scene.remove(previous.group); this.active = prepared; this.project = prepared.project;
    try {
      this.syncProject(prepared.project);
      this.stats.rebuilds++; this.stats.gpuBytes = this.estimatedGpu(prepared.project);
      this.renderer && (this.renderer.shadowMap.needsUpdate = true);
    } catch (error) {
      this.scene.remove(prepared.group); if (previous) this.scene.add(previous.group); this.active = previous; this.project = oldProject; Object.assign(this.stats, oldStats); this.invalidate(); throw error;
    }
    previous?.dispose(); this.invalidate();
  }
  syncProject(project: Project) {
    this.project = project;
    this.visibilityKey = '';
    this.active?.group.children.forEach(root => {
      const i = project.instances.find(i => i.id === root.userData.instanceId); if (!i) return;
      root.position.fromArray(i.transform.position); root.quaternion.fromArray(i.transform.rotation).normalize(); root.scale.setScalar(i.transform.scale);
      const a = project.assets.find(a => a.revisionId === i.assetRevision)!;
      root.traverse((o: any) => { if (!o.isMesh && !o.isLine && !o.isPoints) return; let parent: Object3D | null = o; while (parent && !parent.userData.cyrusNodeKey) parent = parent.parent; if (parent) o.userData.layerId = resolveLayer(parent.userData.cyrusNodeKey, a, i); o.material = this.variant(o.userData.sourceMaterial, o.userData.layerId, this.active!.group.userData.variants); });
    });
    if (this.renderer) {
      const style = project.lighting.style ?? 'soft';
      if (style === 'architectural' && !this.environment) {
        const generator = new PMREMGenerator(this.renderer), room = new RoomEnvironment();
        try { this.environment = generator.fromScene(room, 0.04, 0.1, 100, { size: 256 }); }
        finally { generator.dispose(); room.dispose(); }
      } else if (style === 'soft' && this.environment) { this.scene.environment = null; this.environment.dispose(); this.environment = null; }
      this.scene.environment = this.environment?.texture ?? null;
      this.scene.environmentIntensity = style === 'architectural' ? 0.2 : 1;
      this.ambient.intensity = style === 'architectural' ? 0.12 : 0.5;
      this.hemisphere.intensity = style === 'architectural' ? 0.7 : 2.2;
      this.sun.intensity = style === 'architectural' ? 3.6 : 2.3;
      if (style !== this.lightingStyle) {
        this.sun.position.set(...(style === 'architectural' ? [-55, 80, 45] : [-35, 70, 35]) as [number, number, number]);
        this.sun.target.position.set(0, style === 'architectural' ? 12 : 0, 0); this.lightingStyle = style;
        this.sun.shadow.map?.dispose(); this.sun.shadow.map = null;
      }
      this.renderer.toneMappingExposure = project.lighting.exposure; const shadows = project.lighting.shadows && project.profile === 'balanced';
      if (this.renderer.shadowMap.enabled !== shadows) {
        // Three's cached programs retain the shadow define until materials change.
        for (const material of this.active?.group.userData.variants.values() ?? []) material.needsUpdate = true;
      }
      this.renderer.shadowMap.enabled = shadows; this.sun.shadow.mapSize.setScalar(style === 'architectural' ? 2048 : 1024); this.renderer.shadowMap.needsUpdate = true;
    }
    this.invalidate();
  }
  setEvaluation(evaluation: Evaluation) {
    this.presentation = evaluation;
    for (const [layer, uniform] of this.layerFades) uniform.value = evaluation.layerFade[layer] ?? 0;
    const visibilityKey = Object.keys(evaluation.visible).map(id => `${id}:${+evaluation.visible[id]}:${+(evaluation.layerFade[id] >= 1)}`).join('|');
    if (visibilityKey !== this.visibilityKey) {
      this.visibilityKey = visibilityKey;
      this.active?.group.traverse((o: any) => { if (o.isMesh || o.isLine || o.isPoints) { const next = !!evaluation.visible[o.userData.layerId], shadow = o.isMesh && (evaluation.layerFade[o.userData.layerId] ?? 0) >= 1; if ((o.visible !== next || o.castShadow !== shadow) && this.renderer) this.renderer.shadowMap.needsUpdate = true; o.visible = next; o.castShadow = shadow; } });
    }
    this.style.value = evaluation.reveal;
    if (!this.editing || this.presentationMode) { this.perspective.position.fromArray(evaluation.position); this.perspective.quaternion.fromArray(evaluation.quaternion); this.perspective.fov = evaluation.fov; this.perspective.updateProjectionMatrix(); }
    this.invalidate();
  }
  mode(mode: 'explore' | 'plan' | 'playback' | 'preview') {
    this.planMode = mode === 'plan'; this.suspended = mode === 'preview';
    this.presentationMode = mode === 'playback';
    if (this.planControls) this.planControls.enabled = mode === 'plan';
    if (this.planMesh) this.planMesh.visible = this.planMode;
    if (this.controls) this.controls.enabled = mode === 'explore'; this.grid.visible = this.editing && mode !== 'playback' && mode !== 'preview'; this.invalidate();
  }
  capture(): { position: Vec3; quaternion: Quat; fov: number; aspect: number } { return { position: this.perspective.position.toArray() as Vec3, quaternion: this.perspective.quaternion.toArray() as Quat, fov: this.perspective.fov, aspect: this.frameAspect ?? this.mount.clientWidth / Math.max(1, this.mount.clientHeight) }; }
  setPlan(plan: Project['plan'], bytes?: Uint8Array) {
    const key = plan ? canonical([plan, this.project?.profile]) : ''; if (this.planKey === key) return; this.planKey = key; const generation = ++this.planGeneration;
    const remove = () => { if (this.planMesh) { this.scene.remove(this.planMesh); this.planMesh.geometry.dispose(); this.planMesh.material.map?.dispose(); this.planMesh.material.dispose(); this.planMesh = null; } };
    if (!plan || !bytes) { remove(); this.invalidate(); return; }
    void prepareImage(bytes, this.project?.profile ?? 'balanced').then(prepared => {
    if (generation !== this.planGeneration) return;
    const url = URL.createObjectURL(new Blob([prepared as Uint8Array<ArrayBuffer>]));
    new TextureLoader().load(url, texture => {
      URL.revokeObjectURL(url); if (generation !== this.planGeneration) { texture.dispose(); return; } remove(); texture.colorSpace = SRGBColorSpace;
      const corners = [[0, 0], [plan.width, 0], [plan.width, plan.height], [0, plan.height]] as [number, number][];
      const points = corners.map(pixel => { const p = planPoint(plan, pixel); p[1] += 0.15; return p; });
      const geometry = new BufferGeometry(); geometry.setAttribute('position', new Float32BufferAttribute(points.flat(), 3)); geometry.setAttribute('uv', new Float32BufferAttribute([0, 1, 1, 1, 1, 0, 0, 0], 2)); geometry.setIndex([0, 2, 1, 0, 3, 2]); geometry.computeVertexNormals();
      this.planMesh = new Mesh(geometry, new MeshBasicMaterial({ map: texture, side: DoubleSide, depthTest: false, toneMapped: false })); this.planMesh.renderOrder = 100; this.planMesh.visible = this.planMode; this.scene.add(this.planMesh); this.invalidate();
    }, undefined, () => { URL.revokeObjectURL(url); this.onStatus('Plan image could not decode; 3D scene retained'); });
    }).catch(() => this.onStatus('Plan preparation failed; 3D scene retained'));
  }
  restore(pose: { position: Vec3; quaternion: Quat; fov: number }) { this.perspective.position.fromArray(pose.position); this.perspective.quaternion.fromArray(pose.quaternion); this.perspective.fov = pose.fov; this.perspective.updateProjectionMatrix(); this.invalidate(); }
  invalidate = () => { if (!this.raf && !this.suspended) this.raf = requestAnimationFrame(this.draw); };
  private draw = () => {
    this.raf = 0; if (this.suspended || this.lost || !this.renderer) return;
    const started = performance.now(), frameInterval = this.lastDraw ? started - this.lastDraw : 0; this.lastDraw = started;
    const width = Math.max(1, this.mount.clientWidth), height = Math.max(1, this.mount.clientHeight), dpr = Math.min(devicePixelRatio, this.project?.profile === 'mobile' ? 1 : 1.5) * this.quality.scale;
    if (this.renderer.getPixelRatio() !== dpr || this.canvas.width !== Math.floor(width * dpr) || this.canvas.height !== Math.floor(height * dpr)) { this.renderer.setPixelRatio(dpr); this.renderer.setSize(width, height, false); }
    this.renderer.setScissorTest(false); this.renderer.setViewport(0, 0, width, height); this.renderer.setClearColor(this.scene.background as Color); this.renderer.clear();
    const camera = this.planMode ? this.planCamera : this.perspective;
    const frame = fitFrame(width, height, this.planMode ? null : this.frameAspect), { x, y, width: w, height: h } = frame;
    if (this.perspective.aspect !== w / h) { this.perspective.aspect = w / h; this.perspective.updateProjectionMatrix(); }
    if (this.planCamera.right !== 65 * width / height) { this.planCamera.left = -65 * width / height; this.planCamera.right = 65 * width / height; this.planCamera.updateProjectionMatrix(); }
    this.renderer.setViewport(x, y, w, h); this.renderer.setScissor(x, y, w, h); this.renderer.setScissorTest(true);
    const gl = this.renderer.getContext() as WebGL2RenderingContext, ext = this.gpuExtension;
    if (ext && this.gpuQueries.length) {
      const query = this.gpuQueries[0];
      if (gl.getParameter(ext.GPU_DISJOINT_EXT)) { this.gpuMs = null; for (const q of this.gpuQueries) gl.deleteQuery(q); this.gpuQueries = []; }
      else if (gl.getQueryParameter(query, gl.QUERY_RESULT_AVAILABLE)) { this.gpuMs = gl.getQueryParameter(query, gl.QUERY_RESULT) / 1000000; gl.deleteQuery(query); this.gpuQueries.shift(); }
    }
    const query = ext && this.gpuQueries.length < 4 ? gl.createQuery() : null; if (query) gl.beginQuery(ext.TIME_ELAPSED_EXT, query);
    try { this.renderer.render(this.scene, camera); } finally { if (query) { gl.endQuery(ext.TIME_ELAPSED_EXT); this.gpuQueries.push(query); } }
    this.stats.renders++; this.stats.calls = this.renderer.info.render.calls; this.stats.triangles = this.renderer.info.render.triangles; this.stats.cpuMs = performance.now() - started; this.stats.gpuMs = this.gpuMs;
    if (this.project) this.stats.gpuBytes = this.estimatedGpu(this.project);
    this.quality.sample(this.stats.cpuMs, frameInterval, frameInterval / 1000, this.project?.profile === 'mobile'); this.stats.renderScale = this.quality.scale; this.onFrame();
  };
  dispose() {
    cancelAnimationFrame(this.raf); this.observer.disconnect(); this.controls?.removeEventListener('change', this.invalidate); this.controls?.dispose();
    this.planControls?.dispose(); this.planGeneration++; this.setPlan(undefined);
    this.canvas.removeEventListener('webglcontextlost', this.onLost); this.canvas.removeEventListener('webglcontextrestored', this.onRestored);
    this.active?.dispose(); this.grid.geometry.dispose(); (this.grid.material as Material).dispose(); this.sun.shadow.dispose(); this.environment?.dispose(); this.renderer?.dispose(); this.canvas.remove();
    if (this.renderer) for (const query of this.gpuQueries) (this.renderer.getContext() as WebGL2RenderingContext).deleteQuery(query); this.gpuQueries = [];
  }
}
