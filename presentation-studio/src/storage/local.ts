import { referencedHashes } from './archive';
import { sha256 } from '../core/hash';
import { validateProject, type Files, type Project } from '../core/model';
const DATABASE = 'cyrus-presentation-v1', BLOB_DIRECTORY = 'cyrus-presentation-blobs-v1';
const request = <T>(r: IDBRequest<T>) => new Promise<T>((resolve, reject) => { r.onsuccess = () => resolve(r.result); r.onerror = () => reject(r.error); });
const complete = (tx: IDBTransaction) => new Promise<void>((resolve, reject) => { tx.oncomplete = () => resolve(); tx.onabort = tx.onerror = () => reject(tx.error ?? new Error('Autosave transaction aborted')); });
async function database(): Promise<IDBDatabase> {
  const r = indexedDB.open(DATABASE, 1);
  r.onupgradeneeded = () => { r.result.createObjectStore('blobs'); r.result.createObjectStore('metadata'); };
  return request(r);
}
async function directory(): Promise<FileSystemDirectoryHandle | undefined> {
  const storage = navigator.storage as StorageManager & { getDirectory?: () => Promise<FileSystemDirectoryHandle> };
  const root = await storage?.getDirectory?.().catch(() => undefined);
  return root?.getDirectoryHandle(BLOB_DIRECTORY, { create: true });
}
type Pending = { project: Project; blobs: Files; waiters: { resolve(): void; reject(error: unknown): void }[] };
export class LocalStore {
  private pending: Pending | null = null;
  private active = false;
  save(project: Project, blobs: Files): Promise<void> {
    return new Promise((resolve, reject) => {
      const waiters = [...(this.pending?.waiters ?? []), { resolve, reject }];
      this.pending = { project: structuredClone(project), blobs: new Map(blobs), waiters }; void this.pump();
    });
  }
  private async pump() {
    if (this.active) return; this.active = true;
    try {
      while (this.pending) { const next = this.pending; this.pending = null; try { await this.write(next.project, next.blobs); next.waiters.forEach(w => w.resolve()); } catch (error) { next.waiters.forEach(w => w.reject(error)); } }
    } finally { this.active = false; }
  }
  private async write(project: Project, blobs: Files) {
    const db = await database();
    try {
      let root = await directory();
      const hashes = referencedHashes(project), keep = new Set(hashes), staged = new Map<string, Uint8Array>();
      for (const hash of hashes) {
        const bytes = blobs.get(hash); if (!bytes || await sha256(bytes) !== hash) throw new Error('Autosave resource integrity failed');
        if (root) {
          const file = await root.getFileHandle(hash, { create: true });
          if (typeof file.createWritable !== 'function') { root = undefined; break; }
          const writer = await file.createWritable(); await writer.write(bytes as Uint8Array<ArrayBuffer>); await writer.close();
        }
      }
      if (!root) for (const hash of hashes) staged.set(hash, blobs.get(hash)!);
      const tx = db.transaction(['blobs', 'metadata'], 'readwrite'), finish = complete(tx), store = tx.objectStore('blobs');
      for (const [hash, bytes] of staged) store.put(bytes, hash);
      const keys = store.getAllKeys(); keys.onsuccess = () => { for (const key of keys.result) if (!keep.has(String(key)) || root) store.delete(key); };
      tx.objectStore('metadata').put({ project, storage: root ? 'opfs' : 'indexeddb' }, 'committed'); await finish;
      if (root) for await (const [name] of (root as any).entries()) if (/^[a-f0-9]{64}$/.test(name) && !keep.has(name)) await root.removeEntry(name).catch(() => {});
    } finally { db.close(); }
  }
  async load(): Promise<{ project: Project; blobs: Files } | null> {
    const db = await database();
    try {
      const saved = await request(db.transaction('metadata', 'readonly').objectStore('metadata').get('committed'));
      if (!saved) return null; const project = validateProject(saved.project), blobs: Files = new Map();
      const root = saved.storage === 'opfs' ? await directory() : undefined;
      if (saved.storage === 'opfs' && !root) throw new Error('Local blob storage unavailable; reopen your portable archive');
      for (const hash of referencedHashes(project)) {
        const bytes = root ? new Uint8Array(await (await (await root.getFileHandle(hash)).getFile()).arrayBuffer()) : await request(db.transaction('blobs', 'readonly').objectStore('blobs').get(hash));
        if (!bytes || await sha256(bytes) !== hash) throw new Error('Autosave resource missing; reopen your portable archive'); blobs.set(hash, bytes);
      }
      return { project, blobs };
    } finally { db.close(); }
  }
}
