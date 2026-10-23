"""Selected, frozen inputs for native and managed build receipts.

Source trees are explicit product inputs. CMake's file API supplies the effective
configuration and include search roots; compiler dependency output audits that
selection. Only the public team trust header is read from the trust directory.
"""
from pathlib import Path
import hashlib
import json
import re
import shutil
import subprocess
import sys

SCHEMA = "cyrus.build-inputs/2"
MANAGED_SCHEMA = "cyrus.managed-build/2"
CORE_SOURCES = ("AminScatter/setup/InstallEngine.cs", "AminScatter/setup/AnalyzerInstallEngine.cs",
                "AminScatter/setup/VerifiedBackup.cs", "AminScatter/setup/LibraryOptions.cs",
                "AminScatter/shared/LibraryLocation.cs")


def digest(path):
    value = hashlib.sha256()
    with Path(path).open("rb") as stream:
        for block in iter(lambda: stream.read(1024*1024), b""):
            value.update(block)
    return value.hexdigest()


def identity(value):
    return hashlib.sha256(json.dumps(value, sort_keys=True, separators=(",", ":")).encode()).hexdigest()


def key(path, root):
    path, root = Path(path).resolve(), Path(root).resolve()
    return path.relative_to(root).as_posix() if path.is_relative_to(root) else path.as_posix()


def snapshot(paths, root):
    result = {}
    for path in sorted({Path(p).resolve() for p in paths}, key=str):
        if not path.is_file():
            raise FileNotFoundError("Required build input is unavailable: " + str(path))
        result[key(path, root)] = digest(path)
    return result


def tree(path):
    path = Path(path)
    if not path.is_dir():
        raise FileNotFoundError("Selected build input directory is unavailable: " + str(path))
    return sorted(p for p in path.rglob("*") if p.is_file())


def enabled(value):
    return str(value).upper() not in ("", "0", "OFF", "NO", "FALSE", "NONE", "NOTFOUND")


def source_paths(root, project, options=None):
    root = Path(root).resolve()
    options = options or {}
    host = options.get("max_year", 2027)
    team = options.get("team_license", project == "AminScatter" and host is not None)
    script = "AminScatterObject.ms" if project == "AminScatter" else "CyrusSurfaceAnalyzer.ms"
    paths = [root/project/"CMakeLists.txt", root/project/"scripts"/script,
             root/"tools/build_max.py", root/"tools/build_inputs.py", root/"tools/procedural_lab/offline_build.py"]
    paths += sorted((root/"cmake").glob("*.cmake"))
    for name in ("src", "include", "tests", "third_party"):
        if (root/project/name).is_dir():
            paths += tree(root/project/name)
    if project == "AminScatter":
        paths += [root/"CyrusLicensing/third_party/nlohmann/json.hpp", root/"CyrusLicensing/third_party/nlohmann/LICENSE.MIT"]
        paths += [root/"AminScatter/ui/LibraryGallery.cs", root/"AminScatter/shared/LibraryLocation.cs",
                  root/"AminScatter/tools/build_gallery.py", root/"AminScatter/tools/build_installer.py"]
        paths += [root/p for p in CORE_SOURCES]
        ui = root/"AminScatter/tools/ui"
        if ui.is_dir():
            paths += [p for p in tree(ui) if p.suffix in (".cjs", ".json", ".ms", ".js")
                      and "node_modules" not in p.parts]
        if team or options.get("token_prototype", False):
            paths.append(root/"CyrusLicensing/CMakeLists.txt")
            paths += tree(root/"CyrusLicensing/src") + tree(root/"CyrusLicensing/include")
            if options.get("build_testing", True):
                paths += tree(root/"CyrusLicensing/tests")
        if team:
            # Never sweep an issuer/trust folder: only this public C++ input.
            paths.append(Path(options.get("team_trust_header", root/"CyrusLicensing/team/team_public_key.h")))
        if options.get("native_license_experiment", False):
            raise ValueError("This product evidence builder does not admit laboratory licensing authorities.")
    elif project == "CyrusSurfaceAnalyzer":
        paths.append(root/"AminScatter/src/input_validity.cpp")
    else:
        raise ValueError("Unknown product: " + project)
    return paths


def source_manifest(root, project, options=None):
    return {"schema": SCHEMA, "configuration": {"project": project, **(options or {})},
            "files": snapshot(source_paths(root, project, options), root)}


def frozen(paths, configuration, root):
    return {"schema": SCHEMA, "configuration": configuration, "files": snapshot(paths, root)}


def verify_frozen(manifest, root):
    if manifest.get("schema") != SCHEMA or not manifest.get("files"):
        raise ValueError("A complete version 2 input manifest is required.")
    now = snapshot([Path(root)/p for p in manifest["files"]], root)
    if now != manifest["files"]:
        changed = sorted(p for p in now if now[p] != manifest["files"].get(p))
        raise ValueError("Build inputs changed; receipt remains pending: " + ", ".join(changed[:12]))


def managed_pending(output, producer):
    Path(output).with_suffix(".build.json").write_text(json.dumps({"schema": MANAGED_SCHEMA,
        "status": "pending", "producer": producer})+"\n", encoding="utf-8")


def managed_complete(output, producer, manifest, root, fields):
    verify_frozen(manifest, root)
    receipt = {"schema": MANAGED_SCHEMA, "status": "complete", "producer": producer,
               "input_manifest": manifest, "input_manifest_sha256": identity(manifest),
               "artifact_sha256": digest(output), **fields}
    Path(output).with_suffix(".build.json").write_text(json.dumps(receipt, indent=2)+"\n", encoding="utf-8")
    return receipt


def verify_managed(output, producer, root, required=()):
    output = Path(output)
    receipt = json.loads(output.with_suffix(".build.json").read_text(encoding="utf-8"))
    if (receipt.get("schema") != MANAGED_SCHEMA or receipt.get("status") != "complete"
            or receipt.get("producer") != producer):
        raise ValueError("A frozen version 2 " + producer + " producer receipt is required; rebuild this artifact.")
    manifest = receipt.get("input_manifest", {})
    if receipt.get("input_manifest_sha256") != identity(manifest):
        raise ValueError("Producer input manifest identity differs.")
    verify_frozen(manifest, root)
    if any(key(Path(root)/p, root) not in manifest["files"] for p in required):
        raise ValueError("Producer receipt omits a required input.")
    if receipt.get("artifact_sha256") != digest(output):
        raise ValueError("Producer artifact identity differs.")
    return receipt


def producer_link(path, receipt):
    return {"receipt_sha256": digest(Path(path).with_suffix(".build.json")),
            "artifact_sha256": digest(path), "schema": receipt["schema"],
            "producer": receipt["producer"], "input_manifest_sha256": receipt["input_manifest_sha256"]}


def tool_versions(paths):
    """Read public Windows PE version resources without running build tools."""
    quoted=",".join("'"+str(Path(path)).replace("'", "''")+"'" for path in sorted(set(paths)))
    command=("$result=@{}; foreach($path in @("+quoted+")){"
             "$result[$path]=[Diagnostics.FileVersionInfo]::GetVersionInfo($path).FileVersion};"
             "ConvertTo-Json -InputObject $result -Compress")
    return json.loads(subprocess.check_output(['powershell.exe','-NoProfile','-NonInteractive','-Command',command],text=True))


def verify_package_receipt(path, root):
    path=Path(path)
    receipt=json.loads(path.with_suffix('.build.json').read_text(encoding='utf-8'))
    if receipt.get('schema')!='cyrus.package-build/2' or receipt.get('status')!='complete':
        raise ValueError('A complete version 2 package producer receipt is required.')
    manifest=receipt.get('input_manifest',{})
    if receipt.get('input_manifest_sha256')!=identity(manifest) or receipt.get('artifact_sha256')!=digest(path):
        raise ValueError('Package producer identity differs.')
    verify_frozen(manifest,root)
    return receipt


def query_cmake(folder):
    query = Path(folder)/".cmake/api/v1/query/client-cyrus-inputs"
    query.mkdir(parents=True, exist_ok=True)
    for name in ("codemodel-v2", "cache-v2", "cmakeFiles-v1", "toolchains-v1"):
        (query/name).write_bytes(b"")


def cmake_reply(folder):
    reply = Path(folder)/".cmake/api/v1/reply"
    indices = sorted(reply.glob("index-*.json"))
    if not indices:
        raise ValueError("CMake did not publish the required file API reply.")
    index = json.loads(indices[-1].read_text(encoding="utf-8"))
    objects = {entry["kind"]: json.loads((reply/entry["jsonFile"]).read_text(encoding="utf-8"))
               for entry in index["objects"]}
    if not {"codemodel", "cache", "cmakeFiles", "toolchains"} <= objects.keys():
        raise ValueError("CMake input/configuration reply is incomplete.")
    configurations = objects["codemodel"]["configurations"]
    if len(configurations) != 1:
        raise ValueError("Use the qualified single-configuration build generator.")
    targets = [json.loads((reply/entry["jsonFile"]).read_text(encoding="utf-8"))
               for entry in configurations[0].get("targets", [])]
    return index, objects, targets


def native_manifest(root, project, folder, environment, requested):
    root, folder = Path(root).resolve(), Path(folder).resolve()
    index, objects, targets = cmake_reply(folder)
    cache = {entry["name"]: entry["value"] for entry in objects["cache"]["entries"]}
    options = {**requested, "team_license": enabled(cache.get("CYRUS_TEAM_LICENSE", "OFF")),
               "token_prototype": enabled(cache.get("CYRUS_BUILD_TOKEN_PROTOTYPE", "OFF")),
               "build_testing": enabled(cache.get("BUILD_TESTING", "ON")),
               "native_license_experiment": enabled(cache.get("CYRUS_NATIVE_LICENSE_EXPERIMENT", "OFF"))}
    if options["team_license"]:
        options["team_trust_header"] = str(Path(cache["CYRUS_TEAM_TRUST_DIR"])/"team_public_key.h")
    selected = source_paths(root, project, options)
    source_root = Path(objects["codemodel"]["paths"]["source"])
    for entry in objects["cmakeFiles"]["inputs"]:
        if not entry.get("isGenerated"):
            selected.append(source_root/entry["path"])
    include_roots, library_roots = set(), set()
    configured_sources = set()
    for target in targets:
        for entry in target.get("sources", []):
            if not entry.get("isGenerated"):
                path = (source_root/entry["path"]).resolve()
                selected.append(path);configured_sources.add(path)
        for group in target.get("compileGroups", []):
            include_roots.update(Path(entry["path"]).resolve() for entry in group.get("includes", []))
        for field in ("link", "archive"):
            for fragment in target.get(field, {}).get("commandFragments", []):
                text = fragment["fragment"]
                for match in re.finditer(r'/LIBPATH:(?:"([^"]+)"|(\S+))', text, re.I):
                    library_roots.add(Path(match[1] or match[2]).resolve())
    for toolchain in objects["toolchains"]["toolchains"]:
        compiler = toolchain.get("compiler", {})
        if compiler.get("path"):
            selected.append(Path(compiler["path"]))
        implicit = compiler.get("implicit", {})
        include_roots.update(Path(p).resolve() for p in implicit.get("includeDirectories", []))
        library_roots.update(Path(p).resolve() for p in implicit.get("linkDirectories", []))
    include_roots.update(Path(p).resolve() for p in environment.get("INCLUDE", "").split(";") if p)
    library_roots.update(Path(p).resolve() for p in environment.get("LIB", "").split(";") if p)
    sdk = cache.get("MAXSDK_ROOT")
    if requested.get("max_year") is not None:
        if not sdk:
            raise ValueError("The host SDK is missing from the effective configuration.")
        include_roots.add((Path(sdk)/"include").resolve())
        library_roots.add((Path(sdk)/"lib/x64/Release").resolve())
    # External include/library search roots are selected by this configuration.
    # Product sources are covered above; never sweep the checkout or trust root.
    trust = Path(options["team_trust_header"]).parent.resolve() if options.get("team_trust_header") else None
    for directory in sorted(include_roots, key=str):
        if directory.is_relative_to(folder) or directory == trust:
            continue
        if directory.is_relative_to(root) and not (sdk and directory.is_relative_to(Path(sdk).resolve())):
            continue
        selected += tree(directory)
    for directory in sorted(library_roots, key=str):
        if directory.is_relative_to(folder):
            continue
        if not directory.is_dir():
            raise FileNotFoundError("Selected library search directory is unavailable: " + str(directory))
        selected += sorted(directory.glob("*.lib"))
    tools = {"cmake": index["cmake"]["paths"]["cmake"], "ctest": index["cmake"]["paths"]["ctest"]}
    for name in ("CMAKE_C_COMPILER", "CMAKE_CXX_COMPILER", "CMAKE_LINKER", "CMAKE_MAKE_PROGRAM", "CMAKE_RC_COMPILER", "CMAKE_MT"):
        if cache.get(name) and not cache[name].endswith("-NOTFOUND"):
            resolved = shutil.which(cache[name], path=environment.get("PATH")) or cache[name]
            tools[name] = resolved
    selected += [Path(path) for path in tools.values()]
    selected += [Path(sys.executable), folder/"CMakeCache.txt"]
    configuration = {"project": project, "requested": requested, "effective_options": options,
        "cache": cache, "cmake": index["cmake"], "toolchains": objects["toolchains"],
        "targets": targets, "include_search": sorted(map(str, include_roots)),
        "library_search": sorted(map(str, library_roots)), "tools": tools,
        "tool_versions": tool_versions(tools.values()),
        "environment": {name: environment.get(name, "") for name in ("INCLUDE", "LIB", "CL", "_CL_", "LINK", "_LINK_", "CFLAGS", "CXXFLAGS", "LDFLAGS")}}
    result = frozen(selected, configuration, root)
    result["configured_sources"] = sorted(key(path, root) for path in configured_sources)
    return result


def compiler_dependencies(folder, manifest, environment):
    folder = Path(folder).resolve()
    paths = set()
    generator = manifest["configuration"]["cache"]["CMAKE_GENERATOR"]
    if generator == "Ninja":
        command = [manifest["configuration"]["tools"]["CMAKE_MAKE_PROGRAM"], "-C", str(folder), "-t", "deps"]
        result = subprocess.run(command, env=environment, capture_output=True, text=True, check=True)
        if len(result.stdout) > 128*1024*1024:
            raise ValueError("Compiler dependency audit exceeds its allowance.")
        paths.update((folder/line.strip()).resolve() for line in result.stdout.splitlines() if line.startswith("    ") and line.strip())
    elif generator == "NMake Makefiles":
        # CMake's MSVC dependency scanner writes one complete include path per
        # line in .obj.d files on the first build. compiler_depend.internal is
        # a later consolidated view and can still be empty after a clean build.
        for dependency in folder.rglob("*.obj.d"):
            if dependency.stat().st_size > 128*1024*1024:
                raise ValueError("Compiler dependency audit exceeds its allowance.")
            paths.update((folder/line.strip()).resolve() for line in dependency.read_text(encoding="utf-8").splitlines()
                         if line.strip())
        for dependency in folder.rglob("compiler_depend.internal"):
            paths.update((folder/line.strip()).resolve() for line in dependency.read_text(encoding="utf-8").splitlines()
                         if line.startswith(" ") and line.strip())
    else:
        raise ValueError("Unsupported compiler dependency audit generator: " + generator)
    if not paths:
        raise ValueError("The compiler produced no auditable dependency records.")
    return paths


def audit_dependencies(root, folder, manifest, environment):
    folder = Path(folder).resolve()
    dependencies = compiler_dependencies(folder, manifest, environment)
    missing = [p for p in dependencies if not p.is_relative_to(folder) and key(p, root) not in manifest["files"]]
    if missing:
        raise ValueError("Consumed dependencies escaped the frozen input selection: " + ", ".join(map(str, sorted(missing)[:12])))
    generated = [p for p in dependencies if p.is_relative_to(folder)]
    return {"compiler_dependencies": snapshot(dependencies, root),
            "generated_inputs": snapshot(generated, root),
            "generated_input_scope": "Generated by the recorded CMake graph from frozen inputs; captured after production, not pre-existing frozen source."}
