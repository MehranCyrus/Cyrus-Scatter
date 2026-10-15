# GitHub tools inventory and conversation handoff

Checked 15 October 2026. This covers **the nine GitHub projects recorded from your earlier links**, the installed Ghidra stack, our research helpers, and the documents/projects needed to continue in a new conversation. It is not an inventory of every GitHub dependency or application on the computer.

**We have one established native reverse-engineering stack: Ghidra 12.1.4 + Ghidra MCP 6.0.0 + Java 21.** Its files, saved analysis projects and research reports are present. The other eight projects are references or alternatives; no installations were identified in the checked locations or command paths. Installing all nine is unnecessary for continuing Forest, Chaos or tyFlow research.

The GitHub repositories contain the tools' own source/documentation. The installed Forest, Chaos and tyFlow binaries are separate analysis inputs. Having the analyzer's source code does not give us the plugins' original C++ projects; native analysis reconstructs portions of their executable logic.

Use [NEW_CONVERSATION.md](F:/Cursor/_Cyrus_Apps/CyrusScatter/docs/GitHub_Tools_Inventory_2026-10-15/NEW_CONVERSATION.md) as a copy-paste introduction. [LOCAL_INVENTORY.json](F:/Cursor/_Cyrus_Apps/CyrusScatter/docs/GitHub_Tools_Inventory_2026-10-15/LOCAL_INVENTORY.json) records exact paths, file presence, selected hashes, version markers and archive checks.

## The nine original GitHub references

| Project and documentation | Purpose | Local status | Fit for native Max plugins |
| --- | --- | --- | --- |
| [Universal Modder README](https://github.com/rehan-remade/universal-modder#readme) | Agent skills, game reconnaissance, modding workflows and supporting CLI | Reference; no install identified | Workflow guidance, not the decompiler |
| [REA README](https://github.com/morluto/rea#readme) | CLI/MCP investigations across native binaries and application artifacts | Reference; no install identified | Potential alternate interface to an installed native engine |
| [AI Game Modding Guides README](https://github.com/trevaintdead/ai-game-modding-guides/blob/main/README.md) | Written guides and templates for agent-assisted game projects | Reference; direct page access unresolved in this check | Learning material, not an executable analyzer |
| [Ghidra MCP README](https://github.com/bethington/ghidra-mcp#readme) | Agent/programmatic access to Ghidra | **Portable backend present; used successfully in earlier research** | Our established interface |
| [Hex-Rays IDA MCP README](https://github.com/HexRaysSA/ida-mcp#readme) | Agent interface to IDA | Reference; no IDA/backend install identified | Suitable alternative when its backend is available |
| [ILSpy README](https://github.com/icsharpcode/ILSpy#readme) | .NET assembly browser and decompiler | Reference; no install identified | For managed companion assemblies, not the inspected native engines |
| [Cpp2IL README](https://github.com/SamboyCoding/Cpp2IL#readme) | Unity IL2CPP reconstruction | Reference; no install identified | No matching Unity target identified |
| [AnyPS5 README](https://github.com/boykopovar/AnyPS5#readme) | PS5 executable porting and replacement platform services | Reference; no install identified | Outside this Windows Max plugin task |
| [PortPS5 README](https://github.com/ymatrix1/PortPS5#readme) | Windows-focused PS5 executable relinking/compatibility | Reference; no install identified | Outside this Windows Max plugin task |

The original record expanded two shortened links to `rehan-remade/universal-modder` and `trevaintdead/ai-game-modding-guides`; the user did not separately confirm those expansions. That provenance is retained in [the original full handoff](<C:/Users/Mehran/Documents/ChatGPT/Play/tyflow-analysis/FULL-HANDOFF-REPORT.txt>). The old `yuriolive/PortPS5` URL currently redirects to `ymatrix1/PortPS5`.

“No install identified” is a scoped observation: PATH, the research tool folder, selected top-level installation/download/project directories, npm/dotnet command locations and Windows uninstall records were checked. It is not proof of absence from every drive, virtual environment or application profile.

## What each project does and where its documentation is

### Universal Modder

Universal Modder provides agent workflows for reconnaissance, reverse engineering, assets, testing and recording findings. Its README describes skills, a shared knowledge base and the `um` CLI. The reverse-engineering skill coordinates external analyzers; it does not replace their native engines. [Official README](https://github.com/rehan-remade/universal-modder#readme).

Documentation: the [skills directory](https://github.com/rehan-remade/universal-modder/tree/main/skills), including the README-linked reverse-engineering skill, and [knowledge directory](https://github.com/rehan-remade/universal-modder/tree/main/knowledge). No local clone or active installation was identified. Its useful contribution here is a repeatable research workflow; our existing Max-specific helpers already supply one.

### REA

REA presents CLI and MCP workflows for native binaries, JavaScript/Electron, managed assemblies and other artifacts. Native analysis uses an external provider such as Ghidra, Hopper or IDA. [Official README](https://github.com/morluto/rea#readme), [CLI and Evidence guide](https://github.com/morluto/rea/blob/main/docs/cli.md).

**The old 6 October note about unavailable Windows Ghidra operations is no longer a sufficient current description.** Main now documents experimental Windows x64 support with a limited read-only Ghidra boundary and package/release distinctions. It does not establish general Windows feature parity. [Windows Ghidra guide](https://github.com/morluto/rea/blob/main/docs/windows-ghidra-p0.md).

No local REA installation was identified, and it was not used for our plugin findings. It could be evaluated separately if a broader application workflow is needed; it does not need to be added to resume the existing Ghidra projects.

### AI Game Modding Guides

The earlier handoff and indexed GitHub documentation describe guides/templates for passthrough mods, Rust rewrites, mod loaders, prompting, testing and troubleshooting. These are written references, not a native DLL decompiler. [README](https://github.com/trevaintdead/ai-game-modding-guides/blob/main/README.md), [Start Here](https://github.com/trevaintdead/ai-game-modding-guides/blob/main/guides/00-start-here.md).

No local clone was identified. Direct repository/README retrieval failed in this check, including a 404 from the page fetch, while indexed GitHub README/guide text remained available. Treat current direct access as unresolved; the local original handoff preserves the earlier description. Do not make these guides a prerequisite for the functioning native-analysis workflow.

### Ghidra MCP

Ghidra MCP exposes Ghidra's projects, functions, instructions, decompilation, symbols, references and scripts to agents/programs. **Ghidra is the analysis engine; Ghidra MCP is the access layer.** Our historical runs used the Java headless backend through local Python HTTP clients. [Official README](https://github.com/bethington/ghidra-mcp#readme), [installed 6.0.0 release](https://github.com/bethington/ghidra-mcp/releases/tag/v6.0.0).

The extracted backend JAR is present. The release ZIP and Python bridge wheel are present and passed ZIP integrity checks. Downloading the wheel is not proof it was installed or registered as an active MCP server. No related distribution was found in the Python environment used for this inventory. This chat does not currently advertise a dedicated Ghidra tool namespace; the established Python/REST route remains documented.

The local release folder has the JAR, extension metadata and module manifest, but no standalone README. Use the upstream release documentation and our local reproduction guides below. The five Java files in `tools/reference-source` describe the tool backend; they are neither a complete Ghidra MCP checkout nor vendor plugin source.

### Hex-Rays IDA MCP

This is the official Hex-Rays interface for IDA. Its current README requires IDA 9.4 or higher with `idalib` and Python 3.11+, plus the listed installation prerequisites. The MCP repository does not supply the IDA analysis engine itself. [Official README and installation instructions](https://github.com/HexRaysSA/ida-mcp#readme).

No IDA executable or corresponding installation was identified in the checks, and no IDA-based findings are claimed. It is an alternate native-analysis environment if a particular unresolved question justifies a second view. It cannot reconstruct missing original source files merely by being installed.

### ILSpy

ILSpy inspects managed .NET assemblies and decompiles them to C#. It offers desktop and command-line frontends, metadata browsing and project export. [Official README](https://github.com/icsharpcode/ILSpy#readme), [documentation wiki](https://github.com/icsharpcode/ILSpy/wiki), [ILSpyCmd source/documentation](https://github.com/icsharpcode/ILSpy/tree/master/ICSharpCode.ILSpyCmd).

No standalone ILSpy/ilspycmd installation was identified. Prior binary inventories establish that the inspected main tyFlow, Forest and Chaos modules are native PE images rather than managed assemblies. ILSpy becomes relevant if we identify a separate managed companion; a `.dll` filename alone is insufficient to choose it. No managed companion analysis was performed in this inventory.

### Cpp2IL

Cpp2IL targets Unity's IL2CPP build pipeline and uses its metadata/native artifacts to reconstruct managed representations. Its README distinguishes the CLI and core API and warns that its development branch is undergoing changes. [Official README](https://github.com/SamboyCoding/Cpp2IL#readme), [core API documentation](https://github.com/SamboyCoding/Cpp2IL/blob/development/Cpp2IL.Core/README_CORE.md).

No Cpp2IL executable or clone was identified. The inspected Max plugin engines were not identified as Unity IL2CPP targets. Cpp2IL is therefore a reference for a different binary pipeline, not a missing step in Forest/Chaos analysis.

### AnyPS5

AnyPS5 ports PS5 executables to native Linux/Windows formats using a relinker and replacement platform libraries. This is a platform-compatibility project, not a general Windows DLL decompiler. [Official README](https://github.com/boykopovar/AnyPS5#readme), [usage](https://github.com/boykopovar/AnyPS5/blob/main/docs/user/USAGE.md), [architecture](https://github.com/boykopovar/AnyPS5/blob/main/docs/dev/ARCHITECTURE.md).

No installation or source checkout was identified. It was not used in the Max plugin research. Its architecture may be interesting for platform-porting research, but it adds no demonstrated capability to the current native plugin questions.

### PortPS5

PortPS5 is a Windows-focused hard fork of AnyPS5. Its README describes native execution of already-decrypted PS5 dumps through ELF-to-PE relinking, replacement system libraries and Vulkan translation. [Current README](https://github.com/ymatrix1/PortPS5#readme), [product requirements](https://github.com/ymatrix1/PortPS5/blob/main/docs/PRD.md).

The original `https://github.com/yuriolive/PortPS5` link redirects to the current owner above. No local checkout or installation was identified. The project is not relevant to analyzing the installed native Max scatter modules, and its milestones should not be treated as our tested compatibility results.

## The installed analysis stack and exact paths

The shared lab root is:

`C:\Users\Mehran\Documents\ChatGPT\Play\tyflow-analysis`

The folder name reflects the original tyFlow investigation. Its tool installations were subsequently reused for Forest and Chaos; it is not limited to tyFlow inputs.

| Component | Verified location | Status and documentation |
| --- | --- | --- |
| Runtime path manifest | [tools.json](<C:/Users/Mehran/Documents/ChatGPT/Play/tyflow-analysis/tools.json>) | Paths and configured versions; not a complete tool catalog |
| Ghidra 12.1.4 | [installation directory](<C:/Users/Mehran/Documents/ChatGPT/Play/tyflow-analysis/tools/ghidra/ghidra_12.1.4_PUBLIC>) | Version verified from `Ghidra/application.properties`; [upstream](https://github.com/NationalSecurityAgency/ghidra) |
| Ghidra GUI launcher | [ghidraRun.bat](<C:/Users/Mehran/Documents/ChatGPT/Play/tyflow-analysis/tools/ghidra/ghidra_12.1.4_PUBLIC/ghidraRun.bat>) | Present; not launched in this inventory |
| Ghidra batch launcher | [analyzeHeadless.bat](<C:/Users/Mehran/Documents/ChatGPT/Play/tyflow-analysis/tools/ghidra/ghidra_12.1.4_PUBLIC/support/analyzeHeadless.bat>) | Present; standard Ghidra batch entry point |
| Ghidra MCP backend | [GhidraMCP-6.0.0.jar](<C:/Users/Mehran/Documents/ChatGPT/Play/tyflow-analysis/tools/ghidra-mcp/GhidraMCP/lib/GhidraMCP-6.0.0.jar>) | Present, hash recorded; earlier headless analysis succeeded |
| Java runtime | [java.exe](<C:/Users/Mehran/Documents/ChatGPT/Play/tyflow-analysis/tools/java/jdk-21.0.12.1+1/bin/java.exe>) | Local release metadata identifies Temurin `21.0.12.1+1-LTS` |
| Saved downloads | [downloads directory](<C:/Users/Mehran/Documents/ChatGPT/Play/tyflow-analysis/tools/downloads>) | `ghidra.zip`, `jdk21.zip`, `GhidraMCP-6.0.0.zip`, `ghidra_mcp_bridge-6.0.0-py3-none-any.whl` |
| Selected tool source | [reference-source directory](<C:/Users/Mehran/Documents/ChatGPT/Play/tyflow-analysis/tools/reference-source>) | Five Ghidra MCP Java reference files; not vendor source |

The Java distribution came from Eclipse Adoptium's Temurin release; [the local preparation script](<C:/Users/Mehran/Documents/ChatGPT/Play/tyflow-analysis/prepare_tools.py>) preserves the original download URLs and selected expected hashes. It is an installation/preparation script, not a read-only inventory command; do not rerun it merely to inspect the tools.

`extension.properties` has `version=12.1.2` and describes plugin 6.0.0. Preserve that metadata distinction: the installed Ghidra version is verified as 12.1.4, the backend JAR is 6.0.0, and GUI extension deployment is not established by the headless receipts. Do not rename or “correct” these files based on a caption.

### Local Ghidra manuals

These manuals are present and readable without downloading another tool:

- [GettingStarted.md](<C:/Users/Mehran/Documents/ChatGPT/Play/tyflow-analysis/tools/ghidra/ghidra_12.1.4_PUBLIC/GettingStarted.md>): installation layout, Java, GUI/headless use, extensions and troubleshooting.
- [GettingStarted.html](<C:/Users/Mehran/Documents/ChatGPT/Play/tyflow-analysis/tools/ghidra/ghidra_12.1.4_PUBLIC/GettingStarted.html>): HTML version of the starter manual.
- [CheatSheet.html](<C:/Users/Mehran/Documents/ChatGPT/Play/tyflow-analysis/tools/ghidra/ghidra_12.1.4_PUBLIC/docs/CheatSheet.html>): analysis/navigation reference.
- [GhidraAPI_javadoc.zip](<C:/Users/Mehran/Documents/ChatGPT/Play/tyflow-analysis/tools/ghidra/ghidra_12.1.4_PUBLIC/docs/GhidraAPI_javadoc.zip>): Java API documentation for scripts.
- [README_PDB.html](<C:/Users/Mehran/Documents/ChatGPT/Play/tyflow-analysis/tools/ghidra/ghidra_12.1.4_PUBLIC/docs/README_PDB.html>): PDB-related documentation; it does not supply a vendor PDB.

### Runtime availability

On 15 October, neither `127.0.0.1:18089` nor `127.0.0.1:18091` accepted a connection. **The tools are present; a research server is not currently running on those ports.** This inventory did not start one, launch Max, execute a vendor module or repeat a decompilation test.

Historical counts differ: the original tyFlow handoff records 245 endpoints, while the Forest schema record reports 215. Upstream also publishes its own current counts. These are not counts of recovered algorithms or interchangeable runtime contracts. A new run must read its actual schema.

## Our local helpers and their responsibilities

These are our research scripts, separate from the nine upstream repositories.

| Helper | Purpose and important boundary |
| --- | --- |
| [Original start_headless.py](<C:/Users/Mehran/Documents/ChatGPT/Play/tyflow-analysis/start_headless.py>) | Original tyFlow backend on port 18089, shared lab userhome/projects and 8 GiB heap. It starts a process and writes state; it is not the preferred isolation template for new research. |
| [Original mcp_request.py](<C:/Users/Mehran/Documents/ChatGPT/Play/tyflow-analysis/mcp_request.py>) | Original REST client for port 18089; optional response export. It does not start a server. |
| [Original inspect_pe.py](<C:/Users/Mehran/Documents/ChatGPT/Play/tyflow-analysis/inspect_pe.py>) | PE inventory helper. Inspect its assumptions before applying it to a different target. |
| [Isolated backend.py](F:/Cursor/_Cyrus_Apps/CyrusScatter/docs/ForestPack_Research_2026-10-08/reproduce/backend.py) | Fresh run, private userhome/project directory, hidden localhost backend, default port 18091 and saved PID. Reuses the installed runtime paths. |
| [static_pe.py](F:/Cursor/_Cyrus_Apps/CyrusScatter/docs/TyFlow_Architecture_Research_2026-10-06/reproduce/static_pe.py) | Static PE metadata helper used by the research inventories. |
| [export_selected.py](F:/Cursor/_Cyrus_Apps/CyrusScatter/docs/ForestPack_Research_2026-10-08/reproduce/export_selected.py) | Bounded function exports with assembly/reference/decompile ledgers; 30 selections per batch, 64 KiB body ceiling and 30 seconds per decompilation. |
| [prepare_projects.py](F:/Cursor/_Cyrus_Apps/CyrusScatter/docs/Vendor_Native_Deep_Research_2026-10-09/reproduce/prepare_projects.py) | Copy pinned prior Forest/Chaos projects into a fresh run; rejects changed binary hashes. |
| [probe.py](F:/Cursor/_Cyrus_Apps/CyrusScatter/docs/Vendor_Native_Deep_Research_2026-10-09/reproduce/probe.py) | Load a copied project and trace question-selected references. |
| [leaf.py](F:/Cursor/_Cyrus_Apps/CyrusScatter/docs/Vendor_Native_Deep_Research_2026-10-09/reproduce/leaf.py) | Define one missing straight-line leaf under strict instruction/byte limits in the analysis copy. |
| [field_refs.py](F:/Cursor/_Cyrus_Apps/CyrusScatter/docs/Vendor_Native_Deep_Research_2026-10-09/reproduce/field_refs.py) | Search decoded instruction operands for one selected field displacement. |
| [sdk_witness.py](F:/Cursor/_Cyrus_Apps/CyrusScatter/docs/Vendor_Native_Deep_Research_2026-10-09/reproduce/sdk_witness.py) | Compile our own SDK layout/type witnesses without linking or executing them. |
| [read_saved_paint.ms](F:/Cursor/_Cyrus_Apps/CyrusScatter/docs/Vendor_Native_Deep_Research_2026-10-09/reproduce/read_saved_paint.ms) | Requires an owned Max host; loads only the prior disposable fixture and reads packed public paint data. It changes that disposable host's scene, so never run it in an artist session. |
| [Deep research reproduction guide](F:/Cursor/_Cyrus_Apps/CyrusScatter/docs/Vendor_Native_Deep_Research_2026-10-09/reproduce/README.md) | Full controlled sequence, identity checks, exports, SDK witnesses, scene probe and cleanup. |

Do not mix the port-18089 client with a port-18091 server. Do not execute old finalize scripts against historical report receipts. Addresses and replay fixtures are tied to their recorded binaries and old schema/package assumptions.

## Existing documentation to read first

| Document | What it provides |
| --- | --- |
| [Original full handoff](<C:/Users/Mehran/Documents/ChatGPT/Play/tyflow-analysis/FULL-HANDOFF-REPORT.txt>) | All nine original projects, initial tyFlow setup, identity, methods and selected early findings. Section 2 is the original tool survey. |
| [Original decompilation findings](<C:/Users/Mehran/Documents/ChatGPT/Play/tyflow-analysis/decompilation-findings.txt>) | Initial selected tyFlow native findings; historical, not a complete codebase. |
| [tyFlow architecture research](F:/Cursor/_Cyrus_Apps/CyrusScatter/docs/TyFlow_Architecture_Research_2026-10-06/README.md) | Later architecture investigation with evidence/limitations. |
| [tyFlow continuation](F:/Cursor/_Cyrus_Apps/CyrusScatter/docs/TyFlow_Architecture_Research_2026-10-06/CONTINUATION.md) | Tool/project locations and continuation instructions. |
| [tyFlow Cyrus R&D](F:/Cursor/_Cyrus_Apps/CyrusScatter/docs/TyFlow_CyrusScatter_RnD_2026-10-06/README.md) | Bounded comparison against the Cyrus version inspected at that time. |
| [Forest architecture research](F:/Cursor/_Cyrus_Apps/CyrusScatter/docs/ForestPack_Research_2026-10-08/README.md) | Native display, collisions, ownership and cache evidence. |
| [Forest tool handoff](F:/Cursor/_Cyrus_Apps/CyrusScatter/docs/ForestPack_Research_2026-10-08/HANDOFF.md) | Existing tool suitability/reproduction notes. Some open questions were resolved by the later deep report. |
| [Forest brush research](F:/Cursor/_Cyrus_Apps/CyrusScatter/docs/ForestPack_Research_2026-10-08/brush/README.md) | Contour painting, Max Painter, publication and Undo findings. |
| [Forest Chaos measured behavior](F:/Cursor/_Cyrus_Apps/CyrusScatter/docs/Vendor_Surface_Paint_Research_2026-10-09/README.md) | Disposable runtime tests of surfaces, Density/Fixed Total, overlaps and paint removal. |
| [Deeper native findings](F:/Cursor/_Cyrus_Apps/CyrusScatter/docs/Vendor_Native_Deep_Research_2026-10-09/README.md) | Packed mesh anchors, tubular membership, receiver remapping and Forest sample reuse/eviction. |
| [Native code map](F:/Cursor/_Cyrus_Apps/CyrusScatter/docs/Vendor_Native_Deep_Research_2026-10-09/CODE_MAP.md) | Module-specific RVAs, reconstructed fields, roles and corrected exploratory labels. |

The deeper pass inspected 42 selected function bodies across three modules. That establishes useful partial native logic, not 42 fully recovered algorithms or a percentage of the products understood. We have not recovered Forest/Chaos/tyFlow's original repository, complete build system or complete implementation. Additional interfaces cannot recover information that is absent from the binary.

## Saved projects and private results

### Original tyFlow lab

The saved project is [tyFlowArchitecture.gpr](<C:/Users/Mehran/Documents/ChatGPT/Play/tyflow-analysis/projects/tyFlowArchitecture.gpr>) with its required [tyFlowArchitecture.rep directory](<C:/Users/Mehran/Documents/ChatGPT/Play/tyflow-analysis/projects/tyFlowArchitecture.rep>). Keep both together. The input copy is under `C:\Users\Mehran\Documents\ChatGPT\Play\tyflow-analysis\inputs\tyFlow_2027.dlo`.

Selected raw results are in [decompiled](<C:/Users/Mehran/Documents/ChatGPT/Play/tyflow-analysis/decompiled>), [research-20261006](<C:/Users/Mehran/Documents/ChatGPT/Play/tyflow-analysis/research-20261006>) and [research-072-rnd-20261006](<C:/Users/Mehran/Documents/ChatGPT/Play/tyflow-analysis/research-072-rnd-20261006>). These are private research artifacts, not files to integrate into Cyrus.

### Forest and Chaos runs

All these run directories were present during this inventory:

| Run directory | Contents / use |
| --- | --- |
| [forestpack-research-20261008-01](F:/Cursor/_Cyrus_Apps/CyrusScatter/build/forestpack-research-20261008-01) | Original Forest architecture project, input inventories and selected listings |
| [forest-brush-research-20261008-01](F:/Cursor/_Cyrus_Apps/CyrusScatter/build/forest-brush-research-20261008-01) | Forest brush project and bounded native/SDK results |
| [vendor-surface-paint-20261009-01](F:/Cursor/_Cyrus_Apps/CyrusScatter/build/vendor-surface-paint-20261009-01) | Measured host experiments, Forest/Chaos projects and saved disposable fixture |
| [vendor-native-deep-20261009-01](F:/Cursor/_Cyrus_Apps/CyrusScatter/build/vendor-native-deep-20261009-01) | Most recent combined native projects, exports, SDK witnesses and saved-paint decode |

The last directory contains these saved project pairs:

- [ChaosOwnership.gpr](F:/Cursor/_Cyrus_Apps/CyrusScatter/build/vendor-native-deep-20261009-01/projects/ChaosOwnership.gpr) and `.rep`: `ScatterMax_Release-2027.dll`, the Chaos Max adapter.
- [ReceivingSurfaceCore.gpr](F:/Cursor/_Cyrus_Apps/CyrusScatter/build/vendor-native-deep-20261009-01/projects/ReceivingSurfaceCore.gpr) and `.rep`: `ScatterCore.ForScatter_Release.dll`, the Chaos calculation core.
- [ForestPack943.gpr](F:/Cursor/_Cyrus_Apps/CyrusScatter/build/vendor-native-deep-20261009-01/projects/ForestPack943.gpr) and `.rep`: the analyzed `ForestPackLite.dlo`.

These are Ghidra analysis databases containing imported programs and annotations; they are not original vendor code repositories. Clone the project pair into a new run before further annotation. If the target hash differs from the receipt, rediscover addresses rather than applying old RVAs.

The C-drive lab and ignored `build/` folders are **not backed up by the Cyrus Git repository**. A new local conversation can use them on this computer. A different computer needs the relevant tool setup and permitted local project/artifact copies separately; cloning Cyrus alone is insufficient.

## How a new conversation should continue

1. Read this report and the relevant native code map/reproduction guide. Choose one concrete unanswered question.
2. Read the current repository README and workflow. The current source is **Scatter 0.82.4 / schema 58**, independently from the old 0.74 research fixture. Phase 6 remains paused. Old research is not current Cyrus acceptance.
3. Recheck tool/input paths, hashes and actual server state. Presence today and historical success do not replace a fresh runtime/schema check when analysis resumes.
4. Use the isolated backend and a new ignored run. Copy an applicable saved project, or import a fresh binary if identity changed. Keep backend writes confined to the analysis copy.
5. Follow selected references, verify function bounds/types, and separate assembly evidence, decompiler interpretation and host observations. Compile an SDK witness where host layout matters.
6. Use Max **2027 only** and an owned disposable profile/scene for runtime questions. Preserve the user's session, installed plugins, Cyrus changes and licensing. Keep mutations serialized and inspect a timed-out request before queuing another.
7. Save/close projects and stop only verified owned processes. Write a bounded successor report; do not overwrite historical evidence or copy proprietary implementation into Cyrus.

The project knowledge tools currently report stale enrolled sources, and the vendor research path search returned no hits because this research is outside the selected corpus. Use the exact local files directly. Do not rebuild or activate a knowledge generation just to make this inventory searchable. [Status receipt](F:/Cursor/_Cyrus_Apps/CyrusScatter/docs/GitHub_Tools_Inventory_2026-10-15/KNOWLEDGE_STATUS.json), [path-search receipt](F:/Cursor/_Cyrus_Apps/CyrusScatter/docs/GitHub_Tools_Inventory_2026-10-15/KNOWLEDGE_SEARCH.json).

## Verification and scope of this inventory

The collector verified 57 tool/document/project paths, installed version markers, selected small-file hashes and the two Ghidra MCP distribution archives. No requested alternate executable was found in PATH; checked npm/dotnet command files were absent. Neither research port was connectable. The collectors only read existing tools and wrote this report's receipts.

Primary GitHub READMEs/documentation were checked for the nine references, with the guide-access limitation and PortPS5 redirect recorded above. Upstream main may change independently of the installed 6.0.0 release. This task performed no installation, configuration changes, Ghidra/Max launch, vendor modification, product-code change, build, commit, push or deployment. Existing working changes remain outside its scope.
