"""Compare real private installed files and loaded-module paths with the MZP."""
from pathlib import Path
import argparse
import hashlib
import json
import zipfile
from build import ROOT, BASE


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('profile', type=Path)
    parser.add_argument('--loaded-profile', type=Path)
    args = parser.parse_args()
    profile = args.profile.resolve()
    if not profile.is_relative_to(BASE / 'hosts') or not (profile / 'installer-acceptance.json').exists():
        raise SystemExit('Expected an actual private installer result')
    product = profile / 'scripts/CyrusScatter'
    manifest = json.loads((product / 'manifest.json').read_text())
    package = ROOT / f'dist/v1/CyrusScatter-{manifest["version"]}-Max{manifest["max_year"]}.mzp'
    with zipfile.ZipFile(package) as archive:
        if archive.testzip() is not None:
            raise SystemExit('Corrupt MZP')
        if json.loads(archive.read('manifest.json')) != manifest:
            raise SystemExit('Installed manifest differs from the current package')
        for name, digest in manifest['files'].items():
            if hashlib.sha256(archive.read(name)).hexdigest() != digest:
                raise SystemExit('Bad package payload: ' + name)
        paths = {}
        for name in ('CyrusScatter.ms', 'Uninstall.ms', 'INSTALL.txt'):
            paths[name] = product / name
        for name, folder in (('CyrusScatter.mcr', 'macros'), ('CyrusScatterStartup.ms', 'startup')):
            paths[name] = profile / folder / name
        native = product / f'bin-max{manifest["max_year"]}-{manifest["native_id"]}'
        for name in ('AminScatter.dlx', 'CyrusScatterEdit.dlm', 'CyrusBrush.dlx', 'CyrusBrushStorage.dlh'):
            paths[name] = native / name
        for name, path in paths.items():
            if sha(path) != manifest['files'][name]:
                raise SystemExit('Installed bytes differ: ' + name)
    result = dict(package_sha256=sha(package), installed_file_hashes={name: sha(path) for name, path in paths.items()},
                  actual_mzp_install=True, max_year=manifest['max_year'], version=manifest['version'])
    if args.loaded_profile:
        loaded_profile = args.loaded_profile.resolve()
        if not loaded_profile.is_relative_to(BASE / 'hosts'):
            raise SystemExit('Loaded profile is outside the private hosts')
        loaded = json.loads((loaded_profile / 'loaded-identity.json').read_text())
        loaded_product = loaded_profile / 'scripts/CyrusScatter'
        if sha(loaded_product / 'CyrusScatter.ms') != manifest['files']['CyrusScatter.ms']:
            raise SystemExit('Restarted script differs from the package')
        if loaded['script_version'] != manifest['version'] or len(loaded['modules']) != 4:
            raise SystemExit('Restart did not load the four product modules')
        for name, filename in loaded['modules']:
            path = Path(filename).resolve()
            if not path.is_relative_to(loaded_product) or sha(path) != manifest['files'][name]:
                raise SystemExit('Loaded module path/hash mismatch: ' + name)
        result['clean_startup'] = loaded
    (profile / 'installation-verified.json').write_text(json.dumps(result, indent=2) + '\n')
    print(json.dumps({key: value for key, value in result.items() if key != 'clean_startup'}, indent=2))


if __name__ == '__main__':
    main()
