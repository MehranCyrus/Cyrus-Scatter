# Upload Cyrus Scatter to cPanel

This package is a compiled static React website. Hosting needs no Node.js process, npm installation, PHP application or database. The ZIP contains the deployable site only; its manifest and these instructions stay outside the ZIP.

## Choose the destination

In **cPanel → Domains**, find your domain and its **Document Root**. For the main domain this is commonly `public_html`; addon domains and subdomains can use different folders. Use the folder shown for your domain rather than assuming all domains share `public_html`.

For a first preview alongside an existing site, create a folder such as `scatter-preview` inside that document root and deploy there. Its URL will be `https://your-domain.com/scatter-preview/`. The same package works at the domain root or in a subfolder.

## Upload and extract

If you already uploaded the preceding Cyrus package, first remove its generated `sources/` folder, `assets/CREDITS.md` and `assets/fonts/README.md` from that deployment. Extracting a new ZIP does not delete old files. These are retired Cyrus files; preserve unrelated host files. The new package contains no Markdown or source snapshots.

1. Open **cPanel → File Manager** and navigate to the chosen destination. Back up existing site files before replacing them.
2. Click **Upload**, select `CyrusScatter-website-0.79.5.zip`, and wait for completion.
3. Return to File Manager, select the ZIP and click **Extract**. Extract into the chosen destination itself.
4. Confirm the resulting structure has `index.html`, `favicon.ico`, `assets/` directly inside that destination. There should be no enclosing `dist/` or `website/` folder.
5. Delete the uploaded ZIP from the host after extraction. Keep your local ZIP for later redeployment.
6. Open `https://your-domain.com/` or the preview-folder URL, including its trailing slash. The guide opens at `#/guide`; the reference opens at `#/controls`.

The domain must point to this hosting account. Check **SSL/TLS Status** or **SSL/TLS Certificates** in cPanel for HTTPS; availability and AutoSSL controls depend on the provider. An existing `index.php` or inherited redirect can take precedence over this site: use a clean preview folder or ask the host to confirm the correct document root/index configuration before replacing an existing application.

## Check the uploaded site

Check the main hero, logo/favicon, `#/guide`, `#/controls?topic=painting`, a dropdown and guide search. Refresh a guide URL directly to confirm it reloads. Open a changelog version link and a Sources & credits image. If you see the old site, hard-refresh or clear the host/CDN cache. A blank page generally means the ZIP was extracted one directory too deep, the domain points to a different root, or an existing rewrite/redirect intercepts assets.

Routes use URL fragments (`#/…`), so this package needs no SPA rewrite rules or `.htaccess` replacement. Preserve unrelated host configuration. Upload only the generated ZIP contents, not the repository, `node_modules`, source artwork, plugin code or licensing tools. The website contains curated rendered guides and a concise changelog. Raw Markdown, internal report snapshots and repository source documents are excluded.

## Build a later update

From the repository root, run `npm --prefix website run package:cpanel`. It checks documentation, builds the frontend, and writes a ZIP plus hashes into the ignored `dist/website/cpanel-<date>-<build>/` directory. Extract the new package over the same website files, retaining unrelated server files. This local packaging command does not upload or publish anything.

Official cPanel references: [find the document root](https://support.cpanel.net/hc/en-us/articles/1500004206502-How-to-find-the-document-root-of-a-domain), [File Manager upload/extract](https://docs.cpanel.net/cpanel/files/file-manager/), and [SSL guide](https://docs.cpanel.net/knowledge-base/security/guide-to-ssl/).
