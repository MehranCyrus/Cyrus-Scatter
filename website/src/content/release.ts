import release from '../../content/release.json'

/** Relative to the deployed website, including installations in a subfolder. */
export const currentRelease = {
  ...release,
  installerBytes: release.installer.bytes,
  contentBytes: release.content.archiveBytes,
  installer: { ...release.installer, url: `${import.meta.env.BASE_URL}${release.installer.path}` },
}
export const decimalSize = (bytes: number) => bytes >= 1e9 ? `${(bytes / 1e9).toFixed(2)} GB` : `${(bytes / 1e6).toFixed(2)} MB`
