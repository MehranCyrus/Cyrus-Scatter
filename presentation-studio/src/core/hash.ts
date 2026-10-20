import { sha256 as digest } from '@noble/hashes/sha2.js';
import { bytesToHex } from '@noble/hashes/utils.js';
export const contentFingerprint = (value: unknown) => bytesToHex(digest(new TextEncoder().encode(canonical(value))));
export function canonical(value: unknown): string {
  if (Array.isArray(value)) return `[${value.map(canonical).join(',')}]`;
  if (value && typeof value === 'object') return `{${Object.entries(value).filter(([, v]) => v !== undefined).sort(([a], [b]) => a.localeCompare(b)).map(([k, v]) => `${JSON.stringify(k)}:${canonical(v)}`).join(',')}}`;
  return JSON.stringify(value);
}
export async function sha256(data: Uint8Array): Promise<string> {
  if (!globalThis.crypto?.subtle) return bytesToHex(digest(data));
  const bufferDigest = await crypto.subtle.digest('SHA-256', data as Uint8Array<ArrayBuffer>);
  return [...new Uint8Array(bufferDigest)].map(x => x.toString(16).padStart(2, '0')).join('');
}
export const encode = (value: unknown) => new TextEncoder().encode(canonical(value));
