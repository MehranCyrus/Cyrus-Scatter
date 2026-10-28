# Reproducing the standalone probes

These are original **research executables**, not a Max plugin or an implementation of the Cyrus fitter. They do not connect to Max, edit scenes, install dependencies or change production code. They create temporary process-owned GPU/D3D resources and write measurements.

## Tested local setup

Windows 11 Pro x64, RTX 3090 (sm_86), driver 617.42, MSVC toolset 14.38.33130, Windows SDK 10.0.19041.0, CUDA toolkit **12.1**. The workstation's default toolkit was 11.8; the runner selects 12.1 explicitly. Kernels target `compute_86`. Other architectures/toolkits need a deliberate source/build change and fresh results.

## Run in the repository

From the repository root:

```powershell
python docs/research/gpu-interactions-research-20261027/reports/local-codex/prototype/run_probes.py deformation
python docs/research/gpu-interactions-research-20261027/reports/local-codex/prototype/run_probes.py interop
```

The helper imports the repository's compiler-environment utility, selects the explicit compiler/toolkit and builds under `build/gpu-interaction-research-20261027-01`. It saves compiler/stdout/stderr logs there and replaces the corresponding local result/execution JSON here. Preserve an original research package before rerunning if comparing identities. Running on a different machine with different tool locations requires updating the helper; it is not an installer.

## Run from an extracted report

The source can also be built without repository utilities. In a **VS 2022 x64 Developer PowerShell** with the tested compiler environment, set CUDA 12.1 include/library paths and compile each source as ordinary C++17:

```powershell
$cyrusCuda = 'C:\Program Files\NVIDIA GPU Computing Toolkit\CUDA\v12.1'
$env:PATH = "$cyrusCuda\bin;" + $env:PATH
cl.exe /nologo /std:c++17 /O2 /fp:precise /MD /EHsc "/I$cyrusCuda\include" deformation_probe.cpp /Fe:deformation_probe.exe /link "/LIBPATH:$cyrusCuda\lib\x64" OpenCL.lib cuda.lib cudart.lib nvrtc.lib d3d11.lib dxgi.lib
cl.exe /nologo /std:c++17 /O2 /fp:precise /MD /EHsc "/I$cyrusCuda\include" interop_probe.cpp /Fe:interop_probe.exe /link "/LIBPATH:$cyrusCuda\lib\x64" OpenCL.lib cuda.lib cudart.lib nvrtc.lib d3d11.lib dxgi.lib
.\deformation_probe.exe
.\interop_probe.exe
```

These are the same important compiler/link settings as the recorded helper. The exact recorded absolute command is in each execution JSON. NVRTC compiles the CUDA kernel strings; **NVCC is not used in the successful build**. An earlier local NVCC attempt failed with an unsupported-host-OS message; see [the retained diagnostic](../evidence/nvcc-attempt-02.log).

## Interpretation and limits

`deformation_results.json` is the latest final aligned, strict-math run. It records four output sizes, CPU worker count, upload/readback bytes, timing quantiles, compile-call times and maximum error against double evaluation. Only 20 samples/case and three warmups were taken. Raw per-iteration values are not included. The CPU parallel comparison creates threads each iteration. Clocks/background desktop use were not controlled; no optimal backend claim follows.

`interop_results.json` reports both API checks separately. CUDA uses classic D3D11 register/map/unmap. OpenCL queries KHR and NV extension names and uses the variant actually exposed for the D3D device. This workstation used the NV variant. Owned D3D staging reads verify exact writes. No draw/present or Max lifecycle test is included.

The samples use straightforward process-scoped error handling. They are not production resource wrappers: exceptional exits may rely on process teardown for remaining objects. They do not demonstrate safe asynchronous unloading, recovery from a hung/reset GPU, or private host resource ownership. Porting them into a plugin requires the lifecycle contract in the report, not copying `main()` into a callback.

No vendor headers, runtime DLLs, libraries or compiled executables are distributed in this ZIP. Install/use those through their official licensed toolchains. No production source or scene changes are needed to study the included results.
