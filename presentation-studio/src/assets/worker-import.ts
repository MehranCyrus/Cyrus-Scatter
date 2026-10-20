import { inspectGLB } from './glb';
import type { Asset } from '../core/model';
export async function inspectInWorker(bytes: Uint8Array, name: string, logicalId?: string, signal?: AbortSignal): Promise<Asset> {
  signal?.throwIfAborted();
  if (typeof Worker === 'undefined') return inspectGLB(bytes, name, logicalId);
  return new Promise((resolve, reject) => {
    const worker = new Worker(new URL('../workers/import.ts', import.meta.url), { type: 'module' });
    const abort = () => { done(); reject(new DOMException('Import cancelled', 'AbortError')); };
    const done = () => { signal?.removeEventListener('abort', abort); worker.terminate(); };
    worker.onmessage = event => { done(); if (event.data.error) reject(new Error(event.data.error)); else resolve(event.data.asset); };
    worker.onerror = event => { done(); reject(new Error(event.message)); };
    signal?.addEventListener('abort', abort, { once: true });
    const owned = bytes.slice(); worker.postMessage({ bytes: owned, name, logicalId }, [owned.buffer]);
  });
}
