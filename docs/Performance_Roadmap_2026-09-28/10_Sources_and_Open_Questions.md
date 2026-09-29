# 10 — Sources, provenance and open questions

**Checked:** 2026-09-28. External references are primary vendor/specification sources. Local implementation findings and proposed architecture are separate from vendor facts.

## Local evidence

- [Source snapshot](source_snapshot.json): raw and CRLF-to-LF-normalized SHA-256 values for the 97 existing inventory paths. No Git commands were used. The snapshot covers source, scripts, templates, tests, installers and guides; it does not certify installed binaries.
- [Codebase documentation](../CyrusScatter_Complete_Codebase_Documentation_2026-09-27/README.md): existing architecture reference, reconciled against local source in [01](01_Current_Code_Audit.md).
- [Performance engineering report](../Cyrus%20Scatter%20Performance%20Engineering%20Report.md): background research. Its exported chat citation markers and sandbox ZIP links are not usable local evidence. Referenced ancillary files such as `benchmark_plan.csv` and its research ZIP were not found in the docs inventory.
- [Licensing package](../CyrusScatter_Licensing_Implementation_Package_2026-09-27/README.md): separate future work; performance backends should not alter scene semantics or depend on licensing implementation.

The source snapshot is also the reference for checking whether an implementation task starts from the code described here. If hashes change, inspect the affected areas before applying this plan.

## Official references

| Topic | Source | Use / limit |
|---|---|---|
| Max thread safety | [Autodesk 2026 thread safety](https://help.autodesk.com/cloudhelp/2026/ENU/MAXDEV-Developer/files/best_practices/thread_safety.html) | Host access boundary in [05](05_Multithreading_Architecture.md); verify specific callbacks for every supported SDK |
| Max 2024 SDK | [Autodesk 2024 SDK changes](https://help.autodesk.com/cloudhelp/2024/ENU/Max-Developer-Help/what_s_new/whats_new_3dsmax_2024_sdk.html) | Compiler/C++ baseline and SDK changes |
| Max 2025 SDK | [Autodesk 2025 SDK requirements](https://help.autodesk.com/cloudhelp/2025/ENU/MAXDEV-Developer/files/about_the_3ds_max_sdk/sdk_requirements.html) | Release-specific compiler/Windows SDK; lists older TBB usage that reinforces dependency-coexistence checks |
| Max 2026 SDK | [Autodesk 2026 SDK requirements](https://help.autodesk.com/cloudhelp/2026/ENU/MAXDEV-Developer/files/about_the_3ds_max_sdk/sdk_requirements.html) | Current source-target build prerequisites |
| Max 2027 setup | [Autodesk developer setup article](https://blog.autodesk.io/setting-up-3ds-max-2027-sdk-development-with-visual-studio-2026/) | Provisional toolchain matrix; confirm against installed SDK samples before pinning |
| Max 2027 system requirements | [Autodesk system requirements](https://www.autodesk.com/support/technical/article/caas/sfdcarticles/sfdcarticles/System-requirements-for-Autodesk-3ds-Max-2027.html) | Current release, Windows 11 and x64/SSE4.2 baseline; Cyrus's 32 GB floor is the user's separate requirement |
| CPU scheduler | [oneTBB task_arena specification](https://oneapi-spec.uxlfoundation.org/specifications/oneapi/latest/elements/onetbb/source/task_scheduler/task_arena/task_arena_cls) | Arena limits and lifetime; pin a tested stable implementation separately |
| GPU device/runtime | [Khronos OpenCL API specification](https://registry.khronos.org/OpenCL/specs/unified/html/OpenCL_API.html) | Capability queries, allocation limits and API contracts |
| GPU language/numeric layout | [Khronos OpenCL C specification](https://registry.khronos.org/OpenCL/specs/unified/html/OpenCL_C.html) | Numeric features and vector layout |

## Source discrepancies to resolve during setup

The 2025 release-specific requirements page lists Windows SDK `10.0.22621.0`; the 2026 page's historical 2025 row lists `10.0.19041.0`. Use the installed 2025 SDK sample project and its release notes to resolve/pin the actual build environment, and record the choice.

The Autodesk 2027 setup article's linked SDK-requirements page returned Page Not Found through the web tool. Its toolchain guidance is recorded provisionally in [11](11_Platforms_and_Minimum_Requirements.md), with verification required before release. Its OS table also differs from the dedicated 2027 system-requirements page. This roadmap chooses Windows 11 as the common supported test platform, following the dedicated system-requirements page.

Do not infer installed GPU features from specification publication dates. Do not infer binary compatibility merely because two Max versions use a similarly named compiler toolset.

## Remaining questions and defaults

| Question | Working default / next action |
|---|---|
| Which performance area comes first? | User wants all areas; B04 selects the first optimization by measured cost |
| Representative artist scenes? | Build synthetic fixtures first, then add user scene copies when available |
| Access to Max 2024–2027 and SDKs? | F01 inventories/provisions actual paths; missing runtime testing stays marked pending |
| Renderers and versions to qualify? | Exercise generic PFlow with an available supported renderer plus the code's Corona proxy path when a compatible Corona install is available; record exact combinations before a support claim |
| Minimum CPU model/core count? | x64 multicore/SSE4.2 baseline, no added AVX requirement; qualify a practical lower-end Intel/AMD configuration rather than promise a particular MHz or instance count |
| GPU models and VRAM? | No compute GPU required for base operation; optional devices must pass G01–G04 |
| Largest scene that fits 32 GB? | Unknown; M01 establishes a documented envelope including Max/renderer memory |
| Default concurrency and crossover? | Unknown; T01–T04 measurements decide |
| Exact savings and schedule? | Unknown until baseline/setup gates; record measured savings and actual effort |

## What this review did not prove

No successful compilation, CTest execution, host runtime test, rendered-image comparison, 32 GB qualification, race test or OpenCL test occurred in this documentation pass. Source inspection supports the proposed targets; it does not demonstrate which is slowest on a real scene.
