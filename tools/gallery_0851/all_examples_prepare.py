"""Bind the immutable installed/source inventory for the owned all-example witness."""
from pathlib import Path
import json
from pymxs import runtime as r
ROOT=Path(__file__).resolve().parents[2];OUT=Path(str(r.MCPFixtureDir)).resolve()
assert OUT.parent==ROOT/'build/mcp-qualification' and OUT.name.startswith('foundation-roadmap-gallery0851-')
library=Path(str(r.CyrusRecipeBundledDirectory('0.85.1'))) if 'recipient-' in OUT.name else ROOT/'AminScatter/library'
entries=json.loads((library/'inventory.json').read_text(encoding='utf-8'))['entries']
r.execute('global GalleryAllExamples')
r.GalleryAllExamples=r.Array(*[r.Array(e['id'],str(library/e['scene']),str(library/e['recipe']),r.Array(*e['counts'])) for e in entries])
