import release from '../../content/release.json'

/** The documented product edition is independent of download publication. */
export const currentRelease = {
  ...release,
  contentBytes: release.content.archiveBytes,
}
export const decimalSize = (bytes: number) => bytes >= 1e9 ? `${(bytes / 1e9).toFixed(2)} GB` : `${(bytes / 1e6).toFixed(2)} MB`
