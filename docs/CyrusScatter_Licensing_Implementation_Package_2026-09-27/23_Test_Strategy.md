# 23 — Licensing Test Strategy

## Pure unit tests

Policy matrix:
- every capability × every license state;
- maintenance before/on/after publication date;
- trial expiry;
- grace expiry;
- offline expiry;
- suspended/revoked;
- clock suspect;
- render context;
- feature entitlement missing.

## Provider contract tests

Run the same suite against Fake, Cryptlex POC and Keygen POC.

## Max integration

- licensed create/edit;
- unlicensed load;
- unlicensed mutation denied;
- CS Edit saved-state evaluation;
- Analyzer authoring;
- Analyzer saved-data render;
- bake/export;
- manual/live update;
- old scene open/save/reopen.

## Render

- local production render;
- Corona IR;
- render cancellation;
- multi-frame;
- `3dsmaxcmd.exe`;
- Deadline 3ds Command;
- Deadline 3ds Max worker if supported;
- clean render worker without authoring activation;
- provider network unavailable on worker.

## Offline

- disconnected before launch;
- request/response;
- expired offline file;
- copied file to another machine;
- clock rollback;
- offline deactivation;
- reinstall.

## Floating

- acquire/release;
- two Max instances;
- seat exhaustion;
- crash/zombie recovery;
- Wi-Fi loss;
- server/provider outage;
- borrowed seat if offered;
- on-prem server restart.

## Packaging

- clean Windows user;
- no dev PATH;
- Max 2026;
- Max 2027;
- upgrade from current MZP install;
- uninstall/reinstall;
- signed binary verification.

## Security regression

- edit MAXScript to skip UI checks;
- call visible primitives directly;
- copy cache;
- modify cache;
- replace public config files;
- block DNS;
- provider error fuzzing.

A release cannot be called licensing-complete until these have evidence/logs.
