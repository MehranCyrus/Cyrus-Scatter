"""Encode a faithful display derivative without modifying the artist's source image.

Requires tools/requirements-assets.txt. Production/site builds use committed
derivatives and do not require Pillow or the ignored artist source folder.
"""
from pathlib import Path
import hashlib
import json
from PIL import Image, features, __version__ as pillow_version

SITE=Path(__file__).resolve().parents[1]
REPO=SITE.parent
SOURCE=REPO/'Test Scene'/'Reference_Garden_075'/'Garden_Final.png'
DESTINATION=SITE/'public'/'assets'/'captures'

def sha(data):return hashlib.sha256(data).hexdigest()

def main():
    original=SOURCE.read_bytes()
    source_hash=sha(original)
    with Image.open(SOURCE) as image:
        source_size=image.size
        width=min(1200,image.width)
        height=round(image.height*width/image.width)
        derivative=image.resize((width,height),Image.Resampling.LANCZOS)
        target=DESTINATION/'garden-study-075.webp'
        derivative.save(target,format='WEBP',quality=95,method=6,exact=True)
    assert SOURCE.read_bytes()==original,'Artist source must remain unchanged.'
    encoded=target.read_bytes()
    if len(encoded)>1_500_000:
        raise SystemExit('Display derivative exceeds 1.5 MB; review quality/size deliberately.')
    manifest_path=DESTINATION/'manifest.json'
    manifest=json.loads(manifest_path.read_text(encoding='utf-8'))
    for record in manifest:
        if record['file'].startswith('garden-study-075.'):
            record.update({'file':target.name,'sha256':sha(encoded),'bytes':len(encoded),'source':SOURCE.relative_to(REPO).as_posix(),'originalSha256':source_hash,'originalBytes':len(original),'originalWidth':source_size[0],'originalHeight':source_size[1],'width':width,'height':height,'encoding':{'format':'WebP','quality':95,'method':6,'alpha':'preserved','resize':'Lanczos','library':'Pillow '+pillow_version,'encoder':'libwebp '+str(features.version('webp'))},'kind':'Historical 0.75 Corona garden render · optimized display derivative'})
    manifest_path.write_text(json.dumps(manifest,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
    obsolete=DESTINATION/'garden-study-075.png'
    if obsolete.is_file():obsolete.unlink()
    print(json.dumps({'file':target.name,'bytes':len(encoded),'size':[width,height],'sha256':sha(encoded),'originalSha256':source_hash},indent=2))

if __name__=='__main__':main()
