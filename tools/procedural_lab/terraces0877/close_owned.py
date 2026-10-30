from pathlib import Path
from pymxs import runtime as r
out=Path(str(r.GardenRun))
assert '/build/terraces0877-' in out.as_posix() and (out/'loaded-identity.json').is_file()
r.quitMax(r.Name('noPrompt'))
