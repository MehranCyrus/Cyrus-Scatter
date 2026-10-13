"""Independent pixel check for the owned Scanline/PFlow boundary witness."""
import argparse
import hashlib
import json
from pathlib import Path
from PIL import Image, ImageChops, ImageStat

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('receipt', type=Path)
args = parser.parse_args()
report = json.loads(args.receipt.read_text(encoding='utf-8'))
if not report.get('passed'):
    raise ValueError('A successful renderer receipt is required')
images = {}
for item in report['images']:
    path = Path(item['path'])
    if hashlib.sha256(path.read_bytes()).hexdigest() != item['sha256']:
        raise ValueError('Captured image identity changed: ' + str(path))
    images[item['label']] = Image.open(path).convert('RGB')
checks = []


def check(ok, label, data=None):
    checks.append({'passed': bool(ok), 'label': label, 'data': data})


original = images['pflow']
check(original.size == (384, 384), 'Actual render uses the declared resolution', list(original.size))
pixels = list(original.getdata())
green = sum(g > 50 and g > 1.5 * red and g > 1.25 * b for red, g, b in pixels)
cyan = sum(g > 50 and b > 70 and min(g, b) > 1.5 * red for red, g, b in pixels)
check(green > 100, 'Nonempty rendered source/face material is green', green)
check(cyan > 100, 'Nonempty rendered source/face material is cyan', cyan)
overlay_diff = ImageChops.difference(original, images['with-overlays-and-palette'])
check(overlay_diff.getbbox() is None, 'Display field/radius/palette edits change no rendered pixel')
reference_diff = ImageChops.difference(original, images['explicit-instances'])
diff_pixels = sum(max(pixel) > 2 for pixel in reference_diff.getdata())
mean_error = max(ImageStat.Stat(reference_diff).mean)
check(diff_pixels / len(pixels) <= .01 and mean_error <= .25,
      'PFlow materials/transforms match independent instances within the declared raster tolerance',
      {'pixels_above_two_levels': diff_pixels, 'fraction': diff_pixels / len(pixels), 'max_channel_mean_error': mean_error,
       'allowed_fraction': .01, 'allowed_mean': .25})
result = {'passed': all(row['passed'] for row in checks), 'checks': checks,
          'receipt_sha256': hashlib.sha256(args.receipt.read_bytes()).hexdigest(),
          'verifier_sha256': hashlib.sha256(Path(__file__).read_bytes()).hexdigest(),
          'scope': 'Primitive geometry with Standard and Multi/Sub-Object materials in Scanline; no other renderer or proxy qualification.'}
destination = args.receipt.with_stem(args.receipt.stem + '-verified')
if destination.exists():
    raise FileExistsError(destination)
destination.write_text(json.dumps(result, indent=2) + '\n', encoding='utf-8')
print(json.dumps(result))
raise SystemExit(0 if result['passed'] else 1)
