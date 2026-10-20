import { loadCameraClips } from '../presentation/camera-clip';
import { z } from 'zod';
import { publicGLB } from '../assets/prune';
import { encode, sha256 } from '../core/hash';
import { projectSchema, resolveLayer, validateProject, type Files, type Project } from '../core/model';
import { photoFingerprint, sceneFingerprint, stalePhoto } from '../presentation/evaluate';
import { prepareImage } from '../assets/images';
export const manifestSchema = z.object({ format: z.literal('cyrus-presentation'), version: z.literal(1), playerVersion: z.literal('0.3.0'), project: projectSchema, resources: z.record(z.string().regex(/^[a-f0-9]{64}$/), z.object({ path: z.string(), bytes: z.number().int().nonnegative(), mime: z.string() })) });
export type Manifest = z.infer<typeof manifestSchema>;
export const imageMime = (bytes: Uint8Array) => bytes[0] === 0x89 ? 'image/png' : bytes[0] === 255 ? 'image/jpeg' : 'image/webp';
export async function compile(project: Project, blobs: Files, shell: Files, signal?: AbortSignal): Promise<{ manifest: Manifest; files: Files }> {
  validateProject(project); await loadCameraClips(project, blobs); const p = structuredClone(project), files: Files = new Map(shell), resources: Manifest['resources'] = {};
  p.revision = 0; p.assets = []; p.instances = []; p.layers = p.layers.filter(l => l.included);
  if (p.timeline) p.timeline.layers = p.timeline.layers.filter(t => p.layers.some(l => l.id === t.layerId));
  const sourceScene = sceneFingerprint(project);
  if (project.stops.some(s => stalePhoto(project, s, sourceScene))) throw new Error('An artistic photo is stale. Review and approve or remove it before exporting.');
  const add = async (bytes: Uint8Array, extension: string, mime: string) => { const hash = await sha256(bytes), path = `assets/${hash}.${extension}`; files.set(path, bytes); resources[hash] = { path, bytes: bytes.length, mime }; return hash; };
  for (const instance of project.instances) {
    signal?.throwIfAborted(); const asset = project.assets.find(a => a.revisionId === instance.assetRevision)!;
    if (!asset.nodes.some(n => n.renderable && p.layers.some(l => l.id === resolveLayer(n.key, asset, instance)))) continue;
    const source = blobs.get(asset.hash); if (!source || await sha256(source) !== asset.hash) throw new Error('Missing or corrupt GLB source');
    const output = publicGLB(source, asset, instance, project.layers), hash = await add(output.bytes, 'glb', 'model/gltf-binary');
    const prepared = { ...asset, id: instance.id, revisionId: instance.id, name: 'Landscape', hash, nodes: output.nodes, nodeKeys: output.nodes.map(n => n.key), bytes: output.bytes.length, warnings: [] };
    p.assets.push(prepared); p.instances.push({ ...instance, name: '', assetRevision: prepared.revisionId, membership: Object.fromEntries(Object.entries(instance.membership).filter(([key, value]) => output.nodes.some(n => n.key === key) && p.layers.some(l => l.id === value))) });
  }
  for (const hash of new Set(p.segments.flatMap(s => s.cameraClip ? [s.cameraClip.hash] : []))) await add(blobs.get(hash)!, 'json', 'application/json');
  const preparedImages = new Map<string, Promise<string>>();
  const copyImage = (hash: string): Promise<string> => {
    if (!preparedImages.has(hash)) preparedImages.set(hash, (async () => { const bytes = blobs.get(hash); if (!bytes || await sha256(bytes) !== hash) throw new Error('Missing or corrupt image'); const derivative = await prepareImage(bytes, p.profile), mime = imageMime(derivative); return add(derivative, mime.split('/')[1], mime); })());
    return preparedImages.get(hash)!;
  };
  if (p.plan) p.plan.hash = await copyImage(p.plan.hash);
  for (const stop of p.stops) if (stop.photo) { stop.photo.hash = await copyImage(stop.photo.hash); if (stop.photo.portraitHash) stop.photo.portraitHash = await copyImage(stop.photo.portraitHash); }
  // Public asset IDs differ after pruning; approve the identical prepared presentation state, never carry editor fingerprints.
  const compiledScene = sceneFingerprint(p);
  for (const s of p.stops) if (s.photo) s.photo.approvedFingerprint = photoFingerprint(p, s, compiledScene);
  validateProject(p); const manifest: Manifest = { format: 'cyrus-presentation', version: 1, playerVersion: '0.3.0', project: p, resources };
  files.set('manifest.json', encode(manifest));
  files.set('README.txt', new TextEncoder().encode('Cyrus Presentation\nUnpack this complete folder and upload it to static HTTP/HTTPS hosting. Open index.html through HTTP, including nested paths. No studio, API or login is needed. Do not use file://. Artistic images are labelled interpretations. Viewer layer changes are session-only.\n'));
  if (!files.has('index.html')) throw new Error('Player shell is unavailable. Build the player before the studio.'); return { manifest, files };
}
