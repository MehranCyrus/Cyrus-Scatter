import type { Files } from '../core/model';
let cached: Promise<Files> | undefined;
export function playerShell(): Promise<Files> {
  return cached ??= fetch(new URL('./player-shell.json', document.baseURI)).then(r => { if (!r.ok) throw new Error('Build the player first: npm run build:player'); return r.json() as Promise<[string, string][]>; }).then(files => new Map(files.map(([path, base64]) => [path, Uint8Array.from(atob(base64), c => c.charCodeAt(0))])));
}
export function previewHTML(files: Files, token: string): { html: string; revoke(): void } {
  const urls: string[] = [], map = new Map<string, string>();
  for (const [path, bytes] of files) if (/\.(js|css)$/.test(path)) { const url = URL.createObjectURL(new Blob([bytes as Uint8Array<ArrayBuffer>], { type: path.endsWith('.js') ? 'text/javascript' : 'text/css' })); urls.push(url); map.set(path, url); }
  let html = new TextDecoder().decode(files.get('index.html'));
  html = html.replace(/(src|href)="\.\/([^"?]+)"/g, (match, attr, path) => map.has(path) ? `${attr}="${map.get(path)}"` : match);
  html = html.replace('<head>', `<head><meta name="cyrus-preview-token" content="${token}">`);
  return { html, revoke: () => urls.forEach(url => URL.revokeObjectURL(url)) };
}
