import { expect, test } from 'vitest';
import { readFileSync, existsSync, writeFileSync, mkdirSync } from 'node:fs';
import { Quaternion, Vector3 } from 'three';
import { encode, sha256 } from '../../src/core/hash';
import { emptyProject, reconnect } from '../../src/core/model';
import { cameraAt, cameraReference, parseCameraClip, loadCameraClips } from '../../src/presentation/camera-clip';
import { Evaluator } from '../../src/presentation/evaluate';
import { packSync, projectFiles, readProjectArchive } from '../../src/storage/archive';
import { compile } from '../../src/compiler/compile';

const folder = 'exports/fixtures/max-camera';
const native = test.skipIf(!existsSync(`${folder}/free-reference.json`));
const read = (name: string) => new Uint8Array(readFileSync(`${folder}/${name}.json`));
const canonical = (v: number[]) => [v[0] / 100, v[2] / 100, -v[1] / 100];

native('every native Free, Target, Physical and path-constrained sample preserves world basis, position, FOV and time', () => {
  const evidence: Record<string, unknown> = {};
  for (const name of ['free', 'target', 'physical', 'path']) {
    const clip = parseCameraClip(read(name)), reference = JSON.parse(new TextDecoder().decode(read(`${name}-reference`)));
    expect(clip.samples.length).toBe(241); expect(clip.aspect).toBeCloseTo(1920 * 1.2 / 1080, 6);
    let maxPosition = 0, maxBasis = 0, maxFov = 0, maxTime = 0;
    for (let i = 0; i < clip.samples.length; i++) {
      const s = clip.samples[i], r = reference.samples[i], q = new Quaternion().fromArray(s.quaternion);
      maxPosition = Math.max(maxPosition, new Vector3().fromArray(s.position).distanceTo(new Vector3().fromArray(canonical(r.positionMax))));
      for (const [axis, key] of [[new Vector3(1, 0, 0), 'rightMax'], [new Vector3(0, 1, 0), 'upMax'], [new Vector3(0, 0, 1), 'backMax']] as const) {
        const expected = new Vector3().fromArray(canonical(r[key])).normalize(); maxBasis = Math.max(maxBasis, axis.applyQuaternion(q).distanceTo(expected));
      }
      maxFov = Math.max(maxFov, Math.abs(s.fov - 2 * Math.atan(Math.tan(r.horizontalFov * Math.PI / 360) / clip.aspect) * 180 / Math.PI));
      maxTime = Math.max(maxTime, Math.abs(s.time - r.time));
    }
    expect(maxPosition).toBeLessThan(1e-5); expect(maxBasis).toBeLessThan(2e-6); expect(maxFov).toBeLessThan(2e-5); expect(maxTime).toBeLessThan(1e-6);
    evidence[name] = { samples: clip.samples.length, duration: clip.samples.at(-1)!.time, maxPositionMetres: maxPosition, maxBasisVectorError: maxBasis, maxVerticalFovDegrees: maxFov, maxTimeSeconds: maxTime };
  }
  mkdirSync('exports/qualification/max-camera', { recursive: true }); writeFileSync('exports/qualification/max-camera/native-parity.json', JSON.stringify(evidence, null, 2));
});

native('source system units convert correctly and acceleration survives evaluator, editable archive and public compilation', async () => {
  const bytes = read('free'), clip = parseCameraClip(bytes), metres = parseCameraClip(read('metres')), hash = await sha256(bytes), p = emptyProject();
  p.schemaVersion = 2; p.stops = [clip.samples[0], clip.samples.at(-1)!].map((s, i) => ({ id: `native-${i}`, name: `Native ${i}`, position: s.position, quaternion: s.quaternion, fov: s.fov, aspect: clip.aspect, hold: 0 })); reconnect(p);
  Object.assign(p.segments[0], { duration: 2, ease: 0, cameraClip: cameraReference(hash, clip) });
  for (let i = 0; i < metres.samples.length; i++) expect(new Vector3().fromArray(metres.samples[i].position).distanceTo(new Vector3().fromArray(clip.samples[i * 4].position).multiplyScalar(100))).toBeLessThan(.001);
  const blobs = new Map([[hash, bytes]]), evaluator = new Evaluator(p, await loadCameraClips(p, blobs));
  const opened = await readProjectArchive(packSync(await projectFiles(p, blobs))), output = await compile(p, blobs, new Map([['index.html', encode('owned shell')]]));
  expect(output.manifest.playerVersion).toBe('0.3.0'); expect(output.files.get(`assets/${hash}.json`)).toEqual(bytes);
  const restored = new Evaluator(opened.project, await loadCameraClips(opened.project, opened.blobs));
  const publicEvaluator = new Evaluator(output.manifest.project, await loadCameraClips(output.manifest.project, blobs));
  for (const t of [0, .135, .5, 1.177, 1.999, 2, 1, .5]) {
    const at = p.opening + p.revealDuration + t, expected = evaluator.evaluate(at);
    expect(restored.evaluate(at)).toEqual(expected); expect(publicEvaluator.evaluate(at)).toEqual(expected);
    expect(new Vector3().fromArray(expected.position).distanceTo(new Vector3().fromArray(cameraAt(clip, t).position))).toBeLessThan(1e-10);
  }
  const middle = cameraAt(clip, 1).position, straightMiddle = clip.samples[0].position.map((v, i) => (v + clip.samples.at(-1)!.position[i]) / 2);
  expect(new Vector3().fromArray(middle).distanceTo(new Vector3().fromArray(straightMiddle))).toBeGreaterThan(1);
});

native('corrupt or missing imported resources prevent editable serialization and public compilation', async () => {
  const bytes = read('free'), clip = parseCameraClip(bytes), hash = await sha256(bytes), p = emptyProject();
  p.schemaVersion = 2; p.stops = [clip.samples[0], clip.samples.at(-1)!].map((s, i) => ({ id: `native-${i}`, name: `Native ${i}`, position: s.position, quaternion: s.quaternion, fov: s.fov, aspect: clip.aspect, hold: 0 })); reconnect(p);
  Object.assign(p.segments[0], { duration: 2, ease: 0, cameraClip: cameraReference(hash, clip) });
  await expect(projectFiles(p, new Map())).rejects.toThrow('camera');
  await expect(compile(p, new Map([[hash, encode({})]]), new Map())).rejects.toThrow('camera');
});

native('oversampled interpolation has measured subframe error against native evaluation between exported samples', () => {
  const evidence: Record<string, unknown> = {};
  for (const name of ['free', 'target', 'physical', 'path']) {
    const clip = parseCameraClip(read(name)), reference = JSON.parse(new TextDecoder().decode(read(`${name}-subframe-reference`)));
    let maxPosition = 0, maxBasis = 0, maxFov = 0;
    for (const r of reference.samples) {
      const s = cameraAt(clip, r.time), q = new Quaternion().fromArray(s.quaternion);
      maxPosition = Math.max(maxPosition, new Vector3().fromArray(s.position).distanceTo(new Vector3().fromArray(canonical(r.positionMax))));
      for (const [axis, key] of [[new Vector3(1, 0, 0), 'rightMax'], [new Vector3(0, 1, 0), 'upMax'], [new Vector3(0, 0, 1), 'backMax']] as const) maxBasis = Math.max(maxBasis, axis.applyQuaternion(q).distanceTo(new Vector3().fromArray(canonical(r[key])).normalize()));
      maxFov = Math.max(maxFov, Math.abs(s.fov - 2 * Math.atan(Math.tan(r.horizontalFov * Math.PI / 360) / clip.aspect) * 180 / Math.PI));
    }
    expect(maxPosition).toBeLessThan(.01); expect(maxBasis).toBeLessThan(.001); expect(maxFov).toBeLessThan(.02);
    evidence[name] = { nativeSubframeChecks: reference.samples.length, maxPositionMetres: maxPosition, maxBasisVectorError: maxBasis, maxVerticalFovDegrees: maxFov };
  }
  writeFileSync('exports/qualification/max-camera/subframe-parity.json', JSON.stringify(evidence, null, 2));
});
