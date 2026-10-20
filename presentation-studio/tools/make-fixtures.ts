import { writeFile, mkdir } from 'node:fs/promises';
import { demoGLB } from '../src/assets/demo';
await mkdir('exports/fixtures', { recursive: true });
for (const [name, count] of [['medium', 1949], ['large', 25000]] as const) { const bytes = demoGLB(count, name === 'large' ? 500 : 100); await writeFile(`exports/fixtures/${name}.glb`, bytes); console.log(`${name}: ${bytes.length} bytes`); }
