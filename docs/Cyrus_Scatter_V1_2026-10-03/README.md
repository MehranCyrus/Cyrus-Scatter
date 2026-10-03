# Cyrus Scatter 1.0 foundation

3 October 2026. The native Max layer editor and procedural Brush are integrated into the main plugin. The previous retained Mesh / Point Cloud / Proxy paths remain in use. Public product version: **1.0.0**. Analyzer remains **0.14**; MCP remains its separately installed **1.0** service.

| Read | Purpose |
| --- | --- |
| [Artist guide](ARTIST_GUIDE.md) | Installation, the new panels, visibility, counts and painting |
| [Implementation and qualification report](REPORT.md) | Changes, evidence, compatibility, performance and tested limits |
| [Completed implementation tracker](PLAN.md) | Original contract and the gates used to accept this foundation |
| [Next roadmap](ROADMAP.md) | Artist testing, zones/maps, broader host support and heavy-scene detail |
| [Developer reproduction](../../tools/v1/README.md) | SDK builds, private Max fixtures, package verification and cleanup |
| [Evidence manifest](evidence/MANIFEST.json) | Selected results and byte-level provenance |

The earlier Brush and artist-zone documents remain design/history references. This report supersedes their statements that product Brush integration is pending. Automatic camera-dependent point detail, multi-target Brush, UV mask exchange and ML are still separate stages.

Current follow-ups are the [1.0.1 Reset and Brush/Relax patch](../Brush_Relax_Reset_2026-10-03/REPORT.md) and [1.1 shared planting groups](../Planting_Groups_2026-10-03/REPORT.md). The [workflow diagnosis](../Artist_Zones_Integration_2026-10-03/PLANTING_GROUPS_REVIEW.md) records the earlier reproduced failures. The 1.0.0 evidence in this directory remains historical and frozen.

Local trial installers are under `dist/v1/`. Binaries, installers and generated scenes are intentionally excluded from Git; source, developer tools, documentation and selected evidence are backed up. The pre-implementation source/docs backup is commit `9aca3683f3ec62aaf2fff0e27a7b57301f51b95e`.
