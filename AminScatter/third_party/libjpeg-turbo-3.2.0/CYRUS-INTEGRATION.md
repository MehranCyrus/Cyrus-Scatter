# Pinned JPEG validation dependency

Unmodified upstream libjpeg-turbo 3.2.0 source/configure closure from the official release tarball. See CYRUS-SOURCE-PIN.json for the exact release URL, archive SHA-256 and per-file identities. Original upstream source and license notices remain unchanged.

The build uses ExternalProject_Add, supported by upstream, and statically links only jpeg-static with /MD. Shared libraries, TurboJPEG API, tools, tests, arithmetic decoding/encoding and SIMD are disabled. No machine JPEG DLL or PATH lookup is used. Cyrus accepts 8-bit Gray/RGB JPEG only, including progressive input, and treats every corrupt-data warning as failure. The C cleanup boundary prevents longjmp across C++ destructors.

This source subset intentionally omits optional SIMD, tools, sample images, regression inputs, JNA and PNG dependencies. Configure/build validation of this exact closure is recorded in the owned RL02 receipts. Package/runtime qualification remains separate.

Preserve LICENSE.md, README.ijg and all existing notices. Product documentation accompanying a statically linked binary must contain: This software is based in part on the work of the Independent JPEG Group. Root packaging owns inclusion of the notices in actual deliverables.
