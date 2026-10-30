from pathlib import Path
from pymxs import runtime as r
root=Path(__file__).resolve().parents[3]
r.execute('try(destroyDialog CyrusSelectionUI)catch()')
r.fileIn(str(root/'AminScatter/tools/ui/templates/viewport-selection.ms'))
r.CyrusSelectionTimer.Stop()
r.python.ExecuteFile(str(Path(__file__).with_name('smoke.py')))
