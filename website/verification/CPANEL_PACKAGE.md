# cPanel upload package — 11 October 2026

The compiled static website is packaged at `dist/website/cpanel-2026-10-11-C0cBdD7x/CyrusScatter-website-0.79.5.zip` (ignored build output). The ZIP has 111 files, is 17.94 MiB, and contains `index.html` directly at its root. Its SHA-256 is `5cc851963044ae7e689ab2b6f21e0c1ad8322a989f079731383f78a028e27754`. The adjacent manifest records every included file and hash.

`npm --prefix website run package:cpanel` passed documentation synchronization/verification, TypeScript compilation, Vite production build, ZIP CRC validation and complete file readback. The existing bundle-size advisory remains nonfatal.

`website/tools/check_static_upload.py` tested this exact archive on an owned plain local HTTP server, extracted at `/` and `/preview/`. All 17 assertions passed: archive integrity/root structure, landing/guide/painting-reference/update-lesson routes, connected dropdown state, mobile guide fit and absence of browser exceptions. Every packaged file was fetched and hash-checked at both destinations (222 HTTP checks). Captured evidence is in `build/cpanel-upload-20261011/accepted/`, including `checks.json` and mobile screenshots.

This verifies a conventional static upload locally. It does not verify the user's cPanel configuration, DNS, HTTPS or public deployment; no upload was performed. See [the upload instructions](../CPANEL_UPLOAD.md). No Node.js server, database or SPA rewrite is required; fragment routes and relative asset paths support root and subfolder deployment.
