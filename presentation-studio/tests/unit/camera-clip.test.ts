import { describe, expect, test } from 'vitest';
import { Quaternion } from 'three';
import { encode } from '../../src/core/hash';
import { emptyProject, reconnect, validateProject, type Project } from '../../src/core/model';
import { cameraAt, cameraReference, parseCameraClip, CAMERA_FILE_LIMIT, type CameraClip } from '../../src/presentation/camera-clip';
import { Evaluator } from '../../src/presentation/evaluate';

export function sampleClip(): CameraClip {
  return { format: 'cyrus-camera-animation', version: 1, units: 'metres', up: 'Y', name: 'Owned camera', fps: 30, aspect: 16 / 9, source: { application: '3ds Max 2027', exporterVersion: '0.1.1', cameraType: 'FreeCamera', startTick: 1600, endTick: 11200, ticksPerSecond: 4800, samplesPerFrame: 4 }, samples: [
    { time: 0, position: [0, 2, 5], quaternion: [0, 0, 0, 1], fov: 40 },
    { time: .5, position: [1, 3, 4], quaternion: [0, Math.SQRT1_2, 0, Math.SQRT1_2], fov: 60 },
    { time: 2, position: [10, 4, 1], quaternion: [0, 1, 0, 0], fov: 50 },
  ] };
}
export function boundProject(clip = sampleClip(), hash = 'a'.repeat(64)): Project {
  const p = emptyProject(); p.opening = 2; p.revealDuration = 5;
  p.schemaVersion = 2; p.stops = [clip.samples[0], clip.samples.at(-1)!].map((s, i) => ({ id: `stop-${i}`, name: `View ${i}`, position: s.position, quaternion: s.quaternion, fov: s.fov, aspect: clip.aspect, hold: 0 }));
  reconnect(p); Object.assign(p.segments[0], { duration: 2, ease: 0, cameraClip: cameraReference(hash, clip) }); return p;
}

describe('sampled camera contract', () => {
  test('ordinary schema 1 projects remain readable; imported clips require schema 2 to guard older readers', () => {
    expect(validateProject(emptyProject()).schemaVersion).toBe(1);
    const p = boundProject(); expect(validateProject(p).schemaVersion).toBe(2);
    p.schemaVersion = 1; expect(() => validateProject(p)).toThrow('schema 2');
  });
  test('aggregate decoded sample work is bounded independently of the archive byte budget', () => {
    const p = boundProject(); p.stops = Array.from({ length: 7 }, (_, i) => ({ ...p.stops[0], id: `bounded-${i}` })); reconnect(p);
    p.segments.forEach((s, i) => Object.assign(s, { duration: 2, ease: 0, cameraClip: { ...cameraReference(i.toString().repeat(64), sampleClip()), sampleCount: 20000 } }));
    expect(() => validateProject(p)).toThrow('100,000');
  });
  test('accelerating motion and nonuniform timestamps are preserved without arc-length easing', () => {
    const clip = parseCameraClip(encode(sampleClip())), e = new Evaluator(boundProject(clip), new Map([['a'.repeat(64), clip]]));
    expect(e.evaluate(7.5).position).toEqual([1, 3, 4]); expect(e.evaluate(8).position).toEqual([4, 3 + 1 / 3, 3]);
    expect(e.evaluate(7.25).fov).toBe(50); expect(e.evaluate(9).position).toEqual([10, 4, 1]);
  });
  test('random and reverse seeks are stateless and quaternions use shortest-path interpolation', () => {
    const clip = sampleClip(), forward = [0, .25, .5, 1, 2].map(t => cameraAt(clip, t));
    expect([2, 1, .5, .25, 0].map(t => cameraAt(clip, t)).reverse()).toEqual(forward);
    clip.samples[1].quaternion = clip.samples[1].quaternion.map(v => -v) as any;
    expect(Math.abs(new Quaternion().fromArray(cameraAt(clip, .25).quaternion).dot(new Quaternion().fromArray(forward[1].quaternion)))).toBeCloseTo(1, 12);
  });
  test('reduced motion selects endpoints while source aspect stays fixed in portrait playback', () => {
    const clip = sampleClip(), e = new Evaluator(boundProject(clip), new Map([['a'.repeat(64), clip]]));
    expect(e.evaluate(7.4, true).aspect).toBe(16 / 9); expect(e.evaluate(7.4, true, {}, true).position).toEqual(clip.samples[0].position);
    expect(e.evaluate(8.4, true, {}, true).position).toEqual(clip.samples.at(-1)!.position);
  });
  test('unknown fields, formats, nonfinite values and excessive sample/file sizes reject', () => {
    expect(() => parseCameraClip(new Uint8Array(CAMERA_FILE_LIMIT + 1))).toThrow('4 MiB');
    for (const mutate of [(c: any) => { c.units = 'centimetres'; }, (c: any) => { c.extra = 'C:/private.max'; }, (c: any) => { c.samples[0].fov = null; }, (c: any) => { c.samples = Array(20001).fill(c.samples[0]); }, (c: any) => { c.samples[1].quaternion = [0, 0, 0, 2]; }]) {
      const clip = sampleClip(); mutate(clip); expect(() => parseCameraClip(encode(clip))).toThrow();
    }
  });
  test('duplicate times, missing first sample and mismatched source duration reject', () => {
    for (const times of [[0, 0, 2], [.1, .5, 2], [0, .5, 3]]) {
      const clip = sampleClip(); clip.samples.forEach((s, i) => { s.time = times[i]; }); expect(() => parseCameraClip(encode(clip))).toThrow();
    }
  });
  test('missing resources, tampered metadata and modified endpoints fail instead of using the fallback path', () => {
    const clip = sampleClip(), p = boundProject(clip), clips = new Map([['a'.repeat(64), clip]]);
    expect(() => new Evaluator(p)).toThrow('Missing');
    p.segments[0].cameraClip!.sampleCount++; expect(() => new Evaluator(p, clips)).toThrow('metadata');
    p.segments[0].cameraClip!.sampleCount--; p.stops[0].position = [99, 0, 0]; expect(() => new Evaluator(p, clips)).toThrow('endpoints');
  });
});
