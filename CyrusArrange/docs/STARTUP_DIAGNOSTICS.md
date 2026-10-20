# Private-host startup investigation

This is the historical 0.1.3 investigation. Two private Max 2027.1 test processes failed before their test entry points. Their cause remains unresolved. Successful later runs have their own exact-build receipts; they do not turn these failed attempts into passes. See the [0.1.3 release ledger](RELEASE_VALIDATION_0.1.3.md) for that qualification and the [0.3.1 report](RELEASE_VALIDATION_0.3.1.md) for the current release and its separate diagnostics.

## Observed failures

The affected runs are `host-cache-boundaries-01` and `host-import-probe-02`. Both preserved exception contexts record an execute-at-null access violation on a background thread. No test assertion executed in either attempt. Artist sessions and profiles were preserved.

The original minidumps remain in the development workspace. They are not redistributed in the source/example archive. The import-probe dump SHA256 is `b80628d5116a29551b4ae0db77334ba7bec7ce5a3a051e273bb0390174ed228d`; the boundary dump SHA256 is `22900f32a85d4a39b051546a641374d987fcd566dd8aa96d6797c1ab5a552504`.

## Analysis method

The first audit scanned raw stack slots and explicitly did not claim an unwound caller chain. The later offline audit used Windows `dbghelp.dll` and [StackWalk64](https://learn.microsoft.com/en-us/windows/win32/api/dbghelp/nf-dbghelp-stackwalk64), supplying the saved exception context, captured dump memory and bounded callbacks for module/unwind metadata. It did not attach to a process or execute target DLLs.

Missing instruction/unwind pages came only from matching on-disk PE images. Matching checked image size and timestamp, checksum when present, and recorded CodeView GUID/age when present. Current complete image hashes are recorded. This is an explicit historical-image assumption: the dumps do not contain complete historical image hashes or prove every runtime code byte was unchanged.

Arbitrary writable globals were never reconstructed from disk initializers. Legion's declared unwind records occupy a writable section, so the final reader admitted only the exact runtime-function-declared metadata ranges there. Oversized reads remained rejected; smaller fallback reads completed the trace. The scripts bound dump size, reads, frames and unwind-chain depth.

## Recovered path and limits

Both dumps recover the same thirteen-frame module-relative path, from the null exception to `RtlUserThreadStart`. It includes `chrome_elf`, a kernel32 call through the `ntdll!NtMapViewOfSection` import, exported Legion process-enumeration functions, Corona and the normal thread-start functions. Exact private source-function names are not inferred from nearby exports.

An independent calculation from [x64 unwind records](https://learn.microsoft.com/en-us/cpp/build/exception-handling-x64?view=msvc-170) matches all eleven nonzero frame transitions per dump, including the saved return addresses and stack-pointer advances. These twenty-two checks corroborate the platform unwind; they are not a replacement general-purpose unwinder.

The matching on-disk `chrome_elf` instructions contain `call rax` ending at the top saved return address. Both exception contexts have `RAX=0` and `RIP=0`. The preceding path loads an indirect target through a writable global, but that global and historical instruction pages are absent from both dumps. The analysis therefore localizes a consistent null-call path without establishing the pointer's initialization history, an initialization race, corruption, ABI mismatch or vendor responsibility.

No Cyrus Arrange frame appears on the recovered fault-thread path. That absence does not rule out earlier behavior elsewhere in the process. No speculative plugin change or artist-profile modification was made from these dumps.

## Reproducibility and next evidence

`build/startup-diagnostic-03/receipt.json` binds the preserved input identities and the offline scripts, PE metadata checks, unwind output, independent arithmetic checks and report. Earlier failed/restricted analysis attempts remain preserved. The report SHA256 is `112dbe5b4069eea61a17efa03020a6d8d749e22e9a6b10f4a5180d37ce0039b7`; the receipt SHA256 is `9f8dcc917bd00894717cb2321ba068b831b8e748efdcf930933c35523c17e80e`.

Establishing causality would require the missing runtime code/global state and initialization-order evidence, or matching private symbols and vendor analysis. Until then, these are documented environment observations with an unresolved cause, separate from the functional placement, lifecycle and installer qualification results.
