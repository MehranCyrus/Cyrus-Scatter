# 21 — Versioning, Release Metadata, and Update Control

## Add before maintenance enforcement

Suggested `version.json`:

```json
{
  "product": "cyrus-scatter",
  "version": "1.0.0",
  "publishedAt": "2026-11-15T00:00:00Z",
  "channel": "stable",
  "maxTargets": [2026, 2027],
  "licenseSchema": 1
}
```

Generate from it:
- CMake product version;
- installer/package version;
- About/license UI;
- release artifact name;
- provider release metadata.

## Keep separate

Do not replace:
- Scatter scripted class version 44;
- Analyzer scripted class version 13;
- CS Edit chunk `0x4001`.

Those are scene/schema compatibility numbers.

## Maintenance

LicenseCore compares trusted entitlement maintenance eligibility to immutable release metadata. Never use local file modification time as release date.

## Rollback

Every release should retain:
- previous installer;
- previous provider adapter compatibility;
- migration notes;
- scene compatibility tests.

A licensing update must be rollbackable without changing saved-scene schema.
