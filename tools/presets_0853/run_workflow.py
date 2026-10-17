"""Existing planting, exact-reference Save, unavailable-library Redo and failure."""
from pathlib import Path
import argparse, json, subprocess, sys
from await_host import wait

ROOT = Path(__file__).resolve().parents[2]
p = argparse.ArgumentParser()
p.add_argument('profile', type=Path)
p.add_argument('--phases', nargs='+', default=['galleryLoad','preserved','undo','checkUndo','redo','checkRedo','save','checkSave','loadSaved','checkSaved','cancel','fault','checkFault'])
a = p.parse_args()
host = a.profile.resolve()
assert host.parent == ROOT / 'build/mcp-qualification' and host.name.startswith('foundation-presets0853-')
moved = None
try:
    for phase in a.phases:
        if phase=='galleryLoad':wait(host,'not CyrusRecipeBrowser.scanTimer.active')
        if phase in ('preserved','checkSaved','checkFault'):wait(host,'CyrusReadyPresetEditor!=undefined and CyrusReadyPresetEditor.finished')
        if phase=='checkSave':wait(host,'CyrusPresetSaveEditor!=undefined and CyrusPresetSaveEditor.finished')
        (host / 'workflow-phase.txt').write_text(phase, encoding='utf-8')
        result = subprocess.run([sys.executable, str(ROOT / 'tools/presets_0853/dispatch.py'), str(host)],
                                input='fileIn "' + (ROOT / 'tools/presets_0853/workflow.ms').as_posix() + '"',
                                text=True, capture_output=True)
        print(phase, result.stdout.strip(), flush=True)
        if result.returncode:
            print(result.stderr, flush=True)
            raise SystemExit(result.returncode)
        logs = sorted(host.glob('workflow-*-' + phase + '.txt'), key=lambda f:f.stat().st_mtime)
        text = logs[-1].read_text(encoding='utf-8-sig')
        assert 'PASS: complete' in text and 'FAIL:' not in text, text
        if phase == 'preserved':
            source = Path(json.loads((host / 'library-meadow-capture.json').read_text(encoding='utf-8'))['package']).resolve()
            target = source.with_name(source.name + '-unavailable')
            assert source.is_relative_to(ROOT / 'build/presets-0853-20261016-01/library/Presets') and not target.exists()
            source.rename(target)
            moved = (source, target)
        if phase == 'checkRedo' and moved:
            moved[1].rename(moved[0]);moved = None
finally:
    if moved:
        assert not moved[0].exists() and moved[1].exists()
        moved[1].rename(moved[0])
