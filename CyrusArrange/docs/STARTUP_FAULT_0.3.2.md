# Owned Max startup fault — offline evidence

Status: failing worker path identified; underlying cause unresolved. This is a
diagnostic report, not a startup fix or release certification. The complete
fourteen-item goal remains active. No artist process, profile or scene was changed.

## Preserved failures and ownership

Four audited isolated Max 2027 starts described here failed before fixture entry
and before a loaded-pair identity receipt. They ran no fixture assertions:

| Owned run | PID / exception thread | Dump SHA-256 |
| --- | --- | --- |
| `build/host-032-status-path03` | 50488 / 2960 | `48b34d9148b0211c442567204844cc0daf8417fe07669e8b11d4087b5837c6b1` |
| `build/host-032-receiving-packing02` | 46996 / 5452 | `103824aec9d1c6673a2d4e0dd9e65766aa4c3b92c60ad79d679c7fcdf480838a` |
| `build/host-032-release02-arrange_unified_modify_tests` | 24812 / 47420 | `6d2765b6a0332cf07fc9fc2e94642d55e0d7ede1c256b3ddd4a627ebf9f7c35a` |
| `build/host-032-release05-arrange_simple_workflow_tests` — normal dump | 30896 / 49624 | `b1f48df3279706b1b3bb70498b82872f8ab9252d8bde335a4f8c4479357e0d2b` |

The dumps were checked against their recorded owned process identities. Original
failure receipts remain failed. A later successful test does not replace them.
Separate profile-guard failures in earlier quantity fixtures have a different
observation and are not attributed to this startup crash.

## Offline reconstruction

`build/startup-unwind-audit01/receipt.json` hashes the diagnostic inputs, harness,
outputs and detailed `REPORT.md`. The audit reads dump/PE bytes with existing
Windows DbgHelp; it does not execute product DLLs or start/control Max. Both dumps
produce the same twelve-frame x64 unwind chain:

```text
null RIP
chrome_elf.dll +0x1a2cb
chrome_elf.dll +0x1a7f2
kernel32.dll +0x1836e
LegionLib_Release.dll +0x8838e
LegionLib_Release.dll +0x8806b
Corona_Release.dll +0x4d7bfb
Corona_Release.dll +0x4d4d8c
LegionLib_Release.dll +0x65c65
LegionLib_Release.dll +0x635a8
LegionLib_Release.dll +0x63019
kernel32.dll +0x2dda7
ntdll.dll +0x7ee4c
```

Both exception contexts contain RAX=0 and RIP=0, with an execute-access violation.
The first return address is the qword at the actual exception RSP. The matching
Chrome disk image has `call rax` immediately before it at +0x1a2c9. This supports
the interpretation of a null indirect call, while a corrupted return remains a
possible alternative. The rest of the chain uses PE unwind tables and advancing
stack pointers, rather than counting arbitrary stack words as frames.

No Arrange frame occurs on that failing worker chain. This narrows the observed
path through installed Corona/CEF code; it does not exclude earlier corruption,
other-thread execution or plugin interactions and does not establish causation.

## Initial normal-dump identity and missing evidence

Matched `chrome_elf.dll` 113.0.5672.128 and `Corona_Release.dll` 15.0.671720 agree
with dump RSDS GUID/age and PE timestamp/size/checksum. Legion 15.0.671720 lacks
RSDS and has zero timestamp/checksum, so its matching size and local-image identity
are weaker evidence. Full file hashes and module inventories are in the sealed
audit receipt. These initial normal dumps lack the relevant code pages and dispatch
globals; at that stage the call instruction was established from the matching disk
image, not captured memory. The release05 full capture below supplies those pages.
Private renderer/CEF function names are unavailable and are not invented.

Microsoft describes the callback/memory contract for
[StackWalk64](https://learn.microsoft.com/en-us/windows/win32/api/dbghelp/nf-dbghelp-stackwalk64)
and the [x64 unwind conventions](https://learn.microsoft.com/en-us/cpp/build/exception-handling-x64).
The harness preserves which reads came from captured memory and which used local
matching images. No unavailable read requests occurred in either reconstruction.

## Qualification boundary

The remaining useful evidence is a first-chance snapshot of the instructions,
dispatch data and all target-thread contexts before crash handlers run. A controlled
same-environment baseline without Arrange could test whether its presence is
necessary. Neither comparison has been performed. Do not infer that paced startups
fix the fault, attribute a culprit from a raw pointer/module match, or alter artist
plugins on the strength of this evidence.

Native03's subsequent paced device and packing hosts exited normally with every
identity/profile guard. They qualify their actual tests only. Release qualification
requires its own exact-pair functional, render, installer and automatic-startup
receipts; no claim of universally fault-free startup follows from a finite run.

## Release02 capture preparation — historical status

The first native-release02 unified host fails before fixture entry. Its PID 24812,
exception thread 47420, log timestamp and new dump header bind that startup failure
to the owned process. Empty post-fixture identity output does not establish a
wrong-module load; the fixture never reached those identity writes. No artist or
unrelated Scatter process was controlled. The exact failed receipt remains in
`build/host-032-release02-arrange_unified_modify_tests`.

The runner now maps child TEMP/TMP to its private folder, including early startup.
Optional `--capture-full-crash-dump` requests `AMED_MAX_BIGMINIDUMP=full` in that
child only, with an 8 GiB free-space admission check. It leaves the standard dump
configuration unchanged. Autodesk describes this extra heap dump in
[Using 3ds Max Generated Minidump Files](https://help.autodesk.com/cloudhelp/2023/ENU/Max-Developer-Help/writing_plug-ins/troubleshooting/using_3ds_max_generated_minidump.html).
That accessible documentation is version2023; the installed 2027 executable also
contains both environment-variable names. At that preparation checkpoint,
successful full capture in 2027 was unproved. The release05 evidence below resolves
that capture question for this installed Max 2027.1. It remains a post-fault handler
capture, rather than first-chance debugging, and does not identify or fix the cause.

## Release05 actual full-memory capture

The `native-032-release05` pair had 189 frozen source inputs. Its owned PID 30896 failed
before fixture entry with result `PENDING` and exit 0xffffffff; it contributes zero
qualified assertions. The missing post-fixture loaded-pair/privateINI log cannot
establish a wrong module or INI. The private binary hashes and artist-profile guards
in its failed receipt remained unchanged. Both dump MiscInfo streams identify
PID 30896, process creation 2026-10-19T05:57:13Z, exception thread 49624, and the same
saved execute-access violation 0xc0000005, address=0, RIP=0 and RAX=0 context. Their module lists agree.

No dump bytes were read while the producer was active. After the process was
terminal, two fresh size/mtime observations five seconds apart matched and
exclusive attributes-only opens succeeded. The earlier Length=0 observation while
the big file was still open was not evidence of an empty or failed capture.
[The sealed audit](../build/startup-release05-audit01/REPORT.md) and
[receipt](../build/startup-release05-audit01/receipt.json) preserve admission,
stream/range validation, instruction bytes and streaming hashes:

| Captured file | Bytes | Actual header / memory stream | SHA-256 |
| --- | --- | --- | --- |
| Normal, retained as `owned-normal-minidump.dmp` | 7,137,045 | 2026-10-19T05:57:46Z; flags 0x2000c0; MemoryList stream 5 / 42,539 ranges | `b1f48df3279706b1b3bb70498b82872f8ab9252d8bde335a4f8c4479357e0d2b` |
| Full, subsequently archived losslessly | 9,311,935,113 | 2026-10-19T05:57:47Z; flags 0x2200a6; Memory64List stream 9 / 14,613 ranges | `ee5c29dbca22afe8ad2e7e9c759e5d16b168950067026995684bdda55472473c` |

The full header has the [MiniDumpWithFullMemory flag](https://learn.microsoft.com/en-us/windows/win32/api/minidumpapiset/ne-minidumpapiset-minidump_type).
Its 9,284,538,368 captured-memory bytes and every described range fit within the
stable file. This establishes actual successful full capture on Max 29.1.0.11426;
the filename or requested environment value alone would not establish it.

The build-only reader uses read-only mmap and supports both memory streams; it
does not read the 9.31 GB file into one RAM buffer or execute product DLLs. Its full
walk reconstructs the same twelve-frame path with 607 captured-memory reads,
zero local-image fallback reads and zero unavailable reads. All twelve 64-byte
callsite windows, actual runtime-function entries and 32-byte unwind prefixes
match the qualified disk images. Null-PC bootstrapping still assumes an ABI
return after a null indirect call rather than a corrupted stack return.

Captured memory now establishes `call rax` at chrome+0x1a2c9, and the saved
context establishes RAX=0/RIP=0. Kernel32's +0x8c690 import is independently identified
as `ntdll!NtMapViewOfSection`; its pointer still targets ntdll+0x162240. The captured
NT entry has an inline `mov rax,<chrome+0x1a7a0>; jmp rax` redirection. Thus the
observed redirection is at the NT entry, rather than a kernel32 IAT pointer
directly replaced with a chrome address.

Crucially, the full snapshot's chrome+0x16c000 forwarding slot is **nonzero**:
it targets chrome+0x168000, whose first 32 bytes match the unpatched NT syscall stub.
This proves the captured interception/forwarding layout. It does not prove what
the faulting invocation read earlier, who installed or changed the redirection,
an initialization race, earlier corruption, or a vendor/Arrange cause. Other
threads or handlers could have changed state before this post-fault snapshot.
The absence of an Arrange frame does not exclude earlier interactions or
other-thread activity. Legion's relevant code/unwind bytes now match directly,
while its missing RSDS remains a module-level identity limitation. Filtered module
paths and the absent post-fixture identity log also limit private loaded-path
claims. No first-chance capture is claimed.

## Lossless archive and raw-file reclamation

After offline analysis finished and all reader handles were closed, the parent
archived the original private-temp `3dsmax_minidump_big.dmp` as
[the full-memory lossless ZIP](../build/startup-release05-audit01/full-memory-dump-lossless.zip).
The ZIP is 2,780,433,490 bytes, SHA-256
`58773da7d6cded75ad615cfc7eb88cf1c668be680a9c593aba9bbaaaf13154eb`.
Its sole dump member is `3dsmax_minidump_big.dmp`.

The parent fully read back/decompressed 9,311,935,113 bytes and verified the original
SHA-256 `ee5c29dbca22afe8ad2e7e9c759e5d16b168950067026995684bdda55472473c`.
The [archive record](../build/startup-release05-audit01/full-memory-dump-archive.json)
preserves this first stage with the raw original still retained; its SHA-256 is
`4492d8b5fcf7269214b7d6957768c470ca35fb1583e32870b5b9a6a0b4c82b31`.
It also binds the sealed audit receipt's SHA-256
`f7f2144d24cd489950dc34466da0ccaa8c928d356bf9f8ef8870358edd71bf3c`.
Only afterward, at 2026-10-19T06:20:49.9714780Z, the
[reclamation record](../build/startup-release05-audit01/full-memory-dump-reclamation.json)
records removal of that 9,311,935,113-byte raw original while retaining the verified
ZIP. Its SHA-256 is
`033a809967d1b8516941e95b20e28699cc8fa8327cd229104bba1f6c14c17b6f`.
The reclamation record pins the preceding archive-record hash. The two records
describe successive states, rather than contradicting one another.

The initial audit/report retains the original path as provenance; the raw file
is now absent and recovery uses the lossless ZIP. The normal dump and small
evidence remain preserved. A docs-update metadata check confirmed ZIP presence/
recorded size, its single member's name/sizes, raw-file absence and the
record-to-record hash link; it did not repeat the multi-gigabyte decompression
during the active host campaign. The
original content hash comes from the sealed admission/full-readback receipts.
This private diagnostic archive is separate from a public plugin/source package.

## Source research and prepared first-chance plan

[The bounded research/prototype receipt](../build/chromium-first-chance-proposal01/receipt.json)
and [plan](../build/chromium-first-chance-proposal01/PLAN.md) are build-only
preparation. The matching vendor chrome file reports version 113.0.5672.128,
SHA-256 `8c038d73183287f9a6de87051bd6ba91086b2d7923181bc32e6acbefd6003e5d`,
and RSDS 244408c1-1cc3-d862-4c4c-44205044422e/age1. Its `.crthunk` section is at
RVA 0x168000 and eight-byte `.oldntma` at 0x16c000. Disk disassembly shows a setup
candidate call at +0x1a969 before the pointer store at +0x1a970. Those initializer
bytes were not retrospectively promoted to fault-time evidence.

The public Chromium 113.0.5672.128 tag resolves to commit
39e9174f2c425e38766c161cae252b7dbbda18b0. Its
[x64 hook source](https://github.com/chromium/chromium/blob/39e9174f2c425e38766c161cae252b7dbbda18b0/chrome/chrome_elf/third_party_dlls/hook.cc#L35-L39)
initializes an original-function pointer to null, forwards through it, and assigns
the thunk address after Setup. The
[resolver source](https://github.com/chromium/chromium/blob/39e9174f2c425e38766c161cae252b7dbbda18b0/sandbox/win/src/service_resolver_64.cc#L253-L284)
copies the original stub before replacing the NT entry. This agrees structurally
with the vendor layout and supports a testable initialization-window hypothesis.
Public version equality does not prove the vendor's source revision; no matching
private PDB/build manifest or fault-time initializer-thread sequence was obtained.
The hypothesis is not a root-cause finding.

The proposed external debugger creates only its own new child with
[DEBUG_ONLY_THIS_PROCESS](https://learn.microsoft.com/en-us/windows/win32/procthread/process-creation-flags),
requests [DebugSetProcessKillOnExit(FALSE)](https://learn.microsoft.com/en-us/windows/win32/api/winbase/nf-winbase-debugsetprocesskillonexit),
and filters the first-chance execute AV at 0. Windows documents that
[first-chance notification precedes handlers](https://learn.microsoft.com/en-us/windows/win32/debug/debugger-exception-handling)
and [debug events hold all target threads until continuation](https://learn.microsoft.com/en-us/windows/win32/debug/debugging-events).
The proposal reads thread contexts/selected image memory and writes an external,
targeted non-full dump before passing the AV onward and detaching the owned child.
Child TEMP/TMP remain private and `AMED_MAX_BIGMINIDUMP=none` avoids requesting another full dump.
There is no existing-PID attach mode, kill API or target-memory/register patch.

Three fixed-target prototype binaries compiled with `/W4 /WX`. Only four help/refusal
branches ran; neither the synthetic probe nor Max was launched. Event/capture/
continuation/detach/timeout behavior remains runtime-unqualified. Cancellation is
cooperative, and the creation-to-no-kill-API interval cannot be eliminated by that
API. The parent must first review and qualify the separate owned synthetic probe,
then provision/hash private Max profiles and serialize any controlled baseline.
The proposed no-Arrange control must witness both Arrange modules absent and the
same renderer/CEF modules present, without changing shared installation/profile
state. Debugging changes timing; finite passes cannot establish fault-free startup
or exclude a race. All future launches remain separately owned actions; this
research supplies no startup fix or release qualification.


## Release09 later Batch-worker recurrence and separate retry

A fifth audited pre-entry failure occurred in
`build/host-032-release09-arrange_gallery_tests`. Its launcher receipt belongs to
Batch manager PID 29844, while the private session log and dump identify Max
worker PID 16772, exception thread 3076. Worker creation 07:11:58Z and dump
header 07:12:40Z match this run's unique private startup paths and timestamps.
Decoded Batch stdout also names the worker image and private INI/plugins/entry.
The preserved evidence binds this owned worker failure to the Batch run; it does
not contain an OS process-create event directly recording the parent-child edge.

[The bounded offline audit](../build/startup-release09-audit01/REPORT.md) and
[receipt](../build/startup-release09-audit01/receipt.json) preserve the terminal/
stable/closed-file admission and 6,269,160-byte copied dump, SHA-256
`d21731a65f08c1fabcabf2ab4d8d4174ed6592c325c2e56d5675b3620b915e04`.
The exception again has execute 0xc0000005, parameters 8/0, RIP=0/RAX=0, and the same
12-frame worker chain. The existing sealed offline helper ran once: 139 captured
reads, 468 matched-image reads, 0 unavailable. After interruption, its saved exit 0
and absence from the process list were verified; it was not repeated or rebuilt.
This sparse normal dump contains none of the twelve callsite windows or candidate
dispatch slots. Matching disk bytes agree with the prior full capture, without
establishing current captured code, fault-time pointer state or a cause.

The original receipt remains failed/PENDING, exit 0xffffffff, with zero fixture
assertions. Root separately completed
`build/host-032-release09-arrange_gallery_tests-retry01`: 57 assertions, exit 0, all
five guards true, with exactly the same native pair and test hash. That fresh
serialized retry qualifies its actual fixture result only; it neither replaces
the failed start nor demonstrates a startup fix, crash rate or release readiness.
No new Max/prototype launch, build, process control or artist action occurred in
this offline audit. Further campaign evidence remains in its own receipts.


## Bounded ordinary startup comparison without Arrange

[The sealed comparison audit](../build/ordinary-no-arrange-baseline09-audit01/REPORT.md)
and [receipt](../build/ordinary-no-arrange-baseline09-audit01/receipt.json)
record four actual, separately owned ordinary Max2027 starts. An earlier
preparation-only UTF-16 template decode failure launched no host and is preserved
separately. The first actual start exited normally but its module inventory
failed on an IntegerPtr formatting call; that attempt is invalid absence
evidence. The minimal build-only formatting correction was followed by three
normal exits, with both Arrange modules absent from each of two complete
1,105-module inventories per process. Expected Max, Corona, Legion and
chrome_elf image identities and recorded private/artist/source guards matched.
No private dump was produced. All four once-only start slots are exhausted.

The audit binds the preserved native09 source map and copied profile templates;
it does not claim maintained source still equals native09 after the separate
release10 fixture adoption. Private startup/scripts stayed empty, while Max
generated71 macro files per clean run; initial preparation emptiness is not a
claim of final macro emptiness.

No same-fault event was observed with Arrange absent. Three clean observations
cannot establish a crash rate, cause, module exoneration or fault-free startup.
Ordinary starts also differ from the failed Batch-worker path, and the module
snapshots do not record all intermediate loads/unloads. The original failures
remain failed and the startup cause remains unresolved. No debugger, artist
process control, shared installation change or additional startup run was used
for this comparison.
