# 12 — Trial and Evaluation Policy

## Recommended trial

- 30 days;
- full authoring feature set;
- node-locked;
- no watermark or scene corruption;
- trial status visible in UI;
- purchase converts without reinstalling.

## Trial abuse

Use provider trial activation/fingerprint mechanisms rather than a registry date. Reinstalling should not reset the trial.

## Offline trial

Prefer requiring periodic online sync for ordinary trials. If you support air-gapped evaluations, issue a deliberately time-limited signed evaluation file through sales/support.

## Expiry

After expiry:
- saved scenes remain loadable;
- saved data remains intact;
- authoring/mutation/bake is blocked;
- render policy follows the chosen render-worker model;
- UI provides purchase/activate action.

## Extension

Support should be able to extend a trial for legitimate evaluation without issuing a new build or asking the user to delete local state.

## Metrics/privacy

Track only what is needed to operate the trial. Avoid turning licensing telemetry into broad product surveillance.
