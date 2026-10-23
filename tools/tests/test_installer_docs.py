"""Cross-check artist recovery instructions against the shipped installer rules."""
from pathlib import Path
import re

ROOT=Path(__file__).resolve().parents[2]

def test_installation_guide_lists_the_exact_legacy_wrapper_versions_once():
    code=(ROOT/'AminScatter/setup/InstallEngine.cs').read_text(encoding='utf-8-sig')
    block=code.split('static readonly string[,] LegacyWrappers = {',1)[1].split('};',1)[0]
    supported=set(re.findall(r'\{"([0-9.]+)"',block))
    guide=(ROOT/'docs/Max_2027_Installation.md').read_text(encoding='utf-8-sig')
    paragraphs=[p for p in guide.split('\n\n') if p.startswith('A profile without an installation receipt can migrate')]
    assert len(paragraphs)==1
    assert set(re.findall(r'\b0\.[0-9]+\.[0-9]+(?:\.[0-9]+)?\b',paragraphs[0]))==supported

def test_artist_guide_has_one_panel_order_instruction():
    guide=(ROOT/'docs/ARTIST_GUIDE.md').read_text(encoding='utf-8-sig')
    assert guide.count('Drag rollout headers to arrange the Modify panel.')==1
