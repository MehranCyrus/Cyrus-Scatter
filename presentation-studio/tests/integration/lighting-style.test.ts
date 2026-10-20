import { expect, it } from 'vitest';
import { emptyProject, validateProject } from '../../src/core/model';
import { encode } from '../../src/core/hash';
import { photoFingerprint } from '../../src/presentation/evaluate';
import { projectFiles, readProjectArchive, packSync } from '../../src/storage/archive';
import { compile, manifestSchema } from '../../src/compiler/compile';

it('persists an explicit lighting style through editable and public artifacts and invalidates artistic approval', async () => {
  const project = emptyProject(), soft = photoFingerprint(project, project.stops[0]);
  expect(validateProject(project).lighting.style).toBeUndefined();
  project.lighting.style = 'architectural';
  expect(photoFingerprint(project, project.stops[0])).not.toBe(soft);
  const files = new Map(), opened = await readProjectArchive(packSync(await projectFiles(project, files)));
  expect(opened.project.lighting).toEqual(project.lighting);
  const output = await compile(opened.project, opened.blobs, new Map([['index.html', encode('owned player shell')]]));
  expect(manifestSchema.parse(output.manifest).project.lighting.style).toBe('architectural');
  expect(output.manifest.playerVersion).toBe('0.3.0');
  expect(() => validateProject({ ...project, lighting: { ...project.lighting, style: 'unbounded-custom-lighting' } })).toThrow();
});
