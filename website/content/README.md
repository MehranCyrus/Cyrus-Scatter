# Maintained website content

`guide-chapters.json` contains the five curated customer-facing chapters. These are rendered into HTML/search data; no raw Markdown download or internal reference route is published. `source-manifest.json` records reviewed local source fingerprints and versions. A changed source fails verification until its public wording is reviewed and its fingerprint deliberately refreshed.

`changelog.json` contains 53 concise documented version entries, ordered by development chronology. Dates are left unknown for the early September milestones. Historical 1.x names precede the later 0.7 series. Same-version updates are grouped; missing versions are not invented. Its evidence paths remain local and are stripped from generated public data.

`control-explanations.json` contains readable labels and source evidence for all 241 semantic controls. Evidence remains local; exact control identities and explanations remain public. `gallery-reading-notes.json` records the interpretation of 19 supplied concept posters and their current guide links.

Run `npm run docs:sync`, `npm run docs:check`, then `npm run build`. The only generated content output is `src/content/reference.json`. No `public/sources/` tree is generated. The cPanel packager rejects Markdown and source snapshots.

The older coverage/status files and earlier verification receipts remain historical and are not imported into the active website. The retained poster-reading edition 0.78.3 does not identify the current Scatter 0.79.5 development build. Historical runtime evidence is never relabeled.
