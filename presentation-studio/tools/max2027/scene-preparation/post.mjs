import { NodeIO } from '@gltf-transform/core';
import { ALL_EXTENSIONS, EXTMeshoptCompression } from '@gltf-transform/extensions';
import { dedup, weld, weldPrimitive, prune, quantize, textureCompress, simplifyPrimitive } from '@gltf-transform/functions';
import { MeshoptEncoder, MeshoptSimplifier } from 'meshoptimizer';
import { MeshoptDecoder } from 'three/addons/libs/meshopt_decoder.module.js';
import { BufferGeometry, BufferAttribute } from 'three';
import { toCreasedNormals } from 'three/addons/utils/BufferGeometryUtils.js';
import sharp from 'sharp';
import { readFile, writeFile, stat } from 'node:fs/promises';
import { createHash } from 'node:crypto';
import { resolve } from 'node:path';
import { fileURLToPath } from 'node:url';
import { inspectGLB } from '../../../src/assets/glb.ts';

const hash = bytes => createHash('sha256').update(bytes).digest('hex');
const io = () => new NodeIO().registerExtensions(ALL_EXTENSIONS).registerDependencies({ 'meshopt.encoder': MeshoptEncoder, 'meshopt.decoder': MeshoptDecoder });
const triangles = mesh => mesh.listPrimitives().reduce((sum, p) => sum + (p.getIndices()?.getCount() ?? p.getAttribute('POSITION').getCount()) / 3, 0);
const submitted = doc => doc.getRoot().listNodes().reduce((sum, node) => sum + (node.getMesh() ? triangles(node.getMesh()) : 0), 0);

export function bindPlacements(doc, metadata, namespace) {
  const mapping = new Map(metadata.map(n => [n.exportName, n])), used = new Set(), placements = [], meshLayers = new Map();
  for (const node of doc.getRoot().listNodes().filter(n => n.getMesh())) {
    const prototype = mapping.get(node.getName()); if (!prototype) throw Error(`Renderable native node lacks source identity: ${node.getName()}`);
    const world = node.getWorldMatrix(), candidates = metadata.filter(n => n.exportIncluded && n.evaluatedTriangles > 0 && n.instanceOwner === prototype.instanceOwner && !used.has(n.handle) && n.objectMatrix.every((v, i) => Math.abs(v - world[i]) < (i >= 12 && i < 15 ? .001 : .00001)));
    if (candidates.length !== 1) throw Error(`Ambiguous instance correspondence: ${node.getName()} (${candidates.length} candidates)`);
    const original = candidates[0]; used.add(original.handle);
    node.setName(original.name).setExtras({ ...node.getExtras(), cyrus: { entityId: `${namespace}:node:${original.handle}`, layerId: original.layer } });
    const layers = meshLayers.get(node.getMesh()) ?? new Set(); layers.add(original.layer); meshLayers.set(node.getMesh(), layers);
    placements.push({ node, world, original });
  }
  const omitted = metadata.filter(n => n.exportIncluded && n.evaluatedTriangles > 0 && !used.has(n.handle));
  if (omitted.length) throw Error(`Native export omitted ${omitted.length} nonempty placements`);
  // Flatten only the exported static placement wrappers, retaining canonical world matrices.
  // The prepared Max and source-nodes sidecar preserve the original hierarchy.
  for (const { node } of placements) for (const child of node.listChildren()) node.removeChild(child);
  const root = doc.getRoot(), scenes = root.listScenes(); if (scenes.length !== 1) throw Error('Expected one native scene');
  const scene = scenes[0]; for (const child of scene.listChildren()) scene.removeChild(child);
  const groups = new Map();
  for (const { node, world, original } of placements) {
    let group = groups.get(original.layer);
    if (!group) { group = doc.createNode(original.layer).setExtras({ cyrus: { entityId: `${namespace}:layer:${original.layer}`, layerId: original.layer } }); groups.set(original.layer, group); scene.addChild(group); }
    node.getParentNode()?.removeChild(node); group.addChild(node); node.setMatrix(world);
    if (node.getWorldMatrix().some((v, i) => Math.abs(v - world[i]) > .00001)) throw Error('Static layer grouping changed a placement transform');
  }
  if (groups.size > 256) throw Error('Export exceeds 256 useful layers');
  return { meshLayers, bindings: placements.map(p => ({ handle: p.original.handle, instanceOwner: p.original.instanceOwner, layer: p.original.layer, matrix: p.world })), layers: [...groups.keys()] };
}

function orientedIndexHash(accessor) {
  const input = accessor.getArray(), output = new Uint32Array(input.length);
  for (let i = 0; i < input.length; i += 3) {
    let best = 0;
    for (let r = 1; r < 3; r++) for (let k = 0; k < 3; k++) { const a = input[i + (r + k) % 3], b = input[i + (best + k) % 3]; if (a < b) { best = r; break; } if (a > b) break; }
    for (let k = 0; k < 3; k++) output[i + k] = input[i + (best + k) % 3];
  }
  return hash(new Uint8Array(output.buffer));
}
function codecFingerprint(doc) {
  const attribute = a => ({ count: a.getCount(), component: a.getComponentType(), type: a.getType(), normalized: a.getNormalized(), hash: hash(new Uint8Array(a.getArray().buffer, a.getArray().byteOffset, a.getArray().byteLength)) });
  return {
    nodes: doc.getRoot().listNodes().filter(n => n.getMesh()).map(n => ({ id: n.getExtras().cyrus.entityId, matrix: n.getWorldMatrix(), primitives: n.getMesh().listPrimitives().map(p => ({ mode: p.getMode(), material: p.getMaterial()?.getName(), indices: p.getIndices() ? orientedIndexHash(p.getIndices()) : null, attributes: Object.fromEntries(p.listSemantics().sort().map(s => [s, attribute(p.getAttribute(s))])) })) })).sort((a, b) => a.id.localeCompare(b.id)),
    materials: doc.getRoot().listMaterials().map(m => ({ name: m.getName(), base: m.getBaseColorFactor(), roughness: m.getRoughnessFactor(), metalness: m.getMetallicFactor(), alpha: m.getAlphaMode(), cutoff: m.getAlphaCutoff(), doubleSided: m.getDoubleSided(), emissive: m.getEmissiveFactor(), textures: ['BaseColor', 'MetallicRoughness', 'Normal', 'Occlusion', 'Emissive'].map(slot => { const t = m[`get${slot}Texture`](); return t ? { mime: t.getMimeType(), hash: hash(t.getImage()) } : null; }) })).sort((a, b) => a.name.localeCompare(b.name)),
  };
}

export async function prepareNativeGLB(source, metadata, recipe, namespace) {
  await Promise.all([MeshoptEncoder.ready, MeshoptDecoder.ready, MeshoptSimplifier.ready]);
  const loader = io(), doc = await loader.readBinary(source), root = doc.getRoot(), started = performance.now();
  if (root.listAnimations().length || root.listSkins().length || root.listMeshes().some(m => m.listPrimitives().some(p => p.listTargets().length || p.getMode() !== 4))) throw Error('Native preparation requires static triangle geometry without skin/morph data');
  const fallback = root.listMaterials().filter(m => /^fallback material$/i.test(m.getName()));
  if (fallback.length) throw Error(`Native exporter emitted ${fallback.length} fallback materials; explicitly convert unsupported materials before delivery`);
  const nativeTriangles = submitted(doc), { meshLayers, bindings, layers } = bindPlacements(doc, metadata, namespace), reductions = [];
  await doc.transform(weld());
  for (const mesh of root.listMeshes()) {
    const owners = [...(meshLayers.get(mesh) ?? [])], policies = owners.map(layer => recipe.post.layers.find(r => r.layer === layer));
    if (!owners.length || owners.some(layer => recipe.protectedLayers.includes(layer)) || policies.some(p => !p || p.ratio === 1 || p.error === 0)) continue;
    const ratio = Math.max(...policies.map(p => p.ratio)), error = Math.min(...policies.map(p => p.error)), crease = policies.every(p => p.normals === 'crease45'), before = triangles(mesh);
    for (const primitive of mesh.listPrimitives()) {
      if (crease) { primitive.setAttribute('NORMAL', null); weldPrimitive(primitive); }
      simplifyPrimitive(primitive, { simplifier: MeshoptSimplifier, ratio, error, lockBorder: true });
      if (crease) {
        const position = primitive.getAttribute('POSITION'), geometry = new BufferGeometry();
        geometry.setAttribute('position', new BufferAttribute(position.getArray(), 3)); geometry.setIndex(new BufferAttribute(primitive.getIndices().getArray(), 1));
        for (const semantic of primitive.listSemantics().filter(s => s !== 'POSITION' && s !== 'NORMAL')) { const a = primitive.getAttribute(semantic); geometry.setAttribute(semantic, new BufferAttribute(a.getArray(), a.getElementSize())); }
        const normalGeometry = toCreasedNormals(geometry, Math.PI / 4);
        for (const [name, a] of Object.entries(normalGeometry.attributes)) { const semantic = name === 'position' ? 'POSITION' : name === 'normal' ? 'NORMAL' : name, original = primitive.getAttribute(semantic); primitive.setAttribute(semantic, doc.createAccessor().setType(original?.getType() ?? 'VEC3').setArray(a.array).setBuffer(position.getBuffer())); }
        primitive.setIndices(null); weldPrimitive(primitive); normalGeometry.dispose(); geometry.dispose();
      }
    }
    const after = triangles(mesh); if (!after || after > before) throw Error('Invalid post-export simplification result');
    reductions.push({ layers: owners, before, after, ratio, relativeError: error, normals: crease ? 'crease45' : 'preserve' });
  }
  const operations = [dedup({ propertyTypes: ['Mesh', 'Material', 'Texture', 'Accessor'] }), prune()];
  if (recipe.post.textureFormat === 'webp') operations.push(textureCompress({ encoder: sharp, targetFormat: 'webp', resize: [recipe.post.textureEdge, recipe.post.textureEdge], quality: recipe.post.textureQuality }));
  if (recipe.post.quantization) { const q = recipe.post.quantization; operations.push(quantize({ quantizePosition: q.positionBits, quantizeNormal: q.normalBits, quantizeTexcoord: q.uvBits })); }
  await doc.transform(...operations, weld(), dedup({ propertyTypes: ['Accessor'] }), prune());
  // Establish the actual ordinary GLB representation before testing the codec.
  // NodeIO omits near-default transforms (writer tolerance 10e-6); this is serialization, not compression.
  const beforeSerialization = codecFingerprint(doc), uncompressed = await loader.writeBinary(doc), canonicalDoc = await loader.readBinary(uncompressed), canonicalFingerprint = codecFingerprint(canonicalDoc);
  let serializationMatrixError = 0;
  if (beforeSerialization.nodes.length !== canonicalFingerprint.nodes.length || JSON.stringify(beforeSerialization.materials) !== JSON.stringify(canonicalFingerprint.materials)) throw Error('Ordinary GLB serialization changes scene membership or materials');
  for (let i = 0; i < beforeSerialization.nodes.length; i++) {
    const a = beforeSerialization.nodes[i], b = canonicalFingerprint.nodes[i];
    if (a.id !== b.id || JSON.stringify(a.primitives) !== JSON.stringify(b.primitives)) throw Error('Ordinary GLB serialization changes decoded geometry');
    serializationMatrixError = Math.max(serializationMatrixError, ...a.matrix.map((v, index) => Math.abs(v - b.matrix[index])));
  }
  if (serializationMatrixError > .000001) throw Error('Ordinary GLB transform serialization exceeds the preparation tolerance');
  let bytes, exactCodec = null;
  if (recipe.post.meshopt) {
    const beforeCodec = canonicalFingerprint;
    canonicalDoc.createExtension(EXTMeshoptCompression).setRequired(true).setEncoderOptions({ method: EXTMeshoptCompression.EncoderMethod.QUANTIZE });
    bytes = await loader.writeBinary(canonicalDoc); const afterCodec = codecFingerprint(await loader.readBinary(bytes)); exactCodec = JSON.stringify(beforeCodec) === JSON.stringify(afterCodec);
    if (!exactCodec) {
      const changes = beforeCodec.nodes.flatMap((a, index) => { const b = afterCodec.nodes[index]; return JSON.stringify(a) === JSON.stringify(b) ? [] : [{ expected: a, actual: b, maximumMatrixDifference: b ? Math.max(...a.matrix.map((v, i) => Math.abs(v - b.matrix[i]))) : null }]; });
      const error = Error('Meshopt roundtrip changes geometry, placements or materials'); error.diagnostics = { expectedNodes: beforeCodec.nodes.length, actualNodes: afterCodec.nodes.length, materialsExact: JSON.stringify(beforeCodec.materials) === JSON.stringify(afterCodec.materials), changedNodes: changes.length, examples: changes.slice(0, 20) }; throw error;
    }
  } else bytes = uncompressed;
  const asset = await inspectGLB(bytes, 'optimized.glb');
  return { bytes, uncompressed, report: { version: '0.1.0', sourceSha256: hash(source), outputSha256: hash(bytes), uncompressedSha256: hash(uncompressed), sourceBytes: source.length, outputBytes: bytes.length, uncompressedBytes: uncompressed.length, maximumSerializationMatrixEntryError: serializationMatrixError, nativeSubmittedTriangles: nativeTriangles, submittedTriangles: asset.triangles, uniqueTriangles: root.listMeshes().reduce((n, m) => n + triangles(m), 0), estimatedSourceGpuBytes: asset.gpuBytes, materials: root.listMaterials().length, textures: root.listTextures().length, renderedPlacements: bindings.length, layers, bindings, reductions, exactMeshoptRoundtrip: exactCodec, warnings: asset.warnings, postElapsedMs: performance.now() - started, versions: { gltfTransform: '4.5.1', meshoptimizerEncoder: '1.3.0', three: '0.186.1', decoder: 'Three bundled meshoptimizer 1.1', sharp: '0.35.5' }, limits: ['Relative simplification error is algorithmic, not a measured Hausdorff guarantee.', 'Quantization and texture preparation are lossy recorded choices.', 'Ordinary GLB serialization can omit near-default transforms; its measured error is separate from exact codec roundtrip.', 'Numeric admission and codec identity do not replace visual or hardware qualification.'] } };
}

if (process.argv[1] && resolve(process.argv[1]) === fileURLToPath(import.meta.url)) {
  const directory = resolve(process.argv[2] ?? ''), plan = JSON.parse(await readFile(`${directory}/plan.json`, 'utf8'));
  if ((await stat(`${directory}/native.glb`)).size > 2 * 1024 ** 3) throw Error('Native GLB exceeds the preparation working-set ceiling');
  let result;
  try { result = await prepareNativeGLB(await readFile(`${directory}/native.glb`), JSON.parse(await readFile(`${directory}/export-nodes.json`, 'utf8')), plan.recipe, `max:${plan.sourceSha256.slice(0, 16)}`); }
  catch (error) { await writeFile(`${directory}/post-failure-${Date.now()}.json`, JSON.stringify({ error: String(error), diagnostics: error.diagnostics }, null, 2), { flag: 'wx' }); throw error; }
  await writeFile(`${directory}/optimized.glb`, result.bytes, { flag: 'wx' }); await writeFile(`${directory}/uncompressed.glb`, result.uncompressed, { flag: 'wx' }); await writeFile(`${directory}/post-report.json`, JSON.stringify(result.report, null, 2), { flag: 'wx' });
  console.log(JSON.stringify({ phase: 'post-export-complete', bytes: result.bytes.length, triangles: result.report.submittedTriangles, sha256: result.report.outputSha256 }));
}
