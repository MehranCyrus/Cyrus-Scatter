import { readdir, readFile, mkdir, writeFile } from 'node:fs/promises';
import { resolve, relative } from 'node:path';
const root = resolve(import.meta.dirname, '..'), player = resolve(root, 'dist/player');
const files = [];
async function walk(dir) { for (const entry of await readdir(dir, { withFileTypes: true })) { const path = resolve(dir, entry.name); if (entry.isDirectory()) await walk(path); else files.push([relative(player, path).replaceAll('\\', '/'), (await readFile(path)).toString('base64')]); } }
await walk(player);
const notices = ['Cyrus Presentation player 0.3.0', '', await readFile(resolve(root, 'node_modules/three/LICENSE'), 'utf8'), '', await readFile(resolve(root, 'node_modules/meshoptimizer/LICENSE.md'), 'utf8'), '', await readFile(resolve(root, 'node_modules/zod/LICENSE'), 'utf8'), '', await readFile(resolve(root, 'node_modules/@noble/hashes/LICENSE'), 'utf8')].join('\n');
files.push(['notices.txt', Buffer.from(notices).toString('base64')]);
await mkdir(resolve(root, 'public'), { recursive: true }); await writeFile(resolve(root, 'public/player-shell.json'), JSON.stringify(files));
console.log(`Embedded ${files.length} player files, without studio modules.`);
