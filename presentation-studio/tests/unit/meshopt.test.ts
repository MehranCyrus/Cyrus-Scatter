import { beforeAll, expect, it, vi } from 'vitest';
import { MeshoptDecoder } from 'three/addons/libs/meshopt_decoder.module.js';
import { MeshoptEncoder } from 'meshoptimizer';
import { meshoptFixture } from '../helpers/meshopt-fixture';
import { inspectGLB, readGLB, writeGLB, LIMITS } from '../../src/assets/glb';
import { decodeMeshopt, planMeshopt, MESHOPT } from '../../src/assets/meshopt';
let original: Uint8Array, compressed: Uint8Array;
beforeAll(async () => { ({ original, compressed } = await meshoptFixture()); });

it('inspects decoded numeric data while retaining the compressed hash/size and original layer identities', async () => {
  const a = await inspectGLB(original, 'source'), b = await inspectGLB(compressed, 'compressed');
  expect(b.bounds).toEqual(a.bounds); expect(b.triangles).toBe(a.triangles); expect(b.bytes).toBe(compressed.length);
  expect(b.nodes.filter(n => n.renderable).map(n => n.externalId)).toEqual(a.nodes.filter(n => n.renderable).map(n => n.externalId));
  expect(b.warnings).toEqual([]); expect(b.gpuBytes).toBeGreaterThan(0);
  const copy = compressed.slice(); await decodeMeshopt(readGLB(compressed), LIMITS.expandedBytes); expect(compressed).toEqual(copy);
});

it('rejects all invalid ranges, sizes, filters and external buffers before decoder calls', async () => {
  const spy = vi.spyOn(MeshoptDecoder, 'decodeGltfBuffer');
  try {
    for (const change of [
      (j: any, v: any) => { v.extensions[MESHOPT].buffer = 1; },
      (j: any, v: any) => { v.extensions[MESHOPT].byteOffset = 999999999; },
      (j: any, v: any) => { v.extensions[MESHOPT].count = 30000001; },
      (j: any, v: any) => { v.extensions[MESHOPT].filter = 'CUSTOM'; },
      (j: any, v: any) => { v.byteStride = 123; },
      (j: any) => { j.buffers[1].uri = 'https://example.invalid/fallback'; },
      (j: any) => { j.buffers[1].byteLength = LIMITS.expandedBytes + 1; },
    ]) {
      const source = readGLB(compressed), j = structuredClone(source.json), view = j.bufferViews.find((v: any) => v.extensions?.[MESHOPT]); change(j, view);
      await expect(decodeMeshopt({ json: j, bin: source.bin }, LIMITS.expandedBytes)).rejects.toThrow();
    }
    const source = readGLB(compressed); expect(() => planMeshopt(source, 64)).toThrow(); expect(spy).not.toHaveBeenCalled();
  } finally { spy.mockRestore(); }
});

it('rejects corrupt streams and invalid decoded indices rather than trusting compressed metadata', async () => {
  const { json, bin } = readGLB(compressed), view = json.bufferViews.find((v: any) => v.extensions?.[MESHOPT]), broken = bin.slice();
  broken[view.extensions[MESHOPT].byteOffset ?? 0] = 0;
  await expect(inspectGLB(writeGLB(json, broken), 'corrupt')).rejects.toThrow('Meshopt');
  const decoded = await decodeMeshopt(readGLB(compressed), LIMITS.expandedBytes), primitive = decoded.json.meshes[0].primitives[0], a = decoded.json.accessors[primitive.indices], v = decoded.json.bufferViews[a.bufferView], bytes = decoded.bin.slice();
  const values = new DataView(bytes.buffer), offset = (v.byteOffset ?? 0) + (a.byteOffset ?? 0);
  if (a.componentType === 5123) values.setUint16(offset, 65535, true); else values.setUint32(offset, 0xffffffff, true);
  await expect(inspectGLB(writeGLB(decoded.json, bytes), 'bad indices')).rejects.toThrow('Mesh index exceeds');
});

it('accepts the standard optional fallback tag while still requiring no external data', async () => {
  const source = readGLB(compressed); delete source.json.buffers[1].extensions;
  expect(planMeshopt(source, LIMITS.expandedBytes)).not.toBeNull();
  await expect(inspectGLB(writeGLB(source.json, source.bin), 'untagged placeholder')).resolves.toHaveProperty('triangles');
});

it('decodes each standard filter and non-triangle index mode with the bundled decoder', async () => {
  await MeshoptEncoder.ready;
  const samples = [
    { filter: 'OCTAHEDRAL', stride: 4, data: MeshoptEncoder.encodeFilterOct(new Float32Array([1, 0, 0, 1]), 1, 4, 8), type: Int8Array, expected: [127, 0, 0, 127] },
    { filter: 'QUATERNION', stride: 8, data: MeshoptEncoder.encodeFilterQuat(new Float32Array([0, 0, 0, 1]), 1, 8, 16), type: Int16Array, expected: [0, 0, 0, 32767] },
    { filter: 'EXPONENTIAL', stride: 16, data: MeshoptEncoder.encodeFilterExp(new Float32Array([1.25, 2.5, 10, -.125]), 1, 16, 24), type: Float32Array, expected: [1.25, 2.5, 10, -.125] },
  ];
  for (const sample of samples) {
    const bin = MeshoptEncoder.encodeGltfBuffer(sample.data, 1, sample.stride, 'ATTRIBUTES');
    const decoded = await decodeMeshopt({ json: { extensionsRequired: [MESHOPT], buffers: [{ byteLength: bin.length }, { byteLength: sample.stride }], bufferViews: [{ buffer: 1, byteLength: sample.stride, extensions: { [MESHOPT]: { buffer: 0, byteLength: bin.length, count: 1, byteStride: sample.stride, mode: 'ATTRIBUTES', filter: sample.filter } } }] }, bin }, LIMITS.expandedBytes);
    expect([...new sample.type(decoded.bin.buffer as ArrayBuffer)]).toEqual(sample.expected);
  }
  const indices = new Uint32Array([3, 1, 2, 0]), bin = MeshoptEncoder.encodeGltfBuffer(new Uint8Array(indices.buffer), 4, 4, 'INDICES');
  const decoded = await decodeMeshopt({ json: { extensionsRequired: [MESHOPT], buffers: [{ byteLength: bin.length }, { byteLength: 16 }], bufferViews: [{ buffer: 1, byteLength: 16, extensions: { [MESHOPT]: { buffer: 0, byteLength: bin.length, count: 4, byteStride: 4, mode: 'INDICES' } } }] }, bin }, LIMITS.expandedBytes);
  expect([...new Uint32Array(decoded.bin.buffer)]).toEqual([...indices]);
});
