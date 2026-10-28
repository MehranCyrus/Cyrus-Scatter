"""Create an instrumented copy of the exact loaded viewport sync for profiling.

The product function is not replaced.  The generated copy uses the same body
and records bounded, host-thread elapsed intervals between its existing stages.
Run only in an owned Max test process after selecting a repeatable fixture.
"""
from pathlib import Path
import argparse
import hashlib
import json


def once(text, before, after):
    if text.count(before) != 1:
        raise ValueError(f"Expected one instrumentation boundary: {before!r}")
    return text.replace(before, after, 1)


parser = argparse.ArgumentParser()
parser.add_argument('--script', type=Path, required=True)
parser.add_argument('--output', type=Path, required=True)
args = parser.parse_args()
raw = args.script.read_bytes()
text = raw.decode('utf-8-sig')
start = text.index('fn CyrusPointSync = (')
end = text.index('\nfn CyrusViewportRedraw = (', start)
body = text[start:end]
body = once(body, 'fn CyrusPointSync = (', 'fn CVProfilePointSync = (')
body = once(body, '    CyrusPointBusy=true\n', '    CyrusPointBusy=true\n    CVProfileBegin()\n')
body = once(body, '        CyrusPointOwners=surviving\n', '        CyrusPointOwners=surviving\n        CVProfileMark "owners"\n')
body = once(body, '            -- Observe every visible dependency', '            CVProfileMark "layer_entries"\n            -- Observe every visible dependency')
body = once(body, '            if refreshLeaf!=undefined do refreshLeaf.refreshPreview()', '            CVProfileMark "preview_cache"\n            if refreshLeaf!=undefined do refreshLeaf.refreshPreview()\n            CVProfileMark "refresh_preview"')
body = once(body, '            for entry in entries do (\n                local obj=entry[2],cache=', '            CVProfileMark "ensure_interactions"\n            for entry in entries do (\n                local obj=entry[2],cache=')
body = once(body, '            local owner=CyrusPointOwner n', '            CVProfileMark "collect_display"\n            local owner=CyrusPointOwner n')
body = once(body, '            append records #(n,owner,caches,styles,fallback,2)', '            CVProfileMark "retained_publish_and_status"\n            append records #(n,owner,caches,styles,fallback,2)')
body = once(body, '        CyrusPointLastError=publishError;CyrusPointDetailStatus=detailStatus', '        CyrusPointLastError=publishError;CyrusPointDetailStatus=detailStatus\n        CVProfileMark "commit_records"')
body = once(body, '    CyrusPointBusy=false\n', '    CyrusPointBusy=false\n    CVProfileMark "finish"\n')
prefix = '''-- Diagnostic copy; the production global CyrusPointSync is not modified.
global CVProfileRows,CVProfilePrevious,CVProfileStopwatch,CVProfileBegin,CVProfileMark,CVProfilePointSync
CVProfileStopwatch=dotNetObject "System.Diagnostics.Stopwatch"
fn CVProfileBegin = (CVProfileRows=#();CVProfileStopwatch.Restart();CVProfilePrevious=0.0)
fn CVProfileMark label = (
    local current=CVProfileStopwatch.Elapsed.TotalMilliseconds as double
    append CVProfileRows #(label,current-CVProfilePrevious)
    CVProfilePrevious=current
)
'''
args.output.parent.mkdir(parents=True, exist_ok=True)
args.output.write_text(prefix + body + '\n', encoding='utf-8')
args.output.with_suffix('.identity.json').write_text(json.dumps({
    'source_path': str(args.script.resolve()), 'source_sha256': hashlib.sha256(raw).hexdigest(),
    'instrumented_sha256': hashlib.sha256(args.output.read_bytes()).hexdigest(),
    'scope': 'Owned host instrumented copy; production sync is unchanged.'}, indent=2), encoding='utf-8')
print(args.output)
