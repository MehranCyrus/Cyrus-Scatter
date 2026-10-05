# Third-party source in the licensing prototype

`nlohmann/json.hpp` is the unmodified single header from nlohmann/json **v3.12.0**:

- Source: <https://raw.githubusercontent.com/nlohmann/json/v3.12.0/single_include/nlohmann/json.hpp>
- Publisher release and SHA-256: <https://github.com/nlohmann/json/releases/tag/v3.12.0>
- Header SHA-256: `aaf127c04cb31c406e5b04a63f1ae89369fccde6d8fa7cdda1ed4f32dfc5de63`
- Copyright/permission notice: [LICENSE.MIT](nlohmann/LICENSE.MIT), retained verbatim.

The optional CMake verifier target checks the header hash. Preserve the notice in future distributions containing this component. The Python test issuer dependencies are separately pinned in [requirements-signer.txt](../../tools/licensing_lab/requirements-signer.txt) and installed only in ignored lab storage; they are not Max plugin dependencies.
