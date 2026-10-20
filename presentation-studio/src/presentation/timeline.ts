import { reconnect, uuid, type Project, type Stop, type Vec3 } from '../core/model';

export type Timeline = NonNullable<Project['timeline']>;
export type KeySelection = { cameraIds?: string[]; layerKeyIds?: string[] };
export const snapTime = (time: number, fps: number) => Math.round(time * fps) / fps;

// Reading an older project is lossless. Schema 3 is published only by an explicit edit.
export function timelineOf(p: Project): Timeline {
  if (p.timeline) return p.timeline;
  let cursor = p.opening + p.revealDuration;
  const keys = p.stops.map((s, i) => { const key: Timeline['keys'][number] = { stopId: s.id, time: cursor, interpolation: 'legacy' }; cursor += s.hold + (p.segments[i]?.duration ?? 0); return key; });
  return { fps: 30, duration: cursor, keys, layers: [] };
}
export function ensureTimeline(p: Project): Timeline { const t = p.timeline ?? structuredClone(timelineOf(p)); p.schemaVersion = 3; p.timeline = t; return t; }
export const cameraLocked = (p: Project, id: string) => p.segments.some(s => s.cameraClip && (s.from === id || s.to === id));
export function clipRanges(p: Project) {
  const keys = timelineOf(p).keys;
  return p.segments.flatMap((s, i) => s.cameraClip ? [{ id: s.id, name: s.cameraClip.name, start: keys[i].time + p.stops[i].hold, end: keys[i].time + p.stops[i].hold + s.cameraClip.duration }] : []);
}
export function authoredVisibility(p: Project, layerId: string, time: number): boolean {
  const layer = p.layers.find(l => l.id === layerId); if (!layer) throw new Error('Select a valid layer');
  const keys = p.timeline?.layers.find(l => l.layerId === layerId)?.keys ?? [];
  let lo = 0, hi = keys.length;
  while (lo < hi) { const mid = (lo + hi) >>> 1; if (keys[mid].time <= time) lo = mid + 1; else hi = mid; }
  return lo ? keys[lo - 1].visible : layer.defaultVisible;
}
function assertEditable(p: Project, ids: string[]) {
  if (ids.some(id => cameraLocked(p, id))) throw new Error('Imported Max camera keys are protected. Add keys outside the clip, or explicitly remove the imported animation.');
}
function preserveClips(p: Project, original: ReturnType<typeof clipRanges>) {
  const current = clipRanges(p);
  if (original.some(c => !current.some(n => n.id === c.id && Math.abs(c.start - n.start) < 1e-7 && Math.abs(c.end - n.end) < 1e-7))) throw new Error('This edit would change the imported Max clip. Keep new camera keys outside its protected time range.');
}
export function syncTimeline(p: Project): void {
  if (!p.timeline) return;
  const t = p.timeline, stops = new Map(p.stops.map(s => [s.id, s]));
  t.keys.sort((a, b) => a.time - b.time);
  if (t.keys.some(k => !stops.has(k.stopId)) || t.keys.length !== stops.size) throw new Error('Camera timeline has a missing view');
  p.stops = t.keys.map(k => stops.get(k.stopId)!); reconnect(p);
  p.segments.forEach((s, i) => {
    const a = p.stops[i], b = p.stops[i + 1], k = t.keys[i], seconds = t.keys[i + 1].time - k.time - a.hold;
    if (seconds < -1e-7) throw new Error('Camera keys overlap a held view. Move the key beyond its hold.');
    if (s.cameraClip) { if (Math.abs(seconds - s.cameraClip.duration) > 1e-7 || k.interpolation !== 'legacy') throw new Error('Imported Max timing is protected'); }
    else {
      s.duration = Math.max(0, seconds);
      if (k.interpolation !== 'legacy') {
        s.control1 = a.position.map((v, j) => v + (b.position[j] - v) / 3) as Vec3;
        s.control2 = a.position.map((v, j) => v + (b.position[j] - v) * 2 / 3) as Vec3;
        s.ease = k.interpolation === 'ease' ? .2 : 0;
      }
    }
  });
  for (const l of t.layers) l.keys.sort((a, b) => a.time - b.time);
}
export function moveTimelineKeys(p: Project, selection: KeySelection, delta: number): void {
  if (!Number.isFinite(delta)) throw new Error('Key time must be finite');
  const cameraIds = selection.cameraIds ?? [], layerIds = new Set(selection.layerKeyIds ?? []), original = clipRanges(p); assertEditable(p, cameraIds);
  const t = ensureTimeline(p);
  for (const k of t.keys) if (cameraIds.includes(k.stopId)) k.time += delta;
  for (const l of t.layers) for (const k of l.keys) if (layerIds.has(k.id)) k.time += delta;
  if (t.keys.some(k => k.time < 0 || k.time > t.duration) || t.layers.some(l => l.keys.some(k => k.time < 0 || k.time > t.duration))) throw new Error('Keep keys within the timeline duration');
  const times = t.keys.map(k => k.time);
  if (new Set(times).size !== times.length) throw new Error('Camera keys cannot share the same time');
  syncTimeline(p); preserveClips(p, original);
}
export function insertCameraKey(p: Project, pose: Omit<Stop, 'id' | 'name' | 'hold'>, time: number): string {
  const frame = { position: pose.position, quaternion: pose.quaternion, fov: pose.fov, aspect: pose.aspect };
  const t = ensureTimeline(p), at = snapTime(time, t.fps), existing = t.keys.find(k => Math.abs(k.time - at) < 1e-7), original = clipRanges(p);
  if (original.some(c => at > c.start - 1e-7 && at < c.end + 1e-7)) throw new Error('This time belongs to protected Max motion. Move the playhead outside the imported clip to capture a new camera key.');
  if (existing) { assertEditable(p, [existing.stopId]); Object.assign(p.stops.find(s => s.id === existing.stopId)!, frame); syncTimeline(p); return existing.stopId; }
  const id = uuid(); p.stops.push({ id, name: `View ${p.stops.length + 1}`, ...frame, hold: 0 });
  t.keys.push({ stopId: id, time: at, interpolation: 'ease' }); t.duration = Math.max(t.duration, at);
  syncTimeline(p); preserveClips(p, original); return id;
}
export function deleteTimelineKeys(p: Project, selection: KeySelection): void {
  const cameraIds = selection.cameraIds ?? [], ids = new Set(selection.layerKeyIds ?? []), original = clipRanges(p); assertEditable(p, cameraIds);
  if (!p.stops.some(s => cameraIds.includes(s.id)) && !p.timeline?.layers.some(l => l.keys.some(k => ids.has(k.id)))) throw new Error('Select one or more timeline keys first');
  const t = ensureTimeline(p); if (cameraIds.length && p.stops.every(s => cameraIds.includes(s.id))) throw new Error('Keep at least one camera key');
  p.stops = p.stops.filter(s => !cameraIds.includes(s.id)); t.keys = t.keys.filter(k => !cameraIds.includes(k.stopId));
  for (const l of t.layers) l.keys = l.keys.filter(k => !ids.has(k.id));
  syncTimeline(p); preserveClips(p, original);
}
export function captureLayerKey(p: Project, layerId: string, time: number, visible: boolean): void {
  if (!p.layers.some(l => l.id === layerId)) throw new Error('Select a valid presentation layer');
  const t = ensureTimeline(p); if (!Number.isFinite(time) || time < 0 || time > t.duration) throw new Error('Keep visibility keys within the timeline'); const at = Math.min(t.duration, snapTime(time, t.fps));
  let track = t.layers.find(l => l.layerId === layerId); if (!track) { track = { layerId, keys: [] }; t.layers.push(track); }
  const key = track.keys.find(k => Math.abs(k.time - at) < 1e-7); if (key) key.visible = visible; else track.keys.push({ id: uuid(), time: at, visible });
  track.keys.sort((a, b) => a.time - b.time);
}
export type TimelineClipboard = { camera: { stop: Stop; time: number; interpolation: Timeline['keys'][number]['interpolation'] }[]; layers: { layerId: string; visible: boolean; time: number }[]; origin: number; projectId: string };
export function copyTimelineKeys(p: Project, selection: KeySelection): TimelineClipboard {
  const t = timelineOf(p), cameras = selection.cameraIds ?? [], ids = selection.layerKeyIds ?? []; assertEditable(p, cameras);
  const camera = t.keys.filter(k => cameras.includes(k.stopId)).map(k => ({ stop: structuredClone(p.stops.find(s => s.id === k.stopId)!), time: k.time, interpolation: k.interpolation === 'legacy' ? 'ease' as const : k.interpolation }));
  const layers = t.layers.flatMap(l => l.keys.filter(k => ids.includes(k.id)).map(k => ({ layerId: l.layerId, visible: k.visible, time: k.time })));
  if (!camera.length && !layers.length) throw new Error('Select one or more editable timeline keys first');
  return { camera, layers, origin: Math.min(...camera.map(k => k.time), ...layers.map(k => k.time)), projectId: p.id };
}
export function pasteTimelineKeys(p: Project, clipboard: TimelineClipboard, time: number): void {
  if (clipboard.projectId !== p.id) throw new Error('Copy keys from this project before pasting');
  const t = ensureTimeline(p), start = snapTime(time, t.fps), original = clipRanges(p);
  for (const item of clipboard.camera) {
    const at = start + item.time - clipboard.origin;
    if (t.keys.some(k => Math.abs(k.time - at) < 1e-7)) throw new Error('A camera key already exists at the paste time. Move the playhead to an empty time.');
    if (at > t.duration || at < 0) throw new Error('Extend the timeline before pasting beyond its duration');
    const stop = structuredClone(item.stop); stop.id = uuid(); stop.name = `${stop.name} copy`.slice(0, 200); stop.hold = 0; delete stop.photo;
    p.stops.push(stop); t.keys.push({ stopId: stop.id, time: at, interpolation: item.interpolation });
  }
  for (const item of clipboard.layers) captureLayerKey(p, item.layerId, start + item.time - clipboard.origin, item.visible);
  syncTimeline(p); preserveClips(p, original);
}
