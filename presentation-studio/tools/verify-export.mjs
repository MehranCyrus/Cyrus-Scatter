import { readFile, writeFile } from 'node:fs/promises';
import { resolve } from 'node:path';
import { createHash } from 'node:crypto';
import { unpackSync } from '../src/storage/archive.ts';
import { manifestSchema } from '../src/compiler/compile.ts';
import { loadCameraClips } from '../src/presentation/camera-clip.ts';
import { validateProject } from '../src/core/model.ts';
const path = process.argv[2]; if (!path) { console.error('Usage: npm run verify:export -- exports/presentation.zip'); process.exit(1); }
const bytes = await readFile(resolve(path)); if (bytes.length > 250 * 1024 ** 2) throw new Error('Archive too large');
const files = Object.fromEntries(unpackSync(bytes)), manifest = manifestSchema.parse(JSON.parse(new TextDecoder().decode(files['manifest.json']))); validateProject(manifest.project);
if (manifest.format !== 'cyrus-presentation' || manifest.version !== 1 || manifest.playerVersion !== '0.3.0' || !files['index.html']) throw new Error('Invalid public manifest or player shell');
for (const path of Object.keys(files)) if (path.includes('..') || path.startsWith('/') || path.includes('\\') || /studio|originals|project\.json|\.map$/.test(path)) throw new Error(`Unexpected public path ${path}`);
for (const [hash, resource] of Object.entries(manifest.resources)) { const data = files[resource.path]; if (!data || data.length !== resource.bytes || createHash('sha256').update(data).digest('hex') !== hash) throw new Error(`Resource integrity failure: ${resource.path}`); }
await loadCameraClips(manifest.project, new Map(Object.entries(manifest.resources).map(([hash, spec]) => [hash, files[spec.path]])));
const report = { archive: resolve(path), sha256: createHash('sha256').update(bytes).digest('hex'), bytes: bytes.length, files: Object.keys(files).length, resources: Object.keys(manifest.resources).length, title: manifest.project.title, layers: manifest.project.layers.length, stops: manifest.project.stops.length, checked: ['bounded ZIP directory, CRC and expanded lengths', 'manifest/player version and project schema', 'resource hashes and lengths', 'camera sample contract, endpoints and original timing', 'relative public paths', 'excluded editor/original/source-map paths'], runtimeVerification: 'Run npm run test:browser for actual nested-HTTP playback and parity checks.' };
await writeFile(`${resolve(path)}.verification.json`, JSON.stringify(report, null, 2)); console.log(JSON.stringify(report, null, 2));
