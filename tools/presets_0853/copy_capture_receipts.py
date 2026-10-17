"""Reuse the unchanged qualified asset captures for a new consumer script."""
from pathlib import Path
import argparse,json,shutil
ROOT=Path(__file__).resolve().parents[2]
p=argparse.ArgumentParser();p.add_argument('source',type=Path);p.add_argument('destination',type=Path);a=p.parse_args()
source=a.source.resolve();destination=a.destination.resolve()
for path in (source,destination):assert path.parent==ROOT/'build/mcp-qualification' and path.name.startswith('foundation-presets0853-')
for record in source.glob('library-*-capture.json'):
    data=json.loads(record.read_text());assert data['status']=='passed';shutil.copy2(record,destination/record.name)
