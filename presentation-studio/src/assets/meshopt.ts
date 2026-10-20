import { MeshoptDecoder } from 'three/addons/libs/meshopt_decoder.module.js';
import type { GLB } from './glb';

export const MESHOPT = 'EXT_meshopt_compression';
interface ViewPlan { offset: number; length: number; sourceOffset: number; sourceLength: number; codec?: any; }
export interface MeshoptPlan { bytes: number; views: ViewPlan[]; }
const integer = (value: unknown, minimum = 0, maximum = Number.MAX_SAFE_INTEGER): value is number => typeof value === 'number' && Number.isSafeInteger(value) && value >= minimum && value <= maximum;
const range = (offset: unknown, length: unknown, total: number) => integer(offset) && integer(length) && offset <= total && length <= total - offset;

/** Validate the complete declared working set before any decoder allocation. */
export function planMeshopt({ json: j, bin }: GLB, maximum: number): MeshoptPlan | null {
  const views = j.bufferViews ?? [];
  if (!Array.isArray(views)) throw new Error('Invalid GLB buffer views');
  if (!views.some((v: any) => v?.extensions?.[MESHOPT])) return null;
  if (views.length > 100000 || !Array.isArray(j.buffers) || ![1, 2].includes(j.buffers.length)) throw new Error('Meshopt requires one embedded buffer and at most one placeholder');
  for (let i = 0; i < j.buffers.length; i++) {
    const buffer = j.buffers[i];
    if (!buffer || buffer.uri !== undefined || !integer(buffer.byteLength, 0, i ? maximum : bin.length)) throw new Error('External or oversized Meshopt buffer');
    if (i && !j.extensionsRequired?.includes(MESHOPT)) throw new Error('Meshopt placeholder requires the decoder');
  }
  let total = 0;
  const plans: ViewPlan[] = [];
  for (const view of views) {
    if (!view || !integer(view.buffer, 0, j.buffers.length - 1) || !range(view.byteOffset ?? 0, view.byteLength, j.buffers[view.buffer].byteLength)) throw new Error('Invalid Meshopt fallback view range');
    const codec = view.extensions?.[MESHOPT];
    let sourceOffset = view.byteOffset ?? 0, sourceLength = view.byteLength;
    if (codec) {
      if (codec.buffer !== 0 || !range(codec.byteOffset ?? 0, codec.byteLength, j.buffers[0].byteLength) || !integer(codec.byteLength, 1)) throw new Error('Invalid compressed Meshopt range');
      if (!integer(codec.count, 1, 30000000) || !integer(codec.byteStride, 2, 256) || codec.count * codec.byteStride !== view.byteLength) throw new Error('Invalid Meshopt decoded size');
      const mode = codec.mode, filter = codec.filter ?? 'NONE', stride = codec.byteStride;
      if (!['ATTRIBUTES', 'TRIANGLES', 'INDICES'].includes(mode) || !['NONE', 'OCTAHEDRAL', 'QUATERNION', 'EXPONENTIAL'].includes(filter)) throw new Error('Unsupported Meshopt mode/filter');
      if (view.byteStride !== undefined && view.byteStride !== stride) throw new Error('Meshopt strides do not match');
      if (mode === 'ATTRIBUTES') {
        if (stride % 4) throw new Error('Invalid Meshopt attribute stride');
        if (filter === 'OCTAHEDRAL' && ![4, 8].includes(stride) || filter === 'QUATERNION' && stride !== 8) throw new Error('Invalid Meshopt filter stride');
      } else if (![2, 4].includes(stride) || filter !== 'NONE' || mode === 'TRIANGLES' && codec.count % 3) throw new Error('Invalid Meshopt index stream');
      sourceOffset = codec.byteOffset ?? 0; sourceLength = codec.byteLength;
    } else if (view.buffer !== 0) throw new Error('Uncompressed view cannot use a placeholder buffer');
    const length = Math.ceil(view.byteLength / 4) * 4;
    if (!integer(length) || length > maximum - total) throw new Error('Meshopt decoded views exceed the expanded limit');
    plans.push({ offset: total, length: view.byteLength, sourceOffset, sourceLength, codec }); total += length;
  }
  return { bytes: total, views: plans };
}

/** Numeric admission sees ordinary decoded views; persisted/renderer bytes stay compressed. */
export async function decodeMeshopt(source: GLB, maximum: number): Promise<GLB> {
  const plan = planMeshopt(source, maximum); if (!plan) return source;
  await MeshoptDecoder.ready;
  const bin = new Uint8Array(plan.bytes);
  for (const view of plan.views) {
    const target = bin.subarray(view.offset, view.offset + view.length), input = source.bin.subarray(view.sourceOffset, view.sourceOffset + view.sourceLength);
    try {
      if (view.codec) MeshoptDecoder.decodeGltfBuffer(target, view.codec.count, view.codec.byteStride, input, view.codec.mode, view.codec.filter ?? 'NONE');
      else target.set(input);
    } catch { throw new Error('Invalid Meshopt compressed payload'); }
  }
  const json = structuredClone(source.json);
  json.bufferViews.forEach((view: any, index: number) => {
    view.buffer = 0; view.byteOffset = plan.views[index].offset;
    if (view.extensions) { delete view.extensions[MESHOPT]; if (!Object.keys(view.extensions).length) delete view.extensions; }
  });
  json.buffers = [{ byteLength: bin.length }];
  for (const key of ['extensionsUsed', 'extensionsRequired']) if (json[key]) { json[key] = json[key].filter((ext: string) => ext !== MESHOPT); if (!json[key].length) delete json[key]; }
  return { json, bin };
}
