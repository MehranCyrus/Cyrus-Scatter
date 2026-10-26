# Prepare model runtime correction — 0.87.3.1

26 October 2026. **Scoped Max 2027 qualification.** This correction supersedes the
two build-only 0.87.3.1 packages. Product version 0.87.3.1, native Interactions 6,
and saved schema 61 are retained. The user's latest request resumes host testing.

## Cause and correction

The exact reported error was reproduced with the preceding package, through its
mounted generated Prepare handler:

`No "findItem" function for ReferenceTarget:ParamBlock2`

The source-ID and definition fields are Max `ArrayParameter` wrappers. In this
context, `copy interactionSourceIDs` returns `ParamBlock2ParamBlock2`, not an Array.
The new preparation function then passed that object to `findItem`. Both staged
lists now explicitly collect their entries into ordinary arrays before searching
or appending. Existing source identities and definitions remain on their owning
layer; the preparation command no longer clones the whole parameter block.

## Install

[Corrected Max 2027 MZP](../../../dist/CyrusScatter-0.87.3.1-20261026-preparefix/CyrusScatter-0.87.3.1-Max2027.mzp).
Run **Scripting > Run Script** in your normal Max 2027 session, then restart Max.
Prepare the selected source again. Earlier same-version MZPs under the plain and
`scriptfix` folders retain their reported failures; use the `preparefix` package.

Archive SHA-256: `f558f95b25ca3cc5c7d83161da536e3f79760c19b2331b568cba8213ce36f4ae`.
Script SHA-256: `4ad83319536f25ac55895bcbef636824b7a11da7f470de4fa728c57f183f3eeb`.
Exact payload and evidence identities are in [the qualification](QUALIFICATION_PREPARATION_FIX_08731.json).

## Executed checks

The final host loaded the delivered package's extracted script/modules in an owned
standard-plugin profile, with a copy of `New Plants test.max`. Original scene and
artist-profile paths were preserved. No artist installation occurred.

| Check | Observed result |
| --- | --- |
| Fresh Max 2027 SDK build / native CTest | **59/59 passed** |
| Native overhead-clump regression | All **80 contacting blades** fit, zero hidden roots, complete mesh separation and fixed anchors, with hiding on or off |
| Final generated UI handlers | **22 assertions passed**: first Prepare, reprepare, stable source binding, optional review, 1/25/100% preview, automatic minimum/connection/limit changes, and Manual pending amount retention |
| Preview geometry | 230 / 7,082 / 27,501 triangles at 1 / 25 / 100% for the supplied grass |
| Cyrus Edit / full-mesh audits | Five positions passed; four contact cases fitted 120 / 120 / 89 / 79 guides, with zero hidden roots and zero audited intersections; leaving restored the plants |
| Preparation Undo/Redo | Minimum setting and saved definition hashes restore together; IDs remain stable |
| Multi-source / failure / persistence | **11 assertions passed**: second source preparation, automatic refresh of both, rejected-limit retention/recovery, unsupported-source retention/removal, optional review cleanup, and saved definition/ID round-trip |

The contact audits inspect complete visible triangles in double precision; they
are independent of the light preview subset. At the central hovering position,
the two nearby grass copies retain all 55,002 original triangles. These are exact input checks,
not a guarantee for arbitrary source geometry or renderer float delivery. Command
durations include host update/redraw requests and are not presented FPS.

The final physical click attempt was interrupted by Computer Use's manual-input
guard. No physical-click success is claimed. The actual generated handler was
executed in the final loaded Max window, and its source/persistence outcomes were
verified. Broader renderer/material fidelity, long sessions, physical drag feel
and maximum-scale performance retain their separate acceptance gates.

## Test scope corrections retained

An initial test position had no geometric contact: the independent rest-mesh audit
found a positive 31.6 mm minimum gap. Its expectation of bending was invalid; the
final move set uses known contacting positions and a deliberate move-away case.
An initial lifecycle driver combined multiple authored actions and a rejected Undo
scope in one interpreter command; Max rolled back that command. The final campaign
separates artist actions into distinct host commands and verifies prior prepared
data/rows survive rejection. Both initial diagnostics are retained as test history.

Template line endings were normalized after qualification. Generator check proves
the final generated script remains byte-identical to the tested/package hash.
The as-built template and normalization hashes are retained with the evidence;
native receipt hashes are preserved rather than rewritten.

Knowledge retrieval was stale and current source was inspected directly. The
knowledge index was not rebuilt. No older Max qualification, Git publication,
website deployment or unrelated product delivery is inferred from these results.
