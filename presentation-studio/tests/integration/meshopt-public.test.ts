import { expect, it } from 'vitest';
import { meshoptFixture } from '../helpers/meshopt-fixture';
import { inspectGLB, readGLB } from '../../src/assets/glb';
import { emptyProject, identityTransform, uuid } from '../../src/core/model';
import { compile } from '../../src/compiler/compile';
import { encode } from '../../src/core/hash';
import { MESHOPT } from '../../src/assets/meshopt';
it('prunes excluded compressed layers without expanding payloads or losing numeric validity and original membership keys', async () => {
  const { compressed } = await meshoptFixture(), asset = await inspectGLB(compressed, 'owned compressed fixture'), p = emptyProject(), membership: Record<string, string> = {};
  for (const node of asset.nodes.filter(n => !n.parent)) { const layer = { id: uuid(), name: node.name, included: node.name === 'Site', defaultVisible: true, viewerToggle: true, reveal: 0 }; p.layers.push(layer); membership[node.key] = layer.id; }
  p.assets.push(asset); p.instances.push({ id: uuid(), assetRevision: asset.revisionId, name: 'fixture', membership, transform: identityTransform() });
  const output = await compile(p, new Map([[asset.hash, compressed]]), new Map([['index.html', encode('owned shell')]])), publicAsset = output.manifest.project.assets[0], bytes = output.files.get(`assets/${publicAsset.hash}.glb`)!;
  const raw = readGLB(bytes), inspected = await inspectGLB(bytes, 'public');
  expect(raw.json.extensionsRequired).toContain(MESHOPT); expect(raw.json.buffers).toHaveLength(2);
  expect(inspected.triangles).toBeLessThan(asset.triangles); expect(bytes.length).toBeLessThan(compressed.length);
  expect(output.manifest.project.layers.map(l => l.name)).toEqual(['Site']); expect(publicAsset.nodeKeys).toEqual(publicAsset.nodes.map(n => n.key));
  expect(JSON.stringify(raw.json)).not.toContain('entityId'); expect(inspected.warnings).toEqual([]);
});
