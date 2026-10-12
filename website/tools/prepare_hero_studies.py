"""Prepare the five aerial concepts, preserving native originals and framing."""
from pathlib import Path
import hashlib
import json
from PIL import Image

SITE = Path(__file__).resolve().parents[1]
SOURCE = SITE / 'artwork/hero-studies-20261011'
DESTINATION = SITE / 'public/assets/hero-studies'


def main():
    DESTINATION.mkdir(parents=True, exist_ok=True)
    briefs = json.loads((SOURCE/'prompts.json').read_text(encoding='utf-8'))['briefs']
    records = []
    for brief in briefs:
        original = SOURCE / (brief['id'] + '.png')
        with Image.open(original) as source:
            source = source.convert('RGB')
            for width in (640, 1100, source.width):
                assert width <= source.width
                image = source if width == source.width else source.resize(
                    (width, round(source.height * width/source.width)), Image.Resampling.LANCZOS)
                suffix = '' if width == source.width else f'-{width}'
                target = DESTINATION / (brief['id'] + suffix + '.webp')
                image.save(target, 'WEBP', quality=96, method=6)
                records.append({
                    'file': target.name, 'title': brief['title'],
                    'kind': 'AI-generated concept artwork; not Cyrus output',
                    'source': original.relative_to(SITE).as_posix(),
                    'originalSha256': hashlib.sha256(original.read_bytes()).hexdigest(),
                    'sha256': hashlib.sha256(target.read_bytes()).hexdigest(),
                    'dimensions': list(image.size), 'nativeDimensions': list(source.size),
                    'bytes': target.stat().st_size,
                    'encoding': {'format': 'WebP', 'quality': 96, 'method': 6, 'upscaled': False},
                    'generator': 'Built-in image_gen',
                    'prompts': 'artwork/hero-studies-20261011/prompts.json',
                    'selectedForHero': brief['id'] == '03-contour-terraces',
                })
    (DESTINATION/'manifest.json').write_text(json.dumps(records, indent=2)+'\n', encoding='utf-8')
    print(json.dumps({'variants': len(records), 'nativeDimensions': records[-1]['nativeDimensions']}, indent=2))


if __name__ == '__main__':
    main()
