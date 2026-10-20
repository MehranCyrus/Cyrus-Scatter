import { mkdir, writeFile } from 'node:fs/promises';
import { createHash } from 'node:crypto';
const root = new URL('../exports/fixtures/khronos/', import.meta.url);
await mkdir(root, { recursive: true });
const receipts = [];
for (const name of ['BoxTextured', 'AlphaBlendModeTest', 'NormalTangentTest']) {
  for (const suffix of ['README.md', `glTF-Binary/${name}.glb`]) {
    const url = `https://raw.githubusercontent.com/KhronosGroup/glTF-Sample-Assets/main/Models/${name}/${suffix}`;
    const response = await fetch(url); if (!response.ok) throw new Error(`${response.status}: ${url}`);
    const data = Buffer.from(await response.arrayBuffer()), path = `${name}${suffix === 'README.md' ? '.README.md' : '.glb'}`;
    await writeFile(new URL(path, root), data); receipts.push({ url, path, sha256: createHash('sha256').update(data).digest('hex'), bytes: data.length });
  }
}
await writeFile(new URL('provenance.json', root), JSON.stringify(receipts, null, 2));
console.log('Downloaded three opt-in Khronos fixtures to ignored exports/fixtures/khronos; read their README legal sections before reuse.');
