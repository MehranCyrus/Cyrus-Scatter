import { readGLB, writeGLB, LIMITS } from './glb';
import { MESHOPT, planMeshopt } from './meshopt';
import { resolveLayer, type Asset, type Instance, type Layer, type NodeRecord } from '../core/model';

/** Rebuild a static self-contained GLB using only reachable included resources. */
export function publicGLB(bytes: Uint8Array, asset: Asset, instance: Instance, layers: Layer[]): { bytes: Uint8Array; nodes: NodeRecord[] } {
  const { json: source, bin } = readGLB(bytes), j = structuredClone(source), keep = new Set<number>(), meshes = new Set<number>(), accessors = new Set<number>(), materials = new Set<number>(), textures = new Set<number>(), images = new Set<number>(), samplers = new Set<number>(), views = new Set<number>();
  planMeshopt({ json: source, bin }, LIMITS.expandedBytes);
  const allowed = new Set(layers.filter(l => l.included).map(l => l.id));
  const visibleMesh = new Set<number>();
  asset.nodes.filter(n => n.renderable).forEach(n => {
    if (!allowed.has(resolveLayer(n.key, asset, instance)!)) return;
    const index = Number(n.key.slice(2)); visibleMesh.add(index); let key: string | null = n.key;
    while (key) { keep.add(Number(key.slice(2))); key = asset.nodes.find(x => x.key === key)?.parent ?? null; }
  });
  const selected = [...keep].sort((a, b) => a - b), nodeMap = new Map(selected.map((index, next) => [index, next]));
  j.nodes = selected.map(index => {
    const n = structuredClone(source.nodes[index]);
    n.children = (n.children ?? []).filter((c: number) => keep.has(c)).map((c: number) => nodeMap.get(c));
    if (!n.children.length) delete n.children;
    n.extras = { cyrus: { nodeKey: `n:${index}` } }; delete n.name; delete n.camera;
    if (!visibleMesh.has(index)) { delete n.mesh; delete n.extensions; }
    else { meshes.add(n.mesh); for (const a of Object.values(n.extensions?.EXT_mesh_gpu_instancing?.attributes ?? {})) accessors.add(a as number); }
    return n;
  });
  j.scenes = [{ nodes: (source.scenes[source.scene ?? 0].nodes ?? []).filter((n: number) => keep.has(n)).map((n: number) => nodeMap.get(n)) }]; j.scene = 0;
  const compact = (key: string, indices: Set<number>) => { const list = [...indices].sort((a, b) => a - b), map = new Map(list.map((n, i) => [n, i])); j[key] = list.map(n => structuredClone(source[key]?.[n])); if (j[key].some((x: any) => !x)) throw new Error(`Missing ${key} resource`); return map; };
  const meshMap = compact('meshes', meshes);
  for (const n of j.nodes) { if (n.mesh !== undefined) n.mesh = meshMap.get(n.mesh); }
  for (const m of j.meshes) { delete m.name; delete m.extras; for (const p of m.primitives) { Object.values(p.attributes).forEach(a => accessors.add(a as number)); if (p.indices !== undefined) accessors.add(p.indices); if (p.material !== undefined) materials.add(p.material); } }
  const materialMap = compact('materials', materials);
  const visitTextures = (obj: any, remap?: Map<number, number>) => {
    if (!obj || typeof obj !== 'object') return;
    for (const [key, value] of Object.entries(obj)) {
      if (key.endsWith('Texture') && value && typeof value === 'object' && 'index' in value) { const t = value as { index: number }; if (remap) t.index = remap.get(t.index)!; else textures.add(t.index); }
      else visitTextures(value, remap);
    }
  };
  for (const m of j.materials) { delete m.name; delete m.extras; visitTextures(m); }
  const textureMap = compact('textures', textures);
  for (const t of j.textures) { delete t.name; delete t.extras; if (t.source !== undefined) images.add(t.source); if (t.extensions?.EXT_texture_webp) images.add(t.extensions.EXT_texture_webp.source); if (t.sampler !== undefined) samplers.add(t.sampler); }
  const imageMap = compact('images', images), samplerMap = compact('samplers', samplers);
  for (const im of j.images) { delete im.name; delete im.extras; views.add(im.bufferView); }
  for (const t of j.textures) { if (t.source !== undefined) t.source = imageMap.get(t.source); if (t.extensions?.EXT_texture_webp) t.extensions.EXT_texture_webp.source = imageMap.get(t.extensions.EXT_texture_webp.source); if (t.sampler !== undefined) t.sampler = samplerMap.get(t.sampler); }
  for (const m of j.materials) visitTextures(m, textureMap);
  const accessorMap = compact('accessors', accessors);
  for (const a of j.accessors) { delete a.name; delete a.extras; if (a.bufferView !== undefined) views.add(a.bufferView); }
  for (const m of j.meshes) for (const p of m.primitives) { for (const k of Object.keys(p.attributes)) p.attributes[k] = accessorMap.get(p.attributes[k]); if (p.indices !== undefined) p.indices = accessorMap.get(p.indices); if (p.material !== undefined) p.material = materialMap.get(p.material); }
  for (const n of j.nodes) for (const k of Object.keys(n.extensions?.EXT_mesh_gpu_instancing?.attributes ?? {})) n.extensions.EXT_mesh_gpu_instancing.attributes[k] = accessorMap.get(n.extensions.EXT_mesh_gpu_instancing.attributes[k]);
  const viewMap = compact('bufferViews', views); let total = 0, fallbackTotal = 0;
  const payloads = j.bufferViews.map((view: any) => {
    const codec = view.extensions?.[MESHOPT], sourceOffset = codec ? codec.byteOffset ?? 0 : view.byteOffset ?? 0, length = codec ? codec.byteLength : view.byteLength, offset = total;
    if (codec) {
      view.buffer = 1; view.byteOffset = fallbackTotal; fallbackTotal += Math.ceil(view.byteLength / 4) * 4;
      codec.buffer = 0; codec.byteOffset = total;
    } else { view.buffer = 0; view.byteOffset = total; }
    total += Math.ceil(length / 4) * 4; return { sourceOffset, length, offset };
  });
  const compactBin = new Uint8Array(total);
  for (const p of payloads) compactBin.set(bin.subarray(p.sourceOffset, p.sourceOffset + p.length), p.offset);
  for (const a of j.accessors) if (a.bufferView !== undefined) a.bufferView = viewMap.get(a.bufferView);
  for (const im of j.images) im.bufferView = viewMap.get(im.bufferView);
  const stripPrivate = (value: any) => {
    if (!value || typeof value !== 'object') return;
    if (Array.isArray(value)) { value.forEach(stripPrivate); return; }
    if (value.extras?.cyrus?.nodeKey) value.extras = { cyrus: { nodeKey: value.extras.cyrus.nodeKey } }; else delete value.extras;
    delete value.name; Object.values(value).forEach(stripPrivate);
  };
  stripPrivate(j);
  j.buffers = [{ byteLength: total }];
  if (fallbackTotal) {
    j.buffers.push({ byteLength: fallbackTotal, extensions: { [MESHOPT]: { fallback: true } } });
    for (const key of ['extensionsUsed', 'extensionsRequired']) j[key] = [...new Set([...(j[key] ?? []), MESHOPT])];
  } else for (const key of ['extensionsUsed', 'extensionsRequired']) if (j[key]) { j[key] = j[key].filter((ext: string) => ext !== MESHOPT); if (!j[key].length) delete j[key]; }
  j.asset = { version: '2.0', generator: 'Cyrus Presentation Compiler 1' };
  delete j.extras; delete j.extensions; delete j.animations; delete j.skins; delete j.cameras;
  for (const key of ['nodes', 'meshes', 'materials', 'accessors', 'bufferViews', 'textures', 'images', 'samplers']) if (!j[key]?.length) delete j[key];
  const nodes = asset.nodes.filter(n => keep.has(Number(n.key.slice(2)))).map(n => ({ key: n.key, name: '', path: '', parent: n.parent, renderable: visibleMesh.has(Number(n.key.slice(2))) }));
  return { bytes: writeGLB(j, compactBin), nodes };
}
