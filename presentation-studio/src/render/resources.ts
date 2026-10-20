import type { Project } from '../core/model';
export function sourceGpuEstimate(project: Project): number {
  const shared = new Set<string>(); let bytes = 0;
  for (const instance of project.instances) {
    const asset = project.assets.find(a => a.revisionId === instance.assetRevision); if (!asset) throw new Error('Missing asset revision');
    if (!shared.has(asset.hash)) { bytes += asset.gpuBytes - (asset.instanceBytes ?? 0); shared.add(asset.hash); }
    bytes += asset.instanceBytes ?? 0;
  }
  return bytes;
}
