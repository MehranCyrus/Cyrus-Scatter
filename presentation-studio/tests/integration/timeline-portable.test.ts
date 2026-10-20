import { expect, test } from 'vitest';
import { createDemo } from '../../src/assets/demo';
import { compile } from '../../src/compiler/compile';
import { encode } from '../../src/core/hash';
import { Evaluator, duration } from '../../src/presentation/evaluate';
import { captureLayerKey, ensureTimeline, insertCameraKey, moveTimelineKeys } from '../../src/presentation/timeline';
import { packSync, projectFiles, readProjectArchive } from '../../src/storage/archive';

test('absolute camera/layer animation survives portable save/reopen and public compilation at every boundary', async () => {
  const { project: p, blobs } = await createDemo(), layer = p.layers[6];
  ensureTimeline(p); const newId = insertCameraKey(p, { position: [5, 15, 25], quaternion: [0, 0, 0, 1], fov: 63, aspect: 16 / 9 }, 0);
  moveTimelineKeys(p, { cameraIds: [newId] }, 1); captureLayerKey(p, layer.id, 12, false); captureLayerKey(p, layer.id, 20, true);
  const original = new Evaluator(p), opened = await readProjectArchive(packSync(await projectFiles(p, blobs))), restored = new Evaluator(opened.project);
  expect(opened.project).toEqual(p); expect(opened.project.schemaVersion).toBe(3);
  const output = await compile(p, blobs, new Map([['index.html', encode('owned test shell')]])), published = new Evaluator(output.manifest.project);
  expect(output.manifest.playerVersion).toBe('0.3.0'); expect(output.manifest.project.timeline).toEqual(p.timeline);
  for (const t of [0, 1, 6.999, 7, 11.999, 12, 15.321, 19.999, 20, duration(p), 12, 1]) {
    expect(restored.evaluate(t)).toEqual(original.evaluate(t)); expect(published.evaluate(t)).toEqual(original.evaluate(t));
  }
});
test('excluded layers and their authored tracks are removed from public output together', async () => {
  const { project: p, blobs } = await createDemo(), layer = p.layers[6]; captureLayerKey(p, layer.id, 12, true); layer.included = false;
  const out = await compile(p, blobs, new Map([['index.html', encode('owned test shell')]]));
  expect(out.manifest.project.layers.some(l => l.id === layer.id)).toBe(false); expect(out.manifest.project.timeline!.layers.some(l => l.layerId === layer.id)).toBe(false);
  expect(new Evaluator(out.manifest.project).evaluate(20).visible[layer.id]).toBeUndefined();
});
