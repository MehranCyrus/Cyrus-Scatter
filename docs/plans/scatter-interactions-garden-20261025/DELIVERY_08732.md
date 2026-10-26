# 0.87.3.2 — source controls and broad-leaf contact

26 October 2026. User-selected patch to 0.87.3.1. **Qualified for Max 2027 only**, using the exact final MZP payload in an owned profile. Saved schema remains **61**; native Interactions is **7**. Independent product/content versions retain their existing deliveries.

## Install and try

Package: `dist/CyrusScatter-0.87.3.2-20261026-final/CyrusScatter-0.87.3.2-Max2027.mzp`.

Run it through **Scripting > Run Script**, then restart Max. Click **Prepare model** again for a Neottopteris source prepared by an older build; its saved definition is preserved until replaced. See the [artist workflow](ARTIST_WORKFLOW_08732.md).

Saved trial: `Test Scene/CyrusScatter_08732_OwnedTests/Neottopteris_Interaction_08732.max` (262.23 MiB). One full fern, a sphere moved using Cyrus Edit, 100% preview, default preparation budgets, Live mode and roots kept visible. The source definition, stable source ID and complete contact audit pass after reopening. The supplied original `New Plants test.max` and artist INI retain their intake hashes. No installation into an artist profile or artist-session restart was performed.

## Result

- **+ / x source controls:** Interactions registers/removes the same canonical layer source rows as Models & Points. Both lists refresh together. Removing a row keeps its scene object; Undo/Redo restores the exact row identity. Manual pending placement edits remain pending.
- **Everyday settings:** Minimum stem, Refinement stiffness and Branch connection sit below blade percentage. Geometry, guide, memory and work budgets are folded under **Preparation limits**. Existing automatic preparation/contact refresh behavior is retained.
- **Color swatches:** the generator formerly assigned a responsive field width to a small inline swatch. Inline swatches now reserve and fit a 22-pixel slot inside their column.
- **Neottopteris:** this is an inference failure on a complex decorative asset. The Decorative05 source has 38,818 vertices, 50,382 triangles and 2,079 components, including 1,930 tiny 13-vertex pieces. The earlier 513-guide result concentrated on the base and treated most broad leaves as rigid attachments. The correction prepares all **36 broad leaves** from their shared elevated crown, including drooping leaves, within a **547-guide** definition. Its **47 compact non-ribbon decorative parts** remain fixed. All original faces remain at 100% preview.
- **Actual surface contact:** the first corrected preparation exposed one triangle crossing a collider with zero interior vertices. A face bridging guide spans can escape the union of vertex capsules. Locally relevant guides now check actual surfaces when capsules are clear, and every fitted candidate proves its posed faces. Failed candidates receive bounded mesh refinement before publication. Shape bounds and contact-band distance queries avoid expensive complete-distance searches for already clear faces.

Preparation uses copied SI geometry and an indexed, work-bounded endpoint vote. An isolated airborne leaf is still rejected. Source definitions remain shared between placements; preparation is not repeated for every scattered instance. Fixed decoration never rotates with an arbitrary nearby leaf. A collider touching it reports a conflict. See the [ownership, invalidation, memory and failure plan](PLAN_08732.md).

## Observed qualification

| Check | Final result |
| --- | --- |
| Matched SDK/native build | Max 2027; **59/59** native tests |
| Generated script/inventory | 361 controls; generation/layout checks pass |
| Generated preparation/settings controls | **22** checks pass |
| Preparation lifecycle | **11** checks, plus preparation Undo/Redo, pass |
| New + / remove controls | **10** checks, including same-view binding and row Undo/Redo, pass |
| Native swatch geometry | **8** checks: actual Modify pages plus disposable 170/210/290-width pages; UI scale 1 |
| Grass Cyrus Edit movements | **5** positions, complete visible-mesh checks pass; no roots hidden |
| Fern Cyrus Edit movements | **5** positions, complete visible-mesh checks pass; no roots hidden |
| Fern save/reopen | Definition and source ID preserved; full contact check passes |
| Physical Windows input | Frame source, Prepare model and Show source guides clicked successfully; source/readback checks pass |
| Package | ZIP CRC, every manifest hash, version/host guard and loaded native/script identities verified |

The final fern Prepare button took **0.74 s** in this campaign. Its four contacting moves fitted 6/5/5/4 guides in **5.56–7.23 ms**; moving away restored the rest result. The full audit examines all **50,382 triangles**. Four grass contacts fitted 121/121/89/80 guides in **91.61–141.88 ms**. Command timings include scheduling and redraw and are higher; these figures are **not presented FPS or held-pointer frame-rate measurements**.

An intermediate surface-proof implementation took about 1.06–1.51 s on the grass movements. Contact-band distance and bounds rejection reduce those final measurements to the range above while preserving the same geometry checks. A captured numeric replay separately reproduces the previous **one** surface crossing and the final **zero**, with zero root-anchor error. Native snapshots of both supplied Neottopteris variants also pass preparation, UV/material corner correspondence and saved-definition reuse.

## Exact identity and limits

Final MZP SHA-256: `3b137675d5d20d3d30fdc22e597877aca603a1062cd636348ac49d9f5839c983`.

Script SHA-256: `5abe52eb767971dcff185edf9029a10124196a488d0b70fb6326c7377614d122`.

Producer: `build/interactions08732-neottopteris-20261026-01/native-04/receipt.json`. Final profile: `final-host-03`, PID 58404. [Qualification and source hashes](QUALIFICATION_08732.json); [retained evidence](evidence-08732/). Earlier internal same-version candidates under the non-final/surfacefix folders are superseded; their original receipts are preserved.

Geometry proof/refinement retains its explicit per-guide 50k-vertex/100k-triangle admission and shared per-plant 2M work budget. It uses at most 1.2 MB of temporary Vec3 payload for one guide; workers operate on copied data. Source/pose counters are not process-wide memory peaks. Exhaustion, impossible fixed-root contact or fixed-decoration conflict retains the prior complete publication.

The owned profiles load standard plug-ins only; renderer-specific materials can display black there. No material editing was performed. Production renderer/float-delivery qualification, other DPI scales, held-pointer FPS, wider plant families and general botanical correctness remain separate acceptance. Tree/exposed-root collider work retains its earlier scope. No Max 2024/2026 delivery, EXE, commit, push or website publication is included in this patch task.
