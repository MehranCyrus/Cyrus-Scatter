# 16 — Provider POC Acceptance Matrix

Implement the same `ILicenseProvider` contract twice and score observed behavior.

| Test | Pass condition |
|---|---|
| Online node activation | activates once, signed/local state survives restart |
| Duplicate machine activation | deterministic provider response |
| Self-deactivate | seat freed and local state cleared |
| Dead-machine reset | admin/support can recover |
| Offline request/response | works on disconnected Max machine |
| Offline replay | rejected or harmless |
| Hardware change | predictable tolerance/recovery |
| Trial start/reinstall | reinstall does not reset |
| Trial extension | admin extension syncs correctly |
| Perpetual maintenance | old eligible build works after maintenance expiry |
| New build after expiry | denied with clear reason |
| Hosted floating acquire | seat acquired only for authoring |
| Hosted floating crash | zombie seat recovers within documented lease behavior |
| Hosted floating outage | grace behavior acceptable |
| On-prem/air-gap | operationally supportable if in launch scope |
| Render worker | no paid authoring seat consumed |
| Provider outage | cached/grace behavior matches policy |
| Clock rollback | detected/recoverable without false bricking |
| VM clone | behavior understood |
| Proxy/firewall | clear error/timeout behavior |
| API latency | no UI/viewport stalls |
| Uninstall/reinstall | license state behavior intentional |
| Provider key rotation | recoverable |
| Audit/support logs | enough data without excessive PII |
| C++/Windows SDK | compatible with Max toolchain and deployment |

## Decision criteria

Weight:
- 30% technical fit;
- 20% studio/offline/render workflows;
- 15% reliability/operational burden;
- 15% integration quality;
- 10% vendor support;
- 10% cost at projected customers/seats.

Record evidence, not impressions.
