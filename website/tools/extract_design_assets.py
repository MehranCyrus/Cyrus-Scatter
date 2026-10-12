"""Extract eight deduplicated supplied WebP variants; never modifies the design archive."""
from pathlib import Path
import base64
import hashlib
import json
import re

SITE=Path(__file__).resolve().parents[1]
SOURCE=SITE.parent/'Landing Page Design'/'Cyrus_Scatter_Landing_Page (2).html'
NAMES=['courtyard-mobile','courtyard','courtyard-480','coastal-mobile','coastal','coastal-480','perennial','perennial-480']
destination=SITE/'public'/'assets'/'concepts'
destination.mkdir(parents=True,exist_ok=True)
seen=set(); records=[]
for match in re.finditer(r'data:image/webp;base64,([A-Za-z0-9+/=]+)',SOURCE.read_text(encoding='utf-8')):
    data=base64.b64decode(match[1]); digest=hashlib.sha256(data).hexdigest()
    if digest in seen:continue
    seen.add(digest);name=NAMES[len(records)]+'.webp'
    (destination/name).write_bytes(data)
    records.append({'file':name,'sha256':digest,'source':SOURCE.relative_to(SITE.parent).as_posix(),'kind':'Supplied generated concept artwork; not Cyrus output','bytes':len(data)})
if len(records)!=8:raise SystemExit('Supplied concept variant count changed; review extraction.')
manifest = destination/'manifest.json'
# Re-extracting the archive must not drop the current generated asset receipts.
existing = json.loads(manifest.read_text(encoding='utf-8')) if manifest.exists() else []
extracted = {record['file'] for record in records}
records.extend(record for record in existing if record['file'] not in extracted)
manifest.write_text(json.dumps(records,indent=2)+'\n',encoding='utf-8')
print('Extracted eight local concept image variants.')
