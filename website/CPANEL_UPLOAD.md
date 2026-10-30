# Upload Cyrus Scatter 0.87.6.7

The full website ZIP includes the static site and the verified
`downloads/CyrusScatter-0.87.6.7-Setup.exe`. This EXE contains separate packages
for Max 2024, 2026 and 2027. Nothing has been deployed by this task.

## Upload to your host

1. Back up the existing site.
2. In cPanel File Manager, open the site's document root (usually `public_html`),
   or the subfolder where you want Cyrus Scatter to live.
3. Upload **CyrusScatter-website-0.87.6.7.zip** and extract it there.
   `index.html`, `assets/` and `downloads/` must be directly in that destination.
   Replace the website's previous files while preserving unrelated hosting files,
   email folders, custom configuration and other sites.
4. Open the site and its **Download** page. Clear your host/CDN cache if it still
   shows the previous edition. Download the EXE and confirm its filename below.

Do not upload the separate Installer.zip as a replacement for the full website.
It contains only the EXE. No Node server or dependency installation is required
on the host. Relative URLs and hash routes support a domain root or a subfolder.

## Download identity

- Filename: `CyrusScatter-0.87.6.7-Setup.exe`
- Size: 8,584,192 bytes
- SHA-256: `c61f75989442fecbdf2042336eaf3e5993310f91fb2b632bfc551a72b2f47235`
- Max 2027: focused runtime qualification. Max 2024/2026: SDK-build/package only.
- The optional plant-content ZIP and independent Surface Analyzer are not included.

## Rebuild locally

From `website/`:

```powershell
npm run docs:sync
npm run package:cpanel
```

Packaging checks source documentation, compiles the site, verifies and stages the
EXE, then checks archive integrity and payload hashes. Outputs are under
`dist/website/cpanel-2026-10-29-<entry-hash>/` in the repository root.
Local checks do not replace checking the actual public host after upload.

Verification and archive details are recorded in the repository at
`website/verification/UPLOAD_08767_20261029.md`.
