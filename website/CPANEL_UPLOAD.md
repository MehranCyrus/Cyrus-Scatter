# Upload Cyrus Scatter 0.87.3 to cPanel

The upload ZIP contains the compiled static website **and one downloadable release file: the main Windows EXE**. It needs no Node.js process, database or PHP application on the host. Plant content and standalone MZPs are not included.

Scoped runtime evidence remains Max 2027. New Max 2024/2026 payloads have native tests only. Preserve original scenes: schema 61 saves plant preparation and custom collider links. Static recipes do not yet transfer that contact state.

## Upload and extract

1. In **cPanel â†’ Domains**, find the domain's document root. Use that destination or a preview subfolder such as `scatter-preview`.
2. Back up the existing website, then upload `CyrusScatter-website-0.87.3.zip` through **File Manager â†’ Upload**.
3. Extract into the destination itself. `index.html`, `favicon.ico`, `assets/` and `downloads/` must sit directly inside it, without an enclosing `dist/` or `website/` folder.
4. Confirm `downloads/CyrusScatter-0.87.3-Setup.exe` exists and is **7,636,480 bytes**.
5. Delete the uploaded ZIP from the server after extraction. Retain your local copy.
6. Open the domain or preview URL with its trailing slash, then visit `#/download`.

The Download page serves the **EXE directly**, without asking visitors to extract a ZIP. It installs Scatter 0.87.3 and Surface Analyzer 0.14.2 together. Relative paths work at the domain root and inside a subfolder. The smaller `CyrusScatter-0.87.3-Installer.zip` beside the upload ZIP is an optional sharing archive containing exactly one file, the EXE; it is not the website upload.

## Verify the download

Click **Download Windows EXE**. The saved filename should be `CyrusScatter-0.87.3-Setup.exe`, with SHA-256:

```text
df9328324815afd7bfe00ef24f5905e5d072d822efdcad4f5f5a7ff445ac3ddf
```

Check `#/library`, its image viewer, `#/changelog`, the guide and control search as well. Refresh a guide URL. If old content remains, hard-refresh or clear the hosting cache. A 404 for the EXE usually means the `downloads/` folder was not extracted beside `index.html`; an HTML file saved as an EXE means a host redirect or error handler intercepted that path.

Existing `index.php`, redirects or host security rules may affect serving. Preserve unrelated server configuration and use a preview folder when needed. Hash routes need no SPA rewrite or replacement `.htaccess`. If the host blocks EXE downloads, ask it to permit the exact download path.

Remove retired Cyrus `sources/`, `assets/CREDITS.md` and `assets/fonts/README.md` from an earlier deployment if present. Extraction does not remove old files. Preserve unrelated server files and any separately managed content; this upload does not manage a plant-library download.

## Installation shown to visitors

Save work and close the selected Max versions before running the EXE. Choose Max 2024, 2026 or 2027, then Install/Update and reopen Max. Both products install together; no separate Analyzer installation is needed. Leave **Install / update plant library** unchecked for plugin-only installation or existing content. An optional matching content ZIP can be placed beside the EXE separately; it is not in this website package. Uninstall Scatter retains the independent Analyzer, content and scenes.

## Build a later upload

Run `npm --prefix website run package:cpanel` from the repository root. Source/content checks run first, then the production build stages the exact SHA-verified EXE. The packager rejects additional release/model binaries and writes both ZIPs plus a hash manifest under ignored `dist/website/cpanel-<date>-<build>/`.

Upload only the generated website ZIP contents. Do not upload repository source, `node_modules`, authoring artwork or licensing tools. Raw Markdown and internal reports remain excluded. Building and packaging locally does not publish to the server.
