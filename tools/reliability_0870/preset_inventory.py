"""Record every bundled recipe's authored terrain dependencies; no host qualification."""
from pathlib import Path
import argparse, hashlib, json

ROOT = Path(__file__).resolve().parents[2]

def inventory():
    result = []
    for path in sorted((ROOT / 'AminScatter/library').glob('*.csrecipe.json')):
        document = json.loads(path.read_text(encoding='utf-8-sig'))
        layers = []
        for layer in document['layers']:
            settings = layer['settings']
            layers.append({
                'name': layer['name'],
                'mesh_mask': {key: settings.get(key) for key in ('meshMaskEnabled', 'meshMaskChannel', 'meshMaskComponent', 'meshMaskMinimum', 'meshMaskMaximum', 'meshMaskInvert')},
                'altitude': {key: settings.get(key) for key in ('altitudeEnabled', 'altitudeMinimum', 'altitudeMaximum')},
                'image': {key: settings.get(key) for key in ('distributionMode', 'densityCoordinateMode', 'densityUVChannel', 'densityMap')},
                'layout': {key: settings.get(key) for key in settings if key.startswith('grid') or key in ('placementMode', 'patternLines', 'diversityMode')},
                'paint': layer.get('paint'),
                'areas': layer.get('areas'),
            })
        result.append({'path': path.relative_to(ROOT).as_posix(),
                       'sha256': hashlib.sha256(path.read_bytes()).hexdigest(),
                       'name': document.get('name'), 'format': document['formatVersion'],
                       'units': document.get('unitsPerMetre'), 'layers': layers})
    if len(result) != 8:
        raise RuntimeError(f'Expected all eight bundled recipes, found {len(result)}')
    return {'qualification': 'Static dependency inventory only; does not prove portability or host behavior.', 'recipes': result}

if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--output', type=Path, required=True)
    args = parser.parse_args()
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(json.dumps(inventory(), indent=2) + '\n', encoding='utf-8')
    print('Recorded all eight bundled recipes:', args.output)
