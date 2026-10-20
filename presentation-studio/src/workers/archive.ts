import { packSync, unpackSync } from '../storage/archive';
self.onmessage = event => {
  try { const { kind, input } = event.data; const result = kind === 'pack' ? packSync(new Map(input)) : [...unpackSync(input)]; self.postMessage({ result }, result instanceof Uint8Array ? { transfer: [result.buffer] } : undefined); }
  catch (error) { self.postMessage({ error: error instanceof Error ? error.message : String(error) }); }
};
