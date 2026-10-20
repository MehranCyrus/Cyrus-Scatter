import { sha256 } from '../core/hash';
import { uuid, type Asset, type NodeRecord, type Vec3 } from '../core/model';
import { Matrix4 } from 'three';
import { glbBounds } from './bounds';
import { decodeMeshopt, MESHOPT } from './meshopt';

export const LIMITS = { fileBytes: 250 * 1024 * 1024, expandedBytes: 512 * 1024 * 1024, gpuBytes: 384 * 1024 * 1024, imageEdge: 8192, nodes: 100000, triangles: 10000000 };
const supported = new Set(['KHR_materials_unlit', 'KHR_texture_transform', 'KHR_mesh_quantization', 'EXT_mesh_gpu_instancing', 'EXT_texture_webp', MESHOPT]);
export interface GLB { json: any; bin: Uint8Array; }
export function readGLB(bytes: Uint8Array): GLB {
  if (bytes.length > LIMITS.fileBytes || bytes.length < 20) throw new Error('GLB size is outside the admitted range');
  const v = new DataView(bytes.buffer, bytes.byteOffset, bytes.byteLength);
  if (v.getUint32(0, true) !== 0x46546c67 || v.getUint32(4, true) !== 2 || v.getUint32(8, true) !== bytes.length) throw new Error('Invalid or truncated GLB 2.0 header');
  let offset = 12, json: any, bin: Uint8Array = new Uint8Array();
  while (offset < bytes.length) {
    if (offset + 8 > bytes.length) throw new Error('Truncated GLB chunk');
    const length = v.getUint32(offset, true), type = v.getUint32(offset + 4, true); offset += 8;
    if (offset + length > bytes.length || length % 4) throw new Error('Invalid GLB chunk size');
    if (type === 0x4e4f534a) { if (json || offset !== 20) throw new Error('Invalid GLB JSON ordering'); if (length > 16 * 1024 * 1024) throw new Error('GLB metadata exceeds 16 MiB'); json = JSON.parse(new TextDecoder().decode(bytes.subarray(offset, offset + length)).trim()); }
    else if (type === 0x004e4942) { if (bin.length) throw new Error('Multiple binary chunks'); bin = bytes.subarray(offset, offset + length); }
    offset += length;
  }
  if (!json || json.asset?.version !== '2.0') throw new Error('Unsupported glTF version');
  return { json, bin };
}
export function writeGLB(json: any, bin: Uint8Array): Uint8Array {
  const raw = new TextEncoder().encode(JSON.stringify(json)), jlen = Math.ceil(raw.length / 4) * 4, blen = Math.ceil(bin.length / 4) * 4;
  const bytes = new Uint8Array(12 + 8 + jlen + (blen ? 8 + blen : 0)), v = new DataView(bytes.buffer);
  v.setUint32(0, 0x46546c67, true); v.setUint32(4, 2, true); v.setUint32(8, bytes.length, true); v.setUint32(12, jlen, true); v.setUint32(16, 0x4e4f534a, true); bytes.fill(32, 20, 20 + jlen); bytes.set(raw, 20);
  if (blen) { v.setUint32(20 + jlen, blen, true); v.setUint32(24 + jlen, 0x004e4942, true); bytes.set(bin, 28 + jlen); }
  return bytes;
}
function imageSize(bytes: Uint8Array, mime: string): [number, number] {
  const v = new DataView(bytes.buffer, bytes.byteOffset, bytes.byteLength);
  if (mime === 'image/png' && bytes.length >= 24 && v.getUint32(0) === 0x89504e47) return [v.getUint32(16), v.getUint32(20)];
  if (mime === 'image/webp' && bytes.length >= 30) {
    const kind = new TextDecoder().decode(bytes.subarray(12, 16));
    if (kind === 'VP8X') return [1 + bytes[24] + (bytes[25] << 8) + (bytes[26] << 16), 1 + bytes[27] + (bytes[28] << 8) + (bytes[29] << 16)];
    if (kind === 'VP8 ') return [v.getUint16(26, true) & 0x3fff, v.getUint16(28, true) & 0x3fff];
    if (kind === 'VP8L' && bytes.length >= 25) { const bits = v.getUint32(21, true); return [(bits & 0x3fff) + 1, ((bits >>> 14) & 0x3fff) + 1]; }
  }
  if (mime === 'image/jpeg' && bytes[0] === 255 && bytes[1] === 216) {
    let i = 2;
    while (i + 9 < bytes.length) { if (bytes[i] !== 255) { i++; continue; } const marker = bytes[i + 1]; i += 2; if (marker === 0xd9 || marker === 0xda) break; const len = v.getUint16(i); if (len < 2 || i + len > bytes.length) break; if ([0xc0, 0xc1, 0xc2, 0xc3].includes(marker)) return [v.getUint16(i + 5), v.getUint16(i + 3)]; i += len; }
  }
  throw new Error('Unsupported or invalid image; use PNG, JPEG or WebP');
}
export { imageSize };

export async function inspectGLB(bytes: Uint8Array, name: string, logicalId: string = uuid()): Promise<Asset> {
  const source = readGLB(bytes), warnings: string[] = [];
  for (const ext of source.json.extensionsRequired ?? []) if (!supported.has(ext)) throw new Error(`Unsupported required extension: ${ext}. Prepare a static standard-material GLB upstream.`);
  const { json: j, bin } = await decodeMeshopt(source, LIMITS.expandedBytes);
  if ((j.buffers ?? []).length > 1 || (j.buffers ?? []).some((b: any) => b.uri || b.byteLength > bin.length)) throw new Error('Use a self-contained GLB with one embedded buffer');
  for (const ext of j.extensionsRequired ?? []) if (!supported.has(ext)) throw new Error(`Unsupported required extension: ${ext}. Prepare a static standard-material GLB upstream.`);
  for (const ext of j.extensionsUsed ?? []) if (!supported.has(ext)) warnings.push(`Optional ${ext} is not qualified; appearance may differ`);
  if (j.animations?.length || j.skins?.length || j.nodes?.some((n: any) => n.skin !== undefined) || j.meshes?.some((m: any) => m.primitives?.some((p: any) => p.targets?.length))) throw new Error('Animated, skinned or morphing scenes require a static GLB export');
  if (!j.nodes?.length || j.nodes.length > LIMITS.nodes || !j.scenes?.length) throw new Error('Missing scene or too many nodes');
  const views = j.bufferViews ?? [], accessors = j.accessors ?? [];
  for (const view of views) if (view.buffer !== 0 || !Number.isInteger(view.byteLength) || view.byteLength < 0 || (view.byteOffset ?? 0) < 0 || (view.byteOffset ?? 0) + view.byteLength > bin.length) throw new Error('Invalid buffer view range');
  const width: Record<string, number> = { SCALAR: 1, VEC2: 2, VEC3: 3, VEC4: 4, MAT2: 4, MAT3: 9, MAT4: 16 }, size: Record<number, number> = { 5120: 1, 5121: 1, 5122: 2, 5123: 2, 5125: 4, 5126: 4 };
  let gpuBytes = 0;
  for (const a of accessors) {
    if (!width[a.type] || !size[a.componentType] || !Number.isInteger(a.count) || a.count < 0 || a.count > 30000000) throw new Error('Invalid accessor');
    const bytesPer = width[a.type] * size[a.componentType], view = views[a.bufferView];
    if (a.bufferView !== undefined && (!view || (a.byteOffset ?? 0) + (a.count ? (a.count - 1) * (view.byteStride ?? bytesPer) + bytesPer : 0) > view.byteLength)) throw new Error('Accessor exceeds buffer view');
    if (a.sparse) throw new Error('Sparse accessors require upstream preparation for this MVP');
    gpuBytes += a.count * bytesPer;
    for (const values of [a.min, a.max]) if (values && values.some((x: number) => !Number.isFinite(x) || Math.abs(x) > 10000000)) throw new Error('Nonfinite or extreme geometry bounds');
  }
  for (const image of j.images ?? []) {
    if (image.uri || image.bufferView === undefined || !views[image.bufferView]) throw new Error('External images are not admitted; embed them in the GLB');
    const view = views[image.bufferView], [w, h] = imageSize(bin.subarray(view.byteOffset ?? 0, (view.byteOffset ?? 0) + view.byteLength), image.mimeType);
    if (!w || !h || w > LIMITS.imageEdge || h > LIMITS.imageEdge) throw new Error('Texture dimensions exceed 8192 pixels'); gpuBytes += w * h * 4 * 4 / 3;
  }
  const parents = new Map<number, number>(), active = new Set<number>();
  j.nodes.forEach((n: any, index: number) => {
    for (const values of [n.translation, n.rotation, n.scale, n.matrix]) if (values && (!Array.isArray(values) || values.some((x: number) => !Number.isFinite(x) || Math.abs(x) > 10000000))) throw new Error('Invalid node transform');
    if (n.scale?.some((x: number) => Math.abs(x) < 1e-10)) throw new Error('Singular node transform');
    if (n.matrix && (n.matrix.length !== 16 || Math.abs(new Matrix4().fromArray(n.matrix).determinant()) < 1e-12)) throw new Error('Singular or invalid node matrix');
    if (n.translation && n.translation.length !== 3 || n.scale && n.scale.length !== 3 || n.rotation && (n.rotation.length !== 4 || Math.hypot(...n.rotation) < 1e-10)) throw new Error('Invalid node TRS dimensions');
    if (n.matrix && (n.translation || n.rotation || n.scale)) throw new Error('Node cannot combine matrix and TRS transforms');
    for (const child of n.children ?? []) { if (!j.nodes[child] || parents.has(child)) throw new Error('Invalid or multiply-parented node'); parents.set(child, index); }
  });
  const visit = (n: number, chain: Set<number>) => { if (!j.nodes[n] || chain.has(n) || chain.size > 256) throw new Error('Invalid cyclic or excessively deep scene'); if (active.has(n)) return; active.add(n); const next = new Set(chain).add(n); for (const c of j.nodes[n].children ?? []) visit(c, next); };
  for (const n of j.scenes[j.scene ?? 0]?.nodes ?? []) visit(n, new Set());
  for (let n = 0; n < j.nodes.length; n++) { const seen = new Set<number>(); let k: number | undefined = n; while (k !== undefined) { if (seen.has(k) || seen.size > 256) throw new Error('Cyclic or excessively deep node hierarchy'); seen.add(k); k = parents.get(k); } }
  let triangles = 0, instanceBytes = 0;
  for (const index of active) {
    const node = j.nodes[index]; if (node.mesh === undefined) continue; const mesh = j.meshes?.[node.mesh]; if (!mesh) throw new Error('Missing mesh');
    const attributes = node.extensions?.EXT_mesh_gpu_instancing?.attributes, count = attributes ? accessors[Object.values(attributes)[0] as number]?.count : 1;
    if (!count || count > 200000) throw new Error('Invalid instance count');
    for (const primitive of mesh.primitives ?? []) {
      if (primitive.extensions && Object.keys(primitive.extensions).some(x => !supported.has(x))) throw new Error('Compressed or custom geometry requires upstream preparation');
      const pos = accessors[primitive.attributes?.POSITION]; if (!pos) throw new Error('Missing vertex positions');
      if (primitive.indices !== undefined && !accessors[primitive.indices]) throw new Error('Missing indices');
      if (primitive.indices !== undefined) {
        const indices = accessors[primitive.indices], view = views[indices.bufferView];
        if (indices.type !== 'SCALAR' || ![5121, 5123, 5125].includes(indices.componentType) || !view) throw new Error('Invalid index accessor');
        const data = new DataView(bin.buffer, bin.byteOffset + (view.byteOffset ?? 0) + (indices.byteOffset ?? 0)), stride = view.byteStride ?? size[indices.componentType];
        for (let row = 0; row < indices.count; row++) { const offset = row * stride, index = indices.componentType === 5121 ? data.getUint8(offset) : indices.componentType === 5123 ? data.getUint16(offset, true) : data.getUint32(offset, true); if (index >= pos.count) throw new Error('Mesh index exceeds vertex count'); }
      }
      for (const a of Object.values(primitive.attributes ?? {})) if (!accessors[a as number]) throw new Error('Missing vertex accessor');
      const vertices = (primitive.indices !== undefined ? accessors[primitive.indices].count : pos.count);
      const mode = primitive.mode ?? 4; if (mode === 4) triangles += vertices / 3 * count; else if (mode === 5 || mode === 6) triangles += Math.max(0, vertices - 2) * count;
    }
    if (attributes) { gpuBytes += count * 64; instanceBytes += count * 64; }
  }
  if (triangles > LIMITS.triangles || gpuBytes > LIMITS.gpuBytes) throw new Error('Scene exceeds admitted geometry/GPU estimate; optimize upstream or split the scene');
  let metadataBytes = 0;
  const records: NodeRecord[] = j.nodes.map((n: any, index: number) => {
    const chain: string[] = []; let k: number | undefined = index; while (k !== undefined) { chain.unshift(j.nodes[k].name || `Node ${k}`); k = parents.get(k); }
    const record = { key: `n:${index}`, name: String(n.name ?? `Node ${index}`).slice(0, 200), path: chain.join('/').slice(0, 2000), parent: parents.has(index) ? `n:${parents.get(index)}` : null, externalId: n.extras?.cyrus?.entityId, externalLayer: n.extras?.cyrus?.layerId, renderable: active.has(index) && n.mesh !== undefined };
    metadataBytes += new TextEncoder().encode(JSON.stringify(record)).length; if (metadataBytes > 4 * 1024 * 1024) throw new Error('Node metadata exceeds 4 MiB; simplify the imported hierarchy'); return record;
  });
  const external = records.flatMap(n => n.externalId ? [n.externalId] : []); if (new Set(external).size !== external.length) throw new Error('Duplicate external node IDs');
  return { id: logicalId, revisionId: uuid(), name: name.slice(0, 200), hash: await sha256(bytes), bytes: bytes.length, bounds: glbBounds(j, bin, active, parents), nodes: records, triangles, gpuBytes, instanceBytes, warnings };
}

export function replacementSuggestions(old: Asset, next: Asset): Record<string, string> {
  const suggestions: Record<string, string> = {};
  for (const n of next.nodes) {
    const matches = old.nodes.filter(o => n.externalId ? o.externalId === n.externalId : !o.externalId && o.path === n.path);
    if (matches.length === 1 && next.nodes.filter(x => n.externalId ? x.externalId === n.externalId : x.path === n.path).length === 1) suggestions[n.key] = matches[0].key;
  }
  return suggestions;
}

export function planPoint(plan: { a: [number, number]; b: [number, number]; distance: number; origin: Vec3; rotation: number }, pixel: [number, number]): Vec3 {
  const dx = plan.b[0] - plan.a[0], dy = plan.b[1] - plan.a[1], scale = plan.distance / Math.hypot(dx, dy), angle = plan.rotation - Math.atan2(dy, dx), x = (pixel[0] - plan.a[0]) * scale, z = (pixel[1] - plan.a[1]) * scale;
  return [plan.origin[0] + x * Math.cos(angle) - z * Math.sin(angle), plan.origin[1], plan.origin[2] + x * Math.sin(angle) + z * Math.cos(angle)];
}
