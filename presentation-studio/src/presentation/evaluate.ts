import { Matrix4, Quaternion, Vector3 } from 'three';
import { cameraAt, validateCameraBindings, type CameraClips } from './camera-clip';
import { contentFingerprint } from '../core/hash';
import type { Project, Segment, Stop, Vec3, Quat } from '../core/model';
import { authoredVisibility } from './timeline';

export interface ArcTable { u: number[]; distance: number[]; length: number; }
export function bezier(a: Vec3, b: Vec3, c: Vec3, d: Vec3, u: number): Vec3 {
  const v = 1 - u;
  return a.map((x, i) => v ** 3 * x + 3 * v ** 2 * u * b[i] + 3 * v * u ** 2 * c[i] + u ** 3 * d[i]) as Vec3;
}
const mix = (a: Vec3, b: Vec3): Vec3 => a.map((x, i) => (x + b[i]) / 2) as Vec3;
const distance = (a: Vec3, b: Vec3) => Math.hypot(...a.map((x, i) => x - b[i]));
export function arcTable(a: Vec3, b: Vec3, c: Vec3, d: Vec3, tolerance = 0.00001): ArcTable {
  const table: ArcTable = { u: [0], distance: [0], length: 0 }; let previous = a;
  const split = (p0: Vec3, p1: Vec3, p2: Vec3, p3: Vec3, lo: number, hi: number, depth: number) => {
    const polygon = distance(p0, p1) + distance(p1, p2) + distance(p2, p3);
    if (depth >= 15 || polygon - distance(p0, p3) <= tolerance && hi - lo <= 1 / 256) {
      table.length += distance(previous, p3); table.u.push(hi); table.distance.push(table.length); previous = p3; return;
    }
    const p01 = mix(p0, p1), p12 = mix(p1, p2), p23 = mix(p2, p3), p012 = mix(p01, p12), p123 = mix(p12, p23), mid = mix(p012, p123), t = (lo + hi) / 2;
    split(p0, p01, p012, mid, lo, t, depth + 1); split(mid, p123, p23, p3, t, hi, depth + 1);
  };
  split(a, b, c, d, 0, 1, 0); return table;
}
export function parameterAt(table: ArcTable, fraction: number): number {
  if (table.length < 1e-10) return Math.min(1, Math.max(0, fraction));
  const target = Math.min(1, Math.max(0, fraction)) * table.length; let lo = 0, hi = table.distance.length - 1;
  while (hi - lo > 1) { const mid = (lo + hi) >>> 1; if (table.distance[mid] < target) lo = mid; else hi = mid; }
  const span = table.distance[hi] - table.distance[lo];
  return table.u[lo] + (table.u[hi] - table.u[lo]) * (span > 1e-12 ? (target - table.distance[lo]) / span : 0);
}
export function easedDistance(t: number, ease: number): number {
  t = Math.min(1, Math.max(0, t)); if (!ease) return t;
  const ramp = (x: number) => x ** 3 - x ** 4 / 2;
  if (t < ease) return ease * ramp(t / ease) / (1 - ease);
  if (t > 1 - ease) return 1 - ease * ramp((1 - t) / ease) / (1 - ease);
  return (t - ease / 2) / (1 - ease);
}
export function duration(p: Project): number { return p.timeline?.duration ?? p.opening + p.revealDuration + p.stops.reduce((n, s) => n + s.hold, 0) + p.segments.reduce((n, s) => n + s.duration, 0); }
export function stopTime(p: Project, stopId: string): number {
  if (p.timeline) { const key = p.timeline.keys.find(k => k.stopId === stopId); return key ? key.time + (p.stops.find(s => s.id === stopId)?.hold ?? 0) / 2 : p.timeline.duration; }
  let t = p.opening + p.revealDuration;
  for (let i = 0; i < p.stops.length; i++) { if (p.stops[i].id === stopId) return t + p.stops[i].hold / 2; t += p.stops[i].hold + (p.segments[i]?.duration ?? 0); }
  return duration(p);
}
export function sceneFingerprint(p: Project): string {
  return contentFingerprint({ scene: p.instances.map(i => ({ revision: i.assetRevision, transform: i.transform, membership: i.membership })), assets: p.assets.map(a => ({ revision: a.revisionId, hash: a.hash })), layers: p.layers.map(l => ({ id: l.id, included: l.included, visible: l.defaultVisible })), ...(p.timeline?.layers.some(l => l.keys.length) ? { visibilityTracks: p.timeline.layers } : {}), lighting: p.lighting });
}
export function photoFingerprint(p: Project, s: Stop, scene = sceneFingerprint(p)): string {
  return contentFingerprint({ scene, pose: { position: s.position, quaternion: s.quaternion, fov: s.fov, aspect: s.aspect, portrait: s.portrait } });
}
export const stalePhoto = (p: Project, s: Stop, scene?: string) => !!s.photo && s.photo.approvedFingerprint !== photoFingerprint(p, s, scene);
export interface Evaluation {
  position: Vec3; quaternion: Quat; fov: number; aspect: number;
  visible: Record<string, boolean>; layerFade: Record<string, number>; reveal: number; planOpacity: number;
  phase: 'plan' | 'reveal' | 'hold' | 'travel'; stopId: string | null;
  photo: { hash: string; caption: string; opacity: number } | null;
}
export class Evaluator {
  private tables = new Map<string, ArcTable>();
  private stale = new Map<string, boolean>();
  constructor(public project: Project, private clips: CameraClips = new Map()) { validateCameraBindings(project, clips); const scene = sceneFingerprint(project); for (const stop of project.stops) this.stale.set(stop.id, stalePhoto(project, stop, scene)); }
  photoStale(stopId: string) { return this.stale.get(stopId) ?? false; }
  table(s: Segment): ArcTable {
    if (!this.tables.has(s.id)) { const a = this.project.stops.find(x => x.id === s.from)!, b = this.project.stops.find(x => x.id === s.to)!; this.tables.set(s.id, arcTable(a.position, s.control1, s.control2, b.position)); }
    return this.tables.get(s.id)!;
  }
  evaluate(time: number, portrait = false, choices: Record<string, boolean> = {}, reducedMotion = false): Evaluation {
    const p = this.project, t = Math.min(duration(p), Math.max(0, time));
    const reveal = p.revealDuration ? Math.min(1, Math.max(0, (t - p.opening) / p.revealDuration)) : +(t >= p.opening);
    const visible = Object.fromEntries(p.layers.map(l => { const authored = authoredVisibility(p, l.id, t); return [l.id, l.included && reveal >= l.reveal && (l.viewerToggle ? choices[l.id] ?? authored : authored)]; }));
    const layerFade = Object.fromEntries(p.layers.map(l => { const span = Math.min(1 - l.reveal, l.fade ?? 0.12); return [l.id, !visible[l.id] ? 0 : !span || reveal >= 1 ? 1 : Math.min(1, Math.max(0, (reveal - l.reveal) / span))]; }));
    let stop = p.stops[0], position = stop.position, quaternion = stop.quaternion, fov = stop.fov, aspect = stop.aspect;
    let phase: Evaluation['phase'] = t < p.opening ? 'plan' : t < p.opening + p.revealDuration ? 'reveal' : 'hold';
    let stopId: string | null = stop.id, photo: Evaluation['photo'] = null, cursor = p.timeline?.keys[0].time ?? p.opening + p.revealDuration;
    const mismatch = p.layers.some(l => l.included && (l.viewerToggle ? choices[l.id] ?? authoredVisibility(p, l.id, t) : authoredVisibility(p, l.id, t)) !== l.defaultVisible);
    for (let i = 0; i < p.stops.length && t >= cursor; i++) {
      stop = p.stops[i]; position = stop.position; quaternion = stop.quaternion; fov = stop.fov; aspect = stop.aspect; stopId = stop.id; phase = 'hold';
      const holdEnd = cursor + stop.hold;
      if (t <= holdEnd || i === p.stops.length - 1) {
        if (portrait && stop.portrait) ({ position, quaternion, fov, aspect } = stop.portrait);
        if (stop.photo && !this.photoStale(stop.id) && !mismatch && stop.hold > 0) {
          const fade = Math.min(0.5, stop.hold / 3), opacity = reducedMotion ? 1 : Math.min(1, (t - cursor) / fade, i === p.stops.length - 1 ? 1 : (holdEnd - t) / fade);
          if (opacity > 0) photo = { hash: portrait && stop.photo.portraitHash ? stop.photo.portraitHash : stop.photo.hash, caption: stop.photo.caption, opacity };
        }
        break;
      }
      cursor = holdEnd; const segment = p.segments[i]; if (!segment) break;
      if (t < cursor + segment.duration) {
        const end = p.stops[i + 1], progress = segment.duration ? (t - cursor) / segment.duration : 1, fraction = p.timeline?.keys[i].interpolation === 'hold' ? 0 : easedDistance(progress, segment.ease);
        if (segment.cameraClip) ({ position, quaternion, fov, aspect } = cameraAt(this.clips.get(segment.cameraClip.hash)!, t - cursor));
        else {
        position = bezier(stop.position, segment.control1, segment.control2, end.position, parameterAt(this.table(segment), fraction));
        quaternion = new Quaternion().fromArray(stop.quaternion).normalize().slerp(new Quaternion().fromArray(end.quaternion).normalize(), fraction).toArray() as Quat;
        fov = stop.fov + (end.fov - stop.fov) * fraction; aspect = stop.aspect + (end.aspect - stop.aspect) * fraction;
        if (portrait && (stop.portrait || end.portrait)) {
          const a = stop.portrait ?? stop, b = end.portrait ?? end;
          const c1 = segment.control1.map((v, j) => v + a.position[j] - stop.position[j]) as Vec3, c2 = segment.control2.map((v, j) => v + b.position[j] - end.position[j]) as Vec3;
          const key = `${segment.id}:portrait`; if (!this.tables.has(key)) this.tables.set(key, arcTable(a.position, c1, c2, b.position));
          position = bezier(a.position, c1, c2, b.position, parameterAt(this.tables.get(key)!, fraction));
          quaternion = new Quaternion().fromArray(a.quaternion).normalize().slerp(new Quaternion().fromArray(b.quaternion).normalize(), fraction).toArray() as Quat;
          fov = a.fov + (b.fov - a.fov) * fraction; aspect = a.aspect + (b.aspect - a.aspect) * fraction;
        }
        }
        if (reducedMotion) { const frame = progress < .5 ? stop : end; ({ position, quaternion, fov, aspect } = frame); }
        phase = 'travel'; stopId = null; break;
      }
      cursor += segment.duration;
    }
    return { position, quaternion: new Quaternion().fromArray(quaternion).normalize().toArray() as Quat, fov, aspect, visible, layerFade, reveal, planOpacity: p.plan ? 1 - reveal : 0, phase, stopId, photo };
  }
}
export function lookQuaternion(position: Vec3, target: Vec3): Quat {
  const direction = new Vector3().fromArray(target).sub(new Vector3().fromArray(position));
  if (direction.lengthSq() < 1e-12) throw new Error('Look target must differ from camera position');
  const up = Math.abs(direction.clone().normalize().y) > 0.999 ? new Vector3(0, 0, 1) : new Vector3(0, 1, 0);
  return new Quaternion().setFromRotationMatrix(new Matrix4().lookAt(new Vector3().fromArray(position), new Vector3().fromArray(target), up)).toArray() as Quat;
}
