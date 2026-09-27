# 31 — Risk Register and Open Experiments

| Risk | Impact | Mitigation / experiment |
|---|---|---|
| Render worker misclassified as authoring or vice versa | high | native RuntimeContext experiments across 3dsmaxcmd/Deadline/interactive |
| Provider SDK conflicts with Max process/toolchain | high | minimal DLL POC on clean Max 2026/2027 |
| Licensing blocks saved scene evaluation | critical | explicit capability separation + old-scene render tests |
| Maintenance version mismatch | high | central release metadata before enforcement |
| Duplicate licensing state across modules | high | process-wide CyrusLicenseCore DLL |
| CS Edit module load relationship changes | high | do not refactor; clean-load test first |
| Offline customers locked out | high | signed offline workflow + documented renewal/recovery |
| Floating zombie seats | medium | lease tuning + explicit release + crash tests |
| MAXScript bypass | high | native gates, UI never authority |
| Public source exposure | medium/high | assume source knowledge; rotate secrets; native/signature security |
| Provider outage | high | signed cache/grace + backoff |
| Provider lock-in | medium | ILicenseProvider + normalized snapshot |
| Old MZP and new bundle both load | high | installer migration/detection |
| 2027 SDK/toolchain changes | high | dedicated build/test target |
| Over-obfuscation causes Max instability | high | postpone/selective only |
| Support burden from hardware transfers | medium | self-service + audited admin reset |

## Experiments required before final provider policy

1. identify all native Max signals available for render/network state;
2. run Deadline 3dsCmd and 3dsMax workers;
3. determine whether Analyzer must recompute on worker for all saved-scene cases;
4. measure provider SDK startup/refresh behavior inside Max;
5. test provider device fingerprint on common workstation upgrades/VMs;
6. test offline response renewal UX;
7. test lease duration under real studio network loss;
8. verify licensing DLL search/loading from ApplicationPlugins bundle.
