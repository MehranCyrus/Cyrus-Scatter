import { readFile, writeFile, mkdir } from 'node:fs/promises';
import { resolve } from 'node:path';
import sharp from 'sharp';
import { Quaternion } from 'three';
import { inspectGLB } from '../src/assets/glb';
import { sha256 } from '../src/core/hash';
import { emptyProject, identityTransform, reconnect, uuid, type Files, type Vec3 } from '../src/core/model';
import { lookQuaternion, photoFingerprint } from '../src/presentation/evaluate';
import { packSync, projectFiles } from '../src/storage/archive';

// Explicit acceptance fixture adapter; no runtime dependency on, or mutation of, the website.
const sourceRoot = resolve('../website/prototypes/botanical-islands/public/assets'), output = resolve('exports/fixtures/previous-study');
await mkdir(output, { recursive: true });
const model = new Uint8Array(await readFile(resolve(sourceRoot, 'models/botanical-islands-garden.glb'))), asset = await inspectGLB(model, 'Botanical Islands original');
if (asset.hash !== 'a4ae0b17d3bbff359df72360d549f90e99f2fc6878249df6e59d3428551de93d') throw new Error('Previous study GLB changed; review its provenance before updating this fixture');
const layoutBytes = await readFile(resolve(sourceRoot, 'data/botanical-islands-layout.json')), layout = JSON.parse(layoutBytes.toString()), svg = await readFile(resolve(sourceRoot, 'vectors/01-base-blueprint.svg'));
const plan = new Uint8Array(await sharp(svg, { density: 72 }).png().toBuffer()), planHash = await sha256(plan), project = emptyProject(), blobs: Files = new Map([[asset.hash, model], [planHash, plan]]);
project.title = 'Botanical Islands — presentation MVP'; project.assets = [asset]; project.opening = 3; project.revealDuration = 6;
project.layers = ['Site', 'Paths', 'Building', 'Ground cover', 'Understory', 'Trees'].map((name, i) => ({ id: uuid(), name, included: true, defaultVisible: true, viewerToggle: i >= 3, reveal: i < 3 ? 0 : .15 + (i - 3) * .22, fade: .16 }));
const membership: Record<string, string> = {};
for (const node of asset.nodes) {
  const name = node.name.toLowerCase();
  const index = name.startsWith('trees_') ? 5 : name.startsWith('grasses_') || name.startsWith('ferns_') ? 3 : name.startsWith('shrubs_') || name.startsWith('flower_') ? 4 : /pavilion|building/.test(name) ? 2 : /path|courtyard|meeting/.test(name) ? 1 : !node.parent ? 0 : -1;
  if (index >= 0) membership[node.key] = project.layers[index].id;
}
project.instances = [{ id: uuid(), assetRevision: asset.revisionId, name: 'Botanical Islands original GLB', transform: identityTransform(), membership }];
project.plan = { hash: planHash, width: 1536, height: 1024, a: [768, 510], b: [1048, 510], distance: 10, origin: [0, 0, 0], rotation: 0, third: { pixel: [768, 790], world: [0, 0, 10] } };
const vector = (point: any): Vec3 => [point.x, point.y, point.z];
const overhead: Vec3 = [0, 58, 0.01];
project.stops = [{ id: uuid(), name: 'The masterplan', position: overhead, quaternion: lookQuaternion(overhead, [0, 0, 0]), fov: 45, aspect: 1.5, hold: 2 }];
const cameraStops = layout.CAMERA_STOPS;
for (let i = 0; i < layout.CAMERA_ROUTE.length; i++) {
  const point = layout.CAMERA_ROUTE[i], authored = cameraStops.find((s: any) => s.routeIndex === i);
  let quaternion;
  if (authored) quaternion = lookQuaternion(vector(authored.position), vector(authored.target));
  else {
    const from = cameraStops.filter((s: any) => s.routeIndex < i).at(-1), to = cameraStops.find((s: any) => s.routeIndex > i), fraction = (i - from.routeIndex) / (to.routeIndex - from.routeIndex);
    quaternion = new Quaternion().fromArray(lookQuaternion(vector(from.position), vector(from.target))).slerp(new Quaternion().fromArray(lookQuaternion(vector(to.position), vector(to.target))), fraction).toArray() as [number, number, number, number];
  }
  project.stops.push({ id: uuid(), name: authored?.name ?? `Path waypoint ${i}`, position: vector(point), quaternion, fov: authored?.fov.desktop ?? 56, aspect: 1586 / 992, hold: authored ? 5 : 0 });
}
reconnect(project);
for (const segment of project.segments) { const a = project.stops.find(s => s.id === segment.from)!, b = project.stops.find(s => s.id === segment.to)!; segment.duration = Math.max(.1, Math.hypot(...b.position.map((v, i) => v - a.position[i])) / (a.name === 'The masterplan' ? 7 : 1.6)); segment.ease = a.hold || b.hold ? .09 : 0; }
const photographs = ['01-western-meadow.png', '02-upper-garden-fork.png', '03-meeting-clearing.png', '04-pavilion-finale.png'];
const photoSources = [];
for (let i = 0; i < photographs.length; i++) {
  const bytes = new Uint8Array(await readFile(resolve(sourceRoot, 'photographs', photographs[i]))), hash = await sha256(bytes); blobs.set(hash, bytes);
  const stop = project.stops.find(s => s.name === cameraStops[i].name)!; stop.photo = { hash, caption: 'Artistic interpretation from the earlier Botanical Islands study' }; stop.photo.approvedFingerprint = photoFingerprint(project, stop);
  photoSources.push({ file: photographs[i], hash, bytes: bytes.length });
}
const archive = packSync(await projectFiles(project, blobs)); await writeFile(resolve(output, 'botanical-islands.cyrus-presentation.zip'), archive);
const provenance = { source: sourceRoot, sourceGlbSha256: asset.hash, sourceBytes: model.length, nodeCount: asset.nodes.length, triangles: asset.triangles, gpuBytes: asset.gpuBytes, instanceBytes: asset.instanceBytes, canonicalPlantIds: layout.PLANTS.length, layoutSha256: await sha256(layoutBytes), planSvgSha256: await sha256(svg), planPngSha256: planHash, planPreparation: 'sharp SVG rasterization, 1536x1024, density 72; original SVG untouched', photoSources, layers: project.layers.map(l => l.name), stops: project.stops.length, archiveSha256: await sha256(archive), route: 'Original 16 world waypoints retained as zero-hold route stops; initial overhead added. Linear Bezier segments preserve the polyline. New MVP timing/orientation interpolation is not claimed identical to the prior player.', approvals: 'Scripted acceptance-fixture approval of existing artistic images; admin review still required before publication.' };
await writeFile(resolve(output, 'provenance.json'), JSON.stringify(provenance, null, 2)); console.log(JSON.stringify(provenance, null, 2));
