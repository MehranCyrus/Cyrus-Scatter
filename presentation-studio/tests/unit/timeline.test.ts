import { expect, test } from 'vitest';
import { createDemo } from '../../src/assets/demo';
import { History } from '../../src/core/history';
import { emptyProject, reconnect, validateProject } from '../../src/core/model';
import { Evaluator, duration } from '../../src/presentation/evaluate';
import { cameraReference, type CameraClip } from '../../src/presentation/camera-clip';
import { authoredVisibility, captureLayerKey, copyTimelineKeys, deleteTimelineKeys, ensureTimeline, insertCameraKey, moveTimelineKeys, pasteTimelineKeys, syncTimeline, timelineOf } from '../../src/presentation/timeline';

function timed() {
  const p = emptyProject(); p.opening = p.revealDuration = 0; p.stops[0].hold = 0; p.stops[0].position = [0, 0, 0];
  p.stops.push({ ...structuredClone(p.stops[0]), id: 'second', position: [10, 0, 0], fov: 70 }); reconnect(p); p.segments[0].duration = 10;
  const t = ensureTimeline(p); t.keys[0].interpolation = 'linear'; t.duration = 20; syncTimeline(p); return p;
}
function clipProject() {
  const clip: CameraClip = { format: 'cyrus-camera-animation', version: 1, units: 'metres', up: 'Y', name: 'Protected', fps: 30, aspect: 16 / 9, source: { application: '3ds Max 2027', exporterVersion: '0.1.1', cameraType: 'FreeCamera', startTick: 0, endTick: 9600, ticksPerSecond: 4800, samplesPerFrame: 4 }, samples: [
    { time: 0, position: [0, 2, 5], quaternion: [0, 0, 0, 1], fov: 40 },
    { time: .5, position: [1, 3, 4], quaternion: [0, Math.SQRT1_2, 0, Math.SQRT1_2], fov: 60 },
    { time: 2, position: [10, 4, 1], quaternion: [0, 1, 0, 0], fov: 50 },
  ] };
  const p = emptyProject(); p.schemaVersion = 2; p.stops = [clip.samples[0], clip.samples[2]].map((s, i) => ({ id: `clip-${i}`, name: `View ${i}`, position: s.position, quaternion: s.quaternion, fov: s.fov, aspect: clip.aspect, hold: 0 })); reconnect(p);
  Object.assign(p.segments[0], { duration: 2, ease: 0, cameraClip: cameraReference('a'.repeat(64), clip) }); return { p, clip };
}

test('schema conversion preserves every old camera pose, reveal, hold and curved path through random and reverse seeks', async () => {
  const { project: p } = await createDemo(); p.segments[0].control1 = [50, 25, -15];
  const original = structuredClone(p), before = new Evaluator(p), times = [0, 2, 6.7, 7, 8.2, 10, 15.32, duration(p)];
  expect(timelineOf(p).keys).toHaveLength(p.stops.length); expect(p).toEqual(original);
  ensureTimeline(p); expect(validateProject(p).schemaVersion).toBe(3); const after = new Evaluator(p);
  for (const t of [...times, ...[...times].reverse()]) expect(after.evaluate(t)).toEqual(before.evaluate(t));
});
test('absolute camera keys support linear, ease and hold with exact endpoint continuity and no previous-frame state', () => {
  const p = timed(); expect(new Evaluator(p).evaluate(5).position).toEqual([5, 0, 0]); expect(new Evaluator(p).evaluate(5).fov).toBe(57.5);
  p.timeline!.keys[0].interpolation = 'ease'; syncTimeline(p); expect(new Evaluator(p).evaluate(1).position[0]).toBeLessThan(1);
  p.timeline!.keys[0].interpolation = 'hold'; syncTimeline(p); const e = new Evaluator(p);
  expect(e.evaluate(9.999).position).toEqual([0, 0, 0]); expect(e.evaluate(10).position).toEqual([10, 0, 0]); expect(e.evaluate(1)).toEqual(e.evaluate(1));
});
test('capture inserts at the playhead, updates an existing time, and preserves independently timed later keys', () => {
  const p = timed(), pose = { position: [3, 4, 5] as [number, number, number], quaternion: [0, 0, 0, 1] as [number, number, number, number], fov: 55, aspect: 16 / 9 };
  const id = insertCameraKey(p, pose, 5.012); expect(p.timeline!.keys.find(k => k.stopId === id)!.time).toBe(5);
  const same = insertCameraKey(p, { ...pose, fov: 62 }, 5); expect(same).toBe(id); expect(p.stops).toHaveLength(3); expect(p.stops.find(s => s.id === id)!.fov).toBe(62);
  expect(p.timeline!.keys.at(-1)!.time).toBe(10); expect(validateProject(p)).toBeDefined();
});
test('multi-key movement commits atomically, keeps offsets, rejects collisions and restores exact state with undo', () => {
  const p = timed(); p.layers = [{ id: 'trees', name: 'Trees', included: true, defaultVisible: true, viewerToggle: true, reveal: 0 }]; captureLayerKey(p, 'trees', 3, false);
  const h = new History(p), before = structuredClone(h.current), layerId = p.timeline!.layers[0].keys[0].id;
  h.commit(d => moveTimelineKeys(d, { cameraIds: ['second'], layerKeyIds: [layerId] }, 2));
  expect(h.current.timeline!.keys.at(-1)!.time).toBe(12); expect(h.current.timeline!.layers[0].keys[0].time).toBe(5);
  const moved = structuredClone(h.current); expect(() => h.commit(d => moveTimelineKeys(d, { cameraIds: ['second'] }, -12))).toThrow('same time'); expect(h.current).toEqual(moved);
  expect(() => h.commit(d => moveTimelineKeys(d, { layerKeyIds: [layerId] }, -6))).toThrow('within'); expect(h.current).toEqual(moved);
  h.undo(); expect(h.current).toEqual(before); h.redo(); expect(h.current).toEqual(moved);
});
test('layer keys use step visibility at boundaries, gates still apply, viewer overrides reset to the schedule', () => {
  const p = timed(); p.layers = [{ id: 'trees', name: 'Trees', included: true, defaultVisible: true, viewerToggle: true, reveal: 0 }];
  captureLayerKey(p, 'trees', 3, false); captureLayerKey(p, 'trees', 8, true); const e = new Evaluator(p);
  expect(authoredVisibility(p, 'trees', 2.99)).toBe(true); expect(e.evaluate(3).visible.trees).toBe(false); expect(e.evaluate(8).visible.trees).toBe(true);
  expect(e.evaluate(4, false, { trees: true }).visible.trees).toBe(true); expect(e.evaluate(4, false, {}).visible.trees).toBe(false);
  p.layers[0].included = false; expect(new Evaluator(p).evaluate(4, false, { trees: true }).visible.trees).toBe(false);
  p.layers[0].included = true; p.opening = 2; p.revealDuration = 3; p.layers[0].reveal = 1; expect(new Evaluator(p).evaluate(4, false, { trees: true }).visible.trees).toBe(false);
});
test('protected Max clips survive conversion and surrounding keys while splitting, retiming and deletion fail atomically', () => {
  const { p, clip } = clipProject(), clips = new Map([['a'.repeat(64), clip]]), original = new Evaluator(p, clips);
  const h = new History(p); h.commit(d => { insertCameraKey(d, { ...d.stops[0], position: [-10, 5, 10] }, 0); });
  const e = new Evaluator(h.current, clips); for (const t of [7, 7.135, 7.5, 8.72, 9]) expect(e.evaluate(t).position).toEqual(original.evaluate(t).position);
  const before = structuredClone(h.current);
  expect(() => h.commit(d => insertCameraKey(d, d.stops[0], 8))).toThrow('protected');
  expect(() => h.commit(d => moveTimelineKeys(d, { cameraIds: ['clip-0'] }, 1))).toThrow('protected');
  expect(() => h.commit(d => deleteTimelineKeys(d, { cameraIds: ['clip-1'] }))).toThrow('protected'); expect(h.current).toEqual(before);
});
test('copy/paste retains relative offsets and visibility values, rejects conflicts, and deletion keeps a camera owner', () => {
  const p = timed(); p.layers = [{ id: 'trees', name: 'Trees', included: true, defaultVisible: true, viewerToggle: false, reveal: 0 }]; captureLayerKey(p, 'trees', 11, false);
  const clip = copyTimelineKeys(p, { cameraIds: ['second'], layerKeyIds: [p.timeline!.layers[0].keys[0].id] }); pasteTimelineKeys(p, clip, 15);
  expect(p.timeline!.keys.at(-1)!.time).toBe(15); expect(p.timeline!.layers[0].keys.at(-1)!.time).toBe(16); expect(authoredVisibility(p, 'trees', 16)).toBe(false);
  expect(validateProject(p)).toBeDefined(); const h = new History(p), before = structuredClone(h.current);
  expect(() => h.commit(d => pasteTimelineKeys(d, clip, 10))).toThrow('already exists'); expect(h.current).toEqual(before);
  expect(() => h.commit(d => deleteTimelineKeys(d, { cameraIds: d.stops.map(s => s.id) }))).toThrow('at least');
});
test('malformed schemas, dangling tracks, inconsistent durations and duplicate visibility times are rejected', () => {
  const p = timed(); expect(() => validateProject({ ...p, timeline: undefined })).toThrow('schema 3');
  const bad = structuredClone(p); bad.timeline!.keys[1].time = 11; expect(() => validateProject(bad)).toThrow('disagree');
  p.timeline!.layers = [{ layerId: 'missing', keys: [] }]; expect(() => validateProject(p)).toThrow('missing layer');
});
test('a visibility key at a subframe timeline end stays in bounds, and empty deletion cannot create a history edit', () => {
  const p = timed(); p.timeline!.duration = 20.02; p.layers = [{ id: 'paths', name: 'Paths', included: true, defaultVisible: true, viewerToggle: true, reveal: 0 }];
  captureLayerKey(p, 'paths', 20.02, false); expect(p.timeline!.layers[0].keys[0].time).toBe(20.02); expect(validateProject(p)).toBeDefined();
  const h = new History(p), before = structuredClone(h.current); expect(() => h.commit(d => deleteTimelineKeys(d, {}))).toThrow('Select'); expect(h.current).toEqual(before);
  p.timeline!.layers[0].keys.push({ id: 'duplicate-time', time: 20.02, visible: true }); expect(() => validateProject(p)).toThrow('unique');
});
