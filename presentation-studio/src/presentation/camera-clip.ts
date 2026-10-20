import { z } from 'zod';
import { Quaternion } from 'three';
import { sha256 } from '../core/hash';
import { quat, vec3, type Files, type Project, type Quat, type Vec3 } from '../core/model';

export const CAMERA_FILE_LIMIT = 4 * 1024 * 1024;
const sampleSchema = z.strictObject({ time: z.number().finite().min(0).max(3600), position: vec3, quaternion: quat, fov: z.number().finite().min(10).max(110) });
export const cameraClipSchema = z.strictObject({
  format: z.literal('cyrus-camera-animation'), version: z.literal(1),
  units: z.literal('metres'), up: z.literal('Y'), name: z.string().min(1).max(200),
  fps: z.number().finite().positive().max(4800), aspect: z.number().finite().min(.3).max(4),
  source: z.strictObject({ application: z.literal('3ds Max 2027'), exporterVersion: z.literal('0.1.1'), cameraType: z.enum(['FreeCamera', 'TargetCamera', 'Physical']), startTick: z.number().int().safe(), endTick: z.number().int().safe(), ticksPerSecond: z.literal(4800), samplesPerFrame: z.union([z.literal(1), z.literal(2), z.literal(4)]) }),
  samples: z.array(sampleSchema).min(2).max(20000),
});
export type CameraClip = z.infer<typeof cameraClipSchema>;
export type CameraClips = ReadonlyMap<string, CameraClip>;
export type CameraSample = CameraClip['samples'][number];

export function parseCameraClip(bytes: Uint8Array): CameraClip {
  if (!bytes.length || bytes.length > CAMERA_FILE_LIMIT) throw new Error('Camera animation exceeds the 4 MiB limit');
  let value: unknown;
  try { value = JSON.parse(new TextDecoder('utf-8', { fatal: true }).decode(bytes).replace(/^\uFEFF/, '')); } catch { throw new Error('Camera animation must be a valid UTF-8 JSON file'); }
  const clip = cameraClipSchema.parse(value), samples = clip.samples;
  const duration = samples.at(-1)!.time;
  if (samples[0].time !== 0 || duration <= 0 || clip.source.endTick <= clip.source.startTick || Math.abs(duration - (clip.source.endTick - clip.source.startTick) / 4800) > 1e-6) throw new Error('Camera animation has an invalid source time range');
  for (let i = 0; i < samples.length; i++) {
    const s = samples[i];
    if (i && s.time <= samples[i - 1].time) throw new Error('Camera sample times must increase strictly');
    if (Math.abs(Math.hypot(...s.quaternion) - 1) > .001) throw new Error('Camera quaternion must be normalized');
    s.quaternion = new Quaternion().fromArray(s.quaternion).normalize().toArray() as Quat;
  }
  return clip;
}

export function cameraReference(hash: string, clip: CameraClip) {
  return { hash, name: clip.name, duration: clip.samples.at(-1)!.time, sampleCount: clip.samples.length, fps: clip.fps, aspect: clip.aspect };
}

/** Stateless time lookup: random seeks and reverse playback follow the same source samples. */
export function cameraAt(clip: CameraClip, time: number): CameraSample & { aspect: number } {
  const samples = clip.samples, t = Math.max(0, Math.min(samples.at(-1)!.time, time));
  let lo = 0, hi = samples.length - 1;
  while (hi - lo > 1) { const mid = (lo + hi) >>> 1; if (samples[mid].time <= t) lo = mid; else hi = mid; }
  const a = samples[lo], b = samples[hi], u = (t - a.time) / (b.time - a.time);
  return { time: t, position: a.position.map((v, i) => v + (b.position[i] - v) * u) as Vec3, quaternion: new Quaternion().fromArray(a.quaternion).slerp(new Quaternion().fromArray(b.quaternion), u).normalize().toArray() as Quat, fov: a.fov + (b.fov - a.fov) * u, aspect: clip.aspect };
}

export function validateCameraBindings(project: Project, clips: CameraClips) {
  for (const segment of project.segments) if (segment.cameraClip) {
    const ref = segment.cameraClip, clip = clips.get(ref.hash);
    if (!clip) throw new Error('Missing imported camera animation');
    if (JSON.stringify(ref) !== JSON.stringify(cameraReference(ref.hash, clip))) {
      // Key order is irrelevant to a persisted JSON object.
      const actual = cameraReference(ref.hash, clip);
      if (Object.entries(actual).some(([key, value]) => ref[key as keyof typeof ref] !== value)) throw new Error('Imported camera metadata does not match its resource');
    }
    const start = project.stops.find(s => s.id === segment.from)!, end = project.stops.find(s => s.id === segment.to)!;
    for (const [stop, sample] of [[start, clip.samples[0]], [end, clip.samples.at(-1)!]] as const) {
      if (stop.portrait || stop.aspect !== clip.aspect || Math.abs(stop.fov - sample.fov) > 1e-8 || stop.position.some((v, i) => Math.abs(v - sample.position[i]) > 1e-8) || 1 - Math.abs(new Quaternion().fromArray(stop.quaternion).normalize().dot(new Quaternion().fromArray(sample.quaternion))) > 1e-8) throw new Error('Imported camera endpoints must match the source animation');
    }
  }
}

export async function loadCameraClips(project: Project, blobs: Files, cached: CameraClips = new Map()): Promise<Map<string, CameraClip>> {
  const clips = new Map<string, CameraClip>(); let samples = 0;
  for (const segment of project.segments) if (segment.cameraClip && !clips.has(segment.cameraClip.hash)) {
    const hash = segment.cameraClip.hash, bytes = blobs.get(hash);
    if (!bytes || await sha256(bytes) !== hash) throw new Error('Missing or corrupt imported camera animation');
    const clip = cached.get(hash) ?? parseCameraClip(bytes); samples += clip.samples.length;
    if (samples > 100000) throw new Error('Project camera animations exceed 100,000 unique samples');
    clips.set(hash, clip);
  }
  validateCameraBindings(project, clips); return clips;
}
