import { Box3, Matrix4, Quaternion, Vector3 } from 'three';

/** Numeric glTF bounds for admission. No DOM, loader, network, or renderer access. */
export function glbBounds(j: any, bin: Uint8Array, active: Set<number>, parents: Map<number, number>): { min: [number, number, number]; max: [number, number, number] } {
  const matrices = new Map<number, Matrix4>(), accessors = new Map<number, Box3>(), meshes = new Map<number, Box3>();
  const data = new DataView(bin.buffer, bin.byteOffset, bin.byteLength), sizes: Record<number, number> = { 5120: 1, 5121: 1, 5122: 2, 5123: 2, 5125: 4, 5126: 4 };
  const read = (index: number, row: number, component: number, width: number) => {
    const a = j.accessors[index], v = j.bufferViews[a.bufferView], offset = (v.byteOffset ?? 0) + (a.byteOffset ?? 0) + row * (v.byteStride ?? sizes[a.componentType] * width) + component * sizes[a.componentType];
    let value: number;
    switch (a.componentType) { case 5120: value = data.getInt8(offset); break; case 5121: value = data.getUint8(offset); break; case 5122: value = data.getInt16(offset, true); break; case 5123: value = data.getUint16(offset, true); break; case 5125: value = data.getUint32(offset, true); break; default: value = data.getFloat32(offset, true); }
    if (a.normalized) value = Math.max(-1, value / ({ 5120: 127, 5121: 255, 5122: 32767, 5123: 65535, 5125: 4294967295 }[a.componentType as 5120] ?? 1));
    if (!Number.isFinite(value) || Math.abs(value) > 10000000) throw new Error('Nonfinite or extreme numeric geometry'); return value;
  };
  const matrix = (index: number): Matrix4 => {
    if (!matrices.has(index)) {
      const node = j.nodes[index], local = node.matrix ? new Matrix4().fromArray(node.matrix) : new Matrix4().compose(new Vector3().fromArray(node.translation ?? [0, 0, 0]), new Quaternion().fromArray(node.rotation ?? [0, 0, 0, 1]).normalize(), new Vector3().fromArray(node.scale ?? [1, 1, 1]));
      matrices.set(index, parents.has(index) ? matrix(parents.get(index)!).clone().multiply(local) : local);
    }
    return matrices.get(index)!;
  };
  const meshBounds = (index: number): Box3 => {
    if (!meshes.has(index)) {
      const box = new Box3();
      for (const p of j.meshes[index].primitives) {
        const index = p.attributes.POSITION;
        if (!accessors.has(index)) { const a = j.accessors[index], bounds = new Box3(); if (a.type !== 'VEC3' || a.bufferView === undefined) throw new Error('Invalid position accessor'); for (let row = 0; row < a.count; row++) bounds.expandByPoint(new Vector3(read(index, row, 0, 3), read(index, row, 1, 3), read(index, row, 2, 3))); accessors.set(index, bounds); }
        box.union(accessors.get(index)!);
      }
      meshes.set(index, box);
    }
    return meshes.get(index)!;
  };
  const total = new Box3(); let instances = 0;
  for (const index of active) {
    const node = j.nodes[index]; if (node.mesh === undefined) continue;
    const box = meshBounds(node.mesh), world = matrix(index), attrs = node.extensions?.EXT_mesh_gpu_instancing?.attributes;
    if (!attrs) { total.union(box.clone().applyMatrix4(world)); continue; }
    const count = j.accessors[Object.values(attrs)[0] as number].count; instances += count;
    if (instances > 500000) throw new Error('Instance preparation exceeds 500,000 admitted rows');
    for (const [key, index] of Object.entries(attrs) as [string, number][]) if (j.accessors[index]?.count !== count || j.accessors[index].type !== (key === 'ROTATION' ? 'VEC4' : 'VEC3')) throw new Error('Inconsistent instance attributes');
    for (let row = 0; row < count; row++) {
      const vector = (name: string, fallback: number[]) => attrs[name] !== undefined ? fallback.map((_, component) => read(attrs[name], row, component, fallback.length)) : fallback;
      const pose = new Matrix4().compose(new Vector3().fromArray(vector('TRANSLATION', [0, 0, 0])), new Quaternion().fromArray(vector('ROTATION', [0, 0, 0, 1])).normalize(), new Vector3().fromArray(vector('SCALE', [1, 1, 1])));
      total.union(box.clone().applyMatrix4(world.clone().multiply(pose)));
    }
  }
  if (total.isEmpty() || !Number.isFinite(total.min.length()) || total.getSize(new Vector3()).length() > 1000000) throw new Error('Empty, invalid or extreme landscape bounds');
  return { min: total.min.toArray(), max: total.max.toArray() };
}
