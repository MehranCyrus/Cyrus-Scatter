# Foundation corrections — Scatter 0.79.6

This is the portable engineering handoff for the 12 October 2026 foundation work. It qualifies specific failure, units and persistence boundaries; it is not a packaged release or physical artist acceptance. Analyzer remains independently versioned at 0.14. Internal class IDs and CyrusUnified1 are unchanged.

## Publication and recovery

The native display now constructs a successor generation, admits its peak coexistence cost, and prepares point/mesh item wrappers before releasing the previous generation. Ready unchanged sibling buffers can be reused. Failed identical inputs retry. A direct production-body fixture injects allocation/item failures and verifies old ownership, revision and resource accounting.

The scripted controller captures the complete root/leaf publication before mutation. It stages preview preparation and keeps the native Edit transaction open until every preview, row, owner, source, radius and statistic has been installed. Failure restores the prior publication and Edit maps. Native rollback restores all maps before best-effort status text. Post-commit diagnostics cannot turn a completed publication into a reported rollback.

Actual Max tests inject errors into recorded copies of the generated methods: after Edit publication, after each of three layer installs, during root installation, before native commit, and after the second display-only install. They verify complete previous state, cache identity, released solve guards, same-input recovery and pending Manual behavior. No fault injection is installed in the production script.

This does not promise recovery from every GPU/device-loss or SDK notification failure. Resource admission covers old and new generations simultaneously; a successor may be rejected even if it would fit after discarding the old one. That tradeoff preserves the last usable result.

## Units and schema 56

Schema 56 adds typed world-unit storage without changing the type of saved schema-55 parameters. The old fields are inert migration inputs. Source radii/Z offsets, edge distances, six movement bounds, pair-rule gaps, three Area falloff widths and absolute per-instance radii use typed distances. Radius multipliers, weights and scales remain dimensionless. Existing typed scalar distances retain their representation. Distance animation controllers are copied during migration.

Only the immediately preceding schema 55 is migrated. Earlier model-set/stroke formats remain rejected; this does not restore retired compatibility. Existing same-unit Edit binding names retain their serialized Name representation. Malformed Area/radius metadata is denied rather than guessed. Save converted scenes under a new name and preserve originals.

The host fixture checks same-unit migration, inches-to-centimeters load, centimeter-to-inch reopen, explicit world rescaling, merge into an existing scene, animated scalar/tab distances and new-schema layer copy. It compares accepted IDs and physical transforms, not just captions. Original schema-55 Area strings already rounded distances to six significant digits: the 400 mm witness recovers about 399.9992 mm. Typed successors avoid that string round trip but cannot restore discarded digits.

**Native Paint and CS Edit rescaling remains guarded.** Their receipts describe receiver geometry as well as numeric settings. A unit conversion that changes those bindings is rejected; reopening the original file with its saved units recovers the tested edited and painted result. The guard fixture checks retained contour/vertex counts and radius IDs, plus exact recovered placement fingerprints. It does not claim byte equality of every internal native payload. Arbitrary topology correspondence and tiny/huge vector-unit qualification remain separate work (B07/F09).

## Reproduction and evidence

The maintained fixtures are in [tools/foundation_validation](../../tools/foundation_validation/README.md). Runs use isolated profiles under `build/mcp-qualification/foundation-*`; artist profiles, scenes and installed modules are not used.

| Check | Observed result | Scope |
| --- | --- | --- |
| SDK-free native build | 16/16 suites | Includes production-body publication failure regression |
| Max 2026 SDK build | 25/25 suites | `build/completion-20261012/foundation-max2026-02` |
| Max 2027 SDK build | 25/25 suites | `build/completion-20261012/foundation-max2027-02` |
| MCP/tooling Python tests | 158 passed | Existing public settings map to the new internal distance fields |
| Publication fault scenario | 42 assertions in each Max year | Actual script methods/native Edit transaction; injected script copies |
| Units and persistence scenario | 79 assertions in each Max year | Final corrected script; actual load, merge, rescale, save/reopen and density conversion |
| Bound Paint/Edit migration and denial | 8 assertions in each Max year | Same-unit exact recovery and explicit rescale guard |
| Native retained scenario | Both years passed | Admission rejection retains old generation; changed two groups upload, sibling reuses |
| Generated-source check | Passed, 241 controls | `foundation-generated-04`; no claim this alone compiles MAXScript |

The final corrected generated script SHA256 is `a197da0157ccb59827fb61d371b9811834044e9ba2ff063287f4d62bb65a5eb0`. Publication/retained and the first 77-check units scenarios used the preceding script `4c6d701c91f485507ea14746e0ebcaccb24195b25e431d205e0193f14f8d1a4a`; the subsequent correction only restores Name formatting in generation binding labels. The final 79-check units and 8-check guard scenarios use the corrected script. Native binaries are unchanged between these script checks. Each owned launch pins compiled inputs, module hashes and loaded paths; interpreted script copies have separate hashes.

The initial guard fixture used the retired six-argument Brush API, then exposed the binding-label defect. Another attempt created an incomplete synthetic source row whose color normalized on reload; the final fixture prepares the saved source row as the UI does. Failed requests/results remain in the local profiles. The retained scenario records and repairs only a pre-test redraw lock in its disposable host, then requires redraw to remain enabled throughout the scenario. It is not evidence of general callback/long-session reliability.

Detailed local receipts and earlier attempts remain under `build/completion-20261012`, `build/mcp-qualification/foundation-20261012-*` and `_local/completion/20261012-finish`. Those ignored artifacts are not included in a source-only clone. The source fixtures and this bounded handoff are portable.

## Decision sources

Autodesk documents [typed scripted parameters](https://help.autodesk.com/cloudhelp/2024/ENU/MAXScript-Help/files/MAXScript-Tools-and-Interaction/Creating-MAXScript-Tools/Scripted-Plug-ins/GUID-461915FA-31A2-49CE-84AF-2544B782ACA3.html) and the [restrictions on changing saved parameter types and update handlers](https://help.autodesk.com/cloudhelp/2024/ENU/MAXScript-Help/files/MAXScript-Tools-and-Interaction/Creating-MAXScript-Tools/Scripted-Plug-ins/GUID-44D4AC45-65DD-401B-B4A1-07B71B35D544.html). Those restrictions motivate separate new typed fields. [Scene loading/merging](https://help.autodesk.com/cloudhelp/2024/ENU/MAXScript-Help/files/MAXScript-Tools-and-Interaction/File-Access/3ds-Max-Scene-Files-Access/GUID-624D3D05-B15D-4A97-9F15-DA35CDB0DDD2.html) documents file-unit choices; actual conversion and callback order were independently exercised in the two supported hosts.

The [engineering foundation](../ENGINEERING_FOUNDATION.md) owns required contracts and their qualifiers; the [backlog](../BACKLOG.md) retains unrelated physical UI, artist, device-loss, extreme-geometry and release gates. Knowledge retrieval must retain these limits when citing this report.
