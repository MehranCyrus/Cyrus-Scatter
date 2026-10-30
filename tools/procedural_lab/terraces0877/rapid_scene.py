from pathlib import Path
from pymxs import runtime as r
root=Path(__file__).resolve().parents[3]
r.execute('global CVProfileCase="rapid-scene"')
r.fileIn(str(root/'tools/procedural_lab/drag08756/drag_timer.ms'))
