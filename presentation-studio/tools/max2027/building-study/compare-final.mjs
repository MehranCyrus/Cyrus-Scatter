import sharp from 'sharp';
import { readFile, writeFile } from 'node:fs/promises';
const folder = 'exports/building-20261016/final-browser-v2', rows = [];
for (const seconds of [2, 7, 16, 29, 38]) {
  const name = String(seconds).padStart(2, '0');
  const a = await sharp(`${folder}/source-${name}.png`).ensureAlpha().raw().toBuffer({ resolveWithObject: true });
  const b = await sharp(`${folder}/final-${name}.png`).ensureAlpha().raw().toBuffer({ resolveWithObject: true });
  if (a.info.width !== b.info.width || a.info.height !== b.info.height) throw Error('View dimensions differ.');
  let sum = 0, maximum = 0, changed = 0, over8 = 0;
  for (let pixel = 0; pixel < a.data.length; pixel += 4) {
    let difference = 0;
    for (let channel = 0; channel < 3; channel++) { const d = Math.abs(a.data[pixel + channel] - b.data[pixel + channel]); sum += d; maximum = Math.max(maximum, d); difference = Math.max(difference, d); }
    if (difference) changed++; if (difference > 8) over8++;
  }
  const pixels = a.info.width * a.info.height;
  rows.push({ seconds, width: a.info.width, height: a.info.height, meanAbsoluteChannelError: sum / (pixels * 3), maximumChannelError: maximum, changedPixels: changed, pixelsOver8: over8, fractionOver8: over8 / pixels });
}
const report = JSON.parse(await readFile(`${folder}/report.json`, 'utf8'));

await writeFile(`${folder}/render-comparison.json`, JSON.stringify({ presentationFieldsPreserved: report.presentationPreserved, rows, note: 'Independent preparation successor: review colour changes alongside world geometry and current camera evidence.' }, null, 2));
console.log(JSON.stringify(rows, null, 2));

