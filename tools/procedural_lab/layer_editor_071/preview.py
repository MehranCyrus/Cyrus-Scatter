"""Open the qualified 0.7.1 editor in a separate Max 2027 profile and demo scene."""
from pathlib import Path
import argparse
import datetime
import json
import time
import uuid
from private_host import ROOT, digest, launch

HERE = Path(__file__).resolve().parent
CANDIDATE = ROOT / 'build/ui-071/final01'
SCRIPT_HASH = '07d0bca2efe330b8b632c1a483cea23c65629b0f7ef5c0cbecd2c6984f1f9924'
MODULES = {
    'AminScatter.dlx': 'd9b24bf33d06eb46070b53179c4fb49914b670861a139eeb768c9966e69895cb',
    'CyrusBrush.dlx': 'a7e7830d7b21f95e2bdd408fce6ef36f48767fd8bdc7ab5525780ef9bc0ddbb7',
    'CyrusBrushStorage.dlh': 'e7798e5ba801ed0d720d9ab1480ed77d2a2d50f515f76ba96d7a08c1d386c786',
    'CyrusScatterEdit.dlm': '3402b16eb65a3de0bde44bccff152d123e237e818decfe778af8f77a75fd785a',
}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--verify-only', action='store_true')
    parser.add_argument('--smoke-test', action='store_true')
    args = parser.parse_args()
    result = json.loads((CANDIDATE / 'result.json').read_text())
    script = CANDIDATE / 'source/AminScatter/scripts/AminScatterObject.ms'
    if result['status'] != 'PASS' or digest(script) != SCRIPT_HASH:
        raise RuntimeError('Qualified source is missing or changed; qualify a new candidate first.')
    if result['metadata']['script_sha256'] != SCRIPT_HASH or result['metadata']['binaries'] != MODULES:
        raise RuntimeError('Qualification identity does not match the preview.')
    for name, expected in MODULES.items():
        if digest(CANDIDATE / 'max2027' / name) != expected:
            raise RuntimeError('Qualified module changed: ' + name)
    if args.verify_only:
        print('PASS: qualified script and all four ordinary Max 2027 modules match.')
        return

    stamp = datetime.datetime.now().strftime('%Y%m%d-%H%M%S') + '-' + uuid.uuid4().hex[:8]
    folder = ROOT / 'build/user-tests/layer-editor-071' / stamp
    extra = 'if cyrusOwnedLabStatus!=undefined or cyrusOwnedLabBrushEnd!=undefined do throw "Unexpected development authority"\n'
    extra += 'fileIn @"' + (HERE / 'demo.ms').as_posix() + '"'
    process, metadata = launch(folder, script, CANDIDATE / 'max2027', extra=extra,
                               transport=False, visible=not args.smoke_test)
    print('Separate Max 2027 preview: ' + str(folder), flush=True)
    deadline = time.monotonic() + 180
    try:
        while not (folder / 'ready.json').exists():
            error = folder / 'startup-error.txt'
            if error.exists():
                raise RuntimeError(error.read_text(encoding='utf-8-sig'))
            if process.poll() is not None or time.monotonic() > deadline:
                raise RuntimeError('Private preview did not finish startup; see ' + str(folder))
            time.sleep(.5)
        metadata.update(status='PASS', scope='Private launch, exact loaded modules, script and demo',
                        smoke_test=args.smoke_test)
        (folder / 'preview-result.json').write_text(json.dumps(metadata, indent=2) + '\n')
        print('Ready. Select a layer and click Edit layer; the demo opens the editor for you.')
        print('Your normal Max profile and other open scenes were not changed.')
    finally:
        if args.smoke_test and process.poll() is None:
            # Only the process returned by this launch; the scene is disposable.
            process.terminate()
            process.wait(timeout=30)


if __name__ == '__main__':
    main()
