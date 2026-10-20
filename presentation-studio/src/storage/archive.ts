import { unzipSync, zipSync } from 'fflate';
import { loadCameraClips } from '../presentation/camera-clip';
import { LIMITS } from '../assets/glb';
import { encode, sha256 } from '../core/hash';
import { validateProject, type Files, type Project } from '../core/model';

export function safePath(path: string): boolean { return !!path && path.length < 500 && !path.startsWith('/') && !path.includes('\\') && !path.includes(':') && !path.split('/').some(x => x === '..' || x === '.' || !x); }
export function inspectZIPInfo(bytes: Uint8Array): { paths: string[]; expanded: number; entries: { name: string; size: number; crc: number }[] } {
  if (bytes.length > LIMITS.fileBytes || bytes.length < 22) throw new Error('Archive exceeds the 250 MiB admission limit or is truncated');
  const view = new DataView(bytes.buffer, bytes.byteOffset, bytes.byteLength); let end = -1;
  for (let i = bytes.length - 22; i >= Math.max(0, bytes.length - 65557); i--) if (view.getUint32(i, true) === 0x06054b50 && i + 22 + view.getUint16(i + 20, true) === bytes.length) { end = i; break; }
  if (end < 0 || view.getUint16(end + 4, true) || view.getUint16(end + 6, true)) throw new Error('Invalid or multipart archive');
  const count = view.getUint16(end + 10, true), size = view.getUint32(end + 12, true), start = view.getUint32(end + 16, true);
  if (count === 65535 || count > 10000 || start + size > end) throw new Error('Unsupported or oversized archive directory');
  let cursor = start, expanded = 0; const paths: string[] = [], entries: { name: string; size: number; crc: number }[] = [];
  for (let i = 0; i < count; i++) {
    if (cursor + 46 > end || view.getUint32(cursor, true) !== 0x02014b50) throw new Error('Corrupt archive directory');
    const length = view.getUint16(cursor + 28, true), extra = view.getUint16(cursor + 30, true), comment = view.getUint16(cursor + 32, true), name = new TextDecoder('utf-8', { fatal: true }).decode(bytes.subarray(cursor + 46, cursor + 46 + length));
    expanded += view.getUint32(cursor + 24, true);
    if (view.getUint16(cursor + 8, true) & 1 || expanded > LIMITS.expandedBytes || !safePath(name) || paths.includes(name) || cursor + 46 + length + extra + comment > end) throw new Error('Unsafe, encrypted, duplicate or oversized archive entry');
    paths.push(name); entries.push({ name, size: view.getUint32(cursor + 24, true), crc: view.getUint32(cursor + 16, true) }); cursor += 46 + length + extra + comment;
  }
  if (cursor !== start + size) throw new Error('Archive directory length mismatch'); return { paths, expanded, entries };
}
export function inspectZIP(bytes: Uint8Array): string[] { return inspectZIPInfo(bytes).paths; }
const crcTable = Uint32Array.from({ length: 256 }, (_, value) => { for (let i = 0; i < 8; i++) value = value & 1 ? 0xedb88320 ^ (value >>> 1) : value >>> 1; return value >>> 0; });
function crc32(bytes: Uint8Array) { let result = 0xffffffff; for (const b of bytes) result = crcTable[(result ^ b) & 255] ^ (result >>> 8); return (result ^ 0xffffffff) >>> 0; }
export function packSync(files: Files): Uint8Array {
  let expanded = 0; const ordered: Record<string, Uint8Array | [Uint8Array, any]> = {};
  for (const [path, bytes] of [...files].sort(([a], [b]) => a.localeCompare(b))) { if (!safePath(path)) throw new Error('Unsafe archive path'); expanded += bytes.length; ordered[path] = [bytes, { mtime: new Date(2020, 0, 1), level: /\.(png|jpg|webp|glb)$/.test(path) ? 0 : 6 }]; }
  if (expanded > LIMITS.expandedBytes) throw new Error('Expanded archive exceeds 512 MiB');
  const packed = zipSync(ordered as any); if (packed.length > LIMITS.fileBytes) throw new Error('Packed archive exceeds 250 MiB'); return packed;
}
export function unpackSync(bytes: Uint8Array): Files {
  const info = inspectZIPInfo(bytes), files = new Map(Object.entries(unzipSync(bytes)));
  for (const entry of info.entries) { const data = files.get(entry.name); if (!data || data.length !== entry.size || crc32(data) !== entry.crc) throw new Error('Archive CRC or expanded-length integrity failure'); }
  return files;
}
export async function archiveWork(kind: 'pack' | 'unpack', input: Files | Uint8Array, signal?: AbortSignal): Promise<Files | Uint8Array> {
  signal?.throwIfAborted();
  if (typeof Worker === 'undefined') return kind === 'pack' ? packSync(input as Files) : unpackSync(input as Uint8Array);
  return new Promise((resolve, reject) => {
    const worker = new Worker(new URL('../workers/archive.ts', import.meta.url), { type: 'module' });
    const abort = () => { worker.terminate(); reject(new DOMException('Operation cancelled', 'AbortError')); };
    const done = () => { worker.terminate(); signal?.removeEventListener('abort', abort); };
    signal?.addEventListener('abort', abort, { once: true });
    worker.onmessage = event => { done(); if (event.data.error) reject(new Error(event.data.error)); else resolve(kind === 'pack' ? event.data.result : new Map(event.data.result)); };
    worker.onerror = event => { done(); reject(new Error(event.message)); };
    // Copies preserve the only source and the published asset buffers.
    worker.postMessage({ kind, input: input instanceof Map ? [...input] : input });
  });
}
export function referencedHashes(p: Project): string[] { return [...new Set([...p.assets.map(a => a.hash), ...p.segments.flatMap(s => s.cameraClip ? [s.cameraClip.hash] : []), ...(p.plan ? [p.plan.hash] : []), ...p.stops.flatMap(s => s.photo ? [s.photo.hash, ...(s.photo.portraitHash ? [s.photo.portraitHash] : [])] : [])])]; }
export async function projectFiles(project: Project, blobs: Files): Promise<Files> {
  validateProject(project); await loadCameraClips(project, blobs); const manifest = encode(project); if (manifest.length > 8 * 1024 * 1024) throw new Error('Project metadata exceeds the 8 MiB portable manifest limit'); const files: Files = new Map([['project.json', manifest]]);
  for (const hash of referencedHashes(project)) { const bytes = blobs.get(hash); if (!bytes || await sha256(bytes) !== hash) throw new Error(`Missing or corrupt asset: ${hash.slice(0, 12)}`); files.set(`blobs/${hash}`, bytes); }
  files.set('provenance.json', encode({ format: 'cyrus-editable-project', version: 1, originalsPreserved: true })); return files;
}
export async function readProjectArchive(bytes: Uint8Array, signal?: AbortSignal, retainedBytes = 0): Promise<{ project: Project; blobs: Files }> {
  const info = inspectZIPInfo(bytes); if (retainedBytes + bytes.length * 2 + info.expanded * 2 > 768 * 1024 * 1024) throw new Error('Archive import exceeds estimated CPU headroom; prepare smaller assets');
  const files = await archiveWork('unpack', bytes, signal) as Files;
  const raw = files.get('project.json'); if (!raw || raw.length > 8 * 1024 * 1024) throw new Error('Missing or oversized project manifest');
  const project = validateProject(JSON.parse(new TextDecoder().decode(raw))), blobs: Files = new Map();
  const allowed = new Set(['project.json', 'provenance.json', ...referencedHashes(project).map(h => `blobs/${h}`)]);
  if ([...files.keys()].some(path => !allowed.has(path))) throw new Error('Unexpected file in editable archive');
  for (const hash of referencedHashes(project)) { signal?.throwIfAborted(); const data = files.get(`blobs/${hash}`); if (!data || await sha256(data) !== hash) throw new Error(`Missing or corrupt project resource: ${hash.slice(0, 12)}`); blobs.set(hash, data); }
  await loadCameraClips(project, blobs); return { project, blobs };
}
