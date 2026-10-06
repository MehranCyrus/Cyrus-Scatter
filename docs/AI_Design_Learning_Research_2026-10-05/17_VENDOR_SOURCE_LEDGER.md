# Official vendor documentation: second-pass ledger

Accessed **5 October 2026**. These are 25 selected documentation entries, not research-paper reproductions. `A01` revisits original entry `S38`; the other entries extend the [original ledger](12_RESEARCH_LEDGER.md). SideFX's live pages identify Houdini 22.0 and can change. Autodesk URLs identify the consulted release. Record installed build/SDK identities separately before implementation.

Reading depth refers to relevant page content, not every navigation link, class member or linked manual. No vendor application was operated. Recommendations in the two engineering supplements are our synthesis; documentation feature availability is not Cyrus feature availability.

## SideFX procedural and instance contracts

| ID and source | Version / reading depth | Relevant lesson and limit |
| --- | --- | --- |
| H01 — [Scatter](https://www.sidefx.com/docs/houdini/nodes/sop/scatter.html) | Live Houdini 22.0; overview and selected seeding/order/relaxation/attachment sections | Stable positions do not imply stable point indices. Primitive seeding and bounded relaxation have specific scopes; no universal identity guarantee. |
| H02 — [Scatter and Align](https://www.sidefx.com/docs/houdini/nodes/sop/scatteralign.html) | Live 22.0; workflow, scaling, constraints and relevant parameters | Separate population constraints, overlap removal and moving-point relaxation. Its normalized-source scale convention must not be assumed in Cyrus. |
| H03 — [Attribute From Pieces](https://www.sidefx.com/docs/houdini/nodes/sop/attribfrompieces.html) | Live 22.0; overview and assignment attributes | Asset-piece assignment is a distinct stage. Piece labels and source-size conventions require declared meanings. |
| H04 — [Copying and instancing point attributes](https://www.sidefx.com/docs/houdini/copy/instanceattrs.html) | Live 22.0; short attribute/precedence reference | Orientation, scale, pivot and matrix precedence are explicit contracts. Max conversion needs its own verified conventions. |
| H05 — [Attribute Interpolate](https://www.sidefx.com/docs/houdini/nodes/sop/attribinterpolate.html) | Live 22.0; parameter reference before navigation index | Primitive coordinates or element weights encode correspondence. They do not automatically survive remeshing. |
| H06 — [Copy to Points](https://www.sidefx.com/docs/houdini/nodes/sop/copytopoints.html) | Live 22.0; overview and relevant parameters | Piece matching and packed shared geometry separate assignment from geometry duplication. No cross-host memory/performance equivalence is established. |

## SideFX variation, scheduling and integrity

| ID and source | Version / reading depth | Relevant lesson and limit |
| --- | --- | --- |
| H07 — [Wedge TOP](https://www.sidefx.com/docs/houdini/nodes/top/wedge.html) | Live 22.0; overview, generation and target-parameter selection sections | Useful variation attributes and sweeps; selecting work can optionally alter parameters. Gallery browsing should not implicitly apply a candidate. |
| H08 — [Cooking/Executing TOP networks](https://www.sidefx.com/docs/houdini/tops/cooking.html) | Live 22.0; dirtying and execution sections | Intermediate result-file changes are not automatically a sufficient dependency signal. Validate artifacts on reuse/resume. |
| H09 — [pdg.WorkItem](https://www.sidefx.com/docs/houdini/tops/pdg/WorkItem.html) | Live 22.0; selected cache methods | Explicit cache invalidation exists. This is an analogy for an owned artifact contract, not a recommendation to add PDG. |
| H10 — [Local Scheduler](https://www.sidefx.com/docs/houdini/nodes/top/localscheduler.html) | Live 22.0; slots, memory/time limits and success/failure policies | Admission, process execution and semantic success are distinct. Do not equate a slot with an internal thread or a succeeded task with a valid render. |
| H11 — [Wait for All](https://www.sidefx.com/docs/houdini/nodes/top/waitforall.html) | Live 22.0; partition timing, failed inputs and split attributes | Partition options can omit failed or missing inputs. Cyrus must explicitly require the complete expected view set. |

## SideFX machine learning

| ID and source | Version / reading depth | Relevant lesson and limit |
| --- | --- | --- |
| H12 — [ML overview](https://www.sidefx.com/docs/houdini/ml/overview.html) | Live 22.0; overview of utilities, building blocks and training | Procedural data and external training can form a pipeline. The existence of a toolchain does not create aesthetic supervision. |
| H13 — [ML stages](https://www.sidefx.com/docs/houdini/ml/stages.html) | Live 22.0; full short conceptual page | Forward approximation, inverse prediction, preprocessing and held-out evaluation are separate concerns. Small classical models remain valid baselines. |
| H14 — [ONNX inference](https://www.sidefx.com/docs/houdini/nodes/sop/onnx.html) | Live 22.0; input/output tensor and execution-provider sections | Tensor layout and execution backend matter. ONNX is an optional deployment format, not a requirement for the first Cyrus ranker. |

## Autodesk host and runtime contracts

| ID and source | Version / reading depth | Relevant lesson and limit |
| --- | --- | --- |
| A01 — [Python threading](https://help.autodesk.com/cloudhelp/2027/ENU/MAXDEV-Python/files/MAXDEV_Python_threading_html.html) | Max 2027; short page rechecked; also S38 | Keep worker Python away from `pymxs`. This does not forbid all carefully designed native parallel computation. |
| A02 — [ReferenceTarget](https://help.autodesk.com/cloudhelp/2027/ENU/MAXDEV-CPP-API-REF/class_reference_target.html) | Max 2027; `NotifyDependents` contract and relevant propagation details | Notification interval and cache validity differ. Trace initiators because propagated references need not identify the original source. |
| A03 — [Rendering notifications](https://help.autodesk.com/cloudhelp/2027/ENU/MAXScript-Help/files/MAXScript-Tools-and-Interaction/Change-Handlers-and-Callbacks/General-Event-Callback-Mechanism/GUID-E5BE0058-2216-4E0B-88AF-680CA58AAC73.html) | Max 2027; full short event reference | Setup/teardown and per-frame phases have different mutation permissions. Actual third-party renderer behaviour still needs runtime tests. |
| A04 — [General callback mechanism](https://help.autodesk.com/cloudhelp/2027/ENU/MAXScript-Help/files/MAXScript-Tools-and-Interaction/Change-Handlers-and-Callbacks/GUID-C1F6495F-5831-4FC8-A00C-667C5F2EAE36.html) | Max 2027; registration, removal, inspection and event-name sections | Own callback registrations; function redefinition is not replacement. `notificationEvent()` is a 2027 addition, so diagnostic paths need version gating. |
| A05 — [System notification codes](https://help.autodesk.com/cloudhelp/2027/ENU/MAXDEV-CPP-API-REF/group___notification_codes.html) | Max 2027; selected render notifications; matched local `notify.h` | Native phase contracts corroborate the MAXScript distinction. Not all notification payloads or SDK events were audited. |
| A06 — [GeomObject](https://help.autodesk.com/cloudhelp/2027/ENU/MAXDEV-CPP-API-REF/class_geom_object.html) | Max 2027; render-mesh ownership and multi-mesh transform sections | A future direct adapter must obey mesh ownership/space/validity contracts. This does not prove a defect in the current PFlow path. |
| A07 — [TexmapThreadSafe](https://help.autodesk.com/cloudhelp/2027/ENU/MAXDEV-CPP-API-REF/class_max_s_d_k_1_1_texmap_thread_safe.html) | Max 2027; detailed description and deprecation contract | Texture evaluation has a specific multithreaded prepared-data contract. The deprecated opt-in interface is not a recommended new implementation. |
| A08 — [Hold](https://help.autodesk.com/cloudhelp/2027/ENU/MAXDEV-CPP-API-REF/class_hold.html) | Max 2027; Begin, Accept, Cancel and nesting remarks | Balanced host Undo differs from persistent workflow history. A crashed process is not an automatic cancelled transaction. |
| A09 — [Time and intervals](https://help.autodesk.com/cloudhelp/2026/ENU/MAXDEV-Developer/files/overview/overview_time_and_intervals.html) | **Max 2026**; full short overview; equivalent 2027 overview URL unavailable | Validity can avoid repeated evaluation. Use matching SDK/API contracts before changing a concrete 2027 implementation. |
| A10 — [Node Event System](https://help.autodesk.com/cloudhelp/2027/ENU/MAXScript-Help/files/MAXScript-Tools-and-Interaction/Change-Handlers-and-Callbacks/GUID-7C91D285-5683-4606-9F7C-B8D3A7CA508B.html) | Max 2027; lifecycle, timer, polling and event sections | UI/message-loop dependence is a concrete Batch qualification concern. Node events do not replace every other callback mechanism. |
| A11 — [3ds Max Batch usage](https://help.autodesk.com/cloudhelp/2022/ENU/3DSMax-Batch/files/GUID-48A78515-C24B-4E46-AC5F-884FBCF40D59.htm) | **Max 2022**; command execution and process-return sections; same 2027 URL unavailable | Process/initialization outcomes are separate from domain artifact validity. Current Batch/renderer support remains unqualified. |

## Recheck at implementation time

Pin the actual host SDK, executable, plugin DLL, script, renderer and companion dependencies. The online manual is a contract reference, not a loaded-build fingerprint. Some old guessed Autodesk URLs were unavailable; they were replaced with verified current MAXScript URLs where possible, and the two older conceptual references are labelled above. Do not treat an unavailable page as evidence that an API was removed.

The [SDK cross-check receipt](evidence/vendor_sdk_crosscheck.json) records local header hashes only. Full SDKs and private runtime files remain in their existing ignored locations. No third-party source code, binary or training dataset was copied into this documentation package.
