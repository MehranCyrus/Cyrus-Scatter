"""Replace only the owned fixture scene with the copied terrace drag fixture."""
from pathlib import Path
from pymxs import runtime as r

root = Path(__file__).resolve().parents[3]
r.fileIn(str(root / 'tools/procedural_lab/interactions08741/physical_boot.ms'))
