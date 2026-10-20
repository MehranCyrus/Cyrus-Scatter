import { BoxGeometry, ConeGeometry, CylinderGeometry, IcosahedronGeometry, SphereGeometry, type BufferGeometry } from 'three';
import { writeGLB, inspectGLB } from './glb';
import { emptyProject, identityTransform, reconnect, uuid, type Files, type Project, type Vec3 } from '../core/model';
import { sha256 } from '../core/hash';
import { lookQuaternion } from '../presentation/evaluate';

export function demoGLB(count = 1949, siteSize = 100): Uint8Array {
  const j: any = { asset: { version: '2.0', generator: 'Cyrus owned demo fixture' }, scene: 0, scenes: [{ nodes: [] }], nodes: [], meshes: [], materials: [], accessors: [], bufferViews: [], buffers: [], extensionsUsed: ['EXT_mesh_gpu_instancing'] };
  const chunks: Uint8Array[] = []; let length = 0;
  const attribute = (values: number[], type: string, size: number) => {
    const data = new Float32Array(values), bytes = new Uint8Array(data.buffer), view = j.bufferViews.push({ buffer: 0, byteOffset: length, byteLength: bytes.length }) - 1; chunks.push(bytes); length += bytes.length;
    const min = Array(size).fill(Infinity), max = Array(size).fill(-Infinity);
    values.forEach((v, i) => { min[i % size] = Math.min(min[i % size], v); max[i % size] = Math.max(max[i % size], v); });
    return j.accessors.push({ bufferView: view, componentType: 5126, count: values.length / size, type, min, max }) - 1;
  };
  const material = (colour: string, roughness = 0.85) => { const c = Number.parseInt(colour, 16); return j.materials.push({ pbrMetallicRoughness: { baseColorFactor: [(c >> 16) / 255, ((c >> 8) & 255) / 255, (c & 255) / 255, 1], metallicFactor: 0, roughnessFactor: roughness } }) - 1; };
  const mesh = (geometry: BufferGeometry, mat: number) => {
    const g = geometry.index ? geometry.toNonIndexed() : geometry;
    const position = attribute(Array.from(g.getAttribute('position').array), 'VEC3', 3), normal = attribute(Array.from(g.getAttribute('normal').array), 'VEC3', 3);
    const index = j.meshes.push({ primitives: [{ attributes: { POSITION: position, NORMAL: normal }, material: mat }] }) - 1;
    if (g !== geometry) g.dispose(); geometry.dispose(); return index;
  };
  const colours = { ground: material('bac6a0'), stone: material('d5cdbb'), path: material('e7ddc9'), wall: material('eee5d1'), roof: material('9d5841'), glass: material('395953', 0.2), dark: material('455c38'), leaf: material('678044'), shrub: material('889b55'), flower: material('c59e94'), trunk: material('75674e'), water: material('759c99', 0.15) };
  const box = mesh(new BoxGeometry(1, 1, 1), colours.wall), pathMesh = mesh(new BoxGeometry(1, 1, 1), colours.path), stone = mesh(new BoxGeometry(1, 1, 1), colours.stone), ground = mesh(new BoxGeometry(1, 1, 1), colours.ground);
  const groups: Record<string, number> = {};
  for (const name of ['Site', 'Paths', 'Building', 'Ground cover', 'Shrubs', 'Flowers', 'Trees']) { groups[name] = j.nodes.push({ name, children: [], extras: { cyrus: { entityId: `demo-group-${name}`, layerId: name } } }) - 1; j.scenes[0].nodes.push(groups[name]); }
  const node = (group: string, name: string, m: number, position: Vec3, scale: Vec3, rotation?: number[]) => { const index = j.nodes.push({ name, mesh: m, translation: position, scale, ...(rotation ? { rotation } : {}), extras: { cyrus: { entityId: `demo-${j.nodes.length}` } } }) - 1; j.nodes[groups[group]].children.push(index); };
  node('Site', 'Site ground', ground, [0, -0.25, 0], [siteSize, 0.5, siteSize]);
  node('Paths', 'Arrival walk', pathMesh, [0, 0.04, 12], [6, 0.08, 64]); node('Paths', 'Cross walk', pathMesh, [0, 0.04, 5], [60, 0.08, 3]);
  node('Paths', 'Terrace', stone, [0, 0.12, -20], [27, 0.24, 22]);
  node('Building', 'Main pavilion', box, [0, 3.7, -25], [18, 7, 11]);
  const roof = mesh(new ConeGeometry(1, 1, 4, 1), colours.roof); node('Building', 'Terracotta roof', roof, [0, 8.7, -25], [15, 3.6, 10], [0, Math.sin(Math.PI / 8), 0, Math.cos(Math.PI / 8)]);
  const glazing = mesh(new BoxGeometry(1, 1, 1), colours.glass);
  for (const x of [-6, 0, 6]) node('Building', 'Garden doors', glazing, [x, 2.7, -19.43], [3, 4.8, 0.12]);
  for (const x of [-9, -3, 3, 9]) node('Building', 'Veranda columns', box, [x, 2.3, -16.5], [0.4, 4.6, 0.4]);
  node('Building', 'Veranda canopy', stone, [0, 4.8, -17], [20, 0.3, 5]);
  const water = mesh(new BoxGeometry(1, 1, 1), colours.water); node('Site', 'Reflection basin', water, [17, 0.12, -20], [7, 0.05, 18]);
  let seed = 7331; const random = () => { seed = (Math.imul(seed, 1664525) + 1013904223) >>> 0; return seed / 4294967296; };
  const leaf = mesh(new IcosahedronGeometry(1, 1), colours.leaf), darkLeaf = mesh(new IcosahedronGeometry(1, 1), colours.dark), shrub = mesh(new SphereGeometry(1, 8, 5), colours.shrub), grass = mesh(new ConeGeometry(0.45, 0.85, 5), colours.dark), flower = mesh(new IcosahedronGeometry(0.35, 0), colours.flower), trunk = mesh(new CylinderGeometry(0.18, 0.28, 3.5, 6), colours.trunk);
  const batches = new Map<string, { group: string; mesh: number; positions: number[]; scales: number[] }>();
  const add = (group: string, m: number, x: number, y: number, z: number, sx: number, sy = sx, sz = sx) => {
    const cell = siteSize > 100 ? 40 : 20;
    const key = `${group}:${m}:${Math.floor(x / cell)}:${Math.floor(z / cell)}`;
    if (!batches.has(key)) batches.set(key, { group, mesh: m, positions: [], scales: [] });
    const b = batches.get(key)!; b.positions.push(x, y, z); b.scales.push(sx, sy, sz);
  };
  for (let i = 0; i < Math.min(count, 25000); i++) {
    const side = random() > 0.5 ? 1 : -1, x = side * (5 + random() * (siteSize / 2 - 11)), z = (-0.43 + random() * 0.86) * siteSize;
    if (z < -9 && z > -33 && Math.abs(x) < 24 || Math.abs(z - 5) < 2.5) continue;
    const r = random();
    if (r < 0.075) { const h = 0.8 + random() * 0.7; add('Trees', trunk, x, 1.7 * h, z, h); add('Trees', i % 3 ? leaf : darkLeaf, x, 4.5 * h, z, 2.3 * h, 3.1 * h, 2.3 * h); }
    else if (r < 0.35) { const s = 0.55 + random() * 0.7; add('Shrubs', shrub, x, s * 0.65, z, s, s * 0.8, s); }
    else if (r < 0.62) { const s = 0.8 + random() * 0.5; add('Flowers', flower, x, 0.5, z, s); }
    else add('Ground cover', grass, x, 0.3, z, 0.8 + random() * 0.7);
  }
  for (const [key, b] of batches) {
    const index = j.nodes.push({ name: key, mesh: b.mesh, extensions: { EXT_mesh_gpu_instancing: { attributes: { TRANSLATION: attribute(b.positions, 'VEC3', 3), SCALE: attribute(b.scales, 'VEC3', 3) } } }, extras: { cyrus: { entityId: `demo-batch-${key}` } } }) - 1; j.nodes[groups[b.group]].children.push(index);
  }
  const bin = new Uint8Array(length); let offset = 0; for (const data of chunks) { bin.set(data, offset); offset += data.length; } j.buffers = [{ byteLength: bin.length }];
  return writeGLB(j, bin);
}

export async function createDemo(): Promise<{ project: Project; blobs: Files }> {
  const bytes = demoGLB(), asset = await inspectGLB(bytes, 'Courtyard garden.glb'), p = emptyProject(), blobs: Files = new Map([[asset.hash, bytes]]);
  p.title = 'The courtyard garden'; p.assets.push(asset);
  const names = ['Site', 'Paths', 'Building', 'Ground cover', 'Shrubs', 'Flowers', 'Trees'];
  p.layers = names.map((name, index) => ({ id: uuid(), name, included: true, defaultVisible: true, viewerToggle: index >= 3, reveal: index < 3 ? index * 0.08 : (index - 1) * 0.14 }));
  const instance = { id: uuid(), assetRevision: asset.revisionId, name: 'Courtyard landscape', transform: identityTransform(), membership: Object.fromEntries(asset.nodes.filter(n => n.externalLayer).map(n => [n.key, p.layers.find(l => l.name === n.externalLayer)!.id])) }; p.instances.push(instance);
  const positions: Vec3[] = [[65, 70, 85], [22, 6, 32], [0, 2.4, 12], [0, 3.1, -2]];
  const targets: Vec3[] = [[0, 0, -5], [0, 3, -20], [0, 3, -21], [0, 4, -22]];
  p.stops = positions.map((position, i) => ({ id: uuid(), name: ['The masterplan', 'Into the planting', 'Garden walk', 'The pavilion'][i], position, quaternion: lookQuaternion(position, targets[i]), fov: i ? 48 : 42, hold: i === 3 ? 5 : 3, aspect: 16 / 9 })); reconnect(p); p.segments.forEach((s, i) => { s.duration = [7, 5, 5][i]; });
  if (typeof document !== 'undefined') {
    const canvas = document.createElement('canvas'); canvas.width = 1000; canvas.height = 1000; const c = canvas.getContext('2d')!;
    c.fillStyle = '#f6f4ec'; c.fillRect(0, 0, 1000, 1000); c.strokeStyle = '#687065'; c.lineWidth = 2; c.strokeRect(45, 45, 910, 910);
    c.fillStyle = '#e2dfd3'; c.fillRect(470, 330, 60, 640); c.fillRect(210, 530, 580, 30); c.strokeRect(370, 160, 260, 220); c.fillStyle = '#f6f4ec'; c.fillRect(410, 195, 180, 110); c.strokeRect(410, 195, 180, 110);
    for (let i = 0; i < 130; i++) { const x = 65 + (i * 197 % 870), y = 65 + (i * 293 % 870); if (Math.abs(x - 500) < 55 || x > 330 && x < 680 && y < 390 || Math.abs(y - 545) < 25) continue; c.beginPath(); c.arc(x, y, 10 + i % 11, 0, Math.PI * 2); c.stroke(); }
    c.fillStyle = '#405346'; c.font = '20px Georgia'; c.fillText('COURTYARD GARDEN', 60, 990); const blob = await new Promise<Blob>(resolve => canvas.toBlob(b => resolve(b!), 'image/png')); const image = new Uint8Array(await blob.arrayBuffer()), hash = await sha256(image); blobs.set(hash, image);
    p.plan = { hash, width: 1000, height: 1000, a: [0, 0], b: [1000, 0], distance: 100, origin: [-50, 0, -50], rotation: 0 };
  }
  return { project: p, blobs };
}
