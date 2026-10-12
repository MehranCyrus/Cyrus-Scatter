"""Prepare lossless logo/icon downscales from the user's chosen PNG."""
from pathlib import Path
import hashlib
import json
from PIL import Image, ImageOps

SITE = Path(__file__).resolve().parents[1]
SOURCE = SITE/'artwork/brand/cyrus-scatter-original.png'
DESTINATION = SITE/'public/assets/brand'


def main():
    DESTINATION.mkdir(parents=True, exist_ok=True)
    records = []
    digest = hashlib.sha256(SOURCE.read_bytes()).hexdigest()
    with Image.open(SOURCE) as original:
        original = original.convert('RGBA')
        # Preserve aspect ratio and alpha; at most one pixel of transparent padding.
        def square(size):
            image = ImageOps.contain(original, (size,size), Image.Resampling.LANCZOS)
            canvas = Image.new('RGBA',(size,size),(0,0,0,0))
            canvas.paste(image,((size-image.width)//2,(size-image.height)//2))
            return canvas
        for name,size in [('logo-96.png',96),('logo-192.png',192),('favicon-16.png',16),
                          ('favicon-32.png',32),('apple-touch-icon.png',180),('icon-512.png',512)]:
            path = DESTINATION/name
            square(size).save(path, optimize=True)
            records.append({'file':name,'dimensions':[size,size],'bytes':path.stat().st_size,
                            'sha256':hashlib.sha256(path.read_bytes()).hexdigest()})
        ico = SITE/'public/favicon.ico'
        square(64).save(ico,format='ICO',sizes=[(16,16),(32,32),(48,48),(64,64)])
        records.append({'file':'../../favicon.ico','sizes':[16,32,48,64],
                        'bytes':ico.stat().st_size,'sha256':hashlib.sha256(ico.read_bytes()).hexdigest()})
        manifest = {'source':SOURCE.relative_to(SITE).as_posix(),'originalFilename':'Layer 13 copy 2.png',
                    'originalSha256':digest,'originalDimensions':list(original.size),
                    'kind':'User-selected supplied Cyrus Scatter logo',
                    'processing':'Lossless PNG encoding; aspect-preserving downscales with original alpha; no artwork changes',
                    'assets':records}
    (DESTINATION/'manifest.json').write_text(json.dumps(manifest,indent=2)+'\n',encoding='utf-8')
    print(json.dumps({'sourceSha256':digest,'files':len(records)},indent=2))


if __name__ == '__main__':
    main()
