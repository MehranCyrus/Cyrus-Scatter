# 24 — Migration and Rollout Strategy

## Existing users/scenes

Licensing must not require scene conversion.

Preserve:
- Scatter Class ID;
- Analyzer Class ID;
- CS Edit Class ID;
- scripted parameter names/types;
- CS Edit chunks;
- generated migration behavior.

## Beta migration

1. ship signed beta installer to selected users;
2. installer detects old userScripts install;
3. back up/remove old plugin registration;
4. install bundle;
5. open known scenes;
6. compare placement counts/transforms/render;
7. activate beta entitlement;
8. collect sanitized diagnostics.

## Existing customers before formal licensing

If there are already users, decide explicitly:
- grandfathered perpetual key;
- beta key;
- trial conversion;
- paid upgrade.

Do not encode ad hoc exceptions into client code. Represent them as provider entitlements.

## Rollback

Keep previous non-licensed/pre-commercial build and installation instructions available during beta. If licensing blocks production work unexpectedly, rollback must be fast.

## Release channels

Use:
- internal;
- beta;
- stable.

Maintenance eligibility should use published release metadata consistently across channels according to your commercial terms.
