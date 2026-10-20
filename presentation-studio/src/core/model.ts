import { z } from 'zod';
import { Box3, Matrix4, Quaternion, Vector3 } from 'three';

const coordinate = z.number().finite().min(-10000000).max(10000000);
export const vec3 = z.tuple([coordinate, coordinate, coordinate]);
export const quat = z.tuple([z.number().finite(), z.number().finite(), z.number().finite(), z.number().finite()]).refine(v => Math.hypot(...v) > 0.00001, 'Invalid quaternion');
const id = z.string().min(1).max(160);
const label = z.string().max(200);
const hash = z.string().regex(/^[a-f0-9]{64}$/);
export const transformSchema = z.object({ position: vec3, rotation: quat, scale: z.number().finite().positive().max(100000) });
export const layerSchema = z.object({ id, name: label, included: z.boolean(), defaultVisible: z.boolean(), viewerToggle: z.boolean(), reveal: z.number().finite().min(0).max(1), fade: z.number().finite().min(0).max(1).optional() });
export const nodeSchema = z.object({ key: id, name: label, path: z.string().max(2000), parent: id.nullable(), externalId: id.optional(), externalLayer: label.optional(), renderable: z.boolean() });
export const assetSchema = z.object({ id, revisionId: id, name: label, hash, bytes: z.number().int().nonnegative(), bounds: z.object({ min: vec3, max: vec3 }), nodes: z.array(nodeSchema).max(100000), nodeKeys: z.array(id).max(100000).optional(), triangles: z.number().nonnegative(), gpuBytes: z.number().nonnegative(), instanceBytes: z.number().nonnegative().optional(), warnings: z.array(z.string()).max(100) });
export const instanceSchema = z.object({ id, assetRevision: id, name: label, transform: transformSchema, membership: z.record(z.string(), id) });
export const photoSchema = z.object({ hash, portraitHash: hash.optional(), caption: z.string().max(2000), approvedFingerprint: hash.optional() });
export const stopSchema = z.object({ id, name: label, position: vec3, quaternion: quat, fov: z.number().finite().min(10).max(110), hold: z.number().finite().min(0).max(120), aspect: z.number().finite().min(0.3).max(4), portrait: z.object({ position: vec3, quaternion: quat, fov: z.number().finite().min(10).max(110), aspect: z.number().finite().min(0.3).max(1) }).optional(), photo: photoSchema.optional() });
export const cameraClipRefSchema = z.object({ hash, name: label, duration: z.number().finite().positive().max(3600), sampleCount: z.number().int().min(2).max(20000), fps: z.number().finite().positive().max(4800), aspect: z.number().finite().min(.3).max(4) });
export const segmentSchema = z.object({ id, from: id, to: id, control1: vec3, control2: vec3, duration: z.number().finite().min(0).max(3600), ease: z.number().finite().min(0).max(0.45), cameraClip: cameraClipRefSchema.optional() });
export const planSchema = z.object({ hash, width: z.number().positive(), height: z.number().positive(), a: z.tuple([z.number().finite(), z.number().finite()]), b: z.tuple([z.number().finite(), z.number().finite()]), distance: z.number().finite().positive(), origin: vec3, rotation: z.number().finite(), third: z.object({ pixel: z.tuple([z.number().finite(), z.number().finite()]), world: vec3 }).optional() });
const timelineTime = z.number().finite().min(0).max(864000);
export const timelineSchema = z.object({
  fps: z.number().int().min(1).max(120), duration: timelineTime,
  keys: z.array(z.object({ stopId: id, time: timelineTime, interpolation: z.enum(['legacy', 'linear', 'ease', 'hold']) })).min(1).max(200),
  layers: z.array(z.object({ layerId: id, keys: z.array(z.object({ id, time: timelineTime, visible: z.boolean() })).max(2000) })).max(128),
});
export const projectSchema = z.object({
  schemaVersion: z.union([z.literal(1), z.literal(2), z.literal(3)]), id, revision: z.number().int().nonnegative(), title: label,
  units: z.literal('metres'), up: z.literal('Y'),
  assets: z.array(assetSchema).max(100), instances: z.array(instanceSchema).max(1000), layers: z.array(layerSchema).max(128),
  stops: z.array(stopSchema).min(1).max(200), segments: z.array(segmentSchema).max(199),
  plan: planSchema.optional(), timeline: timelineSchema.optional(), opening: z.number().finite().min(0).max(120), revealDuration: z.number().finite().min(0).max(120),
  profile: z.enum(['balanced', 'mobile']), lighting: z.object({ exposure: z.number().finite().min(0.1).max(3), shadows: z.boolean(), style: z.enum(['soft', 'architectural']).optional() }),
});
export type Vec3 = z.infer<typeof vec3>;
export type Quat = z.infer<typeof quat>;
export type Project = z.infer<typeof projectSchema>;
export type Layer = Project['layers'][number];
export type Asset = Project['assets'][number];
export type Instance = Project['instances'][number];
export type Stop = Project['stops'][number];
export type Segment = Project['segments'][number];
export type NodeRecord = Asset['nodes'][number];
export type Files = Map<string, Uint8Array>;
export const uuid = () => crypto.randomUUID();
export const identityTransform = (): Instance['transform'] => ({ position: [0, 0, 0], rotation: [0, 0, 0, 1], scale: 1 });

export function validateProject(value: unknown): Project {
  const p = projectSchema.parse(value);
  const unique = (values: string[], what: string) => { if (new Set(values).size !== values.length) throw new Error(`Duplicate ${what} identity`); };
  unique(p.layers.map(x => x.id), 'layer'); unique(p.assets.map(x => x.revisionId), 'asset revision'); unique(p.instances.map(x => x.id), 'instance'); unique(p.stops.map(x => x.id), 'stop'); unique(p.segments.map(x => x.id), 'segment');
  const layers = new Set(p.layers.map(x => x.id));
  const revisions = new Map(p.assets.map(a => [a.revisionId, a]));
  if (p.instances.reduce((sum, i) => sum + (revisions.get(i.assetRevision)?.nodes.length ?? 0), 0) > 500000) throw new Error('Scene hierarchy exceeds the admitted work limit');
  for (const a of p.assets) { unique(a.nodes.map(n => n.key), 'node'); unique(a.nodes.flatMap(n => n.externalId ? [n.externalId] : []), 'external node'); if ((a.instanceBytes ?? 0) > a.gpuBytes) throw new Error('Instance storage exceeds the total asset estimate'); }
  for (const i of p.instances) {
    const a = revisions.get(i.assetRevision); if (!a) throw new Error('Missing asset revision');
    const world = new Box3(new Vector3().fromArray(a.bounds.min), new Vector3().fromArray(a.bounds.max)).applyMatrix4(new Matrix4().compose(new Vector3().fromArray(i.transform.position), new Quaternion().fromArray(i.transform.rotation).normalize(), new Vector3().setScalar(i.transform.scale)));
    if (world.isEmpty() || !Number.isFinite(world.min.length()) || world.getSize(new Vector3()).length() > 1000000) throw new Error('Asset transform exceeds admitted world bounds');
    const keys = new Set(a.nodes.map(n => n.key));
    for (const [node, layer] of Object.entries(i.membership)) if (!keys.has(node) || !layers.has(layer)) throw new Error('Invalid layer membership');
    for (const n of a.nodes.filter(n => n.renderable)) if (!resolveLayer(n.key, a, i)) throw new Error(`Unassigned node: ${n.name}`);
  }
  const cameraResources = new Map(p.segments.flatMap(s => s.cameraClip ? [[s.cameraClip.hash, s.cameraClip.sampleCount] as const] : []));
  if ([...cameraResources.values()].reduce((sum, count) => sum + count, 0) > 100000) throw new Error('Project camera animations exceed 100,000 unique samples');
  if (p.schemaVersion === 1 && p.segments.some(s => s.cameraClip)) throw new Error('Imported camera animation requires project schema 2');
  if (p.segments.length !== p.stops.length - 1) throw new Error('Camera adjacency is incomplete');
  p.segments.forEach((s, index) => { if (s.from !== p.stops[index].id || s.to !== p.stops[index + 1].id) throw new Error('Camera adjacency is invalid'); if (s.cameraClip && (s.duration !== s.cameraClip.duration || s.ease !== 0)) throw new Error('Imported camera timing must match its original clip'); });
  if ((p.schemaVersion === 3) !== !!p.timeline) throw new Error('Timed tracks require project schema 3 and a timeline');
  if (p.timeline) {
    const t = p.timeline;
    unique(t.keys.map(k => k.stopId), 'camera key'); unique(t.layers.map(l => l.layerId), 'layer track'); unique(t.layers.flatMap(l => l.keys.map(k => k.id)), 'visibility key');
    if (t.keys.length !== p.stops.length || t.keys.some((k, i) => k.stopId !== p.stops[i].id)) throw new Error('Timeline camera keys must match the ordered camera views');
    if (t.duration < p.opening + p.revealDuration) throw new Error('Timeline duration must include the opening and reveal');
    t.keys.forEach((k, i) => {
      const end = k.time + p.stops[i].hold, next = t.keys[i + 1];
      if (end > t.duration + 1e-7 || next && (end > next.time + 1e-7 || Math.abs(next.time - end - p.segments[i].duration) > 1e-7)) throw new Error('Camera key times overlap or disagree with travel duration');
      if (p.segments[i]?.cameraClip && k.interpolation !== 'legacy') throw new Error('Imported Max motion must retain original interpolation');
    });
    if (t.layers.reduce((n, l) => n + l.keys.length, 0) > 20000) throw new Error('Timeline exceeds 20,000 visibility keys');
    for (const track of t.layers) {
      if (!layers.has(track.layerId)) throw new Error('Timeline references a missing layer');
      if (track.keys.some((k, i) => k.time > t.duration || i > 0 && k.time <= track.keys[i - 1].time)) throw new Error('Visibility key times must be unique, ordered and within the timeline');
    }
  }
  if (p.plan && Math.hypot(p.plan.b[0] - p.plan.a[0], p.plan.b[1] - p.plan.a[1]) < 0.001) throw new Error('Calibration points must be distinct');
  return p;
}

const nodeIndices = new WeakMap<NodeRecord[], Map<string, NodeRecord>>();
export function resolveLayer(key: string, asset: Asset, instance: Instance): string | undefined {
  let index = nodeIndices.get(asset.nodes); if (!index) { index = new Map(asset.nodes.map(n => [n.key, n])); nodeIndices.set(asset.nodes, index); }
  const seen = new Set<string>();
  while (key) {
    if (seen.has(key) || seen.size > 256) throw new Error('Cyclic or excessively deep node hierarchy'); seen.add(key);
    if (instance.membership[key]) return instance.membership[key];
    key = index.get(key)?.parent ?? '';
  }
}

export function reconnect(p: Project): void {
  const old = p.segments;
  p.segments = p.stops.slice(1).map((to, index) => {
    const from = p.stops[index], existing = old.find(s => s.from === from.id && s.to === to.id);
    return existing ?? { id: uuid(), from: from.id, to: to.id, control1: from.position.map((v, j) => v + (to.position[j] - v) / 3) as Vec3, control2: from.position.map((v, j) => v + (to.position[j] - v) * 2 / 3) as Vec3, duration: Math.max(2, Math.hypot(...from.position.map((v, j) => v - to.position[j])) / 3), ease: 0.12 };
  });
}

export function emptyProject(): Project {
  return { schemaVersion: 1, id: uuid(), revision: 0, title: 'Untitled landscape', units: 'metres', up: 'Y', assets: [], instances: [], layers: [], stops: [{ id: uuid(), name: 'Arrival', position: [35, 30, 40], quaternion: [-0.25, 0.36, 0.1, 0.89], fov: 45, hold: 3, aspect: 16 / 9 }], segments: [], opening: 2, revealDuration: 5, profile: 'balanced', lighting: { exposure: 1, shadows: true } };
}
