# 13 — Perpetual Ownership, Maintenance, and Release Eligibility

## Commercial rule

A perpetual license owns eligible builds forever. Maintenance controls access to **newer releases**, not continued use of the owned build.

## Required release metadata

Every release needs:
- product SemVer;
- immutable publication date;
- Max target;
- channel;
- Git commit/tag;
- package hash.

## Decision

```text
license is perpetual?
  yes
   |
releasePublishedAt <= maintenanceUntil ?
   | yes -> build eligible forever
   | no  -> build not entitled; renew maintenance or install eligible build
```

## Why version cleanup comes first

Current repository version identifiers disagree. Maintenance cannot safely depend on “0.59 vs 0.53 vs 0.1.0 vs class version 44.” Introduce a distinct product release version/date before licensing.

## Provider mapping

Cryptlex currently supports maintenance policies with release version/published date. Keygen documents perpetual fallback patterns where releases inside the license window remain usable.

## Renewal

Renewing maintenance changes future release eligibility; it should not create a new node activation unless the customer's machine/licensing mode changed.

## Downgrade

Keep old eligible installers available or document how customers obtain them. A perpetual model is incomplete if the customer cannot reinstall the build they own.
