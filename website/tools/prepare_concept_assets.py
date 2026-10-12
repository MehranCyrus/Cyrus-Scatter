"""Encode native generated artwork and responsive downscales; never upscale."""
from pathlib import Path
import hashlib
import json
from PIL import Image

SITE = Path(__file__).resolve().parents[1]
SOURCE = SITE / 'artwork/landing-20261011'
DESTINATION = SITE / 'public/assets/concepts'
MANIFEST = DESTINATION / 'manifest.json'


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def main():
    records = json.loads(MANIFEST.read_text(encoding='utf-8'))
    records = [record for record in records if '-20261011' not in record['file']]
    for name in ('courtyard', 'coastal', 'perennial'):
        original = SOURCE / f'{name}.png'
        with Image.open(original) as source:
            source = source.convert('RGB')
            for width in (480, 960, source.width):
                assert width <= source.width
                image = source if width == source.width else source.resize(
                    (width, round(source.height * width / source.width)), Image.Resampling.LANCZOS)
                suffix = '' if width == source.width else f'-{width}'
                target = DESTINATION / f'{name}-20261011{suffix}.webp'
                image.save(target, 'WEBP', quality=96, method=6)
                records.append({
                    'file': target.name,
                    'sha256': sha(target),
                    'source': original.relative_to(SITE).as_posix(),
                    'originalSha256': sha(original),
                    'kind': 'AI-generated concept artwork; not Cyrus output',
                    'generator': 'Built-in image_gen',
                    'generatedOn': '2026-10-11',
                    'bytes': target.stat().st_size,
                    'dimensions': list(image.size),
                    'nativeDimensions': list(source.size),
                    'encoding': {'format': 'WebP', 'quality': 96, 'method': 6, 'upscaled': False},
                    'prompts': 'artwork/landing-20261011/prompts.json',
                })
    MANIFEST.write_text(json.dumps(records, indent=2) + '\n', encoding='utf-8')
    print(json.dumps([{'file': r['file'], 'dimensions': r.get('dimensions'), 'bytes': r['bytes']}
                      for r in records if '-20261011' in r['file']], indent=2))


if __name__ == '__main__':
    main()
