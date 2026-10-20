import { test } from 'node:test';
import assert from 'node:assert/strict';
import { Document, NodeIO } from '@gltf-transform/core';
import { ALL_EXTENSIONS } from '@gltf-transform/extensions';
import { MeshoptDecoder } from 'three/addons/libs/meshopt_decoder.module.js';
import { SphereGeometry } from 'three';
import { prepareNativeGLB } from '../post.mjs';
import { inspectGLB } from '../../../../src/assets/glb.ts';
const recipe = () => ({ protectedLayers: [], post: { layers: [], textureFormat: 'preserve', textureEdge: 2048, textureQuality: 92, quantization: null, meshopt: true } });

async function fixture() {
  const doc = new Document(), buffer = doc.createBuffer(), geometry = new SphereGeometry(4, 64, 32);
  const accessor = (name, values, type) => doc.createAccessor(name).setBuffer(buffer).setArray(values).setType(type);
  const material = doc.createMaterial('Owned PBR').setBaseColorFactor([.2, .3, .4, 1]).setRoughnessFactor(.7).setMetallicFactor(0);
  const primitive = doc.createPrimitive().setAttribute('POSITION', accessor('position', geometry.attributes.position.array, 'VEC3')).setAttribute('NORMAL', accessor('normal', geometry.attributes.normal.array, 'VEC3')).setAttribute('TEXCOORD_0', accessor('uv', geometry.attributes.uv.array, 'VEC2')).setIndices(accessor('indices', geometry.index.array, 'SCALAR')).setMaterial(material);
  const mesh = doc.createMesh().addPrimitive(primitive), parent = doc.createNode('Source hierarchy').setTranslation([12, 3, 8]), a = doc.createNode('NativeOwner1').setMesh(mesh).setTranslation([5, 0, 0]), b = doc.createNode('NativeOwner1').setMesh(mesh).setTranslation([-5, 0, 0]).setScale([-1, 2, 1]);
  parent.addChild(a).addChild(b); doc.createScene().addChild(parent);
  const metadata = [a, b].map((n, i) => ({ exportName: `NativeOwner${i + 1}`, handle: i + 1, name: `Original placement ${i + 1}`, layer: i ? 'Protected' : 'Reduce', instanceOwner: 1, exportIncluded: true, evaluatedTriangles: geometry.index.count / 3, objectMatrix: n.getWorldMatrix() }));
  geometry.dispose(); return { source: await new NodeIO().writeBinary(doc), metadata };
}

test('native reused instance names bind distinct IDs while layer grouping retains world transforms and shared geometry', async () => {
  const { source, metadata } = await fixture(), copy = source.slice(), result = await prepareNativeGLB(source, metadata, recipe(), 'owned');
  assert.deepEqual(source, copy); assert.equal(result.report.renderedPlacements, 2); assert.equal(result.report.exactMeshoptRoundtrip, true);
  await MeshoptDecoder.ready; const doc = await new NodeIO().registerExtensions(ALL_EXTENSIONS).registerDependencies({ 'meshopt.decoder': MeshoptDecoder }).readBinary(result.bytes);
  const nodes = doc.getRoot().listNodes().filter(n => n.getMesh()); assert.equal(nodes[0].getMesh(), nodes[1].getMesh());
  for (const n of nodes) { const original = metadata.find(m => n.getExtras().cyrus.entityId === `owned:node:${m.handle}`); assert.ok(original); n.getWorldMatrix().forEach((v, i) => assert.ok(Math.abs(v - original.objectMatrix[i]) < .00001)); }
  assert.equal((await inspectGLB(result.bytes, 'prepared')).triangles, metadata.reduce((sum, n) => sum + n.evaluatedTriangles, 0));
});

test('a protected member prevents lossy simplification of a shared mesh; explicit unprotected rules reduce it', async () => {
  const { source, metadata } = await fixture(), config = recipe(); config.protectedLayers = ['Protected']; config.post.layers = ['Reduce', 'Protected'].map(layer => ({ layer, ratio: .3, error: .01, normals: 'crease45' }));
  const protectedResult = await prepareNativeGLB(source, metadata, config, 'owned'); assert.equal(protectedResult.report.reductions.length, 0);
  config.protectedLayers = []; const reduced = await prepareNativeGLB(source, metadata, config, 'owned'); assert.ok(reduced.report.submittedTriangles < protectedResult.report.submittedTriangles); assert.equal(reduced.report.reductions.length, 1);
  assert.equal(reduced.report.renderedPlacements, 2); assert.equal(reduced.report.exactMeshoptRoundtrip, true);
});

test('hidden native prototype names can bind an included placement, while ambiguous or omitted geometry fails', async () => {
  const { source, metadata } = await fixture();
  const ambiguous = structuredClone(metadata); ambiguous[1].objectMatrix = [...ambiguous[0].objectMatrix]; await assert.rejects(prepareNativeGLB(source, ambiguous, recipe(), 'owned'), /Ambiguous/);
  const missing = structuredClone(metadata); missing.push({ ...missing[0], exportName: 'NativeOwner3', handle: 3, objectMatrix: missing[0].objectMatrix.map((v, i) => i === 12 ? v + 100 : v) }); await assert.rejects(prepareNativeGLB(source, missing, recipe(), 'owned'), /omitted/);
  // The prototype may be hidden even though its reused export name labels visible instances.
  const hidden = { ...metadata[0], exportName: 'NativeOwner1', handle: 0, exportIncluded: false }; const included = metadata.map((m, i) => ({ ...m, exportName: `VisibleName${i}` }));
  const result = await prepareNativeGLB(source, [hidden, ...included], recipe(), 'owned'); assert.equal(result.report.renderedPlacements, 2);
});

test('the measured exporter fallback marker is rejected without treating an ordinary artist fallback label as unsupported', async () => {
  const { source, metadata } = await fixture(), loader = new NodeIO(), doc = await loader.readBinary(source);
  doc.getRoot().listMaterials()[0].setName('Artist fallback sandstone');
  await assert.doesNotReject(prepareNativeGLB(await loader.writeBinary(doc), metadata, recipe(), 'owned'));
  doc.getRoot().listMaterials()[0].setName('fallback Material');
  await assert.rejects(prepareNativeGLB(await loader.writeBinary(doc), metadata, recipe(), 'owned'), /fallback materials/);
});

test('near-default transform serialization is measured separately and does not weaken exact codec identity', async () => {
  const { source, metadata } = await fixture(), loader = new NodeIO(), doc = await loader.readBinary(source);
  const position = doc.getRoot().listMeshes()[0].listPrimitives()[0].getAttribute('POSITION');
  position.setArray(position.getArray().map(v => v / 4 * .999999847));
  const config = recipe(); config.post.quantization = { positionBits: 16, normalBits: 12, uvBits: 16 };
  const result = await prepareNativeGLB(await loader.writeBinary(doc), metadata, config, 'owned');
  assert.ok(result.report.maximumSerializationMatrixEntryError > 0); assert.ok(result.report.maximumSerializationMatrixEntryError < .000001);
  assert.equal(result.report.exactMeshoptRoundtrip, true); assert.ok(result.uncompressed.length > result.bytes.length);
});
